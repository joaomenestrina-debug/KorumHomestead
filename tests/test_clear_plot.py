"""Pulling up a growing plot (Farm:Clear and the x of the Garden): the seed is lost, the plot is free again."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class ClearPlot(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def plant(self):
        self.lua.execute("NS.db.coins = 500; NS.db.tutorial.done = true; NS.db.seen.garden = true; NS.Farm:Plant(1, 2447)")

    def test_a_growing_plot_is_pulled_up_and_the_seed_is_lost(self):
        self.plant()
        coins = self.ev("NS.db.coins")
        self.assertTrue(self.ev("(NS.Farm:Clear(1))"))
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "empty")
        self.assertEqual(self.ev("NS.db.coins"), coins)
        self.assertEqual(self.ev("NS.db.stats.harvested"), 0)

    def test_only_a_growing_plot_can_be_pulled_up(self):
        self.assertEqual(tuple(self.lua.eval("function() return NS.Farm:Clear(1) end")()), (False, "notGrowing"))
        self.plant()
        self.lua.execute("NOW = NOW + 3600")                      # ready: it is harvested, never pulled up
        self.assertEqual(tuple(self.lua.eval("function() return NS.Farm:Clear(1) end")()), (False, "notGrowing"))
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "ready")

    def test_the_x_asks_first_and_pulls_up_on_the_second_click(self):
        self.plant()
        self.open("garden")
        self.assertTrue(self.ev("NS.UI.screens.garden.tiles[1].clear:IsShown()"))
        self.assertFalse(self.ev("NS.UI.screens.garden.tiles[2].clear:IsShown()"))
        self.press("NS.UI.screens.garden.tiles[1].clear")
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "growing")
        self.assertIn("again", self.ev("NS.UI.msg"))
        self.press("NS.UI.screens.garden.tiles[1].clear")
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "empty")
        self.assertFalse(self.ev("NS.UI.screens.garden.tiles[1].clear:IsShown()"))

    def test_a_late_second_click_only_asks_again(self):
        self.plant()
        self.open("garden")
        self.press("NS.UI.screens.garden.tiles[1].clear")
        self.lua.execute("NOW = NOW + 6")
        self.press("NS.UI.screens.garden.tiles[1].clear")
        self.assertEqual(self.ev("(NS.Farm:Status(1))"), "growing")


if __name__ == "__main__":
    unittest.main()
