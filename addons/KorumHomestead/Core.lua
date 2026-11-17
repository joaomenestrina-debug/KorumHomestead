--[[
    Korum Homestead - core

    A small idle farm for the moments of waiting in the game: plant herbs, come back, harvest, sell, fill orders and
    level up the Herbalism of the homestead. Independent: it uses nothing from other addons.

    Growing happens by the clock (time()), so the plants keep growing while the game is closed; nothing rots or dies.
    The homestead belongs to the account: every character harvests in the same one. Its coins are its own, they have
    nothing to do with the gold of the game.
]]

local addonName, KH = ...
_G.KorumHomestead = KH
-- the version is the one of the .toc, so a release only changes it there
local Meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
KH.version = (Meta and Meta(addonName, "Version")) or "1.0.0"

KH.defaults = {
    coins = 40,
    xp = 0,
    level = 1,
    plots = {},            -- [index] = {plant = itemID, at = time planted}
    nplots = 2,            -- plots owned
    selected = 2447,       -- the plant "Plant" uses
    crops = {},            -- [itemID] = harvested and not sold
    orders = {},           -- {plant, qty, coins, xp, npc}
    stats = {harvested = 0, earned = 0, delivered = 0},
    lang = "auto",         -- auto | enUS | ptBR
    alerts = true,         -- a line in the chat when a plot becomes ready
    welcome = true,        -- the line when logging in with plots ready
    minimap = {angle = 215, hide = false},
    buildings = {},        -- hall, garden, barn, market -> level (Village.lua fills what is missing)
    queue = {},            -- the Workshop's work: {recipe, at, time}
    followers = {},        -- the Inn's: {done = missions made, mission = {kind, at, time}}
    goods = {},            -- ore, fish: what the Mine and the Pond made and was not sold or used
    made = {},             -- mine, pond -> the time up to which their production was counted
    work = nil,            -- the building being built: {id, at, time}
    bubble = {show = true},      -- the icon on the screen; x, y where the player dragged it
    seen = {},             -- the buildings whose "how this works" card was read
    tutorial = {done = false},   -- the first steps shown in the window (plant, wait, harvest, sell); over after the first sale
}

local function Merge(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                dst[k] = {}
                Merge(dst[k], v)
            else
                dst[k] = v
            end
        elseif type(v) == "table" and type(dst[k]) == "table" then
            Merge(dst[k], v)
        end
    end
end

-- ----------------------------------------------------------------------------
-- Events
-- ----------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}
KH.frame = frame

function KH:On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        pcall(frame.RegisterEvent, frame, event)
    end
    table.insert(handlers[event], fn)
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if (...) == addonName then
            KorumHomesteadDB = KorumHomesteadDB or {}
            Merge(KorumHomesteadDB, KH.defaults)
            KH.db = KorumHomesteadDB
        end
        return
    end
    for _, fn in ipairs(handlers[event] or {}) do
        local ok, err = pcall(fn, event, ...)
        if not ok then print("|cffff5555Korum Homestead (error)|r: " .. tostring(err)) end
    end
end)
frame:RegisterEvent("ADDON_LOADED")

function KH.After(seconds, fn)
    if C_Timer and C_Timer.After then C_Timer.After(seconds, fn) else fn() end
end

function KH.Now() return time() end

-- Something the homestead has to tell: on its icon on the screen, or in the chat when the icon is hidden
function KH:Notify(msg)
    if KH.UI and KH.UI.Toast and KH.UI:Toast(msg) then return end
    self:Print(msg)
end

function KH:Print(msg)
    print("|cff40d9c4Korum Homestead|r: " .. tostring(msg))
end

-- ----------------------------------------------------------------------------
-- Slash commands (the window does everything; these are shortcuts)
-- ----------------------------------------------------------------------------
SLASH_KORUMHOMESTEAD1 = "/kh"
SLASH_KORUMHOMESTEAD2 = "/homestead"
SlashCmdList["KORUMHOMESTEAD"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "harvest" or msg == "colher" then
        local n = KH.Farm:HarvestAll()
        KH:Print(KH.T("harvestedN", n))
        if KH.UI then KH.UI:Refresh() end
    elseif msg == "help" or msg == "ajuda" then
        KH:Print(KH.T("help"))
    elseif KH.UI then
        KH.UI:Toggle()
    end
end
