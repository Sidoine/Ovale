local __exports = LibStub:NewLibrary("ovale/PassiveAura", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local exp = math.exp
local INFINITY = math.huge
local pairs = pairs
local GetTime = GetTime
local INVSLOT_TRINKET1 = INVSLOT_TRINKET1
local INVSLOT_TRINKET2 = INVSLOT_TRINKET2
local OvalePassiveAuraBase = Ovale:NewModule("OvalePassiveAura", aceEvent)
local self_playerGUID = nil
local TRINKET_SLOTS = {
    [1] = INVSLOT_TRINKET1,
    [2] = INVSLOT_TRINKET2
}
local AURA_NAME = {}
local INCREASED_CRIT_EFFECT_3_PERCENT = 44797
do
    AURA_NAME[INCREASED_CRIT_EFFECT_3_PERCENT] = "3% Increased Critical Effect"
end
local INCREASED_CRIT_EFFECT = {
    [INCREASED_CRIT_EFFECT_3_PERCENT] = 1.03
}
local INCREASED_CRIT_META_GEM = {
    [32409] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [34220] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [41285] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [41398] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [52291] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [52297] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [68778] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [68779] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [68780] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [76884] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [76885] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [76886] = INCREASED_CRIT_EFFECT_3_PERCENT,
    [76888] = INCREASED_CRIT_EFFECT_3_PERCENT
}
local AMPLIFICATION = 146051
do
    AURA_NAME[AMPLIFICATION] = "Amplification"
end
local AMPLIFICATION_TRINKET = {
    [102293] = AMPLIFICATION,
    [104426] = AMPLIFICATION,
    [104675] = AMPLIFICATION,
    [104924] = AMPLIFICATION,
    [105173] = AMPLIFICATION,
    [105422] = AMPLIFICATION,
    [102299] = AMPLIFICATION,
    [104478] = AMPLIFICATION,
    [104727] = AMPLIFICATION,
    [104976] = AMPLIFICATION,
    [105225] = AMPLIFICATION,
    [105474] = AMPLIFICATION,
    [102305] = AMPLIFICATION,
    [104613] = AMPLIFICATION,
    [104862] = AMPLIFICATION,
    [105111] = AMPLIFICATION,
    [105360] = AMPLIFICATION,
    [105609] = AMPLIFICATION
}
local READINESS_AGILITY_DPS = 146019
local READINESS_STRENGTH_DPS = 145955
local READINESS_TANK = 146025
do
    AURA_NAME[READINESS_AGILITY_DPS] = "Readiness"
    AURA_NAME[READINESS_STRENGTH_DPS] = "Readiness"
    AURA_NAME[READINESS_TANK] = "Readiness"
end
local READINESS_TRINKET = {
    [102292] = READINESS_AGILITY_DPS,
    [104476] = READINESS_AGILITY_DPS,
    [104725] = READINESS_AGILITY_DPS,
    [104974] = READINESS_AGILITY_DPS,
    [105223] = READINESS_AGILITY_DPS,
    [105472] = READINESS_AGILITY_DPS,
    [102298] = READINESS_STRENGTH_DPS,
    [104495] = READINESS_STRENGTH_DPS,
    [104744] = READINESS_STRENGTH_DPS,
    [104993] = READINESS_STRENGTH_DPS,
    [105242] = READINESS_STRENGTH_DPS,
    [105491] = READINESS_STRENGTH_DPS,
    [102306] = READINESS_TANK,
    [104572] = READINESS_TANK,
    [104821] = READINESS_TANK,
    [105070] = READINESS_TANK,
    [105319] = READINESS_TANK,
    [105568] = READINESS_TANK
}
local READINESS_ROLE = {
    DEATHKNIGHT = {
        blood = READINESS_TANK,
        frost = READINESS_STRENGTH_DPS,
        unholy = READINESS_STRENGTH_DPS
    },
    DRUID = {
        feral = READINESS_AGILITY_DPS,
        guardian = READINESS_TANK
    },
    HUNTER = {
        beast_mastery = READINESS_AGILITY_DPS,
        marksmanship = READINESS_AGILITY_DPS,
        survival = READINESS_AGILITY_DPS
    },
    MONK = {
        brewmaster = READINESS_TANK,
        windwalker = READINESS_AGILITY_DPS
    },
    PALADIN = {
        protection = READINESS_TANK,
        retribution = READINESS_STRENGTH_DPS
    },
    ROGUE = {
        assassination = READINESS_AGILITY_DPS,
        combat = READINESS_AGILITY_DPS,
        subtlety = READINESS_AGILITY_DPS
    },
    SHAMAN = {
        enhancement = READINESS_AGILITY_DPS
    },
    WARRIOR = {
        arms = READINESS_STRENGTH_DPS,
        fury = READINESS_STRENGTH_DPS,
        protection = READINESS_TANK
    }
}
local OvalePassiveAuraClass = __class(OvalePassiveAuraBase, {
    OnInitialize = function(self)
        self_playerGUID = Ovale.playerGUID
        self:RegisterMessage("Ovale_EquipmentChanged")
        self:RegisterMessage("Ovale_SpecializationChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_EquipmentChanged")
        self:UnregisterMessage("Ovale_SpecializationChanged")
    end,
    Ovale_EquipmentChanged = function(self)
        self:UpdateIncreasedCritEffectMetaGem()
        self:UpdateAmplification()
        self:UpdateReadiness()
    end,
    Ovale_SpecializationChanged = function(self)
        self:UpdateReadiness()
    end,
    UpdateIncreasedCritEffectMetaGem = function(self)
        local metaGem = OvaleEquipment.metaGem
        local spellId = metaGem and INCREASED_CRIT_META_GEM[metaGem]
        local now = GetTime()
        if spellId then
            local name = AURA_NAME[spellId]
            local start = now
            local duration = INFINITY
            local ending = INFINITY
            local stacks = 1
            local value = INCREASED_CRIT_EFFECT[spellId]
            OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value, nil, nil)
        else
            OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
        end
    end,
    UpdateAmplification = function(self)
        local hasAmplification = false
        local critDamageIncrease = 0
        local statMultiplier = 1
        for _, slot in pairs(TRINKET_SLOTS) do
            local trinket = OvaleEquipment:GetEquippedItem(slot)
            if trinket and AMPLIFICATION_TRINKET[trinket] then
                hasAmplification = true
                local ilevel = OvaleEquipment:GetEquippedItemLevel(slot)
                if ilevel == nil then
                    ilevel = 528
                end
                local amplificationEffect = exp((ilevel - 528) * 0.009327061882 + 1.713797928)
                if OvalePaperDoll.level >= 90 then
                    amplificationEffect = amplificationEffect * (100 - OvalePaperDoll.level) / 10
                    amplificationEffect = amplificationEffect > 1 and amplificationEffect or 1
                end
                critDamageIncrease = critDamageIncrease + amplificationEffect / 100
                statMultiplier = statMultiplier * (1 + amplificationEffect / 100)
            end
        end
        local now = GetTime()
        local spellId = AMPLIFICATION
        if hasAmplification then
            local name = AURA_NAME[spellId]
            local start = now
            local duration = INFINITY
            local ending = INFINITY
            local stacks = 1
            local value1 = critDamageIncrease
            local value2 = statMultiplier
            OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value1, value2, nil)
        else
            OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
        end
    end,
    UpdateReadiness = function(self)
        local specialization = OvalePaperDoll:GetSpecialization()
        local spellId = READINESS_ROLE[Ovale.playerClass] and READINESS_ROLE[Ovale.playerClass][specialization]
        if spellId then
            local hasReadiness = false
            local cdMultiplier
            for _, slot in pairs(TRINKET_SLOTS) do
                local trinket = OvaleEquipment:GetEquippedItem(slot)
                local readinessId = trinket and READINESS_TRINKET[trinket]
                if readinessId then
                    hasReadiness = true
                    local ilevel = OvaleEquipment:GetEquippedItemLevel(slot)
                    ilevel = ilevel or 528
                    local cdRecoveryRateIncrease = exp((ilevel - 528) * 0.009317881032 + 3.434954478)
                    if readinessId == READINESS_TANK then
                        cdRecoveryRateIncrease = cdRecoveryRateIncrease / 2
                    end
                    if OvalePaperDoll.level >= 90 then
                        cdRecoveryRateIncrease = cdRecoveryRateIncrease * (100 - OvalePaperDoll.level) / 10
                    end
                    cdMultiplier = 1 / (1 + cdRecoveryRateIncrease / 100)
                    cdMultiplier = cdMultiplier < 0.9 and cdMultiplier or 0.9
                    break
                end
            end
            local now = GetTime()
            if hasReadiness then
                local name = AURA_NAME[spellId]
                local start = now
                local duration = INFINITY
                local ending = INFINITY
                local stacks = 1
                local value = cdMultiplier
                OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value, nil, nil)
            else
                OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
            end
        end
    end,
})
__exports.OvalePassiveAura = OvalePassiveAuraClass()
