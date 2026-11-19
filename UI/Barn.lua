local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

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
        for i = 1, D.ORDER_SLOTS do local o = db.orders[i]; if o then wanted[o.plant or o.good] = true end end
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
                local sell = row.good and KH.Village:GoodSell(row.id) or D.Plant(row.id).sell
                total = total + n
                if not row.good then herbs = herbs + n end
                worth = worth + math.floor(n * sell * KH.Village:PayBonus())
                row:SetHeight(rowH)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -66 - at * rowH)
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
