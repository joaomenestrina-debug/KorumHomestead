local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, T = P.Kit, P.C, P.T
local VDIR = P.VDIR
local Notice, Reason, GoodTex = P.Notice, P.Reason, P.GoodTex
local BuildingArt, BuildingName = P.BuildingArt, P.BuildingName

-- ----------------------------------------------------------------------------
-- "While you were away": a card over the window when it opens after a while closed (Away.lua has the numbers).
-- One button brings in what is ready; the other closes the card.
-- ----------------------------------------------------------------------------
local LINES, CHIPS = 6, 6

local function Build()
    local win = UI.win
    local dim = CreateFrame("Frame", nil, win.content)
    dim:SetAllPoints(win.content)
    dim:SetFrameLevel(win.content:GetFrameLevel() + 60)
    dim:EnableMouse(true)
    dim.fill = dim:CreateTexture(nil, "BACKGROUND")
    dim.fill:SetAllPoints(dim)
    dim.fill:SetColorTexture(0, 0, 0, 0.62)
    local card = CreateFrame("Frame", nil, dim)
    card:SetSize(520, 360)
    card:SetPoint("CENTER", 0, 6)
    card.surface, card.outline = Kit.Rounded(card, 18, 0.07, 0.085, 0.095, 0.99, 0.14)
    card.title = Kit.Text(card, 18, C.text)
    card.title:SetPoint("TOPLEFT", 28, -24)
    card.sub = Kit.Text(card, 12, C.textSoft)
    card.sub:SetPoint("TOPLEFT", 28, -52)
    card.lines = {}
    for i = 1, LINES do
        local line = {}
        line.icon = card:CreateTexture(nil, "ARTWORK")
        line.icon:SetSize(28, 28)
        line.icon:SetPoint("TOPLEFT", 28, -84 - (i - 1) * 36)
        line.text = Kit.Text(card, 13, C.text)
        line.text:SetPoint("LEFT", line.icon, "RIGHT", 12, 0)
        line.text:SetWidth(420)
        line.text:SetWordWrap(false)
        line.chips = {}
        for c = 1, CHIPS do
            local chip = {}
            chip.icon = card:CreateTexture(nil, "ARTWORK")
            chip.icon:SetSize(22, 22)
            chip.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            chip.n = Kit.Text(card, 12, C.text)
            chip.n:SetPoint("LEFT", chip.icon, "RIGHT", 5, 0)
            line.chips[c] = chip
        end
        card.lines[i] = line
    end
    card.collect = Kit.Button(card, 180, 34, "", function() UI:CollectAway() end)
    card.collect:SetPoint("BOTTOMLEFT", 28, 22)
    card.close = Kit.Button(card, 120, 34, "", function() UI:HideAway() end)
    card.close:SetPoint("LEFT", card.collect, "RIGHT", 12, 0)
    dim.card = card
    dim:Hide()
    UI.away = dim
end

-- the lines of the card, from the summary: {icon, text} or {chips = {{id, n}, ...}}
local function Lines(s)
    local out = {}
    if s.ready > 0 then out[#out + 1] = {icon = BuildingArt("garden"), text = T(s.ready == 1 and "awayReadyOne" or "awayReadyMany", s.ready)} end
    if (s.visitors or 0) > 0 then
        out[#out + 1] = {icon = VDIR .. "cart", text = T(s.visitors == 1 and "awayVisitorOne" or "awayVisitorMany", s.visitors)}
    end
    for _, kind in ipairs(s.missed or {}) do                -- the ones that went away: their chance went with them
        out[#out + 1] = {icon = VDIR .. "cart", text = T("awayMissed_" .. kind), faded = true}
    end
    if s.back > 0 then out[#out + 1] = {icon = BuildingArt("inn"), text = T(s.back == 1 and "awayBackOne" or "awayBackMany", s.back)} end
    for _, b in ipairs(s.built) do
        out[#out + 1] = {icon = BuildingArt(b.id, b.level), text = T("awayBuilt", BuildingName(b.id), b.level)}
    end
    if #s.goods > 0 then out[#out + 1] = {chips = s.goods} end
    if KH.Daily and not KH.Daily:Done() then
        local streak = KH.Daily:Streak()
        out[#out + 1] = {icon = BuildingArt("market"), text = streak > 0 and T("awayDailyStreak", streak) or T("awayDaily")}
    end
    return out
end

function UI:ShowAway(s)
    if not self.away then Build() end
    local card = self.away.card
    card.title:SetText(T("awayH"))
    card.sub:SetText(T("awayS", KH.Duration(s.seconds)))
    local lines = Lines(s)
    for i, line in ipairs(card.lines) do
        local spec = lines[i]
        line.icon:SetShown(spec ~= nil and spec.icon ~= nil)
        line.text:SetShown(spec ~= nil)
        for _, chip in ipairs(line.chips) do chip.icon:Hide(); chip.n:Hide() end
        if spec and spec.chips then
            line.text:SetText(T("awayMade"))
            line.text:ClearAllPoints()
            line.text:SetPoint("TOPLEFT", card, "TOPLEFT", 28, -84 - (i - 1) * 36 - 7)
            local x = 28 + Kit.TextWidth(line.text, T("awayMade")) + 14
            for c, good in ipairs(spec.chips) do
                local chip = line.chips[c]
                if not chip then break end
                chip.icon:ClearAllPoints()
                chip.icon:SetPoint("TOPLEFT", card, "TOPLEFT", x, -84 - (i - 1) * 36 - 3)
                chip.icon:SetTexture(GoodTex(good.id))
                chip.n:SetText("+" .. KH.Number(good.n))
                chip.icon:Show(); chip.n:Show()
                x = x + 22 + 5 + Kit.TextWidth(chip.n, "+" .. KH.Number(good.n)) + 16
            end
        elseif spec then
            line.text:ClearAllPoints()
            line.text:SetPoint("LEFT", line.icon, "RIGHT", 12, 0)
            line.icon:SetTexture(spec.icon)
            line.icon:SetAlpha(spec.faded and 0.45 or 1)
            line.text:SetText(spec.text)
            Kit.Paint(line.text, spec.faded and C.textMuted or C.text)
        end
    end
    local can = s.ready > 0 or s.back > 0
    card.collect:SetLabel(T("awayCollect"))
    card.collect:SetStyle(can and "primary" or "quiet")
    card.collect:SetEnabledState(can)
    card.close:SetLabel(T("awayClose"))
    self.awaySummary = s
    self.away:Show()
end

function UI:HideAway()
    if self.away then self.away:Hide() end
    self.awaySummary = nil
end

function UI:CollectAway()
    local got = KH.Away:CollectAll()
    local text = (got.harvested > 0 or got.coins > 0) and T("awayCollected", got.harvested, KH.Number(got.coins)) or ""
    if got.why then text = (text ~= "" and text .. " " or "") .. Reason(got.why) end    -- the Barn filled up halfway
    if text ~= "" then Notice(text) end
    self:HideAway()
    KH.Away:Mark()
    self:Refresh()
end

-- the window opened: if it was closed long enough, the card tells what happened; the stamp starts again from now
function UI:AwayOnOpen()
    local s = KH.Away:Summary()
    KH.Away:Mark()
    if s then self:ShowAway(s) else self:HideAway() end
end
