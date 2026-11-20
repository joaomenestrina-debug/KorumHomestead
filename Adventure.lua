--[[
    Korum Homestead - the village follows the adventure of the character (docs/masmorras.md §12)

    The village stays a world of its own: it never changes anything on the character. It only reads what the game tells
    and reacts:

        joining a queue (dungeon or battleground)   a small card reminds of the village (UI/Reminder.lua: what waits, and
        or taking a flight                          a button to open it), at most once every B.ADVENTURE.queueGap
                                                    seconds for the two together, never in a fight (owner, 20/11: a
                                                    reminder, not the window opening by itself)
        killing a boss of a dungeon                 the followers are inspired there: +B.DUNGEON.inspired chance for the
                                                    next B.DUNGEON.inspiredRuns runs; killing again renews, never adds up;
                                                    the dungeon gets the "You were here" mark
        killing a raid boss                         an Epic insignia, once a week per raid, and more chance of a new
                                                    follower on the next raid of the followers
        staying in a zone of the Forever            after B.ADVENTURE.zoneStay seconds there, in a row, the place is seen
                                                    (once per account, forever): its calls come more often. The place the
                                                    character is in comes first when the next call is drawn, at most once
                                                    every zoneGap seconds per zone and reactGap seconds for all of them.
                                                    Entering a zone never makes an event by itself.

    The setting "The village follows your adventure" turns all of it off. The times are kept in the save of the account
    (adventure.lastQueue, adventure.raidAt), by the clock, so a /reload changes nothing.

        Adventure:On()                  the setting
        Adventure:Queued()              true while the character waits in a queue
        Adventure:OnQueue()             the queue changed (reminds of the village when a wait starts)
        Adventure:Tick()                once a second: a flight that starts reminds of the village
        Adventure:Remind(reason)        "queue" or "flight": the reminder card, when it may show now
        Adventure:OnBoss(success)       a boss fight ended in the current instance
        Adventure:CurrentDungeon()      the id of the dungeon the character is in, or nil
        Adventure:Zone()                the place of the calls whose zone the character is in, or nil
        Adventure:Here()                that place once the character stayed long enough (and marks it seen)
        Adventure:CallPlace()           that place when it may come first in the next call (and stamps the waits)
]]

local addonName, KH = ...
local B = KH.Balance

local A = {}
KH.Adventure = A

B.ADVENTURE = {queueGap = 600, bossGap = 60, zoneStay = 300, zoneGap = 7200, reactGap = 1800}

local function Save()
    local db = KH.db
    db.adventure = db.adventure or {}
    local a = db.adventure
    if a.on == nil then a.on = true end
    a.inspired = a.inspired or {}
    a.visited = a.visited or {}
    a.raidAt = a.raidAt or {}
    a.zones = a.zones or {}
    a.zoneAt = a.zoneAt or {}
    return a
end

function A:On() return Save().on ~= false end

function A:Queued()
    if _G.GetLFGMode then
        for category = 1, 6 do
            local ok, mode = pcall(GetLFGMode, category)
            if ok and (mode == "queued" or mode == "proposal") then return true end
        end
    end
    if _G.GetBattlefieldStatus then
        local max = (_G.GetMaxBattlefieldID and GetMaxBattlefieldID()) or 3
        for i = 1, max do
            local ok, status = pcall(GetBattlefieldStatus, i)
            if ok and status == "queued" then return true end
        end
    end
    return false
end

-- the reminder card, at most once every queueGap seconds (a queue and a flight share the wait), never in a fight
function A:Remind(reason)
    if not self:On() then return false end
    local a = Save()
    if a.remind == false then return false end            -- "don't ask again" on the card; back on in the Settings
    if KH.Now() - (a.lastQueue or 0) < B.ADVENTURE.queueGap then return false end
    if _G.InCombatLockdown and InCombatLockdown() then return false end
    if not (KH.UI and KH.UI.Reminder and KH.UI:Reminder(reason)) then return false end
    a.lastQueue = KH.Now()
    return true
end

local waiting = false
function A:OnQueue()
    local now = self:Queued()
    local started = now and not waiting
    waiting = now
    if not started then return false end
    return self:Remind("queue")
end

