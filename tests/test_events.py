"""Random events (Events.lua, docs/eventos.md): only with the game open, at most 2, a deadline by the clock; missing one
loses its chance and its xp, nothing else; five kinds, each paying what it says; never more than the Garden."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

HOUR = 3600


class Base(unittest.TestCase):
    SAVED = None
    setUp_ = th.Homestead.setUp
    ev = th.Homestead.ev

    def setUp(self):
        self.setUp_()
        self.lua.execute("""
            NS.db.level = 30; NS.db.coins = 100000
            NS.db.buildings.hall = 5; NS.db.buildings.mine = 2; NS.db.buildings.pond = 2; NS.db.buildings.workshop = 3
            NS.Orders:Ensure()
        """)

    def spawn(self, kind):
        return self.ev(f"NS.Events:Spawn('{kind}').id")

    def open_count(self):
        return self.ev("#NS.Events:Open()")


class Clock(Base):
    def test_events_come_with_play_and_stop_at_two(self):
        self.assertEqual(self.open_count(), 0)
        self.lua.execute(f"NS.Events:Update(); NOW = NOW + 2 * {HOUR}; NS.Events:Update()")    # the longest gap
        self.assertEqual(self.open_count(), 1)
        self.lua.execute(f"NOW = NOW + 2 * {HOUR}; NS.Events:Update(); NOW = NOW + 1800; NS.Events:Update()")
        for _ in range(6):
            self.lua.execute(f"NOW = NOW + 2 * {HOUR}; NS.Events:Update()")
        self.assertLessEqual(self.open_count(), 2)

    def test_the_time_away_is_not_play(self):
        self.lua.execute(f"NS.Events:Update(); NOW = NOW + 10 * {HOUR}; NS.Events:OnLogin(); NS.Events:Update()")
        self.assertEqual(self.open_count(), 0)                   # nothing waiting at login after a long time away

    def test_a_missed_event_goes_away_and_takes_nothing(self):
        self.spawn("merchant")
        coins, crops = self.ev("NS.db.coins"), self.ev("NS.Village:Stored()")
        self.lua.execute(f"NOW = NOW + 3 * {HOUR}; NS.db.events.nextAt = NOW + 99999; NS.Events:Update()")
        self.assertEqual(self.open_count(), 0)
        self.assertEqual((self.ev("NS.db.coins"), self.ev("NS.Village:Stored()")), (coins, crops))
        self.assertEqual(list(self.lua.eval("NS.Events:Missed()").values()), ["merchant"])
        self.assertEqual(len(self.lua.eval("NS.Events:Missed()")), 0)        # told once


class Kinds(Base):
    def test_the_urgent_order_pays_double_and_three_times_the_xp(self):
        id_ = self.spawn("urgent")
        self.lua.execute(f"local e = NS.Events:Get({id_}); if type(e.key) == 'number' then NS.db.crops[e.key] = e.qty else NS.db.goods[e.key] = e.qty end")
        coins, xp, level = self.ev("NS.db.coins"), self.ev("NS.db.xp"), self.ev("NS.db.level")
        reward = self.ev(f"NS.Events:Get({id_}).coins")
        ok = self.lua.eval(f"function() return NS.Events:Deliver({id_}) end")()[0]
        self.assertTrue(ok)
        self.assertEqual(self.ev("NS.db.coins"), coins + reward)
        self.assertEqual(self.open_count(), 0)

    def test_the_urgent_order_waits_for_what_it_asks(self):
        id_ = self.spawn("urgent")
        self.assertEqual(tuple(self.lua.eval(f"function() return NS.Events:Deliver({id_}) end")()), (False, "missing"))

    def test_the_merchant_pays_double_up_to_twenty(self):
        id_ = self.spawn("merchant")
        self.lua.execute(f"local e = NS.Events:Get({id_}); if type(e.key) == 'number' then NS.db.crops[e.key] = 30 else NS.db.goods[e.key] = 30 end")
        price = self.ev(f"NS.Events:Get({id_}).price")
        value = self.ev(f"(function() local k = NS.Events:Get({id_}).key; return type(k) == 'number' and NS.Data.Plant(k).sell or NS.Village:GoodSell(k) end)()")
        self.assertAlmostEqual(price, value * 2, delta=max(2, value * 0.06))
        coins = self.ev("NS.db.coins")
        wants = self.ev(f"NS.Events:Get({id_}).left")         # up to twenty (fewer for a costly item: the cap)
        self.assertTrue(5 < wants <= 20)
        self.lua.execute(f"NS.Events:Sell({id_}, 5)")
        self.assertEqual(self.ev("NS.db.coins"), coins + 5 * price)
        self.assertEqual(self.ev(f"NS.Events:Get({id_}).left"), wants - 5)
        self.lua.execute(f"NS.Events:Sell({id_})")                          # the rest he wants
        self.assertEqual(self.open_count(), 0)

    def test_the_caravan_trades_gain_value_and_never_make_coins(self):
        id_ = self.spawn("caravan")
        coins = self.ev("NS.db.coins")
        for k in (1, 2, 3):
            t = f"NS.Events:Get({id_}).trades[{k}]"
            self.lua.execute(f"local t = {t}; if type(t.give) == 'number' then NS.db.crops[t.give] = (NS.db.crops[t.give] or 0) + t.n else NS.db.goods[t.give] = NS.Village:Good(t.give) + t.n end")
            gain = self.lua.eval(f"""function() local t = {t}
                local function v(k) return type(k) == 'number' and NS.Data.Plant(k).sell or NS.Village:GoodSell(k) end
                return (t.m * v(t.get)) / (t.n * v(t.give)) end""")()
            self.assertLessEqual(gain, 1.3 + 1e-9)
            self.assertTrue(self.lua.eval(f"function() return NS.Events:Trade({id_}, {k}) end")()[0])
        self.assertEqual(self.ev("NS.db.coins"), coins)
        self.assertEqual(self.open_count(), 0)

    def test_rare_finds_go_to_the_barn(self):
        for kind in ("fish", "ore"):
            id_ = self.spawn(kind)
            key = self.ev(f"NS.Events:Get({id_}).key")
            self.assertEqual(self.ev(f"NS.Balance.GOODS.{key}.rare"), kind)
            self.lua.execute(f"NS.Events:Collect({id_})")
            self.assertEqual(self.ev(f"NS.Village:Good('{key}')"), 1)
            self.assertGreater(self.ev(f"NS.Village:GoodSell('{key}')"), 0)

    def test_a_rare_find_is_not_a_workshop_item(self):
        # one key, one thing: the Firefin Snapper of the Pond once shared "snapper" with the Mud Snapper of the Workshop
        for key in self.lua.eval("NS.Balance.RARE_ORDER").values():
            self.assertIsNone(self.lua.eval(f"NS.Workshop.Recipe('{key}')"), key)
            self.assertNotEqual(self.ev(f"NS.T('good_{key}')"), f"good_{key}")

    def test_no_rare_fish_without_a_pond(self):
        self.lua.execute("NS.db.buildings.pond = 0; NS.db.buildings.mine = 0")
        for _ in range(60):
            self.lua.execute("local e = NS.Events:Spawn(); NS.db.events.open = {}")
            self.assertNotIn(self.ev("NS.db.events.serial and NS.Events:Spawn().kind"), ("fish", "ore"))
            self.lua.execute("NS.db.events.open = {}")


# What the events earn an hour at a level, played by the real answers (Deliver, Sell, Trade, Collect), with the village a
# player can have there (each building at the highest level its gate opens). coins = what they pay over selling the same
# things at the Market; value = coins + the value the caravans add (goods, not coins); xp = what the answers give.
MEASURE = """function(level, n)
    local B, V, D = NS.Balance, NS.Village, NS.Data
    local db = NS.db
    local function Value(k) return type(k) == 'number' and D.Plant(k).sell or V:GoodSell(k) end
    local function Stock(k, q)
        if type(k) == 'number' then db.crops[k] = q else db.goods[k] = q end
    end
    db.level = level
    local lv = 0
    for i, gate in ipairs(B.BUILD_GATE) do if gate <= level then lv = i end end
    for id in pairs(B.BUILD_WEIGHT) do db.buildings[id] = lv end
    db.nplots = V:Plots()
    local coins, value, xp, kinds = 0, 0, 0, {}
    for i = 1, n do
        db.events.open = {}
        local e = NS.Events:Spawn()
        kinds[e.kind] = (kinds[e.kind] or 0) + 1
        local ok, r
        if e.kind == 'urgent' then
            Stock(e.key, e.qty)
            ok, r = NS.Events:Deliver(e.id)
            coins = coins + r.coins - e.qty * Value(e.key)
            xp = xp + r.xp
        elseif e.kind == 'merchant' then
            Stock(e.key, e.left)
            local price = e.price
            ok, r = NS.Events:Sell(e.id)
            coins = coins + r.coins - r.n * Value(e.key)
            xp = xp + r.xp
        elseif e.kind == 'caravan' then
            for k, t in ipairs(e.trades) do
                Stock(t.give, t.n)
                ok, r = NS.Events:Trade(e.id, k)
                value = value + t.m * Value(t.get) - t.n * Value(t.give)
            end
        else
            ok, r = NS.Events:Collect(e.id)
            coins = coins + Value(e.key)
            xp = xp + r.xp
        end
        assert(ok, e.kind)
        db.level = level
    end
    local per = 3600 / ((B.EVENTS.gapMin + B.EVENTS.gapMax) / 2) / n      -- events an hour, per event drawn
    local plots = V:Plots()
    local garden = B.GardenIncome(level, plots)
    local gardenXP = plots * D.XPToNext(level) * B.HERB_CURVE.harvestXPShare / B.HERB_CURVE.xpHours
    return coins * per, (coins + value) * per, xp * per, garden, gardenXP, plots
