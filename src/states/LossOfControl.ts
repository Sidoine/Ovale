import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { C_LossOfControl, GetTime } from "@wowts/wow-mock";
import { LuaArray, pairs } from "@wowts/lua";
import { insert } from "@wowts/table";
import { upper, format } from "@wowts/string";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleDebugClass, Tracer } from "../engine/Debug";
import { StateModule } from "../engine/State";

interface LossOfControlEventInfo {
    locType: string;
    spellID: number;
    startTime: number;
    duration: number;
}

export class OvaleLossOfControlClass implements StateModule {
    private lossOfControlHistory: LuaArray<LossOfControlEventInfo> = {};
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(ovale: OvaleClass, ovaleDebug: OvaleDebugClass) {
        this.module = ovale.createModule(
            "OvaleLossOfControl",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.tracer.Debug("Enabled LossOfControl module");
        this.module.RegisterEvent(
            "LOSS_OF_CONTROL_ADDED",
            this.LOSS_OF_CONTROL_ADDED
        );
    };
    private OnDisable = () => {
        this.tracer.Debug("Disabled LossOfControl module");
        this.lossOfControlHistory = {};
        this.module.UnregisterEvent("LOSS_OF_CONTROL_ADDED");
    };
    private LOSS_OF_CONTROL_ADDED = (event: string, eventIndex: number) => {
        this.tracer.Debug(
            "LOSS_OF_CONTROL_ADDED",
            format(
                "C_LossOfControl.GetActiveLossOfControlData(%d)",
                eventIndex
            ),
            C_LossOfControl.GetActiveLossOfControlData(eventIndex)
        );
        const lossOfControlData = C_LossOfControl.GetActiveLossOfControlData(
            eventIndex
        );
        if (lossOfControlData) {
            const data: LossOfControlEventInfo = {
                locType: upper(lossOfControlData.locType),
                spellID: lossOfControlData.spellID,
                startTime: lossOfControlData.startTime || GetTime(),
                duration: lossOfControlData.duration || 10,
            };
            insert(this.lossOfControlHistory, data);
        }
    };
    HasLossOfControl = (locType: string, atTime: number) => {
        let lowestStartTime: number | undefined = undefined;
        let highestEndTime: number | undefined = undefined;
        for (const [, data] of pairs<LossOfControlEventInfo>(
            this.lossOfControlHistory
        )) {
            if (
                upper(locType) == data.locType &&
                data.startTime <= atTime &&
                atTime <= data.startTime + data.duration
            ) {
                if (
                    lowestStartTime == undefined ||
                    lowestStartTime > data.startTime
                ) {
                    lowestStartTime = data.startTime;
                }
                if (
                    highestEndTime == undefined ||
                    highestEndTime < data.startTime + data.duration
                ) {
                    highestEndTime = data.startTime + data.duration;
                }
            }
        }
        return lowestStartTime != undefined && highestEndTime != undefined;
    };
    CleanState(): void {}
    InitializeState(): void {}
    ResetState(): void {}
}
