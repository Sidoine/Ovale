import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleArtifact } from "./Artifact";
import { OvaleAST, AstNode, AstAnnotation, PositionalParameters, NamedParameters, PARAMETER_KEYWORD, ConditionNamedParameters } from "./AST";
import { OvaleCondition } from "./Condition";
import { OvaleCooldown } from "./Cooldown";
import { OvaleData, SpellInfo } from "./Data";
import { OvaleEquipment } from "./Equipment";
import { OvalePaperDoll } from "./PaperDoll";
import { POWER_TYPES, PowerType } from "./Power";
import { OvaleScore } from "./Score";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleStance } from "./Stance";
import { Ovale } from "./Ovale";
import { checkBoxes, lists, ResetControls } from "./Controls";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, tonumber, tostring, type, wipe, LuaArray, lualength, truthy, LuaObj, kpairs } from "@wowts/lua";
import { find, match, sub } from "@wowts/string";
import { insert } from "@wowts/table";
import { GetSpellInfo } from "@wowts/wow-mock";
import { isLuaArray, checkToken } from "./tools";

let OvaleCompileBase = Ovale.NewModule("OvaleCompile", aceEvent);
export let OvaleCompile: OvaleCompileClass;
let self_compileOnStances = false;
 
let self_serial = 0;
let self_timesEvaluated = 0;
let self_icon: LuaArray<AstNode> = {}
let NUMBER_PATTERN = "^%-?%d+%.?%d*$";
function HasTalent(talentId: number) {
    if (OvaleSpellBook.IsKnownTalent(talentId)) {
        return OvaleSpellBook.GetTalentPoints(talentId) > 0;
    } else {
        OvaleCompile.Error("Unknown talent ID '%s'", talentId);
        return false;
    }
}
function RequireValue(value: string | number) : [ string|number, boolean] {
    let required = (sub(tostring(value), 1, 1) != "!");
    if (!required) {
        value = sub(<string>value, 2);
        if (truthy(match(value, NUMBER_PATTERN))) {
            return [tonumber(value), required];
        }
    }
    return [value, required];
}

function RequireNumber(value: string): [number, boolean] {
    let required = (sub(tostring(value), 1, 1) != "!");
    if (!required) {
        value = sub(value, 2);
        return [tonumber(value), required];
    }
    return [tonumber(value), required];
}

