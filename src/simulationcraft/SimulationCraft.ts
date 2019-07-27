import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "../Localization";
import { OvaleClass } from "../Ovale";
import { AstNode, AstAnnotation, OvaleASTClass } from "../AST";
import { ResetControls } from "../Controls";
import { format, gmatch, gsub, lower, match, sub } from "@wowts/string";
import { ipairs, pairs, tonumber, type, wipe, LuaObj, LuaArray, lualength, truthy, kpairs } from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import { RAID_CLASS_COLORS } from "@wowts/wow-mock";
import { isLuaArray } from "../tools";
import { OvaleOptionsClass } from "../Options";
import { Annotation, Profile, ParseNode, CONSUMABLE_ITEMS, OVALE_TAGS, classInfos } from "./definitions";
import { OvaleDataClass } from "../Data";
import { Emiter } from "./emiter";
import { print_r, OvaleFunctionName, OvaleTaggedFunctionName, self_outputPool, CamelSpecialization, CamelCase } from "./text-tools";
import { Parser } from "./parser";
import { Unparser } from "./unparser";
import { OvaleDebugClass, Tracer } from "../Debug";
import { OvaleCompileClass } from "../Compile";
import { Splitter } from "./splitter";
import { Generator, Mark, Sweep} from "./generator";
import { AceModule } from "@wowts/tsaddon";

