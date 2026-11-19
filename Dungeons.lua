--[[
    Korum Homestead - the followers and the dungeons (docs/masmorras.md)

    The Inn shelters the followers (one more per Inn level). They go to the dungeons of WoW Forever. Each dungeon has
    threats; each follower has abilities that counter them. The chance of a run comes from the threats left uncountered,
    the levels, the group size, the traits, the equipment, the combos and the potion, and is shown before sending.
    Nobody dies: a failure brings half the reward and maybe a follower hurt for a while.

    Everything about a run is decided when it is sent (the roll, the reward, who gets hurt, what drops) and shown when the
    group comes back, so closing the game changes nothing. `opts` = {potion = good, food = good, boss = true}.

        Inn:Count() / Inn:List() / Inn:Has(id) / Inn:Get(id) / Inn.Def(id)
        Inn:State(id)                       "home" | "away" | "back" | "hurt", seconds left
        Inn:Abilities(id) / Inn:Traits(id)  what it has now
        Inn:AddXP(id, n)                    levels gained
        Inn:NextQuality(id)                 "rare" | "epic" | nil, and whether it can take it now
        Inn:Promote(id, pick)               takes the insignia and makes the pick (1 or 2)
        Inn:RespecCost(id) / Inn:Respec(id, "ability" | "trait")
        Inn:GearPower(id) / Inn:Equip(id, gearId) / Inn:Unequip(id, slot) / Inn:BestGear(id, slot)
        Inn:Master(id, "veteran" | "mentor")   at the highest level, with a Title
        Inn:BackCount() / Inn:AwayCount() / Inn:CollectAll() / Inn:Update()

        Dungeons.Get(id) / Dungeons.LIST
        Dungeons:Open(id) / Dungeons:Daily() / Dungeons:RaidLeft(id)
        Dungeons:Threats(id, opts) / Dungeons:Chance(id, party, opts)   total, parts, counters, uncountered
        Dungeons:Combos(party) / Dungeons:Known(comboId)
        Dungeons:Free(fid) / Dungeons:Recommended(id, party, opts) / Dungeons:Suggest(id, opts)
        Dungeons:Cost / Duration / Reward / TrophyChance (id, party, ...)
        Dungeons:Send(id, party, opts)      ok, why
        Dungeons:Trips() / Dungeons:Collect(n) / Dungeons:CollectAll()
]]

local addonName, KH = ...
local B = KH.Balance
local V = KH.Village

local I = {}
KH.Inn = I
local Dg = {}
KH.Dungeons = Dg

local R = B.DUNGEON

local function Has(list, x)
    for _, v in ipairs(list) do if v == x then return true end end
    return false
end
local function Roll() return (KH.Rand or math.random)(10000) / 10000 end
local function Round(x) return math.floor(x + 0.5) end
local function Opt(opts, k) return opts and opts[k] end

-- ----------------------------------------------------------------------------
-- The followers
-- ----------------------------------------------------------------------------
I.DEFS, I.BY_ID = B.FOLLOWERS, {}
for i, f in ipairs(B.FOLLOWERS) do I.BY_ID[f.id] = f; f.index = i end
I.MAX = #B.FOLLOWERS

function I.Def(id) return I.BY_ID[id] end

function I:Count() return math.min(I.MAX, V:Level("inn")) end

function I:List()
    local out = {}
    for i = 1, self:Count() do out[i] = I.DEFS[i].id end
    return out
end

function I:Has(id)
    local def = I.Def(id)
    return def ~= nil and def.index <= self:Count()
end

function I:Get(id)
    local db = KH.db
    db.followers = db.followers or {}
    local f = db.followers[id]
    if not f then
        f = {level = 1, xp = 0, quality = I.Def(id).rarity, changes = 0, runs = 0}
        db.followers[id] = f
    end
    return f
end

function I:Abilities(id)
    local def, f = I.Def(id), self:Get(id)
    local out = {def.start}
    if f.ability then out[2] = f.ability end
    return out
