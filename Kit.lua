--[[
    Korum Homestead - visual kit

    The addon's own copy of the Korum look, pared down to what a quiet window needs: dark translucent surfaces with
    rounded corners, one accent colour (the Korum turquoise), text in three greys, pill buttons, thin progress bars,
    a dotted progress ring, and short animations (fades, bars that fill, numbers that float away).

    The textures (Media\Icons\*.tga) are white on transparent and take their colour here.
    Everything is drawn with plain frames and textures; the animations run from one OnUpdate, no AnimationGroup.
]]

local addonName, KH = ...
local Kit = {}
KH.Kit = Kit

Kit.COLORS = {
    accent = {0.25, 0.85, 0.80},
    accentBright = {0.45, 0.96, 0.91},
    onAccent = {0.02, 0.12, 0.12},      -- text over a filled accent button
    bg = {0.040, 0.052, 0.062},
    text = {0.96, 0.96, 0.98},
    textSoft = {0.66, 0.68, 0.72},
    textMuted = {0.46, 0.48, 0.53},
    textFaint = {0.30, 0.32, 0.36},
    gold = {1.00, 0.82, 0.30},
}
local C = Kit.COLORS

Kit.ICON_DIR = "Interface\\AddOns\\KorumHomestead\\Media\\Icons\\"
Kit.LOGO = "Interface\\AddOns\\KorumHomestead\\Media\\logo"
local function Icon(name) return Kit.ICON_DIR .. name end
Kit.Icon = Icon

local function Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Kit.Font()
    if not Kit.font then
        local f = GameFontNormal and GameFontNormal.GetFont and GameFontNormal:GetFont()
        Kit.font = f or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
    return Kit.font
end

