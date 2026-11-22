--[[
    Korum Homestead - the village

    The homestead is a small village seen from above. Its buildings have levels; a level is bought with coins (and, from the
    third level on, ore) and takes time to build, one work at a time. The work goes on while the game is closed, like
    everything here.

        hall     the Hall: no other building can be above its level
        garden   the Garden: one more plot per level, up to its cap
        barn     the Barn: how many herbs fit, and as much of each good
        market   the Market: sales and orders pay more per level above the first
        mine     the Mine: makes ore by itself, every hour (opened by the Hall)
        pond     the Pond: makes fish by itself, every hour (opened by the Hall)

    The Mine and the Pond start as empty lots (level 0). What they make goes to the Barn by itself, until it is full.

        Village:Level(id)            the level now (0: not built)
        Village:Next(id)             {level, cost, ore, time} of the next level, nil at the top
        Village:CanUpgrade(id)       true, or false, the key of the reason and its number (the Hall level or the ore needed)
        Village:Upgrade(id)          pays and starts the work
        Village:Work()               the work going on: {id, at, time}, seconds left, progress 0..1   (nil when idle)
        Village:Update()             makes what the Mine and the Pond made since the last time, and finishes the work whose
                                     time is over; returns the building that got ready and its level
        Village:Plots() / BarnCap() / Stored() / Fill() / PayBonus() / Rate(id) / SellGood(good, n)
]]

local addonName, KH = ...
local V = {}
KH.Village = V
local B = KH.Balance

