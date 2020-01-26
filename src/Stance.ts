import { L } from "./Localization";
import { Tokens, OvaleRequirement } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, tonumber, type, wipe, LuaObj, LuaArray } from "@wowts/lua";
import { sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetNumShapeshiftForms, GetShapeshiftForm, GetShapeshiftFormInfo, GetSpellInfo } from "@wowts/wow-mock";
import { SpellCast } from "./LastSpell";
import { isString } from "./tools";
import { States, StateModule } from "./State";
import { OvaleDebugClass, Tracer } from "./Debug";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleDataClass } from "./Data";

const [druidCatForm] = GetSpellInfo(768);
const [druidTravelForm] = GetSpellInfo(783);
const [druidAquaticForm] = GetSpellInfo(1066);
const [druidBearForm] = GetSpellInfo(5487);
const [druidMoonkinForm] =GetSpellInfo(24858);
const [druid_flight_form] = GetSpellInfo(33943);
const [druid_swift_flight_form] = GetSpellInfo(40120);
const [rogue_stealth] = GetSpellInfo(1784);

type Stance = "druid_cat_form" | "druid_travel_form" | "druid_aquatic_form" | "druid_bear_form" | "druid_moonkin_form" | "druid_flight_form" | "druid_swift_flight_form" | "rogue_stealth";

let SPELL_NAME_TO_STANCE: LuaObj<Stance> = {};

if (druidCatForm) SPELL_NAME_TO_STANCE[druidCatForm] = "druid_cat_form";
if (druidTravelForm) SPELL_NAME_TO_STANCE[druidTravelForm] = "druid_travel_form";
if (druidAquaticForm) SPELL_NAME_TO_STANCE[druidAquaticForm] = "druid_aquatic_form";
if (druidBearForm) SPELL_NAME_TO_STANCE[druidBearForm] = "druid_bear_form";
if (druidMoonkinForm) SPELL_NAME_TO_STANCE[druidMoonkinForm] = "druid_moonkin_form";
if (druid_flight_form) SPELL_NAME_TO_STANCE[druid_flight_form] = "druid_flight_form";
if (druid_swift_flight_form) SPELL_NAME_TO_STANCE[druid_swift_flight_form] = "druid_swift_flight_form";
if (rogue_stealth) SPELL_NAME_TO_STANCE[rogue_stealth] = "rogue_stealth";

export const STANCE_NAME: {[key in Stance]: boolean } = {
    druid_aquatic_form: true,
    druid_bear_form: true,
    druid_cat_form: true,
    druid_flight_form: true,
    druid_moonkin_form: true,
    druid_swift_flight_form: true,
    druid_travel_form: true,
    rogue_stealth: true
}

let array = {}

class StanceData {
    stance: number = 0;
}