function TestConditionLevel(value: number) {
    return OvalePaperDoll.level >= value;
}
function TestConditionMaxLevel(value: number) {
    return OvalePaperDoll.level <= value;
}
function TestConditionSpecialization(value: string) {
    let [spec, required] = RequireValue(value);
    let isSpec = OvalePaperDoll.IsSpecialization(spec);
    return (required && isSpec) || (!required && !isSpec);
}
function TestConditionStance(value: string) {
    self_compileOnStances = true;
    let [stance, required] = RequireValue(value);
    let isStance = OvaleStance.IsStance(stance, undefined);
    return (required && isStance) || (!required && !isStance);
}
function TestConditionSpell(value: string) {
    let [spell, required] = RequireValue(value);
    let hasSpell = OvaleSpellBook.IsKnownSpell(<number>spell);
    return (required && hasSpell) || (!required && !hasSpell);
}
function TestConditionTalent(value: string) {
    let [talent, required] = RequireNumber(value);
    let hasTalent = HasTalent(talent);
    return (required && hasTalent) || (!required && !hasTalent);
}
function TestConditionEquipped(value: string) {
    let [item, required] = RequireValue(value);
    let hasItemEquipped = OvaleEquipment.HasEquippedItem(item as number);
    return (required && hasItemEquipped && true) || (!required && !hasItemEquipped);
}
function TestConditionTrait(value: string) {
    let [trait, required] = RequireNumber(value);
    let hasTrait = OvaleArtifact.HasTrait(trait);
    return (required && hasTrait) || (!required && !hasTrait);
}
let TEST_CONDITION_DISPATCH: Record<keyof ConditionNamedParameters, (value: string | number) => boolean> = {
    if_spell: TestConditionSpell,
    if_equipped: TestConditionEquipped,
    if_stance: TestConditionStance,
    level: TestConditionLevel,
    maxLevel: TestConditionMaxLevel,
    specialization: TestConditionSpecialization,
    talent: TestConditionTalent,
    trait: TestConditionTrait,
    pertrait: TestConditionTrait
}
function TestConditions(positionalParams: PositionalParameters, namedParams: NamedParameters) {
    OvaleCompile.StartProfiling("OvaleCompile_TestConditions");
    let boolean = true;
    for (const [param, dispatch] of kpairs(TEST_CONDITION_DISPATCH)) {
        let value = namedParams[param];
        if (isLuaArray(value)) {
            for (const [, v] of ipairs<any>(value)) {
                boolean = dispatch(v);
                if (!boolean) {
                    break;
                }
            }
        } else if (value) {
            boolean = dispatch(value);
        }
        if (!boolean) {
            break;
        }
    }
    if (boolean && namedParams.itemset && namedParams.itemcount) {
        let equippedCount = OvaleEquipment.GetArmorSetCount(namedParams.itemset);
        boolean = (equippedCount >= namedParams.itemcount);
    }
    if (boolean && namedParams.checkbox) {
        const profile = Ovale.db.profile;
        for (const [,checkbox] of ipairs(namedParams.checkbox)) {
            let [name, required] = RequireValue(checkbox);
            const control = checkBoxes[name] || {}
            control.triggerEvaluation = true;
            checkBoxes[name] = control;
            let isChecked = profile.check[name];
            boolean = (required && isChecked) || (!required && !isChecked);
            if (!boolean) {
                break;
            }
        }
    }
    if (boolean && namedParams.listitem) {
        const profile = Ovale.db.profile;
        for (const [name, listitem] of pairs(namedParams.listitem)) {
            let [item, required] = RequireValue(listitem);
            const control = lists[name] || { items: {}, default: undefined };
            control.triggerEvaluation = true;
            lists[name] = control;
            let isSelected = (profile.list[name] == item);
            boolean = (required && isSelected) || (!required && !isSelected);
            if (!boolean) {
                break;
            }
        }
    }
    OvaleCompile.StopProfiling("OvaleCompile_TestConditions");
    return boolean;
}
function EvaluateAddCheckBox(node: AstNode) {
    let ok = true;
    let [name, positionalParams, namedParams] = [node.name, node.positionalParams, node.namedParams];
    if (TestConditions(positionalParams, namedParams)) {
        let checkBox = checkBoxes[name]
        if (!checkBox) {
            self_serial = self_serial + 1;
            OvaleCompile.Debug("New checkbox '%s': advance age to %d.", name, self_serial);
        }
        checkBox = checkBox || {
        }
        checkBox.text = <string>node.description.value;
        for (const [, v] of ipairs(positionalParams)) {
            if (v == "default") {
                checkBox.checked = true;
                break;
            }
        }
        checkBoxes[name] = checkBox;
    }
    return ok;
}
function EvaluateAddIcon(node: AstNode) {
    let ok = true;
    let [positionalParams, namedParams] = [node.positionalParams, node.namedParams];
    if (TestConditions(positionalParams, namedParams)) {
        self_icon[lualength(self_icon) + 1] = node;
    }
    return ok;
}
function EvaluateAddListItem(node: AstNode) {
    let ok = true;
    let [name, item, positionalParams, namedParams] = [node.name, node.item, node.positionalParams, node.namedParams];
    if (TestConditions(positionalParams, namedParams)) {
        let list = lists[name]
        if (!(list && list.items && list.items[item])) {
            self_serial = self_serial + 1;
            OvaleCompile.Debug("New list '%s': advance age to %d.", name, self_serial);
        }
        list = list || {
            items: {
            },
            default: undefined
        }
        list.items[item] = node.description.value;
        for (const [, v] of ipairs(positionalParams)) {
            if (v == "default") {
                list.default = item;
                break;
            }
        }
        lists[name] = list;
    }
    return ok;
}
function EvaluateItemInfo(node: AstNode) {
    let ok = true;
    let [itemId, positionalParams, namedParams] = [node.itemId, node.positionalParams, node.namedParams];
    if (itemId && TestConditions(positionalParams, namedParams)) {
        const ii = OvaleData.ItemInfo(itemId);
        for (const [k, v] of kpairs(namedParams)) {
            if (k == "proc") {
                let buff = tonumber(namedParams.buff);
                if (buff) {
                    let name = "item_proc_" + namedParams.proc;
                    let list = OvaleData.buffSpellList[name] || {};
                    list[buff] = true;
                    OvaleData.buffSpellList[name] = list;
                } else {
                    ok = false;
                    break;
                }
            } else if (!checkToken(PARAMETER_KEYWORD, k)) {
                // TODO check that is a spell info parameter
                ii[k as keyof SpellInfo] = <any>v;
            }
        }
        OvaleData.itemInfo[itemId] = ii;
    }
    return ok;
}
function EvaluateItemRequire(node: AstNode) {
    let ok = true;
    let [itemId, positionalParams, namedParams] = [node.itemId, node.positionalParams, node.namedParams];
    if (TestConditions(positionalParams, namedParams)) {
        const property = node.property;
        let count = 0;
        let ii = OvaleData.ItemInfo(itemId);
        let tbl = ii.require[property] || {};
        let arr = undefined;
        for (const [k, v] of kpairs(namedParams)) {
            if (!checkToken(PARAMETER_KEYWORD, k)) {
                arr = tbl[k] || {};
                if (isLuaArray(arr)) {
                    insert(arr, v);
                    tbl[k] = arr;
                    count = count + 1;
                }
            }
        }
        if (count > 0) {
            ii.require[property] = tbl;
        }
    }
    return ok;
}
function EvaluateList(node: AstNode) {
    let ok = true;
    let [name, positionalParams, ] = [node.name, node.positionalParams, node.namedParams];
    let listDB: "itemList" | "buffSpellList";
    if (node.keyword == "ItemList") {
        listDB = "itemList";
    } else {
        listDB = "buffSpellList";
    }
    const list = OvaleData[listDB][name] || {};
    for (const [, _id] of pairs(positionalParams)) {
        let id = tonumber(_id);
        if (id) {
            list[id] = true;
        } else {
            ok = false;
            break;
        }
    }
    OvaleData[listDB][name] = list;
    return ok;
}
function EvaluateScoreSpells(node: AstNode) {
    let ok = true;
    let [positionalParams,] = [node.positionalParams, node.namedParams];
    for (const [, _spellId] of ipairs(positionalParams)) {
        let spellId = tonumber(_spellId);
        if (spellId) {
            OvaleScore.AddSpell(tonumber(spellId));
        } else {
            ok = false;
            break;
        }
    }
    return ok;
}
function EvaluateSpellAuraList(node: AstNode) {
    let ok = true;
    let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
    if (!spellId) {
        OvaleCompile.Error("No spellId for name %s", node.name);
        return false;
    }
    if (TestConditions(positionalParams, namedParams)) {
        let keyword = node.keyword;
        let si = OvaleData.SpellInfo(spellId);
        let auraTable;
        if (truthy(find(keyword, "^SpellDamage"))) {
            auraTable = si.aura.damage;
        } else if (truthy(find(keyword, "^SpellAddPet"))) {
            auraTable = si.aura.pet;
        } else if (truthy(find(keyword, "^SpellAddTarget"))) {
            auraTable = si.aura.target;
        } else {
            auraTable = si.aura.player;
        }
        const filter = truthy(find(node.keyword, "Debuff")) && "HARMFUL" || "HELPFUL";
        const tbl = auraTable[filter] || {};
        let count = 0;
        for (const [k, v] of kpairs(namedParams)) {
            if (!checkToken(PARAMETER_KEYWORD, k)) {
                if (OvaleData.buffSpellList[k]) {
                    tbl[k] = v;
                    count = count + 1;
                } else {
                    const id = tonumber(k);
                    if (!id) {
                        OvaleCompile.Warning(`${k} is not a parameter keyword in '${node.name}' ${node.type}`);
                    } else {
                        tbl[id] = v;
                        count = count + 1;
                    }
                }
            }
        }
        if (count > 0) {
            auraTable[filter] = tbl;
        }
    }
    return ok;
}
function EvaluateSpellInfo(node: AstNode) {
    const addpower: LuaObj<PowerType> = {}
    for (const [,powertype] of ipairs(POWER_TYPES)) {
        const key = `add${powertype}`;
        addpower[key] = powertype;
    }
    let ok = true;
    let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
    if (spellId && TestConditions(positionalParams, namedParams)) {
        let si = OvaleData.SpellInfo(spellId);
        for (const [k, v] of kpairs(namedParams)) {
            if (k == "add_duration") {
                let value = tonumber(v);
                if (value) {
                    let realValue = value;
                    if (namedParams.pertrait != undefined) {
                        realValue = value * OvaleArtifact.TraitRank(namedParams.pertrait);
                    }
                    let addDuration = si.add_duration || 0;
                    si.add_duration = addDuration + realValue;
                } else {
                    ok = false;
                    break;
                }
            } else if (k == "add_cd") {
                let value = tonumber(v);
                if (value) {
                    let addCd = si.add_cd || 0;
                    si.add_cd = addCd + value;
                } else {
                    ok = false;
                    break;
                }
            } else if (k == "addlist") {
                let list = OvaleData.buffSpellList[<string>v] || {
                }
                list[spellId] = true;
                OvaleData.buffSpellList[<string>v] = list;
            } else if (k == "dummy_replace") {
                let [spellName] = GetSpellInfo(<string>v);
                if (!spellName) spellName = v as string;
                OvaleSpellBook.AddSpell(spellId, spellName);
            } else if (k == "learn" && v == 1) {
                let [spellName] = GetSpellInfo(spellId);
                OvaleSpellBook.AddSpell(spellId, spellName);
            } else if (k == "shared_cd") {
                si[k] = <number>v;
                OvaleCooldown.AddSharedCooldown(<string>v, spellId);
            } else if (addpower[k] != undefined) {
                let value = tonumber(v);
                if (value) {
                    let realValue = value;
                    if (namedParams.pertrait != undefined) {
                        realValue = value * OvaleArtifact.TraitRank(namedParams.pertrait);
                    }
                    let power = <number>si[k as keyof SpellInfo] || 0;
                    si[k as keyof SpellInfo] = power + realValue;
                } else {
                    ok = false;
                    break;
                }
            } else if (!checkToken(PARAMETER_KEYWORD, k)) {
                si[k as keyof SpellInfo] = <any>v;
            }
        }
    }
    return ok;
}
function EvaluateSpellRequire(node: AstNode) {
    let ok = true;
    let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
    if (TestConditions(positionalParams, namedParams)) {
        let property = node.property as keyof SpellInfo;
        let count = 0;
        let si = OvaleData.SpellInfo(spellId);
        let tbl = si.require[property] || {};
        let arr = undefined;
        for (const [k, v] of kpairs(namedParams)) {
            if (!checkToken(PARAMETER_KEYWORD, k)) {
                arr = tbl[k] || {};
                if (isLuaArray(arr)) {
                    insert(arr, v);
                    tbl[k] = arr;
                    count = count + 1;
                }
            }
        }
        if (count > 0) {
            si.require[property] = tbl;
        }
    }
    return ok;
}
function AddMissingVariantSpells(annotation: AstAnnotation) {
    if (annotation.functionReference) {
        for (const [, node] of ipairs(annotation.functionReference)) {
            let [positionalParams,] = [node.positionalParams, node.namedParams];
            let spellId = <number>positionalParams[1];
            if (spellId && OvaleCondition.IsSpellBookCondition(node.func)) {
                if (!OvaleSpellBook.IsKnownSpell(spellId) && !OvaleCooldown.IsSharedCooldown(spellId)) {
                    let spellName;
                    if (type(spellId) == "number") {
                        spellName = OvaleSpellBook.GetSpellName(spellId);
                    }
                    if (spellName) {
                        let [name] = GetSpellInfo(spellName);
                        if (spellName == name) {
                            OvaleCompile.Debug("Learning spell %s with ID %d.", spellName, spellId);
                            OvaleSpellBook.AddSpell(spellId, spellName);
                        }
                    } else {
                        let functionCall = node.name;
                        if (node.paramsAsString) {
                            functionCall = `${node.name}(${node.paramsAsString})`;
                        }
                        OvaleCompile.Error("Unknown spell with ID %s used in %s.", spellId, functionCall);
                    }
                }
            }
        }
    }
}
function AddToBuffList(buffId: number, statName?: string, isStacking?: boolean) {
    if (statName) {
        for (const [, useName] of pairs(OvaleData.STAT_USE_NAMES)) {
            if (isStacking || !truthy(find(useName, "_stacking_"))) {
                let name = `${useName}_${statName}_buff`;
                let list = OvaleData.buffSpellList[name] || {};
                list[buffId] = true;
                OvaleData.buffSpellList[name] = list;
                let shortStatName = OvaleData.STAT_SHORTNAME[statName];
                if (shortStatName) {
                    name = `${useName}_${shortStatName}_buff`;
                    list = OvaleData.buffSpellList[name] || {
                    }
                    list[buffId] = true;
                    OvaleData.buffSpellList[name] = list;
                }
                name = `${useName}_any_buff`;
                list = OvaleData.buffSpellList[name] || {
                }
                list[buffId] = true;
                OvaleData.buffSpellList[name] = list;
            }
        }
    } else {
        let si = OvaleData.spellInfo[buffId];
        isStacking = si && (si.stacking == 1 || si.max_stacks > 0);
        if (si && si.stat) {
            let stat = si.stat;
            if (isLuaArray(stat)) {
                for (const [, name] of ipairs(stat)) {
                    AddToBuffList(buffId, name, isStacking);
                }
            } else {
                AddToBuffList(buffId, stat, isStacking);
            }
        }
    }
}

