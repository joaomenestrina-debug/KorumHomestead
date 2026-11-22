local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local BUILDERS = P.builders
local CRUMB = {workshop = "b_workshop", inn = "b_inn", guide = "guide", hall = "b_hall", garden = "b_garden", barn = "b_barn", mine = "b_mine", pond = "b_pond", orders = "b_market", settings = "tabSettings", news = "newsH", visitors = "visitorsTab", achievements = "achH"}
function UI:Create()
    if self.win then return end
    local win = Kit.Window({
        name = "KorumHomesteadFrame", width = WIDTH, height = HEIGHT,
        title = "|cff40d9c4Korum|r Homestead", logo = Kit.LOGO, tabs = {},
        onSelect = function(id) UI:OnSelect(id) end,
        closeTip = function() return T("close") end,
    })
    self.win = win
    self.frame = win.frame
    self.screens = {}
    -- closing the window stamps the moment, so the next opening can tell what happened meanwhile (UI/Away.lua)
    local onHide = self.frame:GetScript("OnHide")
    self.frame:SetScript("OnHide", function(...)
        if onHide then onHide(...) end
        if KH.db then KH.Away:Mark() end
    end)

    -- the header keeps the two numbers of the game in sight on every screen: the coins and the level
    local h = win.header
    self.coinText = Kit.Text(h, 14, C.text, "RIGHT")
    self.coinText:SetPoint("RIGHT", win.close, "LEFT", -16, 0)
    self.coinDot = h:CreateTexture(nil, "ARTWORK")
    self.coinDot:SetTexture(Kit.Icon("dot"))
    self.coinDot:SetSize(12, 12)
    self.coinDot:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    self.coinDot:SetPoint("RIGHT", self.coinText, "LEFT", -6, 0)
    local coinHit = CreateFrame("Frame", nil, h)
    coinHit:SetPoint("TOPLEFT", self.coinDot, "TOPLEFT", -6, 12)
    coinHit:SetPoint("BOTTOMRIGHT", self.coinText, "BOTTOMRIGHT", 4, -10)
    coinHit:EnableMouse(true)
    coinHit:SetScript("OnEnter", function(frame) Tip(frame, T("coinsTip"), {T("coins", KH.Number(KH.db.coins)), T("coinsHow")}) end)
    coinHit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local lv = CreateFrame("Frame", nil, h)
    lv:SetSize(96, 30)                          -- narrow: the title, the zoom and up to 999,999 coins share this line
    lv:SetPoint("RIGHT", self.coinDot, "LEFT", -16, 0)
    lv.label = Kit.Text(lv, 11, C.textSoft, "RIGHT")
    lv.label:SetPoint("TOPRIGHT", 0, -3)
    lv.bar = Kit.Bar(lv, 96, 3)
    lv.bar:SetPoint("BOTTOMRIGHT", 0, 6)
    lv:EnableMouse(true)
    lv:SetScript("OnEnter", function(frame)
        local db = KH.db
        local first = db.level >= D.MAX_LEVEL and T("maxLevel", KH.Number(KH.Balance.HERBALISM.lotusXP), math.floor(KH.Farm:CapProgress() * 100)) or T("xpTip", db.xp, D.XPToNext(db.level))
        Tip(frame, T("herbalism", db.level), {first, T("xpHow")})
    end)
    lv:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.levelBox = lv

    -- the gear: the settings are a screen like the others
    local gear = CreateFrame("Button", nil, h)
    gear:SetSize(26, 26)
    gear:SetPoint("RIGHT", lv, "LEFT", -10, -4)
    gear.bg = gear:CreateTexture(nil, "BACKGROUND")
    gear.bg:SetAllPoints()
    gear.bg:SetTexture(Kit.Icon("dot"))
    gear.bg:SetVertexColor(1, 1, 1, 0.06)
    gear.icon = gear:CreateTexture(nil, "ARTWORK")
    gear.icon:SetSize(14, 14)
    gear.icon:SetPoint("CENTER")
    gear.icon:SetTexture(Kit.Icon("settings"))
    gear.icon:SetVertexColor(C.textSoft[1], C.textSoft[2], C.textSoft[3])
    gear:SetScript("OnEnter", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.16); Tip(frame, T("tabSettings"), {}) end)
    gear:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    gear:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("settings") end)
    self.gear = gear

    -- the question mark: the guide
    local help = CreateFrame("Button", nil, h)
    help:SetSize(26, 26)
    help:SetPoint("RIGHT", gear, "LEFT", -6, 0)
    help.bg = help:CreateTexture(nil, "BACKGROUND")
    help.bg:SetAllPoints()
    help.bg:SetTexture(Kit.Icon("dot"))
    help.bg:SetVertexColor(1, 1, 1, 0.06)
    help.mark = Kit.Text(help, 13, C.textSoft, "CENTER")
    help.mark:SetPoint("CENTER", 0, 0)
    help.mark:SetText("?")
    help:SetScript("OnEnter", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.16); Tip(frame, T("guide"), {T("guideS")}) end)
    help:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    help:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("guide") end)
    self.help = help

    -- the sparkle: what changed in the latest versions, to read again whenever the player wants
    local news = CreateFrame("Button", nil, h)
    news:SetSize(26, 26)
    news:SetPoint("RIGHT", help, "LEFT", -6, 0)
    news.bg = news:CreateTexture(nil, "BACKGROUND")
    news.bg:SetAllPoints()
    news.bg:SetTexture(Kit.Icon("dot"))
    news.bg:SetVertexColor(1, 1, 1, 0.06)
    news.icon = news:CreateTexture(nil, "ARTWORK")
    news.icon:SetSize(14, 14)
    news.icon:SetPoint("CENTER")
    news.icon:SetTexture(Kit.Icon("news"))
    news.icon:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    news:SetScript("OnEnter", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.16); Tip(frame, T("newsH"), {T("newsS")}) end)
    news:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    news:SetScript("OnClick", function() Kit.ClickSound(); UI:ShowNews(false) end)
    self.newsButton = news

    -- the trophy: the achievements, done and still to do
    local ach = CreateFrame("Button", nil, h)
    ach:SetSize(26, 26)
    ach:SetPoint("RIGHT", news, "LEFT", -6, 0)
    ach.bg = ach:CreateTexture(nil, "BACKGROUND")
    ach.bg:SetAllPoints()
    ach.bg:SetTexture(Kit.Icon("dot"))
    ach.bg:SetVertexColor(1, 1, 1, 0.06)
    ach.icon = ach:CreateTexture(nil, "ARTWORK")
    ach.icon:SetSize(14, 14)
    ach.icon:SetPoint("CENTER")
    ach.icon:SetTexture(Kit.Icon("trophy"))
    ach.icon:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    ach:SetScript("OnEnter", function(frame)
        frame.bg:SetVertexColor(1, 1, 1, 0.16)
        local have, total = KH.Achievements:Points()
        local done, all = KH.Achievements:Count()
        Tip(frame, T("achH"), {T("achS", done, all, have, total)})
    end)
    ach:SetScript("OnLeave", function(frame) frame.bg:SetVertexColor(1, 1, 1, 0.06); if GameTooltip then GameTooltip:Hide() end end)
    ach:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("achievements") end)
    self.achButton = ach

    -- the zoom of the window, 60% to 150%: the whole window scales at once, so texts and places keep their layout
    local zoom = CreateFrame("Frame", nil, h)
    zoom:SetSize(88, 26)                        -- kept tight: the title of the window is on the same line
    zoom:SetPoint("RIGHT", ach, "LEFT", -10, 0)
    zoom.plus = Kit.Button(zoom, 24, 22, "+", function() UI:Zoom(0.1) end)
    zoom.plus:SetPoint("RIGHT", 0, 0)
    zoom.value = Kit.Text(zoom, 11, C.textSoft, "CENTER")
    zoom.value:SetPoint("RIGHT", zoom.plus, "LEFT", 0, 0)
    zoom.value:SetWidth(36)
    zoom.minus = Kit.Button(zoom, 24, 22, "−", function() UI:Zoom(-0.1) end)
    zoom.minus:SetPoint("RIGHT", zoom.value, "LEFT", 0, 0)
    for _, b in ipairs({zoom.plus, zoom.minus}) do
        local enter, leave = b:GetScript("OnEnter"), b:GetScript("OnLeave")
        b:SetScript("OnEnter", function(frame) enter(frame); Tip(frame, T("zoomTip"), {T("zoomHow")}) end)
        b:SetScript("OnLeave", function(frame) leave(frame); if GameTooltip then GameTooltip:Hide() end end)
    end
    self.zoom = zoom
    self:ApplyZoom()

    -- the path, where the tabs were: "Village" always takes you back to the map; after it, where you are
    local row = win.tabRow
    local home = CreateFrame("Button", nil, row)
    home:SetSize(60, Kit.TABS_H)
    home:SetPoint("LEFT", 0, 0)
    home.label = Kit.Text(home, 13, C.text)
    home.label:SetPoint("LEFT", 0, 0)
    home.line = home:CreateTexture(nil, "ARTWORK")
    home.line:SetHeight(2)
    home.line:SetPoint("BOTTOMLEFT", home, "BOTTOMLEFT", 0, 0)
    home.line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    home:SetScript("OnEnter", function(frame) frame.hover = true; UI:PaintPath() end)
    home:SetScript("OnLeave", function(frame) frame.hover = false; UI:PaintPath() end)
    home:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("village") end)
    self.home = home
    self.here = Kit.Text(row, 13, C.text)
    self.here:SetPoint("LEFT", home.label, "RIGHT", 0, 0)   -- after the word itself: its real width in any language
