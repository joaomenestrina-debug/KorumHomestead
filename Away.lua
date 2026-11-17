--[[
    Korum Homestead - while you were away

    When the window opens after a while closed (B.AWAY.minSeconds), it tells what happened meanwhile: plots ready, what the
    Mine, the Pond and the Workshop made, followers back, buildings finished. One button collects everything there is to
    collect (harvest the plots, bring the followers in).

    The window stamps the moment it was last seen (db.lastSeen) with a picture of the counters (db.snapshot); the summary
    is the difference between that picture and now. A save without a picture (older versions, a new homestead) has no
    summary the first time.

        Away:Mark()                 the window is seen now: stamp the time and the counters
        Away:Summary()              what changed since the stamp, or nil (too soon, no stamp, nothing to tell)
        Away:CollectAll()           harvest the ready plots and collect the followers; returns {harvested, coins, ore, why}
]]

local addonName, KH = ...
local B = KH.Balance
local V = KH.Village

local A = {}
KH.Away = A

-- what can be counted, in the order the summary tells it: what the buildings make, then the Workshop's work
local function GoodsOrder()
    local out = {"ore", "fish"}
    for _, r in ipairs(KH.Workshop.RECIPES) do out[#out + 1] = r.id end
    return out
end

local function Copy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = v end
    return out
end

function A:Mark()
    local db = KH.db
    V:Produce()
    KH.Workshop:Update()
    db.lastSeen = KH.Now()
    db.snapshot = {goods = Copy(db.goods), buildings = Copy(db.buildings)}
end

-- {seconds, ready, back, goods = {{id, n}, ...}, built = {{id, level}, ...}} or nil
function A:Summary()
    local db = KH.db
    local seen, shot = tonumber(db.lastSeen) or 0, db.snapshot
    if seen <= 0 or type(shot) ~= "table" then return nil end
    local seconds = KH.Now() - seen
    if seconds < B.AWAY.minSeconds then return nil end
    -- bring the counters up to now; buildings that finished are told here (the clock will not announce them again)
    V:Update()
    KH.Workshop:Update()
    local out = {seconds = seconds, ready = KH.Farm:ReadyCount(), back = KH.Inn:BackCount(), goods = {}, built = {}}
    local before = shot.goods or {}
    for _, id in ipairs(GoodsOrder()) do
        local n = (db.goods[id] or 0) - (before[id] or 0)
        if n > 0 then out.goods[#out.goods + 1] = {id = id, n = n} end
    end
    local was = shot.buildings or {}
    for _, id in ipairs(V.BUILDINGS) do
        local level = V:Level(id)
        if level > (was[id] or 0) then out.built[#out.built + 1] = {id = id, level = level} end
    end
    if out.ready == 0 and out.back == 0 and #out.goods == 0 and #out.built == 0 then return nil end
    return out
end

-- one click: what is ready comes in
function A:CollectAll()
    local harvested, why = KH.Farm:HarvestAll()
    local coins, ore = KH.Inn:CollectAll()
    return {harvested = harvested, coins = coins, ore = ore, why = why}
end
