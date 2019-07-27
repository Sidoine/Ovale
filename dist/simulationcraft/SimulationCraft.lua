local __exports = LibStub:NewLibrary("ovale/simulationcraft/SimulationCraft", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Controls = LibStub:GetLibrary("ovale/Controls")
local ResetControls = __Controls.ResetControls
local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local lower = string.lower
local match = string.match
local sub = string.sub
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local type = type
local wipe = wipe
local kpairs = pairs
local concat = table.concat
local insert = table.insert
local sort = table.sort
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
local __definitions = LibStub:GetLibrary("ovale/simulationcraft/definitions")
local Annotation = __definitions.Annotation
local CONSUMABLE_ITEMS = __definitions.CONSUMABLE_ITEMS
local OVALE_TAGS = __definitions.OVALE_TAGS
local classInfos = __definitions.classInfos
local __texttools = LibStub:GetLibrary("ovale/simulationcraft/text-tools")
local print_r = __texttools.print_r
local OvaleFunctionName = __texttools.OvaleFunctionName
local OvaleTaggedFunctionName = __texttools.OvaleTaggedFunctionName
local self_outputPool = __texttools.self_outputPool
local CamelSpecialization = __texttools.CamelSpecialization
local CamelCase = __texttools.CamelCase
local __generator = LibStub:GetLibrary("ovale/simulationcraft/generator")
local Mark = __generator.Mark
local Sweep = __generator.Sweep
local self_lastSimC = nil
local self_lastScript = nil
local name = "OvaleSimulationCraft"
__exports.OvaleSimulationCraftClass = __class(nil, {
    constructor = function(self, ovaleOptions, ovaleData, emiter, ovaleAst, parser, unparser, ovaleDebug, ovaleCompile, splitter, generator, ovale)
        self.ovaleOptions = ovaleOptions
        self.ovaleData = ovaleData
        self.emiter = emiter
        self.ovaleAst = ovaleAst
        self.parser = parser
        self.unparser = unparser
        self.ovaleDebug = ovaleDebug
        self.ovaleCompile = ovaleCompile
        self.splitter = splitter
        self.generator = generator
        self.ovale = ovale
        self.OnInitialize = function()
            self.emiter:InitializeDisambiguation()
            self:CreateOptions()
        end
        self.handleDisable = function()
        end
        self:registerOptions()
        self.module = ovale:createModule("OvaleSimulationCraft", self.OnInitialize, self.handleDisable)
        self.tracer = ovaleDebug:create("")
    end,
    AddSymbol = function(self, annotation, symbol)
        local symbolTable = annotation.symbolTable or {}
        local symbolList = annotation.symbolList or {}
        if  not symbolTable[symbol] and  not self.ovaleData.DEFAULT_SPELL_LIST[symbol] then
            symbolTable[symbol] = true
            symbolList[#symbolList + 1] = symbol
        end
        annotation.symbolTable = symbolTable
        annotation.symbolList = symbolList
    end,
    registerOptions = function(self)
        local actions = {
            simc = {
                name = "SimulationCraft",
                type = "execute",
                func = function()
                    local appName = name
                    AceConfigDialog:SetDefaultSize(appName, 700, 550)
                    AceConfigDialog:Open(appName)
                end

            }
        }
        for k, v in pairs(actions) do
            self.ovaleOptions.options.args.actions.args[k] = v
        end
        local defaultDB = {
            overrideCode = ""
        }
        for k, v in pairs(defaultDB) do
            (self.ovaleOptions.defaultDB.profile)[k] = v
        end
    end,
    ToString = function(self, tbl)
        local output = print_r(tbl)
        return concat(output, "\n")
    end,
    Release = function(self, profile)
        if profile.annotation then
            local annotation = profile.annotation
            if annotation.astAnnotation then
                self.ovaleAst:ReleaseAnnotation(annotation.astAnnotation)
            end
            if annotation.nodeList then
                self.parser:release(annotation.nodeList)
            end
            for key, value in kpairs(annotation) do
                if type(value) == "table" then
                    wipe(value)
                end
                annotation[key] = nil
            end
            profile.annotation = nil
        end
        profile.actionList = nil
    end,
    ParseProfile = function(self, simc, annotation)
        local profile = {}
        for _line in gmatch(simc, "[^\r\n]+") do
            local line = match(_line, "^%s*(.-)%s*$")
            if  not (match(line, "^#.*") or match(line, "^$")) then
                local k, operator, value = match(line, "([^%+=]+)(%+?=)(.*)")
                local key = k
                if operator == "=" then
                    (profile)[key] = value
                elseif operator == "+=" then
                    if type(profile[key]) ~= "table" then
                        local oldValue = profile[key]
                        profile[key] = {}
                        insert(profile[key], oldValue)
                    end
                    insert(profile[key], value)
                end
            end
        end
        for k, v in kpairs(profile) do
            if isLuaArray(v) then
                (profile)[k] = concat(v)
            end
        end
        profile.templates = {}
        for k in kpairs(profile) do
            if sub(k, 1, 2) == "$(" and sub(k, -1) == ")" then
                insert(profile.templates, k)
            end
        end
        local ok = true
        annotation = annotation or Annotation(self.ovaleData)
        local nodeList = {}
        local actionList = {}
        for k, _v in kpairs(profile) do
            local v = _v
            if ok and match(k, "^actions") then
                local name = match(k, "^actions%.([%w_]+)")
                if  not name then
                    name = "_default"
                end
                for index = #profile.templates, 1, -1 do
                    local template = profile.templates[index]
                    local variable = sub(template, 3, -2)
                    local pattern = "%$%(" .. variable .. "%)"
                    v = gsub(v, pattern, profile[template])
                end
                local node
                ok, node = self.parser:ParseActionList(name, v, nodeList, annotation)
                if ok then
                    actionList[#actionList + 1] = node
                else
                    break
                end
            end
        end
        sort(actionList, function(a, b)
            return a.name < b.name
        end
)
        for className in kpairs(RAID_CLASS_COLORS) do
            local lowerClass = lower(className)
            if profile[lowerClass] then
                annotation.class = className
                annotation.name = profile[lowerClass]
            end
        end
        annotation.specialization = profile.spec
        annotation.level = profile.level
        ok = ok and (annotation.class ~= nil and annotation.specialization ~= nil and annotation.level ~= nil)
        annotation.pet = profile.default_pet
        local consumables = {}
        for k, v in pairs(CONSUMABLE_ITEMS) do
            if v then
                if profile[k] ~= nil then
                    consumables[k] = profile[k]
                end
            end
        end
        annotation.consumables = consumables
        if profile.role == "tank" then
            annotation.role = profile.role
            annotation.melee = annotation.class
        elseif profile.role == "spell" then
            annotation.role = profile.role
            annotation.ranged = annotation.class
        elseif profile.role == "attack" or profile.role == "dps" then
            annotation.role = "attack"
            if profile.position == "ranged_back" then
                annotation.ranged = annotation.class
            else
                annotation.melee = annotation.class
            end
        end
        annotation.position = profile.position
        local taggedFunctionName = {}
        for _, node in ipairs(actionList) do
            local fname = OvaleFunctionName(node.name, annotation)
            taggedFunctionName[fname] = true
            for _, tag in pairs(OVALE_TAGS) do
                local bodyName, conditionName = OvaleTaggedFunctionName(fname, tag)
                taggedFunctionName[bodyName] = true
                taggedFunctionName[conditionName] = true
            end
        end
        annotation.taggedFunctionName = taggedFunctionName
        annotation.functionTag = {}
        profile.actionList = actionList
        profile.annotation = annotation
        annotation.nodeList = nodeList
        if  not ok then
            self:Release(profile)
            profile = nil
        end
        return profile
    end,
    Unparse = function(self, profile)
        local output = self_outputPool:Get()
        if profile.actionList then
            for _, node in ipairs(profile.actionList) do
                output[#output + 1] = self.unparser:Unparse(node)
            end
        end
        local s = concat(output, "\n")
        self_outputPool:Release(output)
        return s
    end,
    EmitAST = function(self, profile)
        local nodeList = {}
        local ast = self.ovaleAst:NewNode(nodeList, true)
        local child = ast.child
        ast.type = "script"
        local annotation = profile.annotation
        local ok = true
        if profile.actionList then
            annotation.astAnnotation = annotation.astAnnotation or {}
            annotation.astAnnotation.nodeList = nodeList
            local dictionaryAST
            do
                self.ovaleDebug:ResetTrace()
                local dictionaryAnnotation = {
                    nodeList = {},
                    definition = profile.annotation.dictionary
                }
                local dictionaryFormat = [[
				Include(ovale_common)
				Include(ovale_trinkets_mop)
				Include(ovale_trinkets_wod)
				Include(ovale_%s_spells)
				%s
			]]
                local dictionaryCode = format(dictionaryFormat, lower(annotation.class), (self.ovaleOptions.db.profile.overrideCode) or "")
                dictionaryAST = self.ovaleAst:ParseCode("script", dictionaryCode, dictionaryAnnotation.nodeList, dictionaryAnnotation)
                if dictionaryAST then
                    dictionaryAST.annotation = dictionaryAnnotation
                    annotation.dictionaryAST = dictionaryAST
                    annotation.dictionary = dictionaryAnnotation.definition
                    self.ovaleAst:PropagateConstants(dictionaryAST)
                    self.ovaleAst:PropagateStrings(dictionaryAST)
                    self.ovaleAst:FlattenParameters(dictionaryAST)
                    ResetControls()
                    self.ovaleCompile:EvaluateScript(dictionaryAST, true)
                end
            end
            for _, node in ipairs(profile.actionList) do
                local addFunctionNode = self.emiter.EmitActionList(node, nodeList, annotation, nil)
                if addFunctionNode then
                    if node.name == "_default" and  not annotation.interrupt then
                        local defaultInterrupt = classInfos[annotation.class][annotation.specialization]
                        if defaultInterrupt and defaultInterrupt.interrupt then
                            local interruptCall = self.ovaleAst:NewNode(nodeList)
                            interruptCall.type = "custom_function"
                            interruptCall.name = CamelSpecialization(annotation) .. "InterruptActions"
                            annotation.interrupt = annotation.class
                            annotation[defaultInterrupt.interrupt] = annotation.class
                            insert(addFunctionNode.child[1].child, 1, interruptCall)
                        end
                    end
                    local actionListName = gsub(node.name, "^_+", "")
                    local commentNode = self.ovaleAst:NewNode(nodeList)
                    commentNode.type = "comment"
                    commentNode.comment = "## actions." .. actionListName
                    child[#child + 1] = commentNode
                    for _, tag in pairs(OVALE_TAGS) do
                        local bodyNode, conditionNode = self.splitter.SplitByTag(tag, addFunctionNode, nodeList, annotation)
                        child[#child + 1] = bodyNode
                        child[#child + 1] = conditionNode
                    end
                else
                    ok = false
                    break
                end
            end
        end
        if ok then
            annotation.supportingFunctionCount = self.generator:InsertSupportingFunctions(child, annotation)
            annotation.supportingInterruptCount = annotation.interrupt and self.generator:InsertInterruptFunctions(child, annotation)
            annotation.supportingControlCount = self.generator:InsertSupportingControls(child, annotation)
            self.generator:InsertVariables(child, annotation)
            local className, specialization = annotation.class, annotation.specialization
            local lowerclass = lower(className)
            local aoeToggle = "opt_" .. lowerclass .. "_" .. specialization .. "_aoe"
            do
                local commentNode = self.ovaleAst:NewNode(nodeList)
                commentNode.type = "comment"
                commentNode.comment = "## " .. CamelCase(specialization) .. " icons."
                insert(child, commentNode)
                local code = format("AddCheckBox(%s L(AOE) default specialization=%s)", aoeToggle, specialization)
                local node = self.ovaleAst:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=shortcd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, self.generator:GenerateIconBody("shortcd", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=%s help=shortcd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, self.generator:GenerateIconBody("shortcd", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon enemies=1 help=main specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, specialization, self.generator:GenerateIconBody("main", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=%s help=aoe specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, self.generator:GenerateIconBody("main", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=cd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, self.generator:GenerateIconBody("cd", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=%s help=cd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, self.generator:GenerateIconBody("cd", profile))
                local node = self.ovaleAst:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            Mark(ast)
            local changed = Sweep(ast)
            while changed do
                Mark(ast)
                changed = Sweep(ast)
            end
            Mark(ast)
            Sweep(ast)
        end
        if  not ok then
            self.ovaleAst:Release(ast)
            ast = nil
        end
        return ast
    end,
    Emit = function(self, profile, noFinalNewLine)
        local ast = self:EmitAST(profile)
        local annotation = profile.annotation
        local className = annotation.class
        local lowerclass = lower(className)
        local specialization = annotation.specialization
        local output = self_outputPool:Get()
        do
            output[#output + 1] = "# Based on SimulationCraft profile " .. annotation.name .. "."
            output[#output + 1] = "#	class=" .. lowerclass
            output[#output + 1] = "#	spec=" .. specialization
            if profile.talents then
                output[#output + 1] = "#	talents=" .. profile.talents
            end
            if profile.glyphs then
                output[#output + 1] = "#	glyphs=" .. profile.glyphs
            end
            if profile.default_pet then
                output[#output + 1] = "#	pet=" .. profile.default_pet
            end
        end
        do
            output[#output + 1] = ""
            output[#output + 1] = "Include(ovale_common)"
            output[#output + 1] = "Include(ovale_trinkets_mop)"
            output[#output + 1] = "Include(ovale_trinkets_wod)"
            output[#output + 1] = format("Include(ovale_%s_spells)", lowerclass)
            local overrideCode = self.ovaleOptions.db.profile.overrideCode
            if overrideCode and overrideCode ~= "" then
                output[#output + 1] = ""
                output[#output + 1] = "# Overrides."
                output[#output + 1] = overrideCode
            end
            if annotation.supportingControlCount > 0 then
                output[#output + 1] = ""
            end
        end
        output[#output + 1] = self.ovaleAst:Unparse(ast)
        if profile.annotation.symbolTable then
            output[#output + 1] = ""
            output[#output + 1] = "### Required symbols"
            sort(profile.annotation.symbolList)
            for _, symbol in ipairs(profile.annotation.symbolList) do
                if  not tonumber(symbol) and profile.annotation.dictionary and  not profile.annotation.dictionary[symbol] and  not self.ovaleData.buffSpellList[symbol] then
                    self.tracer:Print("Warning: Symbol '%s' not defined", symbol)
                end
                output[#output + 1] = "# " .. symbol
            end
        end
        annotation.dictionary = nil
        if annotation.dictionaryAST then
            self.ovaleAst:Release(annotation.dictionaryAST)
        end
        if  not noFinalNewLine and output[#output] ~= "" then
            output[#output + 1] = ""
        end
        local s = concat(output, "\n")
        self_outputPool:Release(output)
        self.ovaleAst:Release(ast)
        return s
    end,
    CreateOptions = function(self)
        local options = {
            name = self.ovale:GetName() .. " SimulationCraft",
            type = "group",
            args = {
                input = {
                    order = 10,
                    name = L["Input"],
                    type = "group",
                    args = {
                        description = {
                            order = 10,
                            name = L["The contents of a SimulationCraft profile."] .. "\nhttps://code.google.com/p/simulationcraft/source/browse/profiles",
                            type = "description"
                        },
                        input = {
                            order = 20,
                            name = L["SimulationCraft Profile"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function()
                                return self_lastSimC
                            end,
                            set = function(info, value)
                                self_lastSimC = value
                                local profile = self:ParseProfile(self_lastSimC)
                                local code = ""
                                if profile then
                                    code = self:Emit(profile)
                                end
                                self_lastScript = gsub(code, "	", "    ")
                            end
                        }
                    }
                },
                overrides = {
                    order = 20,
                    name = L["Overrides"],
                    type = "group",
                    args = {
                        description = {
                            order = 10,
                            name = L["SIMULATIONCRAFT_OVERRIDES_DESCRIPTION"],
                            type = "description"
                        },
                        overrides = {
                            order = 20,
                            name = L["Overrides"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function()
                                local code = self.ovaleOptions.db.profile.code
                                return gsub(code, "	", "    ")
                            end,
                            set = function(info, value)
                                self.ovaleOptions.db.profile.overrideCode = value
                                if self_lastSimC then
                                    local profile = self:ParseProfile(self_lastSimC)
                                    local code = ""
                                    if profile then
                                        code = self:Emit(profile)
                                    end
                                    self_lastScript = gsub(code, "	", "    ")
                                end
                            end
                        }
                    }
                },
                output = {
                    order = 30,
                    name = L["Output"],
                    type = "group",
                    args = {
                        description = {
                            order = 10,
                            name = L["The script translated from the SimulationCraft profile."],
                            type = "description"
                        },
                        output = {
                            order = 20,
                            name = L["Script"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function()
                                return self_lastScript
                            end

                        }
                    }
                }
            }
        }
        local appName = self.module:GetName()
        AceConfig:RegisterOptionsTable(appName, options)
        AceConfigDialog:AddToBlizOptions(appName, "SimulationCraft", self.ovale:GetName())
    end,
})
