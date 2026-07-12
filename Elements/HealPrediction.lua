local _, UUF = ...

function UUF:CreateUnitHealPrediction(unitFrame, unit)
    if not unitFrame.Health then return end
    local unitDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)]
    if not (unitDB and unitDB.HealPrediction and unitDB.HealPrediction.Absorbs.Enabled) then return end

    local health = unitFrame.Health
    local healthFill = health:GetStatusBarTexture()

    -- Incoming heal bar — ATTACH, grows right from health fill, clipped at bar edge
    local healBar = CreateFrame("StatusBar", nil, health)
    healBar:SetPoint("TOPLEFT",    healthFill, "TOPRIGHT",    0, 0)
    healBar:SetPoint("BOTTOMLEFT", healthFill, "BOTTOMRIGHT", 0, 0)
    healBar:SetWidth(0.01)
    healBar:SetFrameLevel(health:GetFrameLevel() + 1)
    healBar:SetStatusBarTexture(UUF.Media.Foreground)
    healBar:SetStatusBarColor(0.3, 1.0, 0.3, 0.6)
    healBar:Hide()

    -- Absorb bar — SUF over-absorb style, above the heal bar
    local absorbBar = CreateFrame("StatusBar", nil, health)
    absorbBar:SetAllPoints(health)
    absorbBar:SetReverseFill(true)
    absorbBar:SetFrameLevel(health:GetFrameLevel() + 2)
    absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Overlay")
    local fillTex = absorbBar:GetStatusBarTexture()
    if fillTex then
        fillTex:SetTexture("Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT")
        if fillTex.SetVertTile  then fillTex:SetVertTile(true)  end
        if fillTex.SetHorizTile then fillTex:SetHorizTile(true) end
    end
    absorbBar:SetMinMaxValues(0, 1)
    absorbBar:SetValue(0)
    absorbBar:Hide()

    local absorbGlow = absorbBar:CreateTexture(nil, "OVERLAY")
    absorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    absorbGlow:SetBlendMode("ADD")
    absorbGlow:SetWidth(6)
    absorbGlow:Hide()

    local lastHP, lastMaxHP, lastHeal, lastAbsorb = -1, -1, -1, -1

    unitFrame.HealthPrediction = {
        healingAll   = healBar,
        damageAbsorb = absorbBar,
        UpdateSize = function(frame)
            local barW = frame.Health:GetWidth()
            if barW > 0 then healBar:SetWidth(barW) end
        end,
        Override = function(frame, event, unit)
            if frame.unit ~= unit then return end
            local hp     = UnitHealth(unit)
            local maxHP  = UnitHealthMax(unit)
            local heal   = math.min(UnitGetIncomingHeals(unit) or 0, maxHP - hp)
            local amount = UnitGetTotalAbsorbs(unit) or 0

            if hp == lastHP and maxHP == lastMaxHP and heal == lastHeal and amount == lastAbsorb then return end
            lastHP = hp; lastMaxHP = maxHP; lastHeal = heal; lastAbsorb = amount

            -- Incoming heals — clamped to missing HP so it never extends past the bar
            if heal > 0 and maxHP > 0 then
                healBar:SetMinMaxValues(0, maxHP)
                healBar:SetValue(heal)
                healBar:Show()
            else
                healBar:Hide()
            end

            -- Damage absorbs (SUF over-absorb)
            if amount <= 0 or maxHP <= 0 then
                absorbBar:Hide(); absorbGlow:Hide(); return
            end
            local overAbsorb = math.min(amount - (maxHP - hp), maxHP)
            absorbBar:SetMinMaxValues(0, maxHP)
            absorbBar:SetValue(math.max(0, overAbsorb))
            absorbBar:Show()
            local barW = frame.Health:GetWidth()
            if barW > 0 then
                local barOffset
                if overAbsorb > 0 then
                    barOffset = (overAbsorb / maxHP) * barW
                else
                    barOffset = math.max(0, maxHP - hp - amount) / maxHP * barW
                end
                -- SetPoint replaces an existing point of the same name; ClearAllPoints not needed
                absorbGlow:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", -barOffset + 4, 0)
                absorbGlow:SetPoint("TOPRIGHT",    absorbBar, "TOPRIGHT",    -barOffset + 4, 0)
                absorbGlow:Show()
            end
        end,
    }
end

function UUF:UpdateUnitHealPrediction(unitFrame, unit)
    if unitFrame.HealthPrediction then
        unitFrame.HealthPrediction:ForceUpdate()
    else
        UUF:CreateUnitHealPrediction(unitFrame, unit)
    end
end
