import {
    ParseNode,
    Annotation,
    Modifier,
    SPECIAL_ACTION,
    interruptsClasses,
    Modifiers,
    UNARY_OPERATOR,
    SimcBinaryOperatorType,
    BINARY_OPERATOR,
    SimcUnaryOperatorType,
    checkOptionalSkill,
    CHARACTER_PROPERTY,
    MISC_OPERAND,
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
import { Tracer, OvaleDebugClass } from "../engine/debug";
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
    LowerSpecialization,
    CamelCase,
    OvaleFunctionName,
} from "./text-tools";
import { POOLED_RESOURCE } from "../states/Power";
import { Unparser } from "./unparser";
import { isNumber, MakeString } from "../tools/tools";
import { ClassId } from "@wowts/wow-mock";
import { SpecializationName } from "../states/PaperDoll";

const OPERAND_TOKEN_PATTERN = "[^.]+";

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

type Disambiguations = LuaObj<LuaObj<LuaObj<{ 1: string; 2: string }>>>;

export class Emiter {
    private tracer: Tracer;
    private EMIT_DISAMBIGUATION: Disambiguations = {};

    constructor(
        ovaleDebug: OvaleDebugClass,
        private ovaleAst: OvaleASTClass,
        private ovaleData: OvaleDataClass,
        private unparser: Unparser
    ) {
        this.tracer = ovaleDebug.create("SimulationCraftEmiter");
    }

    private AddDisambiguation(
        name: string,
        info: string,
        className?: ClassId,
        specialization?: SpecializationName,
        _type?: string
    ) {
        this.AddPerClassSpecialization(
            this.EMIT_DISAMBIGUATION,
            name,
            info,
            className,
            specialization,
            _type
        );
    }

    private Disambiguate(
        annotation: Annotation,
        name: string,
        className: ClassId | "ALL_CLASSES",
        specialization: SpecializationName | "ALL_SPECIALIZATIONS",
        _type?: "spell" | "item"
    ): [string, string | undefined] {
        if (className && annotation.dictionary[`${name}_${className}`]) {
            return [`${name}_${className}`, _type];
        }
        if (
            specialization &&
            annotation.dictionary[`${name}_${specialization}`]
        ) {
            return [`${name}_${specialization}`, _type];
        }

        const [disname, distype] = this.GetPerClassSpecialization(
            this.EMIT_DISAMBIGUATION,
            name,
            className,
            specialization
        );
        if (!disname) {
            if (!annotation.dictionary[name]) {
                const otherName =
                    (truthy(match(name, "_buff$")) &&
                        gsub(name, "_buff$", "")) ||
                    (truthy(match(name, "_debuff$")) &&
                        gsub(name, "_debuff$", "")) ||
                    gsub(name, "_item$", "");
                if (annotation.dictionary[otherName]) {
                    return [otherName, _type];
                }
                const potionName = gsub(name, "potion_of_", "");
                if (annotation.dictionary[potionName]) {
                    return [potionName, _type];
                }
            }
            return [name, _type];
        }

        return [disname, distype];
    }

