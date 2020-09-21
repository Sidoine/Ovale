local __exports = LibStub:NewLibrary("ovale/simulationcraft/emiter", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __definitions = LibStub:GetLibrary("ovale/simulationcraft/definitions")
local SPECIAL_ACTION = __definitions.SPECIAL_ACTION
local interruptsClasses = __definitions.interruptsClasses
local UNARY_OPERATOR = __definitions.UNARY_OPERATOR
local BINARY_OPERATOR = __definitions.BINARY_OPERATOR
local checkOptionalSkill = __definitions.checkOptionalSkill
local CHARACTER_PROPERTY = __definitions.CHARACTER_PROPERTY
local MISC_OPERAND = __definitions.MISC_OPERAND
local tonumber = tonumber
local kpairs = pairs
local ipairs = ipairs
local tostring = tostring
local __AST = LibStub:GetLibrary("ovale/AST")
local isNodeType = __AST.isNodeType
local format = string.format
local gmatch = string.gmatch
local find = string.find
local match = string.match
local lower = string.lower
local gsub = string.gsub
local sub = string.sub
local len = string.len
local upper = string.upper
local insert = table.insert
local __texttools = LibStub:GetLibrary("ovale/simulationcraft/text-tools")
local LowerSpecialization = __texttools.LowerSpecialization
local CamelCase = __texttools.CamelCase
local OvaleFunctionName = __texttools.OvaleFunctionName
local __Power = LibStub:GetLibrary("ovale/Power")
local POOLED_RESOURCE = __Power.POOLED_RESOURCE
local __tools = LibStub:GetLibrary("ovale/tools")
local MakeString = __tools.MakeString
local OPERAND_TOKEN_PATTERN = "[^.]+"
local function IsTotem(name)
    if sub(name, 1, 13) == "efflorescence" then
        return true
    elseif name == "rune_of_power" then
        return true
    elseif sub(name, -7, -1) == "_statue" then
        return true
    elseif match(name, "invoke_(niuzao|xuen|chiji)") then
        return true
    elseif sub(name, -6, -1) == "_totem" then
        return true
    end
    return false
end
__exports.Emiter = __class(nil, {
    constructor = function(self, ovaleDebug, ovaleAst, ovaleData, unparser)
        self.ovaleAst = ovaleAst
        self.ovaleData = ovaleData
        self.unparser = unparser
        self.EMIT_DISAMBIGUATION = {}
        self.EmitModifier = function(modifier, parseNode, nodeList, annotation, action, modifiers)
            local node, code
            local className = annotation.classId
            local specialization = annotation.specialization
            if modifier == "if" then
                node = self:Emit(parseNode, nodeList, annotation, action)
            elseif modifier == "target_if" then
                node = self:Emit(parseNode, nodeList, annotation, action)
            elseif modifier == "five_stacks" and action == "focus_fire" then
                local value = tonumber(self.unparser:Unparse(parseNode))
                if value == 1 then
                    local buffName = "pet_frenzy_buff"
                    self:AddSymbol(annotation, buffName)
                    code = format("pet.BuffStacks(%s) >= 5", buffName)
                end
            elseif modifier == "line_cd" then
                if  not SPECIAL_ACTION[action] then
                    self:AddSymbol(annotation, action)
                    local node = self:Emit(parseNode, nodeList, annotation, action)
                    if  not node then
                        return nil
                    end
                    local expressionCode = self.ovaleAst:Unparse(node)
                    code = format("TimeSincePreviousSpell(%s) > %s", action, expressionCode)
                end
            elseif modifier == "max_cycle_targets" then
                local debuffName = self:Disambiguate(annotation, action .. "_debuff", className, specialization)
                self:AddSymbol(annotation, debuffName)
                local node = self:Emit(parseNode, nodeList, annotation, action)
                if  not node then
                    return nil
                end
                local expressionCode = self.ovaleAst:Unparse(node)
                code = format("DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s", debuffName, debuffName, expressionCode)
            elseif modifier == "max_energy" then
                local value = tonumber(self.unparser:Unparse(parseNode))
                if value == 1 then
                    code = format("Energy() >= EnergyCost(%s max=1)", action)
                end
            elseif modifier == "min_frenzy" and action == "focus_fire" then
                local value = tonumber(self.unparser:Unparse(parseNode))
                if value then
                    local buffName = "pet_frenzy_buff"
                    self:AddSymbol(annotation, buffName)
                    code = format("pet.BuffStacks(%s) >= %d", buffName, value)
                end
            elseif modifier == "moving" then
                local value = tonumber(self.unparser:Unparse(parseNode))
                if value == 0 then
                    code = "not Speed() > 0"
                else
                    code = "Speed() > 0"
                end
            elseif modifier == "precombat" then
                local value = tonumber(self.unparser:Unparse(parseNode))
                if value == 1 then
                    code = "not InCombat()"
                else
                    code = "InCombat()"
                end
            elseif modifier == "sync" then
                local name = self.unparser:Unparse(parseNode)
                if  not name then
                    return nil
                end
                if name == "whirlwind_mh" then
                    name = "whirlwind"
                end
                node = annotation.astAnnotation and annotation.astAnnotation.sync and annotation.astAnnotation.sync[name]
                if  not node then
                    local syncParseNode = annotation.sync and annotation.sync[name]
                    if syncParseNode then
                        local syncActionNode = self.EmitAction(syncParseNode, nodeList, annotation, action)
                        if syncActionNode then
                            local syncActionType = syncActionNode.type
                            if syncActionType == "action" then
                                node = syncActionNode
                            elseif syncActionType == "custom_function" then
                                node = syncActionNode
                            elseif syncActionType == "if" or syncActionType == "unless" then
                                local lhsNode = syncActionNode.child[1]
                                if syncActionType == "unless" then
                                    local notNode = self.ovaleAst:NewNode(nodeList, true)
                                    notNode.type = "logical"
                                    notNode.expressionType = "unary"
                                    notNode.operator = "not"
                                    notNode.child[1] = lhsNode
                                    lhsNode = notNode
                                end
                                local rhsNode = syncActionNode.child[2]
                                local andNode = self.ovaleAst:NewNode(nodeList, true)
                                andNode.type = "logical"
                                andNode.expressionType = "binary"
                                andNode.operator = "and"
                                andNode.child[1] = lhsNode
                                andNode.child[2] = rhsNode
                                node = andNode
                            else
                                self.tracer:Print("Warning: Unable to emit action for 'sync=%s'.", name)
                                name = self:Disambiguate(annotation, name, className, specialization)
                                self:AddSymbol(annotation, name)
                                code = format("Spell(%s)", name)
                            end
                        end
                    end
                end
                if node then
                    annotation.astAnnotation.sync = annotation.astAnnotation.sync or {}
                    annotation.astAnnotation.sync[name] = node
                end
            end
            if  not node and code then
                annotation.astAnnotation = annotation.astAnnotation or {}
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            end
            return node
        end
        self.EmitConditionNode = function(nodeList, bodyNode, extraConditionNode, parseNode, annotation, action, modifiers)
            local conditionNode = nil
            for modifier, expressionNode in kpairs(parseNode.modifiers) do
                local rhsNode = self.EmitModifier(modifier, expressionNode, nodeList, annotation, action, modifiers)
                if rhsNode then
                    if  not conditionNode then
                        conditionNode = rhsNode
                    else
                        local lhsNode = conditionNode
                        conditionNode = self.ovaleAst:NewNode(nodeList, true)
                        conditionNode.type = "logical"
                        conditionNode.expressionType = "binary"
                        conditionNode.operator = "and"
                        conditionNode.child[1] = lhsNode
                        conditionNode.child[2] = rhsNode
                    end
                end
            end
            if extraConditionNode then
                if conditionNode then
                    local lhsNode = conditionNode
                    local rhsNode = extraConditionNode
                    conditionNode = self.ovaleAst:NewNode(nodeList, true)
                    conditionNode.type = "logical"
                    conditionNode.expressionType = "binary"
                    conditionNode.operator = "and"
                    conditionNode.child[1] = lhsNode
                    conditionNode.child[2] = rhsNode
                else
                    conditionNode = extraConditionNode
                end
            end
            if conditionNode then
                local node = self.ovaleAst:NewNode(nodeList, true)
                node.type = "if"
                node.child[1] = conditionNode
                node.child[2] = bodyNode
                if bodyNode.type == "simc_pool_resource" then
                    node.simc_pool_resource = true
                elseif bodyNode.type == "simc_wait" then
                    node.simc_wait = true
                end
                return node
            else
                return bodyNode
            end
        end
        self.EmitNamedVariable = function(name, nodeList, annotation, modifiers, parseNode, action, conditionNode)
            local node = annotation.variable[name]
            local group
            if  not node then
                node = self.ovaleAst:NewNode(nodeList, true)
                annotation.variable[name] = node
                node.type = "add_function"
                node.name = name
                group = self.ovaleAst:NewNode(nodeList, true)
                group.type = "group"
                node.child[1] = group
            else
                group = node.child[1]
            end
            annotation.currentVariable = node
            if  not modifiers.value then
                self.tracer:Error("'value' modifier is undefined")
                return 
            end
            local value = self:Emit(modifiers.value, nodeList, annotation, action)
            if  not value then
                return 
            end
            local newNode = self.EmitConditionNode(nodeList, value, conditionNode, parseNode, annotation, action, modifiers)
            if newNode.type == "if" then
                insert(group.child, 1, newNode)
            else
                insert(group.child, newNode)
            end
            annotation.currentVariable = nil
        end
        self.EmitVariableMin = function(name, nodeList, annotation, modifier, parseNode, action)
            self.EmitNamedVariable(name .. "_min", nodeList, annotation, modifier, parseNode, action)
            local valueNode = annotation.variable[name]
            valueNode.name = name .. "_value"
            annotation.variable[valueNode.name] = valueNode
            local bodyCode = format("AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }", name, name, name, name, name)
            local node = self.ovaleAst:ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation)
            if node then
                annotation.variable[name] = node
            end
        end
        self.EmitVariableMax = function(name, nodeList, annotation, modifier, parseNode, action)
            self.EmitNamedVariable(name .. "_max", nodeList, annotation, modifier, parseNode, action)
            local valueNode = annotation.variable[name]
            valueNode.name = name .. "_value"
            annotation.variable[valueNode.name] = valueNode
            local bodyCode = format("AddFunction %s { if %s_value() < %s_max() %s_value() %s_max() }", name, name, name, name, name)
            local node = self.ovaleAst:ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation)
            if node then
                annotation.variable[name] = node
            end
        end
        self.EmitVariableAdd = function(name, nodeList, annotation, modifiers, parseNode, action)
            local valueNode = annotation.variable[name]
            if valueNode then
                return 
            end
            self.EmitNamedVariable(name, nodeList, annotation, modifiers, parseNode, action)
        end
        self.EmitVariableSub = function(name, nodeList, annotation, modifiers, parseNode, action)
            local valueNode = annotation.variable[name]
            if valueNode then
                return 
            end
            self.EmitNamedVariable(name, nodeList, annotation, modifiers, parseNode, action)
        end
        self.EmitVariableIf = function(name, nodeList, annotation, modifiers, parseNode, action)
            local node = annotation.variable[name]
            local group
            if  not node then
                node = self.ovaleAst:NewNode(nodeList, true)
                annotation.variable[name] = node
                node.type = "add_function"
                node.name = name
                group = self.ovaleAst:NewNode(nodeList, true)
                group.type = "group"
                node.child[1] = group
            else
                group = node.child[1]
            end
            annotation.currentVariable = node
            if  not modifiers.condition or  not modifiers.value or  not modifiers.value_else then
                self.tracer:Error("Modifier missing in if")
                return 
            end
            local ifNode = self.ovaleAst:NewNode(nodeList, true)
            ifNode.type = "if"
            local condition = self:Emit(modifiers.condition, nodeList, annotation, nil)
            local value = self:Emit(modifiers.value, nodeList, annotation, nil)
            if  not condition or  not value then
                return 
            end
            ifNode.child[1] = condition
            ifNode.child[2] = value
            insert(group.child, ifNode)
            local elseNode = self.ovaleAst:NewNode(nodeList, true)
            elseNode.type = "unless"
            elseNode.child[1] = ifNode.child[1]
            local valueElse = self:Emit(modifiers.value_else, nodeList, annotation, nil)
            if  not valueElse then
                return 
            end
            elseNode.child[2] = valueElse
            insert(group.child, elseNode)
            annotation.currentVariable = nil
        end
        self.EmitVariable = function(nodeList, annotation, modifier, parseNode, action, conditionNode)
            local op = (modifier.op and self.unparser:Unparse(modifier.op)) or "set"
            if  not modifier.name then
                self.tracer:Error("Modifier name is missing")
                return 
            end
            local name = self.unparser:Unparse(modifier.name)
            if  not name then
                self.tracer:Error("Unable to parse name of variable in %s", modifier.name)
                return 
            end
            if match(name, "^%d") then
                name = "_" .. name
            end
            if op == "min" then
                self.EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action)
            elseif op == "max" then
                self.EmitVariableMax(name, nodeList, annotation, modifier, parseNode, action)
            elseif op == "add" then
                self.EmitVariableAdd(name, nodeList, annotation, modifier, parseNode, action)
            elseif op == "set" then
                self.EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode)
            elseif op == "setif" then
                self.EmitVariableIf(name, nodeList, annotation, modifier, parseNode, action)
            elseif op == "sub" then
                self.EmitVariableSub(name, nodeList, annotation, modifier, parseNode, action)
            elseif op == "reset" then
            else
                self.tracer:Error("Unknown variable operator '%s'.", op)
            end
        end
        self.EmitAction = function(parseNode, nodeList, annotation)
            local node
            local canonicalizedName = lower(gsub(parseNode.name, ":", "_"))
            local className = annotation.classId
            local specialization = annotation.specialization
            local camelSpecialization = LowerSpecialization(annotation)
            local role = annotation.role
            local action, type = self:Disambiguate(annotation, canonicalizedName, className, specialization, "Spell")
            local bodyNode
            local conditionNode
            if action == "auto_attack" and  not annotation.melee then
            elseif action == "auto_shot" then
            elseif action == "choose_target" then
            elseif action == "augmentation" or action == "flask" or action == "food" then
            elseif action == "snapshot_stats" then
            else
                local bodyCode, conditionCode
                local expressionType = "expression"
                local modifiers = parseNode.modifiers
                local isSpellAction = true
                if interruptsClasses[action] == className then
                    bodyCode = camelSpecialization .. "InterruptActions()"
                    annotation[action] = className
                    annotation.interrupt = className
                    isSpellAction = false
                elseif className == "DRUID" and action == "pulverize" then
                    local debuffName = "thrash_bear_debuff"
                    self:AddSymbol(annotation, debuffName)
                    conditionCode = format("target.DebuffGain(%s) <= BaseDuration(%s)", debuffName, debuffName)
                elseif className == "DRUID" and specialization == "guardian" and action == "rejuvenation" then
                    local spellName = "enhanced_rejuvenation"
                    self:AddSymbol(annotation, spellName)
                    conditionCode = format("SpellKnown(%s)", spellName)
                elseif className == "DRUID" and action == "wild_charge" then
                    bodyCode = camelSpecialization .. "GetInMeleeRange()"
                    annotation[action] = className
                    isSpellAction = false
                elseif className == "DRUID" and action == "new_moon" then
                    conditionCode = "not SpellKnown(half_moon) and not SpellKnown(full_moon)"
                    self:AddSymbol(annotation, "half_moon")
                    self:AddSymbol(annotation, "full_moon")
                elseif className == "DRUID" and action == "half_moon" then
                    conditionCode = "SpellKnown(half_moon)"
                elseif className == "DRUID" and action == "full_moon" then
                    conditionCode = "SpellKnown(full_moon)"
                elseif className == "DRUID" and action == "regrowth" and specialization == "feral" then
                    conditionCode = "Talent(bloodtalons_talent) and (BuffRemaining(bloodtalons_buff) < CastTime(regrowth)+GCDRemaining() or InCombat())"
                    self:AddSymbol(annotation, "bloodtalons_talent")
                    self:AddSymbol(annotation, "bloodtalons_buff")
                    self:AddSymbol(annotation, "regrowth")
                elseif className == "HUNTER" and action == "kill_command" then
                    conditionCode = "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()"
                elseif className == "MAGE" and action == "arcane_brilliance" then
                    conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)"
                elseif className == "MAGE" and find(action, "pet_") then
                    conditionCode = "pet.Present()"
                elseif className == "MAGE" and (action == "start_burn_phase" or action == "start_pyro_chain" or action == "stop_burn_phase" or action == "stop_pyro_chain") then
                    local stateAction, stateVariable = match(action, "([^_]+)_(.*)")
                    local value = (stateAction == "start" and 1) or 0
                    if value == 0 then
                        conditionCode = format("GetState(%s) > 0", stateVariable)
                    else
                        conditionCode = format("not GetState(%s) > 0", stateVariable)
                    end
                    bodyCode = format("SetState(%s %d)", stateVariable, value)
                    isSpellAction = false
                elseif className == "MAGE" and action == "time_warp" then
                    conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)"
                    annotation[action] = className
                elseif className == "MAGE" and action == "summon_water_elemental" then
                    conditionCode = "not pet.Present()"
                elseif className == "MAGE" and action == "ice_floes" then
                    conditionCode = "Speed() > 0"
                elseif className == "MAGE" and action == "blast_wave" then
                    conditionCode = "target.Distance(less 8)"
                elseif className == "MAGE" and action == "dragons_breath" then
                    conditionCode = "target.Distance(less 12)"
                elseif className == "MAGE" and action == "arcane_blast" then
                    conditionCode = "Mana() > ManaCost(arcane_blast)"
                elseif className == "MAGE" and action == "cone_of_cold" then
                    conditionCode = "target.Distance() < 12"
                elseif className == "MONK" and action == "chi_sphere" then
                    isSpellAction = false
                elseif className == "MONK" and action == "gift_of_the_ox" then
                    isSpellAction = false
                elseif className == "MONK" and action == "nimble_brew" then
                    conditionCode = "IsFeared() or IsRooted() or IsStunned()"
                elseif className == "MONK" and action == "storm_earth_and_fire" then
                    conditionCode = "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff)"
                    annotation[action] = className
                elseif className == "MONK" and action == "touch_of_death" then
                    conditionCode = "(not CheckBoxOn(opt_touch_of_death_on_elite_only) or (not UnitInRaid() and target.Classification(elite)) or target.Classification(worldboss)) or not BuffExpires(hidden_masters_forbidden_touch_buff)"
                    annotation[action] = className
                    annotation.opt_touch_of_death_on_elite_only = "MONK"
                    self:AddSymbol(annotation, "hidden_masters_forbidden_touch_buff")
                elseif className == "MONK" and action == "whirling_dragon_punch" then
                    conditionCode = "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0"
                elseif className == "PALADIN" and action == "blessing_of_kings" then
                    conditionCode = "BuffExpires(mastery_buff)"
                elseif className == "PALADIN" and action == "judgment" then
                    if modifiers.cycle_targets then
                        self:AddSymbol(annotation, action)
                        bodyCode = "Spell(" .. action .. " text=double)"
                        isSpellAction = false
                    end
                elseif className == "PALADIN" and specialization == "protection" and action == "arcane_torrent_holy" then
                    isSpellAction = false
                elseif className == "ROGUE" and action == "adrenaline_rush" then
                    conditionCode = "EnergyDeficit() > 1"
                elseif className == "ROGUE" and action == "apply_poison" then
                    if modifiers.lethal then
                        local name = self.unparser:Unparse(modifiers.lethal)
                        action = name .. "_poison"
                        local buffName = "lethal_poison_buff"
                        self:AddSymbol(annotation, buffName)
                        conditionCode = format("BuffRemaining(%s) < 1200", buffName)
                    else
                        isSpellAction = false
                    end
                elseif className == "ROGUE" and action == "cancel_autoattack" then
                    isSpellAction = false
                elseif className == "ROGUE" and action == "premeditation" then
                    conditionCode = "ComboPoints() < 5"
                elseif className == "ROGUE" and specialization == "assassination" and action == "vanish" then
                    annotation.vanish = className
                    conditionCode = format("CheckBoxOn(opt_vanish)", action)
                elseif className == "SHAMAN" and sub(action, 1, 11) == "ascendance_" then
                    local buffName = action .. "_buff"
                    self:AddSymbol(annotation, buffName)
                    conditionCode = format("BuffExpires(%s)", buffName)
                elseif className == "SHAMAN" and action == "bloodlust" then
                    bodyCode = camelSpecialization .. "Bloodlust()"
                    annotation[action] = className
                    isSpellAction = false
                elseif className == "SHAMAN" and action == "magma_totem" then
                    local spellName = "primal_strike"
                    self:AddSymbol(annotation, spellName)
                    conditionCode = format("target.InRange(%s)", spellName)
                elseif className == "WARLOCK" and action == "felguard_felstorm" then
                    conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)"
                elseif className == "WARLOCK" and action == "grimoire_of_sacrifice" then
                    conditionCode = "pet.Present()"
                elseif className == "WARLOCK" and action == "havoc" then
                    conditionCode = "Enemies() > 1"
                elseif className == "WARLOCK" and action == "service_pet" then
                    if annotation.pet then
                        local spellName = "service_" .. annotation.pet
                        self:AddSymbol(annotation, spellName)
                        bodyCode = format("Spell(%s)", spellName)
                    else
                        bodyCode = "Texture(spell_nature_removecurse help=ServicePet)"
                    end
                    isSpellAction = false
                elseif className == "WARLOCK" and action == "summon_pet" then
                    if annotation.pet then
                        local spellName = "summon_" .. annotation.pet
                        self:AddSymbol(annotation, spellName)
                        bodyCode = format("Spell(%s)", spellName)
                    else
                        bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))"
                    end
                    conditionCode = "not pet.Present()"
                    isSpellAction = false
                elseif className == "WARLOCK" and action == "wrathguard_wrathstorm" then
                    conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)"
                elseif className == "WARRIOR" and action == "battle_shout" and role == "tank" then
                    conditionCode = "BuffExpires(stamina_buff)"
                elseif className == "WARRIOR" and action == "charge" then
                    conditionCode = "CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel)"
                    self:AddSymbol(annotation, "pummel")
                elseif className == "WARRIOR" and action == "commanding_shout" and role == "attack" then
                    conditionCode = "BuffExpires(attack_power_multiplier_buff)"
                elseif className == "WARRIOR" and action == "enraged_regeneration" then
                    conditionCode = "HealthPercent() < 80"
                elseif className == "WARRIOR" and sub(action, 1, 7) == "execute" then
                    if modifiers.target then
                        local target = tonumber(self.unparser:Unparse(modifiers.target))
                        if target then
                            isSpellAction = false
                        end
                    end
                elseif className == "WARRIOR" and action == "heroic_charge" then
                    isSpellAction = false
                elseif className == "WARRIOR" and action == "heroic_leap" then
                    conditionCode = "CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40)"
                elseif action == "auto_attack" then
                    bodyCode = camelSpecialization .. "GetInMeleeRange()"
                    isSpellAction = false
                elseif className == "DEMONHUNTER" and action == "metamorphosis_havoc" then
                    conditionCode = "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()"
                    annotation.opt_meta_only_during_boss = "DEMONHUNTER"
                elseif className == "DEMONHUNTER" and action == "consume_magic" then
                    conditionCode = "target.HasDebuffType(magic)"
                elseif checkOptionalSkill(action, className, specialization) then
                    annotation[action] = className
                    conditionCode = "CheckBoxOn(opt_" .. action .. ")"
                elseif action == "variable" then
                    self.EmitVariable(nodeList, annotation, modifiers, parseNode, action)
                    isSpellAction = false
                elseif action == "call_action_list" or action == "run_action_list" or action == "swap_action_list" then
                    if modifiers.name then
                        local name = self.unparser:Unparse(modifiers.name)
                        if name then
                            local functionName = OvaleFunctionName(name, annotation)
                            bodyCode = functionName .. "()"
                            if className == "MAGE" and specialization == "arcane" and (name == "burn" or name == "init_burn") then
                                conditionCode = "CheckBoxOn(opt_arcane_mage_burn_phase)"
                                annotation.opt_arcane_mage_burn_phase = className
                            end
                        end
                        isSpellAction = false
                    end
                elseif action == "cancel_buff" then
                    if modifiers.name then
                        local spellName = self.unparser:Unparse(modifiers.name)
                        if spellName then
                            local buffName = self:Disambiguate(annotation, spellName .. "_buff", className, specialization, "spell")
                            self:AddSymbol(annotation, spellName)
                            self:AddSymbol(annotation, buffName)
                            bodyCode = format("Texture(%s text=cancel)", spellName)
                            conditionCode = format("BuffPresent(%s)", buffName)
                            isSpellAction = false
                        end
                    end
                elseif action == "pool_resource" then
                    bodyNode = self.ovaleAst:NewNode(nodeList)
                    bodyNode.type = "simc_pool_resource"
                    bodyNode.for_next = modifiers.for_next ~= nil
                    if modifiers.extra_amount then
                        bodyNode.extra_amount = tonumber(self.unparser:Unparse(modifiers.extra_amount))
                    end
                    isSpellAction = false
                elseif action == "potion" then
                    local name = (modifiers.name and self.unparser:Unparse(modifiers.name)) or annotation.consumables["potion"]
                    if name then
                        name = self:Disambiguate(annotation, name .. "_item", className, specialization, "item")
                        bodyCode = format("Item(%s usable=1)", name)
                        conditionCode = "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)"
                        annotation.opt_use_consumables = className
                        self:AddSymbol(annotation, name)
                        isSpellAction = false
                    end
                elseif action == "sequence" then
                    isSpellAction = false
                elseif action == "stance" then
                    if modifiers.choose then
                        local name = self.unparser:Unparse(modifiers.choose)
                        if name then
                            if className == "MONK" then
                                action = "stance_of_the_" .. name
                            elseif className == "WARRIOR" then
                                action = name .. "_stance"
                            else
                                action = name
                            end
                        end
                    else
                        isSpellAction = false
                    end
                elseif action == "summon_pet" then
                    bodyCode = camelSpecialization .. "SummonPet()"
                    annotation[action] = className
                    isSpellAction = false
                elseif action == "use_items" then
                    bodyCode = camelSpecialization .. "UseItemActions()"
                    annotation["use_item"] = true
                    isSpellAction = false
                elseif action == "use_item" then
                    local legendaryRing = nil
                    if modifiers.slot then
                        local slot = self.unparser:Unparse(modifiers.slot)
                        if slot and match(slot, "finger") then
                            legendaryRing = self:Disambiguate(annotation, "legendary_ring", className, specialization)
                        end
                    elseif modifiers.name then
                        local name = self.unparser:Unparse(modifiers.name)
                        if name then
                            name = self:Disambiguate(annotation, name, className, specialization)
                            if match(name, "legendary_ring") then
                                legendaryRing = name
                            end
                        end
                    elseif modifiers.effect_name then
                    end
                    if legendaryRing then
                        conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing)
                        bodyCode = format("Item(%s usable=1)", legendaryRing)
                        self:AddSymbol(annotation, legendaryRing)
                        annotation.use_legendary_ring = legendaryRing
                    else
                        bodyCode = camelSpecialization .. "UseItemActions()"
                        annotation[action] = true
                    end
                    isSpellAction = false
                elseif action == "wait" then
                    if modifiers.sec then
                        local seconds = tonumber(self.unparser:Unparse(modifiers.sec))
                        if seconds then
                        else
                            bodyNode = self.ovaleAst:NewNode(nodeList)
                            bodyNode.type = "simc_wait"
                            local expressionNode = self:Emit(modifiers.sec, nodeList, annotation, action)
                            if expressionNode then
                                local code = self.ovaleAst:Unparse(expressionNode)
                                conditionCode = code .. " > 0"
                            end
                        end
                    end
                    isSpellAction = false
                elseif action == "heart_essence" then
                    bodyCode = camelSpecialization .. "UseHeartEssence()"
                    annotation.use_heart_essence = true
                    isSpellAction = false
                end
                if isSpellAction then
                    self:AddSymbol(annotation, action)
                    if modifiers.target then
                        local actionTarget = self.unparser:Unparse(modifiers.target)
                        if actionTarget == "2" then
                            actionTarget = "other"
                        end
                        if actionTarget ~= "1" then
                            bodyCode = format("%s(%s text=%s)", type, action, actionTarget)
                        end
                    end
                    bodyCode = bodyCode or type .. "(" .. action .. ")"
                end
                if  not bodyNode and bodyCode then
                    bodyNode = self.ovaleAst:ParseCode(expressionType, bodyCode, nodeList, annotation.astAnnotation)
                end
                if  not conditionNode and conditionCode then
                    conditionNode = self.ovaleAst:ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation)
                end
                if bodyNode then
                    node = self.EmitConditionNode(nodeList, bodyNode, conditionNode, parseNode, annotation, action, modifiers)
                end
            end
            return node
        end
        self.EmitActionList = function(parseNode, nodeList, annotation)
            local groupNode = self.ovaleAst:NewNode(nodeList, true)
            groupNode.type = "group"
            local child = groupNode.child
            local poolResourceNode
            local emit = true
            for _, actionNode in ipairs(parseNode.child) do
                local commentNode = self.ovaleAst:NewNode(nodeList)
                commentNode.type = "comment"
                commentNode.comment = actionNode.action
                child[#child + 1] = commentNode
                if emit then
                    local statementNode = self.EmitAction(actionNode, nodeList, annotation, actionNode.name)
                    if statementNode then
                        if statementNode.type == "simc_pool_resource" then
                            local powerType = POOLED_RESOURCE[annotation.classId]
                            if powerType then
                                if statementNode.for_next then
                                    poolResourceNode = statementNode
                                    poolResourceNode.powerType = powerType
                                else
                                    emit = false
                                end
                            end
                        elseif poolResourceNode then
                            child[#child + 1] = statementNode
                            local bodyNode
                            local poolingConditionNode
                            if statementNode.child then
                                poolingConditionNode = statementNode.child[1]
                                bodyNode = statementNode.child[2]
                            else
                                bodyNode = statementNode
                            end
                            local powerType = CamelCase(poolResourceNode.powerType)
                            local extra_amount = poolResourceNode.extra_amount
                            if extra_amount and poolingConditionNode then
                                local code = self.ovaleAst:Unparse(poolingConditionNode)
                                local extraAmountPattern = powerType .. "%(%) >= [%d.]+"
                                local replaceString = format("True(pool_%s %d)", poolResourceNode.powerType, extra_amount)
                                code = gsub(code, extraAmountPattern, replaceString)
                                poolingConditionNode = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                            end
                            if bodyNode.type == "action" and bodyNode.rawPositionalParams and bodyNode.rawPositionalParams[1] then
                                local name = self.ovaleAst:Unparse(bodyNode.rawPositionalParams[1])
                                local powerCondition
                                if extra_amount then
                                    powerCondition = format("TimeTo%s(%d)", powerType, extra_amount)
                                else
                                    powerCondition = format("TimeTo%sFor(%s)", powerType, name)
                                end
                                local code = format("SpellUsable(%s) and SpellCooldown(%s) < %s", name, name, powerCondition)
                                local conditionNode = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                                if conditionNode then
                                    if statementNode.child and poolingConditionNode then
                                        local rhsNode = conditionNode
                                        conditionNode = self.ovaleAst:NewNode(nodeList, true)
                                        conditionNode.type = "logical"
                                        conditionNode.expressionType = "binary"
                                        conditionNode.operator = "and"
                                        conditionNode.child[1] = poolingConditionNode
                                        conditionNode.child[2] = rhsNode
                                    end
                                    local restNode = self.ovaleAst:NewNode(nodeList, true)
                                    child[#child + 1] = restNode
                                    if statementNode.type == "unless" then
                                        restNode.type = "if"
                                    else
                                        restNode.type = "unless"
                                    end
                                    restNode.child[1] = conditionNode
                                    restNode.child[2] = self.ovaleAst:NewNode(nodeList, true)
                                    restNode.child[2].type = "group"
                                    child = restNode.child[2].child
                                end
                            end
                            poolResourceNode = nil
                        elseif statementNode.type == "simc_wait" then
                        elseif statementNode.simc_wait then
                            local restNode = self.ovaleAst:NewNode(nodeList, true)
                            child[#child + 1] = restNode
                            restNode.type = "unless"
                            restNode.child[1] = statementNode.child[1]
                            restNode.child[2] = self.ovaleAst:NewNode(nodeList, true)
                            restNode.child[2].type = "group"
                            child = restNode.child[2].child
                        else
                            child[#child + 1] = statementNode
                            if statementNode.simc_pool_resource then
                                if statementNode.type == "if" then
                                    statementNode.type = "unless"
                                elseif statementNode.type == "unless" then
                                    statementNode.type = "if"
                                end
                                statementNode.child[2] = self.ovaleAst:NewNode(nodeList, true)
                                statementNode.child[2].type = "group"
                                child = statementNode.child[2].child
                            end
                        end
                    end
                end
            end
            local node = self.ovaleAst:NewNode(nodeList, true)
            node.type = "add_function"
            node.name = OvaleFunctionName(parseNode.name, annotation)
            node.child[1] = groupNode
            return node
        end
        self.EmitExpression = function(parseNode, nodeList, annotation, action)
            local node
            local msg
            if parseNode.expressionType == "unary" then
                local opInfo = UNARY_OPERATOR[parseNode.operator]
                if opInfo then
                    local operator
                    if parseNode.operator == "!" then
                        operator = "not"
                    elseif parseNode.operator == "-" then
                        operator = parseNode.operator
                    end
                    if operator then
                        local rhsNode = self:Emit(parseNode.child[1], nodeList, annotation, action)
                        if rhsNode then
                            if operator == "-" and isNodeType(rhsNode, "value") then
                                rhsNode.value = -1 * rhsNode.value
                            else
                                node = self.ovaleAst:NewNode(nodeList, true)
                                node.type = opInfo[1]
                                node.expressionType = "unary"
                                node.operator = operator
                                node.precedence = opInfo[2]
                                node.child[1] = rhsNode
                            end
                        end
                    end
                end
            elseif parseNode.expressionType == "binary" then
                local opInfo = BINARY_OPERATOR[parseNode.operator]
                if opInfo then
                    local parseNodeOperator = parseNode.operator
                    local operator
                    if parseNodeOperator == "&" then
                        operator = "and"
                    elseif parseNodeOperator == "^" then
                        operator = "xor"
                    elseif parseNodeOperator == "|" then
                        operator = "or"
                    elseif parseNodeOperator == "=" then
                        operator = "=="
                    elseif parseNodeOperator == "%" then
                        operator = "/"
                    elseif parseNode.operatorType == "compare" or parseNode.operatorType == "arithmetic" then
                        if parseNodeOperator ~= "~" and parseNodeOperator ~= "!~" then
                            operator = parseNodeOperator
                        end
                    end
                    if (parseNode.operator == "=" or parseNode.operator == "!=") and (parseNode.child[1].name == "target" or parseNode.child[1].name == "current_target") and parseNode.child[2].name then
                        local name = parseNode.child[2].name
                        if find(name, "^[%a_]+%.") then
                            name = match(name, "^[%a_]+%.([%a_]+)")
                        end
                        local code
                        if name == "sim_target" then
                            code = "True(target_is_sim_target)"
                        elseif name == "target" then
                            code = "False(target_is_target)"
                        else
                            code = format("target.Name(%s)", name)
                            self:AddSymbol(annotation, name)
                        end
                        if parseNode.operator == "!=" then
                            code = "not " .. code
                        end
                        annotation.astAnnotation = annotation.astAnnotation or {}
                        node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    elseif (parseNode.operator == "=" or parseNode.operator == "!=") and parseNode.child[1].name == "sim_target" then
                        local code
                        if parseNode.operator == "=" then
                            code = "True(target_is_sim_target)"
                        else
                            code = "False(target_is_sim_target)"
                        end
                        annotation.astAnnotation = annotation.astAnnotation or {}
                        node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    elseif operator then
                        local lhsNode = self:Emit(parseNode.child[1], nodeList, annotation, action)
                        local rhsNode = self:Emit(parseNode.child[2], nodeList, annotation, action)
                        if lhsNode and rhsNode then
                            node = self.ovaleAst:NewNode(nodeList, true)
                            node.type = opInfo[1]
                            node.expressionType = "binary"
                            node.operator = operator
                            node.child[1] = lhsNode
                            node.child[2] = rhsNode
                        elseif lhsNode then
                            msg = MakeString("Warning: %s operator '%s' right failed.", parseNode.type, parseNode.operator)
                        elseif rhsNode then
                            msg = MakeString("Warning: %s operator '%s' left failed.", parseNode.type, parseNode.operator)
                        else
                            msg = MakeString("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator)
                        end
                    end
                end
            end
            if node then
                if parseNode.left and parseNode.right then
                    node.left = "{"
                    node.right = "}"
                end
            else
                msg = msg or MakeString("Warning: Operator '%s' is not implemented.", parseNode.operator)
                self.tracer:Print(msg)
                local stringNode = self.ovaleAst:NewNode(nodeList)
                stringNode.type = "string"
                stringNode.value = "FIXME_" .. parseNode.operator
                return stringNode
            end
            return node
        end
        self.EmitFunction = function(parseNode, nodeList, annotation, action)
            local node
            if parseNode.name == "ceil" or parseNode.name == "floor" then
                node = self:Emit(parseNode.child[1], nodeList, annotation, action)
            else
                self.tracer:Print("Warning: Function '%s' is not implemented.", parseNode.name)
                node = self.ovaleAst:NewNode(nodeList)
                node.type = "variable"
                node.name = "FIXME_" .. parseNode.name
            end
            return node
        end
        self.EmitNumber = function(parseNode, nodeList, annotation, action)
            local node = self.ovaleAst:NewNode(nodeList)
            node.type = "value"
            node.value = parseNode.value
            node.origin = 0
            node.rate = 0
            return node
        end
        self.EmitOperand = function(parseNode, nodeList, annotation, action)
            local node
            local operand = parseNode.name
            local token = match(operand, OPERAND_TOKEN_PATTERN)
            local target
            if token == "target" then
                node = self.EmitOperandTarget(operand, parseNode, nodeList, annotation, action)
                if  not node then
                    target = token
                    operand = sub(operand, len(target) + 2)
                    token = match(operand, OPERAND_TOKEN_PATTERN)
                end
            end
            if  not node then
                node = self.EmitOperandRune(operand, parseNode, nodeList, annotation, action)
            end
            if  not node then
                node = self.EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target)
            end
            if  not node then
                node = self.EmitOperandRaidEvent(operand, parseNode, nodeList, annotation, action)
            end
            if  not node then
                node = self.EmitOperandRace(operand, parseNode, nodeList, annotation, action)
            end
            if  not node then
                node = self.EmitOperandAction(operand, parseNode, nodeList, annotation, action, target)
            end
            if  not node then
                node = self.EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target)
            end
            if  not node then
                if token == "active_dot" then
                    target = target or "target"
                    node = self.EmitOperandActiveDot(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "aura" then
                    node = self.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "artifact" then
                    node = self.EmitOperandArtifact(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "azerite" then
                    node = self.EmitOperandAzerite(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "buff" then
                    node = self.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "consumable" then
                    node = self.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "cooldown" then
                    node = self.EmitOperandCooldown(operand, parseNode, nodeList, annotation, action)
                elseif token == "debuff" then
                    target = target or "target"
                    node = self.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "disease" then
                    target = target or "target"
                    node = self.EmitOperandDisease(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "dot" then
                    target = target or "target"
                    node = self.EmitOperandDot(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "essence" then
                    node = self.EmitOperandEssence(operand, parseNode, nodeList, annotation, action, target)
                elseif token == "glyph" then
                    node = self.EmitOperandGlyph(operand, parseNode, nodeList, annotation, action)
                elseif token == "pet" then
                    node = self.EmitOperandPet(operand, parseNode, nodeList, annotation, action)
                elseif token == "prev" or token == "prev_gcd" or token == "prev_off_gcd" then
                    node = self.EmitOperandPreviousSpell(operand, parseNode, nodeList, annotation, action)
                elseif token == "refreshable" then
                    node = self.EmitOperandRefresh(operand, parseNode, nodeList, annotation, action)
                elseif token == "seal" then
                    node = self.EmitOperandSeal(operand, parseNode, nodeList, annotation, action)
                elseif token == "set_bonus" then
                    node = self.EmitOperandSetBonus(operand, parseNode, nodeList, annotation, action)
                elseif token == "stack" then
                    node = self.ovaleAst:ParseCode("expression", "buffstacks(" .. action .. ")", nodeList, annotation.astAnnotation)
                elseif token == "talent" then
                    node = self.EmitOperandTalent(operand, parseNode, nodeList, annotation, action)
                elseif token == "totem" then
                    node = self.EmitOperandTotem(operand, parseNode, nodeList, annotation, action)
                elseif token == "trinket" then
                    node = self.EmitOperandTrinket(operand, parseNode, nodeList, annotation, action)
                elseif token == "variable" then
                    node = self.EmitOperandVariable(operand, parseNode, nodeList, annotation, action)
                elseif token == "ground_aoe" then
                    node = self.EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action)
                else
                    node = self:emitMiscOperand(operand, parseNode, nodeList, annotation, action)
                end
            end
            if  not node then
                self.tracer:Print("Warning: Variable '%s' is not implemented.", parseNode.name)
                node = self.ovaleAst:newFunction(nodeList, "message", true)
                node.rawPositionalParams[1] = self.ovaleAst:newString(nodeList, parseNode.name .. " is not implemented")
            end
            return node
        end
        self.EmitOperandAction = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local name
            local property
            if sub(operand, 1, 7) == "action." then
                local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
                tokenIterator()
                name = tokenIterator()
                property = tokenIterator()
            else
                name = action
                property = operand
            end
            if  not name then
                return nil
            end
            local className, specialization = annotation.classId, annotation.specialization
            name = self:Disambiguate(annotation, name, className, specialization)
            target = (target and target .. ".") or ""
            local buffName = name .. "_debuff"
            buffName = self:Disambiguate(annotation, buffName, className, specialization)
            local prefix = (find(buffName, "_debuff$") and "Debuff") or "Buff"
            local buffTarget = (prefix == "Debuff" and "target.") or target
            local talentName = name .. "_talent"
            talentName = self:Disambiguate(annotation, talentName, className, specialization)
            local symbol = name
            local code
            if property == "active" then
                if IsTotem(name) then
                    code = format("TotemPresent(%s)", name)
                else
                    code = format("%s%sPresent(%s)", target, prefix, buffName)
                    symbol = buffName
                end
            elseif property == "ap_check" then
                code = format("AstralPower() >= AstralPowerCost(%s)", name)
            elseif property == "cast_regen" then
                code = format("FocusCastingRegen(%s)", name)
            elseif property == "cast_time" then
                code = format("CastTime(%s)", name)
            elseif property == "charges" then
                code = format("Charges(%s)", name)
            elseif property == "max_charges" then
                code = format("SpellMaxCharges(%s)", name)
            elseif property == "charges_fractional" then
                code = format("Charges(%s count=0)", name)
            elseif property == "cooldown" then
                code = format("SpellCooldown(%s)", name)
            elseif property == "cooldown_react" then
                code = format("not SpellCooldown(%s) > 0", name)
            elseif property == "cost" then
                code = format("PowerCost(%s)", name)
            elseif property == "crit_damage" then
                code = format("%sCritDamage(%s)", target, name)
            elseif property == "damage" then
                code = format("%sDamage(%s)", target, name)
            elseif property == "duration" or property == "new_duration" then
                code = format("BaseDuration(%s)", buffName)
                symbol = buffName
            elseif property == "enabled" then
                if parseNode.asType == "boolean" then
                    code = format("Talent(%s)", talentName)
                else
                    code = format("TalentPoints(%s)", talentName)
                end
                symbol = talentName
            elseif property == "execute_time" or property == "execute_remains" then
                code = format("ExecuteTime(%s)", name)
            elseif property == "executing" then
                code = format("ExecuteTime(%s) > 0", name)
            elseif property == "gcd" then
                code = "GCD()"
            elseif property == "hit_damage" then
                code = format("%sDamage(%s)", target, name)
            elseif property == "in_flight" or property == "in_flight_to_target" then
                code = format("InFlightToTarget(%s)", name)
            elseif property == "in_flight_remains" then
                code = "0"
            elseif property == "miss_react" then
                code = "True(miss_react)"
            elseif property == "persistent_multiplier" or property == "pmultiplier" then
                code = format("PersistentMultiplier(%s)", buffName)
            elseif property == "recharge_time" then
                code = format("SpellChargeCooldown(%s)", name)
            elseif property == "full_recharge_time" then
                code = format("SpellFullRecharge(%s)", name)
            elseif property == "remains" then
                if IsTotem(name) then
                    code = format("TotemRemaining(%s)", name)
                else
                    code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName)
                    symbol = buffName
                end
            elseif property == "shard_react" then
                code = "SoulShards() >= 1"
            elseif property == "tick_dmg" or property == "tick_damage" then
                code = format("%sLastDamage(%s)", buffTarget, buffName)
            elseif property == "tick_time" then
                code = format("%sCurrentTickTime(%s)", buffTarget, buffName)
                symbol = buffName
            elseif property == "ticking" then
                code = format("%s%sPresent(%s)", buffTarget, prefix, buffName)
                symbol = buffName
            elseif property == "ticks_remain" then
                code = format("%sTicksRemaining(%s)", buffTarget, buffName)
                symbol = buffName
            elseif property == "travel_time" then
                code = format("TravelTime(%s)", name)
            elseif property == "usable" then
                code = format("CanCast(%s)", name)
            elseif property == "usable_in" then
                code = format("SpellCooldown(%s)", name)
            elseif property == "marks_next_gcd" then
                code = "0"
            end
            if code then
                if name == "call_action_list" and property ~= "gcd" then
                    self.tracer:Print("Warning: dubious use of call_action_list in %s", code)
                end
                annotation.astAnnotation = annotation.astAnnotation or {}
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                if  not SPECIAL_ACTION[symbol] then
                    self:AddSymbol(annotation, symbol)
                end
            end
            return node
        end
        self.EmitOperandActiveDot = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "active_dot" then
                local name = tokenIterator()
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local dotName = name .. "_debuff"
                dotName = self:Disambiguate(annotation, dotName, annotation.classId, annotation.specialization)
                local prefix = (find(dotName, "_buff$") and "Buff") or "Debuff"
                target = (target and target .. ".") or ""
                local code = format("%sCountOnAny(%s)", prefix, dotName)
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, dotName)
                end
            end
            return node
        end
        self.EmitOperandArtifact = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "artifact" then
                local code
                local name = tokenIterator()
                local property = tokenIterator()
                if property == "rank" then
                    code = format("ArtifactTraitRank(%s)", name)
                elseif property == "enabled" then
                    code = format("HasArtifactTrait(%s)", name)
                end
                if code then
                    annotation.astAnnotation = annotation.astAnnotation or {}
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, name)
                end
            end
            return node
        end
        self.EmitOperandAzerite = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "azerite" then
                local code
                local name = tokenIterator()
                local property = tokenIterator()
                if property == "rank" then
                    code = format("AzeriteTraitRank(%s_trait)", name)
                elseif property == "enabled" then
                    code = format("HasAzeriteTrait(%s_trait)", name)
                end
                if code then
                    annotation.astAnnotation = annotation.astAnnotation or {}
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, name .. "_trait")
                end
            end
            return node
        end
        self.EmitOperandEssence = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "essence" then
                local code
                local name = tokenIterator()
                local property = tokenIterator()
                local essenceId = format("%s_essence_id", name)
                essenceId = self:Disambiguate(annotation, essenceId, annotation.classId, annotation.specialization)
                if property == "major" then
                    code = format("AzeriteEssenceIsMajor(%s)", essenceId)
                elseif property == "minor" then
                    code = format("AzeriteEssenceIsMinor(%s)", essenceId)
                elseif property == "enabled" then
                    code = format("AzeriteEssenceIsEnabled(%s)", essenceId)
                elseif property == "rank" then
                    code = format("AzeriteEssenceRank(%s)", essenceId)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, essenceId)
                end
            end
            return node
        end
        self.EmitOperandRefresh = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "refreshable" then
                local buffName = action .. "_debuff"
                buffName = self:Disambiguate(annotation, buffName, annotation.classId, annotation.specialization)
                local target
                local prefix = (find(buffName, "_buff$") and "Buff") or "Debuff"
                if prefix == "Debuff" then
                    target = "target."
                else
                    target = ""
                end
                local any = (self.ovaleData.DEFAULT_SPELL_LIST[buffName] and " any=1") or ""
                local code = format("%sRefreshable(%s%s)", target, buffName, any)
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                self:AddSymbol(annotation, buffName)
            end
            return node
        end
        self.EmitOperandBuff = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "aura" or token == "buff" or token == "debuff" or token == "consumable" then
                local name = tokenIterator()
                local property = tokenIterator()
                if token == "consumable" and property == nil then
                    property = "remains"
                end
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local buffName = (token == "debuff" and name .. "_debuff") or name .. "_buff"
                buffName = self:Disambiguate(annotation, buffName, annotation.classId, annotation.specialization)
                local prefix
                if  not find(buffName, "_debuff$") and  not find(buffName, "_debuff$") then
                    prefix = (target == "target" and "Debuff") or "Buff"
                else
                    prefix = (find(buffName, "_debuff$") and "Debuff") or "Buff"
                end
                local any = (self.ovaleData.DEFAULT_SPELL_LIST[buffName] and " any=1") or ""
                target = (target and target .. ".") or ""
                if buffName == "dark_transformation_buff" and target == "" then
                    target = "pet."
                end
                if buffName == "pet_beast_cleave_buff" and target == "" then
                    target = "pet."
                end
                if buffName == "pet_frenzy_buff" and target == "" then
                    target = "pet."
                end
                local code
                if property == "cooldown_remains" then
                    code = format("SpellCooldown(%s)", name)
                elseif property == "down" then
                    code = format("%s%sExpires(%s%s)", target, prefix, buffName, any)
                elseif property == "duration" then
                    code = format("BaseDuration(%s)", buffName)
                elseif property == "max_stack" then
                    code = format("SpellData(%s max_stacks)", buffName)
                elseif property == "react" or property == "stack" then
                    if parseNode.asType == "boolean" then
                        code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
                    else
                        code = format("%s%sStacks(%s%s)", target, prefix, buffName, any)
                    end
                elseif property == "remains" then
                    if parseNode.asType == "boolean" then
                        code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
                    else
                        code = format("%s%sRemaining(%s%s)", target, prefix, buffName, any)
                    end
                elseif property == "up" then
                    code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
                elseif property == "improved" then
                    code = format("%sImproved(%s%s)", prefix, buffName)
                elseif property == "value" then
                    code = format("%s%sAmount(%s%s)", target, prefix, buffName, any)
                end
                if code then
                    annotation.astAnnotation = annotation.astAnnotation or {}
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, buffName)
                end
            end
            return node
        end
        self.EmitOperandCharacter = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local className = annotation.classId
            local specialization = annotation.specialization
            local camelSpecialization = LowerSpecialization(annotation)
            target = (target and target .. ".") or ""
            local code
            if CHARACTER_PROPERTY[operand] then
                code = target .. CHARACTER_PROPERTY[operand]
            elseif operand == "position_front" then
                code = (annotation.position == "front" and "True(position_front)") or "False(position_front)"
            elseif operand == "position_back" then
                code = (annotation.position == "back" and "True(position_back)") or "False(position_back)"
            elseif className == "MAGE" and operand == "incanters_flow_dir" then
                local name = "incanters_flow_buff"
                code = format("BuffDirection(%s)", name)
                self:AddSymbol(annotation, name)
            elseif className == "PALADIN" and operand == "time_to_hpg" then
                code = camelSpecialization .. "TimeToHPG()"
                if specialization == "holy" then
                    annotation.time_to_hpg_heal = className
                elseif specialization == "protection" then
                    annotation.time_to_hpg_tank = className
                elseif specialization == "retribution" then
                    annotation.time_to_hpg_melee = className
                end
            elseif className == "PRIEST" and operand == "shadowy_apparitions_in_flight" then
                code = "1"
            elseif operand == "rtb_buffs" then
                code = "BuffCount(roll_the_bones_buff)"
            elseif className == "ROGUE" and operand == "anticipation_charges" then
                local name = "anticipation_buff"
                code = format("BuffStacks(%s)", name)
                self:AddSymbol(annotation, name)
            elseif sub(operand, 1, 22) == "active_enemies_within." then
                code = "Enemies()"
            elseif find(operand, "^incoming_damage_") then
                local _seconds, measure = match(operand, "^incoming_damage_([%d]+)(m?s?)$")
                local seconds = tonumber(_seconds)
                if measure == "ms" then
                    seconds = seconds / 1000
                end
                if parseNode.asType == "boolean" then
                    code = format("IncomingDamage(%f) > 0", seconds)
                else
                    code = format("IncomingDamage(%f)", seconds)
                end
            elseif sub(operand, 1, 10) == "main_hand." then
                local weaponType = sub(operand, 11)
                if weaponType == "1h" then
                    code = "HasWeapon(main type=one_handed)"
                elseif weaponType == "2h" then
                    code = "HasWeapon(main type=two_handed)"
                end
            elseif operand == "mastery_value" then
                code = format("%sMasteryEffect() / 100", target)
            elseif sub(operand, 1, 5) == "role." then
                local role = match(operand, "^role%.([%w_]+)")
                if role and role == annotation.role then
                    code = format("True(role_%s)", role)
                else
                    code = format("False(role_%s)", role)
                end
            elseif operand == "spell_haste" or operand == "stat.spell_haste" then
                code = "100 / { 100 + SpellCastSpeedPercent() }"
            elseif operand == "attack_haste" or operand == "stat.attack_haste" then
                code = "100 / { 100 + MeleeAttackSpeedPercent() }"
            elseif sub(operand, 1, 13) == "spell_targets" then
                code = "Enemies()"
            elseif operand == "t18_class_trinket" then
                code = format("HasTrinket(%s)", operand)
                self:AddSymbol(annotation, operand)
            end
            if code then
                annotation.astAnnotation = annotation.astAnnotation or {}
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            end
            return node
        end
        self.EmitOperandCooldown = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "cooldown" then
                local name = tokenIterator()
                local property = tokenIterator()
                local prefix
                name, prefix = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization, "Spell")
                local code
                if property == "execute_time" then
                    code = format("ExecuteTime(%s)", name)
                elseif property == "duration" then
                    code = format("%sCooldownDuration(%s)", prefix, name)
                elseif property == "ready" then
                    code = format("%sCooldown(%s) == 0", prefix, name)
                elseif property == "remains" or property == "remains_guess" or property == "adjusted_remains" then
                    if parseNode.asType == "boolean" then
                        code = format("%sCooldown(%s) > 0", prefix, name)
                    else
                        code = format("%sCooldown(%s)", prefix, name)
                    end
                elseif property == "up" then
                    code = format("not %sCooldown(%s) > 0", prefix, name)
                elseif property == "charges" then
                    if parseNode.asType == "boolean" then
                        code = format("%sCharges(%s) > 0", prefix, name)
                    else
                        code = format("%sCharges(%s)", prefix, name)
                    end
                elseif property == "charges_fractional" then
                    code = format("%sCharges(%s count=0)", prefix, name)
                elseif property == "max_charges" then
                    code = format("%sMaxCharges(%s)", prefix, name)
                elseif property == "full_recharge_time" then
                    code = format("%sCooldown(%s)", prefix, name)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, name)
                end
            end
            return node
        end
        self.EmitOperandDisease = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "disease" then
                local property = tokenIterator()
                target = (target and target .. ".") or ""
                local code
                if property == "max_ticking" then
                    code = target .. "DiseasesAnyTicking()"
                elseif property == "min_remains" then
                    code = target .. "DiseasesRemaining()"
                elseif property == "min_ticking" then
                    code = target .. "DiseasesTicking()"
                elseif property == "ticking" then
                    code = target .. "DiseasesAnyTicking()"
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandGroundAoe = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "ground_aoe" then
                local name = tokenIterator()
                local property = tokenIterator()
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local dotName = name .. "_debuff"
                dotName = self:Disambiguate(annotation, dotName, annotation.classId, annotation.specialization)
                local prefix = (find(dotName, "_buff$") and "Buff") or "Debuff"
                local target = (prefix == "Debuff" and "target.") or ""
                local code
                if property == "remains" then
                    code = format("%s%sRemaining(%s)", target, prefix, dotName)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, dotName)
                end
            end
            return node
        end
        self.EmitOperandDot = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "dot" then
                local name = tokenIterator()
                local property = tokenIterator()
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local dotName = name .. "_debuff"
                dotName = self:Disambiguate(annotation, dotName, annotation.classId, annotation.specialization)
                local prefix = (find(dotName, "_buff$") and "Buff") or "Debuff"
                target = (target and target .. ".") or ""
                local code
                if property == "duration" then
                    code = format("%s%sDuration(%s)", target, prefix, dotName)
                elseif property == "pmultiplier" then
                    code = format("%s%sPersistentMultiplier(%s)", target, prefix, dotName)
                elseif property == "remains" then
                    code = format("%s%sRemaining(%s)", target, prefix, dotName)
                elseif property == "stack" then
                    code = format("%s%sStacks(%s)", target, prefix, dotName)
                elseif property == "tick_dmg" then
                    code = format("%sTickValue(%s)", target, prefix, dotName)
                elseif property == "ticking" then
                    code = format("%s%sPresent(%s)", target, prefix, dotName)
                elseif property == "ticks_remain" then
                    code = format("%sTicksRemaining(%s)", target, dotName)
                elseif property == "tick_time_remains" then
                    code = format("%sTickTimeRemaining(%s)", target, dotName)
                elseif property == "exsanguinated" then
                    code = format("TargetDebuffRemaining(%s_exsanguinated)", dotName)
                elseif property == "refreshable" then
                    code = format("%s%sRefreshable(%s)", target, prefix, dotName)
                elseif property == "max_stacks" then
                    code = format("MaxStacks(%s)", dotName)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, dotName)
                end
            end
            return node
        end
        self.EmitOperandGlyph = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "glyph" then
                local name = tokenIterator()
                local property = tokenIterator()
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local glyphName = "glyph_of_" .. name
                glyphName = self:Disambiguate(annotation, glyphName, annotation.classId, annotation.specialization)
                local code
                if property == "disabled" then
                    code = format("not Glyph(%s)", glyphName)
                elseif property == "enabled" then
                    code = format("Glyph(%s)", glyphName)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, glyphName)
                end
            end
            return node
        end
        self.EmitOperandPet = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "pet" then
                local name = tokenIterator()
                local property = tokenIterator()
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local isTotem = IsTotem(name)
                local code
                if isTotem and property == "active" then
                    code = format("TotemPresent(%s)", name)
                elseif isTotem and property == "remains" then
                    code = format("TotemRemaining(%s)", name)
                elseif property == "active" then
                    code = "pet.Present()"
                elseif name == "buff" then
                    local pattern = format("^pet%%.([%%w_.]+)", operand)
                    local petOperand = match(operand, pattern)
                    node = self.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, "pet")
                else
                    local pattern = format("^pet%%.%s%%.([%%w_.]+)", name)
                    local petOperand = match(operand, pattern)
                    local target = "pet"
                    if petOperand then
                        node = self.EmitOperandSpecial(petOperand, parseNode, nodeList, annotation, action, target)
                        if  not node then
                            node = self.EmitOperandAction(petOperand, parseNode, nodeList, annotation, action, target)
                        end
                        if  not node then
                            node = self.EmitOperandCharacter(petOperand, parseNode, nodeList, annotation, action, target)
                        end
                        if  not node then
                            local petAbilityName = match(petOperand, "^[%w_]+%.([^.]+)")
                            petAbilityName = self:Disambiguate(annotation, petAbilityName, annotation.classId, annotation.specialization)
                            if sub(petAbilityName, 1, 4) ~= "pet_" then
                                petOperand = gsub(petOperand, "^([%w_]+)%.", "%1." .. name .. "_")
                            end
                            if property == "buff" then
                                node = self.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
                            elseif property == "cooldown" then
                                node = self.EmitOperandCooldown(petOperand, parseNode, nodeList, annotation, action)
                            elseif property == "debuff" then
                                node = self.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
                            elseif property == "dot" then
                                node = self.EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target)
                            end
                        end
                    end
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    if isTotem then
                        self:AddSymbol(annotation, name)
                    end
                end
            end
            return node
        end
        self.EmitOperandPreviousSpell = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "prev" or token == "prev_gcd" or token == "prev_off_gcd" then
                local name = tokenIterator()
                local howMany = 1
                if tonumber(name) then
                    howMany = tonumber(name)
                    name = tokenIterator()
                end
                name = self:Disambiguate(annotation, name, annotation.classId, annotation.specialization)
                local code
                if token == "prev" then
                    code = format("PreviousSpell(%s)", name)
                elseif token == "prev_gcd" then
                    if howMany ~= 1 then
                        code = format("PreviousGCDSpell(%s count=%d)", name, howMany)
                    else
                        code = format("PreviousGCDSpell(%s)", name)
                    end
                else
                    code = format("PreviousOffGCDSpell(%s)", name)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, name)
                end
            end
            return node
        end
        self.EmitOperandRaidEvent = function(operand, parseNode, nodeList, annotation, action)
            local node
            local name
            local property
            if sub(operand, 1, 11) == "raid_event." then
                local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
                tokenIterator()
                name = tokenIterator()
                property = tokenIterator()
            else
                local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
                name = tokenIterator()
                property = tokenIterator()
            end
            local code
            if name == "movement" then
                if property == "cooldown" or property == "in" then
                    code = "600"
                elseif property == "distance" then
                    code = "target.Distance()"
                elseif property == "exists" then
                    code = "False(raid_event_movement_exists)"
                elseif property == "remains" then
                    code = "0"
                end
            elseif name == "adds" then
                if property == "cooldown" then
                    code = "600"
                elseif property == "count" then
                    code = "0"
                elseif property == "exists" or property == "up" then
                    code = "False(raid_event_adds_exists)"
                elseif property == "in" then
                    code = "600"
                elseif property == "duration" then
                    code = "10"
                end
            elseif name == "invulnerable" then
                if property == "up" then
                    code = "False(raid_events_invulnerable_up)"
                end
            end
            if code then
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            end
            return node
        end
        self.EmitOperandRace = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "race" then
                local race = lower(tokenIterator())
                local code
                if race then
                    local raceId = nil
                    if race == "blood_elf" then
                        raceId = "BloodElf"
                    elseif race == "troll" then
                        raceId = "Troll"
                    elseif race == "orc" then
                        raceId = "Orc"
                    else
                        self.tracer:Print("Warning: Race '%s' not defined", race)
                    end
                    code = format("Race(%s)", raceId)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandRune = function(operand, parseNode, nodeList, annotation, action)
            local node
            local code
            if parseNode.rune then
                if parseNode.asType == "boolean" then
                    code = "RuneCount() >= 1"
                else
                    code = "RuneCount()"
                end
            elseif match(operand, "^rune.time_to_([%d]+)$") then
                local runes = match(operand, "^rune.time_to_([%d]+)$")
                code = format("TimeToRunes(%d)", runes)
            else
                return nil
            end
            node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            return node
        end
        self.EmitOperandSetBonus = function(operand, parseNode, nodeList, annotation, action)
            local node
            local setBonus = match(operand, "^set_bonus%.(.*)$")
            local code
            if setBonus then
                local tokenIterator = gmatch(setBonus, "[^_]+")
                local name = tokenIterator()
                local count = tokenIterator()
                local role = tokenIterator()
                if name and count then
                    local setName, level = match(name, "^(%a+)(%d*)$")
                    if setName == "tier" then
                        setName = "T"
                    else
                        setName = upper(setName)
                    end
                    if level then
                        name = setName .. tostring(level)
                    end
                    if role then
                        name = name .. "_" .. role
                    end
                    count = match(count, "(%d+)pc")
                    if name and count then
                        code = format("ArmorSetBonus(%s %d)", name, count)
                    end
                end
            end
            if code then
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            end
            return node
        end
        self.EmitOperandSeal = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "seal" then
                local name = lower(tokenIterator())
                local code
                if name then
                    code = format("Stance(paladin_seal_of_%s)", name)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandSpecial = function(operand, parseNode, nodeList, annotation, action, target)
            local node
            local className = annotation.classId
            local specialization = annotation.specialization
            target = (target and target .. ".") or ""
            operand = lower(operand)
            local code
            if className == "DEATHKNIGHT" and operand == "dot.breath_of_sindragosa.ticking" then
                local buffName = "breath_of_sindragosa"
                code = format("BuffPresent(%s)", buffName)
                self:AddSymbol(annotation, buffName)
            elseif className == "DEATHKNIGHT" and sub(operand, 1, 24) == "pet.dancing_rune_weapon." then
                local petOperand = sub(operand, 25)
                local tokenIterator = gmatch(petOperand, OPERAND_TOKEN_PATTERN)
                local token = tokenIterator()
                if token == "active" then
                    local buffName = "dancing_rune_weapon_buff"
                    code = format("BuffPresent(%s)", buffName)
                    self:AddSymbol(annotation, buffName)
                elseif token == "dot" then
                    if target == "" then
                        target = "target"
                    else
                        target = sub(target, 1, -2)
                    end
                    node = self.EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target)
                end
            elseif className == "DEMONHUNTER" and operand == "buff.metamorphosis.extended_by_demonic" then
                code = "not BuffExpires(extended_by_demonic_buff)"
            elseif className == "DEMONHUNTER" and operand == "cooldown.chaos_blades.ready" then
                code = "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0"
                self:AddSymbol(annotation, "chaos_blades_talent")
                self:AddSymbol(annotation, "chaos_blades")
            elseif className == "DEMONHUNTER" and operand == "cooldown.nemesis.ready" then
                code = "Talent(nemesis_talent) and SpellCooldown(nemesis) == 0"
                self:AddSymbol(annotation, "nemesis_talent")
                self:AddSymbol(annotation, "nemesis")
            elseif className == "DEMONHUNTER" and operand == "cooldown.metamorphosis.ready" and specialization == "havoc" then
                code = "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis_havoc) == 0"
                self:AddSymbol(annotation, "metamorphosis_havoc")
            elseif className == "DRUID" and operand == "buff.wild_charge_movement.down" then
                code = "True(wild_charge_movement_down)"
            elseif className == "DRUID" and operand == "eclipse_dir.lunar" then
                code = "EclipseDir() < 0"
            elseif className == "DRUID" and operand == "eclipse_dir.solar" then
                code = "EclipseDir() > 0"
            elseif className == "DRUID" and operand == "max_fb_energy" then
                local spellName = "ferocious_bite"
                code = format("EnergyCost(%s max=1)", spellName)
                self:AddSymbol(annotation, spellName)
            elseif className == "DRUID" and operand == "solar_wrath.ap_check" then
                local spellName = "solar_wrath"
                code = format("AstralPower() >= AstralPowerCost(%s)", spellName)
                self:AddSymbol(annotation, spellName)
            elseif className == "HUNTER" and operand == "buff.careful_aim.up" then
                code = "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)"
                self:AddSymbol(annotation, "rapid_fire_buff")
            elseif className == "HUNTER" and operand == "buff.stampede.remains" then
                local spellName = "stampede"
                code = format("TimeSincePreviousSpell(%s) < 40", spellName)
                self:AddSymbol(annotation, spellName)
            elseif className == "HUNTER" and operand == "lowest_vuln_within.5" then
                code = "target.DebuffRemaining(vulnerable)"
                self:AddSymbol(annotation, "vulnerable")
            elseif className == "HUNTER" and operand == "cooldown.trueshot.duration_guess" then
                code = "0"
            elseif className == "HUNTER" and operand == "ca_execute" then
                code = "Talent(careful_aim_talent) and (target.HealthPercent() > 80 or target.HealthPercent() < 20)"
                self:AddSymbol(annotation, "careful_aim_talent")
            elseif className == "MAGE" and operand == "buff.rune_of_power.remains" then
                code = "TotemRemaining(rune_of_power)"
            elseif className == "MAGE" and operand == "buff.shatterlance.up" then
                code = "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)"
                self:AddSymbol(annotation, "frostbolt")
                self:AddSymbol(annotation, "t18_class_trinket")
            elseif className == "MAGE" and (operand == "burn_phase" or operand == "pyro_chain") then
                if parseNode.asType == "boolean" then
                    code = format("GetState(%s) > 0", operand)
                else
                    code = format("GetState(%s)", operand)
                end
            elseif className == "MAGE" and (operand == "burn_phase_duration" or operand == "pyro_chain_duration") then
                local variable = sub(operand, 1, -10)
                if parseNode.asType == "boolean" then
                    code = format("GetStateDuration(%s) > 0", variable)
                else
                    code = format("GetStateDuration(%s)", variable)
                end
            elseif className == "MAGE" and operand == "firestarter.active" then
                code = "Talent(firestarter_talent) and target.HealthPercent() >= 90"
                self:AddSymbol(annotation, "firestarter_talent")
            elseif className == "MAGE" and operand == "brain_freeze_active" then
                code = "target.DebuffPresent(winters_chill_debuff)"
                self:AddSymbol(annotation, "winters_chill_debuff")
            elseif className == "MAGE" and operand == "action.frozen_orb.in_flight" then
                code = "TimeSincePreviousSpell(frozen_orb) < 10"
                self:AddSymbol(annotation, "frozen_orb")
            elseif className == "MONK" and sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target." then
                local property = sub(operand, 36)
                if target == "" then
                    target = "target."
                end
                local debuffName = "storm_earth_and_fire_target_debuff"
                self:AddSymbol(annotation, debuffName)
                if property == "down" then
                    code = format("%sDebuffExpires(%s)", target, debuffName)
                elseif property == "up" then
                    code = format("%sDebuffPresent(%s)", target, debuffName)
                end
            elseif className == "MONK" and operand == "dot.zen_sphere.ticking" then
                local buffName = "zen_sphere_buff"
                code = format("BuffPresent(%s)", buffName)
                self:AddSymbol(annotation, buffName)
            elseif className == "MONK" and sub(operand, 1, 8) == "stagger." then
                local property = sub(operand, 9)
                if property == "heavy" or property == "light" or property == "moderate" then
                    local buffName = format("%s_stagger_debuff", property)
                    code = format("DebuffPresent(%s)", buffName)
                    self:AddSymbol(annotation, buffName)
                elseif property == "pct" then
                    code = format("%sStaggerRemaining() / %sMaxHealth() * 100", target, target)
                elseif match(property, "last_tick_damage_(%d+)") then
                    local ticks = match(property, "last_tick_damage_(%d+)")
                    code = format("StaggerTick(%d)", ticks)
                end
            elseif className == "MONK" and operand == "spinning_crane_kick.count" then
                code = "SpellCount(spinning_crane_kick)"
                self:AddSymbol(annotation, "spinning_crane_kick")
            elseif className == "MONK" and operand == "combo_strike" then
                if action then
                    code = format("not PreviousSpell(%s)", action)
                end
            elseif className == "MONK" and operand == "combo_break" then
                if action then
                    code = format("PreviousSpell(%s)", action)
                end
            elseif className == "PALADIN" and operand == "dot.sacred_shield.remains" then
                local buffName = "sacred_shield_buff"
                code = format("BuffRemaining(%s)", buffName)
                self:AddSymbol(annotation, buffName)
            elseif className == "PRIEST" and operand == "mind_harvest" then
                code = "target.MindHarvest()"
            elseif className == "PRIEST" and operand == "natural_shadow_word_death_range" then
                code = "target.HealthPercent() < 20"
            elseif className == "PRIEST" and operand == "primary_target" then
                code = "1"
            elseif className == "ROGUE" and operand == "trinket.cooldown.up" then
                code = "HasTrinket(draught_of_souls) and ItemCooldown(draught_of_souls) > 0"
                self:AddSymbol(annotation, "draught_of_souls")
            elseif className == "ROGUE" and operand == "mantle_duration" then
                code = "BuffRemaining(master_assassins_initiative)"
                self:AddSymbol(annotation, "master_assassins_initiative")
            elseif className == "ROGUE" and operand == "poisoned_enemies" then
                code = "0"
            elseif className == "ROGUE" and operand == "poisoned_bleeds" then
                code = "DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)"
                self:AddSymbol(annotation, "rupture_debuff")
                self:AddSymbol(annotation, "garrote_debuff")
                self:AddSymbol(annotation, "internal_bleeding_talent")
                self:AddSymbol(annotation, "internal_bleeding_debuff")
            elseif className == "ROGUE" and operand == "exsanguinated" then
                code = "target.DebuffPresent(exsanguinated)"
                self:AddSymbol(annotation, "exsanguinated")
            elseif className == "ROGUE" and operand == "ss_buffed" then
                code = "False(ss_buffed)"
            elseif className == "ROGUE" and operand == "non_ss_buffed_targets" then
                code = "Enemies() - DebuffCountOnAny(garrote_debuff)"
                self:AddSymbol(annotation, "garrote_debuff")
            elseif className == "ROGUE" and operand == "ss_buffed_targets_above_pandemic" then
                code = "0"
            elseif className == "ROGUE" and operand == "master_assassin_remains" then
                code = "BuffRemaining(master_assassin_buff)"
                self:AddSymbol(annotation, "master_assassin_buff")
            elseif className == "ROGUE" and operand == "buff.roll_the_bones.remains" then
                code = "BuffRemaining(roll_the_bones_buff)"
                self:AddSymbol(annotation, "roll_the_bones_buff")
            elseif className == "ROGUE" and operand == "buff.roll_the_bones.up" then
                code = "BuffPresent(roll_the_bones_buff)"
                self:AddSymbol(annotation, "roll_the_bones_buff")
            elseif className == "SHAMAN" and operand == "buff.resonance_totem.remains" then
                local spell = self:Disambiguate(annotation, "totem_mastery", annotation.classId, annotation.specialization)
                code = format("TotemRemaining(%s)", spell)
                self:AddSymbol(annotation, spell)
            elseif className == "SHAMAN" and match(operand, "pet.[a-z_]+.active") then
                code = "pet.Present()"
            elseif className == "WARLOCK" and match(operand, "pet%.service_[a-z_]+%..+") then
                local spellName, property = match(operand, "pet%.(service_[a-z_]+)%.(.+)")
                if property == "active" then
                    code = format("SpellCooldown(%s) > 100", spellName)
                    self:AddSymbol(annotation, spellName)
                end
            elseif className == "WARLOCK" and match(operand, "dot.unstable_affliction_([1-5]).remains") then
                local num = match(operand, "dot.unstable_affliction_([1-5]).remains")
                code = format("target.DebuffStacks(unstable_affliction_debuff) >= %s", num)
            elseif className == "WARLOCK" and operand == "buff.active_uas.stack" then
                code = "target.DebuffStacks(unstable_affliction_debuff)"
            elseif className == "WARLOCK" and match(operand, "pet%.[a-z_]+%..+") then
                local spellName, property = match(operand, "pet%.([a-z_]+)%.(.+)")
                if property == "remains" then
                    code = format("DemonDuration(%s)", spellName)
                elseif property == "active" then
                    code = format("DemonDuration(%s) > 0", spellName)
                end
            elseif className == "WARLOCK" and operand == "contagion" then
                code = "BuffRemaining(unstable_affliction_buff)"
            elseif className == "WARLOCK" and operand == "buff.wild_imps.stack" then
                code = "Demons(wild_imp) + Demons(wild_imp_inner_demons)"
                self:AddSymbol(annotation, "wild_imp")
                self:AddSymbol(annotation, "wild_imp_inner_demons")
            elseif className == "WARLOCK" and operand == "buff.dreadstalkers.remains" then
                code = "DemonDuration(dreadstalker)"
                self:AddSymbol(annotation, "dreadstalker")
            elseif className == "WARLOCK" and match(operand, "imps_spawned_during.([%d]+)") then
                local ms = match(operand, "imps_spawned_during.([%d]+)")
                code = format("ImpsSpawnedDuring(%d)", ms)
            elseif className == "WARLOCK" and operand == "time_to_imps.all.remains" then
                code = "0"
            elseif className == "WARLOCK" and operand == "havoc_active" then
                code = "DebuffCountOnAny(havoc) > 0"
                self:AddSymbol(annotation, "havoc")
            elseif className == "WARLOCK" and operand == "havoc_remains" then
                code = "DebuffRemainingOnAny(havoc)"
                self:AddSymbol(annotation, "havoc")
            elseif className == "WARRIOR" and operand == "gcd.remains" and (action == "battle_cry" or action == "avatar") then
                code = "0"
            elseif operand == "buff.enrage.down" then
                code = "not " .. target .. "IsEnraged()"
            elseif operand == "buff.enrage.remains" then
                code = target .. "EnrageRemaining()"
            elseif operand == "buff.enrage.up" then
                code = target .. "IsEnraged()"
            elseif operand == "debuff.casting.react" then
                code = target .. "IsInterruptible()"
            elseif operand == "debuff.casting.up" then
                local t = (target == "" and "target.") or target
                code = t .. "IsInterruptible()"
            elseif operand == "debuff.flying.down" then
                code = target .. "True(debuff_flying_down)"
            elseif operand == "distance" then
                code = target .. "Distance()"
            elseif sub(operand, 1, 9) == "equipped." then
                local name = self:Disambiguate(annotation, sub(operand, 10) .. "_item", className, specialization)
                local itemId = tonumber(name)
                local itemName = name
                local item = (itemId and tostring(itemId)) or itemName
                code = format("HasEquippedItem(%s)", item)
                self:AddSymbol(annotation, item)
            elseif operand == "gcd.max" then
                code = "GCD()"
            elseif operand == "gcd.remains" then
                code = "GCDRemaining()"
            elseif sub(operand, 1, 15) == "legendary_ring." then
                local name = self:Disambiguate(annotation, "legendary_ring", className, specialization)
                local buffName = name .. "_buff"
                local properties = sub(operand, 16)
                local tokenIterator = gmatch(properties, OPERAND_TOKEN_PATTERN)
                local token = tokenIterator()
                if token == "cooldown" then
                    token = tokenIterator()
                    if token == "down" then
                        code = format("ItemCooldown(%s) > 0", name)
                        self:AddSymbol(annotation, name)
                    elseif token == "remains" then
                        code = format("ItemCooldown(%s)", name)
                        self:AddSymbol(annotation, name)
                    elseif token == "up" then
                        code = format("not ItemCooldown(%s) > 0", name)
                        self:AddSymbol(annotation, name)
                    end
                elseif token == "has_cooldown" then
                    code = format("ItemCooldown(%s) > 0", name)
                    self:AddSymbol(annotation, name)
                elseif token == "up" then
                    code = format("BuffPresent(%s)", buffName)
                    self:AddSymbol(annotation, buffName)
                elseif token == "remains" then
                    code = format("BuffRemaining(%s)", buffName)
                    self:AddSymbol(annotation, buffName)
                end
            elseif operand == "ptr" then
                code = "PTR()"
            elseif operand == "time_to_die" then
                code = "target.TimeToDie()"
            elseif sub(operand, 1, 10) == "using_apl." then
                local aplName = match(operand, "^using_apl%.([%w_]+)")
                code = format("List(opt_using_apl %s)", aplName)
                annotation.using_apl = annotation.using_apl or {}
                annotation.using_apl[aplName] = true
            elseif operand == "cooldown.buff_sephuzs_secret.remains" then
                code = "BuffCooldown(sephuzs_secret_buff)"
                self:AddSymbol(annotation, "sephuzs_secret_buff")
            elseif operand == "is_add" then
                local t = target or "target."
                code = format("not %sClassification(worldboss)", t)
            elseif operand == "priority_rotation" then
                code = "CheckBoxOn(opt_priority_rotation)"
                annotation.opt_priority_rotation = className
            end
            if code then
                node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            end
            return node
        end
        self.EmitOperandTalent = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "talent" then
                local name = lower(tokenIterator())
                local property = tokenIterator()
                local talentName = name .. "_talent"
                talentName = self:Disambiguate(annotation, talentName, annotation.classId, annotation.specialization)
                local code
                if property == "disabled" then
                    if parseNode.asType == "boolean" then
                        code = format("not HasTalent(%s)", talentName)
                    else
                        code = format("HasTalent(%s no)", talentName)
                    end
                elseif property == "enabled" then
                    if parseNode.asType == "boolean" then
                        code = format("HasTalent(%s)", talentName)
                    else
                        code = format("TalentPoints(%s)", talentName)
                    end
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    self:AddSymbol(annotation, talentName)
                end
            end
            return node
        end
        self.EmitOperandTarget = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "target" then
                local property = tokenIterator()
                local howMany = 1
                if tonumber(property) then
                    howMany = tonumber(property)
                    property = tokenIterator()
                end
                if howMany > 1 then
                    self.tracer:Print("Warning: target.%d.%property has not been implemented for multiple targets. (%s)", operand)
                end
                local code
                if property == "adds" then
                    code = "Enemies()-1"
                elseif property == "time_to_die" then
                    code = "target.TimeToDie()"
                elseif property == "distance" then
                    code = "target.Distance()"
                elseif property == "health" then
                    local modifier = tokenIterator()
                    if modifier == "pct" then
                        code = "target.HealthPercent()"
                    end
                else
                    local percent = match(property, "^time_to_pct_(%d+)")
                    if percent then
                        code = "target.TimeToHealthPercent(" .. percent .. ")"
                    end
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandTotem = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "totem" then
                local name = lower(tokenIterator())
                local property = tokenIterator()
                local code
                if property == "active" then
                    code = format("TotemPresent(%s)", name)
                elseif property == "remains" then
                    code = format("TotemRemaining(%s)", name)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandTrinket = function(operand, parseNode, nodeList, annotation, action)
            local node
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            if token == "trinket" then
                local procType = tokenIterator()
                if procType == "1" or procType == "2" then
                    procType = tokenIterator()
                end
                local statName = tokenIterator()
                local code
                if procType == "cooldown" then
                    if statName == "remains" then
                        code = "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }"
                    end
                elseif sub(procType, 1, 4) == "has_" then
                    code = format("True(trinket_%s_%s)", procType, statName)
                else
                    local property = tokenIterator()
                    local buffName = format("trinket_%s_%s_buff", procType, statName)
                    buffName = self:Disambiguate(annotation, buffName, annotation.classId, annotation.specialization)
                    if property == "cooldown" then
                        code = format("BuffCooldownDuration(%s)", buffName)
                    elseif property == "cooldown_remains" then
                        code = format("BuffCooldown(%s)", buffName)
                    elseif property == "down" then
                        code = format("BuffExpires(%s)", buffName)
                    elseif property == "react" then
                        if parseNode.asType == "boolean" then
                            code = format("BuffPresent(%s)", buffName)
                        else
                            code = format("BuffStacks(%s)", buffName)
                        end
                    elseif property == "remains" then
                        code = format("BuffRemaining(%s)", buffName)
                    elseif property == "stack" then
                        code = format("BuffStacks(%s)", buffName)
                    elseif property == "up" then
                        code = format("BuffPresent(%s)", buffName)
                    end
                    self:AddSymbol(annotation, buffName)
                end
                if code then
                    node = self.ovaleAst:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                end
            end
            return node
        end
        self.EmitOperandVariable = function(operand, parseNode, nodeList, annotation, action)
            local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
            local token = tokenIterator()
            local node
            if token == "variable" then
                local name = tokenIterator()
                if  not name then
                    self.tracer:Error("Unable to parse variable name in EmitOperandVariable")
                elseif annotation.currentVariable and annotation.currentVariable.name == name then
                    local group = annotation.currentVariable.child[1]
                    if #group.child == 0 then
                        node = self.ovaleAst:ParseCode("expression", "0", nodeList, annotation.astAnnotation)
                    else
                        node = self.ovaleAst:ParseCode("expression", self.ovaleAst:Unparse(group), nodeList, annotation.astAnnotation)
                    end
                else
                    node = self.ovaleAst:NewNode(nodeList)
                    node.type = "function"
                    node.name = name
                end
            end
            return node
        end
        self.EMIT_VISITOR = {
            ["action"] = self.EmitAction,
            ["action_list"] = self.EmitActionList,
            ["operator"] = self.EmitExpression,
            ["function"] = self.EmitFunction,
            ["number"] = self.EmitNumber,
            ["operand"] = self.EmitOperand
        }
        self.tracer = ovaleDebug:create("SimulationCraftEmiter")
    end,
    AddDisambiguation = function(self, name, info, className, specialization, _type)
        self:AddPerClassSpecialization(self.EMIT_DISAMBIGUATION, name, info, className, specialization, _type)
    end,
    Disambiguate = function(self, annotation, name, className, specialization, _type)
        if className and annotation.dictionary[name .. "_" .. className] then
            return name .. "_" .. className, _type
        end
        if specialization and annotation.dictionary[name .. "_" .. specialization] then
            return name .. "_" .. specialization, _type
        end
        local disname, distype = self:GetPerClassSpecialization(self.EMIT_DISAMBIGUATION, name, className, specialization)
        if  not disname then
            if  not annotation.dictionary[name] then
                local otherName = (match(name, "_buff$") and gsub(name, "_buff$", "")) or (match(name, "_debuff$") and gsub(name, "_debuff$", "")) or gsub(name, "_item$", "")
                if annotation.dictionary[otherName] then
                    return otherName, _type
                end
                local potionName = gsub(name, "potion_of_", "")
                if annotation.dictionary[potionName] then
                    return potionName, _type
                end
            end
            return name, _type
        end
        return disname, distype
    end,
    AddPerClassSpecialization = function(self, tbl, name, info, className, specialization, _type)
        className = className or "ALL_CLASSES"
        specialization = specialization or "ALL_SPECIALIZATIONS"
        tbl[className] = tbl[className] or {}
        tbl[className][specialization] = tbl[className][specialization] or {}
        tbl[className][specialization][name] = {
            [1] = info,
            [2] = _type or "Spell"
        }
    end,
    GetPerClassSpecialization = function(self, tbl, name, className, specialization)
        local info
        while  not info do
            while  not info do
                if tbl[className] and tbl[className][specialization] and tbl[className][specialization][name] then
                    info = tbl[className][specialization][name]
                end
                if specialization ~= "ALL_SPECIALIZATIONS" then
                    specialization = "ALL_SPECIALIZATIONS"
                else
                    break
                end
            end
            if className ~= "ALL_CLASSES" then
                className = "ALL_CLASSES"
            else
                break
            end
        end
        if info then
            return info[1], info[2]
        end
        return 
    end,
    InitializeDisambiguation = function(self)
        self:AddDisambiguation("none", "none")
    end,
    Emit = function(self, parseNode, nodeList, annotation, action)
        local visitor = self.EMIT_VISITOR[parseNode.type]
        if  not visitor then
            self.tracer:Error("Unable to emit node of type '%s'.", parseNode.type)
        else
            return visitor(parseNode, nodeList, annotation, action)
        end
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
    emitMiscOperand = function(self, operand, parseNode, nodeList, annotation, action)
        local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
        local miscOperand = tokenIterator()
        local info = MISC_OPERAND[miscOperand]
        if info then
            local modifier = tokenIterator()
            local name = info.name
            if modifier then
                if  not info.modifiers then
                    self.tracer:Warning("Use of " .. modifier .. " for " .. operand .. " but no modifier has been registered")
                    return nil
                end
                local modifierName = info.modifiers[modifier]
                if modifierName then
                    if modifierName.before then
                        name = modifierName.name .. name
                    else
                        name = name .. modifierName.name
                    end
                end
                if tokenIterator() then
                    self.tracer:Warning("Use of two modifiers on " .. operand .. " is not supported")
                    return nil
                end
            end
            return self.ovaleAst:newFunction(nodeList, name)
        end
        return nil
    end,
})
