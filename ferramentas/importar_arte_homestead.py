"""Brings the pixel art of Korum Homestead into the addon.

    python ferramentas/importar_arte_homestead.py [pasta]        (default: arquivo/arte_v5)

A drawing in high resolution, `nome@hd.png`, wins: it goes into the game with no grid and no cleaning, reduced with a
good filter to near the size it shows at (see SIZE). Otherwise
the folder has every image twice: `nome.png` on the real pixel grid (128x128 buildings, 32x32 icons, 512x256 map) and
`nome@2x.png` (the same, doubled). This script takes the real grid, cleans the stray pixels that the drawing left at the edges
of the images, doubles it again with no smoothing (so what is in the game is exactly what was drawn) and writes the 32-bit
TGA files the game reads into Media/Village (the logo into Media/logo.tga).
"""
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "Media" / "Village"
LOGO = ROOT / "Media" / "logo.tga"

BUILDINGS = ["hall", "garden", "barn", "market", "mine", "pond", "workshop", "inn"]
# the goods (ore, fish, potions, meals, tools) use the icons of items of the game, not drawings
NAMES = (["map", "works", "lot", "logo"]
         + [f"{b}{t}" for b in BUILDINGS for t in (1, 2, 3)] + [f"follower{i}" for i in range(1, 19)]
         # the random events (arte_v4): the visitors' cart on the map and the three visitors
         + ["cart", "visitor_merchant", "visitor_caravan", "visitor_messenger"]
         # the Feast of Winter Veil (arte_v6, A7): the snowy map and three decorations
         + ["map_winter", "winter_tree", "snowman", "gifts"])
KEEP_WHOLE = {"map", "map_winter", "works"}
# the logo shows at 24-44 px: the 32 px pixel drawing reads there, the detailed high-resolution one turns to mush
OLD_GRID = {"logo": "arte_v3"}
# the width each high-resolution drawing goes into the game at (the rest: 256)
SIZE = {"map": 1024, "map_winter": 1024, "logo": 64, "visitor_merchant": 128, "visitor_caravan": 128, "visitor_messenger": 128,
        **{f"follower{i}": 128 for i in range(1, 19)}}           # one piece by nature: nothing is a stray pixel there


def pieces(alpha):
    """Connected pieces (8 neighbours) of the opaque pixels: [(size, min x, max x, [(x, y), ...]), ...], the biggest first."""
    w, h = alpha.size
    px = alpha.load()
    seen = set()
    out = []
    for y in range(h):
        for x in range(w):
            if px[x, y] and (x, y) not in seen:
                stack, cells = [(x, y)], []
                seen.add((x, y))
                while stack:
                    cx, cy = stack.pop()
                    cells.append((cx, cy))
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if 0 <= nx < w and 0 <= ny < h and px[nx, ny] and (nx, ny) not in seen:
                                seen.add((nx, ny))
                                stack.append((nx, ny))
                xs = [c[0] for c in cells]
                out.append((len(cells), min(xs), max(xs), cells))
    return sorted(out, key=lambda p: -p[0])


def clean(img):
    """Takes away the specks and the slivers of the neighbouring drawing at the left and right edges. Returns how many pixels."""
    w, _ = img.size
    alpha = img.getchannel("A")
    removed = 0
    px = img.load()
    for n, lo, hi, cells in pieces(alpha)[1:]:
        if n < 12 or (n < 1200 and (lo <= 10 or hi >= w - 10)):
            for x, y in cells:
                px[x, y] = (0, 0, 0, 0)
            removed += n
    return removed


def unmatte(img):
    """The map came with a light matte outside its rounded corners that is opaque: it is made transparent, by flooding in from
    the four corners over pixels of that colour."""
    w, h = img.size
    px = img.load()
    matte = px[0, 0][:3]
    seen, stack = set(), [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if a != 0 and max(abs(r - matte[0]), abs(g - matte[1]), abs(b - matte[2])) > 14:
            continue
        px[x, y] = (0, 0, 0, 0)
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    # what is left of the light edge: bright, colourless pixels in the outermost ring
    for y in range(h):
        for x in range(w):
            if min(x, y, w - 1 - x, h - 1 - y) < 24:
                r, g, b, al = px[x, y]
                if al and min(r, g, b) > 170 and max(r, g, b) - min(r, g, b) < 40:
                    px[x, y] = (0, 0, 0, 0)
                    seen.add((x, y))
    return len(seen)


def main():
    src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "arquivo" / "arte_v5"
    OUT.mkdir(parents=True, exist_ok=True)
    total = 0
    done, missing = 0, []
    for name in NAMES:
        hd = src / f"{name}@hd.png"
        if name in OLD_GRID:                                # drawn on purpose for its small size: the old one stays
            hd = ROOT / "arquivo" / OLD_GRID[name] / "none"
        if hd.exists():
            # the high-resolution drawing: no grid and no cleaning, only made to the size it shows at in the game
            done += 1
            art = Image.open(hd).convert("RGBA")
            # The game does not smooth a texture drawn much smaller than it is (no mipmaps for addon images): it skips
            # pixels, and a big drawing shown small sparkles with noise. So each drawing is made here, with a good filter,
            # close to the size it shows at (at most ~2.5x of it): the 24 px logo from 64, the 42-64 px portraits from
            # 128, the ~92 px buildings and cart from 256, the ~640 px map from 1024 x 512.
            w = SIZE.get(name, 256)
            h = max(1, round(w * art.height / art.width))
            h = 1 << (h - 1).bit_length()
            if (w, h) != art.size:
                art = art.resize((w, h), Image.LANCZOS)
            art.save(LOGO if name == "logo" else OUT / f"{name}.tga", compression=None)
            continue
        here = ROOT / "arquivo" / OLD_GRID[name] if name in OLD_GRID else src
        if not (here / f"{name}.png").exists():          # a round of art may bring only some of the images
            missing.append(name)
            continue
        done += 1
        native = Image.open(here / f"{name}.png").convert("RGBA")
        if name == "map":
            total += unmatte(native)
        if name not in KEEP_WHOLE:
            total += clean(native)
        big = native.resize((native.width * 2, native.height * 2), Image.NEAREST)
        big.save(LOGO if name == "logo" else OUT / f"{name}.tga", compression=None)
    print(f"{done} imagens em {OUT}; {total} pixels soltos tirados" + (f"; ausentes nesta pasta: {', '.join(missing)}" if missing else ""))


if __name__ == "__main__":
    main()
