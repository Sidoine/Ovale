import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptionsClass } from "./Options";
import { OvaleClass, Print } from "./Ovale";
import { debugprofilestop, GetTime } from "@wowts/wow-mock";
import { format } from "@wowts/string";
import { pairs, next, wipe, LuaObj, lualength, LuaArray } from "@wowts/lua";
import { insert, sort, concat } from "@wowts/table";

let self_timestamp = debugprofilestop();
let self_timeSpent: LuaObj<number> = {}
let self_timesInvoked: LuaObj<number> = {}
let self_stack: LuaArray<string> = {}
let self_stackSize = 0;

export class Profiler {
    constructor(name: string, profiler: OvaleProfilerClass) {
        const args = profiler.options.args.profiling.args.modules.args as any;
        args[name] = {
            name: name,
            desc: format(L["Enable profiling for the %s module."], name),
            type: "toggle"
        }
        profiler.profiles[name] = this;       
    }

    enabled = false;
    
    StartProfiling(tag: string) {
        if (!this.enabled) return;
        let newTimestamp = debugprofilestop();
        if (self_stackSize > 0) {
            let delta = newTimestamp - self_timestamp;
            let previous = self_stack[self_stackSize];
            let timeSpent = self_timeSpent[previous] || 0;
            timeSpent = timeSpent + delta;
            self_timeSpent[previous] = timeSpent;
        }
        self_timestamp = newTimestamp;
        self_stackSize = self_stackSize + 1;
        self_stack[self_stackSize] = tag;
        {
            let timesInvoked = self_timesInvoked[tag] || 0;
            timesInvoked = timesInvoked + 1;
            self_timesInvoked[tag] = timesInvoked;
        }
    }

    StopProfiling(tag: string) {
        if (!this.enabled) return;
        if (self_stackSize > 0) {
            let currentTag = self_stack[self_stackSize];
            if (currentTag == tag) {
                let newTimestamp = debugprofilestop();
                let delta = newTimestamp - self_timestamp;
                let timeSpent = self_timeSpent[currentTag] || 0;
                timeSpent = timeSpent + delta;
                self_timeSpent[currentTag] = timeSpent;
                self_timestamp = newTimestamp;
                self_stackSize = self_stackSize - 1;
            }
        }
    }
}

export class OvaleProfilerClass {
    self_profilingOutput: TextDump = undefined;
    profiles: LuaObj<{ enabled: boolean }> = {};

    actions = {
        profiling: {
            name: L["Profiling"],
            type: "execute",
            func: () => {
                let appName = this.ovale.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }

    options = {
        name: `${this.ovale.GetName()} ${L["Profiling"]}`,
        type: "group",
        args: {
            profiling: {
                name: L["Profiling"],
                type: "group",
                args: {
                    modules: {
                        name: L["Modules"],
                        type: "group",
                        inline: true,
                        order: 10,
                        args: {
                        },
                        get: (info: any) => {
                            let name = info[lualength(info)];
                            const value = this.ovaleOptions.db.global.profiler[name];
                            return (value != undefined);
                        },
                        set: (info: any, value: string) => {
                            value = value || undefined;
                            let name = info[lualength(info)];
                            this.ovaleOptions.db.global.profiler[name] = value;
                            if (value) {
                                this.EnableProfiling(name);
                            } else {
                                this.DisableProfiling(name);
                            }
                        }
                    },
                    reset: {
                        name: L["Reset"],
                        desc: L["Reset the profiling statistics."],
                        type: "execute",
                        order: 20,
                        func: () => {
                            this.ResetProfiling();
                        }
                    },
                    show: {
                        name: L["Show"],
                        desc: L["Show the profiling statistics."],
                        type: "execute",
                        order: 30,
                        func: () => {
                            this.self_profilingOutput.Clear();
                            let s = this.GetProfilingInfo();
                            if (s) {
                                this.self_profilingOutput.AddLine(s);
                                this.self_profilingOutput.Display();
                            }
                        }
                    }
                }
            }
        }
    }

    
    constructor(private ovaleOptions: OvaleOptionsClass, private ovale: OvaleClass) {
        for (const [k, v] of pairs(this.actions)) {
            ovaleOptions.options.args.actions.args[k] = v;
        }
        ovaleOptions.defaultDB.global = ovaleOptions.defaultDB.global || {}
        ovaleOptions.defaultDB.global.profiler = {}
        ovaleOptions.RegisterOptions(OvaleProfilerClass);
        ovale.createModule("OvaleProfiler", this.OnInitialize, this.OnDisable);
    }

    private OnInitialize = () => {
        let appName = this.ovale.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Profiling"], this.ovale.GetName());
    
        if (!this.self_profilingOutput) {
            this.self_profilingOutput = LibTextDump.New(`${this.ovale.GetName()} - ${L["Profiling"]}`, 750, 500);
        }
    }
    private OnDisable = () => {
        this.self_profilingOutput.Clear();
    }

    create(name: string) {
        return new Profiler(name, this);
    }

    private array = {}
            
    private ResetProfiling() {
        for (const [tag] of pairs(self_timeSpent)) {
            self_timeSpent[tag] = undefined;
        }
        for (const [tag] of pairs(self_timesInvoked)) {
            self_timesInvoked[tag] = undefined;
        }
    }

    private GetProfilingInfo() {
        if (next(self_timeSpent)) {
            let width = 1;
            {
                let tenPower = 10;
                for (const [, timesInvoked] of pairs(self_timesInvoked)) {
                    while (timesInvoked > tenPower) {
                        width = width + 1;
                        tenPower = tenPower * 10;
                    }
                }
            }
            wipe(this.array);
            let formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width);
            for (const [tag, timeSpent] of pairs(self_timeSpent)) {
                let timesInvoked = self_timesInvoked[tag];
                insert(this.array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag));
            }
            if (next(this.array)) {
                sort(this.array);
                let now = GetTime();
                insert(this.array, 1, format("Profiling statistics at %f:", now));
                return concat(this.array, "\n");
            }
        }
    }

    DebuggingInfo() {
        Print("Profiler stack size = %d", self_stackSize);
        let index = self_stackSize;
        while (index > 0 && self_stackSize - index < 10) {
            let tag = self_stack[index];
            Print("    [%d] %s", index, tag);
            index = index - 1;
        }
    }
    
    EnableProfiling(name: string) {
        this.profiles[name].enabled = true;
    }
    DisableProfiling(name: string) {
        this.profiles[name].enabled = false;
    }
}
