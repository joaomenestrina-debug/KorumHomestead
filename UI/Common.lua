--[[
    Korum Homestead - the window

    One quiet window, four words at the top: Garden, Barn, Orders, Settings. Every screen opens with one large sentence
    that says where things stand and a smaller one that says what to do next; there is one filled button per screen, the
    thing most likely wanted now. The coins and the Herbalism level stay in the header on every screen.

    The garden is the whole game in one gesture: click a plot. An empty plot plants the chosen seed, a ready one is
    harvested, the next locked one is bought. The first time, the sentences walk the player through plant, wait, harvest
    and sell, and then get out of the way.

    Everything is done with the mouse; the slash commands are only shortcuts. The window refreshes every second while it
    is open, so the rings move.
]]

local addonName, KH = ...
local UI = {}
KH.UI = UI
local Kit = KH.Kit
local C = Kit.COLORS
local D = KH.Data
local T = function(...) return KH.T(...) end

local WIDTH, HEIGHT = 720, 600
local WHITE = "|cfff5f5fa"

local function Reason(why)
    return T("why_" .. tostring(why))
end

-- a quiet line at the top right that fades by itself: what just happened, or why something could not be done
local function Notice(text)
    UI.msg = text or ""
    if UI.win then UI.win:Notice(text) end
end

-- every screen starts the same way: one large sentence, one smaller
local function Screen(win, place)
    local s = {frame = CreateFrame("Frame", nil, win.content), place = place}
    s.frame:SetAllPoints(win.content)
    s.frame:Hide()
    s.width, s.height = win.contentWidth, win.contentHeight
    -- a screen of a place opens with the drawing of the place, so the player sees where they are
    local left = 0
    if place then
        left = 70
        s.art = s.frame:CreateTexture(nil, "ARTWORK")
        s.art:SetSize(60, 60)
        s.art:SetPoint("TOPLEFT", 0, 2)
    end
    s.head = Kit.Text(s.frame, 22, C.text)
    s.head:SetPoint("TOPLEFT", left, 0)
    s.head:SetWidth(s.width - left)
    s.head:SetWordWrap(false)
    s.sub = Kit.Text(s.frame, 12, C.textSoft)
    s.sub:SetPoint("TOPLEFT", left, -32)
    s.sub:SetWidth(s.width - left)
    s.sub:SetWordWrap(false)
    return s
end

local function GoodTex(id)
    local item = KH.Village.ITEM[id]
    if item then return D.Icon(item) end
    return "Interface\\AddOns\\KorumHomestead\\Media\\Village\\" .. id
end

local function SetIcon(texture, id)
    texture:SetTexture(D.Icon(id))
end

-- ----------------------------------------------------------------------------
-- The first steps: plant, wait, harvest, sell. Told by what the homestead has done, so it never asks twice.
-- ----------------------------------------------------------------------------
function UI:Step()
    local db = KH.db
    db.tutorial = db.tutorial or {done = false}
    if db.tutorial.done then return nil end
    if db.stats.harvested == 0 then
        local growing = false
        for i = 1, db.nplots do
            local status = KH.Farm:Status(i)
            if status == "ready" then return "harvest" end
            if status == "growing" then growing = true end
        end
        return growing and "wait" or "plant"
    end
    if db.stats.earned == 0 then return "sell" end
    db.tutorial.done = true
    return nil
end


local V = KH.Village
local VDIR = "Interface\\AddOns\\KorumHomestead\\Media\\Village\\"
local function Tier(level)
    return level <= 2 and 1 or (level <= 4 and 2 or 3)
end
UI.Tier = Tier

local function BuildingArt(id, level)
    level = level or V:Level(id)
    if level == 0 then return VDIR .. "lot" end
    return VDIR .. id .. Tier(level)
end

local function BuildingName(id)
    return T("b_" .. id)
end
local function Tip(owner, title, lines)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(title, 1, 1, 1)
    for _, line in ipairs(lines) do GameTooltip:AddLine(line, 0.66, 0.68, 0.72, true) end
    GameTooltip:Show()
end
local P = {
    Kit = Kit, C = C, D = D, V = V, T = T, WIDTH = WIDTH, HEIGHT = HEIGHT, WHITE = WHITE, VDIR = VDIR,
    Reason = Reason, Notice = Notice, Screen = Screen, GoodTex = GoodTex, SetIcon = SetIcon,
    Tier = Tier, BuildingArt = BuildingArt, BuildingName = BuildingName, Tip = Tip, builders = {},
}
UI.P = P