let trinket: LuaArray<number> = {};
let UpdateTrinketInfo = function () {
        [trinket[1], trinket[2]] = OvaleEquipment.GetEquippedTrinkets();
        for (let i = 1; i <= 2; i += 1) {
            let itemId = trinket[i];
            let ii = itemId && OvaleData.ItemInfo(itemId);
            let buffId = ii && ii.buff;
            if (buffId) {
                if (isLuaArray(buffId)) {
                    for (const [, id] of ipairs(buffId)) {
                        AddToBuffList(id);
                    }
                } else {
                    AddToBuffList(buffId);
                }
            }
        }
    }

const OvaleCompileClassBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleCompileBase));
export class OvaleCompileClass extends OvaleCompileClassBase {
    serial: number | undefined = undefined;
    ast: AstNode | undefined = undefined;
     
    OnInitialize() {
        this.RegisterMessage("Ovale_CheckBoxValueChanged", "ScriptControlChanged");
        this.RegisterMessage("Ovale_EquipmentChanged", "EventHandler");
        this.RegisterMessage("Ovale_ListValueChanged", "ScriptControlChanged");
        this.RegisterMessage("Ovale_ScriptChanged");
        this.RegisterMessage("Ovale_SpecializationChanged", "Ovale_ScriptChanged");
        this.RegisterMessage("Ovale_SpellsChanged", "EventHandler");
        this.RegisterMessage("Ovale_StanceChanged");
        this.RegisterMessage("Ovale_TalentsChanged", "EventHandler");
    
        this.SendMessage("Ovale_ScriptChanged");
    }
    