end

-- {{name, arg}, ...}
function I:Traits(id)
    local def, f = I.Def(id), self:Get(id)
    local out = {{def.trait}}
    if f.trait then out[2] = def.epic[f.trait] end
    return out
end

local function TripOf(fid)
    for n, trip in ipairs(KH.db.trips or {}) do
        for _, p in ipairs(trip.party) do
            if p == fid then return trip, n end
        end
    end
end

function I:State(id)
    local trip = TripOf(id)
    local now = KH.Now()
    if trip then
        local left = trip.at + trip.time - now
        if left > 0 then return "away", left end
        return "back", 0
    end
    local f = self:Get(id)
    if (f.hurt or 0) > now then return "hurt", f.hurt - now end
    return "home", 0
end

function I:AddXP(id, n)
    local f = self:Get(id)
    local gained = 0
    if f.level >= B.FOLLOWER.maxLevel then return 0 end
    f.xp = f.xp + n
    while f.level < B.FOLLOWER.maxLevel and f.xp >= B.FollowerXPToNext(f.level) do
        f.xp = f.xp - B.FollowerXPToNext(f.level)
        f.level = f.level + 1
        gained = gained + 1
    end
    if f.level >= B.FOLLOWER.maxLevel then f.xp = 0 end
    return gained
end

function I:Insignias()
    local d = KH.db.dungeons
    return d.merit or 0, d.epic or 0
end

-- the next quality and whether it can be taken now (level and insignia); a quality the follower reached without its pick
-- (born Rare or Epic) only asks for the pick
function I:NextQuality(id)
    local f = self:Get(id)
    local merit, epic = self:Insignias()
    if not f.ability then
        local ok = f.quality ~= "uncommon" or (f.level >= B.FOLLOWER.rareLevel and merit > 0)
        return "rare", ok
    end
    if not f.trait then
        local ok = f.quality == "epic" or f.quality == "legendary" or (f.level >= B.FOLLOWER.epicLevel and epic > 0)
        return "epic", ok
    end
    return nil, false
end

function I:Promote(id, pick)
    local q, ok = self:NextQuality(id)
    if not q or not ok or (pick ~= 1 and pick ~= 2) then return false end
    local f, def, d = self:Get(id), I.Def(id), KH.db.dungeons
    if q == "rare" then
        if f.quality == "uncommon" then d.merit = d.merit - 1; f.quality = "rare" end
        f.ability = def.rare[pick]
    else
        if f.quality == "uncommon" or f.quality == "rare" then d.epic = d.epic - 1; f.quality = "epic" end
        f.trait = pick
    end
    KH.Journal:Mark(id, q)
    return true
end

function I:RespecCost(id)
    return Round(B.GardenIncome(KH.db.level, V:Plots()) * B.FOLLOWER.respecHours * (self:Get(id).changes + 1))
end

-- changes a pick already made: "ability" or "trait", to the other option
function I:Respec(id, what)
    local f, def = self:Get(id), I.Def(id)
    if self:State(id) ~= "home" and self:State(id) ~= "hurt" then return false, "away" end
    local cost = self:RespecCost(id)
    if KH.db.coins < cost then return false, "coins" end
    if what == "ability" and f.ability then
        f.ability = f.ability == def.rare[1] and def.rare[2] or def.rare[1]
    elseif what == "trait" and f.trait then
        f.trait = 3 - f.trait
    else
        return false, "nothing"
    end
    KH.db.coins = KH.db.coins - cost
    f.changes = f.changes + 1
    return true
end

-- the chance points of the equipment of a follower (Iron hands: each piece one level more)
function I:GearPower(id)
    local f = self:Get(id)
    local extra = 0
    for _, t in ipairs(self:Traits(id)) do extra = extra + (B.TRAITS[t[1]].gear or 0) end
    local sum = 0
    for _, gid in pairs(f.gear or {}) do
        local r = KH.Workshop.Recipe(gid)
        if r then sum = sum + r.power + extra end
    end
    return sum
