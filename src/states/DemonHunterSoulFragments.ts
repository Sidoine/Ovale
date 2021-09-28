import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, pairs } from "@wowts/lua";
import { max, min } from "@wowts/math";
import { AceModule } from "@wowts/tsaddon";
import { GetTime, SpellId } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { CombatLogEvent, SpellPayloadHeader } from "../engine/combat-log-event";
import { DebugTools, Tracer } from "../engine/debug";
import { SpellCastEventHandler, States, StateModule } from "../engine/state";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";

const generator: LuaArray<number> = {
    [225919]: 2, // Fracture
    [SpellId.shear]: 1,
};

const spender: LuaArray<number> = {
    [SpellId.soul_barrier]: -5,
    [SpellId.soul_cleave]: -2,
    [SpellId.spirit_bomb]: -5,
};

// Soul Fragments buff ID
const soulFragmentsId = 203981;

const trackedBuff: LuaArray<boolean> = {
    [soulFragmentsId]: true, // Soul Fragments
    [SpellId.metamorphosis_vengeance]: true,
};

class SoulFragmentsData {
    count = 0; // total soul fragments, including pending spawns
}

/* There is an in-game lag between when a spell that generates Lesser Soul
 * Fragments is cast and when those Lesser Soul Fragments appear in the
 * game world before the GCD has finished. Keep track of pending Lesser
 * Soul Fragments that have not yet appeared so that we know how many
 * Lesser Soul Fragments will be available when the next spell can be cast.
 */
export class OvaleDemonHunterSoulFragmentsClass
    extends States<SoulFragmentsData>
    implements StateModule
{
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private hasSoulFragmentsHandlers = false;
    private hasMetamorphosis = false;
    private count = 0; // stack count of Soul Fragment buff
    private pending = 0; // pending soul fragment spawns

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private aura: OvaleAuraClass,
        private combatLogEvent: CombatLogEvent,
        private paperDoll: OvalePaperDollClass
    ) {
        super(SoulFragmentsData);
        this.module = ovale.createModule(
            "OvaleDemonHunterSoulFragments",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.onOvaleSpecializationChanged
            );
            const specialization = this.paperDoll.getSpecialization();
            this.onOvaleSpecializationChanged(
                "onEnable",
                specialization,
                specialization
            );
        }
    };

    private onDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.unregisterSoulFragmentsHandlers();
        }
    };

    private onOvaleSpecializationChanged = (
        event: string,
        newSpecialization: string,
        oldSpecialization: string
    ) => {
        if (newSpecialization == "vengeance") {
            this.registerSoulFragmentsHandlers();
            const now = GetTime();
            for (const [auraId] of pairs(trackedBuff)) {
                const aura = this.aura.getAura(
                    "player",
                    auraId,
                    now,
                    "HELPFUL",
                    true
                );
                if (aura && this.aura.isActiveAura(aura, now)) {
                    this.onOvaleAuraEvent(
                        "Ovale_AuraChanged",
                        now,
                        aura.guid,
                        aura.spellId,
                        aura.source
                    );
                }
            }
        } else {
            this.unregisterSoulFragmentsHandlers();
        }
    };

    private registerSoulFragmentsHandlers = () => {
        if (!this.hasSoulFragmentsHandlers) {
            this.module.RegisterMessage(
                "Ovale_AuraAdded",
                this.onOvaleAuraEvent
            );
            this.module.RegisterMessage(
                "Ovale_AuraChanged",
                this.onOvaleAuraEvent
            );
            this.module.RegisterMessage(
                "Ovale_AuraRemoved",
                this.onOvaleAuraEvent
            );
            this.combatLogEvent.registerEvent(
                "SPELL_CAST_SUCCESS",
                this,
                this.onSpellCastSuccess
            );
            this.hasSoulFragmentsHandlers = true;
        }
    };

    private unregisterSoulFragmentsHandlers = () => {
        if (this.hasSoulFragmentsHandlers) {
            this.module.UnregisterMessage("Ovale_AuraAdded");
            this.module.UnregisterMessage("Ovale_AuraChanged");
            this.module.UnregisterMessage("Ovale_AuraRemoved");
            this.combatLogEvent.unregisterAllEvents(this);
            this.hasSoulFragmentsHandlers = false;

            this.hasMetamorphosis = false;
            this.count = 0;
            this.pending = 0;
            this.current.count = 0;
        }
    };

    private onOvaleAuraEvent = (
        event: string,
        atTime: number,
        guid: string,
        auraId: number,
        caster: string
    ) => {
        if (guid == this.ovale.playerGUID) {
            if (auraId == SpellId.metamorphosis_vengeance) {
                if (
                    event == "Ovale_AuraAdded" ||
                    event == "Ovale_AuraChanged"
                ) {
                    this.hasMetamorphosis = true;
                } else if (event == "Ovale_AuraRemoved") {
                    this.hasMetamorphosis = false;
                }
            } else if (auraId == soulFragmentsId) {
                if (
                    event == "Ovale_AuraAdded" ||
                    event == "Ovale_AuraChanged"
                ) {
                    const aura = this.aura.getAura(
                        "player",
                        auraId,
                        atTime,
                        "HELPFUL",
                        true
                    );
                    if (aura && this.aura.isActiveAura(aura, atTime)) {
                        const gained = aura.stacks - this.count;
                        if (gained > 0) {
                            // invariant: this.pending >= 0
                            this.pending = max(this.pending - gained, 0);
                        }
                        // invariant: this.count <= 5
                        this.count = min(aura.stacks, 5);
                        this.updateCurrentSoulFragments();
                    }
                } else if (event == "Ovale_AuraRemoved") {
                    this.count = 0;
                    this.updateCurrentSoulFragments();
                }
            }
        }
    };

    private onSpellCastSuccess = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.ovale.playerGUID) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            const fragments = generator[spellId];
            if (fragments && fragments > 0) {
                this.pending += fragments;
                if (this.hasMetamorphosis) {
                    // Metamorphosis triggers an extra Lesser Soul Fragment
                    this.pending += 1;
                }
                this.updateCurrentSoulFragments();
            }
        }
    };

    private updateCurrentSoulFragments = () => {
        // invariant: this.current.count <= 5
        this.current.count = min(this.count + this.pending, 5);
        // invariant: this.pending >= 0
        this.pending = max(this.current.count - this.count, 0);
        this.tracer.debug(
            `${this.current.count} = ${this.count} + ${this.pending}`
        );
    };

    initializeState(): void {}

    resetState() {
        if (this.hasSoulFragmentsHandlers) {
            this.next.count = this.current.count;
        }
    }

    cleanState(): void {}

    applySpellAfterCast: SpellCastEventHandler = (
        spellId,
        targetGUID,
        startCast,
        endCast,
        channel,
        spellcast
    ) => {
        if (this.hasSoulFragmentsHandlers) {
            // Spend Soul Fragments first.
            if (spender[spellId]) {
                const fragments = spender[spellId];
                if (fragments < 0) {
                    const count = this.next.count + fragments;
                    // invariant: this.next.count >= 0
                    this.next.count = max(count, 0);
                }
            }
            // Gain Soul Fragments second, to possibly handle refunds.
            if (generator[spellId]) {
                const fragments = generator[spellId];
                if (fragments > 0) {
                    const count = this.next.count + fragments;
                    // invariant: this.next.count <= 5
                    this.next.count = min(count, 5);
                }
            }
        }
    };

    soulFragments(atTime: number) {
        // TODO Need to add parameters greater and demon
        return this.next.count;
    }
}
