local _, UUF = ...

local readyCheckTextures = {}  -- unitFrame -> texture, only populated when Enabled

local function refreshAll()
    for unitFrame, indicator in pairs(readyCheckTextures) do
        local status = GetReadyCheckStatus(unitFrame.unit)
        if status then
            if status == "ready" then
                indicator:SetTexture([[Interface\RAIDFRAME\ReadyCheck-Ready]])
            elseif status == "notready" then
                indicator:SetTexture([[Interface\RAIDFRAME\ReadyCheck-NotReady]])
            else
                indicator:SetTexture([[Interface\RAIDFRAME\ReadyCheck-Waiting]])
            end
            indicator:Show()
        else
            indicator:Hide()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")
eventFrame:SetScript("OnEvent", refreshAll)

function UUF:CreateUnitReadyCheckIndicator(unitFrame, unit)
    local db = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.ReadyCheck

    local indicator = unitFrame.HighLevelContainer:CreateTexture(
        UUF:FetchFrameName(unit) .. "_ReadyCheckIndicator", "OVERLAY")
    indicator:SetSize(db.Size, db.Size)
    indicator:SetPoint(db.Layout[1], unitFrame.HighLevelContainer,
        db.Layout[2], db.Layout[3], db.Layout[4])
    indicator:Hide()

    unitFrame.ReadyCheckIndicator = indicator
    return indicator
end

function UUF:UpdateUnitReadyCheckIndicator(unitFrame, unit)
    local db = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.ReadyCheck

    if db.Enabled then
        unitFrame.ReadyCheckIndicator = unitFrame.ReadyCheckIndicator
            or UUF:CreateUnitReadyCheckIndicator(unitFrame, unit)

        local indicator = unitFrame.ReadyCheckIndicator
        if indicator then
            indicator:ClearAllPoints()
            indicator:SetSize(db.Size, db.Size)
            indicator:SetPoint(db.Layout[1], unitFrame.HighLevelContainer,
                db.Layout[2], db.Layout[3], db.Layout[4])
            readyCheckTextures[unitFrame] = indicator
        end
    else
        if not unitFrame.ReadyCheckIndicator then return end
        unitFrame.ReadyCheckIndicator:Hide()
        readyCheckTextures[unitFrame] = nil
    end
end
