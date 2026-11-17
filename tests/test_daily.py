"""The extra Market order and delivery streak."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

SAVE_101 = (th.FIXTURES / "save-1.0.1.lua").read_text(encoding="utf-8")


class DailyOrders(unittest.TestCase):
    SAVED = None
    ev = th.Homestead.ev
    use_local_os_clock = th.Homestead.use_local_os_clock

    def setUp(self):
        th.Homestead.setUp(self)
        self.use_local_os_clock()
        self.ev("NS.Daily:Ensure()")

    def test_daily_order_is_saved_for_the_day_and_changes_on_a_new_day(self):
        self.assertEqual(self.ev("NS.db.daily.day"), self.ev("NS.Day()"))
        before = self.ev("NS.Daily:Order()")
        self.lua.execute('Fire("ADDON_LOADED", "KorumHomestead"); Fire("PLAYER_LOGIN")')
        same = self.ev("NS.Daily:Order()")
        self.assertEqual((before.plant, before.qty, before.coins, before.xp, before.npc),
                         (same.plant, same.qty, same.coins, same.xp, same.npc))
        self.lua.execute("NOW = NOW + 86400")
        self.assertTrue(self.ev("NS.Daily:Ensure()"))
        self.assertEqual(self.ev("NS.db.daily.day"), self.ev("NS.Day()"))
        self.assertFalse(self.ev("NS.Daily:Done()"))

    def test_daily_order_uses_the_normal_order_herb_and_scaled_pay(self):
        order = self.ev("NS.Daily:Order()")
        expected = self.ev("function() local o = NS.db.daily.order; local p = NS.Data.Plant(o.plant); local q = o.qty; return q, math.floor(q * p.sell * NS.Balance.ORDERS.payMultiplier * NS.Balance.DAILY.payMultiplier), math.floor(q * p.xp / NS.Balance.ORDERS.xpDivisor * NS.Balance.DAILY.payMultiplier) end")()
        self.assertEqual((order.qty, order.coins, order.xp), expected)

    def test_delivery_consumes_herbs_pays_and_cannot_repeat(self):
        self.lua.execute("local o = NS.Daily:Order(); NS.db.crops[o.plant] = o.qty")
        ok, result = self.lua.eval("function() return NS.Daily:Deliver() end")()
        self.assertTrue(ok)
        self.assertEqual(result.streak, 1)
        self.assertEqual(self.ev("NS.db.daily.done"), True)
        self.assertEqual(self.ev("NS.db.stats.delivered"), 1)
        self.assertEqual(self.ev("NS.db.stats.earned"), result.pay)
        self.assertFalse(self.ev("NS.db.crops[NS.db.daily.order.plant]"))
        ok, reason = self.lua.eval("function() return NS.Daily:Deliver() end")()
        self.assertFalse(ok)
        self.assertEqual(reason, "done")

    def test_delivery_without_the_requested_herbs_returns_missing(self):
        ok, reason = self.lua.eval("function() return NS.Daily:Deliver() end")()
        self.assertFalse(ok)
        self.assertEqual(reason, "missing")

    def test_next_prize_counts_days_and_uses_seven_day_steps_after_thirty(self):
        self.assertEqual(tuple(self.lua.eval("function() return NS.Daily:NextPrize() end")()), (3, 3))
        self.lua.execute("NS.db.daily.streak = 30; NS.db.daily.lastDone = NS.db.daily.day - 1")
        self.assertEqual(tuple(self.lua.eval("function() return NS.Daily:NextPrize() end")()), (37, 7))

    def test_three_day_streak_pays_day_three_prize_once_and_day_seven_gives_rare(self):
        for day in range(1, 8):
            if day > 1:
                self.lua.execute("NOW = NOW + 86400; NS.Daily:Ensure()")
            self.lua.execute("local o = NS.Daily:Order(); NS.db.crops[o.plant] = o.qty")
            ok, result = self.lua.eval("function() return NS.Daily:Deliver() end")()
            self.assertTrue(ok)
            self.assertEqual(result.streak, day)
            if day == 3:
                self.assertGreater(result.bonus, 0)
                self.assertEqual(result.rare, 0)
            if day == 7:
                self.assertEqual(result.rare, 1)
                self.assertEqual(self.ev("NS.db.daily.rare"), 1)

    def test_missing_a_day_resets_visible_streak_but_keeps_best(self):
        for day in range(3):
            if day:
                self.lua.execute("NOW = NOW + 86400; NS.Daily:Ensure()")
            self.lua.execute("local o = NS.Daily:Order(); NS.db.crops[o.plant] = o.qty; NS.Daily:Deliver()")
        self.assertEqual(self.ev("NS.db.daily.best"), 3)
        self.lua.execute("NOW = NOW + 2 * 86400")
        self.assertEqual(self.ev("NS.Daily:Streak()"), 0)
        self.lua.execute("NS.Daily:Ensure(); local o = NS.Daily:Order(); NS.db.crops[o.plant] = o.qty; NS.Daily:Deliver()")
        self.assertEqual(self.ev("NS.db.daily.streak"), 1)
        self.assertEqual(self.ev("NS.db.daily.best"), 3)

    def test_clock_going_back_does_not_change_daily_state(self):
        before = self.ev("NS.db.daily.order")
        self.lua.execute("NOW = NOW - 86400")
        self.assertFalse(self.ev("NS.Daily:Ensure()"))
        self.assertEqual(self.ev("NS.db.daily.day"), self.ev("NS.Day()") + 1)
        after = self.ev("NS.db.daily.order")
        self.assertEqual((before.plant, before.qty, before.coins, before.xp),
                         (after.plant, after.qty, after.coins, after.xp))

    def test_window_tick_ensures_the_new_day(self):
        day = self.ev("NS.db.daily.day")
        self.lua.execute("NOW = NOW + 86400; NS.UI:Tick()")
        self.assertEqual(self.ev("NS.db.daily.day"), day + 1)


class DailyOnOldSave(unittest.TestCase):
    SAVED = SAVE_101
    ev = th.Homestead.ev
    use_local_os_clock = th.Homestead.use_local_os_clock

    def setUp(self):
        th.Homestead.setUp(self)
        self.use_local_os_clock()
        self.ev("NS.Daily:Ensure()")

    def test_old_save_gets_daily_data_and_today_order(self):
        self.assertIsNotNone(self.ev("NS.db.daily"))
        self.assertEqual(self.ev("NS.db.daily.day"), self.ev("NS.Day()"))
        self.assertIsNotNone(self.ev("NS.db.daily.order"))


if __name__ == "__main__":
    unittest.main()
