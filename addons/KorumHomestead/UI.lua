--[[
    Korum Homestead - the window

    One quiet window, four words at the top: Garden, Barn, Orders, Settings. Every screen opens with one large sentence
    that says where things stand and a smaller one that says what to do next; there is one filled button per screen, the
    thing most likely wanted now. The coins and the Herbalism level stay in the header on every screen.

    The garden is the whole game in one gesture: click a plot. An empty plot plants the chosen seed, a ready one is
    harvested, the next locked one is bought. The first time, the sentences walk the player through plant, wait, harvest
    and sell, and then get out of the way.

    Everything is done with the mouse; the slash commands are only shortcuts. The window refreshes every second while it
    is open, so the rings move.
]]

local addonName, KH = ...
local UI = {}
KH.UI = UI
local Kit = KH.Kit
local C = Kit.COLORS
local D = KH.Data
local T = function(...) return KH.T(...) end

local WIDTH, HEIGHT = 720, 600
local WHITE = "|cfff5f5fa"

local function Reason(why)
    return T("why_" .. tostring(why))
end

-- a quiet line at the top right that fades by itself: what just happened, or why something could not be done
local function Notice(text)
    UI.msg = text or ""
    if UI.win then UI.win:Notice(text) end
end

-- every screen starts the same way: one large sentence, one smaller
local function Screen(win, place)
    local s = {frame = CreateFrame("Frame", nil, win.content), place = place}
    s.frame:SetAllPoints(win.content)
    s.frame:Hide()
    s.width, s.height = win.contentWidth, win.contentHeight
    -- a screen of a place opens with the drawing of the place, so the player sees where they are
    local left = 0
    if place then
        left = 70
        s.art = s.frame:CreateTexture(nil, "ARTWORK")
        s.art:SetSize(60, 60)
        s.art:SetPoint("TOPLEFT", 0, 2)
    end
    s.head = Kit.Text(s.frame, 22, C.text)
    s.head:SetPoint("TOPLEFT", left, 0)
    s.head:SetWidth(s.width - left)
    s.head:SetWordWrap(false)
    s.sub = Kit.Text(s.frame, 12, C.textSoft)
    s.sub:SetPoint("TOPLEFT", left, -32)
    s.sub:SetWidth(s.width - left)
    s.sub:SetWordWrap(false)
    return s
end

local function GoodTex(id)
    local item = KH.Village.ITEM[id]
    if item then return D.Icon(item) end
    return "Interface\\AddOns\\KorumHomestead\\Media\\Village\\" .. id
end

local function SetIcon(texture, id)
    texture:SetTexture(D.Icon(id))
end

-- ----------------------------------------------------------------------------
-- The first steps: plant, wait, harvest, sell. Told by what the homestead has done, so it never asks twice.
-- ----------------------------------------------------------------------------
function UI:Step()
    local db = KH.db
    db.tutorial = db.tutorial or {done = false}
    if db.tutorial.done then return nil end
    if db.stats.harvested == 0 then
        local growing = false
        for i = 1, db.nplots do
            local status = KH.Farm:Status(i)
            if status == "ready" then return "harvest" end
            if status == "growing" then growing = true end
        end
        return growing and "wait" or "plant"
    end
    if db.stats.earned == 0 then return "sell" end
    db.tutorial.done = true
    return nil
end

