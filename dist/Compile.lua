local __exports = LibStub:NewLibrary("ovale/Compile", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __AST = LibStub:GetLibrary("ovale/AST")
local PARAMETER_KEYWORD = __AST.PARAMETER_KEYWORD
local __Power = LibStub:GetLibrary("ovale/Power")
local POWER_TYPES = __Power.POWER_TYPES
local __Controls = LibStub:GetLibrary("ovale/Controls")
local checkBoxes = __Controls.checkBoxes
local lists = __Controls.lists
local ResetControls = __Controls.ResetControls
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local wipe = wipe
local kpairs = pairs
local find = string.find
local match = string.match
local sub = string.sub
local insert = table.insert
local GetSpellInfo = GetSpellInfo
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
local checkToken = __tools.checkToken
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"
__exports.OvaleCompileClass = __class(nil, {
    constructor = function(self, ovaleAzerite, ovaleEquipment, ovaleAst, ovaleCondition, ovaleCooldown, ovalePaperDoll, ovaleData, ovaleProfiler, ovaleDebug, ovaleOptions, ovale, ovaleScore, ovaleSpellBook, ovaleStance)
        self.ovaleAzerite = ovaleAzerite
        self.ovaleEquipment = ovaleEquipment
        self.ovaleAst = ovaleAst
        self.ovaleCondition = ovaleCondition
        self.ovaleCooldown = ovaleCooldown
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleData = ovaleData
        self.ovaleDebug = ovaleDebug
        self.ovaleOptions = ovaleOptions
        self.ovale = ovale
        self.ovaleScore = ovaleScore
        self.ovaleSpellBook = ovaleSpellBook
        self.ovaleStance = ovaleStance
        self.serial = nil
        self.ast = nil
        self.compileOnStances = false
        self.self_serial = 0
        self.timesEvaluated = 0
        self.icon = {}
        self.TestConditionLevel = function(value)
            return self.ovalePaperDoll.level >= value
        end
        self.TestConditionMaxLevel = function(value)
            return self.ovalePaperDoll.level <= value
        end
        self.TestConditionSpecialization = function(value)
            local spec, required = self:RequireValue(value)
            local isSpec = self.ovalePaperDoll:IsSpecialization(spec)
            return (required and isSpec) or ( not required and  not isSpec)
        end
        self.TestConditionStance = function(value)
            self.compileOnStances = true
            local stance, required = self:RequireValue(value)
            local isStance = self.ovaleStance:IsStance(stance, nil)
            return (required and isStance) or ( not required and  not isStance)
        end
        self.TestConditionSpell = function(value)
            local spell, required = self:RequireValue(value)
            local hasSpell = self.ovaleSpellBook:IsKnownSpell(spell)
            return (required and hasSpell) or ( not required and  not hasSpell)
        end
        self.TestConditionTalent = function(value)
            local talent, required = self:RequireNumber(value)
            local hasTalent = self:HasTalent(talent)
            return (required and hasTalent) or ( not required and  not hasTalent)
        end
        self.TestConditionEquipped = function(value)
            local item, required = self:RequireValue(value)
            local hasItemEquipped = self.ovaleEquipment:HasEquippedItem(item)
            return (required and hasItemEquipped and true) or ( not required and  not hasItemEquipped)
        end
        self.TestConditionTrait = function(value)
            local trait, required = self:RequireNumber(value)
            local hasTrait = self.ovaleAzerite:HasTrait(trait)
            return (required and hasTrait) or ( not required and  not hasTrait)
        end
        self.TEST_CONDITION_DISPATCH = {
            if_spell = self.TestConditionSpell,
            if_equipped = self.TestConditionEquipped,
            if_stance = self.TestConditionStance,
            level = self.TestConditionLevel,
            maxLevel = self.TestConditionMaxLevel,
            specialization = self.TestConditionSpecialization,
            talent = self.TestConditionTalent,
            trait = self.TestConditionTrait,
            pertrait = self.TestConditionTrait
        }
        self.trinket = {}
        self.OnInitialize = function()
            self.module:RegisterMessage("Ovale_CheckBoxValueChanged", self.ScriptControlChanged)
            self.module:RegisterMessage("Ovale_EquipmentChanged", self.EventHandler)
            self.module:RegisterMessage("Ovale_ListValueChanged", self.ScriptControlChanged)
            self.module:RegisterMessage("Ovale_ScriptChanged", self.Ovale_ScriptChanged)
            self.module:RegisterMessage("Ovale_SpecializationChanged", self.Ovale_ScriptChanged)
            self.module:RegisterMessage("Ovale_SpellsChanged", self.EventHandler)
            self.module:RegisterMessage("Ovale_StanceChanged", self.Ovale_StanceChanged)
            self.module:RegisterMessage("Ovale_TalentsChanged", self.EventHandler)
            self.module:SendMessage("Ovale_ScriptChanged")
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_CheckBoxValueChanged")
            self.module:UnregisterMessage("Ovale_EquipmentChanged")
            self.module:UnregisterMessage("Ovale_ListValueChanged")
            self.module:UnregisterMessage("Ovale_ScriptChanged")
            self.module:UnregisterMessage("Ovale_SpecializationChanged")
            self.module:UnregisterMessage("Ovale_SpellsChanged")
            self.module:UnregisterMessage("Ovale_StanceChanged")
            self.module:UnregisterMessage("Ovale_TalentsChanged")
        end
        self.Ovale_ScriptChanged = function(event)
            self:CompileScript(self.ovaleOptions.db.profile.source[self.ovale.playerClass .. "_" .. self.ovalePaperDoll:GetSpecialization()])
            self.EventHandler(event)
        end
        self.Ovale_StanceChanged = function(event)
            if self.compileOnStances then
                self.EventHandler(event)
            end
        end
        self.ScriptControlChanged = function(event, name)
            if  not name then
                self.EventHandler(event)
            else
                local control
                if event == "Ovale_CheckBoxValueChanged" then
                    control = checkBoxes[name]
                elseif event == "Ovale_ListValueChanged" then
                    control = checkBoxes[name]
                end
                if control and control.triggerEvaluation then
                    self.EventHandler(event)
                end
            end
        end
        self.EventHandler = function(event)
            self.self_serial = self.self_serial + 1
            self.tracer:Debug("%s: advance age to %d.", event, self.self_serial)
            self.ovale:needRefresh()
        end
        self.tracer = ovaleDebug:create("OvaleCompile")
        self.profiler = ovaleProfiler:create("OvaleCompile")
        self.module = ovale:createModule("OvaleCompile", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    HasTalent = function(self, talentId)
        if self.ovaleSpellBook:IsKnownTalent(talentId) then
            return self.ovaleSpellBook:GetTalentPoints(talentId) > 0
        else
            return false
        end
    end,
    RequireValue = function(self, value)
        local required = (sub(tostring(value), 1, 1) ~= "!")
        if  not required then
            value = sub(value, 2)
            if match(value, NUMBER_PATTERN) then
                return tonumber(value), required
            end
        end
        return value, required
    end,
    RequireNumber = function(self, value)
        local required = (sub(tostring(value), 1, 1) ~= "!")
        if  not required then
            value = sub(value, 2)
            return tonumber(value), required
        end
        return tonumber(value), required
    end,
    TestConditions = function(self, positionalParams, namedParams)
        self.profiler:StartProfiling("OvaleCompile_TestConditions")
        local boolean = true
        for param, dispatch in kpairs(self.TEST_CONDITION_DISPATCH) do
            local value = namedParams[param]
            if isLuaArray(value) then
                for _, v in ipairs(value) do
                    boolean = dispatch(v)
                    if  not boolean then
                        break
                    end
                end
            elseif value then
                boolean = dispatch(value)
            end
            if  not boolean then
                break
            end
        end
        if boolean and namedParams.itemset and namedParams.itemcount then
            local equippedCount = self.ovaleEquipment:GetArmorSetCount(namedParams.itemset)
            boolean = (equippedCount >= namedParams.itemcount)
        end
        if boolean and namedParams.checkbox then
            local profile = self.ovaleOptions.db.profile
            for _, checkbox in ipairs(namedParams.checkbox) do
                local name, required = self:RequireValue(checkbox)
                local control = checkBoxes[name] or {}
                control.triggerEvaluation = true
                checkBoxes[name] = control
                local isChecked = profile.check[name]
                boolean = (required and isChecked) or ( not required and  not isChecked)
                if  not boolean then
                    break
                end
            end
        end
        if boolean and namedParams.listitem then
            local profile = self.ovaleOptions.db.profile
            for name, listitem in pairs(namedParams.listitem) do
                local item, required = self:RequireValue(listitem)
                local control = lists[name] or {
                    items = {},
                    default = nil
                }
                control.triggerEvaluation = true
                lists[name] = control
                local isSelected = (profile.list[name] == item)
                boolean = (required and isSelected) or ( not required and  not isSelected)
                if  not boolean then
                    break
                end
            end
        end
        self.profiler:StopProfiling("OvaleCompile_TestConditions")
        return boolean
    end,
    EvaluateAddCheckBox = function(self, node)
        local ok = true
        local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
        if self:TestConditions(positionalParams, namedParams) then
            local checkBox = checkBoxes[name]
            if  not checkBox then
                self.self_serial = self.self_serial + 1
                self.tracer:Debug("New checkbox '%s': advance age to %d.", name, self.self_serial)
            end
            checkBox = checkBox or {}
            checkBox.text = node.description.value
            for _, v in ipairs(positionalParams) do
                if v == "default" then
                    checkBox.checked = true
                    break
                end
            end
            checkBoxes[name] = checkBox
        end
        return ok
    end,
    EvaluateAddIcon = function(self, node)
        local ok = true
        local positionalParams, namedParams = node.positionalParams, node.namedParams
        if self:TestConditions(positionalParams, namedParams) then
            self.icon[#self.icon + 1] = node
        end
        return ok
    end,
    EvaluateAddListItem = function(self, node)
        local ok = true
        local name, item, positionalParams, namedParams = node.name, node.item, node.positionalParams, node.namedParams
        if self:TestConditions(positionalParams, namedParams) then
            local list = lists[name]
            if  not (list and list.items and list.items[item]) then
                self.self_serial = self.self_serial + 1
                self.tracer:Debug("New list '%s': advance age to %d.", name, self.self_serial)
            end
            list = list or {
                items = {},
                default = nil
            }
            list.items[item] = node.description.value
            for _, v in ipairs(positionalParams) do
                if v == "default" then
                    list.default = item
                    break
                end
            end
            lists[name] = list
        end
        return ok
    end,
    EvaluateItemInfo = function(self, node)
        local ok = true
        local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
        if itemId and self:TestConditions(positionalParams, namedParams) then
            local ii = self.ovaleData:ItemInfo(itemId)
            for k, v in kpairs(namedParams) do
                if k == "proc" then
                    local buff = tonumber(namedParams.buff)
                    if buff then
                        local name = "item_proc_" .. namedParams.proc
                        local list = self.ovaleData.buffSpellList[name] or {}
                        list[buff] = true
                        self.ovaleData.buffSpellList[name] = list
                    else
                        ok = false
                        break
                    end
                elseif  not checkToken(PARAMETER_KEYWORD, k) then
                    (ii)[k] = v
                end
            end
            self.ovaleData.itemInfo[itemId] = ii
        end
        return ok
    end,
    EvaluateItemRequire = function(self, node)
        local ok = true
        local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
        if self:TestConditions(positionalParams, namedParams) then
            local property = node.property
            local count = 0
            local ii = self.ovaleData:ItemInfo(itemId)
            local tbl = ii.require[property] or {}
            local arr = nil
            for k, v in kpairs(namedParams) do
                if  not checkToken(PARAMETER_KEYWORD, k) then
                    arr = tbl[k] or {}
                    if isLuaArray(arr) then
                        insert(arr, v)
                        tbl[k] = arr
                        count = count + 1
                    end
                end
            end
            if count > 0 then
                ii.require[property] = tbl
            end
        end
        return ok
    end,
    EvaluateList = function(self, node)
        local ok = true
        local name, positionalParams = node.name, node.positionalParams, node.namedParams
        local listDB
        if node.keyword == "ItemList" then
            listDB = "itemList"
        else
            listDB = "buffSpellList"
        end
        local list = self.ovaleData[listDB][name] or {}
        for _, _id in pairs(positionalParams) do
            local id = tonumber(_id)
            if id then
                list[id] = true
            else
                ok = false
                break
            end
        end
        self.ovaleData[listDB][name] = list
        return ok
    end,
    EvaluateScoreSpells = function(self, node)
        local ok = true
        local positionalParams = node.positionalParams, node.namedParams
        for _, _spellId in ipairs(positionalParams) do
            local spellId = tonumber(_spellId)
            if spellId then
                self.ovaleScore:AddSpell(tonumber(spellId))
            else
                ok = false
                break
            end
        end
        return ok
    end,
    EvaluateSpellAuraList = function(self, node)
        local ok = true
        local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
        if  not spellId then
            self.tracer:Error("No spellId for name %s", node.name)
            return false
        end
        if self:TestConditions(positionalParams, namedParams) then
            local keyword = node.keyword
            local si = self.ovaleData:SpellInfo(spellId)
            local auraTable
            if find(keyword, "^SpellDamage") then
                auraTable = si.aura.damage
            elseif find(keyword, "^SpellAddPet") then
                auraTable = si.aura.pet
            elseif find(keyword, "^SpellAddTarget") then
                auraTable = si.aura.target
            else
                auraTable = si.aura.player
            end
            local filter = find(node.keyword, "Debuff") and "HARMFUL" or "HELPFUL"
            local tbl = auraTable[filter] or {}
            local count = 0
            for k, v in kpairs(namedParams) do
                if  not checkToken(PARAMETER_KEYWORD, k) then
                    if self.ovaleData.buffSpellList[k] then
                        tbl[k] = v
                        count = count + 1
                    else
                        local id = tonumber(k)
                        if  not id then
                            self.tracer:Warning(k .. " is not a parameter keyword in '" .. node.name .. "' " .. node.type)
                        else
                            tbl[id] = v
                            count = count + 1
                        end
                    end
                end
            end
            if count > 0 then
                auraTable[filter] = tbl
            end
        end
        return ok
    end,
    EvaluateSpellInfo = function(self, node)
        local addpower = {}
        for _, powertype in ipairs(POWER_TYPES) do
            local key = "add" .. powertype
            addpower[key] = powertype
        end
        local ok = true
        local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
        if spellId and self:TestConditions(positionalParams, namedParams) then
            local si = self.ovaleData:SpellInfo(spellId)
            for k, v in kpairs(namedParams) do
                if k == "add_duration" then
                    local value = tonumber(v)
                    if value then
                        local realValue = value
                        if namedParams.pertrait ~= nil then
                            realValue = value * self.ovaleAzerite:TraitRank(namedParams.pertrait)
                        end
                        local addDuration = si.add_duration or 0
                        si.add_duration = addDuration + realValue
                    else
                        ok = false
                        break
                    end
                elseif k == "add_cd" then
                    local value = tonumber(v)
                    if value then
                        local addCd = si.add_cd or 0
                        si.add_cd = addCd + value
                    else
                        ok = false
                        break
                    end
                elseif k == "addlist" then
                    local list = self.ovaleData.buffSpellList[v] or {}
                    list[spellId] = true
                    self.ovaleData.buffSpellList[v] = list
                elseif k == "dummy_replace" then
                    local spellName = GetSpellInfo(v)
                    if  not spellName then
                        spellName = v
                    end
                    self.ovaleSpellBook:AddSpell(spellId, spellName)
                elseif k == "learn" and v == 1 then
                    local spellName = GetSpellInfo(spellId)
                    self.ovaleSpellBook:AddSpell(spellId, spellName)
                elseif k == "shared_cd" then
                    si[k] = v
                    self.ovaleCooldown:AddSharedCooldown(v, spellId)
                elseif addpower[k] ~= nil then
                    local value = tonumber(v)
                    if value then
                        local realValue = value
                        if namedParams.pertrait ~= nil then
                            realValue = value * self.ovaleAzerite:TraitRank(namedParams.pertrait)
                        end
                        local power = si[k] or 0
                        (si)[k] = power + realValue
                    else
                        ok = false
                        break
                    end
                elseif  not checkToken(PARAMETER_KEYWORD, k) then
                    (si)[k] = v
                end
            end
        end
        return ok
    end,
    EvaluateSpellRequire = function(self, node)
        local ok = true
        local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
        if self:TestConditions(positionalParams, namedParams) then
            local property = node.property
            local count = 0
            local si = self.ovaleData:SpellInfo(spellId)
            local tbl = si.require[property] or {}
            local arr = nil
            for k, v in kpairs(namedParams) do
                if  not checkToken(PARAMETER_KEYWORD, k) then
                    arr = tbl[k] or {}
                    if isLuaArray(arr) then
                        insert(arr, v)
                        tbl[k] = arr
                        count = count + 1
                    end
                end
            end
            if count > 0 then
                si.require[property] = tbl
            end
        end
        return ok
    end,
    AddMissingVariantSpells = function(self, annotation)
        if annotation.functionReference then
            for _, node in ipairs(annotation.functionReference) do
                local positionalParams = node.positionalParams, node.namedParams
                local spellId = positionalParams[1]
                if spellId and self.ovaleCondition:IsSpellBookCondition(node.func) then
                    if  not self.ovaleSpellBook:IsKnownSpell(spellId) and  not self.ovaleCooldown:IsSharedCooldown(spellId) then
                        local spellName
                        if type(spellId) == "number" then
                            spellName = self.ovaleSpellBook:GetSpellName(spellId)
                        end
                        if spellName then
                            local name = GetSpellInfo(spellName)
                            if spellName == name then
                                self.tracer:Debug("Learning spell %s with ID %d.", spellName, spellId)
                                self.ovaleSpellBook:AddSpell(spellId, spellName)
                            end
                        else
                            local functionCall = node.name
                            if node.paramsAsString then
                                functionCall = node.name .. "(" .. node.paramsAsString .. ")"
                            end
                            self.tracer:Error("Unknown spell with ID %s used in %s.", spellId, functionCall)
                        end
                    end
                end
            end
        end
    end,
    AddToBuffList = function(self, buffId, statName, isStacking)
        if statName then
            for _, useName in pairs(self.ovaleData.STAT_USE_NAMES) do
                if isStacking or  not find(useName, "_stacking_") then
                    local name = useName .. "_" .. statName .. "_buff"
                    local list = self.ovaleData.buffSpellList[name] or {}
                    list[buffId] = true
                    self.ovaleData.buffSpellList[name] = list
                    local shortStatName = self.ovaleData.STAT_SHORTNAME[statName]
                    if shortStatName then
                        name = useName .. "_" .. shortStatName .. "_buff"
                        list = self.ovaleData.buffSpellList[name] or {}
                        list[buffId] = true
                        self.ovaleData.buffSpellList[name] = list
                    end
                    name = useName .. "_any_buff"
                    list = self.ovaleData.buffSpellList[name] or {}
                    list[buffId] = true
                    self.ovaleData.buffSpellList[name] = list
                end
            end
        else
            local si = self.ovaleData.spellInfo[buffId]
            isStacking = si and ((si.stacking or 0) == 1 or (si.max_stacks or 0) > 0)
            if si and si.stat then
                local stat = si.stat
                if isLuaArray(stat) then
                    for _, name in ipairs(stat) do
                        self:AddToBuffList(buffId, name, isStacking)
                    end
                else
                    self:AddToBuffList(buffId, stat, isStacking)
                end
            end
        end
    end,
    UpdateTrinketInfo = function(self)
        self.trinket[1], self.trinket[2] = self.ovaleEquipment:GetEquippedTrinkets()
        for i = 1, 2, 1 do
            local itemId = self.trinket[i]
            local ii = itemId and self.ovaleData:ItemInfo(itemId)
            local buffId = ii and ii.buff
            if buffId then
                if isLuaArray(buffId) then
                    for _, id in ipairs(buffId) do
                        self:AddToBuffList(id)
                    end
                else
                    self:AddToBuffList(buffId)
                end
            end
        end
    end,
    CompileScript = function(self, name)
        self.ovaleDebug:ResetTrace()
        self.tracer:Debug("Compiling script '%s'.", name)
        if self.ast then
            self.ovaleAst:Release(self.ast)
            self.ast = nil
        end
        if self.ovaleCondition:HasAny() then
            self.ast = self.ovaleAst:ParseScript(name)
        end
        ResetControls()
        return self.ast
    end,
    EvaluateScript = function(self, ast, forceEvaluation)
        self.profiler:StartProfiling("OvaleCompile_EvaluateScript")
        local changed = false
        ast = ast or self.ast
        if ast and (forceEvaluation or  not self.serial or self.serial < self.self_serial) then
            changed = true
            local ok = true
            self.compileOnStances = false
            wipe(self.icon)
            self.ovaleData:Reset()
            self.ovaleCooldown:ResetSharedCooldowns()
            self.timesEvaluated = self.timesEvaluated + 1
            self.serial = self.self_serial
            for _, node in ipairs(ast.child) do
                local nodeType = node.type
                if nodeType == "checkbox" then
                    ok = self:EvaluateAddCheckBox(node)
                elseif nodeType == "icon" then
                    ok = self:EvaluateAddIcon(node)
                elseif nodeType == "list_item" then
                    ok = self:EvaluateAddListItem(node)
                elseif nodeType == "item_info" then
                    ok = self:EvaluateItemInfo(node)
                elseif nodeType == "item_require" then
                    ok = self:EvaluateItemRequire(node)
                elseif nodeType == "list" then
                    ok = self:EvaluateList(node)
                elseif nodeType == "score_spells" then
                    ok = self:EvaluateScoreSpells(node)
                elseif nodeType == "spell_aura_list" then
                    ok = self:EvaluateSpellAuraList(node)
                elseif nodeType == "spell_info" then
                    ok = self:EvaluateSpellInfo(node)
                elseif nodeType == "spell_require" then
                    ok = self:EvaluateSpellRequire(node)
                else
                end
                if  not ok then
                    break
                end
            end
            if ok then
                self:AddMissingVariantSpells(ast.annotation)
                self:UpdateTrinketInfo()
            end
        end
        self.profiler:StopProfiling("OvaleCompile_EvaluateScript")
        return changed
    end,
    GetFunctionNode = function(self, name)
        local node
        if self.ast and self.ast.annotation and self.ast.annotation.customFunction then
            node = self.ast.annotation.customFunction[name]
        end
        return node
    end,
    GetIconNodes = function(self)
        return self.icon
    end,
    DebugCompile = function(self)
        self.tracer:Print("Total number of times the script was evaluated: %d", self.timesEvaluated)
    end,
})
