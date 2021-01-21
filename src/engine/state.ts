import { OvaleQueue } from "../tools/Queue";
import { SpellCast } from "../states/LastSpell";

export type SpellCastEventHandler = (
    spellId: number,
    targetGUID: string,
    startCast: number,
    endCast: number,
    channel: boolean,
    spellcast: SpellCast
) => void;

export interface StateModule {
    cleanState(): void;

    /** Called each time the script is executed.
     * Should clear the values that computes the engine state
     * TODO: I don't see the point of this method, it should be removed
     * and its code should be in ResetState
     */
    initializeState(): void;

    /** Called after InitializeState and after any script
     * recompilation. Anything that depends on the script should
     * be done instead of InitializeState
     */
    resetState(): void;

    /**
     * These three methods are called after ResetState for each spell cast that
     * is in flight or that currently cast
     */
    applySpellStartCast?: SpellCastEventHandler;
    applySpellAfterCast?: SpellCastEventHandler;
    applySpellOnHit?: SpellCastEventHandler;
}

export class States<T> {
    current: T;
    next: T;

    constructor(c: { new (): T }) {
        this.current = new c();
        this.next = new c();
    }

    getState(atTime: number | undefined) {
        if (!atTime) return this.current;
        return this.next;
    }
}

export class OvaleStateClass {
    private stateAddons = new OvaleQueue<StateModule>("OvaleState_stateAddons");

    registerState(stateAddon: StateModule) {
        this.stateAddons.insert(stateAddon);
    }
    unregisterState(stateAddon: StateModule) {
        const stateModules = new OvaleQueue<StateModule>(
            "OvaleState_stateModules"
        );
        while (this.stateAddons.size() > 0) {
            const addon = this.stateAddons.remove();
            if (stateAddon != addon) {
                stateModules.insert(addon);
            }
        }
        this.stateAddons = stateModules;
        stateAddon.cleanState();
    }

    /** Called each time the script is executed */
    initializeState() {
        const iterator = this.stateAddons.iterator();
        while (iterator.next()) {
            iterator.value.initializeState();
        }
    }

    /** Called at the start of each AddIcon command */
    resetState() {
        const iterator = this.stateAddons.iterator();
        while (iterator.next()) {
            iterator.value.resetState();
        }
    }

    applySpellStartCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.stateAddons.iterator();
        while (iterator.next()) {
            if (iterator.value.applySpellStartCast) {
                iterator.value.applySpellStartCast(
                    spellId,
                    targetGUID,
                    startCast,
                    endCast,
                    channel,
                    spellcast
                );
            }
        }
    }

    applySpellAfterCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.stateAddons.iterator();
        while (iterator.next()) {
            if (iterator.value.applySpellAfterCast) {
                iterator.value.applySpellAfterCast(
                    spellId,
                    targetGUID,
                    startCast,
                    endCast,
                    channel,
                    spellcast
                );
            }
        }
    }

    applySpellOnHit(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.stateAddons.iterator();
        while (iterator.next()) {
            if (iterator.value.applySpellOnHit) {
                iterator.value.applySpellOnHit(
                    spellId,
                    targetGUID,
                    startCast,
                    endCast,
                    channel,
                    spellcast
                );
            }
        }
    }
}
