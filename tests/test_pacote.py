"""The zip the players download has only what the addon uses in the game (owner, 22/11): the code, the .toc and Media/.
Every other file of the repository is in the `ignore` of .pkgmeta (or starts with a dot, which the packager leaves out)."""
import pathlib
import subprocess
import unittest

HOME = pathlib.Path(__file__).resolve().parent.parent


class Package(unittest.TestCase):
    def test_only_the_files_of_the_game_go_in_the_zip(self):
        ignore = []
        inside = False
        for line in (HOME / ".pkgmeta").read_text(encoding="utf-8").splitlines():
            if line.startswith("ignore:"):
                inside = True
            elif inside and line.strip().startswith("- "):
                ignore.append(line.strip()[2:].strip())
            elif inside and line.strip() and not line.startswith(" "):
                inside = False
        files = subprocess.run(["git", "ls-files"], cwd=HOME, capture_output=True, text=True, check=True).stdout.split()
        shipped = []
        for f in files:
            top = f.split("/")[0]
            if top.startswith(".") or top in ignore or f in ignore:
                continue
            shipped.append(f)
        for f in shipped:
            self.assertTrue(f.endswith(".lua") or f.endswith(".toc") or f.startswith("Media/"), f)
        self.assertNotIn("Probe.lua", shipped)

    def test_the_probe_is_not_in_the_toc_of_the_zip(self):
        toc = (HOME / "KorumHomestead.toc").read_text(encoding="utf-8")
        start, probe, end = toc.index("#@do-not-package@"), toc.index("Probe.lua"), toc.index("#@end-do-not-package@")
        self.assertTrue(start < probe < end)


if __name__ == "__main__":
    unittest.main()
