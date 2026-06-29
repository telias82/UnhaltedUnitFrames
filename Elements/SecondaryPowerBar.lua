local _, UUF = ...

local UpdateSecondaryPowerBarEventFrame = CreateFrame("Frame")
-- TRAIT_CONFIG_UPDATED is retail-only; removed for MoP Classic
UpdateSecondaryPowerBarEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
UpdateSecondaryPowerBarEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
UpdateSecondaryPowerBarEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
UpdateSecondaryPowerBarEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit ~= "player" then return end
    end
    -- C_Timer not available in MoP Classic; defer one frame instead
    local deferred = CreateFrame("Frame")
    deferred:SetScript("OnUpdate", function(f)
        f:SetScript("OnUpdate", nil)
        if UUF.PLAYER then
            UUF:UpdateUnitSecondaryPowerBar(UUF.PLAYER, "player")
        end
    end)
end)

function UUF:IsRunePower()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT"
end

function UUF:LayoutSecondaryPowerBar(unitFrame, unit)
    local FrameDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Frame
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    local isRunes = UUF:IsRunePower()
    local el = isRunes and unitFrame.Runes or unitFrame.ClassPower
    if not el or #el == 0 then return end

    local maxPower = #el
    local totalWidth = (DB.Detached and DB.DetachedWidth) or (FrameDB.Width - 2)

    if DB.Detached then
        if not unitFrame.SecondaryPowerHolder then
            local holder = CreateFrame("Frame", UUF:FetchFrameName(unit) .. "_SecondaryPowerBarHolder", UIParent)
            holder:SetFrameStrata("MEDIUM")
            holder:SetMovable(true)
            holder:EnableMouse(false)
            holder:SetClampedToScreen(true)
            holder:RegisterForDrag("LeftButton")
            holder:SetScript("OnDragStart", function(h) h:StartMoving() end)
            holder:SetScript("OnDragStop", function(h)
                h:StopMovingOrSizing()
                local hx, hy = h:GetCenter()
                local cx, cy = UIParent:GetCenter()
                DB.DetachedX = hx - cx
                DB.DetachedY = hy - cy
            end)
            unitFrame.SecondaryPowerHolder = holder
        end
        local holder = unitFrame.SecondaryPowerHolder

        holder:SetSize(totalWidth, DB.Height)
        holder:ClearAllPoints()
        holder:SetPoint("CENTER", UIParent, "CENTER", DB.DetachedX or 0, DB.DetachedY or 200)
        holder:Show()

        -- ContainerBackground is a texture (can't re-parent), re-anchor it to the holder
        el.ContainerBackground:ClearAllPoints()
        el.ContainerBackground:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
        el.ContainerBackground:SetSize(totalWidth, DB.Height)

        -- OverlayFrame: re-parent and resize to holder
        el.OverlayFrame:SetParent(holder)
        el.OverlayFrame:SetAllPoints(holder)
        el.OverlayFrame:SetFrameLevel(holder:GetFrameLevel() + 5)

        -- Layout bars in screen-pixel space to avoid UIScale-induced alternating widths.
        -- Float division + UIScale rounding produces alternating bar widths; integer screen
        -- pixels distributed with barDivide then converted back to game coords avoids this.
        local scale    = holder:GetEffectiveScale()
        local totalPx  = math.floor(totalWidth * scale + 0.5)
        local pxBase   = math.floor(totalPx / maxPower)
        local pxExtra  = totalPx % maxPower

        for i = 1, maxPower do
            local xStartPx = (i - 1) * pxBase + math.min(i - 1, pxExtra)
            local xEndPx   = xStartPx + pxBase + (i <= pxExtra and 1 or 0)
            local bar = el[i]
            bar:SetParent(holder)
            bar:SetFrameLevel(holder:GetFrameLevel() + 1)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT",     holder, "TOPLEFT", xStartPx / scale,  0)
            bar:SetPoint("BOTTOMRIGHT", holder, "TOPLEFT", xEndPx   / scale, -DB.Height)
        end

        for i = 1, maxPower - 1 do
            local xTickPx = i * pxBase + math.min(i, pxExtra)
            local tick = el.Ticks[i]
            tick:ClearAllPoints()
            tick:SetPoint("TOPLEFT", holder, "TOPLEFT", xTickPx / scale, 0)
            tick:SetSize(1, DB.Height)
        end
        if el.LeftBorder then
            el.LeftBorder:ClearAllPoints()
            el.LeftBorder:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
            el.LeftBorder:SetSize(1, DB.Height)
        end
        if el.RightBorder then
            el.RightBorder:ClearAllPoints()
            el.RightBorder:SetPoint("TOPLEFT", holder, "TOPLEFT", totalPx / scale, 0)
            el.RightBorder:SetSize(1, DB.Height)
        end

        -- PowerBarBorder: place along the bottom edge of the holder
        el.PowerBarBorder:ClearAllPoints()
        el.PowerBarBorder:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, 0)
        el.PowerBarBorder:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", 0, 0)
        el.PowerBarBorder:SetHeight(1)

        -- TagFrame: cover the holder
        if el.TagFrame then
            el.TagFrame:SetParent(holder)
            el.TagFrame:ClearAllPoints()
            el.TagFrame:SetAllPoints(holder)
            el.TagFrame:SetFrameLevel(holder:GetFrameLevel() + 6)
        end
    else
        if unitFrame.SecondaryPowerHolder then
            unitFrame.SecondaryPowerHolder:Hide()
        end

        -- OverlayFrame: re-parent back to container
        el.OverlayFrame:SetParent(unitFrame.Container)
        el.OverlayFrame:SetAllPoints(unitFrame.Container)
        el.OverlayFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 10)

        -- ContainerBackground: re-anchor to container
        el.ContainerBackground:ClearAllPoints()
        el.ContainerBackground:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, -1)
        el.ContainerBackground:SetSize(totalWidth, DB.Height)

        -- Screen-pixel layout (same approach as DETACHED) to avoid UIScale alternating widths
        local scale    = unitFrame.Container:GetEffectiveScale()
        local totalPx  = math.floor(totalWidth * scale + 0.5)
        local pxBase   = math.floor(totalPx / maxPower)
        local pxExtra  = totalPx % maxPower

        for i = 1, maxPower do
            local xStartPx = (i - 1) * pxBase + math.min(i - 1, pxExtra)
            local xEndPx   = xStartPx + pxBase + (i <= pxExtra and 1 or 0)
            local bar = el[i]
            bar:SetParent(unitFrame.Container)
            bar:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 1)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT",     unitFrame.Container, "TOPLEFT", 1 + xStartPx / scale, -1)
            bar:SetPoint("BOTTOMRIGHT", unitFrame.Container, "TOPLEFT", 1 + xEndPx   / scale, -1 - DB.Height)
        end

        for i = 1, maxPower - 1 do
            local xTickPx = i * pxBase + math.min(i, pxExtra)
            local tick = el.Ticks[i]
            tick:ClearAllPoints()
            tick:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1 + xTickPx / scale, -1)
            tick:SetSize(1, DB.Height)
        end
        if el.LeftBorder then
            el.LeftBorder:ClearAllPoints()
            el.LeftBorder:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, -1)
            el.LeftBorder:SetSize(1, DB.Height)
        end
        if el.RightBorder then
            el.RightBorder:ClearAllPoints()
            el.RightBorder:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1 + totalPx / scale, -1)
            el.RightBorder:SetSize(1, DB.Height)
        end

        -- PowerBarBorder: restore container-relative position
        el.PowerBarBorder:ClearAllPoints()
        el.PowerBarBorder:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, -1 - DB.Height)
        el.PowerBarBorder:SetPoint("TOPRIGHT", unitFrame.Container, "TOPLEFT", 1 + totalWidth, -1 - DB.Height)
        el.PowerBarBorder:SetHeight(1)

        -- TagFrame: cover the bar area within the container
        if el.TagFrame then
            el.TagFrame:SetParent(unitFrame.Container)
            el.TagFrame:ClearAllPoints()
            el.TagFrame:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, -1)
            el.TagFrame:SetSize(totalWidth, DB.Height)
            el.TagFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 11)
        end
    end
