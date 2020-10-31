import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptionsClass } from "./Options";
import { OvaleClass } from "./Ovale";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
import { format } from "@wowts/string";
import { pairs, lualength, LuaArray, LuaObj } from "@wowts/lua";
import { GetTime, DEFAULT_CHAT_FRAME } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { MakeString } from "./tools";
import { OptionUiExecute, OptionUiGroup } from "./acegui-helpers";

const OVALE_TRACELOG_MAXLINES = 4096;

export class Tracer {
    constructor(
        private options: OvaleOptionsClass,
        private debug: OvaleDebugClass,
        private name: string
    ) {
        const toggles = debug.defaultOptions.args.toggles as OptionUiGroup;
        toggles.args[name] = {
            name: name,
            desc: format(
                L["Enable debugging messages for the %s module."],
                name
            ),
            type: "toggle",
        };
    }

    Debug(...__args: any[]) {
        let name = this.name;
        if (this.options.db.global.debug[name]) {
            DEFAULT_CHAT_FRAME.AddMessage(
                format("|cff33ff99%s|r: %s", name, MakeString(...__args))
            );
        }
    }
    DebugTimestamp(...__args: any[]) {
        let name = this.name;
        if (this.options.db.global.debug[name]) {
            let now = GetTime();
            let s = format("|cffffff00%f|r %s", now, MakeString(...__args));
            DEFAULT_CHAT_FRAME.AddMessage(
                format("|cff33ff99%s|r: %s", name, s)
            );
        }
    }
    Log(...__args: any[]) {
        if (this.debug.trace) {
            let N = this.debug.traceLog.Lines();
            if (N < OVALE_TRACELOG_MAXLINES - 1) {
                this.debug.traceLog.AddLine(MakeString(...__args));
            } else if (N == OVALE_TRACELOG_MAXLINES - 1) {
                this.debug.traceLog.AddLine(
                    "WARNING: Maximum length of trace log has been reached."
                );
            }
        }
    }
    Error(...__args: any[]) {
        const name = this.name;
        let s = MakeString(...__args);
        DEFAULT_CHAT_FRAME.AddMessage(
            format("|cff33ff99%s|r:|cffff3333 Error:|r %s", name, s)
        );
        this.debug.bug = s;
    }
    Warning(...__args: any[]) {
        const name = this.name;
        let s = MakeString(...__args);
        DEFAULT_CHAT_FRAME.AddMessage(
            format("|cff33ff99%s|r: |cff999933Warning:|r %s", name, s)
        );
        this.debug.warning = s;
    }
    Print(...__args: any[]) {
        let name = this.name;
        let s = MakeString(...__args);
        DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
    }
}

export class OvaleDebugClass {
    self_traced = false;

    defaultOptions: OptionUiGroup = {
        name: `Ovale ${L["Debug"]}`,
        type: "group",
        args: {
            toggles: {
                name: L["Options"],
                type: "group",
                order: 10,
                args: {},
                get: (info: LuaArray<string>) => {
                    const value = this.options.db.global.debug[
                        info[lualength(info)]
                    ];
                    return value != undefined;
                },
                set: (info: LuaArray<string>, value: boolean) => {
                    if (!value) {
                        delete this.options.db.global.debug[
                            info[lualength(info)]
                        ];
                    } else {
                        this.options.db.global.debug[
                            info[lualength(info)]
                        ] = value;
                    }
                },
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
                        },
                    },
                    traceLog: {
                        order: 20,
                        type: "execute",
                        name: L["Show Trace Log"],
                        func: () => {
                            this.DisplayTraceLog();
                        },
                    },
                },
            },
        },
    };

    traceLog: TextDump;
    bug?: string;
    warning?: string;
    trace = false;
    private module: AceModule & AceTimer;

    constructor(private ovale: OvaleClass, private options: OvaleOptionsClass) {
        this.module = ovale.createModule(
            "OvaleDebug",
            this.OnInitialize,
            this.OnDisable,
            aceTimer
        );
        this.traceLog = LibTextDump.New(
            `${this.ovale.GetName()} - ${L["Trace Log"]}`,
            750,
            500
        );

        let actions: LuaObj<OptionUiExecute> = {
            debug: {
                name: L["Debug"],
                type: "execute",
                func: () => {
                    let appName = this.module.GetName();
                    AceConfigDialog.SetDefaultSize(appName, 800, 550);
                    AceConfigDialog.Open(appName);
                },
            },
        };

        for (const [k, v] of pairs(actions)) {
            options.actions.args[k] = v;
        }
        options.defaultDB.global = options.defaultDB.global || {};
        options.defaultDB.global.debug = {};
        options.RegisterOptions(this);
    }

    create(name: string) {
        return new Tracer(this.options, this, name);
    }

    private OnInitialize = () => {
        let appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, this.defaultOptions);
        AceConfigDialog.AddToBlizOptions(
            appName,
            L["Debug"],
            this.ovale.GetName()
        );
    };
    private OnDisable = () => {};

    DoTrace(displayLog: boolean) {
        this.traceLog.Clear();
        this.trace = true;
        DEFAULT_CHAT_FRAME.AddMessage(format("=== Trace @%f", GetTime()));
        if (displayLog) {
            this.module.ScheduleTimer(() => {
                this.DisplayTraceLog();
            }, 0.5);
        }
    }
    ResetTrace() {
        this.bug = undefined;
        this.trace = false;
        this.self_traced = false;
    }
    UpdateTrace() {
        if (this.trace) {
            this.self_traced = true;
        }
        if (this.bug) {
            this.trace = true;
        }
        if (this.trace && this.self_traced) {
            this.self_traced = false;
            this.trace = false;
        }
    }

    DisplayTraceLog() {
        if (this.traceLog.Lines() == 0) {
            this.traceLog.AddLine("Trace log is empty.");
        }
        this.traceLog.Display();
    }
}
