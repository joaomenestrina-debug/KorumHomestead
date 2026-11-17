--[[
    Korum Homestead - the order of the day and its delivery streak.

    This keeps the daily order separate from the three regular Market orders.
]]

local addonName, KH = ...
local Daily = {}
KH.Daily = Daily
local D = KH.Data
local B = KH.Balance
local DONE = "done"

-- the pay of an order comes from Balance.lua every time, so a change of the numbers reaches the order already drawn today
function Daily:Price(order)
    local plant = D.Plant(order.plant)
    if not plant then return order end
    order.coins = math.floor(order.qty * plant.sell * B.ORDERS.payMultiplier * B.DAILY.payMultiplier)
    order.xp = math.floor(order.qty * plant.xp / B.ORDERS.xpDivisor * B.DAILY.xpMultiplier)
    return order
end

function Daily:Make()
    local order = KH.Orders:Make()
    order.qty = math.floor(order.qty * B.DAILY.qtyMultiplier)
    return self:Price(order)
end

function Daily:Ensure()
    local saved = KH.db.daily
    local today = KH.Day()
    if today < saved.day then return false end
    if today ~= saved.day then
        saved.day = today
        saved.order = self:Make()
        saved.done = false
        if saved.lastDone < today - 1 then saved.streak = 0 end
        return true
    end
    if not saved.order then saved.order = self:Make() else self:Price(saved.order) end
    return false
end

function Daily:Order()
    self:Ensure()
    return KH.db.daily.order
end

function Daily:Done()
    self:Ensure()
    return KH.db.daily.done
end

function Daily:CanDeliver()
    local order = self:Order()
    local db = KH.db
    return not db.daily.done and (db.crops[order.plant] or 0) >= order.qty
end

local function PrizeFor(streak)
    local prize = B.DAILY.streak[streak]
    if prize then return prize end
    if streak > 30 and (streak - 30) % B.DAILY.rareEvery == 0 then return {rare = 1} end
    return nil
end

function Daily:Deliver()
    self:Ensure()
    local db = KH.db
    local saved = db.daily
    if saved.done then return false, DONE end
    local order = saved.order
    if (db.crops[order.plant] or 0) < order.qty then return false, "missing" end

    db.crops[order.plant] = db.crops[order.plant] - order.qty
    if db.crops[order.plant] <= 0 then db.crops[order.plant] = nil end

    local streak = (saved.lastDone == saved.day - 1) and saved.streak + 1 or 1
    local pay = math.floor(order.coins * KH.Village:PayBonus())
    local prize = PrizeFor(streak)
    local bonus = prize and math.floor(order.xp * (prize.xp or 0)) or 0      -- the prize of the streak is xp, not coins
    local rare = prize and (prize.rare or 0) or 0
    local xp = order.xp + bonus

    db.coins = db.coins + pay
    db.stats.earned = db.stats.earned + pay
    db.stats.delivered = db.stats.delivered + 1
    saved.streak = streak
    saved.lastDone = saved.day
    saved.best = math.max(saved.best, streak)
    saved.done = true
    saved.rare = saved.rare + rare
    KH.Farm:AddXP(xp)
    return true, {pay = pay, xp = xp, streak = streak, bonus = bonus, rare = rare}
end

function Daily:Streak()
    local saved = KH.db.daily
    local today = KH.Day()
    if saved.lastDone >= today - 1 then return saved.streak end
    return 0
end

function Daily:NextPrize()
    local streak = self:Streak()
    local nextDay
    for day in pairs(B.DAILY.streak) do
        if day > streak and (not nextDay or day < nextDay) then nextDay = day end
    end
    if not nextDay then
        nextDay = 30 + (math.floor((math.max(streak, 30) - 30) / B.DAILY.rareEvery) + 1) * B.DAILY.rareEvery
    end
    return nextDay, nextDay - streak
end
