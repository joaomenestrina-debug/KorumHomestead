--[[
    Korum Homestead - probe of the game's events (only in the copy installed from the repository)

    T3.0 of docs/cronograma-2.0.md: before the village follows the adventure of the character (docs/masmorras.md §12), find
    out what the client of WoW Forever really offers: boss kills, zones, queues, the calendar, addon messages.

    /kh debug, then /kh eventos     turns the probe on or off (it stays on across /reload until turned off)
    /kh eventos limpar               forgets what was written down

    While on, every event below that fires is printed in the chat and written in KorumHomesteadDB.probe.log (the last 400),
    so the SavedVariables file can be read after the session. Turning it on also writes which functions of the game exist.
    It only reads: it never changes the character.

    The whole file is between --@debug@ and --@end-debug@: the CurseForge packager comments it out, so the players' zip
    has none of it.
]]

--@debug@
local addonName, KH = ...
local Probe = {}
KH.Probe = Probe

Probe.MAX = 400
Probe.EVENTS = {
    "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL", "UPDATE_INSTANCE_INFO",
    "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
    "LFG_UPDATE", "LFG_QUEUE_STATUS_UPDATE", "LFG_PROPOSAL_SHOW", "LFG_PROPOSAL_SUCCEEDED", "LFG_COMPLETION_REWARD",
    "LFG_LIST_ACTIVE_ENTRY_UPDATE", "LFG_LIST_APPLICATION_STATUS_UPDATED",
    "UPDATE_BATTLEFIELD_STATUS",
    "CALENDAR_UPDATE_EVENT_LIST",
    "QUEST_TURNED_IN",
}
-- functions of the game the plans lean on: does the Forever client have them?
Probe.APIS = {
    "GetInstanceInfo", "GetRealZoneText", "GetSubZoneText", "C_Map.GetBestMapForUnit", "C_Map.GetMapInfo",
    "GetLFGMode", "GetLFGQueueStats", "GetLFGDungeonInfo", "C_LFGList.GetActiveEntryInfo", "GetBattlefieldStatus",
    "C_Calendar.OpenCalendar", "C_Calendar.GetNumDayEvents", "C_Calendar.GetDayEvent", "C_DateAndTime.GetCurrentCalendarTime",
    "EJ_GetEncounterInfo", "C_ChatInfo.SendAddonMessage", "C_ChatInfo.RegisterAddonMessagePrefix",
    "ChatFrame_OpenChat", "PlaySound",
}

local frame

local function Store()
    local db = KH.db
    db.probe = db.probe or {on = false, log = {}}
    db.probe.log = db.probe.log or {}
    return db.probe
end

local function Find(path)
    local t = _G
    for part in string.gmatch(path, "[^%.]+") do
        if type(t) ~= "table" then return nil end
        t = t[part]
    end
    return t
end

local function Call(path, ...)
    local fn = Find(path)
    if type(fn) ~= "function" then return nil end
    local res = {pcall(fn, ...)}
    if not res[1] then return nil end
    table.remove(res, 1)
    return res
end

local function Join(list)
    local out = {}
    for i = 1, #list do out[i] = tostring(list[i]) end
    return table.concat(out, ", ")
end

