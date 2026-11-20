"""S5: the roster with rooms and the Lodging, the followers that are found, the calls and the zones
(Dungeons.lua, Events.lua, Adventure.lua; docs/masmorras.md §3.5, §10 and §12)."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_dungeons as td  # noqa: E402

HOUR = 3600
RARES = ("lyra", "hoderik", "aldric", "fizzwick", "tazu")


class Base(td.Base):
    def rolls(self, *values):
        """The next rolls of the game, in order (1 = the lowest roll, 9999 = the highest); the last one repeats."""
        lua = "{" + ",".join(str(v) for v in values) + "}"
        self.lua.execute(f"local v, n = {lua}, 0; NS.Rand = function() n = n + 1; return v[math.min(n, #v)] end")

    def back(self):
        self.lua.execute(f"NS.Rand = nil; NOW = NOW + {30 * HOUR}; NS.Dungeons:CollectAll()")

    def call(self, kind, place, size=3, level=1):
        self.lua.execute(f"""CALL = NS.Events:Spawn('call'); CALL.call, CALL.place = '{kind}', '{place}'
            local d = CALL.def
            d.call, d.place, d.size, d.level, d.hours, d.mult = '{kind}', '{place}', {size}, {level}, 1, NS.Balance.CALLS.{kind}.mult
            d.threats, d.env = {{NS.Balance.PLACES.{place}.threats[1]}}, NS.Balance.PLACES.{place}.env""")
        return self.ev("CALL.def.id")


class Roster(Base):
    def test_the_six_come_with_the_inn_and_each_level_is_a_room(self):
        self.inn(level=3)
        self.assertEqual(self.ev("table.concat(NS.Inn:List(), ',')"), "mira,tobin,elda")
        self.assertEqual(self.ev("NS.Inn:Rooms()"), 3)
        self.assertEqual(self.ev("NS.Inn:Total()"), 18)
        self.assertFalse(self.ev("NS.Inn:Has('lyra')"))

    def test_someone_new_waits_in_the_lodging_when_the_rooms_are_full(self):
        self.inn(level=6)
        self.assertEqual(self.ev("NS.Inn:Welcome('lyra', 4)"), "new")
        self.assertTrue(self.ev("NS.Inn:Has('lyra')"))
        self.assertFalse(self.ev("NS.Inn:InRoom('lyra')"))
        self.assertEqual(self.ev("NS.Inn:Get('lyra').level"), 4)
        self.assertEqual(self.ev("NS.Inn:Arrivals()[1]"), "lyra")
        # the seventh level of the Inn is a free room
        self.lua.execute("NS.db.buildings.inn = 7")
        self.assertEqual(self.ev("NS.Inn:Welcome('aldric', 1)"), "new")
        self.assertTrue(self.ev("NS.Inn:InRoom('aldric')"))

    def test_only_who_is_in_a_room_goes_out(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.Inn:Welcome('lyra', 5)")
        self.assertFalse(self.ev("NS.Dungeons:Free('lyra')"))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons:Send('deadmines', {'lyra'}) end")())[:2], (False, "busy"))
        self.assertNotIn("lyra", self.ev("table.concat(NS.Dungeons:Suggest('deadmines'), ',')"))

    def test_moving_and_swapping_ask_for_both_at_home(self):
        self.inn(level=6, mira=5, tobin=5)
        self.lua.execute("NS.Inn:Welcome('lyra', 5)")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Move('lyra', true) end")()), (False, "noRoom"))
        self.assertTrue(self.ev("(NS.Inn:Swap('bram', 'lyra'))"))
        self.assertTrue(self.ev("NS.Inn:InRoom('lyra')"))
        self.assertFalse(self.ev("NS.Inn:InRoom('bram')"))
        self.send("deadmines", ["mira", "tobin"])
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Swap('mira', 'bram') end")()), (False, "away"))
        self.assertTrue(self.ev("(NS.Inn:Move('lyra', false))"))
        self.assertTrue(self.ev("(NS.Inn:Move('bram', true))"))

    def test_the_lodging_tells_when_someone_there_would_help_more(self):
        self.inn(level=6, mira=3, tobin=3, elda=3, garrick=3, sela=3, bram=3)
        self.lua.execute("NS.Inn:Welcome('aldric', 3)")           # Unholy Light counters the undead of Lordaeron
        # Shadowfang: the undead and Hostile magic; Sela answers the magic, nobody in the rooms answers the undead
        who = self.lua.eval("function() return NS.Dungeons:LodgeHint('shadowfang', {'sela'}) end")()
        self.assertEqual(who[0], "aldric")

    def test_one_the_village_already_has_becomes_an_insignia(self):
        self.inn(level=6)
        self.lua.execute("NS.Inn:Welcome('lyra', 1); NS.Inn:Welcome('corvo', 1)")
        self.assertEqual(self.ev("NS.Inn:Welcome('lyra', 1)"), "merit")
        self.assertEqual(self.ev("NS.Inn:Welcome('corvo', 1)"), "epic")
        self.assertEqual((self.ev("NS.db.dungeons.merit"), self.ev("NS.db.dungeons.epic")), (1, 1))

    def test_the_ranking_is_by_power(self):
        self.inn(level=6, mira=10, tobin=12)
        self.lua.execute("NS.Inn:Welcome('ilyanna', 1); NS.db.goods.gw3 = 1; NS.Inn:Equip('mira', 'gw3')")
        # Ilyanna: 10 + 150 (Legendary); Tobin: 120; Mira: 100 + 3 x 5
        self.assertEqual(self.ev("NS.Inn:Power('ilyanna')"), 160)
        self.assertEqual(self.ev("NS.Inn:Power('mira')"), 115)
        order = self.ev("(function() local o = {} for i, r in ipairs(NS.Inn:Ranking()) do o[i] = r.id end return table.concat(o, ',') end)()")
        self.assertTrue(order.startswith("ilyanna,tobin,mira"), order)


class Found(Base):
    def test_they_come_with_their_abilities_and_from_their_place(self):
        self.inn(level=7)
        for fid in RARES + ("elandor", "faelan", "corvo", "brakka", "ilyanna", "hargrim", "shalendra"):
            self.lua.execute(f"NS.Inn:Welcome('{fid}', 1)")
            self.assertTrue(self.ev(f"NS.Inn.Def('{fid}').from ~= nil"))
        self.assertEqual(self.ev("table.concat(NS.Inn:Abilities('lyra'), ',')"), "gust,lightstep")
        self.assertEqual(self.ev("NS.Inn:Get('corvo').quality"), "epic")
        # a Rare by birth has nothing to pick at Rare; an Epic by birth picks its trait at once
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:NextQuality('lyra') end")()), ("epic", False))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:NextQuality('corvo') end")()), ("epic", True))
        self.assertTrue(self.ev("NS.Inn:Promote('corvo', 1)"))
        self.assertEqual(self.ev("NS.db.dungeons.epic"), 0)

    def test_a_legendary_ability_counters_two_threats(self):
        self.inn(level=7)
        self.lua.execute("NS.Inn:Welcome('ilyanna', 1)")
        # Ragefire: Horde and Hostile magic; the Storm of Zephras answers both
        self.assertEqual(self.parts("ragefire", ["ilyanna"]), "")
        self.assertEqual(self.chance("ragefire", ["ilyanna"]), 100)

    def test_teleport_makes_the_run_shorter(self):
        self.inn(level=7)
        self.lua.execute("NS.Inn:Welcome('elandor', 1)")
        self.assertEqual(self.ev("NS.Dungeons:Duration('ragefire', {'elandor'})"), int(HOUR * 0.8))

    def test_a_dungeon_only_gives_who_is_from_it(self):
        self.inn(level=6, mira=5, tobin=5)
        self.rolls(1)                                        # every roll the lowest: still nobody is from the Deadmines
        self.assertTrue(self.ev("(NS.Dungeons:Send('deadmines', {'mira', 'tobin'}))"))
        self.assertIsNone(self.ev("NS.db.trips[1].newcomer"))

    def test_the_hall_of_thanes_gives_hoderik_and_rarely_the_thane(self):
        self.inn(level=6, mira=5)
        # the rolls: success, trophy, someone new, the Legendary share (missed), who
        self.rolls(1, 1, 1, 9999, 1)
        self.assertTrue(self.ev("(NS.Dungeons:Send('thanes', {'mira'}))"))
        self.assertEqual(self.ev("NS.db.trips[1].newcomer"), "hoderik")
        self.back()
        self.assertTrue(self.ev("NS.Inn:Has('hoderik')"))
        self.assertEqual(self.ev("NS.Inn:Get('hoderik').level"), 2)       # the level of the place
        self.rolls(1)
        self.assertTrue(self.ev("(NS.Dungeons:Send('thanes', {'mira'}))"))
        self.assertEqual(self.ev("NS.db.trips[1].newcomer"), "hargrim")

    def test_after_40_dungeons_with_nobody_new_the_next_success_brings_a_rare(self):
        self.inn(level=6, mira=5, tobin=5)
        self.lua.execute("NS.db.dungeons.dry = 39")
        self.rolls(1, 9999)                                  # a success; every other roll misses
        self.assertTrue(self.ev("(NS.Dungeons:Send('deadmines', {'mira', 'tobin'}))"))
        self.assertIn(self.ev("NS.db.trips[1].newcomer"), RARES)
        self.assertEqual(self.ev("NS.db.dungeons.dry"), 0)

    def test_with_every_rare_the_guarantee_is_a_merit_insignia(self):
        self.inn(level=6, mira=5, tobin=5)
        for fid in RARES:
            self.lua.execute(f"NS.Inn:Welcome('{fid}', 1)")
        self.lua.execute("NS.db.dungeons.dry = 39")
        self.rolls(1, 9999)
        self.assertTrue(self.ev("(NS.Dungeons:Send('deadmines', {'mira', 'tobin'}))"))
        self.assertIsNone(self.ev("NS.db.trips[1].newcomer"))
        self.assertEqual(self.ev("NS.db.trips[1].drops[1]"), "merit")

    def test_a_failure_never_brings_anyone(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.db.dungeons.dry = 80")
        self.rolls(9999, 1)
        self.assertTrue(self.ev("(NS.Dungeons:Send('thanes', {'mira'}))"))
        self.assertFalse(self.ev("NS.db.trips[1].ok"))
        self.assertIsNone(self.ev("NS.db.trips[1].newcomer"))

    def test_onyxia_may_bring_the_elder_and_a_piece_with_a_name(self):
        self.inn(level=6, mira=30, tobin=30, elda=30, garrick=30, sela=30, bram=30)
        self.rolls(1)
        self.assertTrue(self.ev("(NS.Dungeons:Send('onyxia', {'mira', 'tobin', 'elda', 'garrick', 'sela', 'bram'}))"))
        self.assertEqual(self.ev("NS.db.trips[1].newcomer"), "ilyanna")
        self.assertEqual(self.ev("NS.db.trips[1].named"), "quelserrar")
        self.back()
        self.assertEqual(self.ev("NS.Inn:Get('ilyanna').level"), 30)
        self.assertEqual(self.ev("NS.Village:Good('quelserrar')"), 1)
        # the piece with a name is worn like any other, and is the best there is
        self.assertEqual(self.ev("NS.Inn:BestGear('mira', 'weapon')"), "quelserrar")
        self.assertTrue(self.ev("(NS.Inn:Equip('mira', 'quelserrar'))"))
        self.assertEqual(self.ev("NS.Inn:GearPower('mira')"), 9)
        lines = self.ev("table.concat(NS.Journal:Lines(NS.Journal:Latest()), ' ')")
        self.assertIn("Ilyanna decided to stay", lines)
        self.assertIn("Quel'Serrar", lines)


class Calls(Base):
    def test_no_call_without_a_follower_in_a_room(self):
        for _ in range(200):
            self.assertNotEqual(self.ev("NS.Events:Spawn().kind"), "call")
            self.lua.execute("NS.db.events.open = {}")

    def test_every_call_is_of_a_place_and_fits_the_followers(self):
        self.inn(level=6, mira=12, tobin=12, elda=12)
        kinds = set()
        for _ in range(300):
            self.lua.execute("NS.db.events.open = {}; CALL = NS.Events:Spawn('call')")
            kind, place = self.ev("CALL.call"), self.ev("CALL.place")
            kinds.add(kind)
            self.assertIsNotNone(self.ev(f"NS.Balance.PLACES.{place}"))
            self.assertTrue(9 <= self.ev("CALL.def.level") <= 12)
            self.assertTrue(1 <= self.ev("CALL.def.size") <= 3)
            self.assertTrue(self.ev("#CALL.def.threats >= 1"))
            if kind == "rescue":
                self.assertIn(place, ("zephras", "drowned", "alcaz", "blackmaw"))
            if kind == "recon":
                self.assertNotEqual(place, "zephras")
            self.assertEqual(self.ev("NS.Dungeons.Get(CALL.def.id).place"), place)
        self.assertEqual(kinds, {"defense", "attack", "escort", "rescue", "recon"})

    def test_a_group_answers_and_the_call_leaves_the_visitors(self):
        self.inn(level=6, mira=5, tobin=5)
        cid = self.call("defense", "thanes", size=2, level=5)
        self.assertEqual(self.ev(f"NS.Dungeons.Name('{cid}')"), "Defense · Hall of Thanes")
        self.rolls(1)
        self.assertTrue(self.ev(f"(NS.Dungeons:Send('{cid}', {{'mira', 'tobin'}}))"))
        self.assertEqual(self.ev("#NS.Events:Open()"), 0)
        self.assertEqual(self.ev("NS.db.trips[1].call.place"), "thanes")
        self.assertEqual(self.ev("(NS.Inn:State('mira'))"), "away")
        coins = self.ev("NS.db.coins")
        self.back()
        self.assertGreater(self.ev("NS.db.coins"), coins)
        self.assertIn("answered a defense call at Hall of Thanes", self.ev("NS.Journal:Lines(NS.Journal:Latest())[1]"))
        self.assertEqual(self.ev("NS.db.dungeons.runs"), 0)      # a call is not a dungeon of the count

    def test_a_call_pays_more_than_a_dungeon_but_under_the_cap(self):
        self.inn(level=6, mira=30, tobin=30, elda=30)
        self.lua.execute("NS.db.level = 60; NS.db.buildings.garden = 7")
        cid = self.call("attack", "kroldok", size=3, level=30)
        self.lua.execute("CALL.def.hours = 2")
        party = "{'mira', 'tobin', 'elda'}"
        paid = self.lua.eval(f"function() return (NS.Dungeons:Reward('{cid}', {party}, 150)) end")()
        self.lua.execute("CALL.def.mult = nil")
        plain = self.lua.eval(f"function() return (NS.Dungeons:Reward('{cid}', {party}, 150)) end")()
        cap = self.ev("NS.Balance.GardenIncome(60, NS.Village:Plots()) * NS.Balance.EVENTS.capMinutes / 60")
        self.assertGreater(paid, plain)
        self.assertLessEqual(paid - plain, cap + 1)

    def test_a_rescue_may_bring_who_was_saved(self):
        self.inn(level=6, mira=5, tobin=5)
        cid = self.call("rescue", "zephras", size=2, level=5)
        self.rolls(1)
        self.assertTrue(self.ev(f"(NS.Dungeons:Send('{cid}', {{'mira', 'tobin'}}))"))
        self.assertEqual(self.ev("NS.db.trips[1].newcomer"), "lyra")
        self.back()
        self.assertTrue(self.ev("NS.Inn:Has('lyra')"))
        self.assertEqual(self.ev("NS.Inn:Get('lyra').level"), 5)

    def test_an_escort_brings_a_caravan_to_the_village(self):
        self.inn(level=6, mira=5)
        cid = self.call("escort", "excavation", size=1, level=5)
        self.rolls(1)
        self.assertTrue(self.ev(f"(NS.Dungeons:Send('{cid}', {{'mira'}}))"))
        self.back()
        self.assertEqual(self.ev("NS.Events:Open()[1].kind"), "caravan")

    def test_a_reconnaissance_gives_no_coins_and_10_on_the_next_run_there(self):
        self.inn(level=6, mira=5, sela=5)
        cid = self.call("recon", "lordaeron", size=1, level=3)
        self.assertEqual(self.lua.eval(f"function() return (NS.Dungeons:Reward('{cid}', {{'mira'}}, 100)) end")(), 0)
        self.rolls(1)
        self.assertTrue(self.ev(f"(NS.Dungeons:Send('{cid}', {{'mira'}}))"))
        self.back()
        self.assertIn("scout:10:nil", self.parts("lordaeron", ["sela"]))
        self.send("lordaeron", ["sela"])
        self.back()
        self.assertNotIn("scout", self.parts("lordaeron", ["sela"]))

    def test_a_call_nobody_answers_just_goes_away(self):
        self.inn(level=6, mira=5)
        self.call("defense", "thanes")
        coins = self.ev("NS.db.coins")
        self.lua.execute(f"NOW = NOW + {4 * HOUR}; NS.Events:Update()")
        self.assertEqual(self.ev("#NS.Events:Open() == 0 or NS.Events:Open()[1].id ~= CALL.id"), True)
        self.assertEqual(self.ev("NS.Events:Missed()[1]"), "call")
        self.assertEqual(self.ev("NS.db.coins"), coins)

    def test_the_visitors_screen_shows_a_call_and_opens_the_inn(self):
        self.inn(level=6, mira=5, tobin=5)
        self.call("rescue", "alcaz", size=2, level=5)
        self.open("visitors")
        card = "NS.UI.screens.visitors.cards[1]"
        self.assertEqual(self.ev(card + ".title:GetText()"), "Rescue · Alcaz Island Prison")
        self.lua.execute(f"NS.UI.screens.visitors:Act({card})")
        self.assertEqual(self.ev("NS.UI.view"), "inn")
        self.assertEqual(self.ev("NS.UI.innDungeon"), self.ev("CALL.def.id"))


class Zones(Base):
    def zone(self, name):
        self.lua.execute(f"function GetRealZoneText() return [[{name}]] end; Fire('ZONE_CHANGED_NEW_AREA')")

    def test_a_zone_counts_after_five_minutes_in_a_row(self):
        self.zone("Wetlands")
        self.assertEqual(self.ev("NS.Adventure:Zone()"), "excavation")
        self.lua.execute("NOW = NOW + 200")
        self.assertIsNone(self.ev("NS.Adventure:Here()"))
        self.zone("Ironforge")                               # left: the clock starts again
        self.zone("Wetlands")
        self.lua.execute("NOW = NOW + 200")
        self.assertIsNone(self.ev("NS.Adventure:Here()"))
        self.assertIsNone(self.ev("NS.db.adventure.zones.excavation"))
        self.lua.execute("NOW = NOW + 101")
        self.assertEqual(self.ev("NS.Adventure:Here()"), "excavation")
        self.assertTrue(self.ev("NS.db.adventure.zones.excavation"))

    def test_the_names_of_the_portuguese_client_count_too(self):
        self.zone("Pantanal")
        self.assertEqual(self.ev("NS.Adventure:Zone()"), "excavation")
        self.zone("Elwynn Forest")
        self.assertIsNone(self.ev("NS.Adventure:Zone()"))

    def test_the_place_comes_first_once_every_two_hours_and_the_others_wait_thirty_minutes(self):
        self.zone("Wetlands")
        self.lua.execute("NOW = NOW + 301")
        self.assertEqual(self.ev("NS.Adventure:CallPlace()"), "excavation")
        self.lua.execute("NOW = NOW + 3600")
        self.assertIsNone(self.ev("NS.Adventure:CallPlace()"))          # the same zone, before two hours
        self.zone("Azshara")
        self.lua.execute("NOW = NOW + 301")
        self.assertEqual(self.ev("NS.Adventure:CallPlace()"), "blackmaw")
        self.zone("Ironforge")
        self.lua.execute("NOW = NOW + 301")
        self.assertIsNone(self.ev("NS.Adventure:CallPlace()"))          # another zone, before thirty minutes
        self.lua.execute("NOW = NOW + 1800")
        self.assertEqual(self.ev("NS.Adventure:CallPlace()"), "thanes")

    def test_entering_a_zone_never_makes_an_event(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.db.events.nextAt = NOW + 99999")
        for name in ("Wetlands", "Azshara", "Ironforge", "Wetlands"):
            self.zone(name)
            self.lua.execute("NOW = NOW + 400; NS.Events:Update()")
        self.assertEqual(self.ev("#NS.Events:Open()"), 0)

    def test_the_call_drawn_while_the_character_is_there_is_of_that_place(self):
        self.inn(level=6, mira=5)
        self.zone("Azshara")
        self.lua.execute("NOW = NOW + 301")
        self.assertEqual(self.ev("NS.Events:Spawn('call').place"), "blackmaw")

    def test_the_setting_off_ignores_the_zones(self):
        self.lua.execute("NS.db.adventure = {on = false}")
        self.zone("Wetlands")
        self.lua.execute("NOW = NOW + 400")
        self.assertIsNone(self.ev("NS.Adventure:Here()"))

    def test_a_raid_boss_gives_luck_for_the_next_raid_of_the_followers(self):
        self.lua.execute("function GetInstanceInfo() return [[Onyxia's Lair]], 'raid', 1, '', 40, 0, false, 249 end")
        self.lua.execute("Fire('ENCOUNTER_END', 1, 'Onyxia', 9, 40, 1)")
        self.assertTrue(self.ev("NS.db.adventure.raidLuck"))
        self.inn(level=6, mira=30, tobin=30, elda=30, garrick=30, sela=30, bram=30)
        # the rolls: success, trophy, someone new at 12% (a roll of 10% passes only with the luck)
        self.rolls(1, 9999, 1000, 9999)
        self.assertTrue(self.ev("(NS.Dungeons:Send('onyxia', {'mira', 'tobin', 'elda', 'garrick', 'sela', 'bram'}))"))
        self.assertEqual(self.ev("NS.db.trips[1].newcomer"), "ilyanna")
        self.assertIsNone(self.ev("NS.db.adventure.raidLuck"))


class Work(Base):
    def test_a_follower_at_the_mine_adds_10_and_a_miner_25(self):
        self.inn(level=6)
        self.lua.execute("NS.db.buildings.mine = 4; NS.db.buildings.pond = 4")
        base = self.ev("NS.Village:Rate('mine')")
        self.assertTrue(self.ev("(NS.Inn:Work('mira', 'mine'))"))
        self.assertAlmostEqual(self.ev("NS.Village:Rate('mine')"), base * 1.10)
        self.assertTrue(self.ev("(NS.Inn:Work('tobin', 'mine'))"))           # Tobin is a Miner; Mira leaves the place
        self.assertAlmostEqual(self.ev("NS.Village:Rate('mine')"), base * 1.25)
        self.assertIsNone(self.ev("NS.Inn:Working('mira')"))
        self.assertAlmostEqual(self.ev("NS.Village:Rate('pond')"), self.ev("NS.Village:Rate('pond', 4)"))
        # what a level would make (the Hall, the Guide) is the plain number
        self.assertEqual(self.ev("NS.Village:Rate('mine', 4)"), base)

    def test_who_works_does_not_go_out_and_one_follower_has_one_place(self):
        self.inn(level=6, mira=5, bram=5)
        self.lua.execute("NS.db.buildings.mine = 4; NS.db.buildings.pond = 4")
        self.assertTrue(self.ev("(NS.Inn:Work('bram', 'pond'))"))
        self.assertFalse(self.ev("NS.Dungeons:Free('bram')"))
        self.assertNotIn("bram", self.ev("table.concat(NS.Dungeons:Suggest('deadmines'), ',')"))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Dungeons:Send('deadmines', {'bram'}) end")())[:2], (False, "busy"))
        self.assertTrue(self.ev("(NS.Inn:Work('bram', 'mine'))"))
        self.assertIsNone(self.ev("NS.Inn:Worker('pond')"))
        self.assertTrue(self.ev("NS.Inn:Rest('mine')"))
        self.assertTrue(self.ev("NS.Dungeons:Free('bram')"))

    def test_someone_away_can_not_start_working(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.db.buildings.mine = 4")
        self.send("ragefire", ["mira"])
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Work('mira', 'mine') end")()), (False, "away"))
        self.lua.execute("NS.db.buildings.pond = 0")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Work('tobin', 'pond') end")()), (False, "nothing"))

    def test_what_was_made_before_is_counted_at_the_old_pace(self):
        self.inn(level=6)
        self.lua.execute("NS.db.buildings.mine = 4; NS.db.buildings.barn = 7; NS.db.goods.ore = 0; NS.Village:Produce()")
        rate = self.ev("NS.Village:Rate('mine')")
        self.lua.execute(f"NOW = NOW + {HOUR}; NS.Inn:Work('tobin', 'mine')")       # one hour alone, then the Miner comes
        self.assertEqual(self.ev("NS.Village:Good('ore')"), rate)
        self.lua.execute(f"NOW = NOW + {HOUR}; NS.Inn:Rest('mine')")
        self.assertEqual(self.ev("NS.Village:Good('ore')"), rate + int(rate * 1.25))

    def test_the_best_for_the_place_comes_first_and_the_lodging_before_the_rooms(self):
        self.inn(level=6)
        self.lua.execute("NS.db.buildings.mine = 4; NS.Inn:Welcome('fizzwick', 1); NS.Inn:Welcome('lyra', 1)")
        order = self.ev("(function() local o = {} for i, c in ipairs(NS.Inn:Workers('mine')) do o[i] = c.id end return table.concat(o, ',') end)()")
        self.assertTrue(order.startswith("fizzwick,tobin,lyra,mira"), order)

    def test_the_screen_of_the_mine_gives_the_place_with_a_click(self):
        self.inn(level=6)
        self.lua.execute("NS.db.buildings.mine = 4")
        self.open("mine")
        s = "NS.UI.screens.mine"
        self.assertEqual(self.ev(s + ".work.rows[1].fid"), "tobin")
        self.assertEqual(self.ev(s + ".rate:GetText()"), "24 ore an hour")
        self.press(s + ".work.rows[1]")
        self.assertEqual(self.ev("NS.Inn:Worker('mine')"), "tobin")
        self.assertEqual(self.ev(s + ".rate:GetText()"), "30 ore an hour")
        self.assertEqual(self.ev(s + ".work.now:GetText()"), "Tobin works here: +25% made.")
        self.press(s + ".work.stop")
        self.assertIsNone(self.ev("NS.Inn:Worker('mine')"))


class Screens(Base):
    def test_the_ranking_moves_and_swaps_followers(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.Inn:Welcome('lyra', 9); NS.Inn:Greeted('lyra'); NS.UI.innTab = 'ranking'")
        self.open("inn")
        s = "NS.UI.screens.inn"
        self.assertEqual(self.ev(s + ".rrows[1].fid"), "lyra")              # the strongest first
        self.assertEqual(self.ev(s + ".sub:GetText()"), "7 of the 18 followers of the game. Rooms: 6 of 6.")
        self.press(s + ".rrows[1].button")                                  # no free room: pick who leaves
        self.assertEqual(self.ev("NS.UI.innSwap"), "lyra")
        self.press(s + ".rrows[2].button")
        self.assertTrue(self.ev("NS.Inn:InRoom('lyra')"))
        self.assertIsNone(self.ev("NS.UI.innSwap"))

    def test_the_chance_of_the_list_is_the_chance_of_the_run(self):
        """Seen in the game on 19/11: the list said 89% and the run 64%, because the optional boss of another dungeon
        was still on."""
        self.inn(level=3, mira=3, tobin=3, elda=1)
        self.lua.execute("NS.UI.innTab = 'dungeons'; NS.UI.innOpts = {boss = true}")
        self.open("inn")
        s = "NS.UI.screens.inn"
        listed = self.ev(s + ".drows[1].chance:GetText()")
        self.press(s + ".drows[1]")
        self.assertIsNone(self.ev("NS.UI.innOpts and NS.UI.innOpts.boss"))
        # nobody picked: each free follower shows the chance it gives alone, and the best is the one of the list
        self.assertEqual(self.ev(s + ".run.free[1].gain:GetText()"), listed)
        self.press(s + ".run.free[1]")
        self.assertEqual(self.ev(s + ".run.chance:GetText()"), listed)
        # the group is full: the others add nothing, so they show nothing
        self.assertEqual(self.ev(s + ".run.free[1].gain:GetText()"), "")

    def test_someone_new_is_greeted_with_a_card(self):
        self.inn(level=6, mira=5)
        self.lua.execute("NS.Inn:Welcome('aldric', 3)")
        self.open("inn")
        s = "NS.UI.screens.inn"
        self.assertTrue(self.ev(s + ".arrive:IsShown()"))
        self.press(s + ".arrive.card.ok")
        self.assertFalse(self.ev(s + ".arrive:IsShown()"))
        self.assertEqual(self.ev("#NS.Inn:Arrivals()"), 0)

    def test_every_new_follower_has_its_texts_in_both_languages(self):
        missing = self.lua.eval("""(function() local out = {}
            for _, lang in ipairs({'enUS', 'ptBR'}) do
                local L = NS.L[lang]
                for _, def in ipairs(NS.Balance.FOLLOWERS) do
                    for _, key in ipairs({'fol_', 'fcl_', 'ttl_'}) do
                        if not L[key .. def.id] then out[#out + 1] = lang .. ':' .. key .. def.id end
                    end
                    if def.from and not L['from_' .. def.id] then out[#out + 1] = lang .. ':from_' .. def.id end
                end
                for ab in pairs(NS.Balance.ABILITIES) do
                    if not L['ab_' .. ab] then out[#out + 1] = lang .. ':ab_' .. ab end
                end
                for place in pairs(NS.Balance.PLACES) do
                    for _, key in ipairs({'pl_', 'plw_'}) do
                        if not L[key .. place] then out[#out + 1] = lang .. ':' .. key .. place end
                    end
                end
                for _, kind in ipairs(NS.Balance.CALLS.order) do
                    for _, key in ipairs({'call_', 'calld_', 'j_call_'}) do
                        if not L[key .. kind] then out[#out + 1] = lang .. ':' .. key .. kind end
                    end
                end
            end
            return table.concat(out, ' ') end)()""")
        self.assertEqual(missing, "")


if __name__ == "__main__":
    unittest.main()
