import { OvaleAzeriteArmor } from "./AzeriteArmor";
import { AstNode, AstAnnotation, PositionalParameters, NamedParameters, PARAMETER_KEYWORD, ConditionNamedParameters, OvaleASTClass } from "./AST";
import { OvaleConditionClass } from "./Condition";
import { OvaleCooldownClass } from "./Cooldown";
import { OvaleDataClass, SpellInfo } from "./Data";
import { OvaleEquipmentClass } from "./Equipment";
import { OvalePaperDollClass } from "./PaperDoll";
import { POWER_TYPES, PowerType } from "./Power";
import { OvaleSpellBookClass } from "./SpellBook";
import { checkBoxes, lists, ResetControls } from "./Controls";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, pairs, tonumber, tostring, wipe, LuaArray, lualength, truthy, LuaObj, kpairs } from "@wowts/lua";
import { find, match, sub } from "@wowts/string";
import { insert } from "@wowts/table";
import { GetSpellInfo } from "@wowts/wow-mock";
import { isLuaArray, checkToken, isNumber, isString } from "./tools";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleOptionsClass } from "./Options";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleScoreClass } from "./Score";
import { OvaleStanceClass } from "./Stance";

const NUMBER_PATTERN = "^%-?%d+%.?%d*$";

function getFunctionCallString(node: AstNode) {
    let functionCall = node.name;
    if (node.paramsAsString) {
        functionCall = `${node.name}(${node.paramsAsString})`;
    }
    return functionCall;
}                                

export class OvaleCompileClass {
    private serial: number | undefined = undefined;
    private ast: AstNode | undefined = undefined;

    private compileOnStances = false;
    private self_serial = 0;
    private timesEvaluated = 0;
    private icon: LuaArray<AstNode> = {}
    private tracer: Tracer;
    private profiler: Profiler;
    private module: AceModule & AceEvent;

    constructor(
        private ovaleAzerite: OvaleAzeriteArmor,
        private ovaleEquipment: OvaleEquipmentClass,
        private ovaleAst: OvaleASTClass,
        private ovaleCondition: OvaleConditionClass,
        private ovaleCooldown: OvaleCooldownClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleData: OvaleDataClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleDebug: OvaleDebugClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovale: OvaleClass,
        private ovaleScore: OvaleScoreClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleStance: OvaleStanceClass) {
        this.tracer = ovaleDebug.create("OvaleCompile");
        this.profiler = ovaleProfiler.create("OvaleCompile");
        this.module = ovale.createModule("OvaleCompile", this.OnInitialize, this.OnDisable, aceEvent);
    }

    private HasTalent(talentId: number) {
        if (this.ovaleSpellBook.IsKnownTalent(talentId)) {
            return this.ovaleSpellBook.GetTalentPoints(talentId) > 0;
        } else {
            return false;
        }
    }

    private RequireValue(value: string | number) : [ string|number, boolean] {
        let required = (sub(tostring(value), 1, 1) != "!");
        if (!required) {
            value = sub(<string>value, 2);
            if (truthy(match(value, NUMBER_PATTERN))) {
                return [tonumber(value), required];
            }
        }
        return [value, required];
    }

    private RequireNumber(value: string): [number, boolean] {
        let required = (sub(tostring(value), 1, 1) != "!");
        if (!required) {
            value = sub(value, 2);
            return [tonumber(value), required];
        }
        return [tonumber(value), required];
    }

    private TestConditionLevel = (value: number) => {
        return this.ovalePaperDoll.level >= value;
    }

    private TestConditionMaxLevel = (value: number) => {
        return this.ovalePaperDoll.level <= value;
    }

    private TestConditionSpecialization = (value: string) => {
        let [spec, required] = this.RequireValue(value);
        let isSpec = this.ovalePaperDoll.IsSpecialization(spec);
        return (required && isSpec) || (!required && !isSpec);
    }

    private TestConditionStance = (value: string) => {
        this.compileOnStances = true;
        let [stance, required] = this.RequireValue(value);
        let isStance = this.ovaleStance.IsStance(stance, undefined);
        return (required && isStance) || (!required && !isStance);
    }

    private TestConditionSpell = (value: string) => {
        let [spell, required] = this.RequireValue(value);
        let hasSpell = this.ovaleSpellBook.IsKnownSpell(<number>spell);
        return (required && hasSpell) || (!required && !hasSpell);
    }

