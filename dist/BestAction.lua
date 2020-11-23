local __exports = LibStub:NewLibrary("ovale/BestAction", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local tonumber = tonumber
local GetActionCooldown = GetActionCooldown
local GetActionTexture = GetActionTexture
local GetItemIcon = GetItemIcon
local GetItemCooldown = GetItemCooldown
local GetItemSpell = GetItemSpell
local GetSpellTexture = GetSpellTexture
local IsActionInRange = IsActionInRange
local IsCurrentAction = IsCurrentAction
local IsItemInRange = IsItemInRange
local IsUsableAction = IsUsableAction
local IsUsableItem = IsUsableItem
local __AST = LibStub:GetLibrary("ovale/AST")
local setResultType = __AST.setResultType
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local isString = __tools.isString
__exports.OvaleBestActionClass = __class(nil, {
    constructor = function(self, ovaleEquipment, ovaleActionBar, ovaleData, ovaleCooldown, ovaleState, Ovale, OvaleGUID, OvalePower, OvaleFuture, OvaleSpellBook, ovaleProfiler, ovaleDebug, variables, ovaleRunes, OvaleSpells, runner)
        self.ovaleEquipment = ovaleEquipment
        self.ovaleActionBar = ovaleActionBar
        self.ovaleData = ovaleData
        self.ovaleCooldown = ovaleCooldown
        self.ovaleState = ovaleState
        self.OvaleGUID = OvaleGUID
        self.OvalePower = OvalePower
        self.OvaleFuture = OvaleFuture
        self.OvaleSpellBook = OvaleSpellBook
        self.variables = variables
        self.ovaleRunes = ovaleRunes
        self.OvaleSpells = OvaleSpells
        self.runner = runner
        self.onInitialize = function()
        end
        self.GetActionItemInfo = function(node, atTime, target)
            self.profiler:StartProfiling("OvaleBestAction_GetActionItemInfo")
            local itemId = node.cachedParams.positional[1]
            local result = node.result
            setResultType(result, "action")
            if  not isNumber(itemId) then
                local itemIdFromSlot = self.ovaleEquipment:GetEquippedItemBySlotName(itemId)
                if  not itemIdFromSlot then
                    self.tracer:Log("Unknown item '%s'.", itemId)
                    return result
                end
                itemId = itemIdFromSlot
            end
            self.tracer:Log("Item ID '%s'", itemId)
            local action = self.ovaleActionBar:GetForItem(itemId)
            local spellName = GetItemSpell(itemId)
            if node.cachedParams.named.texture then
                result.actionTexture = "Interface\\Icons\\" .. node.cachedParams.named.texture
            end
            result.actionTexture = result.actionTexture or GetItemIcon(itemId)
            result.actionInRange = IsItemInRange(itemId, target)
            result.actionCooldownStart, result.actionCooldownDuration, result.actionEnable = GetItemCooldown(itemId)
            result.actionUsable = (spellName and IsUsableItem(itemId) and self.OvaleSpells:IsUsableItem(itemId, atTime)) or false
            if action then
                result.actionShortcut = self.ovaleActionBar:GetBinding(action)
                result.actionIsCurrent = IsCurrentAction(action)
            end
            result.actionType = "item"
            result.actionId = itemId
            result.actionTarget = target
            result.castTime = self.OvaleFuture:GetGCD(nil, atTime)
            self.profiler:StopProfiling("OvaleBestAction_GetActionItemInfo")
            return result
        end
        self.GetActionMacroInfo = function(element, atTime, target)
            self.profiler:StartProfiling("OvaleBestAction_GetActionMacroInfo")
            local result = element.result
            local macro = element.cachedParams.positional[1]
            local action = self.ovaleActionBar:GetForMacro(macro)
            setResultType(result, "action")
            if  not action then
                self.tracer:Log("Unknown macro '%s'.", macro)
                return result
            end
            if element.cachedParams.named.texture then
                result.actionTexture = "Interface\\Icons\\" .. element.cachedParams.named.texture
            end
            result.actionTexture = result.actionTexture or GetActionTexture(action)
            result.actionInRange = IsActionInRange(action, target)
            result.actionCooldownStart, result.actionCooldownDuration, result.actionEnable = GetActionCooldown(action)
            result.actionUsable = IsUsableAction(action)
            result.actionShortcut = self.ovaleActionBar:GetBinding(action)
            result.actionIsCurrent = IsCurrentAction(action)
            result.actionType = "macro"
            result.actionId = macro
            result.castTime = self.OvaleFuture:GetGCD(nil, atTime)
            self.profiler:StopProfiling("OvaleBestAction_GetActionMacroInfo")
            return result
        end
        self.GetActionSpellInfo = function(element, atTime, target)
            self.profiler:StartProfiling("OvaleBestAction_GetActionSpellInfo")
            local spell = element.cachedParams.positional[1]
            if isNumber(spell) then
                return self:getSpellActionInfo(spell, element, atTime, target)
            elseif isString(spell) then
                local spellList = self.ovaleData.buffSpellList[spell]
                if spellList then
                    for spellId in pairs(spellList) do
                        if self.OvaleSpellBook:IsKnownSpell(spellId) then
                            return self:getSpellActionInfo(spellId, element, atTime, target)
                        end
                    end
                end
            end
            setResultType(element.result, "action")
            return element.result
        end
        self.GetActionTextureInfo = function(element, atTime, target)
            self.profiler:StartProfiling("OvaleBestAction_GetActionTextureInfo")
            local result = element.result
            setResultType(result, "action")
            result.actionTarget = target
            local actionTexture
            do
                local texture = element.cachedParams.positional[1]
                local spellId = tonumber(texture)
                if spellId then
                    actionTexture = GetSpellTexture(spellId)
                else
                    actionTexture = "Interface\\Icons\\" .. texture
                end
            end
            result.actionInRange = false
            result.actionCooldownStart = 0
            result.actionCooldownDuration = 0
            result.actionEnable = true
            result.actionUsable = true
            result.actionShortcut = nil
            result.actionIsCurrent = false
            result.actionType = "texture"
            result.actionId = actionTexture
            result.castTime = self.OvaleFuture:GetGCD(nil, atTime)
            self.profiler:StopProfiling("OvaleBestAction_GetActionTextureInfo")
            return result
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_ScriptChanged")
        end
        self.module = Ovale:createModule("BestAction", self.onInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        self.tracer = ovaleDebug:create(self.module:GetName())
        runner:registerActionInfoHandler("item", self.GetActionItemInfo)
        runner:registerActionInfoHandler("macro", self.GetActionMacroInfo)
        runner:registerActionInfoHandler("spell", self.GetActionSpellInfo)
        runner:registerActionInfoHandler("texture", self.GetActionTextureInfo)
    end,
    getSpellActionInfo = function(self, spellId, element, atTime, target)
        local targetGUID = self.OvaleGUID:UnitGUID(target)
        local result = element.result
        local si = self.ovaleData.spellInfo[spellId]
        local replacedSpellId = nil
        if si then
            local replacement = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "replaced_by", targetGUID)
            if replacement then
                replacedSpellId = spellId
                spellId = replacement
                si = self.ovaleData.spellInfo[spellId]
                self.tracer:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
            end
        end
        local action = self.ovaleActionBar:GetForSpell(spellId)
        if  not action and replacedSpellId then
            self.tracer:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
            action = self.ovaleActionBar:GetForSpell(replacedSpellId)
            if action then
                spellId = replacedSpellId
            end
        end
        local isKnownSpell = self.OvaleSpellBook:IsKnownSpell(spellId)
        if  not isKnownSpell and replacedSpellId then
            self.tracer:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
            isKnownSpell = self.OvaleSpellBook:IsKnownSpell(replacedSpellId)
            if isKnownSpell then
                spellId = replacedSpellId
            end
        end
        if  not isKnownSpell and  not action then
            setResultType(result, "none")
            self.tracer:Log("Unknown spell ID '%s'.", spellId)
            return result
        end
        local isUsable, noMana = self.OvaleSpells:IsUsableSpell(spellId, atTime, targetGUID)
        self.tracer:Log("OvaleSpells:IsUsableSpell(%d, %f, %s) returned %s, %s", spellId, atTime, targetGUID, isUsable, noMana)
        if  not isUsable and  not noMana then
            setResultType(result, "none")
            return result
        end
        setResultType(result, "action")
        if element.cachedParams.named.texture then
            result.actionTexture = "Interface\\Icons\\" .. element.cachedParams.named.texture
        end
        result.actionTexture = result.actionTexture or GetSpellTexture(spellId)
        result.actionInRange = self.OvaleSpells:IsSpellInRange(spellId, target)
        result.actionCooldownStart, result.actionCooldownDuration, result.actionEnable = self.ovaleCooldown:GetSpellCooldown(spellId, atTime)
        self.tracer:Log("GetSpellCooldown returned %f, %f", result.actionCooldownStart, result.actionCooldownDuration)
        result.actionCharges = self.ovaleCooldown:GetSpellCharges(spellId, atTime)
        result.actionResourceExtend = 0
        result.actionUsable = isUsable
        if action then
            result.actionShortcut = self.ovaleActionBar:GetBinding(action)
            result.actionIsCurrent = IsCurrentAction(action)
        end
        result.actionType = "spell"
        result.actionId = spellId
        if si then
            if si.texture then
                result.actionTexture = "Interface\\Icons\\" .. si.texture
            end
            if result.actionCooldownStart and result.actionCooldownDuration then
                local extraPower = element.cachedParams.named.extra_amount or 0
                local timeToCd = (result.actionCooldownDuration > 0 and result.actionCooldownStart + result.actionCooldownDuration - atTime) or 0
                local timeToPower = self.OvalePower:TimeToPower(spellId, atTime, targetGUID, nil, extraPower)
                local runes = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "runes", targetGUID)
                if runes then
                    local timeToRunes = self.ovaleRunes:GetRunesCooldown(atTime, runes)
                    if timeToPower < timeToRunes then
                        timeToPower = timeToRunes
                    end
                end
                if timeToPower > timeToCd then
                    result.actionResourceExtend = timeToPower - timeToCd
                    self.tracer:Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, result.actionResourceExtend)
                end
            end
        end
        if si.casttime then
            result.castTime = si.casttime
        else
            result.castTime = self.OvaleSpellBook:GetCastTime(spellId)
        end
        result.actionTarget = target
        local offgcd = element.cachedParams.named.offgcd or self.ovaleData:GetSpellInfoProperty(spellId, atTime, "offgcd", targetGUID) or 0
        result.offgcd = (offgcd == 1 and true) or nil
        if result.timeSpan then
            self.profiler:StopProfiling("OvaleBestAction_GetActionSpellInfo")
        end
        return result
    end,
    StartNewAction = function(self)
        self.ovaleState:ResetState()
        self.OvaleFuture:ApplyInFlightSpells()
        self.runner:refresh()
    end,
    GetAction = function(self, node, atTime)
        self.profiler:StartProfiling("OvaleBestAction_GetAction")
        local groupNode = node.child[1]
        local element = self.runner:PostOrderCompute(groupNode, atTime)
        if element.type == "state" and element.timeSpan:HasTime(atTime) then
            local variable, value = element.name, element.value
            local isFuture =  not element.timeSpan:HasTime(atTime)
            self.variables:PutState(variable, value, isFuture, atTime)
        end
        self.profiler:StopProfiling("OvaleBestAction_GetAction")
        return element
    end,
})