V.BUILDINGS = {"hall", "garden", "barn", "market", "mine", "pond", "workshop", "inn"}
V.MAX_LEVEL = B.VILLAGE_MAX_LEVEL
V.BUILT = {hall = true, garden = true, barn = true, market = true}     -- these exist from the start, at level 1
V.NEEDS_HALL = B.NEEDS_HALL                                                    -- the Hall level that opens the lot
V.MAKES = {mine = "ore", pond = "fish"}
V.GOODS = B.GOODS
-- ore, fish, then every Workshop item in the order of the recipes
V.GOOD_ORDER = {"ore", "fish"}
for _, id in ipairs(B.RARE_ORDER) do V.GOOD_ORDER[#V.GOOD_ORDER + 1] = id end
for _, r in ipairs(B.RECIPES) do V.GOOD_ORDER[#V.GOOD_ORDER + 1] = r.id end
-- the Core of the raids and the pieces with a name: they wait in the Barn too
V.GOOD_ORDER[#V.GOOD_ORDER + 1] = "core"
for _, pieces in pairs(B.NAMED) do
    for _, id in ipairs(pieces) do V.GOOD_ORDER[#V.GOOD_ORDER + 1] = id end
end

-- the tab of the Barn a thing is shown in (owner, 20/11): herbs, raw things, or the trade of the Workshop that made it
V.BARN_TABS = {"herbs", "raw", "alchemy", "cooking", "smithing", "gear"}
function V.BarnTab(key)
    if type(key) == "number" then return "herbs" end
    for _, r in ipairs(B.RECIPES) do
        if r.id == key then return r.trade end
    end
    if B.GOODS[key] and B.GOODS[key].gear then return "gear" end
    return "raw"
end
-- every good is shown with the icon of an item of the game, as the herbs are
-- Item ids used for the game's icons.
V.ITEM = {}
for id, good in pairs(B.GOODS) do V.ITEM[id] = good.item end
for _, r in ipairs(B.RECIPES) do V.ITEM[r.id] = r.item end
-- [target level]
V.COST = B.COST
V.TIME = B.TIME
-- ore that a building asks for, by target level (the Mine itself never asks for ore, or the village could get stuck)
V.ORE = B.ORE

-- a save from before the village: the plots that were bought become the level of the Garden
function V:Migrate()
    local db = KH.db
    db.buildings = db.buildings or {}
    local b = db.buildings
    if not b.garden then b.garden = math.max(1, math.min(V.MAX_LEVEL, (db.nplots or B.STARTING.plots) - 1)) end
    b.hall = b.hall or b.garden
    b.barn = b.barn or 1
    b.market = b.market or 1
    b.mine = b.mine or 0
    b.pond = b.pond or 0
    b.workshop = b.workshop or 0
    b.inn = b.inn or 0
    db.queue = db.queue or {}
    db.followers = db.followers or {}
    db.goods = db.goods or {}
    db.made = db.made or {}
    db.nplots = self:Plots()
end

function V:Level(id)
    local level = KH.db.buildings and KH.db.buildings[id]
    if level then return level end
    return V.BUILT[id] and 1 or 0
end

function V:Next(id)
    local level = self:Level(id)
    if level >= V.MAX_LEVEL or not V.COST[id] then return nil end
    local target = level + 1
    return {level = target, cost = V.COST[id][target], time = V.TIME[id][target], ore = id ~= "mine" and V.ORE[target] or 0}
end

function V:Work()
    local w = KH.db.work
    if not w then return nil end
    local left = w.at + w.time - KH.Now()
    return w, math.max(0, left), math.min(1, math.max(0, (KH.Now() - w.at) / w.time))
end

function V:CanUpgrade(id)
    local nxt = self:Next(id)
    if not nxt then return false, "maxLevel" end
    if KH.db.work then return false, "busy" end
    local hall = self:Level("hall")
    if V.NEEDS_HALL[id] and hall < V.NEEDS_HALL[id] then return false, "hall", V.NEEDS_HALL[id] end
    if id ~= "hall" and nxt.level > hall then return false, "hall", nxt.level end
    local gate = B.BUILD_GATE[nxt.level]
    if gate and (KH.db.level or 1) < gate then return false, "village", gate end    -- the buildings walk with the Village
    if KH.db.coins < nxt.cost then return false, "coins", nxt.cost end
    if nxt.ore > self:Good("ore") then return false, "ore", nxt.ore end
    return true
end

function V:Upgrade(id)
    local ok, why, n = self:CanUpgrade(id)
    if not ok then return false, why, n end
    local nxt = self:Next(id)
    local db = KH.db
    db.coins = db.coins - nxt.cost
    if nxt.ore > 0 then db.goods.ore = self:Good("ore") - nxt.ore end
    db.work = {id = id, at = KH.Now(), time = nxt.time}
    return true
end

-- ----------------------------------------------------------------------------
-- What the Mine and the Pond make
-- ----------------------------------------------------------------------------
function V:Good(good)
    return (KH.db.goods and KH.db.goods[good]) or 0
end

-- units an hour of the building at this level; at the level it has, with who works there (Inn:WorkBonus)
function V:Rate(id, level)
    local good = V.MAKES[id]
    if not good then return 0 end
    if level then return V.GOODS[good].perHour * level end
    local bonus = KH.Inn and KH.Inn:WorkBonus(id) or 0
    return V.GOODS[good].perHour * self:Level(id) * (1 + bonus)
end

function V:Produce()
    local db = KH.db
    db.goods = db.goods or {}
    db.made = db.made or {}
    local now = KH.Now()
    local cap = self:BarnCap()
    for _, id in ipairs(V.BUILDINGS) do
        local good = V.MAKES[id]
        local rate = good and self:Rate(id) or 0
        if rate > 0 then
            local since = db.made[id] or now
            local have = db.goods[good] or 0
            if have >= cap then
                db.made[id] = now                              -- full: nothing is made, and no time is owed
            else
                local units = math.floor((now - since) * rate / B.SECONDS_PER_HOUR)
                if units > 0 then
                    local add = math.min(units, cap - have)
                    db.goods[good] = have + add
                    -- the time those units took is spent; the rest keeps counting towards the next one
                    db.made[id] = (have + add >= cap) and now or (since + units * B.SECONDS_PER_HOUR / rate)
                elseif not db.made[id] then
                    db.made[id] = now
                end
            end
        end
    end
end

-- the sell price of a good: ore and fish have theirs; a Workshop item is worth its recipe (Workshop.Value)
function V:GoodSell(good)
    if KH.Workshop and KH.Workshop.Recipe(good) then return KH.Workshop.Value(good) end
    local info = V.GOODS[good]
    if not info then return 0 end
    -- ore and fish are worth more as the Village grows, like the herbs it opens
    return B.Round(info.sell * B.HERB_CURVE.profitStep ^ ((KH.db and KH.db.level or 1) - 1))
end

function V:SellGood(good, n)
    local db = KH.db
    local have = self:Good(good)
    n = math.min(n or have, have)
    if self:GoodSell(good) <= 0 or n <= 0 then return 0 end
    db.goods[good] = have - n
    local coins = math.floor(n * self:GoodSell(good) * self:PayBonus())
    db.coins = db.coins + coins
    db.stats.earned = db.stats.earned + coins
    return coins
end

function V:Update()
    local db = KH.db
    self:Produce()
    local w = db.work
    if not w or KH.Now() < w.at + w.time then return nil end
    db.work = nil
    db.buildings[w.id] = math.min(V.MAX_LEVEL, self:Level(w.id) + 1)
    db.nplots = self:Plots()
    if V.MAKES[w.id] then
        self:Produce()                                         -- what the old level made up to now
        db.made[w.id] = db.made[w.id] or KH.Now()
    end
    return w.id, db.buildings[w.id]
end

function V:Plots()
    return math.min(KH.Data.MAX_PLOTS, 1 + self:Level("garden"))
end

function V:BarnCap(level)
    return B.BARN_PER_LEVEL * (level or self:Level("barn"))
end

function V:Stored()
    local n = 0
    for _, count in pairs(KH.db.crops) do n = n + count end
    return n
end

-- The spaces of the Barn (owner, 22/11: everything it holds is counted), each as big as BarnCap:
--   herbs      all the herbs together                      ore, fish    what the Mine and the Pond make, each its own
--   finds      the rare finds, the Raid Core and the pieces with a name
--   alchemy, cooking, smithing, gear   what each trade of the Workshop made
-- A full space stops what fills it (the Garden, the Mine, the Pond, a craft of that trade). What comes from a dungeon,
-- a raid or a visitor always comes in, even over the space: nothing is ever lost.
function V.SpaceOf(key)
    if type(key) == "number" then return "herbs" end
    if key == "ore" or key == "fish" then return key end
    local tab = V.BarnTab(key)
    if tab == "raw" or (tab == "gear" and not KH.Workshop.Recipe(key)) then return "finds" end
    return tab
end

function V:Space(space)
    if space == "herbs" then return self:Stored() end
    local n = 0
    for _, good in ipairs(V.GOOD_ORDER) do
        if V.SpaceOf(good) == space then n = n + self:Good(good) end
    end
    return n
end

-- the spaces a tab of the Barn shows, in order
V.TAB_SPACES = {herbs = {"herbs"}, raw = {"ore", "fish", "finds"}, alchemy = {"alchemy"}, cooking = {"cooking"},
    smithing = {"smithing"}, gear = {"gear"}}
local SPACES = {"herbs", "ore", "fish", "finds", "alchemy", "cooking", "smithing", "gear"}
V.SPACES = SPACES

-- how full the Barn is (0 to 1): the fullest of its spaces (ore and fish only once their building is up)
function V:Fill()
    local cap = self:BarnCap()
    if cap <= 0 then return 0 end
    local most = 0
    for _, space in ipairs(SPACES) do
        local up = (space ~= "ore" or self:Level("mine") > 0) and (space ~= "fish" or self:Level("pond") > 0)
        if up then most = math.max(most, self:Space(space)) end
    end
    return math.min(1, most / cap)
end

-- The upgrade the Hall recommends: the one that helps the most now, among those the player can reach (only coins, ore
-- or the work going on stand in the way). A Barn about to fill comes first, then the Hall when it holds the Garden back,
-- then the Garden (income), the Workshop, the Market, the Mine, the Pond, the Inn, the Barn, the Hall.
V.RECOMMEND_ORDER = {"garden", "workshop", "market", "mine", "pond", "inn", "barn", "hall"}
function V:Recommend()
    local function Reachable(id)
        if not self:Next(id) then return false end
        local ok, why = self:CanUpgrade(id)
        return ok or why == "coins" or why == "ore" or why == "busy"
    end
    if Reachable("barn") and self:Fill() >= 0.8 then return "barn", "barn" end
    local _, gardenWhy = self:CanUpgrade("garden")
    if gardenWhy == "hall" and Reachable("hall") then return "hall", "hall" end
    for _, id in ipairs(V.RECOMMEND_ORDER) do
        if Reachable(id) then return id, id end
    end
    return nil
end

-- what sales and orders are multiplied by
function V:PayBonus(level)
    -- the Market's level, and who works there now (only for the Market as it is, not for a level shown ahead)
    local work = (not level and KH.Inn) and KH.Inn:WorkBonus("market") or 0
    return 1 + B.MARKET_BONUS_PER_LEVEL * ((level or self:Level("market")) - 1) + work
end

-- Is there a building the player could start now?
function V:Affordable()
    for _, id in ipairs(V.BUILDINGS) do
        if self:CanUpgrade(id) then return id end
    end
    return nil
end

KH:On("PLAYER_LOGIN", function()
    V:Migrate()
    V:Update()
end)
