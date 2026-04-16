local _, UUF = ...

UUF.RangeEvtFrames = {}

--[[
    Range spell data derived from LibRangeCheck-3.0
    https://www.curseforge.com/wow/addons/librangecheck-3-0

    Copyright (c) 2023 The WoWUIDev Community
    Licensed under the MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
]]

-- The idea to cache/store spells per class comes from ElvUI: https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/UnitFrames/Elements/Range.lua#L1
-- However, implementation is slightly different, as ElvUI allows for custom spell configuration, where I do not. I rely on the data below.

local RangeSpells = {
    ENEMY = {
        DEATHKNIGHT = {
            49576, -- Death Grip (30 yards)
            47541, -- Death Coil (Unholy) (40 yards)
        },
        DEMONHUNTER = {
            185123, -- Throw Glaive (Havoc) (30 yards)
            183752, -- Consume Magic (20 yards)
            204021, -- Fiery Brand (Vengeance) (30 yards)
        },
        DRUID = {
            8921,  -- Moonfire (40 yards)
            5176,  -- Wrath (40 yards)
            339,   -- Entangling Roots (35 yards)
            6795,  -- Growl (30 yards)
            33786, -- Cyclone (20 yards)
            22568, -- Ferocious Bite (Melee)
        },
        EVOKER = {
            362969, -- Azure Strike (25 yards)
        },
        HUNTER = {
            75,     -- Auto Shot (40 yards)
            466930, -- Black Arrow (40 yards)
        },
        MAGE = {
            116,   -- Frostbolt (40 yards)
            133,   -- Fireball (40 yards)
            44425, -- Arcane Barrage (40 yards)
            44614, -- Flurry (40 yards)
            118,   -- Polymorph (30 yards)
            5019,  -- Shoot (30 yards)
        },
        MONK = {
            117952, -- Crackling Jade Lightning (40 yards)
            115546, -- Provoke (30 yards)
            115078, -- Paralysis (20 yards)
            100780, -- Tiger Palm (Melee)
        },
        PALADIN = {
            20473,  -- Holy Shock (40 yards)
            20271,  -- Judgement (30 yards)
            62124,  -- Hand of Reckoning (30 yards)
            183218, -- Hand of Hindrance (30 yards)
            853,    -- Hammer of Justice (10 yards)
            35395,  -- Crusader Strike (Melee)
        },
        PRIEST = {
            585,  -- Smite (40 yards)
            8092, -- Mind Blast (40 yards)
            589,  -- Shadow Word: Pain (40 yards)
            5019, -- Shoot (30 yards)
        },
        ROGUE = {
            185565, -- Poisoned Knife (Assassination) (30 yards)
            36554,  -- Shadowstep (Assassination, Subtlety) (25 yards)
            185763, -- Pistol Shot (Outlaw) (20 yards)
            2094,   -- Blind (15 yards)
            921,    -- Pick Pocket (10 yards)
        },
        SHAMAN = {
            188196, -- Lightning Bolt (40 yards)
            8042,   -- Earth Shock (40 yards)
            117014, -- Elemental Blast (40 yards)
            370,    -- Purge (30 yards)
            73899,  -- Primal Strike (Melee)
        },
        WARLOCK = {
            686,    -- Shadow Bolt (40 yards)
            232670, -- Shadow Bolt (40 yards)
            234153, -- Drain Life (40 yards)
            198590, -- Drain Soul (40 yards)
            5782,   -- Fear (30 yards)
            5019,   -- Shoot (30 yards)
        },
        WARRIOR = {
            355,  -- Taunt (30 yards)
            100,  -- Charge (8-25 yards)
            5246, -- Intimidating Shout (8 yards)
        },
    },
    FRIENDLY = {
        DEATHKNIGHT = {
            47541, -- Death Coil (40 yards)
        },
        DEMONHUNTER = {},
        DRUID = {
            8936,  -- Regrowth (40 yards)
            774,   -- Rejuvenation (Restoration) (40 yards)
            88423, -- Nature's Cure (Restoration) (40 yards)
            2782,  -- Remove Corruption (Restoration) (40 yards)
        },
        EVOKER = {
            361469, -- Living Flame (25 yards)
            355913, -- Emerald Blossom (25 yards)
            360823, -- Naturalize (Preservation) (30 yards)
        },
        HUNTER = {},
        MAGE = {
            1459, -- Arcane Intellect (40 yards)
            475,  -- Remove Curse (40 yards)
        },
        MONK = {
            116670, -- Vivify (40 yards)
            115450, -- Detox (40 yards)
        },
        PALADIN = {
            19750,  -- Flash of Light (40 yards)
            85673,  -- Word of Glory (40 yards)
            4987,   -- Cleanse (Holy) (40 yards)
            213644, -- Cleanse Toxins (Protection, Retribution) (40 yards)
        },
        PRIEST = {
            2061,  -- Flash Heal (40 yards)
            17,    -- Power Word: Shield (40 yards)
            21562, -- Power Word: Fortitude (40 yards)
            527,   -- Purify / Dispel Magic (40 yards)
        },
        ROGUE = {
            57934, -- Tricks of the Trade (40 yards)
            36554, -- Shadowstep (25 yards)
            921,   -- Pick Pocket (10 yards)
        },
        SHAMAN = {
            8004,   -- Healing Surge (Resto, Elemental) (40 yards)
            188070, -- Healing Surge (Enhancement) (40 yards)
            546,    -- Water Walking (30 yards)
        },
        WARRIOR = {
            3411, -- Intervene (30 yards)
        },
        WARLOCK = {
            20707, -- Soulstone (40 yards)
            5697,  -- Unending Breath (30 yards)
        },
    },
    RESURRECT = {
        DEATHKNIGHT = {
            61999, -- Raise Ally (40 yards)
        },
        DEMONHUNTER = {},
        DRUID = {
            50769, -- Revive (40 yards)
            20484, -- Rebirth (40 yards)
        },
        EVOKER = {
            361227, -- Return (40 yards)
        },
        HUNTER = {},
        MAGE = {},
        MONK = {
            115178, -- Resuscitate (40 yards)
        },
        PALADIN = {
            7328,   -- Redemption (40 yards)
            391054, -- Intercession (40 yards)
        },
        PRIEST = {
            2006,   -- Resurrection (40 yards)
            212036, -- Mass Resurrection (40 yards)
        },
        ROGUE = {},
        SHAMAN = {
            2008, -- Ancestral Spirit (40 yards)
        },
        WARRIOR = {},
        WARLOCK = {
            20707, -- Soulstone (40 yards)
        },
    },
    PET = {
        DEATHKNIGHT = {
            47541, -- Death Coil (40 yards)
        },
        DEMONHUNTER = {},
        DRUID = {},
        EVOKER = {},
        HUNTER = {
            136, -- Mend Pet (45 yards)
        },
        MAGE = {},
        MONK = {},
        PALADIN = {},
        PRIEST = {},
        ROGUE = {},
        SHAMAN = {},
        WARRIOR = {},
        WARLOCK = {
            755, -- Health Funnel (45 yards)
        },
    },
}

