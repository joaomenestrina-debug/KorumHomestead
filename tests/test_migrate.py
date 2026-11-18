"""The saves of older versions open in this one, with nothing lost (Migrate.lua)."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402  (the same game state and helpers; the module, so its tests are not run twice)

SAVE_101 = (th.FIXTURES / "save-1.0.1.lua").read_text(encoding="utf-8")
VIEWS = ("village", "garden", "barn", "orders", "hall", "mine", "pond", "workshop", "inn", "guide", "settings")


class Base(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev
    open = th.Homestead.open
    press = th.Homestead.press


class SaveOf101(Base):
    """A real save of 1.0.1 (Herbalism 20, Hall 5, a follower away, ore, fish and a stew in the Barn)."""
    SAVED = SAVE_101

    def test_it_takes_the_current_shape(self):
        self.assertEqual(self.ev("NS.db.schema"), self.ev("NS.SCHEMA"))
        self.assertEqual(self.ev("NS.SCHEMA"), 3)

    def test_nothing_the_player_had_is_lost(self):
        self.assertEqual(self.ev("NS.db.coins"), 16846)
        self.assertEqual(self.ev("NS.db.level"), 37)             # Herbalism 20 (all 13 herbs) -> Village 37
        self.assertEqual(self.ev("NS.db.nplots"), 6)
        self.assertEqual(self.ev("NS.db.stats.earned"), 44486)
        self.assertEqual(self.ev("NS.db.stats.delivered"), 38)
        self.assertEqual(self.ev("NS.db.crops[3821]"), 27)
        for building, level in {"garden": 5, "market": 3, "workshop": 1, "hall": 5, "barn": 5, "pond": 2, "mine": 3, "inn": 1}.items():
            self.assertEqual(self.ev(f"NS.Village:Level('{building}')"), level, building)
        self.assertEqual(self.ev("NS.db.goods.stew"), 1)
        self.assertEqual(self.ev("NS.db.followers[1].mission.kind"), "long")
        self.assertEqual(self.ev("#NS.db.orders"), 8)                # the 3 old ones kept, 1 herb + 4 item orders added
        self.assertTrue(self.ev("NS.db.seen.workshop"))
        self.assertAlmostEqual(self.ev("NS.db.bubble.x"), 2218.67, places=1)

    def test_every_herb_the_player_had_is_still_open(self):
        for herb in (2447, 765, 2449, 785, 2450, 2453, 3355, 3356, 3357, 3818, 3821, 3358, 3369):
            self.assertLessEqual(self.ev(f"NS.Data.Plant({herb}).level"), self.ev("NS.db.level"), herb)
        self.assertEqual(self.ev("NS.db.xp"), 0)

    def test_the_old_orders_keep_their_herbs_and_take_the_new_prices(self):
        self.assertEqual(self.ev("NS.db.orders[1].plant"), 3818)
        self.assertEqual(self.ev("NS.db.orders[1].qty"), 10)
        self.assertEqual(self.ev("NS.db.orders[1].coins"), self.ev("math.floor(10 * NS.Data.Plant(3818).sell * NS.Balance.ORDERS.payMultiplier)"))

    def test_every_screen_opens(self):
        for view in VIEWS:
            self.open(view)
            self.assertEqual(self.ev("NS.UI.view"), view)
        self.assertEqual(self.ev("NS.UI.screens.barn.fill:GetText()").split(" ")[1], "27")

    def test_migrating_twice_changes_nothing(self):
        before = self.ev("NS.db.coins")
        self.assertEqual(self.ev("NS.Migrate(NS.db)"), self.ev("NS.SCHEMA"))
        self.assertEqual(self.ev("NS.db.coins"), before)


class NewHomestead(Base):
    def test_a_new_save_starts_in_the_current_shape(self):
        self.assertEqual(self.ev("NS.db.schema"), self.ev("NS.SCHEMA"))
        self.assertEqual(self.ev("NS.db.coins"), 40)


class SaveOfHerbalism5(Base):
    """A small save of 1.0 (Herbalism 5: Peacebloom to Briarthorn open)."""
    SAVED = "KorumHomesteadDB = {schema = 2, level = 5, xp = 30, coins = 300, nplots = 3, plots = {}, crops = {}, orders = {}}"

    def test_it_lands_where_briarthorn_opens(self):
        self.assertEqual(self.ev("NS.db.level"), self.ev("NS.Data.Plant(2450).level"))
        self.assertEqual(self.ev("NS.db.coins"), 300)


class SaveFromTheFuture(Base):
    """A save written by a newer version (the player went back to an older file): left as it is."""
    SAVED = "KorumHomesteadDB = {schema = 99, coins = 7, future = {kept = true}}"

    def test_it_is_left_alone(self):
        self.assertEqual(self.ev("NS.db.schema"), 99)
        self.assertEqual(self.ev("NS.db.coins"), 7)
        self.assertTrue(self.ev("NS.db.future.kept"))


if __name__ == "__main__":
    unittest.main()
