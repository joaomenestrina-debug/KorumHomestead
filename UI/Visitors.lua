local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local VDIR = P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex = P.GoodTex

-- ----------------------------------------------------------------------------
-- Visitors: the random events that are open now (Events.lua), one card each, with the time left and the answer
-- ----------------------------------------------------------------------------
local CARD_H, CARD_GAP = 186, 10
local PORTRAIT = {urgent = "visitor_messenger", merchant = "visitor_merchant", caravan = "visitor_caravan"}

-- what a key is called and shows: a herb (item id) or a good (ore, fish, a rare find, a Workshop item)
local function Name(key)
    if type(key) == "number" then return D.Name(key) end
    return T("good_" .. key)
end
local function Icon(key)
    if type(key) == "number" then return D.Icon(key) end
    return GoodTex(key)
end
local function Have(key)
    if type(key) == "number" then return KH.db.crops[key] or 0 end
    return V:Good(key)
end
UI.VisitorName = Name

local function ItemLine(parent, size)
    local line = CreateFrame("Frame", nil, parent)
    line:SetSize(240, size)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(size, size)
    line.icon:SetPoint("LEFT", 0, 0)
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line.text = Kit.Text(line, 11, C.text)
    line.text:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.text:SetWidth(240 - size - 6)
    line.text:SetWordWrap(false)
    return line
end

