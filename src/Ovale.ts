import { L } from "./Localization";
import { NewAddon } from "@wowts/tsaddon";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, strjoin, tostring, tostringall, wipe, LuaArray, LuaObj, _G, truthy } from "@wowts/lua";
import { format, find, len } from "@wowts/string";
import { UnitClass, UnitGUID, DEFAULT_CHAT_FRAME, ClassId } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { AceDatabase } from "@wowts/ace_db-3.0";
import { Color } from "./SpellFlash";

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

export interface OvaleDb {
    profile: {
        source: LuaObj<string>;
        code: string,
        check: LuaObj<boolean>,
        list: LuaObj<string>,
        standaloneOptions: boolean,
        showHiddenScripts: boolean;
        overrideCode: string;
        apparence: {
            [k: string]: any,
            avecCible: boolean,
            clickThru: boolean,
            enCombat: boolean,
            enableIcons: boolean,
            hideEmpty: boolean,
            hideVehicule: boolean,
            margin: number,
            offsetX: number,
            offsetY: number,
            targetHostileOnly: boolean,
            verrouille: boolean,
            vertical: boolean,
            alpha: number,
            flashIcon: boolean,
            remainsFontColor: {
                r: number,
                g: number,
                b: number
            },
            fontScale: number,
            highlightIcon: true,
            iconScale: number,
            numeric: false,
            raccourcis: true,
            smallIconScale: number,
            targetText: string,
            iconShiftX: number,
            iconShiftY: number,
            optionsAlpha: number,
            predictif: boolean,
            secondIconScale: number,
            taggedEnemies: boolean,
            minFrameRefresh: number,
            maxFrameRefresh: number,
            fullAuraScan: false,
            frequentHealthUpdates: false,
            auraLag: number,
            moving: boolean,
            spellFlash: {
                enabled: boolean,
                colorMain?: Color,
                colorCd?: Color,
                colorShortCd?: Color,
                colorInterrupt?: Color,
                inCombat?: boolean,
                hideInVehicle?: boolean,
                hasTarget?: boolean,
                hasHostileTarget?: boolean,
                threshold?: number,
                size?: number,
                brightness?: number,
            },
            minimap: {
                hide: boolean
            }
        }
    },
    global: any;
}

const OvaleBase = NewAddon("Ovale", aceEvent);
class OvaleClass extends OvaleBase {
    playerClass: ClassId = undefined;
    playerGUID: string = undefined;
    db: AceDatabase & OvaleDb = undefined;
    refreshNeeded:LuaObj<boolean> = {}
    MSG_PREFIX = "Ovale";


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
                this.Print(s);
                oneTimeMessages[s] = "printed";
            }
        }
    }

    Print(...__args: any[]) {
        let s = MakeString(...__args);
        DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", this.GetName(), s));
    }
}

export const Ovale = new OvaleClass();

