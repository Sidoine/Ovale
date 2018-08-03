local __exports = LibStub:NewLibrary("ovale/Scripts", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local format = string.format
local gsub = string.gsub
local lower = string.lower
local pairs = pairs
local OvaleScriptsBase = Ovale:NewModule("OvaleScripts", aceEvent)
local DEFAULT_NAME = "Ovale"
local DEFAULT_DESCRIPTION = L["Script défaut"]
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = L["Script personnalisé"]
local DISABLED_NAME = "Disabled"
local DISABLED_DESCRIPTION = L["Disabled"]
do
    local defaultDB = {
        code = "",
        source = "Ovale",
        showHiddenScripts = false
    }
    local actions = {
        code = {
            name = L["Code"],
            type = "execute",
            func = function()
                local appName = __exports.OvaleScripts:GetName()
                AceConfigDialog:SetDefaultSize(appName, 700, 550)
                AceConfigDialog:Open(appName)
            end

        }
    }
    for k, v in pairs(defaultDB) do
        OvaleOptions.defaultDB.profile[k] = v
    end
    for k, v in pairs(actions) do
        OvaleOptions.options.args.actions.args[k] = v
    end
    OvaleOptions:RegisterOptions(__exports.OvaleScripts)
end
local OvaleScriptsClass = __class(OvaleScriptsBase, {
    constructor = function(self)
        self.script = {}
        OvaleScriptsBase.constructor(self)
    end,
    OnInitialize = function(self)
        self:CreateOptions()
        self:RegisterScript(nil, nil, DEFAULT_NAME, DEFAULT_DESCRIPTION, nil, "script")
        self:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script")
        self:RegisterScript(nil, nil, DISABLED_NAME, DISABLED_DESCRIPTION, nil, "script")
        self:RegisterMessage("Ovale_StanceChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_StanceChanged")
    end,
    Ovale_StanceChanged = function(self, event, newStance, oldStance)
    end,
    GetDescriptions = function(self, scriptType)
        local descriptionsTable = {}
        for name, script in pairs(self.script) do
            if ( not scriptType or script.type == scriptType) and ( not script.specialization or OvalePaperDoll:IsSpecialization(script.specialization) or script.specialization == "all") then
                if name == DEFAULT_NAME then
                    descriptionsTable[name] = script.desc .. " (" .. self:GetScriptName(name) .. ")"
                else
                    descriptionsTable[name] = script.desc
                end
            end
        end
        return descriptionsTable
    end,
    RegisterScript = function(self, className, specialization, name, description, code, scriptType)
        if  not className or className == Ovale.playerClass then
            self.script[name] = self.script[name] or {}
            local script = self.script[name]
            script.type = scriptType or "script"
            script.desc = description or name
            script.specialization = specialization
            script.code = code or ""
        end
    end,
    UnregisterScript = function(self, name)
        self.script[name] = nil
    end,
    SetScript = function(self, name)
        local oldSource = Ovale.db.profile.source
        if oldSource ~= name then
            Ovale.db.profile.source = name
            self:SendMessage("Ovale_ScriptChanged")
        end
    end,
    GetDefaultScriptName = function(self, className, specialization)
        local name
        if className == "DEATHKNIGHT" then
            if specialization == "blood" then
                name = "icyveins_deathknight_blood"
            elseif specialization == "frost" then
                name = "sc_death_knight_frost_t19"
            elseif specialization == "unholy" then
                name = "sc_death_knight_unholy_t19"
            end
        elseif className == "DEMONHUNTER" then
            if specialization == "vengeance" then
                name = "icyveins_demonhunter_vengeance"
            elseif specialization == "havoc" then
                name = "sc_demon_hunter_havoc_t19"
            end
        elseif className == "DRUID" then
            if specialization == "restoration" then
                name = DISABLED_NAME
            elseif specialization == "guardian" then
                name = "icyveins_druid_guardian"
            elseif specialization == "feral" then
                name = "shmoodude_druid_feral"
            end
        elseif className == "MONK" then
            if specialization == "mistweaver" then
                name = DISABLED_NAME
            elseif specialization == "brewmaster" then
                name = "icyveins_monk_brewmaster"
            end
        elseif className == "PALADIN" then
            if specialization == "holy" then
                name = "icyveins_paladin_holy"
            elseif specialization == "protection" then
                name = "icyveins_paladin_protection"
            end
        elseif className == "PRIEST" then
            if specialization == "discipline" then
                name = "icyveins_priest_discipline"
            elseif specialization == "holy" then
                name = DISABLED_NAME
            end
        elseif className == "SHAMAN" then
            if specialization == "restoration" then
                name = DISABLED_NAME
            end
        elseif className == "WARRIOR" then
            if specialization == "protection" then
                name = "icyveins_warrior_protection"
            end
        end
        if  not name and specialization then
            name = format("sc_%s_%s_t19", lower(className), specialization)
        end
        if  not (name and self.script[name]) then
            name = DISABLED_NAME
        end
        return name
    end,
    GetScriptName = function(self, name)
        return (name == DEFAULT_NAME) and self:GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll:GetSpecialization()) or name
    end,
    GetScript = function(self, name)
        name = self:GetScriptName(name)
        if name and self.script[name] then
            return self.script[name].code
        end
    end,
    CreateOptions = function(self)
        local options = {
            name = Ovale:GetName() .. " " .. L["Script"],
            type = "group",
            args = {
                source = {
                    order = 10,
                    type = "select",
                    name = L["Script"],
                    width = "double",
                    values = function(info)
                        local scriptType =  not Ovale.db.profile.showHiddenScripts and "script"
                        return __exports.OvaleScripts:GetDescriptions(scriptType)
                    end,
                    get = function(info)
                        return Ovale.db.profile.source
                    end,
                    set = function(info, v)
                        self:SetScript(v)
                    end
                },
                script = {
                    order = 20,
                    type = "input",
                    multiline = 25,
                    name = L["Script"],
                    width = "full",
                    disabled = function()
                        return Ovale.db.profile.source ~= CUSTOM_NAME
                    end,
                    get = function(info)
                        local code = __exports.OvaleScripts:GetScript(Ovale.db.profile.source)
                        code = code or ""
                        return gsub(code, "	", "    ")
                    end,
                    set = function(info, v)
                        __exports.OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
                        Ovale.db.profile.code = v
                        self:SendMessage("Ovale_ScriptChanged")
                    end
                },
                copy = {
                    order = 30,
                    type = "execute",
                    name = L["Copier sur Script personnalisé"],
                    disabled = function()
                        return Ovale.db.profile.source == CUSTOM_NAME
                    end,
                    confirm = function()
                        return L["Ecraser le Script personnalisé préexistant?"]
                    end,
                    func = function()
                        local code = __exports.OvaleScripts:GetScript(Ovale.db.profile.source)
                        __exports.OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
                        Ovale.db.profile.source = CUSTOM_NAME
                        Ovale.db.profile.code = __exports.OvaleScripts:GetScript(CUSTOM_NAME)
                        self:SendMessage("Ovale_ScriptChanged")
                    end
                },
                showHiddenScripts = {
                    order = 40,
                    type = "toggle",
                    name = L["Show hidden"],
                    get = function(info)
                        return Ovale.db.profile.showHiddenScripts
                    end,
                    set = function(info, value)
                        Ovale.db.profile.showHiddenScripts = value
                    end
                }
            }
        }
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, options)
        AceConfigDialog:AddToBlizOptions(appName, L["Script"], Ovale:GetName())
    end,
})
__exports.OvaleScripts = OvaleScriptsClass()