function Kit.Text(parent, size, color, justify, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(Kit.Font(), size or 11, "")
    local c = color or C.text
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH(justify or "LEFT")
    fs.size = size or 11
    return fs
end

function Kit.Paint(fs, color)
    fs:SetTextColor(color[1], color[2], color[3])
end

-- the width of a text on screen; a guess by the letters when the client does not tell
function Kit.TextWidth(fs, text)
    local w = fs.GetStringWidth and fs:GetStringWidth()
    if type(w) ~= "number" or w <= 0 then w = #(text or "") * (fs.size or 11) * 0.56 end
    return math.ceil(w)
end

-- A text in a place of a known width: when it does not fit, the letter gets smaller (down to `min`) instead of the text
-- being cut or leaving its place. The width is measured on a ruler without a width, which every client answers.
local ruler
function Kit.Fit(fs, text, width, min)
    width = width or fs.fit
    local size = fs.size or 11
    if width and text and text ~= "" then
        if not ruler then
            ruler = UIParent:CreateFontString(nil, "BACKGROUND")
            ruler:Hide()
        end
        while size > (min or 8) do
            ruler:SetFont(Kit.Font(), size, "")
            ruler:SetText(text)
            if Kit.TextWidth(ruler, text) <= width then break end
            size = size - 1
        end
    end
    if fs.shown ~= size then
        fs:SetFont(Kit.Font(), size, "")
        fs.shown = size
    end
    fs:SetText(text or "")
end

local function ClickSound()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
        pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end
Kit.ClickSound = ClickSound

-- ----------------------------------------------------------------------------
-- Animations: Kit.Animate(seconds, step(0..1), done). One hidden frame drives them all.
-- ----------------------------------------------------------------------------
local anims = {}
local driver = CreateFrame("Frame")
driver:Hide()

local function Ease(p) return 1 - (1 - p) * (1 - p) end

function Kit.Step(elapsed)
    elapsed = tonumber(elapsed) or 0
    for i = #anims, 1, -1 do
        local a = anims[i]
        if a.cancelled then
            table.remove(anims, i)
        else
            a.t = a.t + elapsed
            local p = a.d > 0 and math.min(1, a.t / a.d) or 1
            local ok = pcall(a.step, a.linear and p or Ease(p))
            if p >= 1 or not ok then
                table.remove(anims, i)
                if a.done then pcall(a.done) end
            end
        end
    end
    if #anims == 0 then driver:Hide() end
end
driver:SetScript("OnUpdate", function(_, elapsed) Kit.Step(elapsed) end)

function Kit.Animate(duration, step, done, linear)
    local a = {t = 0, d = duration or 0.2, step = step, done = done, linear = linear}
    anims[#anims + 1] = a
    pcall(step, 0)
    driver:Show()
    return a
end

function Kit.FadeIn(frame, duration)
    frame:SetAlpha(0)
    return Kit.Animate(duration or 0.18, function(p) frame:SetAlpha(p) end, function() frame:SetAlpha(1) end)
end

-- ----------------------------------------------------------------------------
-- Slices: a rounded frame from a 64x64 texture, a pill from a 64x32 one
-- ----------------------------------------------------------------------------
function Kit.NineSlice(parent, path, corner, layer, sublevel)
    local slice = {parts = {}, corner = corner or 8}
    local t = 0.25
    local coords = {
        {0, t, 0, t}, {t, 1 - t, 0, t}, {1 - t, 1, 0, t},
        {0, t, t, 1 - t}, {t, 1 - t, t, 1 - t}, {1 - t, 1, t, 1 - t},
        {0, t, 1 - t, 1}, {t, 1 - t, 1 - t, 1}, {1 - t, 1, 1 - t, 1},
    }
    for i = 1, 9 do
        local tex = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        tex:SetTexture(path)
        tex:SetTexCoord(coords[i][1], coords[i][2], coords[i][3], coords[i][4])
        slice.parts[i] = tex
    end
    local p = slice.parts
    p[1]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    p[3]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    p[7]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    p[9]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT"); p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT")
    p[8]:SetPoint("TOPLEFT", p[7], "TOPRIGHT"); p[8]:SetPoint("BOTTOMRIGHT", p[9], "BOTTOMLEFT")
    p[4]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT"); p[4]:SetPoint("BOTTOMRIGHT", p[7], "TOPRIGHT")
    p[6]:SetPoint("TOPLEFT", p[3], "BOTTOMLEFT"); p[6]:SetPoint("BOTTOMRIGHT", p[9], "TOPRIGHT")
    p[5]:SetPoint("TOPLEFT", p[1], "BOTTOMRIGHT"); p[5]:SetPoint("BOTTOMRIGHT", p[9], "TOPLEFT")
    for _, i in ipairs({1, 3, 7, 9}) do p[i]:SetSize(slice.corner, slice.corner) end

    function slice:SetColor(r, g, b, a)
        for _, tex in ipairs(self.parts) do tex:SetVertexColor(r, g, b, a or 1) end
    end
    function slice:SetShown(shown)
        for _, tex in ipairs(self.parts) do tex:SetShown(shown and true or false) end
    end
    return slice
end

function Kit.ThreeSlice(owner, path, layer, sublevel)
    local slice = {}
    local function Part(l, r)
        local tex = owner:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        tex:SetTexture(path)
        tex:SetTexCoord(l, r, 0, 1)
        return tex
    end
    slice.left, slice.mid, slice.right = Part(0, 0.25), Part(0.25, 0.75), Part(0.75, 1)
    slice.parts = {slice.left, slice.mid, slice.right}
    slice.left:SetPoint("TOPRIGHT", slice.mid, "TOPLEFT")
    slice.left:SetPoint("BOTTOMRIGHT", slice.mid, "BOTTOMLEFT")
    slice.right:SetPoint("TOPLEFT", slice.mid, "TOPRIGHT")
    slice.right:SetPoint("BOTTOMLEFT", slice.mid, "BOTTOMRIGHT")
    function slice:SetCapWidth(w)
        self.left:SetWidth(w)
        self.right:SetWidth(w)
    end
    function slice:SetColor(r, g, b, a)
        for _, tex in ipairs(self.parts) do tex:SetVertexColor(r, g, b, a or 1) end
    end
    function slice:SetShown(shown)
        for _, tex in ipairs(self.parts) do tex:SetShown(shown and true or false) end
    end
    return slice
end

-- a rounded surface, with an optional hairline outline
function Kit.Rounded(frame, corner, r, g, b, a, outlineAlpha, sublevel)
    local surface = Kit.NineSlice(frame, Icon("card"), corner or 10, "BACKGROUND", sublevel or 0)
    surface:SetColor(r, g, b, a)
    local outline
    if outlineAlpha then
        outline = Kit.NineSlice(frame, Icon("border"), corner or 10, "BORDER", sublevel or 0)
        outline:SetColor(1, 1, 1, outlineAlpha)
    end
    return surface, outline
end

local function PillIn(frame, height, layer, sublevel, inset)
    local pill = Kit.ThreeSlice(frame, Icon("pill"), layer or "BACKGROUND", sublevel or 0)
    inset = inset or 0
    local cap = (height - inset * 2) / 2
    pill.mid:SetPoint("TOPLEFT", frame, "TOPLEFT", cap + inset, -inset)
    pill.mid:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -cap - inset, inset)
    pill:SetCapWidth(cap)
    return pill