end

UI.ZOOM_MIN, UI.ZOOM_MAX = 0.6, 1.5

function UI:ApplyZoom()
    local db = KH.db
    if not (db and self.frame) then return end
    local scale = math.max(UI.ZOOM_MIN, math.min(UI.ZOOM_MAX, tonumber(db.scale) or 1))
    db.scale = scale
    self.frame:SetScale(scale)
    if self.zoom then
        self.zoom.value:SetText(math.floor(scale * 100 + 0.5) .. "%")
        self.zoom.minus:SetEnabledState(scale > UI.ZOOM_MIN + 0.001)
        self.zoom.plus:SetEnabledState(scale < UI.ZOOM_MAX - 0.001)
    end
end

function UI:Zoom(step)
    local db = KH.db
    db.scale = math.floor(((tonumber(db.scale) or 1) + step) * 10 + 0.5) / 10       -- steps of 10%
    self:ApplyZoom()
end

function UI:PaintPath()
    local home = self.home
    if not home then return end
    local inVillage = self.view == "village" or self.view == nil
    home.label:SetText(T("village"))
    local w = Kit.TextWidth(home.label, T("village"))
    home:SetWidth(w + 4)
    home.line:SetWidth(w)
    home.line:SetShown(inVillage)
    Kit.Paint(home.label, (inVillage or home.hover) and C.text or C.textSoft)
    if inVillage then
        self.here:SetText("")
    else
        self.here:SetText("|cff757a87  /  |r" .. T(CRUMB[self.view] or "village"))
    end
