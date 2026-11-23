--[[
    Korum Homestead - the voices of the village (owner, 22/11): five people who work for the player, the owner of the
    village, and say its alerts and news with their own humour, each about their part of it (docs/personagens.md):

        steward   Steward Ambrose    the village as a whole: logging in, its level, the buildings, achievements
        foreman   Foreman Dorota     the Garden, the Mine, the Pond, the Barn and the Workshop
        clerk     Clerk Tiberius     the Market: orders, the order of the day and its streak
        butler    Butler Fenwick     the visitors
        advisor   Advisor Marga      the Inn: groups, followers, calls, the character's bosses and raids

    The Steward also teaches the first steps (plant, wait, harvest, sell), and the Butler announces every new version
    on the "What's new" screen: `say_patch<id>_1`, <id> being the entry of KH.NEWS (owner, 22/11).

    Every moment is the key of the text it replaces: the lines for the key `readyAlert` are `say_readyAlert_1`,
    `say_readyAlert_2`... in Locales.lua, with the same codes (%s, %d) in the same order. A moment with no line, or
    with the voices turned off in the Settings ("The characters speak"), says the plain text, as before.

        KH.Say(key, ...)       one of the lines of that moment with the name of who says it, or T(key, ...)
        KH.SayLine(key)        only the words of a line (no name), or nil: for a title, like the achievement card's
        KH.SaidBy(text)        who said a text KH.Say gave, or nil: the icon on the screen shows that face
        KH.Speaker(key)        who says that moment ("steward", "foreman"...)
        KH.VoiceLines(key)     how many lines that moment has
        KH.VoicesOn()
]]

local addonName, KH = ...

KH.SPEAKERS = {"steward", "foreman", "clerk", "butler", "advisor"}

local WHO = {
    steward = {"hello", "levelUp", "levelNotice", "newSeed", "built", "capLotus", "achChat", "achNew",
        "tutPlantS", "tutWaitS", "tutHarvestS", "tutSellS", "vilPlantS", "vilHarvestS", "vilSellS"},
    foreman = {"readyAlert", "headReadyOne", "headReadyMany", "craftDone", "barnAlmost", "alertBarnFull"},
    clerk = {"delivered", "dailyDelivered", "streakPrize", "streakRare"},
    butler = {"ev_new_urgent", "ev_new_merchant", "ev_new_caravan", "ev_new_fish", "ev_new_ore", "evDone_urgent",
        "evDone_merchant", "evDone_trade", "evDone_find"},
    advisor = {"dgSent", "innBackOne", "innBackMany", "collected", "promoted", "ev_new_call", "advInspired", "advRaid"},
}
local SPEAKER = {}
for who, keys in pairs(WHO) do
    for _, key in ipairs(keys) do SPEAKER[key] = who end
end
KH.VOICE_MOMENTS = WHO

function KH.Speaker(key)
    if key:match("^patch%d") then return "butler" end
    return SPEAKER[key] or "steward"
end

local count = {}
function KH.VoiceLines(key)
    if count[key] == nil then
        local n = 0
        while KH.L.enUS["say_" .. key .. "_" .. (n + 1)] do n = n + 1 end
        count[key] = n
    end
    return count[key]
end

-- the portrait of who speaks (Media/Village/<who>.tga, A11)
function KH.Portrait(who) return "Interface\\AddOns\\KorumHomestead\\Media\\Village\\" .. who end

function KH.VoicesOn()
    return not KH.db or KH.db.mayor ~= false
end

-- the last line said for each moment, so the same one does not come twice in a row
local last = {}

function KH.SayLine(key, ...)
    local n = KH.VoicesOn() and KH.VoiceLines(key) or 0
    if n == 0 then return nil end
    local pick = math.random(n)
    if n > 1 and pick == last[key] then pick = pick % n + 1 end
    last[key] = pick
    return KH.T("say_" .. key .. "_" .. pick, ...)
end

-- who said each text KH.Say gave, so the icon on the screen shows that face while the text is on it (owner, 23/11)
local said, saidCount = {}, 0

function KH.Say(key, ...)
    local line = KH.SayLine(key, ...)
    if not line then return KH.T(key, ...) end
    local who = KH.Speaker(key)
    local text = "|cffffd24d" .. KH.T("who_" .. who) .. ":|r " .. line
    if saidCount >= 40 then said, saidCount = {}, 0 end
    if not said[text] then saidCount = saidCount + 1 end
    said[text] = who
    return text
end

-- who said a text, or nil when no one of the village did (a plain text, or the voices off)
function KH.SaidBy(text)
    if not KH.VoicesOn() then return nil end
    return text and said[text]
end

-- who looks after each screen, for the alert growing out of the icon: what waits there is that person's business
KH.PLACE_SPEAKER = {barn = "foreman", garden = "foreman", orders = "clerk", visitors = "butler", inn = "advisor"}
