import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { l } from "../ui/Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptionsClass } from "../ui/Options";
import { OvaleClass } from "../Ovale";
import { debugprofilestop, GetTime } from "@wowts/wow-mock";
import { format } from "@wowts/string";
import { pairs, next, wipe, LuaObj, lualength, LuaArray } from "@wowts/lua";
import { insert, sort, concat } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { printFormat } from "../tools/tools";
import { OptionUiAll, OptionUiGroup } from "../ui/acegui-helpers";

export class Profiler {
    private timestamp = debugprofilestop();
    constructor(name: string, private profiler: OvaleProfilerClass) {
        const args = profiler.moduleOptions;
        args[name] = {
            name: name,
            desc: format(l["enable_profiling"], name),
            type: "toggle",
        };
        profiler.profiles[name] = this;
    }

    enabled = false;

    startProfiling(tag: string) {
        if (!this.enabled) return;
        const newTimestamp = debugprofilestop();
        if (this.profiler.stackSize > 0) {
            const delta = newTimestamp - this.timestamp;
            const previous = this.profiler.stack[this.profiler.stackSize];
            let timeSpent = this.profiler.timeSpent[previous] || 0;
            timeSpent = timeSpent + delta;
            this.profiler.timeSpent[previous] = timeSpent;
        }
        this.timestamp = newTimestamp;
        this.profiler.stackSize = this.profiler.stackSize + 1;
        this.profiler.stack[this.profiler.stackSize] = tag;
        {
            let timesInvoked = this.profiler.timesInvoked[tag] || 0;
            timesInvoked = timesInvoked + 1;
            this.profiler.timesInvoked[tag] = timesInvoked;
        }
    }

    stopProfiling(tag: string) {
        if (!this.enabled) return;
        if (this.profiler.stackSize > 0) {
            const currentTag = this.profiler.stack[this.profiler.stackSize];
            if (currentTag == tag) {
                const newTimestamp = debugprofilestop();
                const delta = newTimestamp - this.timestamp;
                let timeSpent = this.profiler.timeSpent[currentTag] || 0;
                timeSpent = timeSpent + delta;
                this.profiler.timeSpent[currentTag] = timeSpent;
                this.timestamp = newTimestamp;
                this.profiler.stackSize = this.profiler.stackSize - 1;
            }
        }
    }
}

export class OvaleProfilerClass {
    public timeSpent: LuaObj<number> = {};
    public timesInvoked: LuaObj<number> = {};
    public stack: LuaArray<string> = {};
    public stackSize = 0;

    profilingOutput: TextDump;
    profiles: LuaObj<{ enabled: boolean }> = {};

    actions: LuaObj<OptionUiAll> = {
        profiling: {
            name: l["profiling"],
            type: "execute",
            func: () => {
                const appName = this.ovale.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            },
        },
    };

    moduleOptions: LuaObj<OptionUiAll> = {};

    options: OptionUiGroup = {
        name: `${this.ovale.GetName()} ${l["profiling"]}`,
        type: "group",
        args: {
            profiling: {
                name: l["profiling"],
                type: "group",
                args: {
                    modules: {
                        name: l["modules"],
                        type: "group",
                        inline: true,
                        order: 10,
                        args: this.moduleOptions,
                        get: (info: LuaArray<string>) => {
                            const name = info[lualength(info)];
                            const value = this.ovaleOptions.db.global.profiler[
                                name
                            ];
                            return value;
                        },
                        set: (info: LuaArray<string>, value: boolean) => {
                            const name = info[lualength(info)];
                            this.ovaleOptions.db.global.profiler[name] = value;
                            if (value) {
                                this.enableProfiling(name);
                            } else {
                                this.disableProfiling(name);
                            }
                        },
                    },
                    reset: {
                        name: l["reset"],
                        desc: l["reset_profiling"],
                        type: "execute",
                        order: 20,
                        func: () => {
                            this.resetProfiling();
                        },
                    },
                    show: {
                        name: l["show"],
                        desc: l["show_profiling_statistics"],
                        type: "execute",
                        order: 30,
                        func: () => {
                            this.profilingOutput.Clear();
                            const s = this.getProfilingInfo();
                            if (s) {
                                this.profilingOutput.AddLine(s);
                                this.profilingOutput.Display();
                            }
                        },
                    },
                },
            },
        },
    };

    private module: AceModule;

    constructor(
        private ovaleOptions: OvaleOptionsClass,
        private ovale: OvaleClass
    ) {
        for (const [k, v] of pairs(this.actions)) {
            ovaleOptions.actions.args[k] = v;
        }
        ovaleOptions.defaultDB.global = ovaleOptions.defaultDB.global || {};
        ovaleOptions.defaultDB.global.profiler = {};
        ovaleOptions.registerOptions();
        this.module = ovale.createModule(
            "OvaleProfiler",
            this.handleInitialize,
            this.handleDisable
        );
        this.profilingOutput = LibTextDump.New(
            `${this.ovale.GetName()} - ${l["profiling"]}`,
            750,
            500
        );
    }

    private handleInitialize = () => {
        const appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(
            appName,
            l["profiling"],
            this.ovale.GetName()
        );
    };

    private handleDisable = () => {
        this.profilingOutput.Clear();
    };

    create(name: string) {
        return new Profiler(name, this);
    }

    private array: LuaArray<string> = {};

    private resetProfiling() {
        for (const [tag] of pairs(this.timeSpent)) {
            delete this.timeSpent[tag];
        }
        for (const [tag] of pairs(this.timesInvoked)) {
            delete this.timesInvoked[tag];
        }
    }

    private getProfilingInfo() {
        if (next(this.timeSpent)) {
            let width = 1;
            {
                let tenPower = 10;
                for (const [, timesInvoked] of pairs(this.timesInvoked)) {
                    while (timesInvoked > tenPower) {
                        width = width + 1;
                        tenPower = tenPower * 10;
                    }
                }
            }
            wipe(this.array);
            const formatString = format(
                "    %%08.3fms: %%0%dd (%%05f) x %%s",
                width
            );
            for (const [tag, timeSpent] of pairs(this.timeSpent)) {
                const timesInvoked = this.timesInvoked[tag];
                insert(
                    this.array,
                    format(
                        formatString,
                        timeSpent,
                        timesInvoked,
                        timeSpent / timesInvoked,
                        tag
                    )
                );
            }
            if (next(this.array)) {
                sort(this.array);
                const now = GetTime();
                insert(
                    this.array,
                    1,
                    format("Profiling statistics at %f:", now)
                );
                return concat(this.array, "\n");
            }
        }
    }

    debuggingInfo() {
        printFormat("Profiler stack size = %d", this.stackSize);
        let index = this.stackSize;
        while (index > 0 && this.stackSize - index < 10) {
            const tag = this.stack[index];
            printFormat("    [%d] %s", index, tag);
            index = index - 1;
        }
    }

    enableProfiling(name: string) {
        this.profiles[name].enabled = true;
    }
    disableProfiling(name: string) {
        this.profiles[name].enabled = false;
    }
}
