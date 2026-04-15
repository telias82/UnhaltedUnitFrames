local _, UUF = ...
local oUF = UUF.oUF

-- MoP Classic: C_CurveUtil and Enum.LuaCurveType do not exist.
-- dispelColorCurve is now a plain table mapping dispel type strings -> oUF color objects.
-- UpdateDispelColorCurve populates it; UpdateUnitDispelState queries it via UnitDebuff.

local dispelTypeMap = {
    Magic   = oUF.Enum.DispelType.Magic,
    Curse   = oUF.Enum.DispelType.Curse,
    Disease = oUF.Enum.DispelType.Disease,
    Poison  = oUF.Enum.DispelType.Poison,
    Bleed   = oUF.Enum.DispelType.Bleed,
}

function UUF:UpdateDispelColorCurve(unitFrame)
    -- In MoP Classic dispelColorCurve is a plain key->color table, not a curve object.
    if not unitFrame.dispelColorCurve then return end
    for dispelType, index in pairs(dispelTypeMap) do
        local color = oUF.colors.dispel[index]
        if color then
            unitFrame.dispelColorCurve[dispelType] = color
        end
    end
    unitFrame.dispelColorCurveGeneration = UUF.dispelColorGeneration
end

function UUF:CreateUnitDispelHighlight(unitFrame, unit)
    local DispelHighlightDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealthBar.DispelHighlight
    if not unitFrame.DispelHighlight then
        local DispelHighlight = unitFrame.Health:CreateTexture(UUF:FetchFrameName(unit) .. "_DispelHighlight", "OVERLAY")
        DispelHighlight:ClearAllPoints()
        if DispelHighlightDB.Style == "GRADIENT" then
            DispelHighlight:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
            DispelHighlight:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
            DispelHighlight:SetTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Gradient.png")
            DispelHighlight:SetAlpha(1)
        else
            local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
            if barTexture then
                DispelHighlight:SetAllPoints(barTexture)
            else
                DispelHighlight:SetAllPoints(unitFrame.Health)
            end
            DispelHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            DispelHighlight:SetAlpha(0.75)
        end
        DispelHighlight:SetBlendMode("BLEND")
        DispelHighlight:Hide()
        unitFrame.DispelHighlight = DispelHighlight

        -- MoP Classic: plain table instead of C_CurveUtil color curve
        unitFrame.dispelColorCurve = {}
        UUF:UpdateDispelColorCurve(unitFrame)
    end
end

function UUF:UpdateUnitDispelHighlight(unitFrame, unit)
    if not unitFrame.DispelHighlight then return end
    local DispelHighlightDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealthBar.DispelHighlight
    if unitFrame.DispelHighlight then
        if DispelHighlightDB.Enabled then
            UUF:RegisterDispelHighlightEvents(unitFrame, unit)
            unitFrame.DispelHighlight:ClearAllPoints()
            if DispelHighlightDB.Style == "GRADIENT" then
                unitFrame.DispelHighlight:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
                unitFrame.DispelHighlight:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
                unitFrame.DispelHighlight:SetTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Gradient.png")
                unitFrame.DispelHighlight:SetAlpha(1)
            else
                local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
                if barTexture then
                    unitFrame.DispelHighlight:SetAllPoints(barTexture)
                else
                    unitFrame.DispelHighlight:SetAllPoints(unitFrame.Health)
                end
                unitFrame.DispelHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
                unitFrame.DispelHighlight:SetAlpha(0.75)
            end
            UUF:UpdateUnitDispelState(unitFrame, unit)
        else
            UUF:UnregisterDispelHighlightEvents(unitFrame)
            unitFrame.DispelHighlight:Hide()
        end
    end
end

function UUF:UpdateUnitDispelState(unitFrame, unit)
    if not unitFrame.DispelHighlight then return end
    if not UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealthBar.DispelHighlight.Enabled then return end

    local LibDispel = UUF.LD
    if not LibDispel then return end

    -- Refresh color table if colours have been changed via config
    if unitFrame.dispelColorCurveGeneration ~= UUF.dispelColorGeneration then
        UUF:UpdateDispelColorCurve(unitFrame)
    end

    if not UnitIsUnit(unit, "player") and not UnitIsFriend("player", unit) then
        unitFrame.DispelHighlight:Hide()
        return
    end

    local dispelList = LibDispel:GetMyDispelTypes()
    if not (dispelList.Magic or dispelList.Curse or dispelList.Disease or dispelList.Poison or dispelList.Bleed) then
        unitFrame.DispelHighlight:Hide()
        return
    end

    -- MoP Classic: no C_UnitAuras. Scan debuffs with UnitDebuff instead.
    local colorToApply = nil
    local i = 1
    while true do
        local name, _, _, debuffType, _, _, _, _, _, _ = UnitDebuff(unit, i)
        if not name then break end
        if debuffType and debuffType ~= "" and dispelList[debuffType] then
            local color = unitFrame.dispelColorCurve and unitFrame.dispelColorCurve[debuffType]
            if color then
                colorToApply = color
                break -- use first dispellable debuff found (highest priority)
            end
        end
        i = i + 1
    end

    if colorToApply then
        unitFrame.DispelHighlight:SetVertexColor(colorToApply.r, colorToApply.g, colorToApply.b)
        unitFrame.DispelHighlight:Show()
    else
        unitFrame.DispelHighlight:Hide()
    end
end

function UUF:RegisterDispelHighlightEvents(unitFrame, unit)
    if not unitFrame.DispelHighlight then return end
    if not UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].HealthBar.DispelHighlight.Enabled then return end

    if not unitFrame.DispelHighlightHandler then
        unitFrame.DispelHighlightHandler = CreateFrame("Frame")
        unitFrame.DispelHighlightHandler:SetScript("OnEvent", function(self, event, ...) UUF:UpdateUnitDispelState(unitFrame, unit) end)
    end

    unitFrame.DispelHighlightHandler:RegisterUnitEvent("UNIT_AURA", unit)
    unitFrame.DispelHighlightHandler:RegisterEvent("SPELLS_CHANGED")
    unitFrame.DispelHighlightHandler:RegisterEvent("PLAYER_TALENT_UPDATE")
    unitFrame.DispelHighlightHandler:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function UUF:UnregisterDispelHighlightEvents(unitFrame)
    if not unitFrame.DispelHighlightHandler then return end
    unitFrame.DispelHighlightHandler:UnregisterAllEvents()
end
