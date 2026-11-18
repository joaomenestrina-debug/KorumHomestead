"""The owner's rule (docs/economia.md, rule 5): the Workshop always gives more coins and more xp than its raw materials,
for every recipe. And the Market has 4 herb orders and 4 Workshop item orders (rule 4)."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402


class CraftPaysMore(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev

    def recipes(self):
        return [self.ev(f"NS.Workshop.RECIPES[{i}].id") for i in range(1, self.ev("#NS.Workshop.RECIPES") + 1)]

    def raw(self, recipe):
        """What the inputs give without the Workshop: sold in herb orders (coins) and harvested + delivered (xp)."""
        return self.lua.eval(f"""function()
            local B, coins, xp = NS.Balance, 0, 0
            for _, input in ipairs(NS.Workshop.Recipe('{recipe}').inputs) do
                local key, n = input[1], input[2]
                if type(key) == 'string' then
                    coins = coins + n * NS.Village:GoodSell(key) * B.ORDERS.payMultiplier
                else
                    local p = NS.Data.Plant(key)
                    coins = coins + n * p.sell * B.ORDERS.payMultiplier
                    xp = xp + n * (p.xp / p.yield) * (1 + B.ORDERS.xpFactor)
                end
            end
            return coins, xp
        end""")()

    def test_every_recipe_pays_more_coins_than_its_raw_materials(self):
        for r in self.recipes():
            coins, _ = self.raw(r)
            value = self.ev(f"NS.Workshop.Value('{r}')")
            self.assertGreater(value * self.ev("NS.Balance.ORDERS.goodsPayMultiplier"), coins, r)   # in an order
            sold_raw = self.lua.eval(f"""function() local s = 0
                for _, i in ipairs(NS.Workshop.Recipe('{r}').inputs) do
                    s = s + i[2] * (type(i[1]) == 'string' and NS.Village:GoodSell(i[1]) or NS.Data.Plant(i[1]).sell) end
                return s end""")()
            self.assertGreater(value, sold_raw, r)                                                    # at the Barn

    def test_every_recipe_gives_more_xp_than_its_raw_materials(self):
        for r in self.recipes():
            _, xp = self.raw(r)
            craft = self.ev(f"NS.Workshop.XP('{r}')") * (1 + self.ev("NS.Balance.ORDERS.goodsXpFactor"))
            self.assertGreater(craft, xp, r)

    def test_crafting_gives_its_xp_when_it_finishes(self):
        self.lua.execute("""NS.db.buildings.hall = 5; NS.db.buildings.workshop = 1
            NS.db.crops[2447] = 3; NS.db.crops[765] = 1; NS.Workshop:Craft('heal')""")
        before = self.ev("NS.db.xp")
        self.lua.execute("NOW = NOW + 3600; NS.Workshop:Update()")
        self.assertEqual(self.ev("NS.db.xp") - before, self.ev("NS.Workshop.XP('heal')"))


class MarketFourAndFour(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def test_item_orders_come_with_the_workshop_and_are_delivered_from_the_barn(self):
        for i in range(5, 9):
            self.assertIsNone(self.ev(f"NS.db.orders[{i}]"))
        self.lua.execute("NS.db.buildings.hall = 5; NS.db.buildings.workshop = 1; NS.Orders:Ensure()")
        for i in range(1, 5):
            self.assertIsNotNone(self.ev(f"NS.db.orders[{i}].plant"))
        for i in range(5, 9):
            self.assertIn(self.ev(f"NS.db.orders[{i}].good"), ("heal", "stew", "copper"))  # the recipes open at Workshop 1
        self.lua.execute("local o = NS.db.orders[5]; o.good = 'heal'; NS.db.goods.heal = o.qty; NS.db.tutorial.done = true; NS.db.seen.market = true")
        coins, xp = self.ev("NS.db.coins"), self.ev("NS.db.orders[5].coins")
        self.open("orders")
        self.assertEqual(self.ev("NS.UI.screens.orders.rows[5].wants:GetText()"),
                         f"{self.ev('NS.db.orders[5].qty')} × " + self.ev("NS.T('good_heal')"))
        self.press("NS.UI.screens.orders.rows[5].deliver")
        self.assertEqual(self.ev("NS.db.goods.heal"), 0)
        self.assertGreater(self.ev("NS.db.coins"), coins)

    def test_without_the_workshop_the_item_column_says_how_to_get_it(self):
        self.lua.execute("NS.db.tutorial.done = true; NS.db.seen.market = true")
        self.open("orders")
        self.assertTrue(self.ev("NS.UI.screens.orders.rows[5].empty:IsShown()"))
        self.assertEqual(self.ev("NS.UI.screens.orders.rows[5].empty:GetText()"), self.ev("NS.T('ordersNoWorkshop')"))


if __name__ == "__main__":
    unittest.main()
