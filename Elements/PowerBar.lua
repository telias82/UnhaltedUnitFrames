local _, UUF = ...

local INTERP_SMOOTH    = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut or 0
local INTERP_IMMEDIATE = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate        or 0

local nudgeHolder, nudgeDB, nudgeRefreshFn

-- ── Mover UI ──────────────────────────────────────────────────────────────────

local moverUI = CreateFrame("Frame", "UUFMoverUI", UIParent, "BackdropTemplate")
moverUI:SetSize(180, 178)
moverUI:SetFrameStrata("DIALOG")
moverUI:SetFrameLevel(100)
moverUI:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
moverUI:SetMovable(true)
moverUI:EnableMouse(true)
moverUI:RegisterForDrag("LeftButton")
moverUI:SetScript("OnDragStart", function(f) f:StartMoving() end)
moverUI:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
moverUI:SetClampedToScreen(true)
moverUI:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
moverUI:SetBackdropColor(0, 0, 0, 0.88)
moverUI:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
moverUI:Hide()

-- Title
local moverTitle = moverUI:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moverTitle:SetPoint("TOP", moverUI, "TOP", 0, -7)
moverTitle:SetTextColor(1, 0.82, 0)
moverUI._title = moverTitle

-- Separator
local sep = moverUI:CreateTexture(nil, "ARTWORK")
sep:SetHeight(1)
sep:SetPoint("TOPLEFT",  moverUI, "TOPLEFT",  4, -20)
sep:SetPoint("TOPRIGHT", moverUI, "TOPRIGHT", -4, -20)
sep:SetColorTexture(0.4, 0.4, 0.4, 0.8)

local updateCoordBoxes  -- defined below once coord boxes exist

-- Live coord display, throttled to 20 Hz
local coordThrottle = 0
moverUI:SetScript("OnUpdate", function(self, elapsed)
    coordThrottle = coordThrottle + elapsed
    if coordThrottle < 0.05 then return end
    coordThrottle = 0
    if updateCoordBoxes then updateCoordBoxes() end
end)

local function applyNudge(dx, dy)
    if not nudgeHolder or not nudgeDB then return end
    nudgeDB.DetachedX = (nudgeDB.DetachedX or 0) + dx
    nudgeDB.DetachedY = (nudgeDB.DetachedY or 0) + dy
    nudgeHolder:ClearAllPoints()
    nudgeHolder:SetPoint("CENTER", UIParent, "CENTER", nudgeDB.DetachedX, nudgeDB.DetachedY)
end

local function commitCoords(xStr, yStr)
    if not nudgeHolder or not nudgeDB then return end
    local x = tonumber(xStr)
    local y = tonumber(yStr)
    if x then nudgeDB.DetachedX = x end
    if y then nudgeDB.DetachedY = y end
    nudgeHolder:ClearAllPoints()
    nudgeHolder:SetPoint("CENTER", UIParent, "CENTER", nudgeDB.DetachedX or 0, nudgeDB.DetachedY or 0)
end

local function makeCoordBox(parent)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetAutoFocus(false)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetJustifyH("CENTER")
    eb:SetSize(58, 16)
    eb:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, tileSize = 5, edgeSize = 1,
    })
    eb:SetBackdropColor(0, 0, 0, 0.5)
    eb:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    eb:SetScript("OnEscapePressed", function(f) f:ClearFocus() end)
    eb:SetScript("OnEnterPressed",  function(f)
        f:ClearFocus()
        commitCoords(moverUI._xBox:GetText(), moverUI._yBox:GetText())
    end)
    return eb
end

-- X row: label + edit box
local xLbl = moverUI:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
xLbl:SetText("X:")
xLbl:SetTextColor(1, 0.82, 0)
xLbl:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 6, -8)

local xBox = makeCoordBox(moverUI)
xBox:SetPoint("LEFT", xLbl, "RIGHT", 4, 0)
xBox:SetPoint("TOP",  xLbl, "TOP", 0, 0)
moverUI._xBox = xBox

-- Y row: label + edit box (same vertical level)
local yLbl = moverUI:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
yLbl:SetText("Y:")
yLbl:SetTextColor(1, 0.82, 0)
yLbl:SetPoint("LEFT", xBox, "RIGHT", 6, 0)
yLbl:SetPoint("TOP",  xLbl, "TOP", 0, 0)

