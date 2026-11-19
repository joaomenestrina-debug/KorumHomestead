--[[
    Korum Homestead - random events (docs/eventos.md, approved on 17/11)

    Now and then someone comes to the village, or something turns up: an urgent order, a generous merchant, a trading
    caravan, a rare fish in the Pond, a rare ore in the Mine. They only come with the game open (the clock of the window
    calls Events:Update), one every B.EVENTS.gapMin..gapMax seconds of play, at most maxOpen at once. Each has a deadline
    that runs by the clock, also with the game closed; when it passes, the event goes away with its reward and its xp.
    Nothing the player has is ever taken.

        Events:Update()             expires what is over, and maybe brings a new one; returns the new event or nil
        Events:Open()               the open events, oldest first
        Events:Left(e)              seconds left of an event
        Events:Deliver(id)          urgent: takes what it asks, pays
        Events:Sell(id, n)          merchant: sells up to n (or all he still wants) at his price
        Events:Trade(id, i)         caravan: makes trade i (once)
        Events:Collect(id)          fish, ore: brings the find to the Barn
        Events:Missed()             events that went away unanswered since the last call (and forgets them)
]]

local addonName, KH = ...
local B = KH.Balance
local D = KH.Data
local V = KH.Village

local E = {}
KH.Events = E

local function Rand(n) return (KH.Rand or math.random)(n) end
local function RandRange(a, b) return a + Rand(b - a + 1) - 1 end

local function Store()
    local db = KH.db
    db.events = db.events or {}
    local s = db.events
    s.open, s.missed = s.open or {}, s.missed or {}
    s.serial, s.nextAt, s.done = s.serial or 0, s.nextAt or 0, s.done or 0
    return s
end

-- ----------------------------------------------------------------------------
-- What things are worth: herbs by their sell price, goods by theirs (ore, fish, rare finds, Workshop items)
-- ----------------------------------------------------------------------------
local function Value(key)
    if type(key) == "number" then return D.Plant(key).sell end
    return V:GoodSell(key)
end

local function Have(key)
    if type(key) == "number" then return KH.db.crops[key] or 0 end
    return V:Good(key)
end

local function Take(key, n)
    local db = KH.db
    if type(key) == "number" then
        local left = (db.crops[key] or 0) - n
        db.crops[key] = left > 0 and left or nil
    else
        db.goods[key] = V:Good(key) - n
    end
end

local function Give(key, n)
    local db = KH.db
    if type(key) == "number" then
        db.crops[key] = (db.crops[key] or 0) + n
    else
        db.goods[key] = V:Good(key) + n
    end
end

