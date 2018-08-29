import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray, LuaObj } from "@wowts/lua";

let CLEU_DAMAGE_EVENT: LuaObj<boolean> = {
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_AURA: true
}

const OvaleSpellDamageBase = OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleSpellDamage", aceEvent));
class OvaleSpellDamageClass extends OvaleSpellDamageBase {
    value: LuaArray<number> = {}
    OnInitialize() {
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    OnDisable() {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        let [, cleuEvent, , sourceGUID, , , , , , , , arg12, , , arg15] = CombatLogGetCurrentEventInfo();
        if (sourceGUID == Ovale.playerGUID) {
            this.StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
            if (CLEU_DAMAGE_EVENT[cleuEvent]) {
                let [spellId, amount] = [arg12, arg15];
                this.value[spellId] = amount;
                Ovale.needRefresh();
            }
            this.StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    Get(spellId: number) {
        return this.value[spellId];
    }
}

export let OvaleSpellDamage = new OvaleSpellDamageClass()