import {
    ParseNode,
    Annotation,
    Modifier,
    specialActions,
    interruptsClasses,
    Modifiers,
    unaryOperators,
    SimcBinaryOperatorType,
    binaryOperators,
    SimcUnaryOperatorType,
    checkOptionalSkill,
    characterProperties,
    miscOperands,
    ActionParseNode,
    ActionListParseNode,
    FunctionParseNode,
    NumberParseNode,
    OperandParseNode,
    OperatorParseNode,
    MiscOperandModifierType,
} from "./definitions";
import {
    LuaArray,
    truthy,
    tonumber,
    lualength,
    kpairs,
    LuaObj,
    ipairs,
    tostring,
} from "@wowts/lua";
import {
    AstNode,
    OvaleASTClass,
    OperatorType,
    AstAddFunctionNode,
    AstGroupNode,
    isAstNodeWithChildren,
} from "../engine/ast";
import { Tracer, DebugTools } from "../engine/debug";
import {
    format,
    gmatch,
    find,
    match,
    lower,
    gsub,
    sub,
    len,
    upper,
} from "@wowts/string";
import { OvaleDataClass } from "../engine/data";
import { insert } from "@wowts/table";
import {
    toLowerSpecialization,
    toCamelCase,
    toOvaleFunctionName,
} from "./text-tools";
import { pooledResources } from "../states/Power";
import { Unparser } from "./unparser";
import { isNumber, makeString } from "../tools/tools";
import { ClassId } from "@wowts/wow-mock";
import { SpecializationName } from "../states/PaperDoll";

const operandTokenPattern = "[^.]+";

type EmitVisitor<T extends ParseNode> = (
    parseNode: T,
    nodeList: LuaArray<AstNode>,
    annotation: Annotation,
    action: string | undefined
) => AstNode | undefined;
type EmitOperandVisitor = (
    operand: string,
    parseNode: OperandParseNode,
    nodeList: LuaArray<AstNode>,
    annotation: Annotation,
    action?: string,
    target?: string
) => AstNode | undefined;

function isTotem(name: string) {
    if (sub(name, 1, 13) == "efflorescence") {
        return true;
    } else if (name == "rune_of_power") {
        return true;
    } else if (sub(name, -7, -1) == "_statue") {
        return true;
    } else if (truthy(match(name, "invoke_(chiji|yulon)"))) {
        return true;
    } else if (sub(name, -6, -1) == "_totem") {
        return true;
    } else if (name == "raise_dead") {
        return true;
    } else if (name == "summon_gargoyle") {
        return true;
    }
    return false;
}

function emitTrinketCondition(pattern: string, slot?: string) {
    if (slot) {
        return format(pattern, slot);
    } else {
        return `{${format(pattern, "trinket0slot")} and ${format(
            pattern,
            "trinket1slot"
        )}}`;
    }
}

type Disambiguations = LuaObj<LuaObj<LuaObj<{ 1: string; 2: string }>>>;

export class Emiter {
    private tracer: Tracer;
    private emitDisambiguations: Disambiguations = {};

    constructor(
        ovaleDebug: DebugTools,
        private ovaleAst: OvaleASTClass,
        private ovaleData: OvaleDataClass,
        private unparser: Unparser
    ) {
        this.tracer = ovaleDebug.create("SimulationCraftEmiter");
    }

    private addDisambiguation(
        name: string,
        info: string,
        className?: ClassId,
        specialization?: SpecializationName,
        _type?: string
    ) {
        this.addPerClassSpecialization(
            this.emitDisambiguations,
            name,
            info,
            className,
            specialization,
            _type
        );
    }

    private disambiguateExact(
        annotation: Annotation,
        name: string,
        className: ClassId | "ALL_CLASSES",
        specialization: SpecializationName | "ALL_SPECIALIZATIONS",
        _type?: "spell" | "item"
    ): [string | undefined, string | undefined] {
        const [disname, distype] = this.getPerClassSpecialization(
            this.emitDisambiguations,
            name,
            className,
            specialization
        );
        if (disname) {
            return [disname, distype];
        }

        if (annotation.dictionary[name]) {
            return [name, _type];
        }

        return [undefined, undefined];
    }

    private disambiguate(
        annotation: Annotation,
        name: string,
        className: ClassId | "ALL_CLASSES",
        specialization: SpecializationName | "ALL_SPECIALIZATIONS",
        _type?: "spell" | "item",
        suffix?: "buff" | "debuff" | "item"
    ): [string, string | undefined] {
        let disname: string | undefined;
        let distype: string | undefined;
        if (suffix) {
            [disname, distype] = this.disambiguateExact(
                annotation,
                `${name}_${specialization}_${suffix}`,
                className,
                specialization,
                _type
            );
            if (disname) return [disname, distype];

            [disname, distype] = this.disambiguateExact(
                annotation,
                `${name}_${lower(className)}_${suffix}`,
                className,
                specialization,
                _type
            );
            if (disname) return [disname, distype];
        }

        [disname, distype] = this.disambiguateExact(
            annotation,
            `${name}_${specialization}`,
            className,
            specialization,
            _type
        );
        if (disname) return [disname, distype];

        if (suffix) {
            [disname, distype] = this.disambiguateExact(
                annotation,
                `${name}_${suffix}`,
                className,
                specialization,
                _type
            );
            if (disname) return [disname, distype];
        }

        [disname, distype] = this.disambiguateExact(
            annotation,
            `${name}_${lower(className)}`,
            className,
            specialization,
            _type
        );
        if (disname) return [disname, distype];
        [disname, distype] = this.disambiguateExact(
            annotation,
            name,
            className,
            specialization,
            _type
        );
        if (disname) return [disname, distype];

        return [name, _type];
    }

