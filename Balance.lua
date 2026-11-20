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
    core = {sell = 900, item = 17010},                       -- the Core of the raids (Fiery Core): equipment of level 7
    -- pieces with a name (docs/masmorras.md §8): equipment above the Workshop's, from the raids. Real items of the
    -- Forever tied to Onyxia: the blade tempered in her fire and the cloak made of her scales.
    quelserrar = {sell = 2400, item = 18348, gear = {slot = "weapon", power = 9}},
    onyxcloak = {sell = 2400, item = 15138, gear = {slot = "armor", power = 9}},
}
B.NAMED = {onyxia = {"quelserrar", "onyxcloak"}}
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
    weights = {urgent = 30, merchant = 25, caravan = 20, fish = 12.5, ore = 12.5, call = 40},
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
    -- Equipment for the followers (docs/masmorras.md §4): a weapon and an armor at each Workshop level, made of the bars
    -- of the Smithing trade; `power` is the level of the piece (+1 chance point each). Level 7 also asks a raid Core.
    {id = "gw1", trade = "gear", slot = "weapon", power = 1, level = 1, time = 600, item = 2847, inputs = {{"copper", 3}}},   -- Copper Shortsword
    {id = "ga1", trade = "gear", slot = "armor", power = 1, level = 1, time = 600, item = 3471, inputs = {{"copper", 3}}},    -- Copper Chain Vest
    {id = "gw2", trade = "gear", slot = "weapon", power = 2, level = 2, time = 1200, item = 3848, inputs = {{"bar", 3}}},     -- Big Bronze Knife
    {id = "ga2", trade = "gear", slot = "armor", power = 2, level = 2, time = 1200, item = 3842, inputs = {{"bar", 3}}},      -- Green Iron Leggings
    {id = "gw3", trade = "gear", slot = "weapon", power = 3, level = 3, time = 1800, item = 3849, inputs = {{"bar", 3}, {"tools", 1}}},  -- Hardened Iron Shortsword
    {id = "ga3", trade = "gear", slot = "armor", power = 3, level = 3, time = 1800, item = 3844, inputs = {{"bar", 3}, {"tools", 1}}},   -- Green Iron Hauberk
    {id = "gw4", trade = "gear", slot = "weapon", power = 4, level = 4, time = 2400, item = 7941, inputs = {{"mithril", 3}}},  -- Heavy Mithril Axe
    {id = "ga4", trade = "gear", slot = "armor", power = 4, level = 4, time = 2400, item = 7930, inputs = {{"mithril", 3}}},   -- Heavy Mithril Breastplate
    {id = "gw5", trade = "gear", slot = "weapon", power = 5, level = 5, time = 3000, item = 7945, inputs = {{"mithril", 3}, {"blade", 1}}}, -- Big Black Mace
    {id = "ga5", trade = "gear", slot = "armor", power = 5, level = 5, time = 3000, item = 7939, inputs = {{"mithril", 3}, {"blade", 1}}},  -- Truesilver Breastplate
    {id = "gw6", trade = "gear", slot = "weapon", power = 6, level = 6, time = 3600, item = 12773, inputs = {{"thorium", 3}}}, -- Ornate Thorium Handaxe
    {id = "ga6", trade = "gear", slot = "armor", power = 6, level = 6, time = 3600, item = 12405, inputs = {{"thorium", 3}}},  -- Thorium Armor
    {id = "gw7", trade = "gear", slot = "weapon", power = 7, level = 7, time = 4800, item = 12784, inputs = {{"arcanite", 2}, {"core", 1}}}, -- Arcanite Reaper
    {id = "ga7", trade = "gear", slot = "armor", power = 7, level = 7, time = 4800, item = 12640, inputs = {{"arcanite", 2}, {"core", 1}}},  -- Lionheart Helm
}

-- ----------------------------------------------------------------------------------------------------------------
-- Dungeons and followers (docs/masmorras.md, approved on 18/11). Icons are the ones of the game (Interface\Icons\...).
-- ----------------------------------------------------------------------------------------------------------------
-- The eight threats a dungeon can have
B.THREATS = {
    horde = "ability_warrior_cleave",              -- many enemies
    boss = "ability_warrior_savageblow",           -- a brutal boss
    magic = "spell_shadow_shadowbolt",             -- hostile magic
    poison = "ability_creature_poison_03",         -- poison and disease
    traps = "spell_fire_selfdestruct",
    undead = "spell_shadow_raisedead",
    fear = "spell_shadow_possession",
    armored = "ability_warrior_defensivestance",
}
B.THREAT_ORDER = {"horde", "boss", "magic", "poison", "traps", "undead", "fear", "armored"}