end

function UUF:CreateUnitSecondaryPowerBar(unitFrame, unit)
    local FrameDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Frame
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    local unitFrameContainer = unitFrame.Container

    if not DB.Enabled then return end

    local powerType = UUF:GetSecondaryPowerType()
    if not powerType and not UUF:IsRunePower() then return end

    local secondaryPowerElement = {}
    secondaryPowerElement.Ticks = {}

    local maxPower = UUF:IsRunePower() and 6 or (UnitPowerMax("player", powerType) or 6)
    local totalWidth = (DB.Detached and DB.DetachedWidth) or (FrameDB.Width - 2)
    local unitFrameWidth = totalWidth / maxPower

    secondaryPowerElement.ContainerBackground = unitFrameContainer:CreateTexture(nil, "BACKGROUND")
    secondaryPowerElement.ContainerBackground:SetTexture(UUF.Media.Background)

    for i = 1, maxPower do
        local secondaryPowerBar = CreateFrame("StatusBar", nil, unitFrameContainer)
        secondaryPowerBar:SetStatusBarTexture(UUF.Media.Foreground)
        secondaryPowerBar:SetMinMaxValues(0, 1)
        secondaryPowerBar.frequentUpdates = DB.Smooth
        secondaryPowerBar:Hide()

        secondaryPowerBar.Background = secondaryPowerBar:CreateTexture(nil, "BACKGROUND")
        secondaryPowerBar.Background:SetAllPoints(secondaryPowerBar)
        secondaryPowerBar.Background:SetTexture(UUF.Media.Background)

        secondaryPowerElement[i] = secondaryPowerBar
    end

    secondaryPowerElement.OverlayFrame = CreateFrame("Frame", nil, unitFrameContainer)
    secondaryPowerElement.OverlayFrame:SetFrameLevel(unitFrameContainer:GetFrameLevel() + 10)

    for i = 1, maxPower - 1 do
        local secondaryPowerBarTick = secondaryPowerElement.OverlayFrame:CreateTexture(nil, "OVERLAY")
        secondaryPowerBarTick:SetTexture("Interface\\Buttons\\WHITE8x8")
        secondaryPowerBarTick:SetDrawLayer("OVERLAY", 7)
        secondaryPowerElement.Ticks[i] = secondaryPowerBarTick
    end

    secondaryPowerElement.PowerBarBorder = secondaryPowerElement.OverlayFrame:CreateTexture(nil, "OVERLAY")
    secondaryPowerElement.PowerBarBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    secondaryPowerElement.PowerBarBorder:SetDrawLayer("OVERLAY", 6)

    secondaryPowerElement.LeftBorder = secondaryPowerElement.OverlayFrame:CreateTexture(nil, "OVERLAY")
    secondaryPowerElement.LeftBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    secondaryPowerElement.LeftBorder:SetDrawLayer("OVERLAY", 7)

    secondaryPowerElement.RightBorder = secondaryPowerElement.OverlayFrame:CreateTexture(nil, "OVERLAY")
    secondaryPowerElement.RightBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    secondaryPowerElement.RightBorder:SetDrawLayer("OVERLAY", 7)

    secondaryPowerElement.PostUpdateColor = function(self)
        if DB.ColourByType then return end
        for i = 1, #self do
            self[i]:SetStatusBarColor(DB.Foreground[1], DB.Foreground[2], DB.Foreground[3], DB.Foreground[4] or 1)
        end
    end

    secondaryPowerElement.TagFrame = CreateFrame("Frame", nil, unitFrameContainer)
    secondaryPowerElement.TagFrame:SetFrameLevel(unitFrameContainer:GetFrameLevel() + 11)

    if UUF:IsRunePower() then
        secondaryPowerElement.sortOrder = "asc"
        secondaryPowerElement.colorSpec = DB.ColourByType
        unitFrame.Runes = secondaryPowerElement
    else
        unitFrame.ClassPower = secondaryPowerElement
    end

    UUF:CreateUnitSecondaryPowerBarTags(unitFrame, unit)

    return secondaryPowerElement