end
Kit.PillIn = PillIn

function Kit.Hairline(parent, alpha)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetColorTexture(1, 1, 1, alpha or 0.06)
    return line
end

-- a square icon shown as a circle, when the client has masks
function Kit.RoundMask(owner, texture)
    if not owner.CreateMaskTexture or not texture.AddMaskTexture then return end
    pcall(function()
        local mask = owner:CreateMaskTexture()
        if not mask then return end
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(texture)
        texture:AddMaskTexture(mask)
    end)
end

-- ----------------------------------------------------------------------------
-- Controls
-- ----------------------------------------------------------------------------

-- A pill button. style "primary" is the filled accent one (one per screen); the others are quiet.
function Kit.Button(parent, width, height, text, onClick)
    height = height or 28
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)
    btn.pill = PillIn(btn, height, "BACKGROUND")
    btn.label = Kit.Text(btn, height >= 32 and 12 or 11, C.text, "CENTER")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text or "")
    btn.enabledState = true
    btn.style = "quiet"
    local function Paint()
        local hover = btn.hover
        if not btn.enabledState then
            btn.pill:SetColor(1, 1, 1, 0.04)
            Kit.Paint(btn.label, C.textFaint)
        elseif btn.style == "primary" then
            local c = hover and C.accentBright or C.accent
            btn.pill:SetColor(c[1], c[2], c[3], 1)
            Kit.Paint(btn.label, C.onAccent)
        else
            btn.pill:SetColor(1, 1, 1, hover and 0.16 or 0.08)
            Kit.Paint(btn.label, C.text)
        end
    end
    function btn:SetLabel(t) Kit.Fit(self.label, t, width - 14) end        -- a label never leaves its button
    function btn:SetStyle(style) self.style = style; Paint() end
    function btn:SetEnabledState(on)
        self.enabledState = on and true or false
        Paint()
    end
    function btn:SetOnClick(fn) onClick = fn end
    btn:SetScript("OnEnter", function() btn.hover = true; Paint() end)
    btn:SetScript("OnLeave", function() btn.hover = false; Paint() end)
    btn:SetScript("OnClick", function()
        if not btn.enabledState then return end
        ClickSound()
        if onClick then onClick() end
    end)
    Paint()
    return btn
end