-- What each ability counters (a list: the legendary signatures counter two) and its icon.
B.ABILITIES = {
    volley = {counters = {"horde"}, icon = "ability_upgrademoonglaive"},
    eagle = {counters = {"traps"}, icon = "ability_hunter_eagleeye"},
    aimed = {counters = {"boss"}, icon = "ability_hunter_snipershot"},
    hammer = {counters = {"armored"}, icon = "inv_hammer_04"},
    locks = {counters = {"traps"}, icon = "inv_misc_key_03"},
    silver = {counters = {"undead"}, icon = "inv_weapon_shortblade_05"},
    herbs = {counters = {"poison"}, icon = "spell_nature_healingtouch"},
    holy = {counters = {"undead"}, icon = "spell_holy_holybolt"},
    balm = {counters = {"fear"}, icon = "spell_nature_slow"},
    shield = {counters = {"boss"}, icon = "ability_warrior_shieldwall"},
    warcry = {counters = {"fear"}, icon = "ability_warrior_battleshout"},
    whirl = {counters = {"horde"}, icon = "ability_whirlwind"},
    counter = {counters = {"magic"}, icon = "spell_frost_iceshock"},
    fireball = {counters = {"undead"}, icon = "spell_fire_fireball02"},
    blizzard = {counters = {"horde"}, icon = "spell_frost_icestorm"},
    courage = {counters = {"fear"}, icon = "spell_holy_restoration"},
    distract = {counters = {"traps"}, icon = "ability_rogue_distract"},
    dissonant = {counters = {"magic"}, icon = "spell_holy_silence"},
    -- the followers that are found (S5): two abilities each; a Legendary has one that counters two threats
    gust = {counters = {"horde"}, icon = "spell_nature_cyclone"},
    lightstep = {counters = {"traps"}, icon = "ability_rogue_sprint"},
    totem = {counters = {"poison"}, icon = "spell_nature_poisoncleansingtotem"},
    earthshield = {counters = {"boss"}, icon = "spell_nature_stoneskintotem"},
    unholy = {counters = {"undead"}, icon = "spell_holy_flashheal"},
    devotion = {counters = {"armored"}, icon = "spell_holy_devotionaura"},
    ruinlore = {counters = {"traps"}, icon = "inv_misc_map_01"},
    oldlore = {counters = {"magic"}, icon = "inv_misc_book_09"},
    voodoo = {counters = {"fear"}, icon = "spell_shadow_unholyfrenzy"},
    barbed = {counters = {"horde"}, icon = "ability_impalingbolt"},
    greatcounter = {counters = {"magic"}, icon = "spell_nature_wispsplode"},
    teleport = {counters = {}, short = 0.20, icon = "spell_arcane_blink"},
    rejuv = {counters = {"poison"}, icon = "spell_nature_rejuvenation"},
    bear = {counters = {"boss"}, icon = "ability_racial_bearform"},
    stealth = {counters = {"traps"}, icon = "ability_stealth"},
    cheapshot = {counters = {"boss"}, icon = "ability_cheapshot"},
    frosttrap = {counters = {"horde"}, icon = "spell_frost_chainsofice"},
    serene = {counters = {"fear"}, icon = "spell_nature_drowsy"},
    zephras = {counters = {"horde", "magic"}, icon = "spell_nature_callstorm"},
    bastion = {counters = {"boss", "armored"}, icon = "inv_shield_05"},
    ancestral = {counters = {"undead", "fear"}, icon = "spell_holy_prayerofhealing"},
}

