"""Makes what the CurseForge page of Korum Homestead needs: the logo (400x400) and screenshots in English.

    python ferramentas/curse_homestead.py

Everything goes to arquivo/publicar/curse/. The screenshots come from the UI simulator, which draws the herbs' icons itself
(the game's own icons are not available outside the game), so screenshots taken in the game are better where possible.
"""
import pathlib
import sys

from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import simulador_ui as sim  # noqa: E402

ROOT = sim.ROOT
OUT = ROOT / "arquivo" / "publicar" / "curse"


def logo():
    art = Image.open(ROOT / "arquivo" / "arte_v3" / "logo.png").convert("RGBA")       # 32x32, the real grid
    big = art.resize((art.width * 12, art.height * 12), Image.NEAREST)                # 384x384, sharp
    canvas = Image.new("RGBA", (400, 400), (13, 17, 20, 255))
    canvas.alpha_composite(big, ((400 - big.width) // 2, (400 - big.height) // 2))
    canvas.convert("RGB").save(OUT / "logo-400.png")


def screens():
    now = 1700000000
    seen = "seen = {hall = true, garden = true, barn = true, market = true, mine = true, pond = true, workshop = true, inn = true},"
    mid = ("{coins = 1240, xp = 150, level = 6, nplots = 5, selected = 2450, tutorial = {done = true}, lang = 'enUS', " + seen +
           " stats = {harvested = 412, earned = 3980, delivered = 9},"
           " buildings = {hall = 5, garden = 4, barn = 3, market = 2, mine = 2, pond = 3, workshop = 3, inn = 3},"
           " goods = {ore = 34, fish = 18, heal = 2},"
           f" work = {{id = 'barn', at = {now - 200}, time = 480}},"
           f" plots = {{[1] = {{plant = 2450, at = {now - 2000}}}, [2] = {{plant = 2453, at = {now - 700}}},"
           f" [3] = {{plant = 785, at = {now - 330}}}, [4] = {{plant = 2447, at = {now - 20}}}}},"
           " crops = {[2447] = 14, [765] = 9, [2449] = 6, [785] = 12, [2450] = 5},"
           " orders = {{plant = 785, qty = 8, coins = 358, xp = 80, npc = 2}, {plant = 2450, qty = 7, coins = 560, xp = 122, npc = 4},"
           " {plant = 2449, qty = 4, coins = 115, xp = 24, npc = 1}}}")
    first = mid.replace(seen, "seen = {},")
    shots = [
        ("1-village", mid, "village", ""),
        ("2-garden", mid, "garden", ""),
        ("3-workshop", mid, "workshop", "NS.UI.trade = 'alchemy'; NS.Workshop:Craft('heal'); NS.Workshop:Craft('heal'); NS.UI:Refresh()"),
        ("4-inn", mid, "inn", "NS.Inn:Start(1, 'short'); NS.Inn:Start(2, 'medium'); NS.UI:Refresh()"),
        ("5-market", mid, "orders", ""),
        ("6-how-it-works", first, "hall", ""),
        ("7-guide", mid, "guide", "NS.UI.guidePage = 'buildings'; NS.UI:Refresh()"),
    ]
    for name, setup, view, after in shots:
        g = sim.Game("enUS")
        g.run("math.randomseed(11)")
        g.run("KorumHomesteadDB = " + setup)
        g.load("KorumHomestead", sim.HOMESTEAD)
        g.run(f"NS.UI:Show('{view}')")
        g.advance(2.0)
        if after:
            g.run(after)
            g.advance(0.6)
        print(g.shot(OUT / f"{name}.png", "KorumHomesteadFrame"))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    logo()
    screens()
