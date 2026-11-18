--[[
    Korum Homestead - advice: what to craft, what to plant

    The suggestions follow what the Market asks: the herb orders, the item orders, the order of the day and the urgent
    orders of the visitors. What is asked and not yet in the Barn is "missing"; an item missing also makes its herbs
    missing (to craft it). With nothing missing, the advice falls back to what is worth the most.

        Advice:Missing()            {[herb id or good id] = units missing}
        Advice:Craft(ids)           of these recipe ids, the one to craft now (only the ones that can be made); id, "order"|"value"
        Advice:Seed()               the herb to plant now (open and affordable); id, "order"|"value"
]]

local addonName, KH = ...
local D = KH.Data
local V = KH.Village

local A = {}
KH.Advice = A

local function Have(key)
    if type(key) == "number" then return KH.db.crops[key] or 0 end
    return V:Good(key)
end

local function Ask(asked, key, n)
    if key and n and n > 0 then asked[key] = (asked[key] or 0) + n end
end

function A:Missing()
    local db = KH.db
    local asked = {}
    for i = 1, D.ORDER_SLOTS do
        local o = db.orders[i]
        if o then Ask(asked, o.plant or o.good, o.qty) end
    end
    if KH.Daily and not KH.Daily:Done() then
        local o = KH.Daily:Order()
        if o then Ask(asked, o.plant, o.qty) end
    end
    if KH.Events then
        for _, e in ipairs(KH.Events:Open()) do
            if e.kind == "urgent" then Ask(asked, e.key, e.qty) end
        end
    end
    -- an item missing asks for its inputs too
    local missing = {}
    for key, n in pairs(asked) do
        local left = n - Have(key)
        if left > 0 then missing[key] = left end
    end
    for key, n in pairs(missing) do
        local r = type(key) == "string" and KH.Workshop.Recipe(key)
        if r then
            for _, input in ipairs(r.inputs) do Ask(asked, input[1], n * input[2]) end
        end
    end
    for key, n in pairs(asked) do
        local left = n - Have(key)
        missing[key] = left > 0 and left or nil
    end
    return missing
end

function A:Craft(ids)
    local missing = self:Missing()
    local best, bestScore, why = nil, -1, nil
    for _, id in ipairs(ids) do
        if KH.Workshop:CanCraft(id) then
            local value = V:GoodSell(id)
            local need = missing[id] or 0
            -- an item the Market asks always comes before one it does not
            local score = need > 0 and (1e12 + need * value) or value
            if score > bestScore then best, bestScore, why = id, score, need > 0 and "order" or "value" end
        end
    end
    return best, why
end

function A:Seed()
    local db = KH.db
    local missing = self:Missing()
    local best, bestScore, why = nil, -1, nil
    for _, p in ipairs(D.PLANTS) do
        local plant = D.Plant(p[1])
        if plant.level <= db.level and plant.cost <= db.coins then
            local need = missing[plant.id] or 0
            local perHour = (D.Yield(plant, db.level) * plant.sell - plant.cost) * 3600 / plant.grow
            local score = need > 0 and (1e12 + need * plant.sell) or perHour
            if score > bestScore then best, bestScore, why = plant.id, score, need > 0 and "order" or "value" end
        end
    end
    return best, why
end
