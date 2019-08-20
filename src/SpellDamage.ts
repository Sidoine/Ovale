import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray, LuaObj } from "@wowts/lua";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { Profiler, OvaleProfilerClass } from "./Profiler";

let CLEU_DAMAGE_EVENT: LuaObj<boolean> = {
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_AURA: true
}

export class OvaleSpellDamageClass {
    value: LuaArray<number> = {}
    private module: AceModule & AceEvent;
    private profiler: Profiler;

    constructor(private ovale: OvaleClass, ovaleProfiler: OvaleProfilerClass) {
        this.module = ovale.createModule("OvaleSpellDamage", this.OnInitialize, this.OnDisable, aceEvent);
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
    }
    
    private OnDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [, cleuEvent, , sourceGUID, , , , , , , , arg12, , , arg15] = CombatLogGetCurrentEventInfo();
        if (sourceGUID == this.ovale.playerGUID) {
            this.profiler.StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
            if (CLEU_DAMAGE_EVENT[cleuEvent]) {
                let [spellId, amount] = [arg12, arg15];
                this.value[spellId] = amount;
                this.ovale.needRefresh();
            }
            this.profiler.StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    Get(spellId: number) {
        return this.value[spellId];
    }
}
