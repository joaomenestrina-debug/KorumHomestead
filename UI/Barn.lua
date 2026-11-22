local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local TOP = 112                                 -- under the tabs and the legend
UI.barnTab = "herbs"
-- how many the middle button of a row sells (owner, 22/11): − and + walk these steps; never more than the row has
local STEPS = {1, 5, 10, 20, 50, 100, 200, 500, 1000}
local function Step(qty, dir, most)
    if dir > 0 then
        for _, n in ipairs(STEPS) do if n > qty and n <= most then return n end end
        return math.max(qty, math.min(most, STEPS[#STEPS]))
    end
    for i = #STEPS, 1, -1 do if STEPS[i] < qty then return STEPS[i] end end
    return 1
end

-- the "sell N" of a row: −, the number, +, and the button; `sell(id, n)` sells and returns the coins
local function QuantitySeller(row, sell)
    row.qty = 1
    row.sell1 = Kit.Button(row, 92, 24, "", function()
        local coins = sell(row.id, math.min(row.qty, row.have or 0))
        if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
        UI:Refresh()
    end)
    row.sell1:SetPoint("RIGHT", row.sellAll, "LEFT", -8, 0)
    row.more = Kit.Button(row, 22, 24, "+", function()
        row.qty = Step(row.qty, 1, row.have or 1)
        UI:Refresh()
    end)
    row.more:SetPoint("RIGHT", row.sell1, "LEFT", -6, 0)
    row.count = Kit.Text(row, 11, C.text, "CENTER")
    row.count:SetPoint("RIGHT", row.more, "LEFT", -2, 0)
    row.count:SetWidth(34)
    row.less = Kit.Button(row, 22, 24, "−", function()
        row.qty = Step(row.qty, -1, row.have or 1)
        UI:Refresh()
    end)
    row.less:SetPoint("RIGHT", row.count, "LEFT", -2, 0)
    row.info = Kit.Text(row, 11, C.textSoft, "RIGHT")
    row.info:SetPoint("RIGHT", row.less, "LEFT", -14, 0)
end

local function BuildBarn(win)
    local s = Screen(win, "barn")
    local W = s.width
    s.rows = {}
    -- one tab for each kind of thing (owner, 20/11): herbs, raw things, and what each trade of the Workshop made
    local options = {}
    for _, tab in ipairs(KH.Village.BARN_TABS) do
        options[#options + 1] = {value = tab, label = T(tab == "herbs" and "barnTab_herbs" or tab == "raw" and "barnTab_raw" or "trade_" .. tab)}
    end
    s.tabs = Kit.Segmented(s.frame, W, options, function() return UI.barnTab end,
        function(v) UI.barnTab = v; s.boff = 0; UI:Refresh() end)
    -- the list scrolls when a tab has more kinds than fit (the herbs go past twenty): the wheel over it, or the bar
    local BAR = 4
    s.boff = 0
    local area = CreateFrame("Frame", nil, s.frame)
    area:SetPoint("TOPLEFT", 0, -TOP)
    area:SetPoint("BOTTOMRIGHT", s.frame, "BOTTOMRIGHT", 0, 52)
    area:EnableMouseWheel(true)
    area:SetScript("OnMouseWheel", function(_, delta) s.boff = s.boff - delta; s:Refresh() end)
    s.barea = area
    local track = CreateFrame("Button", nil, area)
    track:SetWidth(BAR + 8)
    track:SetPoint("TOPRIGHT", 0, 0)
    track:SetPoint("BOTTOMRIGHT", 0, 0)
    track.line = track:CreateTexture(nil, "BACKGROUND")
    track.line:SetWidth(BAR)
    track.line:SetPoint("TOP", 0, 0)
    track.line:SetPoint("BOTTOM", 0, 0)
    track.line:SetColorTexture(1, 1, 1, 0.06)
    track.thumb = track:CreateTexture(nil, "ARTWORK")
    track.thumb:SetWidth(BAR)
    track.thumb:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
    track:SetScript("OnClick", function()                 -- one page down; at the bottom, back to the top
        s.boff = (s.boff >= (s.bmost or 0)) and 0 or s.boff + (s.bfit or 1)
        s:Refresh()
    end)
    s.btrack = track
    local LIST_W = W - BAR - 14
    local SELLER_W = 96 + 8 + 92 + 6 + 22 + 2 + 34 + 2 + 22 + 14     -- the buttons of a row, from the right edge
    s.tabs:SetPoint("TOPLEFT", 0, -58)
    -- the legend of the dot a row may have (owner, 22/11): instead of words beside each name
    s.legendDot = s.frame:CreateTexture(nil, "ARTWORK")
    s.legendDot:SetTexture(Kit.Icon("dot"))
    s.legendDot:SetSize(8, 8)
    s.legendDot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    s.legend = Kit.Text(s.frame, 10, C.textSoft, "RIGHT")
    s.legend:SetPoint("TOPRIGHT", 0, -94)
    s.legendDot:SetPoint("RIGHT", s.legend, "LEFT", -6, 0)
    s.empty = Kit.Text(s.frame, 12, C.textMuted)
    s.empty:SetPoint("TOPLEFT", 0, -TOP - 12)
    s.empty:SetWidth(W)
    for i, p in ipairs(D.PLANTS) do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(LIST_W, 44)
        row.id, row.tab = p[1], "herbs"
        row.rule = Kit.Hairline(row, 0.05)
        row.rule:SetPoint("BOTTOMLEFT")
        row.rule:SetPoint("BOTTOMRIGHT")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("LEFT", 46, 0)
        row.wanted = row:CreateTexture(nil, "OVERLAY")       -- the dot: an order or a work asks for it (the legend)
        row.wanted:SetTexture(Kit.Icon("dot"))
        row.wanted:SetSize(8, 8)
        row.wanted:SetPoint("RIGHT", row.name, "LEFT", -6, 0)
        row.wanted:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        row.sellAll = Kit.Button(row, 96, 24, "", function()
            local coins = KH.Farm:Sell(row.id)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sellAll:SetPoint("RIGHT", 0, 0)
        QuantitySeller(row, function(id, n) return KH.Farm:Sell(id, n) end)
        s.rows[i] = row
    end

    for _, good in ipairs(KH.Village.GOOD_ORDER) do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(LIST_W, 44)
        row.id, row.good, row.tab = good, true, KH.Village.BarnTab(good)
        row.rule = Kit.Hairline(row, 0.05)
        row.rule:SetPoint("BOTTOMLEFT")
        row.rule:SetPoint("BOTTOMRIGHT")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", 0, 0)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("LEFT", 46, 0)
        row.wanted = row:CreateTexture(nil, "OVERLAY")       -- the dot: an order or a work asks for it (the legend)
        row.wanted:SetTexture(Kit.Icon("dot"))
        row.wanted:SetSize(8, 8)
        row.wanted:SetPoint("RIGHT", row.name, "LEFT", -6, 0)
        row.wanted:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        row.sellAll = Kit.Button(row, 96, 24, "", function()
            local coins = KH.Village:SellGood(row.id)
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        end)
        row.sellAll:SetPoint("RIGHT", 0, 0)
        QuantitySeller(row, function(id, n) return KH.Village:SellGood(id, n) end)
        s.rows[#s.rows + 1] = row
    end

    s.fill = Kit.Text(s.frame, 10, C.textSoft)
    s.fill:SetPoint("BOTTOMLEFT", 0, 28)
    s.fill:SetWidth(W - 280)
    s.fill:SetWordWrap(false)
    s.stats = Kit.Text(s.frame, 10, C.textMuted)
    s.stats:SetPoint("LEFT", s.frame, "BOTTOMLEFT", 0, 18)
    s.stats:SetWidth(W - 280)
    s.stats:SetWordWrap(true)
    -- the one button: sell everything; with an empty barn it shows the way back to the garden
    s.action = Kit.Button(s.frame, 260, 36, "", function() s:Action() end)
    s.action:SetPoint("BOTTOMRIGHT", 0, 0)

    -- the button sells what the open tab shows; with an empty barn it shows the way back to the garden
    function s:Action()
        if self.total > 0 then
            local coins = 0
            if UI.barnTab == "herbs" then coins = KH.Farm:SellAll() end
            for _, good in ipairs(KH.Village.GOOD_ORDER) do
                if KH.Village.BarnTab(good) == UI.barnTab then coins = coins + KH.Village:SellGood(good) end
            end
            if coins > 0 then Notice(T("soldFor", KH.Number(coins))) end
            UI:Refresh()
        else
            UI:Show("garden")
        end
    end

    function s:Refresh()
        local db = KH.db
        local wanted = {}
        for i = 1, D.ORDER_SLOTS do local o = db.orders[i]; if o then wanted[o.plant or o.good] = true end end
        local shown, total, worth = 0, 0, 0
        local function Have(row)
            if row.good then return KH.Village:Good(row.id) end
            return db.crops[row.id] or 0
        end
        local herbs, here, tabWorth = 0, 0, 0
        local count = {}
        for _, row in ipairs(self.rows) do
            local n = Have(row)
            if n > 0 then
                count[row.tab] = (count[row.tab] or 0) + 1
                if row.tab == UI.barnTab then shown = shown + 1 end
            end
        end
        -- each tab says how many kinds it holds
        for k, tab in ipairs(KH.Village.BARN_TABS) do
            local base = T(tab == "herbs" and "barnTab_herbs" or tab == "raw" and "barnTab_raw" or "trade_" .. tab)
            Kit.Fit(self.tabs.buttons[k].label, base .. ((count[tab] or 0) > 0 and (" |cff40d9c4" .. count[tab] .. "|r") or ""),
                math.floor(W / #KH.Village.BARN_TABS) - 8)
        end
        self.tabs:Sync()
        local room = self.height - TOP - 52
        local rowH = math.max(26, math.min(44, math.floor(room / math.max(1, shown))))
        local fit = math.floor(room / rowH)
        self.bfit, self.bmost = fit, math.max(0, shown - fit)
        self.boff = math.max(0, math.min(self.bmost, math.floor(self.boff + 0.5)))
        local at, seen = 0, 0
        for _, row in ipairs(self.rows) do
            local n = Have(row)
            local mine = row.tab == UI.barnTab
            if n > 0 and mine then seen = seen + 1 end
            local inView = seen > self.boff and at < fit          -- under the scroll and still on the page
            row:SetShown(n > 0 and mine and inView)
            if n > 0 then
                local sell = row.good and KH.Village:GoodSell(row.id) or D.Plant(row.id).sell
                total = total + n
                if not row.good then herbs = herbs + n end
                worth = worth + math.floor(n * sell * KH.Village:PayBonus())
                if mine then here, tabWorth = here + n, tabWorth + math.floor(n * sell * KH.Village:PayBonus()) end
            end
            if n > 0 and mine and inView then
                local sell = row.good and KH.Village:GoodSell(row.id) or D.Plant(row.id).sell
                row:SetHeight(rowH)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -TOP - at * rowH)
                at = at + 1
                local side = math.min(30, rowH - 6)
                row.icon:SetSize(side, side)
                if row.good then
                    row.icon:SetTexture(GoodTex(row.id))
                    row.name:SetText(T("good_" .. row.id))
                    row.wanted:SetShown(wanted[row.id] or row.id == "ore")
                else
                    SetIcon(row.icon, row.id)
                    row.name:SetText(D.Name(row.id))
                    row.wanted:SetShown(wanted[row.id] and true or false)
                end
                row.info:SetText(WHITE .. "× " .. n .. "|r   " .. T("worth", KH.Number(math.floor(sell * KH.Village:PayBonus()))))
                -- the name has what is left of the line before the numbers (the buttons take SELLER_W)
                local infoW = Kit.TextWidth(row.info, row.info:GetText())
                Kit.Fit(row.name, row.name:GetText(), math.max(40, LIST_W - 46 - SELLER_W - infoW - 14), 9)
                row.have = n
                row.qty = math.max(1, math.min(row.qty, n))
                row.count:SetText(tostring(row.qty))
                row.sell1:SetLabel(T("sellN", row.qty))
                row.less:SetEnabledState(row.qty > 1)
                row.more:SetEnabledState(row.qty < n)
                row.sellAll:SetLabel(T("sellAll"))
            end
        end
        local track = self.btrack
        track:SetShown(self.bmost > 0)
        if self.bmost > 0 then
            local h = math.max(18, math.floor(room * fit / shown))
            track.thumb:SetHeight(h)
            track.thumb:ClearAllPoints()
            track.thumb:SetPoint("TOP", track, "TOP", 0, -math.floor((room - h) * self.boff / self.bmost + 0.5))
        end
        self.total = total
        self.empty:SetText(total > 0 and here == 0 and T("barnTabEmpty") or "")
        self.legend:SetText(here > 0 and T("barnLegend") or "")
        self.legendDot:SetShown(here > 0)
        if total > 0 then
            self.head:SetText(herbs == total and (total == 1 and T("barnHeadOne") or T("barnHead", total)) or T("barnHeadMixed", total))
            self.sub:SetText(T("barnSub", KH.Number(worth)))
            self.action:SetLabel(here > 0 and T("sellTab", KH.Number(tabWorth)) or T("barnTabNone"))
            self.action:SetStyle(here > 0 and "primary" or "quiet")
            self.action:SetEnabledState(here > 0)
        else
            self.action:SetEnabledState(true)
            self.head:SetText(T("barnEmptyH"))
            self.sub:SetText(T("barnEmpty"))
            self.action:SetLabel(T("goGarden"))
            self.action:SetStyle("quiet")
        end
        -- the space of what the open tab holds (every tab has one: equipment, finds and potions count too)
        local V = KH.Village
        local cap = V:BarnCap()
        local parts = {}
        for _, space in ipairs(V.TAB_SPACES[UI.barnTab]) do
            local up = (space ~= "ore" or V:Level("mine") > 0) and (space ~= "fish" or V:Level("pond") > 0)
            if up then
                local have = V:Space(space)
                local color = have >= cap and "|cffff7a6b" or (have >= cap * KH.Balance.BARN_WARN and "|cffffd24d" or "")
                parts[#parts + 1] = color .. T("storedGood", T("space_" .. space), have, cap) .. (color ~= "" and "|r" or "")
            end
        end
        Kit.Fit(self.fill, table.concat(parts, "  ·  "), W - 280)
        self.stats:SetText(T("stats", db.stats.harvested, db.stats.delivered, KH.Number(db.stats.earned)))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- Orders
-- ----------------------------------------------------------------------------

P.builders.barn = BuildBarn