end

-- the coins of the header: whole up to 999,999; then short (1.24M, 98.76M, 1.20B), the whole number in the tooltip
local function Short(n)
    if n < 1000000 then return KH.Number(n) end
    if n < 1000000000 then return string.format("%.2fM", math.floor(n / 10000) / 100) end
    return string.format("%.2fB", math.floor(n / 10000000) / 100)
end
UI.ShortCoins = Short

-- the coins count up or down to the new number, and the difference floats away under them
function UI:ShowCoins()
    local coins = KH.db.coins
    if self.coinsSeen ~= nil and coins ~= self.coinsSeen then
        local from, delta = self.coinsShown or self.coinsSeen, coins - self.coinsSeen
        Kit.Float(self.coinText, (delta > 0 and "+" or "-") .. KH.Number(math.abs(delta)), delta > 0 and C.gold or C.textSoft, -1, 12)
        if self.coinAnim then self.coinAnim.cancelled = true end
        self.coinAnim = Kit.Animate(0.45, function(p)
            self.coinsShown = math.floor(from + (coins - from) * p + 0.5)
            self.coinText:SetText(Short(self.coinsShown))
        end, function()
            self.coinAnim, self.coinsShown = nil, coins
            self.coinText:SetText(Short(coins))
        end)
    elseif not self.coinAnim then
        self.coinsShown = coins
        self.coinText:SetText(Short(coins))
    end
    self.coinsSeen = coins
end

function UI:ShowLevel()
    local db = KH.db
    local lv = self.levelBox
    lv.label:SetText(T("herbalism", db.level))
    if db.level >= D.MAX_LEVEL then
        lv.bar:Glide(KH.Farm:CapProgress())             -- at the cap the bar fills toward the next Black Lotus
    else
        lv.bar:Glide(db.xp / D.XPToNext(db.level))
    end
    if self.levelSeen and db.level > self.levelSeen then
        local seed
        for _, p in ipairs(D.PLANTS) do
            if p[2] > self.levelSeen and p[2] <= db.level then seed = p[1] end
        end
        Notice(seed and KH.Say("newSeed", db.level, D.Name(seed)) or KH.Say("levelNotice", db.level))
        Kit.Float(lv.label, T("herbalism", db.level), C.accentBright, -1, 12)
    end
    self.levelSeen = db.level
