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
    if id == "inn" then return level == 0 and T("emptyLot") or T(level == 1 and "fx_inn1" or "fx_inn", level) end
    if id == "garden" then return T("fx_garden", math.min(D.MAX_PLOTS, 1 + level)) end
    if id == "barn" then return T("fx_barn", V:BarnCap(level)) end      -- herbs in all, and as much of each good
    if id == "market" then return T("fx_market", math.floor((V:PayBonus(level) - 1) * 100 + 0.5)) end
    return T("fx_hall", level)
end
P.Effect = Effect

-- The Mine and the Pond: they work by themselves; the screen says what they make and where it goes, and gives the one
-- place of work of the building to a follower at home (Inn:Work): anyone adds a little, who has the trade adds more
local WORK_ROWS = 5
local function BuildSource(id)
    return function(win)
        local s = Screen(win, id)
        local W = s.width
        local In = KH.Inn
        s.sub:SetWordWrap(true)                     -- the description of the place can take two lines
        s.rate = Kit.Text(s.frame, 18, C.text)
        s.rate:SetPoint("TOPLEFT", 0, -90)
        s.have = Kit.Text(s.frame, 12, C.textSoft)
        s.have:SetPoint("TOPLEFT", 0, -124)
        s.action = Kit.Button(s.frame, 220, 36, T("openBarn"), function() UI:Show("barn") end)
        s.action:SetPoint("BOTTOMRIGHT", 0, 0)
        s.action:SetStyle("primary")

        local work = CreateFrame("Frame", nil, s.frame)
        work:SetAllPoints(s.frame)
        s.work = work
        work.head = Kit.Text(work, 11, C.textMuted)
        work.head:SetPoint("TOPLEFT", 0, -158)
        work.disc = work:CreateTexture(nil, "ARTWORK")
        work.disc:SetSize(36, 36)
        work.disc:SetPoint("TOPLEFT", 0, -178)
        work.now = Kit.Text(work, 12, C.text)
        work.now:SetPoint("LEFT", work.disc, "RIGHT", 10, 0)
        work.now:SetWidth(W - 46 - 130)
        work.now:SetWordWrap(true)
        work.stop = Kit.Button(work, 110, 28, "", function()
            In:Rest(id)
            UI:Refresh()
        end)
        work.stop:SetPoint("TOPRIGHT", 0, -182)
        work.pick = Kit.Text(work, 11, C.textMuted)
        work.pick:SetPoint("TOPLEFT", 0, -230)
        work.pick:SetWidth(W)
        work.pick:SetWordWrap(false)
        work.rows = {}
        for k = 1, WORK_ROWS do
            local r = CreateFrame("Button", nil, work)
            r:SetSize(W, 30)
            r:SetPoint("TOPLEFT", 0, -250 - (k - 1) * 33)
            r.surface, r.outline = Kit.Rounded(r, 9, 1, 1, 1, 0.04, 0.05)
            r.disc = r:CreateTexture(nil, "ARTWORK")
            r.disc:SetSize(26, 26)
            r.disc:SetPoint("LEFT", 4, 0)
            r.name = Kit.Text(r, 11, C.text)
            r.name:SetPoint("LEFT", 40, 0)
            r.name:SetWidth(200)
            r.name:SetWordWrap(false)
            r.tag = Kit.Text(r, 10, C.textSoft)
            r.tag:SetPoint("LEFT", 250, 0)
            r.tag:SetWidth(280)
            r.tag:SetWordWrap(false)
            r.gain = Kit.Text(r, 11, C.text, "RIGHT")
            r.gain:SetPoint("RIGHT", -12, 0)
            r:SetScript("OnClick", function()
                if r.fid then
                    Kit.ClickSound()
                    local ok, why = In:Work(r.fid, id)
                    if not ok then Notice(Reason(why)) end
                    UI:Refresh()
                end
            end)
            work.rows[k] = r
        end

        function s:Refresh()
            local level = V:Level(id)
            self.head:SetText(BuildingName(id))
            self.sub:SetText(T("b_" .. id .. "D"))
            self.rate:SetText(level > 0 and T("fx_" .. id, math.floor(V:Rate(id) + 0.5)) or "")
            self.have:SetText(level > 0 and T("storedHere", V:Good(V.MAKES[id]), V:BarnCap()) or "")
            self.action:SetShown(level > 0)
            local J = KH.Balance.JOBS
            local job = T("job_" .. J[id])
            local any, skilled = math.floor(J.any * 100 + 0.5), math.floor(J.skilled * 100 + 0.5)
            local list = level > 0 and In:Workers(id) or {}
            local fid = level > 0 and In:Worker(id)
            self.work:SetShown(level > 0 and (fid ~= nil or #list > 0))
            if not self.work:IsShown() then return end
            work.head:SetText(T("workH"))
            work.disc:SetShown(fid ~= nil)
            work.stop:SetShown(fid ~= nil)
            work.now:ClearAllPoints()
            if fid then
                work.disc:SetTexture(VDIR .. "follower" .. In.Def(fid).portrait)
                work.now:SetPoint("LEFT", work.disc, "RIGHT", 10, 0)
                work.now:SetText(T("workNow", T("fol_" .. fid), math.floor(In.JobBonus(fid, id) * 100 + 0.5)))
                work.stop:SetLabel(T("workStop"))
            else
                work.now:SetPoint("TOPLEFT", 0, -182)
                work.now:SetText("|cffa8adb8" .. T("workNone", any, job, skilled) .. "|r")
            end
            Kit.Fit(work.pick, #list > 0 and T("workPick") or "", W)
            for k, r in ipairs(work.rows) do
                local c = list[k]
                r:SetShown(c ~= nil)
                r.fid = c and c.id
                if c then
                    local f = In:Get(c.id)
                    local q = P.QUALITY and P.QUALITY[f.quality]
                    r.disc:SetTexture(VDIR .. "follower" .. In.Def(c.id).portrait)
                    Kit.Fit(r.name, T("fol_" .. c.id) .. "  |cffa8adb8" .. T("folLevel", f.level) .. "|r", 200)
                    if q then r.name:SetTextColor(q[1], q[2], q[3]) end
                    local pro = In.Def(c.id).job == J[id]
                    Kit.Fit(r.tag, (pro and ("|cff40d9c4" .. job .. "|r · ") or "") .. T(c.room and "sheetRoom" or "sheetLodge"), 280)
                    r.gain:SetText((pro and "|cff59d973+" or "|cffa8adb8+") .. math.floor(c.bonus * 100 + 0.5) .. "%|r")
                end
            end
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
        row.tag = Kit.Text(row, 10, C.accent)                -- "Recommended": the best upgrade now
        row.tag:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
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
        local best, reason = V:Recommend()
        if best and not work then self.sub:SetText(T("recommendS", BuildingName(best), T("rec_" .. reason))) end
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
            local recommended = id == best
            row.tag:SetText(recommended and T("recommended") or "")
            local lit = working or recommended
            row.outline:SetColor(lit and C.accent[1] or 1, lit and C.accent[2] or 1, lit and C.accent[3] or 1, working and 0.55 or (recommended and 0.4 or 0.06))
            if not nxt then
                row.now:SetText(Effect(id, level))
                row.cost:SetText(T("why_maxLevel"))
                row.button:SetLabel(T("atMax"))
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
                        row.button:SetStyle(((best and recommended) or (not best and not offered)) and "primary" or "quiet")
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
