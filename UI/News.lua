local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, T = P.Kit, P.C, P.T
local Screen = P.Screen

-- ----------------------------------------------------------------------------
-- What's new: the changes of the latest versions, newest first; the ones not seen before are marked
-- ----------------------------------------------------------------------------
local TOP, STEP, BAR = -76, 40, 6

local function BuildNews(win)
    local s = Screen(win)
    local W = s.width
    s.pool = {}
    s.off = 0
    local function Line(i)
        local fs = s.pool[i]
        if not fs then
            fs = {}
            fs.dot = s.frame:CreateTexture(nil, "ARTWORK")
            fs.dot:SetTexture(Kit.Icon("dot"))
            fs.dot:SetSize(8, 8)
            fs.text = Kit.Text(s.frame, 12, C.text)
            fs.text:SetWidth(W - 44)                            -- room for the scroll bar on the right
            fs.title = Kit.Text(s.frame, 14, C.text)
            fs.tag = Kit.Text(s.frame, 11, C.accent)
            s.pool[i] = fs
        end
        return fs
    end
    s.go = Kit.Button(s.frame, 180, 34, "", function() UI:Show("village") end)
    s.go:SetPoint("BOTTOMLEFT", 0, 8)
    s.go:SetStyle("primary")

    -- the visible part: from under the subtitle to above the button
    local bottom = -(s.height - 60)
    local viewH = TOP - bottom

    -- the scroll bar: a track that takes a click (the bar jumps there) and a thumb to drag; the wheel works too
    local track = CreateFrame("Button", nil, s.frame)
    track:SetPoint("TOPRIGHT", s.frame, "TOPRIGHT", 0, TOP)
    track:SetSize(BAR + 8, viewH)
    track.bg = track:CreateTexture(nil, "BACKGROUND")
    track.bg:SetPoint("TOP", 0, 0)
    track.bg:SetSize(BAR, viewH)
    track.bg:SetColorTexture(1, 1, 1, 0.06)
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(BAR + 8)
    thumb.fill = thumb:CreateTexture(nil, "ARTWORK")
    thumb.fill:SetPoint("TOP", 0, 0)
    thumb.fill:SetColorTexture(C.textSoft[1], C.textSoft[2], C.textSoft[3], 0.55)
    s.track, s.thumb = track, thumb

    local function CursorY()
        local _, y = GetCursorPosition()
        return (y or 0) / (track:GetEffectiveScale() or 1)
    end
    -- the thumb follows the cursor while the button is held (started on the thumb or on the track)
    local function Follow()
        local room = viewH - thumb.h
        if room <= 0 or s.maxOff <= 0 then return end
        local top = track:GetTop() or 0
        local at = top - CursorY() - s.grab                 -- where the top of the thumb should be, down from the track's top
        s:ScrollTo(at / room * s.maxOff)
    end
    local function Grab(grab)
        s.grab = grab
        thumb:SetScript("OnUpdate", Follow)
        Follow()
    end
    local function Let() thumb:SetScript("OnUpdate", nil) end
    thumb:SetScript("OnMouseDown", function()
        local top = track:GetTop() or 0
        Grab(top - CursorY() - (s.off / math.max(1, s.maxOff)) * (viewH - thumb.h))
    end)
    thumb:SetScript("OnMouseUp", Let)
    track:SetScript("OnMouseDown", function() Grab(thumb.h / 2) end)   -- the bar centres on the click
    track:SetScript("OnMouseUp", Let)
    s.frame:EnableMouseWheel(true)
    s.frame:SetScript("OnMouseWheel", function(_, delta) s:ScrollTo(s.off - delta * STEP) end)
    s.frame:HookScript("OnHide", Let)

    function s:ScrollTo(off)
        self.off = math.max(0, math.min(self.maxOff or 0, math.floor(off + 0.5)))
        self:Place()
    end

    -- lays every line where it is with the scroll; the ones outside the visible part are hidden
    function s:Place()
        for i = 1, self.shown or 0 do
            local fs, item = self.pool[i], self.items[i]
            local y = item.y + self.off
            local inside = y <= TOP and y - item.h >= bottom
            if item.head then
                fs.title:ClearAllPoints()
                fs.title:SetPoint("TOPLEFT", 0, y)
                fs.title:SetShown(inside); fs.tag:SetShown(inside)
            else
                fs.dot:ClearAllPoints()
                fs.dot:SetPoint("TOPLEFT", 4, y - 4)
                fs.text:ClearAllPoints()
                fs.text:SetPoint("TOPLEFT", 20, y)
                fs.dot:SetShown(inside); fs.text:SetShown(inside)
            end
        end
        local scrolls = self.maxOff > 0
        track:SetShown(scrolls)
        if scrolls then
            thumb.h = math.max(24, math.floor(viewH * viewH / (viewH + self.maxOff)))
            thumb:SetHeight(thumb.h)
            thumb.fill:SetSize(BAR, thumb.h)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOP", track, "TOP", 0, -math.floor(self.off / self.maxOff * (viewH - thumb.h) + 0.5))
        end
    end

    function s:Refresh()
        self.head:SetText(T("newsH"))
        self.sub:SetText(T("newsS"))
        self.go:SetLabel(T("newsGo"))
        local since = UI.newsSince or KH.LatestNews()
        local y, n = TOP, 0
        self.items = {}
        for e = #KH.NEWS, 1, -1 do
            local entry = KH.NEWS[e]
            local newer = KH.NEWS[e + 1]
            if newer and newer.version == entry.version then
                y = y + 12                                  -- the same version as the entry above: one title for both
            else
                n = n + 1
                local head = Line(n)
                head.dot:Hide(); head.text:Hide()
                head.title:SetText(T("newsVersion", entry.version))
                head.tag:ClearAllPoints()
                head.tag:SetPoint("LEFT", head.title, "RIGHT", 10, 0)
                head.tag:SetText(entry.id > since and T("newsNew") or "")
                self.items[n] = {head = true, y = y, h = 18}
                y = y - 24
            end
            for _, text in ipairs(KH.NewsLines(entry.id)) do
                n = n + 1
                local row = Line(n)
                row.dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
                row.text:SetText(text)
                Kit.Paint(row.text, C.textSoft)
                row.title:Hide(); row.tag:Hide()
                local h = math.max(tonumber(row.text.GetStringHeight and row.text:GetStringHeight() or 0) or 0, 15)
                self.items[n] = {y = y, h = h}
                y = y - h - 8
            end
            y = y - 12
        end
        for i = n + 1, #self.pool do
            local fs = self.pool[i]
            fs.dot:Hide(); fs.text:Hide(); fs.title:Hide(); fs.tag:Hide()
        end
        self.shown = n
        self.maxOff = math.max(0, (TOP - (y + 20)) - viewH)
        self.off = math.min(self.off, self.maxOff)
        self:Place()
    end
    return s
end

P.builders.news = BuildNews

-- Opens the screen. `fresh` marks the entries the player had not seen yet; after this they count as seen.
function UI:ShowNews(fresh)
    local db = KH.db
    self.newsSince = fresh and (tonumber(db.newsSeen) or 0) or KH.LatestNews()
    db.newsSeen = KH.LatestNews()
    if self.screens and self.screens.news then self.screens.news.off = 0 end      -- always from the top
    self:Show("news")
end

-- at login, after an update: the window opens once on the news (not in a fight; it waits for the fight to end)
local function OpenWhenFree()
    if not KH.HasNews() then return end
    if _G.InCombatLockdown and InCombatLockdown() then
        KH.After(5, OpenWhenFree)
        return
    end
    UI:ShowNews(true)
end

KH:On("PLAYER_LOGIN", function()
    if KH.HasNews() then KH.After(4, OpenWhenFree) end
end)
