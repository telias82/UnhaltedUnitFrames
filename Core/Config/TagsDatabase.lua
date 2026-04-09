local _, UUF = ...
local oUF = UUF.oUF
oUF.Tags = oUF.Tags or {}

function UUFG:AddTag(tagString, tagEvents, tagMethod, tagType, tagDescription)
    -- tagString: The string used to call the tag, e.g., "curhp:abbr"
    -- tagEvents: A space-separated string of events that will trigger an update of the tag
    -- tagMethod: A function that takes a unit as an argument and returns the tag's value
    -- tagType: "Health", "Power", "Name", "Misc"
    -- tagDescription: A short description of what the tag does.
    -- tagType, tagDescription are used for the configuration UI. Please provide them. Prefix of your AddOn Name is also advised.
    -- EG: UUFG:AddTag("BCDM: Health", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit) return UnitHealth(unit) or 0 end, "Health", "Show Health")

    if not tagString or not tagEvents or not tagMethod or not tagType or not tagDescription then return end

    oUF.Tags.Methods[tagString] = tagMethod
    oUF.Tags.Events[tagString] = (oUF.Tags.Events[tagString] and (oUF.Tags.Events[tagString] .. " ") or "") .. tagEvents

    local tagDatabase = UUF:FetchTagData(tagType)
    if not tagDatabase then return end

    tagDatabase[1][tagString] = tagDescription

    for _, existing in ipairs(tagDatabase[2]) do
        if existing == tagString then return end
    end

    table.insert(tagDatabase[2], tagString)
end