local yBox = makeCoordBox(moverUI)
yBox:SetPoint("LEFT", yLbl, "RIGHT", 4, 0)
yBox:SetPoint("TOP",  xLbl, "TOP", 0, 0)
moverUI._yBox = yBox

-- W row: width edit box
local wLbl = moverUI:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
wLbl:SetText("W:")
wLbl:SetTextColor(1, 0.82, 0)
wLbl:SetPoint("TOPLEFT", xLbl, "BOTTOMLEFT", 0, -10)

local wBox = makeCoordBox(moverUI)
wBox:SetPoint("LEFT", wLbl, "RIGHT", 4, 0)
wBox:SetPoint("TOP",  wLbl, "TOP", 0, 0)
wBox:SetScript("OnEnterPressed", function(f)
    f:ClearFocus()
    local w = tonumber(f:GetText())
    if not w or not nudgeHolder or not nudgeDB then return end
    w = math.max(10, math.floor(w + 0.5))
    nudgeDB.DetachedWidth = w
    if nudgeRefreshFn then nudgeRefreshFn() end
end)
moverUI._wBox = wBox

-- Now that both boxes exist, define the coord update helper
updateCoordBoxes = function()
    if not nudgeHolder then return end
    local hx, hy = nudgeHolder:GetCenter()
    local cx, cy = UIParent:GetCenter()
    if hx and hy and cx and cy then
        local rx = math.floor((hx - cx) * 10 + 0.5) / 10
        local ry = math.floor((hy - cy) * 10 + 0.5) / 10
        if not xBox:HasFocus() then xBox:SetText(tostring(rx)) end
        if not yBox:HasFocus() then yBox:SetText(tostring(ry)) end
    end
end

-- Reset button
local resetBtn = CreateFrame("Button", nil, moverUI, "UIPanelButtonTemplate")
resetBtn:SetSize(54, 18)
resetBtn:SetPoint("TOP", wBox, "BOTTOM", 0, -6)
resetBtn:SetText("Reset")
resetBtn:SetScript("OnClick", function()
    if not nudgeHolder or not nudgeDB then return end
    nudgeDB.DetachedX = 0
    nudgeDB.DetachedY = 0
    nudgeHolder:ClearAllPoints()
    nudgeHolder:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end)

-- Arrow buttons: ^ v < >
local arrowSize = 22
local function makeArrow(label, dx, dy, anchorPoint, anchorFrame, anchorRelPoint, ox, oy)
    local btn = CreateFrame("Button", nil, moverUI, "UIPanelButtonTemplate")
    btn:SetSize(arrowSize, arrowSize)
    btn:SetText(label)
    btn:SetPoint(anchorPoint, anchorFrame, anchorRelPoint, ox, oy)
    btn:SetScript("OnClick", function() applyNudge(dx, dy) end)
    return btn
end

-- Cross layout: ^ on top, < > flanking, v below
local upBtn    = makeArrow("^",  0,  1, "TOP",   resetBtn, "BOTTOM",  0, -4)
local leftBtn  = makeArrow("<", -1,  0, "RIGHT", upBtn,    "LEFT",   -2,  0)
local rightBtn = makeArrow(">",  1,  0, "LEFT",  upBtn,    "RIGHT",   2,  0)
local downBtn  = makeArrow("v",  0, -1, "TOP",   upBtn,    "BOTTOM",  0, -2)

-- Keyboard capture frame (unchanged behaviour)
local nudgeFrame = CreateFrame("Frame", "UUFNudgeFrame", UIParent)
nudgeFrame:EnableKeyboard(false)
nudgeFrame:SetPropagateKeyboardInput(true)

local function handleNudgeKey(key)
    if not nudgeHolder or not nudgeHolder:IsShown() then return false end
    if key ~= "UP" and key ~= "DOWN" and key ~= "LEFT" and key ~= "RIGHT" then return false end
    local step = IsShiftKeyDown() and 10 or 1
    if key == "UP"    then applyNudge(0,     step)
    elseif key == "DOWN"  then applyNudge(0,    -step)
    elseif key == "LEFT"  then applyNudge(-step, 0)
    elseif key == "RIGHT" then applyNudge( step, 0)
    end
    return true
end

nudgeFrame:SetScript("OnKeyDown", function(self, key)
    nudgeFrame:SetPropagateKeyboardInput(not handleNudgeKey(key))
end)
nudgeFrame:SetScript("OnKeyUp", function(self, key)
    nudgeFrame:SetPropagateKeyboardInput(not (nudgeHolder and nudgeHolder:IsShown()
        and (key == "UP" or key == "DOWN" or key == "LEFT" or key == "RIGHT")))
end)