end

function UUF:CreateUnitSecondaryPowerBarTags(unitFrame, unit)
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    local GeneralDB = UUF.db.profile.General
    local isRunes = UUF:IsRunePower()
    local el = isRunes and unitFrame.Runes or unitFrame.ClassPower
    if not el or not el.TagFrame or not DB.PowerBarTags then return end

    el.TagFrame.PowerBarTags = el.TagFrame.PowerBarTags or {}
    for tagName, tagData in pairs(DB.PowerBarTags) do
        if not el.TagFrame.PowerBarTags[tagName] then
            local fs = el.TagFrame:CreateFontString(nil, "OVERLAY")
            fs:SetFont(UUF.Media.Font, tagData.FontSize, UUF.Media.FontFlag)
            fs:SetVertexColor(tagData.Colour[1], tagData.Colour[2], tagData.Colour[3], 1)
            if GeneralDB.Fonts.Shadow.Enabled then
                fs:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                fs:SetShadowOffset(GeneralDB.Fonts.Shadow.XPos, GeneralDB.Fonts.Shadow.YPos)
            else
                fs:SetShadowColor(0, 0, 0, 0)
                fs:SetShadowOffset(0, 0)
            end
            fs:SetPoint(tagData.Layout[1], el.TagFrame, tagData.Layout[2], tagData.Layout[3], tagData.Layout[4])
            fs:SetJustifyH(UUF:SetJustification(tagData.Layout[1]))
            unitFrame:Tag(fs, tagData.Tag)
            el.TagFrame.PowerBarTags[tagName] = fs
        end
    end
