import { OvaleAzeriteArmor } from "../states/AzeriteArmor";
import {
    AstAnnotation,
    OvaleASTClass,
    AstCheckBoxNode,
    AstIconNode,
    AstListItemNode,
    AstItemInfoNode,
    AstItemRequireNode,
    AstListNode,
    AstScoreSpellsNode,
    AstSpellAuraListNode,
    AstSpellInfoNode,
    AstSpellRequireNode,
    SpellAuraKeyWord,
    AstScriptNode,
} from "./ast";
import { OvaleConditionClass } from "./condition";
import { OvaleCooldownClass } from "../states/Cooldown";
import { AuraType, OvaleDataClass, SpellAddAuras, SpellInfo } from "./data";
import { powerTypes, PowerType } from "../states/Power";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { Controls } from "./controls";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    ipairs,
    pairs,
    tonumber,
    tostring,
    wipe,
    LuaArray,
    lualength,
    truthy,
    LuaObj,
    kpairs,
} from "@wowts/lua";
import { match, sub } from "@wowts/string";
import { insert } from "@wowts/table";
import { GetSpellInfo } from "@wowts/wow-mock";
import { isNumber } from "../tools/tools";
import { DebugTools, Tracer } from "./debug";
import { OvaleProfilerClass, Profiler } from "./profiler";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleScoreClass } from "../ui/Score";
import { OvaleScriptsClass } from "./scripts";

const numberPattern = "^%-?%d+%.?%d*$";

export function requireValue(
    value: string | number
): [string | number, boolean] {
    const required = sub(tostring(value), 1, 1) != "!";
    if (!required) {
        value = sub(<string>value, 2);
        if (truthy(match(value, numberPattern))) {
            return [tonumber(value), required];
        }
    }
    return [value, required];
}

export function requireNumber(value: string | number): [number, boolean] {
    if (isNumber(value)) return [value, true];
    const required = sub(tostring(value), 1, 1) != "!";
    if (!required) {
        value = sub(value, 2);
        return [tonumber(value), required];
    }
    return [tonumber(value), required];
}

const auraTableDispatch: Record<
    SpellAuraKeyWord,
    { filter: AuraType; target: keyof SpellAddAuras }
> = {
    spelladdbuff: { filter: "HELPFUL", target: "player" },
    spelladddebuff: { filter: "HARMFUL", target: "player" },
    spelladdpetbuff: { filter: "HELPFUL", target: "pet" },
    spelladdpetdebuff: { filter: "HARMFUL", target: "pet" },
    spelladdtargetbuff: { filter: "HELPFUL", target: "target" },
    spelladdtargetdebuff: { filter: "HARMFUL", target: "target" },
    spelldamagebuff: { filter: "HELPFUL", target: "damage" },
    spelldamagedebuff: { filter: "HARMFUL", target: "damage" },
};

export class OvaleCompileClass {
    private serial: number | undefined = undefined;
    private ast: AstScriptNode | undefined = undefined;

    private nextSerial = 0;
    private timesEvaluated = 0;
    private icon: LuaArray<AstIconNode> = {};
    private tracer: Tracer;
    private profiler: Profiler;
    private module: AceModule & AceEvent;

