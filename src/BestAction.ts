import { OvalePool } from "./Pool";
import { OvaleTimeSpan, UNIVERSE, newTimeSpanFromArray, EMPTY_SET, newTimeSpan, releaseTimeSpans } from "./TimeSpan";
import { OvaleActionBarClass } from "./ActionBar";
import { OvaleCompileClass } from "./Compile";
import { OvaleConditionClass } from "./Condition";
import { OvaleDataClass } from "./Data";
import { OvaleEquipmentClass, SlotName } from "./Equipment";
import { OvaleStateClass } from "./State";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { abs, huge, floor, min } from "@wowts/math";
import { assert, ipairs, loadstring, pairs, tonumber, wipe, LuaObj, lualength } from "@wowts/lua";
import { GetActionCooldown, GetActionTexture, GetItemIcon, GetItemCooldown, GetItemSpell, GetSpellTexture, IsActionInRange, IsCurrentAction, IsItemInRange, IsUsableAction, IsUsableItem } from "@wowts/wow-mock";
import { AstNode, isNodeType } from "./AST";
import { OvaleCooldownClass } from "./Cooldown";
import { OvaleRunesClass } from "./Runes";
import { OvalePaperDollClass } from "./PaperDoll";
import { BaseState } from "./BaseState";
import { OvaleSpellsClass } from "./Spells";
import { isNumber, isString } from "./tools";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleGUIDClass } from "./GUID";
import { OvalePowerClass } from "./Power";
import { OvaleFutureClass } from "./Future";
import { OvaleSpellBookClass } from "./SpellBook";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { OvaleDebugClass, Tracer } from "./Debug";
import { Variables } from "./Variables";

const INFINITY = huge;

type ActionInfo = [string?, boolean?, number?, number?, boolean?, string?, boolean?, boolean?, string?, (string | number)?, string?, number?, number?];

export interface Element extends AstNode {
    serial?: number;
    timeSpan?: OvaleTimeSpan;
    result?: Element;

    actionTexture?: string;
    actionInRange?: boolean;
    actionCooldownDuration?: number;
    actionCooldownStart?: number;
    actionUsable?: boolean;
    actionShortcut?: string;
    actionIsCurrent?: boolean;
    actionEnable?: boolean;
    actionType?: string;
    actionId?: string | number;
    actionTarget?: string;
    actionResourceExtend?: number;
    actionCharges?: number;
    castTime?: number;
    offgcd?: boolean;
    lua?: string;
}

type ComputerFunction = (element: Element, atTime: number) => [OvaleTimeSpan, Element?];

