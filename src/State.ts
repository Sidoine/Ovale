import { OvaleDebug } from "./Debug";
import { OvaleQueue } from "./Queue";
import { Ovale, Constructor } from "./Ovale";
import { SpellCast } from "./LastSpell";

let OvaleStateBase = Ovale.NewModule("OvaleState");
export let OvaleState: OvaleStateClass;

let self_stateAddons = new OvaleQueue<StateModule>("OvaleState_stateAddons");

export interface StateModule {
    CleanState():void;
    InitializeState():void;
    ResetState():void;
    ApplySpellStartCast?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
    ApplySpellAfterCast?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
    ApplySpellOnHit?(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast):void;
}

const OvaleStateBaseClass = OvaleDebug.RegisterDebugging(OvaleStateBase);
class OvaleStateClass extends OvaleStateBaseClass {
    RegisterHasState<T extends Constructor<{}>, U>(Base: T, ctor: new () => U) {
        return class extends Base {
            current = new ctor();
            next = new ctor();
            GetState(atTime: number) {
                if (!atTime) return this.current;
                return this.next;
            }
        }
    }

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
    InitializeState() {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.InitializeState();
        }
    }
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

OvaleState = new OvaleStateClass();
