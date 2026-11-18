--[[
    A small stand-in for the WoW client's UI, enough to run a Korum addon outside the game and see its windows.
    (ferramentas/simulador_ui.py loads this, runs the addon, and paints what SIM.Dump() returns.)

    It keeps what the addon says about every frame, texture and font string (anchors, sizes, colours, texts), resolves the
    anchors into rectangles the way the client does, and hands back the visible regions in drawing order.
    Coordinates are the game's: the origin at the bottom left of the screen, y growing upwards.
]]

SIM = {order = 0, frames = {}, timers = {}, now = 0, W = 1280, H = 720, clock = 1700000000}

local M = {}
local NOOP = function() end
local MT = {}
MT.__index = function(t, k)
    local v = M[k]
    if v ~= nil then return v end
    if type(k) == "string" and k:match("^%u") then return NOOP end
    return nil
end

local STRATA = {BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8}
local LAYER = {BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5}

local function New(kind, parent)
    SIM.order = SIM.order + 1
    return setmetatable({kind = kind, parent = parent, points = {}, shown = true, alpha = 1, _ord = SIM.order,
        scripts = {}, events = {}, vr = 1, vg = 1, vb = 1, va = 1}, MT)
end

-- ----------------------------------------------------------------------------
-- Anchors and sizes
-- ----------------------------------------------------------------------------
function M:SetPoint(point, a, b, c, d)
    local rel, relPoint, x, y
    if type(a) == "number" then
        x, y = a, b
    else
        rel, relPoint, x, y = a, b, c, d
        if type(relPoint) == "number" then relPoint, x, y = nil, relPoint, x end
    end
    if type(rel) == "string" then rel = _G[rel] end
    self.allpoints = nil
    self.points[point] = {rel = rel, relPoint = relPoint or point, x = x or 0, y = y or 0}
