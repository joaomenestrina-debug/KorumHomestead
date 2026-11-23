--[[
    Korum Homestead - achievements (owner, 22/11: "like the achievements of WoW")

    Milestones of every part of the homestead, each with its points. Every one is visible from the start, done or not,
    with what it asks and how far the player is, so the player sees what is missing and how to get it. The last one,
    "Master of the Homestead", asks for every other one.

    What counts is read from the save (the level, the counters of db.stats, the Inn, the dungeons), so an old homestead
    gets what it already did the first time it opens this version, quietly, with one line saying how many.

        Achievements.LIST                 {id, cat, points, goal, value = function() ... end}; the icon is the category's
                                          drawing (Media/Village/ach_<cat>, A11)
        Achievements.CATS                 the categories, in order
        Achievements:Done(id)             when it was done (time()), or nil
        Achievements:Progress(a)          how far, up to a.goal
        Achievements:Check()              marks what is done now; returns the new ones (UI:Tick calls it)
        Achievements:Points() / Count()   points and achievements done, and the totals
]]

local addonName, KH = ...
local A = {}
KH.Achievements = A

local function db() return KH.db end
local function Stat(key) return (db().stats or {})[key] or 0 end
local function Dg() return db().dungeons or {} end
local function Keys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function Village() return KH.Village end
local function MaxLevel() return KH.Balance.VILLAGE_MAX_LEVEL end

-- the buildings at a level or more
local function Built(level)
    local n = 0
    for _, id in ipairs(Village().BUILDINGS) do
        if Village():Level(id) >= level then n = n + 1 end
    end
    return n
end

-- the followers found that pass a test
local function Followers(test)
    local n = 0
    for _, id in ipairs(KH.Inn:List()) do
        local f = db().followers[id]
        if f and test(f, id) then n = n + 1 end
    end
    return n
end
local QUALITY = {uncommon = 1, rare = 2, epic = 3, legendary = 4}
local function AtLeast(q) return function(f) return (QUALITY[f.quality] or 0) >= QUALITY[q] end end

local function DungeonCount()
    local n = 0
    for _, d in ipairs(KH.Balance.DUNGEONS) do if not d.raid then n = n + 1 end end
    return n
end
local function DungeonsDone()
    local n = 0
    for _, d in ipairs(KH.Balance.DUNGEONS) do
        if not d.raid and ((Dg().done or {})[d.id] or 0) > 0 then n = n + 1 end
    end
    return n
end

local function NamedPiece()
    for _, gid in ipairs({"quelserrar", "onyxcloak"}) do
        if Village():Good(gid) > 0 then return 1 end
    end
    return Followers(function(f)
        for _, gid in pairs(f.gear or {}) do if gid == "quelserrar" or gid == "onyxcloak" then return true end end
        return false
    end) > 0 and 1 or 0
end

local function Workers()
    local n = 0
    for _, place in ipairs(KH.Balance.JOBS.order) do if KH.Inn:Worker(place) then n = n + 1 end end
    return n
end

A.CATS = {"village", "garden", "buildings", "market", "workshop", "followers", "dungeons", "visitors", "final"}