-- Selection highlight on the active holder
local holderHighlight = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
holderHighlight:SetFrameStrata("HIGH")
holderHighlight:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
holderHighlight:SetBackdropBorderColor(1, 0.82, 0, 1)
holderHighlight:EnableMouse(false)
holderHighlight:Hide()

local function updateHighlight()
    if not nudgeHolder or not nudgeHolder:IsShown() then
        holderHighlight:Hide()
        return
    end
    -- SetAllPoints anchors the highlight to nudgeHolder; it tracks automatically
    -- when nudgeHolder is repositioned via SetPoint, no OnUpdate needed
    holderHighlight:ClearAllPoints()
    holderHighlight:SetAllPoints(nudgeHolder)
    holderHighlight:Show()
end

-- ── End Mover UI ──────────────────────────────────────────────────────────────

function UUF:LayoutPowerBar(unitFrame, unit)
    local FrameDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Frame
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar
    local power = unitFrame.Power
    if not power then return end

    local width = PowerBarDB.Detached and (PowerBarDB.DetachedWidth or FrameDB.Width - 2) or (FrameDB.Width - 2)
    local height = PowerBarDB.Height

    if PowerBarDB.Detached then
        if not unitFrame.PowerHolder then
            local holder = CreateFrame("Frame", UUF:FetchFrameName(unit) .. "_PowerBarHolder", UIParent)
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
                PowerBarDB.DetachedX = hx - cx
                PowerBarDB.DetachedY = hy - cy
            end)
            unitFrame.PowerHolder = holder
        end
        power.Holder = unitFrame.PowerHolder

        power.Holder:SetSize(width, height)
        power.Holder:ClearAllPoints()
        power.Holder:SetPoint("CENTER", UIParent, "CENTER", PowerBarDB.DetachedX or 0, PowerBarDB.DetachedY or -200)
        power.Holder:Show()

        power:SetParent(power.Holder)
        power:SetFrameLevel(power.Holder:GetFrameLevel() + 1)
        power:ClearAllPoints()
        power:SetAllPoints(power.Holder)
        power:SetSize(width, height)

        if power.Background then
            power.Background:ClearAllPoints()
            power.Background:SetAllPoints(power)
            power.Background:SetSize(width, height)
        end
    else
        if power.Holder then
            power.Holder:Hide()
        end

        power:SetParent(unitFrame.Container)
        power:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 2)
        power:ClearAllPoints()
        power:SetPoint("BOTTOMLEFT", unitFrame.Container, "BOTTOMLEFT", 1, 1)
        power:SetSize(width, height)

        if power.Background then
            power.Background:ClearAllPoints()
            power.Background:SetPoint("BOTTOMLEFT", unitFrame.Container, "BOTTOMLEFT", 1, 1)
            power.Background:SetSize(width, height)
        end
    end

    if power.PowerBarBorder then
        power.PowerBarBorder:ClearAllPoints()
        power.PowerBarBorder:SetPoint("TOPLEFT", power, "BOTTOMLEFT", 0, 0)
        power.PowerBarBorder:SetPoint("TOPRIGHT", power, "BOTTOMRIGHT", 0, 0)
    end
end