export class OvaleBestActionClass {
    private self_serial = 0;
    private self_timeSpan: LuaObj<OvaleTimeSpan> = {}
    private self_valuePool = new OvalePool<Element>("OvaleBestAction_valuePool");
    private self_value: LuaObj<Element> = {}
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovaleEquipment: OvaleEquipmentClass,
        private ovaleActionBar: OvaleActionBarClass,
        private ovaleData: OvaleDataClass,
        private ovaleCooldown: OvaleCooldownClass,
        private ovaleState: OvaleStateClass,
        private baseState: BaseState,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleCompile: OvaleCompileClass,
        private ovaleCondition: OvaleConditionClass,
        private Ovale: OvaleClass,
        private OvaleGUID: OvaleGUIDClass,
        private OvalePower: OvalePowerClass,
        private OvaleFuture: OvaleFutureClass,
        private OvaleSpellBook: OvaleSpellBookClass,
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: OvaleDebugClass,
        private variables: Variables,
        private ovaleRunes: OvaleRunesClass,
        private OvaleSpells: OvaleSpellsClass

    ) {
        this.module = Ovale.createModule("BestAction", this.onInitialize, this.OnDisable, aceEvent);
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private onInitialize = () => {
        this.module.RegisterMessage("Ovale_ScriptChanged", this.Ovale_ScriptChanged);
    }
        
    private SetValue(node: AstNode, value?: number, origin?: number, rate?: number): Element {
        let result = this.self_value[node.nodeId];
        if (!result) {
            result = this.self_valuePool.Get();
            this.self_value[node.nodeId] = result;
        }
        result.type = "value";
        result.value = value || 0;
        result.origin = origin || 0;
        result.rate = rate || 0;
        return result;
    }

    private AsValue(atTime: number, timeSpan?: OvaleTimeSpan, node?: AstNode): [number, number, number, OvaleTimeSpan] {
        let value: number, origin: number, rate: number;
        if (node && isNodeType(node, "value")) {
            value = <number>node.value;
            origin = node.origin;
            rate = node.rate;
            timeSpan = timeSpan || UNIVERSE;
        } else if (timeSpan && timeSpan.HasTime(atTime)) {
            [value, origin, rate, timeSpan] = [1, 0, 0, UNIVERSE];
        } else {
            [value, origin, rate, timeSpan] = [0, 0, 0, UNIVERSE];
        }
        return [value, origin, rate, timeSpan];
    }

    private GetTimeSpan(node: AstNode, defaultTimeSpan?: OvaleTimeSpan) {
        let timeSpan = this.self_timeSpan[node.nodeId];
        if (timeSpan) {
            if (defaultTimeSpan) {
                timeSpan.copyFromArray(defaultTimeSpan);
            }
        } else {
            this.self_timeSpan[node.nodeId] = newTimeSpanFromArray(defaultTimeSpan);
            timeSpan = this.self_timeSpan[node.nodeId];
        }
        return timeSpan;
    }

    private GetActionItemInfo(element: Element, atTime: number, target: string) : ActionInfo {
        this.profiler.StartProfiling("OvaleBestAction_GetActionItemInfo");
        let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId;
        let itemId = element.positionalParams[1];
        if (!isNumber(itemId)) {
            const itemIdFromSlot = this.ovaleEquipment.GetEquippedItemBySlotName(<SlotName>itemId);
            if (!itemIdFromSlot) {
                this.tracer.Log("Unknown item '%s'.", element.positionalParams[1]);
                return [];
            }
            itemId = itemIdFromSlot;
        }
        this.tracer.Log("Item ID '%s'", itemId);
        let action = this.ovaleActionBar.GetForItem(itemId);
        let [spellName] = GetItemSpell(itemId);
        if (element.namedParams.texture) {
            actionTexture = `Interface\\Icons\\${element.namedParams.texture}`;
        }
        actionTexture = actionTexture || GetItemIcon(itemId);
        actionInRange = IsItemInRange(itemId, target);
        [actionCooldownStart, actionCooldownDuration, actionEnable] = GetItemCooldown(itemId);
        actionUsable = (spellName && IsUsableItem(itemId) && this.OvaleSpells.IsUsableItem(itemId, atTime)) || false;
        if (action) {
            actionShortcut = this.ovaleActionBar.GetBinding(action);
            actionIsCurrent = IsCurrentAction(action);
        }
        actionType = "item";
        actionId = itemId;
        this.profiler.StopProfiling("OvaleBestAction_GetActionItemInfo");
        return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent || false, actionEnable, actionType, actionId, target, 0, 0];
    }
    
    private GetActionMacroInfo(element: Element, atTime: number, target: string): ActionInfo {
        this.profiler.StartProfiling("OvaleBestAction_GetActionMacroInfo");
        let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId;
        let macro = <string>element.positionalParams[1];
        let action = this.ovaleActionBar.GetForMacro(macro);
        if (!action) {
            this.tracer.Log("Unknown macro '%s'.", macro);
            return [];
        }
        if (element.namedParams.texture) {
            actionTexture = `Interface\\Icons\\${element.namedParams.texture}`;
        }
        actionTexture = actionTexture || GetActionTexture(action);
        actionInRange = IsActionInRange(action, target);
        [actionCooldownStart, actionCooldownDuration, actionEnable] = GetActionCooldown(action);
        actionUsable = IsUsableAction(action);
        actionShortcut = this.ovaleActionBar.GetBinding(action);
        actionIsCurrent = IsCurrentAction(action);
        actionType = "macro";
        actionId = macro;
        this.profiler.StopProfiling("OvaleBestAction_GetActionMacroInfo");
        return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, 0, 0];
    }

    private GetActionSpellInfo(element: Element, atTime: number, target: string): ActionInfo {
        this.profiler.StartProfiling("OvaleBestAction_GetActionSpellInfo");
        const spell = element.positionalParams[1];
        if (isNumber(spell)) {
            return this.getSpellActionInfo(spell, element, atTime, target);
        } else if (isString(spell)) {
            const spellList = this.ovaleData.buffSpellList[spell];
            for (const [spellId] of pairs(spellList)) {
                if (this.OvaleSpellBook.IsKnownSpell(spellId)) {
                    return this.getSpellActionInfo(spellId, element, atTime, target);
                }
            }
        } 
        return [];
    }

    private getSpellActionInfo(spellId: number, element: Element, atTime: number, target: string): ActionInfo {
        let targetGUID = this.OvaleGUID.UnitGUID(target);
        let actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges;
        let si = this.ovaleData.spellInfo[spellId];
        let replacedSpellId = undefined;
        if (si && si.replaced_by) {
            let replacement = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "replaced_by", targetGUID);
            if (replacement) {
                replacedSpellId = spellId;
                spellId = replacement;
                si = this.ovaleData.spellInfo[spellId];
                this.tracer.Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId);
            }
        }
        let action = this.ovaleActionBar.GetForSpell(spellId);
        if (!action && replacedSpellId) {
            this.tracer.Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId);
            action = this.ovaleActionBar.GetForSpell(replacedSpellId);
            if (action) spellId = replacedSpellId;
        }
        let isKnownSpell = this.OvaleSpellBook.IsKnownSpell(spellId);
        if (!isKnownSpell && replacedSpellId) {
            this.tracer.Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId);
            isKnownSpell = this.OvaleSpellBook.IsKnownSpell(replacedSpellId);
            if (isKnownSpell) spellId = replacedSpellId;
        }
        if (!isKnownSpell && !action) {
            this.tracer.Log("Unknown spell ID '%s'.", spellId);
            return [];
        } 
        let [isUsable, noMana] = this.OvaleSpells.IsUsableSpell(spellId, atTime, targetGUID);
        this.tracer.Log("OvaleSpells:IsUsableSpell(%d, %f, %s) returned %d, %d", spellId, atTime, targetGUID, isUsable, noMana);
        if (!isUsable && !noMana) return [];
        if (element.namedParams.texture) {
            actionTexture = `Interface\\Icons\\${element.namedParams.texture}`;
        }
        actionTexture = actionTexture || GetSpellTexture(spellId);
        actionInRange = this.OvaleSpells.IsSpellInRange(spellId, target);
        [actionCooldownStart, actionCooldownDuration, actionEnable] = this.ovaleCooldown.GetSpellCooldown(spellId, atTime);

        this.tracer.Log("GetSpellCooldown returned %f, %f", actionCooldownStart, actionCooldownDuration);
        [actionCharges] = this.ovaleCooldown.GetSpellCharges(spellId, atTime);
        actionResourceExtend = 0;
        actionUsable = isUsable;
        if (action) {
            actionShortcut = this.ovaleActionBar.GetBinding(action);
            actionIsCurrent = IsCurrentAction(action);
        }
        actionType = "spell";
        actionId = spellId;
        if (si) {
            if (si.texture) {
                actionTexture = `Interface\\Icons\\${si.texture}`;
            }
            if (actionCooldownStart && actionCooldownDuration) {
                let extraPower = <number>element.namedParams.extra_amount || 0;
                // let seconds = OvaleSpells.GetTimeToSpell(spellId, atTime, targetGUID, extraPower);
                let timeToCd = (actionCooldownDuration > 0) && (actionCooldownStart + actionCooldownDuration - atTime) || 0;
                let timeToPower = this.OvalePower.TimeToPower(spellId, atTime, targetGUID, undefined, extraPower);
                let runes = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "runes", targetGUID);
                if (runes) {
                    let timeToRunes = this.ovaleRunes.GetRunesCooldown(atTime, <number>runes);
                    if (timeToPower < timeToRunes) {
                        timeToPower = timeToRunes;
                    }
                }
                if (timeToPower > timeToCd) {
                    actionResourceExtend = timeToPower - timeToCd;
                    this.tracer.Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, actionResourceExtend);
                }
            }
        }
        this.profiler.StopProfiling("OvaleBestAction_GetActionSpellInfo");
        return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent || false, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges];
    }

    private GetActionTextureInfo(element: Element, atTime: number, target: string): ActionInfo {
        this.profiler.StartProfiling("OvaleBestAction_GetActionTextureInfo");
        let actionTexture;
        {
            let texture = element.positionalParams[1];
            let spellId = tonumber(texture);
            if (spellId) {
                actionTexture = GetSpellTexture(spellId);
            } else {
                actionTexture = `Interface\\Icons\\${texture}`;
            }
        }
        let actionInRange = false;
        let actionCooldownStart = 0;
        let actionCooldownDuration = 0;
        let actionEnable = true;
        let actionUsable = true;
        let actionShortcut = undefined;
        let actionIsCurrent = false;
        let actionType = "texture";
        let actionId = actionTexture;
        this.profiler.StopProfiling("OvaleBestAction_GetActionTextureInfo");
        return [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, 0, 0];
    }

    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_ScriptChanged");
    }
    private Ovale_ScriptChanged = () => {
        for (const [node, timeSpan] of pairs(this.self_timeSpan)) {
            timeSpan.Release();
            delete this.self_timeSpan[node];
        }
        for (const [node, value] of pairs(this.self_value)) {
            this.self_valuePool.Release(value);
            delete this.self_value[node];
        }
    }
    public StartNewAction() {
        this.ovaleState.ResetState();
        this.OvaleFuture.ApplyInFlightSpells();
        this.self_serial = this.self_serial + 1;
    }
    public GetActionInfo(element: Element | undefined, atTime: number): ActionInfo {
        if (element && element.type == "action") {
            if (element.serial && element.serial >= this.self_serial) {
                this.tracer.Log("[%d]    using cached result (age = %d/%d)", element.nodeId, element.serial, this.self_serial);
                return [element.actionTexture, element.actionInRange, element.actionCooldownStart, element.actionCooldownDuration, element.actionUsable, element.actionShortcut, element.actionIsCurrent, element.actionEnable, element.actionType, element.actionId, element.actionTarget, element.actionResourceExtend, element.actionCharges];
            } else {
                let target = <string>element.namedParams.target || this.baseState.next.defaultTarget;
                if (element.name == "item") {
                    return this.GetActionItemInfo(element, atTime, target);
                } else if (element.name == "macro") {
                    return this.GetActionMacroInfo(element, atTime, target);
                } else if (element.name == "spell") {
                    return this.GetActionSpellInfo(element, atTime, target);
                } else if (element.name == "texture") {
                    return this.GetActionTextureInfo(element, atTime, target);
                }
            }
        }
        return [];
    }
    
    public GetAction(node: AstNode, atTime: number):[OvaleTimeSpan, Element | undefined] {
        this.profiler.StartProfiling("OvaleBestAction_GetAction");
        let groupNode = node.child[1];
        let [timeSpan, element] = this.PostOrderCompute(groupNode, atTime);
        if (element && element.type == "state" && timeSpan) {
            let [variable, value] = [element.positionalParams[1], element.positionalParams[2]];
            let isFuture = !timeSpan.HasTime(atTime);
            this.variables.PutState(<string>variable, <number>value, isFuture, atTime);
        }
        this.profiler.StopProfiling("OvaleBestAction_GetAction");
        return [timeSpan, element];
    }

    private PostOrderCompute(element: Element, atTime: number): [OvaleTimeSpan, Element | undefined] {
        this.profiler.StartProfiling("OvaleBestAction_PostOrderCompute");
        let timeSpan: OvaleTimeSpan, result: Element | undefined;
        let postOrder = element.postOrder;
        if (postOrder && !(element.serial && element.serial >= this.self_serial)) {
            let index = 1;
            let N = lualength(postOrder);
            while (index < N) {
                let [childNode, parentNode] = [postOrder[index], postOrder[index + 1]];
                index = index + 2;
                [timeSpan, result] = this.PostOrderCompute(childNode, atTime);
                if (parentNode && timeSpan) {
                    let shortCircuit = false;
                    if (parentNode.child && parentNode.child[1] == childNode) {
                        if (parentNode.type == "if" && timeSpan.Measure() == 0) {
                            this.tracer.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "unless" && timeSpan.IsUniverse()) {
                            this.tracer.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "logical" && parentNode.operator == "and" && timeSpan.Measure() == 0) {
                            this.tracer.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        } else if (parentNode.type == "logical" && parentNode.operator == "or" && timeSpan.IsUniverse()) {
                            this.tracer.Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId);
                            shortCircuit = true;
                        }
                    }
                    if (shortCircuit) {
                        while (parentNode != postOrder[index] && index <= N) {
                            index = index + 2;
                        }
                        if (index > N) {
                            this.tracer.Error("Ran off end of postOrder node list for node %d.", element.nodeId);
                        }
                    }
                }
            }
        }
        [timeSpan, result] = this.RecursiveCompute(element, atTime);
        this.profiler.StopProfiling("OvaleBestAction_PostOrderCompute");
        return [timeSpan, result];
    }
    private RecursiveCompute(element: Element, atTime: number): [OvaleTimeSpan, Element?] {
        this.profiler.StartProfiling("OvaleBestAction_RecursiveCompute");
        let timeSpan: OvaleTimeSpan, result: Element | undefined;
        if (element) {
            if (element.serial == -1) {
                this.Ovale.OneTimeMessage("Recursive call is not supported. This is a known bug with arcane mage script");
                return [EMPTY_SET, element.result];
            }
            else if (element.serial && element.serial >= this.self_serial) {
                timeSpan = element.timeSpan || EMPTY_SET;
                result = element.result;
            } else {
                if (element.asString) {
                    this.tracer.Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString);
                } else {
                    this.tracer.Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime);
                }
                element.serial = -1;
                let visitor = this.COMPUTE_VISITOR[element.type];
                if (visitor) {
                    [timeSpan, result] = visitor(element, atTime);
                    element.serial = this.self_serial;
                    element.timeSpan = timeSpan;
                    element.result = result;
                } else {
                    this.tracer.Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type);
                    timeSpan = EMPTY_SET;
                }
                if (result && isNodeType(result, "value")) {
                    this.tracer.Log("[%d] <<< '%s' returns %s with value = %s, %s, %s", element.nodeId, element.type, timeSpan, result.value, result.origin, result.rate);
                } else if (result && result.nodeId) {
                    this.tracer.Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, timeSpan);
                } else {
                    this.tracer.Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, timeSpan);
                }
            }
        } else {
            timeSpan = EMPTY_SET;
        }
        this.profiler.StopProfiling("OvaleBestAction_RecursiveCompute");
        return [timeSpan, result];
    }
    private ComputeBool(element: Element, atTime: number) {
        let [timeSpan, newElement] = this.Compute(element, atTime);
        if (newElement && isNodeType(newElement, "value") && newElement.value == 0 && newElement.rate == 0) {
            return EMPTY_SET;
        } else {
            return timeSpan;
        }
    }
    private ComputeAction: ComputerFunction = (element, atTime: number): [OvaleTimeSpan, any] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeAction");
        let nodeId = element.nodeId;
        let timeSpan = this.GetTimeSpan(element);
        let result;
        this.tracer.Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString);
        let [actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend, actionCharges] = this.GetActionInfo(element, atTime);
        element.actionTexture = actionTexture;
        element.actionInRange = actionInRange;
        element.actionCooldownStart = actionCooldownStart;
        element.actionCooldownDuration = actionCooldownDuration;
        element.actionUsable = actionUsable;
        element.actionShortcut = actionShortcut;
        element.actionIsCurrent = actionIsCurrent;
        element.actionEnable = actionEnable;
        element.actionType = actionType;
        element.actionId = actionId;
        element.actionTarget = actionTarget;
        element.actionResourceExtend = actionResourceExtend;
        element.actionCharges = actionCharges;
        let action = element.positionalParams[1];
        if (!actionTexture) {
            this.tracer.Log("[%d]    Action %s not found.", nodeId, action);
            wipe(timeSpan);
        } else if (!actionEnable) {
            this.tracer.Log("[%d]    Action %s not enabled.", nodeId, action);
            wipe(timeSpan);
        } else if (element.namedParams.usable == 1 && !actionUsable) {
            this.tracer.Log("[%d]    Action %s not usable.", nodeId, action);
            wipe(timeSpan);
        } else {
            let spellInfo;
            if (actionType == "spell") {
                let spellId = <number>actionId;
                if (spellId) spellInfo = this.ovaleData.spellInfo[spellId];
                if (spellInfo && spellInfo.casttime) {
                    element.castTime = <number>spellInfo.casttime;
                } else {
                    element.castTime = this.OvaleSpellBook.GetCastTime(spellId);
                }
            } else {
                element.castTime = 0;
            }
            let start: number;
            if (actionCooldownStart && actionCooldownStart > 0 && (actionCharges == undefined || actionCharges == 0)) {
                this.tracer.Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, actionCharges || "(nil)");
                if (actionCooldownDuration && actionCooldownDuration > 0) {
                    this.tracer.Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration);
                    start = actionCooldownStart + actionCooldownDuration;
                } else {
                    this.tracer.Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, actionCooldownStart);
                    start = actionCooldownStart;
                }
            } else {
                if (actionCharges == undefined) {
                    this.tracer.Log("[%d]    Action %s is off cooldown.", nodeId, action);
                    start = atTime;
                } else if (actionCooldownDuration && actionCooldownDuration > 0) {
                    this.tracer.Log("[%d]    Action %s still has %f charges and is not on GCD.", nodeId, action, actionCharges);
                    start = atTime;
                }
                else {
                    this.tracer.Log("[%d]    Action %s still has %f charges but is on GCD (start=%f).", nodeId, action, actionCharges, actionCooldownStart);
                    start = actionCooldownStart || 0;
                }
            }
            if (actionResourceExtend && actionResourceExtend > 0) {
                if (element.namedParams.pool_resource && element.namedParams.pool_resource == 1) {
                    this.tracer.Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action);
                } else {
                    this.tracer.Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, actionResourceExtend);
                    start = start + actionResourceExtend;
                }
            }
            this.tracer.Log("[%d]    start=%f atTime=%f", nodeId, start, atTime);
            let offgcd = element.namedParams.offgcd || (spellInfo && spellInfo.offgcd) || 0;
            element.offgcd = (offgcd == 1) && true || undefined;
            if (element.offgcd) {
                this.tracer.Log("[%d]    Action %s is off the global cooldown.", nodeId, action);
            } else if (start < atTime) {
                this.tracer.Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action);
                let newStart = atTime;
                if (this.OvaleFuture.IsChanneling(atTime)) {
                    let spell = this.OvaleFuture.GetCurrentCast(atTime);
                    if (spell) {
                        let si = spell.spellId && this.ovaleData.spellInfo[spell.spellId];
                        if (si) {
                            let channel = si.channel || si.canStopChannelling;
                            if (channel) {
                                let hasteMultiplier = this.ovalePaperDoll.GetHasteMultiplier(si.haste, this.ovalePaperDoll.next);
                                let numTicks = floor(channel * hasteMultiplier + 0.5);
                                let tick = (spell.stop - spell.start) / numTicks;
                                let tickTime = spell.start;
                                for (let i = 1; i <= numTicks; i += 1) {
                                    tickTime = tickTime + tick;
                                    if (newStart <= tickTime) {
                                        break;
                                    }
                                }
                                newStart = tickTime;
                                this.tracer.Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spell.spellId, newStart, numTicks, tick, tickTime);
                            }
                        }
                    }                    
                }
                if (start < newStart) {
                    start = newStart;
                }
            }
            this.tracer.Log("[%d]    Action %s can start at %f.", nodeId, action, start);
            timeSpan.Copy(start, INFINITY);
            result = element;
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeAction");
        return [timeSpan, result];
    }
    private ComputeArithmetic: ComputerFunction = (element, atTime): [OvaleTimeSpan, Element?] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeArithmetic");
        let timeSpan = this.GetTimeSpan(element);
        let result: Element;
        const [rawTimeSpanA, nodeA] = this.Compute(element.child[1], atTime);
        let [a, b, c, timeSpanA] = this.AsValue(atTime, rawTimeSpanA, nodeA);
        const [rawTimeSpanB, nodeB] = this.Compute(element.child[2], atTime);
        let [x, y, z, timeSpanB] = this.AsValue(atTime, rawTimeSpanB, nodeB);
        timeSpanA.Intersect(timeSpanB, timeSpan);
        if (timeSpan.Measure() == 0) {
            this.tracer.Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan);
            result = this.SetValue(element, 0);
        } else {
            let operator = element.operator;
            let t = atTime;
            this.tracer.Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z);
            let l, m, n; // The new value, origin, and rate
            let A = a + (t - b) * c; // the A value at time t
            let B = x + (t - y) * z; // The B value at time t
            if (operator == "+") {
                l = A + B;
                m = t;
                n = c + z;
            } else if (operator == "-") {
                l = A - B;
                m = t;
                n = c - z;
            } else if (operator == "*") {
                l = A * B;
                m = t;
                n = A * z + B * c;
            } else if (operator == "/") {
                if (B === 0) {
                    if (A !== 0) {
                        this.Ovale.OneTimeMessage("[%d] Division by 0 in %s", element.nodeId, element.asString);
                    }
                    B = 0.00001;
                }
                l = A / B;
                m = t;
                let numerator = B * c - A * z;
                if (numerator != INFINITY) {
                    n = numerator / (B ^ 2);
                } else {
                    n = numerator;
                }
                let bound;
                if (z == 0) {
                    bound = INFINITY;
                } else {
                    bound = abs(B / z);
                }
                let scratch = timeSpan.IntersectInterval(t - bound, t + bound);
                timeSpan.copyFromArray(scratch);
                scratch.Release();
            } else if (operator == "%") {
                if (c == 0 && z == 0) {
                    l = A % B;
                    m = t;
                    n = 0;
                } else {
                    this.tracer.Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId);
                    l = 0;
                    m = 0;
                    n = 0;
                }
            } else if (operator === ">?") {
                l = min(A, B);
                m = t;
                // TODO should change the end
                if (l === A) {
                    n = c;
                } else {
                    n = z;
                }
            } else if (operator === "<?") {
                l = min(A, B);
                m = t;
                if (l === A) {
                    n = z;
                } else {
                    n = c;
                }
            }
            this.tracer.Log("[%d]    arithmetic '%s' returns %s+(t-%s)*%s", element.nodeId, operator, l, m, n);
            result = this.SetValue(element, l, m, n);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeArithmetic");
        return [timeSpan, result];
    }
    private ComputeCompare: ComputerFunction = (element, atTime) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeCompare");
        let timeSpan = this.GetTimeSpan(element);
        const [rawTimeSpanA, elementA] = this.Compute(element.child[1], atTime);
        let [a, b, c, timeSpanA] = this.AsValue(atTime, rawTimeSpanA, elementA);
        const [rawTimeSpanB, elementB] = this.Compute(element.child[2], atTime);
        let [x, y, z, timeSpanB] = this.AsValue(atTime, rawTimeSpanB, elementB);
        timeSpanA.Intersect(timeSpanB, timeSpan);
        if (timeSpan.Measure() == 0) {
            this.tracer.Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan);
        } else {
            let operator = element.operator;
            this.tracer.Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z);
            let A = a - b * c;
            let B = x - y * z;
            if (c == z) {
                if (!((operator == "==" && A == B) || (operator == "!=" && A != B) || (operator == "<" && A < B) || (operator == "<=" && A <= B) || (operator == ">" && A > B) || (operator == ">=" && A >= B))) {
                    wipe(timeSpan);
                }
            } else {
                let diff = B - A;
                let t;
                if (diff == INFINITY) {
                    t = INFINITY;
                } else {
                    t = diff / (c - z);
                }
                t = (t > 0) && t || 0;
                this.tracer.Log("[%d]    intersection at t = %s", element.nodeId, t);
                let scratch: OvaleTimeSpan | undefined;
                if ((c > z && operator == "<") || (c > z && operator == "<=") || (c < z && operator == ">") || (c < z && operator == ">=")) {
                    scratch = timeSpan.IntersectInterval(0, t);
                } else if ((c < z && operator == "<") || (c < z && operator == "<=") || (c > z && operator == ">") || (c > z && operator == ">=")) {
                    scratch = timeSpan.IntersectInterval(t, INFINITY);
                }
                if (scratch) {
                    timeSpan.copyFromArray(scratch);
                    scratch.Release();
                } else {
                    wipe(timeSpan);
                }
            }
            this.tracer.Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeCompare");
        return [timeSpan, element];
    }
    private ComputeCustomFunction = (element: Element, atTime: number): [OvaleTimeSpan, Element | undefined] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeCustomFunction");
        let timeSpan = this.GetTimeSpan(element);
        let result: Element | undefined;
        let node = this.ovaleCompile.GetFunctionNode(element.name);
        if (node) {
            let [timeSpanA, elementA] = this.Compute(node.child[1], atTime);
            if (timeSpanA) timeSpan.copyFromArray(timeSpanA);
            result = elementA;
        } else {
            wipe(timeSpan);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeCustomFunction");
        return [timeSpan, result];
    }
    private ComputeFunction: ComputerFunction = (element, atTime: number): [OvaleTimeSpan, Element | undefined] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeFunction");
        let timeSpan = this.GetTimeSpan(element);
        let result;
        const [start, ending, value, origin, rate] = this.ovaleCondition.EvaluateCondition(element.func, element.positionalParams, element.namedParams, atTime);
        if (start !== undefined && ending !== undefined) {
            timeSpan.Copy(start, ending);
        } else {
            wipe(timeSpan);
        }
        if (value !== undefined) {
            result = this.SetValue(element, value, origin, rate);
        }
        this.tracer.Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate);
        this.profiler.StopProfiling("OvaleBestAction_ComputeFunction");
        return [timeSpan, result];
    }
    private ComputeGroup: ComputerFunction = (element, atTime): [OvaleTimeSpan, Element?] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeGroup");
        let bestTimeSpan, bestElement;
        let best = newTimeSpan();
        let current = newTimeSpan();
        for (const [, node] of ipairs(element.child)) {
            let [currentTimeSpan, currentElement] = this.Compute(node, atTime);
            currentTimeSpan.IntersectInterval(atTime, INFINITY, current);
            if (current.Measure() > 0) {
                let nodeString = (currentElement && currentElement.nodeId) && ` [${currentElement.nodeId}]` || "";
                this.tracer.Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                let currentCastTime;
                if (currentElement) {
                    currentCastTime = currentElement.castTime;
                }
                let gcd = this.OvaleFuture.GetGCD(undefined, atTime);
                if (!currentCastTime || currentCastTime < gcd) {
                    currentCastTime = gcd;
                }
                let currentIsBetter = false;
                if (best.Measure() == 0) {
                    this.tracer.Log("[%d]    group first best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                    currentIsBetter = true;
                } else {
                    let threshold = (bestElement && bestElement.namedParams) && bestElement.namedParams.wait || 0;
                    if (best[1] - current[1] > threshold) {
                        this.tracer.Log("[%d]    group new best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString);
                        currentIsBetter = true;
                    }
                }
                if (currentIsBetter) {
                    best.copyFromArray(current);
                    bestTimeSpan = currentTimeSpan;
                    bestElement = currentElement;
                }
            }
        }
        releaseTimeSpans(best, current);
        let timeSpan = this.GetTimeSpan(element, bestTimeSpan);
        if (!bestTimeSpan) {
            wipe(timeSpan);
        }
        if (bestElement) {
            let id = bestElement.value;
            if (bestElement.positionalParams) {
                id = <number>bestElement.positionalParams[1];
            }
            this.tracer.Log("[%d]    group best action %s remains %s", element.nodeId, id, timeSpan);
        } else {
            this.tracer.Log("[%d]    group no best action returns %s", element.nodeId, timeSpan);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeGroup");
        return [timeSpan, bestElement];
    }
    private ComputeIf: ComputerFunction = (element, atTime): [OvaleTimeSpan, Element?] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeIf");
        let timeSpan = this.GetTimeSpan(element);
        let result;
        let timeSpanA = this.ComputeBool(element.child[1], atTime);
        let conditionTimeSpan = timeSpanA;
        if (element.type == "unless") {
            conditionTimeSpan = timeSpanA.Complement();
        }
        if (conditionTimeSpan.Measure() == 0) {
            timeSpan.copyFromArray(conditionTimeSpan);
            this.tracer.Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan);
        } else {
            let [timeSpanB, elementB] = this.Compute(element.child[2], atTime);
            conditionTimeSpan.Intersect(timeSpanB, timeSpan);
            this.tracer.Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB);
            result = elementB;
        }
        if (element.type == "unless") {
            conditionTimeSpan.Release();
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeIf");
        return [timeSpan, result];
    }
    private ComputeLogical: ComputerFunction = (element, atTime) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeLogical");
        let timeSpan = this.GetTimeSpan(element);
        let timeSpanA = this.ComputeBool(element.child[1], atTime);
        if (element.operator == "and") {
            if (timeSpanA.Measure() == 0) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator);
            } else {
                let timeSpanB = this.ComputeBool(element.child[2], atTime);
                timeSpanA.Intersect(timeSpanB, timeSpan);
            }
        } else if (element.operator == "not") {
            timeSpanA.Complement(timeSpan);
        } else if (element.operator == "or") {
            if (timeSpanA.IsUniverse()) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator);
            } else {
                let timeSpanB = this.ComputeBool(element.child[2], atTime);
                timeSpanA.Union(timeSpanB, timeSpan);
            }
        } else if (element.operator == "xor") {
            let timeSpanB = this.ComputeBool(element.child[2], atTime);
            let left = timeSpanA.Union(timeSpanB);
            let scratch = timeSpanA.Intersect(timeSpanB);
            let right = scratch.Complement();
            left.Intersect(right, timeSpan);
            releaseTimeSpans(left, scratch, right);
        } else {
            wipe(timeSpan);
        }

        this.tracer.Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan);
        this.profiler.StopProfiling("OvaleBestAction_ComputeLogical");
        return [timeSpan, element];
    }
    private ComputeLua: ComputerFunction = (element: Element, atTime) => {
        if (!element.lua) return [EMPTY_SET];
        this.profiler.StartProfiling("OvaleBestAction_ComputeLua");
        let value = loadstring(element.lua)();
        this.tracer.Log("[%d]    lua returns %s", element.nodeId, value);
        let result;
        if (value) {
            result = this.SetValue(element, value);
        }
        let timeSpan = this.GetTimeSpan(element, UNIVERSE);
        this.profiler.StopProfiling("OvaleBestAction_ComputeLua");
        return [timeSpan, result];
    }
    private ComputeState: ComputerFunction = (element: Element, atTime): [OvaleTimeSpan, Element?] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeState");
        let result = element;
        assert(element.func == "setstate");
        const name = element.positionalParams[1] as string;
        const value = element.positionalParams[2] as number;
        this.tracer.Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2]);
        const currentValue = this.variables.GetState(name);
        let timeSpan;
        if (currentValue !== value) {
            timeSpan = this.GetTimeSpan(element, UNIVERSE);
        } else {
            timeSpan = EMPTY_SET;
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeState");
        return [timeSpan, result];
    }
    private ComputeValue: ComputerFunction = (element: Element, atTime): [OvaleTimeSpan, Element?] => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeValue");
        this.tracer.Log("[%d]    value is %s", element.nodeId, element.value);
        let timeSpan = this.GetTimeSpan(element, UNIVERSE);
        this.profiler.StopProfiling("OvaleBestAction_ComputeValue");
        return [timeSpan, element];
    }

    public Compute(element: Element, atTime: number): [OvaleTimeSpan, Element?] {
        return this.PostOrderCompute(element, atTime);
    }

    COMPUTE_VISITOR: LuaObj<ComputerFunction> = {
        ["action"]: this.ComputeAction,
        ["arithmetic"]: this.ComputeArithmetic,
        ["compare"]: this.ComputeCompare,
        ["custom_function"]: this.ComputeCustomFunction,
        ["function"]: this.ComputeFunction,
        ["group"]: this.ComputeGroup,
        ["if"]: this.ComputeIf,
        ["logical"]: this.ComputeLogical,
        ["lua"]: this.ComputeLua,
        ["state"]: this.ComputeState,
        ["unless"]: this.ComputeIf,
        ["value"]: this.ComputeValue
    }
}