local playerClass = select(2, UnitClass("player"))

-- One cached spell name per category. Picked once at login/spellbook change,
-- used directly in IsSpellInRange — no per-tick iteration.
local activeSpellName = {
    enemy     = nil,
    friendly  = nil,
    resurrect = nil,
    pet       = nil,
}

local function FindBestSpell(spellList)
    for _, spellID in ipairs(spellList or {}) do
        local name = GetSpellInfo(spellID)
        if name then return name end
    end
end

local function UpdateActiveSpells()
    activeSpellName.enemy     = FindBestSpell(RangeSpells.ENEMY[playerClass])
    activeSpellName.friendly  = FindBestSpell(RangeSpells.FRIENDLY[playerClass])
    activeSpellName.resurrect = FindBestSpell(RangeSpells.RESURRECT[playerClass])
    activeSpellName.pet       = FindBestSpell(RangeSpells.PET[playerClass])
end

local spellUpdateFrame = CreateFrame("Frame")
spellUpdateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
spellUpdateFrame:RegisterEvent("SPELLS_CHANGED")
spellUpdateFrame:SetScript("OnEvent", UpdateActiveSpells)

-- Check range for a unit using the single cached spell for that category.
-- Falls back to CheckInteractDistance (interact = ~28 yards) when no spell is
-- available and we are out of combat.
local function CheckSpellRange(unit, category)
    local spellName = activeSpellName[category]
    if not spellName then
        if not InCombatLockdown() then return CheckInteractDistance(unit, 4) end
        return nil
    end

    local inRange = IsSpellInRange(spellName, unit)
    if inRange == 1 then return true end
    if inRange == 0 then return false end
    -- nil means the spell isn't applicable to this target type; fall back
    if not InCombatLockdown() then return CheckInteractDistance(unit, 4) end
    return nil
end

function UUF:RegisterRangeFrame(frameName, unit)
    if not frameName or not unit then return end

    local frame = type(frameName) == "table" and frameName or _G[frameName]
    if not frame then return end

    local RangeDB = UUF.db.profile.General.Range
    frame.Range = RangeDB.Enabled and RangeDB or nil

    -- Per-frame ticker at 0.5s — predictable cadence, no event spam.
    -- UpdateRangeAlpha bails immediately when range is disabled, so the ticker
    -- is cheap to keep running regardless of the setting state.
    local frameData = { frame = frame, unit = unit }
    frameData.ticker = C_Timer.NewTicker(0.5, function()
        UUF:UpdateRangeAlpha(frame, unit)
    end)

    table.insert(UUF.RangeEvtFrames, frameData)
    UUF:UpdateRangeAlpha(frame, unit)
end

function UUF:IsRangeFrameRegistered(unit)
    for _, data in ipairs(UUF.RangeEvtFrames) do
        if data.unit == unit then return true end
    end
end

function UUF:UpdateRangeAlpha(frame, unit)
    local RangeDB = UUF.db.profile.General.Range
    if not RangeDB or not RangeDB.Enabled then frame:SetAlpha(1) return end
    if not frame:IsVisible() or not unit or not UnitExists(unit) then return end
    if unit == "player" then frame:SetAlpha(1) return end

    local inAlpha  = RangeDB.InRange or 1
    local outAlpha = RangeDB.OutOfRange or 0.5
    local inRange

    if UnitIsDeadOrGhost(unit) then
        inRange = CheckSpellRange(unit, "resurrect")
    elseif UnitCanAttack("player", unit) then
        inRange = CheckSpellRange(unit, "enemy")
    elseif UnitIsUnit(unit, "pet") then
        inRange = CheckSpellRange(unit, "pet")
    elseif UnitIsConnected(unit) then
        inRange = CheckSpellRange(unit, "friendly")
    else
        inRange = false
    end

    if inRange == nil then inRange = true end

    local newAlpha = inRange and inAlpha or outAlpha
    if newAlpha ~= frame._lastRangeAlpha then
        frame._lastRangeAlpha = newAlpha
        frame:SetAlpha(newAlpha)
    end
end
