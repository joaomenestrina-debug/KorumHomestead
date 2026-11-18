local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local CARD_H, GAP, DAILY_H = 68, 6, 92

-- one order card: the herb, who asks, the bar of what the Barn has, the pay and the button
local function OrderRow(parent, W, y, h, onDeliver, above)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(W, h)
    row:SetPoint("TOPLEFT", 0, y)
    row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(46, 46)
    row.icon:SetPoint("LEFT", 22, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    Kit.RoundMask(row, row.icon)
    local top = (h - 64 + (above or 0)) / 2     -- the three lines (and the tag `above` them) sit in the middle of the card
    row.who = Kit.Text(row, 13, C.text)
    row.who:SetPoint("TOPLEFT", 88, -top)
    row.wants = Kit.Text(row, 12, C.textSoft)
    row.wants:SetPoint("TOPLEFT", 88, -top - 20)
    row.bar = Kit.Bar(row, 180, 4)
    row.bar:SetPoint("TOPLEFT", 88, -top - 48)
    row.have = Kit.Text(row, 10, C.textMuted)
    row.have:SetPoint("LEFT", row.bar, "RIGHT", 10, 0)
    row.deliver = Kit.Button(row, 124, 34, "", onDeliver)
    row.deliver:SetPoint("RIGHT", -22, 0)
    row.coins = Kit.Text(row, 13, C.text, "RIGHT")
    row.coins:SetPoint("BOTTOMRIGHT", row.deliver, "LEFT", -22, 2)
    row.xp = Kit.Text(row, 10, C.textMuted, "RIGHT")
    row.xp:SetPoint("TOPRIGHT", row.deliver, "LEFT", -22, -4)
    return row
end

-- a small card of the two columns: herbs on the left, Workshop items on the right
local function SmallRow(parent, x, y, w, onDeliver)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(w, CARD_H)
    row:SetPoint("TOPLEFT", x, y)
    row.surface, row.outline = Kit.Rounded(row, 10, 1, 1, 1, 0.045, 0.06)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(34, 34)
    row.icon:SetPoint("LEFT", 10, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    Kit.RoundMask(row, row.icon)
    row.who = Kit.Text(row, 10, C.textMuted)
    row.who:SetPoint("TOPLEFT", 54, -9)
    row.wants = Kit.Text(row, 12, C.text)
    row.wants:SetPoint("TOPLEFT", 54, -24)
    row.wants:SetWidth(w - 54 - 170)
    row.wants:SetWordWrap(false)
    row.bar = Kit.Bar(row, 96, 3)
    row.bar:SetPoint("TOPLEFT", 54, -49)
    row.have = Kit.Text(row, 9, C.textMuted)
    row.have:SetPoint("LEFT", row.bar, "RIGHT", 6, 0)
    row.deliver = Kit.Button(row, 86, 26, "", onDeliver)
    row.deliver:SetPoint("RIGHT", -10, 0)
    row.coins = Kit.Text(row, 11, C.text, "RIGHT")
    row.coins:SetPoint("BOTTOMRIGHT", row.deliver, "LEFT", -10, 1)
    row.xp = Kit.Text(row, 9, C.textMuted, "RIGHT")
    row.xp:SetPoint("TOPRIGHT", row.deliver, "LEFT", -10, -3)
    row.short = true                               -- no room for "in the barn": only the numbers
    row.empty = Kit.Text(row, 10, C.textMuted)
    row.empty:SetPoint("LEFT", 14, 0)
    row.empty:SetWidth(w - 28)
    return row
end

local function PaintOrder(row, o, extraXP)
    local have = KH.Orders.Have(o)
    local can = have >= o.qty
    if o.good then
        row.icon:SetTexture(GoodTex(o.good))
        row.wants:SetText(T("orderWants", o.qty, T("good_" .. o.good)))
    else
        SetIcon(row.icon, o.plant)
        row.wants:SetText(T("orderWants", o.qty, D.Name(o.plant)))
    end
    row.bar:Glide(have / o.qty, can and C.accentBright or C.accent)
    row.have:SetText(T(row.short and "orderHaveShort" or "orderHave", math.min(have, o.qty), o.qty))
    row.coins:SetText(T("orderCoins", KH.Number(math.floor(o.coins * KH.Village:PayBonus()))))
    row.xp:SetText(T("orderXP", o.xp + (extraXP or 0)))
    row.deliver:SetLabel(can and T("deliver") or T("toGo", o.qty - have))
    row.deliver:SetStyle(can and "primary" or "quiet")
    row.deliver:SetEnabledState(can)
    row.outline:SetColor(can and C.accent[1] or 1, can and C.accent[2] or 1, can and C.accent[3] or 1, can and 0.5 or 0.06)
    return can
end

local function BuildOrders(win)
    local s = Screen(win, "market")
    local W = s.width

    -- the order of the day, on top: it pays more and keeps the streak
    local daily = OrderRow(s.frame, W, -66, DAILY_H, function() s:DeliverDaily() end, 16)
    daily.surface:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.07)
    daily.tag = Kit.Text(daily, 10, C.accent)
    daily.tag:SetPoint("BOTTOMLEFT", daily.who, "TOPLEFT", 0, 4)
    daily.streak = Kit.Text(daily, 10, C.textSoft, "RIGHT")
    daily.streak:SetPoint("TOPRIGHT", -22, -12)
    daily.rare = daily:CreateTexture(nil, "ARTWORK")
    daily.rare:SetSize(14, 14)
    daily.rare:SetPoint("RIGHT", daily.streak, "LEFT", -5, 0)
    daily.rare:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    s.daily = daily

    -- below it, two columns of four: herbs | Workshop items
    s.rows = {}
    local colW = math.floor((W - 10) / 2)
    local herbs = KH.Balance.ORDERS.herbSlots
    for i = 1, D.ORDER_SLOTS do
        local col, line = (i <= herbs) and 0 or 1, (i <= herbs) and (i - 1) or (i - herbs - 1)
        s.rows[i] = SmallRow(s.frame, col * (colW + 10), -66 - DAILY_H - 8 - line * (CARD_H + GAP), colW, function() s:Deliver(i) end)
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

    function s:DeliverDaily()
        local ok, r = KH.Daily:Deliver()
        UI:Refresh()        -- first: a level reached with the xp has its own notice, and the prize must be the one that stays
        if not ok then
            Notice(Reason(r))
        elseif r.rare > 0 then
            Notice(T("streakRare", r.streak, KH.Number(r.pay), KH.Number(r.bonus), r.rare, D.Name(KH.Balance.DAILY.rareItem)))
            Kit.Float(self.daily.coins, "+" .. KH.Number(r.pay), C.gold, 1, 14)
        elseif r.bonus > 0 then
            Notice(T("streakPrize", r.streak, KH.Number(r.pay), KH.Number(r.bonus)))
            Kit.Float(self.daily.coins, "+" .. KH.Number(r.pay), C.gold, 1, 14)
        else
            Notice(T("dailyDelivered", KH.Number(r.pay)))
        end
    end

    function s:Refresh()
        KH.Orders:Ensure()
        local db = KH.db
        local ready = 0
        for i, row in ipairs(self.rows) do
            local o = db.orders[i]
            local parts = {row.icon, row.who, row.wants, row.bar, row.have, row.deliver, row.coins, row.xp}
            for _, part in ipairs(parts) do part:SetShown(o ~= nil) end
            row.empty:SetShown(o == nil)
            if o then
                row.who:SetText(T("npc" .. o.npc))
                if PaintOrder(row, o) then ready = ready + 1 end
            else
                row.empty:SetText(T("ordersNoWorkshop"))          -- item orders come with the Workshop's recipes
                row.outline:SetColor(1, 1, 1, 0.04)
            end
        end

        -- the order of the day
        local d = self.daily
        local o = KH.Daily:Order()
        local streak = KH.Daily:Streak()
        d.tag:SetText(T("dailyTag"))
        d.who:SetText(T("npc" .. o.npc))
        local nextDay, missing = KH.Daily:NextPrize()
        if KH.Daily:Done() then
            SetIcon(d.icon, o.plant)
            d.wants:SetText(T("dailyDone"))
            d.bar:Glide(1, C.accentBright)
            d.have:SetText(T("dailyNew", KH.Duration(KH.UntilNextDay())))
            d.coins:SetText("")
            d.xp:SetText("")
            d.deliver:SetLabel(T("dailyTomorrow"))
            d.deliver:SetStyle("quiet")
            d.deliver:SetEnabledState(false)
            d.outline:SetColor(1, 1, 1, 0.06)
        else
            -- the prize of the streak (xp) shows in the xp when this delivery reaches it
            local prize = missing == 1 and KH.Balance.DAILY.streak[nextDay]
            if PaintOrder(d, o, prize and math.floor(o.xp * (prize.xp or 0)) or 0) then ready = ready + 1 end
        end
        local rare = KH.Balance.DAILY.streak[nextDay] and (KH.Balance.DAILY.streak[nextDay].rare or 0) or (nextDay > 30 and 1 or 0)
        d.rare:SetTexture(D.Icon(KH.Balance.DAILY.rareItem))
        d.rare:SetShown(rare > 0)
        if streak > 0 then
            d.streak:SetText(T(streak == 1 and "dailyStreakOne" or "dailyStreak", streak, nextDay, missing))
        else
            d.streak:SetText(T("dailyStreakNone", nextDay))
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

P.builders.orders = BuildOrders
