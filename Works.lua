--[[
    Korum Homestead - the Workshop and the Inn

    The Workshop turns herbs into potions, one at a time, in a queue that goes on while the game is closed. Each level of the
    Workshop adds a place in the queue and, up to the third, a recipe.

    The Inn shelters the followers (one more per level, six at most). A follower can be sent on a mission: it takes time, costs
    fish for the road, and brings coins and ore back. The more missions a follower has done, the better it pays.

        Workshop:Slots() / Workshop:Unlocked(recipeId) / Workshop:CanCraft(recipeId)
        Workshop.Shown(trade)           the 3 recipes the Workshop screen shows for a trade
        Workshop:Offered(recipeId)      open and on the screen: the only items orders and visitors ask for
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
local B = KH.Balance

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
W.RECIPES = B.RECIPES

-- what one item is worth and the xp of crafting it (Balance.lua B.CRAFT): always more than its raw materials
local function InputValue(key)
    if type(key) == "string" then return KH.Village:GoodSell(key) end
    return D.Plant(key).sell
end
local function InputXP(key)
    if type(key) == "string" then return B.CRAFT.goodXP end
    local p = D.Plant(key)
    return p.xp / p.yield
end
function W.Value(id)
    local r = W.Recipe(id)
    local sum = 0
    for _, input in ipairs(r.inputs) do sum = sum + InputValue(input[1]) * input[2] end
    return B.Round(B.CRAFT.markup * sum + B.CRAFT.perMinute * r.time / 60)
end
function W.XP(id)
    local r = W.Recipe(id)
    local sum = 0
    for _, input in ipairs(r.inputs) do sum = sum + InputXP(input[1]) * input[2] end
    return math.max(1, B.Round(B.CRAFT.xpFactor * sum + B.CRAFT.xpPerMinute * r.time / 60))
end

-- the recipes of one trade, in order
function W.OfTrade(trade)
    local out = {}
    for _, r in ipairs(W.RECIPES) do
        if r.trade == trade then out[#out + 1] = r end
    end
    return out
end

-- 7 recipes a trade, 3 rows on the screen: the two best already open and the next one to come
W.ROWS = 3
function W.Shown(trade, level)
    local recipes = W.OfTrade(trade)
    level = level or V:Level("workshop")
    local open = 0
    for i, r in ipairs(recipes) do if r.level <= level then open = i end end
    local from = math.max(1, math.min(#recipes - W.ROWS + 1, open - (W.ROWS - 2)))
    local out = {}
    for i = from, math.min(#recipes, from + W.ROWS - 1) do out[#out + 1] = recipes[i] end
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

-- places in the queue at this Workshop level (or the one it has)
function W.QueueAt(level)
    if level <= 0 then return 0 end
    return B.CRAFT.queueBase + (level - 1) * B.CRAFT.queuePerLevel
end
function W:Slots() return W.QueueAt(V:Level("workshop")) end

function W:Unlocked(id)
    local r = W.Recipe(id)
    return r ~= nil and V:Level("workshop") >= r.level
end

-- what orders and visitors may ask for: an item the player sees on the Workshop screen and can make there (an old
-- recipe that left the screen is not asked for: the player would not find it)
function W:Offered(id)
    local r = W.Recipe(id)
    if not r or not self:Unlocked(id) then return false end
    for _, shown in ipairs(W.Shown(r.trade)) do
        if shown.id == id then return true end
    end
    return false
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
        KH.Farm:AddXP(W.XP(job.recipe))             -- the Workshop gives xp (more than the herbs it used)
    end
    return done
end

-- ----------------------------------------------------------------------------
-- The Inn
-- ----------------------------------------------------------------------------
I.NAMES = {"Mira", "Tobin", "Elda", "Garrick", "Sela", "Bram"}
I.MAX = B.INN.maxFollowers
I.MISSIONS = B.MISSIONS

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

-- follower progression uses the cap and mission interval in Balance.lua
function I:Level(i)
    return math.min(B.INN.maxLevel, 1 + math.floor(self:Follower(i).done / B.INN.missionsPerLevel))
end

function I:Pay(i, mission)
    return math.floor(mission.coins * (1 + B.INN.payBonusPerLevel * (self:Level(i) - 1)))
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
