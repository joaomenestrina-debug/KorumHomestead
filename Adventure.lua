--[[
    Korum Homestead - the village follows the adventure of the character (docs/masmorras.md §12)

    The village stays a world of its own: it never changes anything on the character. It only reads what the game tells
    and reacts:

        joining a queue (dungeon or battleground)   the village opens, at most once every B.ADVENTURE.queueGap seconds
                                                    (never in a fight)
        killing a boss of a dungeon                 the followers are inspired there: +B.DUNGEON.inspired chance for the
                                                    next B.DUNGEON.inspiredRuns runs; killing again renews, never adds up;
                                                    the dungeon gets the "You were here" mark
        killing a raid boss                         an Epic insignia, once a week per raid

    The setting "The village follows your adventure" turns all of it off. The times are kept in the save of the account
    (adventure.lastQueue, adventure.raidAt), by the clock, so a /reload changes nothing.

        Adventure:On()                  the setting
        Adventure:Queued()              true while the character waits in a queue
        Adventure:OnQueue()             the queue changed (opens the village when a wait starts)
        Adventure:OnBoss(success)       a boss fight ended in the current instance
        Adventure:CurrentDungeon()      the id of the dungeon the character is in, or nil
]]

local addonName, KH = ...
local B = KH.Balance

local A = {}
KH.Adventure = A

B.ADVENTURE = {queueGap = 600, bossGap = 60}

local function Save()
    local db = KH.db
    db.adventure = db.adventure or {}
    local a = db.adventure
    if a.on == nil then a.on = true end
    a.inspired = a.inspired or {}
    a.visited = a.visited or {}
    a.raidAt = a.raidAt or {}
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

local waiting = false
function A:OnQueue()
    local now = self:Queued()
    local started = now and not waiting
    waiting = now
    if not started or not self:On() then return false end
    local a = Save()
    if KH.Now() - (a.lastQueue or 0) < B.ADVENTURE.queueGap then return false end
    if _G.InCombatLockdown and InCombatLockdown() then return false end
    a.lastQueue = KH.Now()
    if KH.UI and not (KH.UI.frame and KH.UI.frame:IsShown()) then KH.UI:Show("village") end
    return true
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
            KH:Notify(KH.T("advRaid"))
        end
    else
        KH:Notify(KH.T("advInspired", KH.T("dg_" .. id)))
    end
    return id
end

KH:On("LFG_UPDATE", function() A:OnQueue() end)
KH:On("LFG_QUEUE_STATUS_UPDATE", function() A:OnQueue() end)
KH:On("UPDATE_BATTLEFIELD_STATUS", function() A:OnQueue() end)
KH:On("ENCOUNTER_END", function(_, _, _, _, _, success) A:OnBoss(success == 1 or success == true) end)
KH:On("BOSS_KILL", function() A:OnBoss(true) end)
KH:On("PLAYER_LOGIN", function()
    Save()
    waiting = A:Queued()
end)
