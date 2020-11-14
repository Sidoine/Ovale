import { Tokens, OvaleRequirement } from "../Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { C_LossOfControl, GetTime, HasFullControl } from "@wowts/wow-mock";
import { LuaArray, pairs, LuaObj, ipairs } from "@wowts/lua";
import { insert } from "@wowts/table";
import { sub, upper, format } from "@wowts/string";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleDebugClass, Tracer } from "../Debug";
import { StateModule } from "../State";
import { OneTimeMessage } from "../tools";
import { ConditionResult, OvaleConditionClass, TestBoolean } from "../Condition";

/*
These should be the locType constants.
    STUN_MECHANIC
    SCHOOL_INTERRUPT
    DISARM
    PACIFYSILENCE
    SILENCE
    PACIFY
    ROOT
    STUN
    FEAR
    CHARM
    CONFUSE
    POSSESS
*/
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

    constructor(
        ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        private requirement: OvaleRequirement
    ) {
        this.module = ovale.createModule(
            "OvaleLossOfControl",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }
    
    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.RegisterCondition("isfeared", false, this.IsFeared);
        ovaleCondition.RegisterCondition("isincapacitated", false, this.IsIncapacitated);
        ovaleCondition.RegisterCondition("isrooted", false, this.IsRooted);
        ovaleCondition.RegisterCondition("isstunned", false, this.IsStunned);
        ovaleCondition.RegisterCondition("haslossofcontrol", false, this.HasLossOfControlCondition);
    }

    private OnInitialize = () => {
        this.tracer.Debug("Enabled LossOfControl module");
        this.module.RegisterEvent(
            "LOSS_OF_CONTROL_ADDED",
            this.LOSS_OF_CONTROL_ADDED
        );
        this.requirement.RegisterRequirement(
            "lossofcontrol",
            this.RequireLossOfControlHandler
        );
    };
    private OnDisable = () => {
        this.tracer.Debug("Disabled LossOfControl module");
        this.lossOfControlHistory = {};
        this.module.UnregisterEvent("LOSS_OF_CONTROL_ADDED");
        this.requirement.UnregisterRequirement("lossofcontrol");
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
        let lossOfControlData = C_LossOfControl.GetActiveLossOfControlData(eventIndex);
        if (lossOfControlData) {
            let data: LossOfControlEventInfo = {
                locType: upper(lossOfControlData.locType),
                spellID: lossOfControlData.spellID,
                startTime: lossOfControlData.startTime || GetTime(),
                duration: lossOfControlData.duration || 10,
            };
            insert(this.lossOfControlHistory, data);
        }
    };
    RequireLossOfControlHandler = (
        spellId: number,
        atTime: number,
        requirement: string,
        tokens: Tokens,
        index: number,
        targetGUID: string | undefined
    ): [boolean, string, number] => {
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
            OneTimeMessage(
                "Warning: requirement '%s' is missing a locType argument.",
                requirement
            );
        }
        return [verified, requirement, index];
    };
    GetLossOfControlTiming = (locType: string, atTime: number) => {
        let lowestStartTime: number | undefined = undefined;
        let highestEndTime: number | undefined = undefined;
        for (const [, data] of pairs<LossOfControlEventInfo>(this.lossOfControlHistory)) {
            if (
                upper(locType) == data.locType &&
                data.startTime <= atTime &&
                atTime <= data.startTime + data.duration
            ) {
                if (lowestStartTime == undefined || lowestStartTime > data.startTime) {
                    lowestStartTime = data.startTime;
                }
                if (highestEndTime == undefined || highestEndTime < data.startTime + data.duration) {
                    highestEndTime = data.startTime + data.duration;
                }
            }
        }
        return [lowestStartTime, highestEndTime];
    };
    HasLossOfControl = (locType: string, atTime: number) => {
        let lowestStartTime, highestEndTime = this.GetLossOfControlTiming(locType, atTime);
        return lowestStartTime != undefined && highestEndTime != undefined;
    };
    CleanState(): void {}
    InitializeState(): void {}
    ResetState(): void {}
    
    /**  Test if the player is feared.
    @name IsFeared
    @paramsig boolean
    @param yesno Optional. If yes, then return true if feared. If no, then return true if it not feared.
     Default is yes.
     Valid values: yes, no.
    @return A boolean value.
    @usage
    if IsFeared() Spell(every_man_for_himself)
    */
    private IsFeared = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let yesno = positionalParams[1];
        let boolean =
            !HasFullControl() &&
            this.HasLossOfControl("FEAR", atTime);
        return TestBoolean(boolean, yesno);
    };
    
    /** Test if the player is incapacitated.
    @name IsIncapacitated
    @paramsig boolean
    @param yesno Optional. If yes, then return true if incapacitated. If no, then return true if it not incapacitated.
     Default is yes.
     Valid values: yes, no.
    @return A boolean value.
    @usage
    if IsIncapacitated() Spell(every_man_for_himself)
    */
    private IsIncapacitated = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let yesno = positionalParams[1];
        let boolean =
            !HasFullControl() &&
            this.HasLossOfControl("CONFUSE", atTime);
        return TestBoolean(boolean, yesno);
    };
    
    /** Test if the player is rooted.
    @name IsRooted
    @paramsig boolean
    @param yesno Optional. If yes, then return true if rooted. If no, then return true if it not rooted.
     Default is yes.
     Valid values: yes, no.
    @return A boolean value.
    @usage
    if IsRooted() Item(Trinket0Slot usable=1)
    */
    private IsRooted = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let yesno = positionalParams[1];
        let boolean = this.HasLossOfControl("ROOT", atTime);
        return TestBoolean(boolean, yesno);
    };
    
    /** Test if the player is stunned.
    @name IsStunned
    @paramsig boolean
    @param yesno Optional. If yes, then return true if stunned. If no, then return true if it not stunned.
     Default is yes.
     Valid values: yes, no.
    @return A boolean value.
    @usage
    if IsStunned() Item(Trinket0Slot usable=1)
    */
    private IsStunned = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let yesno = positionalParams[1];
        let boolean =
            !HasFullControl() &&
            this.HasLossOfControl("STUN_MECHANIC", atTime);
        return TestBoolean(boolean, yesno);
    };
    
    /** Test if a specific loss of control is present.
    @name HasLossOfControl
    @paramsig boolean
    @param yesno Optional. If yes, then return true if loss of control is present. If no, then return true if not present.
    Default is yes.
    Valid values: yes.  "no" currently doesn't work.
    @return A boolean value.
    @usage
    if player.HasLossOfControl(fear) Spell(berserker_rage)
    if player.HasLossOfControl(fear stun incapacitate) Item(Trinket0Slot usable=1)
    */
    private HasLossOfControlCondition = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ): ConditionResult => {
        for (const [, lossOfControlType] of ipairs(positionalParams)) {
            let [start, ending] = this.GetLossOfControlTiming(upper(lossOfControlType), atTime);
            if (start !== undefined && ending !== undefined) {
                return [start, ending];
            }
        }
        return [];
    };
}
