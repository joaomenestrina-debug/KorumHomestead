--[[
    Korum Homestead - the plants and the numbers

    Each plant is a herb of the game, by its item id: the name and the icon come from the game client (so they are in the
    player's own language); the English name below is only the fallback until the client knows the item.

        {item id, level to plant, seconds to grow, seed cost, sell price, xp, harvest, English name}
]]

local addonName, KH = ...
local D = {}
KH.Data = D
local B = KH.Balance

D.PLANTS = B.PLANTS
D.MAX_LEVEL = B.HERBALISM.maxLevel
D.MAX_PLOTS = B.HERBALISM.maxPlots
D.ORDER_SLOTS = B.ORDERS.slots
D.NPC_COUNT = B.ORDERS.npcCount

local byId
function D.Plant(id)
    if not byId then
        byId = {}
        for _, p in ipairs(D.PLANTS) do
            byId[p[1]] = {id = p[1], level = p[2], grow = p[3], cost = p[4], sell = p[5], xp = p[6], yield = p[7], en = p[8]}
        end
    end
    return byId[id]
end

-- the xp that takes the homestead from `level` to the next one
function D.XPToNext(level)
    return B.XPToNext(level)
end

-- harvest at this level, including the extra amount awarded by Herbalism progression.
function D.Yield(plant, level)
    return plant.yield + math.floor((level or 1) / B.HERBALISM.extraHarvestLevels)
end

-- Name and icon come from the game; the fallbacks keep the screen alive before the client knows the item
function D.Name(id)
    local p = D.Plant(id)
    local name
    if C_Item and C_Item.GetItemNameByID then
        local ok, n = pcall(C_Item.GetItemNameByID, id)
        if ok then name = n end
    end
    if not name and _G.GetItemInfo then
        local ok, n = pcall(GetItemInfo, id)
        if ok then name = n end
    end
    return name or (p and p.en) or ("#" .. tostring(id))
end

function D.Icon(id)
    local icon
    if C_Item and C_Item.GetItemIconByID then
        local ok, i = pcall(C_Item.GetItemIconByID, id)
        if ok then icon = i end
    end
    if not icon and _G.GetItemIcon then
        local ok, i = pcall(GetItemIcon, id)
        if ok then icon = i end
    end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ask the client for the items now, so the names are ready when the window opens
function D.Preload()
    if not (C_Item and C_Item.RequestLoadItemDataByID) then return end
    for _, p in ipairs(D.PLANTS) do pcall(C_Item.RequestLoadItemDataByID, p[1]) end
    for _, item in pairs(KH.Village and KH.Village.ITEM or {}) do pcall(C_Item.RequestLoadItemDataByID, item) end
    pcall(C_Item.RequestLoadItemDataByID, KH.Balance.DAILY.rareItem)        -- the keepsake of the streak
end