    private TestConditionTalent = (value: string) => {
        let [talent, required] = this.RequireNumber(value);
        let hasTalent = this.HasTalent(talent);
        return (required && hasTalent) || (!required && !hasTalent);
    }

    private TestConditionEquipped = (value: string) => {
        let [item, required] = this.RequireValue(value);
        let hasItemEquipped = this.ovaleEquipment.HasEquippedItem(item as number);
        return (required && hasItemEquipped && true) || (!required && !hasItemEquipped);
    }
    
    private TestConditionTrait = (value: string) => {
        let [trait, required] = this.RequireNumber(value);
        let hasTrait = this.ovaleAzerite.HasTrait(trait);
        return (required && hasTrait) || (!required && !hasTrait);
    }

    private TEST_CONDITION_DISPATCH: Record<keyof ConditionNamedParameters, (value: string | number) => boolean> = {
        if_spell: this.TestConditionSpell,
        if_equipped: this.TestConditionEquipped,
        if_stance: this.TestConditionStance,
        level: this.TestConditionLevel,
        maxLevel: this.TestConditionMaxLevel,
        specialization: this.TestConditionSpecialization,
        talent: this.TestConditionTalent,
        trait: this.TestConditionTrait,
        pertrait: this.TestConditionTrait
    }

    private TestConditions(positionalParams: PositionalParameters, namedParams: NamedParameters) {
        this.profiler.StartProfiling("OvaleCompile_TestConditions");
        let boolean = true;
        for (const [param, dispatch] of kpairs(this.TEST_CONDITION_DISPATCH)) {
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
            let equippedCount = this.ovaleEquipment.GetArmorSetCount(namedParams.itemset);
            boolean = (equippedCount >= namedParams.itemcount);
        }
        if (boolean && namedParams.checkbox) {
            const profile = this.ovaleOptions.db.profile;
            for (const [,checkbox] of ipairs(namedParams.checkbox)) {
                let [name, required] = this.RequireValue(checkbox);
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
            const profile = this.ovaleOptions.db.profile;
            for (const [name, listitem] of pairs(namedParams.listitem)) {
                let [item, required] = this.RequireValue(listitem);
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
        this.profiler.StopProfiling("OvaleCompile_TestConditions");
        return boolean;
    }
    
    private EvaluateAddCheckBox(node: AstNode) {
        let ok = true;
        let [name, positionalParams, namedParams] = [node.name, node.positionalParams, node.namedParams];
        if (this.TestConditions(positionalParams, namedParams)) {
            let checkBox = checkBoxes[name]
            if (!checkBox) {
                this.self_serial = this.self_serial + 1;
                this.tracer.Debug("New checkbox '%s': advance age to %d.", name, this.self_serial);
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
    
    private EvaluateAddIcon(node: AstNode) {
        let ok = true;
        let [positionalParams, namedParams] = [node.positionalParams, node.namedParams];
        if (this.TestConditions(positionalParams, namedParams)) {
            this.icon[lualength(this.icon) + 1] = node;
        }
        return ok;
    }
    
    private EvaluateAddListItem(node: AstNode) {
        let ok = true;
        let [name, item, positionalParams, namedParams] = [node.name, node.item, node.positionalParams, node.namedParams];
        if (this.TestConditions(positionalParams, namedParams)) {
            let list = lists[name]
            if (!(list && list.items && list.items[item])) {
                this.self_serial = this.self_serial + 1;
                this.tracer.Debug("New list '%s': advance age to %d.", name, this.self_serial);
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
    
    private EvaluateItemInfo(node: AstNode) {
        let ok = true;
        let [itemId, positionalParams, namedParams] = [node.itemId, node.positionalParams, node.namedParams];
        if (itemId && this.TestConditions(positionalParams, namedParams)) {
            const ii = this.ovaleData.ItemInfo(itemId);
            for (const [k, v] of kpairs(namedParams)) {
                if (k == "proc") {
                    let buff = tonumber(namedParams.buff);
                    if (buff) {
                        let name = "item_proc_" + namedParams.proc;
                        let list = this.ovaleData.buffSpellList[name] || {};
                        list[buff] = true;
                        this.ovaleData.buffSpellList[name] = list;
                    } else {
                        ok = false;
                        break;
                    }
                } else if (!checkToken(PARAMETER_KEYWORD, k)) {
                    // TODO check that is a spell info parameter
                    (<any>ii)[k] = v;
                }
            }
            this.ovaleData.itemInfo[itemId] = ii;
        }
        return ok;
    }
    
    private EvaluateItemRequire(node: AstNode) {
        let ok = true;
        let [itemId, positionalParams, namedParams] = [node.itemId, node.positionalParams, node.namedParams];
        if (this.TestConditions(positionalParams, namedParams)) {
            const property = node.property;
            let count = 0;
            let ii = this.ovaleData.ItemInfo(itemId);
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
    
    private EvaluateList(node: AstNode) {
        let ok = true;
        let [name, positionalParams, ] = [node.name, node.positionalParams, node.namedParams];
        let listDB: "itemList" | "buffSpellList";
        if (node.keyword == "ItemList") {
            listDB = "itemList";
        } else {
            listDB = "buffSpellList";
        }
        const list = this.ovaleData[listDB][name] || {};
        for (const [, _id] of pairs(positionalParams)) {
            let id = tonumber(_id);
            if (id) {
                list[id] = true;
            } else {
                ok = false;
                break;
            }
        }
        this.ovaleData[listDB][name] = list;
        return ok;
    }
    
    private EvaluateScoreSpells(node: AstNode) {
        let ok = true;
        let [positionalParams,] = [node.positionalParams, node.namedParams];
        for (const [, _spellId] of ipairs(positionalParams)) {
            let spellId = tonumber(_spellId);
            if (spellId) {
                this.ovaleScore.AddSpell(tonumber(spellId));
            } else {
                ok = false;
                break;
            }
        }
        return ok;
    }
    
    private EvaluateSpellAuraList(node: AstNode) {
        let ok = true;

        let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
        if (!spellId) {
            this.tracer.Error("No spellId for name %s", node.name);
            return false;
        }
        if (this.TestConditions(positionalParams, namedParams)) {
            let keyword = node.keyword;
            let si = this.ovaleData.SpellInfo(spellId);
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
                    if (this.ovaleData.buffSpellList[k]) {
                        tbl[k] = v;
                        count = count + 1;
                    } else {
                        const id = tonumber(k);
                        if (!id) {
                            this.tracer.Warning(`${k} is not a parameter keyword in '${node.name}' ${node.type}`);
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
    
    private EvaluateSpellInfo(node: AstNode) {
        const addpower: LuaObj<PowerType> = {}
        for (const [,powertype] of ipairs(POWER_TYPES)) {
            const key = `add${powertype}`;
            addpower[key] = powertype;
        }
        let ok = true;
        let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
        if (spellId && this.TestConditions(positionalParams, namedParams)) {
            let si = this.ovaleData.SpellInfo(spellId);
            for (const [k, v] of kpairs(namedParams)) {
                if (k == "add_duration") {
                    let value = tonumber(v);
                    if (value) {
                        let realValue = value;
                        if (namedParams.pertrait != undefined) {
                            realValue = value * this.ovaleAzerite.TraitRank(namedParams.pertrait);
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
                    let list = this.ovaleData.buffSpellList[<string>v] || {
                    }
                    list[spellId] = true;
                    this.ovaleData.buffSpellList[<string>v] = list;
                } else if (k == "dummy_replace") {
                    let [spellName] = GetSpellInfo(<string>v);
                    if (!spellName) spellName = v as string;
                    this.ovaleSpellBook.AddSpell(spellId, spellName);
                } else if (k == "learn" && v == 1) {
                    let [spellName] = GetSpellInfo(spellId);
                    this.ovaleSpellBook.AddSpell(spellId, spellName);
                } else if (k == "shared_cd") {
                    si[k] = <number>v;
                    this.ovaleCooldown.AddSharedCooldown(<string>v, spellId);
                } else if (addpower[k] != undefined) {
                    let value = tonumber(v);
                    if (value) {
                        let realValue = value;
                        if (namedParams.pertrait != undefined) {
                            realValue = value * this.ovaleAzerite.TraitRank(namedParams.pertrait);
                        }
                        let power = <number>si[k as keyof SpellInfo] || 0;
                        (<any>si)[k] = power + realValue;
                    } else {
                        ok = false;
                        break;
                    }
                } else if (!checkToken(PARAMETER_KEYWORD, k)) {
                    (<any>si)[k] = v;
                }
            }
        }
        return ok;
    }
    
    private EvaluateSpellRequire(node: AstNode) {
        let ok = true;
        let [spellId, positionalParams, namedParams] = [node.spellId, node.positionalParams, node.namedParams];
        if (this.TestConditions(positionalParams, namedParams)) {
            let property = node.property as keyof SpellInfo;
            let count = 0;
            let si = this.ovaleData.SpellInfo(spellId);
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
    
    /** This attempt to replace an unknown spell by a spell with
     * the same name that is known in a Spell function call. In the case of
     * a spell list, it tries to find the one that is known. */ 
    private AddMissingVariantSpells(annotation: AstAnnotation) {
        if (annotation.functionReference) {
            for (const [, node] of ipairs(annotation.functionReference)) {
                if (this.ovaleCondition.IsSpellBookCondition(node.func)) {
                    let [positionalParams,] = [node.positionalParams, node.namedParams];
                    let spellId = positionalParams[1];
                    if (isNumber(spellId)) {
                        if (!this.ovaleSpellBook.IsKnownSpell(spellId) && !this.ovaleCooldown.IsSharedCooldown(spellId)) {
                            const spellName = this.ovaleSpellBook.GetSpellName(spellId);
                            if (spellName) {
                                let [name] = GetSpellInfo(spellName);
                                if (spellName == name) {
                                    this.tracer.Debug("Learning spell %s with ID %d.", spellName, spellId);
                                    this.ovaleSpellBook.AddSpell(spellId, spellName);
                                }
                            } else {
                                this.tracer.Error("Unknown spell with ID %s used in %s.", spellId, getFunctionCallString(node));
                            }
                        }
                    } else if (isString(spellId)) {
                        if (!this.ovaleData.buffSpellList[spellId]) {
                            this.tracer.Error("Unknown spell list %s in %s.", spellId, getFunctionCallString(node));
                        }
                    } else if (spellId) {
                        this.tracer.Error("Spell argument must be either a spell id or a spell list name in %s.", getFunctionCallString(node))
                    }     
                }                           
            }
        }
    }
    
    private AddToBuffList(buffId: number, statName?: string, isStacking?: boolean) {
        if (statName) {
            for (const [, useName] of pairs(this.ovaleData.STAT_USE_NAMES)) {
                if (isStacking || !truthy(find(useName, "_stacking_"))) {
                    let name = `${useName}_${statName}_buff`;
                    let list = this.ovaleData.buffSpellList[name] || {};
                    list[buffId] = true;
                    this.ovaleData.buffSpellList[name] = list;
                    let shortStatName = this.ovaleData.STAT_SHORTNAME[statName];
                    if (shortStatName) {
                        name = `${useName}_${shortStatName}_buff`;
                        list = this.ovaleData.buffSpellList[name] || {
                        }
                        list[buffId] = true;
                        this.ovaleData.buffSpellList[name] = list;
                    }
                    name = `${useName}_any_buff`;
                    list = this.ovaleData.buffSpellList[name] || {
                    }
                    list[buffId] = true;
                    this.ovaleData.buffSpellList[name] = list;
                }
            }
        } else {
            let si = this.ovaleData.spellInfo[buffId];
            isStacking = si && ((si.stacking || 0) == 1 || (si.max_stacks || 0) > 0);
            if (si && si.stat) {
                let stat = si.stat;
                if (isLuaArray(stat)) {
                    for (const [, name] of ipairs(stat)) {
                        this.AddToBuffList(buffId, name, isStacking);
                    }
                } else {
                    this.AddToBuffList(buffId, stat, isStacking);
                }
            }
        }
    }

    private trinket: LuaArray<number> = {};
    UpdateTrinketInfo() {
        [this.trinket[1], this.trinket[2]] = this.ovaleEquipment.GetEquippedTrinkets();
        for (let i = 1; i <= 2; i += 1) {
            let itemId = this.trinket[i];
            let ii = itemId && this.ovaleData.ItemInfo(itemId);
            let buffId = ii && ii.buff;
            if (buffId) {
                if (isLuaArray(buffId)) {
                    for (const [, id] of ipairs(buffId)) {
                        this.AddToBuffList(id);
                    }
                } else {
                    this.AddToBuffList(buffId);
                }
            }
        }
    }
     
    private OnInitialize = () => {
        this.module.RegisterMessage("Ovale_CheckBoxValueChanged", this.ScriptControlChanged);
        this.module.RegisterMessage("Ovale_EquipmentChanged", this.EventHandler);
        this.module.RegisterMessage("Ovale_ListValueChanged", this.ScriptControlChanged);
        this.module.RegisterMessage("Ovale_ScriptChanged", this.Ovale_ScriptChanged);
        this.module.RegisterMessage("Ovale_SpecializationChanged", this.Ovale_ScriptChanged);
        this.module.RegisterMessage("Ovale_SpellsChanged", this.EventHandler);
        this.module.RegisterMessage("Ovale_StanceChanged", this.Ovale_StanceChanged);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.EventHandler);
    
        this.module.SendMessage("Ovale_ScriptChanged");
    }
    
    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_CheckBoxValueChanged");
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
        this.module.UnregisterMessage("Ovale_ListValueChanged");
        this.module.UnregisterMessage("Ovale_ScriptChanged");
        this.module.UnregisterMessage("Ovale_SpecializationChanged");
        this.module.UnregisterMessage("Ovale_SpellsChanged");
        this.module.UnregisterMessage("Ovale_StanceChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    }
    private Ovale_ScriptChanged = (event: string) => {
        this.CompileScript(this.ovaleOptions.db.profile.source[`${this.ovale.playerClass}_${this.ovalePaperDoll.GetSpecialization()}`]);
        this.EventHandler(event);
    }
    private Ovale_StanceChanged = (event: string) => {
        if (this.compileOnStances) {
            this.EventHandler(event);
        }
    }
    private ScriptControlChanged = (event: string, name: string) => {
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
    private EventHandler = (event: string) => {
        this.self_serial = this.self_serial + 1;
        this.tracer.Debug("%s: advance age to %d.", event, this.self_serial);
        this.ovale.needRefresh();
    }
    CompileScript(name: string) {
        this.ovaleDebug.ResetTrace();
        this.tracer.Debug("Compiling script '%s'.", name);
        if (this.ast) {
            this.ovaleAst.Release(this.ast);
            this.ast = undefined;
        }
        if (this.ovaleCondition.HasAny()) {
            this.ast = this.ovaleAst.parseNamedScript(name);
        }
        ResetControls();
        return this.ast;
    }
    EvaluateScript(ast?: AstNode, forceEvaluation?: boolean) {
        this.profiler.StartProfiling("OvaleCompile_EvaluateScript");
        let changed = false;
        ast = ast || this.ast;
        if (ast && (forceEvaluation || !this.serial || this.serial < this.self_serial)) {
            changed = true;
            let ok = true;
            this.compileOnStances = false;
            wipe(this.icon);
            this.ovaleData.Reset();
            this.ovaleCooldown.ResetSharedCooldowns();
            this.timesEvaluated = this.timesEvaluated + 1;
            this.serial = this.self_serial;
            for (const [, node] of ipairs(ast.child)) {
                let nodeType = node.type;
                if (nodeType == "checkbox") {
                    ok = this.EvaluateAddCheckBox(node);
                } else if (nodeType == "icon") {
                    ok = this.EvaluateAddIcon(node);
                } else if (nodeType == "list_item") {
                    ok = this.EvaluateAddListItem(node);
                } else if (nodeType == "item_info") {
                    ok = this.EvaluateItemInfo(node);
                } else if (nodeType == "item_require") {
                    ok = this.EvaluateItemRequire(node);
                } else if (nodeType == "list") {
                    ok = this.EvaluateList(node);
                } else if (nodeType == "score_spells") {
                    ok = this.EvaluateScoreSpells(node);
                } else if (nodeType == "spell_aura_list") {
                    ok = this.EvaluateSpellAuraList(node);
                } else if (nodeType == "spell_info") {
                    ok = this.EvaluateSpellInfo(node);
                } else if (nodeType == "spell_require") {
                    ok = this.EvaluateSpellRequire(node);
                } else {
                }
                if (!ok) {
                    break;
                }
            }
            if (ok) {
                this.AddMissingVariantSpells(ast.annotation);
                this.UpdateTrinketInfo();
            }
        }
        this.profiler.StopProfiling("OvaleCompile_EvaluateScript");
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
        return this.icon;
    }
    DebugCompile() {
        this.tracer.Print("Total number of times the script was evaluated: %d", this.timesEvaluated);
    }
}
