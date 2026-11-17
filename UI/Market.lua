local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

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

P.builders.orders = BuildOrders
