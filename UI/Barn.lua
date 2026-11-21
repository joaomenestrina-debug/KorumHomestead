local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local TOP = 98                                  -- under the tabs
UI.barnTab = "herbs"

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
    s.tabs:SetPoint("TOPLEFT", 0, -58)
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
        row:SetSize(LIST_W, 44)
        row.id, row.good, row.tab = good, true, KH.Village.BarnTab(good)
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
                    row.wanted:SetText(wanted[row.id] and T("onOrder") or (row.id == "ore" and T("forWorks") or ""))
                else
                    SetIcon(row.icon, row.id)
                    row.name:SetText(D.Name(row.id))
                    row.wanted:SetText(wanted[row.id] and T("onOrder") or "")
                end
                row.info:SetText(WHITE .. "× " .. n .. "|r     " .. T("worth", KH.Number(math.floor(sell * KH.Village:PayBonus()))))
                row.sell1:SetLabel(T("sell1"))
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
        -- the space of the herbs, and of each good the village makes
        local cap = KH.Village:BarnCap()
        local parts = {T("storedHerbs", KH.Village:Stored(), cap)}
        for _, id in ipairs(KH.Village.BUILDINGS) do
            local good = KH.Village.MAKES[id]
            if good and KH.Village:Level(id) > 0 then
                parts[#parts + 1] = T("storedGood", T("good_" .. good), KH.Village:Good(good), cap)
            end
        end
        self.fill:SetText(table.concat(parts, "  ·  "))
        self.stats:SetText(T("stats", db.stats.harvested, db.stats.delivered, KH.Number(db.stats.earned)))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- Orders
-- ----------------------------------------------------------------------------

P.builders.barn = BuildBarn
