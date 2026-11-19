local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip
local Effect = P.Effect

local GUIDE_PAGES = {"start", "buildings", "herbs", "tips"}

local function BuildGuide(win)
    local s = Screen(win)
    local W = s.width
    UI.guidePage = UI.guidePage or "start"
    local options = {}
    for _, id in ipairs(GUIDE_PAGES) do options[#options + 1] = {value = id, label = T("g_" .. id)} end
    s.pick = Kit.Segmented(s.frame, 480, options, function() return UI.guidePage end, function(v) UI.guidePage = v; UI:Refresh() end)
    s.pick:SetPoint("TOPLEFT", 0, -64)
    s.pages = {}
    local TOP = -110
    local function Page(id)
        local p = CreateFrame("Frame", nil, s.frame)
        p:SetPoint("TOPLEFT", 0, TOP)
        p:SetPoint("BOTTOMRIGHT", 0, 0)
        p:Hide()
        s.pages[id] = p
        return p
    end

    -- 1. the first steps, numbered
    local p = Page("start")
    p.steps = {}
    for i = 1, 4 do
        local row = CreateFrame("Frame", nil, p)
        row:SetSize(W, 58)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 62)
        row.disc = row:CreateTexture(nil, "ARTWORK")
        row.disc:SetTexture(Kit.Icon("dot"))
        row.disc:SetSize(46, 46)
        row.disc:SetPoint("LEFT", -6, 0)
        row.disc:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.16)
        row.n = Kit.Text(row, 14, C.accent, "CENTER")
        row.n:SetPoint("CENTER", row.disc, "CENTER", 0, 0)
        row.n:SetText(tostring(i))
        row.title = Kit.Text(row, 13, C.text)
        row.title:SetPoint("TOPLEFT", 50, -10)
        row.text = Kit.Text(row, 11, C.textSoft)
        row.text:SetPoint("TOPLEFT", 50, -30)
        row.text:SetWidth(W - 56)
        row.text:SetWordWrap(true)
        p.steps[i] = row
    end
    p.note = Kit.Text(p, 11, C.textMuted)
    p.note:SetPoint("TOPLEFT", 0, -4 * 62 - 14)
    p.note:SetWidth(W)
    p.note2 = Kit.Text(p, 11, C.textMuted)
    p.note2:SetPoint("TOPLEFT", p.note, "BOTTOMLEFT", 0, -8)
    p.note2:SetWidth(W)

    -- 2. the buildings: what each one is for, and what a level changes
    p = Page("buildings")
    p.rows = {}
    for i, id in ipairs(V.BUILDINGS) do
        local row = CreateFrame("Frame", nil, p)
        row.id = id
        row:SetSize(W, 40)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 42)
        row.art = row:CreateTexture(nil, "ARTWORK")
        row.art:SetSize(34, 34)
        row.art:SetPoint("LEFT", 0, 1)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 46, -1)
        row.what = Kit.Text(row, 10, C.textSoft)
        row.what:SetPoint("TOPLEFT", 46, -15)
        row.what:SetWidth(W - 50)
        row.what:SetWordWrap(false)
        row.levels = Kit.Text(row, 10, C.accent)
        row.levels:SetPoint("TOPLEFT", 46, -27)
        row.levels:SetWidth(W - 64)
        row.levels:SetWordWrap(false)
        row.rule = Kit.Hairline(row, 0.05)
        row.rule:SetPoint("BOTTOMLEFT")
        row.rule:SetPoint("BOTTOMRIGHT")
        p.rows[i] = row
    end
    p.note = Kit.Text(p, 11, C.textMuted)
    p.note:SetPoint("TOPLEFT", 0, -8 * 42 + 2)
    p.note:SetWidth(W)

    -- 3. the herbs: one line each, the ones still locked faded
    p = Page("herbs")
    local COL = {30, 236, 316, 400, 486, 572}
    p.head = {}
    for c = 1, 6 do
        local h = Kit.Text(p, 10, C.textMuted)
        h:SetPoint("TOPLEFT", COL[c], 0)
        p.head[c] = h
    end
    p.rows = {}
    for i = 1, 13 do                     -- the same window of herbs as the Garden's strip (UI.SeedWindow)
        local row = CreateFrame("Frame", nil, p)
        row.id = D.PLANTS[i][1]
        row:SetSize(W, 24)
        row:SetPoint("TOPLEFT", 0, -20 - (i - 1) * 24)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", 2, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.cells = {}
        for c = 1, 6 do
            local cell = Kit.Text(row, 11, c == 1 and C.text or C.textSoft)
            cell:SetPoint("LEFT", COL[c], 0)
            if c == 1 then
                cell:SetWidth(COL[2] - COL[1] - 8)
                cell:SetWordWrap(false)
            end
            row.cells[c] = cell
        end
        p.rows[i] = row
    end

    -- 4. tips
    p = Page("tips")
    p.lines = {}
    for i = 1, 6 do
        local dot = p:CreateTexture(nil, "ARTWORK")
        dot:SetTexture(Kit.Icon("dot"))
        dot:SetSize(12, 12)
        dot:SetPoint("TOPLEFT", -2, -(i - 1) * 46 - 3)
        dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        local line = Kit.Text(p, 12, C.text)
        line:SetPoint("TOPLEFT", 20, -(i - 1) * 46)
        line:SetWidth(W - 24)
        p.lines[i] = line
    end

    function s:Refresh()
        local db = KH.db
        self.head:SetText(T("guideH"))
        self.sub:SetText(T("guideS"))
        for i, b in ipairs(self.pick.buttons) do b.label:SetText(T("g_" .. GUIDE_PAGES[i])) end
        self.pick:Sync()
        for id, page in pairs(self.pages) do page:SetShown(id == UI.guidePage) end

        local start = self.pages.start
        for i, row in ipairs(start.steps) do
            row.title:SetText(T("g_s" .. i .. "T"))
            row.text:SetText(T("g_s" .. i .. "D"))
        end
        start.note:SetText(T("g_clock"))
        start.note2:SetText(T("g_coins"))

        local b = self.pages.buildings
        for _, row in ipairs(b.rows) do
            row.art:SetTexture(BuildingArt(row.id, math.max(1, V:Level(row.id))))
            row.name:SetText(V:Level(row.id) == 0 and T("notBuilt", BuildingName(row.id)) or T("nameLevelLong", BuildingName(row.id), V:Level(row.id)))
            row.what:SetText(T("b_" .. row.id .. "D"))
            row.levels:SetText(T("g_levels", Effect(row.id, 1), V.MAX_LEVEL, Effect(row.id, V.MAX_LEVEL)))
        end
        b.note:SetText(T("g_rule"))

        local h = self.pages.herbs
        for c, key in ipairs({"g_cHerb", "g_cLevel", "g_cGrow", "g_cSeed", "g_cYield", "g_cSell"}) do h.head[c]:SetText(T(key)) end
        local first = UI.seedFirst or UI.SeedWindow(db.level)        -- the Garden's arrows move this page too
        for i, row in ipairs(h.rows) do
            row.id = D.PLANTS[first + i - 1][1]
            local plant = D.Plant(row.id)
            local locked = db.level < plant.level
            SetIcon(row.icon, row.id)
            row.icon:SetAlpha(locked and 0.3 or 1)
            if row.icon.SetDesaturated then row.icon:SetDesaturated(locked) end
            local values = {D.Name(row.id), tostring(plant.level), KH.Duration(plant.grow), KH.Number(plant.cost),
                tostring(D.Yield(plant, db.level)), KH.Number(math.floor(plant.sell * V:PayBonus()))}
            for c, cell in ipairs(row.cells) do
                cell:SetText(values[c])
                Kit.Paint(cell, locked and C.textFaint or (c == 1 and C.text or C.textSoft))
            end
        end

        for i, line in ipairs(self.pages.tips.lines) do line:SetText(T("g_t" .. i)) end
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The Workshop: herbs into potions, in a queue that goes on while the game is closed
-- ----------------------------------------------------------------------------

P.builders.guide = BuildGuide
