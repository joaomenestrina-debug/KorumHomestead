--[[
    Korum Homestead - the followers and the dungeons (docs/masmorras.md)

    The Inn shelters the followers: the six of the village come one per Inn level, the others are found in the dungeons,
    the raids and the rescue calls of their places (docs/masmorras.md §3.5). Each Inn level is a room; who is in a room
    goes out and gives its bonus at home, the others wait in the Lodging. They go to the dungeons of WoW Forever. Each dungeon has
    threats; each follower has abilities that counter them. The chance of a run comes from the threats left uncountered,
    the levels, the group size, the traits, the equipment, the combos and the potion, and is shown before sending.
    Nobody dies: a failure brings half the reward and maybe a follower hurt for a while.

    Everything about a run is decided when it is sent (the roll, the reward, who gets hurt, what drops) and shown when the
    group comes back, so closing the game changes nothing. `opts` = {potion = good, food = good, boss = true}.

        Inn:Count() / Inn:List() / Inn:Has(id) / Inn:Get(id) / Inn.Def(id) / Inn:Total()
        Inn:Rooms() / Inn:RoomList() / Inn:InRoom(id) / Inn:FreeRooms()
        Inn:Move(id, toRoom) / Inn:Swap(inRoom, lodged)     both at home
        Inn:Power(id) / Inn:Ranking()        the roster by Power
        Inn:Welcome(id, level)               someone found arrives: "new", or the insignia a repeated one becomes
        Inn:Arrivals() / Inn:Greeted(id)     who arrived and was not greeted yet (the arrival card)
        Inn.Gear(goodId)                     {slot, power, item} of a piece (the Workshop's or one with a name)
        Inn:Work(id, place) / Inn:Rest(place)   a follower at home works at the Mine or the Pond, or stops
        Inn:Worker(place) / Inn:Working(id) / Inn:WorkBonus(place) / Inn:Workers(place)   who, where, how much, who could
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

function I.Def(id) return I.BY_ID[id] end
function I:Total() return #I.DEFS end

local function Found()
    local db = KH.db
    db.found = db.found or {}
    return db.found
end
local function Lodged()
    local db = KH.db
    db.lodged = db.lodged or {}
    return db.lodged
end

-- the six of the village come with the Inn, one per level; the others when they are found
function I:Has(id)
    local def = I.Def(id)
    if not def then return false end
    if not def.from then return def.index <= V:Level("inn") end
    return Found()[id] ~= nil
end

-- the roster: the six first, then the found ones in the order they arrived
function I:List()
    local out, late = {}, {}
    local found = Found()
    for _, def in ipairs(I.DEFS) do
        if not def.from then
            if def.index <= V:Level("inn") then out[#out + 1] = def.id end
        elseif found[def.id] then
            late[#late + 1] = def.id
        end
    end
    table.sort(late, function(a, b)
        if found[a] ~= found[b] then return found[a] < found[b] end
        return I.Def(a).index < I.Def(b).index
    end)
    for _, id in ipairs(late) do out[#out + 1] = id end
    return out
end

function I:Count() return #self:List() end

function I:Rooms() return math.min(B.ROOMS.max, V:Level("inn")) end
function I:InRoom(id) return self:Has(id) and not Lodged()[id] end

function I:RoomList()
    local out = {}
    for _, id in ipairs(self:List()) do
        if not Lodged()[id] then out[#out + 1] = id end
    end
    return out
end

function I:FreeRooms() return self:Rooms() - #self:RoomList() end

-- never more followers in rooms than rooms: the last to arrive wait in the Lodging
function I:Tidy()
    local rooms = self:RoomList()
    for k = #rooms, self:Rooms() + 1, -1 do Lodged()[rooms[k]] = true end
end

function I:Get(id)
    local db = KH.db
    db.followers = db.followers or {}
    local f = db.followers[id]
    if not f then
        local def = I.Def(id)
        f = {level = 1, xp = 0, quality = def.rarity, ability = def.second, changes = 0, runs = 0}
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
    local out = {type(def.trait) == "table" and def.trait or {def.trait}}
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
    if not f.ability and I.Def(id).rare then
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
    if what == "ability" and f.ability and def.rare then
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

-- a piece of equipment: the Workshop's (a "gear" recipe) or one with a name (a good with `gear`)
function I.Gear(gid)
    local r = KH.Workshop.Recipe(gid)
    if r then return r.trade == "gear" and r or nil end
    local g = B.GOODS[gid]
    if g and g.gear then return {id = gid, slot = g.gear.slot, power = g.gear.power, item = g.item} end
end

-- the chance points of the equipment of a follower (Iron hands: each piece one level more)
function I:GearPower(id)
    local f = self:Get(id)
    local extra = 0
    for _, t in ipairs(self:Traits(id)) do extra = extra + (B.TRAITS[t[1]].gear or 0) end
    local sum = 0
    for _, gid in pairs(f.gear or {}) do
        local r = I.Gear(gid)
        if r then sum = sum + r.power + extra end
    end
    return sum
end

-- puts a piece from the Barn on the follower; the one it had goes back to the Barn
function I:Equip(id, gid)
    local r = I.Gear(gid)
    if not r then return false, "nothing" end
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
    local power = now and I.Gear(now).power or 0
    local best
    for _, r in ipairs(KH.Workshop.RECIPES) do
        if r.trade == "gear" and r.slot == slot and V:Good(r.id) > 0 and r.power > power then best, power = r.id, r.power end
    end
    for gid, g in pairs(B.GOODS) do
        if g.gear and g.gear.slot == slot and V:Good(gid) > 0 and g.gear.power > power then best, power = gid, g.gear.power end
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

-- moves a follower at home between a room and the Lodging
function I:Move(id, toRoom)
    if not self:Has(id) then return false, "nothing" end
    local state = self:State(id)
    if state ~= "home" and state ~= "hurt" then return false, "away" end
    if toRoom then
        if not Lodged()[id] then return false, "nothing" end
        if self:FreeRooms() <= 0 then return false, "noRoom" end
        Lodged()[id] = nil
    else
        if Lodged()[id] then return false, "nothing" end
        Lodged()[id] = true
    end
    return true
end

-- the one in the Lodging takes the room of the other, both at home
function I:Swap(inRoom, lodged)
    if not (self:InRoom(inRoom) and self:Has(lodged) and Lodged()[lodged]) then return false, "nothing" end
    for _, id in ipairs({inRoom, lodged}) do
        local state = self:State(id)
        if state ~= "home" and state ~= "hurt" then return false, "away" end
    end
    Lodged()[inRoom] = true
    Lodged()[lodged] = nil
    return true
end

function I:Power(id)
    local f, P = self:Get(id), B.POWER
    local gear = 0
    for _, gid in pairs(f.gear or {}) do
        local g = I.Gear(gid)
        if g then gear = gear + g.power end
    end
    return f.level * P.level + (P.quality[f.quality] or 0) + gear * P.gear
end

-- the roster by Power, the strongest first: {{id, power, room}, ...}
function I:Ranking()
    local out = {}
    for _, id in ipairs(self:List()) do out[#out + 1] = {id = id, power = self:Power(id), room = self:InRoom(id)} end
    table.sort(out, function(a, b)
        if a.power ~= b.power then return a.power > b.power end
        return I.Def(a.id).index < I.Def(b.id).index
    end)
    return out
end

-- someone found arrives: a new follower takes a free room (or waits in the Lodging) and comes at `level`; one the
-- village already has becomes an insignia (Merit for a Rare, Epic for the others). Returns "new", "merit" or "epic".
function I:Welcome(id, level)
    local def = I.Def(id)
    local db = KH.db
    if self:Has(id) then
        local kind = def.rarity == "rare" and "merit" or "epic"
        db.dungeons[kind] = (db.dungeons[kind] or 0) + 1
        return kind
    end
    local full = self:FreeRooms() <= 0
    Found()[id] = KH.Now()
    local f = self:Get(id)
    f.level = math.max(f.level, math.min(B.FOLLOWER.maxLevel, level or 1))
    if full then Lodged()[id] = true end
    db.arrivals = db.arrivals or {}
    db.arrivals[#db.arrivals + 1] = id
    KH.Journal:Mark(id, "arrived")
    return "new"
end

-- Work: one follower at home at the Mine and one at the Pond (B.JOBS). What the building made up to now is counted at the
-- old pace before anyone comes or goes.
local function Jobs()
    local db = KH.db
    db.jobs = db.jobs or {}
    return db.jobs
end

function I:Worker(place)
    local fid = Jobs()[place]
    if fid and self:Has(fid) then return fid end
    return nil
end

function I:Working(id)
    for _, place in ipairs(B.JOBS.order) do
        if Jobs()[place] == id and self:Has(id) then return place end
    end
    return nil
end

function I.JobBonus(id, place)
    return I.Def(id).job == B.JOBS[place] and B.JOBS.skilled or B.JOBS.any
end

function I:WorkBonus(place)
    local fid = B.JOBS[place] and self:Worker(place)
    return fid and I.JobBonus(fid, place) or 0
end

function I:Work(id, place)
    if not B.JOBS[place] or V:Level(place) < 1 then return false, "nothing" end
    if not self:Has(id) then return false, "nothing" end
    local state = self:State(id)
    if state ~= "home" and state ~= "hurt" then return false, "away" end
    V:Produce()
    for _, other in ipairs(B.JOBS.order) do
        if Jobs()[other] == id then Jobs()[other] = nil end
    end
    Jobs()[place] = id
    return true
end

function I:Rest(place)
    if not Jobs()[place] then return false end
    V:Produce()
    Jobs()[place] = nil
    return true
end

-- who could work there now (at home, not working elsewhere), the best first: who has the trade, then who waits in the
-- Lodging (so the rooms keep who goes out)
function I:Workers(place)
    local out = {}
    for _, id in ipairs(self:List()) do
        local state = self:State(id)
        if (state == "home" or state == "hurt") and not self:Working(id) then
            out[#out + 1] = {id = id, bonus = I.JobBonus(id, place), room = self:InRoom(id)}
        end
    end
    table.sort(out, function(a, b)
        if a.bonus ~= b.bonus then return a.bonus > b.bonus end
        if a.room ~= b.room then return not a.room end
        return I.Def(a.id).index < I.Def(b.id).index
    end)
    return out
end

function I:Arrivals() return KH.db.arrivals or {} end
function I:Greeted(id)
    local list = KH.db.arrivals or {}
    for i = #list, 1, -1 do if list[i] == id then table.remove(list, i) end end
end

-- ----------------------------------------------------------------------------
-- The dungeons
-- ----------------------------------------------------------------------------
Dg.LIST, Dg.BY_ID = B.DUNGEONS, {}
for i, d in ipairs(B.DUNGEONS) do Dg.BY_ID[d.id] = d; d.index = i end

-- a dungeon of the list, or the place of a call that is open (Events.lua: its event carries the same fields)
function Dg.Get(id)
    local d = Dg.BY_ID[id]
    if d or type(id) ~= "string" or id:sub(1, 5) ~= "call:" then return d end
    for _, e in ipairs(KH.Events:Open()) do
        if e.def and e.def.id == id then return e.def end
    end
end

-- what a dungeon, a call or a kept run is called
function Dg.Name(d)
    if type(d) == "string" then d = Dg.Get(d) or {id = d} end
    if d.call then return KH.T("callName", KH.T("call_" .. d.call), KH.T("pl_" .. d.place)) end
    return KH.T("dg_" .. d.id)
end

function Dg:Best()
    local best = 0
    for _, id in ipairs(I:RoomList()) do best = math.max(best, I:Get(id).level) end
    return best
end

function Dg:Open(id)
    local d = Dg.Get(id)
    if d and d.call then return #I:RoomList() > 0 end
    return d ~= nil and #I:RoomList() > 0 and self:Best() + R.openAhead >= d.level
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
    if Opt(opts, "boss") and not d.raid and not d.call then list[#list + 1] = "boss" end
    return list
end

-- what a threat nobody answers takes in a dungeon of that level: less in the first ones
function Dg.ThreatCost(level)
    for _, step in ipairs(R.threatEarly) do
        if level <= step.upTo then return step.points end
    end
    return R.threat
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
                local key = fid .. k .. threat           -- an ability answers each of its threats once
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
    for _, threat in ipairs(open) do Add("threat", -Dg.ThreatCost(d.level), threat) end
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
    if (KH.db.dungeons.scouted or {})[id] and #party > 0 then Add("scout", B.CALLS.recon.scout) end
    return total, parts, counters, open
end

-- the chance that counts for the roll (0..100) and the reward bonus (1..1.5)
function Dg.Odds(total)
    local capped = math.max(0, math.min(R.maxChance, total))
    return math.min(100, capped), 1 + math.max(0, capped - 100) / 100
end

function Dg:Free(fid)
    return I:InRoom(fid) and I:State(fid) == "home" and not I:Working(fid)
end

function Dg:Recommended(id, party, opts)
    party = party or {}
    local d = Dg.Get(id)
    local base = self:Chance(id, party, opts)
    local out = {}
    for _, fid in ipairs(I:RoomList()) do
        if not Has(party, fid) then
            local with = {unpack(party)}
            with[#with + 1] = fid
            local total, _, counters = self:Chance(id, with, opts)
            local mine = {}
            for _, c in ipairs(counters) do if c[2] == fid then mine[#mine + 1] = c[1] end end
            out[#out + 1] = {id = fid, gain = total - base, total = total, counters = mine, free = self:Free(fid),
                full = #party >= d.size}
        end
    end
    table.sort(out, function(a, b)
        if a.free ~= b.free then return a.free end
        if a.gain ~= b.gain then return a.gain > b.gain end
        return I.Def(a.id).index < I.Def(b.id).index
    end)
    return out
end

-- someone at home in the Lodging who would add more than anyone free in the rooms: the id, what it adds and the threats
-- it would answer (the screen says "bring it to a room")
function Dg:LodgeHint(id, party, opts)
    party = party or {}
    local d = Dg.Get(id)
    if #party >= d.size then return nil end
    local base = self:Chance(id, party, opts)
    local function Gain(fid)
        local with = {unpack(party)}
        with[#with + 1] = fid
        local total, _, counters = self:Chance(id, with, opts)
        local mine = {}
        for _, c in ipairs(counters) do if c[2] == fid then mine[#mine + 1] = c[1] end end
        return total - base, mine
    end
    local best = 0
    for _, fid in ipairs(I:RoomList()) do
        if not Has(party, fid) and self:Free(fid) then best = math.max(best, (Gain(fid))) end
    end
    local who, gain, counters
    for _, fid in ipairs(I:List()) do
        if not I:InRoom(fid) and I:State(fid) == "home" and not I:Working(fid) then
            local g, mine = Gain(fid)
            if g > best and (not gain or g > gain) then who, gain, counters = fid, g, mine end
        end
    end
    return who, gain, counters
end

-- the group with the best chance among the free followers (a tie goes to the smaller group, then to the lower average
-- level, so the strong stay free for higher dungeons)
function Dg:Suggest(id, opts)
    local d = Dg.Get(id)
    local free = {}
    for _, fid in ipairs(I:RoomList()) do if self:Free(fid) then free[#free + 1] = fid end end
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
        for _, ab in ipairs(I:Abilities(fid)) do
            if B.ABILITIES[ab].short then cut = math.max(cut, B.ABILITIES[ab].short) end
        end
    end
    for _, c in ipairs(self:Combos(party)) do if c.short then cut = math.max(cut, c.short) end end
    local long = (Opt(opts, "boss") and not Dg.Get(id).raid and not Dg.Get(id).call) and (1 + R.bossShort) or 1
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
    if d.mult then
        -- a call pays beside a dungeon of the same time; what it adds stays under the cap of the events
        local cap = B.GardenIncome(db.level, V:Plots()) * B.EVENTS.capMinutes / 60
        coins = d.mult == 0 and 0 or Round(coins + math.min(coins * (d.mult - 1), cap))
        vxp = Round(vxp * math.max(1, d.mult))
    end
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
    if I:InRoom("mira") and not Has(party, "mira") and I:State("mira") == "home" then ch = ch + R.miraTrophy end
    return math.min(1, ch * RareBonus(party))
end

-- who may come from a place: `kind` = "dungeon", "raid" or "rescue". Where a Legendary lives beside another follower it
-- is the rare one; among the others, one the village does not have yet comes first.
local function Newcomer(kind, place)
    local plain, legend = {}, {}
    for _, def in ipairs(I.DEFS) do
        if def.from and def.from[kind] == place then
            local list = def.from.legendary and legend or plain
            list[#list + 1] = def.id
        end
    end
    local pool = plain
    if #legend > 0 and (#plain == 0 or Roll() < B.NEWCOMER.legendaryShare) then pool = legend end
    if #pool == 0 then return nil end
    local fresh = {}
    for _, fid in ipairs(pool) do if not I:Has(fid) then fresh[#fresh + 1] = fid end end
    if #fresh > 0 then pool = fresh end
    return pool[math.min(#pool, math.floor(Roll() * #pool) + 1)]
end

-- the chance of a new follower on a success of a dungeon of that level
function Dg.NewcomerChance(level)
    for _, step in ipairs(B.NEWCOMER.dungeon) do
        if level <= step.upTo then return step.chance end
    end
    return 0
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
    local newcomer, named, caravan, scout
    for _, c in ipairs(self:Combos(party)) do combos[#combos + 1] = c.id end
    db.adventure = db.adventure or {}
    local N = B.NEWCOMER
    if not d.raid and not d.call then db.dungeons.dry = (db.dungeons.dry or 0) + 1 end
    if ok then
        local rare = RareBonus(party)
        if d.raid then
            drops[#drops + 1] = "epic"
            drops[#drops + 1] = "core"
        elseif d.call then
            local c = B.CALLS[d.call]
            if c.merit and Roll() < c.merit * rare then drops[#drops + 1] = "merit" end
        elseif d.level >= R.epic.from and Roll() < R.epic.chance * rare then drops[#drops + 1] = "epic"
        elseif d.level >= R.merit.from and Roll() < R.merit.chance * rare then drops[#drops + 1] = "merit" end
        if Roll() < self:TrophyChance(id, party, opts) then drops[#drops + 1] = "trophy" end
        -- someone new, only from where they are from (docs/masmorras.md §3.5)
        if d.raid then
            local luck = db.adventure.raidLuck and N.raidLuck or 0
            if Roll() < (N.raidLegendary + luck) * rare then newcomer = Newcomer("raid", id) end
            local pieces = B.NAMED[id]
            if pieces and Roll() < R.named * rare then named = pieces[math.min(#pieces, math.floor(Roll() * #pieces) + 1)] end
        elseif d.call then
            if d.call == "rescue" and Roll() < N.rescue * rare then newcomer = Newcomer("rescue", d.place) end
            if d.call == "escort" then caravan = true end
            if d.call == "recon" and B.PLACES[d.place].dungeon then scout = d.place end
        else
            if Roll() < Dg.NewcomerChance(d.level) * rare then newcomer = Newcomer("dungeon", id) end
            if not newcomer and db.dungeons.dry >= N.guarantee then
                -- the guarantee: a Rare the village does not have, of this dungeon first; with all of them, an insignia
                local here, any
                for _, def in ipairs(I.DEFS) do
                    if def.from and def.rarity == "rare" and not I:Has(def.id) then
                        any = any or def.id
                        if def.from.dungeon == id then here = here or def.id end
                    end
                end
                newcomer = here or any
                if not newcomer then drops[#drops + 1] = "merit" end
                db.dungeons.dry = 0
            end
        end
        if newcomer then db.dungeons.dry = 0 end
    else
        coins, vxp = Round(coins / 2), Round(vxp / 2)
        for fid, x in pairs(fxp) do fxp[fid] = Round(x / 2) end
        local noHurt = false
        for _, c in ipairs(self:Combos(party)) do if c.noHurt then noHurt = true end end
        local risk = R.injury * (Opt(opts, "food") and R.foodHurt or 1)
        if I:InRoom("garrick") and not Has(party, "garrick") and I:State("garrick") == "home" then risk = risk - R.garrickHurt end
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
    if d.raid then db.adventure.raidLuck = nil end       -- the luck of the character's raid kill is for one raid
    db.adventure.inspired = db.adventure.inspired or {}
    local insp = db.adventure.inspired[id]
    if insp and insp > 0 then db.adventure.inspired[id] = insp - 1 end
    if db.dungeons.scouted then db.dungeons.scouted[id] = nil end       -- what the scouts saw is for one run
    db.dungeons.serial = (db.dungeons.serial or 0) + 1
    db.trips = db.trips or {}
    local time = self:Duration(id, party, opts)
    local trip = {n = db.dungeons.serial, at = KH.Now(), time = time,
        party = {unpack(party)}, total = total, ok = ok, coins = coins, vxp = vxp, fxp = fxp, hurt = hurt, drops = drops,
        counters = counters, open = open, combos = combos, boss = Opt(opts, "boss") or nil,
        newcomer = newcomer, newLevel = newcomer and d.level or nil, named = named, caravan = caravan, scout = scout}
    if d.call then
        trip.call = {kind = d.call, place = d.place}      -- the call is answered: its event leaves the Visitors
        KH.Events:Answer(id)
    else
        trip.dungeon = id
    end
    db.trips[#db.trips + 1] = trip
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
    if trip.newcomer then trip.welcome = I:Welcome(trip.newcomer, trip.newLevel) end
    if trip.named then db.goods[trip.named] = V:Good(trip.named) + 1 end
    if trip.scout then
        d.scouted = d.scouted or {}
        d.scouted[trip.scout] = true
    end
    if trip.caravan and KH.Events then KH.Events:Spawn("caravan") end   -- the caravan escorted passes by the village
    if trip.dungeon then d.runs = (d.runs or 0) + 1 end
    if trip.dungeon or trip.call then KH.Journal:Add(trip) end
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
    db.found, db.lodged, db.arrivals = db.found or {}, db.lodged or {}, db.arrivals or {}
    I:Tidy()
    for _, trip in ipairs(db.trips) do
        if Dg:TripState(trip) == "back" then announced[trip.n] = true end
    end
end)
