import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import LibTextDump, { TextDump } from "@wowts/lib_text_dump-1.0";
import { OvaleOptions } from "./Options";
import { Constructor, Ovale } from "./Ovale";
import { debugprofilestop, GetTime } from "@wowts/wow-mock";
import { format } from "@wowts/string";
import { pairs, next, wipe, LuaObj, lualength } from "@wowts/lua";
import { insert, sort, concat } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";

let OvaleProfilerBase = Ovale.NewModule("OvaleProfiler");

let self_timestamp = debugprofilestop();
let self_timeSpent: LuaObj<number> = {}
let self_timesInvoked = {}
let self_stack = {}
let self_stackSize = 0;

class OvaleProfilerClass extends OvaleProfilerBase {
    self_profilingOutput: TextDump = undefined;
    profiles: LuaObj<{ enabled: boolean }> = {};

    actions = {
        profiling: {
            name: L["Profiling"],
            type: "execute",
            func: () => {
                let appName = this.GetName();
                AceConfigDialog.SetDefaultSize(appName, 800, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }

    options = {
        name: `${Ovale.GetName()} ${L["Profiling"]}`,
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
                        get: (info) => {
                            let name = info[lualength(info)];
                            const value = Ovale.db.global.profiler[name];
                            return (value != undefined);
                        },
                        set: (info, value) => {
                            value = value || undefined;
                            let name = info[lualength(info)];
                            Ovale.db.global.profiler[name] = value;
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

    DoNothing = function() {}

    
    constructor() {
        super();
        for (const [k, v] of pairs(this.actions)) {
            OvaleOptions.options.args.actions.args[k] = v;
        }
        OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global || {}
        OvaleOptions.defaultDB.global.profiler = {}
        OvaleOptions.RegisterOptions(OvaleProfilerClass);
    }

    OnInitialize() {
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, this.options);
        AceConfigDialog.AddToBlizOptions(appName, L["Profiling"], Ovale.GetName());
    
        if (!this.self_profilingOutput) {
            this.self_profilingOutput = LibTextDump.New(`${Ovale.GetName()} - ${L["Profiling"]}`, 750, 500);
        }
    }
    OnDisable() {
        this.self_profilingOutput.Clear();
    }
    RegisterProfiling<T extends Constructor<AceModule>>(module: T, name?: string) {
        const profiler = this;
        return class extends module {
            constructor(...__args:any[]) {
                super(...__args);
                name = name || this.GetName();
                profiler.options.args.profiling.args.modules.args[name] = {
                    name: name,
                    desc: format(L["Enable profiling for the %s module."], name),
                    type: "toggle"
                }
                profiler.profiles[name] = this;       
            }

            enabled = false;
            
            StartProfiling(tag) {
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
        
            StopProfiling(tag) {
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
        
    }

    array = {}
            
    ResetProfiling() {
        for (const [tag] of pairs(self_timeSpent)) {
            self_timeSpent[tag] = undefined;
        }
        for (const [tag] of pairs(self_timesInvoked)) {
            self_timesInvoked[tag] = undefined;
        }
    }

    GetProfilingInfo() {
        if (next(self_timeSpent)) {
            let width = 1;
            {
                let tenPower = 10;
                for (const [_, timesInvoked] of pairs(self_timesInvoked)) {
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
        Ovale.Print("Profiler stack size = %d", self_stackSize);
        let index = self_stackSize;
        while (index > 0 && self_stackSize - index < 10) {
            let tag = self_stack[index];
            Ovale.Print("    [%d] %s", index, tag);
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

export const OvaleProfiler = new OvaleProfilerClass();