end

-- puts a piece from the Barn on the follower; the one it had goes back to the Barn
function I:Equip(id, gid)
    local r = KH.Workshop.Recipe(gid)
    if not r or r.trade ~= "gear" then return false, "nothing" end
    if V:Good(gid) < 1 then return false, "noGear" end
    local f = self:Get(id)
    f.gear = f.gear or {}
    local db = KH.db
    local old = f.gear[r.slot]
    if old then db.goods[old] = V:Good(old) + 1 end
    db.goods[gid] = V:Good(gid) - 1
    f.gear[r.slot] = gid
    return true
end

function I:Unequip(id, slot)
    local f = self:Get(id)
    local gid = f.gear and f.gear[slot]
    if not gid then return false end
    KH.db.goods[gid] = V:Good(gid) + 1
    f.gear[slot] = nil
    return true
end

-- the best piece of a slot in the Barn that is better than what the follower wears
function I:BestGear(id, slot)
    local f = self:Get(id)
    local now = f.gear and f.gear[slot]
    local power = now and KH.Workshop.Recipe(now).power or 0
    local best
    for _, r in ipairs(KH.Workshop.RECIPES) do
        if r.trade == "gear" and r.slot == slot and V:Good(r.id) > 0 and r.power > power then best, power = r.id, r.power end
    end
    return best
end

-- Mastery at the highest level: "veteran" (more chance in every dungeon) or "mentor" (more xp for its group); a Title too
function I:Master(id, pick)
    local f = self:Get(id)
    if f.level < B.FOLLOWER.maxLevel or f.mastery or (pick ~= "veteran" and pick ~= "mentor") then return false end
    f.mastery = pick
    KH.Journal:Mark(id, "title")
    return true
end

-- ----------------------------------------------------------------------------
-- The dungeons
-- ----------------------------------------------------------------------------
Dg.LIST, Dg.BY_ID = B.DUNGEONS, {}
for i, d in ipairs(B.DUNGEONS) do Dg.BY_ID[d.id] = d; d.index = i end

function Dg.Get(id) return Dg.BY_ID[id] end

function Dg:Best()
    local best = 0
    for _, id in ipairs(I:List()) do best = math.max(best, I:Get(id).level) end
    return best
end

function Dg:Open(id)
    local d = Dg.Get(id)
    return d ~= nil and I:Count() > 0 and self:Best() + R.openAhead >= d.level
end