    constructor(
        private ovaleAzerite: OvaleAzeriteArmor,
        private ovaleAst: OvaleASTClass,
        private ovaleCondition: OvaleConditionClass,
        private ovaleCooldown: OvaleCooldownClass,
        private ovaleData: OvaleDataClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleDebug: DebugTools,
        private ovale: OvaleClass,
        private ovaleScore: OvaleScoreClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private controls: Controls,
        private script: OvaleScriptsClass
    ) {
        this.tracer = ovaleDebug.create("OvaleCompile");
        this.profiler = ovaleProfiler.create("OvaleCompile");
        this.module = ovale.createModule(
            "OvaleCompile",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    private evaluateAddCheckBox(node: AstCheckBoxNode) {
        const ok = true;
        const [name, positionalParams, namedParams] = [
            node.name,
            node.rawPositionalParams,
            node.rawNamedParams,
        ];
        const description =
            (node.description.type === "string" && node.description.value) ||
            node.name;
        let defaultValue = false;
        for (const [, v] of ipairs(positionalParams)) {
            if (v.type === "string" && v.value === "default") {
                defaultValue = true;
                break;
            }
        }

        if (
            this.controls.addCheckBox(
                name,
                description,
                defaultValue,
                namedParams.enabled
            )
        ) {
            this.nextSerial = this.nextSerial + 1;
            this.tracer.debug(
                "New checkbox '%s': advance age to %d.",
                name,
                this.nextSerial
            );
        }
        return ok;
    }

    private evaluateAddIcon(node: AstIconNode) {
        this.icon[lualength(this.icon) + 1] = node;
        return true;
    }

    private evaluateAddListItem(node: AstListItemNode) {
        const ok = true;
        const [name, item, positionalParams, namedParams] = [
            node.name,
            node.item,
            node.rawPositionalParams,
            node.rawNamedParams,
        ];
        if (item) {
            let defaultValue = false;
            for (const [, v] of ipairs(positionalParams)) {
                if (v.type === "string" && v.value == "default") {
                    defaultValue = true;
                    break;
                }
            }

            const description =
                (node.description.type === "string" &&
                    node.description.value) ||
                item;

            if (
                this.controls.addListItem(
                    name,
                    item,
                    description,
                    defaultValue,
                    namedParams.enabled
                )
            ) {
                this.nextSerial = this.nextSerial + 1;
                this.tracer.debug(
                    "New list '%s': advance age to %d.",
                    name,
                    this.nextSerial
                );
            }
        }
        return ok;
    }

    private evaluateItemInfo(node: AstItemInfoNode) {
        let ok = true;
        const [itemId, namedParams] = [node.itemId, node.rawNamedParams];
        if (itemId) {
            const ii = this.ovaleData.getItemInfo(itemId);
            for (const [k, v] of kpairs(namedParams)) {
                // if (k == "proc") {
                //     const buff = v;
                //     if (buff.type === "value" && isNumber(buff.value)) {
                //         const name = "item_proc_" + namedParams.proc;
                //         const list = this.ovaleData.buffSpellList[name] || {};
                //         list[buff.value] = true;
                //         this.ovaleData.buffSpellList[name] = list;
                //     } else {
                //         ok = false;
                //         break;
                //     }
                // } else {
                if (v.type === "value" || v.type === "string")
                    (ii as any)[k] = v.value;
                else {
                    ok = false;
                    break;
                }
                // }
            }
            this.ovaleData.itemInfo[itemId] = ii;
        }
        return ok;
    }

    private evaluateItemRequire(node: AstItemRequireNode) {
        const property = node.property;
        const ii = this.ovaleData.getItemInfo(node.itemId);
        const tbl = ii.require[property] || {};
        insert(tbl, node);
        ii.require[property] = tbl;
        return true;
    }

    private evaluateList(node: AstListNode) {
        let ok = true;
        const [name, positionalParams] = [node.name, node.rawPositionalParams];
        let listDB: "itemList" | "buffSpellList";
        if (node.keyword == "ItemList") {
            listDB = "itemList";
        } else {
            listDB = "buffSpellList";
        }
        const list = this.ovaleData[listDB][name] || {};
        for (const [, _id] of pairs(positionalParams)) {
            if (_id.type === "value" && isNumber(_id.value)) {
                list[_id.value] = true;
            } else {
                this.tracer.error(
                    "%s is not a number in the '%s' list",
                    _id.asString,
                    name
                );
                ok = false;
                break;
            }
        }
        this.ovaleData[listDB][name] = list;
        return ok;
    }

    private evaluateScoreSpells(node: AstScoreSpellsNode) {
        let ok = true;
        const [positionalParams] = [node.rawPositionalParams];
        for (const [, _spellId] of ipairs(positionalParams)) {
            if (_spellId.type === "value" && isNumber(_spellId.value)) {
                this.ovaleScore.addSpell(_spellId.value);
            } else {
                ok = false;
                break;
            }
        }
        return ok;
    }

    private evaluateSpellAuraList(node: AstSpellAuraListNode) {
        const ok = true;

        const [spellId] = [node.spellId];
        if (!spellId) {
            this.tracer.error("No spellId for name %s", node.name);
            return false;
        }
        const keyword = node.keyword;
        const si = this.ovaleData.getSpellInfo(spellId);
        if (si.aura) {
            const auraInfo = auraTableDispatch[keyword];
            const auraTable = si.aura[auraInfo.target];
            const filter = auraInfo.filter;
            const tbl = auraTable[filter] || {};
            tbl[node.buffSpellId] = node;
            const buff = this.ovaleData.getSpellInfo(node.buffSpellId);
            buff.effect = auraInfo.filter;
        }
        return ok;
    }

    private evaluateSpellInfo(node: AstSpellInfoNode) {
        const addpower: LuaObj<PowerType> = {};
        for (const [, powertype] of ipairs(powerTypes)) {
            const key = `add${powertype}`;
            addpower[key] = powertype;
        }
        let ok = true;
        const [spellId, , namedParams] = [
            node.spellId,
            node.rawPositionalParams,
            node.rawNamedParams,
        ];
        if (spellId) {
            const si = this.ovaleData.getSpellInfo(spellId);
            for (const [k, v] of kpairs(namedParams)) {
                if (k == "add_duration") {
                    if (v.type === "value") {
                        let realValue = v.value;
                        if (
                            namedParams.pertrait &&
                            namedParams.pertrait.type === "value"
                        ) {
                            realValue =
                                v.value *
                                this.ovaleAzerite.traitRank(
                                    namedParams.pertrait.value
                                );
                        }
                        const addDuration = si.add_duration || 0;
                        si.add_duration = addDuration + realValue;
                    } else {
                        ok = false;
                        break;
                    }
                } else if (k == "add_cd") {
                    const value = tonumber(v);
                    if (value) {
                        const addCd = si.add_cd || 0;
                        si.add_cd = addCd + value;
                    } else {
                        ok = false;
                        break;
                    }
                } else if (k == "addlist" && v.type === "string") {
                    const list = this.ovaleData.buffSpellList[v.value] || {};
                    list[spellId] = true;
                    this.ovaleData.buffSpellList[v.value] = list;
                } else if (k == "dummy_replace" && v.type === "string") {
                    let [spellName] = GetSpellInfo(v.value);
                    if (!spellName) spellName = v.value;
                    this.ovaleSpellBook.addSpell(spellId, spellName);
                } else if (k == "learn" && v.type === "value" && v.value == 1) {
                    const [spellName] = GetSpellInfo(spellId);
                    if (spellName)
                        this.ovaleSpellBook.addSpell(spellId, spellName);
                } else if (k == "shared_cd" && v.type === "string") {
                    si.shared_cd = v.value;
                    this.ovaleCooldown.addSharedCooldown(v.value, spellId);
                } else if (addpower[k] != undefined) {
                    if (v.type === "value") {
                        let realValue = v.value;
                        if (
                            namedParams.pertrait &&
                            namedParams.pertrait.type === "value"
                        ) {
                            realValue =
                                v.value *
                                this.ovaleAzerite.traitRank(
                                    namedParams.pertrait.value
                                );
                        }
                        const power = <number>si[k as keyof SpellInfo] || 0;
                        (<any>si)[k] = power + realValue;
                    } else {
                        this.tracer.error(
                            "Unexpected value type %s in a addpower SpellInfo parameter (should be value)",
                            v.type
                        );
                        ok = false;
                        break;
                    }
                } else {
                    if (v.type === "value" || v.type === "string")
                        (si as any)[k] = v.value;
                    else {
                        this.tracer.error(
                            "Unexpected value type %s in a SpellInfo parameter (should be value or string)",
                            v.type
                        );
                        ok = false;
                        break;
                    }
                }
            }
        }
        return ok;
    }

    private evaluateSpellRequire(node: AstSpellRequireNode) {
        const ok = true;
        const [spellId] = [
            node.spellId,
            node.rawPositionalParams,
            node.rawNamedParams,
        ];
        const property = node.property;
        const si = this.ovaleData.getSpellInfo(spellId);
        const tbl = si.require[property] || {};
        insert(tbl, node);
        si.require[property] = tbl;
        return ok;
    }

    /** This attempt to replace an unknown spell by a spell with
     * the same name that is known in a Spell function call. In the case of
     * a spell list, it tries to find the one that is known. */
    private addMissingVariantSpells(annotation: AstAnnotation) {
        if (annotation.spellNode) {
            for (const [, spellIdParam] of ipairs(annotation.spellNode)) {
                if (spellIdParam.type === "value") {
                    const spellId = spellIdParam.value;
                    if (
                        !this.ovaleSpellBook.isKnownSpell(spellId) &&
                        !this.ovaleCooldown.isSharedCooldown(spellId)
                    ) {
                        const spellName = this.ovaleSpellBook.getSpellName(
                            spellId
                        );
                        if (spellName) {
                            const [name] = GetSpellInfo(spellName);
                            if (spellName == name) {
                                this.tracer.debug(
                                    "Learning spell %s with ID %d.",
                                    spellName,
                                    spellId
                                );
                                this.ovaleSpellBook.addSpell(
                                    spellId,
                                    spellName
                                );
                            }
                        } else if (spellId > 0) {
                            this.tracer.error(
                                "Unknown spell with ID %s.",
                                spellId
                            );
                        }
                    }
                } else if (spellIdParam.type === "string") {
                    if (!this.ovaleData.buffSpellList[spellIdParam.value]) {
                        this.tracer.error(
                            "Unknown spell list %s",
                            spellIdParam.value
                        );
                    }
                } else if (spellIdParam.type === "variable") {
                    this.tracer.error(
                        "Spell argument %s must be either a spell id or a spell list name.",
                        spellIdParam.name
                    );
                } else {
                    this.tracer.error(
                        "Spell argument must be either a spell id or a spell list name."
                    );
                }
            }
        }
    }

    // private trinket: LuaArray<number> = {};
    updateTrinketInfo() {
        // TODO
        // [
        //     this.trinket[1],
        //     this.trinket[2],
        // ] = this.ovaleEquipment.GetEquippedTrinkets();
        // for (let i = 1; i <= 2; i += 1) {
        //     let itemId = this.trinket[i];
        //     let ii = itemId && this.ovaleData.ItemInfo(itemId);
        //     let buffId = ii && ii.buff;
        //     if (buffId) {
        //         if (isLuaArray(buffId)) {
        //             for (const [, id] of ipairs(buffId)) {
        //                 this.AddToBuffList(id);
        //             }
        //         } else {
        //             this.AddToBuffList(buffId);
        //         }
        //     }
        // }
    }

    private handleInitialize = () => {
        // TODO Remove these
        this.module.RegisterMessage(
            "Ovale_CheckBoxValueChanged",
            this.handleScriptControlChanged
        );
        this.module.RegisterMessage(
            "Ovale_ListValueChanged",
            this.handleScriptControlChanged
        );
        this.module.RegisterMessage(
            "Ovale_ScriptChanged",
            this.handleScriptChanged
        );
        this.module.RegisterMessage(
            "Ovale_SpecializationChanged",
            this.handleScriptChanged
        );

        this.module.SendMessage("Ovale_ScriptChanged");
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_CheckBoxValueChanged");
        this.module.UnregisterMessage("Ovale_ListValueChanged");
        this.module.UnregisterMessage("Ovale_ScriptChanged");
        this.module.UnregisterMessage("Ovale_SpecializationChanged");
    };
    private handleScriptChanged = (event: string) => {
        this.compileScript(this.script.getCurrentSpecScriptName());
        this.eventHandler(event);
    };

    private handleScriptControlChanged = (event: string, name: string) => {
        if (!name) {
            this.eventHandler(event);
        } else {
            let control;
            if (event == "Ovale_CheckBoxValueChanged") {
                control = this.controls.checkBoxesByName[name];
            } else if (event == "Ovale_ListValueChanged") {
                control = this.controls.listsByName[name];
            }
            if (control && control.triggerEvaluation) {
                this.eventHandler(event);
            }
        }
    };

    private eventHandler = (event: string) => {
        this.nextSerial = this.nextSerial + 1;
        this.tracer.debug("%s: advance age to %d.", event, this.nextSerial);
        this.ovale.needRefresh();
    };
    compileScript(name: string) {
        this.ovaleDebug.resetTrace();
        this.tracer.debug("Compiling script '%s'.", name);
        if (this.ast) {
            this.ovaleAst.release(this.ast);
            this.ast = undefined;
        }
        if (this.ovaleCondition.hasAny()) {
            this.ast = this.ovaleAst.parseNamedScript(name);
            this.tracer.debug(
                `Compilation result: ${
                    (this.ast !== undefined && "success") || "failed"
                }`
            );
        } else {
            this.tracer.debug("No conditions. No need to compile.");
        }
        this.controls.reset();
        return this.ast;
    }
    evaluateScript(ast?: AstScriptNode, forceEvaluation?: boolean) {
        this.profiler.startProfiling("OvaleCompile_EvaluateScript");
        let changed = false;
        ast = ast || this.ast;
        // this.tracer.Debug(
        //     `ast?: ${(this.ast !== undefined && "yes") || "no"} serial: ${
        //         this.serial || "nil"
        //     }. asked: ${this.self_serial}`
        // );
        if (
            ast &&
            (forceEvaluation || !this.serial || this.serial < this.nextSerial)
        ) {
            this.tracer.debug("Script has changed. Evaluating...");
            changed = true;
            let ok = true;
            wipe(this.icon);
            this.ovaleData.reset();
            this.ovaleCooldown.resetSharedCooldowns();
            this.timesEvaluated = this.timesEvaluated + 1;
            this.serial = this.nextSerial;
            for (const [, node] of ipairs(ast.child)) {
                if (node.type == "checkbox") {
                    ok = this.evaluateAddCheckBox(node);
                } else if (node.type == "icon") {
                    ok = this.evaluateAddIcon(node);
                } else if (node.type == "list_item") {
                    ok = this.evaluateAddListItem(node);
                } else if (node.type == "item_info") {
                    ok = this.evaluateItemInfo(node);
                } else if (node.type == "itemrequire") {
                    ok = this.evaluateItemRequire(node);
                } else if (node.type == "list") {
                    ok = this.evaluateList(node);
                } else if (node.type == "score_spells") {
                    ok = this.evaluateScoreSpells(node);
                } else if (node.type == "spell_aura_list") {
                    ok = this.evaluateSpellAuraList(node);
                } else if (node.type == "spell_info") {
                    ok = this.evaluateSpellInfo(node);
                } else if (node.type == "spell_require") {
                    ok = this.evaluateSpellRequire(node);
                } else if (
                    node.type !== "define" &&
                    node.type !== "add_function"
                ) {
                    this.tracer.error("Unknown node type", node.type);
                    ok = false;
                }
                if (!ok) {
                    break;
                }
            }
            if (ok) {
                if (ast.annotation)
                    this.addMissingVariantSpells(ast.annotation);
                this.updateTrinketInfo();
            }
        }
        this.profiler.stopProfiling("OvaleCompile_EvaluateScript");
        return changed;
    }
    getFunctionNode(name: string) {
        let node;
        if (
            this.ast &&
            this.ast.annotation &&
            this.ast.annotation.customFunction
        ) {
            node = this.ast.annotation.customFunction[name];
        }
        return node;
    }
    getIconNodes() {
        return this.icon;
    }
    debugCompile() {
        this.tracer.print(
            "Total number of times the script was evaluated: %d",
            this.timesEvaluated
        );
    }
}
