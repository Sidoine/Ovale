import { L } from "./ui/Localization";
import { NewAddon, AceModule } from "@wowts/tsaddon";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, wipe, LuaArray, LuaObj, _G } from "@wowts/lua";
import { UnitClass, UnitGUID, ClassId } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { Library } from "@wowts/tslib";
import { ClearOneTimeMessages } from "./tools/tools";

const MAX_REFRESH_INTERVALS = 500;
const self_refreshIntervals: LuaArray<number> = {};
let self_refreshIndex = 1;

export type Constructor<T> = new (...args: any[]) => T;

const name = "Ovale";

const OvaleBase = NewAddon(name, aceEvent);
export const MSG_PREFIX = name;

export class OvaleClass extends OvaleBase {
    playerClass: ClassId = "WARRIOR";
    playerGUID = "";
    refreshNeeded: LuaObj<boolean> = {};

    constructor() {
        super();
        _G["BINDING_HEADER_OVALE"] = "Ovale";
        const toggleCheckBox = L["Inverser la boîte à cocher "];
        _G["BINDING_NAME_OVALE_CHECKBOX0"] = `${toggleCheckBox}(1)`;
        _G["BINDING_NAME_OVALE_CHECKBOX1"] = `${toggleCheckBox}(2)`;
        _G["BINDING_NAME_OVALE_CHECKBOX2"] = `${toggleCheckBox}(3)`;
        _G["BINDING_NAME_OVALE_CHECKBOX3"] = `${toggleCheckBox}(4)`;
        _G["BINDING_NAME_OVALE_CHECKBOX4"] = `${toggleCheckBox}(5)`;
    }

    // OnDisable() {
    //     this.UnregisterEvent("PLAYER_ENTERING_WORLD");
    //     this.UnregisterEvent("PLAYER_TARGET_CHANGED");
    //     this.UnregisterMessage("Ovale_CombatEnded");
    //     this.UnregisterMessage("Ovale_OptionChanged");
    //     this.frame.Hide();
    // }
    OnInitialize() {
        this.playerGUID = UnitGUID("player") || "error";
        const [, classId] = UnitClass("player");
        this.playerClass = classId || "WARRIOR";
        wipe(self_refreshIntervals);
        self_refreshIndex = 1;
        ClearOneTimeMessages();
    }

    needRefresh() {
        if (this.playerGUID) {
            this.refreshNeeded[this.playerGUID] = true;
        }
    }

    AddRefreshInterval(milliseconds: number) {
        if (milliseconds < huge) {
            self_refreshIntervals[self_refreshIndex] = milliseconds;
            self_refreshIndex =
                (self_refreshIndex < MAX_REFRESH_INTERVALS &&
                    self_refreshIndex + 1) ||
                1;
        }
    }
    GetRefreshIntervalStatistics() {
        let [sumRefresh, minRefresh, maxRefresh, count] = [0, huge, 0, 0];
        for (const [, v] of ipairs(self_refreshIntervals)) {
            if (v > 0) {
                if (minRefresh > v) {
                    minRefresh = v;
                }
                if (maxRefresh < v) {
                    maxRefresh = v;
                }
                sumRefresh = sumRefresh + v;
                count = count + 1;
            }
        }
        const avgRefresh = (count > 0 && sumRefresh / count) || 0;
        return [avgRefresh, minRefresh, maxRefresh, count];
    }

    createModule(
        name: string,
        onInitialize: () => void,
        onRelease: () => void
    ): AceModule;
    createModule<T>(
        name: string,
        onInitialize: () => void,
        onRelease: () => void,
        dep1: Library<T>
    ): AceModule & T;
    createModule<T, U>(
        name: string,
        onInitialize: () => void,
        onRelease: () => void,
        dep1: Library<T>,
        dep2: Library<U>
    ): AceModule & T & U;
    createModule<T, U, V>(
        name: string,
        onInitialize: () => void,
        onRelease: () => void,
        dep1: Library<T>,
        dep2: Library<U>,
        dep3: Library<V>
    ): AceModule & T & U & V;
    createModule<T, U, V, W>(
        name: string,
        onInitialize: () => void,
        onRelease: () => void,
        dep1: Library<T>,
        dep2: Library<U>,
        dep3: Library<V>,
        dep4: Library<W>
    ): AceModule & T & U & V & W;
    createModule<T, U, V, W>(
        name: string,
        onInitialize: () => void,
        onRelease: () => void,
        dep1?: Library<T>,
        dep2?: Library<U>,
        dep3?: Library<V>,
        dep4?: Library<W>
    ): AceModule & T & U & V & W {
        const ret = new (this.NewModule(name, dep1, dep2, dep3, dep4))();
        ret.OnInitialize = onInitialize;
        // TODO use onRelease
        return ret;
    }
}
