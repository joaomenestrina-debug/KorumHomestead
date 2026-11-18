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
    -- Starting coins and plot count are supplied by Balance.lua before ADDON_LOADED.
    xp = 0,
    level = 1,             -- the level of the Village, 1..60 (until 2.0 it was "Herbalism" 1..20: Migrate.lua schema 3)
    capXP = 0,             -- xp earned at the cap; every B.HERBALISM.lotusXP becomes a Black Lotus
    plots = {},            -- [index] = {plant = itemID, at = time planted}
    selected = 2447,       -- the plant "Plant" uses
    crops = {},            -- [itemID] = harvested and not sold
    orders = {},           -- {plant, qty, coins, xp, npc}
    daily = {day = 0, order = nil, done = false, streak = 0, best = 0, lastDone = 0, rare = 0},
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
    bubble = {show = true, label = true},   -- the icon on the screen (label: the alert in words beside it); x, y where it was dragged
    events = {open = {}, nextAt = 0, serial = 0, missed = {}, done = 0},   -- the random events (Events.lua)
    scale = 1,             -- the zoom of the window (0.6 to 1.5), the - % + in its header
    lastSeen = 0,          -- when the window was last seen (Away.lua); 0 = never stamped
    snapshot = nil,        -- the counters at lastSeen: {goods = {...}, buildings = {...}}
    seen = {},             -- the buildings whose "how this works" card was read
    tutorial = {done = false},   -- the first steps shown in the window (plant, wait, harvest, sell); over after the first sale
    newsSeen = 0,          -- the id of the last "What's new" entry seen (News.lua); an older save sees what came after it
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
            local fresh = next(KorumHomesteadDB) == nil
            KH.Migrate(KorumHomesteadDB)            -- the save of an older version first takes the current shape (Migrate.lua)
            Merge(KorumHomesteadDB, KH.defaults)
            if fresh then KorumHomesteadDB.newsSeen = KH.LatestNews() end    -- a new homestead has no old news to read
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

-- The player's local calendar day, as days since 1970-01-01.
function KH.Day(at)
    local today = date("*t", at or KH.Now())
    local year, month, day = today.year, today.month, today.day
    local shift = math.floor((14 - month) / 12)
    year = year + 4800 - shift
    month = month + 12 * shift - 3
    local julian = day + math.floor((153 * month + 2) / 5) + 365 * year + math.floor(year / 4)
        - math.floor(year / 100) + math.floor(year / 400) - 32045
    return julian - 2440588
end

local function DaysInMonth(year, month)
    if month == 2 then
        local leap = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
        return leap and 29 or 28
    end
    if month == 4 or month == 6 or month == 9 or month == 11 then return 30 end
    return 31
end

-- Seconds from the given instant to the next midnight in the player's local time.
function KH.UntilNextDay(at)
    at = at or KH.Now()
    local today = date("*t", at)
    local year, month, day = today.year, today.month, today.day + 1
    if day > DaysInMonth(year, month) then
        day = 1
        month = month + 1
        if month > 12 then year, month = year + 1, 1 end
    end
    local nextMidnight = time({year = year, month = month, day = day, hour = 0, min = 0, sec = 0})
    return nextMidnight - at
end

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
    --@debug@
    -- Only in the copy installed from the repository: the CurseForge packager turns this block into a comment,
    -- so the zip the players download has no debug command at all.
    elseif msg == "debug" then                         -- testing: turns the commands below on and off
        KH.db.debug = not KH.db.debug
        KH:Print("debug " .. (KH.db.debug and "on" or "off"))
    elseif (msg == "evento" or msg == "event") and KH.db.debug then
        local e = KH.Events:Spawn()                    -- a visitor now, without waiting (only with debug on)
        KH:Notify(KH.T("ev_new_" .. e.kind))
        if KH.UI then KH.UI:Refresh() end
    --@end-debug@
    elseif msg == "help" or msg == "ajuda" then
        KH:Print(KH.T("help"))
    elseif KH.UI then
        KH.UI:Toggle()
    end
end
