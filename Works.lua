--[[
    Korum Homestead - the Workshop

    The Workshop turns herbs into potions, one at a time, in a queue that goes on while the game is closed. Each level of the
    Workshop adds a place in the queue and, up to the third, a recipe.


        Workshop:Slots() / Workshop:Unlocked(recipeId) / Workshop:CanCraft(recipeId)

    Each trade (a tab: alchemy, cooking, smithing, gear) has a queue of its own, with the same number of places, and
    they all run at the same time (owner, 20/11). The save keeps one list, db.queue; a job belongs to the trade of its
    recipe and starts when the job before it in that trade ends.
        Workshop.Shown(trade)           the 3 recipes the Workshop screen shows for a trade
        Workshop:Offered(recipeId)      open and on the screen: the only items orders and visitors ask for
        Workshop:Craft(recipeId)        takes the herbs and puts the potion in the queue
        Workshop:Update()               finishes the potions whose time is over; returns {recipeId, ...}

]]

local addonName, KH = ...
local V = KH.Village
local D = KH.Data
local B = KH.Balance

local W = {}
KH.Workshop = W

-- ----------------------------------------------------------------------------
-- The Workshop
-- ----------------------------------------------------------------------------
-- Three trades, three recipes each. An input is {herb item id, amount} (from the Barn's herbs) or {"fish" | "ore", amount}
-- (from the Pond and the Mine). Cooking lives on fish, smithing on ore, alchemy on herbs.
W.TRADES = {"alchemy", "cooking", "smithing"}
W.TABS = {"alchemy", "cooking", "smithing", "gear"}      -- the tabs of the screen: the three trades and the equipment
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
    if not r or r.trade == "gear" or not self:Unlocked(id) then return false end
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
    if #self:Jobs(W.Recipe(id).trade) >= self:Slots() then return false, "queueFull" end
    -- the Barn has a space for what each trade makes: what is there and what is in the queue must fit
    if V:Space(V.SpaceOf(id)) + #self:Jobs(r.trade) >= V:BarnCap() then return false, "barnFull" end
    if not self:Has(r) then return false, "herbs" end
    return true
end

function W:Craft(id)
    local ok, why, n = self:CanCraft(id)
    if not ok then return false, why, n end
    local r = W.Recipe(id)
    local db = KH.db
    for _, input in ipairs(r.inputs) do Take(input[1], input[2]) end
    -- after the last job of the same trade (each trade has its own queue)
    local at = KH.Now()
    for _, job in ipairs(db.queue) do
        local jr = W.Recipe(job.recipe)
        if jr and jr.trade == r.trade then at = math.max(at, job.at + job.time) end
    end
    -- a worker in the Workshop makes each craft shorter
    local time = math.max(1, math.floor(r.time * (1 - KH.Inn:WorkBonus("workshop")) + 0.5))
    db.queue[#db.queue + 1] = {recipe = id, at = at, time = time}
    return true
end

-- the queue of a trade as it stands (all of them with no trade): {{recipe, left, progress, trade}, ...}, the next to be
-- ready first
function W:Jobs(trade)
    local out = {}
    for _, job in ipairs(KH.db.queue) do
        local r = W.Recipe(job.recipe)
        if not trade or (r and r.trade == trade) then
            local left = job.at + job.time - KH.Now()
            out[#out + 1] = {recipe = job.recipe, left = math.max(0, left), trade = r and r.trade,
                progress = math.min(1, math.max(0, (KH.Now() - job.at) / job.time))}
        end
    end
    table.sort(out, function(a, b) return a.left < b.left end)
    return out
end

function W:Update()
    local db = KH.db
    local done = {}
    local i = 1
    while db.queue[i] do                            -- every trade runs at once: any job may be the one that ended
        local job = db.queue[i]
        if KH.Now() >= job.at + job.time then
            table.remove(db.queue, i)
            db.goods[job.recipe] = (db.goods[job.recipe] or 0) + 1
            done[#done + 1] = job.recipe
            KH.Farm:AddXP(W.XP(job.recipe))         -- the Workshop gives xp (more than the herbs it used)
        else
            i = i + 1
        end
    end
    return done
end

KH:On("PLAYER_LOGIN", function()
    W:Update()
end)
