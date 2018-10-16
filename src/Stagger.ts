import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray, lualength, pairs } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { OvaleFuture } from "./Future";

let OvaleStaggerBase = Ovale.NewModule("OvaleStagger", aceEvent);
export let OvaleStagger: OvaleStaggerClass;

let self_serial = 1;
let MAX_LENGTH = 30
class OvaleStaggerClass extends OvaleStaggerBase {
    staggerTicks: LuaArray<number> = {}

    OnInitialize() {
        if (Ovale.playerClass == "MONK") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "MONK") {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        let [, cleuEvent, , sourceGUID, , , , , , , , spellId, , , amount] = CombatLogGetCurrentEventInfo();
        if (sourceGUID != Ovale.playerGUID) {
            return;
        }
        self_serial = self_serial + 1;
        if(cleuEvent == "SPELL_PERIODIC_DAMAGE" && spellId == 124255){
            insert(this.staggerTicks, amount);
            if (lualength(this.staggerTicks) > MAX_LENGTH) {
                remove(this.staggerTicks, 1);
            }
        }
    }

    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {   
        if(!OvaleFuture.IsInCombat(undefined)){
            for (const [k] of pairs(this.staggerTicks)) {
                this.staggerTicks[k] = undefined;
            }
        }
    }
    
    LastTickDamage(countTicks: number): number{
        if(!countTicks || countTicks == 0 || countTicks < 0) countTicks = 1;
        
        let damage = 0;
        let arrLen = lualength(this.staggerTicks)
               
        if(arrLen < 1) return 0;
                
        for(let i = arrLen; i > arrLen - (countTicks - 1); i += -1){
            damage += this.staggerTicks[i] || 0;
        }
        return damage;
    }
}

OvaleStagger = new OvaleStaggerClass();
OvaleState.RegisterState(OvaleStagger);
