"""Advice (Advice.lua): what to craft and what to plant follows what the Market asks; with nothing asked, what pays most."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class Advice(unittest.TestCase):
    SAVED = None
    setUp_ = th.Homestead.setUp
    ev = th.Homestead.ev

    def setUp(self):
        self.setUp_()
        self.lua.execute("""
            NS.db.level = 20; NS.db.coins = 100000; NS.db.buildings.hall = 4; NS.db.buildings.workshop = 2
            NS.db.goods.ore = 100; NS.db.crops = {}
            NS.db.daily.done = true                                        -- the order of the day out of the way
            for i = 1, 8 do NS.db.orders[i] = nil end
        """)

    def advice(self, what, args=""):
        return tuple(self.lua.eval(f"function() return NS.Advice:{what}({args}) end")())

    def test_an_item_order_decides_the_craft(self):
        self.assertEqual(self.advice("Craft", "{'copper', 'bar'}"), ("bar", "value"))       # nothing asked: worth the most
        self.lua.execute("NS.db.orders[5] = {good = 'copper', qty = 3, coins = 1, xp = 1, npc = 1}")
        self.assertEqual(self.advice("Craft", "{'copper', 'bar'}"), ("copper", "order"))    # the Market asks for it
        self.lua.execute("NS.db.goods.copper = 3")
        self.assertEqual(self.advice("Craft", "{'copper', 'bar'}"), ("bar", "value"))       # already in the Barn

    def test_a_herb_order_decides_the_seed(self):
        best_value = self.advice("Seed")
        self.assertEqual(best_value[1], "value")
        self.lua.execute("NS.db.orders[1] = {plant = 765, qty = 5, coins = 1, xp = 1, npc = 1}")
        self.assertEqual(self.advice("Seed"), (765, "order"))

    def test_an_item_asked_asks_for_its_herbs(self):
        self.lua.execute("NS.db.orders[5] = {good = 'heal', qty = 2, coins = 1, xp = 1, npc = 1}")
        missing = self.lua.eval("NS.Advice:Missing()")
        self.assertEqual(missing["heal"], 2)
        self.assertEqual(missing[2447], 6)                       # 3 Peacebloom a potion
        self.assertEqual(self.advice("Seed")[1], "order")


if __name__ == "__main__":
    unittest.main()
