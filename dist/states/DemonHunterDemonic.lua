local __exports = LibStub:NewLibrary("ovale/states/DemonHunterDemonic", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local GetTalentInfoByID = GetTalentInfoByID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local huge = math.huge
local select = select
local INFINITY = huge
local HAVOC_DEMONIC_TALENT_ID = 22547
local HAVOC_SPEC_ID = 577
local HAVOC_EYE_BEAM_SPELL_ID = 198013
local HAVOC_META_BUFF_ID = 162264
local HIDDEN_BUFF_ID = -HAVOC_DEMONIC_TALENT_ID
local HIDDEN_BUFF_DURATION = INFINITY
local HIDDEN_BUFF_EXTENDED_BY_DEMONIC = "Extended by Demonic"
__exports.OvaleDemonHunterDemonicClass = __class(nil, {
    constructor = function(self, ovaleAura, ovale, ovaleDebug)
        self.ovaleAura = ovaleAura
        self.ovale = ovale
        self.isDemonHunter = false
        self.OnInitialize = function()
            self.isDemonHunter = (self.ovale.playerClass == "DEMONHUNTER" and true) or false
            if self.isDemonHunter then
                self.debug:Debug("playerGUID: (%s)", self.ovale.playerGUID)
                self.module:RegisterMessage("Ovale_TalentsChanged", self.Ovale_TalentsChanged)
            end
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_TalentsChanged")
        end
        self.Ovale_TalentsChanged = function(event)
            self.isHavoc = (self.isDemonHunter and GetSpecializationInfo(GetSpecialization()) == HAVOC_SPEC_ID and true) or false
            self.hasDemonic = (self.isHavoc and select(10, GetTalentInfoByID(HAVOC_DEMONIC_TALENT_ID, HAVOC_SPEC_ID)) and true) or false
            if self.isHavoc and self.hasDemonic then
                self.debug:Debug("We are a havoc DH with Demonic.")
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            else
                if  not self.isHavoc then
                    self.debug:Debug("We are not a havoc DH.")
                elseif  not self.hasDemonic then
                    self.debug:Debug("We don't have the Demonic talent.")
                end
                self:DropAura()
                self.module:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.module = ovale:createModule("OvaleDemonHunterDemonic", self.OnInitialize, self.OnDisable, aceEvent)
        self.debug = ovaleDebug:create(self.module:GetName())
        self.playerGUID = self.ovale.playerGUID
        self.isHavoc = false
        self.hasDemonic = false
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, arg12, arg13 = CombatLogGetCurrentEventInfo()
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = arg12, arg13
            if HAVOC_EYE_BEAM_SPELL_ID == spellId then
                self.debug:Debug("Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).", spellId, spellName)
                self:GainAura()
            end
        end
        if sourceGUID == self.playerGUID and cleuEvent == "SPELL_AURA_REMOVED" then
            local spellId, spellName = arg12, arg13
            if HAVOC_META_BUFF_ID == spellId then
                self.debug:Debug("Aura %d (%s) is removed. Dropping Aura.", spellId, spellName)
                self:DropAura()
            end
        end
    end,
    GainAura = function(self)
        local now = GetTime()
        local aura_meta = self.ovaleAura:GetAura("player", HAVOC_META_BUFF_ID, now, "HELPFUL", true)
        if aura_meta and self.ovaleAura:IsActiveAura(aura_meta, now) then
            self.debug:Debug("Adding '%s' (%d) buff to player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
            local duration = HIDDEN_BUFF_DURATION
            local ending = now + HIDDEN_BUFF_DURATION
            self.ovaleAura:GainedAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID, "HELPFUL", false, nil, 1, nil, duration, ending, false, HIDDEN_BUFF_EXTENDED_BY_DEMONIC, nil, nil, nil)
        else
            self.debug:Debug("Aura 'Metamorphosis' (%d) is not present.", HAVOC_META_BUFF_ID)
        end
    end,
    DropAura = function(self)
        local now = GetTime()
        self.debug:Debug("Removing '%s' (%d) buff on player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, self.playerGUID)
        self.ovaleAura:LostAuraOnGUID(self.playerGUID, now, HIDDEN_BUFF_ID, self.playerGUID)
    end,
})
