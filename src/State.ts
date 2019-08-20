import { OvaleQueue } from "./Queue";
import { SpellCast } from "./LastSpell";

let self_stateAddons = new OvaleQueue<StateModule>("OvaleState_stateAddons");

export interface StateModule {
    CleanState():void;
    InitializeState():void;
    ResetState():void;
    ApplySpellStartCast?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
    ApplySpellAfterCast?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
    ApplySpellOnHit?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
}

export class States<T> {
    current: T;
    next: T;

    constructor(c: {new(): T}) {
        this.current = new c();
        this.next = new c();
    }

    GetState(atTime: number | undefined) {
        if (!atTime) return this.current;
        return this.next;
    }
}

export class OvaleStateClass {
    
    RegisterState(stateAddon: StateModule) {
        self_stateAddons.Insert(stateAddon);
    }
    UnregisterState(stateAddon: StateModule) {
        let stateModules = new OvaleQueue<StateModule>("OvaleState_stateModules");
        while (self_stateAddons.Size() > 0) {
            let addon = self_stateAddons.Remove();
            if (stateAddon != addon) {
                stateModules.Insert(addon);
            }
        }
        self_stateAddons = stateModules;
        stateAddon.CleanState();
    }
    
    /** Called each time the script is executed */
    InitializeState() {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.InitializeState();
        }
    }

    /** Called at the start of each AddIcon command */
    ResetState() {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.ResetState();
        }
    }

    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellStartCast) {
                iterator.value.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }

    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellAfterCast){
                iterator.value.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }
    
    ApplySpellOnHit(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellOnHit) {
                iterator.value.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }
}