    private AddPerClassSpecialization(
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
    private GetPerClassSpecialization(
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

    public InitializeDisambiguation() {
        this.AddDisambiguation("none", "none");
        this.AddDisambiguation(
            "inevitable_demise_az_buff",
            "inevitable_demise_buff",
            "WARLOCK"
        );
        this.AddDisambiguation(
            "dark_soul",
            "dark_soul_misery",
            "WARLOCK",
            "affliction"
        );
        this.AddDisambiguation("flagellation_cleanse", "flagellation", "ROGUE");
        this.AddDisambiguation("ashvanes_razor_coral", "razor_coral");
        this.AddDisambiguation(
            "bok_proc_buff",
            "blackout_kick_aura",
            "MONK",
            "windwalker"
        );
        this.AddDisambiguation(
            "dance_of_chiji_azerite_buff",
            "dance_of_chiji_buff",
            "MONK",
            "windwalker"
        );
        this.AddDisambiguation(
            "energizing_elixer_talent",
            "energizing_elixir_talent",
            "MONK",
            "windwalker"
        );
        this.AddDisambiguation("blink_any", "blink", "MAGE");
        this.AddDisambiguation(
            "buff_disciplinary_command",
            "disciplinary_command",
            "MAGE"
        );
        this.AddDisambiguation(
            "disciplinary_command_arcane_buff",
            "disciplinary_command__arcane_aura_dnt",
            "MAGE"
        );
        this.AddDisambiguation(
            "disciplinary_command_fire_buff",
            "disciplinary_command__fire_aura_dnt",
            "MAGE"
        );
        this.AddDisambiguation(
            "disciplinary_command_frost_buff",
            "disciplinary_command__frost_aura_dnt",
            "MAGE"
        );
        this.AddDisambiguation(
            "hyperthread_wristwraps_300142",
            "hyperthread_wristwraps",
            "MAGE",
            "fire"
        );
        this.AddDisambiguation("use_mana_gem", "replenish_mana", "MAGE");
        this.AddDisambiguation(
            "unbridled_fury_buff",
            "potion_of_unbridled_fury"
        );
        this.AddDisambiguation("swipe_bear", "swipe", "DRUID");
        this.AddDisambiguation(
            "wound_spender",
            "scourge_strike",
            "DEATHKNIGHT"
        );
        this.AddDisambiguation("any_dnd", "death_and_decay", "DEATHKNIGHT");
        this.AddDisambiguation(
            "incarnation_talent",
            "incarnation_tree_of_life_talent",
            "DRUID",
            "restoration"
        );
        this.AddDisambiguation(
            "incarnation_talent",
            "incarnation_guardian_of_ursoc_talent",
            "DRUID",
            "guardian"
        );
        this.AddDisambiguation(
            "incarnation_talent",
            "incarnation_chosen_of_elune_talent",
            "DRUID",
            "balance"
        );
        this.AddDisambiguation(
            "incarnation_talent",
            "incarnation_king_of_the_jungle_talent",
            "DRUID",
            "feral"
        );
        this.AddDisambiguation("ca_inc", "celestial_alignment", "DRUID");
        this.AddDisambiguation(
            "adaptive_swarm_heal",
            "adaptive_swarm",
            "DRUID"
        );
    }

    /** Transform a ParseNode to an AstNode
     * @param parseNode The ParseNode to transform
     * @param nodeList The list of AstNode. Any created node will be added to this array.
     * @param action The current Simulationcraft action, or undefined if in a condition modifier
     */
    Emit(
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action: string | undefined
    ) {
        // TODO
        const visitor = this.EMIT_VISITOR[
            parseNode.type
        ] as EmitVisitor<ParseNode>;
        if (!visitor) {
            this.tracer.Error(
                "Unable to emit node of type '%s'.",
                parseNode.type
            );
        } else {
            return visitor(parseNode, nodeList, annotation, action);
        }
    }

    private AddSymbol(annotation: Annotation, symbol: string) {
        const symbolTable = annotation.symbolTable || {};
        const symbolList = annotation.symbolList || {};
        if (
            !symbolTable[symbol] &&
            !this.ovaleData.DEFAULT_SPELL_LIST[symbol]
        ) {
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
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const miscOperand = tokenIterator();
        const info = MISC_OPERAND[miscOperand];
        if (info) {
            let modifier = tokenIterator();
            if (info.code) {
                if (info.symbolsInCode) {
                    for (const [_, symbol] of ipairs(info.symbolsInCode)) {
                        annotation.AddSymbol(symbol);
                    }
                    const [result] = this.ovaleAst.ParseCode(
                        "expression",
                        info.code,
                        nodeList,
                        annotation.astAnnotation
                    );
                    if (result) return result;
                    return undefined;
                }
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
                    result.rawNamedParams[
                        info.extraNamedParameter.name
                    ] = this.ovaleAst.newValue(
                        annotation.astAnnotation,
                        info.extraNamedParameter.value
                    );
                } else {
                    result.rawNamedParams[
                        info.extraNamedParameter.name
                    ] = this.ovaleAst.newString(
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
                annotation.AddSymbol(info.extraSymbol);
            }
            while (modifier) {
                if (!info.modifiers && info.symbol === undefined) {
                    this.tracer.Warning(
                        `Use of ${modifier} for ${operand} but no modifier has been registered`
                    );
                    this.ovaleAst.Release(result);
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
                                annotation.AddSymbol(symbol);
                            }
                        }
                        this.ovaleAst.Release(result);
                        const [newCode] = this.ovaleAst.ParseCode(
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
                        annotation.AddSymbol(modifierName);
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
                        annotation.AddSymbol(modifierParameters.extraSymbol);
                    }
                } else if (info.symbol !== undefined) {
                    if (info.symbol !== "") {
                        modifier = `${modifier}_${info.symbol}`;
                    }
                    [modifier] = this.Disambiguate(
                        annotation,
                        modifier,
                        annotation.classId,
                        annotation.specialization
                    );
                    this.AddSymbol(annotation, modifier);
                    insert(
                        result.rawPositionalParams,
                        this.ovaleAst.newVariable(
                            annotation.astAnnotation,
                            modifier
                        )
                    );
                } else {
                    this.tracer.Warning(
                        `Modifier parameters not found for ${modifier} in ${result.name}`
                    );
                    this.ovaleAst.Release(result);
                    return undefined;
                }

                modifier = tokenIterator();
            }

            return result;
        }

        return undefined;
    }

    private EmitModifier = (
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
            node = this.Emit(parseNode, nodeList, annotation, action);
        } else if (modifier == "target_if") {
            node = this.Emit(parseNode, nodeList, annotation, action);
        } else if (modifier == "five_stacks" && action == "focus_fire") {
            const value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                const buffName = "pet_frenzy_buff";
                this.AddSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= 5", buffName);
            }
        } else if (modifier == "line_cd") {
            if (!SPECIAL_ACTION[action]) {
                this.AddSymbol(annotation, action);
                const node = this.Emit(parseNode, nodeList, annotation, action);
                if (!node) return undefined;
                const expressionCode = this.ovaleAst.Unparse(node);
                code = format(
                    "TimeSincePreviousSpell(%s) > %s",
                    action,
                    expressionCode
                );
            }
        } else if (modifier == "max_cycle_targets") {
            const [debuffName] = this.Disambiguate(
                annotation,
                `${action}_debuff`,
                className,
                specialization
            );
            this.AddSymbol(annotation, debuffName);
            const node = this.Emit(parseNode, nodeList, annotation, action);
            if (!node) return undefined;
            const expressionCode = this.ovaleAst.Unparse(node);
            code = format(
                "DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s",
                debuffName,
                debuffName,
                expressionCode
            );
        } else if (modifier == "max_energy") {
            const value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                code = format("Energy() >= EnergyCost(%s max=1)", action);
            }
        } else if (modifier == "min_frenzy" && action == "focus_fire") {
            const value = tonumber(this.unparser.Unparse(parseNode));
            if (value) {
                const buffName = "pet_frenzy_buff";
                this.AddSymbol(annotation, buffName);
                code = format("pet.BuffStacks(%s) >= %d", buffName, value);
            }
        } else if (modifier == "moving") {
            const value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 0) {
                code = "not Speed() > 0";
            } else {
                code = "Speed() > 0";
            }
        } else if (modifier == "precombat") {
            const value = tonumber(this.unparser.Unparse(parseNode));
            if (value == 1) {
                code = "not InCombat()";
            } else {
                code = "InCombat()";
            }
        } else if (modifier == "sync") {
            let name = this.unparser.Unparse(parseNode);
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
                    const syncActionNode = this.EmitAction(
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
                                const notNode = this.ovaleAst.newNodeWithChildren(
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
                            this.tracer.Print(
                                "Warning: Unable to emit action for 'sync=%s'.",
                                name
                            );
                            [name] = this.Disambiguate(
                                annotation,
                                name,
                                className,
                                specialization
                            );
                            this.AddSymbol(annotation, name);
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
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };

    private EmitConditionNode = (
        nodeList: LuaArray<AstNode>,
        bodyNode: AstNode,
        extraConditionNode: AstNode | undefined,
        parseNode: ActionParseNode,
        annotation: Annotation,
        action: string,
        modifiers: Modifiers
    ) => {
        let conditionNode = undefined;
        for (const [modifier, expressionNode] of kpairs(parseNode.modifiers)) {
            const rhsNode = this.EmitModifier(
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

    private EmitNamedVariable = (
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
            this.Emit(modifiers.value, nodeList, annotation, action);
        const newNode = this.EmitConditionNode(
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

    private EmitVariableMin = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        this.EmitNamedVariable(
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
        const [node] = this.ovaleAst.ParseCode(
            "add_function",
            bodyCode,
            nodeList,
            annotation.astAnnotation
        );
        if (node) {
            annotation.variable[name] = node as AstAddFunctionNode;
        }
    };

    private EmitVariableMax = (
        name: string,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string
    ) => {
        this.EmitNamedVariable(
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
        const [node] = this.ovaleAst.ParseCode(
            "add_function",
            bodyCode,
            nodeList,
            annotation.astAnnotation
        );
        if (node) {
            annotation.variable[name] = node as AstAddFunctionNode;
        }
    };

    private EmitVariableAdd = (
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
        this.EmitNamedVariable(
            name,
            nodeList,
            annotation,
            modifiers,
            parseNode,
            action
        );
    };

    private EmitVariableSub = (
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
        this.EmitNamedVariable(
            name,
            nodeList,
            annotation,
            modifiers,
            parseNode,
            action
        );
    };

    private EmitVariableIf = (
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
            this.tracer.Error("Modifier missing in if");
            return;
        }

        const ifNode = this.ovaleAst.newNodeWithChildren(
            "if",
            annotation.astAnnotation
        );
        const condition = this.Emit(
            modifiers.condition,
            nodeList,
            annotation,
            undefined
        );
        const value = this.Emit(
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
        const valueElse = this.Emit(
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
            (modifiers.op && this.unparser.Unparse(modifiers.op)) || "min";
        if (!modifiers.name) {
            this.tracer.Error("Modifier name is missing in %s", action);
            return;
        }
        const name = this.unparser.Unparse(modifiers.name);
        if (!name) {
            this.tracer.Error(
                "Unable to parse name of variable in %s",
                modifiers.name
            );
            return;
        }
        if (op === "min" || op === "max") {
            // TODO
            this.EmitVariableAdd(
                name,
                nodeList,
                annotation,
                modifiers,
                parseNode,
                action
            );
        } else {
            this.tracer.Error(`Unknown cycling_variable operator ${op}`);
        }
    }

    private EmitVariable = (
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        modifier: Modifiers,
        parseNode: ActionParseNode,
        action: string,
        conditionNode?: AstNode
    ) => {
        const op = (modifier.op && this.unparser.Unparse(modifier.op)) || "set";
        if (!modifier.name) {
            this.tracer.Error("Modifier name is missing in %s", action);
            return;
        }
        let name = this.unparser.Unparse(modifier.name);
        if (!name) {
            this.tracer.Error(
                "Unable to parse name of variable in %s",
                modifier.name
            );
            return;
        }
        if (truthy(match(name, "^%d"))) {
            name = "_" + name;
        }
        if (op == "min") {
            this.EmitVariableMin(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "max") {
            this.EmitVariableMax(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "add") {
            this.EmitVariableAdd(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op == "set" || op === "reset") {
            this.EmitNamedVariable(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action,
                conditionNode
            );
        } else if (op === "setif") {
            this.EmitVariableIf(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else if (op === "sub") {
            this.EmitVariableSub(
                name,
                nodeList,
                annotation,
                modifier,
                parseNode,
                action
            );
        } else {
            this.tracer.Error("Unknown variable operator '%s'.", op);
        }
    };

    /** Takes a ParseNode of type "action" and transforms it to an AstNode. */
    private EmitAction: EmitVisitor<ActionParseNode> = (
        parseNode,
        nodeList,
        annotation
    ) => {
        let node: AstNode | undefined;
        const canonicalizedName = lower(gsub(parseNode.name, ":", "_"));
        const className = annotation.classId;
        const specialization = annotation.specialization;
        const camelSpecialization = LowerSpecialization(annotation);
        const role = annotation.role;
        let [action, type] = this.Disambiguate(
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
                action == "snapshot_stats"
            )
        ) {
            // Most of this code is obsolete and should be cleaned or dispatched in the correct function
            let bodyCode, conditionCode;
            const expressionType = "expression";
            const modifiers = parseNode.modifiers;
            let isSpellAction = true;
            if (
                interruptsClasses[action as keyof typeof interruptsClasses] ===
                className
            ) {
                bodyCode = `${camelSpecialization}InterruptActions()`;
                annotation[
                    action as keyof typeof interruptsClasses
                ] = className;
                annotation.interrupt = className;
                isSpellAction = false;
            } else if (
                className === "DEMONHUNTER" &&
                action === "pick_up_fragment"
            ) {
                bodyCode = "texture(spell_shadow_soulgem text=pickup)";
                conditionCode = "soulfragments() > 0";
                isSpellAction = false;
            } else if (className == "DRUID" && action == "pulverize") {
                const debuffName = "thrash_bear_debuff";
                this.AddSymbol(annotation, debuffName);
                conditionCode = format(
                    "target.DebuffGain(%s) <= BaseDuration(%s)",
                    debuffName,
                    debuffName
                );
            } else if (
                className == "DRUID" &&
                specialization == "guardian" &&
                action == "rejuvenation"
            ) {
                const spellName = "enhanced_rejuvenation";
                this.AddSymbol(annotation, spellName);
                conditionCode = format("SpellKnown(%s)", spellName);
            } else if (className == "DRUID" && action == "wild_charge") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (className == "DRUID" && action == "new_moon") {
                conditionCode =
                    "not SpellKnown(half_moon) and not SpellKnown(full_moon)";
                this.AddSymbol(annotation, "half_moon");
                this.AddSymbol(annotation, "full_moon");
            } else if (className == "DRUID" && action == "half_moon") {
                conditionCode = "SpellKnown(half_moon)";
            } else if (className == "DRUID" && action == "full_moon") {
                conditionCode = "SpellKnown(full_moon)";
            } else if (
                className == "DRUID" &&
                action == "regrowth" &&
                specialization == "feral"
            ) {
                conditionCode =
                    "Talent(bloodtalons_talent) and (BuffRemaining(bloodtalons_buff) < CastTime(regrowth)+GCDRemaining() or InCombat())";
                this.AddSymbol(annotation, "bloodtalons_talent");
                this.AddSymbol(annotation, "bloodtalons_buff");
                this.AddSymbol(annotation, "regrowth");
            } else if (className == "HUNTER" && action == "kill_command") {
                conditionCode =
                    "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()";
            } else if (className == "MAGE" && action == "arcane_brilliance") {
                conditionCode =
                    "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)";
            } else if (className == "MAGE" && truthy(find(action, "pet_"))) {
                conditionCode = "pet.Present()";
            } else if (
                className == "MAGE" &&
                (action == "start_burn_phase" ||
                    action == "start_pyro_chain" ||
                    action == "stop_burn_phase" ||
                    action == "stop_pyro_chain")
            ) {
                const [stateAction, stateVariable] = match(
                    action,
                    "([^_]+)_(.*)"
                );
                const value = (stateAction == "start" && 1) || 0;
                if (value == 0) {
                    conditionCode = format("GetState(%s) > 0", stateVariable);
                } else {
                    conditionCode = format(
                        "not GetState(%s) > 0",
                        stateVariable
                    );
                }
                bodyCode = format("SetState(%s %d)", stateVariable, value);
                isSpellAction = false;
            } else if (className == "MAGE" && action == "time_warp") {
                conditionCode =
                    "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)";
                annotation[action] = className;
            } else if (
                className == "MAGE" &&
                action == "summon_water_elemental"
            ) {
                conditionCode = "not pet.Present()";
            } else if (className == "MAGE" && action == "ice_floes") {
                conditionCode = "Speed() > 0";
            } else if (className == "MAGE" && action == "blast_wave") {
                conditionCode = "target.Distance(less 8)";
            } else if (className == "MAGE" && action == "dragons_breath") {
                conditionCode = "target.Distance(less 12)";
            } else if (className == "MAGE" && action == "arcane_blast") {
                conditionCode = "Mana() > ManaCost(arcane_blast)";
            } else if (className == "MAGE" && action == "cone_of_cold") {
                conditionCode = "target.Distance() < 12";
            } else if (className == "MONK" && action == "chi_sphere") {
                isSpellAction = false;
            } else if (className == "MONK" && action == "gift_of_the_ox") {
                isSpellAction = false;
            } else if (className == "MONK" && action == "nimble_brew") {
                conditionCode = "IsFeared() or IsRooted() or IsStunned()";
            } else if (
                className == "MONK" &&
                action == "storm_earth_and_fire"
            ) {
                conditionCode =
                    "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire)";
                annotation[action] = className;
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
                className == "MONK" &&
                action == "whirling_dragon_punch"
            ) {
                conditionCode =
                    "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0";
            } else if (
                className == "PALADIN" &&
                action == "blessing_of_kings"
            ) {
                conditionCode = "BuffExpires(mastery_buff)";
            } else if (className == "PALADIN" && action == "judgment") {
                if (modifiers.cycle_targets) {
                    this.AddSymbol(annotation, action);
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
                    lethal = this.unparser.Unparse(modifiers.lethal);
                } else if (specialization == "assassination") {
                    lethal = "deadly";
                } else {
                    lethal = "instant";
                }
                action = `${lethal}_poison`;
                const buffName = "lethal_poison_buff";
                this.AddSymbol(annotation, buffName);
                conditionCode = format(
                    "BuffRemaining(%s) < 1200",
                    buffName
                );
            } else if (className == "ROGUE" && action == "cancel_autoattack") {
                isSpellAction = false;
            } else if (className == "ROGUE" && action == "premeditation") {
                conditionCode = "ComboPoints() < 5";
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
                const [buffName] = this.Disambiguate(
                    annotation,
                    `${action}_buff`,
                    className,
                    specialization
                );
                this.AddSymbol(annotation, buffName);
                conditionCode = format("BuffExpires(%s)", buffName);
            } else if (className == "SHAMAN" && action == "bloodlust") {
                bodyCode = `${camelSpecialization}Bloodlust()`;
                annotation[action] = className;
                isSpellAction = false;
            } else if (className == "SHAMAN" && action == "magma_totem") {
                const spellName = "primal_strike";
                this.AddSymbol(annotation, spellName);
                conditionCode = format("target.InRange(%s)", spellName);
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
                    this.AddSymbol(annotation, spellName);
                    bodyCode = format("Spell(%s)", spellName);
                } else {
                    bodyCode =
                        "Texture(spell_nature_removecurse help=ServicePet)";
                }
                isSpellAction = false;
            } else if (className == "WARLOCK" && action == "summon_pet") {
                if (annotation.pet) {
                    const spellName = `summon_${annotation.pet}`;
                    this.AddSymbol(annotation, spellName);
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
            } else if (
                className == "WARRIOR" &&
                action == "battle_shout" &&
                role == "tank"
            ) {
                conditionCode = "BuffExpires(stamina_buff)";
            } else if (className == "WARRIOR" && action == "charge") {
                conditionCode =
                    "CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel)";
                this.AddSymbol(annotation, "pummel");
            } else if (
                className == "WARRIOR" &&
                action == "commanding_shout" &&
                role == "attack"
            ) {
                conditionCode = "BuffExpires(attack_power_multiplier_buff)";
            } else if (
                className == "WARRIOR" &&
                action == "enraged_regeneration"
            ) {
                conditionCode = "HealthPercent() < 80";
            } else if (
                className == "WARRIOR" &&
                sub(action, 1, 7) == "execute"
            ) {
                if (modifiers.target) {
                    const target = tonumber(
                        this.unparser.Unparse(modifiers.target)
                    );
                    if (target) {
                        isSpellAction = false;
                    }
                }
            } else if (className == "WARRIOR" && action == "heroic_charge") {
                isSpellAction = false;
            } else if (className == "WARRIOR" && action == "heroic_leap") {
                conditionCode =
                    "CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40)";
            } else if (action == "auto_attack") {
                bodyCode = `${camelSpecialization}GetInMeleeRange()`;
                isSpellAction = false;
            } else if (
                className == "DEMONHUNTER" &&
                action == "metamorphosis_havoc"
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
                this.EmitVariable(
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
                    const name = this.unparser.Unparse(modifiers.name);
                    if (name) {
                        const functionName = OvaleFunctionName(
                            name,
                            annotation
                        );
                        bodyCode = `${functionName}()`;
                        if (
                            className == "MAGE" &&
                            specialization == "arcane" &&
                            (name == "burn" || name == "init_burn")
                        ) {
                            conditionCode =
                                "CheckBoxOn(opt_arcane_mage_burn_phase)";
                            if (!annotation.options) annotation.options = {};
                            annotation.options[
                                "opt_arcane_mage_burn_phase"
                            ] = true;
                        }
                    }
                    isSpellAction = false;
                }
            } else if (action == "cancel_buff") {
                if (modifiers.name) {
                    const spellName = this.unparser.Unparse(modifiers.name);
                    if (spellName) {
                        const [buffName] = this.Disambiguate(
                            annotation,
                            `${spellName}_buff`,
                            className,
                            specialization,
                            "spell"
                        );
                        this.AddSymbol(annotation, spellName);
                        this.AddSymbol(annotation, buffName);
                        bodyCode = format("Texture(%s text=cancel)", spellName);
                        conditionCode = format("BuffPresent(%s)", buffName);
                        isSpellAction = false;
                    }
                }
            } else if (action === "cancel_action") {
                bodyCode = "texture(INV_Pet_ExitBattle text=cancel)";
                isSpellAction = false;
            } else if (action == "pool_resource") {
                bodyNode = this.ovaleAst.NewNode(
                    "simc_pool_resource",
                    annotation.astAnnotation
                );
                bodyNode.for_next = modifiers.for_next != undefined;
                if (modifiers.extra_amount) {
                    bodyNode.extra_amount = tonumber(
                        this.unparser.Unparse(modifiers.extra_amount)
                    );
                }
                isSpellAction = false;
            } else if (action == "potion") {
                let name =
                    (modifiers.name && this.unparser.Unparse(modifiers.name)) ||
                    annotation.consumables["potion"];
                if (name) {
                    if (name === "disabled") {
                        return undefined;
                    }
                    [name] = this.Disambiguate(
                        annotation,
                        `${name}_item`,
                        className,
                        specialization,
                        "item"
                    );
                    bodyCode = format("Item(%s usable=1)", name);
                    conditionCode =
                        "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)";
                    annotation.opt_use_consumables = className;
                    this.AddSymbol(annotation, name);
                    isSpellAction = false;
                }
            } else if (action === "sequence" || action == "strict_sequence") {
                // TODO doesn't seem to be supported
                isSpellAction = false;
            } else if (action == "stance") {
                if (modifiers.choose) {
                    const name = this.unparser.Unparse(modifiers.choose);
                    if (name) {
                        if (className == "MONK") {
                            action = `stance_of_the_${name}`;
                        } else if (className == "WARRIOR") {
                            action = `${name}_stance`;
                        } else {
                            action = name;
                        }
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
                let legendaryRing: string | undefined = undefined;
                // TODO use modifiers.slots
                if (modifiers.slot) {
                    // use this slot only?
                    const slot = this.unparser.Unparse(modifiers.slot);
                    if (slot && truthy(match(slot, "finger"))) {
                        [legendaryRing] = this.Disambiguate(
                            annotation,
                            "legendary_ring",
                            className,
                            specialization
                        );
                    }
                } else if (modifiers.name) {
                    let name = this.unparser.Unparse(modifiers.name);
                    if (name) {
                        [name] = this.Disambiguate(
                            annotation,
                            name,
                            className,
                            specialization
                        );
                        if (truthy(match(name, "legendary_ring"))) {
                            legendaryRing = name;
                        }
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
                    const seconds = tonumber(
                        this.unparser.Unparse(modifiers.sec)
                    );
                    if (!seconds) {
                        bodyNode = this.ovaleAst.newNodeWithChildren(
                            "simc_wait",
                            annotation.astAnnotation
                        );
                        const expressionNode = this.Emit(
                            modifiers.sec,
                            nodeList,
                            annotation,
                            action
                        );
                        if (expressionNode) {
                            const code = this.ovaleAst.Unparse(expressionNode);
                            conditionCode = code + " > 0";
                        }
                    }
                }
                isSpellAction = false;
            } else if (action == "heart_essence") {
                bodyCode = `Spell(296208)`;
                isSpellAction = false;
            } else if (parseNode.actionListName === "precombat") {
                const definition = annotation.dictionary[action];
                if (isNumber(definition)) {
                    const spellInfo = this.ovaleData.GetSpellInfo(definition);
                    if (spellInfo && spellInfo.aura) {
                        for (const [, info] of kpairs(
                            spellInfo.aura.player.HELPFUL
                        )) {
                            if (info.buffSpellId) {
                                const buffSpellInfo = this.ovaleData.GetSpellInfo(
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
                this.AddSymbol(annotation, action);
                if (modifiers.target) {
                    let actionTarget = this.unparser.Unparse(modifiers.target);
                    if (actionTarget == "2") {
                        actionTarget = "other";
                    }
                    if (actionTarget != "1") {
                        bodyCode = format(
                            "%s(%s text=%s)",
                            type,
                            action,
                            actionTarget
                        );
                    }
                }
                bodyCode = bodyCode || `${type}(${action})`;
            }
            if (!bodyNode && bodyCode) {
                [bodyNode] = this.ovaleAst.ParseCode(
                    expressionType,
                    bodyCode,
                    nodeList,
                    annotation.astAnnotation
                );
            }
            if (!conditionNode && conditionCode) {
                [conditionNode] = this.ovaleAst.ParseCode(
                    expressionType,
                    conditionCode,
                    nodeList,
                    annotation.astAnnotation
                );
            }
            if (bodyNode) {
                node = this.EmitConditionNode(
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

    public EmitActionList: EmitVisitor<ActionListParseNode> = (
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
            const commentNode = this.ovaleAst.NewNode(
                "comment",
                annotation.astAnnotation
            );
            commentNode.comment = actionNode.action;
            child[lualength(child) + 1] = commentNode;
            if (emit) {
                const statementNode = this.EmitAction(
                    actionNode,
                    nodeList,
                    annotation,
                    actionNode.name
                );
                if (statementNode) {
                    if (statementNode.type == "simc_pool_resource") {
                        const powerType = POOLED_RESOURCE[annotation.classId];
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
                        const powerType = CamelCase(poolResourceNode.powerType);
                        const extra_amount = poolResourceNode.extra_amount;
                        if (extra_amount && poolingConditionNode) {
                            let code = this.ovaleAst.Unparse(
                                poolingConditionNode
                            );
                            const extraAmountPattern =
                                powerType + "%(%) >= [%d.]+";
                            const replaceString = format(
                                "always(pool_%s %d)",
                                poolResourceNode.powerType,
                                extra_amount
                            );
                            code = gsub(
                                code,
                                extraAmountPattern,
                                replaceString
                            );
                            [poolingConditionNode] = this.ovaleAst.ParseCode(
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
                            const name = this.ovaleAst.Unparse(
                                bodyNode.rawPositionalParams[1]
                            );
                            let powerCondition;
                            if (extra_amount) {
                                powerCondition = format(
                                    "TimeTo%s(%d)",
                                    powerType,
                                    extra_amount
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
                            let [conditionNode] = this.ovaleAst.ParseCode(
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
                                    conditionNode = this.ovaleAst.newNodeWithChildren(
                                        "logical",
                                        annotation.astAnnotation
                                    );
                                    conditionNode.expressionType = "binary";
                                    conditionNode.operator = "and";
                                    conditionNode.child[1] = poolingConditionNode;
                                    conditionNode.child[2] = rhsNode;
                                }
                                let restNodeType: "if" | "unless";
                                if (statementNode.type == "unless") {
                                    restNodeType = "if";
                                } else {
                                    restNodeType = "unless";
                                }

                                const restNode = this.ovaleAst.newNodeWithChildren(
                                    restNodeType,
                                    annotation.astAnnotation
                                );
                                child[lualength(child) + 1] = restNode;
                                restNode.child[1] = conditionNode;
                                restNode.child[2] = this.ovaleAst.newNodeWithChildren(
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
                            statementNode.child[2] = this.ovaleAst.newNodeWithChildren(
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
        node.name = OvaleFunctionName(parseNode.name, annotation);
        return node;
    };

    private EmitExpression: EmitVisitor<OperatorParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let msg;
        if (parseNode.expressionType == "unary") {
            const opInfo =
                UNARY_OPERATOR[parseNode.operator as SimcUnaryOperatorType];
            if (opInfo) {
                let operator: OperatorType | undefined;
                if (parseNode.operator == "!") {
                    operator = "not";
                } else if (parseNode.operator == "-") {
                    operator = parseNode.operator;
                }
                if (operator) {
                    const rhsNode = this.Emit(
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
                BINARY_OPERATOR[parseNode.operator as SimcBinaryOperatorType];
            if (opInfo) {
                const parseNodeOperator = parseNode.operator as SimcBinaryOperatorType;
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
                        this.AddSymbol(annotation, name);
                    }

                    if (parseNode.operator == "!=") {
                        code = "not " + code;
                    }
                    annotation.astAnnotation = annotation.astAnnotation || {};
                    [node] = this.ovaleAst.ParseCode(
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
                    [node] = this.ovaleAst.ParseCode(
                        "expression",
                        code,
                        nodeList,
                        annotation.astAnnotation
                    );
                } else if (operator) {
                    const lhsNode = this.Emit(
                        parseNode.child[1],
                        nodeList,
                        annotation,
                        action
                    );
                    const rhsNode = this.Emit(
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
                        msg = MakeString(
                            "Warning: %s operator '%s' right failed.",
                            parseNode.type,
                            parseNode.operator
                        );
                    } else if (rhsNode) {
                        msg = MakeString(
                            "Warning: %s operator '%s' left failed.",
                            parseNode.type,
                            parseNode.operator
                        );
                    } else {
                        msg = MakeString(
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
                MakeString(
                    "Warning: Operator '%s' is not implemented.",
                    parseNode.operator
                );
            this.tracer.Print(msg);
            const stringNode = this.ovaleAst.NewNode(
                "string",
                annotation.astAnnotation
            );
            stringNode.value = `FIXME_${parseNode.operator}`;
            return stringNode;
        }
        return node;
    };

    private EmitFunction: EmitVisitor<FunctionParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        if (parseNode.name == "ceil" || parseNode.name == "floor") {
            node = this.Emit(parseNode.child[1], nodeList, annotation, action);
        } else {
            this.tracer.Print(
                "Warning: Function '%s' is not implemented.",
                parseNode.name
            );
            node = this.ovaleAst.NewNode("variable", annotation.astAnnotation);
            node.name = `FIXME_${parseNode.name}`;
        }
        return node;
    };

    private EmitNumber: EmitVisitor<NumberParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        const node = this.ovaleAst.NewNode("value", annotation.astAnnotation);
        node.value = parseNode.value;
        node.origin = 0;
        node.rate = 0;
        return node;
    };
    private EmitOperand: EmitVisitor<OperandParseNode> = (
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        let operand = parseNode.name;
        let [token] = match(operand, OPERAND_TOKEN_PATTERN);
        let target: string | undefined;
        if (token == "target" || token === "self") {
            node = this.EmitOperandTarget(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
            if (!node) {
                target = token;
                operand = sub(operand, len(target) + 2);
                [token] = match(operand, OPERAND_TOKEN_PATTERN);
            }
        }

        if (!node) {
            node = this.EmitOperandRune(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.EmitOperandSpecial(
                operand,
                parseNode,
                nodeList,
                annotation,
                action,
                target
            );
        }
        if (!node) {
            node = this.EmitOperandRaidEvent(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.EmitOperandRace(
                operand,
                parseNode,
                nodeList,
                annotation,
                action
            );
        }
        if (!node) {
            node = this.EmitOperandAction(
                operand,
                parseNode,
                nodeList,
                annotation,
                action,
                target
            );
        }
        if (!node) {
            node = this.EmitOperandCharacter(
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
                node = this.EmitOperandActiveDot(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "aura") {
                node = this.EmitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "azerite") {
                node = this.EmitOperandAzerite(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "buff") {
                node = this.EmitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "consumable") {
                node = this.EmitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "cooldown") {
                node = this.EmitOperandCooldown(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "debuff") {
                target = target || "target";
                node = this.EmitOperandBuff(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "disease") {
                target = target || "target";
                node = this.EmitOperandDisease(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "dot") {
                target = target || "target";
                node = this.EmitOperandDot(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "essence") {
                node = this.EmitOperandEssence(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            } else if (token == "glyph") {
                node = this.EmitOperandGlyph(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "pet") {
                node = this.EmitOperandPet(
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
                node = this.EmitOperandPreviousSpell(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "refreshable") {
                node = this.EmitOperandRefresh(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "seal") {
                node = this.EmitOperandSeal(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "set_bonus") {
                node = this.EmitOperandSetBonus(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token === "stack") {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    `buffstacks(${action})`,
                    nodeList,
                    annotation.astAnnotation
                );
            } else if (token == "talent") {
                node = this.EmitOperandTalent(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "totem") {
                node = this.EmitOperandTotem(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "trinket") {
                node = this.EmitOperandTrinket(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "variable") {
                node = this.EmitOperandVariable(
                    operand,
                    parseNode,
                    nodeList,
                    annotation,
                    action
                );
            } else if (token == "ground_aoe") {
                node = this.EmitOperandGroundAoe(
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
            this.tracer.Print(
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

    private EmitOperandAction: EmitOperandVisitor = (
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
            const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
        [name] = this.Disambiguate(annotation, name, className, specialization);
        target = (target && `${target}.`) || "";
        let buffName = `${name}_debuff`;
        [buffName] = this.Disambiguate(
            annotation,
            buffName,
            className,
            specialization
        );
        const buffSpellId = annotation.dictionary[buffName];
        let prefix;
        let buffTarget;
        if (buffSpellId && isNumber(buffSpellId)) {
            const buffSpellInfo = this.ovaleData.GetSpellInfo(buffSpellId);
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
        [talentName] = this.Disambiguate(
            annotation,
            talentName,
            className,
            specialization
        );
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
                code = format("ItemCooldown(trinket0slot)");
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
            code = format("ExecuteTime(%s)", name);
        } else if (property == "executing") {
            code = format("ExecuteTime(%s) > 0", name);
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
            if (IsTotem(name)) {
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
                this.tracer.Print(
                    "Warning: dubious use of call_action_list in %s",
                    code
                );
            }
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
            if (!SPECIAL_ACTION[symbol]) {
                this.AddSymbol(annotation, symbol);
            }
        }
        return node;
    };
    private EmitOperandActiveDot: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "active_dot") {
            let name = tokenIterator();
            [name] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let dotName = `${name}_debuff`;
            [dotName] = this.Disambiguate(
                annotation,
                dotName,
                annotation.classId,
                annotation.specialization
            );
            const prefix =
                (truthy(find(dotName, "_buff$")) && "Buff") || "Debuff";
            target = (target && `${target}.`) || "";
            const code = format("%sCountOnAny(%s)", prefix, dotName);
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, dotName);
            }
        }
        return node;
    };

    private EmitOperandAzerite: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, `${name}_trait`);
            }
        }
        return node;
    };

    private EmitOperandEssence: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "essence") {
            let code;
            const name = tokenIterator();
            const property = tokenIterator();

            let essenceId = format("%s_essence_id", name);
            [essenceId] = this.Disambiguate(
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, essenceId);
            }
        }
        return node;
    };

    private EmitOperandRefresh: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "refreshable") {
            let buffName = `${action}_debuff`;
            [buffName] = this.Disambiguate(
                annotation,
                buffName,
                annotation.classId,
                annotation.specialization
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
                (this.ovaleData.DEFAULT_SPELL_LIST[buffName] && " any=1") || "";
            const code = format("%sRefreshable(%s%s)", target, buffName, any);
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
            this.AddSymbol(annotation, buffName);
        }
        return node;
    };

    private isDaemon(name: string) {
        return name === "vilefiend" || name === "wild_imps";
    }

    private EmitOperandBuff: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
            if (name === "out_of_range") {
                if (property == "up") {
                    code = "not target.inrange()";
                }
            } else if (this.isDaemon(name)) {
                buffName = name;
                if (property === "remains") {
                    code = `demonduration(${buffName})`;
                } else if (property === "stack") {
                    code = `demons(${buffName})`;
                }
            } else if (name === "arcane_charge") {
                if (property === "stack") {
                    code = "arcanecharges()";
                } else if (property === "max_stack") {
                    code = "maxarcanecharges()";
                }
            } else {
                // buffname
                [name] = this.Disambiguate(
                    annotation,
                    name,
                    annotation.classId,
                    annotation.specialization
                );
                buffName =
                    (token == "debuff" && `${name}_debuff`) || `${name}_buff`;
                [buffName] = this.Disambiguate(
                    annotation,
                    buffName,
                    annotation.classId,
                    annotation.specialization
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
                    (this.ovaleData.DEFAULT_SPELL_LIST[buffName] && " any=1") ||
                    "";

                // target
                target = (target && `${target}.`) || "";
                if (buffName == "dark_transformation_buff" && target == "") {
                    target = "pet.";
                }
                if (buffName == "pet_beast_cleave_buff" && target == "") {
                    target = "pet.";
                }
                if (buffName == "pet_frenzy_buff" && target == "") {
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (buffName) this.AddSymbol(annotation, buffName);
            }
        }
        return node;
    };

    private EmitOperandCharacter: EmitOperandVisitor = (
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
        const camelSpecialization = LowerSpecialization(annotation);
        target = (target && `${target}.`) || "";
        let code;
        if (CHARACTER_PROPERTY[operand]) {
            code = `${target}${CHARACTER_PROPERTY[operand]}`;
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
        } else if (
            className == "PRIEST" &&
            operand == "shadowy_apparitions_in_flight"
        ) {
            code = "1";
        } else if (operand == "rtb_buffs") {
            code = "BuffCount(roll_the_bones_buff)";
        } else if (className == "ROGUE" && operand == "anticipation_charges") {
            const name = "anticipation_buff";
            code = format("BuffStacks(%s)", name);
            this.AddSymbol(annotation, name);
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
            if (weaponType == "1h") {
                code = "HasWeapon(main type=one_handed)";
            } else if (weaponType == "2h") {
                code = "HasWeapon(main type=two_handed)";
            }
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
            code = "Enemies()";
        } else if (operand == "t18_class_trinket") {
            code = format("HasTrinket(%s)", operand);
            this.AddSymbol(annotation, operand);
        }
        if (code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };

    private EmitOperandCooldown: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();

        if (token == "cooldown") {
            let name = tokenIterator();
            const property = tokenIterator();
            let prefix;
            [name, prefix] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization,
                "spell"
            );
            let code;
            if (property == "execute_time") {
                code = format("ExecuteTime(%s)", name);
            } else if (property == "duration") {
                code = format("%sCooldownDuration(%s)", prefix, name);
            } else if (property == "ready") {
                code = format("%sCooldown(%s) == 0", prefix, name);
            } else if (
                property == "remains" ||
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, name);
            }
        }
        return node;
    };
    private EmitOperandDisease: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private EmitOperandGroundAoe: EmitOperandVisitor = (
        operand: string,
        parseNode: ParseNode,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation,
        action?: string
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "ground_aoe") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let dotName = `${name}_debuff`;
            [dotName] = this.Disambiguate(
                annotation,
                dotName,
                annotation.classId,
                annotation.specialization
            );
            const prefix =
                (truthy(find(dotName, "_buff$")) && "Buff") || "Debuff";
            const target = (prefix == "Debuff" && "target.") || "";
            let code;
            if (property == "remains") {
                code = format("%s%sRemaining(%s)", target, prefix, dotName);
            }
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, dotName);
            }
        }
        return node;
    };

    private EmitOperandDot: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action,
        target
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "dot") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let dotName;
            if (truthy(match(name, "_dot$"))) {
                dotName = gsub(name, "_dot$", "_debuff");
            } else {
                dotName = `${name}_debuff`;
            }
            [dotName] = this.Disambiguate(
                annotation,
                dotName,
                annotation.classId,
                annotation.specialization
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, dotName);
            }
        }
        return node;
    };
    private EmitOperandGlyph: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "glyph") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            let glyphName = `glyph_of_${name}`;
            [glyphName] = this.Disambiguate(
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, glyphName);
            }
        }
        return node;
    };
    private EmitOperandPet: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "pet") {
            let name = tokenIterator();
            const property = tokenIterator();
            [name] = this.Disambiguate(
                annotation,
                name,
                annotation.classId,
                annotation.specialization
            );
            const isTotem = IsTotem(name);
            let code;
            if (isTotem && property == "active") {
                code = format("TotemPresent(%s)", name);
            } else if (isTotem && property == "remains") {
                code = format("TotemRemaining(%s)", name);
            } else if (property == "active") {
                code = "pet.Present()";
            } else if (name == "buff") {
                const pattern = format("^pet%%.([%%w_.]+)", operand);
                const [petOperand] = match(operand, pattern);
                node = this.EmitOperandBuff(
                    petOperand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    "pet"
                );
            } else {
                const pattern = format("^pet%%.%s%%.([%%w_.]+)", name);
                let [petOperand] = match(operand, pattern);
                const target = "pet";
                if (petOperand) {
                    node = this.EmitOperandSpecial(
                        petOperand,
                        parseNode,
                        nodeList,
                        annotation,
                        action,
                        target
                    );
                    if (!node) {
                        node = this.EmitOperandAction(
                            petOperand,
                            parseNode,
                            nodeList,
                            annotation,
                            action,
                            target
                        );
                    }
                    if (!node) {
                        node = this.EmitOperandCharacter(
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
                        [petAbilityName] = this.Disambiguate(
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
                            node = this.EmitOperandBuff(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action,
                                target
                            );
                        } else if (property == "cooldown") {
                            node = this.EmitOperandCooldown(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action
                            );
                        } else if (property == "debuff") {
                            node = this.EmitOperandBuff(
                                petOperand,
                                parseNode,
                                nodeList,
                                annotation,
                                action,
                                target
                            );
                        } else if (property == "dot") {
                            node = this.EmitOperandDot(
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
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (isTotem) this.AddSymbol(annotation, name);
            }
        }
        return node;
    };
    private EmitOperandPreviousSpell: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
            let name = tokenIterator();
            let howMany = 1;
            if (tonumber(name)) {
                howMany = tonumber(name);
                name = tokenIterator();
            }
            [name] = this.Disambiguate(
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, name);
            }
        }
        return node;
    };
    private EmitOperandRaidEvent: EmitOperandVisitor = (
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
            const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
            tokenIterator();
            name = tokenIterator();
            property = tokenIterator();
        } else {
            const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
        }
        if (code) {
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private EmitOperandRace: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
                    this.tracer.Print("Warning: Race '%s' not defined", race);
                }
                code = format("Race(%s)", raceId);
            }
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };
    private EmitOperandRune: EmitOperandVisitor = (
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
        [node] = this.ovaleAst.ParseCode(
            "expression",
            code,
            nodeList,
            annotation.astAnnotation
        );
        return node;
    };
    private EmitOperandSetBonus: EmitOperandVisitor = (
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
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private EmitOperandSeal: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "seal") {
            const name = lower(tokenIterator());
            let code;
            if (name) {
                code = format("Stance(paladin_seal_of_%s)", name);
            }
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };
    private EmitOperandSpecial: EmitOperandVisitor = (
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
        if (
            className == "DEATHKNIGHT" &&
            operand == "dot.breath_of_sindragosa.ticking"
        ) {
            const buffName = "breath_of_sindragosa";
            code = format("BuffPresent(%s)", buffName);
            this.AddSymbol(annotation, buffName);
        } else if (
            className == "DEATHKNIGHT" &&
            sub(operand, 1, 24) == "pet.dancing_rune_weapon."
        ) {
            const petOperand = sub(operand, 25);
            const tokenIterator = gmatch(petOperand, OPERAND_TOKEN_PATTERN);
            const token = tokenIterator();
            if (token == "active") {
                const buffName = "dancing_rune_weapon_buff";
                code = format("BuffPresent(%s)", buffName);
                this.AddSymbol(annotation, buffName);
            } else if (token == "dot") {
                if (target == "") {
                    target = "target";
                } else {
                    target = sub(target, 1, -2);
                }
                node = this.EmitOperandDot(
                    petOperand,
                    parseNode,
                    nodeList,
                    annotation,
                    action,
                    target
                );
            }
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
                "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0";
            this.AddSymbol(annotation, "chaos_blades_talent");
            this.AddSymbol(annotation, "chaos_blades");
        } else if (
            className == "DEMONHUNTER" &&
            operand == "cooldown.nemesis.ready"
        ) {
            code = "Talent(nemesis_talent) and SpellCooldown(nemesis) == 0";
            this.AddSymbol(annotation, "nemesis_talent");
            this.AddSymbol(annotation, "nemesis");
        } else if (
            className == "DEMONHUNTER" &&
            operand == "cooldown.metamorphosis.ready" &&
            specialization == "havoc"
        ) {
            code =
                "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis) == 0";
            this.AddSymbol(annotation, "metamorphosis");
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
            this.AddSymbol(annotation, spellName);
        } else if (className == "DRUID" && operand == "solar_wrath.ap_check") {
            const spellName = "solar_wrath";
            code = format("AstralPower() >= AstralPowerCost(%s)", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "DRUID" && operand == "starfire.ap_check") {
            const spellName = "starfire";
            code = format("AstralPower() >= AstralPowerCost(%s)", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "buff.careful_aim.up") {
            code =
                "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)";
            this.AddSymbol(annotation, "rapid_fire_buff");
        } else if (
            className == "HUNTER" &&
            operand == "buff.stampede.remains"
        ) {
            const spellName = "stampede";
            code = format("TimeSincePreviousSpell(%s) < 40", spellName);
            this.AddSymbol(annotation, spellName);
        } else if (className == "HUNTER" && operand == "lowest_vuln_within.5") {
            code = "target.DebuffRemaining(vulnerable)";
            this.AddSymbol(annotation, "vulnerable");
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
            this.AddSymbol(annotation, "careful_aim_talent");
        } else if (
            className == "MAGE" &&
            operand == "buff.rune_of_power.remains"
        ) {
            code = "TotemRemaining(rune_of_power)";
        } else if (className == "MAGE" && operand == "buff.shatterlance.up") {
            code =
                "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)";
            this.AddSymbol(annotation, "frostbolt");
            this.AddSymbol(annotation, "t18_class_trinket");
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
            this.AddSymbol(annotation, "firestarter_talent");
        } else if (className == "MAGE" && operand == "brain_freeze_active") {
            code = "target.DebuffPresent(winters_chill_debuff)";
            this.AddSymbol(annotation, "winters_chill_debuff");
        } else if (
            className == "MAGE" &&
            operand == "action.frozen_orb.in_flight"
        ) {
            code = "TimeSincePreviousSpell(frozen_orb) < 10";
            this.AddSymbol(annotation, "frozen_orb");
        } else if (
            className == "MONK" &&
            sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target."
        ) {
            const property = sub(operand, 36);
            if (target == "") {
                target = "target.";
            }
            const debuffName = "storm_earth_and_fire_target_debuff";
            this.AddSymbol(annotation, debuffName);
            if (property == "down") {
                code = format("%sDebuffExpires(%s)", target, debuffName);
            } else if (property == "up") {
                code = format("%sDebuffPresent(%s)", target, debuffName);
            }
        } else if (className == "MONK" && operand == "dot.zen_sphere.ticking") {
            const buffName = "zen_sphere_buff";
            code = format("BuffPresent(%s)", buffName);
            this.AddSymbol(annotation, buffName);
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
            this.AddSymbol(annotation, "spinning_crane_kick");
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
            this.AddSymbol(annotation, buffName);
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
            this.AddSymbol(annotation, "draught_of_souls");
        } else if (className == "ROGUE" && operand == "mantle_duration") {
            code = "BuffRemaining(master_assassins_initiative)";
            this.AddSymbol(annotation, "master_assassins_initiative");
        } else if (className == "ROGUE" && operand == "poisoned_enemies") {
            code = "0";
        } else if (className == "ROGUE" && operand == "poisoned_bleeds") {
            code =
                "DebuffCountOnAny(rupture) + DebuffCountOnAny(garrote) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)";
            this.AddSymbol(annotation, "rupture");
            this.AddSymbol(annotation, "garrote");
            this.AddSymbol(annotation, "internal_bleeding_talent");
            this.AddSymbol(annotation, "internal_bleeding_debuff");
        } else if (className == "ROGUE" && operand == "exsanguinated") {
            code = "target.DebuffPresent(exsanguinated)";
            this.AddSymbol(annotation, "exsanguinated");
        }
        // TODO: has garrote been casted out of stealth with shrouded suffocation azerite trait?
        else if (className == "ROGUE" && operand == "ss_buffed") {
            code = "never(ss_buffed)";
        } else if (className == "ROGUE" && operand == "non_ss_buffed_targets") {
            code = "Enemies() - DebuffCountOnAny(garrote)";
            this.AddSymbol(annotation, "garrote");
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
            this.AddSymbol(annotation, "master_assassin_buff");
        } else if (
            className == "ROGUE" &&
            operand == "buff.roll_the_bones.remains"
        ) {
            code = "BuffRemaining(roll_the_bones_buff)";
            this.AddSymbol(annotation, "roll_the_bones_buff");
        } else if (
            className == "ROGUE" &&
            operand == "buff.roll_the_bones.up"
        ) {
            code = "BuffPresent(roll_the_bones_buff)";
            this.AddSymbol(annotation, "roll_the_bones_buff");
        } else if (
            className == "SHAMAN" &&
            operand == "buff.resonance_totem.remains"
        ) {
            const [spell] = this.Disambiguate(
                annotation,
                "totem_mastery",
                annotation.classId,
                annotation.specialization
            );
            code = format("TotemRemaining(%s)", spell);
            this.AddSymbol(annotation, spell);
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
                this.AddSymbol(annotation, spellName);
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
            this.AddSymbol(annotation, "wild_imp");
            this.AddSymbol(annotation, "wild_imp_inner_demons");
        } else if (
            className == "WARLOCK" &&
            operand == "buff.dreadstalkers.remains"
        ) {
            code = "DemonDuration(dreadstalker)";
            this.AddSymbol(annotation, "dreadstalker");
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
            this.AddSymbol(annotation, "havoc");
        } else if (className == "WARLOCK" && operand == "havoc_remains") {
            code = "DebuffRemainingOnAny(havoc)";
            this.AddSymbol(annotation, "havoc");
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
        } else if (operand == "debuff.casting.react") {
            code = `${target}IsInterruptible()`;
        } else if (operand == "debuff.casting.up") {
            const t = (target == "" && "target.") || target;
            code = `${t}IsInterruptible()`;
        } else if (operand == "distance") {
            code = `${target}Distance()`;
        } else if (sub(operand, 1, 9) == "equipped.") {
            const [name] = this.Disambiguate(
                annotation,
                `${sub(operand, 10)}_item`,
                className,
                specialization
            );
            const itemId = tonumber(name);
            const itemName = name;
            const item = (itemId && tostring(itemId)) || itemName;
            code = format("HasEquippedItem(%s)", item);
            this.AddSymbol(annotation, item);
        } else if (operand == "gcd.max") {
            code = "GCD()";
        } else if (operand == "gcd.remains") {
            code = "GCDRemaining()";
        } else if (sub(operand, 1, 15) == "legendary_ring.") {
            const [name] = this.Disambiguate(
                annotation,
                "legendary_ring",
                className,
                specialization
            );
            const buffName = `${name}_buff`;
            const properties = sub(operand, 16);
            const tokenIterator = gmatch(properties, OPERAND_TOKEN_PATTERN);
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
            const [aplName] = match(operand, "^using_apl%.([%w_]+)");
            code = format("List(opt_using_apl %s)", aplName);
            annotation.using_apl = annotation.using_apl || {};
            annotation.using_apl[aplName] = true;
        } else if (operand == "cooldown.buff_sephuzs_secret.remains") {
            code = "BuffCooldown(sephuzs_secret_buff)";
            this.AddSymbol(annotation, "sephuzs_secret_buff");
        } else if (operand == "is_add") {
            const t = target || "target.";
            code = format("not %sClassification(worldboss)", t);
        } else if (operand == "priority_rotation") {
            code = "CheckBoxOn(opt_priority_rotation)";
            annotation.opt_priority_rotation = className;
        }
        if (code) {
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }
        return node;
    };
    private EmitOperandTalent: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "talent") {
            const name = lower(tokenIterator());
            const property = tokenIterator();
            let talentName = `${name}_talent`;
            [talentName] = this.Disambiguate(
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
            } else if (property == "enabled") {
                if (parseNode.asType == "boolean") {
                    code = format("HasTalent(%s)", talentName);
                } else {
                    code = format("TalentPoints(%s)", talentName);
                }
            }
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                this.AddSymbol(annotation, talentName);
            }
        }
        return node;
    };

    private EmitOperandTarget: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let target = tokenIterator();
        if (target === "self") target = "player";
        let property = tokenIterator();
        let howMany = 1;
        if (tonumber(property)) {
            howMany = tonumber(property);
            property = tokenIterator();
        }
        if (howMany > 1) {
            this.tracer.Print(
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
        } else if (property) {
            const [percent] = match(property, "^time_to_pct_(%d+)");
            if (percent) {
                code = `${target}.TimeToHealthPercent(${percent})`;
            }
        }
        if (code) {
            [node] = this.ovaleAst.ParseCode(
                "expression",
                code,
                nodeList,
                annotation.astAnnotation
            );
        }

        return node;
    };

    private EmitOperandTotem: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
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
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private EmitOperandTrinket: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        let node: AstNode | undefined;
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        if (token == "trinket") {
            let procType = tokenIterator();
            if (procType === "1" || procType === "2") {
                procType = tokenIterator(); // TODO use trinket slot?
            }
            const statName = tokenIterator();
            let code;
            if (procType === "cooldown") {
                if (statName == "remains") {
                    code =
                        "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }";
                }
            } else if (procType === "has_cooldown") {
                code =
                    "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }";
            } else if (sub(procType, 1, 4) == "has_") {
                code = format("always(trinket_%s_%s)", procType, statName);
            } else {
                const property = statName;
                const [buffName] = this.Disambiguate(
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
                this.AddSymbol(annotation, buffName);
            }
            if (code) {
                [node] = this.ovaleAst.ParseCode(
                    "expression",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
            }
        }
        return node;
    };

    private EmitOperandVariable: EmitOperandVisitor = (
        operand,
        parseNode,
        nodeList,
        annotation,
        action
    ) => {
        const tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        const token = tokenIterator();
        let node: AstNode | undefined;
        if (token == "variable") {
            let name = tokenIterator();
            if (!name) {
                this.tracer.Error(
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
                        [node] = this.ovaleAst.ParseCode(
                            "expression",
                            "0",
                            nodeList,
                            annotation.astAnnotation
                        );
                    } else {
                        [node] = this.ovaleAst.ParseCode(
                            "group",
                            this.ovaleAst.Unparse(group),
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

    private EMIT_VISITOR = {
        ["action"]: this.EmitAction,
        ["action_list"]: this.EmitActionList,
        ["operator"]: this.EmitExpression,
        ["function"]: this.EmitFunction,
        ["number"]: this.EmitNumber,
        ["operand"]: this.EmitOperand,
    };
}
