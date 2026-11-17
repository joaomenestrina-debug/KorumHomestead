--[[
    Korum Homestead - the saved data across versions

    KorumHomesteadDB carries the number of the shape it was written in (db.schema). When the addon loads, the save is
    brought up to the current shape one step at a time, before the defaults fill what is missing. A step may add, move or
    fill fields; it never deletes what the player earned. A save from a newer version than this one is left as it is.

        schema 1    every save of 1.0.x (they have no number)
        schema 2    2.0: the number itself; nothing else changes yet
        schema 3    2.0 economy: "Herbalism 1-20" becomes the Village level 1-60 (docs/economia.md)

    To change the shape: raise KH.SCHEMA, add KH.MIGRATIONS[new number] = function(db) ... end, and a test that opens the
    saved sample of the previous version (tests/fixtures/).
]]

local addonName, KH = ...

KH.SCHEMA = 3

KH.MIGRATIONS = {
    [2] = function(db)
        -- nothing moves yet: 2.0 starts by numbering the saves
    end,

    -- Herbalism 1-20 becomes the Village level 1-60. The player keeps every herb already open: the new level is the
    -- highest new level among the herbs the old level opened. The xp inside the level starts again; the orders keep
    -- their herb and amount and take the new prices.
    [3] = function(db)
        local OLD = {[2447] = 1, [765] = 1, [2449] = 2, [785] = 3, [2450] = 4, [2453] = 6, [3355] = 7, [3356] = 9,
            [3357] = 11, [3818] = 13, [3821] = 15, [3358] = 17, [3369] = 19}         -- the 1.0 table, frozen here
        local old = tonumber(db.level) or 1
        local level = 1
        for id, needed in pairs(OLD) do
            local plant = old >= needed and KH.Data.Plant(id)
            if plant and plant.level > level then level = plant.level end
        end
        db.level, db.xp = level, 0
        local B = KH.Balance
        for _, o in pairs(db.orders or {}) do
            local plant = o.plant and KH.Data.Plant(o.plant)
            if plant and o.qty then
                o.coins = math.floor(o.qty * plant.sell * B.ORDERS.payMultiplier)
                o.xp = math.floor(o.qty * plant.xp / B.ORDERS.xpDivisor)
            end
        end
    end,
}

-- Brings `db` (the raw saved table) to KH.SCHEMA. Returns the schema it had before.
function KH.Migrate(db)
    if next(db) == nil then              -- a new homestead: already in the current shape
        db.schema = KH.SCHEMA
        return KH.SCHEMA
    end
    local from = tonumber(db.schema) or 1
    for n = from + 1, KH.SCHEMA do
        local step = KH.MIGRATIONS[n]
        if step then step(db) end
        db.schema = n
    end
    return from
end
