--[[
    Korum Homestead - the farm

    The rules, without any window: plots, planting, harvest, selling, the level and the orders. Every function that can fail
    returns false and the key of the reason (the UI says it in the language of the player).

        Farm:Status(index)           "locked" | "empty" | "growing" | "ready", progress 0..1, seconds left
        Farm:Plant(index, plantId)   buys the seed and plants it
        Farm:Harvest(index)          the plant of a ready plot goes to the barn; returns how many
        Farm:HarvestAll() / Farm:PlantAll(plantId)
        Farm:Sell(plantId, n) / Farm:SellAll()
        Farm:AddXP(n)
        Orders:Ensure() / Orders:Deliver(slot)
]]

local addonName, KH = ...
local F = {}
KH.Farm = F
local Orders = {}
KH.Orders = Orders
local D = KH.Data
local B = KH.Balance

-- ----------------------------------------------------------------------------
-- The level
-- ----------------------------------------------------------------------------
function F:AddXP(n)
    local db = KH.db
    if db.level >= D.MAX_LEVEL then
        -- at the cap the xp is not lost: every B.HERBALISM.lotusXP of it becomes a Black Lotus (the rare keepsake)
        db.capXP = (db.capXP or 0) + n
        local every = KH.Balance.HERBALISM.lotusXP
        while db.capXP >= every do
            db.capXP = db.capXP - every
            db.daily.rare = (db.daily.rare or 0) + 1
            KH:Notify(KH.Say("capLotus", D.Name(KH.Balance.DAILY.rareItem)))
        end
        return
    end
    db.xp = db.xp + n
    while db.level < D.MAX_LEVEL and db.xp >= D.XPToNext(db.level) do
        db.xp = db.xp - D.XPToNext(db.level)
        db.level = db.level + 1
        KH:Notify(KH.Say("levelUp", db.level))
    end
    if db.level >= D.MAX_LEVEL then db.xp = 0 end
end

-- how far the xp at the cap is from the next Black Lotus (0..1)
function F:CapProgress()
    return (KH.db.capXP or 0) / KH.Balance.HERBALISM.lotusXP
end

-- ----------------------------------------------------------------------------
-- The plots
-- ----------------------------------------------------------------------------
function F:Status(index)
    local db = KH.db
    if index > db.nplots then return "locked", 0, 0 end
    local plot = db.plots[index]
    if not plot then return "empty", 0, 0 end
    local plant = D.Plant(plot.plant)
    if not plant then return "empty", 0, 0 end
    local elapsed = KH.Now() - plot.at
    local grow = plot.grow or plant.grow             -- a worker in the Garden at planting time made it shorter
    if elapsed >= grow then return "ready", 1, 0 end
    return "growing", math.max(0, elapsed) / grow, grow - elapsed
end

function F:ReadyCount()
    local n = 0
    for i = 1, KH.db.nplots do
        if self:Status(i) == "ready" then n = n + 1 end
    end
    return n
end

-- Nothing growing, nothing in the barn and not even the cheapest seed affordable: the player could never earn again
function F:Stuck()
    local db = KH.db
    for i = 1, db.nplots do
        if db.plots[i] then return false end
    end
    for _, n in pairs(db.crops) do
        if n > 0 then return false end
    end
    return db.coins < D.PLANTS[1][4]
end

function F:Plant(index, plantId)
    local db = KH.db
    local plant = D.Plant(plantId)
    if not plant then return false, "noPlant" end
    if self:Status(index) ~= "empty" then return false, "notEmpty" end
    if db.level < plant.level then return false, "level" end
    -- a neighbour lends the cheapest seed to whoever is stuck without coins
    if plantId == D.PLANTS[1][1] and self:Stuck() then db.coins = plant.cost end
    if db.coins < plant.cost then return false, "coins" end
    db.coins = db.coins - plant.cost
    local grow = self:GrowTime(plant)
    db.plots[index] = {plant = plantId, at = KH.Now(), grow = grow ~= plant.grow and grow or nil}
    return true
end

-- how long a seed takes now: shorter while someone works in the Garden
function F:GrowTime(plant)
    local bonus = KH.Inn and KH.Inn:WorkBonus("garden") or 0
    return math.max(1, math.floor(plant.grow * (1 - bonus) + 0.5))
end

function F:PlantAll(plantId)
    local n, why = 0, nil
    for i = 1, KH.db.nplots do
        if self:Status(i) == "empty" then
            local ok, reason = self:Plant(i, plantId)
            if ok then n = n + 1 else why = reason break end
        end
    end
    return n, why
end

-- Pulls up what is growing, so another seed can go in. The seed is lost: nothing comes back.
function F:Clear(index)
    if self:Status(index) ~= "growing" then return false, "notGrowing" end
    local plant = KH.db.plots[index].plant
    KH.db.plots[index] = nil
    return true, plant
end

function F:Harvest(index)
    local db = KH.db
    if self:Status(index) ~= "ready" then return 0 end
    local plot = db.plots[index]
    local plant = D.Plant(plot.plant)
    -- a Barn almost full takes what fits; the rest waits in the plot (`left`), still ready, and the xp comes once
    local amount = plot.left or D.Yield(plant, db.level)
    local room = KH.Village:BarnCap() - KH.Village:Stored()
    if room <= 0 then return 0, "barnFull" end
    local fit = math.min(amount, room)
    db.crops[plant.id] = (db.crops[plant.id] or 0) + fit
    db.stats.harvested = db.stats.harvested + fit
    if not plot.left then self:AddXP(plant.xp) end
    if fit < amount then
        plot.left = amount - fit
        return fit, "barnFull"
    end
    db.plots[index] = nil
    return fit
