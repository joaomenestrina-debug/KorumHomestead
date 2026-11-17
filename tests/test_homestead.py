"""Korum Homestead: the farm rules (plots, growth by the clock, harvest, selling, orders, level) and the window."""
import os
import pathlib
import re
import sys
import time
import unittest

from lupa import lua51

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from client_mock import CLIENT  # noqa: E402  (frames, print, timers)

HOME = pathlib.Path(__file__).resolve().parent.parent          # the addon is the root of this repository
FILES = [line.strip() for line in (HOME / "KorumHomestead.toc").read_text(encoding="utf-8").splitlines()
         if line.strip().endswith(".lua")]


FIXTURES = pathlib.Path(__file__).resolve().parent / "fixtures"


class Homestead(unittest.TestCase):
    SAVED = None            # the text of a SavedVariables file to start from (a save of an older version); None = new

    def setUp(self):
        lua = self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        lua.execute(CLIENT)
        lua.execute("""
            -- what the window needs from a frame beyond the shared mock: sizes, scripts and alpha that can be read back
            local Frame = getmetatable(UIParent)
            function Frame:GetScript(k) return self._scripts[k] end
            function Frame:SetSize(w, h) self._w, self._h = w, h end
            function Frame:SetWidth(w) self._w = w end
            function Frame:SetHeight(h) self._h = h end
            function Frame:GetWidth() return self._w end
            function Frame:GetHeight() return self._h end
            function Frame:SetAlpha(a) self._alpha = a end
            function Frame:GetAlpha() return self._alpha or 1 end
            UIParent:SetSize(1024, 768)
            UISpecialFrames = {}
            NOW = 1000000
            function time() return NOW end
            function GetLocale() return "enUS" end
            function GetCursorPosition() return 0, 0 end
            function atan2(y, x) return math.atan(y / x) end
            math.atan2 = math.atan2 or function(y, x) return math.atan(y / x) end
            IconDB = {}
            C_Item = {GetItemNameByID = function(id) return IconDB[id] end, GetItemIconByID = function(id) return 12345 end}
            math.randomseed(7)
            NS = {}
            function LoadAddon(path)
                local f = assert(io.open(path, "rb")); local src = f:read("*a"); f:close()
                assert(loadstring(src, "@" .. path))("KorumHomestead", NS)
            end
        """)
        if self.SAVED:
            lua.execute(self.SAVED)
        for f in FILES:
            lua.execute(f"LoadAddon([[{HOME / f}]])")
        lua.execute("""
            Fire("ADDON_LOADED", "KorumHomestead")
            Fire("PLAYER_LOGIN")
        """)

    def ev(self, code):
        return self.lua.eval(code)

    def test_a_new_homestead_has_two_plots_and_a_little_money(self):
        self.assertEqual(self.ev("NS.db.nplots"), 2)
        self.assertEqual(self.ev("NS.db.coins"), 40)
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "empty")
        self.assertEqual(self.ev("(NS.Farm:Status(3))"), "locked")

    def test_planting_costs_the_seed_and_grows_by_the_clock(self):
        self.assertTrue(self.ev("NS.Farm:Plant(1, 2447)"))
        self.assertEqual(self.ev("NS.db.coins"), 36)
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "growing")
        self.lua.execute("NOW = NOW + 20")
        status, progress, left = self.lua.eval("function() return NS.Farm:Status(1) end")()
        self.assertEqual(status, "growing")
        self.assertAlmostEqual(progress, 20 / 45, places=3)
        self.assertEqual(left, 25)
        self.lua.execute("NOW = NOW + 999999")                       # hours away from the game: it just waits, ready
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "ready")

    def test_harvest_fills_the_barn_and_gives_xp(self):
        self.lua.execute("NS.Farm:Plant(1, 2447); NOW = NOW + 60")
        self.assertEqual(self.ev("NS.Farm:Harvest(1)"), 3)
        self.assertEqual(self.ev("NS.db.crops[2447]"), 3)
        self.assertEqual(self.ev("NS.db.xp"), self.ev("NS.Data.Plant(2447).xp"))   # a little: herbs give little xp
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "empty")
        self.assertEqual(self.ev("NS.Farm:Harvest(1)"), 0)           # nothing there

    def test_the_rules_say_why_a_plant_is_refused(self):
        ok, why = self.lua.eval("function() return NS.Farm:Plant(1, 3821) end")()    # level 15
        self.assertFalse(ok)
        self.assertEqual(why, "level")
        self.lua.execute("NS.db.level = NS.Data.Plant(3821).level; NS.db.coins = 1")
        ok, why = self.lua.eval("function() return NS.Farm:Plant(1, 3821) end")()
        self.assertEqual(why, "coins")
        self.lua.execute("NS.db.coins = 100; NS.Farm:Plant(1, 2447)")
        ok, why = self.lua.eval("function() return NS.Farm:Plant(1, 2447) end")()
        self.assertEqual(why, "notEmpty")

    def test_leveling_up_unlocks_seeds(self):
        self.lua.execute("NS.Farm:AddXP(NS.Data.XPToNext(1))")
        self.assertEqual(self.ev("NS.db.level"), 2)
        self.assertEqual(self.ev("NS.db.xp"), 0)
        self.lua.execute("NS.Farm:AddXP(100000000)")
        self.assertEqual(self.ev("NS.db.level"), 60)                  # the cap: the level of the Village
        self.lua.execute("NS.db.daily.rare = 0; NS.Farm:AddXP(NS.Balance.HERBALISM.lotusXP * 2 + 5)")
        self.assertEqual(self.ev("NS.db.daily.rare"), 2)              # at the cap the xp becomes Black Lotus
        self.assertEqual(self.ev("NS.db.capXP"), 5)

    def test_selling_turns_the_barn_into_coins(self):
        self.lua.execute("NS.db.crops[2447] = 5; NS.db.crops[765] = 2")
        a, b = self.ev("NS.Data.Plant(2447).sell"), self.ev("NS.Data.Plant(765).sell")
        self.assertEqual(self.ev("NS.Farm:Sell(2447, 2)"), 2 * a)
        self.assertEqual(self.ev("NS.db.crops[2447]"), 3)
        self.assertEqual(self.ev("NS.Farm:SellAll()"), 3 * a + 2 * b)
        self.assertIsNone(self.ev("NS.db.crops[2447]"))
        self.assertEqual(self.ev("NS.db.stats.earned"), 5 * a + 2 * b)

    # ------------------------------------------------------------------ the village
    def up(self, building):
        return tuple(self.lua.eval(f"function() return NS.Village:CanUpgrade('{building}') end")())[:2]

    def test_the_mine_and_the_pond_are_lots_until_the_hall_grows(self):
        self.lua.execute("NS.db.coins = 10000")
        self.assertEqual(self.ev("NS.Village:Level('mine')"), 0)
        self.assertEqual(tuple(self.lua.eval("function() return NS.Village:CanUpgrade('mine') end")()), (False, "hall", 2))
        self.assertEqual(tuple(self.lua.eval("function() return NS.Village:CanUpgrade('pond') end")()), (False, "hall", 3))
        self.lua.execute("NS.db.buildings.hall = 2")
        self.assertTrue(self.ev("(NS.Village:Upgrade('mine'))"))
        self.assertEqual(self.ev("NS.db.coins"), 10000 - 200)
        self.lua.execute("NOW = NOW + 300")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Village:Update() end")()), ("mine", 1))

    def test_the_mine_makes_ore_by_the_hour_until_the_barn_is_full(self):
        self.lua.execute("NS.db.buildings.mine = 2; NS.Village:Update()")       # 12 an hour
        self.assertEqual(self.ev("NS.Village:Rate('mine')"), 12)
        self.lua.execute("NOW = NOW + 1800; NS.Village:Update()")
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 6)
        self.lua.execute("NOW = NOW + 150; NS.Village:Update()")                # half a unit: nothing yet, nothing lost
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 6)
        self.lua.execute("NOW = NOW + 150; NS.Village:Update()")
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 7)
        self.lua.execute("NOW = NOW + 86400 * 3; NS.Village:Update()")          # days away: it stops at what the Barn holds
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 40)
        self.lua.execute("NS.db.goods.ore = 0; NOW = NOW + 300; NS.Village:Update()")
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 1)                  # no time was owed from the full days

    def test_bigger_works_ask_for_ore_and_goods_can_be_sold(self):
        self.lua.execute("NS.db.coins = 10000; NS.db.buildings.hall = 2")
        self.assertEqual(self.ev("NS.Village:Next('hall').ore"), 10)            # level 3
        self.assertEqual(tuple(self.lua.eval("function() return NS.Village:CanUpgrade('hall') end")()), (False, "ore", 10))
        self.lua.execute("NS.db.goods.ore = 14; NS.db.goods.fish = 4")
        self.assertTrue(self.ev("(NS.Village:Upgrade('hall'))"))
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 4)
        self.assertEqual(self.ev("NS.Village:Next('mine').ore"), 0)             # the Mine never asks for ore
        coins = self.ev("NS.db.coins")
        self.assertEqual(self.ev("NS.Village:SellGood('fish')"), 20)
        self.assertEqual(self.ev("NS.Village:SellGood('ore', 1)"), 6)
        self.assertEqual(self.ev("NS.db.coins"), coins + 26)

    def test_the_workshop_crafts_potions_in_a_queue_that_runs_by_the_clock(self):
        self.lua.execute("NS.db.buildings.workshop = 2; NS.db.crops[2447] = 9; NS.db.crops[765] = 3; NS.db.crops[785] = 2; NS.db.crops[2449] = 2")
        self.assertEqual(self.ev("NS.Workshop:Slots()"), 2)
        self.assertTrue(self.ev("(NS.Workshop:Craft('heal'))"))
        self.assertEqual(self.ev("NS.db.crops[2447]"), 6)                      # 3 peacebloom and 1 silverleaf went
        self.assertTrue(self.ev("(NS.Workshop:Craft('mana'))"))
        ok, why = self.lua.eval("function() return NS.Workshop:CanCraft('heal') end")()[:2]
        self.assertEqual((ok, why), (False, "queueFull"))                      # two places only
        self.assertEqual(tuple(self.lua.eval("function() return NS.Workshop:CanCraft('agil') end")())[:2], (False, "recipeLevel"))
        self.lua.execute("NOW = NOW + 120")
        self.assertEqual(self.lua.eval("NS.Workshop:Update()")[1], "heal")
        self.assertEqual(self.ev("NS.Village:Good('heal')"), 1)
        self.lua.execute("NOW = NOW + 300")                                     # the second started when the first ended
        self.assertEqual(self.lua.eval("NS.Workshop:Update()")[1], "mana")
        self.assertEqual(self.ev("#NS.db.queue"), 0)
        self.assertEqual(self.ev("NS.Village:SellGood('mana')"), 150)

    def test_every_place_opens_with_its_drawing_and_explains_itself_once(self):
        self.lua.execute("NS.db.buildings.workshop = 2; NS.db.tutorial.done = true; NS.db.seen = {}")
        self.open("workshop")
        screen = "NS.UI.screens.workshop"
        self.assertTrue(self.ev(screen + ".art ~= nil"))
        self.assertTrue(self.ev(screen + ".coach:IsShown()"))                 # the first time: the card
        self.assertIn("Alchemy", self.ev(screen + ".coach.card.lines[1]:GetText()"))
        self.press(screen + ".coach.card.ok")
        self.assertFalse(self.ev(screen + ".coach:IsShown()"))
        self.assertTrue(self.ev("NS.db.seen.workshop"))
        self.open("village")
        self.open("workshop")
        self.assertFalse(self.ev(screen + ".coach:IsShown()"))                # not again
        self.press(screen + ".helpButton")                                    # the "?" brings it back
        self.assertTrue(self.ev(screen + ".coach:IsShown()"))
        for place in ("garden", "barn", "hall"):
            self.open(place)
            self.assertTrue(self.ev("NS.UI.screens." + place + ".art ~= nil"))

    def test_cooking_lives_on_fish_and_smithing_on_ore(self):
        self.lua.execute("NS.db.buildings.workshop = 3; NS.db.goods.fish = 14; NS.db.goods.ore = 7; NS.db.crops[2447] = 2")
        self.assertTrue(self.ev("(NS.Workshop:Craft('stew'))"))
        self.assertEqual(self.ev("NS.Village:Good('fish')"), 10)               # 4 fish went
        self.assertTrue(self.ev("(NS.Workshop:Craft('roast'))"))               # 10 fish and 2 peacebloom
        self.assertEqual((self.ev("NS.Village:Good('fish')"), self.ev("NS.db.crops[2447]")), (0, None))
        self.assertTrue(self.ev("(NS.Workshop:Craft('bar'))"))                 # the third place
        self.lua.execute("NOW = NOW + 90 + 240")
        self.assertEqual(len(self.lua.eval("NS.Workshop:Update()")), 2)
        self.assertEqual(self.ev("NS.Village:Good('stew')"), 1)
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 1)
        self.assertEqual(tuple(self.lua.eval("function() return NS.Workshop:CanCraft('blade') end")())[:2], (False, "recipeLevel"))
        self.lua.execute("NOW = NOW + 200")
        self.lua.eval("NS.Workshop:Update()")
        self.assertEqual(self.ev("NS.Village:SellGood('bar')"), 60)

    def test_the_workshop_screen_changes_trade(self):
        self.lua.execute("NS.db.buildings.workshop = 2; NS.db.goods.fish = 5; NS.db.tutorial.done = true")
        self.open("workshop")
        rows = "NS.UI.screens.workshop.rows"
        self.assertEqual(self.ev(rows + "[1].name:GetText()").split("   ")[0], "Healing potion")
        self.lua.execute("NS.UI.trade = 'cooking'; NS.UI:Refresh()")
        self.assertEqual(self.ev(rows + "[1].name:GetText()").split("   ")[0], "Fish stew")
        self.press(rows + "[1].button")
        self.assertEqual(self.ev("NS.Village:Good('fish')"), 1)
        self.assertEqual(self.ev("#NS.db.queue"), 1)

    def test_followers_go_on_missions_for_fish_and_come_back_with_coins(self):
        self.lua.execute("NS.db.buildings.inn = 2; NS.db.goods.fish = 3")
        self.assertEqual(self.ev("NS.Inn:Count()"), 2)
        self.assertEqual(self.ev("(NS.Inn:Status(3))"), "locked")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Start(1, 'medium') end")())[:2], (False, "fish"))   # needs 6
        self.assertTrue(self.ev("(NS.Inn:Start(1, 'short'))"))
        self.assertEqual(self.ev("NS.Village:Good('fish')"), 1)
        self.assertEqual(self.ev("(NS.Inn:Status(1))"), "away")
        self.assertEqual(self.ev("(NS.Inn:Status(2))"), "idle")
        self.lua.execute("NOW = NOW + 1800")
        self.assertEqual(self.ev("(NS.Inn:Status(1))"), "back")
        self.assertEqual(self.ev("NS.Inn:Update()"), 1)
        self.assertEqual(self.ev("NS.Inn:Update()"), 0)                         # told once
        coins = self.ev("NS.db.coins")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Inn:Collect(1) end")()), (40, 0))
        self.assertEqual(self.ev("NS.db.coins"), coins + 40)
        self.assertEqual(self.ev("(NS.Inn:Status(1))"), "idle")
        self.lua.execute("NS.db.followers[1].done = 6")                          # two levels up: +20%
        self.assertEqual(self.ev("NS.Inn:Pay(1, NS.Inn.Mission('short'))"), 48)

    def test_the_workshop_and_the_inn_are_lots_opened_by_the_hall_and_have_screens(self):
        self.lua.execute("NS.db.coins = 50000; NS.db.goods.ore = 500; NS.db.buildings.hall = 3")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Village:CanUpgrade('workshop') end")())[:3], (False, "hall", 4))
        self.lua.execute("NS.db.buildings.hall = 5; NS.db.buildings.workshop = 1; NS.db.buildings.inn = 1; NS.db.goods.fish = 30; NS.db.crops[2447] = 5; NS.db.crops[765] = 2")
        self.open("village")
        v = "NS.UI.screens.village.spots"
        self.assertEqual(self.ev(v + ".workshop.note:GetText()"), "idle")
        self.assertEqual(self.ev(v + ".inn.note:GetText()"), "1 followers")
        self.press(v + ".workshop")
        self.assertEqual(self.ev("NS.UI.view"), "workshop")
        self.press("NS.UI.screens.workshop.rows[1].button")
        self.assertEqual(self.ev("#NS.db.queue"), 1)
        self.assertEqual(self.ev("NS.UI.screens.workshop.head:GetText()"), "1 in the queue")
        self.open("inn")
        row = "NS.UI.screens.inn.rows[1]"
        self.press(row + ".missions[1]")
        self.assertEqual(self.ev("(NS.Inn:Status(1))"), "away")
        self.lua.execute("NS.db.workshop_probe = 1; NOW = NOW + 1800; NS.UI:Tick()")
        self.assertEqual(self.ev("NS.UI.screens.inn.head:GetText()"), "1 follower is back")
        self.press(row + ".collect")
        self.assertEqual(self.ev("(NS.Inn:Status(1))"), "idle")
        self.assertEqual(self.ev("NS.UI.screens.inn.rows[2].state:GetText()"), "Comes when the Inn reaches level 2.")

    def test_the_lots_and_the_goods_are_on_the_screens(self):
        self.lua.execute("NS.db.coins = 500; NS.db.tutorial.done = true; NS.db.stats.harvested = 1; NS.db.stats.earned = 1")
        self.open("village")
        v = "NS.UI.screens.village.spots"
        self.assertEqual(self.ev(v + ".mine.name:GetText()"), "Mine")
        self.assertEqual(self.ev(v + ".mine.note:GetText()"), "Needs Hall 2")
        self.press(v + ".mine")                                                # an empty lot: the Hall builds it
        self.assertEqual(self.ev("NS.UI.view"), "hall")
        rows = "NS.UI.screens.hall.rows"
        self.assertEqual(self.ev(rows + "[5].name:GetText()"), "Mine · not built")
        self.lua.execute("NS.db.buildings.hall = 2; NS.UI:Refresh()")
        self.assertEqual(self.ev(rows + "[5].button.label:GetText()"), "Build")
        self.press(rows + "[5].button")
        self.lua.execute("NOW = NOW + 300; NS.UI:Tick(); NOW = NOW + 3600; NS.UI:Tick()")
        self.open("village")
        self.assertEqual(self.ev(v + ".mine.name:GetText()"), "Mine · 1")
        self.assertEqual(self.ev(v + ".mine.note:GetText()"), "6 / 40 Ore")
        self.press(v + ".mine")                                                # built: its own screen, which leads to the Barn
        self.assertEqual(self.ev("NS.UI.view"), "mine")
        self.press("NS.UI.screens.mine.action")
        self.assertEqual(self.ev("NS.UI.view"), "barn")
        barn = "NS.UI.screens.barn"
        ore = f"{barn}.rows[{self.ev('#NS.Data.PLANTS') + 1}]"                  # the goods come after the herbs
        self.assertTrue(self.ev(ore + ":IsShown()"))
        self.assertEqual(self.ev(ore + ".name:GetText()"), "Ore")
        coins = self.ev("NS.db.coins")
        self.press(ore + ".sell1")
        self.assertEqual(self.ev("NS.db.coins"), coins + 6)
        self.press(barn + ".action")                                           # sell everything takes the goods too
        self.assertEqual(self.ev("NS.Village:Good('ore')"), 0)

    def test_buildings_cost_coins_and_take_time_one_work_at_a_time(self):
        self.assertEqual(self.up("hall"), (False, "coins"))
        self.lua.execute("NS.db.coins = 10000")
        self.assertEqual(self.up("garden"), (False, "hall"))          # nothing goes above the Hall
        self.assertTrue(self.ev("(NS.Village:Upgrade('hall'))"))
        self.assertEqual(self.ev("NS.db.coins"), 10000 - 100)
        self.assertEqual(self.up("barn"), (False, "busy"))
        work, left, progress = self.lua.eval("function() return NS.Village:Work() end")()
        self.assertEqual((work["id"], left, progress), ("hall", 45, 0))
        self.assertIsNone(self.ev("(NS.Village:Update())"))            # not yet
        self.lua.execute("NOW = NOW + 45")
        self.assertEqual(self.lua.eval("function() return NS.Village:Update() end")(), ("hall", 2))
        self.assertEqual(self.ev("NS.Village:Level('hall')"), 2)
        self.assertIsNone(self.ev("NS.db.work"))

    def test_a_bigger_garden_has_more_plots(self):
        self.lua.execute("NS.db.coins = 10000; NS.db.buildings.hall = 3")
        self.assertEqual(self.ev("NS.db.nplots"), 2)
        self.lua.execute("NS.Village:Upgrade('garden'); NOW = NOW + 60; NS.Village:Update()")
        self.assertEqual(self.ev("NS.db.nplots"), 3)
        self.assertEqual(self.ev("(NS.Farm:Status(3))"), "empty")
        self.lua.execute("NS.db.buildings.garden = 7")
        self.assertIsNone(self.ev("NS.Village:Next('garden')"))        # the top
        self.assertEqual(self.up("garden"), (False, "maxLevel"))

    def test_the_barn_holds_only_so_much(self):
        self.lua.execute("NS.db.crops[765] = 39; NS.Farm:Plant(1, 2447); NOW = NOW + 60")
        n, why = self.lua.eval("function() return NS.Farm:Harvest(1) end")()
        self.assertEqual((n, why), (0, "barnFull"))                   # 39 + 3 do not fit in 40
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "ready")      # the plant waits in the plot
        self.lua.execute("NS.db.buildings.barn = 2")
        self.assertEqual(self.ev("(NS.Farm:Harvest(1))"), 3)

    def test_a_bigger_market_pays_more(self):
        self.lua.execute("NS.db.buildings.market = 6; NS.db.crops[785] = 10")     # +20%
        self.assertEqual(self.ev("NS.Farm:Sell(785, 10)"), self.ev("math.floor(10 * NS.Data.Plant(785).sell * 1.2)"))
        self.lua.execute("local o = NS.db.orders[1]; NS.db.crops[o.plant] = o.qty; BEFORE = NS.db.coins; REWARD = o.coins")
        self.lua.execute("NS.Orders:Deliver(1)")
        self.assertEqual(self.ev("NS.db.coins - BEFORE"), self.ev("math.floor(REWARD * 1.2)"))

    def test_a_save_from_before_the_village_keeps_its_plots(self):
        self.lua.execute("""
            KorumHomesteadDB = {coins = 5, level = 3, xp = 0, nplots = 5, plots = {}, crops = {}, orders = {},
                stats = {harvested = 9, earned = 50, delivered = 0}}
            Fire("ADDON_LOADED", "KorumHomestead"); Fire("PLAYER_LOGIN")
        """)
        self.assertEqual(self.ev("NS.Village:Level('garden')"), 4)
        self.assertEqual(self.ev("NS.Village:Level('hall')"), 4)
        self.assertEqual(self.ev("NS.db.nplots"), 5)

    def test_the_village_is_the_first_screen_and_every_building_is_a_door(self):
        self.lua.execute("SlashCmdList.KORUMHOMESTEAD('')")
        self.assertEqual(self.ev("NS.UI.view"), "village")
        v = "NS.UI.screens.village"
        self.assertEqual(self.ev(v + ".head:GetText()"), "Welcome to your village")
        self.assertTrue(self.ev(v + ".spots.garden.calls"))           # the first step points at the Garden
        self.assertEqual(self.ev(v + ".spots.garden.name:GetText()"), "Garden · 1")
        self.assertEqual(self.ev(v + ".spots.barn.note:GetText()"), "0 / 40 herbs")
        for building, view in (("garden", "garden"), ("barn", "barn"), ("market", "orders"), ("hall", "hall")):
            self.press(v + ".spots." + building)
            self.assertEqual(self.ev("NS.UI.view"), view)
            self.assertIn("/", self.ev("NS.UI.here:GetText()"))        # the path says where you are
            self.press("NS.UI.home")                                   # and "Village" takes you back
            self.assertEqual(self.ev("NS.UI.view"), "village")
        self.press("NS.UI.gear")
        self.assertEqual(self.ev("NS.UI.view"), "settings")

    def test_the_village_button_does_what_is_wanted_now(self):
        self.lua.execute("NS.db.tutorial.done = true; NS.db.stats.harvested = 1; NS.db.stats.earned = 1; NS.Farm:PlantAll(2447); NOW = NOW + 60")
        self.open("village")
        v = "NS.UI.screens.village"
        self.assertEqual(self.ev(v + ".head:GetText()"), "2 plots ready to harvest")
        self.assertEqual(self.ev(v + ".spots.garden.note:GetText()"), "2 ready")
        self.press(v + ".primary")                                     # harvest everything from the map
        self.assertEqual(self.ev("NS.db.crops[2447]"), 6)
        self.lua.execute("NS.db.coins = 500; NS.db.crops = {}; NS.UI:Refresh()")
        self.assertEqual(self.ev(v + ".mode"), "hall")                 # nothing to harvest: a building can be improved
        self.assertTrue(self.ev(v + ".spots.hall.calls"))
        self.press(v + ".primary")
        self.assertEqual(self.ev("NS.UI.view"), "hall")

    def test_the_hall_improves_buildings_with_one_click(self):
        self.lua.execute("NS.db.coins = 500")
        self.open("hall")
        rows = "NS.UI.screens.hall.rows"
        self.assertEqual(self.ev(rows + "[1].button.label:GetText()"), "Improve to level 2")
        self.assertEqual(self.ev(rows + "[2].button.label:GetText()"), "Needs Hall 2")
        self.assertIn("2 plots", self.ev(rows + "[2].now:GetText()"))
        self.assertIn("3 plots", self.ev(rows + "[2].now:GetText()"))
        self.press(rows + "[1].button")
        self.assertEqual(self.ev("NS.db.work.id"), "hall")
        self.assertEqual(self.ev("NS.UI.screens.hall.head:GetText()"), "Building: Hall level 2")
        self.assertIn("building", self.ev(rows + "[1].button.label:GetText()"))
        self.lua.execute(self.NOTES)
        self.lua.execute("NOW = NOW + 45; NS.UI:Tick()")
        self.assertEqual(self.ev("NS.Village:Level('hall')"), 2)
        self.assertIn("Hall reached level 2!", " ".join(self.lua.eval("NOTES").values()))
        self.assertEqual(self.ev(rows + "[2].button.label:GetText()"), "Improve to level 2")

    def test_plant_all_and_harvest_all_are_one_click(self):
        self.assertEqual(self.ev("(NS.Farm:PlantAll(2447))"), 2)
        self.assertEqual(self.ev("NS.Farm:ReadyCount()"), 0)
        self.lua.execute("NOW = NOW + 100")
        self.assertEqual(self.ev("NS.Farm:ReadyCount()"), 2)
        self.assertEqual(self.ev("(NS.Farm:HarvestAll())"), 6)

    def test_orders_pay_more_than_the_market_and_are_replaced(self):
        orders = self.ev("NS.db.orders")
        self.assertEqual(len(orders), 3)
        self.lua.execute("local o = NS.db.orders[1]; NS.db.crops[o.plant] = o.qty")
        coins = self.ev("NS.db.coins")
        reward = self.ev("NS.db.orders[1].coins")
        self.assertTrue(self.ev("NS.Orders:CanDeliver(1)"))
        ok, order = self.lua.eval("function() return NS.Orders:Deliver(1) end")()
        self.assertTrue(ok)
        self.assertEqual(self.ev("NS.db.coins"), coins + reward)
        self.assertEqual(self.ev("NS.db.stats.delivered"), 1)
        self.assertIsNotNone(self.ev("NS.db.orders[1]"))              # a new one took its place
        ok, why = self.lua.eval("function() return NS.Orders:Deliver(2) end")()
        self.assertFalse(ok)
        self.assertEqual(why, "missing")

    def test_delivering_an_order_takes_the_herbs_out_of_the_barn(self):
        self.lua.execute("local o = NS.db.orders[1]; NS.db.crops[o.plant] = o.qty + 3; NS.db.tutorial.done = true")
        before = self.ev("NS.Village:Stored()")
        qty = self.ev("NS.db.orders[1].qty")
        self.open("orders")
        self.press("NS.UI.screens.orders.rows[1].deliver")
        self.assertEqual(self.ev("NS.Village:Stored()"), before - qty)
        self.open("barn")
        self.assertIn("%d / " % (before - qty), self.ev("NS.UI.screens.barn.stats:GetText()"))

    def test_texts_follow_the_language_and_fall_back_to_english(self):
        self.assertEqual(self.ev("NS.T('harvest')"), "Harvest")
        self.lua.execute("NS.db.lang = 'ptBR'")
        self.assertEqual(self.ev("NS.T('harvest')"), "Colher")
        self.assertEqual(self.ev("NS.T('coins', '5')"), "5 moedas")
        self.assertEqual(self.ev("NS.T('no such key')"), "no such key")
        self.assertEqual(self.ev("NS.Duration(5400)"), "1h 30m")
        self.assertEqual(self.ev("NS.Duration(45)"), "45s")
        self.assertEqual(self.ev("NS.Number(1234567)"), "1,234,567")

    def test_every_text_exists_in_both_languages(self):
        problems = self.lua.eval("""(function()
            local bad = {}
            local function Shape(text)                       -- the %d and %s of a text, in order
                local out = {}
                for spec in text:gmatch("%%[ds]") do out[#out + 1] = spec end
                return table.concat(out)
            end
            for key, text in pairs(NS.L.enUS) do
                local pt = NS.L.ptBR[key]
                if not pt then bad[#bad + 1] = "ptBR lacks " .. key
                elseif Shape(pt) ~= Shape(text) then bad[#bad + 1] = "arguments differ in " .. key end
            end
            for key in pairs(NS.L.ptBR) do
                if not NS.L.enUS[key] then bad[#bad + 1] = "enUS lacks " .. key end
            end
            return table.concat(bad, "; ")
        end)()""")
        self.assertEqual(problems, "")

    def test_every_text_the_window_asks_for_exists(self):
        source = "".join((HOME / f).read_text(encoding="utf-8") for f in FILES + ["Core.lua", "Farm.lua"])
        keys = set(re.findall(r'\bT\("([A-Za-z_0-9]+)"[,)]', source))
        keys |= {"why_" + k for k in re.findall(r'Reason\("(\w+)"\)', source)}
        keys |= {"why_" + k for k in re.findall(r'return false, "(\w+)"', source)}
        keys |= {f"npc{i}" for i in range(1, 7)} | {"optAlerts", "optAlertsD", "optWelcome", "optWelcomeD",
                                                         "optMinimap", "optMinimapD", "subEmpty", "subBroke"}
        self.assertGreater(len(keys), 60)
        for key in sorted(keys):
            self.assertTrue(self.ev(f"NS.L.enUS['{key}'] ~= nil"), key)

    def test_no_accented_text_goes_through_string_upper(self):
        for lua in FILES:
            path = HOME / lua
            self.assertNotIn("string.upper", path.read_text(encoding="utf-8"), lua)

    # ------------------------------------------------------------------ the window
    def open(self, view="garden"):
        self.lua.execute(f"NS.UI:Show('{view}')")

    def press(self, widget):
        """A click of the mouse on a button of the window."""
        self.lua.execute(f"local b = {widget}; b:GetScript('OnClick')(b)")

    def garden(self, field):
        return self.ev(f"NS.UI.screens.garden.{field}")

    def test_the_window_works_on_every_tab_without_commands(self):
        self.lua.execute("NS.db.coins = 500; SlashCmdList.KORUMHOMESTEAD('')")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))
        self.press("NS.UI.screens.village.spots.garden")
        self.press("NS.UI.screens.garden.tiles[1]")                  # plant
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "growing")
        self.press("NS.UI.screens.garden.tiles[3]")                  # the next plot: it comes from the Hall
        self.assertEqual(self.ev("NS.UI.view"), "hall")
        self.assertEqual(self.ev("NS.db.nplots"), 2)
        self.open()
        self.lua.execute("NOW = NOW + 100; NS.UI:Tick()")
        self.press("NS.UI.screens.garden.tiles[1]")                  # harvest
        self.assertEqual(self.ev("NS.db.crops[2447]"), 3)
        self.open("barn")
        self.assertEqual(self.ev("NS.UI.view"), "barn")
        coins = self.ev("NS.db.coins")
        self.press("NS.UI.screens.barn.rows[1].sell1")
        self.assertEqual(self.ev("NS.db.coins"), coins + 4)
        self.press("NS.UI.screens.barn.action")                      # sell everything
        self.assertEqual(self.ev("NS.db.coins"), coins + 12)
        self.assertIsNone(self.ev("NS.db.crops[2447]"))
        self.open("orders")
        self.lua.execute("""
            NS.db.orders[1].plant, NS.db.orders[2].plant, NS.db.orders[3].plant = 2447, 765, 2447
            NS.db.crops[765] = NS.db.orders[2].qty
            NS.UI:Refresh()
        """)
        self.assertEqual(self.ev("NS.UI.screens.orders.rows[1].deliver.label:GetText()"),
                         "%d to go" % self.ev("NS.db.orders[1].qty"))
        self.assertTrue(self.ev("NS.UI.screens.orders.rows[2].deliver.enabledState"))
        self.assertFalse(self.ev("NS.UI.screens.orders.rows[1].deliver.enabledState"))
        self.press("NS.UI.screens.orders.rows[2].deliver")
        self.assertEqual(self.ev("NS.db.stats.delivered"), 1)
        self.press("NS.UI.screens.orders.rows[1].deliver")           # nothing to give: nothing happens
        self.assertEqual(self.ev("NS.db.stats.delivered"), 1)
        self.open("settings")
        self.press("NS.UI.screens.settings.lang.buttons[3]")         # Português
        self.assertEqual(self.ev("NS.db.lang"), "ptBR")
        self.assertEqual(self.ev("NS.UI.home.label:GetText()"), "Vila")
        self.assertEqual(self.ev("NS.UI.screens.settings.head:GetText()"), "Ajustes")
        self.press("NS.UI.screens.settings.alerts")
        self.assertFalse(self.ev("NS.db.alerts"))
        self.press("NS.UI.screens.settings.minimap")
        self.assertTrue(self.ev("NS.db.minimap.hide"))
        self.assertFalse(self.ev("KorumHomesteadMinimap:IsShown()"))
        self.press("NS.UI.win.close")
        self.assertFalse(self.ev("KorumHomesteadFrame:IsShown()"))

    def test_the_window_closes_with_escape_and_fits_the_screen(self):
        self.open()
        names = list(self.ev("UISpecialFrames").values())
        self.assertIn("KorumHomesteadFrame", names)
        self.assertLessEqual(self.ev("KorumHomesteadFrame:GetHeight()"), 768 - 40)
        self.assertEqual(self.ev("KorumHomesteadFrame:GetWidth()"), 720)

    def test_the_first_time_the_window_says_what_to_do_next(self):
        self.open()
        self.assertEqual(self.ev("NS.UI:Step()"), "plant")
        self.assertEqual(self.garden("head:GetText()"), "Welcome to your homestead")
        self.assertIn("Click an empty plot", self.garden("sub:GetText()"))
        self.assertTrue(self.garden("tiles[1].hinted"))               # the first empty plot is the one pointed at
        self.assertFalse(self.garden("tiles[2].hinted"))
        self.press("NS.UI.screens.garden.tiles[1]")
        self.assertEqual(self.ev("NS.UI:Step()"), "wait")
        self.assertEqual(self.garden("head:GetText()"), "It is growing")
        self.assertIn("45s", self.garden("sub:GetText()"))
        self.assertFalse(self.garden("tiles[2].hinted"))
        self.lua.execute("NOW = NOW + 45; NS.UI:Tick()")
        self.assertEqual(self.garden("head:GetText()"), "Your first harvest is ready")
        self.press("NS.UI.screens.garden.tiles[1]")
        self.assertEqual(self.garden("head:GetText()"), "Now turn it into coins")
        self.press("NS.UI.home")
        self.assertTrue(self.ev("NS.UI.screens.village.spots.barn.calls"))   # the way to the barn is marked on the map
        self.press("NS.UI.screens.village.spots.barn")
        self.press("NS.UI.screens.barn.action")
        self.assertIsNone(self.ev("NS.UI:Step()"))
        self.assertTrue(self.ev("NS.db.tutorial.done"))
        self.open()
        self.assertEqual(self.garden("head:GetText()"), "Room to plant")
        self.assertIn("Peacebloom", self.garden("sub:GetText()"))

    def test_someone_who_already_played_is_not_taught_again(self):
        self.lua.execute("NS.db.stats.harvested = 30; NS.db.stats.earned = 200")
        self.open()
        self.assertEqual(self.garden("head:GetText()"), "Room to plant")
        self.assertTrue(self.ev("NS.db.tutorial.done"))

    def test_a_homestead_saved_by_the_first_version_gets_the_new_field(self):
        self.lua.execute("""
            KorumHomesteadDB = {coins = 77, level = 3, xp = 1, nplots = 4, plots = {}, crops = {[765] = 2}, orders = {},
                stats = {harvested = 9, earned = 50, delivered = 0}, selected = 765, lang = "auto", alerts = false, welcome = true,
                minimap = {angle = 10, hide = false}}
            Fire("ADDON_LOADED", "KorumHomestead")
        """)
        self.assertEqual(self.ev("NS.db.coins"), 77)
        self.assertFalse(self.ev("NS.db.alerts"))
        self.assertFalse(self.ev("NS.db.tutorial.done"))
        self.open()
        self.assertEqual(self.garden("tiles[1].note:GetText()"), "Plant Silverleaf")

    def test_a_plot_says_what_a_click_on_it_does(self):
        self.lua.execute("NS.db.coins = 200; NS.db.tutorial.done = true")
        self.open()
        self.assertEqual(self.garden("tiles[1].title:GetText()"), "Empty plot")
        self.assertEqual(self.garden("tiles[1].note:GetText()"), "Plant Peacebloom")
        self.assertEqual(self.garden("tiles[3].title:GetText()"), "New plot")
        self.assertEqual(self.garden("tiles[3].note:GetText()"), "Improve the Garden")
        self.assertFalse(self.garden("tiles[4]:IsShown()"))          # only the next plot is promised
        self.press("NS.UI.screens.garden.tiles[1]")
        self.assertEqual(self.garden("tiles[1].title:GetText()"), "Peacebloom")
        self.assertEqual(self.garden("tiles[1].note:GetText()"), "45s left")
        self.assertEqual(self.garden("tiles[1].ring.lit"), 0)
        self.lua.execute("NOW = NOW + 15; NS.UI:Tick()")
        self.assertEqual(self.garden("tiles[1].ring.lit"), 12)        # a third of the 36 dots
        self.press("NS.UI.screens.garden.tiles[1]")                  # growing: a click changes nothing
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "growing")
        self.lua.execute("NOW = NOW + 30; NS.UI:Tick()")
        self.assertEqual(self.garden("tiles[1].note:GetText()"), "Harvest")
        self.assertEqual(self.garden("tiles[1].ring.lit"), 36)
        self.lua.execute("NS.db.coins = 3; NS.UI:Refresh()")
        self.assertEqual(self.garden("tiles[2].note:GetText()"), "Needs 4 coins")
        self.assertEqual(self.garden("tiles[3].note:GetText()"), "Improve the Garden")
        self.press("NS.UI.screens.garden.tiles[2]")
        self.assertEqual(self.ev("NS.UI.msg"), "Not enough coins.")
        self.assertEqual(self.ev("(NS.Farm:Status(2))"), "empty")

    def test_the_seed_is_picked_on_the_strip(self):
        self.open()
        self.assertEqual(self.ev("#NS.UI.screens.garden.seeds"), 13)
        self.assertEqual(self.garden("seeds[1].note:GetText()"), "45s")
        self.assertEqual(self.garden("seeds[3].note:GetText()"), "Lv 3")      # locked: its level
        self.assertIn("Peacebloom", self.garden("detail:GetText()"))
        self.assertIn(f"{self.ev('NS.Data.Plant(2447).cost')} coins · grows in 45s · yields 3", self.garden("detail:GetText()"))
        self.press("NS.UI.screens.garden.seeds[2]")
        self.assertEqual(self.ev("NS.db.selected"), 765)
        self.assertEqual(self.garden("tiles[1].note:GetText()"), "Plant Silverleaf")
        self.press("NS.UI.screens.garden.seeds[3]")                  # locked: stays, and says why
        self.assertEqual(self.ev("NS.db.selected"), 765)
        self.assertEqual(self.ev("NS.UI.msg"), "Unlocks at Village 3")
        self.lua.execute("local b = NS.UI.screens.garden.seeds[3]; b:GetScript('OnEnter')(b)")
        self.assertIn("Earthroot", self.garden("detail:GetText()"))  # the seed under the mouse explains itself
        self.assertIn("Unlocks at Village 3", self.garden("detail:GetText()"))
        self.lua.execute("local b = NS.UI.screens.garden.seeds[3]; b:GetScript('OnLeave')(b)")
        self.assertIn("Silverleaf", self.garden("detail:GetText()"))

    def test_there_is_one_main_button_and_it_does_what_is_wanted_now(self):
        self.lua.execute("NS.db.tutorial.done = true")
        self.open()
        self.assertEqual(self.garden("primary.label:GetText()"), "Plant all")
        self.assertEqual(self.garden("primary.style"), "primary")
        self.press("NS.UI.screens.garden.primary")
        self.assertEqual(self.ev("NS.db.coins"), 32)
        self.assertEqual(self.garden("head:GetText()"), "Everything is growing")
        self.assertEqual(self.garden("primary.label:GetText()"), "Come back later")
        self.assertFalse(self.garden("primary.enabledState"))
        self.press("NS.UI.screens.garden.primary")                   # disabled: nothing
        self.lua.execute("NOW = NOW + 60; NS.UI:Tick()")
        self.assertEqual(self.garden("head:GetText()"), "2 plots ready to harvest")
        self.assertEqual(self.garden("primary.label:GetText()"), "Harvest all")
        self.press("NS.UI.screens.garden.primary")
        self.assertEqual(self.ev("NS.db.crops[2447]"), 6)
        self.assertEqual(self.ev("NS.UI.msg"), "Harvested 6.")
        self.lua.execute("NS.db.coins = 0; NS.UI:Refresh()")
        self.assertFalse(self.garden("primary.enabledState"))
        self.assertIn("Not enough coins for Peacebloom", self.garden("sub:GetText()"))

    def test_the_barn_guides_when_empty_and_marks_what_an_order_wants(self):
        self.open("barn")
        self.assertEqual(self.ev("NS.UI.screens.barn.head:GetText()"), "The barn is empty")
        self.assertEqual(self.ev("NS.UI.screens.barn.action.label:GetText()"), "Go to the garden")
        self.press("NS.UI.screens.barn.action")
        self.assertEqual(self.ev("NS.UI.view"), "garden")
        self.lua.execute("""
            NS.db.orders[1].plant = 765
            NS.db.orders[2].plant = 765
            NS.db.orders[3].plant = 765
            for _, p in ipairs(NS.Data.PLANTS) do NS.db.crops[p[1]] = 2 end
            NS.UI:Show("barn")
        """)
        barn = "NS.UI.screens.barn"
        self.assertEqual(self.ev(barn + ".head:GetText()"), f"{2 * self.ev('#NS.Data.PLANTS')} herbs in the barn")
        self.assertEqual(self.ev(barn + ".rows[2].wanted:GetText()"), "on order")
        self.assertEqual(self.ev(barn + ".rows[1].wanted:GetText()"), "")
        self.assertIn("Sell everything", self.ev(barn + ".action.label:GetText()"))
        # thirteen kinds still fit in the window, without scrolling
        self.assertLessEqual(66 + 13 * self.ev(barn + ".rows[13]:GetHeight()") + 40, self.ev("NS.UI.win.contentHeight"))

    def test_changes_are_shown_as_they_happen(self):
        self.lua.execute("NS.db.coins = 100; NS.db.tutorial.done = true")
        self.open()
        self.assertEqual(self.ev("NS.UI.coinText:GetText()"), "100")
        self.assertEqual(self.ev("NS.UI.levelBox.label:GetText()"), "Village 1")
        self.press("NS.UI.screens.garden.tiles[1]")
        self.lua.execute("NS.Kit.Step(0.2)")
        shown = int(self.ev("NS.UI.coinText:GetText()"))
        self.assertTrue(96 <= shown < 100, shown)                     # on its way down
        self.lua.execute("NS.Kit.Step(1)")
        self.assertEqual(self.ev("NS.UI.coinText:GetText()"), "96")
        self.lua.execute("NOW = NOW + 60; NS.UI:Tick()")
        self.press("NS.UI.screens.garden.tiles[1]")
        self.lua.execute("NS.Kit.Step(1)")
        self.assertAlmostEqual(self.ev("NS.UI.levelBox.bar.value"), self.ev("NS.Data.Plant(2447).xp / NS.Data.XPToNext(1)"))
        self.lua.execute("NS.Farm:AddXP(NS.Data.XPToNext(1) - NS.db.xp + NS.Data.XPToNext(2)); NS.UI:Refresh(); NS.Kit.Step(5)")
        self.assertEqual(self.ev("NS.UI.levelBox.label:GetText()"), "Village 3")
        self.assertEqual(self.ev("NS.UI.msg"), "Village 3! New seed: Earthroot")
        self.assertEqual(self.ev("NS.UI.levelBox.bar.value"), 0)
        self.assertEqual(self.ev("NS.UI.win.notice:GetText()"), "Village 3! New seed: Earthroot")

    def test_the_map_marks_where_something_waits(self):
        self.lua.execute("NS.db.tutorial.done = true; NS.Farm:Plant(1, 2447); NOW = NOW + 60")
        self.open("village")
        v = "NS.UI.screens.village.spots"
        self.assertTrue(self.ev(v + ".garden.calls"))
        self.assertFalse(self.ev(v + ".market.calls"))
        self.lua.execute("""
            NS.db.orders[1].plant, NS.db.orders[2].plant, NS.db.orders[3].plant = 765, 2447, 2447
            NS.db.crops[765] = NS.db.orders[1].qty
            NS.UI:Refresh()
        """)
        self.assertTrue(self.ev(v + ".market.calls"))
        self.assertEqual(self.ev(v + ".market.note:GetText()"), "1 to deliver")
        self.open("orders")
        self.assertEqual(self.ev("NS.UI.screens.orders.head:GetText()"), "1 order ready to deliver")

    def test_the_animations_end_and_survive_an_error(self):
        self.lua.execute("""
            LOG = {}
            NS.Kit.Animate(1, function(p) LOG[#LOG + 1] = p end, function() LOG.done = true end)
            NS.Kit.Animate(1, function(p) if p > 0 then error("boom") end end)
            local gone = NS.Kit.Animate(1, function(p) LOG.gone = p end)
            gone.cancelled = true
            NS.Kit.Step(0.5); NS.Kit.Step(0.6); NS.Kit.Step(1)
        """)
        self.assertTrue(self.ev("LOG.done"))
        self.assertEqual(self.ev("LOG[#LOG]"), 1)
        self.assertEqual(self.ev("LOG.gone"), 0)

    def test_nothing_breaks_under_the_mouse_or_as_time_passes(self):
        self.lua.execute("""
            NS.db.coins = 5000; NS.db.level = 8
            for _, p in ipairs(NS.Data.PLANTS) do NS.db.crops[p[1]] = 3 end
            NS.Farm:Plant(1, 2447); NS.Village:Upgrade("hall"); NOW = NOW + 20
            for _, view in ipairs({"village", "hall", "guide", "workshop", "inn", "garden", "barn", "orders", "settings"}) do NS.UI:Show(view) end
            for round = 1, 2 do
                for _, f in ipairs(FRAMES) do
                    for _, script in ipairs({"OnEnter", "OnLeave", "OnShow"}) do
                        local fn = f:GetScript(script)
                        if fn then fn(f) end
                    end
                    local tick = f:GetScript("OnUpdate")
                    if tick then tick(f, 0.6) end
                end
                NOW = NOW + 60
            end
            NS.Kit.Step(10)
            NS.UI:Show("garden")
        """)
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))
        self.assertEqual(self.ev("NS.UI.screens.garden.tiles[1].note:GetText()"), "Harvest")

    def test_the_minimap_button_counts_what_is_ready(self):
        self.lua.execute("NS.Farm:PlantAll(2447); NOW = NOW + 100; NS.UI:Tick()")
        self.assertEqual(self.ev("KorumHomesteadMinimap.badge:GetText()"), "2")
        self.lua.execute("KorumHomesteadMinimap:GetScript('OnClick')()")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))

    NOTES = """
        NOTES = {}
        local notify = NS.Notify
        NS.Notify = function(self, text) NOTES[#NOTES + 1] = text; return notify(self, text) end
    """

    def test_a_plot_that_finishes_is_announced_once(self):
        self.lua.execute(self.NOTES)
        self.lua.execute("NS.Farm:Plant(1, 2447); PRINTS = {}; NOW = NOW + 100; NS.UI:Tick(); NS.UI:Tick()")
        lines = [n for n in self.lua.eval("NOTES").values() if "ready to harvest" in n]
        self.assertEqual(len(lines), 1)
        self.assertEqual(len(self.lua.eval("PRINTS")), 0)             # on the icon, not in the chat

    # ------------------------------------------------------------------ the icon on the screen
    def test_the_icon_counts_what_waits_and_opens_the_window(self):
        icon = "KorumHomesteadIcon"
        self.assertTrue(self.ev(icon + ":IsShown()"))
        self.assertFalse(self.ev(icon + ".badge:IsShown()"))
        self.lua.execute("""
            NS.Farm:PlantAll(2447); NOW = NOW + 60
            NS.db.orders[1].plant, NS.db.orders[2].plant, NS.db.orders[3].plant = 765, 3821, 3821
            NS.db.crops[765] = NS.db.orders[1].qty
            NS.UI:Tick()
        """)
        self.assertTrue(self.ev(icon + ".badge:IsShown()"))
        self.assertEqual(self.ev(icon + ".badge.text:GetText()"), "3")   # two plots and an order
        self.assertTrue(self.ev(icon + ".waiting"))
        self.press(icon)
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))
        self.press(icon)
        self.assertFalse(self.ev("KorumHomesteadFrame:IsShown()"))       # the window minimizes back into it

    def test_the_notifications_come_out_of_the_icon_one_after_the_other(self):
        self.assertTrue(self.ev("NS.UI:Toast('first')"))
        self.lua.execute("NS.UI:Toast('second')")
        toast = "KorumHomesteadIcon.toast"
        self.assertTrue(self.ev(toast + ":IsShown()"))
        self.assertEqual(self.ev(toast + ".text:GetText()"), "first")
        self.lua.execute("NS.Kit.Step(6)")
        self.assertEqual(self.ev(toast + ".text:GetText()"), "second")
        self.lua.execute("NS.Kit.Step(6)")
        self.assertFalse(self.ev(toast + ":IsShown()"))

    def test_the_guide_explains_the_game_with_the_numbers_of_the_rules(self):
        self.lua.execute("SlashCmdList.KORUMHOMESTEAD('')")
        self.press("NS.UI.help")
        self.assertEqual(self.ev("NS.UI.view"), "guide")
        g = "NS.UI.screens.guide"
        self.assertTrue(self.ev(g + ".pages.start:IsShown()"))
        self.assertEqual(self.ev(g + ".pages.start.steps[1].title:GetText()"), "Plant")
        for i, page in enumerate(("start", "buildings", "herbs", "tips"), 1):
            self.press(f"{g}.pick.buttons[{i}]")
            self.assertTrue(self.ev(f"{g}.pages.{page}:IsShown()"))
        self.assertIn("2 plots", self.ev(g + ".pages.buildings.rows[2].levels:GetText()"))
        self.assertIn("8 plots", self.ev(g + ".pages.buildings.rows[2].levels:GetText()"))
        self.assertEqual(self.ev(g + ".pages.herbs.rows[1].cells[3]:GetText()"), "45s")     # Peacebloom grows in 45s
        self.assertEqual(self.ev(g + ".pages.herbs.rows[1].cells[6]:GetText()"), str(self.ev("NS.Data.Plant(2447).sell")))
        self.lua.execute("NS.db.buildings.market = 6; NS.UI:Refresh()")                      # a bigger market: the guide follows
        self.assertEqual(self.ev(g + ".pages.herbs.rows[4].cells[6]:GetText()"), str(self.ev("math.floor(NS.Data.Plant(785).sell * 1.2)")))
        self.assertEqual(self.ev("NS.UI.here:GetText():match('Guide')"), "Guide")

    def test_the_icon_remembers_where_it_was_dragged_and_can_be_hidden(self):
        self.lua.execute("""
            local icon = KorumHomesteadIcon
            icon.GetCenter = function() return 900, 500 end
            icon:GetScript("OnDragStart")(icon)
            icon:GetScript("OnDragStop")(icon)
        """)
        self.assertEqual((self.ev("NS.db.bubble.x"), self.ev("NS.db.bubble.y")), (900, 500))
        self.open("settings")
        self.press("NS.UI.screens.settings.bubble")
        self.assertFalse(self.ev("NS.db.bubble.show"))
        self.assertFalse(self.ev("KorumHomesteadIcon:IsShown()"))
        self.lua.execute("PRINTS = {}; NS:Notify('hello')")             # hidden: the chat says it instead
        self.assertIn("hello", " ".join(self.lua.eval("PRINTS").values()))

    def test_a_player_without_coins_and_without_crops_is_never_stuck(self):
        self.lua.execute("NS.db.coins = 2")
        self.assertTrue(self.ev("NS.Farm:Plant(1, 2447)"))             # the neighbour lends the cheapest seed
        self.assertEqual(self.ev("NS.db.coins"), 0)
        self.lua.execute("NS.db.coins = 2")
        ok, why = self.lua.eval("function() return NS.Farm:Plant(2, 765) end")()   # not the cheapest: no help, and not stuck now
        self.assertFalse(ok)

    def test_the_window_closes_when_a_fight_starts_and_does_not_open_during_one(self):
        self.lua.execute("SlashCmdList.KORUMHOMESTEAD('')")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))
        self.lua.execute("Fire('PLAYER_REGEN_DISABLED')")
        self.assertFalse(self.ev("KorumHomesteadFrame:IsShown()"))
        self.lua.execute("IN_COMBAT = true; function InCombatLockdown() return IN_COMBAT end")
        self.lua.execute("SlashCmdList.KORUMHOMESTEAD('')")
        self.assertFalse(self.ev("KorumHomesteadFrame:IsShown()"))
        self.lua.execute("IN_COMBAT = false")
        self.lua.execute("SlashCmdList.KORUMHOMESTEAD('')")
        self.assertTrue(self.ev("KorumHomesteadFrame:IsShown()"))

    def test_it_is_independent_of_the_other_addons(self):
        for toc in HOME.glob("*.toc"):
            text = toc.read_text(encoding="utf-8")
            self.assertNotIn("Dependencies", text)
            self.assertNotIn("OptionalDeps", text)
        for lua in HOME.glob("*.lua"):
            text = lua.read_text(encoding="utf-8")
            for other in ("KorumFacilities", "KorumRadar", "KorumLevelingGuide", "KorumSafeTravels", "GoldRadar"):
                self.assertNotIn(other, text, lua.name)

    def use_local_os_clock(self):
        self.lua.execute("""
            function time(fields)
                if fields then return os.time(fields) end
                return NOW
            end
            function date(format, at) return os.date(format, at or NOW) end
        """)

    def test_day_changes_at_local_midnight(self):
        self.use_local_os_clock()
        self.lua.execute("NOW = os.time({year = 2024, month = 2, day = 1, hour = 23, min = 59, sec = 30})")
        before = self.ev("NS.Day()")
        self.lua.execute("NOW = NOW + 60")
        self.assertEqual(self.ev("NS.Day()"), before + 1)

    def test_day_stays_the_same_for_23_hours_inside_one_local_day(self):
        self.use_local_os_clock()
        self.lua.execute("NOW = os.time({year = 2024, month = 2, day = 1, hour = 0, min = 30, sec = 0})")
        first = self.ev("NS.Day()")
        self.lua.execute("NOW = NOW + 23 * 60 * 60")
        self.assertEqual(self.ev("NS.Day()"), first)

    def test_until_next_local_midnight(self):
        self.use_local_os_clock()
        self.lua.execute("NOW = os.time({year = 2024, month = 2, day = 1, hour = 23, min = 0, sec = 0})")
        self.assertAlmostEqual(self.ev("NS.UntilNextDay()"), 3600, delta=1)
        self.lua.execute("NOW = os.time({year = 2024, month = 2, day = 1, hour = 0, min = 0, sec = 0})")
        self.assertEqual(self.ev("NS.UntilNextDay()"), 86400)

    @unittest.skipUnless(hasattr(time, "tzset"), "Python's time.tzset is unavailable; cannot set a test time zone")
    def test_day_advances_once_at_midnight_across_daylight_saving_changes(self):
        old_tz = os.environ.get("TZ")
        try:
            os.environ["TZ"] = "Europe/Berlin"
            time.tzset()
            self.use_local_os_clock()
            for month, day, next_month, next_day, hours in (
                (3, 31, 4, 1, 23),
                (10, 27, 10, 28, 25),
            ):
                start = self.ev(f"os.time({{year = 2024, month = {month}, day = {day}, hour = 0, min = 0, sec = 0}})")
                next_midnight = self.ev(f"os.time({{year = 2024, month = {next_month}, day = {next_day}, hour = 0, min = 0, sec = 0}})")
                self.assertEqual(next_midnight - start, hours * 3600)
                self.assertEqual(self.ev(f"NS.Day({next_midnight - 1})"), self.ev(f"NS.Day({start})"))
                self.assertEqual(self.ev(f"NS.Day({next_midnight})"), self.ev(f"NS.Day({start})") + 1)
                self.assertEqual(self.ev(f"NS.UntilNextDay({start})"), hours * 3600)
        finally:
            if old_tz is None:
                os.environ.pop("TZ", None)
            else:
                os.environ["TZ"] = old_tz
            time.tzset()


if __name__ == "__main__":
    unittest.main()
