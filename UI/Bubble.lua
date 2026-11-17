local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

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

UI.P.Waiting = Waiting
