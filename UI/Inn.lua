--[[
    Korum Homestead - the Inn: the followers and the dungeons (docs/masmorras.md §16)

    Two tabs. Followers: a card for each one (portrait, quality, level, abilities, what it is doing); a click opens its
    sheet (abilities, traits, the next quality, the Journal). Dungeons: the dungeons of WoW Forever by level, each with its
    threats and the chance of the best free group now; a click opens the run: the threats (the countered ones dim), the
    group slots, the free followers with "Recommended" and how much each adds, the suggested group, the chance with where
    every point comes from, the reward and Send.
]]

local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local VDIR = P.VDIR
local Reason, Notice, Screen, Tip = P.Reason, P.Notice, P.Screen, P.Tip

local ICONS = "Interface\\Icons\\"
local TOP = 98                                  -- under the tabs
local ROW_H, ROW_GAP = 48, 4
local DG_ROWS, DG_H = 7, 40
local QUALITY = {uncommon = {0.12, 1, 0}, rare = {0, 0.44, 0.87}, epic = {0.64, 0.21, 0.93}, legendary = {1, 0.5, 0}}
P.QUALITY = QUALITY
UI.innTab = "followers"
UI.innPage = 1

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

local function ShowAbility(b, ab)
    local def = KH.Balance.ABILITIES[ab]
    b.tex:SetTexture(ICONS .. def.icon)
    b.tex:SetAlpha(1)
    local names = {}
    for i, th in ipairs(def.counters) do names[i] = T("th_" .. th) end
    b:SetScript("OnEnter", function(self) Tip(self, T("ab_" .. ab), {T("abCounters", table.concat(names, ", "))}) end)
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
    return T("folHome")
end

local function FollowerRow(parent, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ROW_H)
    row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
    row.disc = row:CreateTexture(nil, "ARTWORK")
    row.disc:SetSize(40, 40)
    row.disc:SetPoint("LEFT", 6, 0)
    row.name = Kit.Text(row, 13, C.text)
    row.name:SetPoint("TOPLEFT", 54, -7)
    row.state = Kit.Text(row, 10, C.textSoft)
    row.state:SetPoint("TOPLEFT", 54, -26)
    row.state:SetWidth(230)
    row.state:SetWordWrap(false)
    row.bar = Kit.Bar(row, 160, 3)
    row.bar:SetPoint("TOPLEFT", 54, -40)
    row.icons = {}
    for k = 1, 2 do
        local b = IconButton(row, 24)
        b:SetPoint("LEFT", 300 + (k - 1) * 30, 0)
        row.icons[k] = b
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
end

