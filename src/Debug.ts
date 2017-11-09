import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptions } from "./Options";
import { Constructor, MakeString, Ovale } from "./Ovale";
import aceTimer from "@wowts/ace_timer-3.0";
import { format } from "@wowts/string";
import { pairs, lualength } from "@wowts/lua";
import { GetTime, DEFAULT_CHAT_FRAME } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
let OvaleDebugBase = Ovale.NewModule("OvaleDebug", aceTimer);
let self_traced = false;
let self_traceLog: TextDump = undefined;
let OVALE_TRACELOG_MAXLINES = 4096;

class OvaleDebugClass extends OvaleDebugBase {
    options = {
        name: `${Ovale.GetName()} ${L["Debug"]}`,
        type: "group",
        args: {
            toggles: {
                name: L["Options"],
                type: "group",
                order: 10,
                args: {
                },
                get: function (info) {
                    const value = Ovale.db.global.debug[info[lualength(info)]];
                    return (value != undefined);
                },
                set: function (info, value) {
                    value = value || undefined;
                    Ovale.db.global.debug[info[lualength(info)]] = value;
                }
            },
            trace: {
                name: L["Trace"],
                type: "group",
                order: 20,
                args: {
                    trace: {
                        order: 10,
                        type: "execute",
                        name: L["Trace"],
                        desc: L["Trace the next frame update."],
                        func: () => {
                            this.DoTrace(true);
                        }
                    },
                    traceLog: {
                        order: 20,
                        type: "execute",
                        name: L["Show Trace Log"],
                        func: () => {
                            this.DisplayTraceLog();
                        }
                    }
                }
            }
        }
    }

    bug = false;
    trace = false;

    constructor() {
        super();
        let actions = {
            debug: {
                name: L["Debug"],
                type: "execute",
                func: () => {
                    let appName = this.GetName();
                    AceConfigDialog.SetDefaultSize(appName, 800, 550);
                    AceConfigDialog.Open(appName);
                }
            }
        }
        for (const [k, v] of pairs(actions)) {
            OvaleOptions.options.args.actions.args[k] = v;
        }
        OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {}
        OvaleOptions.defaultDB.global.debug = {}
        OvaleOptions.RegisterOptions(this);
    }

    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Debug"], Ovale.GetName());
    
        self_traceLog = LibTextDump.New(`${Ovale.GetName()} - ${L["Trace Log"]}`, 750, 500);
    }
    DoTrace(displayLog) {
        self_traceLog.Clear();
        this.trace = true;
        DEFAULT_CHAT_FRAME.AddMessage(format("=== Trace @%f", GetTime()));
        if (displayLog) {
            this.ScheduleTimer("DisplayTraceLog", 0.5);
        }
    }
    ResetTrace() {
        this.bug = false;
        this.trace = false;
        self_traced = false;
    }
    UpdateTrace() {
        if (this.trace) {
            self_traced = true;
        }
        if (this.bug) {
            this.trace = true;
        }
        if (this.trace && self_traced) {
            self_traced = false;
            this.trace = false;
        }
    }

    RegisterDebugging<T extends Constructor<AceModule>>(addon: T) {
        const debug = this;
        return class extends addon {
            constructor(...args:any[]) {
                super(...args);
                const name = this.GetName();
                debug.options.args.toggles.args[name] = {
                    name: name,
                    desc: format(L["Enable debugging messages for the %s module."], name),
                    type: "toggle"
                };
            }

            Debug(...__args) {
                let name = this.GetName();
                if (Ovale.db.global.debug[name]) {
                    DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, MakeString(...__args)));
                }
            }
            DebugTimestamp(...__args) {
                let name = this.GetName();
                if (Ovale.db.global.debug[name]) {
                    let now = GetTime();
                    let s = format("|cffffff00%f|r %s", now, MakeString(...__args));
                    DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
                }
            }
            Log(...__args) {
                if (debug.trace) {
                    let N = self_traceLog.Lines();
                    if (N < OVALE_TRACELOG_MAXLINES - 1) {
                        self_traceLog.AddLine(MakeString(...__args));
                    } else if (N == OVALE_TRACELOG_MAXLINES - 1) {
                        self_traceLog.AddLine("WARNING: Maximum length of trace log has been reached.");
                    }
                }
            }
            Error(...__args) {
                let s = MakeString(...__args);
                this.Print("Fatal error: %s", s);
                OvaleDebug.bug = true;
            }
            Print(...__args) {
                let name = this.GetName();
                let s = MakeString(...__args);
                DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
            }            
        }
    }

    DisplayTraceLog() {
        if (self_traceLog.Lines() == 0) {
            self_traceLog.AddLine("Trace log is empty.");
        }
        self_traceLog.Display();
    }
}

export const OvaleDebug = new OvaleDebugClass();

