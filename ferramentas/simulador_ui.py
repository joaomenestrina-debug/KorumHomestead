"""Runs a Korum addon outside the game and paints its window to PNG files.

    python ferramentas/simulador_ui.py            the screens of Korum Homestead -> arquivo/telas/homestead/

The addon's Lua runs for real (lupa, Lua 5.1) against ferramentas/simulador_ui.lua, a stand-in for the client's UI that
resolves the anchors into rectangles. This file paints those rectangles with Pillow: the addon's own textures (TGA),
tints, texture coordinates, rotation, masks, additive blending, and the texts with their colour codes.

What it cannot be: the game. The font is a stand-in (the client's Friz Quadrata is not on disk), the herb icons are
drawn placeholders (the real ones live inside the game's data), and text metrics differ a little.
"""
import math
import pathlib
import re
import sys

from lupa import lua51
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
HERE = pathlib.Path(__file__).resolve().parent
S = 2                                   # pixels per UI unit (a sharp picture)
W, H = 1280, 720

FONT_FILES = ["C:/Windows/Fonts/candara.ttf", "C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"]
FONT_PATH = next((f for f in FONT_FILES if pathlib.Path(f).exists()), None)
_fonts = {}


def font(size):
    key = round(size * S)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(FONT_PATH, key) if FONT_PATH else ImageFont.load_default()
    return _fonts[key]


CODE = re.compile(r"\|c[0-9a-fA-F]{8}|\|r|\|T[^|]*\|t")


def runs(text, base):
    """'a |cffRRGGBBb|r c' -> [(text, (r, g, b)), ...]"""
    out, color, pos = [], base, 0
    for m in CODE.finditer(text):
        if m.start() > pos:
            out.append((text[pos:m.start()], color))
        tok = m.group(0)
        color = tuple(int(tok[i:i + 2], 16) for i in (4, 6, 8)) if tok.startswith("|c") else base
        pos = m.end()
    if pos < len(text):
        out.append((text[pos:], color))
    return out


def plain(text):
    return CODE.sub("", text).replace("|n", "\n")


def wrap(text, size, width):
    f = font(size)
    lines = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split(" "):
            trial = (cur + " " + word) if cur else word
            if cur and f.getlength(trial) / S > width:
                lines.append(cur)
                cur = word
            else:
                cur = trial
        lines.append(cur)
    return lines


def line_height(size):
    a, d = font(size).getmetrics()
    return (a + d) / S


def measure(text, size, flags, width, wrapped):
    text = plain(text or "")
    f = font(size)
    if width and width > 0 and wrapped:
        lines = wrap(text, size, width)
        return max((f.getlength(l) / S for l in lines), default=0), line_height(size) * max(1, len(lines))
    lines = text.split("\n")
    return max((f.getlength(l) / S for l in lines), default=0), line_height(size) * max(1, len(lines))


# ----------------------------------------------------------------------------------------------------------------
# Textures
# ----------------------------------------------------------------------------------------------------------------
_images = {}
HERB_HUES = {2447: (236, 232, 205), 765: (150, 200, 190), 2449: (150, 110, 70), 785: (190, 120, 220), 2450: (120, 150, 70),
             2453: (150, 110, 190), 3355: (120, 160, 220), 3356: (210, 70, 80), 3357: (110, 190, 110), 3818: (150, 170, 150),
             3821: (230, 190, 70), 3358: (200, 200, 235), 3369: (90, 130, 100)}


def herb_icon(item_id):
    """A drawn stand-in for a herb's icon: the real ones are inside the game's data."""
    n = 128
    hue = HERB_HUES.get(item_id, (160, 200, 160))
    img = Image.new("RGBA", (n, n), (18, 32, 28, 255))
    d = ImageDraw.Draw(img)
    for y in range(n):
        t = y / n
        d.line([(0, y), (n, y)], fill=(int(20 + 26 * t), int(44 + 30 * t), int(38 + 22 * t), 255))
    d.line([(64, 118), (60, 70)], fill=(70, 140, 80, 255), width=6)
    d.ellipse([28, 74, 62, 96], fill=(60, 130, 75, 255))
    d.ellipse([62, 82, 98, 102], fill=(70, 145, 85, 255))
    petals = 5 + item_id % 3
    for i in range(petals):
        a = 2 * math.pi * i / petals + (item_id % 7) * 0.2
        cx, cy = 60 + math.cos(a) * 20, 50 + math.sin(a) * 20
        d.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=hue + (255,))
    d.ellipse([49, 39, 71, 61], fill=(250, 215, 90, 255))
    return img.filter(ImageFilter.GaussianBlur(0.6))


