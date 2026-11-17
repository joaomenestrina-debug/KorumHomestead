--[[
    Korum Homestead - the numbers behind the game

    Tune the homestead here. Tables below follow the game from herbs to the Inn.
]]

local addonName, KH = ...
local B = {}
KH.Balance = B

-- The level of the Village (1-60) and what it gives (docs/economia.md, approved on 17/11). The table keeps the name
-- HERBALISM so old readers work; the player sees "Village".
--   maxLevel            the cap: the character cap of WoW Forever, whose professions go to 300
--   maxPlots            plots in the Garden at most
--   extraHarvestLevels  one more herb per harvest every this many levels
--   xpBase, xpGrowth    xp from a level to the next: xpBase * level * (1 + level / xpGrowth)
--   lotusXP             at the cap, every this much xp becomes one Black Lotus (the rare keepsake)
B.HERBALISM = {maxLevel = 60, maxPlots = 8, extraHarvestLevels = 20, xpBase = 50, xpGrowth = 10, lotusXP = 20000}

-- The herbs: item id, Herbalism skill the game asks to gather it, English fallback. Each opens at Village level =
-- skill / 5 (at least 1). The Black Lotus (300 = level 60) is not planted: it is the rare keepsake (B.DAILY.rareItem).
B.HERBS = {
    {2447, 1, "Peacebloom"}, {765, 1, "Silverleaf"}, {2449, 15, "Earthroot"}, {785, 50, "Mageroyal"},
    {2450, 70, "Briarthorn"}, {3820, 85, "Stranglekelp"}, {2453, 100, "Bruiseweed"}, {3355, 115, "Wild Steelbloom"},
    {3369, 120, "Grave Moss"}, {3356, 125, "Kingsblood"}, {3357, 150, "Liferoot"}, {3818, 160, "Fadeleaf"},
    {3821, 170, "Goldthorn"}, {3358, 185, "Khadgar's Whisker"}, {3819, 195, "Wintersbite"}, {4625, 205, "Firebloom"},
    {8831, 210, "Purple Lotus"}, {8836, 220, "Arthas' Tears"}, {8838, 230, "Sungrass"}, {8839, 235, "Blindweed"},
    {8845, 245, "Ghost Mushroom"}, {8846, 250, "Gromsblood"}, {13464, 260, "Golden Sansam"}, {13463, 270, "Dreamfoil"},
    {13465, 280, "Mountain Silversage"}, {13466, 285, "Plaguebloom"}, {13467, 290, "Icecap"},
}

-- How the numbers of each herb come out of its place in the list (index i from 0) and its level L:
--   grow        firstGrow * growStep ^ i seconds (45 s for the first, about 4 h for the last)
--   harvest     firstYield + i / yieldEvery
--   profit      what one plot earns in an hour with this herb: profitPerHour * profitStep ^ (L - 1)
--   seed cost   seedShare of what the harvest sells for; the rest is the profit
--   xp          harvest xp is small on purpose (the Workshop and the Market give the xp): one plot growing this herb for
--               xpHours hours makes harvestXPShare of the xp of its level
B.HERB_CURVE = {
    firstGrow = 45, growStep = 1.25, firstYield = 3, yieldEvery = 6,
    profitPerHour = 600, profitStep = 1.05, seedShare = 0.35,
    xpHours = 8, harvestXPShare = 0.15,
}

local function Round(x)                                -- 2 significant digits, so prices read well
    if x < 10 then return math.max(1, math.floor(x + 0.5)) end
    local mag = 1
    while x >= 100 * mag do mag = mag * 10 end
    return math.floor(x / mag + 0.5) * mag
end
B.Round = Round

function B.XPToNext(level)
    local h = B.HERBALISM
    return Round(h.xpBase * level * (1 + level / h.xpGrowth))
end

-- Herb rows built from the two tables above: {item id, level, grow seconds, seed cost, sell price, xp, harvest, name}
B.PLANTS = {}
for i, herb in ipairs(B.HERBS) do
    local c, n = B.HERB_CURVE, i - 1
    local level = math.max(1, math.floor(herb[2] / 5))
    local grow = Round(c.firstGrow * c.growStep ^ n)
    local yield = c.firstYield + math.floor(n / c.yieldEvery)
    local profit = c.profitPerHour * c.profitStep ^ (level - 1) * grow / 3600
    local gross = profit / (1 - c.seedShare)
    local cost = Round(gross * c.seedShare)
    local sell = Round(gross / yield)
    local xp = math.max(1, Round(B.XPToNext(level) * c.harvestXPShare * grow / (c.xpHours * 3600)))
    B.PLANTS[i] = {herb[1], level, grow, cost, sell, xp, yield, herb[3]}
end

-- Order slots, NPC count, quantity formula, level range, reward multipliers and XP divisor.
B.ORDERS = {
    slots = 3,
    npcCount = 6,
    quantityBase = 2,
    quantityRandom = 5,
    quantityLevels = 15,
    plantLevelRange = 15,
    payMultiplier = 1.6,
    xpDivisor = 2,
}

-- Daily order size, pay, and streak prizes.
B.DAILY = {
    qtyMultiplier = 2,        -- the daily order asks for twice the herbs of a normal order
    payMultiplier = 1.25,     -- coins per herb: 1.25x a normal order (with twice the herbs, 2.5x a normal order in all)
    xpMultiplier = 2.5,       -- xp per herb: 2.5x a normal order
    streak = {                -- extra prize when a streak reaches the day, once per streak; never coins (no excess of gold)
        [3] = {xp = 1.0},              -- add 100% of the day's xp
        [7] = {xp = 1.0, rare = 1},    -- add 100% xp and one rare keepsake
        [14] = {xp = 2.0, rare = 1},   -- add 200% xp and one rare keepsake
        [30] = {xp = 3.0, rare = 2},   -- add 300% xp and two rare keepsakes
    },
    rareEvery = 7,            -- after day 30, give one rare keepsake every 7 streak days
    rareItem = 13468,         -- Black Lotus, the keepsake shown by its game icon
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

-- While you were away (Away.lua): the window tells what happened only after this long closed (seconds).
B.AWAY = {minSeconds = 1800}

-- Initial coins and plot count for a new homestead.
B.STARTING = {coins = 40, plots = 2}
KH.defaults.coins = B.STARTING.coins
KH.defaults.nplots = B.STARTING.plots