    private addPerClassSpecialization(
        tbl: Disambiguations,
        name: string,
        info: string,
        className: ClassId | "ALL_CLASSES" | undefined,
        specialization: SpecializationName | "ALL_SPECIALIZATIONS" | undefined,
        _type: string | undefined
    ) {
        className = className || "ALL_CLASSES";
        specialization = specialization || "ALL_SPECIALIZATIONS";
        tbl[className] = tbl[className] || {};
        tbl[className][specialization] = tbl[className][specialization] || {};
        tbl[className][specialization][name] = {
            1: info,
            2: _type || "Spell",
        };
    }
    private getPerClassSpecialization(
        tbl: Disambiguations,
        name: string,
        className: ClassId | "ALL_CLASSES",
        specialization: SpecializationName | "ALL_SPECIALIZATIONS"
    ) {
        let info;
        while (!info) {
            while (!info) {
                if (
                    tbl[className] &&
                    tbl[className][specialization] &&
                    tbl[className][specialization][name]
                ) {
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

    public initializeDisambiguation() {
        this.addDisambiguation("exhaustion_buff", "exhaustion_debuff");
        this.addDisambiguation(
            "inevitable_demise_az_buff",
            "inevitable_demise",
            "WARLOCK"
        );
        this.addDisambiguation(
            "dark_soul",
            "dark_soul_misery",
            "WARLOCK",
            "affliction"
        );
        this.addDisambiguation("flagellation_cleanse", "flagellation", "ROGUE");
        this.addDisambiguation("ashvanes_razor_coral", "razor_coral");
        this.addDisambiguation(
            "bok_proc_buff",
            "blackout_kick_aura_buff",
            "MONK",
            "windwalker"
        );
        this.addDisambiguation(
            "dance_of_chiji_azerite_buff",
            "dance_of_chiji_buff",
            "MONK",
            "windwalker"
        );
        this.addDisambiguation(
            "energizing_elixer_talent",
            "energizing_elixir_talent",
            "MONK",
            "windwalker"
        );
        this.addDisambiguation(
            "chiji_the_red_crane",
            "invoke_chiji_the_red_crane",
            "MONK",
            "mistweaver"
        );
        this.addDisambiguation(
            "yulon_the_jade_serpent",
            "invoke_yulon_the_jade_serpent",
            "MONK",
            "mistweaver"
        );
        this.addDisambiguation("blink_any", "blink", "MAGE");
        this.addDisambiguation(
            "buff_disciplinary_command",
            "disciplinary_command",
            "MAGE"
        );
        this.addDisambiguation(
            "hyperthread_wristwraps_300142",
            "hyperthread_wristwraps",
            "MAGE",
            "fire"
        );
        this.addDisambiguation("use_mana_gem", "replenish_mana", "MAGE");
        this.addDisambiguation(
            "unbridled_fury_buff",
            "potion_of_unbridled_fury"
        );
        this.addDisambiguation("swipe_bear", "swipe", "DRUID");
        this.addDisambiguation(
            "wound_spender",
            "scourge_strike",
            "DEATHKNIGHT"
        );
        this.addDisambiguation("any_dnd", "death_and_decay", "DEATHKNIGHT");
        this.addDisambiguation(
            "incarnation_talent",
            "incarnation_tree_of_life_talent",
            "DRUID",
            "restoration"
        );
        this.addDisambiguation(
            "lunar_inspiration",
            "moonfire_cat",
            "DRUID",
            "feral"
        );
        this.addDisambiguation(
            "incarnation_talent",
            "incarnation_guardian_of_ursoc_talent",
            "DRUID",
            "guardian"
        );
        this.addDisambiguation(
            "incarnation_talent",
            "incarnation_chosen_of_elune_talent",
            "DRUID",
            "balance"
        );
        this.addDisambiguation(
            "incarnation_talent",
            "incarnation_king_of_the_jungle_talent",
            "DRUID",
            "feral"
        );
        this.addDisambiguation(
            "incarnation",
            "incarnation_chosen_of_elune",
            "DRUID",
            "balance"
        );
        this.addDisambiguation(
            "incarnation",
            "incarnation_guardian_of_ursoc",
            "DRUID",
            "guardian"
        );
        this.addDisambiguation(
            "incarnation",
            "incarnation_king_of_the_jungle",
            "DRUID",
            "feral"
        );
        this.addDisambiguation(
            "incarnation",
            "incarnation_tree_of_life",
            "DRUID",
            "restoration"
        );
        this.addDisambiguation("berserk", "berserk_bear", "DRUID", "guardian");
        this.addDisambiguation("berserk", "berserk_cat", "DRUID", "feral");
        this.addDisambiguation("bs_inc", "berserk_bear", "DRUID", "guardian");
        this.addDisambiguation("bs_inc", "berserk_cat", "DRUID", "feral");
        this.addDisambiguation("ca_inc", "celestial_alignment", "DRUID");
        this.addDisambiguation(
            "adaptive_swarm_heal",
            "adaptive_swarm",
            "DRUID"
        );
        this.addDisambiguation(
            "spectral_intellect_item",
            "potion_of_spectral_intellect_item"
        );
        this.addDisambiguation(
            "spectral_strength_item",
            "potion_of_spectral_strength_item"
        );
        this.addDisambiguation(
            "spectral_agility_item",
            "potion_of_spectral_agility_item"
        );
        this.addDisambiguation(
            "dreadfire_vessel_344732",
            "dreadfire_vessel",
            "MAGE"
        );
        this.addDisambiguation("fiend", "shadowfiend", "PRIEST");
        this.addDisambiguation(
            "deeper_strategem_talent",
            "deeper_stratagem_talent",
            "ROGUE"
        );
        this.addDisambiguation(
            "gargoyle",
            "summon_gargoyle",
            "DEATHKNIGHT",
            "unholy"
        );
        this.addDisambiguation("ghoul", "raise_dead", "DEATHKNIGHT", "blood");
        this.addDisambiguation("ghoul", "raise_dead", "DEATHKNIGHT", "frost");
        this.addDisambiguation(
            "dark_trasnformation",
            "dark_transformation",
            "DEATHKNIGHT"
        );
        this.addDisambiguation("frenzy", "frenzy_pet_buff", "HUNTER");

        this.addDisambiguation("blood_fury", "blood_fury_ap_int", "MONK");
        this.addDisambiguation("blood_fury", "blood_fury_ap_int", "PALADIN");
        this.addDisambiguation("blood_fury", "blood_fury_ap_int", "SHAMAN");
        this.addDisambiguation("blood_fury", "blood_fury_ap", "DEATHKNIGHT");
        this.addDisambiguation("blood_fury", "blood_fury_ap", "HUNTER");
        this.addDisambiguation("blood_fury", "blood_fury_ap", "ROGUE");
        this.addDisambiguation("blood_fury", "blood_fury_ap", "WARRIOR");
        this.addDisambiguation("blood_fury", "blood_fury_int", "MAGE");
        this.addDisambiguation("blood_fury", "blood_fury_int", "PRIEST");
        this.addDisambiguation("blood_fury", "blood_fury_int", "WARLOCK");
        this.addDisambiguation("blood_fury_buff", "blood_fury_ap_int", "MONK");
        this.addDisambiguation(
            "blood_fury_buff",
            "blood_fury_ap_int",
            "PALADIN"
        );
        this.addDisambiguation(
            "blood_fury_buff",
            "blood_fury_ap_int",
            "SHAMAN"
        );
        this.addDisambiguation(
            "blood_fury_buff",
            "blood_fury_ap",
            "DEATHKNIGHT"
        );
        this.addDisambiguation("blood_fury_buff", "blood_fury_ap", "HUNTER");
        this.addDisambiguation("blood_fury_buff", "blood_fury_ap", "ROGUE");
        this.addDisambiguation("blood_fury_buff", "blood_fury_ap", "WARRIOR");
        this.addDisambiguation("blood_fury_buff", "blood_fury_int", "MAGE");
        this.addDisambiguation("blood_fury_buff", "blood_fury_int", "PRIEST");
        this.addDisambiguation("blood_fury_buff", "blood_fury_int", "WARLOCK");
        this.addDisambiguation(
            "elemental_equilibrium_debuff",
            "elemental_equilibrium_buff",
            "SHAMAN",
            "elemental"
        );
        this.addDisambiguation("doom_winds_debuff", "doom_winds", "SHAMAN");
        this.addDisambiguation(
            "meat_cleaver",
            "whirlwind_buff",
            "WARRIOR",
            "fury"
        );
        this.addDisambiguation(
            "roaring_blaze",
            "conflagrate_debuff",
            "WARLOCK",
            "destruction"
        );
        this.addDisambiguation(
            "chaos_theory_buff",
            "chaos_blades",
            "DEMONHUNTER"
        );
        this.addDisambiguation(
            "phantom_fire_item",
            "potion_of_phantom_fire_item"
        );
        this.addDisambiguation("interrupt", "pet_interrupt", "WARLOCK");
        this.addDisambiguation("bonedust_brew_debuff", "bonedust_brew", "MONK");
    }

    /** Transform a ParseNode to an AstNode
     * @param parseNode The ParseNode to transform
     * @param nodeList The list of AstNode. Any created node will be added to this array.
     * @param action The current Simulationcraft action, or undefined if in a condition modifier
     */
    emit(
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action: string | undefined
    ) {
        // TODO
        const visitor = this.emitVisitors[
            parseNode.type
        ] as EmitVisitor<ParseNode>;
        if (!visitor) {
            this.tracer.error(
                "Unable to emit node of type '%s'.",
                parseNode.type
            );
        } else {
            return visitor(parseNode, nodeList, annotation, action);
        }
    }

    private addSymbol(annotation: Annotation, symbol: string) {
        const symbolTable = annotation.symbolTable || {};
        const symbolList = annotation.symbolList || {};
        if (!symbolTable[symbol] && !this.ovaleData.defaultSpellLists[symbol]) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        annotation.symbolTable = symbolTable;
        annotation.symbolList = symbolList;
    }

    private emitMiscOperand(
        operand: string,
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action: string | undefined
    ): AstNode | undefined {
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const miscOperand = tokenIterator();
        const info = miscOperands[miscOperand];
        if (info) {
            let modifier = tokenIterator();
            if (info.code) {
                if (info.symbolsInCode) {
                    for (const [_, symbol] of ipairs(info.symbolsInCode)) {
                        annotation.addSymbol(symbol);
                    }
                }
                const [result] = this.ovaleAst.parseCode(
                    "expression",
                    info.code,
                    nodeList,
                    annotation.astAnnotation
                );
                return result;
            }

            const result = this.ovaleAst.newNodeWithParameters(
                "function",
                annotation.astAnnotation
            );
            result.name = info.name || miscOperand;

            if (info.extraParameter) {
                if (isNumber(info.extraParameter)) {
                    insert(
                        result.rawPositionalParams,
                        this.ovaleAst.newValue(
                            annotation.astAnnotation,
                            info.extraParameter
                        )
                    );
                } else {
                    insert(
                        result.rawPositionalParams,
                        this.ovaleAst.newString(
                            annotation.astAnnotation,
                            info.extraParameter
                        )
                    );
                }
            }
            if (info.extraNamedParameter) {
                if (isNumber(info.extraNamedParameter.value)) {
                    result.rawNamedParams[info.extraNamedParameter.name] =
                        this.ovaleAst.newValue(
                            annotation.astAnnotation,
                            info.extraNamedParameter.value
                        );
                } else {
                    result.rawNamedParams[info.extraNamedParameter.name] =
                        this.ovaleAst.newString(
                            annotation.astAnnotation,
                            info.extraNamedParameter.value
                        );
                }
            }

            if (info.extraSymbol) {
                insert(
                    result.rawPositionalParams,
                    this.ovaleAst.newVariable(
                        annotation.astAnnotation,
                        info.extraSymbol
                    )
                );
                annotation.addSymbol(info.extraSymbol);
            }
            while (modifier) {
                if (!info.modifiers && info.symbol === undefined) {
                    this.tracer.warning(
                        `Use of ${modifier} for ${operand} but no modifier has been registered`
                    );
                    this.ovaleAst.release(result);
                    return undefined;
                }
                const modifierParameters =
                    info.modifiers && info.modifiers[modifier];
                if (modifierParameters) {
                    const modifierName = modifierParameters.name || modifier;
                    if (modifierParameters.code) {
                        if (modifierParameters.symbolsInCode) {
                            for (const [_, symbol] of ipairs(
                                modifierParameters.symbolsInCode
                            )) {
                                annotation.addSymbol(symbol);
                            }
                        }
                        this.ovaleAst.release(result);
                        const [newCode] = this.ovaleAst.parseCode(
                            "expression",
                            modifierParameters.code,
                            nodeList,
                            annotation.astAnnotation
                        );
                        if (newCode) return newCode;
                        return undefined;
                    } else if (
                        modifierParameters.type ===
                        MiscOperandModifierType.Prefix
                    ) {
                        result.name = modifierName + result.name;
                    } else if (
                        modifierParameters.type ===
                        MiscOperandModifierType.Suffix
                    ) {
                        result.name += modifierName;
                    } else if (
                        modifierParameters.type ===
                        MiscOperandModifierType.Parameter
                    ) {
                        insert(
                            result.rawPositionalParams,
                            this.ovaleAst.newString(
                                annotation.astAnnotation,
                                modifierName
                            )
                        );
                    } else if (
                        modifierParameters.type ===
                        MiscOperandModifierType.Symbol
                    ) {
                        insert(
                            result.rawPositionalParams,
                            this.ovaleAst.newVariable(
                                annotation.astAnnotation,
                                modifierName
                            )
                        );
                        annotation.addSymbol(modifierName);
                    } else if (
                        modifierParameters.type ===
                        MiscOperandModifierType.Replace
                    ) {
                        result.name = modifierName;
                    }
                    if (modifierParameters.createOptions) {
                        if (!annotation.options) annotation.options = {};
                        annotation.options[modifierName] = true;
                    }
                    if (modifierParameters.extraParameter) {
                        if (isNumber(modifierParameters.extraParameter)) {
                            insert(
                                result.rawPositionalParams,
                                this.ovaleAst.newValue(
                                    annotation.astAnnotation,
                                    modifierParameters.extraParameter
                                )
                            );
                        } else {
                            insert(
                                result.rawPositionalParams,
                                this.ovaleAst.newString(
                                    annotation.astAnnotation,
                                    modifierParameters.extraParameter
                                )
                            );
                        }
                    }
                    if (modifierParameters.extraSymbol) {
                        insert(
                            result.rawPositionalParams,
                            this.ovaleAst.newVariable(
                                annotation.astAnnotation,
                                modifierParameters.extraSymbol
                            )
                        );
                        annotation.addSymbol(modifierParameters.extraSymbol);
                    }
                } else if (info.symbol !== undefined) {
                    if (info.symbol !== "") {
                        modifier = `${modifier}_${info.symbol}`;
                    }
                    [modifier] = this.disambiguate(
                        annotation,
                        modifier,
                        annotation.classId,
                        annotation.specialization
                    );
                    this.addSymbol(annotation, modifier);
                    insert(
                        result.rawPositionalParams,
                        this.ovaleAst.newVariable(
                            annotation.astAnnotation,
                            modifier
                        )
                    );
                } else {
                    this.tracer.warning(
                        `Modifier parameters not found for ${modifier} in ${result.name}`
                    );
                    this.ovaleAst.release(result);
                    return undefined;
                }

                modifier = tokenIterator();
            }

            return result;
        }

        return undefined;
    }

    private emitModifier = (
        modifier: Modifier,
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action: string,
        modifiers: Modifiers
    ) => {
        let node: AstNode | undefined, code;
        const className = annotation.classId;
        const specialization = annotation.specialization;
        if (modifier == "if") {
            node = this.emit(parseNode, nodeList, annotation, action);
        } else if (modifier == "target_if") {
            if (parseNode.targetIf) {
                /* Skip "target_if" for "first:", "max:", and "min:" since
                 * they only apply for multi-target and are for choosing
                 * between the targets; in a single-target situation, this
                 * always evaluates to the current target.
                 */
            } else {
                node = this.emit(parseNode, nodeList, annotation, action);
            }
        } else if (modifier == "five_stacks" && action == "focus_fire") {
            const value = tonumber(this.unparser.unparse(parseNode));
            if (value == 1) {
                const buffName = "frenzy_pet_buff";
                this.addSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= 5", buffName);
            }
        } else if (modifier == "line_cd") {
            if (!specialActions[action]) {
                this.addSymbol(annotation, action);
                const node = this.emit(parseNode, nodeList, annotation, action);
                if (!node) return undefined;
                const expressionCode = this.ovaleAst.unparse(node);
                code = format(
                    "TimeSincePreviousSpell(%s) > %s",
                    action,
                    expressionCode
                );
            }
        } else if (modifier == "max_cycle_targets") {
            const [debuffName] = this.disambiguate(
                annotation,
                action,
                className,
                specialization,
                undefined,
                "debuff"
            );
            this.addSymbol(annotation, debuffName);
            const node = this.emit(parseNode, nodeList, annotation, action);
            if (!node) return undefined;
            const expressionCode = this.ovaleAst.unparse(node);
            code = format(
                "DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s",
                debuffName,
                debuffName,
                expressionCode
            );
        } else if (modifier == "max_energy") {
            const value = tonumber(this.unparser.unparse(parseNode));
            if (value == 1) {
                code = format("Energy() >= EnergyCost(%s max=1)", action);
            }
        } else if (modifier == "min_frenzy" && action == "focus_fire") {
            const value = tonumber(this.unparser.unparse(parseNode));
            if (value) {
                const buffName = "frenzy_pet_buff";
                this.addSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= %d", buffName, value);
            }
        } else if (modifier == "precast_etf_equip" && action == "trueshot") {
            const value = tonumber(this.unparser.unparse(parseNode));
            const symbol = "eagletalons_true_focus_runeforge";
            if (value > 0) {
                code = `equippedruneforge(${symbol})`;
            } else {
                code = `not equippedruneforge(${symbol})`;
            }
            this.addSymbol(annotation, symbol);
        } else if (modifier == "moving") {
            const value = tonumber(this.unparser.unparse(parseNode));
            if (value == 0) {
                code = "not Speed() > 0";
            } else {
                code = "Speed() > 0";
            }
        } else if (modifier == "precombat") {
            const value = tonumber(this.unparser.unparse(parseNode));
            if (value == 1) {
                code = "not InCombat()";
            } else {
                code = "InCombat()";
            }
        } else if (modifier == "sync") {
            let name = this.unparser.unparse(parseNode);
            if (!name) return undefined;
            if (name == "whirlwind_mh") {
                name = "whirlwind";
            }
            node =
                annotation.astAnnotation &&
                annotation.astAnnotation.sync &&
                annotation.astAnnotation.sync[name];
            if (!node) {
                const syncParseNode = annotation.sync && annotation.sync[name];
                if (syncParseNode) {
                    const syncActionNode = this.emitAction(
                        syncParseNode,
                        nodeList,
                        annotation,
                        action
                    );
                    if (syncActionNode) {
                        if (syncActionNode.type == "action") {
                            node = syncActionNode;
                        } else if (syncActionNode.type == "custom_function") {
                            node = syncActionNode;
                        } else if (
                            syncActionNode.type == "if" ||
                            syncActionNode.type == "unless"
                        ) {
                            let lhsNode = syncActionNode.child[1];
                            if (syncActionNode.type == "unless") {
                                const notNode =
                                    this.ovaleAst.newNodeWithChildren(
                                        "logical",
                                        annotation.astAnnotation
                                    );
                                notNode.expressionType = "unary";
                                notNode.operator = "not";
                                notNode.child[1] = lhsNode;
                                lhsNode = notNode;
                            }
                            const rhsNode = syncActionNode.child[2];
                            const andNode = this.ovaleAst.newNodeWithChildren(
                                "logical",
                                annotation.astAnnotation
                            );
                            andNode.expressionType = "binary";
                            andNode.operator = "and";
                            andNode.child[1] = lhsNode;
                            andNode.child[2] = rhsNode;
                            node = andNode;
                        } else {
                            this.tracer.print(
                                "Warning: Unable to emit action for 'sync=%s'.",
                                name
                            );
                            [name] = this.disambiguate(
                                annotation,
                                name,
                                className,
                                specialization
                            );
                            this.addSymbol(annotation, name);
                            code = format("Spell(%s)", name);
                        }
                    }
                }
            }
            if (node) {
                annotation.astAnnotation.sync =
                    annotation.astAnnotation.sync || {};
                annotation.astAnnotation.sync[name] = node;
            }
        }
        if (!node && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };

    private emitConditionNode = (
        nodeList: LuaArray<AstNode>,
        bodyNode: AstNode,
        extraConditionNode: AstNode | undefined,
        parseNode: ActionParseNode,
        annotation: Annotation,
        action: string,
        modifiers: Modifiers
    ) => {
        let conditionNode = undefined;
        for (const [modifier, expressionNode] of kpairs(modifiers)) {
            const rhsNode = this.emitModifier(
                modifier,
                expressionNode,
                nodeList,
                annotation,
                action,
                modifiers
            );
            if (rhsNode) {
                if (!conditionNode) {
                    conditionNode = rhsNode;
                } else {
                    const lhsNode = conditionNode;
                    conditionNode = this.ovaleAst.newNodeWithChildren(
                        "logical",
                        annotation.astAnnotation
                    );
                    conditionNode.expressionType = "binary";
                    conditionNode.operator = "and";
                    conditionNode.child[1] = lhsNode;
                    conditionNode.child[2] = rhsNode;
                }
            }
        }
        if (extraConditionNode) {
            if (conditionNode) {
                const lhsNode = conditionNode;
                const rhsNode = extraConditionNode;
                conditionNode = this.ovaleAst.newNodeWithChildren(
                    "logical",
                    annotation.astAnnotation
                );
                conditionNode.expressionType = "binary";
                conditionNode.operator = "and";
                conditionNode.child[1] = lhsNode;
                conditionNode.child[2] = rhsNode;
            } else {
                conditionNode = extraConditionNode;
            }
        }
        if (conditionNode) {
            const node = this.ovaleAst.newNodeWithChildren(
                "if",
                annotation.astAnnotation
            );
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
    };

    private emitNamedVariable = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifiers: Modifiers,
        parseNode: ActionParseNode,
        action: string,
        conditionNode?: AstNode
    ) => {
        let node = annotation.variable[name];
        let group;
        if (!node) {
            group = this.ovaleAst.newNodeWithChildren(
                "group",
                annotation.astAnnotation
            );
            node = this.ovaleAst.newNodeWithBodyAndParameters(
                "add_function",
                annotation.astAnnotation,
                group
            );
            annotation.variable[name] = node;
            node.name = name;
        } else {
            group = node.body;
        }
        annotation.currentVariable = node;
        const value =
            modifiers.value &&
            this.emit(modifiers.value, nodeList, annotation, action);
        const newNode = this.emitConditionNode(
            nodeList,
            value || this.ovaleAst.newValue(annotation.astAnnotation, 0),
            conditionNode,
            parseNode,
            annotation,
            action,
            modifiers
        );
        if (newNode.type == "if") {
            insert(group.child, 1, newNode);
        } else {
            insert(group.child, newNode);
        }
        annotation.currentVariable = undefined;
    };

    private emitVariableMin = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        this.emitNamedVariable(
            `${name}_min`,
            nodeList,
            annotation,
            modifier,
            parseNode,
            action
        );
        const valueNode = annotation.variable[name];
        valueNode.name = `${name}_value`;
        annotation.variable[valueNode.name] = valueNode;
        const bodyCode = format(
            "AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }",
            name,
            name,
            name,
            name,
            name
        );
        const [node] = this.ovaleAst.parseCode(
            "add_function",
            bodyCode,
            nodeList,
            annotation.astAnnotation
        );
        if (node) {
            annotation.variable[name] = node as AstAddFunctionNode;
        }
    };

    private emitVariableMax = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        this.emitNamedVariable(
            `${name}_max`,
            nodeList,
            annotation,
            modifier,
            parseNode,
            action
        );
        const valueNode = annotation.variable[name];
        valueNode.name = `${name}_value`;
        annotation.variable[valueNode.name] = valueNode;
        const bodyCode = format(
            "AddFunction %s { if %s_value() < %s_max() %s_value() %s_max() }",
            name,
            name,
            name,
            name,
            name
        );
        const [node] = this.ovaleAst.parseCode(
            "add_function",
            bodyCode,
            nodeList,
            annotation.astAnnotation
        );
        if (node) {
            annotation.variable[name] = node as AstAddFunctionNode;
        }
    };

    private emitVariableAdd = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifiers: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        // TODO
        const valueNode = annotation.variable[name];
        if (valueNode) return;
        this.emitNamedVariable(
            name,
            nodeList,
            annotation,
            modifiers,
            parseNode,
            action
        );
    };

    private emitVariableSub = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifiers: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        // TODO
        const valueNode = annotation.variable[name];
        if (valueNode) return;
        this.emitNamedVariable(
            name,
            nodeList,
            annotation,
            modifiers,
            parseNode,
            action
        );
    };

    private emitVariableIf = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifiers: Modifiers,
        parseNode: ParseNode,
        action: string
    ) => {
        let node = annotation.variable[name];
        let group: AstGroupNode;
        if (!node) {
            group = this.ovaleAst.newNodeWithChildren(
                "group",
                annotation.astAnnotation
            );
            node = this.ovaleAst.newNodeWithBodyAndParameters(
                "add_function",
                annotation.astAnnotation,
                group
            );
            annotation.variable[name] = node;
            node.name = name;
        } else {
            group = node.body;
        }

        annotation.currentVariable = node;

        if (!modifiers.condition || !modifiers.value || !modifiers.value_else) {
            this.tracer.error("Modifier missing in if");
            return;
        }

        const ifNode = this.ovaleAst.newNodeWithChildren(
            "if",
            annotation.astAnnotation
        );
        const condition = this.emit(
            modifiers.condition,
            nodeList,
            annotation,
            undefined
        );
        const value = this.emit(
            modifiers.value,
            nodeList,
            annotation,
            undefined
        );
        if (!condition || !value) return;
        ifNode.child[1] = condition;
        ifNode.child[2] = value;
        insert(group.child, ifNode);
        const elseNode = this.ovaleAst.newNodeWithChildren(
            "unless",
            annotation.astAnnotation
        );
        elseNode.child[1] = ifNode.child[1];
        const valueElse = this.emit(
            modifiers.value_else,
            nodeList,
            annotation,
            undefined
        );
        if (!valueElse) return;
        elseNode.child[2] = valueElse;
        insert(group.child, elseNode);

        annotation.currentVariable = undefined;
    };