end
function M:GetChildren()
    local out = {}
    for _, f in ipairs(SIM.frames) do
        if f.parent == self then out[#out + 1] = f end
    end
    return unpack(out)
end
function M:GetPoint(i)
    local order = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    local n = 0
    for _, name in ipairs(order) do
        local pt = self.points[name]
        if pt then
            n = n + 1
            if n == (i or 1) then return name, pt.rel, pt.relPoint, pt.x, pt.y end
        end
    end
end
function M:ClearAllPoints() self.points = {}; self.allpoints = nil end
function M:SetAllPoints(rel) self.points = {}; self.allpoints = rel or self.parent or UIParent end
function M:SetSize(w, h) self.w, self.h = w, h end
function M:SetWidth(w) self.w = w end
function M:SetHeight(h) self.h = h end
function M:GetWidth() return (SIM.Rect(self))[3] end
function M:GetHeight() return (SIM.Rect(self))[4] end
function M:GetSize() local r = SIM.Rect(self) return r[3], r[4] end
function M:GetCenter() local r = SIM.Rect(self) return r[1] + r[3] / 2, r[2] + r[4] / 2 end
function M:GetLeft() return SIM.Rect(self)[1] end
function M:GetBottom() return SIM.Rect(self)[2] end
function M:GetRight() local r = SIM.Rect(self) return r[1] + r[3] end
function M:GetTop() local r = SIM.Rect(self) return r[2] + r[4] end
function M:GetEffectiveScale() return 1 end
function M:GetScale() return 1 end
function M:GetParent() return self.parent end
function M:SetParent(p) self.parent = p end
function M:GetName() return self.name end

-- ----------------------------------------------------------------------------
-- Showing
-- ----------------------------------------------------------------------------
local function Visible(r)
    while r do
        if not r.shown then return false end
        r = r.parent
    end
    return true
end
SIM.Visible = Visible

function M:Show()
    if self.shown then return end
    self.shown = true
    if self.scripts.OnShow and Visible(self) then self.scripts.OnShow(self) end
end
function M:Hide()
    if not self.shown then return end
    local was = Visible(self)
    self.shown = false
    if self.scripts.OnHide and was then self.scripts.OnHide(self) end
end
function M:SetShown(v) if v then self:Show() else self:Hide() end end
function M:IsShown() return self.shown end
function M:IsVisible() return Visible(self) end
function M:SetAlpha(a) self.alpha = a end
function M:GetAlpha() return self.alpha end

-- ----------------------------------------------------------------------------
-- Frames
-- ----------------------------------------------------------------------------
function M:SetScript(k, fn) self.scripts[k] = fn end
function M:GetScript(k) return self.scripts[k] end
function M:HookScript(k, fn)
    local old = self.scripts[k]
    self.scripts[k] = old and function(...) old(...); fn(...) end or fn
end
function M:HasScript() return true end
function M:RegisterEvent(e) self.events[e] = true end
function M:UnregisterEvent(e) self.events[e] = nil end
function M:SetFrameStrata(s) self.strata = s end
function M:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function M:SetFrameLevel(l) self.level = l end
function M:GetFrameLevel() return (type(self.level) == "number" and self.level) or ((self.parent and self.parent.kind == "frame" and self.parent:GetFrameLevel() or 0) + 1) end
function M:IsEnabled() return self.disabled ~= true end
function M:Enable() self.disabled = false end
function M:Disable() self.disabled = true end
function M:IsMouseOver() return false end

function M:CreateTexture(name, layer, inherits, sublevel)
    local t = New("texture", self)
    t.layer, t.sublevel = layer or "ARTWORK", sublevel or 0
    self.regions = self.regions or {}
    self.regions[#self.regions + 1] = t
    return t
end
function M:CreateFontString(name, layer)
    local t = New("font", self)
    t.layer, t.sublevel = layer or "ARTWORK", 0
    t.text, t.size, t.flags, t.justify, t.wrap = "", 12, "", "CENTER", true
    self.regions = self.regions or {}
    self.regions[#self.regions + 1] = t
    return t
end
function M:CreateMaskTexture()
    return New("mask", self)
end

-- ----------------------------------------------------------------------------
-- Textures
-- ----------------------------------------------------------------------------
function M:SetTexture(path) self.texture = path; self.solid = nil end
function M:GetTexture() return self.texture end
function M:SetColorTexture(r, g, b, a) self.solid = {r, g, b, a or 1}; self.texture = nil end
function M:SetVertexColor(r, g, b, a) self.vr, self.vg, self.vb, self.va = r, g, b, a or 1 end
function M:SetTexCoord(l, r, t, b) self.coords = {l, r, t, b} end
function M:SetRotation(rad) self.rotation = rad end
function M:SetBlendMode(mode) self.blend = mode end
function M:SetDesaturated(on) self.desaturated = on and true or false end
function M:AddMaskTexture(mask) self.mask = mask end
function M:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel or 0 end

-- ----------------------------------------------------------------------------
-- Font strings
-- ----------------------------------------------------------------------------
function M:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags or ""; return true end
function M:GetFont() return self.font or "Fonts\\FRIZQT__.TTF", self.size or 12, self.flags or "" end
function M:SetText(t) self.text = t == nil and "" or tostring(t) end
function M:SetFormattedText(f, ...) self.text = string.format(f, ...) end
function M:GetText() return self.text end
function M:SetTextColor(r, g, b, a) self.tr, self.tg, self.tb, self.ta = r, g, b, a or 1 end
function M:SetJustifyH(j) self.justify = j end
function M:SetJustifyV(j) self.justifyV = j end
function M:SetWordWrap(on) self.wrap = on and true or false end
function M:GetStringWidth()
    local w = PY_MEASURE(self.text or "", self.size or 12, self.flags or "", 0, false)
    return w
end
function M:GetStringHeight()
    local _, h = PY_MEASURE(self.text or "", self.size or 12, self.flags or "", self.w or 0, self.wrap ~= false)
    return h
end
function M:GetNumLines() return 1 end
function M:AddLine() end                      -- the tooltip
function M:SetOwner() end

-- ----------------------------------------------------------------------------
-- Layout: every region to {left, bottom, width, height}
-- ----------------------------------------------------------------------------
local pass

local function Intrinsic(r)
    if r.kind == "font" then
        local w, h = PY_MEASURE(r.text or "", r.size or 12, r.flags or "", r.w or 0, r.wrap ~= false)
        return r.w or w, r.h or h
    end
    return r.w or 0, r.h or 0
end

local function Resolve(r)
    if r == nil then return {0, 0, SIM.W, SIM.H} end
    if pass[r] then return pass[r] end
    if r == UIParent or r == WorldFrame then
        pass[r] = {0, 0, SIM.W, SIM.H}
        return pass[r]
    end
    pass[r] = {0, 0, 0, 0}                        -- a cycle falls here instead of looping
    local rect
    if r.allpoints then
        local p = Resolve(r.allpoints)
        rect = {p[1], p[2], p[3], p[4]}
    else
        local L, R, T, B, CX, CY
        for point, pt in pairs(r.points) do
            local p = Resolve(pt.rel or r.parent or UIParent)
            local rp = pt.relPoint
            local x = (rp:find("LEFT") and p[1]) or (rp:find("RIGHT") and p[1] + p[3]) or (p[1] + p[3] / 2)
            local y = (rp:find("BOTTOM") and p[2]) or (rp:find("TOP") and p[2] + p[4]) or (p[2] + p[4] / 2)
            x, y = x + pt.x, y + pt.y
            if point:find("LEFT") then L = x elseif point:find("RIGHT") then R = x else CX = x end
            if point:find("BOTTOM") then B = y elseif point:find("TOP") then T = y else CY = y end
        end
        local iw, ih
        local w = (L and R) and (R - L)
        local h = (T and B) and (T - B)
        if not w or not h then
            if r.kind == "font" and w and not r.w then
                -- stretched between two anchors: the text wraps (or is cut) to that width
                local _, hh = PY_MEASURE(r.text or "", r.size or 12, r.flags or "", w, r.wrap ~= false)
                iw, ih = w, r.h or hh
            else
                iw, ih = Intrinsic(r)
            end
        end
        w = w or iw
        h = h or ih
        local left = L or (R and R - w) or (CX and CX - w / 2) or 0
        local bottom = B or (T and T - h) or (CY and CY - h / 2) or 0
        rect = {left, bottom, w, h}
        if next(r.points) == nil then rect.unplaced = true end
    end
    pass[r] = rect
    return rect
end

function SIM.Rect(r)
    pass = {}
    return Resolve(r)
end

-- ----------------------------------------------------------------------------
-- What to draw, in order
-- ----------------------------------------------------------------------------
local function EffAlpha(r)
    local a = 1
    while r do
        a = a * (r.alpha or 1)
        r = r.parent
    end
    return a
end

function SIM.Dump()
    pass = {}
    local frames = {}
    for _, f in ipairs(SIM.frames) do
        if Visible(f) and f.regions then frames[#frames + 1] = f end
    end
    table.sort(frames, function(a, b)
        local sa, sb = STRATA[a:GetFrameStrata()] or 3, STRATA[b:GetFrameStrata()] or 3
        if sa ~= sb then return sa < sb end
        local la, lb = a:GetFrameLevel(), b:GetFrameLevel()
        if la ~= lb then return la < lb end
        return a._ord < b._ord
    end)
    local out = {}
    for _, f in ipairs(frames) do
        local regions = {}
        for _, r in ipairs(f.regions) do
            if r.shown then regions[#regions + 1] = r end
        end
        table.sort(regions, function(a, b)
            local la, lb = LAYER[a.layer] or 3, LAYER[b.layer] or 3
            if la ~= lb then return la < lb end
            if a.sublevel ~= b.sublevel then return a.sublevel < b.sublevel end
            return a._ord < b._ord
        end)
        for _, r in ipairs(regions) do
            local rect = Resolve(r)
            local item = {kind = r.kind, x = rect[1], y = rect[2], w = rect[3], h = rect[4], alpha = EffAlpha(r)}
            if rect.unplaced or (f ~= UIParent and Resolve(f).unplaced and not next(r.points)) then item.skip = true end
            if r.kind == "texture" then
                item.texture = r.texture
                if r.solid then item.sr, item.sg, item.sb, item.sa = r.solid[1], r.solid[2], r.solid[3], r.solid[4] end
                item.vr, item.vg, item.vb, item.va = r.vr, r.vg, r.vb, r.va
                if r.coords then item.c1, item.c2, item.c3, item.c4 = r.coords[1], r.coords[2], r.coords[3], r.coords[4] end
                item.rotation, item.blend, item.desaturated = r.rotation, r.blend, r.desaturated
                item.masked = r.mask ~= nil
            else
                item.text, item.size, item.flags = r.text or "", r.size or 12, r.flags or ""
                item.tr, item.tg, item.tb, item.ta = r.tr or 1, r.tg or 1, r.tb or 1, r.ta or 1
                item.justify, item.wrap, item.fixed = r.justify or "CENTER", r.wrap ~= false, (r.w ~= nil) or false
                -- for ferramentas/conferir_textos.py: a text placed beside another text follows its real width in the game
                item.id = r._ord
                for _, pt in pairs(r.points) do
                    if pt.rel and pt.rel.kind and pt.rel.kind ~= "texture" and pt.rel.kind ~= "frame" then item.rel = pt.rel._ord end
                end
            end
            out[#out + 1] = item
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- The client's globals the addons use
-- ----------------------------------------------------------------------------
function CreateFrame(kind, name, parent)
    if type(parent) == "string" then parent = _G[parent] end
    local f = New("frame", parent)
    f.name = name
    f.frameType = kind
    if name then _G[name] = f end
    SIM.frames[#SIM.frames + 1] = f
    return f
end

UIParent = CreateFrame("Frame", "UIParent")
WorldFrame = UIParent
Minimap = CreateFrame("Frame", "Minimap", UIParent)
Minimap:SetSize(140, 140)
Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -24, -24)
GameTooltip = CreateFrame("Frame", "GameTooltip", UIParent)
GameTooltip:Hide()
GameFontNormal = New("font", UIParent)
UISpecialFrames = {}
SlashCmdList = {}
PRINTS = {}
function print(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
    PRINTS[#PRINTS + 1] = table.concat(t, " ")
end
function time(t) if t then return os.time(t) end return SIM.clock end     -- time({year=...}) as in the game
function date(f) return os.date(f, SIM.clock) end
function GetTime() return SIM.now end
function GetLocale() return SIM.locale or "enUS" end
function GetCursorPosition() return 0, 0 end
function InCombatLockdown() return false end
function UnitName() return "Korum" end
function GetRealmName() return "Forever" end
function hooksecurefunc() end
tinsert, tremove, wipe = table.insert, table.remove, function(t) for k in pairs(t) do t[k] = nil end return t end
format, strfind, strsub, strlower, strupper, floor, ceil, min, max, abs =
    string.format, string.find, string.sub, string.lower, string.upper, math.floor, math.ceil, math.min, math.max, math.abs
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
C_Timer = {After = function(seconds, fn) SIM.timers[#SIM.timers + 1] = {at = SIM.now + seconds, fn = fn} end}

function SIM.Fire(event, ...)
    for _, f in ipairs(SIM.frames) do
        if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
end

-- the game runs: timers that are due, then every visible frame's OnUpdate
function SIM.Advance(seconds, step)
    step = step or 0.05
    local left = seconds
    while left > 1e-9 do
        local dt = math.min(step, left)
        left = left - dt
        SIM.now = SIM.now + dt
        local due = {}
        for i = #SIM.timers, 1, -1 do
            if SIM.timers[i].at <= SIM.now then due[#due + 1] = table.remove(SIM.timers, i) end
        end
        for i = #due, 1, -1 do due[i].fn() end
        local n = #SIM.frames
        for i = 1, n do
            local f = SIM.frames[i]
            if f.scripts.OnUpdate and Visible(f) then f.scripts.OnUpdate(f, dt) end
        end
    end
end

function SIM.Load(path, addon, ns)
    local f = assert(io.open(path, "rb"))
    local src = f:read("*a")
    f:close()
    assert(loadstring(src, "@" .. path))(addon, ns)
end
