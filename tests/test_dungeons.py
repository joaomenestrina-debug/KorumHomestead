"""The dungeons and the followers (Dungeons.lua, Journal.lua; docs/masmorras.md §15)."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

HOUR = 3600


class Base(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def inn(self, level=6, fish=500, **levels):
        self.lua.execute(f"NS.db.buildings.hall = 5; NS.db.buildings.inn = {level}; NS.db.goods.fish = {fish}; NS.db.level = 30")
        for fid, lv in levels.items():
            self.lua.execute(f"NS.Inn:Get('{fid}').level = {lv}")

    def chance(self, dungeon, party):
        lua = "{" + ",".join(f"'{p}'" for p in party) + "}"
        return self.ev(f"(NS.Dungeons:Chance('{dungeon}', {lua}))")

    def parts(self, dungeon, party):
        lua = "{" + ",".join(f"'{p}'" for p in party) + "}"
        return self.lua.eval(f"""(function() local _, parts = NS.Dungeons:Chance('{dungeon}', {lua})
            local out = {{}} for i, p in ipairs(parts) do out[i] = p[1] .. ':' .. p[2] .. ':' .. tostring(p[3]) end
            return table.concat(out, ' ') end)()""")

    def send(self, dungeon, party, roll=1):
        lua = "{" + ",".join(f"'{p}'" for p in party) + "}"
        self.lua.execute(f"NS.Rand = function() return {roll} end")
        ok = self.lua.eval(f"function() return NS.Dungeons:Send('{dungeon}', {lua}) end")()
        self.lua.execute("NS.Rand = nil")
        return ok


class Chance(Base):
    def test_each_threat_left_takes_25_and_a_counter_removes_it(self):
        self.inn(mira=1, sela=1)
        # Ragefire: Horde and Hostile magic. Mira counters Horde (Volley); Sela counters magic (Counterspell)
        self.assertEqual(self.parts("ragefire", ["mira"]), "threat:-25:magic trait:10:mira")   # Mira likes caves
        self.assertEqual(self.chance("ragefire", ["mira"]), 85)
        self.assertEqual(self.chance("ragefire", ["sela"]), 75)
        self.assertEqual(self.parts("ragefire", []), "threat:-25:horde threat:-25:magic missing:-20:1")

    def test_levels_under_cost_5_each_and_over_give_2_up_to_10(self):
        self.inn(mira=1, tobin=1)
        self.lua.execute("NS.Inn:Get('mira').level = 4; NS.Inn:Get('tobin').level = 4")
        # Deadmines (level 5, Horde and Traps, 2 followers): Mira counters Horde; the group is one level under
        self.assertEqual(self.parts("deadmines", ["mira", "tobin"]), "threat:-25:traps level:-5:nil trait:10:mira")
        self.lua.execute("NS.Inn:Get('mira').level = 30; NS.Inn:Get('tobin').level = 30")
        self.assertIn("level:10:nil", self.parts("deadmines", ["mira", "tobin"]))

    def test_a_missing_follower_costs_20(self):
        self.inn(mira=5)
        self.assertIn("missing:-20:1", self.parts("deadmines", ["mira"]))

    def test_traits_count(self):
        self.inn(mira=4, bram=4, garrick=6)
        # Mira likes caves (+10, Deadmines is a cave); Bram: +5 for each other follower
        self.assertIn("trait:10:mira", self.parts("deadmines", ["mira", "bram"]))
        self.assertIn("trait:5:bram", self.parts("deadmines", ["mira", "bram"]))
        # Garrick fears the undead until level 20
        self.assertIn("trait:-10:garrick", self.parts("shadowfang", ["garrick"]))
        self.lua.execute("NS.Inn:Get('garrick').level = 20")
        self.assertNotIn("trait:-10:garrick", self.parts("shadowfang", ["garrick"]))

    def test_over_100_becomes_a_reward_bonus_up_to_150(self):
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons.Odds(130) end")()), (100, 1.3))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons.Odds(200) end")()), (100, 1.5))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons.Odds(-20) end")()), (0, 1))


class Group(Base):
    def test_the_suggested_group_is_the_best_one(self):
        self.inn(mira=8, tobin=8, elda=8, garrick=8, sela=8, bram=8)
        # Blackfathom: Horde and Poison. Mira (Horde) + Elda (Poison) counter both
        best = self.lua.eval("function() local p, t = NS.Dungeons:Suggest('blackfathom'); table.sort(p); return table.concat(p, ','), t end")()
        self.assertEqual(best[0], "elda,mira")
        # no other pair does better
        ids = ["mira", "tobin", "elda", "garrick", "sela", "bram"]
        for a in ids:
            for b in ids:
                if a < b:
                    self.assertLessEqual(min(150, self.chance("blackfathom", [a, b])), best[1])

    def test_the_recommended_come_first_with_what_they_counter(self):
        self.inn(mira=8, tobin=8, elda=8, garrick=8, sela=8, bram=8)
        first = self.lua.eval("function() local r = NS.Dungeons:Recommended('blackfathom', {'mira'})[1]; return r.id, r.gain, r.counters[1] end")()
        self.assertEqual(tuple(first), ("elda", 45, "poison"))        # Poison countered and the empty place filled

    def test_someone_away_is_not_free(self):
        self.inn(mira=1)
        self.assertTrue(self.send("ragefire", ["mira"]))
        self.assertFalse(self.ev("NS.Dungeons:Free('mira')"))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons:Send('ragefire', {'mira'}) end")())[:2], (False, "busy"))
        party = self.lua.eval("function() return #NS.Dungeons:Suggest('ragefire') end")()
        self.assertNotEqual(self.ev("NS.Dungeons:Suggest('ragefire')[1]"), "mira")
        self.assertGreaterEqual(party, 0)


class Runs(Base):
    def test_a_success_pays_in_full_and_levels_up(self):
        self.inn(mira=1)
        self.assertTrue(self.send("ragefire", ["mira"]))
        trip = "NS.db.trips[1]"
        self.assertTrue(self.ev(trip + ".ok"))
        coins = self.ev(trip + ".coins")
        self.assertEqual(coins, self.ev("(NS.Dungeons:Reward('ragefire', {'mira'}, 85))"))
        self.lua.execute(f"NOW = NOW + {HOUR}; NS.Inn:CollectAll()")
        self.assertGreater(self.ev("NS.db.followers.mira.xp") + self.ev("NS.db.followers.mira.level"), 1)
        self.assertEqual(self.ev("NS.db.dungeons.runs"), 1)

    def test_a_failure_pays_half_and_may_hurt(self):
        self.inn(mira=1)
        self.lua.execute("NS.Rand = function() return 1 end")
        full = self.ev("(NS.Dungeons:Reward('ragefire', {'mira'}, 85))")
        self.assertTrue(self.send("ragefire", ["mira"], roll=9999))      # 99.99 > 85: a failure; 0.9999 > 0.30: not hurt
        self.assertFalse(self.ev("NS.db.trips[1].ok"))
        self.assertEqual(self.ev("NS.db.trips[1].coins"), round(full / 2))

    def test_a_hurt_follower_rests_two_hours(self):
        self.inn(mira=1)
        self.lua.execute("local n = 0; NS.Rand = function() n = n + 1; return n == 1 and 9999 or 1 end")
        self.lua.execute("assert(NS.Dungeons:Send('ragefire', {'mira'})); NS.Rand = nil")
        self.assertEqual(self.ev("NS.db.trips[1].hurt[1]"), "mira")
        self.lua.execute(f"NOW = NOW + {HOUR}; NS.Inn:CollectAll()")
        self.assertEqual(self.ev("(NS.Inn:State('mira'))"), "hurt")
        self.assertFalse(self.ev("NS.Dungeons:Free('mira')"))
        self.lua.execute(f"NOW = NOW + {2 * HOUR}")
        self.assertEqual(self.ev("(NS.Inn:State('mira'))"), "home")

    def test_the_dungeon_of_the_day_gives_more_follower_xp(self):
        self.inn(mira=1)
        daily = self.ev("NS.Dungeons:Daily()")
        self.assertIsNotNone(daily)
        plain = self.lua.eval(f"function() local _, _, x = NS.Dungeons:Reward('{daily}', {{'mira'}}, 100, -1); return x.mira end")()
        today = self.lua.eval(f"function() local _, _, x = NS.Dungeons:Reward('{daily}', {{'mira'}}, 100); return x.mira end")()
        if self.ev("NS.Dungeons:Daily(-1)") != daily:
            self.assertEqual(today, round(plain * 1.5))

    def test_closing_the_game_changes_nothing(self):
        self.inn(mira=1)
        self.send("ragefire", ["mira"])
        before = self.ev("NS.db.trips[1].coins")
        self.lua.execute(f"KorumHomesteadDB = NS.db; NOW = NOW + {HOUR}")
        self.assertEqual(self.ev("NS.db.trips[1].coins"), before)
        self.assertEqual(self.ev("NS.Inn:BackCount()"), 1)


class Quality(Base):
    def test_rare_needs_level_10_and_a_merit_insignia(self):
        self.inn(mira=9)
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:NextQuality('mira') end")()), ("rare", False))
        self.lua.execute("NS.Inn:Get('mira').level = 10")
        self.assertFalse(self.lua.eval("function() return NS.Inn:NextQuality('mira') end")()[1])
        self.lua.execute("NS.db.dungeons.merit = 1")
        self.assertTrue(self.lua.eval("function() return NS.Inn:NextQuality('mira') end")()[1])
        self.assertTrue(self.ev("NS.Inn:Promote('mira', 2)"))
        self.assertEqual(self.ev("NS.db.followers.mira.quality"), "rare")
        self.assertEqual(self.ev("NS.db.followers.mira.ability"), "aimed")
        self.assertEqual(self.ev("NS.db.dungeons.merit"), 0)
        self.assertEqual(self.ev("#NS.Inn:Abilities('mira')"), 2)

    def test_epic_picks_a_second_trait(self):
        self.inn(mira=20)
        self.lua.execute("NS.db.dungeons.merit = 1; NS.db.dungeons.epic = 1; NS.Inn:Promote('mira', 1)")
        self.assertTrue(self.ev("NS.Inn:Promote('mira', 2)"))
        self.assertEqual(self.ev("NS.db.followers.mira.quality"), "epic")
        self.assertEqual(self.ev("NS.Inn:Traits('mira')[2][1]"), "lucky")

    def test_changing_a_pick_costs_more_each_time(self):
        self.inn(mira=10)
        self.lua.execute("NS.db.coins = 1e7; NS.db.dungeons.merit = 1; NS.Inn:Promote('mira', 1)")
        first = self.ev("NS.Inn:RespecCost('mira')")
        self.assertTrue(self.ev("(NS.Inn:Respec('mira', 'ability'))"))
        self.assertEqual(self.ev("NS.db.followers.mira.ability"), "aimed")
        self.assertAlmostEqual(self.ev("NS.Inn:RespecCost('mira')"), 2 * first, delta=1)

    def test_xp_levels_up_to_30_and_stops(self):
        self.inn(mira=1)
        self.assertEqual(self.ev("NS.Inn:AddXP('mira', 1e7)"), 29)
        self.assertEqual(self.ev("NS.db.followers.mira.level"), 30)
        self.assertEqual(self.ev("NS.Inn:AddXP('mira', 100)"), 0)


class Journal(Base):
    def test_every_threat_ability_and_drop_writes_in_both_languages(self):
        self.inn()
        for lang in ("enUS", "ptBR"):
            missing = self.lua.eval(f"""(function()
                local miss = {{}}
                local L = NS.L['{lang}']
                local function need(k) if not L[k] then miss[#miss + 1] = k end end
                for _, th in ipairs(NS.Balance.THREAT_ORDER) do need('j_by_' .. th); need('j_open_' .. th); need('th_' .. th) end
                for ab in pairs(NS.Balance.ABILITIES) do need('ab_' .. ab) end
                for name in pairs(NS.Balance.TRAITS) do need('tr_' .. name); need('trd_' .. name) end
                for _, d in ipairs(NS.Balance.DUNGEONS) do need('dg_' .. d.id); need('env_' .. d.env) end
                for _, f in ipairs(NS.Balance.FOLLOWERS) do need('fol_' .. f.id); need('fcl_' .. f.id) end
                for _, k in ipairs({{'j_ok', 'j_fail', 'j_hurt1', 'j_hurtN', 'j_went1', 'j_wentN', 'j_drop_merit', 'j_drop_epic', 'j_and'}}) do need(k) end
                return table.concat(miss, ',') end)()""")
            self.assertEqual(missing, "", lang)

    def test_a_run_writes_its_lines(self):
        self.inn(mira=4, tobin=4)
        self.lua.execute("NS.Inn:Get('mira').level = 6; NS.Inn:Get('tobin').level = 6")
        self.send("deadmines", ["mira", "tobin"])
        self.lua.execute(f"NOW = NOW + {2 * HOUR}; NS.Inn:CollectAll()")
        lines = self.lua.eval("function() local l = NS.Journal:Lines(NS.Journal:Latest()); return l[1], l[2] end")()
        self.assertEqual(lines[0], "Mira and Tobin went into The Deadmines. Mira held back the crowd with Volley.")
        self.assertTrue(lines[1].startswith("The traps caught them off guard. They came back victorious."), lines[1])
        self.assertEqual(self.ev("#NS.Journal:For('tobin')"), 1)
        self.assertTrue(self.ev("NS.db.followers.tobin.marks.first ~= nil"))


class Economy(Base):
    def test_dungeons_stay_under_half_of_the_garden(self):
        """Seven rooms always out, always at 150%: the coins of the dungeons stay under 50% of what the Garden makes."""
        for level in (30, 45, 60):
            self.lua.execute(f"NS.db.level = {level}; NS.db.buildings.garden = 7; NS.db.buildings.inn = 7")
            garden = self.ev(f"NS.Balance.GardenIncome({level}, NS.Village:Plots())")
            per_hour = self.lua.eval("""(function()
                local best = 0
                for _, d in ipairs(NS.Balance.DUNGEONS) do
                    local c = NS.Dungeons:Reward(d.id, {'mira', 'tobin', 'elda'}, 150)
                    best = math.max(best, c / d.hours * 7 / 3)      -- the seven rooms, always out
                end
                return best end)()""")
            self.assertLess(per_hour, 0.5 * garden, level)


class Pace(Base):
    def test_a_follower_sent_three_times_a_day_reaches_the_targets(self):
        """Level 10 in about a week, 20 in about three, 30 in six to eight (docs/masmorras.md §3.1)."""
        self.inn(mira=1)
        days = self.lua.eval("""(function()
            local f = NS.Inn:Get('mira')
            local at = {}
            local day = 0
            while f.level < 30 and day < 200 do
                day = day + 1
                for run = 1, 3 do
                    local best
                    for _, d in ipairs(NS.Balance.DUNGEONS) do
                        if d.level <= f.level + 1 then best = d end
                    end
                    local _, _, x = NS.Dungeons:Reward(best.id, {'mira'}, 100, -1)
                    NS.Inn:AddXP('mira', x.mira * 0.85)                 -- some runs fail and pay half
                end
                for _, lv in ipairs({10, 20, 30}) do
                    if f.level >= lv and not at[lv] then at[lv] = day end
                end
            end
            return at[10], at[20], at[30] end)()""")
        ten, twenty, thirty = days
        self.assertTrue(5 <= ten <= 10, ten)
        self.assertTrue(16 <= twenty <= 28, twenty)
        self.assertTrue(40 <= thirty <= 58, thirty)


class Migration(Base):
    SAVED = ("KorumHomesteadDB = {schema = 3, level = 40, coins = 900, nplots = 6, plots = {}, crops = {}, orders = {},"
             " buildings = {hall = 5, inn = 3}, goods = {fish = 10},"
             " followers = {{done = 7}, {done = 0, mission = {kind = 'medium', at = 990, time = 7200}}, {done = 20}}}")

    def test_the_six_keep_their_place_and_level(self):
        self.assertEqual(self.ev("NS.db.followers.mira.level"), 5)            # 7 missions: old level 3 -> 5
        self.assertEqual(self.ev("NS.db.followers.tobin.level"), 1)
        self.assertEqual(self.ev("NS.db.followers.elda.level"), 9)            # old level 5 (the most) -> 9
        self.assertEqual(self.ev("NS.db.trips[1].party[1]"), "tobin")
        self.assertEqual(self.ev("NS.db.trips[1].coins"), 170)
        self.lua.execute("NOW = NOW + 7200")
        self.assertEqual(self.ev("NS.Inn:BackCount()"), 1)
        coins = self.ev("NS.db.coins")
        self.lua.execute("NS.Inn:CollectAll()")
        self.assertEqual(self.ev("NS.db.coins"), coins + 170)
        self.assertEqual(self.ev("NS.db.goods.ore"), 2)


class Equipment(Base):
    def test_every_piece_is_worth_more_than_its_bars(self):
        bad = self.lua.eval("""(function() local out = {}
            for _, r in ipairs(NS.Workshop.RECIPES) do
                if r.trade == 'gear' then
                    local sum = 0
                    for _, i in ipairs(r.inputs) do sum = sum + NS.Village:GoodSell(i[1]) * i[2] end
                    if NS.Workshop.Value(r.id) <= sum then out[#out + 1] = r.id end
                end
            end
            return table.concat(out, ',') end)()""")
        self.assertEqual(bad, "")

    def test_orders_and_visitors_never_ask_for_equipment(self):
        self.lua.execute("NS.db.buildings.workshop = 7")
        self.assertFalse(self.ev("NS.Workshop:Offered('gw1')"))

    def test_equipping_adds_its_level_and_swapping_returns_the_old_piece(self):
        self.inn(mira=1, tobin=1)
        self.lua.execute("NS.db.goods.gw1 = 1; NS.db.goods.gw3 = 1; NS.db.goods.ga2 = 1")
        self.assertTrue(self.ev("(NS.Inn:Equip('mira', 'gw1'))"))
        self.assertEqual(self.ev("NS.Inn:GearPower('mira')"), 1)
        self.assertEqual(self.ev("NS.Inn:BestGear('mira', 'weapon')"), "gw3")
        self.assertTrue(self.ev("(NS.Inn:Equip('mira', 'gw3'))"))
        self.assertEqual(self.ev("NS.db.goods.gw1"), 1)
        self.assertIn("gear:3:mira", self.parts("ragefire", ["mira"]))
        # Tobin's Iron hands: each piece one level more
        self.assertTrue(self.ev("(NS.Inn:Equip('tobin', 'ga2'))"))
        self.assertEqual(self.ev("NS.Inn:GearPower('tobin')"), 3)
        self.assertTrue(self.ev("NS.Inn:Unequip('mira', 'weapon')"))
        self.assertEqual(self.ev("NS.db.goods.gw3"), 1)


class Consumables(Base):
    def test_a_potion_adds_10_and_is_spent(self):
        self.inn(mira=1)
        self.lua.execute("NS.db.goods.heal = 1")
        self.assertEqual(self.lua.eval("function() return (NS.Dungeons:Chance('ragefire', {'mira'}, {potion = 'heal'})) end")(), 95)
        self.lua.execute("NS.Rand = function() return 1 end; assert(NS.Dungeons:Send('ragefire', {'mira'}, {potion = 'heal'})); NS.Rand = nil")
        self.assertEqual(self.ev("NS.db.goods.heal"), 0)

    def test_food_gives_more_xp(self):
        self.inn(mira=1)
        plain = self.lua.eval("function() local _, _, x = NS.Dungeons:Reward('ragefire', {'mira'}, 100, -1); return x.mira end")()
        fed = self.lua.eval("function() local _, _, x = NS.Dungeons:Reward('ragefire', {'mira'}, 100, -1, {food = 'stew'}); return x.mira end")()
        self.assertGreater(fed, plain)

    def test_the_optional_boss_adds_a_threat_and_time(self):
        self.inn(mira=1)
        self.assertEqual(self.ev("#NS.Dungeons:Threats('ragefire', {boss = true})"), 3)
        self.assertEqual(self.ev("NS.Dungeons:Duration('ragefire', {'mira'}, {boss = true})"), 4500)


class Combos(Base):
    def test_each_combo_needs_two_followers_and_applies_its_effect(self):
        self.inn(mira=10, sela=10, garrick=10, elda=10)
        self.lua.execute("NS.db.dungeons.merit = 9; NS.Inn:Promote('sela', 2)")      # Sela takes Blizzard
        self.assertEqual(self.ev("NS.Dungeons:Combos({'mira', 'sela'})[1].id"), "crossfire")
        self.assertIn("combo:15:crossfire", self.parts("deadmines", ["mira", "sela"]))
        self.assertEqual(self.ev("#NS.Dungeons:Combos({'mira'})"), 0)
        # Wall and Mend: nobody comes back hurt
        self.lua.execute("local n = 0; NS.Rand = function() n = n + 1; return n == 1 and 9999 or 1 end")
        self.lua.execute("assert(NS.Dungeons:Send('deadmines', {'garrick', 'elda'})); NS.Rand = nil")
        self.assertFalse(self.ev("NS.db.trips[1].ok"))
        self.assertEqual(self.ev("#NS.db.trips[1].hurt"), 0)

    def test_the_book_learns_a_combo_once_when_the_group_comes_back(self):
        self.inn(mira=10, sela=10)
        self.lua.execute("NS.db.dungeons.merit = 9; NS.Inn:Promote('sela', 1)")      # Sela takes Fireball
        self.assertFalse(self.ev("NS.Dungeons:Known('crossfire')"))
        self.send("deadmines", ["mira", "sela"])
        self.assertFalse(self.ev("NS.Dungeons:Known('crossfire')"))
        self.lua.execute(f"NOW = NOW + {2 * HOUR}; NS.Inn:CollectAll()")
        self.assertTrue(self.ev("NS.Dungeons:Known('crossfire')"))


class Raid(Base):
    def test_onyxia_once_a_week_with_a_core_and_an_epic_insignia(self):
        self.inn(mira=30, tobin=30, elda=30, garrick=30, sela=30, bram=30)
        party = "{'mira', 'tobin', 'elda', 'garrick', 'sela', 'bram'}"
        self.lua.execute(f"NS.Rand = function() return 1 end; assert(NS.Dungeons:Send('onyxia', {party})); NS.Rand = nil")
        self.assertGreater(self.ev("NS.Dungeons:RaidLeft('onyxia')"), 0)
        self.lua.execute(f"NOW = NOW + {24 * HOUR}; NS.Inn:CollectAll()")
        self.assertEqual(self.ev("NS.Village:Good('core')"), 1)
        self.assertEqual(self.ev("NS.db.dungeons.epic"), 1)
        self.assertEqual(tuple(self.lua.eval(f"function() return NS.Dungeons:Send('onyxia', {party}) end")())[:2], (False, "raidWeek"))
        self.lua.execute(f"NOW = NOW + {6 * 24 * HOUR}")
        self.assertEqual(self.ev("NS.Dungeons:RaidLeft('onyxia')"), 0)


class Mastery(Base):
    def test_level_30_picks_a_mastery_and_a_title(self):
        self.inn(mira=29)
        self.assertFalse(self.ev("NS.Inn:Master('mira', 'veteran')"))
        self.lua.execute("NS.Inn:Get('mira').level = 30")
        self.assertTrue(self.ev("NS.Inn:Master('mira', 'veteran')"))
        self.assertFalse(self.ev("NS.Inn:Master('mira', 'mentor')"))
        self.assertIn("veteran:10:mira", self.parts("ragefire", ["mira"]))
        self.assertTrue(self.ev("NS.db.followers.mira.marks.title ~= nil"))


class Adventure(Base):
    def instance(self, name, kind="party", iid=36):
        self.lua.execute(f"function GetInstanceInfo() return [[{name}]], '{kind}', 1, '', 5, 0, false, {iid} end")

    def test_a_queue_opens_the_village_at_most_every_ten_minutes(self):
        self.lua.execute("QUEUED = false; function GetLFGMode() return QUEUED and 'queued' or nil end")
        self.lua.execute("QUEUED = true; Fire('LFG_UPDATE')")
        self.assertEqual(self.ev("NS.UI.view"), "village")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))
        self.lua.execute("KorumHomesteadFrame:Hide(); QUEUED = false; Fire('LFG_UPDATE'); NOW = NOW + 300; QUEUED = true; Fire('LFG_UPDATE')")
        self.assertFalse(self.ev("KorumHomesteadFrame:IsShown()"))
        self.lua.execute("QUEUED = false; Fire('LFG_UPDATE'); NOW = NOW + 301; QUEUED = true; Fire('LFG_UPDATE')")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))

    def test_a_boss_inspires_the_followers_there_and_does_not_add_up(self):
        self.inn(mira=5, tobin=5)
        self.instance("The Deadmines")
        self.lua.execute("Fire('ENCOUNTER_END', 1, 'Rhahk', 1, 5, 1)")
        self.assertEqual(self.ev("NS.db.adventure.inspired.deadmines"), 3)
        self.assertTrue(self.ev("NS.db.adventure.visited.deadmines"))
        self.assertIn("inspired:15:nil", self.parts("deadmines", ["mira", "tobin"]))
        self.lua.execute("Fire('BOSS_KILL', 1, 'Rhahk')")                      # the same fight: nothing more
        self.lua.execute("NOW = NOW + 120; Fire('ENCOUNTER_END', 2, 'Gilnid', 1, 5, 1)")
        self.assertEqual(self.ev("NS.db.adventure.inspired.deadmines"), 3)     # renews, never more than 3
        self.send("deadmines", ["mira", "tobin"])
        self.assertEqual(self.ev("NS.db.adventure.inspired.deadmines"), 2)

    def test_a_dungeon_of_the_forever_is_found_by_its_name(self):
        self.instance("Salão dos Thanes", iid=99999)
        self.assertEqual(self.ev("NS.Adventure:CurrentDungeon()"), "thanes")

    def test_a_lost_fight_or_the_setting_off_changes_nothing(self):
        self.instance("The Deadmines")
        self.lua.execute("Fire('ENCOUNTER_END', 1, 'Rhahk', 1, 5, 0)")
        self.assertIsNone(self.ev("NS.db.adventure.inspired.deadmines"))
        self.lua.execute("NS.db.adventure.on = false; Fire('ENCOUNTER_END', 1, 'Rhahk', 1, 5, 1)")
        self.assertIsNone(self.ev("NS.db.adventure.inspired.deadmines"))

    def test_a_raid_boss_gives_an_epic_insignia_once_a_week(self):
        self.instance("Onyxia's Lair", kind="raid", iid=249)
        self.lua.execute("Fire('ENCOUNTER_END', 1, 'Onyxia', 9, 40, 1)")
        self.assertEqual(self.ev("NS.db.dungeons.epic"), 1)
        self.lua.execute("NOW = NOW + 3600; Fire('ENCOUNTER_END', 1, 'Onyxia', 9, 40, 1)")
        self.assertEqual(self.ev("NS.db.dungeons.epic"), 1)


if __name__ == "__main__":
    unittest.main()
