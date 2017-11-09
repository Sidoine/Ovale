local __exports = LibStub:NewLibrary("ovale/Stance", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local tonumber = tonumber
local type = type
local wipe = wipe
local sub = string.sub
local concat = table.concat
local insert = table.insert
local sort = table.sort
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetSpellInfo = GetSpellInfo
local OvaleStanceBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleStance", aceEvent)))
local druidCatForm = GetSpellInfo(768)
local druidTravelForm = GetSpellInfo(783)
local druidAquaticForm = GetSpellInfo(1066)
local druidBearForm = GetSpellInfo(5487)
local druidMoonkinForm = GetSpellInfo(24858)
local druid_flight_form = GetSpellInfo(33943)
local druid_swift_flight_form = GetSpellInfo(40120)
local rogue_stealth = GetSpellInfo(1784)
local SPELL_NAME_TO_STANCE = {
    [druidCatForm] = "druid_cat_form",
    [druidTravelForm] = "druid_travel_form",
    [druidAquaticForm] = "druid_aquatic_form",
    [druidBearForm] = "druid_bear_form",
    [druidMoonkinForm] = "druid_moonkin_form",
    [druid_flight_form] = "druid_flight_form",
    [druid_swift_flight_form] = "druid_swift_flight_form",
    [rogue_stealth] = "rogue_stealth"
}
local STANCE_NAME = {}
do
    for _, name in pairs(SPELL_NAME_TO_STANCE) do
        STANCE_NAME[name] = true
    end
end
do
    local debugOptions = {
        stance = {
            name = L["Stances"],
            type = "group",
            args = {
                stance = {
                    name = L["Stances"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvaleStance:DebugStances()
                    end

                }
            }
        }
    }
    for k, v in pairs(debugOptions) do
        OvaleDebug.options.args[k] = v
    end
end
local array = {}
local OvaleStanceClass = __class(OvaleStanceBase, {
    constructor = function(self)
        self.ready = false
        self.stanceList = {}
        self.stanceId = {}
        self.stance = nil
        self.STANCE_NAME = STANCE_NAME
        OvaleStanceBase.constructor(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
        self:RegisterMessage("Ovale_SpellsChanged", "UpdateStances")
        self:RegisterMessage("Ovale_TalentsChanged", "UpdateStances")
        RegisterRequirement("stance", "RequireStanceHandler", self)
    end,
    OnDisable = function(self)
        UnregisterRequirement("stance")
        self:UnregisterEvent("PLAYER_ALIVE")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
        self:UnregisterMessage("Ovale_SpellsChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    PLAYER_TALENT_UPDATE = function(self, event)
        self.stance = nil
        self:UpdateStances()
    end,
    UPDATE_SHAPESHIFT_FORM = function(self, event)
        self:ShapeshiftEventHandler()
    end,
    UPDATE_SHAPESHIFT_FORMS = function(self, event)
        self:ShapeshiftEventHandler()
    end,
    CreateStanceList = function(self)
        self:StartProfiling("OvaleStance_CreateStanceList")
        wipe(self.stanceList)
        wipe(self.stanceId)
        local _, name, stanceName
        for i = 1, GetNumShapeshiftForms(), 1 do
            _, name = GetShapeshiftFormInfo(i)
            stanceName = SPELL_NAME_TO_STANCE[name]
            if stanceName then
                self.stanceList[i] = stanceName
                self.stanceId[stanceName] = i
            end
        end
        self:StopProfiling("OvaleStance_CreateStanceList")
    end,
    DebugStances = function(self)
        wipe(array)
        for k, v in pairs(self.stanceList) do
            if self.stance == k then
                insert(array, v .. " (active)")
            else
                insert(array, v)
            end
        end
        sort(array)
        return concat(array, "\n")
    end,
    GetStance = function(self, stanceId)
        stanceId = stanceId or self.stance
        return self.stanceList[stanceId]
    end,
    IsStance = function(self, name)
        if name and self.stance then
            if type(name) == "number" then
                return name == self.stance
            else
                return name == __exports.OvaleStance:GetStance(self.stance)
            end
        end
        return false
    end,
    IsStanceSpell = function(self, spellId)
        local name = GetSpellInfo(spellId)
        return  not  not (name and SPELL_NAME_TO_STANCE[name])
    end,
    ShapeshiftEventHandler = function(self)
        self:StartProfiling("OvaleStance_ShapeshiftEventHandler")
        local oldStance = self.stance
        local newStance = GetShapeshiftForm()
        if oldStance ~= newStance then
            self.stance = newStance
            Ovale:needRefresh()
            self:SendMessage("Ovale_StanceChanged", self:GetStance(newStance), self:GetStance(oldStance))
        end
        self:StopProfiling("OvaleStance_ShapeshiftEventHandler")
    end,
    UpdateStances = function(self)
        self:CreateStanceList()
        self:ShapeshiftEventHandler()
        self.ready = true
    end,
    RequireStanceHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        local verified = false
        local stance = tokens
        if index then
            stance = tokens[index]
            index = index + 1
        end
        if stance then
            local isBang = false
            if sub(stance, 1, 1) == "!" then
                isBang = true
                stance = sub(stance, 2)
            end
            stance = tonumber(stance) or stance
            local isStance = self:IsStance(stance)
            if  not isBang and isStance or isBang and  not isStance then
                verified = true
            end
            local result = verified and "passed" or "FAILED"
            if isBang then
                self:Log("    Require NOT stance '%s': %s", stance, result)
            else
                self:Log("    Require stance '%s': %s", stance, result)
            end
        else
            Ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
        end
        return verified, requirement, index
    end,
})
__exports.OvaleStance = OvaleStanceClass()
