import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { l } from "../ui/Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptionsClass } from "../ui/Options";
import { OvaleClass } from "../Ovale";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
import { format } from "@wowts/string";
import { pairs, lualength, LuaArray, LuaObj } from "@wowts/lua";
import { GetTime, DEFAULT_CHAT_FRAME } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { makeString } from "../tools/tools";
import { OptionUiExecute, OptionUiGroup } from "../ui/acegui-helpers";

const traceLogMaxLines = 4096;

export class Tracer {
    constructor(
        private options: OvaleOptionsClass,
        public debugTools: DebugTools,
        private name: string
    ) {
        const toggles = debugTools.defaultOptions.args.toggles as OptionUiGroup;
        toggles.args[name] = {
            name: name,
            desc: format(l["enable_debug_messages"], name),
            type: "toggle",
        };
    }

    isDebugging() {
        return (this.options.db.global.debug[this.name] && true) || false;
    }
    debug(pattern: string, ...parameters: unknown[]) {
        const name = this.name;
        if (this.isDebugging()) {
            DEFAULT_CHAT_FRAME.AddMessage(
                format(
                    "|cff33ff99%s|r: %s",
                    name,
                    makeString(pattern, ...parameters)
                )
            );
        }
    }
    debugTimestamp(pattern: string, ...parameters: unknown[]) {
        const name = this.name;
        if (this.isDebugging()) {
            const now = GetTime();
            const s = format(
                "|cffffff00%f|r %s",
                now,
                makeString(pattern, ...parameters)
            );
            DEFAULT_CHAT_FRAME.AddMessage(
                format("|cff33ff99%s|r: %s", name, s)
            );
        }
    }
    log(pattern: string, ...parameters: unknown[]) {
        if (this.debugTools.trace) {
            const numberOfLines = this.debugTools.traceLog.Lines();
            if (numberOfLines < traceLogMaxLines - 1) {
                this.debugTools.traceLog.AddLine(
                    makeString(pattern, ...parameters)
                );
            } else if (numberOfLines == traceLogMaxLines - 1) {
                this.debugTools.traceLog.AddLine(
                    "WARNING: Maximum length of trace log has been reached."
                );
            }
        }
    }
    error(pattern: string, ...parameters: unknown[]) {
        const name = this.name;
        const s = makeString(pattern, ...parameters);
        DEFAULT_CHAT_FRAME.AddMessage(
            format("|cff33ff99%s|r:|cffff3333 Error:|r %s", name, s)
        );
        this.debugTools.bug = s;
    }
    warning(pattern: string, ...parameters: unknown[]) {
        const name = this.name;
        const s = makeString(pattern, ...parameters);
        DEFAULT_CHAT_FRAME.AddMessage(
            format("|cff33ff99%s|r: |cff999933Warning:|r %s", name, s)
        );
        this.debugTools.warning = s;
    }
    print(pattern: string, ...parameters: unknown[]) {
        const name = this.name;
        const s = makeString(pattern, ...parameters);
        DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99%s|r: %s", name, s));
    }
}

export class DebugTools {
    traced = false;

    defaultOptions: OptionUiGroup = {
        name: `Ovale ${l["debug"]}`,
        type: "group",
        args: {
            toggles: {
                name: l["options"],
                type: "group",
                order: 10,
                args: {},
                get: (info: LuaArray<string>) => {
                    const value =
                        this.options.db.global.debug[info[lualength(info)]];
                    return value != undefined;
                },
                set: (info: LuaArray<string>, value: boolean) => {
                    if (!value) {
                        delete this.options.db.global.debug[
                            info[lualength(info)]
                        ];
                    } else {
                        this.options.db.global.debug[info[lualength(info)]] =
                            value;
                    }
                },
            },
            trace: {
                name: l["trace"],
                type: "group",
                order: 20,
                args: {
                    trace: {
                        order: 10,
                        type: "execute",
                        name: l["trace"],
                        desc: l["trace_next_frame"],
                        func: () => {
                            this.doTrace(true);
                        },
                    },
                    traceLog: {
                        order: 20,
                        type: "execute",
                        name: l["show_trace_log"],
                        func: () => {
                            this.displayTraceLog();
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
            this.onInitialize,
            this.onDisable,
            aceTimer
        );
        this.traceLog = LibTextDump.New(
            `${this.ovale.GetName()} - ${l["trace_log"]}`,
            750,
            500
        );

        const actions: LuaObj<OptionUiExecute> = {
            debug: {
                name: l["debug"],
                type: "execute",
                func: () => {
                    const appName = this.module.GetName();
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
        options.registerOptions();
    }

    create(name: string) {
        return new Tracer(this.options, this, name);
    }

    private onInitialize = () => {
        const appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, this.defaultOptions);
        AceConfigDialog.AddToBlizOptions(
            appName,
            l["debug"],
            this.ovale.GetName()
        );
    };
    private onDisable = () => {};

    doTrace(displayLog: boolean) {
        this.traceLog.Clear();
        this.trace = true;
        DEFAULT_CHAT_FRAME.AddMessage(format("=== Trace @%f", GetTime()));
        if (displayLog) {
            this.module.ScheduleTimer(() => {
                this.displayTraceLog();
            }, 0.5);
        }
    }

    resetTrace() {
        this.bug = undefined;
        this.trace = false;
        this.traced = false;
    }

    updateTrace() {
        if (this.trace) {
            this.traced = true;
        }
        if (this.bug) {
            this.trace = true;
        }
        if (this.trace && this.traced) {
            this.traced = false;
            this.trace = false;
        }
    }

    displayTraceLog() {
        if (this.traceLog.Lines() == 0) {
            this.traceLog.AddLine("Trace log is empty.");
        }
        this.traceLog.Display();
    }
}
