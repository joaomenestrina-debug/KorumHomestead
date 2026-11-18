"""The "What's new" screen (News.lua, UI/News.lua): it opens by itself once after an update, never for a new homestead."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

SAVE_101 = (th.FIXTURES / "save-1.0.1.lua").read_text(encoding="utf-8")


class Base(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def login(self):
        self.lua.execute('Fire("PLAYER_LOGIN"); RunTimers()')

    def shown(self):
        return self.ev("KorumHomesteadFrame and KorumHomesteadFrame:IsShown() and NS.UI.view") or None


class AfterAnUpdate(Base):
    SAVED = SAVE_101

    def test_the_window_opens_on_the_news_once(self):
        self.lua.execute("RunTimers()")
        self.assertEqual(self.shown(), "news")
        self.assertEqual(self.ev("NS.db.newsSeen"), self.ev("NS.LatestNews()"))
        self.assertEqual(self.ev("NS.UI.screens.news.pool[1].tag:GetText()"), "New")
        self.lua.execute("KorumHomesteadFrame:Hide()")
        self.login()
        self.assertIsNone(self.shown())

    def test_it_waits_for_a_fight_to_end(self):
        self.lua.execute("IN_COMBAT = true; function InCombatLockdown() return IN_COMBAT end; RunTimers(3)")
        self.assertIsNone(self.shown())
        self.lua.execute("IN_COMBAT = false; RunTimers()")
        self.assertEqual(self.shown(), "news")

    def test_every_entry_has_its_lines_in_both_languages(self):
        for i in range(1, self.ev("#NS.NEWS") + 1):
            entry = self.ev(f"NS.NEWS[{i}].id")
            self.assertEqual(self.ev(f"NS.NEWS[{i}].id"), i)
            n = 1
            while self.ev(f"NS.L.enUS['news{entry}_{n}'] ~= nil"):
                self.assertTrue(self.ev(f"NS.L.ptBR['news{entry}_{n}'] ~= nil"), f"news{entry}_{n}")
                n += 1
            self.assertGreater(n, 1, f"entry {entry} has no lines")

    def test_the_button_goes_to_the_village(self):
        self.lua.execute("RunTimers()")
        self.press("NS.UI.screens.news.go")
        self.assertEqual(self.shown(), "village")


class NewHomestead(Base):
    def test_a_new_player_does_not_get_old_news(self):
        self.lua.execute("RunTimers()")
        self.assertIsNone(self.shown())
        self.assertEqual(self.ev("NS.db.newsSeen"), self.ev("NS.LatestNews()"))

    def test_the_settings_open_the_news_without_marks(self):
        self.open("settings")
        self.press("NS.UI.screens.settings.news")
        self.assertEqual(self.shown(), "news")
        self.assertEqual(self.ev("NS.UI.screens.news.pool[1].tag:GetText()"), "")
        self.assertEqual(self.ev("NS.UI.screens.news.pool[2].text:GetText()"), self.ev("NS.T('news' .. NS.LatestNews() .. '_1')"))


if __name__ == "__main__":
    unittest.main()


class TheButtonOnTop(Base):
    def test_the_sparkle_on_top_opens_the_news_any_time(self):
        self.open("village")
        self.lua.execute("NS.UI.newsButton:GetScript('OnClick')(NS.UI.newsButton)")
        self.assertEqual(self.shown(), "news")