local Tags = {
    ["curhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["curhpperhp"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["curhpperhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["perhp:absorb"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
    ["curhpperhp:absorb"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
    ["absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["absorbs:abbr"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["absorbs:truncate"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["maxhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",

    ["curpp:colour"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:abbr:colour"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent-with-sign"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent-with-sign:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",

    ["maxpp:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["maxpp:colour"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["maxpp:abbr:colour"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",

    ["name:colour"] = "UNIT_CLASSIFICATION_CHANGED UNIT_FACTION UNIT_NAME_UPDATE",
    ["maxhp:abbr:colour"] = "UNIT_HEALTH UNIT_MAXHEALTH",
}

for i = 1, 25 do
    Tags["name:short:" .. i] = "UNIT_NAME_UPDATE"
end

for i = 1, 25 do
    Tags["name:short:" .. i .. ":colour"] = "UNIT_NAME_UPDATE"
end

UUF.SEPARATOR_TAGS = {
{
    ["||"] = "|",
    ["-"] = "-",
    ["/"] = "/",
    [" "] = "Space",
    ["[]"] = "[]",
    ["()"] = "()",
},
{
    "||",
    "-",
    "/",
    "[]",
    "()",
    " "
}
}

UUF.TOT_SEPARATOR_TAGS = {
    {
        ["»"] = "»",
        ["-"] = "-",
        [">"] = ">",
    },
    {
        "»",
        "-",
        ">",
    }
}

-- MoP Classic-native number abbreviation.
-- AbbreviateNumbers and AbbreviateLargeNumbers are retail-only Blizzard globals
-- that do not exist in MoP Classic. This replaces both with a self-contained
-- implementation that correctly formats values into K/M/B suffixes.
--
-- Examples:
--   950       -> "950"
--   9500      -> "9.5K"
--   95000     -> "95.0K"
--   450200    -> "450.2K"
--   3808000   -> "3.8M"
--   10500000  -> "10.5M"
--   100000000 -> "100.0M"
local function AbbreviateValue(value)
    if not value or value == 0 then return "0" end
    if value >= 1e9 then
        local v = value / 1e9
        return string.format("%.1fB", v)
    elseif value >= 1e6 then
        local v = value / 1e6
        return string.format("%.1fM", v)
    elseif value >= 1e3 then
        local v = value / 1e3
        if v >= 100 then
            return string.format("%.0fK", v)
        else
            return string.format("%.1fK", v)
        end
    else
        return tostring(value)
    end
end

for tagString, tagEvents in pairs(Tags) do
    oUF.Tags.Events[tagString] = (oUF.Tags.Events[tagString] and (oUF.Tags.Events[tagString] .. " ") or "") .. tagEvents
end

local function FetchUnitPowerColour(unit)
    local powerType = UnitPowerType(unit)
    local powerColour = powerType and UUF.db.profile.General.Colours.Power[powerType]
    if powerColour then
        local powerColourR, powerColourG, powerColourB = unpack(powerColour)
        return powerColourR, powerColourG, powerColourB
    end
    return 1, 1, 1
end

oUF.Tags.Methods["curhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitStatus = UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        return string.format("%s", AbbreviateValue(unitHealth))
    end
end

oUF.Tags.Methods["curhpperhp:absorb"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    local unitStatus = UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    end
    if unitMaxHealth > 0 then
        local effectiveHealth = unitHealth + absorbAmount
        local pct = effectiveHealth / unitMaxHealth * 100
        if UUF.SEPARATOR == "[]" then
            return string.format("%s [%.0f%%]", AbbreviateValue(effectiveHealth), pct)
        elseif UUF.SEPARATOR == "()" then
            return string.format("%s (%.0f%%)", AbbreviateValue(effectiveHealth), pct)
        elseif UUF.SEPARATOR == " " then
            return string.format("%s %.0f%%", AbbreviateValue(effectiveHealth), pct)
        else
            return string.format("%s %s %.0f%%", AbbreviateValue(effectiveHealth), UUF.SEPARATOR, pct)
        end
    end
    return ""
end

oUF.Tags.Methods["curhpperhp"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    local unitHealthPercent = unitMaxHealth > 0 and (unitHealth / unitMaxHealth * 100) or 0
    local unitStatus = UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        if UUF.SEPARATOR == "[]" then
            return string.format("%s [%.0f%%]", unitHealth, unitHealthPercent)
        elseif UUF.SEPARATOR == "()" then
            return string.format("%s (%.0f%%)", unitHealth, unitHealthPercent)
        elseif UUF.SEPARATOR == " " then
            return string.format("%s %.0f%%", unitHealth, unitHealthPercent)
        else
            return string.format("%s %s %.0f%%", unitHealth, UUF.SEPARATOR, unitHealthPercent)
        end
    end
end

oUF.Tags.Methods["curhpperhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    local unitHealthPercent = unitMaxHealth > 0 and (unitHealth / unitMaxHealth * 100) or 0
    local unitStatus = UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        if UUF.SEPARATOR == "[]" then
            return string.format("%s [%.0f%%]", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif UUF.SEPARATOR == "()" then
            return string.format("%s (%.0f%%)", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif UUF.SEPARATOR == " " then
            return string.format("%s %.0f%%", AbbreviateValue(unitHealth), unitHealthPercent)
        else
            return string.format("%s %s %.0f%%", AbbreviateValue(unitHealth), UUF.SEPARATOR, unitHealthPercent)
        end
    end
end

oUF.Tags.Methods["absorbs"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", absorbAmount)
    end
end

oUF.Tags.Methods["absorbs:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", AbbreviateValue(absorbAmount))
    end
end

oUF.Tags.Methods["absorbs:truncate"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", absorbAmount ~= 0 and absorbAmount or "")
    end
end

oUF.Tags.Methods["perhp:absorb"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    local unitStatus = UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    end
    if unitMaxHealth > 0 then
        return string.format("%.0f%%", (unitHealth + absorbAmount) / unitMaxHealth * 100)
    end
    return ""
end



oUF.Tags.Methods["curpp:colour"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColourR, powerColourG, powerColourB = FetchUnitPowerColour(unit)
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("|cff%02x%02x%02x%s|r", powerColourR * 255, powerColourG * 255, powerColourB * 255, unitPower)
    end
end

oUF.Tags.Methods["maxpp:colour"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColourR, powerColourG, powerColourB = FetchUnitPowerColour(unit)
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("|cff%02x%02x%02x%s|r", powerColourR * 255, powerColourG * 255, powerColourB * 255, unitPowerMax)
    end
end

oUF.Tags.Methods["curpp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

-- MoP Classic: Enum.PowerType, UnitPowerPercent, and CurveConstants do not exist.
-- Power type 0 = MANA. Percentage calculated manually.
local function MopManaPercent(unit)
    local cur = UnitPower(unit, 0)
    local max = UnitPowerMax(unit, 0)
    if max and max > 0 then return cur / max * 100 end
    return 0
end

oUF.Tags.Methods["curpp:manapercent"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == 0 and unitPower then
        return string.format("%.f", MopManaPercent(unit))
    else
        return string.format("%s", unitPower)
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == 0 and unitPower then
        return string.format("%.f%%", MopManaPercent(unit))
    else
        return string.format("%s", unitPower)
    end
end

oUF.Tags.Methods["curpp:manapercent:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == 0 and unitPower then
        return string.format("%.f", MopManaPercent(unit))
    else
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == 0 and unitPower then
        return string.format("%.f%%", MopManaPercent(unit))
    else
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["maxpp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("%s", AbbreviateValue(unitPowerMax))
    end
end

oUF.Tags.Methods["curpp:abbr:colour"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColourR, powerColourG, powerColourB = FetchUnitPowerColour(unit)
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("|cff%02x%02x%02x%s|r", powerColourR * 255, powerColourG * 255, powerColourB * 255, AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["maxpp:abbr:colour"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColourR, powerColourG, powerColourB = FetchUnitPowerColour(unit)
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("|cff%02x%02x%02x%s|r", powerColourR * 255, powerColourG * 255, powerColourB * 255, AbbreviateValue(unitPowerMax))
    end
end

oUF.Tags.Methods["maxhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitMaxHealth = UnitHealthMax(unit)
    if unitMaxHealth then
        return string.format("%s", AbbreviateValue(unitMaxHealth))
    end
end

oUF.Tags.Methods["maxhp:abbr:colour"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local classColourR, classColourG, classColourB = UUF:GetUnitColour(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    if unitMaxHealth then
        return string.format("|cff%02x%02x%02x%s|r", classColourR * 255, classColourG * 255, classColourB * 255, AbbreviateValue(unitMaxHealth))
    end
end

oUF.Tags.Methods["name:colour"] = function(unit)
    local classColourR, classColourG, classColourB = UUF:GetUnitColour(unit)
    local unitName = UnitName(unit) or ""
    return string.format("|cff%02x%02x%02x%s|r", classColourR * 255, classColourG * 255, classColourB * 255, unitName)
end

oUF.Tags.Methods["resetcolor"] = function(unit)
    return "|r"
end

local function ShortenUnitName(unit, maxChars)
    if not unit or not UnitExists(unit) then return "" end
    local unitName = UnitName(unit) or ""
    if maxChars and maxChars > 0 then
        unitName = string.format("%." .. maxChars .. "s", unitName)
    end
    return UUF:CleanTruncateUTF8String(unitName)
end

for i = 1, 25 do
    oUF.Tags.Methods["name:short:" .. i] = function(unit) return ShortenUnitName(unit, i) end
end
for i = 1, 25 do
    oUF.Tags.Methods["name:short:" .. i .. ":colour"] = function(unit)
        local classColourR, classColourG, classColourB = UUF:GetUnitColour(unit)
        local shortenedName = ShortenUnitName(unit, i)
        return string.format("|cff%02x%02x%02x%s|r", classColourR * 255, classColourG * 255, classColourB * 255, shortenedName)
    end
end

local HealthTags = {
    {
        ["curhp"] = "Current Health",
        ["curhp:abbr"] = "Current Health with Abbreviation",
        ["perhp"] = "Percentage Health",
        ["curhpperhp"] = "Current Health and Percentage",
        ["curhpperhp:abbr"] = "Current Health and Percentage with Abbreviation",
        ["maxhp:abbr"] = "Maximum Health with Abbreviation",
        ["absorbs"] = "Total Absorbs",
        ["absorbs:abbr"] = "Total Absorbs with Abbreviation",
        ["absorbs:truncate"] = "Total Absorbs but will hide when at zero.",
        ["perhp:absorb"] = "Percentage Health including Absorbs",
        ["curhpperhp:absorb"] = "Current Health and Percentage including Absorbs",
        ["missinghp"] = "Missing Health",
    },
    {
        "curhp",
        "curhp:abbr",
        "perhp",
        "curhpperhp",
        "curhpperhp:abbr",
        "maxhp:abbr",
        "absorbs",
        "absorbs:abbr",
        "absorbs:truncate",
        "perhp:absorb",
        "curhpperhp:absorb",
        "missinghp",
    }

}

local PowerTags = {
    {
        ["perpp"] = "Percentage Power",
        ["curpp"] = "Current Power",
        ["curpp:colour"] = "Current Power with Colour",
        ["curpp:abbr"] = "Current Power with Abbreviation",
        ["curpp:abbr:colour"] = "Current Power with Abbreviation and Colour",
        ["maxpp"] = "Maximum Power",
        ["maxpp:abbr"] = "Maximum Power with Abbreviation",
        ["maxpp:colour"] = "Maximum Power with Colour",
        ["maxpp:abbr:colour"] = "Maximum Power with Abbreviation and Colour",
        ["missingpp"] = "Missing Power",
        ["curpp:manapercent"] = "Current Power but Mana as Percentage",
        ["curpp:manapercent:abbr"] = "Current Power but Mana as Percentage with Abbreviation",
        ["curpp:manapercent-with-sign"] = "Current Power but Mana as Percentage with % Sign",
        ["curpp:manapercent-with-sign:abbr"] = "Current Power but Mana as Percentage with % Sign and Abbreviation",
    },
    {
        "perpp",
        "curpp",
        "curpp:colour",
        "curpp:abbr",
        "curpp:abbr:colour",
        "curpp:manapercent",
        "curpp:manapercent:abbr",
        "maxpp",
        "maxpp:abbr",
        "maxpp:colour",
        "maxpp:abbr:colour",
        "missingpp",
    }
}

local NameTags = {
    {
        ["name"] = "Unit Name",
        ["name:colour"] = "Unit Name with Colour",
        ["name:short:10"] = "Unit Name Shortened (1 - 25 Chars)",
        ["name:short:10:colour"] = "Unit Name Shortened (1 - 25 Chars) with Colour",
    },
    {
        "name",
        "name:colour",
        "name:short:10",
        "name:short:10:colour",
    }
}

local MiscTags = {
    {
        ["classification"] = "Unit Classification",
        ["shortclassification"] = "Unit Classification with Abbreviation",
        ["creature"] = "Creature Type",
        ["group"] = "Group Number",
        ["level"] = "Unit Level",
        ["powercolor"] = "Unit Power Colour - Prefix",
        ["raidcolor"] = "Unit Class Colour - Prefix",
        ["class"] = "Unit Class",
        ["resetcolor"] = "Resets Colour Prefix",
    },
    {
        "classification",
        "shortclassification",
        "creature",
        "group",
        "level",
        "powercolor",
        "raidcolor",
        "class",
        "resetcolor",
    }
}

function UUF:FetchTagData(queriedDB)
    if queriedDB == "Health" then
        return HealthTags
    elseif queriedDB == "Power" then
        return PowerTags
    elseif queriedDB == "Name" then
        return NameTags
    elseif queriedDB == "Misc" then
        return MiscTags
    end
end

function UUFG:GetTags()
    return oUF.Tags
end