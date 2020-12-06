import { L } from "../ui/Localization";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, type, wipe, LuaObj, LuaArray } from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import {
    GetNumShapeshiftForms,
    GetShapeshiftForm,
    GetShapeshiftFormInfo,
    GetSpellInfo,
} from "@wowts/wow-mock";
import { SpellCast } from "./LastSpell";
import { States, StateModule } from "../engine/state";
import { OvaleDebugClass } from "../engine/debug";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { OptionUiAll } from "../ui/acegui-helpers";
import { OvaleConditionClass, TestBoolean } from "../engine/condition";

const [druidCatForm] = GetSpellInfo(768);
const [druidTravelForm] = GetSpellInfo(783);
const [druidAquaticForm] = GetSpellInfo(1066);
const [druidBearForm] = GetSpellInfo(5487);
const [druidMoonkinForm] = GetSpellInfo(24858);
const [druid_flight_form] = GetSpellInfo(33943);
const [druid_swift_flight_form] = GetSpellInfo(40120);
const [rogue_stealth] = GetSpellInfo(1784);

type Stance =
    | "druid_cat_form"
    | "druid_travel_form"
    | "druid_aquatic_form"
    | "druid_bear_form"
    | "druid_moonkin_form"
    | "druid_flight_form"
    | "druid_swift_flight_form"
    | "rogue_stealth";

const SPELL_NAME_TO_STANCE: LuaObj<Stance> = {};

if (druidCatForm) SPELL_NAME_TO_STANCE[druidCatForm] = "druid_cat_form";
if (druidTravelForm)
    SPELL_NAME_TO_STANCE[druidTravelForm] = "druid_travel_form";
if (druidAquaticForm)
    SPELL_NAME_TO_STANCE[druidAquaticForm] = "druid_aquatic_form";
if (druidBearForm) SPELL_NAME_TO_STANCE[druidBearForm] = "druid_bear_form";
if (druidMoonkinForm)
    SPELL_NAME_TO_STANCE[druidMoonkinForm] = "druid_moonkin_form";
if (druid_flight_form)
    SPELL_NAME_TO_STANCE[druid_flight_form] = "druid_flight_form";
if (druid_swift_flight_form)
    SPELL_NAME_TO_STANCE[druid_swift_flight_form] = "druid_swift_flight_form";
if (rogue_stealth) SPELL_NAME_TO_STANCE[rogue_stealth] = "rogue_stealth";

export const STANCE_NAME: { [key in Stance]: boolean } = {
    druid_aquatic_form: true,
    druid_bear_form: true,
    druid_cat_form: true,
    druid_flight_form: true,
    druid_moonkin_form: true,
    druid_swift_flight_form: true,
    druid_travel_form: true,
    rogue_stealth: true,
};

const array = {};

class StanceData {
    stance = 0;
}

export class OvaleStanceClass
    extends States<StanceData>
    implements StateModule {
    ready = false;
    stanceList: LuaArray<string> = {};
    stanceId: LuaObj<number> = {};
    private module: AceModule & AceEvent;
    private profiler: Profiler;

    constructor(
        ovaleDebug: OvaleDebugClass,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass
    ) {
        super(StanceData);
        this.module = ovale.createModule(
            "OvaleStance",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        const debugOptions: LuaObj<OptionUiAll> = {
            stance: {
                name: L["stances"],
                type: "group",
                args: {
                    stance: {
                        name: L["stances"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.DebugStances();
                        },
                    },
                },
            },
        };
        for (const [k, v] of pairs(debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.RegisterCondition("stance", false, this.Stance);
    }

    /** Test if the player is in a given stance.
	 @name Stance
	 @paramsig boolean
	 @param stance The stance name or a number representing the stance index.
	 @param yesno Optional. If yes, then return true if the player is in the given stance. If no, then return true otherwise.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 unless Stance(druid_bear_form) Spell(bear_form)
     */
    private Stance = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        const [stance, yesno] = [positionalParams[1], positionalParams[2]];
        const boolean = this.IsStance(stance, atTime);
        return TestBoolean(boolean, yesno);
    };

    private OnInitialize = () => {
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.UpdateStances);
        this.module.RegisterEvent(
            "UPDATE_SHAPESHIFT_FORM",
            this.UPDATE_SHAPESHIFT_FORM
        );
        this.module.RegisterEvent(
            "UPDATE_SHAPESHIFT_FORMS",
            this.UPDATE_SHAPESHIFT_FORMS
        );
        this.module.RegisterMessage("Ovale_SpellsChanged", this.UpdateStances);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.UpdateStances);
    };
    private OnDisable = () => {
        this.module.UnregisterEvent("PLAYER_ALIVE");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORMS");
        this.module.UnregisterMessage("Ovale_SpellsChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };

    private UPDATE_SHAPESHIFT_FORM = (event: string) => {
        this.ShapeshiftEventHandler();
    };
    private UPDATE_SHAPESHIFT_FORMS = (event: string) => {
        this.ShapeshiftEventHandler();
    };

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
    IsStance(name: string | number, atTime: number | undefined) {
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
        const [name] = GetSpellInfo(spellId);
        return !!(name && SPELL_NAME_TO_STANCE[name]);
    }
    ShapeshiftEventHandler() {
        this.profiler.StartProfiling("OvaleStance_ShapeshiftEventHandler");
        const oldStance = this.current.stance;
        const newStance = GetShapeshiftForm();
        if (oldStance != newStance) {
            this.current.stance = newStance;
            this.ovale.needRefresh();
            this.module.SendMessage(
                "Ovale_StanceChanged",
                this.GetStance(newStance),
                this.GetStance(oldStance)
            );
        }
        this.profiler.StopProfiling("OvaleStance_ShapeshiftEventHandler");
    }
    UpdateStances = () => {
        this.CreateStanceList();
        this.ShapeshiftEventHandler();
        this.ready = true;
    };
    InitializeState() {
        this.next.stance = 0;
    }
    CleanState(): void {}
    ResetState() {
        this.profiler.StartProfiling("OvaleStance_ResetState");
        this.next.stance = this.current.stance;
        this.profiler.StopProfiling("OvaleStance_ResetState");
    }
    ApplySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvaleStance_ApplySpellAfterCast");
        let stance = this.ovaleData.GetSpellInfoProperty(
            spellId,
            endCast,
            "to_stance",
            targetGUID
        );
        if (stance) {
            if (type(stance) == "string") {
                stance = this.stanceId[stance];
            }
            this.next.stance = stance;
        }
        this.profiler.StopProfiling("OvaleStance_ApplySpellAfterCast");
    };
}
