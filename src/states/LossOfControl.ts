import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { C_LossOfControl, GetTime, GetSpellInfo } from "@wowts/wow-mock";
import { LuaArray, pairs } from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import { upper } from "@wowts/string";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { DebugTools, Tracer } from "../engine/debug";
import { StateModule } from "../engine/state";
import { huge } from "@wowts/math";
import { OptionUiGroup } from "../ui/acegui-helpers";

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

    constructor(ovale: OvaleClass, ovaleDebug: DebugTools) {
        this.module = ovale.createModule(
            "OvaleLossOfControl",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        ovaleDebug.defaultOptions.args["locHistory"] = this.debugOptions;
    }

    private handleInitialize = () => {
        this.tracer.debug("Enabled LossOfControl module");
        this.module.RegisterEvent(
            "LOSS_OF_CONTROL_ADDED",
            this.handleLossOfControlAdded
        );
    };
    private handleDisable = () => {
        this.tracer.debug("Disabled LossOfControl module");
        this.lossOfControlHistory = {};
        this.module.UnregisterEvent("LOSS_OF_CONTROL_ADDED");
    };
    private handleLossOfControlAdded = (e: string, eventIndex: number) => {
        const lossOfControlData = C_LossOfControl.GetActiveLossOfControlData(
            eventIndex
        );
        if (lossOfControlData) {
            this.tracer.debug(
                "event",
                e,
                "eventIndex",
                eventIndex,
                "locType",
                lossOfControlData.locType || "undefined",
                "spellID",
                lossOfControlData.spellID || "undefined",
                "spellName",
                GetSpellInfo(lossOfControlData.spellID),
                "startTime",
                lossOfControlData.startTime || "undefined",
                "duration",
                lossOfControlData.duration || "undefined"
            );
            const data: LossOfControlEventInfo = {
                locType: upper(lossOfControlData.locType),
                spellID: lossOfControlData.spellID,
                startTime: lossOfControlData.startTime || GetTime(),
                duration: lossOfControlData.duration || 10,
            };
            insert(this.lossOfControlHistory, data);
        }
    };
    hasLossOfControl = (locType: string, atTime: number) => {
        let lowestStartTime: number = huge;
        let highestEndTime: number = 0;
        for (const [, data] of pairs<LossOfControlEventInfo>(
            this.lossOfControlHistory
        )) {
            if (
                upper(locType) == upper(data.locType) &&
                data.startTime <= atTime &&
                atTime <= data.startTime + data.duration
            ) {
                if (lowestStartTime > data.startTime) {
                    lowestStartTime = data.startTime;
                }
                if (highestEndTime < data.startTime + data.duration) {
                    highestEndTime = data.startTime + data.duration;
                }
            }
        }
        return lowestStartTime < huge && highestEndTime > 0;
    };

    private debugOptions: OptionUiGroup = {
        type: "group",
        name: "Loss of Control History",
        args: {
            locHistory: {
                type: "input",
                name: "Loss of Control History",
                multiline: 25,
                width: "full",
                get: () => {
                    const output: LuaArray<string> = {};
                    for (const [, data] of pairs<LossOfControlEventInfo>(
                        this.lossOfControlHistory
                    )) {
                        const spellName = GetSpellInfo(data.spellID);
                        insert(
                            output,
                            `${spellName} - ${data.spellID} - ${data.locType} - ${data.startTime} - ${data.duration}`
                        );
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {}
}
