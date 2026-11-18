local addonName, KH = ...
local UI = KH.UI
local P = UI.P
local Kit, C, D, V, T = P.Kit, P.C, P.D, P.V, P.T
local WIDTH, HEIGHT, WHITE, VDIR = P.WIDTH, P.HEIGHT, P.WHITE, P.VDIR
local Reason, Notice, Screen = P.Reason, P.Notice, P.Screen
local GoodTex, SetIcon = P.GoodTex, P.SetIcon
local Tier, BuildingArt, BuildingName, Tip = P.Tier, P.BuildingArt, P.BuildingName, P.Tip

local SPOT = {pond = {96, 147}, hall = {251, 147}, workshop = {409, 147}, mine = {567, 147},
    garden = {106, 265}, market = {255, 265}, inn = {410, 265}, barn = {562, 265}}
local VIEW_OF = {garden = "garden", hall = "hall", market = "orders", barn = "barn", mine = "mine", pond = "pond",
    workshop = "workshop", inn = "inn"}

-- where a click on a building takes: an empty lot is built in the Hall
local function Door(id)
    return KH.Village:Level(id) == 0 and "hall" or VIEW_OF[id]
end
local SPRITE = 92
local function BuildVillage(win)
    local s = Screen(win)
    local W = s.width
    local mapH = math.floor(W / 2)
    local map = CreateFrame("Frame", nil, s.frame)
    map:SetSize(W, mapH)
    map:SetPoint("TOPLEFT", 0, -66)
    map.art = map:CreateTexture(nil, "BACKGROUND")
    map.art:SetAllPoints(map)
    map.art:SetTexture(VDIR .. "map")
    s.map = map
    local scale = W / 664

    s.spots = {}
    for _, id in ipairs(V.BUILDINGS) do
        local b = CreateFrame("Button", nil, map)
        b.id = id
        b:SetSize(SPRITE, SPRITE + 36)
        b:SetPoint("TOPLEFT", map, "TOPLEFT", SPOT[id][1] * scale - SPRITE / 2, -(SPOT[id][2] * scale - SPRITE * 0.844))
        b.glow = b:CreateTexture(nil, "BACKGROUND")
        b.glow:SetTexture(Kit.Icon("glow"))
        b.glow:SetSize(SPRITE * 1.5, SPRITE * 1.5)
        b.glow:SetPoint("CENTER", b, "TOP", 0, -SPRITE * 0.6)
        b.glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
        if b.glow.SetBlendMode then b.glow:SetBlendMode("ADD") end
        b.glow:SetAlpha(0)
        b.art = b:CreateTexture(nil, "ARTWORK")
        b.art:SetSize(SPRITE, SPRITE)
        b.art:SetPoint("TOP", 0, 0)
        b.works = b:CreateTexture(nil, "OVERLAY")
        b.works:SetSize(SPRITE, SPRITE)
        b.works:SetPoint("TOP", 0, 0)
        b.works:SetTexture(VDIR .. "works")
        b.works:Hide()
        -- the plate under the building: its name and level, and what waits there
        b.plate = CreateFrame("Frame", nil, b)
        b.plate:SetSize(112, 34)
        b.plate:SetPoint("TOP", b, "TOP", 0, -(SPRITE - 6))
        b.plate.surface, b.plate.outline = Kit.Rounded(b.plate, 10, 0.03, 0.05, 0.06, 0.78, 0.08)
        b.name = Kit.Text(b.plate, 11, C.text, "CENTER")
        b.name:SetPoint("TOP", 0, -5)
        b.name:SetWidth(108)
        b.name:SetWordWrap(false)
        b.note = Kit.Text(b.plate, 9, C.textSoft, "CENTER")
        b.note:SetPoint("TOP", 0, -19)
        b.note:SetWidth(108)
        b.note:SetWordWrap(false)
        b:SetScript("OnEnter", function(self) self.hover = true; s.hover = self.id; s:Paint() end)
        b:SetScript("OnLeave", function(self) self.hover = false; s.hover = nil; s:Paint() end)
        b:SetScript("OnClick", function(self) Kit.ClickSound(); UI:Show(Door(self.id)) end)
        s.spots[id] = b
    end

    -- the visitors' cart: on the grass by the Hall, under the trees, while someone came (Events.lua); a click opens
    -- Visitors. It glows, sends out a ring and hops, so it is seen at once
    local CART = 90
    local cart = CreateFrame("Button", nil, map)
    cart:SetSize(CART, CART)
    cart:SetPoint("TOPLEFT", map, "TOPLEFT", 228 * scale - CART / 2, -(78 * scale - CART * 0.844))
    cart:SetFrameLevel(map:GetFrameLevel() + 20)
    cart.glow = cart:CreateTexture(nil, "BACKGROUND")
    cart.glow:SetTexture(Kit.Icon("glow"))
    cart.glow:SetSize(CART * 1.6, CART * 1.6)
    cart.glow:SetPoint("CENTER", 0, -CART * 0.15)
    cart.glow:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    if cart.glow.SetBlendMode then cart.glow:SetBlendMode("ADD") end
    cart.ring = cart:CreateTexture(nil, "BACKGROUND")
    cart.ring:SetTexture(Kit.Icon("glow"))
    cart.ring:SetPoint("CENTER", 0, -CART * 0.15)
    cart.ring:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
    if cart.ring.SetBlendMode then cart.ring:SetBlendMode("ADD") end
    cart.art = cart:CreateTexture(nil, "ARTWORK")
    cart.art:SetSize(CART, CART)
    cart.art:SetPoint("TOPLEFT", 0, 0)
    cart.art:SetTexture(VDIR .. "cart")
    cart.badge = Kit.Text(cart, 11, C.onAccent, "CENTER")
    cart.disc = cart:CreateTexture(nil, "OVERLAY")
    cart.disc:SetTexture(Kit.Icon("dot"))
    cart.disc:SetSize(20, 20)
    cart.disc:SetPoint("TOPRIGHT", -14, -18)
    cart.disc:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 1)
    cart.badge:SetPoint("CENTER", cart.disc, "CENTER", 0, 0)
    cart.badge:SetDrawLayer("OVERLAY", 7)
    cart:SetScript("OnEnter", function(self)
        self.hover = true
        Tip(self, T("visitorsTab"), {T("cartTip")})
    end)
    cart:SetScript("OnLeave", function(self) self.hover = false; if GameTooltip then GameTooltip:Hide() end end)
    cart:SetScript("OnClick", function() Kit.ClickSound(); UI:Show("visitors") end)
    cart:Hide()
    s.cart = cart

    s.primary = Kit.Button(s.frame, 220, 36, "", function() s:Primary() end)
    s.primary:SetPoint("BOTTOMRIGHT", 0, 0)
    s.primary:SetStyle("primary")
    s.detail = Kit.Text(s.frame, 11, C.textSoft)
    s.detail:SetPoint("BOTTOMLEFT", 0, 12)
    s.detail:SetWidth(W - 240)
    s.detail:SetWordWrap(false)

    -- what waits for the player breathes softly; the building under the mouse lights up
    s.clock = 0
    s.frame:SetScript("OnUpdate", function(_, elapsed)
        s.clock = s.clock + (tonumber(elapsed) or 0)
        local wave = 0.5 + 0.5 * math.sin(s.clock * 3)
        local cart = s.cart
        cart.glow:SetAlpha(cart.hover and 0.9 or (0.45 + 0.4 * wave))
        local ring = (s.clock * 0.7) % 1                                -- a ring that grows and fades, over and over
        cart.ring:SetSize(CART * (1 + 1.2 * ring), CART * (1 + 1.2 * ring))
        cart.ring:SetAlpha(cart.hover and 0 or 0.7 * (1 - ring))
        local hop = math.abs(math.sin(s.clock * 2.6))                   -- a small hop of the cart
        cart.art:SetPoint("TOPLEFT", 0, cart.hover and 0 or math.floor(hop * 4 + 0.5))
        for _, b in pairs(s.spots) do
            if b.hover then
                b.glow:SetAlpha(0.42)
            elseif b.calls then
                b.glow:SetAlpha(0.12 + 0.22 * wave)
            else
                b.glow:SetAlpha(0)
            end
        end
    end)

    function s:Paint()
        for _, b in pairs(self.spots) do
            b.plate.outline:SetColor(b.hover and C.accent[1] or 1, b.hover and C.accent[2] or 1, b.hover and C.accent[3] or 1,
                b.hover and 0.8 or (b.calls and 0.22 or 0.08))
        end
        if self.hover then
            self.detail:SetText(WHITE .. BuildingName(self.hover) .. "|r   " .. T("b_" .. self.hover .. "D"))
        else
            self.detail:SetText(self.idle or "")
        end
    end

    function s:Primary()
        if self.mode == "harvest" then
            local n, why = KH.Farm:HarvestAll()
            if n > 0 then
                Kit.Float(self.spots.garden.art, "+" .. n, C.accentBright, 1, 16)
                Notice(T("harvestedN", n))
            elseif why then
                Notice(Reason(why))
            end
            UI:Refresh()
        else
            UI:Show(self.mode or "garden")
        end
    end

    function s:Refresh()
        local db = KH.db
        local visitors = #KH.Events:Open()
        self.cart:SetShown(visitors > 0)
        self.cart.badge:SetText(tostring(visitors))
        local step = UI:Step()
        local ready, growing, empty, soonest = 0, 0, 0, nil
        for i = 1, db.nplots do
            local status, _, left = KH.Farm:Status(i)
            if status == "ready" then ready = ready + 1
            elseif status == "growing" then
                growing = growing + 1
                if not soonest or left < soonest then soonest = left end
            else empty = empty + 1 end
        end
        local deliverable = 0
        for i = 1, D.ORDER_SLOTS do
            if KH.Orders:CanDeliver(i) then deliverable = deliverable + 1 end
        end
        if KH.Daily:CanDeliver() then deliverable = deliverable + 1 end
        local work, left = V:Work()
        local affordable = V:Affordable()
        local cap, fill = V:BarnCap(), V:Fill()

        for _, id in ipairs(V.BUILDINGS) do
            local b = self.spots[id]
            b.art:SetTexture(BuildingArt(id))
            b.works:SetShown(work ~= nil and work.id == id)
            local level = V:Level(id)
            b.name:SetText(level == 0 and BuildingName(id) or T("nameLevel", BuildingName(id), level))
            local note, calls = "", false
            if work and work.id == id then
                note = T("building", KH.Duration(left))
            elseif level == 0 then
                local ok, why, n = V:CanUpgrade(id)
                if ok then note, calls = T("canBuild"), not step
                elseif why == "hall" then note = T("short_hall", n)
                elseif why == "village" then note = T("short_village", n)
                else note = T("emptyLot") end
            elseif V.MAKES[id] then
                local good = V.MAKES[id]
                local have = V:Good(good)
                note, calls = T("goodStored", have, cap, T("good_" .. good)), have >= cap
            elseif id == "workshop" then
                local jobs = KH.Workshop:Jobs()
                if #jobs > 0 then note = T("shopPlate", #jobs, KH.Duration(jobs[1].left)) else note = T("shopIdle") end
            elseif id == "inn" then
                local back, away = KH.Inn:BackCount(), KH.Inn:AwayCount()
                if back > 0 then note, calls = T(back == 1 and "backOne" or "backMany", back), true
                elseif away > 0 then note = T("awayMany", away)
                else note = T("followersIdle", KH.Inn:Count()) end
            elseif id == "garden" then
                if ready > 0 then note, calls = T(ready == 1 and "readyOne" or "readyMany", ready), true
                elseif empty > 0 then note, calls = T(empty == 1 and "emptyOne" or "emptyMany", empty), step == "plant"
                else note = T("timeLeft", KH.Duration(soonest or 0)) end
            elseif id == "barn" then
                note, calls = T("barnFill", math.floor(fill * 100 + 0.5)), step == "sell" or fill >= 1
            elseif id == "market" then
                if deliverable > 0 then note, calls = T(deliverable == 1 and "deliverOne" or "deliverMany", deliverable), true
                else note = T("ordersWaiting", D.ORDER_SLOTS) end
            elseif id == "hall" then
                if affordable and not step then note, calls = T("canUpgrade"), true else note = T("buildHere") end
            end
            b.calls = calls
            b.note:SetText(note)
            Kit.Paint(b.note, calls and C.accent or C.textSoft)
        end

        -- the two sentences, and the one button
        self.mode = "garden"
        local label = T("openGarden")
        if step == "plant" then
            self.head:SetText(T("vilPlantH")); self.sub:SetText(T("vilPlantS"))
        elseif step == "wait" then
            self.head:SetText(T("tutWaitH")); self.sub:SetText(T("tutWaitS", KH.Duration(soonest or 0)))
        elseif step == "harvest" then
            self.head:SetText(T("tutHarvestH")); self.sub:SetText(T("vilHarvestS"))
            self.mode, label = "harvest", T("harvestAll")
        elseif step == "sell" then
            self.head:SetText(T("tutSellH")); self.sub:SetText(T("vilSellS"))
            self.mode, label = "barn", T("openBarn")
        elseif ready > 0 then
            self.head:SetText(ready == 1 and T("headReadyOne") or T("headReadyMany", ready))
            self.sub:SetText(T("vilReadyS"))
            self.mode, label = "harvest", T("harvestAll")
        elseif deliverable > 0 then
            self.head:SetText(T(deliverable == 1 and "vilDeliverOneH" or "vilDeliverH", deliverable))
            self.sub:SetText(T("vilDeliverS"))
            self.mode, label = "orders", T("openMarket")
        elseif affordable then
            self.head:SetText(T(V:Level(affordable) == 0 and "vilBuildH" or "vilUpgradeH", BuildingName(affordable)))
            self.sub:SetText(T("vilUpgradeS"))
            self.mode, label = "hall", T("openHall")
        elseif empty > 0 then
            self.head:SetText(T("headEmpty"))
            self.sub:SetText(T("vilEmptyS"))
        else
            self.head:SetText(T("vilQuietH"))
            self.sub:SetText(T("subGrowing", KH.Duration(soonest or 0)))
        end
        self.primary:SetLabel(label)
        self.primary:SetEnabledState(true)

        if work then
            self.idle = T("workLine", BuildingName(work.id), V:Level(work.id) + 1, KH.Duration(left))
        else
            self.idle = T("vilTip")
        end
        self:Paint()
    end
    return s
end

-- ----------------------------------------------------------------------------
-- The Hall: where every building of the village is improved, one work at a time
-- ----------------------------------------------------------------------------

P.builders.village = BuildVillage