end

function UI:RefreshHeader()
    self:ShowCoins()
    self:ShowLevel()
    local deliverable = false
    for i = 1, D.ORDER_SLOTS do
        if KH.Orders:CanDeliver(i) then deliverable = true end
    end
    if KH.Daily:CanDeliver() then deliverable = true end
    self.win:SetTabDot("orders", deliverable)
    self.win:SetTabDot("barn", self:Step() == "sell")
    self.win:SetTabDot("garden", self.view ~= "garden" and KH.Farm:ReadyCount() > 0)
end

-- the language changed: the words of the tabs and of the open screen are written again
function UI:Relabel()
    self:PaintPath()
    self:Refresh()
end

function UI:OnSelect(id)
    local changed = self.view ~= id
    self.view = id
    for _, s in pairs(self.screens) do s.frame:Hide() end
    local s = self.screens[id]
    if not s then
        s = BUILDERS[id](self.win)
        self.screens[id] = s
    end
    s.frame:Show()
    if changed then Kit.FadeIn(s.frame, 0.14) end
    self:PaintPath()
    if KH.db then
        self:RefreshHeader()
        self:RefreshScreen()
        -- the first time a place is opened, a card says how it works (and a "?" brings it back)
        if s.place and not s.helpButton then
            local b = Kit.Button(s.frame, 30, 30, "?", function() UI:Coach(s, true) end)
            b:SetPoint("TOPRIGHT", 0, 0)
            b:SetStyle("quiet")
            s.helpButton = b
        end
        if s.place then self:Coach(s) end
    end
end

-- The card that explains a place: three short lines and one button. It opens by itself the first time the place is opened, and
-- the "?" beside the title brings it back.
function UI:Coach(s, force)
    if not (s and s.place) then return end
    local db = KH.db
    db.seen = db.seen or {}
    if db.seen[s.place] and not force then return end
    if not s.coach then
        local dim = CreateFrame("Frame", nil, s.frame)
        dim:SetAllPoints(s.frame)
        dim:SetFrameLevel(s.frame:GetFrameLevel() + 40)
        dim:EnableMouse(true)
        dim.fill = dim:CreateTexture(nil, "BACKGROUND")
        dim.fill:SetAllPoints(dim)
        dim.fill:SetColorTexture(0, 0, 0, 0.62)
        local card = CreateFrame("Frame", nil, dim)
        card:SetSize(500, 318)                 -- room under the third line: the game breaks the lines sooner
        card:SetPoint("CENTER", 0, 10)
        card.surface, card.outline = Kit.Rounded(card, 18, 0.07, 0.085, 0.095, 0.99, 0.14)
        card.art = card:CreateTexture(nil, "ARTWORK")
        card.art:SetSize(92, 92)
        card.art:SetPoint("TOP", 0, -18)
        card.title = Kit.Text(card, 18, C.text, "CENTER")
        card.title:SetPoint("TOP", 0, -118)
        card.title:SetWidth(460)
        card.lines = {}
        for i = 1, 3 do
            local line = Kit.Text(card, 12, C.textSoft, "CENTER")
            line:SetPoint("TOP", 0, -150 - (i - 1) * 34)
            line:SetWidth(440)
            card.lines[i] = line
        end
        card.ok = Kit.Button(card, 160, 34, "", function()
            KH.db.seen[s.place] = true
            dim:Hide()
        end)
        card.ok:SetPoint("BOTTOM", 0, 16)
        card.ok:SetStyle("primary")
        dim.card = card
        s.coach = dim
    end
    local card = s.coach.card
    card.art:SetTexture(BuildingArt(s.place))
    card.title:SetText(BuildingName(s.place))
    for i, line in ipairs(card.lines) do line:SetText(T("tut_" .. s.place .. i)) end
    card.ok:SetLabel(T("gotIt"))
    s.coach:Show()
end

function UI:RefreshScreen()
    local s = self.screens and self.screens[self.view]
    if not s or not KH.db then return end
    s:Refresh()
    if s.art and s.place then
        local level = V:Level(s.place)
        s.art:SetTexture(BuildingArt(s.place, level))
        s.art:SetAlpha(level > 0 and 1 or 0.45)
    end
