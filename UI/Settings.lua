local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local function BuildSettings(win)
    local s = Screen(win)
    local W = s.width
    s.langLabel = Kit.Text(s.frame, 11, C.textMuted)
    s.langLabel:SetPoint("TOPLEFT", 0, -72)
    s.lang = Kit.Segmented(s.frame, 380, {
        {value = "auto", label = T("langAuto")}, {value = "enUS", label = "English"}, {value = "ptBR", label = "Português"},
    }, function() return KH.db.lang end, function(v) KH.db.lang = v; UI:Relabel() end)
    s.lang:SetPoint("TOPLEFT", 0, -92)
    local y = -152
    s.alerts, y = Kit.Toggle(s.frame, y, W, function() return KH.db.alerts end, function(v) KH.db.alerts = v end)
    s.welcome, y = Kit.Toggle(s.frame, y, W, function() return KH.db.welcome end, function(v) KH.db.welcome = v end)
    s.minimap, y = Kit.Toggle(s.frame, y, W, function() return not KH.db.minimap.hide end,
        function(v) KH.db.minimap.hide = not v; UI:ApplyMinimap() end)
    s.bubble, y = Kit.Toggle(s.frame, y, W, function() return KH.db.bubble.show end,
        function(v) KH.db.bubble.show = v; UI:ApplyBubble() end)
    s.about = Kit.Text(s.frame, 10, C.textMuted)
    s.about:SetPoint("BOTTOMLEFT", 0, 12)

    function s:Refresh()
        self.head:SetText(T("settingsH"))
        self.sub:SetText(T("settingsS"))
        self.langLabel:SetText(T("language"))
        for _, spec in ipairs({{self.alerts, "optAlerts"}, {self.welcome, "optWelcome"}, {self.minimap, "optMinimap"}, {self.bubble, "optBubble"}}) do
            spec[1].label:SetText(T(spec[2]))
            spec[1].desc:SetText(T(spec[2] .. "D"))
            spec[1]:Sync()
        end
        self.lang.buttons[1].label:SetText(T("langAuto"))
        self.lang:Sync()
        self.about:SetText(T("about", KH.version))
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The window
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- The village: the map the window opens on. Every building is a place to click.
-- ----------------------------------------------------------------------------

P.builders.settings = BuildSettings
