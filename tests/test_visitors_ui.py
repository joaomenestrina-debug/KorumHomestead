"""The screens of the random events (T2.7): the Visitors screen, the cart on the map, the alert, the away card."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

HOUR = 3600


class Visitors(unittest.TestCase):
    SAVED = None
    setUp_ = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def setUp(self):
        self.setUp_()
        self.lua.execute("""
            NS.db.level = 30; NS.db.coins = 100000; NS.db.tutorial.done = true; NS.db.newsSeen = 1000
            NS.db.buildings.hall = 5; NS.db.buildings.mine = 2; NS.db.buildings.pond = 2; NS.db.buildings.workshop = 3
            for k in pairs(NS.db.seen) do NS.db.seen[k] = true end; NS.db.seen.market = true
            NS.Orders:Ensure()
        """)

    def test_no_visitors_no_cart(self):
        self.open("village")
        self.assertFalse(self.ev("NS.UI.screens.village.cart:IsShown()"))
        self.open("visitors")
        self.assertEqual(self.ev("NS.UI.screens.visitors.head:GetText()"), "No visitors now")

    def test_the_cart_leads_to_the_card_and_the_card_answers(self):
        self.lua.execute("NS.Events:Spawn('fish')")
        self.open("village")
        self.assertTrue(self.ev("NS.UI.screens.village.cart:IsShown()"))
        self.press("NS.UI.screens.village.cart")
        self.assertEqual(self.ev("NS.UI.view"), "visitors")
        v = "NS.UI.screens.visitors.cards[1]"
        self.assertEqual(self.ev(v + ".title:GetText()"), "Something rare in the Pond")
        key = self.ev("NS.Events:Open()[1].key")
        self.press(v + ".button")
        self.assertEqual(self.ev(f"NS.Village:Good('{key}')"), 1)
        self.assertFalse(self.ev(v + ":IsShown()"))

    def test_the_caravan_card_trades(self):
        self.lua.execute("""local e = NS.Events:Spawn('caravan'); local t = e.trades[1]
            if type(t.give) == 'number' then NS.db.crops[t.give] = t.n else NS.db.goods[t.give] = t.n end""")
        self.open("visitors")
        row = "NS.UI.screens.visitors.cards[1].trades[1]"
        self.assertTrue(self.ev(row + ".button.enabledState"))
        self.press(row + ".button")
        self.assertEqual(self.ev(row + ".button.label:GetText()"), "Done")

    def test_the_alert_says_who_came_and_the_time_left(self):
        self.lua.execute("NS.Events:Spawn('merchant'); NS.UI:UpdateBadge()")
        self.assertIn("A merchant wants", self.ev("KorumHomesteadIcon.alert.text:GetText()"))
        self.press("KorumHomesteadIcon.alert")
        self.assertEqual(self.ev("NS.UI.view"), "visitors")

    def test_the_away_card_tells_who_left(self):
        self.open("village")
        self.lua.execute("KorumHomesteadFrame:Hide(); KorumHomesteadFrame:GetScript('OnHide')(KorumHomesteadFrame)")
        self.lua.execute(f"NS.Events:Spawn('merchant'); NOW = NOW + 3 * {HOUR}; NS.db.events.nextAt = NOW + 99999; NS.Events:Update()")
        self.open("village")
        texts = [self.ev(f"NS.UI.away.card.lines[{i}].text:GetText()") for i in range(1, 7)]
        self.assertIn("The generous merchant left", texts)


if __name__ == "__main__":
    unittest.main()
