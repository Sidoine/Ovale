import { l } from "../ui/Localization";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, type, wipe, LuaObj, LuaArray } from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import {
    GetNumShapeshiftForms,
    GetShapeshiftForm,
    GetShapeshiftFormInfo,
    GetSpellInfo,
    SpellId,
} from "@wowts/wow-mock";
import { SpellCast } from "./LastSpell";
import { States, StateModule } from "../engine/state";
import { DebugTools } from "../engine/debug";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { OptionUiAll } from "../ui/acegui-helpers";
import { OvaleConditionClass, returnBoolean } from "../engine/condition";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

const [druidCatForm] = GetSpellInfo(SpellId.cat_form);
const [druidTravelForm] = GetSpellInfo(SpellId.travel_form);
const [druidAquaticForm] = GetSpellInfo(1066);
const [druidBearForm] = GetSpellInfo(SpellId.bear_form);
const [druidMoonkinForm] = GetSpellInfo(SpellId.moonkin_form);
const [druidFlightForm] = GetSpellInfo(33943);
const [druidSwiftFlightForm] = GetSpellInfo(40120);
const [rogueStealth] = GetSpellInfo(1784);

type Stance =
    | "druid_cat_form"
    | "druid_travel_form"
    | "druid_aquatic_form"
    | "druid_bear_form"
    | "druid_moonkin_form"
    | "druid_flight_form"
    | "druid_swift_flight_form"
    | "rogue_stealth";

const spellNameToStance: LuaObj<Stance> = {};

if (druidCatForm) spellNameToStance[druidCatForm] = "druid_cat_form";
if (druidTravelForm) spellNameToStance[druidTravelForm] = "druid_travel_form";
if (druidAquaticForm)
    spellNameToStance[druidAquaticForm] = "druid_aquatic_form";
if (druidBearForm) spellNameToStance[druidBearForm] = "druid_bear_form";
if (druidMoonkinForm)
    spellNameToStance[druidMoonkinForm] = "druid_moonkin_form";
if (druidFlightForm) spellNameToStance[druidFlightForm] = "druid_flight_form";
if (druidSwiftFlightForm)
    spellNameToStance[druidSwiftFlightForm] = "druid_swift_flight_form";
if (rogueStealth) spellNameToStance[rogueStealth] = "rogue_stealth";

export const stanceName: { [key in Stance]: boolean } = {
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
        ovaleDebug: DebugTools,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass
    ) {
        super(StanceData);
        this.module = ovale.createModule(
            "OvaleStance",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        const debugOptions: LuaObj<OptionUiAll> = {
            stance: {
                name: l["stances"],
                type: "group",
                args: {
                    stance: {
                        name: l["stances"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.debugStances();
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
        ovaleCondition.registerCondition("stance", false, this.stance);
    }

    /** Test if the player is in a given stance.
	 @name Stance
	 @paramsig boolean
	 @param stance The stance name or a number representing the stance index.
	 @return A boolean value.
	 @usage
	 unless Stance(druid_bear_form) Spell(bear_form)
     */
    private stance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const stance = positionalParams[1];
        const boolean = this.isStance(stance, atTime);
        return returnBoolean(boolean);
    };

    private handleInitialize = () => {
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.updateStances);
        this.module.RegisterEvent(
            "UPDATE_SHAPESHIFT_FORM",
            this.handleUpdateShapeshiftForm
        );
        this.module.RegisterEvent(
            "UPDATE_SHAPESHIFT_FORMS",
            this.handleUpdateShapeshiftForms
        );
        this.module.RegisterMessage("Ovale_SpellsChanged", this.updateStances);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.updateStances);
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_ALIVE");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORMS");
        this.module.UnregisterMessage("Ovale_SpellsChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };

    private handleUpdateShapeshiftForm = (event: string) => {
        this.shapeshiftEventHandler();
    };
    private handleUpdateShapeshiftForms = (event: string) => {
        this.shapeshiftEventHandler();
    };

    createStanceList() {
        this.profiler.startProfiling("OvaleStance_CreateStanceList");
        wipe(this.stanceList);
        wipe(this.stanceId);
        let name, stanceName, spellId;
        for (let i = 1; i <= GetNumShapeshiftForms(); i += 1) {
            [, , , spellId] = GetShapeshiftFormInfo(i);
            [name] = GetSpellInfo(spellId);
            if (name) {
                stanceName = spellNameToStance[name];
                if (stanceName) {
                    this.stanceList[i] = stanceName;
                    this.stanceId[stanceName] = i;
                }
            }
        }
        this.profiler.stopProfiling("OvaleStance_CreateStanceList");
    }

    debugStances() {
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

    getStance(stanceId?: number) {
        stanceId = stanceId || this.current.stance;
        return this.stanceList[stanceId];
    }

    isStance(name: string | number, atTime: number | undefined) {
        const state = this.getState(atTime);
        if (name && state.stance) {
            if (type(name) == "number") {
                return name == state.stance;
            } else {
                return name == this.getStance(state.stance);
            }
        }
        return false;
    }

    isStanceSpell(spellId: number) {
        const [name] = GetSpellInfo(spellId);
        return !!(name && spellNameToStance[name]);
    }

    shapeshiftEventHandler() {
        this.profiler.startProfiling("OvaleStance_ShapeshiftEventHandler");
        const oldStance = this.current.stance;
        const newStance = GetShapeshiftForm();
        if (oldStance != newStance) {
            this.current.stance = newStance;
            this.ovale.needRefresh();
            this.module.SendMessage(
                "Ovale_StanceChanged",
                this.getStance(newStance),
                this.getStance(oldStance)
            );
        }
        this.profiler.stopProfiling("OvaleStance_ShapeshiftEventHandler");
    }
    updateStances = () => {
        this.createStanceList();
        this.shapeshiftEventHandler();
        this.ready = true;
    };
    initializeState() {
        this.next.stance = 0;
    }
    cleanState(): void {}
    resetState() {
        this.profiler.startProfiling("OvaleStance_ResetState");
        this.next.stance = this.current.stance;
        this.profiler.stopProfiling("OvaleStance_ResetState");
    }
    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleStance_ApplySpellAfterCast");
        let stance = this.ovaleData.getSpellInfoProperty(
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
        this.profiler.stopProfiling("OvaleStance_ApplySpellAfterCast");
    };
}
