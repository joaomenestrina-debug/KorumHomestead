--[[
    Korum Homestead - what's new

    Every change the player can notice gets a line here, under the version that brings it. After an update the window
    opens by itself on the "What's new" screen once, at login, with the new lines marked; the screen is also in the
    Settings. A new homestead does not see the old news.

    To add news: put {id = next number, version = "x.y.z"} at the END of KH.NEWS (or use the last entry while that version
    is not released) and write its lines in Locales.lua, in both languages: news<id>_1, news<id>_2, ... in order.
    db.newsSeen keeps the id of the last entry the player has seen.
]]

local addonName, KH = ...

KH.NEWS = {
    {id = 1, version = "2.0.0"},
    {id = 2, version = "2.1.0-alpha1"},
    {id = 3, version = "2.1.0-alpha2"},
    {id = 4, version = "2.1.0-alpha4"},
    {id = 5, version = "2.1.0-alpha5"},
}

function KH.LatestNews()
    local last = KH.NEWS[#KH.NEWS]
    return last and last.id or 0
end

-- the lines of an entry, in the language of the player
function KH.NewsLines(id)
    local lines = {}
    while KH.L.enUS["news" .. id .. "_" .. (#lines + 1)] do
        lines[#lines + 1] = KH.T("news" .. id .. "_" .. (#lines + 1))
    end
    return lines
end

-- is there something the player has not seen yet?
function KH.HasNews()
    return (tonumber(KH.db and KH.db.newsSeen) or 0) < KH.LatestNews()
end
