"""Checks every text of every screen of the simulator for room: the game's font is wider than the simulator's, so each
text is measured FACTOR times wider. It reports a text that leaves the window, and two texts that run into each other.
A text with a fixed width and no wrap is cut by the game ("..."), so it can not leave its place and is not checked.

    python ferramentas/conferir_textos.py          (the same scenes as simulador_ui.py, in ptBR and English)
"""
import pathlib
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import simulador_ui as S  # noqa: E402

FACTOR = 1.18          # how much wider the game's text runs than the simulator's (seen on the game's screenshots)
MARGIN = 6             # the window's border
problems = []
scene_name = ["?"]


def game_box(t):
    natural = S.measure(t["text"], t["size"], t["flags"], 0, False)[0]
    wide = natural * FACTOR
    if t["justify"] == "RIGHT":
        left = t["x"] + t["w"] - wide
    elif t["justify"] == "CENTER":
        left = t["x"] + (t["w"] - wide) / 2
    else:
        left = t["x"]
    return left, left + wide, t["y"], t["y"] + t["h"]


def check(game, frame_name):
    items = [dict(i.items()) for i in game.lua.eval("SIM.Dump()").values()]
    fx, fy, fw, fh = game.lua.eval(f"function() local r = SIM.Rect({frame_name}) return r[1], r[2], r[3], r[4] end")()
    texts = []
    for t in items:
        if t["kind"] == "texture" or t.get("skip") or not t["text"].strip() or t["alpha"] < 0.3:
            continue
        if not (fx <= t["x"] + t["w"] / 2 <= fx + fw and fy <= t["y"] <= fy + fh):
            continue                         # not in the window (the icon on the screen and its badge)
        if t["fixed"]:                       # a fixed width: cut ("...") or wrapped by the game; only its box must fit
            if t["x"] < fx + MARGIN or t["x"] + t["w"] > fx + fw - MARGIN:
                problems.append(f"{scene_name[0]}: caixa fora da janela: {S.plain(t['text'])[:70]!r}")
            elif not t["wrap"] and S.measure(t["text"], t["size"], t["flags"], 0, False)[0] * FACTOR > t["w"] + 1:
                problems.append(f"{scene_name[0]}: cortado com '...': {S.plain(t['text'])[:70]!r}")
            continue
        box = game_box(t)
        texts.append((t, box))
        if box[0] < fx + MARGIN or box[1] > fx + fw - MARGIN:
            problems.append(f"{scene_name[0]}: sai da janela: {S.plain(t['text'])[:70]!r}")
    for i, (a, ba) in enumerate(texts):
        for b, bb in texts[i + 1:]:
            if a.get("rel") == b.get("id") or b.get("rel") == a.get("id"):
                continue                     # one is placed beside the other: it moves with it in the game
            ox = min(ba[1], bb[1]) - max(ba[0], bb[0])
            oy = min(ba[3], bb[3]) - max(ba[2], bb[2])
            if ox > 2 and oy > 3 and abs(a["alpha"] - b["alpha"]) < 0.2:
                problems.append(f"{scene_name[0]}: sobreposto: {S.plain(a['text'])[:40]!r} x {S.plain(b['text'])[:40]!r}")


original = S.Game.shot


def shot(self, path, frame_name=None, **kw):
    scene_name[0] = pathlib.Path(path).stem
    if frame_name == "KorumHomesteadFrame":
        check(self, frame_name)
    return original(self, path, frame_name, **kw)


S.Game.shot = shot

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    with tempfile.TemporaryDirectory() as out:
        S.homestead(pathlib.Path(out))
    for p in sorted(set(problems)):
        print(p)
    print(f"{len(set(problems))} problema(s)")