A.LIST = {
    -- the Village
    {id = "village10", cat = "village", points = 10, goal = 10, value = function() return db().level end},
    {id = "village20", cat = "village", points = 10, goal = 20, value = function() return db().level end},
    {id = "village30", cat = "village", points = 25, goal = 30, value = function() return db().level end},
    {id = "village45", cat = "village", points = 25, goal = 45, value = function() return db().level end},
    {id = "village60", cat = "village", points = 50, goal = 60, value = function() return db().level end},
    {id = "lotus1", cat = "village", points = 25, goal = 1, value = function() return db().daily.rare or 0 end},
    {id = "lotus10", cat = "village", points = 50, goal = 10, value = function() return db().daily.rare or 0 end},
    -- the Garden
    {id = "harvest100", cat = "garden", points = 10, goal = 100, value = function() return Stat("harvested") end},
    {id = "harvest1k", cat = "garden", points = 10, goal = 1000, value = function() return Stat("harvested") end},
    {id = "harvest10k", cat = "garden", points = 25, goal = 10000, value = function() return Stat("harvested") end},
    {id = "harvest100k", cat = "garden", points = 50, goal = 100000, value = function() return Stat("harvested") end},
    {id = "plots", cat = "garden", points = 25, goal = 8, value = function() return db().nplots or 0 end},
    -- the buildings
    {id = "buildAll", cat = "buildings", points = 10, goal = 8, value = function() return Built(1) end},
    {id = "buildMax", cat = "buildings", points = 25, goal = 1, value = function() return Built(MaxLevel()) end},
    {id = "innMax", cat = "buildings", points = 25, goal = 7, value = function() return Village():Level("inn") end},
    {id = "buildMaxAll", cat = "buildings", points = 50, goal = 8, value = function() return Built(MaxLevel()) end},
    -- the Market: coins, orders and the order of the day
    {id = "earn10k", cat = "market", points = 10, goal = 10000, value = function() return Stat("earned") end},
    {id = "earn100k", cat = "market", points = 10, goal = 100000, value = function() return Stat("earned") end},
    {id = "earn1m", cat = "market", points = 25, goal = 1000000, value = function() return Stat("earned") end},
    {id = "earn10m", cat = "market", points = 50, goal = 10000000, value = function() return Stat("earned") end},
    {id = "orders10", cat = "market", points = 10, goal = 10, value = function() return Stat("delivered") end},
    {id = "orders100", cat = "market", points = 10, goal = 100, value = function() return Stat("delivered") end},
    {id = "orders1k", cat = "market", points = 25, goal = 1000, value = function() return Stat("delivered") end},
    {id = "streak7", cat = "market", points = 10, goal = 7, value = function() return db().daily.best or 0 end},
    {id = "streak30", cat = "market", points = 25, goal = 30, value = function() return db().daily.best or 0 end},
    -- the Workshop
    {id = "craft10", cat = "workshop", points = 10, goal = 10, value = function() return Stat("crafted") end},
    {id = "craft100", cat = "workshop", points = 10, goal = 100, value = function() return Stat("crafted") end},
    {id = "craft1k", cat = "workshop", points = 25, goal = 1000, value = function() return Stat("crafted") end},
    {id = "geared", cat = "workshop", points = 10, goal = 1, value = function()
        return Followers(function(f) return f.gear and f.gear.weapon and f.gear.armor and true or false end) end},
    {id = "named", cat = "workshop", points = 25, goal = 1, value = NamedPiece},
    -- the followers
    {id = "found7", cat = "followers", points = 10, goal = 7, value = function() return KH.Inn:Count() end},
    {id = "found12", cat = "followers", points = 25, goal = 12, value = function() return KH.Inn:Count() end},
    {id = "found18", cat = "followers", points = 50, goal = 18, value = function() return KH.Inn:Count() end},
    {id = "level10", cat = "followers", points = 10, goal = 1, value = function()
        return Followers(function(f) return f.level >= 10 end) end},
    {id = "level30", cat = "followers", points = 25, goal = 1, value = function()
        return Followers(function(f) return f.level >= KH.Balance.FOLLOWER.maxLevel end) end},
    {id = "allLevel30", cat = "followers", points = 50, goal = 18, value = function()
        return Followers(function(f) return f.level >= KH.Balance.FOLLOWER.maxLevel end) end},
    {id = "rare", cat = "followers", points = 10, goal = 1, value = function() return Followers(AtLeast("rare")) end},
    {id = "epic", cat = "followers", points = 25, goal = 1, value = function() return Followers(AtLeast("epic")) end},
    {id = "legendary", cat = "followers", points = 50, goal = 1, value = function() return Followers(AtLeast("legendary")) end},
    {id = "mastery", cat = "followers", points = 25, goal = 1, value = function()
        return Followers(function(f) return f.mastery ~= nil end) end},
    {id = "masteryAll", cat = "followers", points = 50, goal = 18, value = function()
        return Followers(function(f) return f.mastery ~= nil end) end},
    {id = "workers", cat = "followers", points = 10, goal = 5, value = Workers},
    -- the dungeons
    {id = "runs1", cat = "dungeons", points = 10, goal = 1, value = function() return Dg().runs or 0 end},
    {id = "runs10", cat = "dungeons", points = 10, goal = 10, value = function() return Dg().runs or 0 end},
    {id = "runs100", cat = "dungeons", points = 25, goal = 100, value = function() return Dg().runs or 0 end},
    {id = "runs500", cat = "dungeons", points = 50, goal = 500, value = function() return Dg().runs or 0 end},
    {id = "everyDungeon", cat = "dungeons", points = 50, goal = DungeonCount, value = DungeonsDone},
    {id = "onyxia1", cat = "dungeons", points = 25, goal = 1, value = function() return (Dg().done or {}).onyxia or 0 end},
    {id = "onyxia10", cat = "dungeons", points = 50, goal = 10, value = function() return (Dg().done or {}).onyxia or 0 end},
    {id = "combos", cat = "dungeons", points = 25, goal = function() return #KH.Balance.COMBOS end,
        value = function() return Keys(Dg().combos) end},
    {id = "trophies", cat = "dungeons", points = 50, goal = function() return Keys(KH.Balance.TROPHIES) end,
        value = function()
            local n = 0
            for id in pairs(KH.Balance.TROPHIES) do if ((Dg().trophies or {})[id] or 0) > 0 then n = n + 1 end end
            return n
        end},
    -- the visitors and the calls
    {id = "visitors10", cat = "visitors", points = 10, goal = 10, value = function() return (db().events or {}).done or 0 end},
    {id = "visitors100", cat = "visitors", points = 25, goal = 100, value = function() return (db().events or {}).done or 0 end},
    {id = "calls10", cat = "visitors", points = 25, goal = 10, value = function() return Dg().calls or 0 end},
    -- the last one: everything
    {id = "master", cat = "final", points = 100, goal = function() return #A.LIST - 1 end,
        value = function()
            local n = 0
            for _, a in ipairs(A.LIST) do if a.id ~= "master" and A:Done(a.id) then n = n + 1 end end
            return n
        end},
}

