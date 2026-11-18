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
-- The Market: 4 herb orders and 4 Workshop item orders (docs/economia.md, rule 4).
--   xpFactor            a herb order gives this many times the harvest xp of the herbs it takes
--   goods*              item orders: amount (base + random + one more every goodsLevels), pay and xp over the item's value
B.ORDERS = {
    herbSlots = 4, goodsSlots = 4, slots = 8,
    xpFactor = 3,
    goodsBase = 1, goodsRandom = 2, goodsLevels = 20,
    goodsPayMultiplier = 1.6, goodsXpFactor = 2,
    npcCount = 6,
    quantityBase = 2,
    quantityRandom = 5,
    quantityLevels = 15,
    plantLevelRange = 15,
    payMultiplier = 1.6,
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

-- The buildings walk with the Village (docs/economia.md, rule 6): building level n needs Village level BUILD_GATE[n], and
-- costs BUILD_HOURS[n] hours of what the Garden earns at that Village level (n + 1 plots, the best herb), times the weight
-- of the building. So the coins never run far ahead of the costs, and nothing is bought too early.
B.BUILD_GATE = {1, 5, 12, 20, 30, 42, 55}
B.BUILD_HOURS = {0.5, 0.5, 1.5, 3, 5, 8, 12}       -- level 1 is free for the buildings the village starts with
B.BUILD_WEIGHT = {hall = 1.0, garden = 1.2, barn = 0.6, market = 0.8, mine = 1.0, pond = 1.0, workshop = 1.2, inn = 1.3}
B.STARTS_BUILT = {hall = true, garden = true, barn = true, market = true}

-- coins an hour from the Garden at a Village level with this many plots (the profit the herbs are built on)
function B.GardenIncome(level, plots)
    local c = B.HERB_CURVE
    return c.profitPerHour * c.profitStep ^ (level - 1) * plots
end

-- Building upgrade costs in coins, indexed by target level (built from the rule above).
B.COST = {}
for id, weight in pairs(B.BUILD_WEIGHT) do
    B.COST[id] = {}
    for n, gate in ipairs(B.BUILD_GATE) do
        local free = n == 1 and B.STARTS_BUILT[id]
        B.COST[id][n] = free and 0 or Round(B.BUILD_HOURS[n] * B.GardenIncome(gate, n + 1) * weight)
    end
end

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
-- Ore and fish: sell price at Village 1 (it grows with the Village level like the herbs, B.HERB_CURVE.profitStep) and
-- units an hour per level of the Mine or the Pond. Workshop items have no fixed price: Workshop.Value.
B.GOODS = {
    ore = {sell = 6, perHour = 6, item = 2770}, fish = {sell = 5, perHour = 5, item = 6303},
    -- the rare finds of the events (docs/eventos.md): a fish of the Pond, an ore of the Mine; game items, worth about
    -- twelve minutes of the Garden when found (their price grows with the Village like the herbs)
    lobster = {sell = 600, item = 13888, rare = "fish"},     -- Darkclaw Lobster
    eel = {sell = 720, item = 13422, rare = "fish"},         -- Stonescale Eel
    firefin = {sell = 480, item = 6359, rare = "fish"},      -- Firefin Snapper (not "snapper": that is the Workshop recipe)
    truesilver = {sell = 600, item = 7911, rare = "ore"},    -- Truesilver Ore
    darkiron = {sell = 720, item = 11370, rare = "ore"},     -- Dark Iron Ore
    arcane = {sell = 960, item = 12363, rare = "ore"},       -- Arcane Crystal
}
B.RARE_ORDER = {"lobster", "eel", "firefin", "truesilver", "darkiron", "arcane"}

-- Random events (docs/eventos.md, approved on 17/11). Only with the game open; at most maxOpen at once; the deadline runs
-- by the clock. Missing one loses its chance and its xp, nothing else.
--   gapMin/gapMax   seconds of play between two events      weights  how often each kind comes (out of their sum)
--   urgent          an order of qtyFactor x a normal one, paying payFactor x its coins and xpFactor x its xp
--   merchant        buys one thing at priceFactor x its price, up to max units
--   caravan         trades: the player receives gainMin..gainMax times the value of what they give; never coins
--   fish, ore       a rare find to collect; findXP = share of the xp of the level
--   capMinutes      the most an urgent order or a merchant adds over selling the same things at the Market, in minutes of
--                   what the Garden makes now: late herbs and Workshop items are worth hours of a plot each, so past this
--                   they ask or buy fewer units (the price stays double)
B.EVENTS = {
    gapMin = 2700, gapMax = 7200, maxOpen = 2, capMinutes = 20,
    weights = {urgent = 30, merchant = 25, caravan = 20, fish = 12.5, ore = 12.5},
    urgent = {time = 2700, qtyFactor = 1.5, payFactor = 2, xpFactor = 3},
    merchant = {time = 7200, priceFactor = 2, max = 20},
    caravan = {time = 10800, trades = 3, gainMin = 1.1, gainMax = 1.3},
    fish = {time = 14400, findXP = 0.1},
    ore = {time = 14400, findXP = 0.1},
}

-- Seconds in one hour, used to convert a per-hour production rate into elapsed seconds.
B.SECONDS_PER_HOUR = 3600

-- Barn capacity per level and market pay bonus per level above the first.
B.BARN_PER_LEVEL = 40
B.MARKET_BONUS_PER_LEVEL = 0.04

-- The Workshop always pays more than its raw materials, in coins and in xp (docs/economia.md, rule 5):
--   value  = markup * (sell price of the inputs) + perMinute * minutes of crafting
--   xp     = xpFactor * (harvest xp of the herb inputs, per herb) + xpPerMinute * minutes
--   ore and fish count goodXP each as an input
B.CRAFT = {markup = 1.5, perMinute = 2, xpFactor = 4, xpPerMinute = 1, goodXP = 0.5,
    queueBase = 3, queuePerLevel = 1}        -- places in the queue: 3 at Workshop 1, one more each level (9 at 7)

-- Workshop recipes: recipe id, trade, required level, craft seconds, and input item ids or goods.
-- One recipe per trade at each Workshop level (1-7), following the game's own ladder, with the herbs open at the Village
-- level that Workshop level asks (B.BUILD_GATE). `item` is the game item whose icon (and look) the good takes.
B.RECIPES = {
    {id = "heal", trade = "alchemy", level = 1, time = 120, item = 118, inputs = {{2447, 3}, {765, 1}}},       -- Minor Healing Potion
    {id = "agil", trade = "alchemy", level = 2, time = 240, item = 2457, inputs = {{765, 2}, {2449, 2}}},      -- Elixir of Minor Agility
    {id = "mana", trade = "alchemy", level = 3, time = 360, item = 2455, inputs = {{785, 2}, {2449, 2}}},      -- Minor Mana Potion
    {id = "healing", trade = "alchemy", level = 4, time = 600, item = 929, inputs = {{2453, 2}, {2450, 2}}},   -- Healing Potion
    {id = "greater", trade = "alchemy", level = 5, time = 1200, item = 1710, inputs = {{3357, 2}, {3356, 2}}}, -- Greater Healing Potion
    {id = "superior", trade = "alchemy", level = 6, time = 2400, item = 3928, inputs = {{3358, 2}, {8831, 1}}},-- Superior Healing Potion
    {id = "major", trade = "alchemy", level = 7, time = 3600, item = 13446, inputs = {{13464, 2}, {13463, 1}}},-- Major Healing Potion
    {id = "stew", trade = "cooking", level = 1, time = 90, item = 13931, inputs = {{"fish", 4}}},
    {id = "snapper", trade = "cooking", level = 2, time = 180, item = 4592, inputs = {{"fish", 6}}},           -- Longjaw Mud Snapper
    {id = "roast", trade = "cooking", level = 3, time = 300, item = 13935, inputs = {{"fish", 10}, {2447, 2}}},
    {id = "cod", trade = "cooking", level = 4, time = 600, item = 4594, inputs = {{"fish", 14}, {3820, 1}}},   -- Rockscale Cod
    {id = "feast", trade = "cooking", level = 5, time = 1200, item = 21023, inputs = {{"fish", 24}, {785, 2}}},
    {id = "yellowtail", trade = "cooking", level = 6, time = 2400, item = 6887, inputs = {{"fish", 30}, {3818, 1}}}, -- Spotted Yellowtail
    {id = "mightfish", trade = "cooking", level = 7, time = 3600, item = 13927, inputs = {{"fish", 40}, {8838, 1}}}, -- Glossy Mightfish
    {id = "copper", trade = "smithing", level = 1, time = 100, item = 2840, inputs = {{"ore", 4}}},            -- Copper Bar
    {id = "bar", trade = "smithing", level = 2, time = 200, item = 3575, inputs = {{"ore", 6}}},
    {id = "tools", trade = "smithing", level = 3, time = 540, item = 5956, inputs = {{"ore", 16}}},
    {id = "mithril", trade = "smithing", level = 4, time = 900, item = 3860, inputs = {{"ore", 20}}},         -- Mithril Bar
    {id = "blade", trade = "smithing", level = 5, time = 1500, item = 3487, inputs = {{"ore", 40}, {2450, 1}}},
    {id = "thorium", trade = "smithing", level = 6, time = 2400, item = 12359, inputs = {{"ore", 50}}},       -- Thorium Bar
    {id = "arcanite", trade = "smithing", level = 7, time = 3600, item = 12360, inputs = {{"ore", 60}, {13466, 1}}}, -- Arcanite Bar
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

