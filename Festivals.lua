--[[
    Korum Homestead - the festivals of the game's calendar

    While a festival of the game runs, the village dresses for it (docs/masmorras.md §13). For now only the Feast of
    Winter Veil: the snowy map and three decorations (art A7).

        Festivals:Current([at])     the id of the festival running at that moment ("winter") or nil
        Festivals:Active(id, [at])  true while that festival runs

    The dates are the ones of the game's calendar for each festival, by the clock of the computer. If the client of the
    Forever turns out to have its own dates (C_Calendar, test T3.0), they come in here without changing anything else.
]]

local addonName, KH = ...

local F = {}
KH.Festivals = F

-- {month, day} of the first and the last day; a festival that crosses the new year has from > to
F.LIST = {
    {id = "winter", from = {12, 15}, to = {1, 2}},
}

local function Day(month, day) return month * 100 + day end

function F:Active(id, at)
    --@debug@
    if KH.festivalForce ~= nil then return KH.festivalForce == id end     -- /kh festa: to see the art outside its dates
    --@end-debug@
    local t = date("*t", at or KH.Now())
    local today = Day(t.month, t.day)
    for _, f in ipairs(self.LIST) do
        if f.id == id then
            local from, to = Day(f.from[1], f.from[2]), Day(f.to[1], f.to[2])
            if from <= to then return today >= from and today <= to end
            return today >= from or today <= to
        end
    end
    return false
end

function F:Current(at)
    for _, f in ipairs(self.LIST) do
        if self:Active(f.id, at) then return f.id end
    end
    return nil
end
