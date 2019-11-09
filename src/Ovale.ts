import { L } from "./Localization";
import { NewAddon, AceModule } from "@wowts/tsaddon";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, strjoin, tostring, tostringall, wipe, LuaArray, LuaObj, _G, truthy } from "@wowts/lua";
import { format, find, len } from "@wowts/string";
import { UnitClass, UnitGUID, DEFAULT_CHAT_FRAME, ClassId } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { Library } from "@wowts/tslib";

export const oneTimeMessages: LuaObj<boolean | "printed"> = {}
let MAX_REFRESH_INTERVALS = 500;
let self_refreshIntervals:LuaArray<number> = {}
let self_refreshIndex = 1;

export type Constructor<T> = new(...args: any[]) => T;

export function MakeString(s?: string, ...__args: any[]) {
    if (s && len(s) > 0) {
        if (__args) {
            if (truthy(find(s, "%%%.%d")) || truthy(find(s, "%%[%w]"))) {
                s = format(s, ...tostringall(...__args));
            } else {
                s = strjoin(" ", s, ...tostringall(...__args));
            }
        }
    } else {
        s = tostring(undefined);
    }
    return s;
}

const name = "Ovale";

const OvaleBase = NewAddon(name, aceEvent);
export const MSG_PREFIX = name;


export function Print(...__args: any[]) {
    let s = MakeString(...__args);
    DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
}


export class OvaleClass extends OvaleBase {
    playerClass: ClassId = "WARRIOR";
    playerGUID: string = "";
    refreshNeeded:LuaObj<boolean> = {}
    

    constructor() {
        super();
        _G["BINDING_HEADER_OVALE"] = "Ovale";
        let toggleCheckBox = L["Inverser la boîte à cocher "];
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
        this.playerGUID = UnitGUID("player");
        const [, classId] = UnitClass("player");
        this.playerClass = classId;
        wipe(self_refreshIntervals);
        self_refreshIndex = 1;
        this.ClearOneTimeMessages();
    }

    needRefresh() {
        if (this.playerGUID) {
            this.refreshNeeded[this.playerGUID] = true;
        }
    }
    
    AddRefreshInterval(milliseconds: number) {
        if (milliseconds < huge) {
            self_refreshIntervals[self_refreshIndex] = milliseconds;
            self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) && (self_refreshIndex + 1) || 1;
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
        let avgRefresh = (count > 0) && (sumRefresh / count) || 0;
        return [avgRefresh, minRefresh, maxRefresh, count];
    }
    
    
    OneTimeMessage(...__args: any[]) {
        let s = MakeString(...__args);
        if (!oneTimeMessages[s]) {
            oneTimeMessages[s] = true;
        }
    }
    ClearOneTimeMessages() {
        wipe(oneTimeMessages);
    }
    PrintOneTimeMessages() {
        for (const [s] of pairs(oneTimeMessages)) {
            if (oneTimeMessages[s] != "printed") {
                Print(s);
                oneTimeMessages[s] = "printed";
            }
        }
    }

    createModule(name: string, onInitialize: () => void, onRelease: () => void) : AceModule;
    createModule<T>(name: string, onInitialize: () => void, onRelease: () => void, dep1: Library<T>) : AceModule & T;
    createModule<T, U>(name: string, onInitialize: () => void, onRelease: () => void, dep1: Library<T>, dep2: Library<U>) : AceModule & T & U;
    createModule<T, U, V>(name: string, onInitialize: () => void, onRelease: () => void, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>): AceModule & T & U & V;
    createModule<T, U, V, W>(name: string, onInitialize: () => void, onRelease: () => void, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>, dep4: Library<W>): AceModule & T & U & V & W;
    createModule<T, U, V, W>(name: string, onInitialize: () => void, onRelease: () => void, dep1?: Library<T>, dep2?: Library<U>, dep3?: Library<V>, dep4?: Library<W>): AceModule & T & U & V & W {
        const ret = new (this.NewModule(name, dep1, dep2, dep3, dep4));
        ret.OnInitialize = onInitialize;
        // TODO use onRelease
        return ret;
    }    
}