local function BuildInn(win)
    local s = Screen(win, "inn")
    local W = s.width
    local In, Dg = KH.Inn, KH.Dungeons

    s.tabs = Kit.Segmented(s.frame, 300, {{value = "followers", label = T("innTabFollowers")},
        {value = "dungeons", label = T("innTabDungeons")}},
        function() return UI.innTab end,
        function(v) UI.innTab = v; UI.innFollower, UI.innDungeon = nil, nil; UI:Refresh() end)
    s.tabs:SetPoint("TOPLEFT", 0, -58)
    s.back = Kit.Button(s.frame, 130, 28, "", function()
        UI.innFollower, UI.innDungeon, UI.innParty = nil, nil, nil
        UI:Refresh()
    end)
    s.back:SetPoint("TOPLEFT", 0, -58)
    s.tabHint = Kit.Text(s.frame, 11, C.textSoft)
    s.tabHint:SetPoint("TOPLEFT", 316, -66)
    s.tabHint:SetWidth(W - 316)
    s.tabHint:SetWordWrap(false)

    -- the followers tab
    local list = CreateFrame("Frame", nil, s.frame)
    list:SetAllPoints(s.frame)
    s.list = list
    s.rows = {}
    for i = 1, In.MAX do
        local row = FollowerRow(list, W)
        row:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * (ROW_H + ROW_GAP))
        row:SetScript("OnClick", function() UI.innFollower = row.fid; UI:Refresh() end)
        s.rows[i] = row
    end
    s.action = Kit.Button(s.frame, 220, 36, "", function()
        local coins, _, trips = Dg:CollectAll()
        if trips and trips[1] and trips[1].dungeon then
            Notice(KH.Journal:ChatText(KH.Journal:Latest()))
        elseif coins > 0 then
            Notice(T("collected", KH.Number(coins)))
        end
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
                UI.innDungeon, UI.innParty = row.id, nil
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
    for k = 1, 3 do
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
    for k = 1, In.MAX do
        local r = CreateFrame("Button", nil, run)
        r:SetSize(380, 34)
        r:SetPoint("TOPLEFT", 0, -172 - (k - 1) * 37)
        r.surface, r.outline = Kit.Rounded(r, 9, 1, 1, 1, 0.04, 0.05)
        r.disc = r:CreateTexture(nil, "ARTWORK")
        r.disc:SetSize(28, 28)
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
    for k = 1, 8 do
        local line = Kit.Text(run, 10, C.textSoft)
        line:SetPoint("TOPLEFT", 400, -202 - (k - 1) * 16)
        line:SetWidth(W - 400)
        line:SetWordWrap(false)
        run.parts[k] = line
    end
    run.reward = Kit.Text(run, 11, C.gold)
    run.reward:SetPoint("BOTTOMLEFT", 0, 48)
    run.reward:SetWidth(W)
    run.reward:SetWordWrap(false)
    run.suggest = Kit.Button(run, 180, 36, "", function()
        UI.innParty = Dg:Suggest(UI.innDungeon)
        UI:Refresh()
    end)
    run.suggest:SetPoint("BOTTOMLEFT", 0, 0)
    run.send = Kit.Button(run, 220, 36, "", function()
        local ok, why, n = Dg:Send(UI.innDungeon, UI.innParty or {})
        if ok then
            Notice(T("dgSent", T("dg_" .. UI.innDungeon)))
            UI.innDungeon, UI.innParty = nil, nil
            UI.innTab = "followers"
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
        local line = Kit.Text(sheet, 11, C.textSoft)
        line:SetPoint("TOPLEFT", 0, -254 - (k - 1) * 18)
        line:SetWidth(320)
        line:SetWordWrap(false)
        sheet.traits[k] = line
    end
    sheet.promo = Kit.Text(sheet, 11, C.text)
    sheet.promo:SetPoint("TOPLEFT", 0, -300)
    sheet.promo:SetWidth(320)
    sheet.pick = {}
    for k = 1, 2 do
        local b = Kit.Button(sheet, 150, 30, "", function()
            if In:Promote(UI.innFollower, k) then Notice(T("promoted", FName(UI.innFollower))) end
            UI:Refresh()
        end)
        b:SetPoint("TOPLEFT", (k - 1) * 158, -336)
        sheet.pick[k] = b
    end
    sheet.respec = {}
    for k, what in ipairs({"ability", "trait"}) do
        local b = Kit.Button(sheet, 150, 26, "", function()
            local ok, why = In:Respec(UI.innFollower, what)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        b:SetPoint("TOPLEFT", (k - 1) * 158, -374)
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

    local function RefreshList()
        local back, away = In:BackCount(), In:AwayCount()
        if back > 0 then
            s.head:SetText(T(back == 1 and "innBackOneH" or "innBackManyH", back)); s.sub:SetText(T("innBackS"))
        elseif away > 0 then
            s.head:SetText(T("innAwayH", away)); s.sub:SetText(T("innAwayS"))
        else
            s.head:SetText(T("innH")); s.sub:SetText(T("innS"))
        end
        local ids = In:List()
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
        local nextDef = KH.Balance.FOLLOWERS[#ids + 1]
        s.action:Show()
        s.action:SetLabel(T("collectAll"))
        s.action:SetEnabledState(back > 0)
        s.action:SetStyle(back > 0 and "primary" or "quiet")
        local merit, epic = In:Insignias()
        s.note:SetText(T("innNote", V:Good("fish"), merit, epic)
            .. (nextDef and ("   |cff757a87" .. T("innNext", FName(nextDef.id), #ids + 1) .. "|r") or ""))
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
                row.meta:SetText(T("dgMeta", d.level, d.size, KH.Duration(d.hours * 3600)))
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
                row.tag:SetText(d.id == daily and T("dgDaily") or "")
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
        s.head:SetText(T("dg_" .. id)); s.sub:SetText(T("runS", d.size))
        run.meta:SetText(T("dgMeta", d.level, d.size, KH.Duration(Dg:Duration(id, party))) .. "  ·  " .. T("env_" .. d.env)
            .. (Dg:Daily() == id and ("  ·  |cff40d9c4" .. T("dgDaily") .. "|r") or ""))
        local total, parts, counters = Dg:Chance(id, party)
        local countered = {}
        for _, c in ipairs(counters) do countered[#countered + 1] = c[1] end
        for k, b in ipairs(run.threats) do
            local th = d.threats[k]
            if th then
                local dim = false
                for i, c in ipairs(countered) do if c == th then dim = true; table.remove(countered, i); break end end
                ShowThreat(b, th, dim)
            else
                b:Hide()
            end
        end
        for k, slot in ipairs(run.slots) do
            slot:SetShown(k <= d.size)
            local fid = party[k]
            slot.fid = fid
            if fid then
                slot.disc:SetTexture(Portrait(fid)); slot.disc:Show()
                slot.name:SetText(QName(In:Get(fid).quality, FName(fid)) .. " |cffa8adb8" .. In:Get(fid).level .. "|r")
            else
                slot.disc:Hide()
                slot.name:SetText("|cff757a87" .. T("runEmpty") .. "|r")
            end
        end
        run.freeHead:SetText(T("runFree"))
        local recs = Dg:Recommended(id, party)
        for k, r in ipairs(run.free) do
            local rec = recs[k]
            r:SetShown(rec ~= nil)
            r.fid = rec and rec.id
            if rec then
                r.disc:SetTexture(Portrait(rec.id))
                r.name:SetText(QName(In:Get(rec.id).quality, FName(rec.id)) .. " |cffa8adb8" .. In:Get(rec.id).level .. "|r")
                r:SetAlpha(rec.free and 1 or 0.45)
                if not rec.free then
                    local state, left = In:State(rec.id)
                    r.tag:SetText("|cff757a87" .. T(state == "hurt" and "runHurt" or (state == "back" and "runBack" or "runBusy"),
                        KH.Duration(left)) .. "|r")
                    r.gain:SetText("")
                else
                    local names = {}
                    for i, th in ipairs(rec.counters) do names[i] = T("th_" .. th) end
                    if rec.gain > 0 and #names > 0 then r.tag:SetText(T("runRec", table.concat(names, ", ")))
                    elseif rec.gain > 0 then r.tag:SetText(T("runRecPlain"))
                    else r.tag:SetText("") end
                    if rec.gain > 0 then r.gain:SetText("|cff59d973+" .. rec.gain .. "%|r")
                    elseif rec.gain < 0 then r.gain:SetText("|cffff7a6b" .. rec.gain .. "%|r")
                    else r.gain:SetText("|cff757a87+0%|r") end
                end
            end
        end
        local odds, bonus = Dg.Odds(total)
        run.chance:SetText(#party > 0 and (ChanceColor(odds) .. Percent(odds) .. "|r") or "|cff757a87—|r")
        run.chanceLabel:SetText(bonus > 1 and T("runBonus", Percent((bonus - 1) * 100)) or T("runChance"))
        for k, line in ipairs(run.parts) do
            local p = parts[k]
            if p then
                local sign = p[2] > 0 and "|cff59d973+" or "|cffff7a6b"
                local what
                if p[1] == "threat" then what = T("partThreat", T("th_" .. p[3]))
                elseif p[1] == "trait" then what = T("partTrait", FName(p[3]))
                elseif p[1] == "missing" then what = T("partMissing", p[3])
                else what = T("part_" .. p[1]) end
                line:SetText(sign .. p[2] .. "|r  " .. what)
            else
                line:SetText("")
            end
        end
        if #party > 0 then
            local coins, vxp = Dg:Reward(id, party, total)
            run.reward:SetText(T("runReward", KH.Number(coins), KH.Number(vxp), Dg:Cost(id, party), V:Good("fish")))
        else
            run.reward:SetText(T("runPick"))
        end
        run.suggest:SetLabel(T("runSuggest"))
        run.send:SetLabel(T("runSend"))
        run.send:SetStyle("primary")
        run.send:SetEnabledState(#party > 0)
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
        local abs = In:Abilities(fid)
        for k, b in ipairs(sheet.abs) do
            if abs[k] then
                ShowAbility(b, abs[k])
                local names = {}
                for i, th in ipairs(KH.Balance.ABILITIES[abs[k]].counters) do names[i] = T("th_" .. th) end
                b.text:SetText(T("ab_" .. abs[k]) .. "  |cffa8adb8" .. T("abCounters", table.concat(names, ", ")) .. "|r")
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
        local q, ok = In:NextQuality(fid)
        local def = In.Def(fid)
        for _, b in ipairs(sheet.pick) do b:Hide() end
        if not q then
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
        sheet.respec[1]:SetShown(f.ability ~= nil)
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

    function s:Refresh()
        local level = V:Level("inn")
        local view = "list"
        if level == 0 then view = "none"
        elseif UI.innFollower and In:Has(UI.innFollower) then view = "sheet"
        elseif UI.innDungeon and Dg.Get(UI.innDungeon) and Dg:Open(UI.innDungeon) then view = "run"
        elseif UI.innTab == "dungeons" then view = "dungeons" end
        local inner = view == "sheet" or view == "run"
        self.tabs:SetShown(view ~= "none" and not inner)
        self.back:SetShown(inner)
        self.back:SetLabel(view == "sheet" and T("backFollowers") or T("backDungeons"))
        self.tabHint:SetShown(view == "list" or view == "dungeons")
        self.tabHint:SetText(view == "dungeons" and T("dgHint") or T("innHint"))
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
        else RefreshSheet() end
    end
    return s
end

P.builders.inn = BuildInn
