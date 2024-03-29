import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { l } from "../ui/Localization";
import { OvaleClass } from "../Ovale";
import { AstNode, AstAnnotation, OvaleASTClass } from "../engine/ast";
import { Controls } from "../engine/controls";
import { format, gmatch, gsub, lower, match, sub } from "@wowts/string";
import {
    ipairs,
    pairs,
    tonumber,
    type,
    wipe,
    LuaObj,
    LuaArray,
    lualength,
    truthy,
    kpairs,
} from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import { RAID_CLASS_COLORS, ClassId } from "@wowts/wow-mock";
import { isLuaArray } from "../tools/tools";
import { OvaleOptionsClass } from "../ui/Options";
import {
    Annotation,
    Profile,
    ParseNode,
    consumableItems,
    ovaleIconTags,
    classInfos,
    ActionListParseNode,
    DbcData,
} from "./definitions";
import { OvaleDataClass } from "../engine/data";
import { Emiter } from "./emiter";
import {
    printRepeat,
    toOvaleFunctionName,
    toOvaleTaggedFunctionName,
    outputPool,
    toLowerSpecialization,
    toCamelCase,
} from "./text-tools";
import { Parser } from "./parser";
import { Unparser } from "./unparser";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleCompileClass } from "../engine/compile";
import { Splitter } from "./splitter";
import { Generator, markNode, sweepNode } from "./generator";
import { AceModule } from "@wowts/tsaddon";
import { OptionUiAll } from "../ui/acegui-helpers";

let lastSimC = "";
let lastScript = "";

const name = "OvaleSimulationCraft";

export class OvaleSimulationCraftClass {
    private tracer: Tracer;
    private module: AceModule;
    constructor(
        private ovaleOptions: OvaleOptionsClass,
        private ovaleData: OvaleDataClass,
        private emiter: Emiter,
        private ovaleAst: OvaleASTClass,
        private parser: Parser,
        private unparser: Unparser,
        private ovaleDebug: DebugTools,
        private ovaleCompile: OvaleCompileClass,
        private splitter: Splitter,
        private generator: Generator,
        private ovale: OvaleClass,
        private controls: Controls
    ) {
        this.registerOptions();
        this.module = ovale.createModule(
            "OvaleSimulationCraft",
            this.handleInitialize,
            this.handleDisable
        );
        this.tracer = ovaleDebug.create("SimulationCraft");
    }

    public addSymbol(annotation: Annotation, symbol: string) {
        const symbolTable = annotation.symbolTable || {};
        const symbolList = annotation.symbolList;
        if (!symbolTable[symbol] && !this.ovaleData.defaultSpellLists[symbol]) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        annotation.symbolTable = symbolTable;
        annotation.symbolList = symbolList;
    }

    private registerOptions() {
        const actions: LuaObj<OptionUiAll> = {
            simc: {
                name: "SimulationCraft",
                type: "execute",
                func: function () {
                    const appName = name;
                    AceConfigDialog.SetDefaultSize(appName, 700, 550);
                    AceConfigDialog.Open(appName);
                },
            },
        };
        for (const [k, v] of pairs(actions)) {
            this.ovaleOptions.actions.args[k] = v;
        }

        const defaultDB = {
            overrideCode: "",
        };
        for (const [k, v] of pairs(defaultDB)) {
            (<any>this.ovaleOptions.defaultDB.profile)[k] = v;
        }
    }

    private handleInitialize = () => {
        this.emiter.initializeDisambiguation();
        this.createOptions();
    };

    private handleDisable = () => {};
    // DebuggingInfo() {
    //     self_pool.DebuggingInfo();
    //     self_childrenPool.DebuggingInfo();
    //     self_outputPool.DebuggingInfo();
    // }
    toString(tbl: AstNode) {
        const output = printRepeat(tbl);
        return concat(output, "\n");
    }
    release(profile: Profile) {
        if (profile.annotation) {
            const annotation = profile.annotation;
            if (annotation.astAnnotation) {
                this.ovaleAst.releaseAnnotation(annotation.astAnnotation);
            }
            if (annotation.nodeList) {
                this.parser.release(annotation.nodeList);
            }
            for (const [key, value] of kpairs(annotation)) {
                if (type(value) == "table") {
                    wipe(value);
                }
                delete annotation[key];
            }
        }
        wipe(profile);
    }