local BY = {}
for _, a in ipairs(A.LIST) do BY[a.id] = a end
function A.Get(id) return BY[id] end

local function Store()
    local d = db()
    d.achievements = d.achievements or {}
    return d.achievements
end

function A.Goal(a) return type(a.goal) == "function" and a.goal() or a.goal end

function A:Done(id) return Store()[id] end

function A:Progress(a)
    local ok, v = pcall(a.value)
    return math.min(A.Goal(a), ok and tonumber(v) or 0)
end

-- marks what is done now, the last one after the others; returns the ids of the new ones
function A:Check()
    local new = {}
    local store = Store()
    for pass = 1, 2 do
        for _, a in ipairs(A.LIST) do
            if not store[a.id] and (a.id == "master") == (pass == 2) and self:Progress(a) >= A.Goal(a) then
                store[a.id] = KH.Now()
                new[#new + 1] = a.id
            end
        end
    end
    return new
end

function A:Points()
    local have, total = 0, 0
    for _, a in ipairs(A.LIST) do
        total = total + a.points
        if self:Done(a.id) then have = have + a.points end
    end
    return have, total
end

function A:Count(cat)
    local have, total = 0, 0
    for _, a in ipairs(A.LIST) do
        if not cat or a.cat == cat then
            total = total + 1
            if self:Done(a.id) then have = have + 1 end
        end
    end
    return have, total
end
