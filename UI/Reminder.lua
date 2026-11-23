--[[
    Korum Homestead - the reminder: a small card on the screen when the character takes a flight or joins a queue
    (owner, 20/11; the shape follows the card another addon of his shows at the start of a flight). One question, what
    waits first in the village, "don't ask again" and two buttons: not now, or open. It never opens the window by itself,
    never shows in a fight, and goes away alone after a while. Adventure.lua decides when (at most once every
    B.ADVENTURE.queueGap seconds); "don't ask again" is the setting "Reminder on a flight or in a queue".

        UI:Reminder(reason)     "flight" or "queue": shows the card (nothing when the window is already open)
        UI:HideReminder()
]]

local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, T = P.Kit, P.C, P.T

local WIDTH, HEIGHT, HOLD = 372, 88, 30
local TEXT_W = WIDTH - 50 - 12
local card

local function Close()
    if card.never then
        KH.db.adventure = KH.db.adventure or {}
        KH.db.adventure.remind = false                     -- back on in the Settings
        KH:Print(T("remOff"))
    end
    card:Hide()
end

local function Build()
    card = CreateFrame("Frame", "KorumHomesteadReminder", UIParent)
    card:SetSize(WIDTH, HEIGHT)
    card:SetPoint("TOP", UIParent, "TOP", 0, -170)
    if card.SetFrameStrata then card:SetFrameStrata("DIALOG") end
    card:EnableMouse(true)
    card.surface, card.outline = Kit.Rounded(card, 10, 0.07, 0.085, 0.095, 0.97, 0.18)
    card.logo = card:CreateTexture(nil, "ARTWORK")
    card.logo:SetSize(32, 32)                          -- the Steward asks (A11), or the logo with the voices off
    card.logo:SetPoint("TOPLEFT", 10, -8)
    card.title = Kit.Text(card, 12, C.text)
    card.title:SetPoint("TOPLEFT", 50, -10)
    card.title:SetWidth(TEXT_W)
    card.title:SetWordWrap(false)
    card.sub = Kit.Text(card, 10, C.textSoft)
    card.sub:SetPoint("TOPLEFT", 50, -29)
    card.sub:SetWidth(TEXT_W)
    card.sub:SetWordWrap(false)

    -- "don't ask again": a small box and its words; it counts when the card is answered
    local box = CreateFrame("Button", nil, card)
    box:SetSize(150, 20)
    box:SetPoint("BOTTOMLEFT", 12, 11)
    box.frame = box:CreateTexture(nil, "BACKGROUND")
    box.frame:SetSize(12, 12)
    box.frame:SetPoint("LEFT", 0, 0)
    box.frame:SetColorTexture(1, 1, 1, 0.16)
    box.mark = box:CreateTexture(nil, "ARTWORK")
    box.mark:SetSize(8, 8)
    box.mark:SetPoint("CENTER", box.frame, "CENTER", 0, 0)
    box.mark:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    box.label = Kit.Text(box, 10, C.textSoft)
    box.label:SetPoint("LEFT", 18, 0)
    box.label:SetWidth(132)
    box.label:SetWordWrap(false)
    box:SetScript("OnClick", function()
        Kit.ClickSound()
        card.never = not card.never
        box.mark:SetShown(card.never)
    end)
    card.box = box

    card.open = Kit.Button(card, 76, 24, "", function()
        Close()
        UI:Show(card.view or "village")
    end)
    card.open:SetPoint("BOTTOMRIGHT", -12, 9)
    card.open:SetStyle("primary")
    card.later = Kit.Button(card, 84, 24, "", Close)
    card.later:SetPoint("RIGHT", card.open, "LEFT", -6, 0)
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
    card.logo:SetTexture(KH.VoicesOn() and KH.Portrait("steward") or Kit.LOGO)
    Kit.Fit(card.title, T(reason == "flight" and "remFlight" or "remQueue"), TEXT_W)
    local first = lines[1] and lines[1][1]
    if first and #lines > 1 then first = T("remMore", first, #lines - 1) end
    Kit.Fit(card.sub, first and ("|cff40d9c4" .. first .. "|r") or T("remNothing"), TEXT_W)
    card.view = lines[1] and lines[1][2] or "village"       -- the button goes to what waits first
    card.never = false
    card.box.mark:Hide()
    Kit.Fit(card.box.label, T("remNever"), 132)
    card.open:SetLabel(T("remOpen"))
    card.later:SetLabel(T("remLater"))
    card.left = HOLD
    card:Show()
    return true
end

function UI:HideReminder()
    if card then card:Hide() end
end
