"""The zoom of the window (the - % + in the header): 60% to 150% in steps of 10%, kept in the save."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class Zoom(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def test_it_steps_and_stops_at_the_ends(self):
        self.open("village")
        z = "NS.UI.zoom"
        self.assertEqual(self.ev(z + ".value:GetText()"), "100%")
        for _ in range(10):
            self.press(z + ".minus")
        self.assertEqual(self.ev(z + ".value:GetText()"), "60%")
        self.assertAlmostEqual(self.ev("NS.db.scale"), 0.6)
        self.assertFalse(self.ev(z + ".minus.enabledState"))
        for _ in range(20):
            self.press(z + ".plus")
        self.assertEqual(self.ev(z + ".value:GetText()"), "150%")
        self.assertFalse(self.ev(z + ".plus.enabledState"))

    def test_a_strange_saved_value_is_brought_back_into_range(self):
        self.lua.execute("NS.db.scale = 9")
        self.open("village")
        self.assertAlmostEqual(self.ev("NS.db.scale"), 1.5)


if __name__ == "__main__":
    unittest.main()