function UUF:CreateUnitPowerBar(unitFrame, unit)
    local FrameDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Frame
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar
    local unitContainer = unitFrame.Container

    local PowerBar = CreateFrame("StatusBar", UUF:FetchFrameName(unit) .. "_PowerBar", unitContainer)
    PowerBar:SetPoint("BOTTOMLEFT", unitContainer, "BOTTOMLEFT", 1, 1)
    PowerBar:SetSize(FrameDB.Width - 2, PowerBarDB.Height)
    PowerBar:SetStatusBarTexture(UUF.Media.Foreground)
    PowerBar:SetStatusBarColor(PowerBarDB.Foreground[1], PowerBarDB.Foreground[2], PowerBarDB.Foreground[3], PowerBarDB.Foreground[4] or 1)
    PowerBar:SetFrameLevel(unitContainer:GetFrameLevel() + 2)
    PowerBar.colorPower = PowerBarDB.ColourByType
    PowerBar.colorClass = PowerBarDB.ColourByClass
    PowerBar.smoothing = PowerBarDB.Smooth and INTERP_SMOOTH or INTERP_IMMEDIATE

    if PowerBarDB.Inverse then
        PowerBar:SetReverseFill(true)
    else
        PowerBar:SetReverseFill(false)
    end

    PowerBar.Background = PowerBar:CreateTexture(UUF:FetchFrameName(unit) .. "_PowerBackground", "BACKGROUND")
    PowerBar.Background:SetPoint("BOTTOMLEFT", unitContainer, "BOTTOMLEFT", 1, 1)
    PowerBar.Background:SetSize(FrameDB.Width - 2, PowerBarDB.Height)
    PowerBar.Background:SetTexture(UUF.Media.Background)
    PowerBar.Background:SetVertexColor(PowerBarDB.Background[1], PowerBarDB.Background[2], PowerBarDB.Background[3], PowerBarDB.Background[4] or 1)

    if not PowerBar.PowerBarBorder then
        PowerBar.PowerBarBorder = PowerBar:CreateTexture(nil, "OVERLAY")
        PowerBar.PowerBarBorder:SetHeight(1)
        PowerBar.PowerBarBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        PowerBar.PowerBarBorder:SetVertexColor(0, 0, 0, 1)
        PowerBar.PowerBarBorder:SetPoint("TOPLEFT", PowerBar, "BOTTOMLEFT", 0, 0)
        PowerBar.PowerBarBorder:SetPoint("TOPRIGHT", PowerBar, "BOTTOMRIGHT", 0, 0)
    end

    if PowerBarDB.Enabled then
        unitFrame.Power = PowerBar
        PowerBar:Show()
        if unitFrame.PowerBackground then unitFrame.PowerBackground:Show() end
    else
        if unitFrame:IsElementEnabled("Power") then unitFrame:DisableElement("Power") end
        PowerBar:Hide()
        if unitFrame.PowerBackground then unitFrame.PowerBackground:Hide() end
    end

    UUF:LayoutPowerBar(unitFrame, unit)
    UUF:CreateUnitPowerBarTags(unitFrame, unit)
    UUF:UpdateHealthBarLayout(unitFrame, unit)

    return PowerBar
end

function UUF:CreateUnitPowerBarTags(unitFrame, unit)
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar
    local GeneralDB = UUF.db.profile.General
    local power = unitFrame.Power
    if not power or not PowerBarDB.PowerBarTags then return end

    power.PowerBarTags = power.PowerBarTags or {}
    for tagName, tagData in pairs(PowerBarDB.PowerBarTags) do
        if not power.PowerBarTags[tagName] then
            local fs = power:CreateFontString(UUF:FetchFrameName(unit) .. "_PowerBarTag_" .. tagName, "OVERLAY")
            fs:SetFont(UUF.Media.Font, tagData.FontSize, UUF.Media.FontFlag)
            fs:SetVertexColor(tagData.Colour[1], tagData.Colour[2], tagData.Colour[3], 1)
            if GeneralDB.Fonts.Shadow.Enabled then
                fs:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                fs:SetShadowOffset(GeneralDB.Fonts.Shadow.XPos, GeneralDB.Fonts.Shadow.YPos)
            else
                fs:SetShadowColor(0, 0, 0, 0)
                fs:SetShadowOffset(0, 0)
            end
            fs:SetPoint(tagData.Layout[1], power, tagData.Layout[2], tagData.Layout[3], tagData.Layout[4])
            fs:SetJustifyH(UUF:SetJustification(tagData.Layout[1]))
            unitFrame:Tag(fs, tagData.Tag)
            power.PowerBarTags[tagName] = fs
        end
    end
end

function UUF:UpdateUnitPowerBarTag(unitFrame, unit, tagDB)
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar
    local GeneralDB = UUF.db.profile.General
    local power = unitFrame.Power
    if not power or not power.PowerBarTags then return end

    local tagData = PowerBarDB.PowerBarTags[tagDB]
    local fs = power.PowerBarTags[tagDB]
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
    fs:SetPoint(tagData.Layout[1], power, tagData.Layout[2], tagData.Layout[3], tagData.Layout[4])
    fs:SetJustifyH(UUF:SetJustification(tagData.Layout[1]))
    unitFrame:Tag(fs, tagData.Tag)
    fs:UpdateTag()
end