local function BuildVisitors(win)
    local s = Screen(win)
    local W = s.width
    s.cards = {}
    for c = 1, KH.Balance.EVENTS.maxOpen do
        local card = CreateFrame("Frame", nil, s.frame)
        card:SetSize(W, CARD_H)
        card:SetPoint("TOPLEFT", 0, -66 - (c - 1) * (CARD_H + CARD_GAP))
        card.surface, card.outline = Kit.Rounded(card, 12, 1, 1, 1, 0.045, 0.08)
        card.portrait = card:CreateTexture(nil, "ARTWORK")
        card.portrait:SetSize(64, 64)
        card.portrait:SetPoint("TOPLEFT", 16, -16)
        card.title = Kit.Text(card, 14, C.text)
        card.title:SetPoint("TOPLEFT", 96, -18)
        card.title:SetWidth(W - 96 - 150)
        card.title:SetWordWrap(false)
        card.left = Kit.Text(card, 11, C.gold, "RIGHT")
        card.left:SetPoint("TOPRIGHT", -16, -20)
        card.desc = Kit.Text(card, 11, C.textSoft)
        card.desc:SetPoint("TOPLEFT", 96, -40)
        card.desc:SetWidth(W - 96 - 16)
        card.desc:SetWordWrap(true)
        -- one answer (urgent, merchant, find) ...
        card.item = ItemLine(card, 26)
        card.item:SetPoint("TOPLEFT", 96, -82)
        card.reward = Kit.Text(card, 11, C.gold)
        card.reward:SetPoint("TOPLEFT", 96, -116)
        card.reward:SetWidth(W - 96 - 200)
        card.reward:SetWordWrap(false)
        card.button = Kit.Button(card, 170, 32, "", function() s:Act(card) end)
        card.button:SetPoint("BOTTOMRIGHT", -16, 16)
        -- ... or the three trades of a caravan
        card.trades = {}
        for k = 1, KH.Balance.EVENTS.caravan.trades do
            local row = CreateFrame("Frame", nil, card)
            row:SetSize(W - 96 - 16, 34)
            row:SetPoint("TOPLEFT", 96, -70 - (k - 1) * 38)
            row.give = ItemLine(row, 22)
            row.give:SetPoint("LEFT", 0, 0)
            row.give:SetWidth(205)
            row.give.text:SetWidth(177)
            row.arrow = Kit.Text(row, 13, C.accent, "CENTER")
            row.arrow:SetPoint("LEFT", 207, 0)
            row.arrow:SetText(">")
            row.get = ItemLine(row, 22)
            row.get:SetPoint("LEFT", 224, 0)
            row.get:SetWidth(205)
            row.get.text:SetWidth(177)
            row.button = Kit.Button(row, 100, 28, "", function() s:Trade(card, k) end)
            row.button:SetPoint("RIGHT", 0, 0)
            card.trades[k] = row
        end
        s.cards[c] = card
    end
    s.empty = Kit.Text(s.frame, 12, C.textMuted)
    s.empty:SetPoint("TOPLEFT", 0, -80)
    s.empty:SetWidth(W)

    function s:Act(card)
        local e = card.event
        if not e then return end
        local ok, r
        if e.kind == "urgent" then
            ok, r = KH.Events:Deliver(e.id)
            if ok then Notice(T("evDone_urgent", KH.Number(r.coins), KH.Number(r.xp))) end
        elseif e.kind == "merchant" then
            ok, r = KH.Events:Sell(e.id)
            if ok then Notice(T("evDone_merchant", r.n, KH.Number(r.coins))) end
        else
            ok, r = KH.Events:Collect(e.id)
            if ok then Notice(T("evDone_find", Name(r.key))) end
        end
        if not ok then Notice(Reason(r)) end
        UI:Refresh()
    end

    function s:Trade(card, k)
        local e = card.event
        if not e then return end
        local ok, r = KH.Events:Trade(e.id, k)
        if ok then Notice(T("evDone_trade", r.m, Name(r.get))) else Notice(Reason(r)) end
        UI:Refresh()
    end

    function s:Refresh()
        local open = KH.Events:Open()
        self.head:SetText(#open > 0 and T(#open == 1 and "visitorsOne" or "visitorsMany", #open) or T("visitorsNoneH"))
        self.sub:SetText(T("visitorsS"))
        self.empty:SetText(#open == 0 and T("visitorsNone") or "")
        for c, card in ipairs(self.cards) do
            local e = open[c]
            card.event = e
            card:SetShown(e ~= nil)
            if e then self:Paint(card, e) end
        end
    end

    function s:Paint(card, e)
        local kind = e.kind
        card.portrait:SetTexture(PORTRAIT[kind] and (VDIR .. PORTRAIT[kind]) or Icon(e.key))
        card.title:SetText(T("evTitle_" .. kind))
        card.left:SetText(T("evLeft", KH.Duration(KH.Events:Left(e))))
        card.item:SetShown(kind ~= "caravan")
        card.reward:SetShown(kind ~= "caravan")
        card.button:SetShown(kind ~= "caravan")
        for _, row in ipairs(card.trades) do row:SetShown(kind == "caravan") end
        if kind == "caravan" then
            card.desc:SetText(T("evDesc_caravan"))
            for k, row in ipairs(card.trades) do
                local t = e.trades[k]
                row.give.icon:SetTexture(Icon(t.give))
                row.give.text:SetText(T("evGive", t.n, Name(t.give), Have(t.give)))
                row.get.icon:SetTexture(Icon(t.get))
                row.get.text:SetText(T("evGet", t.m, Name(t.get)))
                local can = KH.Events:CanTrade(e.id, k)
                row.button:SetLabel(t.done and T("evTraded") or T("evTrade"))
                row.button:SetStyle(can and "primary" or "quiet")
                row.button:SetEnabledState(can)
            end
            return
        end
        card.item.icon:SetTexture(Icon(e.key))
        local can
        if kind == "urgent" then
            card.desc:SetText(T("evDesc_urgent"))
            card.item.text:SetText(T("evWants", e.qty, Name(e.key), math.min(Have(e.key), e.qty), e.qty))
            card.reward:SetText(T("evReward", KH.Number(e.coins), KH.Number(e.xp)))
            can = Have(e.key) >= e.qty
            card.button:SetLabel(can and T("deliver") or T("toGo", e.qty - Have(e.key)))
        elseif kind == "merchant" then
            local n = math.min(Have(e.key), e.left)
            card.desc:SetText(T("evDesc_merchant", e.left))
            card.item.text:SetText(T("evPrice", Name(e.key), KH.Number(e.price)))
            card.reward:SetText(n > 0 and T("evSellFor", n, KH.Number(n * e.price)) or T("evHaveNone"))
            can = n > 0
            card.button:SetLabel(can and T("evSell", n) or T("evSellNone"))
        else
            card.desc:SetText(T("evDesc_" .. kind))
            card.item.text:SetText(Name(e.key))
            card.reward:SetText(T("evFindWorth", KH.Number(V:GoodSell(e.key))))
            can = true
            card.button:SetLabel(T("evCollect"))
        end
        card.button:SetStyle(can and "primary" or "quiet")
        card.button:SetEnabledState(can)
        card.outline:SetColor(can and C.accent[1] or 1, can and C.accent[2] or 1, can and C.accent[3] or 1, can and 0.45 or 0.08)
    end
    return s
end

P.builders.visitors = BuildVisitors
