--[[
    Korum Homestead - the saved data across versions

    KorumHomesteadDB carries the number of the shape it was written in (db.schema). When the addon loads, the save is
    brought up to the current shape one step at a time, before the defaults fill what is missing. A step may add, move or
    fill fields; it never deletes what the player earned. A save from a newer version than this one is left as it is.

        schema 1    every save of 1.0.x (they have no number)
        schema 2    2.0: the number itself; nothing else changes yet

    To change the shape: raise KH.SCHEMA, add KH.MIGRATIONS[new number] = function(db) ... end, and a test that opens the
    saved sample of the previous version (tests/fixtures/).
]]

local addonName, KH = ...

KH.SCHEMA = 2

KH.MIGRATIONS = {
    [2] = function(db)
        -- nothing moves yet: 2.0 starts by numbering the saves
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
