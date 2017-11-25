import { OvaleState, StateModule } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";

class BaseStateData {
    currentTime: number|undefined = undefined;
    inCombat = undefined;
    combatStartTime = undefined;    
    defaultTarget: string;
}

const BaseStateBase = OvaleState.RegisterHasState(Ovale.NewModule("BaseState", aceEvent), BaseStateData);

class BaseState extends BaseStateBase implements StateModule {    
    IsInCombat(atTime: number | undefined) {
        return this.GetState(atTime).inCombat;
    }   

    InitializeState() {        
        this.next.defaultTarget = "target";
    }

    ResetState() {
        let now = GetTime();
        this.next.currentTime = now;
        this.next.inCombat = this.current.inCombat;
        this.next.combatStartTime = this.current.combatStartTime || 0;
        this.next.defaultTarget = this.current.defaultTarget;  
    }

    CleanState() {}
}

export const baseState = new BaseState();
OvaleState.RegisterState(baseState);