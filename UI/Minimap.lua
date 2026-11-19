local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local Waiting = P.Waiting
local button
local function PlaceButton()
    if not button then return end
    local angle = math.rad(KH.db.minimap.angle or 215)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

function UI:UpdateBadge()
    local ready, deliverable = Waiting()
    local bubble = UI.bubble
    if button then button.badge:SetText(ready > 0 and tostring(ready) or "") end
    if bubble then
        local n = ready + deliverable + KH.Inn:BackCount()
        bubble.waiting = n > 0
        bubble.badge:SetShown(n > 0)
        bubble.badge.text:SetText(tostring(n))
        UI:UpdateAlert()
    end
end

function UI:ApplyMinimap()
    if not button then return end
    button:SetShown(not KH.db.minimap.hide)
end

function UI:CreateMinimap()
    if button or not Minimap then return end
    local b = CreateFrame("Button", "KorumHomesteadMinimap", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    -- the logo of the village, the same as the icon on the screen: it is round and has its own ring, so no tracking border
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(Kit.LOGO)
    b.hover = b:CreateTexture(nil, "HIGHLIGHT")
    b.hover:SetAllPoints()
    b.hover:SetTexture(Kit.LOGO)
    if b.hover.SetBlendMode then b.hover:SetBlendMode("ADD") end
    b.hover:SetAlpha(0.35)
    b.badge = b:CreateFontString(nil, "OVERLAY")
    b.badge:SetFont(Kit.Font(), 11, "OUTLINE")
    b.badge:SetPoint("BOTTOMRIGHT", 2, -2)
    b.badge:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3])
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            KH.db.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            PlaceButton()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function() UI:Toggle() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(T("tooltipTitle"), 0.4, 0.85, 0.82)
        local n = KH.Farm:ReadyCount()
        GameTooltip:AddLine(n > 0 and T("tooltipReady", n) or T("tooltipNone"), 1, 1, 1)
        GameTooltip:AddLine(T("tooltipClick"), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button = b
    PlaceButton()
    self:ApplyMinimap()
    self:UpdateBadge()
end

-- ----------------------------------------------------------------------------
-- The clock: the rings move, the badge counts, and a plot that finishes is announced once
-- ----------------------------------------------------------------------------
