local __exports = LibStub:NewLibrary("ovale/Scripts", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local format = string.format
local gsub = string.gsub
local lower = string.lower
local pairs = pairs
local kpairs = pairs
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
local GetNumSpecializations = GetNumSpecializations
__exports.DEFAULT_NAME = "Ovale"
local DEFAULT_DESCRIPTION = L["Script défaut"]
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = L["Script personnalisé"]
local DISABLED_NAME = "Disabled"
local DISABLED_DESCRIPTION = L["Disabled"]
__exports.OvaleScriptsClass = __class(nil, {
    constructor = function(self, ovale, ovaleOptions, ovalePaperDoll, ovaleDebug)
        self.ovale = ovale
        self.ovaleOptions = ovaleOptions
        self.ovalePaperDoll = ovalePaperDoll
        self.script = {}
        self.OnInitialize = function()
            self:CreateOptions()
            self:RegisterScript(nil, nil, __exports.DEFAULT_NAME, DEFAULT_DESCRIPTION, nil, "script")
            self:RegisterScript(self.ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, self.ovaleOptions.db.profile.code, "script")
            self:RegisterScript(nil, nil, DISABLED_NAME, DISABLED_DESCRIPTION, nil, "script")
            self.module:RegisterMessage("Ovale_ScriptChanged", self.InitScriptProfiles)
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_ScriptChanged")
        end
        self.InitScriptProfiles = function()
            local countSpecializations = GetNumSpecializations(false, false)
            if  not isLuaArray(self.ovaleOptions.db.profile.source) then
                self.ovaleOptions.db.profile.source = {}
            end
            for i = 1, countSpecializations, 1 do
                local specName = self.ovalePaperDoll:GetSpecialization(i)
                if specName then
                    self.ovaleOptions.db.profile.source[self.ovale.playerClass .. "_" .. specName] = self.ovaleOptions.db.profile.source[self.ovale.playerClass .. "_" .. specName] or self:GetDefaultScriptName(self.ovale.playerClass, specName)
                end
            end
        end
        self.module = ovale:createModule("OvaleScripts", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
        local defaultDB = {
            code = "",
            source = {},
            showHiddenScripts = false
        }
        local actions = {
            code = {
                name = L["Code"],
                type = "execute",
                func = function()
                    local appName = self.module:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 700, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        for k, v in kpairs(defaultDB) do
            (ovaleOptions.defaultDB.profile)[k] = v
        end
        for k, v in pairs(actions) do
            ovaleOptions.actions.args[k] = v
        end
        ovaleOptions:RegisterOptions(self)
    end,
    GetDescriptions = function(self, scriptType)
        local descriptionsTable = {}
        for name, script in pairs(self.script) do
            if ( not scriptType or script.type == scriptType) and ( not script.className or script.className == self.ovale.playerClass) and ( not script.specialization or self.ovalePaperDoll:IsSpecialization(script.specialization)) then
                if name == __exports.DEFAULT_NAME then
                    descriptionsTable[name] = script.desc .. " (" .. self:GetScriptName(name) .. ")"
                else
                    descriptionsTable[name] = script.desc or "No description"
                end
            end
        end
        return descriptionsTable
    end,
    RegisterScript = function(self, className, specialization, name, description, code, scriptType)
        self.script[name] = self.script[name] or {}
        local script = self.script[name]
        script.type = scriptType or "script"
        script.desc = description or name
        script.specialization = specialization
        script.code = code or ""
        script.className = className
    end,
    UnregisterScript = function(self, name)
        self.script[name] = nil
    end,
    SetScript = function(self, name)
        local oldSource = self:getCurrentSpecScriptName()
        if oldSource ~= name then
            self:setCurrentSpecScriptName(name)
            self.module:SendMessage("Ovale_ScriptChanged")
        end
    end,
    GetDefaultScriptName = function(self, className, specialization)
        local name = nil
        local scClassName = lower(className)
        if className == "DEMONHUNTER" then
            scClassName = "demon_hunter"
        elseif className == "DEATHKNIGHT" then
            scClassName = "death_knight"
        end
        if specialization then
            name = format("sc_t25_%s_%s", scClassName, specialization)
            if  not self.script[name] then
                self.tracer:Log("Script " .. name .. " not found")
                name = DISABLED_NAME
            end
        else
            return DISABLED_NAME
        end
        return name
    end,
    GetScriptName = function(self, name)
        return ((name == __exports.DEFAULT_NAME and self:GetDefaultScriptName(self.ovale.playerClass, self.ovalePaperDoll:GetSpecialization())) or name)
    end,
    GetScript = function(self, name)
        name = self:GetScriptName(name)
        if name and self.script[name] then
            return self.script[name].code
        end
        return nil
    end,
    GetScriptOrDefault = function(self, name)
        return (self:GetScript(name) or self:GetScript(self:GetDefaultScriptName(self.ovale.playerClass, self.ovalePaperDoll:GetSpecialization())))
    end,
    getCurrentSpecIdentifier = function(self)
        return self.ovale.playerClass .. "_" .. self.ovalePaperDoll:GetSpecialization()
    end,
    getCurrentSpecScriptName = function(self)
        return self.ovaleOptions.db.profile.source[self:getCurrentSpecIdentifier()]
    end,
    setCurrentSpecScriptName = function(self, source)
        self.ovaleOptions.db.profile.source[self:getCurrentSpecIdentifier()] = source
    end,
    CreateOptions = function(self)
        local options = {
            name = self.ovale:GetName() .. " " .. L["Script"],
            type = "group",
            args = {
                source = {
                    order = 10,
                    type = "select",
                    name = L["Script"],
                    width = "double",
                    values = function(info)
                        local scriptType = ( not self.ovaleOptions.db.profile.showHiddenScripts and "script") or nil
                        return self:GetDescriptions(scriptType)
                    end,
                    get = function(info)
                        return self:getCurrentSpecScriptName()
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
                        return self:getCurrentSpecScriptName() ~= CUSTOM_NAME
                    end,
                    get = function(info)
                        local code = self:GetScript(self:getCurrentSpecScriptName()) or ""
                        return gsub(code, "	", "    ")
                    end,
                    set = function(info, v)
                        self:RegisterScript(self.ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
                        self.ovaleOptions.db.profile.code = v
                        self.module:SendMessage("Ovale_ScriptChanged")
                    end
                },
                copy = {
                    order = 30,
                    type = "execute",
                    name = L["Copier sur Script personnalisé"],
                    disabled = function()
                        return self:getCurrentSpecScriptName() == CUSTOM_NAME
                    end,
                    confirm = function()
                        return L["Ecraser le Script personnalisé préexistant?"]
                    end,
                    func = function()
                        local code = self:GetScript(self:getCurrentSpecScriptName())
                        self:RegisterScript(self.ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
                        self:setCurrentSpecScriptName(CUSTOM_NAME)
                        local script = self:GetScript(CUSTOM_NAME)
                        if script then
                            self.ovaleOptions.db.profile.code = script
                        end
                        self.module:SendMessage("Ovale_ScriptChanged")
                    end
                },
                showHiddenScripts = {
                    order = 40,
                    type = "toggle",
                    name = L["Show hidden"],
                    get = function(info)
                        return self.ovaleOptions.db.profile.showHiddenScripts
                    end,
                    set = function(info, value)
                        self.ovaleOptions.db.profile.showHiddenScripts = value
                    end
                }
            }
        }
        local appName = self.module:GetName()
        AceConfig:RegisterOptionsTable(appName, options)
        AceConfigDialog:AddToBlizOptions(appName, L["Script"], self.ovale:GetName())
    end,
})
