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
    """A village in the middle of the game (Village 30, every building built), in English."""
    now = 1700000000
    seen = "seen = {hall = true, garden = true, barn = true, market = true, mine = true, pond = true, workshop = true, inn = true},"
    mid = ("{schema = 3, coins = 48200, xp = 2100, level = 30, selected = 3356, tutorial = {done = true}, newsSeen = 1000,"
           " lang = 'enUS', " + seen +
           " stats = {harvested = 4120, earned = 398000, delivered = 96},"
           " buildings = {hall = 5, garden = 5, barn = 4, market = 4, mine = 4, pond = 3, workshop = 4, inn = 4},"
           " goods = {ore = 64, fish = 38, heal = 4, healing = 2, stew = 3, bar = 5},"
           f" work = {{id = 'pond', at = {now - 900}, time = 3300}},"
           f" plots = {{[1] = {{plant = 3357, at = {now - 2000}}}, [2] = {{plant = 3356, at = {now - 300}}},"
           f" [3] = {{plant = 3356, at = {now - 120}}}, [4] = {{plant = 2453, at = {now - 600}}},"
           f" [5] = {{plant = 3369, at = {now - 40}}}, [6] = {{plant = 3355, at = {now - 2000}}}}},"
           " crops = {[2447] = 24, [765] = 19, [2449] = 16, [785] = 22, [2450] = 15, [2453] = 30, [3356] = 12, [3357] = 8, [3369] = 14}}")
    shots = [
        ("1-village", "village", "NS.Events:Spawn('merchant')", ""),
        ("2-garden", "garden", "", ""),
        ("3-workshop", "workshop", "", "NS.UI.trade = 'alchemy'; NS.Workshop:Craft('heal'); NS.Workshop:Craft('heal'); NS.UI:Refresh()"),
        ("4-inn", "inn", "", "NS.Inn:Start(1, 'short'); NS.Inn:Start(2, 'medium'); NS.Inn:Start(3, 'long'); NS.UI:Refresh()"),
        ("5-market", "orders", "", ""),
        ("6-visitors", "visitors", "NS.Events:Spawn('urgent'); local e = NS.Events:Spawn('caravan'); local t = e.trades[1];"
         " if type(t.give) == 'number' then NS.db.crops[t.give] = t.n else NS.db.goods[t.give] = t.n end", ""),
        ("7-barn", "barn", "", ""),
    ]
    for name, view, before, after in shots:
        g = sim.Game("enUS")
        g.run("math.randomseed(11)")
        g.run(f"SIM.clock = {now}")
        g.run("KorumHomesteadDB = " + mid)
        g.load("KorumHomestead", sim.HOMESTEAD)
        g.run("NS.Orders:Ensure()")
        if before:
            g.run(before)
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
