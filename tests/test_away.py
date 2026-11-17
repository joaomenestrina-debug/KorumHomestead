"""While you were away (Away.lua): the summary of what happened with the window closed, and "Collect all"."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_homestead as th  # noqa: E402

SAVE_101 = (th.FIXTURES / "save-1.0.1.lua").read_text(encoding="utf-8")
HOUR = 3600


class Base(unittest.TestCase):
    SAVED = None
    setUp = th.Homestead.setUp
    ev = th.Homestead.ev

    def run_lua(self, code):
        self.lua.execute(code)

    def summary(self):
        return self.ev("NS.Away:Summary()")

    def goods(self, s):
        return {g["id"]: g["n"] for g in s["goods"].values()} if s["goods"] else {}


class Away(Base):
    def village(self):
        """A working homestead: Mine 2, Pond 1, a Workshop job, a follower out, plots growing; then the window is seen."""
        self.run_lua("""
            local db = NS.db
            db.coins = 5000
            db.buildings.hall = 5; db.buildings.mine = 2; db.buildings.pond = 1; db.buildings.workshop = 1; db.buildings.inn = 1
            db.buildings.barn = 7
            db.goods.fish = 30
            db.crops[2447] = 3; db.crops[765] = 1
            NS.Farm:Plant(1, 2447); NS.Farm:Plant(2, 2447)
            NS.Workshop:Craft("heal")
            NS.Inn:Start(1, "short")
            NS.Away:Mark()
        """)

    def test_a_new_homestead_has_nothing_to_tell(self):
        self.run_lua("NOW = NOW + 8 * 3600")
        self.assertIsNone(self.summary())

    def test_less_than_half_an_hour_is_not_away(self):
        self.village()
        self.run_lua(f"NOW = NOW + {30 * 60 - 1}")
        self.assertIsNone(self.summary())
        self.run_lua("NOW = NOW + 1")
        self.assertIsNotNone(self.summary())

    def test_eight_hours_away(self):
        self.village()
        ore_rate, fish_rate = self.ev("NS.Village:Rate('mine')"), self.ev("NS.Village:Rate('pond')")
        self.run_lua(f"NOW = NOW + 8 * {HOUR}")
        s = self.summary()
        self.assertEqual(s["seconds"], 8 * HOUR)
        self.assertEqual(s["ready"], 2)
        self.assertEqual(s["back"], 1)
        self.assertEqual(self.goods(s), {"ore": 8 * ore_rate, "fish": 8 * fish_rate, "heal": 1})
        self.assertEqual(list(s["built"].values()), [])

    def test_three_days_away_stops_at_what_the_barn_holds_and_tells_the_building_finished(self):
        self.village()
        self.run_lua("NS.db.work = {id = 'market', at = NOW, time = 600}")
        self.run_lua(f"NOW = NOW + 3 * 24 * {HOUR}")
        s = self.summary()
        cap = self.ev("NS.Village:BarnCap()")
        self.assertLessEqual(self.ev("NS.db.goods.ore"), cap)
        self.assertEqual(self.goods(s)["ore"], self.ev("NS.db.goods.ore"))
        self.assertEqual([(b["id"], b["level"]) for b in s["built"].values()], [("market", 2)])

    def test_marking_again_starts_a_new_count(self):
        self.village()
        self.run_lua(f"NOW = NOW + 8 * {HOUR}; NS.Away:Summary(); NS.Away:Mark(); NOW = NOW + {HOUR}")
        s = self.summary()
        self.assertEqual(self.goods(s).get("heal"), None)            # the potion was told last time
        self.assertEqual(self.goods(s)["ore"], self.ev("NS.Village:Rate('mine')"))

    def test_nothing_happened_means_no_card(self):
        self.run_lua(f"NS.Away:Mark(); NOW = NOW + 8 * {HOUR}")
        self.assertIsNone(self.summary())

    def test_collect_all_harvests_and_brings_the_followers_in(self):
        self.village()
        self.run_lua(f"NOW = NOW + 8 * {HOUR}")
        got = self.ev("NS.Away:CollectAll()")
        self.assertEqual(got["harvested"], 2 * self.ev("NS.Data.Yield(NS.Data.Plant(2447), NS.db.level)"))
        self.assertEqual(got["coins"], self.ev("NS.Inn.Mission('short').coins"))
        self.assertEqual(self.ev("NS.Farm:ReadyCount()"), 0)
        self.assertEqual(self.ev("NS.Inn:BackCount()"), 0)

    def test_the_stamp_survives_a_reload(self):
        self.village()
        self.run_lua(f"""
            NOW = NOW + 8 * {HOUR}
            KorumHomesteadDB = NS.db
            Fire("ADDON_LOADED", "KorumHomestead"); Fire("PLAYER_LOGIN")
        """)
        self.assertEqual(self.summary()["ready"], 2)


class SaveOf101(Base):
    SAVED = SAVE_101

    def test_an_old_save_has_no_stamp_the_first_time(self):
        self.assertEqual(self.ev("NS.db.lastSeen"), 0)
        self.assertIsNone(self.summary())
        self.run_lua(f"NOW = 1794960000; NS.Away:Mark(); NOW = NOW + 8 * {HOUR}")     # the clock of when the save was made
        self.assertIsNotNone(self.summary())


if __name__ == "__main__":
    unittest.main()
