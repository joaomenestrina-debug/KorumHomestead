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
        self.assertEqual(self.ev("NS.SCHEMA"), 2)

    def test_nothing_the_player_had_is_lost(self):
        self.assertEqual(self.ev("NS.db.coins"), 16846)
        self.assertEqual(self.ev("NS.db.level"), 20)
        self.assertEqual(self.ev("NS.db.nplots"), 6)
        self.assertEqual(self.ev("NS.db.stats.earned"), 44486)
        self.assertEqual(self.ev("NS.db.stats.delivered"), 38)
        self.assertEqual(self.ev("NS.db.crops[3821]"), 27)
        for building, level in {"garden": 5, "market": 3, "workshop": 1, "hall": 5, "barn": 5, "pond": 2, "mine": 3, "inn": 1}.items():
            self.assertEqual(self.ev(f"NS.Village:Level('{building}')"), level, building)
        self.assertEqual(self.ev("NS.db.goods.stew"), 1)
        self.assertEqual(self.ev("NS.db.followers[1].mission.kind"), "long")
        self.assertEqual(self.ev("#NS.db.orders"), 3)
        self.assertTrue(self.ev("NS.db.seen.workshop"))
        self.assertAlmostEqual(self.ev("NS.db.bubble.x"), 2218.67, places=1)

    def test_every_screen_opens(self):
        for view in VIEWS:
            self.open(view)
            self.assertEqual(self.ev("NS.UI.view"), view)
        self.assertEqual(self.ev("NS.UI.screens.barn.stats:GetText()").split(" ")[0], "27")

    def test_migrating_twice_changes_nothing(self):
        before = self.ev("NS.db.coins")
        self.assertEqual(self.ev("NS.Migrate(NS.db)"), self.ev("NS.SCHEMA"))
        self.assertEqual(self.ev("NS.db.coins"), before)


class NewHomestead(Base):
    def test_a_new_save_starts_in_the_current_shape(self):
        self.assertEqual(self.ev("NS.db.schema"), self.ev("NS.SCHEMA"))
        self.assertEqual(self.ev("NS.db.coins"), 40)


class SaveFromTheFuture(Base):
    """A save written by a newer version (the player went back to an older file): left as it is."""
    SAVED = "KorumHomesteadDB = {schema = 99, coins = 7, future = {kept = true}}"

    def test_it_is_left_alone(self):
        self.assertEqual(self.ev("NS.db.schema"), 99)
        self.assertEqual(self.ev("NS.db.coins"), 7)
        self.assertTrue(self.ev("NS.db.future.kept"))


if __name__ == "__main__":
    unittest.main()
