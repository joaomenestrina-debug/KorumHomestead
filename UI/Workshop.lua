local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

-- the recipes are three cards side by side (owner, 20/11), so the queue under them has room for more lines
local RECIPE_H, RECIPE_GAP, QUEUE_ROWS = 142, 10, 6
local RECIPE_TOP = 98                          -- under the line of trades
local NEED_LINES = 3                           -- one line for each thing a recipe takes
UI.trade = "alchemy"

local function BuildWorkshop(win)
    local s = Screen(win, "workshop")
    local W = s.width
    local Wk = KH.Workshop
    s.rows = {}
    local options = {}
    for _, trade in ipairs(Wk.TABS) do options[#options + 1] = {value = trade, label = T("trade_" .. trade)} end
    s.trades = Kit.Segmented(s.frame, 440, options, function() return UI.trade end,
        function(v) UI.trade = v; s.qoff = 0; UI:Refresh() end)
    s.trades:SetPoint("TOPLEFT", 0, -58)
    s.tradeHint = Kit.Text(s.frame, 11, C.textSoft)
    s.tradeHint:SetPoint("LEFT", s.trades, "RIGHT", 16, 0)
    s.tradeHint:SetWidth(s.width - 440 - 16)          -- what is left beside the tabs; a long hint takes two lines
    s.tradeHint:SetWordWrap(true)
    local CW = math.floor((W - (Wk.ROWS - 1) * RECIPE_GAP) / Wk.ROWS)
    local TW = CW - 24
    for i = 1, Wk.ROWS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(CW, RECIPE_H)
        row:SetPoint("TOPLEFT", (i - 1) * (CW + RECIPE_GAP), -RECIPE_TOP)
        row.surface, row.outline = Kit.Rounded(row, 12, 1, 1, 1, 0.045, 0.06)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(34, 34)
        row.icon:SetPoint("TOPLEFT", 12, -12)
        row.name = Kit.Text(row, 12, C.text)
        row.name:SetPoint("TOPLEFT", 54, -12)
        row.name:SetWidth(CW - 66)
        row.name:SetWordWrap(false)
        row.meta = Kit.Text(row, 10, C.textMuted)                -- how long and what it is worth
        row.meta:SetPoint("TOPLEFT", 54, -30)
        row.meta:SetWidth(CW - 66)
        row.meta:SetWordWrap(false)
        row.tag = Kit.Text(row, 10, C.accent)                    -- "Recommended": the craft worth the most now
        row.tag:SetPoint("TOPLEFT", 12, -54)
        row.tag:SetWidth(TW)
        row.tag:SetWordWrap(false)
        row.needs = {}
        for k = 1, NEED_LINES do
            local line = Kit.Text(row, 10, C.textSoft)
            line:SetPoint("TOPLEFT", 12, -70 - (k - 1) * 15)
            line:SetWidth(TW)
            line:SetWordWrap(false)
            row.needs[k] = line
        end
        row.button = Kit.Button(row, TW, 28, "", function()
            local ok, why, n = Wk:Craft(row.id)
            if not ok then Notice(Reason(why)) end
            UI:Refresh()
        end)
        row.button:SetPoint("BOTTOM", 0, 10)
        s.rows[i] = row
    end
    local QUEUE_TOP = RECIPE_TOP + RECIPE_H + 14
    s.queueHead = Kit.Text(s.frame, 11, C.textMuted)
    s.queueHead:SetPoint("TOPLEFT", 0, -QUEUE_TOP)
    -- the queue scrolls (owner, 20/11): the wheel over it, or a click on its bar, shows the places under the first six
    local BAR, QH = 4, QUEUE_ROWS * 28
    s.qoff = 0
    local area = CreateFrame("Frame", nil, s.frame)
    area:SetSize(W, QH)
    area:SetPoint("TOPLEFT", 0, -QUEUE_TOP - 20)
    area:EnableMouseWheel(true)
    area:SetScript("OnMouseWheel", function(_, delta) s:ScrollQueue(s.qoff - delta) end)
    s.qarea = area
    local track = CreateFrame("Button", nil, area)
    track:SetSize(BAR + 8, QH)
    track:SetPoint("TOPRIGHT", 0, 0)
    track.line = track:CreateTexture(nil, "BACKGROUND")
    track.line:SetSize(BAR, QH)
    track.line:SetPoint("TOP", 0, 0)
    track.line:SetColorTexture(1, 1, 1, 0.06)
    track.thumb = track:CreateTexture(nil, "ARTWORK")
    track.thumb:SetWidth(BAR)
    track.thumb:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
    -- a click on the bar goes one page down; at the bottom, back to the top
    track:SetScript("OnClick", function()
        local most = math.max(0, #Wk:Jobs(UI.trade) - QUEUE_ROWS)
        s:ScrollQueue(s.qoff >= most and 0 or s.qoff + QUEUE_ROWS)
    end)
    s.qtrack = track
    function s:ScrollQueue(off)
        self.qoff = math.max(0, math.min(math.max(0, #Wk:Jobs(UI.trade) - QUEUE_ROWS), math.floor(off + 0.5)))
        self:Refresh()
    end
    s.queue = {}
    for i = 1, QUEUE_ROWS do
        local row = CreateFrame("Frame", nil, s.frame)
        row:SetSize(W - BAR - 16, 26)
        row:SetPoint("TOPLEFT", 0, -QUEUE_TOP - 20 - (i - 1) * 28)
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
        local jobs = Wk:Jobs(UI.trade)                     -- the queue of the tab that is open
        local all = #Wk:Jobs()
        if level == 0 then
            self.head:SetText(T("shopNoH")); self.sub:SetText(T("shopNoS"))
        elseif all > 0 then
            self.head:SetText(T("shopBusyH", all)); self.sub:SetText(T("shopBusyS", Wk:Slots()))
        else
            self.head:SetText(T("shopH")); self.sub:SetText(T("shopS", Wk:Slots()))
        end
        -- the recommended craft: of the recipes shown that can be made now (Advice.lua)
        local best, why
        for k, trade in ipairs(Wk.TABS) do
            local n = #Wk:Jobs(trade)
            self.trades.buttons[k].label:SetText(T("trade_" .. trade) .. (n > 0 and (" |cff40d9c4" .. n .. "|r") or ""))
        end
        self.trades:Sync()
        self.tradeHint:SetText(T("tradeHint_" .. UI.trade))
        local recipes = Wk.Shown(UI.trade, level)          -- the two best already open and the next one to come
        local shown = {}
        for i, r in ipairs(recipes) do shown[i] = r.id end
        best, why = KH.Advice:Craft(shown)                  -- what the Market asks first, then what is worth the most
        for i, row in ipairs(self.rows) do
            local r = recipes[i]
            row:SetShown(r ~= nil)
            if not r then break end
            row.id = r.id
            row.icon:SetTexture(GoodTex(r.id))
            local unlocked = level >= r.level
            Kit.Fit(row.name, T("good_" .. r.id), CW - 66, 10)
            Kit.Fit(row.meta, KH.Duration(r.time) .. "  ·  " .. T("worth", KH.Number(V:GoodSell(r.id))), CW - 66)
            for k, line in ipairs(row.needs) do
                local input = r.inputs[k]
                if not unlocked then
                    line:SetText(k == 1 and T("short_recipe", r.level) or "")
                elseif input then
                    local have = Wk.Stock(input[1])
                    local label = type(input[1]) == "string" and T("good_" .. input[1]) or D.Name(input[1])
                    Kit.Fit(line, string.format("|cff%s%d|r/%d × %s", have >= input[2] and "59d973" or "ff6a5c", have, input[2], label), TW)
                else
                    line:SetText("")
                end
            end
            row.icon:SetAlpha(unlocked and 1 or 0.3)
            local ok, why, n = Wk:CanCraft(row.id)
            Kit.Fit(row.tag, row.id == best and T(why == "order" and "recommendedOrder" or "recommended") or "", TW)
            if ok then
                row.button:SetLabel(T("craft"))
                row.button:SetStyle(row.id == best and "primary" or "quiet")
            else
                row.button:SetLabel(T("short_" .. why, n))       -- a label longer than the button shrinks (Kit.Fit)
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
        local most = math.max(0, #jobs - QUEUE_ROWS)
        self.qoff = math.min(self.qoff, most)
        for i, row in ipairs(self.queue) do
            local n = i + self.qoff
            local job = jobs[n]
            row:SetShown(job ~= nil)
            if job then
                row.icon:SetTexture(GoodTex(job.recipe))
                row.name:SetText(T("good_" .. job.recipe))
                row.left:SetText(KH.Duration(job.left))
                row.bar:SetShown(job.progress > 0)           -- the one being made now in this trade
                if job.progress > 0 then row.bar:Set(job.progress) end
            end
        end
        local track = self.qtrack
        track:SetShown(most > 0)
        if most > 0 then
            local QH = QUEUE_ROWS * 28
            local h = math.max(18, math.floor(QH * QUEUE_ROWS / #jobs))
            track.thumb:SetHeight(h)
            track.thumb:ClearAllPoints()
            track.thumb:SetPoint("TOP", track, "TOP", 0, -math.floor((QH - h) * self.qoff / most + 0.5))
        end
    end
    return s
end

P.builders.workshop = BuildWorkshop
