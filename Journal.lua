--[[
    Korum Homestead - the Journal of the followers (docs/masmorras.md §13)

    When a group comes back it brings one or two lines telling what happened: where it went, who countered what and with
    which ability, the threat nobody answered, the result, who came back hurt, what was found. The save keeps only the
    numbers of the run; the lines are written when shown, in the language of the player, so almost every return reads
    differently and the save grows little.

        Journal:Add(trip)            keeps the run (the last B.JOURNAL.keep of them)
        Journal:Mark(fid, what)      a milestone kept forever: "first", "rare", "epic"
        Journal:Lines(entry)         the one or two lines of a run
        Journal:Latest()             the last run kept
        Journal:For(fid)             the runs of a follower, newest first, and its milestones
        Journal:ChatText(entry)      the lines in one string, for the chat box (the player sends it, never the addon)
]]

local addonName, KH = ...
local B = KH.Balance

local J = {}
KH.Journal = J

B.JOURNAL = {keep = 60, perFollower = 20}

local function T(...) return KH.T(...) end

local function Names(list)
    local names = {}
    for i, fid in ipairs(list) do names[i] = T("fol_" .. fid) end
    if #names <= 1 then return names[1] or "" end
    return table.concat(names, ", ", 1, #names - 1) .. T("j_and") .. names[#names]
end

function J:Add(trip)
    local db = KH.db
    db.journal = db.journal or {}
    local entry = {at = trip.at + trip.time, d = trip.dungeon, call = trip.call, ok = trip.ok, party = trip.party,
        by = trip.counters, open = trip.open, hurt = trip.hurt, drops = trip.drops, combos = trip.combos, total = trip.total,
        new = trip.newcomer, welcome = trip.welcome, named = trip.named, caravan = trip.caravan, scout = trip.scout}
    table.insert(db.journal, entry)
    while #db.journal > B.JOURNAL.keep do table.remove(db.journal, 1) end
    for _, fid in ipairs(trip.party) do
        local f = KH.Inn:Get(fid)
        if trip.dungeon and not (f.marks and f.marks.first) then self:Mark(fid, "first", trip.dungeon) end
    end
    return entry
end

function J:Mark(fid, what, arg)
    local f = KH.Inn:Get(fid)
    f.marks = f.marks or {}
    if not f.marks[what] then f.marks[what] = {at = KH.Now(), arg = arg} end
end

function J:Lines(e)
    local first
    if e.call then
        first = T(#e.party == 1 and "j_call1" or "j_callN", Names(e.party), T("j_call_" .. e.call.kind), T("pl_" .. e.call.place))
    else
        first = T(#e.party == 1 and "j_went1" or "j_wentN", Names(e.party), T("dg_" .. e.d))
    end
    local by = e.by or {}
    for k = 1, math.min(2, #by) do
        local c = by[k]
        first = first .. " " .. T("j_by_" .. c[1], T("fol_" .. c[2]), T("ab_" .. c[3]))
    end
    local second
    if e.open and e.open[1] then second = T("j_open_" .. e.open[1]) .. " " end
    second = (second or "") .. T(e.ok and "j_ok" or "j_fail")
    if e.hurt and #e.hurt > 0 then second = second .. " " .. T(#e.hurt == 1 and "j_hurt1" or "j_hurtN", Names(e.hurt)) end
    if e.combos and e.combos[1] then second = T("j_combo", T("cb_" .. e.combos[1])) .. " " .. second end
    for _, drop in ipairs(e.drops or {e.drop}) do
        second = second .. " " .. (drop == "trophy" and T("j_drop_trophy", KH.Data.Name(KH.Balance.TROPHIES[e.d]) or "")
            or T("j_drop_" .. drop))
    end
    if e.new then
        second = second .. " " .. T(e.welcome == "new" and "j_new" or "j_again", T("fol_" .. e.new))
    end
    if e.named then second = second .. " " .. T("j_named", T("good_" .. e.named)) end
    if e.caravan then second = second .. " " .. T("j_caravan") end
    if e.scout then second = second .. " " .. T("j_scout", T("dg_" .. e.scout)) end
    return {first, second}
end

function J:Latest()
    local list = KH.db.journal or {}
    return list[#list]
end

function J:For(fid)
    local out = {}
    for i = #(KH.db.journal or {}), 1, -1 do
        local e = KH.db.journal[i]
        for _, p in ipairs(e.party or {}) do
            if p == fid then out[#out + 1] = e; break end
        end
        if #out >= B.JOURNAL.perFollower then break end
    end
    return out, KH.Inn:Get(fid).marks or {}
end

function J:ChatText(e)
    local lines = self:Lines(e)
    return lines[1] .. " " .. lines[2]
end
