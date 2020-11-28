import { OvaleActionBarClass } from "./ActionBar";
import { OvaleDataClass } from "./Data";
import { OvaleEquipmentClass, SlotName } from "../states/Equipment";
import { OvaleStateClass } from "./State";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, tonumber } from "@wowts/lua";
import {
    GetActionCooldown,
    GetActionTexture,
    GetItemIcon,
    GetItemCooldown,
    GetItemSpell,
    GetSpellTexture,
    IsActionInRange,
    IsCurrentAction,
    IsItemInRange,
    IsUsableAction,
    IsUsableItem,
} from "@wowts/wow-mock";
import {
    AstFunctionNode,
    AstIconNode,
    AstNodeSnapshot,
    NodeActionResult,
    NodeNoResult,
    setResultType,
} from "./AST";
import { OvaleCooldownClass } from "../states/Cooldown";
import { OvaleRunesClass } from "../states/Runes";
import { OvaleSpellsClass } from "../states/Spells";
import { isNumber, isString } from "../tools/tools";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleGUIDClass } from "./GUID";
import { OvalePowerClass } from "../states/Power";
import { OvaleFutureClass } from "../states/Future";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { OvaleDebugClass, Tracer } from "./Debug";
import { Variables } from "../states/Variables";
import { ActionInfoHandler, Runner } from "./runner";

export type ActionType = "item" | "spell" | "texture" | "macro" | "value";

