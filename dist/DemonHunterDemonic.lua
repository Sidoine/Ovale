local __exports = LibStub:NewLibrary("ovale/DemonHunterDemonic", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local GetTalentInfoByID = GetTalentInfoByID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local huge = math.huge
local select = select
local OvaleDemonHunterDemonicBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleDemonHunterDemonic", aceEvent))
local INFINITY = huge
local HAVOC_DEMONIC_TALENT_ID = 22547
local HAVOC_SPEC_ID = 577
local HAVOC_EYE_BEAM_SPELL_ID = 198013
local HAVOC_META_BUFF_ID = 162264
local HIDDEN_BUFF_ID = -HAVOC_DEMONIC_TALENT_ID
local HIDDEN_BUFF_DURATION = INFINITY
local HIDDEN_BUFF_EXTENDED_BY_DEMONIC = "Extended by Demonic"
local OvaleDemonHunterDemonicClass = __class(OvaleDemonHunterDemonicBase, {
    OnInitialize = function(self)
        self.playerGUID = nil
        self.isDemonHunter = Ovale.playerClass == "DEMONHUNTER" and true or false
        self.isHavoc = false
        self.hasDemonic = false
        if self.isDemonHunter then
            self:Debug("playerGUID: (%s)", Ovale.playerGUID)
            self.playerGUID = Ovale.playerGUID
            self:RegisterMessage("Ovale_TalentsChanged")
        end
    end,
    OnDisable = function(self)
        self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    Ovale_TalentsChanged = function(self, event)
        self.isHavoc = self.isDemonHunter and GetSpecializationInfo(GetSpecialization()) == HAVOC_SPEC_ID and true or false
        self.hasDemonic = self.isHavoc and select(10, GetTalentInfoByID(HAVOC_DEMONIC_TALENT_ID, HAVOC_SPEC_ID)) and true or false
        if self.isHavoc and self.hasDemonic then
            self:Debug("We are a havoc DH with Demonic.")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            if  not self.isHavoc then
                self:Debug("We are not a havoc DH.")
            elseif  not self.hasDemonic then
                self:Debug("We don't have the Demonic talent.")
            end
            self:DropAura()
            self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, arg12, arg13 = CombatLogGetCurrentEventInfo()
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = arg12, arg13
            if HAVOC_EYE_BEAM_SPELL_ID == spellId then
                self:Debug("Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).", spellId, spellName)
                self:GainAura()
            end
        end
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_AURA_REMOVED" then
            local spellId, spellName = arg12, arg13
            if HAVOC_META_BUFF_ID == spellId then
                self:Debug("Aura %d (%s) is removed. Dropping Aura.", spellId, spellName)
                self:DropAura()
            end
        end
    end,
    GainAura = function(self)
        local now = GetTime()
        local aura_meta = OvaleAura:GetAura("player", HAVOC_META_BUFF_ID, nil, "HELPFUL", true)
        if OvaleAura:IsActiveAura(aura_meta, now) then
            self:Debug("Adding '%s' (%d) buff to player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
            local duration = HIDDEN_BUFF_DURATION
            local ending = now + HIDDEN_BUFF_DURATION
            OvaleAura:GainedAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID, "HELPFUL", nil, nil, 1, nil, duration, ending, nil, HIDDEN_BUFF_EXTENDED_BY_DEMONIC, nil, nil, nil)
        else
            self:Debug("Aura 'Metamorphosis' (%d) is not present.", HAVOC_META_BUFF_ID)
        end
    end,
    DropAura = function(self)
        local now = GetTime()
        self:Debug("Removing '%s' (%d) buff on player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
        OvaleAura:LostAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID)
    end,
})
__exports.OvaleDemonHunterDemonic = OvaleDemonHunterDemonicClass()