    private readProfile(simc: string) {
        const parsedProfile: LuaObj<any> = {};
        for (const _line of gmatch(simc, "[^\r\n]+")) {
            const [line] = match(_line, "^%s*(.-)%s*$");
            if (!(truthy(match(line, "^#.*")) || truthy(match(line, "^$")))) {
                const [k, operator, value] = match(line, "([^%+=]+)(%+?=)(.*)");
                const key = <keyof Profile>k;
                if (operator == "=") {
                    (<any>parsedProfile)[key] = value;
                } else if (operator == "+=") {
                    if (type(parsedProfile[key]) != "table") {
                        const oldValue = parsedProfile[key];
                        (<any>parsedProfile[key]) = {};
                        insert(<LuaArray<any>>parsedProfile[key], oldValue);
                    }
                    insert(<LuaArray<any>>parsedProfile[key], value);
                }
            }
        }
        for (const [k, v] of kpairs(parsedProfile)) {
            if (isLuaArray(v)) {
                (<any>parsedProfile)[k] = concat(<any>v);
            }
        }
        parsedProfile.templates = {};
        for (const [k] of kpairs(parsedProfile)) {
            if (sub(<string>k, 1, 2) == "$(" && sub(<string>k, -1) == ")") {
                insert(parsedProfile.templates, k);
            }
        }

        return parsedProfile as Profile;
    }

