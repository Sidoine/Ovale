import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray, lualength, pairs } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { StateModule } from "./State";
import { OvaleFutureClass } from "./Future";

let self_serial = 1;
let MAX_LENGTH = 30
export class OvaleStaggerClass implements StateModule {
    staggerTicks: LuaArray<number> = {}
    private module: AceModule & AceEvent;

    constructor(private ovale: OvaleClass, private ovaleFuture: OvaleFutureClass) {
        this.module = ovale.createModule("OvaleStagger", this.OnInitialize, this.OnDisable, aceEvent);
    }

    private OnInitialize = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
        }
    }
    private OnDisable = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [, cleuEvent, , sourceGUID, , , , , , , , spellId, , , amount] = CombatLogGetCurrentEventInfo();
        if (sourceGUID != this.ovale.playerGUID) {
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
        if(!this.ovaleFuture.IsInCombat(undefined)){
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