let self_lastSimC: string = undefined;
let self_lastScript: string = undefined;

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
        private ovaleDebug: OvaleDebugClass,
        private ovaleCompile: OvaleCompileClass,
        private splitter: Splitter,
        private generator: Generator,
        private ovale: OvaleClass) {
        this.registerOptions();
        this.module = ovale.createModule("OvaleSimulationCraft", this.OnInitialize, this.handleDisable);
        this.tracer = ovaleDebug.create("")
    }

    public AddSymbol(annotation: Annotation, symbol: string) {
        let symbolTable = annotation.symbolTable || {}
        let symbolList = annotation.symbolList || {};
        if (!symbolTable[symbol] && !this.ovaleData.DEFAULT_SPELL_LIST[symbol]) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        annotation.symbolTable = symbolTable;
        annotation.symbolList = symbolList;
    }

    private registerOptions() {
        let actions = {
            simc: {
                name: "SimulationCraft",
                type: "execute",
                func: function () {
                    let appName = name;
                    AceConfigDialog.SetDefaultSize(appName, 700, 550);
                    AceConfigDialog.Open(appName);
                }
            }
        }
        for (const [k, v] of pairs(actions)) {
            this.ovaleOptions.options.args.actions.args[k] = v;
        }

        let defaultDB = {
            overrideCode: ""
        }
        for (const [k, v] of pairs(defaultDB)) {
            (<any>this.ovaleOptions.defaultDB.profile)[k] = v;
        }
    }
    
    private OnInitialize = () => {
        this.emiter.InitializeDisambiguation();
        this.CreateOptions();
    }

    private handleDisable = () => {}
    // DebuggingInfo() {
    //     self_pool.DebuggingInfo();
    //     self_childrenPool.DebuggingInfo();
    //     self_outputPool.DebuggingInfo();
    // }
    ToString(tbl: AstNode) {
        const output = print_r(tbl);
        return concat(output, "\n");
    }
    Release(profile: Profile) {
        if (profile.annotation) {
            const annotation = profile.annotation;
            if (annotation.astAnnotation) {
                this.ovaleAst.ReleaseAnnotation(annotation.astAnnotation);
            }
            if (annotation.nodeList) {
                this.parser.release(annotation.nodeList);
            }
            for (const [key, value] of kpairs(annotation)) {
                if (type(value) == "table") {
                    wipe(value);
                }
                annotation[key] = undefined;
            }
            profile.annotation = undefined;
        }
        profile.actionList = undefined;
    }
    ParseProfile(simc: string, annotation?: Annotation) {
        let profile:Profile = {}
        for (const _line of gmatch(simc, "[^\r\n]+")) {
            let [line] = match(_line, "^%s*(.-)%s*$");
            if (!(truthy(match(line, "^#.*")) || truthy(match(line, "^$")))) {
                let [k, operator, value] = match(line, "([^%+=]+)(%+?=)(.*)");
                const key = <keyof Profile>k;
                if (operator == "=") {
                    (<any>profile)[key] = value;
                } else if (operator == "+=") {
                    if (type(profile[key]) != "table") {
                        const oldValue = profile[key];
                        (<any>profile[key]) = {}
                        insert(<LuaArray<any>> profile[key], oldValue);
                    }
                    insert(<LuaArray<any>> profile[key], value);
                }
            }
        }
        for (const [k, v] of kpairs(profile)) {
            if (isLuaArray(v)) {
                (<any>profile)[k] = concat(<any>v);
            }
        }
        profile.templates = {}
        for (const [k, ] of kpairs(profile)) {
            if (sub(k, 1, 2) == "$(" && sub(k, -1) == ")") {
                insert(profile.templates, k);
            }
        }
        let ok = true;
        annotation = annotation || new Annotation(this.ovaleData);

        // Parse the different "actions" commands in the script. Save them as ParseNode action_list
        let nodeList: LuaArray<ParseNode> = {};
        let actionList: LuaArray<ParseNode> = {};
        for (const [k, _v] of kpairs(profile)) {
            let v = _v;
            if (ok && truthy(match(k, "^actions"))) {
                let [name] = match(k, "^actions%.([%w_]+)");
                if (!name) {
                    name = "_default";
                }
                for (let index = lualength(profile.templates); index >= 1; index += -1) {
                    let template = profile.templates[index];
                    let variable = sub(template, 3, -2);
                    let pattern = `%$%(${variable}%)`;
                    v = gsub(<string>v, pattern, <string>profile[template]);
                }
                let node: ParseNode;
                [ok, node] = this.parser.ParseActionList(name, <string>v, nodeList, annotation);
                if (ok) {
                    actionList[lualength(actionList) + 1] = node;
                } else {
                    break;
                }
            }
        }
        sort(actionList, function (a, b) {
            return a.name < b.name;
        });
        for (const [className] of kpairs(RAID_CLASS_COLORS)) {
            let lowerClass = <keyof Profile>lower(<string>className);
            if (profile[lowerClass]) {
                annotation.class = className;
                annotation.name = <string>profile[lowerClass];
            }
        }
        annotation.specialization = profile.spec;
        annotation.level = profile.level;
        ok = ok && (annotation.class !== undefined && annotation.specialization !== undefined && annotation.level !== undefined);
        annotation.pet = profile.default_pet;
        let consumables:LuaObj<string> = {}
        for (const [k, v] of pairs(CONSUMABLE_ITEMS)) {
            if (v) {
                if (profile[<keyof Profile>k] != undefined) {
                    consumables[k] = <string>profile[<keyof Profile>k];
                }
            }
        }
        annotation.consumables = consumables;
        if (profile.role == "tank") {
            annotation.role = profile.role;
            annotation.melee = annotation.class;
        } else if (profile.role == "spell") {
            annotation.role = profile.role;
            annotation.ranged = annotation.class;
        } else if (profile.role == "attack" || profile.role == "dps") {
            annotation.role = "attack";
            if (profile.position == "ranged_back") {
                annotation.ranged = annotation.class;
            } else {
                annotation.melee = annotation.class;
            }
        }
		annotation.position = profile.position;
        let taggedFunctionName: LuaObj<boolean> = { }
        for (const [, node] of ipairs(actionList)) {
            let fname = OvaleFunctionName(node.name, annotation);
            taggedFunctionName[fname] = true;
            for (const [, tag] of pairs(OVALE_TAGS)) {
                let [bodyName, conditionName] = OvaleTaggedFunctionName(fname, tag);
                taggedFunctionName[bodyName] = true;
                taggedFunctionName[conditionName] = true;
            }
        }
        annotation.taggedFunctionName = taggedFunctionName;
        annotation.functionTag = {}
        profile.actionList = actionList;
        profile.annotation = annotation;
        annotation.nodeList = nodeList;
        if (!ok) {
            this.Release(profile);
            profile = undefined;
        }
        return profile;
    }
    Unparse(profile: Profile) {
        let output = self_outputPool.Get();
        if (profile.actionList) {
            for (const [, node] of ipairs(profile.actionList)) {
                output[lualength(output) + 1] = this.unparser.Unparse(node);
            }
        }
        let s = concat(output, "\n");
        self_outputPool.Release(output);
        return s;
    }
    EmitAST(profile: Profile) {
        let nodeList = {};
        let ast = this.ovaleAst.NewNode(nodeList, true);
        const child = ast.child;
        ast.type = "script";
        let annotation = profile.annotation;
        let ok = true;
        if (profile.actionList) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            annotation.astAnnotation.nodeList = nodeList;
            let dictionaryAST: AstNode;
            {
                this.ovaleDebug.ResetTrace();
                let dictionaryAnnotation: AstAnnotation = {
                    nodeList: {},
                    definition: profile.annotation.dictionary
                }
                let dictionaryFormat = `
				Include(ovale_common)
				Include(ovale_trinkets_mop)
				Include(ovale_trinkets_wod)
				Include(ovale_%s_spells)
				%s
			`;
                let dictionaryCode = format(dictionaryFormat, lower(annotation.class), (this.ovaleOptions.db.profile.overrideCode) || "");
                [dictionaryAST] = this.ovaleAst.ParseCode("script", dictionaryCode, dictionaryAnnotation.nodeList, dictionaryAnnotation);
                if (dictionaryAST) {
                    dictionaryAST.annotation = dictionaryAnnotation;
                    annotation.dictionaryAST = dictionaryAST;
                    annotation.dictionary = dictionaryAnnotation.definition;
                    this.ovaleAst.PropagateConstants(dictionaryAST);
                    this.ovaleAst.PropagateStrings(dictionaryAST);
                    this.ovaleAst.FlattenParameters(dictionaryAST);
                    ResetControls();
                    this.ovaleCompile.EvaluateScript(dictionaryAST, true);
                }
            }
            for (const [, node] of ipairs(profile.actionList)) {
                let addFunctionNode = this.emiter.EmitActionList(node, nodeList, annotation, undefined);
                if (addFunctionNode) {
                    // Add interrupt if not already added
                    if (node.name === "_default" && !annotation.interrupt) {
                        const defaultInterrupt = classInfos[annotation.class][annotation.specialization];
                        if (defaultInterrupt && defaultInterrupt.interrupt) {
                            const interruptCall = this.ovaleAst.NewNode(nodeList);
                            interruptCall.type = "custom_function";
                            interruptCall.name = CamelSpecialization(annotation) + "InterruptActions";
                            annotation.interrupt = annotation.class;
                            annotation[defaultInterrupt.interrupt] = annotation.class;
                            insert(addFunctionNode.child[1].child, 1, interruptCall);
                        }
                    }

                    let actionListName = gsub(node.name, "^_+", "");
                    let commentNode = this.ovaleAst.NewNode(nodeList);
                    commentNode.type = "comment";
                    commentNode.comment = `## actions.${actionListName}`;
                    child[lualength(child) + 1] = commentNode;
                    for (const [, tag] of pairs(OVALE_TAGS)) {
                        let [bodyNode, conditionNode] = this.splitter.SplitByTag(tag, addFunctionNode, nodeList, annotation);
                        child[lualength(child) + 1] = bodyNode;
                        child[lualength(child) + 1] = conditionNode;
                    }
                } else {
                    ok = false;
                    break;
                }
            }
        }
        if (ok) {
            annotation.supportingFunctionCount = this.generator.InsertSupportingFunctions(child, annotation);
            annotation.supportingInterruptCount = annotation.interrupt && this.generator.InsertInterruptFunctions(child, annotation);
            annotation.supportingControlCount = this.generator.InsertSupportingControls(child, annotation);
            // annotation.supportingDefineCount = InsertSupportingDefines(child, annotation);
            this.generator.InsertVariables(child, annotation);
            let [className, specialization] = [annotation.class, annotation.specialization];
            let lowerclass = lower(className);
            let aoeToggle = `opt_${lowerclass}_${specialization}_aoe`;
            {
                let commentNode = this.ovaleAst.NewNode(nodeList);
                commentNode.type = "comment";
                commentNode.comment = `## ${CamelCase(specialization)} icons.`;
                insert(child, commentNode);
                let code = format("AddCheckBox(%s L(AOE) default specialization=%s)", aoeToggle, specialization);
                let [node] = this.ovaleAst.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=!%s enemies=1 help=shortcd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, this.generator.GenerateIconBody("shortcd", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=shortcd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, this.generator.GenerateIconBody("shortcd", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon enemies=1 help=main specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, specialization, this.generator.GenerateIconBody("main", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=aoe specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, this.generator.GenerateIconBody("main", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=!%s enemies=1 help=cd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, this.generator.GenerateIconBody("cd", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=cd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, this.generator.GenerateIconBody("cd", profile));
                let [node] = this.ovaleAst.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            Mark(ast);
            let [changed] = Sweep(ast);
            while (changed) {
                Mark(ast);
                [changed] = Sweep(ast);
            }
            Mark(ast);
            Sweep(ast);
        }
        if (!ok) {
            this.ovaleAst.Release(ast);
            ast = undefined;
        }
        return ast;
    }
    Emit(profile: Profile, noFinalNewLine?: boolean) {
        let ast = this.EmitAST(profile);
        let annotation = profile.annotation;
        let className = annotation.class;
        let lowerclass = lower(className);
        let specialization = annotation.specialization;
        let output = self_outputPool.Get();
        {
            output[lualength(output) + 1] = `# Based on SimulationCraft profile ${annotation.name}.`;
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
            output[lualength(output) + 1] = "Include(ovale_trinkets_mop)";
            output[lualength(output) + 1] = "Include(ovale_trinkets_wod)";
            output[lualength(output) + 1] = format("Include(ovale_%s_spells)", lowerclass);
            const overrideCode = this.ovaleOptions.db.profile.overrideCode;
            if (overrideCode && overrideCode != "") {
                output[lualength(output) + 1] = "";
                output[lualength(output) + 1] = "# Overrides.";
                output[lualength(output) + 1] = overrideCode;
            }
            if (annotation.supportingControlCount > 0) {
                output[lualength(output) + 1] = "";
            }
        }
        output[lualength(output) + 1] = this.ovaleAst.Unparse(ast);
        if (profile.annotation.symbolTable) {
            output[lualength(output) + 1] = "";
            output[lualength(output) + 1] = "### Required symbols";
            sort(profile.annotation.symbolList);

            for (const [, symbol] of ipairs(profile.annotation.symbolList)) {
                if (!tonumber(symbol) && profile.annotation.dictionary && !profile.annotation.dictionary[symbol] && !this.ovaleData.buffSpellList[symbol]) {
                    this.tracer.Print("Warning: Symbol '%s' not defined", symbol);
                }
                output[lualength(output) + 1] = `# ${symbol}`;
            }
        }
        annotation.dictionary = undefined;
        if (annotation.dictionaryAST) {
            this.ovaleAst.Release(annotation.dictionaryAST);
        }
        if (!noFinalNewLine && output[lualength(output)] != "") {
            output[lualength(output) + 1] = "";
        }
        let s = concat(output, "\n");
        self_outputPool.Release(output);
        this.ovaleAst.Release(ast);
        return s;
    }
    CreateOptions() {
        let options = {
            name: `${this.ovale.GetName()} SimulationCraft`,
            type: "group",
            args: {
                input: {
                    order: 10,
                    name: L["Input"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: `${L["The contents of a SimulationCraft profile."]}\nhttps://code.google.com/p/simulationcraft/source/browse/profiles`,
                            type: "description"
                        },
                        input: {
                            order: 20,
                            name: L["SimulationCraft Profile"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: () => {
                                return self_lastSimC;
                            },
                            set: (info: any, value: string) => {
                                self_lastSimC = value;
                                let profile = this.ParseProfile(self_lastSimC);
                                let code = "";
                                if (profile) {
                                    code = this.Emit(profile);
                                }
                                self_lastScript = gsub(code, "\t", "    ");
                            }
                        }
                    }
                },
                overrides: {
                    order: 20,
                    name: L["Overrides"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: L["SIMULATIONCRAFT_OVERRIDES_DESCRIPTION"],
                            type: "description"
                        },
                        overrides: {
                            order: 20,
                            name: L["Overrides"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: () => {
                                const code = this.ovaleOptions.db.profile.code;
                                return gsub(code, "\t", "    ");
                            },
                            set: (info: any, value: string) => {
                                this.ovaleOptions.db.profile.overrideCode = value;
                                if (self_lastSimC) {
                                    let profile = this.ParseProfile(self_lastSimC);
                                    let code = "";
                                    if (profile) {
                                        code = this.Emit(profile);
                                    }
                                    self_lastScript = gsub(code, "\t", "    ");
                                }
                            }
                        }
                    }
                },
                output: {
                    order: 30,
                    name: L["Output"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: L["The script translated from the SimulationCraft profile."],
                            type: "description"
                        },
                        output: {
                            order: 20,
                            name: L["Script"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: function () {
                                return self_lastScript;
                            }
                        }
                    }
                }
            }
        }
        let appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(appName, "SimulationCraft", this.ovale.GetName());
    }
}