    private emitCyclingVariable(
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifiers: Modifiers,
        parseNode: ActionParseNode,
        action: string,
        conditionNode?: AstNode
    ) {
        const op =
            (modifiers.op && this.unparser.unparse(modifiers.op)) || "min";
        if (!modifiers.name) {
            this.tracer.error("Modifier name is missing in %s", action);
            return;
        }
        const name = this.unparser.unparse(modifiers.name);
        if (!name) {
            this.tracer.error(
                "Unable to parse name of variable in %s",
                modifiers.name
            );
            return;
        }
        if (op === "min" || op === "max") {
            // TODO
            this.emitVariableAdd(
                name,
                nodeList,
                annotation,
                modifiers,
                parseNode,
                action
            );
        } else {
            this.tracer.error(`Unknown cycling_variable operator ${op}`);
        }
    }

    private emitVariable = (
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string,
        conditionNode?: AstNode
    ) => {
        const op = (modifier.op && this.unparser.unparse(modifier.op)) || "set";
        if (!modifier.name) {
            this.tracer.error("Modifier name is missing in %s", action);
            return;
        }
        let name = this.unparser.unparse(modifier.name);
        if (!name) {
            this.tracer.error(
                "Unable to parse name of variable in %s",
                modifier.name
            );
            return;
        }
        if (truthy(match(name, "^%d"))) {
            name = "_" + name;
        }
        if (op == "min") {
            this.emitVariableMin(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "max") {
            this.emitVariableMax(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "add") {
            this.emitVariableAdd(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "set" || op === "reset") {
            this.emitNamedVariable(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action,
                conditionNode
            );
        } else if (op === "setif") {
            this.emitVariableIf(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op === "sub") {
            this.emitVariableSub(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else {
            this.tracer.error("Unknown variable operator '%s'.", op);
        }
    };

    /** Takes a ParseNode of type "action" and transforms it to an AstNode. */
    private emitAction: EmitVisitor<ActionParseNode> = (
        parseNode,
        nodeList,
        annotation
    ) => {
        let node: AstNode | undefined;
        const canonicalizedName = lower(gsub(parseNode.name, ":", "_"));
        const className = annotation.classId;
        const specialization = annotation.specialization;
        const camelSpecialization = toLowerSpecialization(annotation);
        let [action, type] = this.disambiguate(
            annotation,
            canonicalizedName,
            className,
            specialization,
            "spell"
        );
        let bodyNode: AstNode | undefined;
        let conditionNode: AstNode | undefined;
        if (
            !(
                (action == "auto_attack" && !annotation.melee) ||
                action == "auto_shot" ||
                action == "choose_target" ||
                action == "augmentation" ||
                action == "flask" ||
                action == "food" ||
                action == "retarget_auto_attack" ||
                action == "snapshot_stats"
            )
        ) {
            // Most of this code is obsolete and should be cleaned or dispatched in the correct function
            let bodyCode, conditionCode;
            const expressionType = "expression";
            let modifiers = parseNode.modifiers;
            let isSpellAction = true;
            if (
                interruptsClasses[action as keyof typeof interruptsClasses] ===
                className
            ) {
                bodyCode = `${camelSpecialization}InterruptActions()`;
                annotation[action as keyof typeof interruptsClasses] =
                    className;
                annotation.interrupt = className;
                isSpellAction = false;
            } else if (
                className === "DEMONHUNTER" &&
                action === "pick_up_fragment"
            ) {
                bodyCode = "Texture(spell_shadow_soulgem text=pickup)";
                conditionCode =
                    "CheckBoxOn(opt_pick_up_soul_fragments) and SoulFragments() > 0";
                if (!annotation.options) annotation.options = {};
                annotation.options["opt_pick_up_soul_fragments"] = true;
                isSpellAction = false;
            } else if (className == "DRUID" && action == "primal_wrath") {
                conditionCode = "Enemies(tagged=1) > 1";
            } else if (className == "DRUID" && action == "wild_charge") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (className == "DRUID" && action == "new_moon") {
                conditionCode =
                    "not SpellKnown(half_moon) and not SpellKnown(full_moon)";
                this.addSymbol(annotation, "half_moon");
                this.addSymbol(annotation, "full_moon");
            } else if (className == "DRUID" && action == "half_moon") {
                conditionCode = "SpellKnown(half_moon)";
            } else if (className == "DRUID" && action == "full_moon") {
                conditionCode = "SpellKnown(full_moon)";
            } else if (className == "MAGE" && truthy(find(action, "pet_"))) {
                conditionCode = "pet.Present()";
            } else if (className == "MAGE" && action == "time_warp") {
                conditionCode =
                    "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)";
                annotation[action] = className;
            } else if (className == "MAGE" && action == "ice_floes") {
                conditionCode = "Speed() > 0";
            } else if (className == "MAGE" && action == "blast_wave") {
                conditionCode = "target.Distance() < 8";
            } else if (className == "MAGE" && action == "dragons_breath") {
                conditionCode = "target.Distance() < 12";
            } else if (className == "MAGE" && action == "arcane_blast") {
                conditionCode = "Mana() > ManaCost(arcane_blast)";
            } else if (className == "MAGE" && action == "cone_of_cold") {
                conditionCode = "target.Distance() < 12";
            } else if (className == "MONK" && action == "chi_sphere") {
                isSpellAction = false;
            } else if (className == "MONK" && action == "gift_of_the_ox") {
                isSpellAction = false;
            } else if (
                className == "MONK" &&
                action == "storm_earth_and_fire"
            ) {
                conditionCode =
                    "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire)";
                annotation[action] = className;
            } else if (
                className == "MONK" &&
                action == "storm_earth_and_fire_fixate"
            ) {
                /**
                 * There's no way to tell if the SEF copies are fixated. Just
                 * ignore the spell action for now and assume the player is
                 * smart enough to fixate the copies on their own.
                 */
                isSpellAction = false;
            } else if (className == "MONK" && action == "touch_of_death") {
                // conditionCode =
                //     "(not CheckBoxOn(opt_touch_of_death_on_elite_only) or (not UnitInRaid() and target.Classification(elite)) or target.Classification(worldboss)) or not BuffExpires(hidden_masters_forbidden_touch_buff)";
                // annotation[action] = className;
                // if (!annotation.options) annotation.options = {};
                // annotation.options["opt_touch_of_death_on_elite_only"] = true;
                // this.AddSymbol(
                //     annotation,
                //     "hidden_masters_forbidden_touch_buff"
                // );
            } else if (
                className == "PALADIN" &&
                action == "blessing_of_kings"
            ) {
                conditionCode = "BuffExpires(mastery_buff)";
            } else if (className == "PALADIN" && action == "judgment") {
                if (modifiers.cycle_targets) {
                    this.addSymbol(annotation, action);
                    bodyCode = `Spell(${action} text=double)`;
                    isSpellAction = false;
                }
            } else if (
                className == "PALADIN" &&
                specialization == "protection" &&
                action == "arcane_torrent_holy"
            ) {
                isSpellAction = false;
            } else if (className == "ROGUE" && action == "adrenaline_rush") {
                conditionCode = "EnergyDeficit() > 1";
            } else if (className == "ROGUE" && action == "apply_poison") {
                let lethal: string | undefined = undefined;
                if (modifiers.lethal) {
                    lethal = this.unparser.unparse(modifiers.lethal);
                } else if (specialization == "assassination") {
                    lethal = "deadly";
                } else {
                    lethal = "instant";
                }
                action = `${lethal}_poison`;
                const buffName = "lethal_poison_buff";
                this.addSymbol(annotation, buffName);
                conditionCode = format("BuffRemaining(%s) < 1200", buffName);
            } else if (className == "ROGUE" && action == "cancel_autoattack") {
                isSpellAction = false;
            } else if (
                className == "ROGUE" &&
                specialization == "assassination" &&
                action == "vanish"
            ) {
                annotation.vanish = className;
                conditionCode = format("CheckBoxOn(opt_vanish)", action);
            } else if (
                className == "SHAMAN" &&
                sub(action, 1, 11) == "ascendance_"
            ) {
                const [buffName] = this.disambiguate(
                    annotation,
                    action,
                    className,
                    specialization,
                    undefined,
                    "buff"
                );
                this.addSymbol(annotation, buffName);
                conditionCode = format("BuffExpires(%s)", buffName);
            } else if (className == "SHAMAN" && action == "bloodlust") {
                bodyCode = `${camelSpecialization}Bloodlust()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (
                className == "WARLOCK" &&
                action == "felguard_felstorm"
            ) {
                conditionCode =
                    "pet.Present() and pet.CreatureFamily(Felguard)";
            } else if (
                className == "WARLOCK" &&
                action == "grimoire_of_sacrifice"
            ) {
                conditionCode = "pet.Present()";
            } else if (className == "WARLOCK" && action == "havoc") {
                conditionCode = "Enemies() > 1";
            } else if (className == "WARLOCK" && action == "service_pet") {
                if (annotation.pet) {
                    const spellName = `service_${annotation.pet}`;
                    this.addSymbol(annotation, spellName);
                    bodyCode = format("Spell(%s)", spellName);
                } else {
                    bodyCode =
                        "Texture(spell_nature_removecurse help=ServicePet)";
                }
                isSpellAction = false;
            } else if (className == "WARLOCK" && action == "summon_pet") {
                if (annotation.pet) {
                    const spellName = `summon_${annotation.pet}`;
                    this.addSymbol(annotation, spellName);
                    bodyCode = format("Spell(%s)", spellName);
                } else {
                    bodyCode =
                        "Texture(spell_nature_removecurse help=L(summon_pet))";
                }
                conditionCode = "not pet.Present()";
                isSpellAction = false;
            } else if (
                className == "WARLOCK" &&
                action == "wrathguard_wrathstorm"
            ) {
                conditionCode =
                    "pet.Present() and pet.CreatureFamily(Wrathguard)";
            } else if (className == "WARRIOR" && action == "charge") {
                conditionCode =
                    "CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel)";
                this.addSymbol(annotation, "pummel");
            } else if (
                className == "WARRIOR" &&
                sub(action, 1, 7) == "execute"
            ) {
                if (modifiers.target) {
                    const target = tonumber(
                        this.unparser.unparse(modifiers.target)
                    );
                    if (target) {
                        isSpellAction = false;
                    }
                }
            } else if (className == "WARRIOR" && action == "heroic_charge") {
                bodyCode = "Spell(heroic_leap text=charge)";
                this.addSymbol(annotation, "heroic_leap");
                isSpellAction = false;
            } else if (className == "WARRIOR" && action == "heroic_leap") {
                conditionCode =
                    "CheckBoxOn(opt_melee_range) and target.Distance() >= 8 and target.Distance() <= 40";
            } else if (action == "auto_attack") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                isSpellAction = false;
            } else if (
                className == "DEMONHUNTER" &&
                action == "metamorphosis"
            ) {
                conditionCode =
                    "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()";
                if (!annotation.options) annotation.options = {};
                annotation.options["opt_meta_only_during_boss"] = true;
            } else if (
                className == "DEMONHUNTER" &&
                action == "consume_magic"
            ) {
                conditionCode = "target.HasDebuffType(magic)";
            } else if (checkOptionalSkill(action, className, specialization)) {
                annotation[action] = className;
                conditionCode = `CheckBoxOn(opt_${action})`;
            } else if (action === "cycling_variable") {
                this.emitCyclingVariable(
                    nodeList,
                    annotation,
                    modifiers,
                    parseNode,
                    action
                );
                isSpellAction = false;
            } else if (action == "variable") {
                this.emitVariable(
                    nodeList,
                    annotation,
                    modifiers,
                    parseNode,
                    action
                );
                isSpellAction = false;
            } else if (
                action == "call_action_list" ||
                action == "run_action_list" ||
                action == "swap_action_list"
            ) {
                if (modifiers.name) {
                    const name = this.unparser.unparse(modifiers.name);
                    if (name) {
                        const functionName = toOvaleFunctionName(
                            name,
                            annotation
                        );
                        bodyCode = `${functionName}()`;
                    }
                    isSpellAction = false;
                }
            } else if (action == "cancel_buff") {
                if (modifiers.name) {
                    const spellName = this.unparser.unparse(modifiers.name);
                    if (spellName) {
                        const [buffName] = this.disambiguate(
                            annotation,
                            spellName,
                            className,
                            specialization,
                            "spell",
                            "buff"
                        );
                        this.addSymbol(annotation, buffName);
                        bodyCode = format("Texture(%s text=cancel)", buffName);
                        conditionCode = format("BuffPresent(%s)", buffName);
                        isSpellAction = false;
                    }
                }
            } else if (action === "cancel_action") {
                bodyCode = "texture(INV_Pet_ExitBattle text=cancel)";
                isSpellAction = false;
            } else if (action == "pool_resource") {
                bodyNode = this.ovaleAst.newNode(
                    "simc_pool_resource",
                    annotation.astAnnotation
                );
                bodyNode.for_next = modifiers.for_next != undefined;
                if (modifiers.extra_amount) {
                    bodyNode.extra_amount = tonumber(
                        this.unparser.unparse(modifiers.extra_amount)
                    );
                }
                isSpellAction = false;
            } else if (action == "newfound_resolve") {
                const buffName = "newfound_resolve_buff";
                const debuffName = "trial_of_doubt_debuff";
                bodyCode = "Texture(inv_enchant_essencemagiclarge text=face)";
                // Newfound Resolve does not stack
                conditionCode = `not BuffPresent(${buffName}) and DebuffPresent(${debuffName}) and DebuffRemains(${debuffName}) < 10`;
                this.addSymbol(annotation, buffName);
                this.addSymbol(annotation, debuffName);
                // Ignore any modifiers for the "newfound_resolve" action.
                modifiers = {};
                isSpellAction = false;
            } else if (action == "potion") {
                let name =
                    (modifiers.name && this.unparser.unparse(modifiers.name)) ||
                    annotation.consumables["potion"];
                if (name) {
                    if (name === "disabled") {
                        return undefined;
                    }
                    [name] = this.disambiguate(
                        annotation,
                        name,
                        className,
                        specialization,
                        "item",
                        "item"
                    );
                    bodyCode = format("Item(%s usable=1)", name);
                    conditionCode =
                        "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)";
                    annotation.opt_use_consumables = className;
                    this.addSymbol(annotation, name);
                    isSpellAction = false;
                }
            } else if (action === "sequence" || action == "strict_sequence") {
                // TODO doesn't seem to be supported
                isSpellAction = false;
            } else if (action == "summon_pet") {
                bodyCode = `${camelSpecialization}SummonPet()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (action == "use_items") {
                bodyCode = `${camelSpecialization}UseItemActions()`;
                annotation["use_item"] = true;
                isSpellAction = false;
            } else if (action == "use_item") {
                let legendaryRing: string | undefined = undefined;
                // TODO use modifiers.slots
                if (modifiers.slot) {
                    // use this slot only?
                    const slot = this.unparser.unparse(modifiers.slot);
                    if (slot) {
                        if (truthy(match(slot, "^finger"))) {
                            [legendaryRing] = this.disambiguate(
                                annotation,
                                "legendary_ring",
                                className,
                                specialization
                            );
                        } else if (slot == "trinket1") {
                            bodyCode = `Item("trinket0slot" text=13 usable=1)`;
                            annotation[action] = true;
                        } else if (slot == "trinket2") {
                            bodyCode = `Item("trinket1slot" text=14 usable=1)`;
                            annotation[action] = true;
                        }
                    }
                } else if (modifiers.name) {
                    let name = this.unparser.unparse(modifiers.name);
                    if (name) {
                        [name] = this.disambiguate(
                            annotation,
                            name,
                            className,
                            specialization
                        );
                        if (truthy(match(name, "legendary_ring"))) {
                            legendaryRing = name;
                        } else {
                            [name] = this.disambiguate(
                                annotation,
                                name,
                                className,
                                specialization,
                                "item",
                                "item"
                            );
                            if (name) {
                                conditionCode = `HasTrinket(${name})`;
                                bodyCode = `Item(${name} usable=1)`;
                                this.addSymbol(annotation, name);
                            }
                        }
                    }
                } else if (modifiers.effect_name) {
                    // TODO use any item that has this effect
                }
                if (legendaryRing) {
                    conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing);
                    bodyCode = format("Item(%s usable=1)", legendaryRing);
                    this.addSymbol(annotation, legendaryRing);
                    annotation.use_legendary_ring = legendaryRing;
                } else if (!bodyCode) {
                    bodyCode = `${camelSpecialization}UseItemActions()`;
                    annotation[action] = true;
                }
                isSpellAction = false;
            } else if (action == "wait") {
                if (modifiers.sec) {
                    const seconds = tonumber(
                        this.unparser.unparse(modifiers.sec)
                    );
                    if (!seconds) {
                        bodyNode = this.ovaleAst.newNodeWithChildren(
                            "simc_wait",
                            annotation.astAnnotation
                        );
                        const expressionNode = this.emit(
                            modifiers.sec,
                            nodeList,
                            annotation,
                            action
                        );
                        if (expressionNode) {
                            const code = this.ovaleAst.unparse(expressionNode);
                            conditionCode = code + " > 0";
                        }
                    }
                }
                isSpellAction = false;
            } else if (action === "wait_for_cooldown") {
                if (modifiers.name) {
                    const spellName = this.unparser.unparse(modifiers.name);
                    if (spellName) {
                        // TODO wait
                        isSpellAction = true;
                        action = spellName;
                    }
                }
            } else if (action == "heart_essence") {
                bodyCode = `Spell(296208)`;
                conditionCode = `hasequippeditem(158075) and level() < 50`;
                isSpellAction = false;
            } else if (parseNode.actionListName === "precombat") {
                const definition = annotation.dictionary[action];
                if (isNumber(definition)) {
                    const spellInfo =
                        this.ovaleData.getSpellOrListInfo(definition);
                    if (spellInfo && spellInfo.aura) {
                        for (const [, info] of kpairs(
                            spellInfo.aura.player.HELPFUL
                        )) {
                            if (info.buffSpellId) {
                                const buffSpellInfo =
                                    this.ovaleData.getSpellOrListInfo(
                                        info.buffSpellId
                                    );
                                if (
                                    buffSpellInfo &&
                                    (!buffSpellInfo.duration ||
                                        buffSpellInfo.duration > 59)
                                ) {
                                    conditionCode = `buffexpires(${
                                        info.buffName || info.buffSpellId
                                    })`;
                                }
                            }
                        }
                    }
                }
            }
            if (isSpellAction) {
                this.addSymbol(annotation, action);
                if (modifiers.target) {
                    let actionTarget = this.unparser.unparse(modifiers.target);
                    if (actionTarget == "2") {
                        actionTarget = "other";
                    }
                    if (actionTarget != "1") {
                        bodyCode = `${type}(${action} text=${actionTarget})`;
                    }
                } else if (modifiers.cycle_targets) {
                    bodyCode = `${type}(${action} text=cycle)`;
                } else {
                    bodyCode = `${type}(${action})`;
                }
            }
            if (!bodyNode && bodyCode) {
                [bodyNode] = this.ovaleAst.parseCode(
                    expressionType,
                    bodyCode,
                    nodeList,
                    annotation.astAnnotation
                );
            }
            if (!conditionNode && conditionCode) {
                [conditionNode] = this.ovaleAst.parseCode(
                    expressionType,
                    conditionCode,
                    nodeList,
                    annotation.astAnnotation
                );
            }
            if (bodyNode) {
                node = this.emitConditionNode(
                    nodeList,
                    bodyNode,
                    conditionNode,
                    parseNode,
                    annotation,
                    action,
                    modifiers
                );
            }
        }
        return node;
    };

    public emitActionList: EmitVisitor<ActionListParseNode> = (
        parseNode,
        nodeList,
        annotation
    ) => {
        const groupNode = this.ovaleAst.newNodeWithChildren(
            "group",
            annotation.astAnnotation
        );
        let child = groupNode.child;
        let poolResourceNode;
        let emit = true;
        for (const [, actionNode] of ipairs(parseNode.child)) {
            const commentNode = this.ovaleAst.newNode(
                "comment",
                annotation.astAnnotation
            );
            commentNode.comment = actionNode.action;
            child[lualength(child) + 1] = commentNode;
            if (emit) {
                const statementNode = this.emitAction(
                    actionNode,
                    nodeList,
                    annotation,
                    actionNode.name
                );
                if (statementNode) {
                    if (statementNode.type == "simc_pool_resource") {
                        const powerType = pooledResources[annotation.classId];
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
                        let poolingConditionNode: AstNode | undefined;
                        if (isAstNodeWithChildren(statementNode)) {
                            poolingConditionNode = statementNode.child[1];
                            bodyNode = statementNode.child[2];
                        } else {
                            bodyNode = statementNode;
                        }
                        const powerType = toCamelCase(
                            poolResourceNode.powerType
                        );
                        const extraAmount = poolResourceNode.extra_amount;
                        if (extraAmount && poolingConditionNode) {
                            let code =
                                this.ovaleAst.unparse(poolingConditionNode);
                            const extraAmountPattern =
                                powerType + "%(%) >= [%d.]+";
                            const replaceString = format(
                                "always(pool_%s %d)",
                                poolResourceNode.powerType,
                                extraAmount
                            );
                            code = gsub(
                                code,
                                extraAmountPattern,
                                replaceString
                            );
                            [poolingConditionNode] = this.ovaleAst.parseCode(
                                "expression",
                                code,
                                nodeList,
                                annotation.astAnnotation
                            );
                        }
                        if (
                            bodyNode.type == "action" &&
                            bodyNode.rawPositionalParams &&
                            bodyNode.rawPositionalParams[1]
                        ) {
                            const name = this.ovaleAst.unparse(
                                bodyNode.rawPositionalParams[1]
                            );
                            let powerCondition;
                            if (extraAmount) {
                                powerCondition = format(
                                    "TimeTo%s(%d)",
                                    powerType,
                                    extraAmount
                                );
                            } else {
                                powerCondition = format(
                                    "TimeTo%sFor(%s)",
                                    powerType,
                                    name
                                );
                            }
                            const code = format(
                                "SpellUsable(%s) and SpellCooldown(%s) < %s",
                                name,
                                name,
                                powerCondition
                            );
                            let [conditionNode] = this.ovaleAst.parseCode(
                                "expression",
                                code,
                                nodeList,
                                annotation.astAnnotation
                            );
                            if (conditionNode) {
                                if (
                                    isAstNodeWithChildren(statementNode) &&
                                    poolingConditionNode
                                ) {
                                    const rhsNode = conditionNode;
                                    conditionNode =
                                        this.ovaleAst.newNodeWithChildren(
                                            "logical",
                                            annotation.astAnnotation
                                        );
                                    conditionNode.expressionType = "binary";
                                    conditionNode.operator = "and";
                                    conditionNode.child[1] =
                                        poolingConditionNode;
                                    conditionNode.child[2] = rhsNode;
                                }
                                let restNodeType: "if" | "unless";
                                if (statementNode.type == "unless") {
                                    restNodeType = "if";
                                } else {
                                    restNodeType = "unless";
                                }

                                const restNode =
                                    this.ovaleAst.newNodeWithChildren(
                                        restNodeType,
                                        annotation.astAnnotation
                                    );
                                child[lualength(child) + 1] = restNode;
                                restNode.child[1] = conditionNode;
                                restNode.child[2] =
                                    this.ovaleAst.newNodeWithChildren(
                                        "group",
                                        annotation.astAnnotation
                                    );
                                child = restNode.child[2].child;
                            }
                        }
                        poolResourceNode = undefined;
                    } else if (
                        (statementNode.type === "if" ||
                            statementNode.type == "unless") &&
                        statementNode.simc_wait
                    ) {
                        const restNode = this.ovaleAst.newNodeWithChildren(
                            "unless",
                            annotation.astAnnotation
                        );
                        child[lualength(child) + 1] = restNode;
                        restNode.type = "unless";
                        restNode.child[1] = statementNode.child[1];
                        restNode.child[2] = this.ovaleAst.newNodeWithChildren(
                            "group",
                            annotation.astAnnotation
                        );
                        child = restNode.child[2].child;
                    } else if (statementNode.type !== "simc_wait") {
                        child[lualength(child) + 1] = statementNode;
                        if (
                            (statementNode.type === "if" ||
                                statementNode.type == "unless") &&
                            statementNode.simc_pool_resource
                        ) {
                            if (statementNode.type == "if") {
                                statementNode.type = "unless" as "if";
                            } else if (statementNode.type == "unless") {
                                statementNode.type = "if" as "unless";
                            }
                            statementNode.child[2] =
                                this.ovaleAst.newNodeWithChildren(
                                    "group",
                                    annotation.astAnnotation
                                );
                            child = statementNode.child[2].child;
                        }
                    }
                }
            }
        }

        const node = this.ovaleAst.newNodeWithBodyAndParameters(
            "add_function",
            annotation.astAnnotation,
            groupNode
        );
        node.name = toOvaleFunctionName(parseNode.name, annotation);
        return node;
    };

    private emitExpression: EmitVisitor<OperatorParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let msg;
        if (parseNode.expressionType == "unary") {
            const opInfo =
                unaryOperators[parseNode.operator as SimcUnaryOperatorType];
            if (opInfo) {
                let operator: OperatorType | undefined;
                if (parseNode.operator == "!") {
                    operator = "not";
                } else if (parseNode.operator == "-") {
                    operator = parseNode.operator;
                }
                if (operator) {
                    const rhsNode = this.emit(
                        parseNode.child[1],
                        nodeList,
                        annotation,
                        action
                    );
                    if (rhsNode) {
                        if (operator == "-" && rhsNode.type === "value") {
                            rhsNode.value = -1 * rhsNode.value;
                        } else {
                            node = this.ovaleAst.newNodeWithChildren(
                                opInfo[1],
                                annotation.astAnnotation
                            );
                            node.expressionType = "unary";
                            node.operator = operator;
                            node.precedence = opInfo[2];
                            node.child[1] = rhsNode;
                        }
                    }
                }
            }
        } else if (parseNode.expressionType == "binary") {
            const opInfo =
                binaryOperators[parseNode.operator as SimcBinaryOperatorType];
            if (opInfo) {
                const parseNodeOperator =
                    parseNode.operator as SimcBinaryOperatorType;
                let operator: OperatorType | undefined;
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
                } else if (parseNodeOperator === "%%") {
                    operator = "%";
                } else if (
                    parseNode.operatorType == "compare" ||
                    parseNode.operatorType == "arithmetic"
                ) {
                    if (
                        parseNodeOperator !== "~" &&
                        parseNodeOperator !== "!~"
                    ) {
                        operator = parseNodeOperator;
                    }
                }
                if (
                    (parseNode.operator == "=" || parseNode.operator == "!=") &&
                    (parseNode.child[1].name == "target" ||
                        parseNode.child[1].name == "current_target") &&
                    parseNode.child[2].name
                ) {
                    let name = parseNode.child[2].name;
                    if (truthy(find(name, "^[%a_]+%."))) {
                        [name] = match(name, "^[%a_]+%.([%a_]+)");
                    }
                    let code;
                    if (name == "sim_target") {
                        code = "always(target_is_sim_target)";
                    } else if (name == "target") {
                        code = "never(target_is_target)";
                    } else {
                        code = format("target.Name(%s)", name);
                        this.addSymbol(annotation, name);
                    }

                    if (parseNode.operator == "!=") {
                        code = "not " + code;
                    }
                    annotation.astAnnotation = annotation.astAnnotation || {};
                    [node] = this.ovaleAst.parseCode(
                        "expression",
                        code,
                        nodeList,
                        annotation.astAnnotation
                    );
                } else if (
                    (parseNode.operator == "=" || parseNode.operator == "!=") &&
                    parseNode.child[1].name == "sim_target"
                ) {
                    let code;
                    if (parseNode.operator == "=") {
                        code = "always(target_is_sim_target)";
                    } else {
                        code = "never(target_is_sim_target)";
                    }
                    annotation.astAnnotation = annotation.astAnnotation || {};
                    [node] = this.ovaleAst.parseCode(
                        "expression",
                        code,
                        nodeList,
                        annotation.astAnnotation
                    );
                } else if (operator) {
                    const lhsNode = this.emit(
                        parseNode.child[1],
                        nodeList,
                        annotation,
                        action
                    );
                    const rhsNode = this.emit(
                        parseNode.child[2],
                        nodeList,
                        annotation,
                        action
                    );
                    if (lhsNode && rhsNode) {
                        node = this.ovaleAst.newNodeWithChildren(
                            opInfo[1],
                            annotation.astAnnotation
                        );
                        node.expressionType = "binary";
                        node.operator = operator;
                        node.child[1] = lhsNode;
                        node.child[2] = rhsNode;
                    } else if (lhsNode) {
                        msg = makeString(
                            "Warning: %s operator '%s' right failed.",
                            parseNode.type,
                            parseNode.operator
                        );
                    } else if (rhsNode) {
                        msg = makeString(
                            "Warning: %s operator '%s' left failed.",
                            parseNode.type,
                            parseNode.operator
                        );
                    } else {
                        msg = makeString(
                            "Warning: %s operator '%s' left and right failed.",
                            parseNode.type,
                            parseNode.operator
                        );
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
            msg =
                msg ||
                makeString(
                    "Warning: Operator '%s' is not implemented.",
                    parseNode.operator
                );
            this.tracer.print(msg);
            const stringNode = this.ovaleAst.newNode(
                "string",
                annotation.astAnnotation
            );
            stringNode.value = `FIXME_${parseNode.operator}`;
            return stringNode;
        }
        return node;
    };

    private emitFunction: EmitVisitor<FunctionParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        if (parseNode.name == "ceil" || parseNode.name == "floor") {
            node = this.emit(parseNode.child[1], nodeList, annotation, action);
        } else {
            this.tracer.print(
                "Warning: Function '%s' is not implemented.",
                parseNode.name
            );
            node = this.ovaleAst.newNode("variable", annotation.astAnnotation);
            node.name = `FIXME_${parseNode.name}`;
        }
        return node;
    };

    private emitNumber: EmitVisitor<NumberParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        const node = this.ovaleAst.newNode("value", annotation.astAnnotation);
        node.value = parseNode.value;
        node.origin = 0;
        node.rate = 0;
        return node;
    };
    private emitOperand: EmitVisitor<OperandParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let operand = parseNode.name;
        let [token] = match(operand, operandTokenPattern);
        let target: string | undefined;
        if (token == "target" || token === "self") {
            node = this.emitOperandTarget(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
            if (!node) {
                target = token;
                operand = sub(operand, len(target) + 2);
                [token] = match(operand, operandTokenPattern);
            }
        }

        if (!node) {
            node = this.emitOperandRune(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.emitOperandSpecial(
                operand,
                parseNode,
                nodeList,
                annotation,
                action,
                target
            );
        }
        if (!node) {
            node = this.emitOperandRaidEvent(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.emitOperandRace(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.emitOperandAction(
                operand,
                parseNode,
                nodeList,
                annotation,
                action,
                target
            );
        }
        if (!node) {
            node = this.emitOperandCharacter(
                operand,
                parseNode,
                nodeList,
                annotation,
                action,
                target
            );
        }
        if (!node) {
            if (token == "active_dot") {
                target = target || "target";
                node = this.emitOperandActiveDot(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "aura") {
                node = this.emitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "azerite") {
                node = this.emitOperandAzerite(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "buff") {
                node = this.emitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "consumable") {
                node = this.emitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "cooldown") {
                node = this.emitOperandCooldown(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token === "dbc") {
                node = this.emitOperandDbc(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "debuff") {
                target = target || "target";
                node = this.emitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "disease") {
                target = target || "target";
                node = this.emitOperandDisease(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "dot") {
                target = target || "target";
                node = this.emitOperandDot(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "essence") {
                node = this.emitOperandEssence(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "glyph") {
                node = this.emitOperandGlyph(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "pet") {
                node = this.emitOperandPet(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (
                token == "prev" ||
                token == "prev_gcd" ||
                token == "prev_off_gcd"
            ) {
                node = this.emitOperandPreviousSpell(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "refreshable") {
                node = this.emitOperandRefresh(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "seal") {
                node = this.emitOperandSeal(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "set_bonus") {
                node = this.emitOperandSetBonus(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token === "stack") {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    `buffstacks(${action})`,
                    nodeList,
                    annotation.astAnnotation
                );
            } else if (token == "talent") {
                node = this.emitOperandTalent(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "totem") {
                node = this.emitOperandTotem(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "trinket") {
                node = this.emitOperandTrinket(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "variable") {
                node = this.emitOperandVariable(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "ground_aoe") {
                node = this.emitOperandGroundAoe(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else {
                node = this.emitMiscOperand(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            }
        }
        if (!node) {
            this.tracer.print(
                "Warning: Variable '%s' is not implemented.",
                parseNode.name
            );
            node = this.ovaleAst.newFunction(
                "message",
                annotation.astAnnotation
            );
            node.rawPositionalParams[1] = this.ovaleAst.newString(
                annotation.astAnnotation,
                `${parseNode.name} is not implemented`
            );
        }
        return node;
    };

    private emitOperandAction: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node: AstNode | undefined;
        let name;
        let property;
        if (sub(operand, 1, 7) == "action.") {
            const tokenIterator = gmatch(operand, operandTokenPattern);
            tokenIterator();
            name = tokenIterator();
            property = tokenIterator();
        } else {
            name = action;
            property = operand;
        }

        if (!name) {
            return undefined;
        }

        const [className, specialization] = [
            annotation.classId,
            annotation.specialization,
        ];
        [name] = this.disambiguate(annotation, name, className, specialization);
        target = (target && `${target}.`) || "";
        let buffName;
        [buffName] = this.disambiguate(
            annotation,
            name,
            className,
            specialization,
            undefined,
            "debuff"
        );
        const buffSpellId = annotation.dictionary[buffName];
        let prefix;
        let buffTarget;
        if (buffSpellId && isNumber(buffSpellId)) {
            const buffSpellInfo =
                this.ovaleData.getSpellOrListInfo(buffSpellId);
            if (buffSpellInfo) {
                if (buffSpellInfo.effect === "HARMFUL") {
                    prefix = "Debuff";
                } else if (buffSpellInfo.effect === "HELPFUL") {
                    prefix = "Buff";
                }
            }
        }

        if (!prefix)
            prefix = (truthy(find(buffName, "_debuff$")) && "Debuff") || "Buff";
        buffTarget = (prefix == "Debuff" && "target.") || target;
        let talentName = `${name}_talent`;
        [talentName] = this.disambiguate(
            annotation,
            talentName,
            className,
            specialization
        );
        let symbol = name;
        let code;
        if (property == "active") {
            if (isTotem(name)) {
                code = format("TotemPresent(%s)", name);
            } else {
                code = format("%s%sPresent(%s)", target, prefix, buffName);
                symbol = buffName;
            }
        } else if (property == "ap_check") {
            code = format("AstralPower() >= AstralPowerCost(%s)", name);
        } else if (property == "cast_regen") {
            code = format("FocusCastingRegen(%s)", name);
        } else if (property == "cast_time") {
            if (name === "use_item") code = "0";
            // TODO
            else code = format("CastTime(%s)", name);
        } else if (property == "charges") {
            code = format("Charges(%s)", name);
        } else if (property == "max_charges") {
            code = format("SpellMaxCharges(%s)", name);
        } else if (property == "charges_fractional") {
            code = format("Charges(%s count=0)", name);
        } else if (property === "channeling") {
            code = format("channeling(%s)", name);
        } else if (property == "cooldown") {
            if (name === "use_item") {
                code = format('ItemCooldown(slot="trinket0slot")');
            } else {
                code = format("SpellCooldown(%s)", name);
            }
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
        } else if (property === "last_used") {
            code = format("TimeSincePreviousSpell(%s)", name);
        } else if (property == "enabled") {
            if (parseNode.asType == "boolean") {
                code = format("Talent(%s)", talentName);
            } else {
                code = format("TalentPoints(%s)", talentName);
            }
            symbol = talentName;
        } else if (
            property == "execute_time" ||
            property == "execute_remains"
        ) {
            if (name == "use_item") {
                // Assume that items have an execute time of 0 seconds.
                code = "0";
            } else {
                code = format("ExecuteTime(%s)", name);
            }
        } else if (property == "executing") {
            code = format("ExecuteTime(%s) > 0", name);
        } else if (
            property === "full_reduction" ||
            property === "tick_reduction"
        ) {
            // TODO
            code = "0";
        } else if (property == "gcd") {
            code = "GCD()";
        } else if (property == "hit_damage") {
            code = format("%sDamage(%s)", target, name);
        } else if (
            property == "in_flight" ||
            property == "in_flight_to_target"
        ) {
            code = format("InFlightToTarget(%s)", name);
        } else if (property == "in_flight_remains") {
            code = "0";
        } else if (property == "miss_react") {
            code = "always(miss_react)";
        } else if (
            property == "persistent_multiplier" ||
            property == "pmultiplier"
        ) {
            code = format("PersistentMultiplier(%s)", buffName);
        } else if (property == "recharge_time") {
            code = format("SpellChargeCooldown(%s)", name);
        } else if (property == "full_recharge_time") {
            code = format("SpellFullRecharge(%s)", name);
        } else if (property == "remains") {
            if (isTotem(name)) {
                code = format("TotemRemaining(%s)", name);
            } else {
                code = format(
                    "%s%sRemaining(%s)",
                    buffTarget,
                    prefix,
                    buffName
                );
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
        }
        if (code) {
            if (name == "call_action_list" && property != "gcd") {
                this.tracer.print(
                    "Warning: dubious use of call_action_list in %s",
                    code
                );
            }
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (!specialActions[symbol]) {
                this.addSymbol(annotation, symbol);
            }
        }
        return node;
    };
    private emitOperandActiveDot: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "active_dot") {
            let name = tokenIterator();
            [name] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let dotName;
            [dotName] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization,
                undefined,
                "debuff"
            );
            const prefix =
                (truthy(find(dotName, "_buff$")) && "Buff") || "Debuff";
            target = (target && `${target}.`) || "";
            const code = format("%sCountOnAny(%s)", prefix, dotName);
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, dotName);
            }
        }
        return node;
    };

    private emitOperandAzerite: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "azerite") {
            let code;
            const name = tokenIterator();
            const property = tokenIterator();
            if (property == "rank") {
                code = format("AzeriteTraitRank(%s_trait)", name);
            } else if (property == "enabled") {
                code = format("HasAzeriteTrait(%s_trait)", name);
            }
            if (code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, `${name}_trait`);
            }
        }
        return node;
    };

    private emitOperandEssence: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "essence") {
            let code;
            const name = tokenIterator();
            const property = tokenIterator();

            let essenceId = format("%s_essence_id", name);
            [essenceId] = this.disambiguate(
                annotation,
                essenceId,
                annotation.classId,
                annotation.specialization
            );

            if (property == "major") {
                code = format("AzeriteEssenceIsMajor(%s)", essenceId);
            } else if (property == "minor") {
                code = format("AzeriteEssenceIsMinor(%s)", essenceId);
            } else if (property == "enabled") {
                code = format("AzeriteEssenceIsEnabled(%s)", essenceId);
            } else if (property === "rank") {
                code = format("AzeriteEssenceRank(%s)", essenceId);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, essenceId);
            }
        }
        return node;
    };

    private emitOperandRefresh: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "refreshable" && action) {
            let buffName;
            [buffName] = this.disambiguate(
                annotation,
                action,
                annotation.classId,
                annotation.specialization,
                undefined,
                "debuff"
            );
            let target;
            const prefix =
                (truthy(find(buffName, "_buff$")) && "Buff") || "Debuff";
            if (prefix == "Debuff") {
                target = "target.";
            } else {
                target = "";
            }
            const any =
                (this.ovaleData.defaultSpellLists[buffName] && " any=1") || "";
            const code = format("%sRefreshable(%s%s)", target, buffName, any);
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
            this.addSymbol(annotation, buffName);
        }
        return node;
    };

    private isDaemon(name: string) {
        return (
            name === "vilefiend" || name === "wild_imps" || name === "tyrant"
        );
    }

    private emitOperandDbc: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        if (!annotation.dbc) return undefined;

        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token !== "dbc") return undefined;
        const dataBaseName = tokenIterator();
        if (dataBaseName === "effect") {
            const effectId = tonumber(tokenIterator());
            const property = tokenIterator();
            if (property === "base_value") {
                const effect = annotation.dbc.effect[effectId];
                if (effect) {
                    return this.ovaleAst.newValue(
                        annotation.astAnnotation,
                        effect.base_value
                    );
                }
            }
        }
        return undefined;
    };

    private emitOperandBuff: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (
            token == "aura" ||
            token == "buff" ||
            token == "debuff" ||
            token == "consumable"
        ) {
            let name = tokenIterator();
            let property = tokenIterator();
            if (token == "consumable" && property == undefined) {
                property = "remains";
            }

            let code;
            let buffName;
            if (this.isDaemon(name)) {
                if (name === "tyrant") buffName = "demonic_tyrant";
                else buffName = name;
                if (property === "remains") {
                    code = `demonduration(${buffName})`;
                } else if (property === "stack") {
                    code = `demons(${buffName})`;
                } else if (property === "down") {
                    code = `demonduration(${buffName}) <= 0`;
                }
            } else if (name === "arcane_charge") {
                if (property === "stack") {
                    code = "arcanecharges()";
                } else if (property === "max_stack") {
                    code = "maxarcanecharges()";
                }
            } else if (truthy(find(name, "^bt_"))) {
                const trigger = gsub(sub(name, 4), "_", "");
                if (property === "up") {
                    code = `bloodtalons${trigger}present()`;
                } else if (property === "down") {
                    code = `not bloodtalons${trigger}present()`;
                }
            } else if (name === "frozen_pulse") {
                if (property === "up") code = "runecount() < 3";
            } else {
                [buffName] = this.disambiguate(
                    annotation,
                    name,
                    annotation.classId,
                    annotation.specialization,
                    undefined,
                    token as "buff" | "debuff"
                );
                let prefix;
                if (
                    !truthy(find(buffName, "_debuff$")) &&
                    !truthy(find(buffName, "_debuff$"))
                ) {
                    prefix = (target == "target" && "Debuff") || "Buff";
                } else {
                    prefix =
                        (truthy(find(buffName, "_debuff$")) && "Debuff") ||
                        "Buff";
                }

                const any =
                    (this.ovaleData.defaultSpellLists[buffName] && " any=1") ||
                    "";

                // target
                target = (target && `${target}.`) || "";
                if (buffName == "dark_transformation" && target == "") {
                    target = "pet.";
                }
                if (buffName == "beast_cleave_buff" && target == "") {
                    target = "pet.";
                }
                if (buffName == "frenzy_pet_buff" && target == "") {
                    target = "pet.";
                }

                if (property == "cooldown_remains") {
                    code = format("SpellCooldown(%s)", name);
                } else if (property == "down") {
                    code = format(
                        "%s%sExpires(%s%s)",
                        target,
                        prefix,
                        buffName,
                        any
                    );
                } else if (property == "duration") {
                    code = format("BaseDuration(%s)", buffName);
                } else if (property === "last_expire") {
                    code = format("%sBuffLastExpire(%s)", target, buffName);
                } else if (property == "max_stack") {
                    code = format("SpellData(%s max_stacks)", buffName);
                } else if (property == "react" || property == "stack") {
                    if (parseNode.asType == "boolean") {
                        code = format(
                            "%s%sPresent(%s%s)",
                            target,
                            prefix,
                            buffName,
                            any
                        );
                    } else {
                        code = format(
                            "%s%sStacks(%s%s)",
                            target,
                            prefix,
                            buffName,
                            any
                        );
                    }
                } else if (property == "remains") {
                    if (parseNode.asType == "boolean") {
                        code = format(
                            "%s%sPresent(%s%s)",
                            target,
                            prefix,
                            buffName,
                            any
                        );
                    } else {
                        code = format(
                            "%s%sRemaining(%s%s)",
                            target,
                            prefix,
                            buffName,
                            any
                        );
                    }
                } else if (property == "up") {
                    code = format(
                        "%s%sPresent(%s%s)",
                        target,
                        prefix,
                        buffName,
                        any
                    );
                } else if (property == "refreshable") {
                    code = format(
                        "%s%sRefreshable(%s)",
                        target,
                        prefix,
                        buffName
                    );
                } else if (property == "improved") {
                    code = format("%sImproved(%s%s)", prefix, buffName);
                } else if (property === "stack_value") {
                    code = format(
                        "%s%sStacks(%s%s)",
                        target,
                        prefix,
                        buffName,
                        any
                    );
                } else if (property == "value") {
                    code = format(
                        "%s%sAmount(%s%s)",
                        target,
                        prefix,
                        buffName,
                        any
                    );
                }
            }
            if (code) {
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (buffName) this.addSymbol(annotation, buffName);
            }
        }
        return node;
    };

    private emitOperandCharacter: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const className = annotation.classId;
        const specialization = annotation.specialization;
        const camelSpecialization = toLowerSpecialization(annotation);
        target = (target && `${target}.`) || "";
        let code;
        if (characterProperties[operand]) {
            code = `${target}${characterProperties[operand]}`;
        } else if (operand == "position_front") {
            code =
                (annotation.position == "front" && "always(position_front)") ||
                "never(position_front)";
        } else if (operand == "position_back") {
            code =
                (annotation.position == "back" && "always(position_back)") ||
                "never(position_back)";
        } else if (className == "MAGE" && operand == "incanters_flow_dir") {
            const name = "incanters_flow_buff";
            code = format("BuffDirection(%s)", name);
            this.addSymbol(annotation, name);
        } else if (className == "PALADIN" && operand == "time_to_hpg") {
            code = `${camelSpecialization}TimeToHPG()`;
            if (specialization == "holy") {
                annotation.time_to_hpg_heal = className;
            } else if (specialization == "protection") {
                annotation.time_to_hpg_tank = className;
            } else if (specialization == "retribution") {
                annotation.time_to_hpg_melee = className;
            }
        } else if (
            className == "PRIEST" &&
            operand == "shadowy_apparitions_in_flight"
        ) {
            code = "1";
        } else if (operand == "rtb_buffs") {
            code = "BuffCount(roll_the_bones_buff)";
        } else if (sub(operand, 1, 22) == "active_enemies_within.") {
            code = "Enemies()";
        } else if (truthy(find(operand, "^incoming_damage_"))) {
            const [_seconds, measure] = match(
                operand,
                "^incoming_damage_([%d]+)(m?s?)$"
            );
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
            const weaponType = sub(operand, 11);
            code = `HasWeapon(mainhandslot ${weaponType})`;
        } else if (operand == "mastery_value") {
            code = format("%sMasteryEffect() / 100", target);
        } else if (sub(operand, 1, 5) == "role.") {
            const [role] = match(operand, "^role%.([%w_]+)");
            if (role && role == annotation.role) {
                code = format("always(role_%s)", role);
            } else {
                code = format("never(role_%s)", role);
            }
        } else if (operand == "spell_haste" || operand == "stat.spell_haste") {
            code = "100 / { 100 + SpellCastSpeedPercent() }";
        } else if (
            operand == "attack_haste" ||
            operand == "stat.attack_haste"
        ) {
            code = "100 / { 100 + MeleeAttackSpeedPercent() }";
        } else if (sub(operand, 1, 13) == "spell_targets") {
            code = "Enemies(tagged=1)";
        } else if (operand == "t18_class_trinket") {
            code = format("HasTrinket(%s)", operand);
            this.addSymbol(annotation, operand);
        }
        if (code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };

    private emitOperandCooldown: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();

        if (token == "cooldown") {
            let name = tokenIterator();
            const property = tokenIterator();
            let prefix;
            let isSymbol;
            if (truthy(match(name, "^item_cd_"))) {
                name = `shared="${name}"`;
                prefix = "Item";
                isSymbol = false;
            } else if (truthy(match(name, "^[%w_]+_%d+$"))) {
                name = gsub(name, "_%d+$", "_item");
                prefix = "Item";
                isSymbol = true;
            } else {
                [name, prefix] = this.disambiguate(
                    annotation,
                    name,
                    annotation.classId,
                    annotation.specialization,
                    "spell"
                );
                isSymbol = true;
            }
            let code;
            if (property == "execute_time") {
                code = format("ExecuteTime(%s)", name);
            } else if (
                property == "duration" ||
                property == "duration_expected"
            ) {
                code = format("%sCooldownDuration(%s)", prefix, name);
            } else if (property == "ready") {
                code = format("%sCooldown(%s) <= 0", prefix, name);
            } else if (
                property == "remains" ||
                property == "remains_expected" ||
                property == "remains_guess" ||
                property == "adjusted_remains"
            ) {
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
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (isSymbol) this.addSymbol(annotation, name);
            }
        }
        return node;
    };
    private emitOperandDisease: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "disease") {
            const property = tokenIterator();
            target = (target && `${target}.`) || "";
            let code;
            if (property == "max_ticking") {
                code = `${target}DiseasesAnyTicking()`;
            } else if (property == "min_remains") {
                code = `${target}DiseasesRemaining()`;
            } else if (property == "min_ticking") {
                code = `${target}DiseasesTicking()`;
            } else if (property == "ticking") {
                code = `${target}DiseasesAnyTicking()`;
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private emitOperandGroundAoe: EmitOperandVisitor = (
        operand: string,
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action?: string
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "ground_aoe") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let dotName;
            [dotName] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization,
                undefined,
                "debuff"
            );
            const prefix =
                (truthy(find(dotName, "_buff$")) && "Buff") || "Debuff";
            const target = (prefix == "Debuff" && "target.") || "";
            let code;
            if (property == "remains") {
                code = format("%s%sRemaining(%s)", target, prefix, dotName);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, dotName);
            }
        }
        return node;
    };

    private emitOperandDot: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "dot") {
            let name = tokenIterator();
            if (truthy(match(name, "_dot$"))) {
                name = gsub(name, "_dot$", "");
            }
            const property = tokenIterator();
            let [dotName] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization,
                undefined,
                "debuff"
            );
            const prefix =
                (truthy(find(dotName, "_buff$")) && "Buff") || "Debuff";
            target = (target && `${target}.`) || "";
            let code;
            if (property == "duration") {
                code = format("%s%sDuration(%s)", target, prefix, dotName);
            } else if (property == "pmultiplier") {
                code = format(
                    "%s%sPersistentMultiplier(%s)",
                    target,
                    prefix,
                    dotName
                );
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
                code = format(
                    "TargetDebuffRemaining(%s_exsanguinated)",
                    dotName
                );
            } else if (property == "refreshable") {
                code = format("%s%sRefreshable(%s)", target, prefix, dotName);
            } else if (property === "max_stacks") {
                code = format("MaxStacks(%s)", dotName);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, dotName);
            }
        }
        return node;
    };
    private emitOperandGlyph: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "glyph") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let glyphName = `glyph_of_${name}`;
            [glyphName] = this.disambiguate(
                annotation,
                glyphName,
                annotation.classId,
                annotation.specialization
            );
            let code;
            if (property == "disabled") {
                code = format("not Glyph(%s)", glyphName);
            } else if (property == "enabled") {
                code = format("Glyph(%s)", glyphName);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, glyphName);
            }
        }
        return node;
    };
    private emitOperandPet: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "pet") {
            const name = tokenIterator();
            const property = tokenIterator();
            const target = "pet";
            if (name == "buff") {
                const pattern = format("^pet%%.([%%w_.]+)", operand);
                const [petOperand] = match(operand, pattern);
                node = this.emitOperandBuff(
                    petOperand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else {
                const pattern = format("^pet%%.%s%%.([%%w_.]+)", name);
                let [petOperand] = match(operand, pattern);
                if (petOperand) {
                    node = this.emitOperandSpecial(
                        petOperand,
                        parseNode,
                        nodeList,
                        annotation,
                        action,
                        target
                    );
                }
                if (!node) {
                    let code: string | undefined;
                    const [spellName] = this.disambiguate(
                        annotation,
                        name,
                        annotation.classId,
                        annotation.specialization
                    );
                    if (isTotem(spellName)) {
                        if (property == "active") {
                            code = format("TotemPresent(%s)", spellName);
                        } else if (property == "remains") {
                            code = format("TotemRemaining(%s)", spellName);
                        }
                        this.addSymbol(annotation, spellName);
                    } else if (property == "active") {
                        code = "pet.Present()";
                    }
                    if (code) {
                        [node] = this.ovaleAst.parseCode(
                            "expression",
                            code,
                            nodeList,
                            annotation.astAnnotation
                        );
                    }
                    if (!node) {
                        node = this.emitOperandAction(
                            petOperand,
                            parseNode,
                            nodeList,
                            annotation,
                            action,
                            target
                        );
                    }
                    if (!node) {
                        node = this.emitOperandCharacter(
                            petOperand,
                            parseNode,
                            nodeList,
                            annotation,
                            action,
                            target
                        );
                    }
                    if (!node) {
                        let [petAbilityName] = match(
                            petOperand,
                            "^[%w_]+%.([^.]+)"
                        );
                        [petAbilityName] = this.disambiguate(
                            annotation,
                            petAbilityName,
                            annotation.classId,
                            annotation.specialization
                        );
                        if (
                            sub(petAbilityName, 1, 4) != "pet_" &&
                            name !== "main"
                        ) {
                            petOperand = gsub(
                                petOperand,
                                "^([%w_]+)%.",
                                `%1.${name}_`
                            );
                        }
                        if (property == "buff") {
                            node = this.emitOperandBuff(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action,
                                target
                            );
                        } else if (property == "cooldown") {
                            node = this.emitOperandCooldown(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action
                            );
                        } else if (property == "debuff") {
                            node = this.emitOperandBuff(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action,
                                target
                            );
                        } else if (property == "dot") {
                            node = this.emitOperandDot(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action,
                                target
                            );
                        }
                    }
                }
            }
        }
        return node;
    };
    private emitOperandPreviousSpell: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
            let name = tokenIterator();
            let howMany = 1;
            if (tonumber(name)) {
                howMany = tonumber(name);
                name = tokenIterator();
            }
            [name] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let code;
            if (token == "prev") {
                code = format("PreviousSpell(%s)", name);
            } else if (token == "prev_gcd") {
                if (howMany != 1) {
                    code = format(
                        "PreviousGCDSpell(%s count=%d)",
                        name,
                        howMany
                    );
                } else {
                    code = format("PreviousGCDSpell(%s)", name);
                }
            } else {
                code = format("PreviousOffGCDSpell(%s)", name);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, name);
            }
        }
        return node;
    };
    private emitOperandRaidEvent: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let name;
        let property;
        if (sub(operand, 1, 11) == "raid_event.") {
            const tokenIterator = gmatch(operand, operandTokenPattern);
            tokenIterator();
            name = tokenIterator();
            property = tokenIterator();
        } else {
            const tokenIterator = gmatch(operand, operandTokenPattern);
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
                code = "never(raid_event_movement_exists)";
            } else if (property == "remains") {
                code = "0";
            }
        } else if (name == "adds") {
            if (property == "cooldown") {
                code = "600";
            } else if (property == "count") {
                code = "0";
            } else if (property == "exists" || property == "up") {
                code = "never(raid_event_adds_exists)";
            } else if (property == "in") {
                code = "600";
            } else if (property == "duration") {
                code = "10"; //TODO
            } else if (property == "remains") {
                code = "0"; // TODO
            }
        } else if (name == "invulnerable") {
            if (property == "up") {
                code = "never(raid_events_invulnerable_up)";
            } else if (property === "exists") {
                code = "never(raid_event_invulnerable_exists)";
            }
        } else if (name == "vulnerable") {
            if (property == "exists") {
                code = "always(raid_event_vulnerable_exists)";
            } else if (property == "in") {
                code = "0";
            } else if (property == "up") {
                code = "always(raid_event_vulnerable_up)";
            }
        }
        if (code) {
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private emitOperandRace: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "race") {
            const race = lower(tokenIterator());
            let code;
            if (race) {
                let raceId = undefined;
                if (race == "blood_elf") {
                    raceId = "BloodElf";
                } else if (race == "troll") {
                    raceId = "Troll";
                } else if (race == "orc") {
                    raceId = "Orc";
                } else if (race == "night_elf") {
                    raceId = "NightElf";
                } else {
                    this.tracer.print("Warning: Race '%s' not defined", race);
                }
                code = format("Race(%s)", raceId);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };
    private emitOperandRune: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let code;
        if (parseNode.rune) {
            if (parseNode.asType == "boolean") {
                code = "RuneCount() >= 1";
            } else {
                code = "RuneCount()";
            }
        } else if (truthy(match(operand, "^rune.time_to_([%d]+)$"))) {
            const runes = match(operand, "^rune.time_to_([%d]+)$");
            code = format("TimeToRunes(%d)", runes);
        } else {
            return undefined;
        }
        [node] = this.ovaleAst.parseCode(
            "expression",
            code,
            nodeList,
            annotation.astAnnotation
        );
        return node;
    };
    private emitOperandSetBonus: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        const [setBonus] = match(operand, "^set_bonus%.(.*)$");
        let code;
        if (setBonus) {
            const tokenIterator = gmatch(setBonus, "[^_]+");
            let name = tokenIterator();
            let count = tokenIterator();
            const role = tokenIterator();
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
        }
        if (code) {
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private emitOperandSeal: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "seal") {
            const name = lower(tokenIterator());
            let code;
            if (name) {
                code = format("Stance(paladin_seal_of_%s)", name);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };
    private emitOperandSpecial: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node: AstNode | undefined;
        const className = annotation.classId;
        const specialization = annotation.specialization;
        target = (target && `${target}.`) || "";
        operand = lower(operand);
        let code;
        if (operand == "desired_targets") {
            code = `${toCamelCase(specialization)}DesiredTargets()`;
            annotation.desired_targets = true;
        } else if (
            className == "DEATHKNIGHT" &&
            operand == "dot.breath_of_sindragosa.ticking"
        ) {
            const buffName = "breath_of_sindragosa";
            code = format("BuffPresent(%s)", buffName);
            this.addSymbol(annotation, buffName);
        } else if (
            className == "DEATHKNIGHT" &&
            sub(operand, 1, 24) == "pet.dancing_rune_weapon."
        ) {
            const petOperand = sub(operand, 25);
            const tokenIterator = gmatch(petOperand, operandTokenPattern);
            const token = tokenIterator();
            if (token == "active") {
                const buffName = "dancing_rune_weapon_buff";
                code = format("BuffPresent(%s)", buffName);
                this.addSymbol(annotation, buffName);
            } else if (token == "dot") {
                if (target == "") {
                    target = "target";
                } else {
                    target = sub(target, 1, -2);
                }
                node = this.emitOperandDot(
                    petOperand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            }
        } else if (
            className == "DEATHKNIGHT" &&
            sub(operand, 1, 15) == "pet.army_ghoul."
        ) {
            const petOperand = sub(operand, 15);
            const tokenIterator = gmatch(petOperand, operandTokenPattern);
            const token = tokenIterator();
            if (token == "active") {
                const spell = "army_of_the_dead";
                // Army of the Dead ghouls last for 30 seconds after summoning.
                code = format(
                    "SpellCooldownDuration(%s) - SpellCooldown(%s) < 30",
                    spell,
                    spell
                );
                this.addSymbol(annotation, spell);
            }
        } else if (
            className == "DEATHKNIGHT" &&
            sub(operand, 1, 15) == "pet.apoc_ghoul."
        ) {
            const petOperand = sub(operand, 15);
            const tokenIterator = gmatch(petOperand, operandTokenPattern);
            const token = tokenIterator();
            if (token == "active") {
                const spell = "apocalypse";
                // Apocalypse ghouls last for 15 seconds after summoning.
                code = format(
                    "SpellCooldownDuration(%s) - SpellCooldown(%s) < 15",
                    spell,
                    spell
                );
                this.addSymbol(annotation, spell);
            }
        } else if (
            className == "DEMONHUNTER" &&
            truthy(match(operand, "^buff%.out_of_range%."))
        ) {
            const tokenIterator = gmatch(operand, operandTokenPattern);
            tokenIterator(); // consume "buff."
            tokenIterator(); // consume "out_of_range."
            let modifier = lower(tokenIterator());
            let spell = "chaos_strike";
            if (specialization == "vengeance") {
                spell = "shear";
            }
            if (modifier == "up") {
                code = format("not target.InRange(%s)", spell);
            } else if (modifier == "down") {
                code = format("target.InRange(%s)", spell);
            }
            this.addSymbol(annotation, spell);
        } else if (
            className == "DEMONHUNTER" &&
            operand == "buff.metamorphosis.extended_by_demonic"
        ) {
            code = "not BuffExpires(extended_by_demonic_buff)";
        } else if (
            className == "DEMONHUNTER" &&
            operand == "cooldown.chaos_blades.ready"
        ) {
            code =
                "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) <= 0";
            this.addSymbol(annotation, "chaos_blades_talent");
            this.addSymbol(annotation, "chaos_blades");
        } else if (
            className == "DEMONHUNTER" &&
            operand == "cooldown.nemesis.ready"
        ) {
            code = "Talent(nemesis_talent) and SpellCooldown(nemesis) <= 0";
            this.addSymbol(annotation, "nemesis_talent");
            this.addSymbol(annotation, "nemesis");
        } else if (
            className == "DEMONHUNTER" &&
            operand == "cooldown.metamorphosis.ready" &&
            specialization == "havoc"
        ) {
            code =
                "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis) <= 0";
            this.addSymbol(annotation, "metamorphosis");
        } else if (className == "DRUID" && truthy(match(operand, "^druid%."))) {
            const tokenIterator = gmatch(operand, operandTokenPattern);
            tokenIterator(); // consume "druid."
            let name = lower(tokenIterator());

            const [debuffName] = this.disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization,
                undefined,
                "debuff"
            );
            const property = tokenIterator();
            if (property == "ticks_gained_on_refresh") {
                if (debuffName == "primal_wrath") {
                    code = "target.TicksGainedOnRefresh(rip primal_wrath)";
                    this.addSymbol(annotation, "primal_wrath");
                    this.addSymbol(annotation, "rip");
                } else {
                    code = format(
                        "target.TicksGainedOnRefresh(%s)",
                        debuffName
                    );
                    this.addSymbol(annotation, debuffName);
                }
            }
        } else if (
            className == "DRUID" &&
            operand == "buff.wild_charge_movement.down"
        ) {
            code = "always(wild_charge_movement_down)";
        } else if (className == "DRUID" && operand == "eclipse_dir.lunar") {
            code = "EclipseDir() < 0";
        } else if (className == "DRUID" && operand == "eclipse_dir.solar") {
            code = "EclipseDir() > 0";
        } else if (className == "DRUID" && operand == "max_fb_energy") {
            const spellName = "ferocious_bite";
            code = format("EnergyCost(%s max=1)", spellName);
            this.addSymbol(annotation, spellName);
        } else if (className == "DRUID" && operand == "solar_wrath.ap_check") {
            const spellName = "solar_wrath";
            code = format("AstralPower() >= AstralPowerCost(%s)", spellName);
            this.addSymbol(annotation, spellName);
        } else if (className == "DRUID" && operand == "starfire.ap_check") {
            const spellName = "starfire";
            code = format("AstralPower() >= AstralPowerCost(%s)", spellName);
            this.addSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "buff.careful_aim.up") {
            code =
                "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)";
            this.addSymbol(annotation, "rapid_fire_buff");
        } else if (
            className == "HUNTER" &&
            operand == "buff.stampede.remains"
        ) {
            const spellName = "stampede";
            code = format("TimeSincePreviousSpell(%s) < 40", spellName);
            this.addSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "lowest_vuln_within.5") {
            code = "target.DebuffRemaining(vulnerable)";
            this.addSymbol(annotation, "vulnerable");
        } else if (
            className == "HUNTER" &&
            operand == "cooldown.trueshot.duration_guess"
        ) {
            // we calculate the extension we got for trueshot (from talents), the last time we cast it
            // does the simulator even have this information?
            code = "0";
        } else if (className == "HUNTER" && operand == "ca_execute") {
            code =
                "Talent(careful_aim_talent) and (target.HealthPercent() > 80 or target.HealthPercent() < 20)";
            this.addSymbol(annotation, "careful_aim_talent");
        } else if (
            className == "MAGE" &&
            operand == "buff.rune_of_power.remains"
        ) {
            code = "TotemRemaining(rune_of_power)";
        } else if (className == "MAGE" && operand == "buff.shatterlance.up") {
            code =
                "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)";
            this.addSymbol(annotation, "frostbolt");
            this.addSymbol(annotation, "t18_class_trinket");
        } else if (
            className == "MAGE" &&
            (operand == "burn_phase" || operand == "pyro_chain")
        ) {
            if (parseNode.asType == "boolean") {
                code = format("GetState(%s) > 0", operand);
            } else {
                code = format("GetState(%s)", operand);
            }
        } else if (
            className == "MAGE" &&
            (operand == "burn_phase_duration" ||
                operand == "pyro_chain_duration")
        ) {
            const variable = sub(operand, 1, -10);
            if (parseNode.asType == "boolean") {
                code = format("GetStateDuration(%s) > 0", variable);
            } else {
                code = format("GetStateDuration(%s)", variable);
            }
        } else if (className == "MAGE" && operand == "firestarter.active") {
            code =
                "Talent(firestarter_talent) and target.HealthPercent() >= 90";
            this.addSymbol(annotation, "firestarter_talent");
        } else if (className == "MAGE" && operand == "brain_freeze_active") {
            code = "target.DebuffPresent(winters_chill_debuff)";
            this.addSymbol(annotation, "winters_chill_debuff");
        } else if (
            className == "MAGE" &&
            operand == "action.frozen_orb.in_flight"
        ) {
            code = "TimeSincePreviousSpell(frozen_orb) < 10";
            this.addSymbol(annotation, "frozen_orb");
        } else if (
            className == "MONK" &&
            operand == "buff.recent_purifies.value"
        ) {
            // TODO assume that we've always recently purified 5% max health
            code = "MaxHealth() * 0.05";
        } else if (
            className == "MONK" &&
            sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target."
        ) {
            const property = sub(operand, 36);
            if (target == "") {
                target = "target.";
            }
            const debuffName = "storm_earth_and_fire_target_debuff";
            this.addSymbol(annotation, debuffName);
            if (property == "down") {
                code = format("%sDebuffExpires(%s)", target, debuffName);
            } else if (property == "up") {
                code = format("%sDebuffPresent(%s)", target, debuffName);
            }
        } else if (className == "MONK" && operand == "dot.zen_sphere.ticking") {
            const buffName = "zen_sphere_buff";
            code = format("BuffPresent(%s)", buffName);
            this.addSymbol(annotation, buffName);
            // } else if (className == "MONK" && sub(operand, 1, 8) == "stagger.") {
            //     let property = sub(operand, 9);
            //     if (
            //         property == "heavy" ||
            //         property == "light" ||
            //         property == "moderate"
            //     ) {
            //         let buffName = format("%s_stagger_debuff", property);
            //         code = format("DebuffPresent(%s)", buffName);
            //         this.AddSymbol(annotation, buffName);
            //     } else if (property == "pct") {
            //         code = format(
            //             "%sStaggerRemaining() / %sMaxHealth() * 100",
            //             target,
            //             target
            //         );
            //     } else if (truthy(match(property, "last_tick_damage_(%d+)"))) {
            //         let ticks = match(property, "last_tick_damage_(%d+)");
            //         code = format("StaggerTick(%d)", ticks);
            //     }
        } else if (
            className == "MONK" &&
            operand == "spinning_crane_kick.count"
        ) {
            code = "SpellCount(spinning_crane_kick)";
            this.addSymbol(annotation, "spinning_crane_kick");
        } else if (className == "MONK" && operand === "combo_strike") {
            if (action) {
                code = format("not PreviousSpell(%s)", action);
            }
        } else if (className == "MONK" && operand === "combo_break") {
            if (action) {
                code = format("PreviousSpell(%s)", action);
            }
        } else if (
            className == "PALADIN" &&
            operand == "dot.sacred_shield.remains"
        ) {
            const buffName = "sacred_shield_buff";
            code = format("BuffRemaining(%s)", buffName);
            this.addSymbol(annotation, buffName);
        } else if (className == "PRIEST" && operand == "mind_harvest") {
            code = "target.MindHarvest()";
        } else if (
            className == "PRIEST" &&
            operand == "natural_shadow_word_death_range"
        ) {
            code = "target.HealthPercent() < 20";
        } else if (className == "PRIEST" && operand == "primary_target") {
            code = "1";
        } else if (className == "ROGUE" && operand == "trinket.cooldown.up") {
            code =
                "HasTrinket(draught_of_souls) and ItemCooldown(draught_of_souls) > 0";
            this.addSymbol(annotation, "draught_of_souls");
        } else if (className == "ROGUE" && operand == "mantle_duration") {
            code = "BuffRemaining(master_assassins_initiative)";
            this.addSymbol(annotation, "master_assassins_initiative");
        } else if (className == "ROGUE" && operand == "poisoned_enemies") {
            code = "0";
        } else if (className == "ROGUE" && operand == "poisoned_bleeds") {
            code =
                "DebuffCountOnAny(rupture) + DebuffCountOnAny(garrote) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)";
            this.addSymbol(annotation, "rupture");
            this.addSymbol(annotation, "garrote");
            this.addSymbol(annotation, "internal_bleeding_talent");
            this.addSymbol(annotation, "internal_bleeding_debuff");
        } else if (className == "ROGUE" && operand == "exsanguinated") {
            code = "target.DebuffPresent(exsanguinated)";
            this.addSymbol(annotation, "exsanguinated");
        }
        // TODO: has garrote been casted out of stealth with shrouded suffocation azerite trait?
        else if (className == "ROGUE" && operand == "ss_buffed") {
            code = "never(ss_buffed)";
        } else if (className == "ROGUE" && operand == "non_ss_buffed_targets") {
            code = "Enemies() - DebuffCountOnAny(garrote)";
            this.addSymbol(annotation, "garrote");
        } else if (
            className == "ROGUE" &&
            operand == "ss_buffed_targets_above_pandemic"
        ) {
            code = "0";
        } else if (
            className == "ROGUE" &&
            operand == "master_assassin_remains"
        ) {
            code = "BuffRemaining(master_assassin_buff)";
            this.addSymbol(annotation, "master_assassin_buff");
        } else if (
            className == "ROGUE" &&
            operand == "buff.roll_the_bones.remains"
        ) {
            code = "BuffRemaining(roll_the_bones_buff)";
            this.addSymbol(annotation, "roll_the_bones_buff");
        } else if (
            className == "ROGUE" &&
            operand == "buff.roll_the_bones.up"
        ) {
            code = "BuffPresent(roll_the_bones_buff)";
            this.addSymbol(annotation, "roll_the_bones_buff");
        } else if (
            className == "SHAMAN" &&
            operand == "buff.resonance_totem.remains"
        ) {
            const [spell] = this.disambiguate(
                annotation,
                "totem_mastery",
                annotation.classId,
                annotation.specialization
            );
            code = format("TotemRemaining(%s)", spell);
            this.addSymbol(annotation, spell);
        } else if (
            className == "SHAMAN" &&
            truthy(match(operand, "pet.[a-z_]+.active"))
        ) {
            code = "pet.Present()";
        } else if (
            className == "WARLOCK" &&
            truthy(match(operand, "pet%.service_[a-z_]+%..+"))
        ) {
            const [spellName, property] = match(
                operand,
                "pet%.(service_[a-z_]+)%.(.+)"
            );
            if (property == "active") {
                code = format("SpellCooldown(%s) > 100", spellName);
                this.addSymbol(annotation, spellName);
            }
        } else if (
            className == "WARLOCK" &&
            truthy(match(operand, "dot.unstable_affliction_([1-5]).remains"))
        ) {
            const num = match(
                operand,
                "dot.unstable_affliction_([1-5]).remains"
            );
            code = format(
                "target.DebuffStacks(unstable_affliction_debuff) >= %s",
                num
            );
        } else if (
            className == "WARLOCK" &&
            operand == "buff.active_uas.stack"
        ) {
            code = "target.DebuffStacks(unstable_affliction_debuff)";
        } else if (
            className == "WARLOCK" &&
            truthy(match(operand, "pet%.[a-z_]+%..+"))
        ) {
            const [spellName, property] = match(
                operand,
                "pet%.([a-z_]+)%.(.+)"
            );
            if (property == "remains") {
                code = format("DemonDuration(%s)", spellName);
            } else if (property == "active") {
                code = format("DemonDuration(%s) > 0", spellName);
            }
        } else if (className == "WARLOCK" && operand == "contagion") {
            code = "BuffRemaining(unstable_affliction_buff)";
        } else if (
            className == "WARLOCK" &&
            operand == "buff.wild_imps.stack"
        ) {
            code = "Demons(wild_imp) + Demons(wild_imp_inner_demons)";
            this.addSymbol(annotation, "wild_imp");
            this.addSymbol(annotation, "wild_imp_inner_demons");
        } else if (
            className == "WARLOCK" &&
            operand == "buff.dreadstalkers.remains"
        ) {
            code = "DemonDuration(dreadstalker)";
            this.addSymbol(annotation, "dreadstalker");
        } else if (
            className == "WARLOCK" &&
            truthy(match(operand, "imps_spawned_during.([%d]+)"))
        ) {
            const ms = match(operand, "imps_spawned_during.([%d]+)");
            code = format("ImpsSpawnedDuring(%d)", ms);
        } else if (
            className == "WARLOCK" &&
            operand == "time_to_imps.all.remains"
        ) {
            code = "0"; // let's assume imps spawn instantly
        } else if (className == "WARLOCK" && operand == "havoc_active") {
            code = "DebuffCountOnAny(havoc) > 0";
            this.addSymbol(annotation, "havoc");
        } else if (className == "WARLOCK" && operand == "havoc_remains") {
            code = "DebuffRemainingOnAny(havoc)";
            this.addSymbol(annotation, "havoc");
        } else if (
            className == "WARRIOR" &&
            operand == "gcd.remains" &&
            (action == "battle_cry" || action == "avatar")
        ) {
            code = "0";
        } else if (operand == "buff.enrage.down") {
            code = `not ${target}IsEnraged()`;
        } else if (operand == "buff.enrage.remains") {
            code = `${target}EnrageRemaining()`;
        } else if (operand == "buff.enrage.up") {
            code = `${target}IsEnraged()`;
        } else if (operand == "cp_gain") {
            code = `SpellInfoProperty(${action} combopoints) <? ComboPointsDeficit()`;
        } else if (operand == "debuff.casting.react") {
            code = `${target}IsInterruptible()`;
        } else if (operand == "debuff.casting.up") {
            const t = (target == "" && "target.") || target;
            code = `${t}IsInterruptible()`;
        } else if (operand == "distance") {
            code = `${target}Distance()`;
        } else if (sub(operand, 1, 9) == "equipped.") {
            const [name] = this.disambiguate(
                annotation,
                `${sub(operand, 10)}_item`,
                className,
                specialization
            );
            const itemId = tonumber(name);
            const itemName = name;
            const item = (itemId && tostring(itemId)) || itemName;
            code = format("HasEquippedItem(%s)", item);
            this.addSymbol(annotation, item);
        } else if (operand == "gcd.max") {
            code = "GCD()";
        } else if (operand == "gcd.remains") {
            code = "GCDRemaining()";
        } else if (sub(operand, 1, 15) == "legendary_ring.") {
            const [name] = this.disambiguate(
                annotation,
                "legendary_ring",
                className,
                specialization
            );
            const buffName = `${name}_buff`;
            const properties = sub(operand, 16);
            const tokenIterator = gmatch(properties, operandTokenPattern);
            let token = tokenIterator();
            if (token == "cooldown") {
                token = tokenIterator();
                if (token == "down") {
                    code = format("ItemCooldown(%s) > 0", name);
                    this.addSymbol(annotation, name);
                } else if (token == "remains") {
                    code = format("ItemCooldown(%s)", name);
                    this.addSymbol(annotation, name);
                } else if (token == "up") {
                    code = format("not ItemCooldown(%s) > 0", name);
                    this.addSymbol(annotation, name);
                }
            } else if (token == "has_cooldown") {
                code = format("ItemCooldownDuration(%s) > 0", name);
                this.addSymbol(annotation, name);
            } else if (token == "up") {
                code = format("BuffPresent(%s)", buffName);
                this.addSymbol(annotation, buffName);
            } else if (token == "remains") {
                code = format("BuffRemaining(%s)", buffName);
                this.addSymbol(annotation, buffName);
            }
        } else if (operand == "ptr") {
            code = "PTR()";
        } else if (operand == "time_to_die") {
            code = "target.TimeToDie()";
        } else if (sub(operand, 1, 10) == "using_apl.") {
            const [aplName] = match(operand, "^using_apl%.([%w_]+)");
            code = format("List(opt_using_apl %s)", aplName);
            annotation.using_apl = annotation.using_apl || {};
            annotation.using_apl[aplName] = true;
        } else if (operand == "cooldown.buff_sephuzs_secret.remains") {
            code = "BuffCooldown(sephuzs_secret_buff)";
            this.addSymbol(annotation, "sephuzs_secret_buff");
        } else if (operand == "is_add") {
            const t = target || "target.";
            code = format("not %sClassification(worldboss)", t);
        } else if (operand == "priority_rotation") {
            code = "CheckBoxOn(opt_priority_rotation)";
            annotation.opt_priority_rotation = className;
        }
        if (code) {
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private emitOperandTalent: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "talent") {
            const name = lower(tokenIterator());
            const property = tokenIterator();
            let talentName = `${name}_talent`;
            [talentName] = this.disambiguate(
                annotation,
                talentName,
                annotation.classId,
                annotation.specialization
            );
            let code;
            if (property == "disabled") {
                if (parseNode.asType == "boolean") {
                    code = format("not HasTalent(%s)", talentName);
                } else {
                    code = format("HasTalent(%s no)", talentName);
                }
            } else if (property == "enabled" || property === undefined) {
                if (parseNode.asType == "boolean") {
                    code = format("HasTalent(%s)", talentName);
                } else {
                    code = format("TalentPoints(%s)", talentName);
                }
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.addSymbol(annotation, talentName);
            }
        }
        return node;
    };

    private emitOperandTarget: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        let target = tokenIterator();
        if (target === "self") target = "player";
        let property = tokenIterator();
        let howMany = 1;
        if (tonumber(property)) {
            howMany = tonumber(property);
            property = tokenIterator();
        }
        if (howMany > 1) {
            this.tracer.print(
                "Warning: target.%d.%property has not been implemented for multiple targets. (%s)",
                operand
            );
        }
        let code;
        //OvaleSimulationCraft.Print(token, property, operand);
        if (!property) {
            code = `${target}.guid()`;
        } else if (property == "adds") {
            code = "Enemies()-1";
        } else if (property === "target") {
            code = `${target}.targetguid()`;
        } else if (property == "time_to_die") {
            code = `${target}.TimeToDie()`;
        } else if (property === "distance") {
            code = `${target}.Distance()`;
        } else if (property === "is_boss") {
            code = `${target}.classification(worldboss)`;
        } else if (property === "health") {
            const modifier = tokenIterator();
            if (modifier === "pct") {
                code = `${target}.HealthPercent()`;
            }
        } else if (property === "cooldown") {
            const targetAction = tokenIterator();
            if (targetAction == "pause_action") {
                /* target.cooldown.pause_action.* should return values
                 * appropriate for the target never pausing on actions on
                 * the player.
                 */
                const actionProperty = tokenIterator();
                if (actionProperty == "duration") {
                    code = "0";
                } else if (actionProperty == "remains") {
                    code = "600";
                }
            }
        } else if (property) {
            const [percent] = match(property, "^time_to_pct_(%d+)");
            if (percent) {
                code = `${target}.TimeToHealthPercent(${percent})`;
            }
        }
        if (code) {
            [node] = this.ovaleAst.parseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }

        return node;
    };

    private emitOperandTotem: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "totem") {
            const name = lower(tokenIterator());
            const property = tokenIterator();
            let code;
            if (property == "active") {
                code = format("TotemPresent(%s)", name);
            } else if (property == "remains") {
                code = format("TotemRemaining(%s)", name);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private emitOperandTrinket: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        if (token == "trinket") {
            let procType = tokenIterator();
            let slot;
            if (procType === "1" || procType === "2") {
                slot = `trinket${tonumber(procType) - 1}slot`;
                procType = tokenIterator();
            }
            const statName = tokenIterator();
            let code;
            if (procType === "is" && slot && statName) {
                let [item] = this.disambiguate(
                    annotation,
                    `${statName}_item`,
                    annotation.classId,
                    annotation.specialization
                );
                code = `iteminslot("${slot}") == ${item}`;
                this.addSymbol(annotation, item);
            } else if (procType === "cooldown") {
                if (statName == "remains") {
                    code = emitTrinketCondition(
                        `ItemCooldown(slot="%s")`,
                        slot
                    );
                } else if (statName === "duration") {
                    code = emitTrinketCondition(
                        `ItemCooldownDuration(slot="%s")`,
                        slot
                    );
                } else if (statName === "ready") {
                    code = emitTrinketCondition(
                        `not ItemCooldown(slot="%s") > 0`,
                        slot
                    );
                }
            } else if (procType === "ready_cooldown") {
                // TODO The item internal cooldown is ready
                code = "0";
            } else if (procType === "has_cooldown") {
                code = emitTrinketCondition(
                    `ItemCooldownDuration(slot="%s")`,
                    slot
                );
            } else if (procType === "has_buff") {
                // TODO trinket.has_buff.<stat>
                code = "true";
            } else if (procType === "has_proc") {
                code = emitTrinketCondition(`ItemRppm(slot="%s") > 0`, slot);
            } else if (procType === "has_stat") {
                // TODO
                code = "false";
            } else if (procType === "has_use_buff") {
                /* TODO item has an on-use ability that applies a buff;
                 * if the item has a cooldown duration, then it is on-use;
                 * need to detect if it applies a buff.
                 */
                code = emitTrinketCondition(
                    `ItemCooldownDuration(slot="%s") > 0`,
                    slot
                );
            } else if (procType === "proc") {
                if (statName === "any_dps") {
                    const property = tokenIterator();
                    if (property == "duration") {
                        /* TODO duration of the on-use buff granted by the item;
                         * approximate as 30s for 3 minute CD.
                         */
                        code = emitTrinketCondition(
                            `30 * ItemCooldownDuration(slot="%s") / 180`,
                            slot
                        );
                    }
                }
                if (!code) {
                    // TODO trinket.proc.<stat>.<property>
                    code = "false";
                }
            } else {
                const property = statName;
                const [buffName] = this.disambiguate(
                    annotation,
                    procType + "_item",
                    annotation.classId,
                    annotation.specialization
                );
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
                }
                this.addSymbol(annotation, buffName);
            }
            if (code) {
                [node] = this.ovaleAst.parseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private emitOperandVariable: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        const tokenIterator = gmatch(operand, operandTokenPattern);
        const token = tokenIterator();
        let node: AstNode | undefined;
        if (token == "variable") {
            let name = tokenIterator();
            if (!name) {
                this.tracer.error(
                    "Unable to parse variable name in EmitOperandVariable"
                );
            } else {
                if (truthy(match(name, "^%d"))) name = "_" + name;
                if (
                    annotation.currentVariable &&
                    annotation.currentVariable.name == name
                ) {
                    const group = annotation.currentVariable.body;
                    if (lualength(group.child) == 0) {
                        [node] = this.ovaleAst.parseCode(
                            "expression",
                            "0",
                            nodeList,
                            annotation.astAnnotation
                        );
                    } else {
                        [node] = this.ovaleAst.parseCode(
                            "group",
                            this.ovaleAst.unparse(group),
                            nodeList,
                            annotation.astAnnotation
                        );
                    }
                } else {
                    node = this.ovaleAst.newNodeWithParameters(
                        "function",
                        annotation.astAnnotation
                    );
                    node.name = name;
                }
            }
        }
        return node;
    };

    private emitVisitors = {
        ["action"]: this.emitAction,
        ["action_list"]: this.emitActionList,
        ["operator"]: this.emitExpression,
        ["function"]: this.emitFunction,
        ["number"]: this.emitNumber,
        ["operand"]: this.emitOperand,
    };
}
