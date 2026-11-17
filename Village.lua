--[[
    Korum Homestead - the village

    The homestead is a small village seen from above. Its buildings have levels; a level is bought with coins (and, from the
    third level on, ore) and takes time to build, one work at a time. The work goes on while the game is closed, like
    everything here.

        hall     the Hall: no other building can be above its level
        garden   the Garden: one more plot per level (2 at level 1, 8 at level 7)
        barn     the Barn: how many herbs fit (40 per level), and as much of each good
        market   the Market: sales and orders pay 4% more per level above the first
        mine     the Mine: makes ore by itself, every hour (it is built when the Hall reaches level 2)
        pond     the Pond: makes fish by itself, every hour (built when the Hall reaches level 3)

    The Mine and the Pond start as empty lots (level 0). What they make goes to the Barn by itself, until it is full.

        Village:Level(id)            the level now (0: not built)
        Village:Next(id)             {level, cost, ore, time} of the next level, nil at the top
        Village:CanUpgrade(id)       true, or false, the key of the reason and its number (the Hall level or the ore needed)
        Village:Upgrade(id)          pays and starts the work
        Village:Work()               the work going on: {id, at, time}, seconds left, progress 0..1   (nil when idle)
        Village:Update()             makes what the Mine and the Pond made since the last time, and finishes the work whose
                                     time is over; returns the building that got ready and its level
        Village:Plots() / BarnCap() / Stored() / PayBonus() / Rate(id) / SellGood(good, n)
]]

local addonName, KH = ...
local V = {}
KH.Village = V

V.BUILDINGS = {"hall", "garden", "barn", "market", "mine", "pond", "workshop", "inn"}
V.MAX_LEVEL = 7
V.BUILT = {hall = true, garden = true, barn = true, market = true}     -- these exist from the start, at level 1
V.NEEDS_HALL = {mine = 2, pond = 3, workshop = 4, inn = 5}                                    -- the Hall level that opens the lot
V.MAKES = {mine = "ore", pond = "fish"}
V.GOODS = {ore = {sell = 6, perHour = 6}, fish = {sell = 5, perHour = 5}, heal = {sell = 60}, mana = {sell = 150}, agil = {sell = 400},
    stew = {sell = 32}, roast = {sell = 110}, feast = {sell = 330}, bar = {sell = 60}, tools = {sell = 190}, blade = {sell = 560}}
V.GOOD_ORDER = {"ore", "fish", "heal", "mana", "agil", "stew", "roast", "feast", "bar", "tools", "blade"}
-- every good is shown with the icon of an item of the game, as the herbs are
V.ITEM = {ore = 2770, fish = 6303, heal = 118, mana = 2455, agil = 2457,
    stew = 13931, roast = 13935, feast = 21023, bar = 3575, tools = 5956, blade = 3487}                     -- perHour: for each level of its building
-- [target level]
V.COST = {
    hall = {0, 100, 300, 800, 2000, 5000, 12000},
    garden = {0, 150, 400, 1000, 2500, 6000, 15000},
    barn = {0, 60, 180, 500, 1300, 3200, 8000},
    market = {0, 80, 220, 600, 1500, 3800, 9500},
    mine = {200, 350, 700, 1500, 3200, 6500, 13000},
    pond = {350, 500, 900, 1800, 3600, 7000, 14000},
    workshop = {400, 600, 1100, 2200, 4200, 8000, 15000},
    inn = {600, 800, 1400, 2600, 4800, 9000, 16000},
}
V.TIME = {
    hall = {0, 45, 240, 600, 1500, 3000, 6000},
    garden = {0, 60, 300, 900, 1800, 3600, 7200},
    barn = {0, 30, 180, 480, 1200, 2400, 4800},
    market = {0, 30, 180, 480, 1200, 2400, 4800},
    mine = {300, 480, 900, 1800, 3000, 4800, 7200},
    pond = {480, 600, 1200, 2100, 3300, 5400, 7800},
    workshop = {600, 900, 1500, 2400, 3600, 5400, 7800},
    inn = {900, 1200, 1800, 2700, 3900, 5700, 8400},
}
-- ore that a building asks for, by target level (the Mine itself never asks for ore, or the village could get stuck)
V.ORE = {[3] = 10, [4] = 25, [5] = 50, [6] = 90, [7] = 150}

-- a save from before the village: the plots that were bought become the level of the Garden
function V:Migrate()
    local db = KH.db
    db.buildings = db.buildings or {}
    local b = db.buildings
    if not b.garden then b.garden = math.max(1, math.min(V.MAX_LEVEL, (db.nplots or 2) - 1)) end
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

-- units an hour of the building at this level (or at the level it has)
function V:Rate(id, level)
    local good = V.MAKES[id]
    if not good then return 0 end
    return V.GOODS[good].perHour * (level or self:Level(id))
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
                local units = math.floor((now - since) * rate / 3600)
                if units > 0 then
                    local add = math.min(units, cap - have)
                    db.goods[good] = have + add
                    -- the time those units took is spent; the rest keeps counting towards the next one
                    db.made[id] = (have + add >= cap) and now or (since + units * 3600 / rate)
                elseif not db.made[id] then
                    db.made[id] = now
                end
            end
        end
    end
end

function V:SellGood(good, n)
    local db = KH.db
    local info = V.GOODS[good]
    local have = self:Good(good)
    n = math.min(n or have, have)
    if not info or n <= 0 then return 0 end
    db.goods[good] = have - n
    local coins = math.floor(n * info.sell * self:PayBonus())
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
    return 40 * (level or self:Level("barn"))
end

function V:Stored()
    local n = 0
    for _, count in pairs(KH.db.crops) do n = n + count end
    return n
end

-- what sales and orders are multiplied by
function V:PayBonus(level)
    return 1 + 0.04 * ((level or self:Level("market")) - 1)
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
