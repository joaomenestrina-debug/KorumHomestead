--[[
    Korum Homestead - the reminder: a small card on the screen when the character takes a flight or joins a queue
    (owner, 20/11). It says what waits in the village now and has two buttons: open the village, or not now. It never
    opens the window by itself, never shows in a fight, and goes away alone after a while. Adventure.lua decides when
    (at most once every B.ADVENTURE.queueGap seconds; the setting "The village follows your adventure" turns it off).

        UI:Reminder(reason)     "flight" or "queue": shows the card (nothing when the window is already open)
        UI:HideReminder()
]]

local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, T = P.Kit, P.C, P.T

local WIDTH, LINES, HOLD = 340, 3, 30
local card

local function Build()
    card = CreateFrame("Frame", "KorumHomesteadReminder", UIParent)
    card:SetSize(WIDTH, 170)
    card:SetPoint("TOP", UIParent, "TOP", 0, -150)
    if card.SetFrameStrata then card:SetFrameStrata("DIALOG") end
    card:EnableMouse(true)
    card.surface, card.outline = Kit.Rounded(card, 14, 0.07, 0.085, 0.095, 0.97, 0.18)
    card.logo = card:CreateTexture(nil, "ARTWORK")
    card.logo:SetSize(22, 22)
    card.logo:SetPoint("TOPLEFT", 14, -12)
    card.logo:SetTexture(Kit.LOGO)
    card.title = Kit.Text(card, 13, C.text)
    card.title:SetPoint("LEFT", card.logo, "RIGHT", 8, 0)
    card.title:SetWidth(WIDTH - 60)
    card.title:SetWordWrap(false)
    card.why = Kit.Text(card, 11, C.textSoft)
    card.why:SetPoint("TOPLEFT", 14, -42)
    card.why:SetWidth(WIDTH - 28)
    card.why:SetWordWrap(false)
    card.lines = {}
    for i = 1, LINES do
        local line = Kit.Text(card, 11, C.accent)
        line:SetPoint("TOPLEFT", 14, -62 - (i - 1) * 17)
        line:SetWidth(WIDTH - 28)
        line:SetWordWrap(false)
        card.lines[i] = line
    end
    card.open = Kit.Button(card, 166, 30, "", function()
        UI:HideReminder()
        UI:Show(card.view or "village")
    end)
    card.open:SetPoint("BOTTOMLEFT", 14, 12)
    card.open:SetStyle("primary")
    card.later = Kit.Button(card, 132, 30, "", function() UI:HideReminder() end)
    card.later:SetPoint("BOTTOMRIGHT", -14, 12)
    card.left = 0
    card:SetScript("OnUpdate", function(self, elapsed)
        self.left = self.left - (tonumber(elapsed) or 0)
        if self.left <= 0 then self:Hide() end
    end)
    card:Hide()
end

function UI:Reminder(reason)
    if self.frame and self.frame:IsShown() then return false end      -- the village is already open
    if not card then Build() end
    local lines = self:AlertLines()
    Kit.Fit(card.title, T("remTitle"), WIDTH - 60)
    Kit.Fit(card.why, T(reason == "flight" and "remFlight" or "remQueue"), WIDTH - 28)
    for i, line in ipairs(card.lines) do
        local l = lines[i]
        if l then
            Kit.Fit(line, l[1], WIDTH - 28)
        elseif i == 1 then
            Kit.Fit(line, "|cffa8adb8" .. T("remNothing") .. "|r", WIDTH - 28)
        else
            line:SetText("")
        end
    end
    local shown = math.max(1, math.min(LINES, #lines))
    card:SetHeight(62 + shown * 17 + 10 + 30 + 12)
    card.view = lines[1] and lines[1][2] or "village"       -- the button goes to what waits first
    card.open:SetLabel(T("remOpen"))
    card.later:SetLabel(T("remLater"))
    card.left = HOLD
    card:Show()
    return true
end

function UI:HideReminder()
    if card then card:Hide() end
end
