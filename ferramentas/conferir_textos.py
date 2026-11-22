"""Checks every text of every screen of the simulator for room: the game's font is wider than the simulator's, so each
text is measured FACTOR times wider. It reports a text that leaves the window, and two texts that run into each other.
A text with a fixed width and no wrap is cut by the game ("..."), so it can not leave its place and is not checked.

    python ferramentas/conferir_textos.py          (the scenes of simulador_ui.py and the extra ones, in ptBR and English)
    python ferramentas/conferir_textos.py PASTA    (the same, keeping the pictures of the extra scenes in PASTA)
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


def natural(t):
    return S.measure(t["text"], t["size"], t["flags"], 0, False)[0] * FACTOR


def game_box(t):
    """Where the text sits in the game: (left, right, bottom, top)."""
    if t["fixed"]:
        height = t["h"]
        if t["wrap"]:                                    # the game's wider letters break the lines sooner
            wide, tall = S.measure(t["text"], t["size"], t["flags"], t["w"] / FACTOR, True)
            wide = min(t["w"], wide * FACTOR)
            if not t["fixedh"]:
                height = tall
        else:
            wide = min(t["w"], natural(t))               # cut with "..." at the box
        if t["justify"] == "RIGHT":
            left = t["x"] + t["w"] - wide
        elif t["justify"] == "CENTER":
            left = t["x"] + (t["w"] - wide) / 2
        else:
            left = t["x"]
        right = left + wide
        if t["vanchor"] == "TOP":
            top = t["y"] + t["h"]
            return left, right, top - height, top
        if t["vanchor"] == "BOTTOM":
            return left, right, t["y"], t["y"] + height
        mid = t["y"] + t["h"] / 2
        return left, right, mid - height / 2, mid + height / 2
    wide = natural(t)
    if t["justify"] == "RIGHT":
        left = t["x"] + t["w"] - wide
    elif t["justify"] == "CENTER":
        left = t["x"] + (t["w"] - wide) / 2
    else:
        left = t["x"]
    return left, left + wide, t["y"], t["y"] + t["h"]


def check(game, frame_name):
    # the icon on the screen and its alert are not the window: out of the way while the window is checked
    shown = game.lua.eval("KorumHomesteadIcon ~= nil and KorumHomesteadIcon:IsShown()")
    if shown:
        game.lua.execute("KorumHomesteadIcon:Hide()")
    items = [dict(i.items()) for i in game.lua.eval("SIM.Dump()").values()]
    if shown:
        game.lua.execute("KorumHomesteadIcon:Show()")
    fx, fy, fw, fh = game.lua.eval(f"function() local r = SIM.Rect({frame_name}) return r[1], r[2], r[3], r[4] end")()
    texts = []

    def say(what, t):
        problems.append(f"{scene_name[0]}: {what}: {S.plain(t['text'])[:110]!r}")

    # a panel drawn later over a text (a menu, a lesson, the "while you were away" card) hides it: not a clash
    panels = [(n, i) for n, i in enumerate(items)
              if i["kind"] == "texture" and not i.get("skip") and i["w"] >= 150 and i["h"] >= 60
              and i["alpha"] * (i.get("sa") or 1) * (i.get("va") or 1) >= 0.7 and (i.get("sr") is not None or i.get("texture"))]

    def covered(n, box):
        return any(m > n and i["x"] <= box[0] + 2 and i["x"] + i["w"] >= box[1] - 2
                   and i["y"] <= box[2] + 2 and i["y"] + i["h"] >= box[3] - 2 for m, i in panels)

    for n, t in enumerate(items):
        if t["kind"] == "texture" or t.get("skip") or not t["text"].strip() or t["alpha"] < 0.3:
            continue
        t["n"] = n
        if not (fx <= t["x"] + t["w"] / 2 <= fx + fw and fy <= t["y"] <= fy + fh):
            continue                         # not in the window (the icon on the screen and its badge)
        box = game_box(t)
        if covered(n, (t["x"], t["x"] + t["w"], t["y"], t["y"] + t["h"])):
            continue
        texts.append((t, box))
        if box[0] < fx + MARGIN or box[1] > fx + fw - MARGIN:
            say("sai da janela", t)
        elif box[2] < fy + MARGIN or box[3] > fy + fh - MARGIN:
            say("sai da janela (altura)", t)
        if t["fixed"]:
            if not t["wrap"] and natural(t) > t["w"] + 1:
                say(f"cortado com '...' ({natural(t):.0f} > {t['w']:.0f})", t)
            elif t["wrap"] and t["fixedh"] and                     S.measure(t["text"], t["size"], t["flags"], t["w"] / FACTOR, True)[1] > t["h"] + 1:
                say("não cabe na altura", t)
            elif t["wrap"] and max(natural(dict(t, text=w)) for w in S.plain(t["text"]).split()) > t["w"] + 1:
                say("palavra maior que a caixa", t)
        # a text inside a button or a row never leaves it
        small = t["pw"] > 0 and t["ph"] > 0 and (t["pw"] < fw - 2 or t["ph"] < fh - 2)
        cx, cy = (box[0] + box[1]) / 2, (box[2] + box[3]) / 2
        if small and t["px"] <= cx <= t["px"] + t["pw"] and t["py"] <= cy <= t["py"] + t["ph"]:
            if abs(t["pw"] - natural(t) / FACTOR) <= 8:
                pass                         # the frame was sized from this text: it follows its real width in the game
            elif box[0] < t["px"] - 1 or box[1] > t["px"] + t["pw"] + 1:
                say("sai do seu quadro (largura)", t)
            elif t["ptype"] == "Button" and (box[2] < t["py"] - 1 or box[3] > t["py"] + t["ph"] + 1):
                say("sai do seu botão (altura)", t)
    for i, (a, ba) in enumerate(texts):
        for b, bb in texts[i + 1:]:
            if a.get("rel") == b.get("id") or b.get("rel") == a.get("id"):
                continue                     # one is placed beside the other: it moves with it in the game
            ox = min(ba[1], bb[1]) - max(ba[0], bb[0])
            oy = min(ba[3], bb[3]) - max(ba[2], bb[2])
            if ox > 2 and oy > 3 and abs(a["alpha"] - b["alpha"]) < 0.2:
                lo, hi = (a, b) if a["n"] < b["n"] else (b, a)
                inter = (max(ba[0], bb[0]), min(ba[1], bb[1]), max(ba[2], bb[2]), min(ba[3], bb[3]))
                if any(lo["n"] < m < hi["n"] and i["x"] <= inter[0] + 2 and i["x"] + i["w"] >= inter[1] - 2
                       and i["y"] <= inter[2] + 2 and i["y"] + i["h"] >= inter[3] - 2 for m, i in panels):
                    continue
                problems.append(f"{scene_name[0]}: sobreposto: {S.plain(a['text'])[:40]!r} x {S.plain(b['text'])[:40]!r}")


original = S.Game.shot


def shot(self, path, frame_name=None, **kw):
    scene_name[0] = pathlib.Path(path).stem
    if frame_name in ("KorumHomesteadFrame", "KorumHomesteadReminder"):
        check(self, frame_name)
    return original(self, path, frame_name, **kw)


S.Game.shot = shot

# every scene in both languages: a text that fits in one may not fit in the other
one_window = S.window


real_game = S.Game.__init__


def game(self, *a, **kw):
    real_game(self, *a, **kw)
    self.lua.execute(f"SIM.FACTOR = {FACTOR}")       # what the addon measures comes as wide as in the game


S.Game.__init__ = game


def both(path, locale, setup, view, **kw):
    other = "enUS" if locale == "ptBR" else "ptBR"
    one_window(path.with_name(path.stem + "~" + other + path.suffix), other, setup, view, **kw)
    return one_window(path, locale, setup, view, **kw)


S.window = both

FOLLOWERS = ("mira", "tobin", "elda", "garrick", "sela", "bram")
BUILDINGS = ("hall", "garden", "barn", "market", "mine", "pond", "workshop", "inn")
ALL = "{'mira', 'tobin', 'elda', 'garrick', 'sela', 'bram'}"


def extras(out):
    """The states the pictures of simulador_ui.py do not show: a village at the top with huge numbers, the mouse over
    each building, every trade, every follower's sheet at each choice, every dungeon with its group, every visitor,
    every lesson."""
    seen = "{" + ", ".join(f"{b} = true" for b in BUILDINGS) + "}"
    top = "{" + ", ".join(f"{b} = 7" for b in BUILDINGS) + "}"
    rich = ("{coins = 98765432, xp = 0, level = 60, nplots = 8, selected = 3358, tutorial = {done = true}, newsSeen = 1000,"
            f" seen = {seen}, buildings = {top}, stats = {{harvested = 987654, earned = 98765432, delivered = 9876}}}}")
    full = ("for _, p in ipairs(NS.Data.PLANTS) do NS.db.crops[p[1]] = 9999 end; "
            "for id in pairs(NS.Balance.GOODS) do NS.db.goods[id] = 999 end; "
            "for _, r in ipairs(NS.Workshop.RECIPES) do NS.db.goods[r.id] = 99 end; NS.Orders:Ensure()")

    def scene(name, view, before="", setup=rich, **kw):
        S.window(out / f"x-{name}.png", "ptBR", setup, view, before_view=full + "; " + before, **kw)

    for view in ("village", "hall", "garden", "barn", "orders", "mine", "pond", "workshop", "inn", "settings", "guide"):
        scene("topo-" + view, view)
    scene("horta-menu", "garden", after="NS.UI.screens.garden:OpenMenu(1)")
    for tab in ("herbs", "raw", "alchemy", "cooking", "smithing", "gear"):
        scene("celeiro-" + tab, "barn", f"NS.db.goods.core = 9; NS.db.goods.quelserrar = 1; NS.db.goods.onyxcloak = 1; NS.UI.barnTab = '{tab}'")
    scene("celeiro-rolado", "barn", "NS.UI.barnTab = 'herbs'", after="NS.UI.screens.barn.boff = 99; NS.UI:Refresh()")
    scene("celeiro-aba-vazia", "barn", "NS.db.goods = {ore = 5}; NS.UI.barnTab = 'gear'")
    scene("oficina-filas", "workshop", "for _, r in ipairs({'heal', 'heal', 'stew', 'copper'}) do NS.Workshop:Craft(r) end; NS.UI.trade = 'cooking'")
    for b in BUILDINGS:
        scene("vila-sobre-" + b, "village", after=f"local s = NS.UI.screens.village; s.hover = '{b}'; s:Paint()")
        scene("licao-" + b, "orders" if b == "market" else b, setup=rich.replace(seen, "{}"))
    for trade in ("alchemy", "cooking", "smithing", "gear"):
        first = f"local id; for _, r in ipairs(NS.Workshop.RECIPES) do if r.trade == '{trade}' then id = id or r.id end end; "
        scene("oficina-" + trade, "workshop",
              after=f"NS.UI.trade = '{trade}'; {first} for i = 1, 9 do NS.Workshop:Craft(id) end; NS.UI:Refresh()")
    scene("oficina-fila-rolada", "workshop", after="for i = 1, 9 do NS.Workshop:Craft('heal') end; NS.UI.screens.workshop:ScrollQueue(9)")
    for kind in ("urgent", "merchant", "caravan", "fish", "ore"):
        scene("visita-" + kind, "visitors", f"NS.Events:Spawn('{kind}'); NS.Events:Spawn('caravan')")
    scene("visita-nenhuma", "visitors")

    # the Inn: the followers at each choice, then every dungeon
    def levels(lv):
        return (f"for _, fid in ipairs({ALL}) do local f = NS.Inn:Get(fid); f.level = {lv}; f.xp = 0 end; "
                "NS.db.dungeons.merit = 99; NS.db.dungeons.epic = 99; ")

    gear = f"for _, fid in ipairs({ALL}) do NS.Inn:Equip(fid, 'gw7'); NS.Inn:Equip(fid, 'ga7') end; "
    for k, fid in enumerate(FOLLOWERS):
        pick = k % 2 + 1
        others = [f for f in FOLLOWERS if f != fid]
        scene(f"ficha-{fid}-1", "inn", levels(1) + f"NS.UI.innFollower = '{fid}'")
        scene(f"ficha-{fid}-raro", "inn", levels(10) + f"NS.UI.innFollower = '{fid}'")
        scene(f"ficha-{fid}-epico", "inn", levels(20) + gear + f"NS.Inn:Promote('{fid}', {pick}); NS.UI.innFollower = '{fid}'")
        scene(f"ficha-{fid}-maestria", "inn", levels(30) + gear + f"NS.Inn:Promote('{fid}', {pick}); "
              f"NS.Inn:Promote('{fid}', {3 - pick}); NS.UI.innFollower = '{fid}'")
        scene(f"ficha-{fid}-mestre", "inn", levels(30) + gear + f"NS.Inn:Promote('{fid}', {3 - pick}); "
              f"NS.Inn:Promote('{fid}', {pick}); NS.Inn:Master('{fid}', '{('veteran', 'mentor')[k % 2]}'); "
              f"NS.Rand = function() return 0.9999 end; assert(NS.Dungeons:Send('stratholme', {{'{fid}', '{others[0]}', '{others[1]}'}})); NS.Rand = nil; "
              f"NS.db.trips[1].at = NS.Now() - 999999; NS.Dungeons:CollectAll(); NS.UI.innFollower = '{fid}'")
    masters = levels(30) + gear + (f"for i, fid in ipairs({ALL}) do "
                                   "NS.Inn:Promote(fid, 1); NS.Inn:Promote(fid, 2); NS.Inn:Master(fid, i % 2 == 0 and 'veteran' or 'mentor') end; "
                                   "NS.db.dungeons.combos = {}; for _, c in ipairs(NS.Balance.COMBOS) do NS.db.dungeons.combos[c.id] = true end; "
                                   "NS.db.dungeons.trophies = {}; for id in pairs(NS.Balance.TROPHIES) do NS.db.dungeons.trophies[id] = 9 end; ")
    old = "for _, trip in ipairs(NS.db.trips) do trip.at = NS.Now() - 999999 end; NS.Rand = nil"
    two = "NS.Dungeons:Send('stratholme', {'mira', 'tobin', 'elda'}); NS.Dungeons:Send('scholomance', {'garrick', 'sela', 'bram'}); "
    scene("estalagem-mestres", "inn", masters)
    scene("estalagem-fora", "inn", masters + two)
    scene("estalagem-voltaram", "inn", masters + "NS.Rand = function() return 0.0001 end; " + two + old)
    scene("estalagem-feridos", "inn", masters + "NS.Rand = function() return 0.9999 end; " + two + old + "; NS.Dungeons:CollectAll()")
    scene("livro-cheio", "inn", masters + "NS.UI.innTab = 'book'")
    scene("livro-vazio", "inn", levels(1) + "NS.UI.innTab = 'book'")
    for page in range(1, 5):
        scene(f"masmorras-{page}", "inn", masters + f"NS.UI.innTab = 'dungeons'; NS.UI.innPage = {page}; "
              "NS.db.adventure = NS.db.adventure or {}; NS.db.adventure.visited = {}; "
              "for _, d in ipairs(NS.Balance.DUNGEONS) do NS.db.adventure.visited[d.id] = true end")
    g = S.Game("ptBR")
    g.run("KorumHomesteadDB = {}")
    g.load("KorumHomestead", S.HOMESTEAD)
    dungeons = g.lua.eval("(function() local o = {}; for _, d in ipairs(NS.Balance.DUNGEONS) do o[#o + 1] = d.id end; "
                          "return table.concat(o, ',') end)()").split(",")
    for d in dungeons:
        scene(f"grupo-{d}", "inn", masters + f"NS.UI.innDungeon = '{d}'; NS.UI.innOpts = {{potion = 'heal', food = 'stew', boss = true}}; "
              f"NS.UI.innParty = NS.Dungeons:Suggest('{d}', NS.UI.innOpts); NS.db.adventure = NS.db.adventure or {{}}; "
              f"NS.db.adventure.inspired = {{{d} = 3}}")
        scene(f"grupo-{d}-fraco", "inn", levels(1) + f"NS.UI.innDungeon = '{d}'; NS.UI.innParty = {{'bram'}}")

    # S5: the ones that are found, the rooms and the Lodging, the Ranking, the arrival card, the calls
    NEW = ("lyra", "hoderik", "aldric", "fizzwick", "tazu", "elandor", "faelan", "corvo", "brakka", "ilyanna", "hargrim",
           "shalendra")
    found = ("for _, def in ipairs(NS.Balance.FOLLOWERS) do if def.from then NS.Inn:Welcome(def.id, 30); "
             "NS.Inn:Greeted(def.id) end end; NS.db.dungeons.merit = 99; NS.db.dungeons.epic = 99; "
             "for _, fid in ipairs(NS.Inn:List()) do NS.Inn:Get(fid).level = 30 end; ")
    for k, fid in enumerate(NEW):
        scene(f"ficha-{fid}-chegou", "inn", found + f"NS.UI.innFollower = '{fid}'")
        scene(f"ficha-{fid}-mestre", "inn", found + f"NS.db.goods.quelserrar = 1; NS.db.goods.onyxcloak = 1; "
              f"NS.Inn:Equip('{fid}', 'quelserrar'); NS.Inn:Equip('{fid}', 'onyxcloak'); NS.Inn:Promote('{fid}', 2); "
              f"NS.Inn:Promote('{fid}', 2); NS.Inn:Master('{fid}', '{('veteran', 'mentor')[k % 2]}'); NS.UI.innFollower = '{fid}'")
        scene(f"chegada-{fid}", "inn", f"NS.Inn:Welcome('{fid}', 30)")
        scene(f"chegada-{fid}-cheio", "inn", found.replace(f"NS.Inn:Greeted(def.id)", f"if def.id ~= '{fid}' then NS.Inn:Greeted(def.id) end"))
    scene("estalagem-sete-quartos", "inn", found)
    for page in (1, 2, 3):
        scene(f"ranking-{page}", "inn", found + f"NS.UI.innTab = 'ranking'; NS.UI.innRank = {page}")
    scene("ranking-troca", "inn", found + "NS.UI.innTab = 'ranking'; NS.UI.innSwap = 'shalendra'; NS.UI.innRank = 3")
    scene("ranking-seis", "inn", "NS.UI.innTab = 'ranking'")
    scene("grupo-sete-livres", "inn", found + "NS.UI.innDungeon = 'stratholme'; NS.UI.innParty = {}")
    scene("grupo-do-alojamento", "inn", found + "NS.UI.innDungeon = 'scholomance'; NS.UI.innParty = {'mira'}")
    scene("grupo-raide-sete", "inn", found + "NS.UI.innDungeon = 'onyxia'; NS.UI.innParty = NS.Dungeons:Suggest('onyxia')")
    # the work at the Mine and at the Pond: nobody, anyone, who has the trade; and what the Inn says of who works
    for place, pro, other in (("mine", "hargrim", "shalendra"), ("pond", "brakka", "ilyanna")):
        scene(f"trabalho-{place}-vazio", place, found)
        scene(f"trabalho-{place}-oficio", place, found + f"NS.Inn:Work('{pro}', '{place}')")
        scene(f"trabalho-{place}-qualquer", place, found + f"NS.Inn:Work('{other}', '{place}')")
        scene(f"trabalho-{place}-ficha", "inn", found + f"NS.Inn:Work('{pro}', '{place}'); NS.UI.innFollower = '{pro}'")
    scene("trabalho-estalagem", "inn", found + "NS.Inn:Work('tobin', 'mine'); NS.Inn:Work('bram', 'pond')")
    scene("trabalho-grupo", "inn", found + "NS.Inn:Work('tobin', 'mine'); NS.Inn:Work('bram', 'pond'); NS.UI.innDungeon = 'stratholme'")
    # the Work tab of the Inn: the places, and who could work at each one
    busy = "NS.Inn:Work('tobin', 'mine'); NS.Inn:Work('elda', 'garden'); NS.Inn:Work('ilyanna', 'market'); "
    scene("aba-trabalho", "inn", found + busy + "NS.UI.innTab = 'work'")
    scene("aba-trabalho-inicio", "inn", "NS.UI.innTab = 'work'")
    for place in ("mine", "pond", "garden", "workshop", "market"):
        scene(f"aba-trabalho-{place}", "inn", found + busy + f"NS.UI.innTab = 'work'; NS.UI.innWorkAt = '{place}'")
    scene("aba-trabalho-pagina2", "inn", found + f"NS.UI.innTab = 'work'; NS.UI.innWorkAt = 'pond'; NS.UI.innWorkPage = 2")
    scene("trabalho-ranking", "inn", found + "NS.Inn:Work('tobin', 'mine'); NS.Inn:Work('bram', 'pond'); NS.UI.innTab = 'ranking'; NS.UI.innRank = 2")
    # the result card of a group that came back: a success with everything found, a failure with everyone hurt, a call
    home = "KEEP_RESULTS = true; for _, trip in ipairs(NS.db.trips) do trip.at = NS.Now() - 999999 end; NS.Dungeons:CollectAll(); NS.db.arrivals = {}"
    six = "{'garrick', 'sela', 'bram', 'lyra', 'mira', 'tobin'}"
    scene("resultado-raide", "inn", found + "NS.Inn:Promote('sela', 2); NS.Rand = function() return 1 end; "
          f"assert(NS.Dungeons:Send('onyxia', {six})); NS.Rand = nil; " + home)
    scene("resultado-falha", "inn", found + "local n = 0; NS.Rand = function() n = n + 1; return n == 1 and 9999 or 1 end; "
          "NS.db.adventure = {}; assert(NS.Dungeons:Send('stratholme', {'tobin', 'elda', 'lyra'}, {boss = true})); NS.Rand = nil; " + home)
    scene("resultado-masmorra", "inn", found + "NS.Inn:Get('mira').level = 4; NS.Inn:Get('mira').xp = 170; NS.Rand = function() return 1 end; "
          "assert(NS.Dungeons:Send('thanes', {'mira'})); assert(NS.Dungeons:Send('scholomance', {'tobin', 'elda', 'garrick'})); NS.Rand = nil; " + home)
    scene("resultado-chamado", "inn", found + "local e = NS.Events:Spawn('call'); e.def.call, e.def.place, e.def.size = 'rescue', 'blackmaw', 3; "
          "NS.Rand = function() return 1 end; assert(NS.Dungeons:Send(e.def.id, {'mira', 'tobin', 'elda'})); NS.Rand = nil; " + home)
    scene("resultado-escolta", "inn", found + "local e = NS.Events:Spawn('call'); e.def.call, e.def.place, e.def.size, e.def.mult = 'escort', 'excavation', 2, 1.5; "
          "NS.Rand = function() return 1 end; assert(NS.Dungeons:Send(e.def.id, {'mira', 'tobin'})); NS.Rand = nil; " + home)
    # the reminder of a flight or a queue: nothing waiting, and the longest lines (a call, the Barn, the orders)
    busy = (full + "; NS.db.buildings.inn = 7; local e = NS.Events:Spawn('call'); e.def.call, e.def.place = 'recon', 'excavation'; "
            "NS.Events:Spawn('merchant')")
    for locale in ("ptBR", "enUS"):
        for reason in ("flight", "queue"):
            S.reminder(out / f"x-lembrete-{reason}-vazio-{locale}.png", locale, "{tutorial = {done = true}, newsSeen = 1000}", reason)
            S.reminder(out / f"x-lembrete-{reason}-cheio-{locale}.png", locale, rich, reason, busy)
    places = ("zephras", "thanes", "lordaeron", "excavation", "drowned", "kroldok", "alcaz", "blackmaw")
    for kind in ("defense", "attack", "escort", "rescue", "recon"):
        for place in places:
            call = (f"local e = NS.Events:Spawn('call'); e.call, e.place = '{kind}', '{place}'; local d = e.def; "
                    f"d.call, d.place, d.threats, d.size, d.hours, d.level, d.mult, d.env = '{kind}', '{place}', "
                    f"NS.Balance.PLACES.{place}.threats, 3, 1.5, 30, NS.Balance.CALLS.{kind}.mult, NS.Balance.PLACES.{place}.env; ")
            scene(f"chamado-{kind}-{place}", "visitors", found + call + "NS.Events:Spawn('caravan')")
            scene(f"chamado-{kind}-{place}-grupo", "inn", found + call + "NS.UI.innDungeon = e.def.id; "
                  "NS.UI.innParty = NS.Dungeons:Suggest(e.def.id)")
    # what the Journal tells of a call, of someone new, of a piece with a name
    scene("diario-chamado", "inn", found + "local e = NS.Events:Spawn('call'); e.def.call, e.def.place, e.def.size = 'rescue', 'blackmaw', 3; "
          "NS.Rand = function() return 1 end; assert(NS.Dungeons:Send(e.def.id, {'mira', 'tobin', 'elda'})); "
          "assert(NS.Dungeons:Send('onyxia', {'garrick', 'sela', 'bram', 'lyra'})); NS.Rand = nil; "
          "for _, trip in ipairs(NS.db.trips) do trip.at = NS.Now() - 999999 end; NS.Dungeons:CollectAll(); "
          "NS.db.arrivals = {}; NS.UI.innFollower = 'mira'")
    scene("diario-raide", "inn", found + "NS.Rand = function() return 1 end; "
          "assert(NS.Dungeons:Send('onyxia', {'garrick', 'sela', 'bram', 'lyra'})); NS.Rand = nil; "
          "for _, trip in ipairs(NS.db.trips) do trip.at = NS.Now() - 999999 end; NS.Dungeons:CollectAll(); "
          "NS.db.arrivals = {}; NS.UI.innFollower = 'garrick'")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    with tempfile.TemporaryDirectory() as out:
        S.homestead(pathlib.Path(out))
        extras(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(out))
    for p in sorted(set(problems)):
        print(p)
    print(f"{len(set(problems))} problema(s)")