end

function F:HarvestAll()
    local total, why = 0, nil
    for i = 1, KH.db.nplots do
        local n, reason = self:Harvest(i)
        total = total + n
        why = why or reason
    end
    return total, why
end

-- ----------------------------------------------------------------------------
-- The barn: selling
-- ----------------------------------------------------------------------------
function F:Sell(plantId, n)
    local db = KH.db
    local plant = D.Plant(plantId)
    local have = db.crops[plantId] or 0
    n = math.min(n or have, have)
    if not plant or n <= 0 then return 0 end
    db.crops[plantId] = have - n > 0 and (have - n) or nil
    local coins = math.floor(n * plant.sell * KH.Village:PayBonus())
    db.coins = db.coins + coins
    db.stats.earned = db.stats.earned + coins
    return coins
end

function F:SellAll()
    local total = 0
    for _, p in ipairs(D.PLANTS) do total = total + self:Sell(p[1]) end
    return total
end

-- ----------------------------------------------------------------------------
-- The orders: someone in the world wants some of a herb, and pays more than the market
-- ----------------------------------------------------------------------------
local function Rand(n)
    return (KH.Rand or math.random)(n)
end

-- what a herb order pays and the xp it gives, from Balance.lua every time
function Orders.HerbPay(plant, qty)
    return math.floor(qty * plant.sell * B.ORDERS.payMultiplier)
end
function Orders.HerbXP(plant, qty)
    return math.floor(qty * plant.xp / plant.yield * B.ORDERS.xpFactor)
end

-- the slots of each kind: 1..herbSlots ask herbs, the rest ask Workshop items
function Orders.IsGoods(slot) return slot > B.ORDERS.herbSlots end

-- an item order: one of the recipes the Workshop has open, or nil when none is
function Orders:MakeGoods()
    local db, W = KH.db, KH.Workshop
    local open = {}
    for _, r in ipairs(W.RECIPES) do
        if W:Offered(r.id) then open[#open + 1] = r.id end
    end
    if #open == 0 then return nil end
    local id = open[Rand(#open)]
    local qty = B.ORDERS.goodsBase + Rand(B.ORDERS.goodsRandom) - 1 + math.floor(db.level / B.ORDERS.goodsLevels)
    return {good = id, qty = qty, coins = math.floor(qty * W.Value(id) * B.ORDERS.goodsPayMultiplier),
        xp = math.floor(qty * W.XP(id) * B.ORDERS.goodsXpFactor), npc = Rand(D.NPC_COUNT)}
end

function Orders:Make(slot)
    if slot and Orders.IsGoods(slot) then return self:MakeGoods() end
    local db = KH.db
    local options = {}
    for _, p in ipairs(D.PLANTS) do
        if p[2] <= db.level and p[2] >= db.level - B.ORDERS.plantLevelRange then options[#options + 1] = p[1] end
    end
    if #options == 0 then options[1] = D.PLANTS[1][1] end
    local plant = D.Plant(options[Rand(#options)])
    local qty = B.ORDERS.quantityBase + Rand(B.ORDERS.quantityRandom) + math.floor(db.level / B.ORDERS.quantityLevels)
    return {plant = plant.id, qty = qty, coins = Orders.HerbPay(plant, qty), xp = Orders.HerbXP(plant, qty), npc = Rand(D.NPC_COUNT)}
end

function Orders:Ensure()
    local db = KH.db
    for i = 1, D.ORDER_SLOTS do
        local o = db.orders[i]
        -- an order for an item that left the Workshop screen (the Workshop grew) and that the barn cannot fill: a new one
        if o and o.good and KH.Workshop.Recipe(o.good) and not KH.Workshop:Offered(o.good)
            and KH.Village:Good(o.good) < o.qty then
            db.orders[i] = nil
        end
        if not db.orders[i] then db.orders[i] = self:Make(i) end
    end
end

-- how many of what an order asks the homestead has
function Orders.Have(o)
    if o.good then return KH.Village:Good(o.good) end
    return KH.db.crops[o.plant] or 0
end

function Orders:CanDeliver(slot)
    local o = KH.db.orders[slot]
    return o ~= nil and Orders.Have(o) >= o.qty
end

function Orders:Deliver(slot)
    local db = KH.db
    local o = db.orders[slot]
    if not o then return false, "noOrder" end
    if Orders.Have(o) < o.qty then return false, "missing" end
    if o.good then
        db.goods[o.good] = KH.Village:Good(o.good) - o.qty
    else
        db.crops[o.plant] = db.crops[o.plant] - o.qty
        if db.crops[o.plant] <= 0 then db.crops[o.plant] = nil end
    end
    local pay = math.floor(o.coins * KH.Village:PayBonus())
    o.paid = pay
    db.coins = db.coins + pay
    db.stats.earned = db.stats.earned + pay
    db.stats.delivered = db.stats.delivered + 1
    db.orders[slot] = self:Make(slot)
    F:AddXP(o.xp)
    return true, o
end
