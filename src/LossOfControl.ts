import { Tokens, OvaleRequirement } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { C_LossOfControl, GetTime } from "@wowts/wow-mock";
import { LuaArray, pairs } from "@wowts/lua";
import { insert } from "@wowts/table";
import { sub, upper } from "@wowts/string";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { OvaleDebugClass, Tracer } from "./Debug";
import { StateModule } from "./State";

interface LossOfControlEventInfo{
	locType: string;
	spellID: number;
	startTime: number,
	duration: number,
}

export class OvaleLossOfControlClass implements StateModule {
	private lossOfControlHistory: LuaArray<LossOfControlEventInfo>;
	private module: AceModule & AceEvent;
	private tracer: Tracer;

	constructor(private ovale: OvaleClass, ovaleDebug: OvaleDebugClass, private requirement: OvaleRequirement) {
		this.module = ovale.createModule("OvaleLossOfControl", this.OnInitialize, this.OnDisable, aceEvent);
		this.tracer = ovaleDebug.create(this.module.GetName());
	}

	private OnInitialize = () => {
		this.tracer.Debug("Enabled LossOfControl module");
		this.lossOfControlHistory = {};
        this.module.RegisterEvent("LOSS_OF_CONTROL_ADDED", this.LOSS_OF_CONTROL_ADDED);
        this.requirement.RegisterRequirement("lossofcontrol", this.RequireLossOfControlHandler);
    }
    private OnDisable = () => {
		this.tracer.Debug("Disabled LossOfControl module");
		this.lossOfControlHistory = {};
        this.module.UnregisterEvent("LOSS_OF_CONTROL_ADDED");
		this.requirement.UnregisterRequirement("lossofcontrol");
    }
	private LOSS_OF_CONTROL_ADDED = (event: string, eventIndex: number) => {
		this.tracer.Debug("GetEventInfo:", eventIndex, C_LossOfControl.GetEventInfo(eventIndex));
		let [locType, spellID, , , startTime, , duration] = C_LossOfControl.GetEventInfo(eventIndex);
		let data: LossOfControlEventInfo = {
			locType: upper(locType),
			spellID: spellID,
			startTime: startTime || GetTime(),
			duration: duration || 10,
		}
		insert(this.lossOfControlHistory, data);
	}
	RequireLossOfControlHandler = (spellId: number, atTime: number, requirement:string, tokens: Tokens, index: number, targetGUID: string):[boolean, string, number] => {
		let verified: boolean = false;
		let locType = <string>tokens[index];
		index = index + 1;
		
		if (locType) {
			let required = true;
            if (sub(locType, 1, 1) === "!") {
                required = false;
                locType = sub(locType, 2);
            }
			
			let hasLoss = this.HasLossOfControl(locType, atTime);
			verified = (required && hasLoss) || (!required && !hasLoss);
			
		} else {
			this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a locType argument.", requirement);
		}
		return [verified, requirement, index];
	}
	HasLossOfControl = function(locType: string, atTime: number) {
		let lowestStartTime: number|undefined = undefined;
		let highestEndTime: number|undefined  = undefined;
		for (const [, data] of pairs<LossOfControlEventInfo>(this.lossOfControlHistory)) {
			if (upper(locType) == data.locType && (data.startTime <= atTime && atTime <= data.startTime+data.duration)) {
				if (lowestStartTime == undefined || lowestStartTime > data.startTime) { lowestStartTime = data.startTime; }
				if (highestEndTime == undefined || highestEndTime < data.startTime + data.duration) { highestEndTime = data.startTime+data.duration; }
			}
		}
		return lowestStartTime != undefined && highestEndTime != undefined;
	}
	CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
}
