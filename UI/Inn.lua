local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local FOLLOWER_H, FOLLOWER_GAP = 52, 6

local function BuildInn(win)
    local s = Screen(win, "inn")
    local W = s.width
    local In = KH.Inn
    s.rows = {}
    for i = 1, In.MAX do
        local row = CreateFrame("Frame", nil, s.frame)
        row.index = i
        row:SetSize(W, FOLLOWER_H)
        row:SetPoint("TOPLEFT", 0, -66 - (i - 1) * (FOLLOWER_H + FOLLOWER_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.disc = row:CreateTexture(nil, "ARTWORK")          -- the portrait of the follower
        row.disc:SetTexture(VDIR .. "follower" .. i)
        row.disc:SetSize(42, 42)
        row.disc:SetPoint("LEFT", 8, 0)
        row.initial = row:CreateFontString(nil, "OVERLAY")    -- (kept empty: the portrait says who it is)
        row.initial:SetFont(Kit.Font(), 1, "")
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("TOPLEFT", 58, -9)
        row.state = Kit.Text(row, 10, C.textSoft)
        row.state:SetPoint("TOPLEFT", 58, -29)
        row.state:SetWidth(W - 58 - 330)
        row.state:SetWordWrap(false)
        row.bar = Kit.Bar(row, 200, 3)
        row.bar:SetPoint("TOPLEFT", 58, -40)
        row.missions = {}
        for k, m in ipairs(In.MISSIONS) do
            local b = Kit.Button(row, 100, 30, "", function()
                local ok, why, n = In:Start(row.index, m.id)
                if not ok then Notice(Reason(why)) end
                UI:Refresh()
            end)
            b:SetPoint("RIGHT", -10 - (#In.MISSIONS - k) * 106, 0)
            row.missions[k] = b
        end
        row.collect = Kit.Button(row, 200, 30, "", function()
            local coins, ore = In:Collect(row.index)
            if coins > 0 then
                Notice(ore > 0 and T("collected2", KH.Number(coins), ore) or T("collected", KH.Number(coins)))
            end
            UI:Refresh()
        end)
        row.collect:SetPoint("RIGHT", -10, 0)
        row.collect:SetStyle("primary")
        s.rows[i] = row
    end
    s.action = Kit.Button(s.frame, 220, 36, "", function()
        local coins, ore = In:CollectAll()
        if coins > 0 then Notice(ore > 0 and T("collected2", KH.Number(coins), ore) or T("collected", KH.Number(coins))) end
        UI:Refresh()
    end)
    s.action:SetPoint("BOTTOMRIGHT", 0, 0)
    s.action:SetStyle("primary")
    s.note = Kit.Text(s.frame, 11, C.textSoft)
    s.note:SetPoint("BOTTOMLEFT", 0, 12)
    s.note:SetWidth(W - 240)
    s.note:SetWordWrap(false)

    function s:Refresh()
        local level = V:Level("inn")
        local count = In:Count()
        local back = In:BackCount()
        if level == 0 then
            self.head:SetText(T("innNoH")); self.sub:SetText(T("innNoS"))
        elseif back > 0 then
            self.head:SetText(T(back == 1 and "innBackOneH" or "innBackManyH", back)); self.sub:SetText(T("innBackS"))
        elseif In:AwayCount() > 0 then
            self.head:SetText(T("innAwayH", In:AwayCount())); self.sub:SetText(T("innAwayS"))
        else
            self.head:SetText(T("innH")); self.sub:SetText(T("innS"))
        end
        for _, row in ipairs(self.rows) do
            local i = row.index
            local status, left, progress = In:Status(i)
            row:SetShown(level > 0)
            row.name:SetText(In.NAMES[i])
            row.bar:Hide()
            row.collect:Hide()
            for _, b in ipairs(row.missions) do b:Hide() end
            local dim = status == "locked"
            row.disc:SetAlpha(dim and 0.35 or 1)
            if row.disc.SetDesaturated then row.disc:SetDesaturated(dim) end
            row.outline:SetColor(status == "back" and C.accent[1] or 1, status == "back" and C.accent[2] or 1, status == "back" and C.accent[3] or 1,
                status == "back" and 0.55 or 0.06)
            if status == "locked" then
                row.name:SetText(In.NAMES[i] .. "  |cff757a87" .. T("locked") .. "|r")
                row.state:SetText(T("innLocked", i))
            else
                row.name:SetText(T("nameLevelLong", In.NAMES[i], In:Level(i)))
                if status == "idle" then
                    row.state:SetText(T("idleText", In:Follower(i).done))
                    for k, m in ipairs(In.MISSIONS) do
                        local b = row.missions[k]
                        b:Show()
                        b:SetLabel(T("missionBtn", KH.Duration(m.time), m.fish))
                        b:SetEnabledState(V:Good("fish") >= m.fish)
                    end
                elseif status == "away" then
                    local m = In.Mission(In:Follower(i).mission.kind)
                    row.state:SetText(T("awayText", KH.Duration(left)) .. "   |cff757a87" .. T("missionPays", KH.Number(In:Pay(i, m))) .. "|r")
                    row.bar:SetShown(true)
                    row.bar:Set(progress)
                else
                    local m = In.Mission(In:Follower(i).mission.kind)
                    row.state:SetText("|cff59d973" .. T("backText") .. "|r")
                    row.collect:Show()
                    row.collect:SetLabel(T("collectOne", KH.Number(In:Pay(i, m))))
                end
            end
        end
        self.action:SetLabel(T("collectAll"))
        self.action:SetEnabledState(back > 0)
        self.action:SetStyle(back > 0 and "primary" or "quiet")
        self.note:SetText(level > 0 and T("fishHave", V:Good("fish")) or "")
    end
    return s
end

P.builders.inn = BuildInn
