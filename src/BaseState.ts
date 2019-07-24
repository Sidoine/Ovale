import { StateModule, States } from "./State";
import { GetTime } from "@wowts/wow-mock";

class BaseStateData {
    currentTime: number = 0;
    defaultTarget: string = "target";
}

export class BaseState extends States<BaseStateData> implements StateModule {    
    constructor() {
        super(BaseStateData);
    }

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

