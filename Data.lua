--[[
    Korum Homestead - the plants and the numbers

    Each plant is a herb of the game, by its item id: the name and the icon come from the game client (so they are in the
    player's own language); the English name below is only the fallback until the client knows the item.

        {item id, level to plant, seconds to grow, seed cost, sell price, xp, harvest, English name}
]]

local addonName, KH = ...
local D = {}
KH.Data = D

D.PLANTS = {
    {2447, 1, 45, 4, 4, 4, 3, "Peacebloom"},
    {765, 1, 120, 10, 9, 6, 3, "Silverleaf"},
    {2449, 2, 300, 25, 18, 12, 4, "Earthroot"},
    {785, 3, 600, 50, 28, 20, 4, "Mageroyal"},
    {2450, 4, 1200, 100, 50, 35, 5, "Briarthorn"},
    {2453, 6, 1800, 150, 75, 50, 5, "Bruiseweed"},
    {3355, 7, 2700, 250, 110, 75, 5, "Wild Steelbloom"},
    {3356, 9, 3600, 400, 170, 110, 5, "Kingsblood"},
    {3357, 11, 5400, 700, 260, 170, 6, "Liferoot"},
    {3818, 13, 7200, 1000, 330, 240, 6, "Fadeleaf"},
    {3821, 15, 10800, 1800, 520, 360, 7, "Goldthorn"},
    {3358, 17, 14400, 3000, 800, 520, 7, "Khadgar's Whisker"},
    {3369, 19, 21600, 5000, 1100, 800, 8, "Grave Moss"},
}

D.MAX_LEVEL = 20
D.MAX_PLOTS = 8
D.ORDER_SLOTS = 3
D.NPC_COUNT = 6

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
    return 40 * level
end

-- harvest of a plant at this level: a plant more every 6 levels
function D.Yield(plant, level)
    return plant.yield + math.floor((level or 1) / 6)
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
end