export class OvaleStanceClass extends States<StanceData> implements StateModule {
    ready = false;
    stanceList: LuaArray<string> = {}
    stanceId: LuaObj<number> = {};
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(ovaleDebug: OvaleDebugClass, private ovale: OvaleClass, ovaleProfiler: OvaleProfilerClass, private ovaleData: OvaleDataClass, private requirement: OvaleRequirement) {
        super(StanceData);
        this.module = ovale.createModule("OvaleStance", this.OnInitialize, this.OnDisable, aceEvent);
        this.profiler = ovaleProfiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
        let debugOptions = {
            stance: {
                name: L["Stances"],
                type: "group",
                args: {
                    stance: {
                        name: L["Stances"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.DebugStances();
                        }
                    }
                }
            }
        }
        for (const [k, v] of pairs(debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }
    
    private OnInitialize = () => {
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.UpdateStances);
        this.module.RegisterEvent("UPDATE_SHAPESHIFT_FORM", this.UPDATE_SHAPESHIFT_FORM);
        this.module.RegisterEvent("UPDATE_SHAPESHIFT_FORMS", this.UPDATE_SHAPESHIFT_FORMS);
        this.module.RegisterMessage("Ovale_SpellsChanged", this.UpdateStances);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.UpdateStances);
        this.requirement.RegisterRequirement("stance", this.RequireStanceHandler);
    }
    private OnDisable = () => {
        this.requirement.UnregisterRequirement("stance");
        this.module.UnregisterEvent("PLAYER_ALIVE");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORMS");
        this.module.UnregisterMessage("Ovale_SpellsChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    }
    
    private UPDATE_SHAPESHIFT_FORM = (event: string) => {
        this.ShapeshiftEventHandler();
    }
    private UPDATE_SHAPESHIFT_FORMS = (event: string) => {
        this.ShapeshiftEventHandler();
    }
    
    CreateStanceList() {
        this.profiler.StartProfiling("OvaleStance_CreateStanceList");
        wipe(this.stanceList);
        wipe(this.stanceId);
        let name, stanceName, spellId;
        for (let i = 1; i <= GetNumShapeshiftForms(); i += 1) {
            [, , , spellId] = GetShapeshiftFormInfo(i);
            [name] = GetSpellInfo(spellId);
            if (name) {
                stanceName = SPELL_NAME_TO_STANCE[name];
                if (stanceName) {
                    this.stanceList[i] = stanceName;
                    this.stanceId[stanceName] = i;
                }
            }
        }
        this.profiler.StopProfiling("OvaleStance_CreateStanceList");
    }
    DebugStances() {
        wipe(array);
        for (const [k, v] of pairs(this.stanceList)) {
            if (this.current.stance == k) {
                insert(array, `${v} (active)`);
            } else {
                insert(array, v);
            }
        }
        sort(array);
        return concat(array, "\n");
    }

    GetStance(stanceId?: number) {
        stanceId = stanceId || this.current.stance;
        return this.stanceList[stanceId];
    }
    IsStance(name: string|number, atTime: number | undefined) {
        const state = this.GetState(atTime);
        if (name && state.stance) {
            if (type(name) == "number") {
                return name == state.stance;
            } else {
                return name == this.GetStance(state.stance);
            }
        }
        return false;
    }
    IsStanceSpell(spellId: number) {
        let [name] = GetSpellInfo(spellId);
        return !!(name && SPELL_NAME_TO_STANCE[name]);
    }
    ShapeshiftEventHandler() {
        this.profiler.StartProfiling("OvaleStance_ShapeshiftEventHandler");
        let oldStance = this.current.stance;
        let newStance = GetShapeshiftForm();
        if (oldStance != newStance) {
            this.current.stance = newStance;
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_StanceChanged", this.GetStance(newStance), this.GetStance(oldStance));
        }
        this.profiler.StopProfiling("OvaleStance_ShapeshiftEventHandler");
    }
    UpdateStances = () => {
        this.CreateStanceList();
        this.ShapeshiftEventHandler();
        this.ready = true;
    }
    RequireStanceHandler = (spellId: number, atTime: number, requirement:string, tokens: Tokens, index: number, targetGUID: string):[boolean, string, number] => {
        let verified = false;
        let stance = tokens[index];
        index = index + 1;
        
        if (stance) {
            let isBang = false;
            if (isString(stance) && sub(stance, 1, 1) === "!") {
                isBang = true;
                stance = sub(stance, 2);
            }
            stance = tonumber(stance) || stance;
            let isStance = this.IsStance(stance, atTime);
            if (!isBang && isStance || isBang && !isStance) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.tracer.Log("    Require NOT stance '%s': %s", stance, result);
            } else {
                this.tracer.Log("    Require stance '%s': %s", stance, result);
            }
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement);
        }
        return [verified, requirement, index];
    }

    InitializeState() {
        this.next.stance = 0;
    }
    CleanState(): void {
    }
    ResetState() {
        this.profiler.StartProfiling("OvaleStance_ResetState");
        this.next.stance = this.current.stance;
        this.profiler.StopProfiling("OvaleStance_ResetState");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleStance_ApplySpellAfterCast");
        let stance = this.ovaleData.GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID);
        if (stance) {
            if (type(stance) == "string") {
                stance = this.stanceId[stance];
            }
            this.next.stance = stance;
        }
        this.profiler.StopProfiling("OvaleStance_ApplySpellAfterCast");
    }
}