end

function UI:Show(view)
    self:Create()
    local opening = not self.frame:IsShown()
    if opening then
        -- what changed while the window was closed is simply shown, not animated
        self.coinsSeen, self.levelSeen = nil, nil
        Notice("")
        self.frame:Show()
    end
    self.win:Select(view or "village")
    if opening then self:AwayOnOpen() end
end

local function InCombat() return _G.InCombatLockdown and InCombatLockdown() end

function UI:Toggle()
    self:Create()
    if not self.frame:IsShown() and InCombat() then
        Notice(T("inCombat"))
        KH:Notify(T("inCombat"))
        return
    end
    if self.frame:IsShown() then self.frame:Hide() else self:Show() end
end

function UI:Refresh()
    self:UpdateBadge()
    if self.frame and self.frame:IsShown() and KH.db then
        self:RefreshHeader()
        self:RefreshScreen()
    end
end
-- ----------------------------------------------------------------------------
-- The clock: the rings move, the badge counts, and a plot that finishes is announced once
-- ----------------------------------------------------------------------------
local announced = {}
local acc = 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 1 or not KH.db then return end
    acc = 0
    UI:Tick()
end)

function UI:Tick()
    KH.Daily:Ensure()
    -- the achievements: an old save gets what it already did, quietly and in one line; then each new one has its card
    local new = KH.Achievements:Check()
    if not KH.db.achSeeded then
        KH.db.achSeeded = true
        if #new > 0 then KH:Print(T("achOld", #new)) end
    elseif #new > 0 then
        UI:AchievementCard(new)
    end
    KH.Adventure:Tick()                                    -- a flight that starts reminds of the village
    -- the random events: they only come with the game open (this clock), and go away when their time is over
    local new = KH.Events:Update()
    if new then KH:Notify(KH.Say("ev_new_" .. new.kind)) end
    for _, recipe in ipairs(KH.Workshop:Update()) do
        if KH.db.alerts then KH:Notify(KH.Say("craftDone", T("good_" .. recipe))) end
    end
    -- the Barn passes 80%: one line, before the Garden, the Mine or the Pond stop
    local fill = KH.Village:Fill()
    if fill >= KH.Balance.BARN_WARN and not UI.barnWarned then
        UI.barnWarned = true
        if KH.db.alerts then KH:Notify(KH.Say(fill >= 1 and "alertBarnFull" or "barnAlmost", math.floor(fill * 100))) end
    elseif fill < KH.Balance.BARN_WARN then
        UI.barnWarned = nil
    end
    local back = KH.Inn:Update()
    if back > 0 and KH.db.alerts then KH:Notify(KH.Say(back == 1 and "innBackOne" or "innBackMany", back)) end
    local built, level = KH.Village:Update()
    if built then
        local text = KH.Say("built", T("b_" .. built), level)
        if KH.db.alerts then KH:Notify(text) end
        Notice(text)
    end
    for i = 1, KH.db.nplots do
        local ready = KH.Farm:Status(i) == "ready"
        if ready and not announced[i] then
            announced[i] = true
            local plot = KH.db.plots[i]
            if KH.db.alerts and plot then KH:Notify(KH.Say("readyAlert", D.Name(plot.plant))) end
        elseif not ready then
            announced[i] = nil
        end
    end
    self:Refresh()
end

KH:On("PLAYER_LOGIN", function()
    D.Preload()
    KH.Orders:Ensure()
    KH.Daily:Ensure()
    UI:CreateMinimap()
    UI:CreateBubble()
    -- what was ready when logging in is not announced again by the clock; the welcome line tells it once
    for i = 1, KH.db.nplots do
        if KH.Farm:Status(i) == "ready" then announced[i] = true end
    end
    KH.After(6, function()
        local n = KH.Farm:ReadyCount()
        if KH.db.welcome and n > 0 then KH:Notify(KH.Say(n == 1 and "headReadyOne" or "headReadyMany", n))
        elseif KH.db.welcome and KH.VoiceLines("hello") > 0 then KH:Notify(KH.Say("hello")) end
    end)
end)
KH:On("GET_ITEM_INFO_RECEIVED", function() UI:Refresh() end)
-- a fight starts: the window is not in the way
KH:On("PLAYER_REGEN_DISABLED", function()
    if UI.frame and UI.frame:IsShown() then UI.frame:Hide() end
end)
