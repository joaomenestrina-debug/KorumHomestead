"""The Hall always shows the best upgrade for now ("Recommended"), to make the game easy to follow."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class Recommend(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open

    def best(self):
        return self.ev("(NS.Village:Recommend())")

    def test_the_garden_first_when_nothing_presses(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 3")
        self.assertEqual(self.best(), "garden")

    def test_the_hall_when_it_holds_the_others_back(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 2; NS.db.buildings.garden = 2")
        self.assertEqual(self.best(), "hall")

    def test_the_barn_when_it_is_almost_full(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 3; NS.db.crops[2447] = math.floor(NS.Village:BarnCap() * 0.9)")
        self.assertEqual(self.best(), "barn")

    def test_the_barn_when_the_ore_almost_fills_it(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 3; NS.db.buildings.mine = 1; NS.db.goods.ore = math.floor(NS.Village:BarnCap() * 0.9)")
        self.assertEqual(self.best(), "barn")

    def test_the_mine_screen_counts_its_ore_not_the_herbs(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 3; NS.db.buildings.mine = 1; NS.db.buildings.barn = 1;"
                         " NS.db.goods.ore = 7; NS.db.crops[2447] = 30; NS.db.tutorial.done = true; NS.db.seen.mine = true")
        self.open("mine")
        cap = self.ev("NS.Village:BarnCap()")
        self.assertEqual(self.ev("NS.UI.screens.mine.have:GetText()"), "In the barn: 7 / %d" % cap)

    def test_nothing_when_the_village_level_holds_everything(self):
        self.lua.execute("NS.db.level = 1")
        self.assertIsNone(self.best())

    def test_the_hall_screen_marks_it(self):
        self.lua.execute("NS.db.level = 60; NS.db.buildings.hall = 3; NS.db.coins = 10; NS.db.tutorial.done = true; NS.db.seen.hall = true")
        self.open("hall")
        rows = "NS.UI.screens.hall.rows"
        garden = [i for i in range(1, 9) if self.ev(f"{rows}[{i}].id") == "garden"][0]
        self.assertEqual(self.ev(f"{rows}[{garden}].tag:GetText()"), "Recommended")
        self.assertIn("Garden", self.ev("NS.UI.screens.hall.sub:GetText()"))
        others = [self.ev(f"{rows}[{i}].tag:GetText()") for i in range(1, 9) if i != garden]
        self.assertEqual(set(others), {""})


if __name__ == "__main__":
    unittest.main()