function UUF:UpdateUnitPowerBarTags(unitFrame, unit)
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar
    if not PowerBarDB.PowerBarTags then return end
    for tagName, _ in pairs(PowerBarDB.PowerBarTags) do
        UUF:UpdateUnitPowerBarTag(unitFrame, unit, tagName)
    end
end

function UUF:UpdateUnitPowerBar(unitFrame, unit)
    local PowerBarDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].PowerBar

    if PowerBarDB.Enabled then
        unitFrame.Power = unitFrame.Power or UUF:CreateUnitPowerBar(unitFrame, unit)

        if not unitFrame:IsElementEnabled("Power") then unitFrame:EnableElement("Power") end

        if unitFrame.Power then
            unitFrame.Power:SetStatusBarColor(PowerBarDB.Foreground[1], PowerBarDB.Foreground[2], PowerBarDB.Foreground[3], PowerBarDB.Foreground[4] or 1)
            unitFrame.Power:SetStatusBarTexture(UUF.Media.Foreground)
            unitFrame.Power.colorPower = PowerBarDB.ColourByType
            unitFrame.Power.colorClass = PowerBarDB.ColourByClass
            unitFrame.Power.smoothing = PowerBarDB.Smooth and INTERP_SMOOTH or INTERP_IMMEDIATE
            if PowerBarDB.Inverse then
                unitFrame.Power:SetReverseFill(true)
            else
                unitFrame.Power:SetReverseFill(false)
            end
        end

        if unitFrame.Power.Background then
            unitFrame.Power.Background:SetVertexColor(PowerBarDB.Background[1], PowerBarDB.Background[2], PowerBarDB.Background[3], PowerBarDB.Background[4] or 1)
            unitFrame.Power.Background:SetTexture(UUF.Media.Background)
        end

        UUF:LayoutPowerBar(unitFrame, unit)
        UUF:UpdateUnitPowerBarTags(unitFrame, unit)

        unitFrame.Power:Show()
        unitFrame.Power:ForceUpdate()
    else
        if not unitFrame.Power then return end
        if unitFrame:IsElementEnabled("Power") then unitFrame:DisableElement("Power") end
        if unitFrame.PowerHolder then unitFrame.PowerHolder:Hide() end
        unitFrame.Power:Hide()
        unitFrame.Power = nil
    end

    UUF:UpdateHealthBarLayout(unitFrame, unit)
end

function UUF:SetNudgeTarget(holder, db, title, refreshFn)
    nudgeHolder = holder
    nudgeDB = db
    nudgeRefreshFn = refreshFn
    nudgeFrame:EnableKeyboard(holder ~= nil)
    if holder then
        moverUI._title:SetText(title or "Move Bar")
        if moverUI._wBox then
            moverUI._wBox:SetText(tostring(db.DetachedWidth or 0))
        end
        -- Anchor moverUI above or below the holder depending on screen position
        moverUI:ClearAllPoints()
        local _, holderY = holder:GetCenter()
        local screenH = UIParent:GetHeight()
        if holderY and holderY > screenH * 0.55 then
            moverUI:SetPoint("TOP", holder, "BOTTOM", 0, -6)
        else
            moverUI:SetPoint("BOTTOM", holder, "TOP", 0, 6)
        end
        moverUI:Show()
        updateCoordBoxes()
        coordThrottle = 0
        updateHighlight()
    else
        moverUI:Hide()
        holderHighlight:Hide()
    end
end

function UUF:ClearNudgeTarget()
    nudgeHolder = nil
    nudgeDB = nil
    nudgeRefreshFn = nil
    nudgeFrame:EnableKeyboard(false)
    moverUI:Hide()
    holderHighlight:Hide()
end

function UUF:SetDetachedHoldersDraggable(enabled)
    local units = {"PLAYER", "TARGET", "FOCUS", "PET", "TARGETTARGET", "FOCUSTARGET"}
    for _, key in ipairs(units) do
        local frame = UUF[key]
        if frame then
            if frame.PowerHolder then frame.PowerHolder:EnableMouse(enabled) end
            if frame.SecondaryPowerHolder then frame.SecondaryPowerHolder:EnableMouse(enabled) end
        end
    end
    for i = 1, UUF.MAX_BOSS_FRAMES do
        local frame = UUF["BOSS"..i]
        if frame then
            if frame.PowerHolder then frame.PowerHolder:EnableMouse(enabled) end
        end
    end
    if not enabled then UUF:ClearNudgeTarget() end
end
