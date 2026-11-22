--[[
    Korum Homestead - the Mayor (owner, 22/11): the voice of the village. The alerts and the news of the homestead
    (a plot ready, a group back, a visitor, an achievement...) can be said by him, with his own humour
    (docs/prefeito.md has who he is and how he talks).

    Every moment is the key of the text it replaces: the Mayor's lines for the key `readyAlert` are `mayor_readyAlert_1`,
    `mayor_readyAlert_2`... in Locales.lua, with the same codes (%s, %d) in the same order. A moment with no line of
    his, or with the Mayor turned off in the Settings, says the plain text, as before.

        KH.Say(key, ...)     the text of that moment: one of the Mayor's lines, with his name before it, or T(key, ...)
        KH.MayorLines(key)   how many lines he has for it
]]

local addonName, KH = ...

local count = {}

function KH.MayorLines(key)
    if count[key] == nil then
        local n = 0
        while KH.L.enUS["mayor_" .. key .. "_" .. (n + 1)] do n = n + 1 end
        count[key] = n
    end
    return count[key]
end

function KH.MayorOn()
    return not KH.db or KH.db.mayor ~= false
end

-- the last line said for each moment, so the same one does not come twice in a row
local last = {}

function KH.Say(key, ...)
    local n = KH.MayorOn() and KH.MayorLines(key) or 0
    if n == 0 then return KH.T(key, ...) end
    local pick = math.random(n)
    if n > 1 and pick == last[key] then pick = pick % n + 1 end
    last[key] = pick
    return "|cffffd24d" .. KH.T("mayorName") .. ":|r " .. KH.T("mayor_" .. key .. "_" .. pick, ...)
end
