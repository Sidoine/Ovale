import { StateModule } from "../engine/state";
import { GetTime } from "@wowts/wow-mock";

export class BaseState implements StateModule {
    /** The default target for the current icon. */
    defaultTarget = "target";

    /** Cached value of GetTime(), the real current time */
    currentTime = 0;

    InitializeState() {}

    ResetState() {
        this.currentTime = GetTime();
        this.defaultTarget = "target";
    }

    CleanState() {}
}
