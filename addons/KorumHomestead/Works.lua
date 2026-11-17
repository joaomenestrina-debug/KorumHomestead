--[[
    Korum Homestead - the Workshop and the Inn

    The Workshop turns herbs into potions, one at a time, in a queue that goes on while the game is closed. Each level of the
    Workshop adds a place in the queue and, up to the third, a recipe.

    The Inn shelters the followers (one more per level, six at most). A follower can be sent on a mission: it takes time, costs
    fish for the road, and brings coins and ore back. The more missions a follower has done, the better it pays.

        Workshop:Slots() / Workshop:Unlocked(recipeId) / Workshop:CanCraft(recipeId)
        Workshop:Craft(recipeId)        takes the herbs and puts the potion in the queue
        Workshop:Update()               finishes the potions whose time is over; returns {recipeId, ...}

        Inn:Count()                     how many followers there are
        Inn:Status(i)                   "locked" | "idle" | "away" | "back", seconds left, progress 0..1
        Inn:Start(i, kind) / Inn:Collect(i) / Inn:CollectAll()
        Inn:Update()                    returns how many followers just came back
]]

local addonName, KH = ...
local V = KH.Village
local D = KH.Data

local W = {}
KH.Workshop = W
local I = {}
KH.Inn = I

-- ----------------------------------------------------------------------------
-- The Workshop
-- ----------------------------------------------------------------------------
-- Three trades, three recipes each. An input is {herb item id, amount} (from the Barn's herbs) or {"fish" | "ore", amount}
-- (from the Pond and the Mine). Cooking lives on fish, smithing on ore, alchemy on herbs.
W.TRADES = {"alchemy", "cooking", "smithing"}
-- {id, trade, workshop level, seconds, inputs}
W.RECIPES = {
    {id = "heal", trade = "alchemy", level = 1, time = 120, inputs = {{2447, 3}, {765, 1}}},
    {id = "mana", trade = "alchemy", level = 2, time = 300, inputs = {{785, 2}, {2449, 2}}},
    {id = "agil", trade = "alchemy", level = 3, time = 600, inputs = {{2450, 2}, {2453, 2}}},
    {id = "stew", trade = "cooking", level = 1, time = 90, inputs = {{"fish", 4}}},
    {id = "roast", trade = "cooking", level = 3, time = 240, inputs = {{"fish", 10}, {2447, 2}}},
    {id = "feast", trade = "cooking", level = 5, time = 720, inputs = {{"fish", 24}, {785, 2}}},
    {id = "bar", trade = "smithing", level = 2, time = 200, inputs = {{"ore", 6}}},
    {id = "tools", trade = "smithing", level = 4, time = 540, inputs = {{"ore", 16}}},
    {id = "blade", trade = "smithing", level = 6, time = 1500, inputs = {{"ore", 40}, {2450, 1}}},
}

-- the recipes of one trade, in order
function W.OfTrade(trade)
    local out = {}
    for _, r in ipairs(W.RECIPES) do
        if r.trade == trade then out[#out + 1] = r end
    end
    return out
end

-- how many of an input the homestead holds, and taking some away
function W.Stock(key)
    if type(key) == "string" then return KH.Village:Good(key) end
    return KH.db.crops[key] or 0
end

local function Take(key, n)
    local db = KH.db
    if type(key) == "string" then
        db.goods[key] = (db.goods[key] or 0) - n
    else
        local left = (db.crops[key] or 0) - n
        db.crops[key] = left > 0 and left or nil
    end
end

function W.Recipe(id)
    for _, r in ipairs(W.RECIPES) do
        if r.id == id then return r end
    end
end

function W:Slots() return V:Level("workshop") end

function W:Unlocked(id)
    local r = W.Recipe(id)
    return r ~= nil and V:Level("workshop") >= r.level
end

function W:Has(r)
    for _, input in ipairs(r.inputs) do
        if W.Stock(input[1]) < input[2] then return false end
    end
    return true
end

function W:CanCraft(id)
    local r = W.Recipe(id)
    if not r then return false, "noRecipe" end
    if V:Level("workshop") == 0 then return false, "noWorkshop" end
    if V:Level("workshop") < r.level then return false, "recipeLevel", r.level end
    if #KH.db.queue >= self:Slots() then return false, "queueFull" end
    if not self:Has(r) then return false, "herbs" end
    return true
end

function W:Craft(id)
    local ok, why, n = self:CanCraft(id)
    if not ok then return false, why, n end
    local r = W.Recipe(id)
    local db = KH.db
    for _, input in ipairs(r.inputs) do Take(input[1], input[2]) end
    local last = db.queue[#db.queue]
    local at = last and (last.at + last.time) or KH.Now()
    db.queue[#db.queue + 1] = {recipe = id, at = at, time = r.time}
    return true
end

-- the queue as it stands: {{recipe, left, progress}, ...}
function W:Jobs()
    local out = {}
    for i, job in ipairs(KH.db.queue) do
        local left = job.at + job.time - KH.Now()
        out[i] = {recipe = job.recipe, left = math.max(0, left), progress = math.min(1, math.max(0, (KH.Now() - job.at) / job.time))}
    end
    return out
end

function W:Update()
    local db = KH.db
    local done = {}
    while db.queue[1] and KH.Now() >= db.queue[1].at + db.queue[1].time do
        local job = table.remove(db.queue, 1)
        db.goods[job.recipe] = (db.goods[job.recipe] or 0) + 1
        done[#done + 1] = job.recipe
    end
    return done
end

-- ----------------------------------------------------------------------------
-- The Inn
-- ----------------------------------------------------------------------------
I.NAMES = {"Mira", "Tobin", "Elda", "Garrick", "Sela", "Bram"}
I.MAX = 6
-- {id, seconds, fish for the road, coins, ore}
I.MISSIONS = {
    {id = "short", time = 1800, fish = 2, coins = 40, ore = 0},
    {id = "medium", time = 7200, fish = 6, coins = 170, ore = 2},
    {id = "long", time = 28800, fish = 20, coins = 750, ore = 8},
}

function I.Mission(id)
    for _, m in ipairs(I.MISSIONS) do
        if m.id == id then return m end
    end
end

function I:Count() return math.min(I.MAX, V:Level("inn")) end

function I:Follower(i)
    local db = KH.db
    db.followers[i] = db.followers[i] or {done = 0}
    return db.followers[i]
end

-- level 1 to 5: a level for every three missions done
function I:Level(i)
    return math.min(5, 1 + math.floor(self:Follower(i).done / 3))
end

function I:Pay(i, mission)
    return math.floor(mission.coins * (1 + 0.1 * (self:Level(i) - 1)))
end

function I:Status(i)
    if i > self:Count() then return "locked", 0, 0 end
    local f = self:Follower(i)
    if not f.mission then return "idle", 0, 0 end
    local left = f.mission.at + f.mission.time - KH.Now()
    if left <= 0 then return "back", 0, 1 end
    return "away", left, math.min(1, math.max(0, (KH.Now() - f.mission.at) / f.mission.time))
end

function I:Start(i, kind)
    local m = I.Mission(kind)
    if not m then return false, "noMission" end
    if self:Status(i) ~= "idle" then return false, "notIdle" end
    if V:Good("fish") < m.fish then return false, "fish", m.fish end
    KH.db.goods.fish = V:Good("fish") - m.fish
    self:Follower(i).mission = {kind = kind, at = KH.Now(), time = m.time}
    return true
end

function I:Collect(i)
    if self:Status(i) ~= "back" then return 0, 0 end
    local f = self:Follower(i)
    local m = I.Mission(f.mission.kind)
    local coins, ore = self:Pay(i, m), m.ore
    f.mission = nil
    f.done = f.done + 1
    local db = KH.db
    db.coins = db.coins + coins
    db.stats.earned = db.stats.earned + coins
    if ore > 0 then db.goods.ore = V:Good("ore") + ore end
    return coins, ore
end

function I:CollectAll()
    local coins, ore = 0, 0
    for i = 1, self:Count() do
        local c, o = self:Collect(i)
        coins, ore = coins + c, ore + o
    end
    return coins, ore
end

function I:BackCount()
    local n = 0
    for i = 1, self:Count() do
        if self:Status(i) == "back" then n = n + 1 end
    end
    return n
end

function I:AwayCount()
    local n = 0
    for i = 1, self:Count() do
        if self:Status(i) == "away" then n = n + 1 end
    end
    return n
end

-- followers that came back since the last time this was asked
local announced = {}
function I:Update()
    local news = 0
    for i = 1, I.MAX do
        local back = self:Status(i) == "back"
        if back and not announced[i] then news = news + 1 end
        announced[i] = back or nil
    end
    return news
end

KH:On("PLAYER_LOGIN", function()
    W:Update()
    for i = 1, I.MAX do announced[i] = I:Status(i) == "back" or nil end
end)
