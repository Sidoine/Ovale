import { OvaleState, StateModule } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";
import { LuaArray } from "@wowts/lua";
import { OvaleDebug } from "./Debug";

class BaseStateData {
    currentTime: number|undefined = undefined;
    inCombat = undefined;
    combatStartTime = undefined;    
    defaultTarget: string;
}

const BaseStateBase = OvaleDebug.RegisterDebugging(OvaleState.RegisterHasState(Ovale.NewModule("BaseState", aceEvent), BaseStateData));

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

    CombatRequirement = (spellId: number, atTime: number, name: string, tokens: LuaArray<string> | string | number, index: number, targetGUID: string):[boolean, string, number] => {
        return [this.next.inCombat, name, index];
    }

}

export const baseState = new BaseState();
OvaleState.RegisterState(baseState);