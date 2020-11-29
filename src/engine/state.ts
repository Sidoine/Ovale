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
    CleanState(): void;
    InitializeState(): void;
    ResetState(): void;
    ApplySpellStartCast?: SpellCastEventHandler;
    ApplySpellAfterCast?: SpellCastEventHandler;
    ApplySpellOnHit?: SpellCastEventHandler;
}

export class States<T> {
    current: T;
    next: T;

    constructor(c: { new (): T }) {
        this.current = new c();
        this.next = new c();
    }

    GetState(atTime: number | undefined) {
        if (!atTime) return this.current;
        return this.next;
    }
}

export class OvaleStateClass {
    private self_stateAddons = new OvaleQueue<StateModule>(
        "OvaleState_stateAddons"
    );

    RegisterState(stateAddon: StateModule) {
        this.self_stateAddons.Insert(stateAddon);
    }
    UnregisterState(stateAddon: StateModule) {
        const stateModules = new OvaleQueue<StateModule>(
            "OvaleState_stateModules"
        );
        while (this.self_stateAddons.Size() > 0) {
            const addon = this.self_stateAddons.Remove();
            if (stateAddon != addon) {
                stateModules.Insert(addon);
            }
        }
        this.self_stateAddons = stateModules;
        stateAddon.CleanState();
    }

    /** Called each time the script is executed */
    InitializeState() {
        const iterator = this.self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.InitializeState();
        }
    }

    /** Called at the start of each AddIcon command */
    ResetState() {
        const iterator = this.self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.ResetState();
        }
    }

    ApplySpellStartCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellStartCast) {
                iterator.value.ApplySpellStartCast(
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

    ApplySpellAfterCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellAfterCast) {
                iterator.value.ApplySpellAfterCast(
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

    ApplySpellOnHit(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) {
        const iterator = this.self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellOnHit) {
                iterator.value.ApplySpellOnHit(
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