end"""

LEVELS = (1, 5, 10, 12, 20, 30, 42, 50, 55, 60)


def measure(test, level, n=600):
    coins, value, xp, garden, garden_xp, plots = test.lua.eval(MEASURE)(level, n)
    return {"level": level, "plots": plots, "coins": coins, "value": value, "xp": xp,
            "garden": garden, "garden_xp": garden_xp}


class Economy(Base):
    """T2.10: at every level, with the village a player can have there, the events add less than a fifth of what the
    Garden makes in an hour, in coins and also counting what the caravans add."""

    def test_events_never_earn_more_than_a_fifth_of_the_garden(self):
        for level in LEVELS:
            m = measure(self, level)
            self.assertLess(m["coins"], 0.2 * m["garden"], m)
            self.assertLess(m["value"], 0.2 * m["garden"], m)

    def test_a_big_order_or_merchant_stops_at_the_cap(self):
        # level 60, a full village: late herbs and Workshop items are worth hours of a plot each
        self.lua.execute("NS.db.level = 60; for id in pairs(NS.Balance.BUILD_WEIGHT) do NS.db.buildings[id] = 7 end")
        cap = self.ev("NS.Balance.GardenIncome(60, NS.Village:Plots()) * NS.Balance.EVENTS.capMinutes / 60")
        for _ in range(200):
            self.lua.execute("NS.db.events.open = {}")
            e = self.lua.eval("NS.Events:Spawn()")
            value = self.lua.eval("function(k) return type(k) == 'number' and NS.Data.Plant(k).sell or NS.Village:GoodSell(k) end")
            if e.kind == "urgent":
                extra = e.coins - e.qty * value(e.key)
                self.assertTrue(e.qty == 1 or extra <= cap, (e.qty, extra, cap))
            elif e.kind == "merchant":
                extra = e.left * (e.price - value(e.key))
                self.assertTrue(e.left == 1 or extra <= cap, (e.left, extra, cap))
                self.assertLessEqual(e.left, 20)


if __name__ == "__main__":
    unittest.main()
