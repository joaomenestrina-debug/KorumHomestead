"""The achievements (Achievements.lua, UI/Achievements.lua): every one visible with what it asks, an old save gets
what it already did quietly, each new one has its card, and the last one asks for all the others."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_dungeons as td  # noqa: E402


class Achievements(td.Base):
    def test_every_achievement_has_its_texts_and_a_reachable_goal(self):
        ids = self.lua.eval("(function() local o = {} for i, a in ipairs(NS.Achievements.LIST) do o[i] = a.id end return o end)()")
        ids = list(ids.values())
        self.assertGreaterEqual(len(ids), 50)
        self.assertEqual(len(ids), len(set(ids)))
        for lang in ("enUS", "ptBR"):
            for i in ids:
                for key in (f"ach_{i}", f"achd_{i}"):
                    self.assertTrue(self.ev(f"NS.L.{lang}['{key}'] ~= nil"), (lang, key))
        for cat in self.lua.eval("NS.Achievements.CATS").values():
            self.assertTrue(self.ev(f"NS.L.ptBR['achCat_{cat}'] ~= nil"), cat)
        self.assertEqual(ids[-1], "master")

    def test_an_old_save_gets_what_it_did_quietly_and_a_new_one_shows_its_card(self):
        self.lua.execute("NS.db.level = 21; NS.db.stats.harvested = 150; NS.db.achSeeded = nil; NS.db.achievements = nil")
        self.lua.execute("NS.UI:Tick()")
        for done in ("village10", "village20", "harvest100"):
            self.assertTrue(self.ev(f"NS.Achievements:Done('{done}') ~= nil"), done)
        self.assertIsNone(self.ev("NS.Achievements:Done('village30')"))
        self.assertFalse(self.ev("_G.KorumHomesteadAchievement ~= nil and _G.KorumHomesteadAchievement:IsShown()"))
        self.lua.execute("NS.db.stats.harvested = 1000; NS.UI:Tick()")
        self.assertTrue(self.ev("NS.Achievements:Done('harvest1k') ~= nil"))
        self.assertTrue(self.ev("_G.KorumHomesteadAchievement:IsShown()"))

    def test_the_counters_of_the_workshop_the_dungeons_and_the_calls(self):
        self.inn(mira=1)
        self.lua.execute("NS.db.goods.ore = 99; NS.db.buildings.workshop = 1")
        self.assertTrue(self.ev("(NS.Workshop:Craft('copper'))"))
        self.lua.execute("NOW = NOW + 99999; NS.Workshop:Update()")
        self.assertEqual(self.ev("NS.db.stats.crafted"), 1)
        self.lua.execute("NS.Rand = function() return 1 end; assert(NS.Dungeons:Send('ragefire', {'mira'})); NS.Rand = nil; "
                         "NOW = NOW + 99999; NS.Dungeons:CollectAll()")
        self.assertEqual(self.ev("NS.db.dungeons.done.ragefire"), 1)
        self.lua.execute("NS.Achievements:Check()")
        self.assertTrue(self.ev("NS.Achievements:Done('runs1') ~= nil"))

    def test_the_last_one_asks_for_all_the_others(self):
        self.lua.execute("for _, a in ipairs(NS.Achievements.LIST) do if a.id ~= 'master' and a.id ~= 'calls10' then "
                         "NS.db.achievements = NS.db.achievements or {}; NS.db.achievements[a.id] = 1 end end")
        self.lua.execute("NS.Achievements:Check()")
        self.assertIsNone(self.ev("NS.Achievements:Done('master')"))
        self.lua.execute("NS.db.dungeons.calls = 10; NS.Achievements:Check()")
        self.assertTrue(self.ev("NS.Achievements:Done('master') ~= nil"))
        have, total = self.lua.eval("function() return NS.Achievements:Points() end")()
        self.assertEqual(have, total)

    def test_the_screen_shows_the_ones_not_done_with_what_they_ask(self):
        self.lua.execute("NS.db.level = 5; NS.db.tutorial.done = true; NS.UI.achCat = 'village'")
        self.open("achievements")
        s = "NS.UI.screens.achievements"
        self.assertEqual(self.ev(s + ".rows[1].desc:GetText()"), "Reach Village level 10.")
        self.assertEqual(self.ev(s + ".rows[1].state:GetText()"), "5 / 10")
        self.press(s + ".cats[9]")                                           # the last one
        self.assertEqual(self.ev("NS.UI.achCat"), "final")
        self.assertIn("Master of the Homestead", self.ev(s + ".rows[1].name:GetText()"))



class Mayor(td.Base):
    def test_the_mayor_says_his_line_and_the_plain_text_when_he_has_none_or_is_off(self):
        self.assertEqual(self.ev("NS.Say('levelUp', 7)"), self.ev("NS.T('levelUp', 7)"))
        self.lua.execute("NS.L.enUS.mayor_craftDone_1 = 'Your %s is ready. Try not to break it.'")
        said = self.ev("NS.Say('craftDone', 'Stew')")
        self.assertIn("Mayor Ambrose", said)
        self.assertIn("Your Stew is ready. Try not to break it.", said)
        self.lua.execute("NS.db.mayor = false")
        self.assertEqual(self.ev("NS.Say('craftDone', 'Stew')"), self.ev("NS.T('craftDone', 'Stew')"))

if __name__ == "__main__":
    unittest.main()
