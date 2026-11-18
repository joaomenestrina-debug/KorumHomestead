"""The buildings walk with the Village (docs/economia.md, rule 6): each building level asks a Village level, and costs hours
of what the Garden earns there; the whole village is not bought in a weekend any more."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class BuildingsWalkWithTheVillage(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev

    def test_a_building_level_asks_its_village_level(self):
        self.lua.execute("NS.db.coins = 100000000; NS.db.goods.ore = 1000")
        for n in range(2, 8):
            gate = self.ev(f"NS.Balance.BUILD_GATE[{n}]")
            self.lua.execute(f"NS.db.buildings.hall = {n - 1}; NS.db.work = nil; NS.db.level = {gate - 1}")
            self.assertEqual(tuple(self.lua.eval("function() return NS.Village:CanUpgrade('hall') end")()), (False, "village", gate), n)
            self.lua.execute(f"NS.db.level = {gate}")
            self.assertTrue(self.ev("(NS.Village:CanUpgrade('hall'))"), n)

    def test_a_building_already_above_its_gate_is_kept(self):
        self.lua.execute("NS.db.buildings.market = 6; NS.db.level = 10")
        self.assertEqual(self.ev("NS.Village:Level('market')"), 6)

    def test_the_cost_is_hours_of_the_garden_at_the_gate(self):
        for b in ("hall", "garden", "barn", "market", "mine", "pond", "workshop", "inn"):
            for n in range(2, 8):
                cost = self.ev(f"NS.Balance.COST.{b}[{n}]")
                hours = cost / self.ev(f"NS.Balance.GardenIncome(NS.Balance.BUILD_GATE[{n}], {n + 1})")
                expected = self.ev(f"NS.Balance.BUILD_HOURS[{n}] * NS.Balance.BUILD_WEIGHT.{b}")
                self.assertAlmostEqual(hours, expected, delta=expected * 0.06, msg=f"{b} {n}")

    def test_the_whole_village_takes_hundreds_of_hours_of_garden(self):
        hours = self.lua.eval("""function()
            local B, total = NS.Balance, 0
            for id, costs in pairs(B.COST) do
                for n, cost in ipairs(costs) do total = total + cost / B.GardenIncome(B.BUILD_GATE[n], n + 1) end
            end
            return total end""")()
        self.assertGreater(hours, 200)                 # it was ~20 hours before 2.0 (docs/economia.md)


if __name__ == "__main__":
    unittest.main()
