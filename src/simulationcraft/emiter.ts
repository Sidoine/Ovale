import { ParseNode, Annotation, Modifier, SPECIAL_ACTION, interruptsClasses, Modifiers, UNARY_OPERATOR, SimcBinaryOperatorType, BINARY_OPERATOR, SimcUnaryOperatorType, checkOptionalSkill, CHARACTER_PROPERTY } from "./definitions";
import { LuaArray, truthy, tonumber, lualength, kpairs, LuaObj, ipairs, tostring } from "@wowts/lua";
import { AstNode, OvaleASTClass, OperatorType, StringNode, ValueNode, isNodeType } from "../AST";
import { Tracer, OvaleDebugClass } from "../Debug";
import { format, gmatch, find, match, lower, gsub, sub, len, upper } from "@wowts/string";
import { OvaleDataClass } from "../Data";
import { insert } from "@wowts/table";
import { CamelSpecialization, CamelCase, OvaleFunctionName } from "./text-tools";
import { POOLED_RESOURCE } from "../Power";
import { MakeString } from "../Ovale";
import { Unparser } from "./unparser";

const OPERAND_TOKEN_PATTERN = "[^.]+";

type EmitVisitor = (parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string | undefined) => AstNode;
type EmitOperandVisitor = (operand: string, parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string, target?: string) => [boolean, AstNode];


function IsTotem(name: string) {
    if (sub(name, 1, 13) == "efflorescence") {
        return true;
    } else if (name == "rune_of_power") {
        return true;
    } else if (sub(name, -7, -1) == "_statue") {
        return true;
    } else if (truthy(match(name, "invoke_(niuzao|xuen|chiji)"))) {
        return true;
    } else if (sub(name, -6, -1) == "_totem") {
        return true;
    }
    return false;
}

type Disambiguations =  LuaObj<LuaObj<LuaObj<{1: string, 2: string}>>>;

export class Emiter {
    private tracer: Tracer;
    private EMIT_DISAMBIGUATION: Disambiguations = {}

    constructor(ovaleDebug: OvaleDebugClass, private ovaleAst: OvaleASTClass, private ovaleData: OvaleDataClass, private unparser: Unparser) {
        this.tracer = ovaleDebug.create("SimulationCraftEmiter");
    }

    private AddDisambiguation(name: string, info: string, className?: string, specialization?: string, _type?: string) {
        this.AddPerClassSpecialization(this.EMIT_DISAMBIGUATION, name, info, className, specialization, _type);
    }
    
    private Disambiguate(annotation: Annotation, name: string, className: string, specialization: string, _type?: string): [string, string] {
        if (className && annotation.dictionary[`${name}_${className}`]) {
            return [`${name}_${className}`, _type];
        }
        if (specialization && annotation.dictionary[`${name}_${specialization}`]) {
            return [`${name}_${specialization}`, _type];
        }
        
        let [disname, distype] = this.GetPerClassSpecialization(this.EMIT_DISAMBIGUATION, name, className, specialization);
        if (!disname) {
            if (!annotation.dictionary[name]) {
                let otherName = truthy(match(name, "_buff$")) && gsub(name, "_buff$", "") || (truthy(match(name, "_debuff$")) && gsub(name, "_debuff$", "")) || gsub(name, "_item$", "");
                if (annotation.dictionary[otherName]) {
                    return [otherName, _type];
                }
                let potionName = gsub(name, "potion_of_", "");
                if (annotation.dictionary[potionName]) {
                    return [potionName, _type];
                }
            }
            return [name, _type];
        }
    
        return [disname, distype];
    }

    private AddPerClassSpecialization(tbl: Disambiguations, name: string, info: string, className: string, specialization: string, _type: string) {
        className = className || "ALL_CLASSES";
        specialization = specialization || "ALL_SPECIALIZATIONS";
        tbl[className] = tbl[className] || {};
        tbl[className][specialization] = tbl[className][specialization] || {};
        tbl[className][specialization][name] = {
            1: info,
            2: _type || "Spell"
        }
    }
    private GetPerClassSpecialization(tbl: Disambiguations, name: string, className: string, specialization: string) {
        let info;
        while (!info) {
            while (!info) {
                if (tbl[className] && tbl[className][specialization] && tbl[className][specialization][name]) {
                    info = tbl[className][specialization][name];
                }
                if (specialization != "ALL_SPECIALIZATIONS") {
                    specialization = "ALL_SPECIALIZATIONS";
                } else {
                    break;
                }
            }
            if (className != "ALL_CLASSES") {
                className = "ALL_CLASSES";
            } else {
                break;
            }
        }
        if (info) {
            return [info[1], info[2]];
        }
        return [];
    }