function Dg:OpenList()
    local out = {}
    for _, d in ipairs(Dg.LIST) do
        if self:Open(d.id) and not d.raid then out[#out + 1] = d.id end
    end
    return out
end

function Dg:Daily(day)
    local open = self:OpenList()
    if #open == 0 then return nil end
    day = day or KH.Day()
    return open[(day * 37) % #open + 1]
end

function Dg:RaidLeft(id)
    local d = Dg.Get(id)
    if not (d and d.raid) then return 0 end
    local at = (KH.db.dungeons.raids or {})[id] or 0
    return math.max(0, at + B.RAID.every - KH.Now())
end

-- the combos a group forms: two abilities of two different followers
function Dg:Combos(party)
    local out = {}
    for _, c in ipairs(B.COMBOS) do
        local found = false
        for _, fa in ipairs(party) do
            for _, fb in ipairs(party) do
                if fa ~= fb and not found then
                    local hasA, hasB = false, false
                    for _, ab in ipairs(I:Abilities(fa)) do if Has(c.a, ab) then hasA = true end end
                    for _, ab in ipairs(I:Abilities(fb)) do if Has(c.b, ab) then hasB = true end end
                    found = hasA and hasB
                end
            end
        end
        if found then out[#out + 1] = c end
    end
    return out
end

function Dg:Known(comboId) return (KH.db.dungeons.combos or {})[comboId] == true end

-- the threats of a run: the optional boss adds one more Brutal boss
function Dg:Threats(id, opts)
    local d = Dg.Get(id)
    local list = {unpack(d.threats)}
    if Opt(opts, "boss") and not d.raid then list[#list + 1] = "boss" end
    return list
end

-- total chance (not clamped), the parts {{key, points, arg}}, the counters {{threat, fid, ability}} and the threats left
function Dg:Chance(id, party, opts)
    local d = Dg.Get(id)
    local parts, counters, open = {}, {}, {}
    local used = {}
    for _, threat in ipairs(self:Threats(id, opts)) do
        local found
        for _, fid in ipairs(party) do
            for k, ab in ipairs(I:Abilities(fid)) do
                local key = fid .. k
                if not found and not used[key] and Has(B.ABILITIES[ab].counters, threat) then
                    found = {threat, fid, ab}
                    used[key] = true
                end
            end
        end
        if found then counters[#counters + 1] = found else open[#open + 1] = threat end
    end
    local total = 100
    local function Add(key, points, arg)
        if points ~= 0 then
            parts[#parts + 1] = {key, points, arg}
            total = total + points
        end
    end
    for _, threat in ipairs(open) do Add("threat", -R.threat, threat) end
    if #party > 0 then
        local sum = 0
        for _, fid in ipairs(party) do sum = sum + I:Get(fid).level end
        local diff = sum / #party - d.level
        if diff < 0 then Add("level", -Round(-diff * R.below))
        else Add("level", math.min(R.aboveMax, math.floor(diff) * R.above)) end
    end
    Add("missing", -R.missing * math.max(0, d.size - #party), math.max(0, d.size - #party))
    for _, fid in ipairs(party) do
        for _, t in ipairs(I:Traits(fid)) do
            local name, arg = t[1], t[2]
            local tr = B.TRAITS[name]
            if name == "forest" and Has(tr.when, d.env) then Add("trait", tr.points, fid)
            elseif name == "likes" and arg == d.env then Add("trait", tr.points, fid)
            elseif name == "fearsUndead" and Has(d.threats, "undead") and I:Get(fid).level < tr.untilLevel then
                Add("trait", tr.points, fid)
            elseif name == "company" then Add("trait", tr.perOther * (#party - 1), fid)
            elseif name == "partner" and Has(party, arg) then Add("trait", tr.points, fid) end
        end
        Add("gear", I:GearPower(fid), fid)
        if I:Get(fid).mastery == "veteran" then Add("veteran", R.veteran, fid) end
    end
    for _, c in ipairs(self:Combos(party)) do
        local pts = (c.points or 0) + ((c.undead and Has(d.threats, "undead")) and c.undead or 0)
            + ((c.boss and Opt(opts, "boss")) and c.boss or 0)
        if pts ~= 0 then Add("combo", pts, c.id) end
    end
    if Opt(opts, "potion") and #party > 0 then Add("potion", R.potion) end
    local insp = ((KH.db.adventure or {}).inspired or {})[id]
    if insp and insp > 0 and #party > 0 then Add("inspired", R.inspired) end
    return total, parts, counters, open
end

-- the chance that counts for the roll (0..100) and the reward bonus (1..1.5)
function Dg.Odds(total)
    local capped = math.max(0, math.min(R.maxChance, total))
    return math.min(100, capped), 1 + math.max(0, capped - 100) / 100
end

function Dg:Free(fid)
    return I:Has(fid) and I:State(fid) == "home"
end

function Dg:Recommended(id, party, opts)
    party = party or {}
    local d = Dg.Get(id)
    local base = self:Chance(id, party, opts)
    local out = {}
    for _, fid in ipairs(I:List()) do
        if not Has(party, fid) then
            local with = {unpack(party)}
            with[#with + 1] = fid
            local total, _, counters = self:Chance(id, with, opts)
            local mine = {}
            for _, c in ipairs(counters) do if c[2] == fid then mine[#mine + 1] = c[1] end end
            out[#out + 1] = {id = fid, gain = total - base, counters = mine, free = self:Free(fid), full = #party >= d.size}
        end
    end
    table.sort(out, function(a, b)
        if a.free ~= b.free then return a.free end
        if a.gain ~= b.gain then return a.gain > b.gain end
        return I.Def(a.id).index < I.Def(b.id).index
    end)
    return out
end

-- the group with the best chance among the free followers (a tie goes to the smaller group, then to the lower average
-- level, so the strong stay free for higher dungeons)
function Dg:Suggest(id, opts)
    local d = Dg.Get(id)
    local free = {}
    for _, fid in ipairs(I:List()) do if self:Free(fid) then free[#free + 1] = fid end end
    local best, bestTotal, bestLevel = {}, -1e9, 1e9
    local pick = {}
    local function Try(start)
        if #pick > 0 then
            local total = math.min(R.maxChance, (self:Chance(id, pick, opts)))
            local level = 0
            for _, fid in ipairs(pick) do level = level + I:Get(fid).level end
            level = level / #pick
            if total > bestTotal or (total == bestTotal and (#pick < #best or (#pick == #best and level < bestLevel))) then
                best, bestTotal, bestLevel = {unpack(pick)}, total, level
            end
        end
        if #pick >= d.size then return end
        for k = start, #free do
            pick[#pick + 1] = free[k]
            Try(k + 1)
            pick[#pick] = nil
        end
    end
    Try(1)
    return best, bestTotal
end

function Dg:Duration(id, party, opts)
    local cut = 0
    for _, fid in ipairs(party) do
        for _, t in ipairs(I:Traits(fid)) do
            local tr = B.TRAITS[t[1]]
            if tr.short then cut = math.max(cut, tr.short) end
        end
    end
    for _, c in ipairs(self:Combos(party)) do if c.short then cut = math.max(cut, c.short) end end
    local long = (Opt(opts, "boss") and not Dg.Get(id).raid) and (1 + R.bossShort) or 1
    return Round(Dg.Get(id).hours * 3600 * (1 - cut) * long)
end

function Dg:Cost(id, party)
    return math.ceil(R.fishPerHour * Dg.Get(id).hours * #party)
end

-- coins, village xp and the xp of each follower {fid = xp} on a success with that total (a failure is half)
function Dg:Reward(id, party, total, day, opts)
    local d = Dg.Get(id)
    local _, bonus = Dg.Odds(total)
    local db = KH.db
    local n = #party
    local coins = Round(R.coinShare * B.GardenIncome(db.level, V:Plots()) * d.hours * n * bonus)
    local vxp = Round(R.xpShare * B.XPToNext(db.level) * d.hours * n * bonus)
    local group = 0
    for _, fid in ipairs(party) do
        for _, t in ipairs(I:Traits(fid)) do group = group + (B.TRAITS[t[1]].groupXP or 0) end
        if I:Get(fid).mastery == "mentor" then group = group + R.mentorXP end
    end
    for _, c in ipairs(self:Combos(party)) do
        group = group + (c.fxp or 0)
        if c.coins then coins = Round(coins * (1 + c.coins)) end
    end
    if Opt(opts, "food") then group = group + R.foodXP end
    local daily = (self:Daily(day) == id) and R.daily or 0
    local fxp = {}
    for _, fid in ipairs(party) do
        local own = 0
        for _, t in ipairs(I:Traits(fid)) do own = own + (B.TRAITS[t[1]].xp or 0) end
        local x = (R.fxpBase + R.fxpPerLevel * d.level) * (1 + group + own + daily)
        if I:Get(fid).level > d.level + R.lowGap then x = x * R.lowXP end
        fxp[fid] = Round(x)
    end
    return coins, vxp, fxp
end

local function RareBonus(party)
    local rare = 0
    for _, fid in ipairs(party) do
        for _, t in ipairs(I:Traits(fid)) do rare = rare + (B.TRAITS[t[1]].rare or 0) end
    end
    local mult = 1 + rare / 100
    for _, c in ipairs(Dg:Combos(party)) do if c.rare then mult = mult * c.rare end end
    return mult
end

-- the chance of the trophy of the dungeon: 5% to 20% by its level, more with the optional boss and with Mira at home;
-- sure in a crypt with Blessed Steel
function Dg:TrophyChance(id, party, opts)
    local d = Dg.Get(id)
    if not B.TROPHIES[id] then return 0 end
    for _, c in ipairs(self:Combos(party)) do
        if c.crypt and d.env == "crypt" then return 1 end
    end
    local ch = R.trophyMin + (R.trophyMax - R.trophyMin) * (d.level - 1) / 29
    if Opt(opts, "boss") then ch = ch * R.bossTrophy end
    if I:Has("mira") and not Has(party, "mira") and I:State("mira") == "home" then ch = ch + R.miraTrophy end
    return math.min(1, ch * RareBonus(party))
end

function Dg:Send(id, party, opts)
    local d = Dg.Get(id)
    if not d or not self:Open(id) then return false, "closed" end
    if d.raid and self:RaidLeft(id) > 0 then return false, "raidWeek" end
    if #party == 0 then return false, "empty" end
    if #party > d.size then return false, "full" end
    local seen = {}
    for _, fid in ipairs(party) do
        if seen[fid] or not self:Free(fid) then return false, "busy", fid end
        seen[fid] = true
    end
    local cost = self:Cost(id, party)
    if V:Good("fish") < cost then return false, "fish", cost end
    for _, k in ipairs({"potion", "food"}) do
        local g = Opt(opts, k)
        if g and V:Good(g) < 1 then return false, "noConsumable" end
    end
    local db = KH.db
    db.goods.fish = V:Good("fish") - cost
    if Opt(opts, "potion") then db.goods[opts.potion] = V:Good(opts.potion) - 1 end
    if Opt(opts, "food") then db.goods[opts.food] = V:Good(opts.food) - 1 end
    local total, _, counters, open = self:Chance(id, party, opts)
    local odds = Dg.Odds(total)
    local ok = Roll() * 100 < odds
    local coins, vxp, fxp = self:Reward(id, party, total, nil, opts)
    local hurt, drops, combos = {}, {}, {}
    for _, c in ipairs(self:Combos(party)) do combos[#combos + 1] = c.id end
    if ok then
        local rare = RareBonus(party)
        if d.raid then
            drops[#drops + 1] = "epic"
            drops[#drops + 1] = "core"
        elseif d.level >= R.epic.from and Roll() < R.epic.chance * rare then drops[#drops + 1] = "epic"
        elseif d.level >= R.merit.from and Roll() < R.merit.chance * rare then drops[#drops + 1] = "merit" end
        if Roll() < self:TrophyChance(id, party, opts) then drops[#drops + 1] = "trophy" end
    else
        coins, vxp = Round(coins / 2), Round(vxp / 2)
        for fid, x in pairs(fxp) do fxp[fid] = Round(x / 2) end
        local noHurt = false
        for _, c in ipairs(self:Combos(party)) do if c.noHurt then noHurt = true end end
        local risk = R.injury * (Opt(opts, "food") and R.foodHurt or 1)
        if I:Has("garrick") and not Has(party, "garrick") and I:State("garrick") == "home" then risk = risk - R.garrickHurt end
        for _, fid in ipairs(party) do
            local tough = noHurt
            for _, t in ipairs(I:Traits(fid)) do if B.TRAITS[t[1]].neverInjured then tough = true end end
            if not tough and Roll() < risk then hurt[#hurt + 1] = fid end
        end
    end
    if d.raid then
        db.dungeons.raids = db.dungeons.raids or {}
        db.dungeons.raids[id] = KH.Now()                -- tried this week, success or not
    end
    db.adventure = db.adventure or {}
    db.adventure.inspired = db.adventure.inspired or {}
    local insp = db.adventure.inspired[id]
    if insp and insp > 0 then db.adventure.inspired[id] = insp - 1 end
    db.dungeons.serial = (db.dungeons.serial or 0) + 1
    db.trips = db.trips or {}
    db.trips[#db.trips + 1] = {n = db.dungeons.serial, dungeon = id, at = KH.Now(), time = self:Duration(id, party, opts),
        party = {unpack(party)}, total = total, ok = ok, coins = coins, vxp = vxp, fxp = fxp, hurt = hurt, drops = drops,
        counters = counters, open = open, combos = combos, boss = Opt(opts, "boss") or nil}
    return true
end

function Dg:Trips() return KH.db.trips or {} end

function Dg:TripState(trip)
    local left = trip.at + trip.time - KH.Now()
    if left > 0 then return "away", left end
    return "back", 0
end

-- brings the trip n home: pays, levels, hurts, drops and writes the Journal. Returns the trip and the levels gained
function Dg:Collect(n)
    local db = KH.db
    local trip = db.trips[n]
    if not trip or self:TripState(trip) ~= "back" then return nil end
    table.remove(db.trips, n)
    db.coins = db.coins + (trip.coins or 0)
    db.stats.earned = db.stats.earned + (trip.coins or 0)
    if trip.ore and trip.ore > 0 then db.goods.ore = V:Good("ore") + trip.ore end
    if (trip.vxp or 0) > 0 then KH.Farm:AddXP(trip.vxp) end
    local ups = {}
    for _, fid in ipairs(trip.party) do
        local f = I:Get(fid)
        f.runs = (f.runs or 0) + 1
        ups[fid] = I:AddXP(fid, (trip.fxp or {})[fid] or 0)
    end
    local back = trip.at + trip.time
    for _, fid in ipairs(trip.hurt or {}) do I:Get(fid).hurt = back + R.injuryHours * 3600 end
    local d = db.dungeons
    for _, drop in ipairs(trip.drops or {}) do
        if drop == "trophy" then
            d.trophies = d.trophies or {}
            d.trophies[trip.dungeon] = (d.trophies[trip.dungeon] or 0) + 1
        elseif drop == "core" then
            db.goods.core = V:Good("core") + B.RAID.core
        else
            d[drop] = (d[drop] or 0) + 1
        end
    end
    d.combos = d.combos or {}
    for _, c in ipairs(trip.combos or {}) do d.combos[c] = true end
    if trip.dungeon then
        d.runs = (d.runs or 0) + 1
        KH.Journal:Add(trip)
    end
    return trip, ups
end

function Dg:CollectAll()
    local coins, ore, list = 0, 0, {}
    local n = 1
    while n <= #(KH.db.trips or {}) do
        local trip = self:Collect(n)
        if trip then
            coins, ore = coins + (trip.coins or 0), ore + (trip.ore or 0)
            list[#list + 1] = trip
        else
            n = n + 1
        end
    end
    return coins, ore, list
end

-- ----------------------------------------------------------------------------
-- What the rest of the village asks of the Inn
-- ----------------------------------------------------------------------------
function I:BackCount()
    local n = 0
    for _, trip in ipairs(Dg:Trips()) do
        if Dg:TripState(trip) == "back" then n = n + 1 end
    end
    return n
end

function I:AwayCount()
    local n = 0
    for _, trip in ipairs(Dg:Trips()) do
        if Dg:TripState(trip) == "away" then n = n + #trip.party end
    end
    return n
end

function I:CollectAll()
    local coins, ore = Dg:CollectAll()
    return coins, ore
end

-- groups that came back since the last time this was asked
local announced = {}
function I:Update()
    local news = 0
    local now = {}
    for _, trip in ipairs(Dg:Trips()) do
        if Dg:TripState(trip) == "back" then
            now[trip.n] = true
            if not announced[trip.n] then news = news + 1 end
        end
    end
    announced = now
    return news
end

KH:On("PLAYER_LOGIN", function()
    local db = KH.db
    db.dungeons = db.dungeons or {}
    db.trips = db.trips or {}
    for _, trip in ipairs(db.trips) do
        if Dg:TripState(trip) == "back" then announced[trip.n] = true end
    end
end)
