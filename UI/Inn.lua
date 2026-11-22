--[[
    Korum Homestead - the Inn: the followers and the dungeons (docs/masmorras.md §16)

    Five tabs. Followers: a card for each one in a room (portrait, quality, level, abilities, what it is doing); a click
    opens its sheet (abilities, traits, the next quality, the Journal). Ranking: the whole roster by Power, who is in a
    room and who waits in the Lodging, and the buttons that swap them. Work: who works at each building. Book: combos and trophies. Dungeons: the dungeons of WoW Forever by level, each with its
    threats and the chance of the best free group now; a click opens the run: the threats (the countered ones dim), the
    group slots, the free followers with "Recommended" and how much each adds, the suggested group, the chance with where
    every point comes from, the reward and Send.
]]

local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local VDIR = P.VDIR
local BuildingArt, BuildingName = P.BuildingArt, P.BuildingName
local Reason, Notice, Screen, Tip = P.Reason, P.Notice, P.Screen, P.Tip

local ICONS = "Interface\\Icons\\"
local TOP = 98                                  -- under the tabs
local ROW_H, ROW_GAP = 44, 3                    -- seven rooms fit above the foot
local DG_ROWS, DG_H = 7, 40
local ROOMS = KH.Balance.ROOMS.max
local QUALITY = {uncommon = {0.12, 1, 0}, rare = {0, 0.44, 0.87}, epic = {0.64, 0.21, 0.93}, legendary = {1, 0.5, 0}}
P.QUALITY = QUALITY
UI.innTab = "followers"
UI.innPage = 1
UI.innRank = 1
UI.innWorkPage = 1

local function Hex(c) return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end
local function QName(q, text) return Hex(QUALITY[q] or C.text) .. text .. "|r" end
local function FName(fid) return T("fol_" .. fid) end
local function Portrait(fid) return VDIR .. "follower" .. KH.Inn.Def(fid).portrait end
local function Percent(x) return math.floor(x + 0.5) .. "%" end
local function ChanceColor(x)
    if x >= 100 then return "|cff59d973" elseif x >= 60 then return "|cffffd24d" end
    return "|cffff7a6b"
end

local function IconButton(parent, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints(b)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return b
end

local function ShowThreat(b, threat, dim)
    b.tex:SetTexture(ICONS .. KH.Balance.THREATS[threat])
    b.tex:SetAlpha(dim and 0.3 or 1)
    if b.tex.SetDesaturated then b.tex:SetDesaturated(dim) end
    b:SetScript("OnEnter", function(self) Tip(self, T("th_" .. threat), {T(dim and "thCountered" or "thOpen")}) end)
    b:Show()
end

-- what an ability does, in words: the threats it counters, or the time it saves
local function AbilityDoes(ab)
    local def = KH.Balance.ABILITIES[ab]
    if #def.counters == 0 and def.short then return T("abShort", math.floor(def.short * 100 + 0.5)) end
    local names = {}
    for i, th in ipairs(def.counters) do names[i] = T("th_" .. th) end
    return T("abCounters", table.concat(names, ", "))
end

local function ShowAbility(b, ab)
    local def = KH.Balance.ABILITIES[ab]
    b.tex:SetTexture(ICONS .. def.icon)
    b.tex:SetAlpha(1)
    b:SetScript("OnEnter", function(self) Tip(self, T("ab_" .. ab), {AbilityDoes(ab)}) end)
    b:Show()
end

local function TraitText(t)
    local name, arg = t[1], t[2]
    local label, desc = T("tr_" .. name), T("trd_" .. name)
    if name == "partner" then label, desc = T("tr_partner", FName(arg)), T("trd_partner", FName(arg))
    elseif name == "likes" then label, desc = T("tr_likes", T("env_" .. arg)), T("trd_likes", T("env_" .. arg)) end
    return label, desc
end

local function StateText(fid)
    local state, left = KH.Inn:State(fid)
    if state == "away" then return T("folAway", KH.Duration(left))
    elseif state == "back" then return "|cff59d973" .. T("folBack") .. "|r"
    elseif state == "hurt" then return "|cffff7a6b" .. T("folHurt", KH.Duration(left)) .. "|r" end
    local place = KH.Inn:Working(fid)
    if place then return T("folWork", P.BuildingName(place)) end
    return T("folHome")
end

local function FollowerRow(parent, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ROW_H)
    row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
    row.disc = row:CreateTexture(nil, "ARTWORK")
    row.disc:SetSize(40, 40)
    row.disc:SetPoint("LEFT", 6, 0)
    row.disc:SetSize(38, 38)
    row.name = Kit.Text(row, 13, C.text)
    row.name:SetPoint("TOPLEFT", 54, -5)
    row.state = Kit.Text(row, 10, C.textSoft)
    row.state:SetPoint("TOPLEFT", 54, -23)
    row.state:SetWidth(230)
    row.state:SetWordWrap(false)
    row.bar = Kit.Bar(row, 160, 3)
    row.bar:SetPoint("TOPLEFT", 54, -37)
    row.icons = {}
    for k = 1, 2 do
        local b = IconButton(row, 24)
        b:SetPoint("LEFT", 300 + (k - 1) * 30, 0)
        row.icons[k] = b
    end
    -- what the follower wears (owner, 22/11): the weapon and the armor after the abilities, a faint mark when empty
    row.gear = {}
    for k, slot in ipairs({"weapon", "armor"}) do
        local b = IconButton(row, 24)
        b:SetPoint("LEFT", 380 + (k - 1) * 30, 0)
        b.slot = slot
        row.gear[k] = b
    end
    row.right = Kit.Text(row, 11, C.textSoft, "RIGHT")
    row.right:SetPoint("RIGHT", -14, 0)
    row.right:SetWidth(230)
    return row
end

local function FillFollower(row, fid)
    local In = KH.Inn
    local f = In:Get(fid)
    row.fid = fid
    row.disc:SetTexture(Portrait(fid))
    row.name:SetText(QName(f.quality, FName(fid)) .. "  |cffa8adb8" .. T("folLevel", f.level) .. "|r")
    row.state:SetText(StateText(fid))
    local need = KH.Balance.FollowerXPToNext(f.level)
    row.bar:Set(f.level >= KH.Balance.FOLLOWER.maxLevel and 1 or f.xp / need)
    local abs = In:Abilities(fid)
    for k, b in ipairs(row.icons) do
        if abs[k] then ShowAbility(b, abs[k]) else b:Hide() end
    end
    for _, b in ipairs(row.gear) do
        local gid = f.gear and f.gear[b.slot]
        local g = gid and In.Gear(gid)
        if g then
            b.tex:SetTexture(KH.Data.Icon(g.item)); b.tex:SetAlpha(1)
            b:SetScript("OnEnter", function(self) Tip(self, T("good_" .. gid), {T("gearPower", g.power)}) end)
        else
            b.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); b.tex:SetAlpha(0.25)
            b:SetScript("OnEnter", function(self) Tip(self, T("slot_" .. b.slot), {T("gearNone")}) end)
        end
        b:Show()
    end
end

