"""Prepares the copy of the game's own icons and font for the simulator (ferramentas/simulador_ui.py).

    python ferramentas/icones_do_jogo.py

1. Lists every item the addon shows (herbs, goods, Workshop items, the keepsake of the streak).
2. Asks the Wowhead of WoW Forever which icon each one uses.
3. Writes, in the folder of the game's files (KORUM_WOW_ASSETS, by default C:/AI/Tools/wowf_extract):
   item_icons.json (item -> icon) and homestead-listfile.csv (the icons and the fonts, with their numbers in the game's
   data, taken from the community listfile in C:/AI/Tools/listfile/community-listfile.csv).
4. Prints the command that copies those files out of the installed WoW Forever (CASCConsole, C:/AI/Tools/CASCConsole).

The copied files are Blizzard's: they stay on this computer and never go into the repository.
Run it again when the addon starts showing new items, then run the printed command.
"""
import json
import os
import pathlib
import re
import sys
import time
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tests"))

GAME = pathlib.Path(os.environ.get("KORUM_WOW_ASSETS", "C:/AI/Tools/wowf_extract"))
COMMUNITY = pathlib.Path("C:/AI/Tools/listfile/community-listfile.csv")
CASC = pathlib.Path("C:/AI/Tools/CASCConsole/CASCConsole.exe")
WOW = r"C:\Program Files (x86)\World of Warcraft"
FONTS = ["fonts/frizqt__.ttf", "fonts/arialn.ttf"]


def items():
    """Every item id the addon shows, read from the addon itself (the same loader as the tests)."""
    import test_homestead
    h = test_homestead.Homestead("test_a_new_homestead_has_two_plots_and_a_little_money")
    h.setUp()
    ids = h.lua.eval("""(function() local out = {}
        for _, p in ipairs(NS.Data.PLANTS) do out[#out + 1] = p[1] end
        for _, i in pairs(NS.Village.ITEM) do out[#out + 1] = i end
        out[#out + 1] = NS.Balance.DAILY.rareItem
        return table.concat(out, ",") end)()""")
    return sorted({int(i) for i in ids.split(",")})


def icon_of(item):
    req = urllib.request.Request(f"https://www.wowhead.com/forever/item={item}&xml", headers={"User-Agent": "Mozilla/5.0"})
    xml = urllib.request.urlopen(req, timeout=20).read().decode("utf-8", "replace")
    m = re.search(r"<icon[^>]*>([^<]+)</icon>", xml)
    return m.group(1).lower() if m else None


def main():
    GAME.mkdir(parents=True, exist_ok=True)
    old = GAME / "item_icons.json"
    icons = json.loads(old.read_text(encoding="utf-8")) if old.is_file() else {}
    for item in items():
        if not icons.get(str(item)):
            icons[str(item)] = icon_of(item)
            time.sleep(0.3)
    icons["qmark"] = "inv_misc_questionmark"
    old.write_text(json.dumps(icons, indent=1), encoding="utf-8")
    missing = [k for k, v in icons.items() if not v]
    want = {f"interface/icons/{v}.blp" for v in icons.values() if v} | set(FONTS)
    lines = []
    with open(COMMUNITY, encoding="utf-8", errors="replace") as f:
        for line in f:
            fid, _, path = line.rstrip("\n").partition(";")
            if path.lower() in want:
                lines.append(f"{fid};{path}")
    listfile = GAME / "homestead-listfile.csv"
    listfile.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    found = {l.split(";")[1].lower() for l in lines}
    print(f"{len(icons)} itens; {len(lines)} de {len(want)} arquivos achados na lista")
    if missing:
        print("sem ícone no Wowhead:", ", ".join(missing))
    if want - found:
        print("fora da lista da comunidade:", ", ".join(sorted(want - found)))
    print("\nCopie os arquivos do jogo com (PowerShell):")
    print(f'& "{CASC}" -m Listfile -e "{listfile}" -d "{GAME}" -l enUS -p wowf -s "{WOW}"')


if __name__ == "__main__":
    main()