export class OvaleBestActionClass {
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovaleEquipment: OvaleEquipmentClass,
        private ovaleActionBar: OvaleActionBarClass,
        private ovaleData: OvaleDataClass,
        private ovaleCooldown: OvaleCooldownClass,
        private ovaleState: OvaleStateClass,
        Ovale: OvaleClass,
        private OvaleGUID: OvaleGUIDClass,
        private OvalePower: OvalePowerClass,
        private OvaleFuture: OvaleFutureClass,
        private OvaleSpellBook: OvaleSpellBookClass,
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: OvaleDebugClass,
        private variables: Variables,
        private ovaleRunes: OvaleRunesClass,
        private OvaleSpells: OvaleSpellsClass,
        private runner: Runner
    ) {
        this.module = Ovale.createModule(
            "BestAction",
            this.onInitialize,
            this.OnDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
        runner.registerActionInfoHandler("item", this.GetActionItemInfo);
        runner.registerActionInfoHandler("macro", this.GetActionMacroInfo);
        runner.registerActionInfoHandler("spell", this.GetActionSpellInfo);
        runner.registerActionInfoHandler("texture", this.GetActionTextureInfo);
    }

    private onInitialize = () => {};

    private GetActionItemInfo: ActionInfoHandler = (node, atTime, target) => {
        this.profiler.StartProfiling("OvaleBestAction_GetActionItemInfo");
        let itemId = node.cachedParams.positional[1];
        const result = node.result;
        setResultType(result, "action");
        if (!isNumber(itemId)) {
            const itemIdFromSlot = this.ovaleEquipment.GetEquippedItemBySlotName(
                <SlotName>itemId
            );
            if (!itemIdFromSlot) {
                this.tracer.Log("Unknown item '%s'.", itemId);
                return result;
            }
            itemId = itemIdFromSlot;
        }
        this.tracer.Log("Item ID '%s'", itemId);
        const action = this.ovaleActionBar.GetForItem(itemId);
        const [spellName] = GetItemSpell(itemId);
        if (node.cachedParams.named.texture) {
            result.actionTexture = `Interface\\Icons\\${node.cachedParams.named.texture}`;
        }
        result.actionTexture = result.actionTexture || GetItemIcon(itemId);
        result.actionInRange = IsItemInRange(itemId, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = GetItemCooldown(itemId);
        result.actionUsable =
            (spellName &&
                IsUsableItem(itemId) &&
                this.OvaleSpells.IsUsableItem(itemId, atTime)) ||
            false;
        if (action) {
            result.actionShortcut = this.ovaleActionBar.GetBinding(action);
            result.actionIsCurrent = IsCurrentAction(action);
        }
        result.actionType = "item";
        result.actionId = itemId;
        result.actionTarget = target;
        result.castTime = this.OvaleFuture.GetGCD(undefined, atTime);
        this.profiler.StopProfiling("OvaleBestAction_GetActionItemInfo");
        return result;
    };

    private GetActionMacroInfo: ActionInfoHandler = (
        element,
        atTime,
        target
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_GetActionMacroInfo");
        const result = element.result;
        const macro = <string>element.cachedParams.positional[1];
        const action = this.ovaleActionBar.GetForMacro(macro);
        setResultType(result, "action");
        if (!action) {
            this.tracer.Log("Unknown macro '%s'.", macro);
            return result;
        }
        if (element.cachedParams.named.texture) {
            result.actionTexture = `Interface\\Icons\\${element.cachedParams.named.texture}`;
        }
        result.actionTexture = result.actionTexture || GetActionTexture(action);
        result.actionInRange = IsActionInRange(action, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = GetActionCooldown(action);
        result.actionUsable = IsUsableAction(action);
        result.actionShortcut = this.ovaleActionBar.GetBinding(action);
        result.actionIsCurrent = IsCurrentAction(action);
        result.actionType = "macro";
        result.actionId = macro;
        result.castTime = this.OvaleFuture.GetGCD(undefined, atTime);
        this.profiler.StopProfiling("OvaleBestAction_GetActionMacroInfo");
        return result;
    };

    private GetActionSpellInfo: ActionInfoHandler = (
        element,
        atTime,
        target
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_GetActionSpellInfo");
        const spell = element.cachedParams.positional[1];
        if (isNumber(spell)) {
            return this.getSpellActionInfo(spell, element, atTime, target);
        } else if (isString(spell)) {
            const spellList = this.ovaleData.buffSpellList[spell];
            if (spellList) {
                for (const [spellId] of pairs(spellList)) {
                    if (this.OvaleSpellBook.IsKnownSpell(spellId)) {
                        return this.getSpellActionInfo(
                            spellId,
                            element,
                            atTime,
                            target
                        );
                    }
                }
            }
        }
        setResultType(element.result, "action");
        return element.result;
    };

    private getSpellActionInfo(
        spellId: number,
        element: AstFunctionNode,
        atTime: number,
        target: string
    ): NodeActionResult | NodeNoResult {
        const targetGUID = this.OvaleGUID.UnitGUID(target);
        const result = element.result;
        let si = this.ovaleData.spellInfo[spellId];
        let replacedSpellId = undefined;
        if (si) {
            const replacement = this.ovaleData.GetSpellInfoProperty(
                spellId,
                atTime,
                "replaced_by",
                targetGUID
            );
            if (replacement) {
                replacedSpellId = spellId;
                spellId = replacement;
                si = this.ovaleData.spellInfo[spellId];
                this.tracer.Log(
                    "Spell ID '%s' is replaced by spell ID '%s'.",
                    replacedSpellId,
                    spellId
                );
            }
        }
        let action = this.ovaleActionBar.GetForSpell(spellId);
        if (!action && replacedSpellId) {
            this.tracer.Log(
                "Action not found for spell ID '%s'; checking for replaced spell ID '%s'.",
                spellId,
                replacedSpellId
            );
            action = this.ovaleActionBar.GetForSpell(replacedSpellId);
            if (action) spellId = replacedSpellId;
        }
        let isKnownSpell = this.OvaleSpellBook.IsKnownSpell(spellId);
        if (!isKnownSpell && replacedSpellId) {
            this.tracer.Log(
                "Spell ID '%s' is not known; checking for replaced spell ID '%s'.",
                spellId,
                replacedSpellId
            );
            isKnownSpell = this.OvaleSpellBook.IsKnownSpell(replacedSpellId);
            if (isKnownSpell) spellId = replacedSpellId;
        }
        if (!isKnownSpell && !action) {
            setResultType(result, "none");
            this.tracer.Log("Unknown spell ID '%s'.", spellId);
            return result;
        }
        const [isUsable, noMana] = this.OvaleSpells.IsUsableSpell(
            spellId,
            atTime,
            targetGUID
        );
        this.tracer.Log(
            "OvaleSpells:IsUsableSpell(%d, %f, %s) returned %s, %s",
            spellId,
            atTime,
            targetGUID,
            isUsable,
            noMana
        );
        if (!isUsable && !noMana) {
            setResultType(result, "none");
            return result;
        }
        setResultType(result, "action");
        if (element.cachedParams.named.texture) {
            result.actionTexture = `Interface\\Icons\\${element.cachedParams.named.texture}`;
        }
        result.actionTexture = result.actionTexture || GetSpellTexture(spellId);
        result.actionInRange = this.OvaleSpells.IsSpellInRange(spellId, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = this.ovaleCooldown.GetSpellCooldown(spellId, atTime);

        this.tracer.Log(
            "GetSpellCooldown returned %f, %f",
            result.actionCooldownStart,
            result.actionCooldownDuration
        );
        [result.actionCharges] = this.ovaleCooldown.GetSpellCharges(
            spellId,
            atTime
        );
        result.actionResourceExtend = 0;
        result.actionUsable = isUsable;
        if (action) {
            result.actionShortcut = this.ovaleActionBar.GetBinding(action);
            result.actionIsCurrent = IsCurrentAction(action);
        }
        result.actionType = "spell";
        result.actionId = spellId;
        if (si) {
            if (si.texture) {
                result.actionTexture = `Interface\\Icons\\${si.texture}`;
            }
            if (result.actionCooldownStart && result.actionCooldownDuration) {
                const extraPower =
                    <number>element.cachedParams.named.extra_amount || 0;
                // let seconds = OvaleSpells.GetTimeToSpell(spellId, atTime, targetGUID, extraPower);
                const timeToCd =
                    (result.actionCooldownDuration > 0 &&
                        result.actionCooldownStart +
                            result.actionCooldownDuration -
                            atTime) ||
                    0;
                let timeToPower = this.OvalePower.TimeToPower(
                    spellId,
                    atTime,
                    targetGUID,
                    undefined,
                    extraPower
                );
                const runes = this.ovaleData.GetSpellInfoProperty(
                    spellId,
                    atTime,
                    "runes",
                    targetGUID
                );
                if (runes) {
                    const timeToRunes = this.ovaleRunes.GetRunesCooldown(
                        atTime,
                        <number>runes
                    );
                    if (timeToPower < timeToRunes) {
                        timeToPower = timeToRunes;
                    }
                }
                if (timeToPower > timeToCd) {
                    result.actionResourceExtend = timeToPower - timeToCd;
                    this.tracer.Log(
                        "Spell ID '%s' requires an extra %fs for primary resource.",
                        spellId,
                        result.actionResourceExtend
                    );
                }
            }
            if (si.casttime) {
                result.castTime = si.casttime;
            }
        }

        if (!si || !si.casttime) {
            result.castTime = this.OvaleSpellBook.GetCastTime(spellId);
        }
        result.actionTarget = target;
        const offgcd =
            element.cachedParams.named.offgcd ||
            this.ovaleData.GetSpellInfoProperty(
                spellId,
                atTime,
                "offgcd",
                targetGUID
            ) ||
            0;
        result.offgcd = (offgcd == 1 && true) || undefined;
        if (result.timeSpan)
            this.profiler.StopProfiling("OvaleBestAction_GetActionSpellInfo");
        return result;
    }

    private GetActionTextureInfo: ActionInfoHandler = (
        element: AstFunctionNode,
        atTime: number,
        target: string
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_GetActionTextureInfo");
        const result = element.result;
        setResultType(result, "action");
        result.actionTarget = target;
        let actionTexture;
        {
            const texture = element.cachedParams.positional[1];
            const spellId = tonumber(texture);
            if (spellId) {
                actionTexture = GetSpellTexture(spellId);
            } else {
                actionTexture = `Interface\\Icons\\${texture}`;
            }
        }
        result.actionInRange = false;
        result.actionCooldownStart = 0;
        result.actionCooldownDuration = 0;
        result.actionEnable = true;
        result.actionUsable = true;
        result.actionShortcut = undefined;
        result.actionIsCurrent = false;
        result.actionType = "texture";
        result.actionId = actionTexture;
        result.castTime = this.OvaleFuture.GetGCD(undefined, atTime);

        this.profiler.StopProfiling("OvaleBestAction_GetActionTextureInfo");
        return result;
    };

    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_ScriptChanged");
    };

    public StartNewAction() {
        this.ovaleState.ResetState();
        this.OvaleFuture.ApplyInFlightSpells();
        this.runner.refresh();
    }

    public GetAction(node: AstIconNode, atTime: number): AstNodeSnapshot {
        this.profiler.StartProfiling("OvaleBestAction_GetAction");
        const groupNode = node.child[1];
        const element = this.runner.PostOrderCompute(groupNode, atTime);
        if (element.type == "state" && element.timeSpan.HasTime(atTime)) {
            const [variable, value] = [element.name, element.value];
            const isFuture = !element.timeSpan.HasTime(atTime);
            this.variables.PutState(
                <string>variable,
                <number>value,
                isFuture,
                atTime
            );
        }
        this.profiler.StopProfiling("OvaleBestAction_GetAction");
        return element;
    }
}
