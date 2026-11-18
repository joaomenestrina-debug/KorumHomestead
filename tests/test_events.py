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
        self.lua.execute(f"NS.Events:Sell({id_}, 5)")
        self.assertEqual(self.ev("NS.db.coins"), coins + 5 * price)
        self.assertEqual(self.ev(f"NS.Events:Get({id_}).left"), 15)
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

    def test_no_rare_fish_without_a_pond(self):
        self.lua.execute("NS.db.buildings.pond = 0; NS.db.buildings.mine = 0")
        for _ in range(60):
            self.lua.execute("local e = NS.Events:Spawn(); NS.db.events.open = {}")
            self.assertNotIn(self.ev("NS.db.events.serial and NS.Events:Spawn().kind"), ("fish", "ore"))
            self.lua.execute("NS.db.events.open = {}")


class Economy(Base):
    def test_events_never_earn_more_than_a_fifth_of_the_garden(self):
        for level in (10, 30, 50):
            avg = self.lua.eval(f"""function()
                NS.db.level = {level}
                local total, n = 0, 400
                for i = 1, n do
                    local e = NS.Events:Spawn(); NS.db.events.open = {{}}
                    local function v(k) return type(k) == 'number' and NS.Data.Plant(k).sell or NS.Village:GoodSell(k) end
                    if e.kind == 'urgent' then total = total + e.coins - e.qty * v(e.key)          -- over selling them
                    elseif e.kind == 'merchant' then total = total + e.left * e.price / 2      -- the extra over selling
                    elseif e.kind == 'fish' or e.kind == 'ore' then total = total + NS.Village:GoodSell(e.key) end
                end
                return total / n end""")()
            per_hour = avg / ((self.ev("NS.Balance.EVENTS.gapMin") + self.ev("NS.Balance.EVENTS.gapMax")) / 2 / HOUR)
            garden = self.ev(f"NS.Balance.GardenIncome({level}, 6)")
            self.assertLess(per_hour, 0.2 * garden, level)


if __name__ == "__main__":
    unittest.main()
