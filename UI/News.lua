local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, T = P.Kit, P.C, P.T
local Screen = P.Screen

-- ----------------------------------------------------------------------------
-- What's new: the changes of the latest versions, newest first; the ones not seen before are marked
-- ----------------------------------------------------------------------------
local function BuildNews(win)
    local s = Screen(win)
    local W = s.width
    s.pool = {}
    local function Line(i)
        local fs = s.pool[i]
        if not fs then
            fs = {}
            fs.dot = s.frame:CreateTexture(nil, "ARTWORK")
            fs.dot:SetTexture(Kit.Icon("dot"))
            fs.dot:SetSize(8, 8)
            fs.text = Kit.Text(s.frame, 12, C.text)
            fs.text:SetWidth(W - 24)
            fs.title = Kit.Text(s.frame, 14, C.text)
            fs.tag = Kit.Text(s.frame, 11, C.accent)
            s.pool[i] = fs
        end
        return fs
    end
    s.go = Kit.Button(s.frame, 180, 34, "", function() UI:Show("village") end)
    s.go:SetPoint("BOTTOMLEFT", 0, 8)
    s.go:SetStyle("primary")

    function s:Refresh()
        self.head:SetText(T("newsH"))
        self.sub:SetText(T("newsS"))
        self.go:SetLabel(T("newsGo"))
        local since = UI.newsSince or KH.LatestNews()
        local bottom = -(self.height - 60)
        local y, n = -76, 0
        for e = #KH.NEWS, 1, -1 do
            local entry = KH.NEWS[e]
            if y < bottom then break end
            n = n + 1
            local head = Line(n)
            head.dot:Hide(); head.text:Hide()
            head.title:ClearAllPoints()
            head.title:SetPoint("TOPLEFT", 0, y)
            head.title:SetText(T("newsVersion", entry.version))
            head.tag:ClearAllPoints()
            head.tag:SetPoint("LEFT", head.title, "RIGHT", 10, 0)
            head.tag:SetText(entry.id > since and T("newsNew") or "")
            head.title:Show(); head.tag:Show()
            y = y - 24
            for _, text in ipairs(KH.NewsLines(entry.id)) do
                if y < bottom then break end
                n = n + 1
                local row = Line(n)
                row.dot:ClearAllPoints()
                row.dot:SetPoint("TOPLEFT", 4, y - 4)
                row.dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
                row.dot:Show()
                row.text:ClearAllPoints()
                row.text:SetPoint("TOPLEFT", 20, y)
                row.text:SetText(text)
                Kit.Paint(row.text, C.textSoft)
                row.title:Hide(); row.tag:Hide()
                row.text:Show()
                local h = row.text.GetStringHeight and row.text:GetStringHeight() or 0
                y = y - math.max(tonumber(h) or 0, 15) - 8
            end
            y = y - 12
        end
        for i = n + 1, #self.pool do
            local fs = self.pool[i]
            fs.dot:Hide(); fs.text:Hide(); fs.title:Hide(); fs.tag:Hide()
        end
        self.shown = n
    end
    return s
end

P.builders.news = BuildNews

-- Opens the screen. `fresh` marks the entries the player had not seen yet; after this they count as seen.
function UI:ShowNews(fresh)
    local db = KH.db
    self.newsSince = fresh and (tonumber(db.newsSeen) or 0) or KH.LatestNews()
    db.newsSeen = KH.LatestNews()
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