-- Traits: the first comes with the follower, the second is picked at Epic (one of the follower's `epic`).
--   points  chance points, counted `when` the dungeon is of one of those environments, or against `threat`
--   perOther  points for each other follower in the group      rare  points of rare find chance
--   xp  more xp for itself      groupXP  more xp for the whole group      short  the run takes this much less time
--   neverInjured   never comes back hurt      gear  the gear of this follower counts this many levels more (S4)
B.TRAITS = {
    forest = {points = 10, when = {"cave", "natural"}},
    ironhands = {gear = 1},
    wise = {groupXP = 0.10},
    fearsUndead = {points = -10, threat = "undead", untilLevel = 20},
    curious = {rare = 5},
    company = {perOther = 5},
    swift = {short = 0.15},
    lucky = {rare = 10},
    tough = {neverInjured = true},
    quick = {xp = 0.25},
    partner = {points = 10},           -- with the follower named in its argument in the same group
    likes = {points = 10},             -- in dungeons of the environment named in its argument
}

-- The followers. `rare` = the two abilities to pick from at Rare; `epic` = the two traits to pick from at Epic
-- ({"likes", env} and {"partner", follower} carry their argument). `portrait` = Media/Village/follower<n>.
B.FOLLOWERS = {
    {id = "mira", portrait = 1, rarity = "uncommon", start = "volley", rare = {"eagle", "aimed"}, trait = "forest",
        epic = {{"swift"}, {"lucky"}}},
    {id = "tobin", portrait = 2, rarity = "uncommon", start = "hammer", rare = {"locks", "silver"}, trait = "ironhands",
        epic = {{"tough"}, {"likes", "fortress"}}},
    {id = "elda", portrait = 3, rarity = "uncommon", start = "herbs", rare = {"holy", "balm"}, trait = "wise",
        epic = {{"quick"}, {"likes", "cave"}}},
    {id = "garrick", portrait = 4, rarity = "uncommon", start = "shield", rare = {"warcry", "whirl"}, trait = "fearsUndead",
        epic = {{"tough"}, {"partner", "elda"}}},
    {id = "sela", portrait = 5, rarity = "uncommon", start = "counter", rare = {"fireball", "blizzard"}, trait = "curious",
        epic = {{"lucky"}, {"likes", "crypt"}}},
    {id = "bram", portrait = 6, rarity = "uncommon", start = "courage", rare = {"distract", "dissonant"}, trait = "company",
        epic = {{"swift"}, {"partner", "mira"}}},
    -- The ones that are found (docs/masmorras.md §3.5; the names and the looks: docs/tarefas/A8.md). They come Rare, Epic
    -- or Legendary, with their abilities already (`second`), and only from their place: `from` = {dungeon = id} a drop of
    -- that dungeon, {raid = id} of that raid, {rescue = place} someone saved in a rescue call there. `legendary` marks
    -- the rare one of a place that has another. Provisional places (approved on 19/11) until their own content comes
    -- out: Tazu (Darkspear Island), Faelan and Shalendra (Mount Hyjal), Elandor (Dalaran), Ilyanna (Hyjal Summit),
    -- Hargrim (Barrow Deeps).
    {id = "lyra", portrait = 7, rarity = "rare", start = "gust", second = "lightstep", trait = "quick",
        epic = {{"swift"}, {"partner", "ilyanna"}}, from = {rescue = "zephras"}},
    {id = "hoderik", portrait = 8, rarity = "rare", start = "totem", second = "earthshield", trait = {"likes", "fortress"},
        epic = {{"tough"}, {"partner", "hargrim"}}, from = {dungeon = "thanes"}},
    {id = "aldric", portrait = 9, rarity = "rare", start = "unholy", second = "devotion", trait = {"likes", "crypt"},
        epic = {{"tough"}, {"likes", "ruins"}}, from = {dungeon = "lordaeron"}},
    {id = "fizzwick", portrait = 10, rarity = "rare", start = "ruinlore", second = "oldlore", trait = "curious",
        epic = {{"lucky"}, {"likes", "ruins"}}, from = {dungeon = "excavation"}},
    {id = "tazu", portrait = 11, rarity = "rare", start = "voodoo", second = "barbed", trait = "forest",
        epic = {{"swift"}, {"quick"}}, from = {rescue = "drowned"}},
    {id = "elandor", portrait = 12, rarity = "epic", start = "greatcounter", second = "teleport", trait = "wise",
        epic = {{"lucky"}, {"partner", "sela"}}, from = {rescue = "alcaz"}},
    {id = "faelan", portrait = 13, rarity = "epic", start = "rejuv", second = "bear", trait = "forest",
        epic = {{"tough"}, {"partner", "shalendra"}}, from = {rescue = "blackmaw"}},
    {id = "corvo", portrait = 14, rarity = "epic", start = "stealth", second = "cheapshot", trait = "lucky",
        epic = {{"swift"}, {"likes", "fortress"}}, from = {rescue = "alcaz"}},
    {id = "brakka", portrait = 15, rarity = "epic", start = "frosttrap", second = "serene", trait = "company",
        epic = {{"tough"}, {"likes", "cave"}}, from = {rescue = "blackmaw"}},
    {id = "ilyanna", portrait = 16, rarity = "legendary", start = "zephras", trait = "wise",
        epic = {{"swift"}, {"lucky"}}, from = {raid = "onyxia"}},
    {id = "hargrim", portrait = 17, rarity = "legendary", start = "bastion", trait = "ironhands",
        epic = {{"tough"}, {"likes", "fortress"}}, from = {dungeon = "thanes", legendary = true}},
    {id = "shalendra", portrait = 18, rarity = "legendary", start = "ancestral", trait = "tough",
        epic = {{"lucky"}, {"likes", "crypt"}}, from = {rescue = "blackmaw", legendary = true}},
}

-- How the new followers come (docs/masmorras.md §3.5)
--   dungeon     the chance on a success, by the level of the dungeon (only where someone is from)
--   legendaryShare  where a Legendary lives beside another follower, this share of the finds is the Legendary
--   raidLegendary   the chance of the Legendary of a raid on a success; raidLuck = what killing a raid boss with the
--                   character adds to it, once (the Adventure)
--   rescue      the chance that who was saved in a rescue call stays
--   guarantee   after this many dungeons with nobody new, the next success brings a Rare
B.NEWCOMER = {dungeon = {{upTo = 10, chance = 0.01}, {upTo = 20, chance = 0.02}, {upTo = 30, chance = 0.03}},
    legendaryShare = 0.10, raidLegendary = 0.02, raidLuck = 0.10, rescue = 0.25, guarantee = 40}

-- Power: one number for a follower, for the Ranking (level, quality and equipment)
B.POWER = {level = 10, gear = 5, quality = {uncommon = 0, rare = 40, epic = 80, legendary = 150}}

-- The rooms of the Inn: one per level. Who is in a room goes out and gives its bonus at home; the others wait in the
-- Lodging (a roster of up to `roster`).
B.ROOMS = {max = 7, roster = 20}

-- The places of the calls (docs/historia-forever.md: only what the Forever's Wowhead confirms). threats = what is
-- there; `dungeon` = it is also a dungeon of the list (a reconnaissance spies it).
B.PLACES = {
    zephras = {threats = {"magic", "horde", "fear"}, env = "natural"},
    thanes = {threats = {"armored", "magic", "horde"}, env = "fortress", dungeon = true},
    lordaeron = {threats = {"undead", "poison", "fear"}, env = "ruins", dungeon = true},
    excavation = {threats = {"horde", "traps", "magic"}, env = "ruins", dungeon = true},
    drowned = {threats = {"undead", "magic", "horde"}, env = "ruins", dungeon = true},
    kroldok = {threats = {"horde", "boss", "magic"}, env = "fortress", dungeon = true},
    alcaz = {threats = {"horde", "magic", "boss"}, env = "fortress", dungeon = true},
    blackmaw = {threats = {"horde", "fear", "magic"}, env = "cave", dungeon = true},
}
B.PLACE_ORDER = {"zephras", "thanes", "lordaeron", "excavation", "drowned", "kroldok", "alcaz", "blackmaw"}

-- The calls (docs/masmorras.md §10): events for the followers, in the engine of the visitors.
--   size = {least, most} followers     hours = {least, most}     time = seconds to accept     threats = how many
--   mult  the reward beside a dungeon of the same time (0: no coins)   merit  chance of a Merit insignia
--   scout  chance points the dungeon spied gets on its next run
--   levelDown  a call is made for up to this many levels under the best follower in the rooms
--   visited  how much more often a place the character has been to calls
B.CALLS = {
    order = {"defense", "attack", "escort", "rescue", "recon"},
    defense = {size = {1, 3}, hours = {0.5, 1.5}, time = 2700, threats = 2, mult = 1.5},
    attack = {size = {2, 3}, hours = {1, 2}, time = 7200, threats = 3, mult = 2, merit = 0.15},
    escort = {size = {1, 2}, hours = {1, 1}, time = 7200, threats = 1, mult = 1.5},
    rescue = {size = {2, 3}, hours = {1, 2}, time = 10800, threats = 2, mult = 1.5},
    recon = {size = {1, 1}, hours = {0.5, 0.5}, time = 7200, threats = 1, mult = 0, scout = 10},
    levelDown = 3, visited = 3,
}

-- The dungeons of WoW Forever that its Wowhead already has (rule of 19/11: what it does not have does not exist yet).
-- level = the follower level it is made for; size = followers it asks; hours = how long it takes.
B.DUNGEONS = {
    {id = "ragefire", level = 1, size = 1, hours = 1, threats = {"horde", "magic"}, env = "cave"},
    {id = "thanes", level = 2, size = 1, hours = 1, threats = {"armored", "magic"}, env = "fortress", new = true},
    {id = "lordaeron", level = 3, size = 1, hours = 1, threats = {"undead", "poison"}, env = "ruins", new = true},
    {id = "wailing", level = 4, size = 1, hours = 1.5, threats = {"poison", "fear"}, env = "cave"},
    {id = "deadmines", level = 5, size = 2, hours = 1.5, threats = {"horde", "traps"}, env = "cave"},
    {id = "shadowfang", level = 6, size = 2, hours = 1.5, threats = {"undead", "magic"}, env = "fortress"},
    {id = "excavation", level = 7, size = 2, hours = 2, threats = {"horde", "magic", "traps"}, env = "ruins", new = true},
    {id = "blackfathom", level = 8, size = 2, hours = 2, threats = {"horde", "poison"}, env = "ruins"},
    {id = "gnomeregan", level = 10, size = 2, hours = 2.5, threats = {"traps", "armored", "horde"}, env = "fortress"},
    {id = "scarlet", level = 12, size = 3, hours = 2.5, threats = {"horde", "magic", "boss"}, env = "fortress"},
    {id = "drowned", level = 13, size = 3, hours = 3, threats = {"undead", "magic", "horde"}, env = "ruins", new = true},
    {id = "kroldok", level = 15, size = 3, hours = 3, threats = {"horde", "magic", "boss"}, env = "fortress", new = true},
    {id = "uldaman", level = 17, size = 3, hours = 3.5, threats = {"armored", "traps", "magic"}, env = "ruins"},
    {id = "zulfarrak", level = 19, size = 3, hours = 3.5, threats = {"horde", "poison", "boss"}, env = "ruins"},
    {id = "alcaz", level = 20, size = 3, hours = 4, threats = {"horde", "magic", "boss"}, env = "fortress", new = true},
    {id = "maraudon", level = 22, size = 3, hours = 4, threats = {"poison", "armored", "fear"}, env = "cave"},
    {id = "sunken", level = 24, size = 3, hours = 4.5, threats = {"magic", "poison", "fear", "horde"}, env = "ruins"},
    {id = "brd", level = 26, size = 3, hours = 5, threats = {"armored", "magic", "horde", "boss"}, env = "fortress"},
    {id = "blackmaw", level = 28, size = 3, hours = 5, threats = {"horde", "magic", "fear"}, env = "cave", new = true},
    {id = "scholomance", level = 30, size = 3, hours = 6, threats = {"undead", "magic", "fear", "poison"}, env = "crypt"},
    {id = "stratholme", level = 30, size = 3, hours = 6, threats = {"undead", "horde", "boss", "fear"}, env = "crypt"},
    -- the raids: once every B.RAID.every seconds each, counted from when it was done
    {id = "onyxia", level = 30, size = 6, hours = 24, threats = {"boss", "magic", "fear", "horde", "armored"}, env = "cave",
        raid = true},
}

-- The trophy of each dungeon: a real item that drops there in the game (its icon). The new dungeons of the Forever get
-- theirs when the Wowhead of the Forever lists what drops in them.
B.TROPHIES = {
    ragefire = 14145, wailing = 6627, deadmines = 5191, shadowfang = 6220, blackfathom = 6909, gnomeregan = 9492,
    scarlet = 7717, uldaman = 9418, zulfarrak = 9372, maraudon = 17780, sunken = 10837, brd = 11684,
    scholomance = 13937, stratholme = 13505, onyxia = 18422,
}

-- The game's own ids of the dungeons (GetInstanceInfo), to know where the character is (the Adventure, §12). The new
-- dungeons of the Forever are found by their name.
B.INSTANCES = {
    [389] = "ragefire", [43] = "wailing", [36] = "deadmines", [33] = "shadowfang", [48] = "blackfathom",
    [90] = "gnomeregan", [189] = "scarlet", [70] = "uldaman", [209] = "zulfarrak", [349] = "maraudon",
    [109] = "sunken", [230] = "brd", [289] = "scholomance", [329] = "stratholme", [249] = "onyxia",
}

-- Combos: two abilities of different followers in the same group (docs/masmorras.md §7)
--   points  chance points     short  run this much shorter     fxp  more follower xp     coins  more coins
--   noHurt  nobody hurt        rare  rare chance x            undead  points against the undead      crypt  trophy sure in crypts
--   boss  points with the optional boss
B.COMBOS = {
    {id = "wall", a = {"shield"}, b = {"herbs"}, noHurt = true},
    {id = "crossfire", a = {"volley"}, b = {"fireball", "blizzard"}, points = 15},
    {id = "backdoor", a = {"locks"}, b = {"distract"}, short = 0.25},
    {id = "blessed", a = {"silver"}, b = {"holy"}, undead = 20, crypt = true},
    {id = "chorus", a = {"courage"}, b = {"warcry"}, fxp = 0.25},
    {id = "eyes", a = {"eagle"}, b = {"counter"}, rare = 2},
    {id = "storm", a = {"blizzard"}, b = {"whirl"}, coins = 0.25},
    {id = "shotshield", a = {"aimed"}, b = {"shield"}, points = 10, boss = 10},
}

-- The rules of a run (docs/masmorras.md §3, §6, §8 and §9)
--   threat     points one uncountered threat takes          below/above  points per level the group is under/over it
--   threatEarly  the first dungeons forgive more: up to that level a threat left takes only this much (owner, 19/11)
--   missing    points per follower missing                  aboveMax     the most the levels above add
--   maxChance  the chance counts up to this; what passes 100 becomes a reward bonus (150 = x1.5)
--   coinShare  coins per follower per hour, as a share of what the Garden makes in one hour now
--   xpShare    village xp per follower per hour, as a share of the xp of the level now
--   fishPerHour   fish per follower per hour of road
--   fxpBase, fxpPerLevel   follower xp of a run: base + perLevel x dungeon level (half on a failure)
--   lowGap, lowXP   a dungeon more than lowGap levels under the follower gives lowXP of its xp
--   openAhead  a dungeon opens when the best follower is at most this many levels under it
--   injury, injuryHours   the chance of each follower to come back hurt from a failure, and the rest it takes
--   daily      the dungeon of the day gives this much more follower xp
--   merit, epic   insignia drop chance on a success, from that dungeon level up (meritIcon, epicIcon: their icons)
B.DUNGEON = {
    threat = 25, below = 5, above = 2, aboveMax = 10, missing = 20, maxChance = 150, warnBelow = 5,
    threatEarly = {{upTo = 3, points = 10}, {upTo = 6, points = 15}, {upTo = 9, points = 20}},
    coinShare = 0.045, xpShare = 0.005, fishPerHour = 2,
    fxpBase = 60, fxpPerLevel = 4, lowGap = 5, lowXP = 0.25,
    openAhead = 3, injury = 0.30, injuryHours = 2, daily = 0.5,
    merit = {chance = 0.10, from = 8}, epic = {chance = 0.05, from = 19},
    meritIcon = "inv_jewelry_talisman_08", epicIcon = "inv_jewelry_trinketpvp_01",
    trophyMin = 0.05, trophyMax = 0.20, bossTrophy = 1.5, bossShort = 0.25,
    potion = 10, foodXP = 0.20, foodHurt = 0.5, inspired = 15, inspiredRuns = 3,
    miraTrophy = 0.05, garrickHurt = 0.10, veteran = 10, mentorXP = 0.10,
    named = 0.10,                       -- a raid: the chance of a piece with a name
}

-- The raids: once a week each (counted from when it was done); a success brings a Core and an Epic insignia
B.RAID = {every = 7 * 24 * 3600, core = 1}

-- Followers: level 1 to maxLevel; xp to the next level = xpBase + xpPerLevel x level (+ late x each level past lateFrom).
-- Rare at rareLevel with a Merit insignia, Epic at epicLevel with an Epic one. Changing a pick costs respecHours x
-- (changes + 1) hours of what the Garden makes now.
B.FOLLOWER = {maxLevel = 30, xpBase = 60, xpPerLevel = 30, late = 25, lateFrom = 20, rareLevel = 10, epicLevel = 20,
    respecHours = 1}
function B.FollowerXPToNext(level)
    local F = B.FOLLOWER
    return F.xpBase + F.xpPerLevel * level + (level >= F.lateFrom and F.late * (level - F.lateFrom + 1) or 0)
end

-- While you were away (Away.lua): the window tells what happened only after this long closed (seconds).
B.AWAY = {minSeconds = 1800}

-- Initial coins and plot count for a new homestead.
B.STARTING = {coins = 40, plots = 2}
KH.defaults.coins = B.STARTING.coins
KH.defaults.nplots = B.STARTING.plots

