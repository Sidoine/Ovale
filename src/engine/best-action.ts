import { OvaleActionBarClass } from "./action-bar";
import { OvaleDataClass } from "./data";
import { OvaleEquipmentClass, SlotName } from "../states/Equipment";
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
    IsItemInRange,
    IsUsableAction,
    IsUsableItem,
} from "@wowts/wow-mock";
import {
    AstActionNode,
    AstIconNode,
    AstNodeSnapshot,
    NodeActionResult,
    NodeNoResult,
    setResultType,
} from "./ast";
import { OvaleCooldownClass } from "../states/Cooldown";
import { OvaleSpellsClass } from "../states/Spells";
import { isNumber, isString } from "../tools/tools";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { Guids } from "./guid";
import { OvaleFutureClass } from "../states/Future";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { Profiler, OvaleProfilerClass } from "./profiler";
import { DebugTools, Tracer } from "./debug";
import { Variables } from "../states/Variables";
import { ActionInfoHandler, Runner } from "./runner";

export type ActionType =
    | "item"
    | "spell"
    | "texture"
    | "macro"
    | "value"
    | "setstate";

export class OvaleBestActionClass {
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovaleEquipment: OvaleEquipmentClass,
        private ovaleActionBar: OvaleActionBarClass,
        private ovaleData: OvaleDataClass,
        private ovaleCooldown: OvaleCooldownClass,
        ovale: OvaleClass,
        private guids: Guids,
        private future: OvaleFutureClass,
        private spellBook: OvaleSpellBookClass,
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: DebugTools,
        private variables: Variables,
        private spells: OvaleSpellsClass,
        private runner: Runner
    ) {
        this.module = ovale.createModule(
            "BestAction",
            this.onInitialize,
            this.handleDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
        runner.registerActionInfoHandler("item", this.getActionItemInfo);
        runner.registerActionInfoHandler("macro", this.getActionMacroInfo);
        runner.registerActionInfoHandler("spell", this.getActionSpellInfo);
        runner.registerActionInfoHandler("texture", this.getActionTextureInfo);
    }

    private onInitialize = () => {};

    private getActionItemInfo: ActionInfoHandler = (node, atTime, target) => {
        this.profiler.startProfiling("OvaleBestAction_GetActionItemInfo");
        let itemId = node.cachedParams.positional[1];
        const result = node.result;
        setResultType(result, "action");
        if (!isNumber(itemId)) {
            const itemIdFromSlot = this.ovaleEquipment.getEquippedItemBySlotName(
                <SlotName>itemId
            );
            if (!itemIdFromSlot) {
                this.tracer.log("Unknown item '%s'.", itemId);
                return result;
            }
            itemId = itemIdFromSlot;
        }
        this.tracer.log("Item ID '%s'", itemId);
        const actionSlot = this.ovaleActionBar.getItemActionSlot(itemId);
        const [spellName] = GetItemSpell(itemId);
        if (node.cachedParams.named.texture) {
            result.actionTexture = `Interface\\Icons\\${node.cachedParams.named.texture}`;
        } else {
            result.actionTexture = GetItemIcon(itemId);
        }
        result.actionInRange = IsItemInRange(itemId, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = GetItemCooldown(itemId);
        result.actionUsable =
            (spellName &&
                IsUsableItem(itemId) &&
                this.spells.isUsableItem(itemId, atTime)) ||
            false;
        result.actionSlot = actionSlot;
        result.actionType = "item";
        result.actionId = itemId;
        result.actionTarget = target;
        result.castTime = this.future.getGCD(atTime);
        this.profiler.stopProfiling("OvaleBestAction_GetActionItemInfo");
        return result;
    };

    private getActionMacroInfo: ActionInfoHandler = (
        element,
        atTime,
        target
    ) => {
        this.profiler.startProfiling("OvaleBestAction_GetActionMacroInfo");
        const result = element.result;
        const macro = <string>element.cachedParams.positional[1];
        const actionSlot = this.ovaleActionBar.getMacroActionSlot(macro);
        setResultType(result, "action");
        if (!actionSlot) {
            this.tracer.log("Unknown macro '%s'.", macro);
            return result;
        }
        if (element.cachedParams.named.texture) {
            result.actionTexture = `Interface\\Icons\\${element.cachedParams.named.texture}`;
        } else {
            result.actionTexture = GetActionTexture(actionSlot);
        }
        result.actionInRange = IsActionInRange(actionSlot, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = GetActionCooldown(actionSlot);
        result.actionUsable = IsUsableAction(actionSlot);
        result.actionSlot = actionSlot;
        result.actionType = "macro";
        result.actionId = macro;
        result.castTime = this.future.getGCD(atTime);
        this.profiler.stopProfiling("OvaleBestAction_GetActionMacroInfo");
        return result;
    };

    private getActionSpellInfo: ActionInfoHandler = (
        element,
        atTime,
        target
    ) => {
        this.profiler.startProfiling("OvaleBestAction_GetActionSpellInfo");
        const spell = element.cachedParams.positional[1];
        if (isNumber(spell)) {
            return this.getSpellActionInfo(spell, element, atTime, target);
        } else if (isString(spell)) {
            const spellList = this.ovaleData.buffSpellList[spell];
            if (spellList) {
                for (const [spellId] of pairs(spellList)) {
                    if (this.spellBook.isKnownSpell(spellId)) {
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
        element: AstActionNode,
        atTime: number,
        target: string
    ): NodeActionResult | NodeNoResult {
        const targetGUID = this.guids.getUnitGUID(target);
        const result = element.result;
        this.ovaleData.registerSpellAsked(spellId);
        let si = this.ovaleData.spellInfo[spellId];
        let replacedSpellId = undefined;
        if (si) {
            const replacement = this.ovaleData.getSpellInfoProperty(
                spellId,
                atTime,
                "replaced_by",
                targetGUID
            );
            if (replacement) {
                replacedSpellId = spellId;
                spellId = replacement;
                si = this.ovaleData.spellInfo[spellId];
                this.tracer.log(
                    "Spell ID '%s' is replaced by spell ID '%s'.",
                    replacedSpellId,
                    spellId
                );
            }
        }
        let actionSlot = this.ovaleActionBar.getSpellActionSlot(spellId);
        if (!actionSlot && replacedSpellId) {
            this.tracer.log(
                "Action not found for spell ID '%s'; checking for replaced spell ID '%s'.",
                spellId,
                replacedSpellId
            );
            actionSlot = this.ovaleActionBar.getSpellActionSlot(
                replacedSpellId
            );
            if (actionSlot) spellId = replacedSpellId;
        }
        let isKnownSpell = this.spellBook.isKnownSpell(spellId);
        if (!isKnownSpell && replacedSpellId) {
            this.tracer.log(
                "Spell ID '%s' is not known; checking for replaced spell ID '%s'.",
                spellId,
                replacedSpellId
            );
            isKnownSpell = this.spellBook.isKnownSpell(replacedSpellId);
            if (isKnownSpell) spellId = replacedSpellId;
        }
        if (!isKnownSpell && !actionSlot) {
            setResultType(result, "none");
            this.tracer.log("Unknown spell ID '%s'.", spellId);
            return result;
        }
        const [isUsable, noMana] = this.spells.isUsableSpell(
            spellId,
            atTime,
            targetGUID
        );
        this.tracer.log(
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
        } else {
            result.actionTexture = GetSpellTexture(spellId);
        }
        result.actionInRange = this.spells.isSpellInRange(spellId, target);
        [
            result.actionCooldownStart,
            result.actionCooldownDuration,
            result.actionEnable,
        ] = this.ovaleCooldown.getSpellCooldown(spellId, atTime);

        this.tracer.log(
            "GetSpellCooldown returned %f, %f",
            result.actionCooldownStart,
            result.actionCooldownDuration
        );
        [result.actionCharges] = this.ovaleCooldown.getSpellCharges(
            spellId,
            atTime
        );
        result.actionResourceExtend = 0;
        result.actionUsable = isUsable;
        result.actionSlot = actionSlot;
        result.actionType = "spell";
        result.actionId = spellId;
        if (si) {
            if (si.texture) {
                result.actionTexture = `Interface\\Icons\\${si.texture}`;
            }
            if (result.actionCooldownStart && result.actionCooldownDuration) {
                // let seconds = OvaleSpells.GetTimeToSpell(spellId, atTime, targetGUID, extraPower);
                const timeToCd =
                    (result.actionCooldownDuration > 0 &&
                        result.actionCooldownStart +
                            result.actionCooldownDuration -
                            atTime) ||
                    0;
                const timeToPower = this.spells.timeToPowerForSpell(
                    spellId,
                    atTime,
                    targetGUID,
                    undefined,
                    element.cachedParams.named
                );
                if (timeToPower > timeToCd) {
                    result.actionResourceExtend = timeToPower - timeToCd;
                    this.tracer.log(
                        "Spell ID '%s' requires an extra %f seconds for power requirements.",
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
            result.castTime = this.spellBook.getCastTime(spellId);
        }
        result.actionTarget = target;
        const offgcd =
            element.cachedParams.named.offgcd ||
            this.ovaleData.getSpellInfoProperty(
                spellId,
                atTime,
                "offgcd",
                targetGUID
            ) ||
            0;
        result.offgcd = (offgcd == 1 && true) || undefined;
        if (result.timeSpan)
            this.profiler.stopProfiling("OvaleBestAction_GetActionSpellInfo");
        return result;
    }

    private getActionTextureInfo: ActionInfoHandler = (
        element: AstActionNode,
        atTime: number,
        target: string
    ) => {
        this.profiler.startProfiling("OvaleBestAction_GetActionTextureInfo");
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
        result.actionTexture = actionTexture;
        result.actionInRange = false;
        result.actionCooldownStart = 0;
        result.actionCooldownDuration = 0;
        result.actionEnable = true;
        result.actionUsable = true;
        result.actionSlot = undefined;
        result.actionType = "texture";
        result.actionId = actionTexture;
        result.castTime = this.future.getGCD(atTime);

        this.profiler.stopProfiling("OvaleBestAction_GetActionTextureInfo");
        return result;
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_ScriptChanged");
    };

    public startNewAction() {
        this.runner.refresh();
    }

    public getAction(node: AstIconNode, atTime: number): AstNodeSnapshot {
        this.profiler.startProfiling("OvaleBestAction_GetAction");
        const groupNode = node.child[1];
        const element = this.runner.postOrderCompute(groupNode, atTime);
        if (element.type == "state" && element.timeSpan.hasTime(atTime)) {
            const [variable, value] = [element.name, element.value];
            const isFuture = !element.timeSpan.hasTime(atTime);
            if (variable !== undefined && value !== undefined)
                this.variables.putState(variable, value, isFuture, atTime);
        }
        this.profiler.stopProfiling("OvaleBestAction_GetAction");
        return element;
    }
}