end

function UUF:UpdateUnitSecondaryPowerBarTag(unitFrame, unit, tagDB)
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    local GeneralDB = UUF.db.profile.General
    local isRunes = UUF:IsRunePower()
    local el = isRunes and unitFrame.Runes or unitFrame.ClassPower
    if not el or not el.TagFrame or not el.TagFrame.PowerBarTags then return end

    local tagData = DB.PowerBarTags[tagDB]
    local fs = el.TagFrame.PowerBarTags[tagDB]
    if not tagData or not fs then return end

    fs:SetFont(UUF.Media.Font, tagData.FontSize, UUF.Media.FontFlag)
    fs:SetVertexColor(tagData.Colour[1], tagData.Colour[2], tagData.Colour[3], 1)
    if GeneralDB.Fonts.Shadow.Enabled then
        fs:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        fs:SetShadowOffset(GeneralDB.Fonts.Shadow.XPos, GeneralDB.Fonts.Shadow.YPos)
    else
        fs:SetShadowColor(0, 0, 0, 0)
        fs:SetShadowOffset(0, 0)
    end
    fs:ClearAllPoints()
    fs:SetPoint(tagData.Layout[1], el.TagFrame, tagData.Layout[2], tagData.Layout[3], tagData.Layout[4])
    fs:SetJustifyH(UUF:SetJustification(tagData.Layout[1]))
    unitFrame:Tag(fs, tagData.Tag)
    fs:UpdateTag()
end

function UUF:UpdateUnitSecondaryPowerBarTags(unitFrame, unit)
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    if not DB.PowerBarTags then return end
    for tagName in pairs(DB.PowerBarTags) do
        UUF:UpdateUnitSecondaryPowerBarTag(unitFrame, unit, tagName)
    end
end