-- where the character is: the zone, the instance (name, type, difficulty, id) and the map
local function Where()
    local parts = {}
    local zone = Call("GetRealZoneText")
    if zone then parts[#parts + 1] = "zone=" .. tostring(zone[1]) end
    local sub = Call("GetSubZoneText")
    if sub and sub[1] and sub[1] ~= "" then parts[#parts + 1] = "sub=" .. tostring(sub[1]) end
    local inst = Call("GetInstanceInfo")
    if inst then parts[#parts + 1] = "instance={" .. Join(inst) .. "}" end
    local map = Call("C_Map.GetBestMapForUnit", "player")
    if map and map[1] then parts[#parts + 1] = "map=" .. tostring(map[1]) end
    return table.concat(parts, " ")
end

local last
function Probe:Write(text)
    local s = Store()
    local line = date("%d/%m %H:%M:%S") .. " " .. text
    s.log[#s.log + 1] = line
    while #s.log > Probe.MAX do table.remove(s.log, 1) end
    if text ~= last then KH:Print("|cff9aa0aaprobe|r " .. text) end
    last = text
end

-- today's events of the calendar (the holidays the village would follow)
local function Holidays()
    local now = Call("C_DateAndTime.GetCurrentCalendarTime")
    local day = now and type(now[1]) == "table" and now[1].monthDay
    local n = day and Call("C_Calendar.GetNumDayEvents", 0, day)
    if not n or not n[1] then return "calendar: no day events API" end
    local titles = {}
    for i = 1, n[1] do
        local e = Call("C_Calendar.GetDayEvent", 0, day, i)
        if e and type(e[1]) == "table" then titles[#titles + 1] = tostring(e[1].title) .. " (" .. tostring(e[1].calendarType) .. ")" end
    end
    return "calendar today: " .. (#titles > 0 and table.concat(titles, "; ") or "nothing")
end

local function OnEvent(_, event, ...)
    local text = event .. " {" .. Join({...}) .. "}"
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ENCOUNTER_END"
            or event == "BOSS_KILL" then
        text = text .. " " .. Where()
    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        local st = Call("GetBattlefieldStatus", (...) or 1)
        if st then text = text .. " status={" .. Join(st) .. "}" end
    elseif event == "LFG_UPDATE" or event == "LFG_QUEUE_STATUS_UPDATE" then
        local mode = Call("GetLFGMode", 1)
        if mode then text = text .. " mode={" .. Join(mode) .. "}" end
    elseif event == "CALENDAR_UPDATE_EVENT_LIST" then
        text = text .. " " .. Holidays()
    end
    Probe:Write(text)
end

-- which functions and events the client has: written once each time the probe is turned on
function Probe:Report()
    local have, miss = {}, {}
    for _, path in ipairs(Probe.APIS) do
        if type(Find(path)) == "function" then have[#have + 1] = path else miss[#miss + 1] = path end
    end
    self:Write("APIs ok: " .. table.concat(have, ", "))
    self:Write("APIs missing: " .. (#miss > 0 and table.concat(miss, ", ") or "none"))
    self:Write("events ok: " .. table.concat(self.registered or {}, ", "))
    self:Write("events missing: " .. (#(self.refused or {}) > 0 and table.concat(self.refused, ", ") or "none"))
    self:Write("here: " .. Where())
    Call("C_Calendar.OpenCalendar")                     -- the list comes back as CALENDAR_UPDATE_EVENT_LIST
end

function Probe:Start()
    if not frame then
        frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", OnEvent)
    end
    self.registered, self.refused = {}, {}
    for _, event in ipairs(Probe.EVENTS) do
        -- an event the client does not know is an error in RegisterEvent: written down as missing
        if pcall(frame.RegisterEvent, frame, event) then
            self.registered[#self.registered + 1] = event
        else
            self.refused[#self.refused + 1] = event
        end
    end
end

function Probe:Stop()
    if frame then frame:UnregisterAllEvents() end
end

function Probe:Toggle(arg)
    local s = Store()
    if arg == "limpar" or arg == "clear" then
        s.log = {}
        KH:Print("probe: log cleared")
        return
    end
    s.on = not s.on
    if s.on then
        self:Start()
        KH:Print("probe on: events go to the chat and to KorumHomesteadDB.probe")
        self:Report()
    else
        self:Stop()
        KH:Print("probe off (" .. #s.log .. " lines kept)")
    end
end

KH:On("PLAYER_LOGIN", function()
    if KH.db and KH.db.probe and KH.db.probe.on then
        Probe:Start()
        Probe:Write("login, probe still on")
        Probe:Report()
    end
end)
--@end-debug@
