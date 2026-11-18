local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local RECIPE_H, RECIPE_GAP, QUEUE_ROWS = 56, 6, 5
local RECIPE_TOP = 98                          -- under the line of trades
UI.trade = "alchemy"

local function BuildWorkshop(win)
    local s = Screen(win, "workshop")
    local W = s.width
    local Wk = KH.Workshop
    s.rows = {}
    local options = {}
    for _, trade in ipairs(Wk.TRADES) do options[#options + 1] = {value = trade, label = T("trade_" .. trade)} end
    s.trades = Kit.Segmented(s.frame, 360, options, function() return UI.trade end, function(v) UI.trade = v; UI:Refresh() end)
    s.trades:SetPoint("TOPLEFT", 0, -58)
    s.tradeHint = Kit.Text(s.frame, 11, C.textSoft)
    s.tradeHint:SetPoint("LEFT", s.trades, "RIGHT", 16, 0)
    s.tradeHint:SetWidth(s.width - 360 - 16)          -- what is left beside the tabs; a long hint takes two lines
    s.tradeHint:SetWordWrap(true)
    for i = 1, 3 do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, RECIPE_H)
        row:SetPoint("TOPLEFT", 0, -RECIPE_TOP - (i - 1) * (RECIPE_H + RECIPE_GAP))
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(40, 40)
        row.icon:SetPoint("LEFT", 14, 0)
        row.name = Kit.Text(row, 13, C.text)
        row.name:SetPoint("TOPLEFT", 68, -9)
        row.needs = Kit.Text(row, 10, C.textSoft)
        row.needs:SetPoint("TOPLEFT", 68, -29)
        row.needs:SetWidth(W - 68 - 190)
        row.needs:SetWordWrap(false)
        row.button = Kit.Button(row, 156, 32, "", function()
            local ok, why, n = Wk:Craft(row.id)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        row.button:SetPoint("RIGHT", -14, 0)
        row.tag = Kit.Text(row, 10, C.accent)                -- "Recommended": the craft worth the most now
        row.tag:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
        s.rows[i] = row
    end
    s.queueHead = Kit.Text(s.frame, 11, C.textMuted)
    s.queueHead:SetPoint("TOPLEFT", 0, -RECIPE_TOP - 3 * (RECIPE_H + RECIPE_GAP) - 4)
    s.queue = {}
    for i = 1, QUEUE_ROWS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W, 26)
        row:SetPoint("TOPLEFT", 0, -RECIPE_TOP - 3 * (RECIPE_H + RECIPE_GAP) - 24 - (i - 1) * 28)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", 0, 0)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("LEFT", 32, 0)
        row.left = Kit.Text(row, 11, C.textSoft, "RIGHT")
        row.left:SetPoint("RIGHT", 0, 0)
        row.bar = Kit.Bar(row, 220, 3)
        row.bar:SetPoint("LEFT", 190, 0)
        s.queue[i] = row
    end

    function s:Refresh()
        local db = KH.db
        local level = V:Level("workshop")
        local jobs = Wk:Jobs()
        if level == 0 then
            self.head:SetText(T("shopNoH")); self.sub:SetText(T("shopNoS"))
        elseif #jobs > 0 then
            self.head:SetText(T("shopBusyH", #jobs)); self.sub:SetText(T("shopBusyS", Wk:Slots()))
        else
            self.head:SetText(T("shopH")); self.sub:SetText(T("shopS", Wk:Slots()))
        end
        -- the recommended craft: of the recipes shown that can be made now (Advice.lua)
        local best, why
        self.trades:Sync()
        self.tradeHint:SetText(T("tradeHint_" .. UI.trade))
        local recipes = Wk.OfTrade(UI.trade)
        -- 7 recipes a trade, 3 rows: the two best already open and the next one to come
        local open = 0
        for i, r in ipairs(recipes) do if r.level <= level then open = i end end
        local from = math.max(1, math.min(#recipes - #self.rows + 1, open - (#self.rows - 2)))
        local shown = {}
        for i = 1, #self.rows do
            local r = recipes[from + i - 1]
            if r then shown[#shown + 1] = r.id end
        end
        best, why = KH.Advice:Craft(shown)                  -- what the Market asks first, then what is worth the most
        for i, row in ipairs(self.rows) do
            local r = recipes[from + i - 1]
            row:SetShown(r ~= nil)
            if not r then break end
            row.id = r.id
            row.icon:SetTexture(GoodTex(r.id))
            local unlocked = level >= r.level
            row.name:SetText(T("good_" .. r.id) .. "   |cff757a87" .. KH.Duration(r.time) .. "  ·  " .. T("worth", KH.Number(V:GoodSell(r.id))) .. "|r")
            local parts = {}
            for _, input in ipairs(r.inputs) do
                local have = Wk.Stock(input[1])
                local label = type(input[1]) == "string" and T("good_" .. input[1]) or D.Name(input[1])
                parts[#parts + 1] = string.format("|cff%s%d|r/%d × %s", have >= input[2] and "59d973" or "ff6a5c", have, input[2], label)
            end
            row.needs:SetText(unlocked and table.concat(parts, "   ") or T("short_recipe", r.level))
            row.icon:SetAlpha(unlocked and 1 or 0.3)
            local ok, why, n = Wk:CanCraft(row.id)
            row.tag:SetText(row.id == best and T(why == "order" and "recommendedOrder" or "recommended") or "")
            if ok then
                row.button:SetLabel(T("craft"))
                row.button:SetStyle(row.id == best and "primary" or "quiet")
            else
                row.button:SetLabel(T("short_" .. why, n))
                row.button:SetStyle("quiet")
            end
            row.button:SetEnabledState(ok)
            if row.id == best then
                row.outline:SetColor(C.accent[1], C.accent[2], C.accent[3], 0.4)
            else
                row.outline:SetColor(1, 1, 1, ok and 0.12 or 0.05)
            end
        end
        self.queueHead:SetText(level > 0 and T("queueHead", #jobs, Wk:Slots()) or "")
        for i, row in ipairs(self.queue) do
            local job = jobs[i]
            row:SetShown(job ~= nil)
            if job then
                row.icon:SetTexture(GoodTex(job.recipe))
                local more = (i == #self.queue and #jobs > i) and ("   |cff757a87+" .. (#jobs - i) .. "|r") or ""
                row.name:SetText(T("good_" .. job.recipe) .. more)
                row.left:SetText(KH.Duration(job.left))
                row.bar:SetShown(i == 1)
                if i == 1 then row.bar:Set(job.progress) end
            end
        end
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The Inn: the followers and their missions
-- ----------------------------------------------------------------------------

P.builders.workshop = BuildWorkshop
