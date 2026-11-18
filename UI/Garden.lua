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
            local ok, why = KH.Farm:Plant(i, db.selected)
            if not ok then Notice(Reason(why)) end
        end
        UI:Refresh()
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
        for i, b in ipairs(self.seeds) do
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
