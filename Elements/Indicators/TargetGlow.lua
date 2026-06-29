local _, UUF = ...
UUF.TargetHighlightEvtFrames = {}

local unitIsTargetEvtFrame = CreateFrame("Frame")
unitIsTargetEvtFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
unitIsTargetEvtFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
unitIsTargetEvtFrame:SetScript("OnEvent", function()
    for _, frameData in ipairs(UUF.TargetHighlightEvtFrames) do
        local frame, unit = frameData.frame, frameData.unit
        if UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Target.Enabled then
            UUF:UpdateTargetGlowIndicator(frame, unit)
        end
    end
end)

function UUF:CreateUnitTargetGlowIndicator(unitFrame, unit)
    local TargetIndicatorDB = UUF.db.profile.Units[unit].Indicators.Target
    if TargetIndicatorDB then
        unitFrame.TargetIndicator = CreateFrame("Frame", nil, unitFrame.Container, "BackdropTemplate")
        unitFrame.TargetIndicator:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 3)
        unitFrame.TargetIndicator:SetBackdrop({ edgeFile = "Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Glow.tga", edgeSize = 3, insets = {left = -3, right = -3, top = -3, bottom = -3} })
        unitFrame.TargetIndicator:SetBackdropColor(0, 0, 0, 0)
        unitFrame.TargetIndicator:SetBackdropBorderColor(TargetIndicatorDB.Colour[1], TargetIndicatorDB.Colour[2], TargetIndicatorDB.Colour[3], TargetIndicatorDB.Colour[4] or 1)
        unitFrame.TargetIndicator:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", -3, 3)
        unitFrame.TargetIndicator:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", 3, -3)
        unitFrame.TargetIndicator:SetAlpha(0)
    end
end

function UUF:UpdateUnitTargetGlowIndicator(unitFrame, unit)
    local TargetIndicatorDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Target
    if unitFrame and unitFrame.TargetIndicator and TargetIndicatorDB then
        if TargetIndicatorDB.Enabled and UnitIsUnit("target", unit) then
            unitFrame.TargetIndicator:SetBackdropBorderColor(
                TargetIndicatorDB.Colour[1],
                TargetIndicatorDB.Colour[2],
                TargetIndicatorDB.Colour[3],
                TargetIndicatorDB.Colour[4] or 1)
            unitFrame.TargetIndicator:SetAlpha(1)
        else
            unitFrame.TargetIndicator:SetBackdropBorderColor(
                TargetIndicatorDB.Colour[1],
                TargetIndicatorDB.Colour[2],
                TargetIndicatorDB.Colour[3],
                0)
            unitFrame.TargetIndicator:SetAlpha(0)
        end
    end
end

function UUF:UpdateTargetGlowIndicator(unitFrame, unit)
    if unitFrame and unitFrame.TargetIndicator then
        local TargetIndicatorDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Target
        if TargetIndicatorDB then
            if TargetIndicatorDB.Enabled and UnitIsUnit("target", unit) then
                unitFrame.TargetIndicator:SetBackdropBorderColor(
                    TargetIndicatorDB.Colour[1],
                    TargetIndicatorDB.Colour[2],
                    TargetIndicatorDB.Colour[3],
                    TargetIndicatorDB.Colour[4] or 1)
                unitFrame.TargetIndicator:SetAlpha(1)
            else
                unitFrame.TargetIndicator:SetBackdropBorderColor(
                    TargetIndicatorDB.Colour[1],
                    TargetIndicatorDB.Colour[2],
                    TargetIndicatorDB.Colour[3],
                    0)
                unitFrame.TargetIndicator:SetAlpha(0)
            end
        end
    end
end

function UUF:RegisterTargetGlowIndicatorFrame(frameName, unit)
    if not unit or not frameName then return end
        if UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Target then
            local unitFrame = type(frameName) == "table" and frameName or _G[frameName]
            local DB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)]
            table.insert(UUF.TargetHighlightEvtFrames, { frame = unitFrame, unit = unit })
            if DB and DB.Indicators.Target and DB.Indicators.Target.Enabled then
                UUF:UpdateTargetGlowIndicator(unitFrame, unit)
            else
                unitFrame.TargetIndicator:SetAlpha(0)
            end
            unitFrame:HookScript("OnShow", function(frame)
                UUF:UpdateTargetGlowIndicator(frame, unit)
            end)
    end
end