-- herbs open at the level of the player (the order range), and the Workshop items open now
local function OpenHerbs()
    local db, out = KH.db, {}
    for _, p in ipairs(D.PLANTS) do
        if p[2] <= db.level and p[2] >= db.level - B.ORDERS.plantLevelRange then out[#out + 1] = p[1] end
    end
    if #out == 0 then out[1] = D.PLANTS[1][1] end
    return out
end

local function OpenItems()
    local out = {}
    for _, r in ipairs(KH.Workshop.RECIPES) do
        if KH.Workshop:Offered(r.id) then out[#out + 1] = r.id end
    end
    return out
end

-- the xp of delivering n of something: a herb as in a herb order, an item as in an item order
local function DeliverXP(key, n)
    if type(key) == "number" then return KH.Orders.HerbXP(D.Plant(key), n) end
    if KH.Workshop.Recipe(key) then return math.floor(n * KH.Workshop.XP(key) * B.ORDERS.goodsXpFactor) end
    return 0
end

-- how many units an event may ask or buy, when each one adds `extra` coins over selling it: the most it adds stays under
-- B.EVENTS.capMinutes of what the Garden makes now (at least one unit)
local function Capped(n, extra)
    if extra <= 0 then return n end
    local cap = B.GardenIncome(KH.db.level, V:Plots()) * B.EVENTS.capMinutes / 60
    return math.max(1, math.min(n, math.floor(cap / extra)))
end

-- ----------------------------------------------------------------------------
-- Making each kind
-- ----------------------------------------------------------------------------
local MAKE = {}

function MAKE.urgent()
    local c = B.EVENTS.urgent
    local items = OpenItems()
    local o
    if #items > 0 and Rand(2) == 1 then
        o = KH.Orders:MakeGoods()
        o.key = o.good
    else
        o = KH.Orders:Make(1)
        o.key = o.plant
    end
    local normal = o.coins / o.qty                                  -- what a normal order pays for one
    local qty = Capped(math.max(1, math.floor(o.qty * c.qtyFactor)), normal * c.payFactor - Value(o.key))
    return {key = o.key, qty = qty, coins = math.floor(qty * normal * c.payFactor),
        xp = math.floor(o.xp / o.qty * qty * c.xpFactor), npc = o.npc, time = c.time}
end

function MAKE.merchant()
    local c = B.EVENTS.merchant
    local pool = OpenHerbs()
    for _, id in ipairs(OpenItems()) do pool[#pool + 1] = id end
    local key = pool[Rand(#pool)]
    local price = B.Round(Value(key) * c.priceFactor)
    return {key = key, price = price, left = Capped(c.max, price - Value(key)), time = c.time}
end

function MAKE.caravan()
    local c = B.EVENTS.caravan
    local pool = OpenHerbs()
    if V:Level("mine") > 0 then pool[#pool + 1] = "ore" end
    if V:Level("pond") > 0 then pool[#pool + 1] = "fish" end
    for _, id in ipairs(OpenItems()) do pool[#pool + 1] = id end
    local trades = {}
    for i = 1, c.trades do
        local give = pool[Rand(#pool)]
        local get = give
        while #pool > 1 and get == give do get = pool[Rand(#pool)] end
        local n = RandRange(4, 12)
        local gain = c.gainMin + (c.gainMax - c.gainMin) * (Rand(101) - 1) / 100
        local m = math.max(1, math.floor(n * Value(give) * gain / Value(get)))
        trades[i] = {give = give, n = n, get = get, m = m}
    end
    return {trades = trades, time = c.time}
end

local function Find(kind)
    local pool = {}
    for _, id in ipairs(B.RARE_ORDER) do
        if B.GOODS[id].rare == kind then pool[#pool + 1] = id end
    end
    return {key = pool[Rand(#pool)], qty = 1, time = B.EVENTS[kind].time}
end
function MAKE.fish() return Find("fish") end
function MAKE.ore() return Find("ore") end

-- what may come now: no rare fish without a Pond, no rare ore without a Mine
local function Possible(kind)
    if kind == "fish" then return V:Level("pond") > 0 end
    if kind == "ore" then return V:Level("mine") > 0 end
    return true
end

local KINDS = {"urgent", "merchant", "caravan", "fish", "ore"}

local function Draw()
    local total, list = 0, {}
    for _, kind in ipairs(KINDS) do
        if Possible(kind) then
            local w = B.EVENTS.weights[kind] * 10
            total = total + w
            list[#list + 1] = {kind, w}
        end
    end
    local roll = Rand(total)
    for _, item in ipairs(list) do
        roll = roll - item[2]
        if roll <= 0 then return item[1] end
    end
    return list[1][1]
end

local function NextGap()
    return RandRange(B.EVENTS.gapMin, B.EVENTS.gapMax)
end

-- ----------------------------------------------------------------------------
-- The clock
-- ----------------------------------------------------------------------------
function E:Spawn(kind)
    local s = Store()
    kind = kind or Draw()
    local e = MAKE[kind]()
    s.serial = s.serial + 1
    e.id, e.kind, e.at = s.serial, kind, KH.Now()
    s.open[#s.open + 1] = e
    return e
end

function E:Left(e)
    return math.max(0, e.at + e.time - KH.Now())
end

function E:Update()
    local s = Store()
    local now = KH.Now()
    for i = #s.open, 1, -1 do
        local e = s.open[i]
        if now >= e.at + e.time then                       -- over: it goes away with its chance
            table.remove(s.open, i)
            s.missed[#s.missed + 1] = e.kind
        end
    end
    if s.nextAt == 0 then s.nextAt = now + NextGap() end
    if now >= s.nextAt then
        s.nextAt = now + NextGap()
        if #s.open < B.EVENTS.maxOpen then return self:Spawn() end
    end
    return nil
end

-- at login the time away does not count as play: the next event is a whole gap from now
function E:OnLogin()
    local s = Store()
    s.nextAt = KH.Now() + NextGap()
end

function E:Open()
    return Store().open
end

function E:Get(id)
    for i, e in ipairs(Store().open) do
        if e.id == id then return e, i end
    end
end

local function Close(i)
    local s = Store()
    table.remove(s.open, i)
    s.done = s.done + 1
end

function E:Missed()
    local s = Store()
    local out = s.missed
    s.missed = {}
    return out
end

local function Earn(coins)
    local db = KH.db
    db.coins = db.coins + coins
    db.stats.earned = db.stats.earned + coins
end

-- ----------------------------------------------------------------------------
-- The answers
-- ----------------------------------------------------------------------------
function E:Deliver(id)
    local e, i = self:Get(id)
    if not e or e.kind ~= "urgent" then return false, "noEvent" end
    if Have(e.key) < e.qty then return false, "missing" end
    Take(e.key, e.qty)
    Earn(e.coins)
    KH.Farm:AddXP(e.xp)
    Close(i)
    return true, {coins = e.coins, xp = e.xp}
end

function E:Sell(id, n)
    local e, i = self:Get(id)
    if not e or e.kind ~= "merchant" then return false, "noEvent" end
    n = math.min(n or e.left, e.left, Have(e.key))
    if n <= 0 then return false, "missing" end
    Take(e.key, n)
    local coins = n * e.price
    local xp = DeliverXP(e.key, n)
    Earn(coins)
    KH.Farm:AddXP(xp)
    e.left = e.left - n
    if e.left <= 0 then Close(i) end
    return true, {coins = coins, xp = xp, n = n}
end

function E:CanTrade(id, k)
    local e = self:Get(id)
    local t = e and e.kind == "caravan" and e.trades[k]
    return t and not t.done and Have(t.give) >= t.n or false
end

function E:Trade(id, k)
    local e, i = self:Get(id)
    if not e or e.kind ~= "caravan" then return false, "noEvent" end
    local t = e.trades[k]
    if not t or t.done then return false, "done" end
    if Have(t.give) < t.n then return false, "missing" end
    Take(t.give, t.n)
    Give(t.get, t.m)
    t.done = true
    local all = true
    for _, other in ipairs(e.trades) do if not other.done then all = false end end
    if all then Close(i) end
    return true, t
end

function E:Collect(id)
    local e, i = self:Get(id)
    if not e or (e.kind ~= "fish" and e.kind ~= "ore") then return false, "noEvent" end
    Give(e.key, e.qty)
    local xp = math.max(1, math.floor(D.XPToNext(KH.db.level) * B.EVENTS[e.kind].findXP))
    KH.Farm:AddXP(xp)
    Close(i)
    return true, {key = e.key, xp = xp}
end

KH:On("PLAYER_LOGIN", function() E:OnLogin() end)