-- A switch with its sentence and a quieter line of explanation
function Kit.Toggle(parent, y, width, getValue, setValue, pitch)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, 44)
    row:SetPoint("TOPLEFT", 0, y)
    row.label = Kit.Text(row, 12, C.text)
    row.label:SetPoint("TOPLEFT", 0, -6)
    row.label:SetWidth(width - 70)
    row.desc = Kit.Text(row, 10, C.textMuted)
    row.desc:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
    row.desc:SetWidth(width - 70)

    local track = CreateFrame("Frame", nil, row)
    track:SetSize(42, 24)
    track:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    track.pill = PillIn(track, 24, "BACKGROUND")
    local knob = track:CreateTexture(nil, "ARTWORK")
    knob:SetTexture(Icon("dot"))
    knob:SetSize(24, 24)
    local at

    local function Place(x)
        at = x
        knob:ClearAllPoints()
        knob:SetPoint("CENTER", track, "LEFT", 12 + 18 * x, 0)
    end
    function row:Sync(animated)
        local on = getValue() and true or false
        self.on = on
        if on then
            track.pill:SetColor(C.accent[1], C.accent[2], C.accent[3], self.hover and 1 or 0.9)
        else
            track.pill:SetColor(1, 1, 1, self.hover and 0.2 or 0.12)
        end
        local target = on and 1 or 0
        if self.anim then self.anim.cancelled = true; self.anim = nil end
        if animated and at and at ~= target then
            local from = at
            self.anim = Kit.Animate(0.14, function(p) Place(from + (target - from) * p) end, function() Place(target) end)
        else
            Place(target)
        end
    end
    row:SetScript("OnEnter", function() row.hover = true; row:Sync() end)
    row:SetScript("OnLeave", function() row.hover = false; row:Sync() end)
    row:SetScript("OnClick", function()
        setValue(not getValue())
        row:Sync(true)
        ClickSound()
    end)
    row:Sync()
    return row, y - (pitch or 56)
end

