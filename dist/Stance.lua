local __exports = LibStub:NewLibrary("ovale/Stance", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
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
local __tools = LibStub:GetLibrary("ovale/tools")
local isString = __tools.isString
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local druidCatForm = GetSpellInfo(768)
local druidTravelForm = GetSpellInfo(783)
local druidAquaticForm = GetSpellInfo(1066)
local druidBearForm = GetSpellInfo(5487)
local druidMoonkinForm = GetSpellInfo(24858)
local druid_flight_form = GetSpellInfo(33943)
local druid_swift_flight_form = GetSpellInfo(40120)
local rogue_stealth = GetSpellInfo(1784)
local SPELL_NAME_TO_STANCE = {}
if druidCatForm then
    SPELL_NAME_TO_STANCE[druidCatForm] = "druid_cat_form"
end
if druidTravelForm then
    SPELL_NAME_TO_STANCE[druidTravelForm] = "druid_travel_form"
end
if druidAquaticForm then
    SPELL_NAME_TO_STANCE[druidAquaticForm] = "druid_aquatic_form"
end
if druidBearForm then
    SPELL_NAME_TO_STANCE[druidBearForm] = "druid_bear_form"
end
if druidMoonkinForm then
    SPELL_NAME_TO_STANCE[druidMoonkinForm] = "druid_moonkin_form"
end
if druid_flight_form then
    SPELL_NAME_TO_STANCE[druid_flight_form] = "druid_flight_form"
end
if druid_swift_flight_form then
    SPELL_NAME_TO_STANCE[druid_swift_flight_form] = "druid_swift_flight_form"
end
if rogue_stealth then
    SPELL_NAME_TO_STANCE[rogue_stealth] = "rogue_stealth"
end
__exports.STANCE_NAME = {
    druid_aquatic_form = true,
    druid_bear_form = true,
    druid_cat_form = true,
    druid_flight_form = true,
    druid_moonkin_form = true,
    druid_swift_flight_form = true,
    druid_travel_form = true,
    rogue_stealth = true
}
local array = {}
local StanceData = __class(nil, {
    constructor = function(self)
        self.stance = 0
    end
})
__exports.OvaleStanceClass = __class(States, {
    constructor = function(self, ovaleDebug, ovale, ovaleProfiler, ovaleData, requirement)
        self.ovale = ovale
        self.ovaleData = ovaleData
        self.requirement = requirement
        self.ready = false
        self.stanceList = {}
        self.stanceId = {}
        self.OnInitialize = function()
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.UpdateStances)
            self.module:RegisterEvent("UPDATE_SHAPESHIFT_FORM", self.UPDATE_SHAPESHIFT_FORM)
            self.module:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", self.UPDATE_SHAPESHIFT_FORMS)
            self.module:RegisterMessage("Ovale_SpellsChanged", self.UpdateStances)
            self.module:RegisterMessage("Ovale_TalentsChanged", self.UpdateStances)
            self.requirement:RegisterRequirement("stance", self.RequireStanceHandler)
        end
        self.OnDisable = function()
            self.requirement:UnregisterRequirement("stance")
            self.module:UnregisterEvent("PLAYER_ALIVE")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
            self.module:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
            self.module:UnregisterMessage("Ovale_SpellsChanged")
            self.module:UnregisterMessage("Ovale_TalentsChanged")
        end
        self.UPDATE_SHAPESHIFT_FORM = function(event)
            self:ShapeshiftEventHandler()
        end
        self.UPDATE_SHAPESHIFT_FORMS = function(event)
            self:ShapeshiftEventHandler()
        end
        self.UpdateStances = function()
            self:CreateStanceList()
            self:ShapeshiftEventHandler()
            self.ready = true
        end
        self.RequireStanceHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local stance = tokens[index]
            index = index + 1
            if stance then
                local isBang = false
                if isString(stance) and sub(stance, 1, 1) == "!" then
                    isBang = true
                    stance = sub(stance, 2)
                end
                stance = tonumber(stance) or stance
                local isStance = self:IsStance(stance, atTime)
                if  not isBang and isStance or isBang and  not isStance then
                    verified = true
                end
                local result = verified and "passed" or "FAILED"
                if isBang then
                    self.tracer:Log("    Require NOT stance '%s': %s", stance, result)
                else
                    self.tracer:Log("    Require stance '%s': %s", stance, result)
                end
            else
                self.ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
            end
            return verified, requirement, index
        end
        States.constructor(self, StanceData)
        self.module = ovale:createModule("OvaleStance", self.OnInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        self.tracer = ovaleDebug:create(self.module:GetName())
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
                            return self:DebugStances()
                        end
                    }
                }
            }
        }
        for k, v in pairs(debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
    end,
    CreateStanceList = function(self)
        self.profiler:StartProfiling("OvaleStance_CreateStanceList")
        wipe(self.stanceList)
        wipe(self.stanceId)
        local name, stanceName, spellId
        for i = 1, GetNumShapeshiftForms(), 1 do
            _, _, _, spellId = GetShapeshiftFormInfo(i)
            name = GetSpellInfo(spellId)
            if name then
                stanceName = SPELL_NAME_TO_STANCE[name]
                if stanceName then
                    self.stanceList[i] = stanceName
                    self.stanceId[stanceName] = i
                end
            end
        end
        self.profiler:StopProfiling("OvaleStance_CreateStanceList")
    end,
    DebugStances = function(self)
        wipe(array)
        for k, v in pairs(self.stanceList) do
            if self.current.stance == k then
                insert(array, v .. " (active)")
            else
                insert(array, v)
            end
        end
        sort(array)
        return concat(array, "\n")
    end,
    GetStance = function(self, stanceId)
        stanceId = stanceId or self.current.stance
        return self.stanceList[stanceId]
    end,
    IsStance = function(self, name, atTime)
        local state = self:GetState(atTime)
        if name and state.stance then
            if type(name) == "number" then
                return name == state.stance
            else
                return name == self:GetStance(state.stance)
            end
        end
        return false
    end,
    IsStanceSpell = function(self, spellId)
        local name = GetSpellInfo(spellId)
        return  not  not (name and SPELL_NAME_TO_STANCE[name])
    end,
    ShapeshiftEventHandler = function(self)
        self.profiler:StartProfiling("OvaleStance_ShapeshiftEventHandler")
        local oldStance = self.current.stance
        local newStance = GetShapeshiftForm()
        if oldStance ~= newStance then
            self.current.stance = newStance
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_StanceChanged", self:GetStance(newStance), self:GetStance(oldStance))
        end
        self.profiler:StopProfiling("OvaleStance_ShapeshiftEventHandler")
    end,
    InitializeState = function(self)
        self.next.stance = 0
    end,
    CleanState = function(self)
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvaleStance_ResetState")
        self.next.stance = self.current.stance
        self.profiler:StopProfiling("OvaleStance_ResetState")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvaleStance_ApplySpellAfterCast")
        local stance = self.ovaleData:GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID)
        if stance then
            if type(stance) == "string" then
                stance = self.stanceId[stance]
            end
            self.next.stance = stance
        end
        self.profiler:StopProfiling("OvaleStance_ApplySpellAfterCast")
    end,
})
