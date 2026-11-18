local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local TILE_H, TILE_GAP, COLS = 128, 10, 4
local RING_Y = -48

local STRIP = 13                 -- seeds shown on the strip at once

-- the first herb of the strip: the last ones open now, and two still to come
local function SeedWindow(level)
    local open = 0
    for i, p in ipairs(D.PLANTS) do if p[2] <= level then open = i end end
    return math.max(1, math.min(#D.PLANTS - STRIP + 1, open - (STRIP - 3)))
end
UI.SeedWindow = SeedWindow

local function CanPlant(id)
    local plant = D.Plant(id)
    return plant ~= nil and KH.db.level >= plant.level and KH.db.coins >= plant.cost
end

local function PaintTile(t)
    local live = t.live and t.hover
    t.surface:SetColor(1, 1, 1, t.dim and 0.02 or (live and 0.09 or 0.045))
    if t.status == "ready" then
        t.outline:SetColor(C.accent[1], C.accent[2], C.accent[3], live and 0.95 or 0.55)
    elseif not t.hinted then
        t.outline:SetColor(1, 1, 1, t.dim and 0.03 or (live and 0.18 or 0.06))
    end
end

local function BuildGarden(win)
    local s = Screen(win, "garden")
    local W = s.width
    local tileW = math.floor((W - TILE_GAP * (COLS - 1)) / COLS)

    s.tiles = {}
    for i = 1, D.MAX_PLOTS do
        local t = CreateFrame("Button", nil, s.frame)
        t:SetSize(tileW, TILE_H)
        t:SetPoint("TOPLEFT", ((i - 1) % COLS) * (tileW + TILE_GAP), -66 - math.floor((i - 1) / COLS) * (TILE_H + TILE_GAP))
        t.surface, t.outline = Kit.Rounded(t, 12, 1, 1, 1, 0.045, 0.06)
        t.glow = t:CreateTexture(nil, "BACKGROUND", nil, 2)
        t.glow:SetTexture(Kit.Icon("glow"))
        t.glow:SetSize(124, 124)
        t.glow:SetPoint("CENTER", t, "TOP", 0, RING_Y)
        t.glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
        if t.glow.SetBlendMode then t.glow:SetBlendMode("ADD") end
        t.glow:SetAlpha(0)
        t.ring = Kit.Ring(t, 32, 36, 5)
        t.ring:SetPoint("CENTER", t, "TOP", 0, RING_Y)
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetSize(46, 46)
        t.icon:SetPoint("CENTER", t, "TOP", 0, RING_Y)
        t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        Kit.RoundMask(t, t.icon)
        t.lock = t:CreateTexture(nil, "ARTWORK")
        t.lock:SetTexture(Kit.Icon("lock"))
        t.lock:SetSize(26, 26)
        t.lock:SetPoint("CENTER", t, "TOP", 0, RING_Y)
        t.lock:Hide()
        t.title = Kit.Text(t, 12, C.text, "CENTER")
        t.title:SetPoint("TOP", 0, -90)
        t.title:SetWidth(tileW - 12)
        t.title:SetWordWrap(false)
        t.note = Kit.Text(t, 10, C.textSoft, "CENTER")
        t.note:SetPoint("TOP", 0, -108)
        t.note:SetWidth(tileW - 12)
        t.note:SetWordWrap(false)
        t:SetScript("OnEnter", function(self) self.hover = true; PaintTile(self) end)
        t:SetScript("OnLeave", function(self) self.hover = false; PaintTile(self) end)
        t:SetScript("OnClick", function() Kit.ClickSound(); s:Click(i) end)
        -- the x of a growing plot: planted the wrong seed? pull it up (two clicks, the seed is lost)
        t.clear = Kit.Button(t, 24, 24, "×", function() s:Clear(i) end)
        t.clear:SetPoint("TOPRIGHT", -6, -6)
        t.clear:SetFrameLevel(t:GetFrameLevel() + 5)
        local enter, leave = t.clear:GetScript("OnEnter"), t.clear:GetScript("OnLeave")
        t.clear:SetScript("OnEnter", function(self) enter(self); Tip(self, T("clearTip"), {T("clearTipS")}) end)
        t.clear:SetScript("OnLeave", function(self) leave(self); if GameTooltip then GameTooltip:Hide() end end)
        t.clear:Hide()
        s.tiles[i] = t
    end

    -- the seeds: one strip of herbs, the chosen one framed, the locked ones faded with their level. With 27 herbs the strip
    -- shows a window of STRIP of them: the best ones open now and the next ones to come
    local seedsY = -66 - 2 * TILE_H - TILE_GAP - 18
    s.seedsLabel = Kit.Text(s.frame, 11, C.textMuted)
    s.seedsLabel:SetPoint("TOPLEFT", 0, seedsY)
    -- the arrows walk the strip to the herbs before and after it (the Workshop needs the early ones too)
    local function Shift(step)
        local last = #D.PLANTS - STRIP + 1
        UI.seedFirst = math.max(1, math.min(last, (UI.seedFirst or SeedWindow(KH.db.level)) + step))
        UI:Refresh()
    end
    s.seedNext = Kit.Button(s.frame, 26, 20, "›", function() Shift(STRIP - 3) end)
    s.seedNext:SetPoint("TOPRIGHT", 0, seedsY + 3)
    s.seedPrev = Kit.Button(s.frame, 26, 20, "‹", function() Shift(-(STRIP - 3)) end)
    s.seedPrev:SetPoint("RIGHT", s.seedNext, "LEFT", -6, 0)
    s.seeds = {}
    local slotW = math.floor(W / STRIP)
    for i = 1, STRIP do
        local b = CreateFrame("Button", nil, s.frame)
        b:SetSize(slotW, 58)
        b:SetPoint("TOPLEFT", (i - 1) * slotW, seedsY - 18)
        b.id = D.PLANTS[i][1]
        b.frame = CreateFrame("Frame", nil, b)
        b.frame:SetSize(44, 44)
        b.frame:SetPoint("TOP", 0, 0)
        b.fill, b.edge = Kit.Rounded(b.frame, 10, 1, 1, 1, 0, 0)
        b.icon = b.frame:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(34, 34)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        Kit.RoundMask(b.frame, b.icon)
        b.star = b.frame:CreateTexture(nil, "OVERLAY")           -- the suggested seed: a small accent dot
        b.star:SetTexture(Kit.Icon("dot"))
        b.star:SetSize(12, 12)
        b.star:SetPoint("TOPRIGHT", 3, 3)
        b.star:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        b.star:Hide()
        b.note = Kit.Text(b, 9, C.textMuted, "CENTER")
        b.note:SetPoint("TOP", 0, -47)
        b.note:SetWidth(slotW)
        b.note:SetWordWrap(false)
        b:SetScript("OnEnter", function(self) self.hover = true; s.hoverSeed = self.id; s:RefreshSeeds() end)
        b:SetScript("OnLeave", function(self) self.hover = false; s.hoverSeed = nil; s:RefreshSeeds() end)
        b:SetScript("OnClick", function(self) Kit.ClickSound(); s:Pick(self.id) end)
        s.seeds[i] = b
    end

    -- the last line: what the seed under the mouse (or the chosen one) costs and gives; and the one button
    s.primary = Kit.Button(s.frame, 190, 36, "", function() s:Primary() end)
    s.primary:SetPoint("BOTTOMRIGHT", 0, 0)
    s.primary:SetStyle("primary")
    s.detail = Kit.Text(s.frame, 11, C.textSoft)
    s.detail:SetPoint("BOTTOMLEFT", 0, 12)
    s.detail:SetWidth(W - 210)
    s.detail:SetWordWrap(false)

    -- the glow of what is ready breathes; the plot the first step points at blinks softly
    s.clock = 0
    s.frame:SetScript("OnUpdate", function(_, elapsed)
        s.clock = s.clock + (tonumber(elapsed) or 0)
        local wave = 0.5 + 0.5 * math.sin(s.clock * 3)
        for _, t in ipairs(s.tiles) do
            if t.status == "ready" then t.glow:SetAlpha(0.20 + 0.20 * wave) end
            if t.hinted then t.outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.30 + 0.60 * wave) end
        end
    end)

    function s:Pick(id)
        local plant = D.Plant(id)
        if not plant then return end
        if KH.db.level < plant.level then
            Notice(T("needLevel", plant.level))
            return
        end
        KH.db.selected = id
        UI:Refresh()
    end

    function s:Click(i)
        local db = KH.db
        local status = KH.Farm:Status(i)
        local tile = self.tiles[i]
        if status == "locked" then
            UI:Show("hall")                       -- more plots come from a bigger Garden, built in the Hall
        elseif status == "ready" then
            local n, why = KH.Farm:Harvest(i)
            if n > 0 then Kit.Float(tile.ring, "+" .. n, C.accentBright, 1, 16) elseif why then Notice(Reason(why)) end
        elseif status == "empty" then
            self:OpenMenu(i)                          -- an empty plot asks which seed goes in it
            return
        end
        UI:Refresh()
    end

    -- ------------------------------------------------------------------------
    -- The seed menu: every herb at once (the open ones to pick, the next ones faded with their level)
    -- ------------------------------------------------------------------------
    local MENU_COLS = 9
    local function BuildMenu()
        local dim = CreateFrame("Frame", nil, s.frame)
        dim:SetAllPoints(s.frame)
        dim:SetFrameLevel(s.frame:GetFrameLevel() + 50)
        dim:EnableMouse(true)
        dim.fill = dim:CreateTexture(nil, "BACKGROUND")
        dim.fill:SetAllPoints(dim)
        dim.fill:SetColorTexture(0, 0, 0, 0.62)
        local card = CreateFrame("Frame", nil, dim)
        card:SetSize(W - 20, 330)
        card:SetPoint("CENTER", 0, 0)
        card.surface, card.outline = Kit.Rounded(card, 16, 0.07, 0.085, 0.095, 0.99, 0.14)
        card.title = Kit.Text(card, 16, C.text)
        card.title:SetPoint("TOPLEFT", 22, -18)
        card.advice = Kit.Text(card, 11, C.accent, "RIGHT")      -- what the Market needs, or what pays the most
        card.advice:SetPoint("TOPRIGHT", -22, -22)
        card.advice:SetWidth(W - 20 - 44 - 330)
        card.advice:SetWordWrap(false)
        local cellW = math.floor((W - 64) / MENU_COLS)
        dim.cells = {}
        for k, p in ipairs(D.PLANTS) do
            local b = CreateFrame("Button", nil, card)
            b:SetSize(cellW, 66)
            b:SetPoint("TOPLEFT", 22 + ((k - 1) % MENU_COLS) * cellW, -50 - math.floor((k - 1) / MENU_COLS) * 70)
            b.id = p[1]
            b.frame = CreateFrame("Frame", nil, b)
            b.frame:SetSize(44, 44)
            b.frame:SetPoint("TOP", 0, 0)
            b.fill, b.edge = Kit.Rounded(b.frame, 10, 1, 1, 1, 0, 0)
            b.icon = b.frame:CreateTexture(nil, "ARTWORK")
            b.icon:SetSize(34, 34)
            b.icon:SetPoint("CENTER")
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            Kit.RoundMask(b.frame, b.icon)
            b.star = b.frame:CreateTexture(nil, "OVERLAY")           -- the suggested seed: a small accent dot
            b.star:SetTexture(Kit.Icon("dot"))
            b.star:SetSize(12, 12)
            b.star:SetPoint("TOPRIGHT", 3, 3)
            b.star:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
            b.star:Hide()
            b.note = Kit.Text(b, 9, C.textMuted, "CENTER")
            b.note:SetPoint("TOP", 0, -48)
            b.note:SetWidth(cellW)
            b.note:SetWordWrap(false)
            b:SetScript("OnEnter", function(self) self.hover = true; s.hoverSeed = self.id; s:RefreshMenu() end)
            b:SetScript("OnLeave", function(self) self.hover = false; s.hoverSeed = nil; s:RefreshMenu() end)
            b:SetScript("OnClick", function(self) Kit.ClickSound(); s:ChooseInMenu(self.id) end)
            dim.cells[k] = b
        end
        card.detail = Kit.Text(card, 11, C.textSoft)
        card.detail:SetPoint("BOTTOMLEFT", 22, 62)              -- its own line, above the buttons
        card.detail:SetWidth(W - 20 - 44)
        card.detail:SetWordWrap(false)
        card.again = Kit.Button(card, 200, 32, "", function() s:PlantFromMenu(KH.db.selected) end)
        card.again:SetPoint("BOTTOMRIGHT", -22, 16)
        card.again:SetStyle("primary")
        card.close = Kit.Button(card, 90, 32, "", function() s:CloseMenu() end)
        card.close:SetPoint("RIGHT", card.again, "LEFT", -10, 0)
        -- how many plots get the seed: the one clicked and the next empty ones
        card.more = Kit.Button(card, 28, 28, "+", function() s:MenuQty(1) end)
        card.more:SetPoint("RIGHT", card.close, "LEFT", -16, 0)
        card.qty = Kit.Text(card, 14, C.text, "CENTER")
        card.qty:SetPoint("RIGHT", card.more, "LEFT", -4, 0)
        card.qty:SetWidth(30)
        card.less = Kit.Button(card, 28, 28, "−", function() s:MenuQty(-1) end)
        card.less:SetPoint("RIGHT", card.qty, "LEFT", -4, 0)
        card.all = Kit.Button(card, 64, 28, "", function() s:MenuQty(math.huge) end)     -- every empty plot
        card.all:SetPoint("RIGHT", card.less, "LEFT", -10, 0)
        card.qtyLabel = Kit.Text(card, 10, C.textMuted, "RIGHT")
        card.qtyLabel:SetPoint("RIGHT", card.all, "LEFT", -8, 0)
        dim.card = card
        dim:Hide()
        s.menu = dim
    end

    local function EmptyPlots()
        local n = 0
        for k = 1, KH.db.nplots do if KH.Farm:Status(k) == "empty" then n = n + 1 end end
        return n
    end

    function s:MenuQty(step)
        local qty = step == math.huge and EmptyPlots() or (self.menuQty or 1) + step
        self.menuQty = math.max(1, math.min(EmptyPlots(), qty))
        self:RefreshMenu()
    end

    function s:OpenMenu(i)
        if not self.menu then BuildMenu() end
        self.menuPlot = i
        self.menuQty = 1
        self.menu:Show()
        self:RefreshMenu()
    end

    function s:CloseMenu()
        if self.menu then self.menu:Hide() end
        self.menuPlot = nil
        UI:Refresh()
    end

    -- a click on a herb only chooses it; the amount starts again from 1 and the big button plants
    function s:ChooseInMenu(id)
        local plant = D.Plant(id)
        if not plant then return end
        if KH.db.level < plant.level then
            Notice(T("needLevel", plant.level))
            return
        end
        if KH.db.selected ~= id then self.menuQty = 1 end
        KH.db.selected = id
        self:RefreshMenu()
    end

    -- the seed chosen goes in the plot that was clicked, and stays chosen for "Plant all"
    function s:PlantFromMenu(id)
        local plant = D.Plant(id)
        if not plant then return end
        if KH.db.level < plant.level then
            Notice(T("needLevel", plant.level))
            return
        end
        KH.db.selected = id
        local ok, why = KH.Farm:Plant(self.menuPlot or 1, id)
        if not ok then Notice(Reason(why)) return self:RefreshMenu() end
        -- then the next empty plots, up to the amount asked (stops when the coins end)
        local planted = 1
        for k = 1, KH.db.nplots do
            if planted >= (self.menuQty or 1) then break end
            if KH.Farm:Status(k) == "empty" then
                local more, reason = KH.Farm:Plant(k, id)
                if not more then why = reason break end
                planted = planted + 1
            end
        end
        if planted > 1 then Notice(T("plantedN", planted)) end
        if why then Notice(Reason(why)) end
        self:CloseMenu()
    end

    function s:RefreshMenu()
        local menu = self.menu
        if not (menu and menu:IsShown()) then return end
        local db = KH.db
        menu.card.title:SetText(T("menuTitle"))
        local advised, why = KH.Advice:Seed()
        menu.card.advice:SetText(advised and T(why == "order" and "seedAdviceOrder" or "seedAdviceValue", D.Name(advised)) or "")
        for _, b in ipairs(menu.cells) do
            b.star:SetShown(b.id == advised)
            local p = D.Plant(b.id)
            local locked = db.level < p.level
            local chosen = db.selected == b.id
            SetIcon(b.icon, b.id)
            b.icon:SetAlpha(locked and 0.22 or 1)
            if b.icon.SetDesaturated then b.icon:SetDesaturated(locked) end
            b.edge:SetColor(C.accent[1], C.accent[2], C.accent[3], chosen and 0.9 or 0)
            b.fill:SetColor(1, 1, 1, (b.hover and not locked) and 0.10 or (chosen and 0.06 or 0))
            b.note:SetText(locked and T("seedLevel", p.level) or KH.Duration(p.grow))
            Kit.Paint(b.note, locked and C.textFaint or (chosen and C.accent or C.textMuted))
        end
        local id = self.hoverSeed or db.selected
        local p = D.Plant(id)
        if db.level < p.level then
            menu.card.detail:SetText(WHITE .. D.Name(id) .. "|r   " .. T("needLevel", p.level))
        else
            menu.card.detail:SetText(WHITE .. D.Name(id) .. "|r   " .. T("seedInfo", KH.Number(p.cost), KH.Duration(p.grow), D.Yield(p, db.level)))
        end
        local qty = self.menuQty or 1
        menu.card.qty:SetText(tostring(qty))
        menu.card.qtyLabel:SetText(T("menuPlots"))
        menu.card.less:SetEnabledState(qty > 1)
        menu.card.more:SetEnabledState(qty < EmptyPlots())
        menu.card.all:SetLabel(T("menuAll"))
        menu.card.all:SetEnabledState(qty < EmptyPlots())
        menu.card.again:SetLabel(qty > 1 and T("plantSeedN", qty, D.Name(db.selected)) or T("plantSeed", D.Name(db.selected)))
        menu.card.again:SetEnabledState(CanPlant(db.selected))
        menu.card.close:SetLabel(T("close"))
    end

    -- the first click on the x asks, the second (within a few seconds) pulls the plant up
    function s:Clear(i)
        local now = KH.Now()
        if not (self.asking and self.asking.i == i and now - self.asking.at <= 5) then
            self.asking = {i = i, at = now}
            Notice(T("clearAsk", D.Name(KH.db.plots[i] and KH.db.plots[i].plant or 0)))
            UI:Refresh()
            return
        end
        self.asking = nil
        local ok, what = KH.Farm:Clear(i)
        Notice(ok and T("cleared", D.Name(what)) or Reason(what))
        UI:Refresh()
    end

    -- the one button: harvest everything when something is ready, otherwise plant in every empty plot
    function s:Primary()
        local db = KH.db
        if self.mode == "harvest" then
            local total, why = 0, nil
            for i = 1, db.nplots do
                local n, reason = KH.Farm:Harvest(i)
                if n > 0 then Kit.Float(self.tiles[i].ring, "+" .. n, C.accentBright, 1, 16) end
                total = total + n
                why = why or reason
            end
            Notice(total > 0 and T("harvestedN", total) or (why and Reason(why)) or "")
        elseif self.mode == "plant" then
            local n, why = KH.Farm:PlantAll(db.selected)
            if n > 0 then Notice(T("plantedN", n)) elseif why then Notice(Reason(why)) end
        end
        UI:Refresh()
    end

    function s:RefreshSeeds()
        local db = KH.db
        local first = UI.seedFirst or SeedWindow(db.level)
        self.seedPrev:SetEnabledState(first > 1)
        self.seedNext:SetEnabledState(first < #D.PLANTS - STRIP + 1)
        local advised, why = KH.Advice:Seed()
        self.seedsLabel:SetText(T("seedsTitle") .. (advised and ("   |cff40d9c4" .. T(why == "order" and "seedAdviceOrder" or "seedAdviceValue", D.Name(advised)) .. "|r") or ""))
        for i, b in ipairs(self.seeds) do
            b.star:SetShown(D.PLANTS[first + i - 1][1] == advised)
            b.id = D.PLANTS[first + i - 1][1]
            local p = D.Plant(b.id)
            local locked = db.level < p.level
            local chosen = db.selected == b.id
            SetIcon(b.icon, b.id)
            b.icon:SetAlpha(locked and 0.22 or 1)
            if b.icon.SetDesaturated then b.icon:SetDesaturated(locked) end
            if chosen then
                b.fill:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.14)
                b.edge:SetColor(C.accent[1], C.accent[2], C.accent[3], 1)
            elseif b.hover and not locked then
                b.fill:SetColor(1, 1, 1, 0.07)
                b.edge:SetColor(1, 1, 1, 0.16)
            else
                b.fill:SetColor(1, 1, 1, 0)
                b.edge:SetColor(1, 1, 1, 0)
            end
            if locked then
                b.note:SetText(T("seedLevel", p.level))
                Kit.Paint(b.note, C.textFaint)
            else
                b.note:SetText(KH.Duration(p.grow))
                Kit.Paint(b.note, chosen and C.accent or C.textMuted)
            end
        end
        local id = self.hoverSeed or db.selected
        local p = D.Plant(id)
        if not p then
            self.detail:SetText("")
        elseif db.level < p.level then
            self.detail:SetText(WHITE .. D.Name(id) .. "|r   " .. T("needLevel", p.level))
        else
            self.detail:SetText(WHITE .. D.Name(id) .. "|r   " .. T("seedInfo", KH.Number(p.cost), KH.Duration(p.grow), D.Yield(p, db.level)))
        end
    end

    function s:Refresh()
        local db = KH.db
        local step = UI:Step()
        local selected = D.Plant(db.selected)
        local canPlant = CanPlant(db.selected)
        local ready, empty, soonest, hinted = 0, 0, nil, false
        local nextBuy = db.nplots + 1

        for i, t in ipairs(self.tiles) do
            local status, progress, left = KH.Farm:Status(i)
            local plot = db.plots[i]
            t.status, t.dim, t.live, t.hinted = status, false, false, false
            t.clear:SetShown(status == "growing")
            local asking = self.asking and self.asking.i == i and KH.Now() - self.asking.at <= 5
            t.clear:SetStyle(asking and "primary" or "quiet")
            t.lock:Hide()
            t.icon:Show()
            t.ring:Show()
            t.icon:SetAlpha(1)
            if t.icon.SetDesaturated then t.icon:SetDesaturated(false) end
            if status ~= "ready" then t.glow:SetAlpha(0) end
            t:SetShown(status ~= "locked" or i == nextBuy)       -- only the next plot is promised
            if status == "locked" then
                t.icon:Hide()
                t.ring:Hide()
                t.lock:Show()
                t.live = true
                t.lock:SetVertexColor(1, 1, 1, 0.55)
                t.title:SetText(T("newPlot"))
                Kit.Paint(t.title, C.text)
                t.note:SetText(T("plotFromGarden"))
                Kit.Paint(t.note, C.textMuted)
            elseif status == "empty" then
                empty = empty + 1
                t.live = canPlant
                SetIcon(t.icon, db.selected)
                t.icon:SetAlpha(0.28)
                if t.icon.SetDesaturated then t.icon:SetDesaturated(true) end
                t.ring:Set(0, C.accent, 0.08)
                t.title:SetText(T("plotEmpty"))
                Kit.Paint(t.title, C.textSoft)
                if canPlant or not selected then
                    t.note:SetText(T("plantSeed", D.Name(db.selected)))
                    Kit.Paint(t.note, C.accent)
                else
                    t.note:SetText(T("needCoins", KH.Number(selected.cost)))
                    Kit.Paint(t.note, C.textMuted)
                end
                if step == "plant" and not hinted then
                    t.hinted, hinted = true, true
                end
            else
                SetIcon(t.icon, plot.plant)
                t.title:SetText(D.Name(plot.plant))
                Kit.Paint(t.title, C.text)
                if status == "ready" then
                    ready = ready + 1
                    t.live = true
                    t.ring:Set(1, C.accentBright)
                    t.note:SetText(T("harvest"))
                    Kit.Paint(t.note, C.accent)
                else
                    if not soonest or left < soonest then soonest = left end
                    t.ring:Set(progress, C.accent)
                    t.note:SetText(T("timeLeft", KH.Duration(left)))
                    Kit.Paint(t.note, C.textSoft)
                end
            end
            PaintTile(t)
        end

        -- the two sentences
        local wait = KH.Duration(soonest or 0)
        if step == "plant" then
            self.head:SetText(T("tutPlantH")); self.sub:SetText(T("tutPlantS"))
        elseif step == "harvest" then
            self.head:SetText(T("tutHarvestH")); self.sub:SetText(T("tutHarvestS"))
        elseif step == "wait" then
            self.head:SetText(T("tutWaitH")); self.sub:SetText(T("tutWaitS", wait))
        elseif step == "sell" then
            self.head:SetText(T("tutSellH")); self.sub:SetText(T("tutSellS"))
        elseif ready > 0 then
            self.head:SetText(ready == 1 and T("headReadyOne") or T("headReadyMany", ready))
            self.sub:SetText(T("subReady"))
        elseif empty > 0 then
            self.head:SetText(T("headEmpty"))
            self.sub:SetText(T(canPlant and "subEmpty" or "subBroke", D.Name(db.selected)))
        else
            self.head:SetText(T("headGrowing"))
            self.sub:SetText(T("subGrowing", wait))
        end

        -- the one button
        if ready > 0 then
            self.mode = "harvest"
            self.primary:SetLabel(T("harvestAll"))
            self.primary:SetEnabledState(true)
        elseif empty > 0 then
            self.mode = "plant"
            self.primary:SetLabel(T("plantAll"))
            self.primary:SetEnabledState(canPlant)
        else
            self.mode = "wait"
            self.primary:SetLabel(T("comeBack"))
            self.primary:SetEnabledState(false)
        end

        self.seedsLabel:SetText(T("seedsTitle"))
        self:RefreshSeeds()
    end
    return s
end

-- ----------------------------------------------------------------------------
-- Barn
-- ----------------------------------------------------------------------------

P.builders.garden = BuildGarden
