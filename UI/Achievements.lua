--[[
    Korum Homestead - the achievements screen and the card of a new one (Achievements.lua has the rules)

    The categories on the left; on the right every achievement of the category, done or not: its icon (grey while not
    done), name, what it asks, how far the player is (a bar and "12 / 50"), its points and the day it was done. The
    header says the points and how many are done. A new achievement shows a small card at the top of the screen for a
    few seconds and a line in the chat; the trophy at the top of the window opens this screen.

        UI:AchievementCard(ids)     shows the card of the new ones (one at a time)
]]

local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, T = P.Kit, P.C, P.D, P.T
local Screen, Tip = P.Screen, P.Tip

local ICONS = "Interface\\Icons\\"
local TOP = 66
local CAT_W, CAT_H = 140, 30
local ROW_H, ROWS = 54, 6
UI.achCat = "village"
UI.achPage = 1

local function Icon(a)
    if type(a.icon) == "number" then return D.Icon(a.icon) end
    return ICONS .. a.icon
end

local function Day(t)
    return date and date(KH.Lang() == "ptBR" and "%d/%m/%Y" or "%m/%d/%Y", t) or ""
end

local function BuildAchievements(win)
    local s = Screen(win)
    local W = s.width
    local A = KH.Achievements
    local LIST_X = CAT_W + 16
    local LIST_W = W - LIST_X

    s.cats = {}
    for i, cat in ipairs(A.CATS) do
        local b = Kit.Button(s.frame, CAT_W, CAT_H - 4, "", function() UI.achCat, UI.achPage = cat, 1; UI:Refresh() end)
        b:SetPoint("TOPLEFT", 0, -TOP - (i - 1) * CAT_H)
        b.cat = cat
        s.cats[i] = b
    end

    s.rows = {}
    for i = 1, ROWS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(LIST_W, ROW_H - 4)
        row:SetPoint("TOPLEFT", LIST_X, -TOP - (i - 1) * ROW_H)
        row.surface, row.outline = Kit.Rounded(row, 10, 1, 1, 1, 0.045, 0.06)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(36, 36)
        row.icon:SetPoint("LEFT", 8, 0)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 54, -6)
        row.name:SetWidth(LIST_W - 54 - 110)
        row.name:SetWordWrap(false)
        row.desc = Kit.Text(row, 10, C.textSoft)
        row.desc:SetPoint("TOPLEFT", 54, -24)
        row.desc:SetWidth(LIST_W - 54 - 110)
        row.desc:SetWordWrap(false)
        row.pts = Kit.Text(row, 14, C.gold, "RIGHT")
        row.pts:SetPoint("TOPRIGHT", -12, -7)
        row.pts:SetWidth(90)
        row.state = Kit.Text(row, 10, C.textSoft, "RIGHT")
        row.state:SetPoint("BOTTOMRIGHT", -12, 8)
        row.state:SetWidth(150)
        row.state:SetWordWrap(false)
        row.bar = Kit.Bar(row, LIST_W - 54 - 170, 3)
        row.bar:SetPoint("BOTTOMLEFT", 54, 7)
        s.rows[i] = row
    end
    s.prev = Kit.Button(s.frame, 32, 28, "<", function() UI.achPage = math.max(1, UI.achPage - 1); UI:Refresh() end)
    s.prev:SetPoint("BOTTOMLEFT", LIST_X, 4)
    s.next = Kit.Button(s.frame, 32, 28, ">", function() UI.achPage = UI.achPage + 1; UI:Refresh() end)
    s.next:SetPoint("BOTTOMLEFT", LIST_X + 38, 4)
    s.page = Kit.Text(s.frame, 11, C.textSoft)
    s.page:SetPoint("BOTTOMLEFT", LIST_X + 80, 12)

    function s:Refresh()
        A:Check()
        local have, total = A:Points()
        local done, all = A:Count()
        self.head:SetText(T("achH"))
        self.sub:SetText(T("achS", done, all, have, total))
        for _, b in ipairs(self.cats) do
            local d, t = A:Count(b.cat)
            b:SetLabel(T("achCat_" .. b.cat) .. "  " .. d .. "/" .. t)
            b:SetStyle(b.cat == UI.achCat and "primary" or "quiet")
        end
        local list = {}
        for _, a in ipairs(A.LIST) do if a.cat == UI.achCat then list[#list + 1] = a end end
        local pages = math.max(1, math.ceil(#list / ROWS))
        if UI.achPage > pages then UI.achPage = pages end
        local first = (UI.achPage - 1) * ROWS
        for i, row in ipairs(self.rows) do
            local a = list[first + i]
            row:SetShown(a ~= nil)
            if a then
                local when = A:Done(a.id)
                local goal, now = A.Goal(a), A:Progress(a)
                row.icon:SetTexture(Icon(a))
                if row.icon.SetDesaturated then row.icon:SetDesaturated(not when) end
                row.icon:SetAlpha(when and 1 or 0.55)
                Kit.Fit(row.name, (when and "|cffffd24d" or "") .. T("ach_" .. a.id) .. (when and "|r" or ""), LIST_W - 164, 9)
                Kit.Fit(row.desc, T("achd_" .. a.id, KH.Number(goal)), LIST_W - 164, 8)
                row.pts:SetText(T("achPts", a.points))
                row.pts:SetAlpha(when and 1 or 0.5)
                if when then
                    row.state:SetText("|cff59d973" .. Day(when) .. "|r")
                    row.bar:Hide()
                else
                    Kit.Fit(row.state, goal > 1 and (KH.Number(now) .. " / " .. KH.Number(goal)) or T("achNotYet"), 150, 8)
                    row.bar:SetShown(goal > 1)
                    row.bar:Set(now / goal)
                end
                local lit = when and 0.35 or 0.06
                row.outline:SetColor(when and C.gold[1] or 1, when and C.gold[2] or 1, when and C.gold[3] or 1, lit)
            end
        end
        self.prev:SetShown(pages > 1); self.next:SetShown(pages > 1)
        self.page:SetText(pages > 1 and (UI.achPage .. " / " .. pages) or "")
        self.prev:SetEnabledState(UI.achPage > 1)
        self.next:SetEnabledState(UI.achPage < pages)
    end
    return s
end

P.builders.achievements = BuildAchievements

-- ----------------------------------------------------------------------------
-- The card of a new achievement: at the top of the screen, a few seconds, one after the other
-- ----------------------------------------------------------------------------
local card
local waiting = {}
local HOLD = 6

local function Next()
    local id = table.remove(waiting, 1)
    if not id then card:Hide(); return end
    local a = KH.Achievements.Get(id)
    card.id = id
    card.icon:SetTexture(Icon(a))
    card.title:SetText(T("achNew"))
    Kit.Fit(card.name, T("ach_" .. id), 250, 9)
    card.pts:SetText(T("achPts", a.points))
    card.left = HOLD
    card:Show()
end

local function Build()
    card = CreateFrame("Button", "KorumHomesteadAchievement", UIParent)
    card:SetSize(340, 64)
    card:SetPoint("TOP", UIParent, "TOP", 0, -120)
    if card.SetFrameStrata then card:SetFrameStrata("DIALOG") end
    card.surface, card.outline = Kit.Rounded(card, 10, 0.07, 0.085, 0.095, 0.97, 0.18)
    card.outline:SetColor(C.gold[1], C.gold[2], C.gold[3], 0.6)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(40, 40)
    card.icon:SetPoint("LEFT", 12, 0)
    card.title = Kit.Text(card, 10, C.gold)
    card.title:SetPoint("TOPLEFT", 62, -12)
    card.name = Kit.Text(card, 13, C.text)
    card.name:SetPoint("TOPLEFT", 62, -30)
    card.name:SetWidth(250)
    card.name:SetWordWrap(false)
    card.pts = Kit.Text(card, 14, C.gold, "RIGHT")
    card.pts:SetPoint("RIGHT", -14, 0)
    card:SetScript("OnClick", function()
        card:Hide()
        local a = card.id and KH.Achievements.Get(card.id)
        if a then UI.achCat, UI.achPage = a.cat, 1 end
        UI:Show("achievements")
    end)
    card:SetScript("OnUpdate", function(_, elapsed)
        card.left = (card.left or 0) - (elapsed or 0)
        if card.left <= 0 then Next() end
    end)
    card:Hide()
end

function UI:AchievementCard(ids)
    if not card then Build() end
    for _, id in ipairs(ids) do
        waiting[#waiting + 1] = id
        if KH.db.alerts then KH:Notify(T("achChat", T("ach_" .. id), KH.Achievements.Get(id).points)) end
    end
    if not card:IsShown() then Next() end
end