def coin_icon():
    n = 128
    img = Image.new("RGBA", (n, n), (30, 26, 16, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([18, 18, 110, 110], fill=(214, 168, 60, 255))
    d.ellipse([30, 30, 98, 98], fill=(244, 206, 96, 255))
    return img


def circle_mask(size):
    m = Image.new("L", (size[0] * 4, size[1] * 4), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size[0] * 4 - 1, size[1] * 4 - 1], fill=255)
    return m.resize(size, Image.LANCZOS)


def load_texture(path, addon_dirs):
    if path is None:
        return None
    if isinstance(path, (int, float)):
        path = "icon:%d" % int(path)
    if path in _images:
        return _images[path]
    img = None
    low = path.replace("/", "\\").lower()
    if low.startswith("icon:"):
        img = herb_icon(int(low[5:]))
    elif "inv_misc_coin" in low:
        img = coin_icon()
    elif "minimap-trackingborder" in low:
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        ImageDraw.Draw(img).ellipse([4, 4, 72, 72], outline=(190, 160, 90, 255), width=6)
    else:
        for name, folder in addon_dirs.items():
            prefix = ("interface\\addons\\" + name + "\\").lower()
            if low.startswith(prefix):
                rel = path.replace("/", "\\")[len(prefix):].split("\\")
                base = folder.joinpath(*rel)
                for ext in ("", ".tga", ".png", ".blp"):
                    p = base.with_name(base.name + ext)
                    if p.is_file():
                        img = Image.open(p).convert("RGBA")
                        break
    _images[path] = img
    return img


def paint(items, addon_dirs, background):
    canvas = background.copy()
    for it in items:
        x, y, w, h, alpha = it["x"], it["y"], it["w"], it["h"], it["alpha"] or 0
        if alpha <= 0.003 or it.get("skip"):
            continue
        px, py = round(x * S), round((H - y - h) * S)
        pw, ph = max(0, round(w * S)), max(0, round(h * S))
        if it["kind"] == "texture":
            if pw < 1 or ph < 1:
                continue
            va = (it.get("va") if it.get("va") is not None else 1) * alpha
            tint = (it.get("vr", 1), it.get("vg", 1), it.get("vb", 1))
            if it.get("sa") is not None:
                col = tuple(int(255 * max(0, min(1, it[k] * t))) for k, t in zip(("sr", "sg", "sb"), tint))
                img = Image.new("RGBA", (pw, ph), col + (int(255 * max(0, min(1, it["sa"]))),))
            else:
                src = load_texture(it.get("texture"), addon_dirs)
                if src is None:
                    continue
                if it.get("c1") is not None:
                    sw, sh = src.size
                    box = (round(it["c1"] * sw), round(it["c3"] * sh), round(it["c2"] * sw), round(it["c4"] * sh))
                    if box[2] <= box[0] or box[3] <= box[1]:
                        continue
                    src = src.crop(box)
                img = src.resize((pw, ph), Image.LANCZOS)
                if it.get("desaturated"):
                    a = img.getchannel("A")
                    img = Image.merge("RGBA", (*Image.merge("RGB", [img.convert("L")] * 3).split(), a))
                if tint != (1, 1, 1):
                    r, g, b, a = img.split()
                    r, g, b = (ch.point(lambda v, t=t: int(v * max(0, min(1, t)))) for ch, t in zip((r, g, b), tint))
                    img = Image.merge("RGBA", (r, g, b, a))
            if it.get("masked"):
                img.putalpha(ImageChops.multiply(img.getchannel("A"), circle_mask(img.size)))
            if va < 0.999:
                img.putalpha(img.getchannel("A").point(lambda v: int(v * max(0, min(1, va)))))
            if it.get("rotation"):
                side = int(math.hypot(pw, ph)) + 4
                big = Image.new("RGBA", (side, side), (0, 0, 0, 0))
                big.paste(img, ((side - pw) // 2, (side - ph) // 2))
                img = big.rotate(math.degrees(it["rotation"]), resample=Image.BICUBIC)
                px, py = px - (side - pw) // 2, py - (side - ph) // 2
            if it.get("blend") == "ADD":
                layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
                layer.paste(img, (px, py))
                r, g, b, a = layer.split()
                lit = Image.merge("RGB", [ImageChops.multiply(ch, a) for ch in (r, g, b)])
                canvas = Image.merge("RGBA", (*ImageChops.add(canvas.convert("RGB"), lit).split(), canvas.getchannel("A")))
            else:
                canvas.alpha_composite(img, (px, py)) if (0 <= px and 0 <= py and px + img.size[0] <= canvas.size[0]
                                                           and py + img.size[1] <= canvas.size[1]) else _composite(canvas, img, px, py)
        else:
            text = it.get("text") or ""
            if not plain(text).strip():
                continue
            size = it.get("size") or 12
            f = font(size)
            base = tuple(int(255 * max(0, min(1, it.get(k) or 0))) for k in ("tr", "tg", "tb"))
            a = int(255 * max(0, min(1, alpha * (it.get("ta") or 1))))
            layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            d = ImageDraw.Draw(layer)
            lh = line_height(size) * S
            raw_lines = text.replace("|n", "\n").split("\n")
            if it.get("fixed") and it.get("wrap") and w > 0:
                # colour codes do not survive the wrap of this simulator; wrapped texts are plain in the addon
                raw_lines = wrap(plain(text), size, w)
            total = lh * len(raw_lines)
            top = py + (ph - total) / 2
            for i, line in enumerate(raw_lines):
                segs = runs(line, base)
                full = "".join(s for s, _ in segs)
                if it.get("fixed") and not it.get("wrap") and w > 0 and f.getlength(full) / S > w + 0.5:
                    while full and f.getlength(full + "...") / S > w:
                        full = full[:-1]
                    segs = [(full + "...", base)]
                length = sum(f.getlength(s) for s, _ in segs)
                j = (it.get("justify") or "CENTER").upper()
                cx = px if j == "LEFT" else (px + pw - length if j == "RIGHT" else px + (pw - length) / 2)
                cy = top + lh * i + lh / 2
                for s, col in segs:
                    kw = {}
                    if "OUTLINE" in (it.get("flags") or ""):
                        kw = {"stroke_width": S, "stroke_fill": (0, 0, 0, a)}
                    d.text((cx, cy), s, font=f, fill=col + (a,), anchor="lm", **kw)
                    cx += f.getlength(s)
            canvas = Image.alpha_composite(canvas, layer)
    return canvas


def _composite(canvas, img, px, py):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(img, (px, py))
    canvas.alpha_composite(layer)


def backdrop():
    """Something like a game behind the window, so the translucent surfaces read as they will."""
    img = Image.new("RGB", (W * S, H * S))
    d = ImageDraw.Draw(img)
    for y in range(H * S):
        t = y / (H * S)
        d.line([(0, y), (W * S, y)], fill=(int(64 + 60 * (1 - t)), int(96 + 40 * (1 - t)), int(120 - 30 * t)))
    d.polygon([(0, 900), (500, 620), (900, 820), (1500, 560), (2100, 800), (2560, 640), (2560, 1440), (0, 1440)], fill=(46, 78, 60))
    d.polygon([(0, 1100), (700, 940), (1500, 1060), (2560, 900), (2560, 1440), (0, 1440)], fill=(58, 92, 56))
    return img.filter(ImageFilter.GaussianBlur(18)).convert("RGBA")


# ----------------------------------------------------------------------------------------------------------------
# The game
# ----------------------------------------------------------------------------------------------------------------
class Game:
    def __init__(self, locale="enUS", names=None):
        lua = self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        lua.globals().PY_MEASURE = measure
        lua.execute((HERE / "simulador_ui.lua").read_text(encoding="utf-8"))
        lua.execute(f"SIM.locale = '{locale}'; SIM.W, SIM.H = {W}, {H}")
        lua.execute("ITEM_NAMES = {}; C_Item = {GetItemNameByID = function(id) return ITEM_NAMES[id] end, "
                    "GetItemIconByID = function(id) return 'icon:' .. id end, RequestLoadItemDataByID = function() end}")
        for item_id, name in (names or {}).items():
            lua.execute(f"ITEM_NAMES[{item_id}] = [[{name}]]")
        self.dirs = {}

    def load(self, addon, files):
        folder = ROOT if (ROOT / f"{addon}.toc").exists() else ROOT / "addons" / addon
        self.dirs[addon] = folder
        self.lua.execute("NS = NS or {}")
        for f in files:
            self.lua.eval("function(p, a) SIM.Load(p, a, NS) end")(str(folder / f), addon)
        self.lua.execute(f"SIM.Fire('ADDON_LOADED', '{addon}'); SIM.Fire('PLAYER_LOGIN')")

    def run(self, code):
        self.lua.execute(code)

    def advance(self, seconds):
        self.lua.execute(f"SIM.Advance({seconds})")

    def shot(self, path, frame_name=None, margin=36, right=0):
        items = [dict(i.items()) for i in self.lua.eval("SIM.Dump()").values()]
        img = paint(items, self.dirs, backdrop())
        if frame_name:
            x, y, w, h = self.lua.eval(f"function() local r = SIM.Rect({frame_name}) return r[1], r[2], r[3], r[4] end")()
            box = (max(0, round((x - margin) * S)), max(0, round((H - y - h - margin) * S)),
                   min(W * S, round((x + w + margin + right) * S)), min(H * S, round((H - y + margin) * S)))
            img = img.crop(box)
        path.parent.mkdir(parents=True, exist_ok=True)
        img.convert("RGB").save(path)
        return path


PT_NAMES = {2447: "Botão-da-paz", 765: "Folha-prata", 2449: "Raiz-telúrica", 785: "Magi-real", 2450: "Cardo-farpado",
            2453: "Erva-moura", 3355: "Aço-flor Selvagem", 3356: "Sangue-real", 3357: "Raiz-da-vida", 3818: "Folha-pálida",
            3821: "Espinheira-dourada", 3358: "Bigode-de-hadgar", 3369: "Musgo-de-túmulo"}
HOMESTEAD = [line.strip() for line in (ROOT / "KorumHomestead.toc").read_text(encoding="utf-8").splitlines()
             if line.strip().endswith(".lua")]


def homestead(out):
    made = []

    def scene(name, locale, setup, view, after="", settle=2.0):
        g = Game(locale, PT_NAMES if locale == "ptBR" else None)
        g.run("math.randomseed(11)")
        g.run("KorumHomesteadDB = " + setup)
        g.load("KorumHomestead", HOMESTEAD)
        g.run(f"NS.UI:Show('{view}')")
        g.advance(settle)
        if after:
            g.run(after)
            g.advance(0.6)
        made.append(g.shot(out / f"{name}.png", "KorumHomesteadFrame"))

    now = 1700000000
    mid = ("{coins = 1240, xp = 150, level = 6, nplots = 5, selected = 2450, tutorial = {done = true}, newsSeen = 1000,"
           " seen = {hall = true, garden = true, barn = true, market = true, mine = true, pond = true, workshop = true, inn = true},"
           " stats = {harvested = 412, earned = 3980, delivered = 9},"
           " buildings = {hall = 4, garden = 4, barn = 3, market = 2, mine = 2, pond = 3, workshop = 2, inn = 3}, goods = {ore = 34, fish = 18, heal = 2},"
           f" work = {{id = 'barn', at = {now - 200}, time = 480}},"
           f" plots = {{[1] = {{plant = 2450, at = {now - 2000}}}, [2] = {{plant = 2453, at = {now - 700}}},"
           f" [3] = {{plant = 785, at = {now - 330}}}, [4] = {{plant = 2447, at = {now - 20}}}}},"
           " crops = {[2447] = 14, [765] = 9, [2449] = 6, [785] = 12, [2450] = 5},"
           " orders = {{plant = 785, qty = 8, coins = 358, xp = 80, npc = 2}, {plant = 2450, qty = 7, coins = 560, xp = 122, npc = 4},"
           " {plant = 2449, qty = 4, coins = 115, xp = 24, npc = 1}}}")
    scene("1-vila-primeiro-uso", "ptBR", "{}", "village")
    scene("2-vila-em-jogo", "ptBR", mid, "village")
    first = mid.replace("seen = {hall = true, garden = true, barn = true, market = true, mine = true, pond = true, workshop = true, inn = true}", "seen = {}")
    scene("3a-sede-tutorial", "ptBR", first, "hall")
    scene("10c-oficina-tutorial", "ptBR", first, "workshop")
    scene("3-sede", "ptBR", mid, "hall")
    scene("4-horta", "ptBR", mid, "garden")
    scene("5-celeiro", "ptBR", mid, "barn")
    scene("6-mercado", "ptBR", mid, "orders")
    scene("7-village-english", "enUS", mid, "village")
    scene("10-oficina", "ptBR", mid, "workshop", after="NS.Workshop:Craft('heal'); NS.Workshop:Craft('heal'); NS.UI:Refresh()")
    scene("10b-oficina-culinaria", "ptBR", mid, "workshop", after="NS.UI.trade = 'cooking'; NS.Workshop:Craft('stew'); NS.UI:Refresh()")
    scene("11-estalagem", "ptBR", mid, "inn", after="NS.Inn:Start(1, 'short'); NS.Inn:Start(2, 'medium'); NS.db.followers[3] = {done = 4, mission = {kind = 'short', at = NS.Now() - 2000, time = 1800}}; NS.UI:Refresh()")
    scene("12-novidades", "ptBR", mid.replace("newsSeen = 1000", "newsSeen = 0"), "village", settle=5)
    scene("12b-whats-new-english", "enUS", mid.replace("newsSeen = 1000", "newsSeen = 0"), "village", settle=5)
    for i, page in enumerate(("start", "buildings", "herbs", "tips")):
        scene(f"9{i + 1}-guia-{page}", "ptBR", mid, "guide", after=f"NS.UI.guidePage = '{page}'; NS.UI:Refresh()")
    # the icon on the screen, with a notification coming out of it
    g = Game("ptBR", PT_NAMES)
    g.run("KorumHomesteadDB = " + mid)
    g.load("KorumHomestead", HOMESTEAD)
    g.advance(6.6)
    made.append(g.shot(out / "8-icone-na-tela.png", "KorumHomesteadIcon", margin=44, right=300))
    return made


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    target = ROOT / "arquivo" / "telas" / "homestead"
    for p in homestead(target):
        print(p)