-- ----------------------------------------------------------------------------
-- Garden
-- ----------------------------------------------------------------------------
local TILE_H, TILE_GAP, COLS = 128, 10, 4
local RING_Y = -48

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
        s.tiles[i] = t
    end

    -- the seeds: one strip of herbs, the chosen one framed, the locked ones faded with their level
    local seedsY = -66 - 2 * TILE_H - TILE_GAP - 18
    s.seedsLabel = Kit.Text(s.frame, 11, C.textMuted)
    s.seedsLabel:SetPoint("TOPLEFT", 0, seedsY)
    s.seeds = {}
    local slotW = math.floor(W / #D.PLANTS)
    for i, p in ipairs(D.PLANTS) do
        local b = CreateFrame("Button", nil, s.frame)
        b:SetSize(slotW, 58)
        b:SetPoint("TOPLEFT", (i - 1) * slotW, seedsY - 18)
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
        for _, b in ipairs(self.seeds) do
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
local function BuildBarn(win)
    local s = Screen(win, "barn")
    local W = s.width
    s.rows = {}
    for i, p in ipairs(D.PLANTS) do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, 44)
        row.id = p[1]
        row.rule = Kit.Hairline(row, 0.05)
        row.rule:SetPoint("BOTTOMLEFT")
        row.rule:SetPoint("BOTTOMRIGHT")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("LEFT", 42, 0)
        row.wanted = Kit.Text(row, 10, C.accent)
        row.wanted:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
        row.sellAll = Kit.Button(row, 96, 24, "", function()
            local coins = KH.Farm:Sell(row.id)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sellAll:SetPoint("RIGHT", 0, 0)
        row.sell1 = Kit.Button(row, 80, 24, "", function()
            local coins = KH.Farm:Sell(row.id, 1)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sell1:SetPoint("RIGHT", row.sellAll, "LEFT", -8, 0)
        row.info = Kit.Text(row, 11, C.textSoft, "RIGHT")
        row.info:SetPoint("RIGHT", row.sell1, "LEFT", -18, 0)
        s.rows[i] = row
    end

    for _, good in ipairs(KH.Village.GOOD_ORDER) do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, 44)
        row.id, row.good = good, true
        row.rule = Kit.Hairline(row, 0.05)
        row.rule:SetPoint("BOTTOMLEFT")
        row.rule:SetPoint("BOTTOMRIGHT")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 0, 0)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("LEFT", 42, 0)
        row.wanted = Kit.Text(row, 10, C.accent)
        row.wanted:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
        row.sellAll = Kit.Button(row, 96, 24, "", function()
            local coins = KH.Village:SellGood(row.id)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sellAll:SetPoint("RIGHT", 0, 0)
        row.sell1 = Kit.Button(row, 80, 24, "", function()
            local coins = KH.Village:SellGood(row.id, 1)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sell1:SetPoint("RIGHT", row.sellAll, "LEFT", -8, 0)
        row.info = Kit.Text(row, 11, C.textSoft, "RIGHT")
        row.info:SetPoint("RIGHT", row.sell1, "LEFT", -18, 0)
        s.rows[#s.rows + 1] = row
    end

    s.stats = Kit.Text(s.frame, 10, C.textMuted)
    s.stats:SetPoint("BOTTOMLEFT", 0, 12)
    s.stats:SetWidth(W - 280)
    s.stats:SetWordWrap(false)
    -- the one button: sell everything; with an empty barn it shows the way back to the garden
    s.action = Kit.Button(s.frame, 260, 36, "", function() s:Action() end)
    s.action:SetPoint("BOTTOMRIGHT", 0, 0)

    function s:Action()
        if self.total > 0 then
            local coins = KH.Farm:SellAll()
            for _, good in ipairs(KH.Village.GOOD_ORDER) do coins = coins + KH.Village:SellGood(good) end
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        else
            UI:Show("garden")
        end
    end

    function s:Refresh()
        local db = KH.db
        local wanted = {}
        for _, o in ipairs(db.orders) do wanted[o.plant] = true end
        local shown, total, worth = 0, 0, 0
        local function Have(row)
            if row.good then return KH.Village:Good(row.id) end
            return db.crops[row.id] or 0
        end
        local herbs = 0
        for _, row in ipairs(self.rows) do
            if Have(row) > 0 then shown = shown + 1 end
        end
        local room = self.height - 66 - 52
        local rowH = math.max(22, math.min(44, math.floor(room / math.max(1, shown))))
        local fit = math.floor(room / rowH)
        local at = 0
        for _, row in ipairs(self.rows) do
            local n = Have(row)
            row:SetShown(n > 0 and at < fit)
            if n > 0 then
                local plant = row.good and KH.Village.GOODS[row.id] or D.Plant(row.id)
                total = total + n
                if not row.good then herbs = herbs + n end
                worth = worth + math.floor(n * plant.sell * KH.Village:PayBonus())
                row:SetHeight(rowH)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -66 - at * rowH)
                at = at + 1
                local side = math.min(30, rowH - 6)
                row.icon:SetSize(side, side)
                if row.good then
                    row.icon:SetTexture(GoodTex(row.id))
                    row.name:SetText(T("good_" .. row.id))
                    row.wanted:SetText(row.id == "ore" and T("forWorks") or "")
                else
                    SetIcon(row.icon, row.id)
                    row.name:SetText(D.Name(row.id))
                    row.wanted:SetText(wanted[row.id] and T("onOrder") or "")
                end
                row.info:SetText(WHITE .. "× " .. n .. "|r     " .. T("worth", KH.Number(math.floor(plant.sell * KH.Village:PayBonus()))))
                row.sell1:SetLabel(T("sell1"))
                row.sellAll:SetLabel(T("sellAll"))
            end
        end
        self.total = total
        if total > 0 then
            self.head:SetText(herbs == total and (total == 1 and T("barnHeadOne") or T("barnHead", total)) or T("barnHeadMixed", total))
            self.sub:SetText(T("barnSub", KH.Number(worth)))
            self.action:SetLabel(T("sellEverything", KH.Number(worth)))
            self.action:SetStyle("primary")
        else
            self.head:SetText(T("barnEmptyH"))
            self.sub:SetText(T("barnEmpty"))
            self.action:SetLabel(T("goGarden"))
            self.action:SetStyle("quiet")
        end
        self.stats:SetText(T("stored", KH.Village:Stored(), KH.Village:BarnCap()) .. "  ·  "
            .. T("stats", db.stats.harvested, db.stats.delivered, KH.Number(db.stats.earned)))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- Orders
-- ----------------------------------------------------------------------------
local ORDER_H, ORDER_GAP = 100, 10

local function BuildOrders(win)
    local s = Screen(win, "market")
    local W = s.width
    s.rows = {}
    for i = 1, D.ORDER_SLOTS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, ORDER_H)
        row:SetPoint("TOPLEFT", 0, -66 - (i - 1) * (ORDER_H + ORDER_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(46, 46)
        row.icon:SetPoint("LEFT", 22, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        Kit.RoundMask(row, row.icon)
        row.who = Kit.Text(row, 13, C.text)
        row.who:SetPoint("TOPLEFT", 88, -20)
        row.wants = Kit.Text(row, 12, C.textSoft)
        row.wants:SetPoint("TOPLEFT", 88, -40)
        row.bar = Kit.Bar(row, 180, 4)
        row.bar:SetPoint("TOPLEFT", 88, -68)
        row.have = Kit.Text(row, 10, C.textMuted)
        row.have:SetPoint("LEFT", row.bar, "RIGHT", 10, 0)
        row.deliver = Kit.Button(row, 124, 34, "", function() s:Deliver(i) end)
        row.deliver:SetPoint("RIGHT", -22, 0)
        row.coins = Kit.Text(row, 13, C.text, "RIGHT")
        row.coins:SetPoint("BOTTOMRIGHT", row.deliver, "LEFT", -22, 2)
        row.xp = Kit.Text(row, 10, C.textMuted, "RIGHT")
        row.xp:SetPoint("TOPRIGHT", row.deliver, "LEFT", -22, -4)
        s.rows[i] = row
    end

    function s:Deliver(i)
        local ok, result = KH.Orders:Deliver(i)
        if ok then
            Notice(T("delivered", KH.Number(result.paid or result.coins)))
            Kit.FadeIn(self.rows[i], 0.35)          -- a new order took its place
        else
            Notice(Reason(result))
        end
        UI:Refresh()
    end

    function s:Refresh()
        KH.Orders:Ensure()
        local db = KH.db
        local ready = 0
        for i, row in ipairs(self.rows) do
            local o = db.orders[i]
            local have = db.crops[o.plant] or 0
            local can = have >= o.qty
            if can then ready = ready + 1 end
            SetIcon(row.icon, o.plant)
            row.who:SetText(T("npc" .. o.npc))
            row.wants:SetText(T("orderWants", o.qty, D.Name(o.plant)))
            row.bar:Glide(have / o.qty, can and C.accentBright or C.accent)
            row.have:SetText(T("orderHave", math.min(have, o.qty), o.qty))
            row.coins:SetText(T("orderCoins", KH.Number(math.floor(o.coins * KH.Village:PayBonus()))))
            row.xp:SetText(T("orderXP", o.xp))
            row.deliver:SetLabel(can and T("deliver") or T("toGo", o.qty - have))
            row.deliver:SetStyle(can and "primary" or "quiet")
            row.deliver:SetEnabledState(can)
            row.outline:SetColor(can and C.accent[1] or 1, can and C.accent[2] or 1, can and C.accent[3] or 1, can and 0.5 or 0.06)
        end
        if ready > 0 then
            self.head:SetText(ready == 1 and T("ordersReadyOne") or T("ordersReadyMany", ready))
        else
            self.head:SetText(T("ordersWaitH"))
        end
        self.sub:SetText(T("ordersSub"))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- Settings
-- ----------------------------------------------------------------------------
local function BuildSettings(win)
    local s = Screen(win)
    local W = s.width
    s.langLabel = Kit.Text(s.frame, 11, C.textMuted)
    s.langLabel:SetPoint("TOPLEFT", 0, -72)
    s.lang = Kit.Segmented(s.frame, 380, {
        {value = "auto", label = T("langAuto")}, {value = "enUS", label = "English"}, {value = "ptBR", label = "Português"},
    }, function() return KH.db.lang end, function(v) KH.db.lang = v; UI:Relabel() end)
    s.lang:SetPoint("TOPLEFT", 0, -92)
    local y = -152
    s.alerts, y = Kit.Toggle(s.frame, y, W, function() return KH.db.alerts end, function(v) KH.db.alerts = v end)
    s.welcome, y = Kit.Toggle(s.frame, y, W, function() return KH.db.welcome end, function(v) KH.db.welcome = v end)
    s.minimap, y = Kit.Toggle(s.frame, y, W, function() return not KH.db.minimap.hide end,
        function(v) KH.db.minimap.hide = not v; UI:ApplyMinimap() end)
    s.bubble, y = Kit.Toggle(s.frame, y, W, function() return KH.db.bubble.show end,
        function(v) KH.db.bubble.show = v; UI:ApplyBubble() end)
    s.about = Kit.Text(s.frame, 10, C.textMuted)
    s.about:SetPoint("BOTTOMLEFT", 0, 12)

    function s:Refresh()
        self.head:SetText(T("settingsH"))
        self.sub:SetText(T("settingsS"))
        self.langLabel:SetText(T("language"))
        for _, spec in ipairs({{self.alerts, "optAlerts"}, {self.welcome, "optWelcome"}, {self.minimap, "optMinimap"}, {self.bubble, "optBubble"}}) do
            spec[1].label:SetText(T(spec[2]))
            spec[1].desc:SetText(T(spec[2] .. "D"))
            spec[1]:Sync()
        end
        self.lang.buttons[1].label:SetText(T("langAuto"))
        self.lang:Sync()
        self.about:SetText(T("about", KH.version))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The window
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- The village: the map the window opens on. Every building is a place to click.
-- ----------------------------------------------------------------------------
local V = KH.Village
local VDIR = "Interface\\AddOns\\KorumHomestead\\Media\\Village\\"
-- where each building stands on the map (its feet), in the map's own 664x332
-- the feet of each building, on the plazas of the map's art (map.tga is 1024x512, shown at 664x332)
local SPOT = {pond = {96, 147}, hall = {251, 147}, workshop = {409, 147}, mine = {567, 147},
    garden = {106, 265}, market = {255, 265}, inn = {410, 265}, barn = {562, 265}}
local VIEW_OF = {garden = "garden", hall = "hall", market = "orders", barn = "barn", mine = "mine", pond = "pond",
    workshop = "workshop", inn = "inn"}

-- where a click on a building takes: an empty lot is built in the Hall
local function Door(id)
    return KH.Village:Level(id) == 0 and "hall" or VIEW_OF[id]
end
local SPRITE = 92

local function Tier(level)
    return level <= 2 and 1 or (level <= 4 and 2 or 3)
end
UI.Tier = Tier

local function BuildingArt(id, level)
    level = level or V:Level(id)
    if level == 0 then return VDIR .. "lot" end
    return VDIR .. id .. Tier(level)
end

local function BuildingName(id)
    return T("b_" .. id)
end

local function BuildVillage(win)
    local s = Screen(win)
    local W = s.width
    local mapH = math.floor(W / 2)
    local map = CreateFrame("Frame", nil, s.frame)
    map:SetSize(W, mapH)
    map:SetPoint("TOPLEFT", 0, -66)
    map.art = map:CreateTexture(nil, "BACKGROUND")
    map.art:SetAllPoints(map)
    map.art:SetTexture(VDIR .. "map")
    s.map = map
    local scale = W / 664

    s.spots = {}
    for _, id in ipairs(V.BUILDINGS) do
        local b = CreateFrame("Button", nil, map)
        b.id = id
        b:SetSize(SPRITE, SPRITE + 36)
        b:SetPoint("TOPLEFT", map, "TOPLEFT", SPOT[id][1] * scale - SPRITE / 2, -(SPOT[id][2] * scale - SPRITE * 0.844))
        b.glow = b:CreateTexture(nil, "BACKGROUND")
        b.glow:SetTexture(Kit.Icon("glow"))
        b.glow:SetSize(SPRITE * 1.5, SPRITE * 1.5)
        b.glow:SetPoint("CENTER", b, "TOP", 0, -SPRITE * 0.6)
        b.glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
        if b.glow.SetBlendMode then b.glow:SetBlendMode("ADD") end
        b.glow:SetAlpha(0)
        b.art = b:CreateTexture(nil, "ARTWORK")
        b.art:SetSize(SPRITE, SPRITE)
        b.art:SetPoint("TOP", 0, 0)
        b.works = b:CreateTexture(nil, "OVERLAY")
        b.works:SetSize(SPRITE, SPRITE)
        b.works:SetPoint("TOP", 0, 0)
        b.works:SetTexture(VDIR .. "works")
        b.works:Hide()
        -- the plate under the building: its name and level, and what waits there
        b.plate = CreateFrame("Frame", nil, b)
        b.plate:SetSize(112, 34)
        b.plate:SetPoint("TOP", b, "TOP", 0, -(SPRITE - 6))
        b.plate.surface, b.plate.outline = Kit.Rounded(b.plate, 10, 0.03, 0.05, 0.06, 0.78, 0.08)
        b.name = Kit.Text(b.plate, 11, C.text, "CENTER")
        b.name:SetPoint("TOP", 0, -5)
        b.name:SetWidth(108)
        b.name:SetWordWrap(false)
        b.note = Kit.Text(b.plate, 9, C.textSoft, "CENTER")
        b.note:SetPoint("TOP", 0, -19)
        b.note:SetWidth(108)
        b.note:SetWordWrap(false)
        b:SetScript("OnEnter", function(self) self.hover = true; s.hover = self.id; s:Paint() end)
        b:SetScript("OnLeave", function(self) self.hover = false; s.hover = nil; s:Paint() end)
        b:SetScript("OnClick", function(self) Kit.ClickSound(); UI:Show(Door(self.id)) end)
        s.spots[id] = b
    end

    s.primary = Kit.Button(s.frame, 220, 36, "", function() s:Primary() end)
    s.primary:SetPoint("BOTTOMRIGHT", 0, 0)
    s.primary:SetStyle("primary")
    s.detail = Kit.Text(s.frame, 11, C.textSoft)
    s.detail:SetPoint("BOTTOMLEFT", 0, 12)
    s.detail:SetWidth(W - 240)
    s.detail:SetWordWrap(false)

    -- what waits for the player breathes softly; the building under the mouse lights up
    s.clock = 0
    s.frame:SetScript("OnUpdate", function(_, elapsed)
        s.clock = s.clock + (tonumber(elapsed) or 0)
        local wave = 0.5 + 0.5 * math.sin(s.clock * 3)
        for _, b in pairs(s.spots) do
            if b.hover then
                b.glow:SetAlpha(0.42)
            elseif b.calls then
                b.glow:SetAlpha(0.12 + 0.22 * wave)
            else
                b.glow:SetAlpha(0)
            end
        end
    end)

    function s:Paint()
        for _, b in pairs(self.spots) do
            b.plate.outline:SetColor(b.hover and C.accent[1] or 1, b.hover and C.accent[2] or 1, b.hover and C.accent[3] or 1,
                b.hover and 0.8 or (b.calls and 0.22 or 0.08))
        end
        if self.hover then
            self.detail:SetText(WHITE .. BuildingName(self.hover) .. "|r   " .. T("b_" .. self.hover .. "D"))
        else
            self.detail:SetText(self.idle or "")
        end
    end

    function s:Primary()
        if self.mode == "harvest" then
            local n, why = KH.Farm:HarvestAll()
            if n > 0 then
                Kit.Float(self.spots.garden.art, "+" .. n, C.accentBright, 1, 16)
                Notice(T("harvestedN", n))
            elseif why then
                Notice(Reason(why))
            end
            UI:Refresh()
        else
            UI:Show(self.mode or "garden")
        end
    end

    function s:Refresh()
        local db = KH.db
        local step = UI:Step()
        local ready, growing, empty, soonest = 0, 0, 0, nil
        for i = 1, db.nplots do
            local status, _, left = KH.Farm:Status(i)
            if status == "ready" then ready = ready + 1
            elseif status == "growing" then
                growing = growing + 1
                if not soonest or left < soonest then soonest = left end
            else empty = empty + 1 end
        end
        local deliverable = 0
        for i = 1, D.ORDER_SLOTS do
            if KH.Orders:CanDeliver(i) then deliverable = deliverable + 1 end
        end
        local work, left = V:Work()
        local affordable = V:Affordable()
        local stored, cap = V:Stored(), V:BarnCap()

        for _, id in ipairs(V.BUILDINGS) do
            local b = self.spots[id]
            b.art:SetTexture(BuildingArt(id))
            b.works:SetShown(work ~= nil and work.id == id)
            local level = V:Level(id)
            b.name:SetText(level == 0 and BuildingName(id) or T("nameLevel", BuildingName(id), level))
            local note, calls = "", false
            if work and work.id == id then
                note = T("building", KH.Duration(left))
            elseif level == 0 then
                local ok, why, n = V:CanUpgrade(id)
                if ok then note, calls = T("canBuild"), not step
                elseif why == "hall" then note = T("short_hall", n)
                else note = T("emptyLot") end
            elseif V.MAKES[id] then
                local good = V.MAKES[id]
                local have = V:Good(good)
                note, calls = T("goodStored", have, cap, T("good_" .. good)), have >= cap
            elseif id == "workshop" then
                local jobs = KH.Workshop:Jobs()
                if #jobs > 0 then note = T("shopPlate", #jobs, KH.Duration(jobs[1].left)) else note = T("shopIdle") end
            elseif id == "inn" then
                local back, away = KH.Inn:BackCount(), KH.Inn:AwayCount()
                if back > 0 then note, calls = T(back == 1 and "backOne" or "backMany", back), true
                elseif away > 0 then note = T("awayMany", away)
                else note = T("followersIdle", KH.Inn:Count()) end
            elseif id == "garden" then
                if ready > 0 then note, calls = T(ready == 1 and "readyOne" or "readyMany", ready), true
                elseif empty > 0 then note, calls = T(empty == 1 and "emptyOne" or "emptyMany", empty), step == "plant"
                else note = T("timeLeft", KH.Duration(soonest or 0)) end
            elseif id == "barn" then
                note, calls = T("stored", stored, cap), step == "sell" or stored >= cap
            elseif id == "market" then
                if deliverable > 0 then note, calls = T(deliverable == 1 and "deliverOne" or "deliverMany", deliverable), true
                else note = T("ordersWaiting", D.ORDER_SLOTS) end
            elseif id == "hall" then
                if affordable and not step then note, calls = T("canUpgrade"), true else note = T("buildHere") end
            end
            b.calls = calls
            b.note:SetText(note)
            Kit.Paint(b.note, calls and C.accent or C.textSoft)
        end

        -- the two sentences, and the one button
        self.mode = "garden"
        local label = T("openGarden")
        if step == "plant" then
            self.head:SetText(T("vilPlantH")); self.sub:SetText(T("vilPlantS"))
        elseif step == "wait" then
            self.head:SetText(T("tutWaitH")); self.sub:SetText(T("tutWaitS", KH.Duration(soonest or 0)))
        elseif step == "harvest" then
            self.head:SetText(T("tutHarvestH")); self.sub:SetText(T("vilHarvestS"))
            self.mode, label = "harvest", T("harvestAll")
        elseif step == "sell" then
            self.head:SetText(T("tutSellH")); self.sub:SetText(T("vilSellS"))
            self.mode, label = "barn", T("openBarn")
        elseif ready > 0 then
            self.head:SetText(ready == 1 and T("headReadyOne") or T("headReadyMany", ready))
            self.sub:SetText(T("vilReadyS"))
            self.mode, label = "harvest", T("harvestAll")
        elseif deliverable > 0 then
            self.head:SetText(T(deliverable == 1 and "vilDeliverOneH" or "vilDeliverH", deliverable))
            self.sub:SetText(T("vilDeliverS"))
            self.mode, label = "orders", T("openMarket")
        elseif affordable then
            self.head:SetText(T(V:Level(affordable) == 0 and "vilBuildH" or "vilUpgradeH", BuildingName(affordable)))
            self.sub:SetText(T("vilUpgradeS"))
            self.mode, label = "hall", T("openHall")
        elseif empty > 0 then
            self.head:SetText(T("headEmpty"))
            self.sub:SetText(T("vilEmptyS"))
        else
            self.head:SetText(T("vilQuietH"))
            self.sub:SetText(T("subGrowing", KH.Duration(soonest or 0)))
        end
        self.primary:SetLabel(label)
        self.primary:SetEnabledState(true)

        if work then
            self.idle = T("workLine", BuildingName(work.id), V:Level(work.id) + 1, KH.Duration(left))
        else
            self.idle = T("vilTip")
        end
        self:Paint()
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The Hall: where every building of the village is improved, one work at a time
-- ----------------------------------------------------------------------------
local HALL_ROW, HALL_GAP = 46, 4

local function Effect(id, level)
    if V.MAKES[id] then return level == 0 and T("emptyLot") or T("fx_" .. id, V:Rate(id, level)) end
    if id == "workshop" or id == "inn" then return level == 0 and T("emptyLot") or T("fx_" .. id, level) end
    if id == "garden" then return T("fx_garden", math.min(D.MAX_PLOTS, 1 + level)) end
    if id == "barn" then return T("fx_barn", V:BarnCap(level)) end
    if id == "market" then return T("fx_market", math.floor((V:PayBonus(level) - 1) * 100 + 0.5)) end
    return T("fx_hall", level)
end

-- The Mine and the Pond: they work by themselves, so this screen only says what they make and where it goes
local function BuildSource(id)
    return function(win)
        local s = Screen(win, id)
        s.rate = Kit.Text(s.frame, 18, C.text)
        s.rate:SetPoint("TOPLEFT", 0, -90)
        s.have = Kit.Text(s.frame, 12, C.textSoft)
        s.have:SetPoint("TOPLEFT", 0, -124)
        s.action = Kit.Button(s.frame, 220, 36, T("openBarn"), function() UI:Show("barn") end)
        s.action:SetPoint("BOTTOMRIGHT", 0, 0)
        s.action:SetStyle("primary")
        function s:Refresh()
            local level = V:Level(id)
            self.head:SetText(BuildingName(id))
            self.sub:SetText(T("b_" .. id .. "D"))
            self.rate:SetText(level > 0 and T("fx_" .. id, V:Rate(id)) or "")
            self.have:SetText(level > 0 and T("stored", V:Stored(), V:BarnCap()) or "")
            self.action:SetShown(level > 0)
        end
        return s
    end
end

local function BuildHall(win)
    local s = Screen(win, "hall")
    local W = s.width
    s.rows = {}
    for i, id in ipairs(V.BUILDINGS) do
        local row = CreateFrame("Frame", nil, s.frame)
        row.id = id
        row:SetSize(W, HALL_ROW)
        row:SetPoint("TOPLEFT", 0, -66 - (i - 1) * (HALL_ROW + HALL_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.art = row:CreateTexture(nil, "ARTWORK")
        row.art:SetSize(38, 38)
        row.art:SetPoint("LEFT", 10, 2)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 58, -4)
        row.now = Kit.Text(row, 10, C.textSoft)
        row.now:SetPoint("TOPLEFT", 58, -19)
        row.now:SetWidth(W - 58 - 196)
        row.now:SetWordWrap(false)
        row.cost = Kit.Text(row, 10, C.textMuted)
        row.cost:SetPoint("TOPLEFT", 58, -32)
        row.cost:SetWidth(W - 58 - 196)
        row.cost:SetWordWrap(false)
        row.bar = Kit.Bar(row, W - 58 - 206, 3)
        row.bar:SetPoint("TOPLEFT", 58, -38)
        row.bar:Hide()
        row.button = Kit.Button(row, 168, 28, "", function()
            local ok, why = V:Upgrade(row.id)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        row.button:SetPoint("RIGHT", -16, 0)
        s.rows[i] = row
    end

    function s:Refresh()
        local db = KH.db
        local work, left, progress = V:Work()
        if work then
            self.head:SetText(T("hallWorkH", BuildingName(work.id), V:Level(work.id) + 1))
            self.sub:SetText(T("hallWorkS", KH.Duration(left)))
        else
            self.head:SetText(T("hallH"))
            self.sub:SetText(T("hallS"))
        end
        local offered = false
        for _, row in ipairs(self.rows) do
            local id = row.id
            local level = V:Level(id)
            local nxt = V:Next(id)
            local working = work ~= nil and work.id == id
            row.art:SetTexture(BuildingArt(id))
            row.name:SetText(level == 0 and T("notBuilt", BuildingName(id)) or T("nameLevelLong", BuildingName(id), level))
            row.bar:SetShown(working)
            row.cost:SetShown(not working)
            row.outline:SetColor(working and C.accent[1] or 1, working and C.accent[2] or 1, working and C.accent[3] or 1, working and 0.55 or 0.06)
            if not nxt then
                row.now:SetText(Effect(id, level))
                row.cost:SetText(T("why_maxLevel"))
                row.button:SetLabel(T("maxLevel"))
                row.button:SetStyle("quiet")
                row.button:SetEnabledState(false)
            else
                if level == 0 then
                    row.now:SetText("|cff40d9c4" .. Effect(id, nxt.level) .. "|r")
                else
                    row.now:SetText(Effect(id, level) .. "   |cff40d9c4>  " .. Effect(id, nxt.level) .. "|r")
                end
                if nxt.ore > 0 then
                    row.cost:SetText(T("upgradeCostOre", KH.Number(nxt.cost), nxt.ore, KH.Duration(nxt.time)))
                else
                    row.cost:SetText(T("upgradeCost", KH.Number(nxt.cost), KH.Duration(nxt.time)))
                end
                if working then
                    row.bar:Set(progress)
                    row.button:SetLabel(T("building", KH.Duration(left)))
                    row.button:SetStyle("quiet")
                    row.button:SetEnabledState(false)
                else
                    local ok, why, n = V:CanUpgrade(id)
                    if ok then
                        row.button:SetLabel(level == 0 and T("build") or T("upgradeTo", nxt.level))
                        row.button:SetStyle(offered and "quiet" or "primary")
                        offered = true
                        row.button:SetEnabledState(true)
                    else
                        row.button:SetLabel(T("short_" .. why, why == "coins" and KH.Number(n) or n))
                        row.button:SetStyle("quiet")
                        row.button:SetEnabledState(false)
                    end
                end
            end
        end
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The guide: how the homestead works, in four short pages. The numbers come from the rules themselves (Data, Village),
-- so the guide cannot say something the game does not do.
-- ----------------------------------------------------------------------------
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
        row.text:SetWordWrap(false)
        p.steps[i] = row
    end
    p.note = Kit.Text(p, 11, C.textMuted)
    p.note:SetPoint("TOPLEFT", 0, -4 * 62 - 14)
    p.note:SetWidth(W)
    p.note2 = Kit.Text(p, 11, C.textMuted)
    p.note2:SetPoint("TOPLEFT", 0, -4 * 62 - 36)
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
    for i, plant in ipairs(D.PLANTS) do
        local row = CreateFrame("Frame", nil, p)
        row.id = plant[1]
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
        for _, row in ipairs(h.rows) do
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
local RECIPE_H, RECIPE_GAP, QUEUE_ROWS = 56, 6, 5
local RECIPE_TOP = 98                          -- under the line of trades
UI.trade = "alchemy"

local function BuildWorkshop(win)
    local s = Screen(win, "workshop")
    local W = s.width
    local Wk = KH.Workshop
    s.rows = {}
    local options = {}
    for _, trade in ipairs(Wk.TRADES) do options[#options + 1] = {value = trade, label = T("trade_" .. trade)} end
    s.trades = Kit.Segmented(s.frame, 360, options, function() return UI.trade end, function(v) UI.trade = v; UI:Refresh() end)
    s.trades:SetPoint("TOPLEFT", 0, -58)
    s.tradeHint = Kit.Text(s.frame, 11, C.textSoft)
    s.tradeHint:SetPoint("LEFT", s.trades, "RIGHT", 16, 0)
    for i = 1, 3 do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, RECIPE_H)
        row:SetPoint("TOPLEFT", 0, -RECIPE_TOP - (i - 1) * (RECIPE_H + RECIPE_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(40, 40)
        row.icon:SetPoint("LEFT", 14, 0)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("TOPLEFT", 68, -9)
        row.needs = Kit.Text(row, 10, C.textSoft)
        row.needs:SetPoint("TOPLEFT", 68, -29)
        row.needs:SetWidth(W - 68 - 190)
        row.needs:SetWordWrap(false)
        row.button = Kit.Button(row, 156, 32, "", function()
            local ok, why, n = Wk:Craft(row.id)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        row.button:SetPoint("RIGHT", -14, 0)
        s.rows[i] = row
    end
    s.queueHead = Kit.Text(s.frame, 11, C.textMuted)
    s.queueHead:SetPoint("TOPLEFT", 0, -RECIPE_TOP - 3 * (RECIPE_H + RECIPE_GAP) - 4)
    s.queue = {}
    for i = 1, QUEUE_ROWS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, 26)
        row:SetPoint("TOPLEFT", 0, -RECIPE_TOP - 3 * (RECIPE_H + RECIPE_GAP) - 24 - (i - 1) * 28)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", 0, 0)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("LEFT", 32, 0)
        row.left = Kit.Text(row, 11, C.textSoft, "RIGHT")
        row.left:SetPoint("RIGHT", 0, 0)
        row.bar = Kit.Bar(row, 220, 3)
        row.bar:SetPoint("LEFT", 190, 0)
        s.queue[i] = row
    end

    function s:Refresh()
        local db = KH.db
        local level = V:Level("workshop")
        local jobs = Wk:Jobs()
        if level == 0 then
            self.head:SetText(T("shopNoH")); self.sub:SetText(T("shopNoS"))
        elseif #jobs > 0 then
            self.head:SetText(T("shopBusyH", #jobs)); self.sub:SetText(T("shopBusyS", Wk:Slots()))
        else
            self.head:SetText(T("shopH")); self.sub:SetText(T("shopS", Wk:Slots()))
        end
        local first = true
        self.trades:Sync()
        self.tradeHint:SetText(T("tradeHint_" .. UI.trade))
        local recipes = Wk.OfTrade(UI.trade)
        for i, row in ipairs(self.rows) do
            local r = recipes[i]
            row:SetShown(r ~= nil)
            if not r then break end
            row.id = r.id
            row.icon:SetTexture(GoodTex(r.id))
            local unlocked = level >= r.level
            row.name:SetText(T("good_" .. r.id) .. "   |cff757a87" .. KH.Duration(r.time) .. "  ·  " .. T("worth", KH.Number(V.GOODS[r.id].sell)) .. "|r")
            local parts = {}
            for _, input in ipairs(r.inputs) do
                local have = Wk.Stock(input[1])
                local label = type(input[1]) == "string" and T("good_" .. input[1]) or D.Name(input[1])
                parts[#parts + 1] = string.format("|cff%s%d|r/%d × %s", have >= input[2] and "59d973" or "ff6a5c", have, input[2], label)
            end
            row.needs:SetText(unlocked and table.concat(parts, "   ") or T("short_recipe", r.level))
            row.icon:SetAlpha(unlocked and 1 or 0.3)
            local ok, why, n = Wk:CanCraft(row.id)
            if ok then
                row.button:SetLabel(T("craft"))
                row.button:SetStyle(first and "primary" or "quiet")
                first = false
            else
                row.button:SetLabel(T("short_" .. why, n))
                row.button:SetStyle("quiet")
            end
            row.button:SetEnabledState(ok)
            row.outline:SetColor(1, 1, 1, ok and 0.12 or 0.05)
        end
        self.queueHead:SetText(level > 0 and T("queueHead", #jobs, Wk:Slots()) or "")
        for i, row in ipairs(self.queue) do
            local job = jobs[i]
            row:SetShown(job ~= nil)
            if job then
                row.icon:SetTexture(GoodTex(job.recipe))
                local more = (i == #self.queue and #jobs > i) and ("   |cff757a87+" .. (#jobs - i) .. "|r") or ""
                row.name:SetText(T("good_" .. job.recipe) .. more)
                row.left:SetText(KH.Duration(job.left))
                row.bar:SetShown(i == 1)
                if i == 1 then row.bar:Set(job.progress) end
            end
        end
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The Inn: the followers and their missions
-- ----------------------------------------------------------------------------
local FOLLOWER_H, FOLLOWER_GAP = 52, 6

local function BuildInn(win)
    local s = Screen(win, "inn")
    local W = s.width
    local In = KH.Inn
    s.rows = {}
    for i = 1, In.MAX do
        local row = CreateFrame("Frame", nil, s.frame)
        row.index = i
        row:SetSize(W, FOLLOWER_H)
        row:SetPoint("TOPLEFT", 0, -66 - (i - 1) * (FOLLOWER_H + FOLLOWER_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.disc = row:CreateTexture(nil, "ARTWORK")          -- the portrait of the follower
        row.disc:SetTexture(VDIR .. "follower" .. i)
        row.disc:SetSize(42, 42)
        row.disc:SetPoint("LEFT", 8, 0)
        row.initial = row:CreateFontString(nil, "OVERLAY")    -- (kept empty: the portrait says who it is)
        row.initial:SetFont(Kit.Font(), 1, "")
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("TOPLEFT", 58, -9)
        row.state = Kit.Text(row, 10, C.textSoft)
        row.state:SetPoint("TOPLEFT", 58, -29)
        row.state:SetWidth(W - 58 - 330)
        row.state:SetWordWrap(false)
        row.bar = Kit.Bar(row, 200, 3)
        row.bar:SetPoint("TOPLEFT", 58, -40)
        row.missions = {}
        for k, m in ipairs(In.MISSIONS) do
            local b = Kit.Button(row, 100, 30, "", function()
                local ok, why, n = In:Start(row.index, m.id)
                if not ok then Notice(Reason(why)) end
                UI:Refresh()
            end)
            b:SetPoint("RIGHT", -10 - (#In.MISSIONS - k) * 106, 0)
            row.missions[k] = b
        end
        row.collect = Kit.Button(row, 200, 30, "", function()
            local coins, ore = In:Collect(row.index)
            if coins > 0 then
                Notice(ore > 0 and T("collected2", KH.Number(coins), ore) or T("collected", KH.Number(coins)))
            end
            UI:Refresh()
        end)
        row.collect:SetPoint("RIGHT", -10, 0)
        row.collect:SetStyle("primary")
        s.rows[i] = row
    end
    s.action = Kit.Button(s.frame, 220, 36, "", function()
        local coins, ore = In:CollectAll()
        if coins > 0 then Notice(ore > 0 and T("collected2", KH.Number(coins), ore) or T("collected", KH.Number(coins))) end
        UI:Refresh()
    end)
    s.action:SetPoint("BOTTOMRIGHT", 0, 0)
    s.action:SetStyle("primary")
    s.note = Kit.Text(s.frame, 11, C.textSoft)
    s.note:SetPoint("BOTTOMLEFT", 0, 12)
    s.note:SetWidth(W - 240)
    s.note:SetWordWrap(false)

    function s:Refresh()
        local level = V:Level("inn")
        local count = In:Count()
        local back = In:BackCount()
        if level == 0 then
            self.head:SetText(T("innNoH")); self.sub:SetText(T("innNoS"))
        elseif back > 0 then
            self.head:SetText(T(back == 1 and "innBackOneH" or "innBackManyH", back)); self.sub:SetText(T("innBackS"))
        elseif In:AwayCount() > 0 then
            self.head:SetText(T("innAwayH", In:AwayCount())); self.sub:SetText(T("innAwayS"))
        else
            self.head:SetText(T("innH")); self.sub:SetText(T("innS"))
        end
        for _, row in ipairs(self.rows) do
            local i = row.index
            local status, left, progress = In:Status(i)
            row:SetShown(level > 0)
            row.name:SetText(In.NAMES[i])
            row.bar:Hide()
            row.collect:Hide()
            for _, b in ipairs(row.missions) do b:Hide() end
            local dim = status == "locked"
            row.disc:SetAlpha(dim and 0.35 or 1)
            if row.disc.SetDesaturated then row.disc:SetDesaturated(dim) end
            row.outline:SetColor(status == "back" and C.accent[1] or 1, status == "back" and C.accent[2] or 1, status == "back" and C.accent[3] or 1,
                status == "back" and 0.55 or 0.06)
            if status == "locked" then
                row.name:SetText(In.NAMES[i] .. "  |cff757a87" .. T("locked") .. "|r")
                row.state:SetText(T("innLocked", i))
            else
                row.name:SetText(T("nameLevelLong", In.NAMES[i], In:Level(i)))
                if status == "idle" then
                    row.state:SetText(T("idleText", In:Follower(i).done))
                    for k, m in ipairs(In.MISSIONS) do
                        local b = row.missions[k]
                        b:Show()
                        b:SetLabel(T("missionBtn", KH.Duration(m.time), m.fish))
                        b:SetEnabledState(V:Good("fish") >= m.fish)
                    end
                elseif status == "away" then
                    local m = In.Mission(In:Follower(i).mission.kind)
                    row.state:SetText(T("awayText", KH.Duration(left)) .. "   |cff757a87" .. T("missionPays", KH.Number(In:Pay(i, m))) .. "|r")
                    row.bar:SetShown(true)
                    row.bar:Set(progress)
                else
                    local m = In.Mission(In:Follower(i).mission.kind)
                    row.state:SetText("|cff59d973" .. T("backText") .. "|r")
                    row.collect:Show()
                    row.collect:SetLabel(T("collectOne", KH.Number(In:Pay(i, m))))
                end
            end
        end
        self.action:SetLabel(T("collectAll"))
        self.action:SetEnabledState(back > 0)
        self.action:SetStyle(back > 0 and "primary" or "quiet")
        self.note:SetText(level > 0 and T("fishHave", V:Good("fish")) or "")
    end
    return s
end

local BUILDERS = {village = BuildVillage, hall = BuildHall, guide = BuildGuide, workshop = BuildWorkshop, inn = BuildInn, garden = BuildGarden, barn = BuildBarn, mine = BuildSource("mine"), pond = BuildSource("pond"), orders = BuildOrders,
    settings = BuildSettings}
-- the name of each screen in the path at the top ("Village / Garden")
local CRUMB = {workshop = "b_workshop", inn = "b_inn", guide = "guide", hall = "b_hall", garden = "b_garden", barn = "b_barn", mine = "b_mine", pond = "b_pond", orders = "b_market", settings = "tabSettings"}

local function Tip(owner, title, lines)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(title, 1, 1, 1)
    for _, line in ipairs(lines) do GameTooltip:AddLine(line, 0.66, 0.68, 0.72, true) end
    GameTooltip:Show()
end

function UI:Create()
    if self.win then return end
    local win = Kit.Window({
        name = "KorumHomesteadFrame", width = WIDTH, height = HEIGHT,
        title = "|cff40d9c4Korum|r Homestead", logo = Kit.LOGO, tabs = {},
        onSelect = function(id) UI:OnSelect(id) end,
        closeTip = function() return T("close") end,
    })
    self.win = win
    self.frame = win.frame
    self.screens = {}

    -- the header keeps the two numbers of the game in sight on every screen: the coins and the level
    local h = win.header
    self.coinText = Kit.Text(h, 14, C.text, "RIGHT")
    self.coinText:SetPoint("RIGHT", win.close, "LEFT", -16, 0)
    self.coinDot = h:CreateTexture(nil, "ARTWORK")
    self.coinDot:SetTexture(Kit.Icon("dot"))
    self.coinDot:SetSize(12, 12)
    self.coinDot:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    self.coinDot:SetPoint("RIGHT", self.coinText, "LEFT", -6, 0)
    local coinHit = CreateFrame("Frame", nil, h)
    coinHit:SetPoint("TOPLEFT", self.coinDot, "TOPLEFT", -6, 12)
    coinHit:SetPoint("BOTTOMRIGHT", self.coinText, "BOTTOMRIGHT", 4, -10)
    coinHit:EnableMouse(true)
    coinHit:SetScript("OnEnter", function(frame) Tip(frame, T("coinsTip"), {T("coinsHow")}) end)
    coinHit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local lv = CreateFrame("Frame", nil, h)
    lv:SetSize(132, 30)
    lv:SetPoint("RIGHT", self.coinDot, "LEFT", -24, 0)
    lv.label = Kit.Text(lv, 11, C.textSoft, "RIGHT")
    lv.label:SetPoint("TOPRIGHT", 0, -3)
    lv.bar = Kit.Bar(lv, 132, 3)
    lv.bar:SetPoint("BOTTOMRIGHT", 0, 6)
    lv:EnableMouse(true)
    lv:SetScript("OnEnter", function(frame)
        local db = KH.db
        local first = db.level >= D.MAX_LEVEL and T("maxLevel") or T("xpTip", db.xp, D.XPToNext(db.level))
        Tip(frame, T("herbalism", db.level), {first, T("xpHow")})
    end)
    lv:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.levelBox = lv

    -- the gear: the settings are a screen like the others
    local gear = CreateFrame("Button", nil, h)
    gear:SetSize(26, 26)
    gear:SetPoint("RIGHT", lv, "LEFT", -18, -4)
    gear.bg = gear:CreateTexture(nil, "BACKGROUND")
    gear.bg:SetAllPoints()
    gear.bg:SetTexture(Kit.Icon("dot"))
    gear.bg:SetVertexColor(1, 1, 1, 0.06)
    gear.icon = gear:CreateTexture(nil, "ARTWORK")
    gear.icon:SetSize(14, 14)
    gear.icon:SetPoint("CENTER")
    gear.icon:SetTexture(Kit.Icon("settings"))
    gear.icon:SetVertexColor(C.textSoft[1], C.textSoft[2], C.textSoft[3])
    gear:SetScript("OnEnter", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.16); Tip(frame, T("tabSettings"), {}) end)
    gear:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    gear:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("settings") end)
    self.gear = gear

    -- the question mark: the guide
    local help = CreateFrame("Button", nil, h)
    help:SetSize(26, 26)
    help:SetPoint("RIGHT", gear, "LEFT", -8, 0)
    help.bg = help:CreateTexture(nil, "BACKGROUND")
    help.bg:SetAllPoints()
    help.bg:SetTexture(Kit.Icon("dot"))
    help.bg:SetVertexColor(1, 1, 1, 0.06)
    help.mark = Kit.Text(help, 13, C.textSoft, "CENTER")
    help.mark:SetPoint("CENTER", 0, 0)
    help.mark:SetText("?")
    help:SetScript("OnEnter", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.16); Tip(frame, T("guide"), {T("guideS")}) end)
    help:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    help:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("guide") end)
    self.help = help

    -- the path, where the tabs were: "Village" always takes you back to the map; after it, where you are
    local row = win.tabRow
    local home = CreateFrame("Button", nil, row)
    home:SetSize(60, Kit.TABS_H)
    home:SetPoint("LEFT", 0, 0)
    home.label = Kit.Text(home, 13, C.text)
    home.label:SetPoint("LEFT", 0, 0)
    home.line = home:CreateTexture(nil, "ARTWORK")
    home.line:SetHeight(2)
    home.line:SetPoint("BOTTOMLEFT", home, "BOTTOMLEFT", 0, 0)
    home.line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    home:SetScript("OnEnter", function(frame) frame.hover = true; UI:PaintPath() end)
    home:SetScript("OnLeave", function(frame) frame.hover = false; UI:PaintPath() end)
    home:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("village") end)
    self.home = home
    self.here = Kit.Text(row, 13, C.text)
    self.here:SetPoint("LEFT", home, "RIGHT", 0, 0)
end

function UI:PaintPath()
    local home = self.home
    if not home then return end
    local inVillage = self.view == "village" or self.view == nil
    home.label:SetText(T("village"))
    local w = Kit.TextWidth(home.label, T("village"))
    home:SetWidth(w + 4)
    home.line:SetWidth(w)
    home.line:SetShown(inVillage)
    Kit.Paint(home.label, (inVillage or home.hover) and C.text or C.textSoft)
    if inVillage then
        self.here:SetText("")
    else
        self.here:SetText("|cff757a87  /  |r" .. T(CRUMB[self.view] or "village"))
    end
end

-- the coins count up or down to the new number, and the difference floats away under them
function UI:ShowCoins()
    local coins = KH.db.coins
    if self.coinsSeen ~= nil and coins ~= self.coinsSeen then
        local from, delta = self.coinsShown or self.coinsSeen, coins - self.coinsSeen
        Kit.Float(self.coinText, (delta > 0 and "+" or "-") .. KH.Number(math.abs(delta)), delta > 0 and C.gold or C.textSoft, -1, 12)
        if self.coinAnim then self.coinAnim.cancelled = true end
        self.coinAnim = Kit.Animate(0.45, function(p)
            self.coinsShown = math.floor(from + (coins - from) * p + 0.5)
            self.coinText:SetText(KH.Number(self.coinsShown))
        end, function()
            self.coinAnim, self.coinsShown = nil, coins
            self.coinText:SetText(KH.Number(coins))
        end)
    elseif not self.coinAnim then
        self.coinsShown = coins
        self.coinText:SetText(KH.Number(coins))
    end
    self.coinsSeen = coins
end

function UI:ShowLevel()
    local db = KH.db
    local lv = self.levelBox
    lv.label:SetText(T("herbalism", db.level))
    if db.level >= D.MAX_LEVEL then
        lv.bar:Glide(1)
    else
        lv.bar:Glide(db.xp / D.XPToNext(db.level))
    end
    if self.levelSeen and db.level > self.levelSeen then
        local seed
        for _, p in ipairs(D.PLANTS) do
            if p[2] > self.levelSeen and p[2] <= db.level then seed = p[1] end
        end
        Notice(seed and T("newSeed", db.level, D.Name(seed)) or T("levelNotice", db.level))
        Kit.Float(lv.label, T("herbalism", db.level), C.accentBright, -1, 12)
    end
    self.levelSeen = db.level
end

function UI:RefreshHeader()
    self:ShowCoins()
    self:ShowLevel()
    local deliverable = false
    for i = 1, D.ORDER_SLOTS do
        if KH.Orders:CanDeliver(i) then deliverable = true end
    end
    self.win:SetTabDot("orders", deliverable)
    self.win:SetTabDot("barn", self:Step() == "sell")
    self.win:SetTabDot("garden", self.view ~= "garden" and KH.Farm:ReadyCount() > 0)
end

-- the language changed: the words of the tabs and of the open screen are written again
function UI:Relabel()
    self:PaintPath()
    self:Refresh()
end

function UI:OnSelect(id)
    local changed = self.view ~= id
    self.view = id
    for _, s in pairs(self.screens) do s.frame:Hide() end
    local s = self.screens[id]
    if not s then
        s = BUILDERS[id](self.win)
        self.screens[id] = s
    end
    s.frame:Show()
    if changed then Kit.FadeIn(s.frame, 0.14) end
    self:PaintPath()
    if KH.db then
        self:RefreshHeader()
        self:RefreshScreen()
        -- the first time a place is opened, a card says how it works (and a "?" brings it back)
        if s.place and not s.helpButton then
            local b = Kit.Button(s.frame, 30, 30, "?", function() UI:Coach(s, true) end)
            b:SetPoint("TOPRIGHT", 0, 0)
            b:SetStyle("quiet")
            s.helpButton = b
        end
        if s.place then self:Coach(s) end
    end
end

-- The card that explains a place: three short lines and one button. It opens by itself the first time the place is opened, and
-- the "?" beside the title brings it back.
function UI:Coach(s, force)
    if not (s and s.place) then return end
    local db = KH.db
    db.seen = db.seen or {}
    if db.seen[s.place] and not force then return end
    if not s.coach then
        local dim = CreateFrame("Frame", nil, s.frame)
        dim:SetAllPoints(s.frame)
        dim:SetFrameLevel(s.frame:GetFrameLevel() + 40)
        dim:EnableMouse(true)
        dim.fill = dim:CreateTexture(nil, "BACKGROUND")
        dim.fill:SetAllPoints(dim)
        dim.fill:SetColorTexture(0, 0, 0, 0.62)
        local card = CreateFrame("Frame", nil, dim)
        card:SetSize(500, 300)
        card:SetPoint("CENTER", 0, 10)
        card.surface, card.outline = Kit.Rounded(card, 18, 0.07, 0.085, 0.095, 0.99, 0.14)
        card.art = card:CreateTexture(nil, "ARTWORK")
        card.art:SetSize(92, 92)
        card.art:SetPoint("TOP", 0, -18)
        card.title = Kit.Text(card, 18, C.text, "CENTER")
        card.title:SetPoint("TOP", 0, -118)
        card.title:SetWidth(460)
        card.lines = {}
        for i = 1, 3 do
            local line = Kit.Text(card, 12, C.textSoft, "CENTER")
            line:SetPoint("TOP", 0, -150 - (i - 1) * 34)
            line:SetWidth(440)
            card.lines[i] = line
        end
        card.ok = Kit.Button(card, 160, 34, "", function()
            KH.db.seen[s.place] = true
            dim:Hide()
        end)
        card.ok:SetPoint("BOTTOM", 0, 16)
        card.ok:SetStyle("primary")
        dim.card = card
        s.coach = dim
    end
    local card = s.coach.card
    card.art:SetTexture(BuildingArt(s.place))
    card.title:SetText(BuildingName(s.place))
    for i, line in ipairs(card.lines) do line:SetText(T("tut_" .. s.place .. i)) end
    card.ok:SetLabel(T("gotIt"))
    s.coach:Show()
end

function UI:RefreshScreen()
    local s = self.screens and self.screens[self.view]
    if not s or not KH.db then return end
    s:Refresh()
    if s.art and s.place then
        local level = V:Level(s.place)
        s.art:SetTexture(BuildingArt(s.place, level))
        s.art:SetAlpha(level > 0 and 1 or 0.45)
    end
end

function UI:Show(view)
    self:Create()
    if not self.frame:IsShown() then
        -- what changed while the window was closed is simply shown, not animated
        self.coinsSeen, self.levelSeen = nil, nil
        Notice("")
        self.frame:Show()
    end
    self.win:Select(view or "village")
end

local function InCombat() return _G.InCombatLockdown and InCombatLockdown() end

function UI:Toggle()
    self:Create()
    if not self.frame:IsShown() and InCombat() then
        Notice(T("inCombat"))
        KH:Notify(T("inCombat"))
        return
    end
    if self.frame:IsShown() then self.frame:Hide() else self:Show() end
end

function UI:Refresh()
    self:UpdateBadge()
    if self.frame and self.frame:IsShown() and KH.db then
        self:RefreshHeader()
        self:RefreshScreen()
    end
end

-- ----------------------------------------------------------------------------
-- The icon on the screen: the homestead minimized. Drag it anywhere; a click opens or closes the window; the number is what
-- waits for the player; and everything the homestead has to say comes out of it as a short line that goes away by itself.
-- ----------------------------------------------------------------------------
local bubble
local TOAST_HOLD = 5

local function Waiting()
    local ready = KH.Farm:ReadyCount()
    local deliverable = 0
    for i = 1, D.ORDER_SLOTS do
        if KH.Orders:CanDeliver(i) then deliverable = deliverable + 1 end
    end
    return ready, deliverable
end

local function PlaceBubble()
    local at = KH.db.bubble
    bubble:ClearAllPoints()
    if at.x and at.y then
        bubble:SetPoint("CENTER", UIParent, "BOTTOMLEFT", at.x, at.y)
    else
        bubble:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 260, 240)
    end
end

-- the line comes out on the side of the icon that has room
local function PlaceToast()
    local toast = bubble.toast
    local x = bubble.GetCenter and bubble:GetCenter()
    local screen = UIParent.GetWidth and UIParent:GetWidth()
    toast:ClearAllPoints()
    if type(x) == "number" and type(screen) == "number" and x > screen * 0.6 then
        toast:SetPoint("RIGHT", bubble, "LEFT", -8, 0)
    else
        toast:SetPoint("LEFT", bubble, "RIGHT", 8, 0)
    end
end

local function NextToast()
    local toast = bubble.toast
    local text = table.remove(bubble.queue, 1)
    if not text then
        bubble.showing = nil
        return
    end
    bubble.showing = true
    toast.text:SetText(text)
    toast:SetWidth(Kit.TextWidth(toast.text, text) + 28)
    PlaceToast()
    toast:Show()
    Kit.Animate(TOAST_HOLD + 0.6, function(p)
        local t = p * (TOAST_HOLD + 0.6)
        if t < 0.2 then toast:SetAlpha(t / 0.2)
        elseif t > TOAST_HOLD + 0.2 then toast:SetAlpha(math.max(0, 1 - (t - TOAST_HOLD - 0.2) / 0.4))
        else toast:SetAlpha(1) end
    end, function()
        toast:Hide()
        NextToast()
    end, true)
end

-- Something to tell the player: on the icon when it is on the screen; false when it is not (the caller prints it instead)
function UI:Toast(text)
    if not bubble or not KH.db.bubble.show or not text or text == "" then return false end
    if #bubble.queue >= 4 then table.remove(bubble.queue, 1) end
    bubble.queue[#bubble.queue + 1] = text
    if not bubble.showing then NextToast() end
    return true
end

function UI:ApplyBubble()
    if not bubble then return end
    bubble:SetShown(KH.db.bubble.show and true or false)
end

function UI:CreateBubble()
    if bubble then return end
    local b = CreateFrame("Button", "KorumHomesteadIcon", UIParent)
    b:SetSize(44, 44)
    b:SetFrameStrata("MEDIUM")
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:EnableMouse(true)
    b:RegisterForDrag("LeftButton")
    b.queue = {}
    b.glow = b:CreateTexture(nil, "BACKGROUND")
    b.glow:SetTexture(Kit.Icon("glow"))
    b.glow:SetSize(84, 84)
    b.glow:SetPoint("CENTER")
    b.glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    if b.glow.SetBlendMode then b.glow:SetBlendMode("ADD") end
    b.glow:SetAlpha(0)
    b.logo = b:CreateTexture(nil, "ARTWORK")
    b.logo:SetAllPoints()
    b.logo:SetTexture(Kit.LOGO)
    -- the number of things waiting, on a small accent disc at the corner
    b.badge = CreateFrame("Frame", nil, b)
    b.badge:SetSize(20, 20)
    b.badge:SetPoint("CENTER", b, "TOPRIGHT", -5, -5)
    b.badge.disc = b.badge:CreateTexture(nil, "ARTWORK")
    b.badge.disc:SetPoint("TOPLEFT", -5, 5)
    b.badge.disc:SetPoint("BOTTOMRIGHT", 5, -5)
    b.badge.disc:SetTexture(Kit.Icon("dot"))
    b.badge.disc:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    b.badge.text = Kit.Text(b.badge, 11, C.onAccent, "CENTER")
    b.badge.text:SetPoint("CENTER", 0, 0)
    b.badge:Hide()
    -- the line of the notifications
    local toast = CreateFrame("Frame", nil, b)
    toast:SetSize(200, 28)
    toast.pill = Kit.PillIn(toast, 28, "BACKGROUND")
    toast.pill:SetColor(C.bg[1], C.bg[2], C.bg[3], 0.94)
    toast.text = Kit.Text(toast, 12, C.text, "CENTER")
    toast.text:SetPoint("CENTER", 0, 0)
    toast:Hide()
    b.toast = toast

    b:SetScript("OnDragStart", function(self)
        self.dragged = true
        self:StartMoving()
    end)
    b:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if type(x) == "number" and type(y) == "number" then KH.db.bubble.x, KH.db.bubble.y = x, y end
        PlaceBubble()
        PlaceToast()
    end)
    b:SetScript("OnClick", function() Kit.ClickSound(); UI:Toggle() end)
    b:SetScript("OnEnter", function(self)
        self.hover = true
        if not GameTooltip then return end
        local ready, deliverable = Waiting()
        local work, left = KH.Village:Work()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Korum Homestead", 0.25, 0.85, 0.80)
        if ready > 0 then GameTooltip:AddLine(T(ready == 1 and "headReadyOne" or "headReadyMany", ready), 1, 1, 1) end
        if deliverable > 0 then GameTooltip:AddLine(T(deliverable == 1 and "vilDeliverOneH" or "vilDeliverH", deliverable), 1, 1, 1) end
        if work then GameTooltip:AddLine(T("workLine", T("b_" .. work.id), KH.Village:Level(work.id) + 1, KH.Duration(left)), 0.8, 0.8, 0.8) end
        if ready == 0 and deliverable == 0 and not work then GameTooltip:AddLine(T("tooltipNone"), 0.8, 0.8, 0.8) end
        GameTooltip:AddLine(T("bubbleHow"), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self) self.hover = false; if GameTooltip then GameTooltip:Hide() end end)
    -- it breathes while something waits
    b.clock = 0
    b:SetScript("OnUpdate", function(self, elapsed)
        self.clock = self.clock + (tonumber(elapsed) or 0)
        if self.hover then
            self.glow:SetAlpha(0.45)
        elseif self.waiting then
            self.glow:SetAlpha(0.14 + 0.22 * (0.5 + 0.5 * math.sin(self.clock * 3)))
        else
            self.glow:SetAlpha(0)
        end
    end)
    bubble = b
    UI.bubble = b
    PlaceBubble()
    self:ApplyBubble()
    self:UpdateBadge()
end

-- ----------------------------------------------------------------------------
-- The button on the minimap, with the count of ready plots
-- ----------------------------------------------------------------------------
local button
local function PlaceButton()
    if not button then return end
    local angle = math.rad(KH.db.minimap.angle or 215)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

function UI:UpdateBadge()
    local ready, deliverable = Waiting()
    if button then button.badge:SetText(ready > 0 and tostring(ready) or "") end
    if bubble then
        local n = ready + deliverable + KH.Inn:BackCount()
        bubble.waiting = n > 0
        bubble.badge:SetShown(n > 0)
        bubble.badge.text:SetText(tostring(n))
    end
end

function UI:ApplyMinimap()
    if not button then return end
    button:SetShown(not KH.db.minimap.hide)
end

function UI:CreateMinimap()
    if button or not Minimap then return end
    local b = CreateFrame("Button", "KorumHomesteadMinimap", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(20, 20)
    b.icon:SetPoint("CENTER", 0, 1)
    b.icon:SetTexture(D.Icon(2447))
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetSize(54, 54)
    b.border:SetPoint("TOPLEFT")
    b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b.badge = b:CreateFontString(nil, "OVERLAY")
    b.badge:SetFont(Kit.Font(), 11, "OUTLINE")
    b.badge:SetPoint("BOTTOMRIGHT", 2, -2)
    b.badge:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3])
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            KH.db.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            PlaceButton()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function() UI:Toggle() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(T("tooltipTitle"), 0.4, 0.85, 0.82)
        local n = KH.Farm:ReadyCount()
        GameTooltip:AddLine(n > 0 and T("tooltipReady", n) or T("tooltipNone"), 1, 1, 1)
        GameTooltip:AddLine(T("tooltipClick"), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button = b
    PlaceButton()
    self:ApplyMinimap()
    self:UpdateBadge()
end

-- ----------------------------------------------------------------------------
-- The clock: the rings move, the badge counts, and a plot that finishes is announced once
-- ----------------------------------------------------------------------------
local announced = {}
local acc = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 1 or not KH.db then return end
    acc = 0
    UI:Tick()
end)

function UI:Tick()
    for _, recipe in ipairs(KH.Workshop:Update()) do
        if KH.db.alerts then KH:Notify(T("craftDone", T("good_" .. recipe))) end
    end
    local back = KH.Inn:Update()
    if back > 0 and KH.db.alerts then KH:Notify(T(back == 1 and "innBackOne" or "innBackMany", back)) end
    local built, level = KH.Village:Update()
    if built then
        local text = T("built", T("b_" .. built), level)
        if KH.db.alerts then KH:Notify(text) end
        Notice(text)
    end
    for i = 1, KH.db.nplots do
        local ready = KH.Farm:Status(i) == "ready"
        if ready and not announced[i] then
            announced[i] = true
            local plot = KH.db.plots[i]
            if KH.db.alerts and plot then KH:Notify(T("readyAlert", D.Name(plot.plant))) end
        elseif not ready then
            announced[i] = nil
        end
    end
    self:Refresh()
end

KH:On("PLAYER_LOGIN", function()
    D.Preload()
    KH.Orders:Ensure()
    UI:CreateMinimap()
    UI:CreateBubble()
    -- what was ready when logging in is not announced again by the clock; the welcome line tells it once
    for i = 1, KH.db.nplots do
        if KH.Farm:Status(i) == "ready" then announced[i] = true end
    end
    KH.After(6, function()
        local n = KH.Farm:ReadyCount()
        if KH.db.welcome and n > 0 then KH:Notify(T(n == 1 and "headReadyOne" or "headReadyMany", n)) end
    end)
end)
KH:On("GET_ITEM_INFO_RECEIVED", function() UI:Refresh() end)
-- a fight starts: the window is not in the way
KH:On("PLAYER_REGEN_DISABLED", function()
    if UI.frame and UI.frame:IsShown() then UI.frame:Hide() end
end)
