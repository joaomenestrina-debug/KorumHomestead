"""The screens of the daily return (T1.5): the "While you were away" card, the order of the day in the Market, the icon."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

HOUR = 3600


class Base(unittest.TestCase):
    SAVED = None
    setUp_ = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press

    def setUp(self):
        self.setUp_()
        self.lua.execute("""
            function date(format, at) return os.date(format, at or NOW) end
            NS.db.newsSeen = 1000; NS.db.tutorial.done = true; NS.db.seen.market = true
        """)

    def close(self):
        self.lua.execute("KorumHomesteadFrame:Hide(); KorumHomesteadFrame:GetScript('OnHide')(KorumHomesteadFrame)")

    def card(self):
        return self.ev("NS.UI.away ~= nil and NS.UI.away:IsShown()")


class AwayCard(Base):
    def village(self):
        self.lua.execute("""
            local db = NS.db
            db.coins = 5000
            db.buildings.hall = 5; db.buildings.mine = 2; db.buildings.inn = 1
            NS.Farm:Plant(1, 2447); NS.Farm:Plant(2, 2447)
            NS.db.goods.fish = 10; NS.Inn:Start(1, "short")
        """)

    def test_the_card_opens_after_eight_hours_and_collects_everything(self):
        self.village()
        self.open("village")
        self.close()
        self.lua.execute(f"NOW = NOW + 8 * {HOUR}")
        self.open("village")
        self.assertTrue(self.card())
        self.assertEqual(self.ev("NS.UI.away.card.lines[1].text:GetText()"), "2 plots are ready to harvest")
        self.assertEqual(self.ev("NS.UI.away.card.lines[2].text:GetText()"), "1 follower came back from a mission")
        self.assertEqual(self.ev("NS.UI.away.card.lines[3].text:GetText()"), "Made:")
        self.assertTrue(self.ev("NS.UI.away.card.collect.enabledState"))
        self.press("NS.UI.away.card.collect")
        self.assertFalse(self.card())
        self.assertEqual(self.ev("NS.Farm:ReadyCount()"), 0)
        self.assertEqual(self.ev("NS.Inn:BackCount()"), 0)

    def test_a_short_time_away_shows_no_card(self):
        self.village()
        self.open("village")
        self.close()
        self.lua.execute("NOW = NOW + 600")
        self.open("village")
        self.assertFalse(self.card())

    def test_the_first_opening_after_the_update_shows_no_card(self):
        self.village()
        self.lua.execute(f"NOW = NOW + 8 * {HOUR}")
        self.open("village")
        self.assertFalse(self.card())

    def test_close_only_closes(self):
        self.village()
        self.open("village")
        self.close()
        self.lua.execute(f"NOW = NOW + 8 * {HOUR}")
        self.open("village")
        self.press("NS.UI.away.card.close")
        self.assertFalse(self.card())
        self.assertEqual(self.ev("NS.Farm:ReadyCount()"), 2)

    def test_the_card_reminds_the_order_of_the_day(self):
        self.village()
        self.open("village")
        self.close()
        self.lua.execute(f"NOW = NOW + 8 * {HOUR}")
        self.open("village")
        texts = [self.ev(f"NS.UI.away.card.lines[{i}].text:GetText()") for i in range(1, 7)]
        self.assertIn("The order of the day is waiting at the Market", texts)


class DailyInTheMarket(Base):
    def fill(self):
        self.lua.execute("local o = NS.Daily:Order(); NS.db.crops[o.plant] = o.qty")

    def test_the_order_of_the_day_is_on_top_and_delivers(self):
        self.open("orders")
        self.assertEqual(self.ev("NS.UI.screens.orders.daily.tag:GetText()"), "Order of the day")
        self.assertFalse(self.ev("NS.UI.screens.orders.daily.deliver.enabledState"))
        self.fill()
        self.open("orders")
        self.assertTrue(self.ev("NS.UI.screens.orders.daily.deliver.enabledState"))
        before = self.ev("NS.db.coins")
        self.press("NS.UI.screens.orders.daily.deliver")
        self.assertGreater(self.ev("NS.db.coins"), before)
        self.assertTrue(self.ev("NS.Daily:Done()"))
        self.assertEqual(self.ev("NS.UI.screens.orders.daily.deliver.label:GetText()"), "Tomorrow")
        self.assertEqual(self.ev("NS.UI.screens.orders.daily.streak:GetText()"), "Streak: 1 day · prize on day 3 (2 to go)")

    def test_the_streak_prize_is_announced(self):
        for day in range(3):
            self.fill()
            self.open("orders")
            self.press("NS.UI.screens.orders.daily.deliver")
            if day < 2:
                self.lua.execute(f"NOW = NOW + 24 * {HOUR}; NS.UI:Tick()")
        self.assertEqual(self.ev("NS.Daily:Streak()"), 3)
        self.assertTrue(self.ev("NS.UI.msg:find('Day 3 of your streak') ~= nil"))

    def test_the_icon_counts_the_order_of_the_day_when_it_can_be_delivered(self):
        self.fill()          # (the same herbs may fill a normal order too: those count on their own)
        self.lua.execute("NS.UI:UpdateBadge()")
        normal = self.ev("(function() local n = 0; for i = 1, NS.Data.ORDER_SLOTS do if NS.Orders:CanDeliver(i) then n = n + 1 end end; return n end)()")
        self.assertEqual(int(self.ev("NS.UI.bubble.badge.text:GetText()")), normal + 1)

    def test_every_new_text_exists_in_both_languages(self):
        for key in ("awayH", "awayCollect", "dailyTag", "dailyStreak", "streakRare", "why_done"):
            self.assertTrue(self.ev(f"NS.L.enUS['{key}'] ~= nil and NS.L.ptBR['{key}'] ~= nil"), key)


if __name__ == "__main__":
    unittest.main()