local function BuildInn(win)
    local s = Screen(win, "inn")
    local W = s.width
    local In, Dg = KH.Inn, KH.Dungeons

    s.tabs = Kit.Segmented(s.frame, 440, {{value = "followers", label = T("innTabFollowers")},
        {value = "dungeons", label = T("innTabDungeons")}, {value = "ranking", label = T("innTabRanking")},
        {value = "work", label = T("innTabWork")}, {value = "book", label = T("innTabBook")}},
        function() return UI.innTab end,
        function(v)
            UI.innTab = v
            UI.innFollower, UI.innDungeon, UI.innSwap, UI.innOpts, UI.innWorkAt = nil, nil, nil, nil, nil
            UI:Refresh()
        end)
    s.tabs:SetPoint("TOPLEFT", 0, -58)
    s.back = Kit.Button(s.frame, 130, 28, "", function()
        local d = UI.innDungeon and Dg.Get(UI.innDungeon)
        UI.innFollower, UI.innDungeon, UI.innParty, UI.innOpts, UI.innWorkAt = nil, nil, nil, nil, nil
        if d and d.call then UI:Show("visitors") else UI:Refresh() end
    end)
    s.back:SetPoint("TOPLEFT", 0, -58)
    s.tabHint = Kit.Text(s.frame, 10, C.textSoft)
    s.tabHint:SetPoint("LEFT", s.tabs, "RIGHT", 14, 0)
    s.tabHint:SetWidth(W - 454)
    s.tabHint:SetWordWrap(true)

    -- the followers tab
    local list = CreateFrame("Frame", nil, s.frame)
    list:SetAllPoints(s.frame)
    s.list = list
    s.rows = {}
    for i = 1, ROOMS do
        local row = FollowerRow(list, W)
        row:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * (ROW_H + ROW_GAP))
        row:SetScript("OnClick", function() UI.innFollower = row.fid; UI:Refresh() end)
        s.rows[i] = row
    end
    s.action = Kit.Button(s.frame, 220, 36, "", function()
        local coins = Dg:CollectAll()
        -- each group that came back shows its result card (s.result); an old mission only has coins to tell
        if #Dg.results == 0 and coins > 0 then Notice(T("collected", KH.Number(coins))) end
        UI:Refresh()
    end)
    s.action:SetPoint("BOTTOMRIGHT", 0, 0)
    s.note = Kit.Text(s.frame, 11, C.textSoft)
    s.note:SetPoint("BOTTOMLEFT", 0, 12)
    s.note:SetWidth(W - 240)
    s.note:SetWordWrap(false)

    -- the dungeons tab
    local dl = CreateFrame("Frame", nil, s.frame)
    dl:SetAllPoints(s.frame)
    s.dlist = dl
    s.drows = {}
    for i = 1, DG_ROWS do
        local row = CreateFrame("Button", nil, dl)
        row:SetSize(W, DG_H)
        row:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * (DG_H + 4))
        row.surface, row.outline = Kit.Rounded(row, 10, 1, 1, 1, 0.045, 0.06)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 12, -5)
        row.meta = Kit.Text(row, 10, C.textSoft)
        row.meta:SetPoint("TOPLEFT", 12, -22)
        row.threats = {}
        for k = 1, 4 do
            local b = IconButton(row, 22)
            b:SetPoint("LEFT", 330 + (k - 1) * 26, 0)
            row.threats[k] = b
        end
        row.chance = Kit.Text(row, 13, C.text, "RIGHT")
        row.chance:SetPoint("RIGHT", -14, 0)
        row.tag = Kit.Text(row, 10, C.accent, "RIGHT")
        row.tag:SetPoint("RIGHT", -70, 0)
        row:SetScript("OnClick", function()
            if row.id and Dg:Open(row.id) then
                UI.innDungeon, UI.innParty, UI.innOpts = row.id, nil, nil
                UI:Refresh()
            end
        end)
        s.drows[i] = row
    end
    s.prev = Kit.Button(dl, 32, 28, "<", function() UI.innPage = math.max(1, UI.innPage - 1); UI:Refresh() end)
    s.prev:SetPoint("BOTTOMLEFT", 0, 4)
    s.next = Kit.Button(dl, 32, 28, ">", function() UI.innPage = UI.innPage + 1; UI:Refresh() end)
    s.next:SetPoint("BOTTOMLEFT", 38, 4)
    s.page = Kit.Text(dl, 11, C.textSoft)
    s.page:SetPoint("BOTTOMLEFT", 80, 12)

    -- the ranking: the whole roster by Power, with the room or the Lodging of each one
    local rank = CreateFrame("Frame", nil, s.frame)
    rank:SetAllPoints(s.frame)
    s.rank = rank
    s.rrows = {}
    for i = 1, DG_ROWS do
        local row = CreateFrame("Button", nil, rank)
        row:SetSize(W, DG_H)
        row:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * (DG_H + 4))
        row.surface, row.outline = Kit.Rounded(row, 10, 1, 1, 1, 0.045, 0.06)
        row.pos = Kit.Text(row, 12, C.textMuted, "CENTER")
        row.pos:SetPoint("LEFT", 6, 0)
        row.pos:SetWidth(24)
        row.disc = row:CreateTexture(nil, "ARTWORK")
        row.disc:SetSize(32, 32)
        row.disc:SetPoint("LEFT", 34, 0)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 76, -5)
        row.name:SetWidth(250)
        row.name:SetWordWrap(false)
        row.meta = Kit.Text(row, 10, C.textSoft)
        row.meta:SetPoint("TOPLEFT", 76, -22)
        row.meta:SetWidth(250)
        row.meta:SetWordWrap(false)
        row.power = Kit.Text(row, 12, C.gold)
        row.power:SetPoint("LEFT", 336, 0)
        row.where = Kit.Text(row, 10, C.textSoft)
        row.where:SetPoint("LEFT", 430, 0)
        row.button = Kit.Button(row, 124, 26, "", function()
            local fid = row.fid
            if UI.innSwap then
                if fid == UI.innSwap then
                    UI.innSwap = nil
                else
                    local ok, why = In:Swap(fid, UI.innSwap)
                    if not ok then Notice(Reason(why)) end
                    UI.innSwap = nil
                end
            elseif In:InRoom(fid) then
                local ok, why = In:Move(fid, false)
                if not ok then Notice(Reason(why)) end
            elseif In:FreeRooms() > 0 then
                local ok, why = In:Move(fid, true)
                if not ok then Notice(Reason(why)) end
            else
                UI.innSwap = fid                -- no free room: pick who leaves
            end
            UI:Refresh()
        end)
        row.button:SetPoint("RIGHT", -10, 0)
        row:SetScript("OnClick", function() if row.fid then UI.innFollower, UI.innSwap = row.fid, nil; UI:Refresh() end end)
        s.rrows[i] = row
    end
    s.rprev = Kit.Button(rank, 32, 28, "<", function() UI.innRank = math.max(1, UI.innRank - 1); UI:Refresh() end)
    s.rprev:SetPoint("BOTTOMLEFT", 0, 4)
    s.rnext = Kit.Button(rank, 32, 28, ">", function() UI.innRank = UI.innRank + 1; UI:Refresh() end)
    s.rnext:SetPoint("BOTTOMLEFT", 38, 4)
    s.rpage = Kit.Text(rank, 11, C.textSoft)
    s.rpage:SetPoint("BOTTOMLEFT", 80, 12)

    -- the work tab (owner, 22/11): each building with a place of work, who works there and what it gives; a click on a
    -- place lists who could work there (UI.innWorkAt), anyone at home, in a room or in the Lodging
    local work = CreateFrame("Frame", nil, s.frame)
    work:SetAllPoints(s.frame)
    s.work = work
    s.wrows = {}
    local function WorkClick(row)
        if UI.innWorkAt then
            if row.fid then
                local ok, why = In:Work(row.fid, UI.innWorkAt)
                if not ok then Notice(Reason(why)) else UI.innWorkAt = nil end
            end
        elseif row.place and V:Level(row.place) > 0 then
            UI.innWorkAt, UI.innWorkPage = row.place, 1
        end
        UI:Refresh()
    end
    for i = 1, DG_ROWS do
        local row = CreateFrame("Button", nil, work)
        row:SetSize(W, DG_H)
        row:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * (DG_H + 4))
        row.surface, row.outline = Kit.Rounded(row, 10, 1, 1, 1, 0.045, 0.06)
        row.disc = row:CreateTexture(nil, "ARTWORK")
        row.disc:SetSize(32, 32)
        row.disc:SetPoint("LEFT", 8, 0)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 50, -5)
        row.name:SetWidth(230)
        row.name:SetWordWrap(false)
        row.meta = Kit.Text(row, 10, C.textSoft)
        row.meta:SetPoint("TOPLEFT", 50, -22)
        row.meta:SetWidth(230)
        row.meta:SetWordWrap(false)
        row.gain = Kit.Text(row, 11, C.text)
        row.gain:SetPoint("LEFT", 290, 0)
        row.gain:SetWidth(W - 290 - 140)
        row.gain:SetWordWrap(false)
        row.button = Kit.Button(row, 120, 26, "", function() WorkClick(row) end)
        row.button:SetPoint("RIGHT", -10, 0)
        row:SetScript("OnClick", function() WorkClick(row) end)
        s.wrows[i] = row
    end
    s.wprev = Kit.Button(work, 32, 28, "<", function() UI.innWorkPage = math.max(1, UI.innWorkPage - 1); UI:Refresh() end)
    s.wprev:SetPoint("BOTTOMLEFT", 0, 4)
    s.wnext = Kit.Button(work, 32, 28, ">", function() UI.innWorkPage = UI.innWorkPage + 1; UI:Refresh() end)
    s.wnext:SetPoint("BOTTOMLEFT", 38, 4)
    s.wpage = Kit.Text(work, 11, C.textSoft)
    s.wpage:SetPoint("BOTTOMLEFT", 80, 12)
    s.wstop = Kit.Button(work, 220, 36, "", function()
        if UI.innWorkAt then In:Rest(UI.innWorkAt) end
        UI.innWorkAt = nil
        UI:Refresh()
    end)
    s.wstop:SetPoint("BOTTOMRIGHT", 0, 0)

    -- the book: combos and trophies
    local book = CreateFrame("Frame", nil, s.frame)
    book:SetAllPoints(s.frame)
    s.book = book
    book.combosHead = Kit.Text(book, 11, C.textMuted)
    book.combosHead:SetPoint("TOPLEFT", 0, -TOP)
    book.combos = {}
    for k = 1, #KH.Balance.COMBOS do
        local line = Kit.Text(book, 10, C.textSoft)
        line:SetPoint("TOPLEFT", ((k - 1) % 2) * (W / 2), -TOP - 20 - math.floor((k - 1) / 2) * 40)
        line:SetWidth(W / 2 - 12)
        line:SetWordWrap(true)
        book.combos[k] = line
    end
    book.trophiesHead = Kit.Text(book, 11, C.textMuted)
    book.trophiesHead:SetPoint("TOPLEFT", 0, -TOP - 190)
    book.trophies = {}
    local ids = {}
    for _, d in ipairs(Dg.LIST) do if KH.Balance.TROPHIES[d.id] then ids[#ids + 1] = d.id end end
    for k, did in ipairs(ids) do
        local b = IconButton(book, 36)
        b:SetPoint("TOPLEFT", ((k - 1) % 12) * 44, -TOP - 212 - math.floor((k - 1) / 12) * 44)
        b.dungeon = did
        book.trophies[k] = b
    end

    -- one dungeon: the run
    local run = CreateFrame("Frame", nil, s.frame)
    run:SetAllPoints(s.frame)
    s.run = run
    run.meta = Kit.Text(run, 10, C.textSoft)
    run.meta:SetPoint("TOPLEFT", 146, -66)
    run.threats = {}
    for k = 1, 4 do
        local b = IconButton(run, 30)
        b:SetPoint("TOPRIGHT", -(4 - k) * 36, -56)
        run.threats[k] = b
    end
    run.slots = {}
    for k = 1, 6 do
        local slot = CreateFrame("Button", nil, run)
        slot:SetSize(150, 44)
        slot:SetPoint("TOPLEFT", (k - 1) * 158, -100)
        slot.surface, slot.outline = Kit.Rounded(slot, 10, 1, 1, 1, 0.05, 0.08)
        slot.disc = slot:CreateTexture(nil, "ARTWORK")
        slot.disc:SetSize(36, 36)
        slot.disc:SetPoint("LEFT", 4, 0)
        slot.name = Kit.Text(slot, 11, C.text)
        slot.name:SetPoint("LEFT", 46, 0)
        slot.name:SetWidth(100)
        slot.name:SetWordWrap(false)
        slot:SetScript("OnClick", function()
            if slot.fid then
                local party = UI.innParty or {}
                for i = #party, 1, -1 do if party[i] == slot.fid then table.remove(party, i) end end
                UI:Refresh()
            end
        end)
        run.slots[k] = slot
    end
    run.freeHead = Kit.Text(run, 11, C.textMuted)
    run.freeHead:SetPoint("TOPLEFT", 0, -154)
    run.free = {}
    for k = 1, ROOMS do
        local r = CreateFrame("Button", nil, run)
        r:SetSize(380, 25)
        r:SetPoint("TOPLEFT", 0, -172 - (k - 1) * 27)
        r.surface, r.outline = Kit.Rounded(r, 9, 1, 1, 1, 0.04, 0.05)
        r.disc = r:CreateTexture(nil, "ARTWORK")
        r.disc:SetSize(22, 22)
        r.disc:SetPoint("LEFT", 4, 0)
        r.name = Kit.Text(r, 11, C.text)
        r.name:SetPoint("LEFT", 38, 0)
        r.name:SetWidth(110)
        r.name:SetWordWrap(false)
        r.gain = Kit.Text(r, 11, C.text, "RIGHT")
        r.gain:SetPoint("RIGHT", -10, 0)
        r.tag = Kit.Text(r, 10, C.accent)
        r.tag:SetPoint("LEFT", 150, 0)
        r.tag:SetWidth(170)
        r.tag:SetWordWrap(false)
        r:SetScript("OnClick", function()
            local d = Dg.Get(UI.innDungeon)
            local party = UI.innParty or {}
            if r.fid and Dg:Free(r.fid) and #party < d.size then
                party[#party + 1] = r.fid
                UI.innParty = party
                UI:Refresh()
            end
        end)
        run.free[k] = r
    end
    run.chance = Kit.Text(run, 28, C.text)
    run.chance:SetPoint("TOPLEFT", 400, -150)
    run.chanceLabel = Kit.Text(run, 10, C.textSoft)
    run.chanceLabel:SetPoint("TOPLEFT", 400, -184)
    run.parts = {}
    for k = 1, 6 do
        local line = Kit.Text(run, 10, C.textSoft)
        line:SetPoint("TOPLEFT", 400, -198 - (k - 1) * 15)
        line:SetWidth(W - 400)
        line:SetWordWrap(false)
        run.parts[k] = line
    end
    run.combo = Kit.Text(run, 10, C.accent)
    run.combo:SetPoint("TOPLEFT", 400, -292)
    run.combo:SetWidth(W - 400)
    run.combo:SetWordWrap(true)
    run.lodge = Kit.Text(run, 10, C.gold)                   -- someone in the Lodging would help more
    run.lodge:SetPoint("TOPLEFT", 400, -322)
    run.lodge:SetWidth(W - 400)
    run.lodge:SetWordWrap(true)
    run.opts = {}
    local function Cycle(kind)
        local goods = {false}
        for _, r in ipairs(KH.Workshop.RECIPES) do
            if r.trade == kind and V:Good(r.id) > 0 then goods[#goods + 1] = r.id end
        end
        local key = kind == "alchemy" and "potion" or "food"
        local o = UI.innOpts or {}
        local now = o[key] or false
        local nextOne = goods[1]
        for i, g in ipairs(goods) do if g == now then nextOne = goods[i % #goods + 1] end end
        o[key] = nextOne or nil
        UI.innOpts = o
        UI:Refresh()
    end
    for k, kind in ipairs({"alchemy", "cooking", "boss"}) do
        local b = Kit.Button(run, math.floor((W - 16) / 3), 26, "", function()
            if kind == "boss" then
                UI.innOpts = UI.innOpts or {}
                UI.innOpts.boss = not UI.innOpts.boss or nil
                UI:Refresh()
            else
                Cycle(kind)
            end
        end)
        b:SetPoint("BOTTOMLEFT", (k - 1) * (math.floor((W - 16) / 3) + 8), 72)
        -- what each one does, under the mouse: the numbers come from the rules
        local enter, leave = b:GetScript("OnEnter"), b:GetScript("OnLeave")
        b:SetScript("OnEnter", function(frame)
            if enter then enter(frame) end
            local R = KH.Balance.DUNGEON
            if kind == "alchemy" then Tip(frame, T("runPotionH"), {T("runPotionD", R.potion), T("runFromWorkshop")})
            elseif kind == "cooking" then
                Tip(frame, T("runFoodH"), {T("runFoodD", R.food, math.floor(R.foodXP * 100 + 0.5)), T("runFromWorkshop")})
            else Tip(frame, T("runBossH"), {T("runBossD")}) end
        end)
        b:SetScript("OnLeave", function(frame)
            if leave then leave(frame) end
            if GameTooltip then GameTooltip:Hide() end
        end)
        run.opts[k] = b
    end
    run.reward = Kit.Text(run, 11, C.gold)
    run.reward:SetPoint("BOTTOMLEFT", 0, 48)
    run.reward:SetWidth(W)
    run.reward:SetWordWrap(false)
    run.suggest = Kit.Button(run, 180, 36, "", function()
        UI.innParty = Dg:Suggest(UI.innDungeon, UI.innOpts)
        UI:Refresh()
    end)
    run.suggest:SetPoint("BOTTOMLEFT", 0, 0)
    run.send = Kit.Button(run, 220, 36, "", function()
        local name = Dg.Name(UI.innDungeon)                 -- a call leaves the list when the group leaves
        local call = Dg.Get(UI.innDungeon).call
        local ok, why, n = Dg:Send(UI.innDungeon, UI.innParty or {}, UI.innOpts)
        if ok then
            Notice(T("dgSent", name))
            -- back to where the group was picked from (owner, 20/11): the list of dungeons, or the Visitors for a call
            UI.innDungeon, UI.innParty, UI.innOpts = nil, nil, nil
            if call then UI:Show("visitors"); return end
            UI.innTab = "dungeons"
        else
            Notice(why == "fish" and T("why_fishN", n) or Reason(why))
        end
        UI:Refresh()
    end)
    run.send:SetPoint("BOTTOMRIGHT", 0, 0)

    -- one follower: the sheet
    local sheet = CreateFrame("Frame", nil, s.frame)
    sheet:SetAllPoints(s.frame)
    s.sheet = sheet
    sheet.disc = sheet:CreateTexture(nil, "ARTWORK")
    sheet.disc:SetSize(72, 72)
    sheet.disc:SetPoint("TOPLEFT", 0, -96)
    sheet.name = Kit.Text(sheet, 17, C.text)
    sheet.name:SetPoint("TOPLEFT", 84, -98)
    sheet.level = Kit.Text(sheet, 11, C.textSoft)
    sheet.level:SetPoint("TOPLEFT", 84, -124)
    sheet.bar = Kit.Bar(sheet, 200, 3)
    sheet.bar:SetPoint("TOPLEFT", 84, -144)
    sheet.state = Kit.Text(sheet, 11, C.textSoft)
    sheet.state:SetPoint("TOPLEFT", 84, -154)
    sheet.where = Kit.Text(sheet, 10, C.textSoft)           -- where it came from, and its room or the Lodging
    sheet.where:SetPoint("TOPLEFT", 340, -100)
    sheet.where:SetWidth(W - 340)
    sheet.where:SetWordWrap(true)
    sheet.abs = {}
    for k = 1, 2 do
        local b = IconButton(sheet, 26)
        b:SetPoint("TOPLEFT", 0, -184 - (k - 1) * 32)
        b.text = Kit.Text(sheet, 11, C.text)
        b.text:SetPoint("LEFT", b, "RIGHT", 8, 0)
        b.text:SetWidth(290)
        b.text:SetWordWrap(false)
        sheet.abs[k] = b
    end
    sheet.traits = {}
    for k = 1, 2 do
        local line = Kit.Text(sheet, 10, C.textSoft)
        line:SetPoint("TOPLEFT", 0, -250 - (k - 1) * 28)
        line:SetWidth(334)
        line:SetWordWrap(true)
        sheet.traits[k] = line
    end
    sheet.gear = {}
    for k, slot in ipairs({"weapon", "armor"}) do
        local g = IconButton(sheet, 22)
        g:SetPoint("TOPLEFT", 0, -308 - (k - 1) * 28)
        g.text = Kit.Text(sheet, 10, C.textSoft)
        g.text:SetPoint("LEFT", g, "RIGHT", 8, 0)
        g.text:SetWidth(222)
        g.text:SetWordWrap(false)
        g.button = Kit.Button(sheet, 80, 24, "", function()
            local fid = UI.innFollower
            local best = In:BestGear(fid, slot)
            if best then
                local ok, why = In:Equip(fid, best)
                if not ok then Notice(Reason(why)) end
            else
                In:Unequip(fid, slot)
            end
            UI:Refresh()
        end)
        g.button:SetPoint("TOPLEFT", 256, -307 - (k - 1) * 28)
        g.slot = slot
        sheet.gear[k] = g
    end
    sheet.promo = Kit.Text(sheet, 11, C.text)
    sheet.promo:SetPoint("TOPLEFT", 0, -366)
    sheet.promo:SetWidth(320)
    sheet.pick = {}
    for k = 1, 2 do
        local b = Kit.Button(sheet, 150, 28, "", function()
            local fid = UI.innFollower
            local f = In:Get(fid)
            if f.level >= KH.Balance.FOLLOWER.maxLevel and not f.mastery then
                if In:Master(fid, k == 1 and "veteran" or "mentor") then Notice(T("ttl_" .. fid)) end
            elseif In:Promote(fid, k) then
                Notice(T("promoted", FName(fid)))
            end
            UI:Refresh()
        end)
        b:SetPoint("TOPLEFT", (k - 1) * 158, -398)
        sheet.pick[k] = b
    end
    sheet.respec = {}
    for k, what in ipairs({"ability", "trait"}) do
        local b = Kit.Button(sheet, 163, 24, "", function()
            local ok, why = In:Respec(UI.innFollower, what)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        b:SetPoint("TOPLEFT", (k - 1) * 169, -432)
        sheet.respec[k] = b
    end
    sheet.journalHead = Kit.Text(sheet, 11, C.textMuted)
    sheet.journalHead:SetPoint("TOPLEFT", 340, -184)
    sheet.journal = {}
    for k = 1, 5 do
        local line = Kit.Text(sheet, 10, C.textSoft)
        line:SetPoint("TOPLEFT", 340, -204 - (k - 1) * 46)
        line:SetWidth(W - 340)
        line:SetWordWrap(true)
        sheet.journal[k] = line
    end
    sheet.chat = Kit.Button(sheet, 160, 28, "", function()
        local e = KH.Journal:For(UI.innFollower)[1]
        if e and ChatFrame_OpenChat then ChatFrame_OpenChat(KH.Journal:ChatText(e)) end
    end)
    sheet.chat:SetPoint("BOTTOMRIGHT", 0, 0)

    -- a group came back: what happened there, one card per group (Dungeons.results), until the player reads it
    local result = CreateFrame("Frame", nil, s.frame)
    result:SetAllPoints(s.frame)
    result:SetFrameLevel(s.frame:GetFrameLevel() + 34)
    result:EnableMouse(true)
    result.fill = result:CreateTexture(nil, "BACKGROUND")
    result.fill:SetAllPoints(result)
    result.fill:SetColorTexture(0, 0, 0, 0.62)
    local rcard = CreateFrame("Frame", nil, result)
    rcard:SetSize(540, 380)
    rcard:SetPoint("CENTER", 0, 4)
    rcard.surface, rcard.outline = Kit.Rounded(rcard, 18, 0.07, 0.085, 0.095, 0.99, 0.14)
    rcard.title = Kit.Text(rcard, 17, C.text, "CENTER")
    rcard.title:SetPoint("TOP", 0, -16)
    rcard.title:SetWidth(500)
    rcard.title:SetWordWrap(false)
    rcard.verdict = Kit.Text(rcard, 13, C.text, "CENTER")
    rcard.verdict:SetPoint("TOP", 0, -44)
    rcard.verdict:SetWidth(500)
    rcard.verdict:SetWordWrap(false)
    rcard.reward = Kit.Text(rcard, 12, C.gold, "CENTER")
    rcard.reward:SetPoint("TOP", 0, -66)
    rcard.reward:SetWidth(500)
    rcard.reward:SetWordWrap(false)
    rcard.rows = {}
    for k = 1, 6 do
        local r = CreateFrame("Frame", nil, rcard)
        r:SetSize(500, 26)
        r:SetPoint("TOP", 0, -92 - (k - 1) * 28)
        r.surface, r.outline = Kit.Rounded(r, 8, 1, 1, 1, 0.04, 0.05)
        r.disc = r:CreateTexture(nil, "ARTWORK")
        r.disc:SetSize(22, 22)
        r.disc:SetPoint("LEFT", 4, 0)
        r.name = Kit.Text(r, 11, C.text)
        r.name:SetPoint("LEFT", 34, 0)
        r.name:SetWidth(130)
        r.name:SetWordWrap(false)
        r.xp = Kit.Text(r, 11, C.textSoft)
        r.xp:SetPoint("LEFT", 170, 0)
        r.xp:SetWidth(70)
        r.xp:SetWordWrap(false)
        r.level = Kit.Text(r, 11, C.accent)
        r.level:SetPoint("LEFT", 244, 0)
        r.level:SetWidth(110)
        r.level:SetWordWrap(false)
        r.hurt = Kit.Text(r, 10, C.textSoft, "RIGHT")
        r.hurt:SetPoint("RIGHT", -10, 0)
        r.hurt:SetWidth(136)
        r.hurt:SetWordWrap(false)
        rcard.rows[k] = r
    end
    rcard.found = Kit.Text(rcard, 11, C.textSoft, "CENTER")
    rcard.found:SetWidth(500)
    rcard.found:SetWordWrap(true)
    rcard.ok = Kit.Button(rcard, 200, 34, "", function()
        table.remove(Dg.results, 1)
        UI:Refresh()
    end)
    rcard.ok:SetPoint("BOTTOM", 0, 14)
    rcard.ok:SetStyle("primary")
    result.card = rcard
    result:Hide()
    s.result = result

    local function ShowResult(trip)
        local card = rcard
        local odds = math.floor(Dg.Odds(trip.total or 0) + 0.5)
        Kit.Fit(card.title, Dg.Name(trip.call and {call = trip.call.kind, place = trip.call.place} or trip.dungeon), 500)
        Kit.Fit(card.verdict, (trip.ok and "|cff59d973" or "|cffff7a6b") .. T(trip.ok and "resOk" or "resFail", odds) .. "|r", 500)
        Kit.Fit(card.reward, T("resReward", KH.Number(trip.coins or 0), KH.Number(trip.vxp or 0)), 500)
        local hurt = {}
        for _, fid in ipairs(trip.hurt or {}) do hurt[fid] = true end
        local rest = KH.Duration(KH.Balance.DUNGEON.injuryHours * 3600)
        for k, r in ipairs(card.rows) do
            local fid = trip.party[k]
            r:SetShown(fid ~= nil)
            if fid then
                local f = In:Get(fid)
                local now, up = (trip.levels or {})[fid] or f.level, (trip.ups or {})[fid] or 0
                r.disc:SetTexture(Portrait(fid))
                Kit.Fit(r.name, QName(f.quality, FName(fid)), 130)
                r.xp:SetText(T("resXP", (trip.fxp or {})[fid] or 0))
                if up > 0 then Kit.Fit(r.level, T("resLevelUp", now - up, now), 110)
                else Kit.Fit(r.level, "|cffa8adb8" .. T("folLevel", now) .. "|r", 110) end
                Kit.Fit(r.hurt, hurt[fid] and ("|cffff7a6b" .. T("resHurt", rest) .. "|r") or T("resFine"), 136)
            end
        end
        -- what was found, in words
        local found = {}
        for _, drop in ipairs(trip.drops or {}) do
            if drop == "trophy" then found[#found + 1] = T("resTrophy", D.Name(KH.Balance.TROPHIES[trip.dungeon]) or "")
            elseif drop == "core" then found[#found + 1] = T("good_core")
            else found[#found + 1] = T("resDrop_" .. drop) end
        end
        if trip.named then found[#found + 1] = T("good_" .. trip.named) end
        if trip.newcomer then found[#found + 1] = T(trip.welcome == "new" and "j_new" or "j_again", FName(trip.newcomer)) end
        for _, c in ipairs(trip.fresh or {}) do found[#found + 1] = T("resCombo", T("cb_" .. c), T("cbd_" .. c)) end
        if trip.caravan then found[#found + 1] = T("j_caravan") end
        if trip.scout then found[#found + 1] = T("j_scout", T("dg_" .. trip.scout)) end
        card.found:ClearAllPoints()
        card.found:SetPoint("TOP", 0, -92 - math.min(#trip.party, 6) * 28 - 8)
        card.found:SetText(#found > 0 and ("|cffffd24d" .. T("resFound") .. "|r " .. table.concat(found, " · "))
            or ("|cff757a87" .. T("resNothing") .. "|r"))
        card.ok:SetLabel(#Dg.results > 1 and T("resNext", #Dg.results - 1) or T("resClose"))
    end

    -- someone new arrived: a card with who it is and where it came from, until the player greets it
    local arrive = CreateFrame("Frame", nil, s.frame)
    arrive:SetAllPoints(s.frame)
    arrive:SetFrameLevel(s.frame:GetFrameLevel() + 30)
    arrive:EnableMouse(true)
    arrive.fill = arrive:CreateTexture(nil, "BACKGROUND")
    arrive.fill:SetAllPoints(arrive)
    arrive.fill:SetColorTexture(0, 0, 0, 0.62)
    local acard = CreateFrame("Frame", nil, arrive)
    acard:SetSize(460, 290)
    acard:SetPoint("CENTER", 0, 10)
    acard.surface, acard.outline = Kit.Rounded(acard, 18, 0.07, 0.085, 0.095, 0.99, 0.14)
    acard.disc = acard:CreateTexture(nil, "ARTWORK")
    acard.disc:SetSize(104, 104)
    acard.disc:SetPoint("TOP", 0, -18)
    acard.title = Kit.Text(acard, 18, C.text, "CENTER")
    acard.title:SetPoint("TOP", 0, -130)
    acard.title:SetWidth(420)
    acard.title:SetWordWrap(false)
    acard.lines = {}
    for i = 1, 3 do
        local line = Kit.Text(acard, 11, C.textSoft, "CENTER")
        line:SetPoint("TOP", 0, -160 - (i - 1) * 22)
        line:SetWidth(420)
        line:SetWordWrap(false)
        acard.lines[i] = line
    end
    acard.ok = Kit.Button(acard, 180, 34, "", function()
        In:Greeted(arrive.fid)
        UI:Refresh()
    end)
    acard.ok:SetPoint("BOTTOM", 0, 16)
    acard.ok:SetStyle("primary")
    arrive.card = acard
    arrive:Hide()
    s.arrive = arrive

    local function RefreshList()
        local back, away = In:BackCount(), In:AwayCount()
        if back > 0 then
            s.head:SetText(T(back == 1 and "innBackOneH" or "innBackManyH", back)); s.sub:SetText(T("innBackS"))
        elseif away > 0 then
            s.head:SetText(T("innAwayH", away)); s.sub:SetText(T("innAwayS"))
        else
            s.head:SetText(T("innH")); s.sub:SetText(T("innS"))
        end
        local ids = In:RoomList()
        for i, row in ipairs(s.rows) do
            local fid = ids[i]
            row:SetShown(fid ~= nil)
            if fid then
                FillFollower(row, fid)
                local lit = In:State(fid) == "back"
                row.outline:SetColor(lit and C.accent[1] or 1, lit and C.accent[2] or 1, lit and C.accent[3] or 1, lit and 0.55 or 0.06)
                local q, ok = In:NextQuality(fid)
                row.right:SetText(q and ok and ("|cff40d9c4" .. T("folCanPromote", T("q_" .. q)) .. "|r") or T("folOpen"))
            end
        end
        local nextDef = KH.Balance.FOLLOWERS[V:Level("inn") + 1]
        if nextDef and nextDef.from then nextDef = nil end      -- the six of the village come with the Inn
        local lodged = In:Count() - #ids
        s.action:Show()
        s.action:SetLabel(T("collectAll"))
        s.action:SetEnabledState(back > 0)
        s.action:SetStyle(back > 0 and "primary" or "quiet")
        local merit, epic = In:Insignias()
        Kit.Fit(s.note, T("innNote", V:Good("fish"), merit, epic)
            .. (lodged > 0 and (" · " .. T("innLodged", lodged)) or "")
            .. (nextDef and ("   |cff757a87" .. T("innNext", FName(nextDef.id), V:Level("inn") + 1) .. "|r") or ""), W - 240)
    end

    -- what a worker gives at a place, in words ("plants 25% faster")
    local function WorkFx(place, bonus) return T("workFx_" .. place, math.floor(bonus * 100 + 0.5)) end

    local function RefreshWork()
        local J = KH.Balance.JOBS
        local at = UI.innWorkAt
        s.wstop:Hide()
        s.action:Hide()
        s.note:SetText("")
        if not at then
            local working = 0
            for _, place in ipairs(J.order) do if In:Worker(place) then working = working + 1 end end
            s.head:SetText(T("workH"))
            s.sub:SetText(T("workS", working, #J.order))
            for i, row in ipairs(s.wrows) do
                local place = J.order[i]
                row:SetShown(place ~= nil)
                row.place, row.fid = place, nil
                if place then
                    local level = V:Level(place)
                    local fid = level > 0 and In:Worker(place)
                    row.disc:SetTexture(BuildingArt(place))
                    Kit.Fit(row.name, BuildingName(place) .. (level > 0 and ("  |cffa8adb8" .. T("folLevel", level) .. "|r") or ""), 230)
                    if level == 0 then
                        Kit.Fit(row.meta, T("workLocked"), 230)
                        Kit.Fit(row.gain, "", 10)
                    elseif fid then
                        Kit.Fit(row.meta, T("workBy", FName(fid)), 230)
                        Kit.Fit(row.gain, "|cff59d973" .. WorkFx(place, In.JobBonus(fid, place)) .. "|r", W - 430)
                    else
                        Kit.Fit(row.meta, "|cffa8adb8" .. T("workNobody") .. "|r", 230)
                        Kit.Fit(row.gain, "|cffa8adb8" .. T("workUpTo", WorkFx(place, In.PlaceBonus(place, true)),
                            T("job_" .. J[place])) .. "|r", W - 430)
                    end
                    row.button:SetShown(level > 0)
                    if level > 0 then
                        row.button:SetLabel(T(fid and "workChange" or "workChoose"))
                        row.button:SetStyle(fid and "quiet" or "primary")
                    end
                end
            end
            s.wprev:Hide(); s.wnext:Hide(); s.wpage:SetText("")
            return
        end
        -- who could work at that place: the trade first, then the Lodging
        local list = In:Workers(at)
        local fid = In:Worker(at)
        s.head:SetText(T("workPickH", BuildingName(at)))
        s.sub:SetText(T("workPickS", WorkFx(at, In.PlaceBonus(at, false)), T("job_" .. J[at]), WorkFx(at, In.PlaceBonus(at, true))))
        local pages = math.max(1, math.ceil(#list / DG_ROWS))
        if UI.innWorkPage > pages then UI.innWorkPage = pages end
        local first = (UI.innWorkPage - 1) * DG_ROWS
        for i, row in ipairs(s.wrows) do
            local c = list[first + i]
            row:SetShown(c ~= nil)
            row.place, row.fid = nil, c and c.id
            if c then
                local f = In:Get(c.id)
                local pro = In.Def(c.id).job == J[at]
                row.disc:SetTexture(Portrait(c.id))
                Kit.Fit(row.name, QName(f.quality, FName(c.id)) .. "  |cffa8adb8" .. T("folLevel", f.level) .. "|r", 230)
                Kit.Fit(row.meta, (pro and ("|cff40d9c4" .. T("job_" .. J[at]) .. "|r · ") or "")
                    .. T(c.room and "rankRoom" or "rankLodge"), 230)
                Kit.Fit(row.gain, (pro and "|cff59d973" or "|cffa8adb8") .. WorkFx(at, c.bonus) .. "|r", W - 430)
                row.button:Show()
                row.button:SetLabel(T("workPut"))
                row.button:SetStyle(pro and "primary" or "quiet")
            end
        end
        s.wprev:SetShown(pages > 1); s.wnext:SetShown(pages > 1)
        s.wpage:SetText(pages > 1 and (UI.innWorkPage .. " / " .. pages) or "")
        s.wprev:SetEnabledState(UI.innWorkPage > 1)
        s.wnext:SetEnabledState(UI.innWorkPage < pages)
        if #list == 0 then s.note:SetText(T("workPickNone")) end
        s.wstop:SetShown(fid ~= nil)
        if fid then s.wstop:SetLabel(T("workStopWho", FName(fid))) end
    end

    local function RefreshRanking()
        local list = In:Ranking()
        s.head:SetText(T("rankH"))
        s.sub:SetText(T("rankS", #list, In:Total(), #In:RoomList(), In:Rooms()))
        local pages = math.max(1, math.ceil(#list / DG_ROWS))
        if UI.innRank > pages then UI.innRank = pages end
        if UI.innSwap and (not In:Has(UI.innSwap) or In:InRoom(UI.innSwap)) then UI.innSwap = nil end
        local first = (UI.innRank - 1) * DG_ROWS
        for i, row in ipairs(s.rrows) do
            local r = list[first + i]
            row:SetShown(r ~= nil)
            row.fid = r and r.id
            if r then
                local f = In:Get(r.id)
                row.pos:SetText(tostring(first + i))
                row.disc:SetTexture(Portrait(r.id))
                Kit.Fit(row.name, QName(f.quality, FName(r.id)) .. "  |cffa8adb8" .. T("folLevel", f.level) .. "|r", 250)
                Kit.Fit(row.meta, T("q_" .. f.quality) .. " · " .. StateText(r.id), 250)
                row.power:SetText(T("rankPower", r.power))
                row.where:SetText(r.room and ("|cff40d9c4" .. T("rankRoom") .. "|r") or T("rankLodge"))
                local home = In:State(r.id) == "home" or In:State(r.id) == "hurt"
                local label, show
                if UI.innSwap then
                    if r.id == UI.innSwap then label, show = T("rankCancel"), true
                    elseif r.room then label, show = T("rankSwap"), home end
                elseif r.room then
                    label, show = T("rankToLodge"), home
                else
                    label, show = T("rankToRoom"), home
                end
                row.button:SetShown(show and true or false)
                if show then
                    row.button:SetLabel(label)
                    row.button:SetStyle((UI.innSwap and r.id ~= UI.innSwap or not r.room) and "primary" or "quiet")
                end
                local lit = r.id == UI.innSwap
                row.outline:SetColor(lit and C.accent[1] or 1, lit and C.accent[2] or 1, lit and C.accent[3] or 1, lit and 0.55 or 0.06)
            end
        end
        s.rpage:SetText(UI.innRank .. " / " .. pages)
        s.rprev:SetEnabledState(UI.innRank > 1)
        s.rnext:SetEnabledState(UI.innRank < pages)
        s.action:Hide()
        s.note:SetText("")
    end

    local function RefreshDungeons()
        s.head:SetText(T("dgH")); s.sub:SetText(T("dgS"))
        local daily = Dg:Daily()
        local pages = math.max(1, math.ceil(#Dg.LIST / DG_ROWS))
        if UI.innPage > pages then UI.innPage = pages end
        local first = (UI.innPage - 1) * DG_ROWS
        for i, row in ipairs(s.drows) do
            local d = Dg.LIST[first + i]
            row:SetShown(d ~= nil)
            row.id = d and d.id
            if d then
                local open = Dg:Open(d.id)
                row.name:SetText(T("dg_" .. d.id) .. (d.new and ("  |cff40d9c4" .. T("dgNew") .. "|r") or ""))
                row.meta:SetText(T(d.size == 1 and "dgMeta1" or "dgMeta", d.level, d.size, KH.Duration(d.hours * 3600)))
                for k, b in ipairs(row.threats) do
                    if d.threats[k] then ShowThreat(b, d.threats[k], false) else b:Hide() end
                end
                row:SetAlpha(open and 1 or 0.45)
                if open then
                    local party, total = Dg:Suggest(d.id)
                    local odds = #party > 0 and Dg.Odds(total) or 0
                    row.chance:SetText(#party > 0 and (ChanceColor(odds) .. Percent(odds) .. "|r") or "|cff757a87—|r")
                else
                    row.chance:SetText("|cff757a87" .. T("lockedLv", d.level - KH.Balance.DUNGEON.openAhead) .. "|r")
                end
                local visited = ((KH.db.adventure or {}).visited or {})[d.id]
                if d.raid then
                    local left = Dg:RaidLeft(d.id)
                    row.tag:SetText(left > 0 and ("|cff757a87" .. T("dgRaidLeft", KH.Duration(left)) .. "|r") or T("dgRaid"))
                elseif d.id == daily then row.tag:SetText(T("dgDaily"))
                else row.tag:SetText(visited and ("|cffa8adb8" .. T("advVisited") .. "|r") or "") end
            end
        end
        s.page:SetText(UI.innPage .. " / " .. pages)
        s.prev:SetEnabledState(UI.innPage > 1)
        s.next:SetEnabledState(UI.innPage < pages)
        s.action:Hide()
        s.note:SetText("")
    end

    local function RefreshRun()
        local id = UI.innDungeon
        local d = Dg.Get(id)
        local party = UI.innParty or {}
        for i = #party, 1, -1 do if not Dg:Free(party[i]) then table.remove(party, i) end end
        UI.innParty = party
        s.head:SetText(Dg.Name(d))
        if d.call then s.sub:SetText(T(d.size == 1 and "callS1" or "callS", d.size))
        else s.sub:SetText(T(d.size == 1 and "runS1" or "runS", d.size)) end
        run.meta:SetText(T(d.size == 1 and "dgMeta1" or "dgMeta", d.level, d.size, KH.Duration(Dg:Duration(id, party))) .. "  ·  " .. T("env_" .. d.env)
            .. (Dg:Daily() == id and ("  ·  |cff40d9c4" .. T("dgDaily") .. "|r") or ""))
        local opts = UI.innOpts or {}
        if d.raid or d.call then opts.boss = nil end
        for _, key in ipairs({"potion", "food"}) do
            if opts[key] and V:Good(opts[key]) < 1 then opts[key] = nil end
        end
        UI.innOpts = opts
        local total, parts, counters = Dg:Chance(id, party, opts)
        local countered = {}
        for _, c in ipairs(counters) do countered[#countered + 1] = c[1] end
        local threats = Dg:Threats(id, opts)
        for k, b in ipairs(run.threats) do
            local th = threats[k]
            if th then
                local dim = false
                for i, c in ipairs(countered) do if c == th then dim = true; table.remove(countered, i); break end end
                ShowThreat(b, th, dim)
            else
                b:Hide()
            end
        end
        local narrow = d.size > 3                    -- a raid: six places of 104 instead of three of 150
        for k, slot in ipairs(run.slots) do
            slot:SetShown(k <= d.size)
            slot:SetSize(narrow and 104 or 150, 44)
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", (k - 1) * (narrow and 112 or 158), -100)
            slot.disc:SetSize(narrow and 30 or 36, narrow and 30 or 36)
            slot.name:ClearAllPoints()
            slot.name:SetPoint("LEFT", narrow and 38 or 46, 0)
            slot.name:SetWidth(narrow and 62 or 100)
            local fid = party[k]
            slot.fid = fid
            if fid then
                slot.disc:SetTexture(Portrait(fid)); slot.disc:Show()
                local name = QName(In:Get(fid).quality, FName(fid))
                Kit.Fit(slot.name, narrow and name or (name .. " |cffa8adb8" .. In:Get(fid).level .. "|r"), narrow and 62 or 100)
            else
                slot.disc:Hide()
                Kit.Fit(slot.name, "|cff757a87" .. T("runEmpty") .. "|r", narrow and 62 or 100)
            end
        end
        run.freeHead:SetText(T("runFree"))
        local recs = Dg:Recommended(id, party, opts)
        for k, r in ipairs(run.free) do
            local rec = recs[k]
            r:SetShown(rec ~= nil)
            r.fid = rec and rec.id
            if rec then
                r.disc:SetTexture(Portrait(rec.id))
                Kit.Fit(r.name, QName(In:Get(rec.id).quality, FName(rec.id)) .. " |cffa8adb8" .. In:Get(rec.id).level .. "|r", 110)
                r:SetAlpha(rec.free and 1 or 0.45)
                if not rec.free then
                    local state, left = In:State(rec.id)
                    if state == "home" and In:Working(rec.id) then
                        Kit.Fit(r.tag, "|cff757a87" .. T("folWork", P.BuildingName(In:Working(rec.id))) .. "|r", 170)
                    else
                        r.tag:SetText("|cff757a87" .. T(state == "hurt" and "runHurt" or (state == "back" and "runBack" or "runBusy"),
                            KH.Duration(left)) .. "|r")
                    end
                    r.gain:SetText("")
                else
                    local names = {}
                    for i, th in ipairs(rec.counters) do names[i] = T("th_" .. th) end
                    if rec.gain > 0 and #names > 0 then Kit.Fit(r.tag, T("runRec", table.concat(names, ", ")), 170)
                    elseif rec.gain > 0 then Kit.Fit(r.tag, T("runRecPlain"), 170)
                    else r.tag:SetText("") end
                    if rec.full then
                        -- the group is full: nobody else goes, so there is nothing to add
                        r.tag:SetText("")
                        r.gain:SetText("")
                        r:SetAlpha(0.45)
                    elseif #party == 0 then
                        -- nobody picked yet: the chance this follower alone gives, the same number the screen shows next
                        local alone = Dg.Odds(rec.total)
                        r.gain:SetText(ChanceColor(alone) .. Percent(alone) .. "|r")
                    elseif rec.gain > 0 then r.gain:SetText("|cff59d973+" .. rec.gain .. "%|r")
                    elseif rec.gain < 0 then r.gain:SetText("|cffff7a6b" .. rec.gain .. "%|r")
                    else r.gain:SetText("|cff757a87+0%|r") end
                end
            end
        end
        local odds, bonus = Dg.Odds(total)
        run.chance:SetText(#party > 0 and (ChanceColor(odds) .. Percent(odds) .. "|r") or "|cff757a87—|r")
        run.chanceLabel:SetText(bonus > 1 and T("runBonus", Percent((bonus - 1) * 100)) or T("runChance"))
        -- more parts than lines: the last line adds up the rest, so what is shown always sums to the chance
        local shown = parts
        if #parts > #run.parts then
            shown = {}
            for k = 1, #run.parts - 1 do shown[k] = parts[k] end
            local rest, n = 0, 0
            for k = #run.parts, #parts do rest, n = rest + parts[k][2], n + 1 end
            shown[#run.parts] = {"more", rest, n}
        end
        for k, line in ipairs(run.parts) do
            local p = shown[k]
            if p then
                local sign = p[2] >= 0 and "|cff59d973+" or "|cffff7a6b"
                local what
                if p[1] == "threat" then what = T("partThreat", T("th_" .. p[3]))
                elseif p[1] == "trait" then what = T("partTrait", FName(p[3]))
                elseif p[1] == "gear" then what = T("partGear", FName(p[3]))
                elseif p[1] == "veteran" then what = T("partVeteran", FName(p[3]))
                elseif p[1] == "combo" then what = T("partCombo", T("cb_" .. p[3]))
                elseif p[1] == "missing" then what = T("partMissing", p[3])
                elseif p[1] == "more" then what = T("partMore", p[3])
                else what = T("part_" .. p[1]) end
                line:SetText(sign .. p[2] .. "|r  " .. what)
            else
                line:SetText("")
            end
        end
        local combos = Dg:Combos(party)
        if combos[1] then
            run.combo:SetText(Dg:Known(combos[1].id) and T("runCombo", T("cb_" .. combos[1].id) .. " · " .. T("cbd_" .. combos[1].id))
                or T("runComboUnknown"))
        else
            run.combo:SetText("")
        end
        local R = KH.Balance.DUNGEON
        run.opts[1]:SetLabel(T("runPotion", opts.potion and (T("good_" .. opts.potion) .. " |cff59d973+" .. R.potion .. "%|r") or T("runNone")))
        run.opts[2]:SetLabel(T("runFood", opts.food and (T("good_" .. opts.food) .. " |cff59d973+" .. R.food .. "%|r") or T("runNone")))
        run.opts[3]:SetLabel(T("runBoss", opts.boss and T("runBossOn") or T("runBossOff")))
        run.opts[3]:SetShown(not d.raid and not d.call)
        local who, gain = Dg:LodgeHint(id, party, opts)
        run.lodge:SetText(who and T("runLodge", FName(who), gain) or "")
        if d.raid and Dg:RaidLeft(id) > 0 then
            run.reward:SetText(T("dgRaid") .. " · " .. T("dgRaidLeft", KH.Duration(Dg:RaidLeft(id))))
        elseif #party > 0 then
            local coins, vxp = Dg:Reward(id, party, total, nil, opts)
            local trophy = Dg:TrophyChance(id, party, opts)
            run.reward:SetText(T("runReward", KH.Number(coins), KH.Number(vxp), Dg:Cost(id, party), V:Good("fish"))
                .. (trophy > 0 and ("  ·  " .. T("runTrophy", math.floor(trophy * 100 + 0.5))) or ""))
        else
            run.reward:SetText(T("runPick"))
        end
        run.suggest:SetLabel(T("runSuggest"))
        run.send:SetLabel(T("runSend"))
        run.send:SetStyle("primary")
        run.send:SetEnabledState(#party > 0 and not (d.raid and Dg:RaidLeft(id) > 0))
        s.action:Hide()
        s.note:SetText("")
    end

    local function RefreshSheet()
        local fid = UI.innFollower
        local f = In:Get(fid)
        s.head:SetText(FName(fid)); s.sub:SetText(T("fcl_" .. fid))
        sheet.disc:SetTexture(Portrait(fid))
        sheet.name:SetText(QName(f.quality, FName(fid)) .. "  |cffa8adb8" .. T("q_" .. f.quality) .. "|r")
        local need = KH.Balance.FollowerXPToNext(f.level)
        local max = f.level >= KH.Balance.FOLLOWER.maxLevel
        sheet.level:SetText(max and T("folMax", f.level) or T("folXP", f.level, KH.Number(f.xp), KH.Number(need)))
        sheet.bar:Set(max and 1 or f.xp / need)
        sheet.state:SetText(StateText(fid) .. "   |cff757a87" .. T("folRuns", f.runs or 0) .. "|r")
        local where = T(In:InRoom(fid) and "sheetRoom" or "sheetLodge")
        if In.Def(fid).from then where = T("sheetFrom", T("from_" .. fid), where) end
        if In.Def(fid).job then where = where .. "\n|cff40d9c4" .. T("job_" .. In.Def(fid).job) .. "|r: " .. T("jobd_" .. In.Def(fid).job) end
        sheet.where:SetText(where)
        local abs = In:Abilities(fid)
        for k, b in ipairs(sheet.abs) do
            if abs[k] then
                ShowAbility(b, abs[k])
                Kit.Fit(b.text, T("ab_" .. abs[k]) .. "  |cffa8adb8" .. AbilityDoes(abs[k]) .. "|r", 290)
            else
                b:Hide(); b.text:SetText("")
            end
        end
        local traits = In:Traits(fid)
        for k, line in ipairs(sheet.traits) do
            if traits[k] then
                local label, desc = TraitText(traits[k])
                line:SetText(label .. ": |cffa8adb8" .. desc .. "|r")
            else
                line:SetText("")
            end
        end
        for _, g in ipairs(sheet.gear) do
            local gid = f.gear and f.gear[g.slot]
            if gid then
                g.tex:SetTexture(D.Icon(In.Gear(gid).item)); g.tex:SetAlpha(1)
                g:SetScript("OnEnter", function(self) Tip(self, T("good_" .. gid), {T("gearHint")}) end)
                Kit.Fit(g.text, T("good_" .. gid) .. " |cff59d973" .. T("gearPower", In.Gear(gid).power) .. "|r", 222)
            else
                g.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); g.tex:SetAlpha(0.3)
                g:SetScript("OnEnter", function(self) Tip(self, T("slot_" .. g.slot), {T("gearHint")}) end)
                Kit.Fit(g.text, T("slot_" .. g.slot) .. ": |cff757a87" .. T("gearNone") .. "|r", 222)
            end
            g:Show()
            local best = In:BestGear(fid, g.slot)
            g.button:SetShown(best ~= nil or gid ~= nil)
            g.button:SetLabel(best and T("gearEquip", T("gearPower", In.Gear(best).power)) or T("gearOff"))
            g.button:SetStyle(best and "primary" or "quiet")
        end
        local q, ok = In:NextQuality(fid)
        local def = In.Def(fid)
        for _, b in ipairs(sheet.pick) do b:Hide() end
        if f.level >= KH.Balance.FOLLOWER.maxLevel and not f.mastery then
            sheet.promo:SetText(T("masterH"))
            for k, b in ipairs(sheet.pick) do
                local m = k == 1 and "veteran" or "mentor"
                b:Show(); b:SetStyle("primary")
                b:SetLabel(T("master_" .. m))
                b:SetScript("OnEnter", function(self) Tip(self, T("master_" .. m), {T("masterd_" .. m)}) end)
            end
        elseif f.mastery and not (q and ok) then
            sheet.promo:SetText(T("masterDone", T("master_" .. f.mastery), T("ttl_" .. fid)))
        elseif not q then
            sheet.promo:SetText(T("promoDone"))
        elseif not ok then
            local merit, epic = In:Insignias()
            local lv = q == "rare" and KH.Balance.FOLLOWER.rareLevel or KH.Balance.FOLLOWER.epicLevel
            sheet.promo:SetText(T("promoNeeds_" .. q, lv, q == "rare" and merit or epic))
        else
            sheet.promo:SetText(T("promoPick_" .. q))
            for k, b in ipairs(sheet.pick) do
                b:Show()
                b:SetStyle("primary")
                if q == "rare" then b:SetLabel(T("ab_" .. def.rare[k]))
                else b:SetLabel((TraitText(def.epic[k]))) end
            end
        end
        local cost = In:RespecCost(fid)
        sheet.respec[1]:SetShown(f.ability ~= nil and def.rare ~= nil)
        sheet.respec[1]:SetLabel(T("respecAbility", KH.Number(cost)))
        sheet.respec[2]:SetShown(f.trait ~= nil)
        sheet.respec[2]:SetLabel(T("respecTrait", KH.Number(cost)))
        sheet.journalHead:SetText(T("journalH"))
        local entries = KH.Journal:For(fid)
        for k, line in ipairs(sheet.journal) do
            local e = entries[k]
            if e then
                local lines = KH.Journal:Lines(e)
                line:SetText(lines[1] .. " " .. lines[2])
            else
                line:SetText(k == 1 and ("|cff757a87" .. T("journalEmpty") .. "|r") or "")
            end
        end
        sheet.chat:SetLabel(T("journalChat"))
        sheet.chat:SetShown(entries[1] ~= nil)
        s.action:Hide()
        s.note:SetText("")
    end

    local function RefreshBook()
        s.head:SetText(T("bookH")); s.sub:SetText(T("bookS"))
        local known = 0
        for k, c in ipairs(KH.Balance.COMBOS) do
            local line = book.combos[k]
            if Dg:Known(c.id) then
                known = known + 1
                line:SetText("|cff40d9c4" .. T("cb_" .. c.id) .. "|r  " .. T("cbd_" .. c.id))
            else
                line:SetText("|cff757a87" .. T("bookUnknown") .. "|r  " .. T("cbh_" .. c.id))
            end
        end
        book.combosHead:SetText(T("bookCombos", known, #KH.Balance.COMBOS))
        local got = 0
        local trophies = KH.db.dungeons.trophies or {}
        for _, b in ipairs(book.trophies) do
            local item = KH.Balance.TROPHIES[b.dungeon]
            local have = (trophies[b.dungeon] or 0) > 0
            if have then got = got + 1 end
            b.tex:SetTexture(D.Icon(item))
            b.tex:SetAlpha(have and 1 or 0.25)
            if b.tex.SetDesaturated then b.tex:SetDesaturated(not have) end
            b:SetScript("OnEnter", function(self) Tip(self, have and D.Name(item) or T("bookUnknown"), {T("dg_" .. b.dungeon)}) end)
            b:Show()
        end
        book.trophiesHead:SetText(T("bookTrophies", got, #book.trophies))
        s.action:Hide()
        s.note:SetText("")
    end

    function s:Refresh()
        local level = V:Level("inn")
        local view = "list"
        if level == 0 then view = "none"
        elseif UI.innFollower and In:Has(UI.innFollower) then view = "sheet"
        elseif UI.innDungeon and Dg.Get(UI.innDungeon) and Dg:Open(UI.innDungeon) then view = "run"
        elseif UI.innTab == "dungeons" then view = "dungeons"
        elseif UI.innTab == "ranking" then view = "ranking"
        elseif UI.innTab == "work" then view = UI.innWorkAt and "workAt" or "work"
        elseif UI.innTab == "book" then view = "book" end
        local inner = view == "sheet" or view == "run" or view == "workAt"
        self.tabs:SetShown(view ~= "none" and not inner)
        self.back:SetShown(inner)
        self.back:SetLabel(view == "sheet" and T("backFollowers") or (view == "workAt" and T("backWork") or T("backDungeons")))
        if view == "run" and Dg.Get(UI.innDungeon).call then self.back:SetLabel(T("backCalls")) end
        if inner then self.tabs:Hide() end
        self.tabHint:SetShown(view == "list" or view == "dungeons" or view == "ranking" or view == "work")
        self.book:SetShown(view == "book")
        self.rank:SetShown(view == "ranking")
        if view == "ranking" then
            self.tabHint:SetText(UI.innSwap and ("|cffffd24d" .. T("rankSwapH", FName(UI.innSwap)) .. "|r") or T("rankHint"))
        elseif view == "work" then
            self.tabHint:SetText(T("workHint"))
        else
            self.tabHint:SetText(view == "dungeons" and T("dgHint") or T("innHint"))
        end
        self.work:SetShown(view == "work" or view == "workAt")
        self.list:SetShown(view == "list")
        self.dlist:SetShown(view == "dungeons")
        self.run:SetShown(view == "run")
        self.sheet:SetShown(view == "sheet")
        if view == "none" then
            self.head:SetText(T("innNoH")); self.sub:SetText(T("innNoS"))
            self.action:Hide(); self.note:SetText("")
        elseif view == "list" then RefreshList()
        elseif view == "dungeons" then RefreshDungeons()
        elseif view == "run" then RefreshRun()
        elseif view == "ranking" then RefreshRanking()
        elseif view == "work" or view == "workAt" then RefreshWork()
        elseif view == "book" then RefreshBook()
        else RefreshSheet() end
        -- a group came back: its result first; then, if someone new came with it, the arrival card
        local trip = level > 0 and Dg.results[1]
        self.result:SetShown(trip ~= nil and trip ~= false)
        if trip then ShowResult(trip) end
        local fid = level > 0 and not trip and In:Arrivals()[1]
        while fid and not In:Has(fid) do In:Greeted(fid); fid = In:Arrivals()[1] end
        self.arrive:SetShown(fid ~= nil and fid ~= false and not trip)
        if fid then
            local card, f = self.arrive.card, In:Get(fid)
            self.arrive.fid = fid
            card.disc:SetTexture(Portrait(fid))
            Kit.Fit(card.title, T("arrH", QName(f.quality, FName(fid))), 420)
            Kit.Fit(card.lines[1], QName(f.quality, T("q_" .. f.quality)) .. " · " .. T("fcl_" .. fid), 420)
            Kit.Fit(card.lines[2], T("sheetFrom", T("from_" .. fid), T("folLevel", f.level)), 420)
            Kit.Fit(card.lines[3], T(In:InRoom(fid) and "arrRoom" or "arrLodge", FName(fid)), 420)
            card.ok:SetLabel(T("arrOk"))
        end
    end
    return s
end

P.builders.inn = BuildInn