    OnDisable() {
        this.UnregisterMessage("Ovale_CheckBoxValueChanged");
        this.UnregisterMessage("Ovale_EquipmentChanged");
        this.UnregisterMessage("Ovale_ListValueChanged");
        this.UnregisterMessage("Ovale_ScriptChanged");
        this.UnregisterMessage("Ovale_SpecializationChanged");
        this.UnregisterMessage("Ovale_SpellsChanged");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    Ovale_ScriptChanged(event: string) {
        this.CompileScript(Ovale.db.profile.source[`${Ovale.playerClass}_${OvalePaperDoll.GetSpecialization()}`]);
        this.EventHandler(event);
    }
    Ovale_StanceChanged(event: string) {
        if (self_compileOnStances) {
            this.EventHandler(event);
        }
    }
    ScriptControlChanged(event: string, name: string) {
        if (!name) {
            this.EventHandler(event);
        } else {
            let control;
            if (event == "Ovale_CheckBoxValueChanged") {
                control = checkBoxes[name];
            } else if (event == "Ovale_ListValueChanged") {
                control = checkBoxes[name];
            }
            if (control && control.triggerEvaluation) {
                this.EventHandler(event);
            }
        }
    }
    EventHandler(event: string) {
        self_serial = self_serial + 1;
        this.Debug("%s: advance age to %d.", event, self_serial);
        Ovale.needRefresh();
    }
    CompileScript(name: string) {
        OvaleDebug.ResetTrace();
        this.Debug("Compiling script '%s'.", name);
        if (this.ast) {
            OvaleAST.Release(this.ast);
            this.ast = undefined;
        }
        if (OvaleCondition.HasAny()) {
            this.ast = OvaleAST.ParseScript(name);
        }
        ResetControls();
    }
    EvaluateScript(ast?: AstNode, forceEvaluation?: boolean) {
        this.StartProfiling("OvaleCompile_EvaluateScript");
        let changed = false;
        ast = ast || this.ast;
        if (ast && (forceEvaluation || !this.serial || this.serial < self_serial)) {
            changed = true;
            let ok = true;
            self_compileOnStances = false;
            wipe(self_icon);
            OvaleData.Reset();
            OvaleCooldown.ResetSharedCooldowns();
            self_timesEvaluated = self_timesEvaluated + 1;
            this.serial = self_serial;
            for (const [, node] of ipairs(ast.child)) {
                let nodeType = node.type;
                if (nodeType == "checkbox") {
                    ok = EvaluateAddCheckBox(node);
                } else if (nodeType == "icon") {
                    ok = EvaluateAddIcon(node);
                } else if (nodeType == "list_item") {
                    ok = EvaluateAddListItem(node);
                } else if (nodeType == "item_info") {
                    ok = EvaluateItemInfo(node);
                } else if (nodeType == "item_require") {
                    ok = EvaluateItemRequire(node);
                } else if (nodeType == "list") {
                    ok = EvaluateList(node);
                } else if (nodeType == "score_spells") {
                    ok = EvaluateScoreSpells(node);
                } else if (nodeType == "spell_aura_list") {
                    ok = EvaluateSpellAuraList(node);
                } else if (nodeType == "spell_info") {
                    ok = EvaluateSpellInfo(node);
                } else if (nodeType == "spell_require") {
                    ok = EvaluateSpellRequire(node);
                } else {
                }
                if (!ok) {
                    break;
                }
            }
            if (ok) {
                AddMissingVariantSpells(ast.annotation);
                UpdateTrinketInfo();
            }
        }
        this.StopProfiling("OvaleCompile_EvaluateScript");
        return changed;
    }
    GetFunctionNode(name: string) {
        let node;
        if (this.ast && this.ast.annotation && this.ast.annotation.customFunction) {
            node = this.ast.annotation.customFunction[name];
        }
        return node;
    }
    GetIconNodes() {
        return self_icon;
    }
    DebugCompile() {
        this.Print("Total number of times the script was evaluated: %d", self_timesEvaluated);
    }
}

OvaleCompile = new OvaleCompileClass();