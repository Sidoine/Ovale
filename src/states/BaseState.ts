import { StateModule, States } from "../engine/state";
import { GetTime } from "@wowts/wow-mock";

class BaseStateData {
    currentTime = 0;
    defaultTarget = "target";
}

export class BaseState extends States<BaseStateData> implements StateModule {
    constructor() {
        super(BaseStateData);
    }

    InitializeState() {
        this.next.defaultTarget = "target";
    }

    ResetState() {
        const now = GetTime();
        this.next.currentTime = now;
        this.next.defaultTarget = this.current.defaultTarget;
    }

    CleanState() {}
}
