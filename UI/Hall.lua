local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local HALL_ROW, HALL_GAP = 46, 4

local function Effect(id, level)
    if V.MAKES[id] then return level == 0 and T("emptyLot") or T("fx_" .. id, V:Rate(id, level)) end
    if id == "workshop" then return level == 0 and T("emptyLot") or T("fx_workshop", KH.Workshop.QueueAt(level)) end
    if id == "inn" then return level == 0 and T("emptyLot") or T("fx_" .. id, level) end
    if id == "garden" then return T("fx_garden", math.min(D.MAX_PLOTS, 1 + level)) end
    if id == "barn" then return T("fx_barn", V:BarnCap(level)) end
    if id == "market" then return T("fx_market", math.floor((V:PayBonus(level) - 1) * 100 + 0.5)) end
    return T("fx_hall", level)
end
P.Effect = Effect

-- The Mine and the Pond: they work by themselves, so this screen only says what they make and where it goes
local function BuildSource(id)
    return function(win)
        local s = Screen(win, id)
        s.rate = Kit.Text(s.frame, 18, C.text)
        s.rate:SetPoint("TOPLEFT", 0, -90)
        s.have = Kit.Text(s.frame, 12, C.textSoft)
        s.have:SetPoint("TOPLEFT", 0, -124)
        s.action = Kit.Button(s.frame, 220, 36, T("openBarn"), function() UI:Show("barn") end)
        s.action:SetPoint("BOTTOMRIGHT", 0, 0)
        s.action:SetStyle("primary")
        function s:Refresh()
            local level = V:Level(id)
            self.head:SetText(BuildingName(id))
            self.sub:SetText(T("b_" .. id .. "D"))
            self.rate:SetText(level > 0 and T("fx_" .. id, V:Rate(id)) or "")
            self.have:SetText(level > 0 and T("stored", V:Stored(), V:BarnCap()) or "")
            self.action:SetShown(level > 0)
        end
        return s
    end
end

local function BuildHall(win)
    local s = Screen(win, "hall")
    local W = s.width
    s.rows = {}
    for i, id in ipairs(V.BUILDINGS) do
        local row = CreateFrame("Frame", nil, s.frame)
        row.id = id
        row:SetSize(W, HALL_ROW)
        row:SetPoint("TOPLEFT", 0, -66 - (i - 1) * (HALL_ROW + HALL_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.art = row:CreateTexture(nil, "ARTWORK")
        row.art:SetSize(38, 38)
        row.art:SetPoint("LEFT", 10, 2)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 58, -4)
        row.now = Kit.Text(row, 10, C.textSoft)
        row.now:SetPoint("TOPLEFT", 58, -19)
        row.now:SetWidth(W - 58 - 196)
        row.now:SetWordWrap(false)
        row.cost = Kit.Text(row, 10, C.textMuted)
        row.cost:SetPoint("TOPLEFT", 58, -32)
        row.cost:SetWidth(W - 58 - 196)
        row.cost:SetWordWrap(false)
        row.bar = Kit.Bar(row, W - 58 - 206, 3)
        row.bar:SetPoint("TOPLEFT", 58, -38)
        row.bar:Hide()
        row.button = Kit.Button(row, 168, 28, "", function()
            local ok, why = V:Upgrade(row.id)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        row.button:SetPoint("RIGHT", -16, 0)
        s.rows[i] = row
    end

    function s:Refresh()
        local db = KH.db
        local work, left, progress = V:Work()
        if work then
            self.head:SetText(T("hallWorkH", BuildingName(work.id), V:Level(work.id) + 1))
            self.sub:SetText(T("hallWorkS", KH.Duration(left)))
        else
            self.head:SetText(T("hallH"))
            self.sub:SetText(T("hallS"))
        end
        local offered = false
        for _, row in ipairs(self.rows) do
            local id = row.id
            local level = V:Level(id)
            local nxt = V:Next(id)
            local working = work ~= nil and work.id == id
            row.art:SetTexture(BuildingArt(id))
            row.name:SetText(level == 0 and T("notBuilt", BuildingName(id)) or T("nameLevelLong", BuildingName(id), level))
            row.bar:SetShown(working)
            row.cost:SetShown(not working)
            row.outline:SetColor(working and C.accent[1] or 1, working and C.accent[2] or 1, working and C.accent[3] or 1, working and 0.55 or 0.06)
            if not nxt then
                row.now:SetText(Effect(id, level))
                row.cost:SetText(T("why_maxLevel"))
                row.button:SetLabel(T("maxLevel"))
                row.button:SetStyle("quiet")
                row.button:SetEnabledState(false)
            else
                if level == 0 then
                    row.now:SetText("|cff40d9c4" .. Effect(id, nxt.level) .. "|r")
                else
                    row.now:SetText(Effect(id, level) .. "   |cff40d9c4>  " .. Effect(id, nxt.level) .. "|r")
                end
                if nxt.ore > 0 then
                    row.cost:SetText(T("upgradeCostOre", KH.Number(nxt.cost), nxt.ore, KH.Duration(nxt.time)))
                else
                    row.cost:SetText(T("upgradeCost", KH.Number(nxt.cost), KH.Duration(nxt.time)))
                end
                if working then
                    row.bar:Set(progress)
                    row.button:SetLabel(T("building", KH.Duration(left)))
                    row.button:SetStyle("quiet")
                    row.button:SetEnabledState(false)
                else
                    local ok, why, n = V:CanUpgrade(id)
                    if ok then
                        row.button:SetLabel(level == 0 and T("build") or T("upgradeTo", nxt.level))
                        row.button:SetStyle(offered and "quiet" or "primary")
                        offered = true
                        row.button:SetEnabledState(true)
                    else
                        row.button:SetLabel(T("short_" .. why, why == "coins" and KH.Number(n) or n))
                        row.button:SetStyle("quiet")
                        row.button:SetEnabledState(false)
                    end
                end
            end
        end
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The guide: how the homestead works, in four short pages. The numbers come from the rules themselves (Data, Village),
-- so the guide cannot say something the game does not do.
-- ----------------------------------------------------------------------------

P.builders.hall = BuildHall
P.builders.mine = BuildSource("mine")
P.builders.pond = BuildSource("pond")