    public InitializeDisambiguation() {
        this.AddDisambiguation("none", "none");
    
        //Bloodlust
        this.AddDisambiguation("exhaustion_buff", "burst_haste_debuff");
    
        //Items
        this.AddDisambiguation("buff_sephuzs_secret", "sephuzs_secret_buff");
        
        // Essence
        this.AddDisambiguation("concentrated_flame", "concentrated_flame_essence");
        this.AddDisambiguation("memory_of_lucid_dreams", "memory_of_lucid_dreams_essence");
        this.AddDisambiguation("ripple_in_space", "ripple_in_space_essence");
        this.AddDisambiguation("worldvein_resonance", "worldvein_resonance_essence");
    
        //Arcane Torrent
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_runicpower", "DEATHKNIGHT");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_dh", "DEMONHUNTER");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "DRUID");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_focus", "HUNTER");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "MAGE");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_chi", "MONK");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_holy", "PALADIN");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "PRIEST");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "ROGUE");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "SHAMAN");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "WARLOCK");
        this.AddDisambiguation("arcane_torrent", "arcane_torrent_rage", "WARRIOR");
    
        //Blood Fury
        this.AddDisambiguation("blood_fury", "blood_fury_ap", "DEATHKNIGHT");
        this.AddDisambiguation("blood_fury", "blood_fury_ap", "HUNTER");
        this.AddDisambiguation("blood_fury", "blood_fury_sp", "MAGE");
        this.AddDisambiguation("blood_fury", "blood_fury_apsp", "MONK");
        this.AddDisambiguation("blood_fury", "blood_fury_ap", "ROGUE");
        this.AddDisambiguation("blood_fury", "blood_fury_apsp", "SHAMAN");
        this.AddDisambiguation("blood_fury", "blood_fury_sp", "WARLOCK");
        this.AddDisambiguation("blood_fury", "blood_fury_ap", "WARRIOR");
    
        //Death Knight
        this.AddDisambiguation("137075", "taktheritrixs_shoulderpads", "DEATHKNIGHT");
        this.AddDisambiguation("deaths_reach_talent", "deaths_reach_talent_unholy", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("grip_of_the_dead_talent", "grip_of_the_dead_talent_unholy", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("wraith_walk_talent", "wraith_walk_talent_blood", "DEATHKNIGHT", "blood");
        this.AddDisambiguation("deaths_reach_talent", "deaths_reach_talent_unholy", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("grip_of_the_dead_talent", "grip_of_the_dead_talent_unholy", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("cold_heart_talent_buff", "cold_heart_buff", "DEATHKNIGHT", "frost");
        this.AddDisambiguation("outbreak_debuff", "virulent_plague_debuff", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("gargoyle", "summon_gargoyle", "DEATHKNIGHT", "unholy");
        this.AddDisambiguation("empowered_rune_weapon", "empower_rune_weapon", "DEATHKNIGHT");
    
        //Demon Hunter
        this.AddDisambiguation("felblade_talent", "felblade_talent_havoc", "DEMONHUNTER", "havoc");
        this.AddDisambiguation("immolation_aura", "immolation_aura_havoc", "DEMONHUNTER", "havoc");
        this.AddDisambiguation("metamorphosis", "metamorphosis_veng", "DEMONHUNTER", "vengeance");
        this.AddDisambiguation("metamorphosis_buff", "metamorphosis_veng_buff", "DEMONHUNTER", "vengeance");
        this.AddDisambiguation("metamorphosis", "metamorphosis_havoc", "DEMONHUNTER", "havoc");
        this.AddDisambiguation("metamorphosis_buff", "metamorphosis_havoc_buff", "DEMONHUNTER", "havoc");
        this.AddDisambiguation("chaos_blades_debuff", "chaos_blades_buff", "DEMONHUNTER", "havoc");
        this.AddDisambiguation("throw_glaive", "throw_glaive_veng", "DEMONHUNTER", "vengeance");
        this.AddDisambiguation("throw_glaive", "throw_glaive_havoc", "DEMONHUNTER", "havoc");
    
        //Druid
        this.AddDisambiguation("feral_affinity_talent", "feral_affinity_talent_balance", "DRUID", "balance");
        this.AddDisambiguation("guardian_affinity_talent", "guardian_affinity_talent_restoration", "DRUID", "restoration");
        this.AddDisambiguation("incarnation", "incarnation_chosen_of_elune", "DRUID", "balance");
        this.AddDisambiguation("incarnation", "incarnation_tree_of_life", "DRUID", "restoration");
        this.AddDisambiguation("incarnation", "incarnation_king_of_the_jungle", "DRUID", "feral");
        this.AddDisambiguation("incarnation", "incarnation_guardian_of_ursoc", "DRUID", "guardian");
        this.AddDisambiguation("swipe", "swipe_bear", "DRUID", "guardian");
        this.AddDisambiguation("swipe", "swipe_cat", "DRUID", "feral");
        this.AddDisambiguation("rake_bleed", "rake_debuff", "DRUID", "feral");
        
        //Hunter
        this.AddDisambiguation("a_murder_of_crows_talent", "mm_a_murder_of_crows_talent", "HUNTER", "marksmanship");
        this.AddDisambiguation("cat_beast_cleave", "pet_beast_cleave", "HUNTER", "beast_mastery");
        this.AddDisambiguation("cat_frenzy", "pet_frenzy", "HUNTER", "beast_mastery");
        this.AddDisambiguation("kill_command", "kill_command_sv", "HUNTER", "survival");
        this.AddDisambiguation("kill_command", "kill_command_sv", "HUNTER", "survival");
        this.AddDisambiguation("mongoose_bite_eagle", "mongoose_bite", "HUNTER", "survival")
        this.AddDisambiguation("multishot", "multishot_bm", "HUNTER", "beast_mastery");
        this.AddDisambiguation("multishot", "multishot_mm", "HUNTER", "marksmanship");
        this.AddDisambiguation("raptor_strike_eagle", "raptor_strike", "HUNTER", "survival")
        this.AddDisambiguation("serpent_sting", "serpent_sting_mm", "HUNTER", "marksmanship");
        this.AddDisambiguation("serpent_sting", "serpent_sting_sv", "HUNTER", "survival");    
    
        //Mage
        this.AddDisambiguation("132410", "shard_of_the_exodar", "MAGE");
        this.AddDisambiguation("132454", "koralons_burning_touch", "MAGE", "fire");
        this.AddDisambiguation("132863", "darcklis_dragonfire_diadem", "MAGE", "fire");
        this.AddDisambiguation("blink_any", "blink", "MAGE");
        this.AddDisambiguation("summon_arcane_familiar", "arcane_familiar", "MAGE", "arcane");
        this.AddDisambiguation("water_elemental", "summon_water_elemental", "MAGE", "frost");
        
        //Monk
        
        this.AddDisambiguation("bok_proc_buff", "blackout_kick_buff", "MONK", "windwalker");
        this.AddDisambiguation("breath_of_fire_dot_debuff", "breath_of_fire_debuff", "MONK", "brewmaster");
        this.AddDisambiguation("brews", "ironskin_brew", "MONK", "brewmaster");
        this.AddDisambiguation("fortifying_brew", "fortifying_brew_mistweaver", "MONK", "mistweaver");
        this.AddDisambiguation("healing_elixir_talent", "healing_elixir_talent_mistweaver", "MONK", "mistweaver");
        this.AddDisambiguation("rushing_jade_wind_buff", "rushing_jade_wind_windwalker_buff", "MONK", "windwalker");
    
        //Paladin
        this.AddDisambiguation("avenger_shield", "avengers_shield", "PALADIN", "protection");
        this.AddDisambiguation("judgment_of_light_talent", "judgment_of_light_talent_holy", "PALADIN", "holy");
        this.AddDisambiguation("unbreakable_spirit_talent", "unbreakable_spirit_talent_holy", "PALADIN", "holy");
        this.AddDisambiguation("cavalier_talent", "cavalier_talent_holy", "PALADIN", "holy");
        this.AddDisambiguation("divine_purpose_buff", "divine_purpose_buff_holy", "PALADIN", "holy");
        this.AddDisambiguation("judgment", "judgment_holy", "PALADIN", "holy");
        this.AddDisambiguation("judgment", "judgment_prot", "PALADIN", "protection");
    
        //Priest
        this.AddDisambiguation("mindbender", "mindbender_shadow", "PRIEST", "shadow");
    
        //Rogue
        this.AddDisambiguation("deadly_poison_dot", "deadly_poison", "ROGUE", "assassination");
        this.AddDisambiguation("stealth_buff", "stealthed_buff", "ROGUE");
        this.AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_assassination_buff", "ROGUE", "assassination");
        this.AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_outlaw_buff", "ROGUE", "outlaw");
        this.AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_subtlety_buff", "ROGUE", "subtlety");
    
        //Shaman
        this.AddDisambiguation("earth_shield_talent", "earth_shield_talent_restoration", "SHAMAN", "restoration");
        this.AddDisambiguation("flame_shock", "flame_shock_restoration", "SHAMAN", "restoration");
        this.AddDisambiguation("lightning_bolt", "lightning_bolt_elemental", "SHAMAN", "elemental");
        this.AddDisambiguation("lightning_bolt", "lightning_bolt_enhancement", "SHAMAN", "enhancement");
        this.AddDisambiguation("strike", "windstrike", "SHAMAN", "enhancement");
    
        //Warlock
        this.AddDisambiguation("132369", "wilfreds_sigil_of_superior_summoning", "WARLOCK", "demonology");
        this.AddDisambiguation("dark_soul", "dark_soul_misery", "WARLOCK", "affliction");
        this.AddDisambiguation("soul_conduit_talent", "demo_soul_conduit_talent", "WARLOCK", "demonology");
        
        //Warrior
        this.AddDisambiguation("anger_management_talent", "fury_anger_management_talent", "WARRIOR", "fury");
        this.AddDisambiguation("bounding_stride_talent", "prot_bounding_stride_talent", "WARRIOR", "protection");
        this.AddDisambiguation("deep_wounds_debuff", "deep_wounds_arms_debuff", "WARRIOR", "arms")
        this.AddDisambiguation("deep_wounds_debuff", "deep_wounds_prot_debuff", "WARRIOR", "protection")
        this.AddDisambiguation("dragon_roar_talent", "prot_dragon_roar_talent", "WARRIOR", "protection");
        this.AddDisambiguation("execute", "execute_arms", "WARRIOR", "arms");
        this.AddDisambiguation("storm_bolt_talent", "prot_storm_bolt_talent", "WARRIOR", "protection");
        this.AddDisambiguation("meat_cleaver", "whirlwind", "WARRIOR", "fury");

        this.AddDisambiguation("pocketsized_computation_device_item", "pocket_sized_computation_device_item");
        this.AddDisambiguation("condensed_lifeforce", "condensed_life_force");
        this.AddDisambiguation("condensed_lifeforce_essence_id", "condensed_life_force_essence_id")
    }

    /** Transform a ParseNode to an AstNode
     * @param parseNode The ParseNode to transform
     * @param nodeList The list of AstNode. Any created node will be added to this array.
     * @param action The current Simulationcraft action, or undefined if in a condition modifier
     */
    Emit(parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string | undefined) {
        let visitor = this.EMIT_VISITOR[parseNode.type];
        if (!visitor) {
            this.tracer.Error("Unable to emit node of type '%s'.", parseNode.type);
        } else {
            return visitor(parseNode, nodeList, annotation, action);
        }
    }

    private AddSymbol(annotation: Annotation, symbol: string) {
        let symbolTable = annotation.symbolTable || {}
        let symbolList = annotation.symbolList || {};
        if (!symbolTable[symbol] && !this.ovaleData.DEFAULT_SPELL_LIST[symbol]) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        annotation.symbolTable = symbolTable;
        annotation.symbolList = symbolList;
    }

    private EmitModifier = (modifier: Modifier, parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string, modifiers: Modifiers) => {
        let node: AstNode, code;
        let className = annotation.class;
        let specialization = annotation.specialization;
        if (modifier == "if") {
            node = this.Emit(parseNode, nodeList, annotation, action);
        } else if (modifier == "target_if") {
            node = this.Emit(parseNode, nodeList, annotation, action);
        } else if (modifier == "five_stacks" && action == "focus_fire") {
            let value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                let buffName = "pet_frenzy_buff";
                this.AddSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= 5", buffName);
            }
        } else if (modifier == "line_cd") {
            if (!SPECIAL_ACTION[action]) {
                this.AddSymbol(annotation, action);
                let expressionCode = this.ovaleAst.Unparse(this.Emit(parseNode, nodeList, annotation, action));
                code = format("TimeSincePreviousSpell(%s) > %s", action, expressionCode);
            }
        } else if (modifier == "max_cycle_targets") {
            let [debuffName] = this.Disambiguate(annotation, `${action}_debuff` , className, specialization);
            this.AddSymbol(annotation, debuffName);
            let expressionCode = this.ovaleAst.Unparse(this.Emit(parseNode, nodeList, annotation, action));
            code = format("DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s", debuffName, debuffName, expressionCode);
        } else if (modifier == "max_energy") {
            let value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                code = format("Energy() >= EnergyCost(%s max=1)", action);
            }
        } else if (modifier == "min_frenzy" && action == "focus_fire") {
            let value = tonumber(this.unparser.Unparse(parseNode));
            if (value) {
                let buffName = "pet_frenzy_buff";
                this.AddSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= %d", buffName, value);
            }
        } else if (modifier == "moving") {
            let value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 0) {
                code = "not Speed() > 0";
            } else {
                code = "Speed() > 0";
            }
        } else if (modifier == "precombat") {
            let value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                code = "not InCombat()";
            } else {
                code = "InCombat()";
            }
        } else if (modifier == "sync") {
            let name = this.unparser.Unparse(parseNode);
            if (name == "whirlwind_mh") {
                name = "whirlwind";
            }
            node = annotation.astAnnotation && annotation.astAnnotation.sync && annotation.astAnnotation.sync[name];
            if (!node) {
                let syncParseNode = annotation.sync[name];
                if (syncParseNode) {
                    let syncActionNode = this.EmitAction(syncParseNode, nodeList, annotation, action);
                    let syncActionType = syncActionNode.type;
                    if (syncActionType == "action") {
                        node = syncActionNode;
                    } else if (syncActionType == "custom_function") {
                        node = syncActionNode;
                    } else if (syncActionType == "if" || syncActionType == "unless") {
                        let lhsNode = syncActionNode.child[1];
                        if (syncActionType == "unless") {
                            let notNode = this.ovaleAst.NewNode(nodeList, true);
                            notNode.type = "logical";
                            notNode.expressionType = "unary";
                            notNode.operator = "not";
                            notNode.child[1] = lhsNode;
                            lhsNode = notNode;
                        }
                        let rhsNode = syncActionNode.child[2];
                        let andNode = this.ovaleAst.NewNode(nodeList, true);
                        andNode.type = "logical";
                        andNode.expressionType = "binary";
                        andNode.operator = "and";
                        andNode.child[1] = lhsNode;
                        andNode.child[2] = rhsNode;
                        node = andNode;
                    } else {
                        this.tracer.Print("Warning: Unable to emit action for 'sync=%s'.", name);
                        [name] = this.Disambiguate(annotation, name, className, specialization);
                        this.AddSymbol(annotation, name);
                        code = format("Spell(%s)", name);
                    }
                }
            }
            if (node) {
                annotation.astAnnotation = annotation.astAnnotation || {
                }
                annotation.astAnnotation.sync = annotation.astAnnotation.sync || {
                }
                annotation.astAnnotation.sync[name] = node;
            }
        }
        if (!node && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return node;
    }

    private EmitConditionNode = (nodeList: LuaArray<AstNode>, bodyNode: AstNode, conditionNode: AstNode, parseNode: ParseNode, annotation: Annotation, action: string, modifiers: Modifiers) => {
        let extraConditionNode = conditionNode;
        conditionNode = undefined;
        for (const [modifier, expressionNode] of kpairs(parseNode.modifiers)) {
            let rhsNode = this.EmitModifier(modifier, expressionNode, nodeList, annotation, action, modifiers);
            if (rhsNode) {
                if (!conditionNode) {
                    conditionNode = rhsNode;
                } else {
                    let lhsNode = conditionNode;
                    conditionNode = this.ovaleAst.NewNode(nodeList, true);
                    conditionNode.type = "logical";
                    conditionNode.expressionType = "binary";
                    conditionNode.operator = "and";
                    conditionNode.child[1] = lhsNode;
                    conditionNode.child[2] = rhsNode;
                }
            }
        }
        if (extraConditionNode) {
            if (conditionNode) {
                let lhsNode = conditionNode;
                let rhsNode = extraConditionNode;
                conditionNode = this.ovaleAst.NewNode(nodeList, true);
                conditionNode.type = "logical";
                conditionNode.expressionType = "binary";
                conditionNode.operator = "and";
                conditionNode.child[1] = lhsNode;
                conditionNode.child[2] = rhsNode;
            } else {
                conditionNode = extraConditionNode;
            }
        }
        if (conditionNode) {
            let node = this.ovaleAst.NewNode(nodeList, true);
            node.type = "if";
            node.child[1] = conditionNode;
            node.child[2] = bodyNode;
            if (bodyNode.type == "simc_pool_resource") {
                node.simc_pool_resource = true;
            } else if (bodyNode.type == "simc_wait") {
                node.simc_wait = true;
            }
            return node;
        } else {
            return bodyNode;
        }
    }
    
    private EmitNamedVariable = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifiers: Modifiers, parseNode: ParseNode, action: string, conditionNode?: AstNode) => {
        if (!annotation.variable) {
            annotation.variable = {}
        }
        let node = annotation.variable[name];
        let group;
        if (!node) {
            node = this.ovaleAst.NewNode(nodeList, true);
            annotation.variable[name] = node;
            node.type = "add_function";
            node.name = name;
            group = this.ovaleAst.NewNode(nodeList, true);
            group.type = "group";
            node.child[1] = group;
        } else {
            group = node.child[1];
        }
        annotation.currentVariable = node;
        let value = this.Emit(modifiers.value, nodeList, annotation, action);
        let newNode = this.EmitConditionNode(nodeList, value, conditionNode || undefined, parseNode, annotation, action, modifiers);
        if (newNode.type == "if") {
            insert(group.child, 1, newNode);
        } else {
            insert(group.child, newNode);
        }
        annotation.currentVariable = undefined;
    }

    private EmitVariableMin = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: Modifiers, parseNode: ParseNode, action: string) => {
        this.EmitNamedVariable(`${name}_min`, nodeList, annotation, modifier, parseNode, action);
        let valueNode = annotation.variable[name];
        valueNode.name = `${name}_value`;
        annotation.variable[valueNode.name] = valueNode;
        let bodyCode = format("AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }", name, name, name, name, name);
        let [node] = this.ovaleAst.ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation);
        annotation.variable[name] = node;
    }
    
    private EmitVariableMax = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: Modifiers, parseNode: ParseNode, action: string) => {
        this.EmitNamedVariable(`${name}_max`, nodeList, annotation, modifier, parseNode, action);
        let valueNode = annotation.variable[name];
        valueNode.name = `${name}_value`;
        annotation.variable[valueNode.name] = valueNode;
        let bodyCode = format("AddFunction %s { if %s_value() < %s_max() %s_value() %s_max() }", name, name, name, name, name);
        let [node] = this.ovaleAst.ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation);
        annotation.variable[name] = node;
    }

    private EmitVariableAdd = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifiers: Modifiers, parseNode: ParseNode, action: string) => {
        // TODO
        let valueNode = annotation.variable[name];
        if (valueNode) return;
        this.EmitNamedVariable(name, nodeList, annotation, modifiers, parseNode, action);
    }

    private EmitVariableSub = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifiers: Modifiers, parseNode: ParseNode, action: string) => {
        // TODO
        let valueNode = annotation.variable[name];
        if (valueNode) return;
        this.EmitNamedVariable(name, nodeList, annotation, modifiers, parseNode, action);
    }

    private EmitVariableIf = (name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifiers: Modifiers, parseNode: ParseNode, action: string) => {
        let node = annotation.variable[name];
        let group: AstNode;
        if (!node) {
            node = this.ovaleAst.NewNode(nodeList, true);
            annotation.variable[name] = node;
            node.type = "add_function";
            node.name = name;
            group = this.ovaleAst.NewNode(nodeList, true);
            group.type = "group";
            node.child[1] = group;
        } else {
            group = node.child[1];
        }

        annotation.currentVariable = node;

        const ifNode = this.ovaleAst.NewNode(nodeList, true);
        ifNode.type = "if";
        ifNode.child[1] = this.Emit(modifiers.condition, nodeList, annotation, undefined);
        ifNode.child[2] = this.Emit(modifiers.value, nodeList, annotation, undefined);
        insert(group.child, ifNode);
        const elseNode = this.ovaleAst.NewNode(nodeList, true);
        elseNode.type = "unless";
        elseNode.child[1] = ifNode.child[1];
        elseNode.child[2] = this.Emit(modifiers.value_else, nodeList, annotation, undefined);
        insert(group.child, elseNode);

        annotation.currentVariable = undefined;
    }

    private EmitVariable = (nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: Modifiers, parseNode: ParseNode, action: string, conditionNode?: AstNode) => {
        if (!annotation.variable) {
            annotation.variable = {}
        }
        let op = (modifier.op && this.unparser.Unparse(modifier.op)) || "set";
        let name = this.unparser.Unparse(modifier.name);
        if (truthy(match(name, "^%d"))) {
            name = "_" + name;
        }
        if (op == "min") {
            this.EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action);
        } else if (op == "max") {
            this.EmitVariableMax(name, nodeList, annotation, modifier, parseNode, action);
        } else if (op == "add") {
            this.EmitVariableAdd(name, nodeList, annotation, modifier, parseNode, action);
        } else if (op == "set") {
            this.EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode);
        } else if (op === "setif") {
            this.EmitVariableIf(name, nodeList, annotation, modifier, parseNode, action);
        } else if (op === "sub") {
            this.EmitVariableSub(name, nodeList, annotation, modifier, parseNode, action);
        } else if (op === "reset") {
            // TODO need to refactor code to allow this kind of thing
        } else {
            this.tracer.Error("Unknown variable operator '%s'.", op);
        }
    }
   
    /** Takes a ParseNode of type "action" and transforms it to an AstNode. */
    private EmitAction: EmitVisitor = (parseNode: ParseNode, nodeList, annotation) => {
        let node: AstNode;
        let canonicalizedName = lower(gsub(parseNode.name, ":", "_"));
        let className = annotation.class;
        let specialization = annotation.specialization;
        let camelSpecialization = CamelSpecialization(annotation);
        let role = annotation.role;
        let [action, type] = this.Disambiguate(annotation, canonicalizedName, className, specialization, "Spell");
        let bodyNode: AstNode;
        let conditionNode: AstNode;
        if (action == "auto_attack" && !annotation.melee) {
        } else if (action == "auto_shot") {
        } else if (action == "choose_target") {
        } else if (action == "augmentation" || action == "flask" || action == "food") {
        } else if (action == "snapshot_stats") {
        } else {
            let bodyCode, conditionCode;
            const expressionType = "expression";
            const modifiers = parseNode.modifiers;
            let isSpellAction = true;
            if (interruptsClasses[action as keyof typeof interruptsClasses] === className) {
                bodyCode = `${camelSpecialization}InterruptActions()`;
                annotation[action as keyof typeof interruptsClasses] = className;
                annotation.interrupt = className;
                isSpellAction = false;
            } else if (className == "DRUID" && action == "pulverize") {
                let debuffName = "thrash_bear_debuff";
                this.AddSymbol(annotation, debuffName);
                conditionCode = format("target.DebuffGain(%s) <= BaseDuration(%s)", debuffName, debuffName);
            } else if (className == "DRUID" && specialization == "guardian" && action == "rejuvenation") {
                let spellName = "enhanced_rejuvenation";
                this.AddSymbol(annotation, spellName);
                conditionCode = format("SpellKnown(%s)", spellName);
            } else if (className == "DRUID" && action == "wild_charge") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (className == "DRUID" && action == "new_moon") {
                conditionCode = "not SpellKnown(half_moon) and not SpellKnown(full_moon)";
                this.AddSymbol(annotation, "half_moon");
                this.AddSymbol(annotation, "full_moon");
            } else if (className == "DRUID" && action == "half_moon") {
                conditionCode = "SpellKnown(half_moon)";
            } else if (className == "DRUID" && action == "full_moon") {
                conditionCode = "SpellKnown(full_moon)";
            } else if (className == "DRUID" && action == "regrowth" && specialization == "feral") {
                conditionCode = "Talent(bloodtalons_talent) and (BuffRemaining(bloodtalons_buff) < CastTime(regrowth)+GCDRemaining() or InCombat())"
                this.AddSymbol(annotation, "bloodtalons_talent")
                this.AddSymbol(annotation, "bloodtalons_buff")
                this.AddSymbol(annotation, "regrowth")
            } else if (className == "HUNTER" && action == "kill_command") {
                conditionCode = "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()";
            } else if (className == "MAGE" && action == "arcane_brilliance") {
                conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)";
            } else if (className == "MAGE" && truthy(find(action, "pet_"))) {
                conditionCode = "pet.Present()";
            } else if (className == "MAGE" && (action == "start_burn_phase" || action == "start_pyro_chain" || action == "stop_burn_phase" || action == "stop_pyro_chain")) {
                let [stateAction, stateVariable] = match(action, "([^_]+)_(.*)");
                let value = (stateAction == "start") && 1 || 0;
                if (value == 0) {
                    conditionCode = format("GetState(%s) > 0", stateVariable);
                } else {
                    conditionCode = format("not GetState(%s) > 0", stateVariable);
                }
                bodyCode = format("SetState(%s %d)", stateVariable, value);
                isSpellAction = false;
            } else if (className == "MAGE" && action == "time_warp") {
                conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)";
                annotation[action] = className;
            } else if (className == "MAGE" && action == "summon_water_elemental") {
                conditionCode = "not pet.Present()";
            } else if (className == "MAGE" && action == "ice_floes") {
                conditionCode = "Speed() > 0";
            } else if (className == "MAGE" && action == "blast_wave") {
                conditionCode = "target.Distance(less 8)"
            } else if (className == "MAGE" && action == "dragons_breath") {
                conditionCode = "target.Distance(less 12)"
            } else if (className == "MAGE" && action == "arcane_blast") {
                conditionCode = "Mana() > ManaCost(arcane_blast)"
            } else if (className == "MAGE" && action == "cone_of_cold") {
                conditionCode = "target.Distance() < 12"
            } else if (className == "MONK" && action == "chi_sphere") {
                isSpellAction = false;
            } else if (className == "MONK" && action == "gift_of_the_ox") {
                isSpellAction = false;
            } else if (className == "MONK" && action == "nimble_brew") {
                conditionCode = "IsFeared() or IsRooted() or IsStunned()";
            } else if (className == "MONK" && action == "storm_earth_and_fire") {
                conditionCode = "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff)";
                annotation[action] = className;
            } else if (className == "MONK" && action == "touch_of_death") {
                conditionCode = "(not CheckBoxOn(opt_touch_of_death_on_elite_only) or (not UnitInRaid() and target.Classification(elite)) or target.Classification(worldboss)) or not BuffExpires(hidden_masters_forbidden_touch_buff)";
                annotation[action] = className;
                annotation.opt_touch_of_death_on_elite_only = "MONK";
                this.AddSymbol(annotation, "hidden_masters_forbidden_touch_buff");
            } else if (className == "MONK" && action == "whirling_dragon_punch") {
                conditionCode = "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0";
            } else if (className == "PALADIN" && action == "blessing_of_kings") {
                conditionCode = "BuffExpires(mastery_buff)";
            } else if (className == "PALADIN" && action == "judgment") {
                if (modifiers.cycle_targets) {
                    this.AddSymbol(annotation, action);
                    bodyCode = `Spell(${action} text=double)`;
                    isSpellAction = false;
                }
            } else if (className == "PALADIN" && specialization == "protection" && action == "arcane_torrent_holy") {
                isSpellAction = false;
            } else if (className == "ROGUE" && action == "adrenaline_rush") {
                conditionCode = "EnergyDeficit() > 1";
            } else if (className == "ROGUE" && action == "apply_poison") {
                if (modifiers.lethal) {
                    let name = this.unparser.Unparse(modifiers.lethal);
                    action = `${name}_poison`;
                    let buffName = "lethal_poison_buff";
                    this.AddSymbol(annotation, buffName);
                    conditionCode = format("BuffRemaining(%s) < 1200", buffName);
                } else {
                    isSpellAction = false;
                }
            } else if (className == "ROGUE" && action == "cancel_autoattack") {
                isSpellAction = false;
            } else if (className == "ROGUE" && action == "premeditation") {
                conditionCode = "ComboPoints() < 5";
            } else if (className == "ROGUE" && specialization == "assassination" && action == "vanish") {
                annotation.vanish = className;
                conditionCode = format("CheckBoxOn(opt_vanish)", action);
            } else if (className == "SHAMAN" && sub(action, 1, 11) == "ascendance_") {
                let buffName = `${action}_buff`;
                this.AddSymbol(annotation, buffName);
                conditionCode = format("BuffExpires(%s)", buffName);
            } else if (className == "SHAMAN" && action == "bloodlust") {
                bodyCode = `${camelSpecialization}Bloodlust()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (className == "SHAMAN" && action == "magma_totem") {
                let spellName = "primal_strike";
                this.AddSymbol(annotation, spellName);
                conditionCode = format("target.InRange(%s)", spellName);
            } else if (className == "WARLOCK" && action == "felguard_felstorm") {
                conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)";
            } else if (className == "WARLOCK" && action == "grimoire_of_sacrifice") {
                conditionCode = "pet.Present()";
            } else if (className == "WARLOCK" && action == "havoc") {
                conditionCode = "Enemies() > 1";
            } else if (className == "WARLOCK" && action == "service_pet") {
                if (annotation.pet) {
                    let spellName = `service_${annotation.pet}`;
                    this.AddSymbol(annotation, spellName);
                    bodyCode = format("Spell(%s)", spellName);
                } else {
                    bodyCode = "Texture(spell_nature_removecurse help=ServicePet)";
                }
                isSpellAction = false;
            } else if (className == "WARLOCK" && action == "summon_pet") {
                if (annotation.pet) {
                    let spellName = `summon_${annotation.pet}`;
                    this.AddSymbol(annotation, spellName);
                    bodyCode = format("Spell(%s)", spellName);
                } else {
                    bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))";
                }
                conditionCode = "not pet.Present()";
                isSpellAction = false;
            } else if (className == "WARLOCK" && action == "wrathguard_wrathstorm") {
                conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)";
            } else if (className == "WARRIOR" && action == "battle_shout" && role == "tank") {
                conditionCode = "BuffExpires(stamina_buff)";
            } else if (className == "WARRIOR" && action == "charge") {
                conditionCode = "CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel)";
                this.AddSymbol(annotation, "pummel");
            } else if (className == "WARRIOR" && action == "commanding_shout" && role == "attack") {
                conditionCode = "BuffExpires(attack_power_multiplier_buff)";
            } else if (className == "WARRIOR" && action == "enraged_regeneration") {
                conditionCode = "HealthPercent() < 80";
            } else if (className == "WARRIOR" && sub(action, 1, 7) == "execute") {
                if (modifiers.target) {
                    let target = tonumber(this.unparser.Unparse(modifiers.target));
                    if (target) {
                        isSpellAction = false;
                    }
                }
            } else if (className == "WARRIOR" && action == "heroic_charge") {
                isSpellAction = false;
            } else if (className == "WARRIOR" && action == "heroic_leap") {
                conditionCode = "CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40)";
            } else if (action == "auto_attack") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                isSpellAction = false;
            } else if (className == "DEMONHUNTER" && action == "metamorphosis_havoc") {
                conditionCode = "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()";
                annotation.opt_meta_only_during_boss = "DEMONHUNTER";
            } else if (className == "DEMONHUNTER" && action == "consume_magic") {
                conditionCode = "target.HasDebuffType(magic)";
            } else if (checkOptionalSkill(action, className, specialization)) {
                annotation[action] = className;
                conditionCode = `CheckBoxOn(opt_${action})`;
            } else if (action == "variable") {
                this.EmitVariable(nodeList, annotation, modifiers, parseNode, action, conditionNode);
                isSpellAction = false;
            } else if (action == "call_action_list" || action == "run_action_list" || action == "swap_action_list") {
                if (modifiers.name) {
                    let name = this.unparser.Unparse(modifiers.name);
                    let functionName = OvaleFunctionName(name, annotation);
                    bodyCode = `${functionName}()`;
                    if (className == "MAGE" && specialization == "arcane" && (name == "burn" || name == "init_burn")) {
                        conditionCode = "CheckBoxOn(opt_arcane_mage_burn_phase)";
                        annotation.opt_arcane_mage_burn_phase = className;
                    }
                }
                isSpellAction = false;
            } else if (action == "cancel_buff") {
                if (modifiers.name) {
                    let spellName = this.unparser.Unparse(modifiers.name);
                    let [buffName] = this.Disambiguate(annotation, `${spellName}_buff`, className, specialization, "spell");
                    this.AddSymbol(annotation, spellName);
                    this.AddSymbol(annotation, buffName);
                    bodyCode = format("Texture(%s text=cancel)", spellName);
                    conditionCode = format("BuffPresent(%s)", buffName);
                    isSpellAction = false;
                }
            } else if (action == "pool_resource") {
                bodyNode = this.ovaleAst.NewNode(nodeList);
                bodyNode.type = "simc_pool_resource";
                bodyNode.for_next = (modifiers.for_next != undefined);
                if (modifiers.extra_amount) {
                    bodyNode.extra_amount = tonumber(this.unparser.Unparse(modifiers.extra_amount));
                }
                isSpellAction = false;
            } else if (action == "potion") {
                let name = (modifiers.name && this.unparser.Unparse(modifiers.name)) || annotation.consumables["potion"];
                if (name) {
                    [name] = this.Disambiguate(annotation, `${name}_item`, className, specialization, "item");
                    bodyCode = format("Item(%s usable=1)", name);
                    conditionCode = "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)";
                    annotation.opt_use_consumables = className;
                    this.AddSymbol(annotation, name);
                    isSpellAction = false;
                }
            } else if (action === "sequence") {
                isSpellAction = false;
            } else if (action == "stance") {
                if (modifiers.choose) {
                    let name = this.unparser.Unparse(modifiers.choose);
                    if (className == "MONK") {
                        action = `stance_of_the_${name}`;
                    } else if (className == "WARRIOR") {
                        action = `${name}_stance`;
                    } else {
                        action = name;
                    }
                } else {
                    isSpellAction = false;
                }
            } else if (action == "summon_pet") {
                bodyCode = `${camelSpecialization}SummonPet()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (action == "use_items") {
                bodyCode = `${camelSpecialization}UseItemActions()`;
                annotation["use_item"] = true;
                isSpellAction = false;
            } else if (action == "use_item") {
                let legendaryRing: string = undefined;
                // TODO use modifiers.slots
                if (modifiers.slot) {
                    // use this slot only?
                    let slot = this.unparser.Unparse(modifiers.slot);
                    if (truthy(match(slot, "finger"))) {
                        [legendaryRing] = this.Disambiguate(annotation, "legendary_ring", className, specialization);
                    }
                } else if (modifiers.name) {
                    let name = this.unparser.Unparse(modifiers.name);
                    [name] = this.Disambiguate(annotation, name, className, specialization);
                    if (truthy(match(name, "legendary_ring"))) {
                        legendaryRing = name;
                    }
                    // } else if (false) {
                    //     bodyCode = format("Item(%s usable=1)", name);
                    //     AddSymbol(annotation, name);
                    // }
                } else if (modifiers.effect_name) {
                    // TODO use any item that has this effect
                }
                if (legendaryRing) {
                    conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing);
                    bodyCode = format("Item(%s usable=1)", legendaryRing);
                    this.AddSymbol(annotation, legendaryRing);
                    annotation.use_legendary_ring = legendaryRing;
                } else {
                    bodyCode = `${camelSpecialization}UseItemActions()`;
                    annotation[action] = true;
                }
                isSpellAction = false;
            } else if (action == "wait") {
                if (modifiers.sec) {
                    let seconds = tonumber(this.unparser.Unparse(modifiers.sec));
                    if (seconds) {
                    } else {
                        bodyNode = this.ovaleAst.NewNode(nodeList);
                        bodyNode.type = "simc_wait";
                        let expressionNode = this.Emit(modifiers.sec, nodeList, annotation, action);
                        let code = this.ovaleAst.Unparse(expressionNode);
                        conditionCode = code + " > 0";
                    }
                }
                isSpellAction = false;
            } else if (action == "heart_essence") {
                bodyCode = `${camelSpecialization}UseHeartEssence()`;
                annotation.use_heart_essence = true;
                isSpellAction = false;
            }
            if (isSpellAction) {
                this.AddSymbol(annotation, action);
                if (modifiers.target) {
                    let actionTarget = this.unparser.Unparse(modifiers.target);
                    if (actionTarget == "2") {
                        actionTarget = "other";
                    }
                    if (actionTarget != "1") {
                        bodyCode = format("%s(%s text=%s)", type, action, actionTarget);
                    }
                }
                bodyCode = bodyCode || `${type}(${action})`;
            }
            annotation.astAnnotation = annotation.astAnnotation || {};
            if (!bodyNode && bodyCode) {
                [bodyNode] = this.ovaleAst.ParseCode(expressionType, bodyCode, nodeList, annotation.astAnnotation);
            }
            if (!conditionNode && conditionCode) {
                [conditionNode] = this.ovaleAst.ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation);
            }
            if (bodyNode) {
                node = this.EmitConditionNode(nodeList, bodyNode, conditionNode, parseNode, annotation, action, modifiers);
            }
        }
        return node;
    }

    public EmitActionList: EmitVisitor = (parseNode, nodeList, annotation) => {
        let groupNode = this.ovaleAst.NewNode(nodeList, true);
        groupNode.type = "group";
        let child = groupNode.child;
        let poolResourceNode;
        let emit = true;
        for (const [, actionNode] of ipairs(parseNode.child)) {
            let commentNode = this.ovaleAst.NewNode(nodeList);
            commentNode.type = "comment";
            commentNode.comment = actionNode.action;
            child[lualength(child) + 1] = commentNode;
            if (emit) {
                let statementNode = this.EmitAction(actionNode, nodeList, annotation, actionNode.name);
                if (statementNode) {
                    if (statementNode.type == "simc_pool_resource") {
                        let powerType = POOLED_RESOURCE[annotation.class];
                        if (powerType) {
                            if (statementNode.for_next) {
                                poolResourceNode = statementNode;
                                poolResourceNode.powerType = powerType;
                            } else {
                                emit = false;
                            }
                        }
                    } else if (poolResourceNode) {
                        child[lualength(child) + 1] = statementNode;
                        let bodyNode;
                        let poolingConditionNode: AstNode;
                        if (statementNode.child) {
                            poolingConditionNode = statementNode.child[1];
                            bodyNode = statementNode.child[2];
                        } else {
                            bodyNode = statementNode;
                        }
                        let powerType = CamelCase(poolResourceNode.powerType);
                        let extra_amount = poolResourceNode.extra_amount;
                        if (extra_amount && poolingConditionNode) {
                            let code = this.ovaleAst.Unparse(poolingConditionNode);
                            let extraAmountPattern = powerType + "%(%) >= [%d.]+";
                            let replaceString = format("True(pool_%s %d)", poolResourceNode.powerType, extra_amount);
                            code = gsub(code, extraAmountPattern, replaceString);
                            [poolingConditionNode] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                        }
                        if (bodyNode.type == "action" && bodyNode.rawPositionalParams && bodyNode.rawPositionalParams[1]) {
                            let name = this.ovaleAst.Unparse(bodyNode.rawPositionalParams[1]);
                            let powerCondition;
                            if (extra_amount) {
                                powerCondition = format("TimeTo%s(%d)", powerType, extra_amount);
                            } else {
                                powerCondition = format("TimeTo%sFor(%s)", powerType, name);
                            }
                            let code = format("SpellUsable(%s) and SpellCooldown(%s) < %s", name, name, powerCondition);
                            let [conditionNode] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                            if (statementNode.child) {
                                let rhsNode = conditionNode;
                                conditionNode = this.ovaleAst.NewNode(nodeList, true);
                                conditionNode.type = "logical";
                                conditionNode.expressionType = "binary";
                                conditionNode.operator = "and";
                                conditionNode.child[1] = poolingConditionNode;
                                conditionNode.child[2] = rhsNode;
                            }
                            let restNode = this.ovaleAst.NewNode(nodeList, true);
                            child[lualength(child) + 1] = restNode;
                            if (statementNode.type == "unless") {
                                restNode.type = "if";
                            } else {
                                restNode.type = "unless";
                            }
                            restNode.child[1] = conditionNode;
                            restNode.child[2] = this.ovaleAst.NewNode(nodeList, true);
                            restNode.child[2].type = "group";
                            child = restNode.child[2].child;
                        }
                        poolResourceNode = undefined;
                    } else if (statementNode.type == "simc_wait") {
                    } else if (statementNode.simc_wait) {
                        let restNode = this.ovaleAst.NewNode(nodeList, true);
                        child[lualength(child) + 1] = restNode;
                        restNode.type = "unless";
                        restNode.child[1] = statementNode.child[1];
                        restNode.child[2] = this.ovaleAst.NewNode(nodeList, true);
                        restNode.child[2].type = "group";
                        child = restNode.child[2].child;
                    } else {
                        child[lualength(child) + 1] = statementNode;
                        if (statementNode.simc_pool_resource) {
                            if (statementNode.type == "if") {
                                statementNode.type = "unless";
                            } else if (statementNode.type == "unless") {
                                statementNode.type = "if";
                            }
                            statementNode.child[2] = this.ovaleAst.NewNode(nodeList, true);
                            statementNode.child[2].type = "group";
                            child = statementNode.child[2].child;
                        }
                    }
                }
            }
        }
        let node = this.ovaleAst.NewNode(nodeList, true);
        node.type = "add_function";
        node.name = OvaleFunctionName(parseNode.name, annotation);
        node.child[1] = groupNode;
        return node;
    }
    
    private EmitExpression: EmitVisitor = (parseNode, nodeList, annotation, action) => {
        let node: AstNode;
        let msg;
        if (parseNode.expressionType == "unary") {
            let opInfo = UNARY_OPERATOR[parseNode.operator as SimcUnaryOperatorType];
            if (opInfo) {
                let operator: OperatorType;
                if (parseNode.operator == "!") {
                    operator = "not";
                } else if (parseNode.operator == "-") {
                    operator = parseNode.operator;
                }
                if (operator) {
                    let rhsNode = this.Emit(parseNode.child[1], nodeList, annotation, action);
                    if (rhsNode) {
                        if (operator == "-" && isNodeType(rhsNode, "value")) {
                            rhsNode.value = -1 * <number>rhsNode.value;
                        } else {
                            node = this.ovaleAst.NewNode(nodeList, true);
                            node.type = opInfo[1];
                            node.expressionType = "unary";
                            node.operator = operator;
                            node.precedence = opInfo[2];
                            node.child[1] = rhsNode;
                        }
                    }
                }
            }
        } else if (parseNode.expressionType == "binary") {
            let opInfo = BINARY_OPERATOR[parseNode.operator as SimcBinaryOperatorType];
            if (opInfo) {
                const parseNodeOperator = parseNode.operator as SimcBinaryOperatorType;
                let operator: OperatorType;
                if (parseNodeOperator == "&") {
                    operator = "and";
                } else if (parseNodeOperator == "^") {
                    operator = "xor";
                } else if (parseNodeOperator == "|") {
                    operator = "or";
                } else if (parseNodeOperator == "=") {
                    operator = "==";
                } else if (parseNodeOperator == "%") {
                    operator = "/";
                } else if (parseNode.type == "compare" || parseNode.type == "arithmetic") {
                    if (parseNodeOperator !== "~" && parseNodeOperator !== "!~") {
                        operator = parseNodeOperator;
                    }
                }
                if ((parseNode.operator == "=" || parseNode.operator == "!=") && (parseNode.child[1].name == "target" || parseNode.child[1].name == "current_target")) {
                    let rhsNode = parseNode.child[2];
                    let name = rhsNode.name;
                    if (truthy(find(name, "^[%a_]+%."))) {
                        [name] = match(name, "^[%a_]+%.([%a_]+)");
                    }
                    let code;
                    if (name == "sim_target") {
                        code = "True(target_is_sim_target)";
                    } else if (name == "target") {
                        code = "False(target_is_target)";
                    } else {
                        code = format("target.Name(%s)", name);
                        this.AddSymbol(annotation, name);
                    }
                    
                    if (parseNode.operator == "!=") {
                        code = "not " + code;
                    }
                    annotation.astAnnotation = annotation.astAnnotation || {};
                    [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                } else if ((parseNode.operator == "=" || parseNode.operator == "!=") && parseNode.child[1].name == "sim_target") {
                    let code;
                    if (parseNode.operator == "=") {
                        code = "True(target_is_sim_target)";
                    } else {
                        code = "False(target_is_sim_target)";
                    }
                    annotation.astAnnotation = annotation.astAnnotation || {};
                    [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                } else if (operator) {
                    let lhsNode = this.Emit(parseNode.child[1], nodeList, annotation, action);
                    let rhsNode = this.Emit(parseNode.child[2], nodeList, annotation, action);
                    if (lhsNode && rhsNode) {
                        node = this.ovaleAst.NewNode(nodeList, true);
                        node.type = opInfo[1];
                        node.expressionType = "binary";
                        node.operator = operator;
                        node.child[1] = lhsNode;
                        node.child[2] = rhsNode;
                    } else if (lhsNode) {
                        msg = MakeString("Warning: %s operator '%s' right failed.", parseNode.type, parseNode.operator);
                    } else if (rhsNode) {
                        msg = MakeString("Warning: %s operator '%s' left failed.", parseNode.type, parseNode.operator);
                    } else {
                        msg = MakeString("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator);
                    }
                }
            }
        }
        if (node) {
            if (parseNode.left && parseNode.right) {
                node.left = "{";
                node.right = "}";
            }
        } else {
            msg = msg || MakeString("Warning: Operator '%s' is not implemented.", parseNode.operator);
            this.tracer.Print(msg);
            const stringNode = <StringNode>this.ovaleAst.NewNode(nodeList);
            stringNode.type = "string";
            stringNode.value = `FIXME_${parseNode.operator}`;
            return stringNode;
        }
        return node;
    }
    
    private EmitFunction: EmitVisitor = (parseNode, nodeList, annotation, action) => {
        let node;
        if (parseNode.name == "ceil" || parseNode.name == "floor") {
            node = this.EmitExpression(parseNode.child[1], nodeList, annotation, action);
        } else {
            this.tracer.Print("Warning: Function '%s' is not implemented.", parseNode.name);
            node = this.ovaleAst.NewNode(nodeList);
            node.type = "variable";
            node.name = `FIXME_${parseNode.name}`;
        }
        return node;
    }

    private EmitNumber: EmitVisitor = (parseNode, nodeList, annotation, action) => {
        let node = <ValueNode>this.ovaleAst.NewNode(nodeList);
        node.type = "value";
        node.value = parseNode.value;
        node.origin = 0;
        node.rate = 0;
        return node;
    }
    private EmitOperand: EmitVisitor = (parseNode, nodeList, annotation, action) => {
        let ok = false;
        let node : AstNode;
        let operand = parseNode.name;
        let [token] = match(operand, OPERAND_TOKEN_PATTERN);
        let target:string;
        if (token == "target") {
            [ok, node] = this.EmitOperandTarget(operand, parseNode, nodeList, annotation, action);
            if (!ok) {
                target = token;
                operand = sub(operand, len(target) + 2);
                [token] = match(operand, OPERAND_TOKEN_PATTERN);
            }
        }

        if (!ok) {
            [ok, node] = this.EmitOperandRune(operand, parseNode, nodeList, annotation, action);
        }
        if (!ok) {
            [ok, node] = this.EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target);
        }
        if (!ok) {
            [ok, node] = this.EmitOperandRaidEvent(operand, parseNode, nodeList, annotation, action);
        }
        if (!ok) {
            [ok, node] = this.EmitOperandRace(operand, parseNode, nodeList, annotation, action);
        }
        if (!ok) {
            [ok, node] = this.EmitOperandAction(operand, parseNode, nodeList, annotation, action, target);
        }
        if (!ok) {
            [ok, node] = this.EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target);
        }
        if (!ok) {
            if (token == "active_dot") {
                target = target || "target";
                [ok, node] = this.EmitOperandActiveDot(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "aura") {
                [ok, node] = this.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "artifact") {
                [ok, node] = this.EmitOperandArtifact(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "azerite") {
                [ok, node] = this.EmitOperandAzerite(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "buff") {
                [ok, node] = this.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "consumable") {
                [ok, node] = this.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "cooldown") {
                [ok, node] = this.EmitOperandCooldown(operand, parseNode, nodeList, annotation, action);
            } else if (token == "debuff") {
                target = target || "target";
                [ok, node] = this.EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "disease") {
                target = target || "target";
                [ok, node] = this.EmitOperandDisease(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "dot") {
                target = target || "target";
                [ok, node] = this.EmitOperandDot(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "essence") {
                [ok, node] = this.EmitOperandEssence(operand, parseNode, nodeList, annotation, action, target);
            } else if (token == "glyph") {
                [ok, node] = this.EmitOperandGlyph(operand, parseNode, nodeList, annotation, action);
            } else if (token == "pet") {
                [ok, node] = this.EmitOperandPet(operand, parseNode, nodeList, annotation, action);
            } else if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
                [ok, node] = this.EmitOperandPreviousSpell(operand, parseNode, nodeList, annotation, action);
            } else if (token == "refreshable") {
                [ok, node] = this.EmitOperandRefresh(operand, parseNode, nodeList, annotation, action);
            } else if (token == "seal") {
                [ok, node] = this.EmitOperandSeal(operand, parseNode, nodeList, annotation, action);
            } else if (token == "set_bonus") {
                [ok, node] = this.EmitOperandSetBonus(operand, parseNode, nodeList, annotation, action);
            } else if (token == "talent") {
                [ok, node] = this.EmitOperandTalent(operand, parseNode, nodeList, annotation, action);
            } else if (token == "totem") {
                [ok, node] = this.EmitOperandTotem(operand, parseNode, nodeList, annotation, action);
            } else if (token == "trinket") {
                [ok, node] = this.EmitOperandTrinket(operand, parseNode, nodeList, annotation, action);
            } else if (token == "variable") {
                [ok, node] = this.EmitOperandVariable(operand, parseNode, nodeList, annotation, action);
            } else if (token == "ground_aoe") {
                [ok, node] = this.EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action);
            }
        }
        if (!ok) {
            this.tracer.Print("Warning: Variable '%s' is not implemented.", parseNode.name);
            node = this.ovaleAst.NewNode(nodeList);
            node.type = "variable";
            node.name = `FIXME_${parseNode.name}`;
        }
        return node;
    }
    
    private EmitOperandAction: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let name;
        let property;
        if (sub(operand, 1, 7) == "action.") {
            let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
            tokenIterator();
            name = tokenIterator();
            property = tokenIterator();
        } else {
            name = action;
            property = operand;
        }

        if (!name) {
            return [false, undefined];
        }

        let [className, specialization] = [annotation.class, annotation.specialization];
        [name] = this.Disambiguate(annotation, name, className, specialization);
        target = target && (`${target}.`) || "";
        let buffName = `${name}_debuff`;
        [buffName] = this.Disambiguate(annotation, buffName, className, specialization);
        let prefix = truthy(find(buffName, "_debuff$")) && "Debuff" || "Buff";
        let buffTarget = (prefix == "Debuff") && "target." || target;
        let talentName = `${name}_talent`;
        [talentName] = this.Disambiguate(annotation, talentName, className, specialization);
        let symbol = name;
        let code;
        if (property == "active") {
            if (IsTotem(name)) {
                code = format("TotemPresent(%s)", name);
            } else {
                code = format("%s%sPresent(%s)", target, prefix, buffName);
                symbol = buffName;
            }
        } else if (property == "ap_check") {
            code = format("AstralPower() >= AstralPowerCost(%s)", name)
        } else if (property == "cast_regen") {
            code = format("FocusCastingRegen(%s)", name);
        } else if (property == "cast_time") {
            code = format("CastTime(%s)", name);
        } else if (property == "charges") {
            code = format("Charges(%s)", name);
        } else if (property == "max_charges") {
            code = format("SpellMaxCharges(%s)", name);
        } else if (property == "charges_fractional") {
            code = format("Charges(%s count=0)", name);
        } else if (property == "cooldown") {
            code = format("SpellCooldown(%s)", name);
        } else if (property == "cooldown_react") {
            code = format("not SpellCooldown(%s) > 0", name);
        } else if (property == "cost") {
            code = format("PowerCost(%s)", name);
        } else if (property == "crit_damage") {
            code = format("%sCritDamage(%s)", target, name);
        } else if (property == "damage") {
            code = format("%sDamage(%s)", target, name);
        } else if (property == "duration" || property == "new_duration") {
            code = format("BaseDuration(%s)", buffName);
            symbol = buffName;
        } else if (property == "enabled") {
            if (parseNode.asType == "boolean") {
                code = format("Talent(%s)", talentName);
            } else {
                code = format("TalentPoints(%s)", talentName);
            }
            symbol = talentName;
        } else if (property == "execute_time" || property == "execute_remains") {
            code = format("ExecuteTime(%s)", name);
        } else if (property == "executing") {
            code = format("ExecuteTime(%s) > 0", name);
        } else if (property == "gcd") {
            code = "GCD()";
        } else if (property == "hit_damage") {
            code = format("%sDamage(%s)", target, name);
        } else if (property == "in_flight" || property == "in_flight_to_target") {
            code = format("InFlightToTarget(%s)", name);
        } else if (property == "in_flight_remains") {
            code = "0";
        } else if (property == "miss_react") {
            code = "True(miss_react)";
        } else if (property == "persistent_multiplier" || property == "pmultiplier") {
            code = format("PersistentMultiplier(%s)", buffName);
        } else if (property == "recharge_time") {
            code = format("SpellChargeCooldown(%s)", name);
        } else if (property == "full_recharge_time") {
            code = format("SpellFullRecharge(%s)", name)
        } else if (property == "remains") {
            if (IsTotem(name)) {
                code = format("TotemRemaining(%s)", name);
            } else {
                code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName);
                symbol = buffName;
            }
        } else if (property == "shard_react") {
            code = "SoulShards() >= 1";
        } else if (property == "tick_dmg" || property === "tick_damage") {
            code = format("%sLastDamage(%s)", buffTarget, buffName);
        } else if (property == "tick_time") {
            code = format("%sCurrentTickTime(%s)", buffTarget, buffName);
            symbol = buffName;
        } else if (property == "ticking") {
            code = format("%s%sPresent(%s)", buffTarget, prefix, buffName);
            symbol = buffName;
        } else if (property == "ticks_remain") {
            code = format("%sTicksRemaining(%s)", buffTarget, buffName);
            symbol = buffName;
        } else if (property == "travel_time") {
            code = format("TravelTime(%s)", name);
        } else if (property == "usable") {
            code = format("CanCast(%s)", name);
        } else if (property == "usable_in") {
            code = format("SpellCooldown(%s)", name);
        } else if (property == "marks_next_gcd") {
            code = "0"; // TODO
        } else {
            ok = false;
        }
        if (ok && code) {
            if (name == "call_action_list" && property != "gcd") {
                this.tracer.Print("Warning: dubious use of call_action_list in %s", code);
            }
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            if (!SPECIAL_ACTION[symbol]) {
                this.AddSymbol(annotation, symbol);
            }
        }
        return [ok, node];
    }
    private EmitOperandActiveDot: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "active_dot") {
            let name = tokenIterator();
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let dotName = `${name}_debuff`;
            [dotName] = this.Disambiguate(annotation, dotName, annotation.class, annotation.specialization);
            let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
            target = target && (`${target}.`) || "";
            let code = format("%sCountOnAny(%s)", prefix, dotName);
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, dotName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    
    private EmitOperandArtifact: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "artifact") {
            let code:string;
            let name = tokenIterator();
            let property = tokenIterator();
            if (property == "rank") {
                code = format("ArtifactTraitRank(%s)", name);
            } else if (property == "enabled") {
                code = format("HasArtifactTrait(%s)", name);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, name);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
   
   private EmitOperandAzerite: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "azerite") {
            let code:string;
            let name = tokenIterator();
            let property = tokenIterator();
            if (property == "rank") {
                code = format("AzeriteTraitRank(%s_trait)", name);
            } else if (property == "enabled") {
                code = format("HasAzeriteTrait(%s_trait)", name);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, `${name}_trait`);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    
    private EmitOperandEssence: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "essence") {
            let code:string;
            let name = tokenIterator();
            let property = tokenIterator();
            
            let essenceId = format("%s_essence_id", name);
            [essenceId] = this.Disambiguate(annotation, essenceId, annotation.class, annotation.specialization);
            
            if(property == "major") {
                code = format("AzeriteEssenceIsMajor(%s)", essenceId);
            } else if (property == "minor") {
                code = format("AzeriteEssenceIsMinor(%s)", essenceId);
            } else if (property == "enabled") {
                code = format("AzeriteEssenceIsEnabled(%s)", essenceId);
            } else if (property === "rank") {
                code = format("AzeriteEssenceRank(%s)", essenceId);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, essenceId);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
   
   private EmitOperandRefresh: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "refreshable") {
            let buffName = `${action}_debuff`;
            [buffName] = this.Disambiguate(annotation, buffName, annotation.class, annotation.specialization);
            let target;
            let prefix = truthy(find(buffName, "_buff$")) && "Buff" || "Debuff";
            if (prefix == "Debuff") {
                target = "target.";
            } else {
                target = "";
            }
            let any = this.ovaleData.DEFAULT_SPELL_LIST[buffName] && " any=1" || "";
            let code = format("%sRefreshable(%s%s)", target, buffName, any);
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            this.AddSymbol(annotation, buffName);
        }
        return [ok, node];
    }
    
    private EmitOperandBuff: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "aura" || token == "buff" || token == "debuff" || token == "consumable") {
            let name = tokenIterator();
            let property = tokenIterator();
            if ((token == "consumable" && property == undefined)) {
                property = "remains";
            }
            
            // buffname
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let buffName = (token == "debuff") && `${name}_debuff` || `${name}_buff`;
            [buffName] = this.Disambiguate(annotation, buffName, annotation.class, annotation.specialization);
            let prefix
            if (!truthy(find(buffName, "_debuff$")) && !truthy(find(buffName, "_debuff$"))) {
                prefix = target == "target" && "Debuff" || "Buff";
            } else {
                prefix = truthy(find(buffName, "_debuff$")) && "Debuff" || "Buff";
            }
            
            let any = this.ovaleData.DEFAULT_SPELL_LIST[buffName] && " any=1" || "";
            
            // target
            target = target && (`${target}.`) || "";
            if (buffName == "dark_transformation_buff" && target == "") {
                target = "pet.";
            }
            if (buffName == "pet_beast_cleave_buff" && target == "") {
                target = "pet.";
            }
            if (buffName == "pet_frenzy_buff" && target == "") {
                target = "pet.";
            }
            
            let code;
            if (property == "cooldown_remains") {
                code = format("SpellCooldown(%s)", name);
            } else if (property == "down") {
                code = format("%s%sExpires(%s%s)", target, prefix, buffName, any);
            } else if (property == "duration") {
                code = format("BaseDuration(%s)", buffName);
            } else if (property == "max_stack") {
                code = format("SpellData(%s max_stacks)", buffName);
            } else if (property == "react" || property == "stack") {
                if (parseNode.asType == "boolean") {
                    code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
                } else {
                    code = format("%s%sStacks(%s%s)", target, prefix, buffName, any);
                }
            } else if (property == "remains") {
                if (parseNode.asType == "boolean") {
                    code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
                } else {
                    code = format("%s%sRemaining(%s%s)", target, prefix, buffName, any);
                }
            } else if (property == "up") {
                code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
            } else if (property == "improved") {
                code = format("%sImproved(%s%s)", prefix, buffName);
            } else if (property == "value") {
                code = format("%s%sAmount(%s%s)", target, prefix, buffName, any);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, buffName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }

    private EmitOperandCharacter: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let className = annotation.class;
        let specialization = annotation.specialization;
        let camelSpecialization = CamelSpecialization(annotation);
        target = target && (`${target}.`) || "";
        let code;
        if (CHARACTER_PROPERTY[operand]) {
            code = `${target}${CHARACTER_PROPERTY[operand]}`;
        } else if (operand == "position_front") {
            code = annotation.position == "front" && "True(position_front)" || "False(position_front)"
        } else if (operand == "position_back") {
            code = annotation.position == "back" && "True(position_back)" || "False(position_back)"
        } else if (className == "MAGE" && operand == "incanters_flow_dir") {
            let name = "incanters_flow_buff";
            code = format("BuffDirection(%s)", name);
            this.AddSymbol(annotation, name);
        } else if (className == "PALADIN" && operand == "time_to_hpg") {
            code = `${camelSpecialization}TimeToHPG()`;
            if (specialization == "holy") {
                annotation.time_to_hpg_heal = className;
            } else if (specialization == "protection") {
                annotation.time_to_hpg_tank = className;
            } else if (specialization == "retribution") {
                annotation.time_to_hpg_melee = className;
            }
        } else if (className == "PRIEST" && operand == "shadowy_apparitions_in_flight") {
            code = "1";
        } else if (operand == "rtb_buffs") {
            code = "BuffCount(roll_the_bones_buff)";
        } else if (className == "ROGUE" && operand == "anticipation_charges") {
            let name = "anticipation_buff";
            code = format("BuffStacks(%s)", name);
            this.AddSymbol(annotation, name);
        } else if (sub(operand, 1, 22) == "active_enemies_within.") {
            code = "Enemies()";
        } else if (truthy(find(operand, "^incoming_damage_"))) {
            let [_seconds, measure] = match(operand, "^incoming_damage_([%d]+)(m?s?)$");
            let seconds = tonumber(_seconds);
            if (measure == "ms") {
                seconds = seconds / 1000;
            }
            if (parseNode.asType == "boolean") {
                code = format("IncomingDamage(%f) > 0", seconds);
            } else {
                code = format("IncomingDamage(%f)", seconds);
            }
        } else if (sub(operand, 1, 10) == "main_hand.") {
            let weaponType = sub(operand, 11);
            if (weaponType == "1h") {
                code = "HasWeapon(main type=one_handed)";
            } else if (weaponType == "2h") {
                code = "HasWeapon(main type=two_handed)";
            }
        } else if (operand == "mastery_value") {
            code = format("%sMasteryEffect() / 100", target);
        } else if (sub(operand, 1, 5) == "role.") {
            let [role] = match(operand, "^role%.([%w_]+)");
            if (role && role == annotation.role) {
                code = format("True(role_%s)", role);
            } else {
                code = format("False(role_%s)", role);
            }
        } else if (operand == "spell_haste" || operand == "stat.spell_haste") {
            code = "100 / { 100 + SpellCastSpeedPercent() }";
        } else if (operand == "attack_haste" || operand == "stat.attack_haste") {
            code = "100 / { 100 + MeleeAttackSpeedPercent() }";
        } else if (sub(operand, 1, 13) == "spell_targets") {
            code = "Enemies()";
        } else if (operand == "t18_class_trinket") {
            code = format("HasTrinket(%s)", operand);
            this.AddSymbol(annotation, operand);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }

    private EmitOperandCooldown: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        
        if (token == "cooldown") {
            let name = tokenIterator();
            let property = tokenIterator();
            let prefix;
            [name, prefix] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization, "Spell");
            let code;
            if (property == "execute_time") {
                code = format("ExecuteTime(%s)", name);
            } else if (property == "duration") {
                code = format("%sCooldownDuration(%s)", prefix, name);
            } else if (property == "ready") {
                code = format("%sCooldown(%s) == 0", prefix, name);
            } else if (property == "remains" || property == "remains_guess" || property == "adjusted_remains") {
                if (parseNode.asType == "boolean") {
                    code = format("%sCooldown(%s) > 0", prefix, name);
                } else {
                    code = format("%sCooldown(%s)", prefix, name);
                }
            } else if (property == "up") {
                code = format("not %sCooldown(%s) > 0", prefix, name);
            } else if (property == "charges") {
                if (parseNode.asType == "boolean") {
                    code = format("%sCharges(%s) > 0", prefix, name);
                } else {
                    code = format("%sCharges(%s)", prefix, name);
                }
            } else if (property == "charges_fractional") {
                code = format("%sCharges(%s count=0)", prefix, name);
            } else if (property == "max_charges") {
                code = format("%sMaxCharges(%s)", prefix, name);
            } else if (property == "full_recharge_time") {
                code = format("%sCooldown(%s)", prefix, name);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, name);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandDisease: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "disease") {
            let property = tokenIterator();
            target = target && (`${target}.`) || "";
            let code;
            if (property == "max_ticking") {
                code = `${target}DiseasesAnyTicking()`;
            } else if (property == "min_remains") {
                code = `${target}DiseasesRemaining()`;
            } else if (property == "min_ticking") {
                code = `${target}DiseasesTicking()`;
            } else if (property == "ticking") {
                code = `${target}DiseasesAnyTicking()`;
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }

    private EmitOperandGroundAoe: EmitOperandVisitor = (operand: string, parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string): [boolean, AstNode] => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "ground_aoe") {
            let name = tokenIterator();
            let property = tokenIterator();
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let dotName = `${name}_debuff`;
            [dotName] = this.Disambiguate(annotation, dotName, annotation.class, annotation.specialization);
            let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
            let target = (prefix == "Debuff" && "target.") || "";
            let code;
            if (property == "remains") {
                code = format("%s%sRemaining(%s)", target, prefix, dotName);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, dotName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }

    private EmitOperandDot: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "dot") {
            let name = tokenIterator();
            let property = tokenIterator();
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let dotName = `${name}_debuff`;
            [dotName] = this.Disambiguate(annotation, dotName, annotation.class, annotation.specialization);
            let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
            target = target && (`${target}.`) || "";
            let code;
            if (property == "duration") {
                code = format("%s%sDuration(%s)", target, prefix, dotName);
            } else if (property == "pmultiplier") {
                code = format("%s%sPersistentMultiplier(%s)", target, prefix, dotName);
            } else if (property == "remains") {
                code = format("%s%sRemaining(%s)", target, prefix, dotName);
            } else if (property == "stack") {
                code = format("%s%sStacks(%s)", target, prefix, dotName);
            } else if (property == "tick_dmg") {
                code = format("%sTickValue(%s)", target, prefix, dotName);
            } else if (property == "ticking") {
                code = format("%s%sPresent(%s)", target, prefix, dotName);
            } else if (property == "ticks_remain") {
                code = format("%sTicksRemaining(%s)", target, dotName);
            } else if (property == "tick_time_remains") {
                code = format("%sTickTimeRemaining(%s)", target, dotName);
            } else if (property == "exsanguinated") {
                code = format("TargetDebuffRemaining(%s_exsanguinated)", dotName);
            } else if (property == "refreshable") {
                code = format("%s%sRefreshable(%s)", target, prefix, dotName);
            } else if (property === "max_stacks") {
                code = format("MaxStacks(%s)", dotName);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, dotName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandGlyph: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "glyph") {
            let name = tokenIterator();
            let property = tokenIterator();
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let glyphName = `glyph_of_${name}`;
            [glyphName] = this.Disambiguate(annotation, glyphName, annotation.class, annotation.specialization);
            let code;
            if (property == "disabled") {
                code = format("not Glyph(%s)", glyphName);
            } else if (property == "enabled") {
                code = format("Glyph(%s)", glyphName);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, glyphName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandPet: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "pet") {
            let name = tokenIterator();
            let property = tokenIterator();
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let isTotem = IsTotem(name);
            let code;
            if (isTotem && property == "active") {
                code = format("TotemPresent(%s)", name);
            } else if (isTotem && property == "remains") {
                code = format("TotemRemaining(%s)", name);
            } else if (property == "active") {
                code = "pet.Present()";
            } else if (name == "buff") {
                let pattern = format("^pet%%.([%%w_.]+)", operand);
                let [petOperand] = match(operand, pattern);
                [ok, node] = this.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, "pet");
            } else {
                let pattern = format("^pet%%.%s%%.([%%w_.]+)", name);
                let [petOperand] = match(operand, pattern);
                let target = "pet";
                if (petOperand) {
                    [ok, node] = this.EmitOperandSpecial(petOperand, parseNode, nodeList, annotation, action, target);
                    if (!ok) {
                        [ok, node] = this.EmitOperandAction(petOperand, parseNode, nodeList, annotation, action, target);
                    }
                    if (!ok) {
                        [ok, node] = this.EmitOperandCharacter(petOperand, parseNode, nodeList, annotation, action, target);
                    }
                    if (!ok) {
                        let [petAbilityName] = match(petOperand, "^[%w_]+%.([^.]+)");
                        [petAbilityName] = this.Disambiguate(annotation, petAbilityName, annotation.class, annotation.specialization);
                        if (sub(petAbilityName, 1, 4) != "pet_") {
                            petOperand = gsub(petOperand, "^([%w_]+)%.", `%1.${name}_`);
                        }
                        if (property == "buff") {
                            [ok, node] = this.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target);
                        } else if (property == "cooldown") {
                            [ok, node] = this.EmitOperandCooldown(petOperand, parseNode, nodeList, annotation, action);
                        } else if (property == "debuff") {
                            [ok, node] = this.EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target);
                        } else if (property == "dot") {
                            [ok, node] = this.EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target);
                        } else {
                            ok = false;
                        }
                    }
                } else {
                    ok = false;
                }
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, name);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandPreviousSpell: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
            let name = tokenIterator();
            let howMany = 1;
            if (tonumber(name)) {
                howMany = tonumber(name);
                name = tokenIterator();
            }
            [name] = this.Disambiguate(annotation, name, annotation.class, annotation.specialization);
            let code;
            if (token == "prev") {
                code = format("PreviousSpell(%s)", name);
            } else if (token == "prev_gcd") {
                if (howMany != 1) {
                    code = format("PreviousGCDSpell(%s count=%d)", name, howMany);
                } else {
                    code = format("PreviousGCDSpell(%s)", name);
                }
            } else {
                code = format("PreviousOffGCDSpell(%s)", name);
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, name);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandRaidEvent: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let name;
        let property;
        if (sub(operand, 1, 11) == "raid_event.") {
            let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
            tokenIterator();
            name = tokenIterator();
            property = tokenIterator();
        } else {
            let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
            name = tokenIterator();
            property = tokenIterator();
        }
        let code;
        if (name == "movement") {
            if (property == "cooldown" || property == "in") {
                code = "600";
            } else if (property == "distance") {
                code = "target.Distance()";
            } else if (property == "exists") {
                code = "False(raid_event_movement_exists)";
            } else if (property == "remains") {
                code = "0";
            } else {
                ok = false;
            }
        } else if (name == "adds") {
            if (property == "cooldown") {
                code = "600";
            } else if (property == "count") {
                code = "0";
            } else if (property == "exists" || property == "up") {
                code = "False(raid_event_adds_exists)";
            } else if (property == "in") {
                code = "600";
            } else if (property == "duration") {
                code = "10"  //TODO
            } else {
                ok = false;
            }
        } else if (name == "invulnerable") {
            if (property == "up") {
                code = "False(raid_events_invulnerable_up)";
            } else {
                ok = false;
            }
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }
    private EmitOperandRace: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "race") {
            let race = lower(tokenIterator());
            let code;
            if (race) {
                let raceId = undefined;
                if ((race == "blood_elf")) {
                    raceId = "BloodElf";
                } else if (race == "troll") {
                    raceId = "Troll";
                } else if (race == "orc") {
                    raceId = "Orc";
                } else {
                    this.tracer.Print("Warning: Race '%s' not defined", race);
                }
                code = format("Race(%s)", raceId);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {
                };
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandRune: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let code;
        if (parseNode.rune) {
            if (parseNode.asType == "boolean") {
                code = "RuneCount() >= 1";
            } else {
                code = "RuneCount()";
            }
        } else if (truthy(match(operand, "^rune.time_to_([%d]+)$"))) {
            let runes = match(operand, "^rune.time_to_([%d]+)$");
            code = format("TimeToRunes(%d)", runes);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }
    private EmitOperandSetBonus: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node;
        let [setBonus] = match(operand, "^set_bonus%.(.*)$");
        let code;
        if (setBonus) {
            let tokenIterator = gmatch(setBonus, "[^_]+");
            let name = tokenIterator();
            let count = tokenIterator();
            let role = tokenIterator();
            if (name && count) {
                let [setName, level] = match(name, "^(%a+)(%d*)$");
                if (setName == "tier") {
                    setName = "T";
                } else {
                    setName = upper(setName);
                }
                if (level) {
                    name = `${setName}${tostring(level)}`;
                }
                if (role) {
                    name = `${name}_${role}`;
                }
                [count] = match(count, "(%d+)pc");
                if (name && count) {
                    code = format("ArmorSetBonus(%s %d)", name, count);
                }
            }
            if (!code) {
                ok = false;
            }
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }
    private EmitOperandSeal: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "seal") {
            let name = lower(tokenIterator());
            let code;
            if (name) {
                code = format("Stance(paladin_seal_of_%s)", name);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandSpecial: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action, target) => {
        let ok = true;
        let node: AstNode;
        let className = annotation.class;
        let specialization = annotation.specialization;
        target = target && (`${target}.`) || "";
        operand = lower(operand);
        let code;
        if (className == "DEATHKNIGHT" && operand == "dot.breath_of_sindragosa.ticking") {
            let buffName = "breath_of_sindragosa";
            code = format("BuffPresent(%s)", buffName);
            this.AddSymbol(annotation, buffName);
        } else if (className == "DEATHKNIGHT" && sub(operand, 1, 24) == "pet.dancing_rune_weapon.") {
            let petOperand = sub(operand, 25);
            let tokenIterator = gmatch(petOperand, OPERAND_TOKEN_PATTERN);
            let token = tokenIterator();
            if (token == "active") {
                let buffName = "dancing_rune_weapon_buff";
                code = format("BuffPresent(%s)", buffName);
                this.AddSymbol(annotation, buffName);
            } else if (token == "dot") {
                if (target == "") {
                    target = "target";
                } else {
                    target = sub(target, 1, -2);
                }
                [ok, node] = this.EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target);
            }
        } else if (className == "DEMONHUNTER" && operand == "buff.metamorphosis.extended_by_demonic") {
            code = "not BuffExpires(extended_by_demonic_buff)";
        } else if (className == "DEMONHUNTER" && operand == "cooldown.chaos_blades.ready") {
            code = "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0";
            this.AddSymbol(annotation, "chaos_blades_talent");
            this.AddSymbol(annotation, "chaos_blades");
        } else if (className == "DEMONHUNTER" && operand == "cooldown.nemesis.ready") {
            code = "Talent(nemesis_talent) and SpellCooldown(nemesis) == 0";
            this.AddSymbol(annotation, "nemesis_talent");
            this.AddSymbol(annotation, "nemesis");
        } else if (className == "DEMONHUNTER" && operand == "cooldown.metamorphosis.ready" && specialization == "havoc") {
            code = "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis_havoc) == 0";
            this.AddSymbol(annotation, "metamorphosis_havoc");
        } else if (className == "DRUID" && operand == "buff.wild_charge_movement.down") {
            code = "True(wild_charge_movement_down)";
        } else if (className == "DRUID" && operand == "eclipse_dir.lunar") {
            code = "EclipseDir() < 0";
        } else if (className == "DRUID" && operand == "eclipse_dir.solar") {
            code = "EclipseDir() > 0";
        } else if (className == "DRUID" && operand == "max_fb_energy") {
            let spellName = "ferocious_bite";
            code = format("EnergyCost(%s max=1)", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "DRUID" && operand == "solar_wrath.ap_check") {
            let spellName = "solar_wrath";
            code = format("AstralPower() >= AstralPowerCost(%s)", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "buff.careful_aim.up") {
            code = "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)";
            this.AddSymbol(annotation, "rapid_fire_buff");
        } else if (className == "HUNTER" && operand == "buff.stampede.remains") {
            let spellName = "stampede";
            code = format("TimeSincePreviousSpell(%s) < 40", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "lowest_vuln_within.5") {
            code = "target.DebuffRemaining(vulnerable)";
            this.AddSymbol(annotation, "vulnerable");
        } else if (className == "HUNTER" && operand == "cooldown.trueshot.duration_guess") {
            // we calculate the extension we got for trueshot (from talents), the last time we cast it
            // does the simulator even have this information?
            code = "0"
        } else if (className == "HUNTER" && operand == "ca_execute") {
            code = "Talent(careful_aim_talent) and (target.HealthPercent() > 80 or target.HealthPercent() < 20)";
            this.AddSymbol(annotation, "careful_aim_talent")
        } else if (className == "MAGE" && operand == "buff.rune_of_power.remains") {
            code = "TotemRemaining(rune_of_power)";
        } else if (className == "MAGE" && operand == "buff.shatterlance.up") {
            code = "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)";
            this.AddSymbol(annotation, "frostbolt");
            this.AddSymbol(annotation, "t18_class_trinket");
        } else if (className == "MAGE" && (operand == "burn_phase" || operand == "pyro_chain")) {
            if (parseNode.asType == "boolean") {
                code = format("GetState(%s) > 0", operand);
            } else {
                code = format("GetState(%s)", operand);
            }
        } else if (className == "MAGE" && (operand == "burn_phase_duration" || operand == "pyro_chain_duration")) {
            let variable = sub(operand, 1, -10);
            if (parseNode.asType == "boolean") {
                code = format("GetStateDuration(%s) > 0", variable);
            } else {
                code = format("GetStateDuration(%s)", variable);
            }
        } else if (className == "MAGE" && operand == "firestarter.active") {
            code = "Talent(firestarter_talent) and target.HealthPercent() >= 90";
            this.AddSymbol(annotation, "firestarter_talent");
        } else if (className == "MAGE" && operand == "brain_freeze_active") {
            code = "target.DebuffPresent(winters_chill_debuff)"
            this.AddSymbol(annotation, "winters_chill_debuff");
        } else if (className == "MAGE" && operand == "action.frozen_orb.in_flight") {
            code = "TimeSincePreviousSpell(frozen_orb) < 10"
            this.AddSymbol(annotation, "frozen_orb")
        } else if (className == "MONK" && sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target.") {
            let property = sub(operand, 36);
            if (target == "") {
                target = "target.";
            }
            let debuffName = "storm_earth_and_fire_target_debuff";
            this.AddSymbol(annotation, debuffName);
            if (property == "down") {
                code = format("%sDebuffExpires(%s)", target, debuffName);
            } else if (property == "up") {
                code = format("%sDebuffPresent(%s)", target, debuffName);
            } else {
                ok = false;
            }
        } else if (className == "MONK" && operand == "dot.zen_sphere.ticking") {
            let buffName = "zen_sphere_buff";
            code = format("BuffPresent(%s)", buffName);
            this.AddSymbol(annotation, buffName);
        } else if (className == "MONK" && sub(operand, 1, 8) == "stagger.") {
            let property = sub(operand, 9);
            if (property == "heavy" || property == "light" || property == "moderate") {
                let buffName = format("%s_stagger_debuff", property);
                code = format("DebuffPresent(%s)", buffName);
                this.AddSymbol(annotation, buffName);
            } else if (property == "pct") {
                code = format("%sStaggerRemaining() / %sMaxHealth() * 100", target, target);
            } else if (truthy(match(property, "last_tick_damage_(%d+)"))){
                let ticks = match(property, "last_tick_damage_(%d+)");
                code = format("StaggerTick(%d)", ticks);
            } else {
                ok = false;
            }
        } else if (className == "MONK" && operand == "spinning_crane_kick.count") {
            code = "SpellCount(spinning_crane_kick)";
            this.AddSymbol(annotation, "spinning_crane_kick");
        } else if (className == "PALADIN" && operand == "dot.sacred_shield.remains") {
            let buffName = "sacred_shield_buff";
            code = format("BuffRemaining(%s)", buffName);
            this.AddSymbol(annotation, buffName);
        } else if (className == "PRIEST" && operand == "mind_harvest") {
            code = "target.MindHarvest()";
        } else if (className == "PRIEST" && operand == "natural_shadow_word_death_range") {
            code = "target.HealthPercent() < 20";
        } else if (className == "PRIEST" && operand == "primary_target") {
            code = "1";
        } else if (className == "ROGUE" && operand == "trinket.cooldown.up") {
            code = "HasTrinket(draught_of_souls) and ItemCooldown(draught_of_souls) > 0";
            this.AddSymbol(annotation, "draught_of_souls");
        } else if (className == "ROGUE" && operand == "mantle_duration") {
            code = "BuffRemaining(master_assassins_initiative)";
            this.AddSymbol(annotation, "master_assassins_initiative");
        } else if (className == "ROGUE" && operand == "poisoned_enemies") {
            code = "0";
        } else if (className == "ROGUE" && operand == "poisoned_bleeds") {
            code = "DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)";
            this.AddSymbol(annotation, "rupture_debuff");
            this.AddSymbol(annotation, "garrote_debuff");
            this.AddSymbol(annotation, "internal_bleeding_talent");
            this.AddSymbol(annotation, "internal_bleeding_debuff");
        } else if (className == "ROGUE" && operand == "exsanguinated") {
            code = "target.DebuffPresent(exsanguinated)";
            this.AddSymbol(annotation, "exsanguinated");
        } 
        // TODO: has garrote been casted out of stealth with shrouded suffocation azerite trait?
        else if (className == "ROGUE" && operand == "ss_buffed") {
            code = "False(ss_buffed)"; 
        } else if (className == "ROGUE" && operand == "non_ss_buffed_targets") {
            code = "Enemies() - DebuffCountOnAny(garrote_debuff)"
            this.AddSymbol(annotation, "garrote_debuff");
        } else if (className == "ROGUE" && operand == "ss_buffed_targets_above_pandemic") {
            code = "0"
        } else if (className == "ROGUE" && operand == "master_assassin_remains") {
            code = "BuffRemaining(master_assassin_buff)";
            this.AddSymbol(annotation, "master_assassin_buff");
        } else if (className == "ROGUE" && operand == "buff.roll_the_bones.remains"){
            code = "BuffRemaining(roll_the_bones_buff)";
            this.AddSymbol(annotation, "roll_the_bones_buff");
        } else if (className == "ROGUE" && operand == "buff.roll_the_bones.up"){
            code = "BuffPresent(roll_the_bones_buff)";
            this.AddSymbol(annotation, "roll_the_bones_buff");
        } else if (className == "SHAMAN" && operand == "buff.resonance_totem.remains") {
            let [spell] = this.Disambiguate(annotation, "totem_mastery", annotation.class, annotation.specialization);
            code = format("TotemRemaining(%s)", spell);
            ok = true;
            this.AddSymbol(annotation, spell);
        } else if (className == "SHAMAN" && truthy(match(operand, "pet.[a-z_]+.active"))) {
            code = "pet.Present()";
            ok = true;
        } else if (className == "WARLOCK" && truthy(match(operand, "pet%.service_[a-z_]+%..+"))) {
            let [spellName, property] = match(operand, "pet%.(service_[a-z_]+)%.(.+)");
            if (property == "active") {
                code = format("SpellCooldown(%s) > 100", spellName);
                this.AddSymbol(annotation, spellName);
            } else {
                ok = false;
            }
        } else if (className == "WARLOCK" && truthy(match(operand, "dot.unstable_affliction_([1-5]).remains"))) {
            let num = match(operand, "dot.unstable_affliction_([1-5]).remains");
            code = format("target.DebuffStacks(unstable_affliction_debuff) >= %s", num);
        } else if (className == "WARLOCK" && operand == "buff.active_uas.stack") {
            code = "target.DebuffStacks(unstable_affliction_debuff)";
        } else if (className == "WARLOCK" && truthy(match(operand, "pet%.[a-z_]+%..+"))) {
            let [spellName, property] = match(operand, "pet%.([a-z_]+)%.(.+)");
            if(property == "remains"){
                code = format("DemonDuration(%s)", spellName)
            }else if(property == "active"){
                code = format("DemonDuration(%s) > 0", spellName)
            }
        } else if (className == "WARLOCK" && operand == "contagion") {
            code = "BuffRemaining(unstable_affliction_buff)";
        } else if (className == "WARLOCK" && operand == "buff.wild_imps.stack") {
            code = "Demons(wild_imp) + Demons(wild_imp_inner_demons)";
            this.AddSymbol(annotation, "wild_imp");
            this.AddSymbol(annotation, "wild_imp_inner_demons");
        } else if (className == "WARLOCK" && operand == "buff.dreadstalkers.remains") {
            code = "DemonDuration(dreadstalker)";
            this.AddSymbol(annotation, "dreadstalker");
        } else if (className == "WARLOCK" && truthy(match(operand, "imps_spawned_during.([%d]+)"))) {
            let ms = match(operand, "imps_spawned_during.([%d]+)");
            code = format("ImpsSpawnedDuring(%d)", ms);
        } else if (className == "WARLOCK" && operand == "time_to_imps.all.remains") {
            code = "0" // let's assume imps spawn instantly
        } else if (className == "WARLOCK" && operand == "havoc_active") {
            code = "DebuffCountOnAny(havoc) > 0";
            this.AddSymbol(annotation, "havoc");
        } else if (className == "WARLOCK" && operand == "havoc_remains") {
            code = "DebuffRemainingOnAny(havoc)";
            this.AddSymbol(annotation, "havoc");
        } else if (className == "WARRIOR" && operand == "gcd.remains" && (action == "battle_cry" || action == "avatar")) {
            code = "0";
        } else if (operand == "buff.enrage.down") {
            code = `not ${target}IsEnraged()`;
        } else if (operand == "buff.enrage.remains") {
            code = `${target}EnrageRemaining()`;
        } else if (operand == "buff.enrage.up") {
            code = `${target}IsEnraged()`;
        } else if (operand == "debuff.casting.react") {
            code = `${target}IsInterruptible()`;
        } else if (operand == "debuff.casting.up") {
            let t = (target == "" && "target.") || target;
            code = `${t}IsInterruptible()`;
        } else if (operand == "debuff.flying.down") {
            code = `${target}True(debuff_flying_down)`;
        } else if (operand == "distance") {
            code = `${target}Distance()`;
        } else if (sub(operand, 1, 9) == "equipped.") {
            let [name] = this.Disambiguate(annotation, `${sub(operand, 10)}_item`, className, specialization);
            let itemId = tonumber(name)
            let itemName = name;
            let item = itemId && tostring(itemId) || itemName
            code = format("HasEquippedItem(%s)", item)
            this.AddSymbol(annotation, item);
        } else if (operand == "gcd.max") {
            code = "GCD()";
        } else if (operand == "gcd.remains") {
            code = "GCDRemaining()";
        } else if (sub(operand, 1, 15) == "legendary_ring.") {
            let [name] = this.Disambiguate(annotation, "legendary_ring", className, specialization);
            let buffName = `${name}_buff`;
            let properties = sub(operand, 16);
            let tokenIterator = gmatch(properties, OPERAND_TOKEN_PATTERN);
            let token = tokenIterator();
            if (token == "cooldown") {
                token = tokenIterator();
                if (token == "down") {
                    code = format("ItemCooldown(%s) > 0", name);
                    this.AddSymbol(annotation, name);
                } else if (token == "remains") {
                    code = format("ItemCooldown(%s)", name);
                    this.AddSymbol(annotation, name);
                } else if (token == "up") {
                    code = format("not ItemCooldown(%s) > 0", name);
                    this.AddSymbol(annotation, name);
                }
            } else if (token == "has_cooldown") {
                code = format("ItemCooldown(%s) > 0", name);
                this.AddSymbol(annotation, name);
            } else if (token == "up") {
                code = format("BuffPresent(%s)", buffName);
                this.AddSymbol(annotation, buffName);
            } else if (token == "remains") {
                code = format("BuffRemaining(%s)", buffName);
                this.AddSymbol(annotation, buffName);
            }
        } else if (operand == "ptr") {
            code = "PTR()";
        } else if (operand == "time_to_die") {
                code = "target.TimeToDie()";
        } else if (sub(operand, 1, 10) == "using_apl.") {
            let [aplName] = match(operand, "^using_apl%.([%w_]+)");
            code = format("List(opt_using_apl %s)", aplName);
            annotation.using_apl = annotation.using_apl || {}
            annotation.using_apl[aplName] = true;
        } else if (operand == "cooldown.buff_sephuzs_secret.remains") {
            code = "BuffCooldown(sephuzs_secret_buff)";
            this.AddSymbol(annotation, "sephuzs_secret_buff");
        } else if (operand == "is_add") {
            let t = target || "target.";
            code = format("not %sClassification(worldboss)", t);
        } else if (operand == "priority_rotation") {
            code = "CheckBoxOn(opt_priority_rotation)"
            annotation.opt_priority_rotation = className
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }
    private EmitOperandTalent: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "talent") {
            let name = lower(tokenIterator());
            let property = tokenIterator();
            let talentName = `${name}_talent`;
            [talentName] = this.Disambiguate(annotation, talentName, annotation.class, annotation.specialization);
            let code;
            if (property == "disabled") {
                if (parseNode.asType == "boolean") {
                    code = format("not Talent(%s)", talentName);
                } else {
                    code = format("Talent(%s no)", talentName);
                }
            } else if (property == "enabled") {
                if (parseNode.asType == "boolean") {
                    code = format("Talent(%s)", talentName);
                } else {
                    code = format("TalentPoints(%s)", talentName);
                }
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {
                };
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                this.AddSymbol(annotation, talentName);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
   
   private EmitOperandTarget: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "target") {
            let property = tokenIterator();
            let howMany = 1
            if (tonumber(property)) {
                howMany = tonumber(property);
                property = tokenIterator();
            }
            if(howMany > 1) {
                this.tracer.Print("Warning: target.%d.%property has not been implemented for multiple targets. (%s)", operand);
            }
            let code;
            //OvaleSimulationCraft.Print(token, property, operand);
            if (property == "adds") {
                code = "Enemies()-1";
            } else if (property == "time_to_die") {
                code = "target.TimeToDie()";
            } else if (property === "time_to_pct_30") {
                code = "target.TimeToHealthPercent(30)";
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    private EmitOperandTotem: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "totem") {
            let name = lower(tokenIterator());
            let property = tokenIterator();
            let code;
            if (property == "active") {
                code = format("TotemPresent(%s)", name);
            } else if (property == "remains") {
                code = format("TotemRemaining(%s)", name);
            } else {
                ok = false;
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {
                };
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    
    private EmitOperandTrinket: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let ok = true;
        let node: AstNode;
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "trinket") {
            let procType = tokenIterator();
            if (procType === "1" || procType === "2") {
                procType = tokenIterator(); // TODO use trinket slot?
            }
            let statName = tokenIterator();
            let code;
            if (procType === "cooldown") {
                if (statName == "remains") {
                    code = "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }";
                } else {
                    ok = false;
                }
            }
            else if (sub(procType, 1, 4) == "has_") {
                code = format("True(trinket_%s_%s)", procType, statName);
            } else {
                let property = tokenIterator();
                let buffName = format("trinket_%s_%s_buff", procType, statName);
                [buffName] = this.Disambiguate(annotation, buffName, annotation.class, annotation.specialization);
                if (property == "cooldown") {
                    code = format("BuffCooldownDuration(%s)", buffName);
                } else if (property == "cooldown_remains") {
                    code = format("BuffCooldown(%s)", buffName);
                } else if (property == "down") {
                    code = format("BuffExpires(%s)", buffName);
                } else if (property == "react") {
                    if (parseNode.asType == "boolean") {
                        code = format("BuffPresent(%s)", buffName);
                    } else {
                        code = format("BuffStacks(%s)", buffName);
                    }
                } else if (property == "remains") {
                    code = format("BuffRemaining(%s)", buffName);
                } else if (property == "stack") {
                    code = format("BuffStacks(%s)", buffName);
                } else if (property == "up") {
                    code = format("BuffPresent(%s)", buffName);
                } else {
                    ok = false;
                }
                if (ok) {
                    this.AddSymbol(annotation, buffName);
                }
            }
            if (ok && code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            }
        } else {
            ok = false;
        }
        return [ok, node];
    }
    
    private EmitOperandVariable: EmitOperandVisitor = (operand, parseNode, nodeList, annotation, action) => {
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        let node: AstNode;
        let ok;
        if (token == "variable") {
            let name = tokenIterator();
            if (annotation.currentVariable && annotation.currentVariable.name == name) {
                let group = annotation.currentVariable.child[1];
                if (lualength(group.child) == 0) {
                    [node] = this.ovaleAst.ParseCode("expression", "0", nodeList, annotation.astAnnotation);
                } else {
                    [node] = this.ovaleAst.ParseCode("expression", this.ovaleAst.Unparse(group), nodeList, annotation.astAnnotation);
                }
            } else {
                node = this.ovaleAst.NewNode(nodeList);
                node.type = "function";
                node.name = name;
            }
            ok = true;
        } else {
            ok = false;
        }
        return [ok, node];
    }

    private EMIT_VISITOR = {
        ["action"]: this.EmitAction,
        ["action_list"]: this.EmitActionList,
        ["arithmetic"]: this.EmitExpression,
        ["compare"]: this.EmitExpression,
        ["function"]: this.EmitFunction,
        ["logical"]: this.EmitExpression,
        ["number"]: this.EmitNumber,
        ["operand"]: this.EmitOperand
    }
}