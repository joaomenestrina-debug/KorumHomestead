"""The alert beside the floating icon: what waits, in words, growing out of the icon; a click opens the place."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class IconAlert(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    press = th.Homestead.press

    def alert(self):
        return self.ev("KorumHomesteadIcon.alert:IsShown() and KorumHomesteadIcon.alert.text:GetText()") or None

    def test_nothing_waits_no_alert(self):
        self.lua.execute("NS.UI:UpdateBadge()")
        self.assertIsNone(self.alert())

    def test_it_says_what_waits_and_opens_the_place(self):
        self.lua.execute("NS.db.tutorial.done = true; NS.db.seen.garden = true; NS.Farm:PlantAll(2447); NOW = NOW + 60; NS.UI:UpdateBadge()")
        self.assertEqual(self.alert(), "2 plots ready to harvest")
        self.press("KorumHomesteadIcon.alert")
        self.assertEqual(self.ev("NS.UI.view"), "garden")

    def test_more_than_one_thing_takes_turns(self):
        self.lua.execute("""NS.Farm:PlantAll(2447); NOW = NOW + 60
            local o = NS.db.orders[1]; NS.db.crops[o.plant] = (NS.db.crops[o.plant] or 0) + o.qty
            NS.UI:UpdateBadge()""")
        first = self.alert()
        self.lua.execute("local b = KorumHomesteadIcon; b:GetScript('OnUpdate')(b, 6.1)")
        self.assertNotEqual(self.alert(), first)

    def test_it_can_be_turned_off_in_the_settings(self):
        self.lua.execute("NS.Farm:PlantAll(2447); NOW = NOW + 60; NS.UI:UpdateBadge(); NS.db.tutorial.done = true")
        self.assertIsNotNone(self.alert())
        self.lua.execute("NS.UI:Show('settings')")
        self.press("NS.UI.screens.settings.label")
        self.assertFalse(self.ev("NS.db.bubble.label"))
        self.assertIsNone(self.alert())


if __name__ == "__main__":
    unittest.main()
