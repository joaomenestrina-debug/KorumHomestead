--[[
    Korum Homestead - the numbers behind the game

    Tune the homestead here. Tables below follow the game from herbs to the Inn.
]]

local addonName, KH = ...
local B = {}
KH.Balance = B

-- Herb rows: item id, required level, grow seconds, seed cost, sell price, XP, harvest, English fallback.
B.PLANTS = {
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

-- Herbalism cap and plots, XP per level, and levels between extra harvests.
B.HERBALISM = {maxLevel = 20, maxPlots = 8, xpPerLevel = 40, extraHarvestLevels = 6}

-- Order slots, NPC count, quantity formula, level range, reward multipliers and XP divisor.
B.ORDERS = {
    slots = 3,
    npcCount = 6,
    quantityBase = 2,
    quantityRandom = 5,
    quantityLevels = 5,
    plantLevelRange = 8,
    payMultiplier = 1.6,
    xpDivisor = 2,
}

-- Village level cap and Hall levels required to open each building.
B.VILLAGE_MAX_LEVEL = 7
B.NEEDS_HALL = {mine = 2, pond = 3, workshop = 4, inn = 5}

-- Building upgrade costs in coins, indexed by target level.
B.COST = {
    hall = {0, 100, 300, 800, 2000, 5000, 12000},
    garden = {0, 150, 400, 1000, 2500, 6000, 15000},
    barn = {0, 60, 180, 500, 1300, 3200, 8000},
    market = {0, 80, 220, 600, 1500, 3800, 9500},
    mine = {200, 350, 700, 1500, 3200, 6500, 13000},
    pond = {350, 500, 900, 1800, 3600, 7000, 14000},
    workshop = {400, 600, 1100, 2200, 4200, 8000, 15000},
    inn = {600, 800, 1400, 2600, 4800, 9000, 16000},
}

-- Building upgrade times in seconds, indexed by target level.
B.TIME = {
    hall = {0, 45, 240, 600, 1500, 3000, 6000},
    garden = {0, 60, 300, 900, 1800, 3600, 7200},
    barn = {0, 30, 180, 480, 1200, 2400, 4800},
    market = {0, 30, 180, 480, 1200, 2400, 4800},
    mine = {300, 480, 900, 1800, 3000, 4800, 7200},
    pond = {480, 600, 1200, 2100, 3300, 5400, 7800},
    workshop = {600, 900, 1500, 2400, 3600, 5400, 7800},
    inn = {900, 1200, 1800, 2700, 3900, 5700, 8400},
}

-- Ore required for an upgrade by target level; the Mine does not consume ore.
B.ORE = {[3] = 10, [4] = 25, [5] = 50, [6] = 90, [7] = 150}

-- Goods sell prices in coins and production rates in units per hour.
B.GOODS = {
    ore = {sell = 6, perHour = 6}, fish = {sell = 5, perHour = 5}, heal = {sell = 60}, mana = {sell = 150}, agil = {sell = 400},
    stew = {sell = 32}, roast = {sell = 110}, feast = {sell = 330}, bar = {sell = 60}, tools = {sell = 190}, blade = {sell = 560},
}

-- Seconds in one hour, used to convert a per-hour production rate into elapsed seconds.
B.SECONDS_PER_HOUR = 3600

-- Barn capacity per level and market pay bonus per level above the first.
B.BARN_PER_LEVEL = 40
B.MARKET_BONUS_PER_LEVEL = 0.04

-- Workshop recipes: recipe id, trade, required level, craft seconds, and input item ids or goods.
B.RECIPES = {
    {id = "heal", trade = "alchemy", level = 1, time = 120, inputs = {{2447, 3}, {765, 1}}},
    {id = "mana", trade = "alchemy", level = 2, time = 300, inputs = {{785, 2}, {2449, 2}}},
    {id = "agil", trade = "alchemy", level = 3, time = 600, inputs = {{2450, 2}, {2453, 2}}},
    {id = "stew", trade = "cooking", level = 1, time = 90, inputs = {{"fish", 4}}},
    {id = "roast", trade = "cooking", level = 3, time = 240, inputs = {{"fish", 10}, {2447, 2}}},
    {id = "feast", trade = "cooking", level = 5, time = 720, inputs = {{"fish", 24}, {785, 2}}},
    {id = "bar", trade = "smithing", level = 2, time = 200, inputs = {{"ore", 6}}},
    {id = "tools", trade = "smithing", level = 4, time = 540, inputs = {{"ore", 16}}},
    {id = "blade", trade = "smithing", level = 6, time = 1500, inputs = {{"ore", 40}, {2450, 1}}},
}

-- Inn capacity, follower progression, and bonus pay per follower level.
B.INN = {maxFollowers = 6, maxLevel = 5, missionsPerLevel = 3, payBonusPerLevel = 0.1}

-- Inn missions: mission id, duration seconds, fish cost, coin reward, and ore reward.
B.MISSIONS = {
    {id = "short", time = 1800, fish = 2, coins = 40, ore = 0},
    {id = "medium", time = 7200, fish = 6, coins = 170, ore = 2},
    {id = "long", time = 28800, fish = 20, coins = 750, ore = 8},
}

-- Initial coins and plot count for a new homestead.
B.STARTING = {coins = 40, plots = 2}
KH.defaults.coins = B.STARTING.coins
KH.defaults.nplots = B.STARTING.plots