-- a flight: the game tells no event for it, so the clock of the window asks once a second
local flying = false
function A:Tick()
    local now = (_G.UnitOnTaxi and UnitOnTaxi("player")) and true or false
    local started = now and not flying
    flying = now
    if started then return self:Remind("flight") end
    return false
end

-- the dungeon of the addon the character is in: by the game's id, or by the name in English or in Portuguese
function A:CurrentDungeon()
    if not _G.GetInstanceInfo then return nil end
    local name, kind, _, _, _, _, _, instanceID = GetInstanceInfo()
    if kind ~= "party" and kind ~= "raid" then return nil end
    if instanceID and B.INSTANCES[instanceID] then return B.INSTANCES[instanceID] end
    if not name then return nil end
    local want = name:lower()
    for _, d in ipairs(B.DUNGEONS) do
        for _, lang in ipairs({"enUS", "ptBR"}) do
            local n = KH.L[lang]["dg_" .. d.id]
            if n and n:lower() == want then return d.id end
        end
    end
    return nil
end

local lastBoss = 0
function A:OnBoss(success)
    if not success or not self:On() then return nil end
    if KH.Now() - lastBoss < B.ADVENTURE.bossGap then return nil end      -- ENCOUNTER_END and BOSS_KILL of the same fight
    local id = self:CurrentDungeon()
    if not id then return nil end
    lastBoss = KH.Now()
    local a = Save()
    local d = KH.Dungeons.Get(id)
    a.inspired[id] = B.DUNGEON.inspiredRuns                -- renews, never adds up
    a.visited[id] = true
    if d.raid then
        if KH.Now() - (a.raidAt[id] or 0) >= B.RAID.every then
            a.raidAt[id] = KH.Now()
            KH.db.dungeons.epic = (KH.db.dungeons.epic or 0) + 1
            a.raidLuck = true                               -- more chance of a new follower on their next raid
            KH:Notify(KH.T("advRaid"))
        end
    else
        KH:Notify(KH.T("advInspired", KH.T("dg_" .. id)))
    end
    return id
end

-- the place of the calls whose zone the character is in: by the name of the zone, in English or in Portuguese
function A:Zone()
    local zone = (_G.GetRealZoneText and GetRealZoneText()) or (_G.GetZoneText and GetZoneText())
    if not zone or zone == "" then return nil end
    local want = zone:lower()
    for _, place in ipairs(B.PLACE_ORDER) do
        for _, lang in ipairs({"enUS", "ptBR"}) do
            local n = KH.L[lang]["zn_" .. place]
            if n and n:lower() == want then return place end
        end
    end
    return nil
end

-- the clock of the stay starts again at every zone and at every loading screen; it is not saved
local stay = {}
function A:OnZone()
    stay.place, stay.since = self:Zone(), KH.Now()
end

function A:Here()
    if not self:On() then return nil end
    local place = self:Zone()
    if place ~= stay.place then stay.place, stay.since = place, KH.Now() end
    if not place or KH.Now() - (stay.since or KH.Now()) < B.ADVENTURE.zoneStay then return nil end
    Save().zones[place] = true
    return place
end

function A:CallPlace()
    local place = self:Here()
    if not place then return nil end
    local a, now = Save(), KH.Now()
    if now - (a.zoneAt[place] or 0) < B.ADVENTURE.zoneGap then return nil end
    if now - (a.lastReact or 0) < B.ADVENTURE.reactGap then return nil end
    a.zoneAt[place], a.lastReact = now, now
    return place
end

KH:On("ZONE_CHANGED_NEW_AREA", function() A:OnZone() end)
KH:On("PLAYER_ENTERING_WORLD", function() A:OnZone() end)
KH:On("LFG_UPDATE", function() A:OnQueue() end)
KH:On("LFG_QUEUE_STATUS_UPDATE", function() A:OnQueue() end)
KH:On("UPDATE_BATTLEFIELD_STATUS", function() A:OnQueue() end)
KH:On("ENCOUNTER_END", function(_, _, _, _, _, success) A:OnBoss(success == 1 or success == true) end)
KH:On("BOSS_KILL", function() A:OnBoss(true) end)
KH:On("PLAYER_LOGIN", function()
    Save()
    waiting = A:Queued()
    flying = (_G.UnitOnTaxi and UnitOnTaxi("player")) and true or false
end)