-- A choice among a few, side by side in one track
function Kit.Segmented(parent, width, options, getValue, setValue)
    local seg = CreateFrame("Frame", nil, parent)
    seg:SetSize(width, 30)
    seg.track = PillIn(seg, 30, "BACKGROUND")
    seg.track:SetColor(1, 1, 1, 0.06)
    seg.buttons = {}
    local w = math.floor(width / #options)
    for i, opt in ipairs(options) do
        local b = CreateFrame("Button", nil, seg)
        b:SetSize(w, 30)
        b:SetPoint("LEFT", (i - 1) * w, 0)
        b.pill = PillIn(b, 30, "BORDER", 0, 3)
        b.label = Kit.Text(b, 11, C.textSoft, "CENTER")
        b.label:SetPoint("CENTER")
        b.label:SetText(opt.label)
        b.value = opt.value
        b:SetScript("OnEnter", function() b.hover = true; seg:Sync() end)
        b:SetScript("OnLeave", function() b.hover = false; seg:Sync() end)
        b:SetScript("OnClick", function()
            setValue(opt.value)
            seg:Sync()
            ClickSound()
        end)
        seg.buttons[i] = b
    end
    function seg:Sync()
        local cur = getValue()
        for _, b in ipairs(self.buttons) do
            local chosen = b.value == cur
            b.pill:SetColor(1, 1, 1, chosen and 0.16 or (b.hover and 0.05 or 0))
            Kit.Paint(b.label, chosen and C.text or C.textSoft)
        end
    end
    seg:Sync()
    return seg
end

-- ----------------------------------------------------------------------------
-- Progress
-- ----------------------------------------------------------------------------

-- A thin bar. bar:Set(fraction) at once, bar:Glide(fraction) filling smoothly.
function Kit.Bar(parent, width, height)
    height = height or 4
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(width, height)
    bar.track = PillIn(bar, height, "BACKGROUND")
    bar.track:SetColor(1, 1, 1, 0.09)
    bar.fill = CreateFrame("Frame", nil, bar)
    bar.fill:SetHeight(height)
    bar.fill:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.fill.pill = PillIn(bar.fill, height, "ARTWORK")
    bar.color = C.accent
    local function Apply(frac)
        bar.value = frac
        if frac <= 0 then bar.fill:Hide() return end
        bar.fill:Show()
        bar.fill:SetWidth(math.max(height, width * frac))
        bar.fill.pill:SetColor(bar.color[1], bar.color[2], bar.color[3], 1)
    end
    function bar:Set(frac, color)
        if self.anim then self.anim.cancelled = true; self.anim = nil end
        self.color = color or self.color
        self.target = Clamp(frac, 0, 1)
        Apply(self.target)
    end
    function bar:Glide(frac, color)
        frac = Clamp(frac, 0, 1)
        if self.value == nil then return self:Set(frac, color) end
        self.color = color or self.color
        if math.abs(frac - (self.target or self.value)) < 0.0005 then return end
        local from = self.value
        if frac < from then from = 0 end       -- a new level: it fills again from the start
        self.target = frac
        if self.anim then self.anim.cancelled = true end
        self.anim = Kit.Animate(0.4, function(p) Apply(from + (frac - from) * p) end, function() self.anim = nil; Apply(frac) end)
    end
    return bar
end

-- A ring of small dots that light up clockwise from the top: ring:Set(fraction)
function Kit.Ring(parent, radius, count, dotSize)
    local ring = CreateFrame("Frame", nil, parent)
    ring:SetSize(radius * 2, radius * 2)
    ring.dots = {}
    for i = 1, count do
        local angle = math.pi / 2 - 2 * math.pi * (i - 1) / count
        local dot = ring:CreateTexture(nil, "ARTWORK")
        dot:SetTexture(Icon("dot"))
        dot:SetSize(dotSize or 4, dotSize or 4)
        dot:SetPoint("CENTER", ring, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
        ring.dots[i] = dot
    end
    function ring:Set(frac, color, trackAlpha)
        frac = Clamp(frac, 0, 1)
        color = color or C.accent
        local lit = math.floor(frac * count + 0.5)
        if frac > 0 and lit < 1 then lit = 1 end
        if frac < 1 and lit >= count then lit = count - 1 end
        self.lit = lit
        for i, dot in ipairs(self.dots) do
            if i <= lit then
                dot:SetVertexColor(color[1], color[2], color[3], 1)
            else
                dot:SetVertexColor(1, 1, 1, trackAlpha or 0.10)
            end
        end
    end
    ring:Set(0)
    return ring
end

-- ----------------------------------------------------------------------------
-- A number that floats away from where something happened: Kit.Float(anchor, "+3")
-- direction 1 rises above the anchor, -1 sinks below it
-- ----------------------------------------------------------------------------
local floatHost, floatPool
function Kit.Float(anchor, text, color, direction, size)
    if not anchor then return end
    if not floatHost then
        floatHost = CreateFrame("Frame", nil, UIParent)
        floatHost:SetFrameStrata("TOOLTIP")
        floatHost:SetSize(1, 1)
        floatHost:SetPoint("CENTER")
        floatPool = {}
    end
    local fs = table.remove(floatPool)
    if not fs then
        fs = floatHost:CreateFontString(nil, "OVERLAY")
        fs:SetJustifyH("CENTER")
    end
    fs:SetFont(Kit.Font(), size or 14, "OUTLINE")
    color = color or C.accentBright
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetText(text)
    fs:Show()
    direction = direction or 1
    Kit.Animate(1.0, function(p)
        fs:ClearAllPoints()
        if direction > 0 then
            fs:SetPoint("BOTTOM", anchor, "TOP", 0, -6 + 26 * p)
        else
            fs:SetPoint("TOP", anchor, "BOTTOM", 0, -2 - 20 * p)
        end
        fs:SetAlpha(p < 0.6 and 1 or (1 - (p - 0.6) / 0.4))
    end, function()
        fs:Hide()
        floatPool[#floatPool + 1] = fs
    end)
    return fs
end

-- ----------------------------------------------------------------------------
-- The window: a quiet header, text tabs with a thin underline, one content area (no scrolling)
-- spec: name, width, height, title, logo, tabs = {{id, name}}, onSelect(id), closeTip()
-- ----------------------------------------------------------------------------
Kit.PAD = 28
Kit.HEADER_H = 56
Kit.TABS_H = 34

function Kit.Window(spec)
    local win = {tabs = {}, tabList = {}, spec = spec}
    local screenH = UIParent.GetHeight and UIParent:GetHeight()
    local height = math.floor(math.min(spec.height, (tonumber(screenH) or 768) - 40))
    local f = CreateFrame("Frame", spec.name, UIParent)
    f:SetSize(spec.width, height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnShow", function(self) Kit.FadeIn(self, 0.16) end)
    f:Hide()
    win.frame = f
    win.height = height

    Kit.Rounded(f, 14, C.bg[1], C.bg[2], C.bg[3], 0.95, 0.09)
    local shadow = CreateFrame("Frame", nil, f)
    shadow:SetPoint("TOPLEFT", f, "TOPLEFT", -20, 20)
    shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 20, -20)
    shadow:SetFrameLevel(math.max(0, (f:GetFrameLevel() or 1) - 1))
    shadow:EnableMouse(false)
    Kit.NineSlice(shadow, Icon("shadow"), 34, "BACKGROUND", -8):SetColor(0, 0, 0, 0.55)
    if UISpecialFrames and spec.name then table.insert(UISpecialFrames, spec.name) end

    -- header: the name on the left; whoever builds the window hangs what it wants on the right (win.header, win.close)
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(Kit.HEADER_H)
    header:SetPoint("TOPLEFT", Kit.PAD, 0)
    header:SetPoint("TOPRIGHT", -Kit.PAD, 0)
    win.header = header
    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(24, 24)
    logo:SetPoint("LEFT", 0, -4)
    logo:SetTexture(spec.logo)
    local title = Kit.Text(header, 17, C.text)
    title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
    title:SetText(spec.title or "")
    win.title = title

    local close = CreateFrame("Button", nil, header)
    close:SetSize(26, 26)
    close:SetPoint("RIGHT", 6, -4)
    close.bg = close:CreateTexture(nil, "BACKGROUND")
    close.bg:SetAllPoints()
    close.bg:SetTexture(Icon("dot"))
    close.bg:SetVertexColor(1, 1, 1, 0.06)
    close.lines = {}
    for i, rot in ipairs({45, -45}) do
        local l = close:CreateTexture(nil, "ARTWORK")
        l:SetSize(11, 1.5)
        l:SetPoint("CENTER")
        l:SetColorTexture(1, 1, 1, 1)
        l:SetVertexColor(C.textSoft[1], C.textSoft[2], C.textSoft[3])
        if l.SetRotation then l:SetRotation(math.rad(rot)) end
        close.lines[i] = l
    end
    close:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(1, 1, 1, 0.16)
        for _, l in ipairs(self.lines) do l:SetVertexColor(1, 1, 1) end
        if spec.closeTip and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:AddLine(spec.closeTip(), 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    close:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 0.06)
        for _, l in ipairs(self.lines) do l:SetVertexColor(C.textSoft[1], C.textSoft[2], C.textSoft[3]) end
        if GameTooltip then GameTooltip:Hide() end
    end)
    close:SetScript("OnClick", function() f:Hide() end)
    win.close = close

    -- tabs: words, the chosen one white with a short accent line under it
    local tabRow = CreateFrame("Frame", nil, f)
    tabRow:SetHeight(Kit.TABS_H)
    tabRow:SetPoint("TOPLEFT", Kit.PAD, -Kit.HEADER_H)
    tabRow:SetPoint("TOPRIGHT", -Kit.PAD, -Kit.HEADER_H)
    local rule = Kit.Hairline(tabRow, 0.07)
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    win.tabRow = tabRow

    local function PaintTab(tab)
        local active = win.current == tab.id
        Kit.Paint(tab.label, active and C.text or (tab.hover and C.text or C.textSoft))
        tab.line:SetShown(active)
    end
    local function Layout()
        local x = 0
        for _, tab in ipairs(win.tabList) do
            local w = Kit.TextWidth(tab.label, tab.label:GetText())
            tab:SetSize(w + 12, Kit.TABS_H)
            tab.line:SetWidth(w)
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", tabRow, "LEFT", x, 0)
            x = x + w + 12 + 16
        end
    end
    for i, t in ipairs(spec.tabs) do
        local tab = CreateFrame("Button", nil, tabRow)
        tab.id = t.id
        tab.label = Kit.Text(tab, 13, C.textSoft)
        tab.label:SetPoint("LEFT", 0, 0)
        tab.label:SetText(t.name)
        tab.line = tab:CreateTexture(nil, "ARTWORK")
        tab.line:SetHeight(2)
        tab.line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        tab.line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        tab.line:Hide()
        tab.dot = tab:CreateTexture(nil, "OVERLAY")
        tab.dot:SetTexture(Icon("dot"))
        tab.dot:SetSize(9, 9)
        tab.dot:SetPoint("LEFT", tab.label, "RIGHT", 3, 5)
        tab.dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        tab.dot:Hide()
        tab:SetScript("OnEnter", function(self) self.hover = true; PaintTab(self) end)
        tab:SetScript("OnLeave", function(self) self.hover = false; PaintTab(self) end)
        tab:SetScript("OnClick", function(self) win:Select(self.id); ClickSound() end)
        win.tabs[t.id] = tab
        win.tabList[i] = tab
    end
    Layout()

    -- a quiet line on the right of the tabs: what just happened, or why something could not be done. It fades by itself.
    local notice = Kit.Text(tabRow, 11, C.textSoft, "RIGHT")
    notice:SetPoint("RIGHT", 0, 0)
    notice:SetAlpha(0)
    win.notice = notice
    function win:Notice(text)
        if self.noticeAnim then self.noticeAnim.cancelled = true; self.noticeAnim = nil end
        if not text or text == "" then
            notice:SetText("")
            return
        end
        -- the room beside the path at the top (the window says it): a long line, like a character's, takes two lines
        -- and a smaller letter before it ever runs over the path
        local room = self.noticeRoom and self.noticeRoom()
        if room and room > 40 then
            notice:SetWidth(room)
            notice:SetWordWrap(true)
            Kit.Fit(notice, text, room * 2 - 24, 9)
        else
            notice:SetText(text)
        end
        self.noticeAnim = Kit.Animate(3.4, function(p)
            if p < 0.06 then notice:SetAlpha(p / 0.06)
            elseif p > 0.8 then notice:SetAlpha(1 - (p - 0.8) / 0.2)
            else notice:SetAlpha(1) end
        end, function() notice:SetAlpha(0); self.noticeAnim = nil end, true)
    end

    -- content
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", Kit.PAD, -(Kit.HEADER_H + Kit.TABS_H + 22))
    content:SetPoint("BOTTOMRIGHT", -Kit.PAD, 22)
    win.content = content
    win.contentWidth = spec.width - Kit.PAD * 2
    win.contentHeight = height - (Kit.HEADER_H + Kit.TABS_H + 22) - 22

    function win:Select(id)
        self.current = id
        for _, tab in ipairs(self.tabList) do PaintTab(tab) end
        if spec.onSelect then spec.onSelect(id) end
    end
    function win:SetTabLabels(list)
        for _, t in ipairs(list) do
            local tab = self.tabs[t.id]
            if tab then tab.label:SetText(t.name) end
        end
        Layout()
    end
    function win:SetTabDot(id, on)
        local tab = self.tabs[id]
        if tab then tab.dot:SetShown(on and true or false) end
    end
    return win
end
