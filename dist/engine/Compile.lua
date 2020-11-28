local __exports = LibStub:NewLibrary("ovale/engine/Compile", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __statesPower = LibStub:GetLibrary("ovale/states/Power")
local POWER_TYPES = __statesPower.POWER_TYPES
local __Controls = LibStub:GetLibrary("ovale/engine/Controls")
local checkBoxes = __Controls.checkBoxes
local lists = __Controls.lists
local ResetControls = __Controls.ResetControls
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local wipe = wipe
local kpairs = pairs
local match = string.match
local sub = string.sub
local insert = table.insert
local GetSpellInfo = GetSpellInfo
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local isNumber = __toolstools.isNumber
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"
__exports.RequireValue = function(value)
    local required = sub(tostring(value), 1, 1) ~= "!"
    if  not required then
        value = sub(value, 2)
        if match(value, NUMBER_PATTERN) then
            return tonumber(value), required
        end
    end
    return value, required
end
__exports.RequireNumber = function(value)
    if isNumber(value) then
        return value, true
    end
    local required = sub(tostring(value), 1, 1) ~= "!"
    if  not required then
        value = sub(value, 2)
        return tonumber(value), required
    end
    return tonumber(value), required
end
local auraTableDispatch = {
    spelladdbuff = {
        filter = "HELPFUL",
        target = "player"
    },
    spelladddebuff = {
        filter = "HARMFUL",
        target = "player"
    },
    spelladdpetbuff = {
        filter = "HELPFUL",
        target = "pet"
    },
    spelladdpetdebuff = {
        filter = "HARMFUL",
        target = "pet"
    },
    spelladdtargetbuff = {
        filter = "HELPFUL",
        target = "target"
    },
    spelladdtargetdebuff = {
        filter = "HARMFUL",
        target = "target"
    },
    spelldamagebuff = {
        filter = "HELPFUL",
        target = "damage"
    },
    spelldamagedebuff = {
        filter = "HARMFUL",
        target = "damage"
    }
}
__exports.OvaleCompileClass = __class(nil, {
    constructor = function(self, ovaleAzerite, ovaleAst, ovaleCondition, ovaleCooldown, ovalePaperDoll, ovaleData, ovaleProfiler, ovaleDebug, ovaleOptions, ovale, ovaleScore, ovaleSpellBook)
        self.ovaleAzerite = ovaleAzerite
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
        self.serial = nil
        self.ast = nil
        self.self_serial = 0
        self.timesEvaluated = 0
        self.icon = {}
        self.OnInitialize = function()
            self.module:RegisterMessage("Ovale_CheckBoxValueChanged", self.ScriptControlChanged)
            self.module:RegisterMessage("Ovale_ListValueChanged", self.ScriptControlChanged)
            self.module:RegisterMessage("Ovale_ScriptChanged", self.Ovale_ScriptChanged)
            self.module:RegisterMessage("Ovale_SpecializationChanged", self.Ovale_ScriptChanged)
            self.module:SendMessage("Ovale_ScriptChanged")
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_CheckBoxValueChanged")
            self.module:UnregisterMessage("Ovale_ListValueChanged")
            self.module:UnregisterMessage("Ovale_ScriptChanged")
            self.module:UnregisterMessage("Ovale_SpecializationChanged")
        end
        self.Ovale_ScriptChanged = function(event)
            self:CompileScript(self.ovaleOptions.db.profile.source[self.ovale.playerClass .. "_" .. self.ovalePaperDoll:GetSpecialization()])
            self.EventHandler(event)
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
    EvaluateAddCheckBox = function(self, node)
        local ok = true
        local name, positionalParams, namedParams = node.name, node.rawPositionalParams, node.rawNamedParams
        local checkBox = checkBoxes[name]
        if  not checkBox then
            self.self_serial = self.self_serial + 1
            self.tracer:Debug("New checkbox '%s': advance age to %d.", name, self.self_serial)
        end
        checkBox = checkBox or {}
        if node.description.type == "string" then
            checkBox.text = node.description.value
        end
        for _, v in ipairs(positionalParams) do
            if v.type == "string" and v.value == "default" then
                checkBox.checked = true
                break
            end
        end
        checkBox.enabled = namedParams.enabled
        checkBoxes[name] = checkBox
        return ok
    end,
    EvaluateAddIcon = function(self, node)
        self.icon[#self.icon + 1] = node
        return true
    end,
    EvaluateAddListItem = function(self, node)
        local ok = true
        local name, item, positionalParams, namedParams = node.name, node.item, node.rawPositionalParams, node.rawNamedParams
        if item then
            local list = lists[name]
            if  not (list and list.items and list.items[item]) then
                self.self_serial = self.self_serial + 1
                self.tracer:Debug("New list '%s': advance age to %d.", name, self.self_serial)
            end
            list = list or {
                items = {},
                default = nil
            }
            if node.description.type == "string" then
                list.items[item] = node.description.value
            end
            for _, v in ipairs(positionalParams) do
                if v.type == "string" and v.value == "default" then
                    list.default = item
                    break
                end
            end
            list.enabled = namedParams.enabled
            lists[name] = list
        end
        return ok
    end,
    EvaluateItemInfo = function(self, node)
        local ok = true
        local itemId, namedParams = node.itemId, node.rawNamedParams
        if itemId then
            local ii = self.ovaleData:ItemInfo(itemId)
            for k, v in kpairs(namedParams) do
                if k == "proc" then
                    local buff = v
                    if buff.type == "value" and isNumber(buff.value) then
                        local name = "item_proc_" .. namedParams.proc
                        local list = self.ovaleData.buffSpellList[name] or {}
                        list[buff.value] = true
                        self.ovaleData.buffSpellList[name] = list
                    else
                        ok = false
                        break
                    end
                else
                    if v.type == "value" or v.type == "string" then
                        ii[k] = v.value
                    else
                        ok = false
                        break
                    end
                end
            end
            self.ovaleData.itemInfo[itemId] = ii
        end
        return ok
    end,
    EvaluateItemRequire = function(self, node)
        local property = node.property
        local ii = self.ovaleData:ItemInfo(node.itemId)
        local tbl = ii.require[property] or {}
        insert(tbl, node)
        ii.require[property] = tbl
        return true
    end,
    EvaluateList = function(self, node)
        local ok = true
        local name, positionalParams = node.name, node.rawPositionalParams
        local listDB
        if node.keyword == "ItemList" then
            listDB = "itemList"
        else
            listDB = "buffSpellList"
        end
        local list = self.ovaleData[listDB][name] or {}
        for _, _id in pairs(positionalParams) do
            if _id.type == "value" and isNumber(_id.value) then
                list[_id.value] = true
            else
                self.tracer:Error("%s is not a number in the '%s' list", _id.asString, name)
                ok = false
                break
            end
        end
        self.ovaleData[listDB][name] = list
        return ok
    end,
    EvaluateScoreSpells = function(self, node)
        local ok = true
        local positionalParams = node.rawPositionalParams
        for _, _spellId in ipairs(positionalParams) do
            if _spellId.type == "value" and isNumber(_spellId.value) then
                self.ovaleScore:AddSpell(_spellId.value)
            else
                ok = false
                break
            end
        end
        return ok
    end,
    EvaluateSpellAuraList = function(self, node)
        local ok = true
        local spellId = node.spellId
        if  not spellId then
            self.tracer:Error("No spellId for name %s", node.name)
            return false
        end
        local keyword = node.keyword
        local si = self.ovaleData:SpellInfo(spellId)
        if si.aura then
            local auraInfo = auraTableDispatch[keyword]
            local auraTable = si.aura[auraInfo.target]
            local filter = auraInfo.filter
            local tbl = auraTable[filter] or {}
            tbl[node.buffSpellId] = node
            local buff = self.ovaleData:SpellInfo(node.buffSpellId)
            buff.effect = auraInfo.filter
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
        local spellId, _, namedParams = node.spellId, node.rawPositionalParams, node.rawNamedParams
        if spellId then
            local si = self.ovaleData:SpellInfo(spellId)
            for k, v in kpairs(namedParams) do
                if k == "add_duration" then
                    if v.type == "value" then
                        local realValue = v.value
                        if namedParams.pertrait and namedParams.pertrait.type == "value" then
                            realValue = v.value * self.ovaleAzerite:TraitRank(namedParams.pertrait.value)
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
                elseif k == "addlist" and v.type == "string" then
                    local list = self.ovaleData.buffSpellList[v.value] or {}
                    list[spellId] = true
                    self.ovaleData.buffSpellList[v.value] = list
                elseif k == "dummy_replace" and v.type == "string" then
                    local spellName = GetSpellInfo(v.value)
                    if  not spellName then
                        spellName = v.value
                    end
                    self.ovaleSpellBook:AddSpell(spellId, spellName)
                elseif k == "learn" and v.type == "value" and v.value == 1 then
                    local spellName = GetSpellInfo(spellId)
                    if spellName then
                        self.ovaleSpellBook:AddSpell(spellId, spellName)
                    end
                elseif k == "shared_cd" and v.type == "string" then
                    si.shared_cd = v.value
                    self.ovaleCooldown:AddSharedCooldown(v.value, spellId)
                elseif addpower[k] ~= nil then
                    if v.type == "value" then
                        local realValue = v.value
                        if namedParams.pertrait and namedParams.pertrait.type == "value" then
                            realValue = v.value * self.ovaleAzerite:TraitRank(namedParams.pertrait.value)
                        end
                        local power = si[k] or 0
                        (si)[k] = power + realValue
                    else
                        self.tracer:Error("Unexpected value type %s in a addpower SpellInfo parameter (should be value)", v.type)
                        ok = false
                        break
                    end
                else
                    if v.type == "value" or v.type == "string" then
                        si[k] = v.value
                    else
                        self.tracer:Error("Unexpected value type %s in a SpellInfo parameter (should be value or string)", v.type)
                        ok = false
                        break
                    end
                end
            end
        end
        return ok
    end,
    EvaluateSpellRequire = function(self, node)
        local ok = true
        local spellId = node.spellId, node.rawPositionalParams, node.rawNamedParams
        local property = node.property
        local si = self.ovaleData:SpellInfo(spellId)
        local tbl = si.require[property] or {}
        insert(tbl, node)
        si.require[property] = tbl
        return ok
    end,
    AddMissingVariantSpells = function(self, annotation)
        if annotation.spellNode then
            for _, spellIdParam in ipairs(annotation.spellNode) do
                if spellIdParam.type == "value" then
                    local spellId = spellIdParam.value
                    if  not self.ovaleSpellBook:IsKnownSpell(spellId) and  not self.ovaleCooldown:IsSharedCooldown(spellId) then
                        local spellName = self.ovaleSpellBook:GetSpellName(spellId)
                        if spellName then
                            local name = GetSpellInfo(spellName)
                            if spellName == name then
                                self.tracer:Debug("Learning spell %s with ID %d.", spellName, spellId)
                                self.ovaleSpellBook:AddSpell(spellId, spellName)
                            end
                        else
                            self.tracer:Error("Unknown spell with ID %s.", spellId)
                        end
                    end
                elseif spellIdParam.type == "string" then
                    if  not self.ovaleData.buffSpellList[spellIdParam.value] then
                        self.tracer:Error("Unknown spell list %s", spellIdParam.value)
                    end
                elseif spellIdParam.type == "variable" then
                    self.tracer:Error("Spell argument %s must be either a spell id or a spell list name.", spellIdParam.name)
                else
                    self.tracer:Error("Spell argument must be either a spell id or a spell list name.")
                end
            end
        end
    end,
    UpdateTrinketInfo = function(self)
    end,
    CompileScript = function(self, name)
        self.ovaleDebug:ResetTrace()
        self.tracer:Debug("Compiling script '%s'.", name)
        if self.ast then
            self.ovaleAst:Release(self.ast)
            self.ast = nil
        end
        if self.ovaleCondition:HasAny() then
            self.ast = self.ovaleAst:parseNamedScript(name)
            self.tracer:Debug("Compilation result: " .. ((self.ast ~= nil and "success") or "failed"))
        else
            self.tracer:Debug("No conditions. No need to compile.")
        end
        ResetControls()
        return self.ast
    end,
    EvaluateScript = function(self, ast, forceEvaluation)
        self.profiler:StartProfiling("OvaleCompile_EvaluateScript")
        local changed = false
        ast = ast or self.ast
        if ast and (forceEvaluation or  not self.serial or self.serial < self.self_serial) then
            self.tracer:Debug("Script has changed. Evaluating...")
            changed = true
            local ok = true
            wipe(self.icon)
            self.ovaleData:Reset()
            self.ovaleCooldown:ResetSharedCooldowns()
            self.timesEvaluated = self.timesEvaluated + 1
            self.serial = self.self_serial
            for _, node in ipairs(ast.child) do
                if node.type == "checkbox" then
                    ok = self:EvaluateAddCheckBox(node)
                elseif node.type == "icon" then
                    ok = self:EvaluateAddIcon(node)
                elseif node.type == "list_item" then
                    ok = self:EvaluateAddListItem(node)
                elseif node.type == "item_info" then
                    ok = self:EvaluateItemInfo(node)
                elseif node.type == "itemrequire" then
                    ok = self:EvaluateItemRequire(node)
                elseif node.type == "list" then
                    ok = self:EvaluateList(node)
                elseif node.type == "score_spells" then
                    ok = self:EvaluateScoreSpells(node)
                elseif node.type == "spell_aura_list" then
                    ok = self:EvaluateSpellAuraList(node)
                elseif node.type == "spell_info" then
                    ok = self:EvaluateSpellInfo(node)
                elseif node.type == "spell_require" then
                    ok = self:EvaluateSpellRequire(node)
                elseif node.type ~= "define" and node.type ~= "add_function" then
                    self.tracer:Error("Unknown node type", node.type)
                    ok = false
                end
                if  not ok then
                    break
                end
            end
            if ok then
                if ast.annotation then
                    self:AddMissingVariantSpells(ast.annotation)
                end
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