    parseProfile(
        simc: string,
        dictionary?: LuaObj<number | string>,
        dbc?: DbcData
    ) {
        const profile = this.readProfile(simc);

        let classId: ClassId | undefined = undefined;
        let name: string | undefined = undefined;

        for (const [className] of kpairs(RAID_CLASS_COLORS)) {
            const lowerClass = <keyof Profile>lower(<string>className);
            if (profile[lowerClass]) {
                classId = className as ClassId;
                name = <string>profile[lowerClass];
            }
        }

        if (!classId || !name || !profile.spec) {
            return undefined;
        }

        const annotation = new Annotation(
            this.ovaleData,
            name,
            classId,
            profile.spec
        );
        if (dbc) annotation.dbc = dbc;
        if (dictionary) annotation.dictionary = dictionary;
        profile.annotation = annotation;

        let ok = true;

        // Parse the different "actions" commands in the script. Save them as ParseNode action_list
        const nodeList: LuaArray<ParseNode> = {};
        const actionList: LuaArray<ActionListParseNode> = {};
        for (const [k, _v] of kpairs(profile)) {
            let v = _v;
            if (ok && truthy(match(k, "^actions"))) {
                let [name] = match(k, "^actions%.([%w_]+)");
                if (!name) {
                    name = "_default";
                }
                for (
                    let index = lualength(profile.templates);
                    index >= 1;
                    index += -1
                ) {
                    const template = profile.templates[index];
                    const variable = sub(template, 3, -2);
                    const pattern = `%$%(${variable}%)`;
                    v = gsub(<string>v, pattern, <string>profile[template]);
                }
                const node = this.parser.parseActionList(
                    name,
                    <string>v,
                    nodeList,
                    annotation
                );
                if (node) {
                    actionList[lualength(actionList) + 1] = node;
                } else {
                    this.tracer.error(
                        `Error while parsing action list ${name}`
                    );
                    break;
                }
            }
        }
        sort(actionList, function (a, b) {
            return a.name < b.name;
        });

        annotation.specialization = profile.spec;
        annotation.level = profile.level;
        ok =
            ok &&
            annotation.classId !== undefined &&
            annotation.specialization !== undefined &&
            annotation.level !== undefined;
        annotation.pet = profile.default_pet;
        const consumables = annotation.consumables;
        for (const [k, v] of pairs(consumableItems)) {
            if (v) {
                if (profile[<keyof Profile>k] != undefined) {
                    consumables[k] = <string>profile[<keyof Profile>k];
                }
            }
        }
        if (profile.role == "tank") {
            annotation.role = profile.role;
            annotation.melee = annotation.classId;
        } else if (profile.role == "spell") {
            annotation.role = profile.role;
            annotation.ranged = annotation.classId;
        } else if (profile.role == "attack" || profile.role == "dps") {
            annotation.role = "attack";
            if (profile.position == "ranged_back") {
                annotation.ranged = annotation.classId;
            } else {
                annotation.melee = annotation.classId;
            }
        }
        annotation.position = profile.position;
        const taggedFunctionName: LuaObj<boolean> =
            annotation.taggedFunctionName;
        for (const [, node] of ipairs(actionList)) {
            const fname = toOvaleFunctionName(node.name, annotation);
            taggedFunctionName[fname] = true;
            for (const [, tag] of pairs(ovaleIconTags)) {
                const [bodyName, conditionName] = toOvaleTaggedFunctionName(
                    fname,
                    tag
                );
                if (bodyName && conditionName) {
                    taggedFunctionName[lower(bodyName)] = true;
                    taggedFunctionName[lower(conditionName)] = true;
                }
            }
        }
        annotation.functionTag = {};
        profile.actionList = actionList;
        profile.annotation = annotation;
        annotation.nodeList = nodeList;
        if (!ok) {
            this.release(profile);
            return undefined;
        }
        return profile;
    }
    unparse(profile: Profile) {
        const output = outputPool.get();
        if (profile.actionList) {
            for (const [, node] of ipairs(profile.actionList)) {
                output[lualength(output) + 1] =
                    this.unparser.unparse(node) || "";
            }
        }
        const s = concat(output, "\n");
        outputPool.release(output);
        return s;
    }
    emitAST(profile: Profile) {
        const nodeList = {};
        const ast = this.ovaleAst.newNodeWithChildren(
            "script",
            profile.annotation.astAnnotation
        );
        const child = ast.child;
        const annotation = profile.annotation;
        let ok = true;
        if (profile.actionList) {
            if (annotation.astAnnotation) {
                annotation.astAnnotation.nodeList = nodeList;
            } else {
                annotation.astAnnotation = {
                    nodeList: nodeList,
                    definition: annotation.dictionary,
                };
            }

            this.ovaleDebug.resetTrace();
            const dictionaryAnnotation: AstAnnotation = {
                nodeList: {},
                definition: profile.annotation.dictionary,
            };
            const dictionaryFormat = `
            Include(ovale_common)
            Include(ovale_%s_spells)
            %s
        `;
            const dictionaryCode = format(
                dictionaryFormat,
                lower(annotation.classId),
                this.ovaleOptions.db.profile.overrideCode || ""
            );
            const [dictionaryAST] = this.ovaleAst.parseCode(
                "script",
                dictionaryCode,
                dictionaryAnnotation.nodeList,
                dictionaryAnnotation
            );
            if (dictionaryAST && dictionaryAST.type == "script") {
                dictionaryAST.annotation = dictionaryAnnotation;
                annotation.dictionaryAST = dictionaryAST;
                annotation.dictionary = dictionaryAnnotation.definition;
                this.ovaleAst.propagateConstants(dictionaryAST);
                this.ovaleAst.propagateStrings(dictionaryAST);
                // this.ovaleAst.FlattenParameters(dictionaryAST);
                this.controls.reset();
                this.ovaleCompile.evaluateScript(dictionaryAST, true);
            }

            for (const [, node] of ipairs(profile.actionList)) {
                const addFunctionNode = this.emiter.emitActionList(
                    node,
                    nodeList,
                    annotation,
                    undefined
                );
                if (
                    addFunctionNode &&
                    addFunctionNode.type === "add_function"
                ) {
                    // Add interrupt if not already added
                    if (node.name === "_default" && !annotation.interrupt) {
                        const defaultInterrupt =
                            classInfos[annotation.classId][
                                annotation.specialization
                            ];
                        if (defaultInterrupt && defaultInterrupt.interrupt) {
                            const interruptCall =
                                this.ovaleAst.newNodeWithParameters(
                                    "custom_function",
                                    annotation.astAnnotation
                                );
                            interruptCall.name = lower(
                                toLowerSpecialization(annotation) +
                                    "InterruptActions"
                            );
                            annotation.interrupt = annotation.classId;
                            annotation[defaultInterrupt.interrupt] =
                                annotation.classId;
                            insert(
                                addFunctionNode.body.child,
                                1,
                                interruptCall
                            );
                        }
                    }

                    const actionListName = gsub(node.name, "^_+", "");
                    const commentNode = this.ovaleAst.newNode(
                        "comment",
                        annotation.astAnnotation
                    );
                    commentNode.comment = `## actions.${actionListName}`;
                    child[lualength(child) + 1] = commentNode;
                    for (const [, tag] of pairs(ovaleIconTags)) {
                        const [bodyNode, conditionNode] =
                            this.splitter.splitByTag(
                                tag,
                                addFunctionNode,
                                nodeList,
                                annotation
                            );
                        if (bodyNode && conditionNode) {
                            child[lualength(child) + 1] = bodyNode;
                            child[lualength(child) + 1] = conditionNode;
                        }
                    }
                } else {
                    ok = false;
                    break;
                }
            }
        }
        if (ok) {
            annotation.supportingFunctionCount =
                this.generator.insertSupportingFunctions(child, annotation);
            annotation.supportingInterruptCount =
                (annotation.interrupt &&
                    this.generator.insertInterruptFunctions(
                        child,
                        annotation
                    )) ||
                undefined;
            annotation.supportingControlCount =
                this.generator.insertSupportingControls(child, annotation);
            // annotation.supportingDefineCount = InsertSupportingDefines(child, annotation);
            this.generator.insertVariables(child, annotation);
            const [className, specialization] = [
                annotation.classId,
                annotation.specialization,
            ];
            const lowerclass = lower(className);
            const aoeToggle = `opt_${lowerclass}_${specialization}_aoe`;
            {
                const commentNode = this.ovaleAst.newNode(
                    "comment",
                    annotation.astAnnotation
                );
                commentNode.comment = `## ${toCamelCase(
                    specialization
                )} icons.`;
                insert(child, commentNode);
                const code = format(
                    "AddCheckBox(%s L(AOE) default enabled=(specialization(%s)))",
                    aoeToggle,
                    specialization
                );
                const [node] = this.ovaleAst.parseCode(
                    "checkbox",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon enabled=(not checkboxon(%s) and specialization(%s)) enemies=1 help=shortcd
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    aoeToggle,
                    specialization,
                    this.generator.generateIconBody("shortcd", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon enabled=(checkboxon(%s) and specialization(%s)) help=shortcd
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    aoeToggle,
                    specialization,
                    this.generator.generateIconBody("shortcd", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon enemies=1 help=main enabled=(specialization(%s))
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    specialization,
                    this.generator.generateIconBody("main", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon help=aoe enabled=(checkboxon(%s) and specialization(%s))
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    aoeToggle,
                    specialization,
                    this.generator.generateIconBody("main", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon enemies=1 help=cd enabled=(not checkboxon(%s) and specialization(%s))
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    aoeToggle,
                    specialization,
                    this.generator.generateIconBody("cd", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            {
                const fmt = `
				AddIcon enabled=(checkboxon(%s) and specialization(%s)) help=cd
				{
					%s
				}
			`;
                const code = format(
                    fmt,
                    aoeToggle,
                    specialization,
                    this.generator.generateIconBody("cd", profile)
                );
                const [node] = this.ovaleAst.parseCode(
                    "icon",
                    code,
                    nodeList,
                    annotation.astAnnotation
                );
                if (node) insert(child, node);
            }
            markNode(ast);
            let [changed] = sweepNode(ast);
            while (changed) {
                markNode(ast);
                [changed] = sweepNode(ast);
            }
            markNode(ast);
            sweepNode(ast);
        }
        if (!ok) {
            this.ovaleAst.release(ast);
            return undefined;
        }
        return ast;
    }
    emit(profile: Profile, noFinalNewLine?: boolean) {
        const ast = this.emitAST(profile);
        if (!ast) return "error";
        const annotation = profile.annotation;
        const className = annotation.classId;
        const lowerclass = lower(className);
        const specialization = annotation.specialization;
        const output = outputPool.get();
        {
            output[
                lualength(output) + 1
            ] = `# Based on SimulationCraft profile ${annotation.name}.`;
            output[lualength(output) + 1] = `#	class=${lowerclass}`;
            output[lualength(output) + 1] = `#	spec=${specialization}`;
            if (profile.talents) {
                output[lualength(output) + 1] = `#	talents=${profile.talents}`;
            }
            if (profile.glyphs) {
                output[lualength(output) + 1] = `#	glyphs=${profile.glyphs}`;
            }
            if (profile.default_pet) {
                output[lualength(output) + 1] = `#	pet=${profile.default_pet}`;
            }
        }
        {
            output[lualength(output) + 1] = "";
            output[lualength(output) + 1] = "Include(ovale_common)";
            output[lualength(output) + 1] = format(
                "Include(ovale_%s_spells)",
                lowerclass
            );
            const overrideCode = this.ovaleOptions.db.profile.overrideCode;
            if (overrideCode && overrideCode != "") {
                output[lualength(output) + 1] = "";
                output[lualength(output) + 1] = "# Overrides.";
                output[lualength(output) + 1] = overrideCode;
            }
            if (
                annotation.supportingControlCount &&
                annotation.supportingControlCount > 0
            ) {
                output[lualength(output) + 1] = "";
            }
        }
        output[lualength(output) + 1] = this.ovaleAst.unparse(ast);
        if (profile.annotation.symbolTable) {
            output[lualength(output) + 1] = "";
            output[lualength(output) + 1] = "### Required symbols";
            sort(profile.annotation.symbolList);

            for (const [, symbol] of ipairs(profile.annotation.symbolList)) {
                if (
                    !tonumber(symbol) &&
                    !profile.annotation.dictionary[symbol] &&
                    !this.ovaleData.buffSpellList[symbol]
                ) {
                    this.tracer.print(
                        "Warning: Symbol '%s' not defined",
                        symbol
                    );
                }
                output[lualength(output) + 1] = `# ${symbol}`;
            }
        }
        annotation.dictionary = {};
        if (annotation.dictionaryAST) {
            this.ovaleAst.release(annotation.dictionaryAST);
        }
        if (!noFinalNewLine && output[lualength(output)] != "") {
            output[lualength(output) + 1] = "";
        }
        const s = concat(output, "\n");
        outputPool.release(output);
        this.ovaleAst.release(ast);
        return s;
    }
    createOptions() {
        const options = {
            name: `${this.ovale.GetName()} SimulationCraft`,
            type: "group",
            args: {
                input: {
                    order: 10,
                    name: l["input"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: `${l["simulationcraft_profile_content"]}\nhttps://code.google.com/p/simulationcraft/source/browse/profiles`,
                            type: "description",
                        },
                        input: {
                            order: 20,
                            name: l["simulationcraft_profile"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: () => {
                                return lastSimC;
                            },
                            set: (info: any, value: string) => {
                                lastSimC = value;
                                const profile = this.parseProfile(lastSimC);
                                let code = "";
                                if (profile) {
                                    code = this.emit(profile);
                                }
                                lastScript = gsub(code, "\t", "    ");
                            },
                        },
                    },
                },
                overrides: {
                    order: 20,
                    name: l["overrides"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: l["simulationcraft_overrides_description"],
                            type: "description",
                        },
                        overrides: {
                            order: 20,
                            name: l["overrides"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: () => {
                                const code = this.ovaleOptions.db.profile.code;
                                return gsub(code, "\t", "    ");
                            },
                            set: (info: any, value: string) => {
                                this.ovaleOptions.db.profile.overrideCode =
                                    value;
                                if (lastSimC) {
                                    const profile = this.parseProfile(lastSimC);
                                    let code = "";
                                    if (profile) {
                                        code = this.emit(profile);
                                    }
                                    lastScript = gsub(code, "\t", "    ");
                                }
                            },
                        },
                    },
                },
                output: {
                    order: 30,
                    name: l["output"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: l["simulationcraft_profile_translated"],
                            type: "description",
                        },
                        output: {
                            order: 20,
                            name: l["script"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: function () {
                                return lastScript;
                            },
                        },
                    },
                },
            },
        };
        const appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(
            appName,
            "SimulationCraft",
            this.ovale.GetName()
        );
    }
}
