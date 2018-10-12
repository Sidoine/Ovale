import { OvaleState, StateModule } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";
import { OvaleDebug } from "./Debug";

class BaseStateData {
    currentTime: number = 0;
    defaultTarget: string = "target";
}

const BaseStateBase = OvaleDebug.RegisterDebugging(OvaleState.RegisterHasState(Ovale.NewModule("BaseState", aceEvent), BaseStateData));

class BaseState extends BaseStateBase implements StateModule {    
    InitializeState() {        
        this.next.defaultTarget = "target";
    }

    ResetState() {
        let now = GetTime();
        this.next.currentTime = now;
        this.next.defaultTarget = this.current.defaultTarget;  
    }

    CleanState() {}
}

export const baseState = new BaseState();
OvaleState.RegisterState(baseState);