function UUF:UpdateUnitSecondaryPowerBar(unitFrame, unit)
    if not unitFrame then return end

    local FrameDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Frame
    local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].SecondaryPowerBar
    local isRunes = UUF:IsRunePower()
    local secondaryPowerBarElementName = isRunes and "Runes" or "ClassPower"

    local powerType = UUF:GetSecondaryPowerType()
    if not DB.Enabled or (not powerType and not isRunes) then
        if unitFrame[secondaryPowerBarElementName] then
            if unitFrame:IsElementEnabled(secondaryPowerBarElementName) then
                unitFrame:DisableElement(secondaryPowerBarElementName)
            end
            local secondaryPowerBarElement = unitFrame[secondaryPowerBarElementName]
            for i = 1, #secondaryPowerBarElement do secondaryPowerBarElement[i]:Hide() end
            for i = 1, #secondaryPowerBarElement.Ticks do secondaryPowerBarElement.Ticks[i]:Hide() end
            if secondaryPowerBarElement.ContainerBackground then secondaryPowerBarElement.ContainerBackground:Hide() end
            if secondaryPowerBarElement.PowerBarBorder then secondaryPowerBarElement.PowerBarBorder:Hide() end
            if secondaryPowerBarElement.OverlayFrame then secondaryPowerBarElement.OverlayFrame:Hide() end
            if unitFrame.SecondaryPowerHolder then unitFrame.SecondaryPowerHolder:Hide() end
            unitFrame[secondaryPowerBarElementName] = nil
        end
        UUF:UpdateHealthBarLayout(unitFrame, unit)
        return
    end

    local currentMaxPower = isRunes and 6 or (UnitPowerMax("player", powerType) or 6)
    local secondaryPowerBarElement = unitFrame[secondaryPowerBarElementName]

    if not secondaryPowerBarElement or #secondaryPowerBarElement ~= currentMaxPower then
        if secondaryPowerBarElement and unitFrame:IsElementEnabled(secondaryPowerBarElementName) then
            unitFrame:DisableElement(secondaryPowerBarElementName)
        end
        unitFrame[secondaryPowerBarElementName] = UUF:CreateUnitSecondaryPowerBar(unitFrame, unit)
        secondaryPowerBarElement = unitFrame[secondaryPowerBarElementName]
        if not secondaryPowerBarElement then return end
        unitFrame:EnableElement(secondaryPowerBarElementName)
    end

    secondaryPowerBarElement.ContainerBackground:SetVertexColor(DB.Background[1], DB.Background[2], DB.Background[3], DB.Background[4] or 1)
    secondaryPowerBarElement.ContainerBackground:Show()

    secondaryPowerBarElement.OverlayFrame:Show()

    secondaryPowerBarElement.PowerBarBorder:SetVertexColor(0, 0, 0, 1)
    secondaryPowerBarElement.PowerBarBorder:Show()

    if secondaryPowerBarElement.LeftBorder then
        secondaryPowerBarElement.LeftBorder:SetVertexColor(0, 0, 0, 1)
        secondaryPowerBarElement.LeftBorder:Show()
    end
    if secondaryPowerBarElement.RightBorder then
        secondaryPowerBarElement.RightBorder:SetVertexColor(0, 0, 0, 1)
        secondaryPowerBarElement.RightBorder:Show()
    end

    for i = 1, currentMaxPower do
        local bar = secondaryPowerBarElement[i]
        bar.Background:SetVertexColor(DB.Background[1], DB.Background[2], DB.Background[3], DB.Background[4] or 1)
        bar:Show()
    end

    for i = 1, currentMaxPower - 1 do
        secondaryPowerBarElement.Ticks[i]:SetVertexColor(0, 0, 0, 1)
        secondaryPowerBarElement.Ticks[i]:Show()
    end

    for i = currentMaxPower, #secondaryPowerBarElement.Ticks do
        secondaryPowerBarElement.Ticks[i]:Hide()
    end

    if isRunes then
        secondaryPowerBarElement.colorSpec = DB.ColourByType
    end

    if secondaryPowerBarElement.PostUpdateColor then
        secondaryPowerBarElement:PostUpdateColor()
    end

    UUF:LayoutSecondaryPowerBar(unitFrame, unit)
    UUF:UpdateUnitSecondaryPowerBarTags(unitFrame, unit)
    UUF:UpdateHealthBarLayout(unitFrame, unit)
    secondaryPowerBarElement:ForceUpdate()
end
