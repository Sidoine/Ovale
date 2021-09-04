import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { l } from "../ui/Localization";
import { SpecializationName, OvalePaperDollClass } from "../states/PaperDoll";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { format, gsub, lower } from "@wowts/string";
import { pairs, LuaObj, kpairs } from "@wowts/lua";
import { ClassId, SpecializationIndex } from "@wowts/wow-mock";
import { isLuaArray } from "../tools/tools";
import { GetNumSpecializations } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleOptionsClass } from "../ui/Options";
import { DebugTools, Tracer } from "./debug";
import { OptionUiAll } from "../ui/acegui-helpers";

export const defaultScriptName = "Ovale";
const defaultScriptDescription = l["default_script"];
const customScriptName = "custom";
const customScriptDescription = l["custom_script"];
const disabledScriptName = "Disabled";
const disabledScriptDescription = l["disabled"];

export type ScriptType = "script" | "include";

export interface Script {
    type?: ScriptType;
    desc?: string;
    className?: ClassId;
    specialization?: SpecializationName;
    code?: string;
}

export class OvaleScriptsClass {
    script: LuaObj<Script> = {};

    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovalePaperDoll: OvalePaperDollClass,
        ovaleDebug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleScripts",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());

        const defaultDB = {
            code: "",
            source: {},
            showHiddenScripts: false,
        };
        const actions: LuaObj<OptionUiAll> = {
            code: {
                name: l["code"],
                type: "execute",
                func: () => {
                    const appName = this.module.GetName();
                    AceConfigDialog.SetDefaultSize(appName, 700, 550);
                    AceConfigDialog.Open(appName);
                },
            },
        };
        for (const [k, v] of kpairs(defaultDB)) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            (<any>ovaleOptions.defaultDB.profile)[k] = v;
        }
        for (const [k, v] of pairs(actions)) {
            ovaleOptions.actions.args[k] = v;
        }
        ovaleOptions.registerOptions();
    }

    private handleInitialize = () => {
        this.createOptions();
        this.registerScript(
            undefined,
            undefined,
            defaultScriptName,
            defaultScriptDescription,
            undefined,
            "script"
        );
        this.registerScript(
            this.ovale.playerClass,
            undefined,
            customScriptName,
            customScriptDescription,
            this.ovaleOptions.db.profile.code,
            "script"
        );
        this.registerScript(
            undefined,
            undefined,
            disabledScriptName,
            disabledScriptDescription,
            undefined,
            "script"
        );
        this.module.RegisterMessage(
            "Ovale_ScriptChanged",
            this.initScriptProfiles
        );
    };
    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_ScriptChanged");
    };
    getDescriptions(scriptType: ScriptType | undefined) {
        const descriptionsTable: LuaObj<string> = {};
        for (const [name, script] of pairs(this.script)) {
            if (
                (!scriptType || script.type === scriptType) &&
                (!script.className ||
                    script.className === this.ovale.playerClass) &&
                (!script.specialization ||
                    this.ovalePaperDoll.isSpecialization(script.specialization))
            ) {
                if (name == defaultScriptName) {
                    descriptionsTable[name] = `${
                        script.desc
                    } (${this.getScriptName(name)})`;
                } else {
                    descriptionsTable[name] = script.desc || "No description";
                }
            }
        }
        return descriptionsTable;
    }
    registerScript(
        className: ClassId | undefined,
        specialization: SpecializationName | undefined,
        name: string,
        description: string,
        code: string | undefined,
        scriptType: ScriptType
    ) {
        this.script[name] = this.script[name] || {};
        const script = this.script[name];
        script.type = scriptType || "script";
        script.desc = description || name;
        script.specialization = specialization;
        script.code = code || "";
        script.className = className;
    }
    unregisterScript(name: string) {
        delete this.script[name];
    }
    setScript(name: string) {
        const oldSource = this.getCurrentSpecScriptName();
        if (oldSource !== name) {
            this.setCurrentSpecScript(name);
            this.module.SendMessage("Ovale_ScriptChanged");
        }
    }
    getDefaultScriptName(
        className: ClassId,
        specialization: SpecializationName
    ) {
        let name = undefined;
        let scClassName = lower(className);

        if (className === "DEMONHUNTER") {
            scClassName = "demon_hunter";
        } else if (className === "DEATHKNIGHT") {
            scClassName = "death_knight";
        }

        if (specialization) {
            name = format("sc_t27_%s_%s", scClassName, specialization);
            if (!this.script[name]) {
                this.tracer.log(`Script ${name} not found`);
                name = disabledScriptName;
            }
        } else {
            return disabledScriptName;
        }
        return name;
    }
    getScriptName(name: string) {
        return (
            (name == defaultScriptName &&
                this.getDefaultScriptName(
                    this.ovale.playerClass,
                    this.ovalePaperDoll.getSpecialization()
                )) ||
            name
        );
    }
    getScript(name: string) {
        name = this.getScriptName(name);
        if (name && this.script[name]) {
            return this.script[name].code;
        }
        return undefined;
    }
    getScriptOrDefault(name: string) {
        return (
            this.getScript(name) ||
            this.getScript(
                this.getDefaultScriptName(
                    this.ovale.playerClass,
                    this.ovalePaperDoll.getSpecialization()
                )
            )
        );
    }

    getCurrentSpecScriptId() {
        return `${
            this.ovale.playerClass
        }_${this.ovalePaperDoll.getSpecialization()}`;
    }

    getCurrentSpecScriptName() {
        return this.ovaleOptions.db.profile.source[
            this.getCurrentSpecScriptId()
        ];
    }

    setCurrentSpecScript(scriptName: string) {
        this.ovaleOptions.db.profile.source[this.getCurrentSpecScriptId()] =
            scriptName;
    }

    createOptions() {
        const options = {
            name: `${this.ovale.GetName()} ${l["script"]}`,
            type: "group",
            args: {
                source: {
                    order: 10,
                    type: "select",
                    name: l["script"],
                    width: "double",
                    values: (info: any) => {
                        const scriptType =
                            (!this.ovaleOptions.db.profile.showHiddenScripts &&
                                "script") ||
                            undefined;
                        return this.getDescriptions(scriptType);
                    },
                    get: (info: any) => {
                        return this.getCurrentSpecScriptName();
                    },
                    set: (info: any, v: string) => {
                        this.setScript(v);
                    },
                },
                script: {
                    order: 20,
                    type: "input",
                    multiline: 25,
                    name: l["script"],
                    width: "full",
                    disabled: () => {
                        return (
                            this.getCurrentSpecScriptName() !== customScriptName
                        );
                    },
                    get: (info: any) => {
                        const code =
                            this.getScript(this.getCurrentSpecScriptName()) ||
                            "";
                        return gsub(code, "\t", "    ");
                    },
                    set: (info: any, v: string) => {
                        this.registerScript(
                            this.ovale.playerClass,
                            undefined,
                            customScriptName,
                            customScriptDescription,
                            v,
                            "script"
                        );
                        this.ovaleOptions.db.profile.code = v;
                        this.module.SendMessage("Ovale_ScriptChanged");
                    },
                },
                copy: {
                    order: 30,
                    type: "execute",
                    name: l["copy_to_custom_script"],
                    disabled: () => {
                        return (
                            this.getCurrentSpecScriptName() === customScriptName
                        );
                    },
                    confirm: () => {
                        return l["overwrite_existing_script"];
                    },
                    func: () => {
                        const code = this.getScript(
                            this.getCurrentSpecScriptName()
                        );
                        this.registerScript(
                            this.ovale.playerClass,
                            undefined,
                            customScriptName,
                            customScriptDescription,
                            code,
                            "script"
                        );
                        this.setCurrentSpecScript(customScriptName);
                        const script = this.getScript(customScriptName);
                        if (script) this.ovaleOptions.db.profile.code = script;
                        this.module.SendMessage("Ovale_ScriptChanged");
                    },
                },
                showHiddenScripts: {
                    order: 40,
                    type: "toggle",
                    name: l["show_hidden"],
                    get: (info: any) => {
                        return this.ovaleOptions.db.profile.showHiddenScripts;
                    },
                    set: (info: any, value: boolean) => {
                        this.ovaleOptions.db.profile.showHiddenScripts = value;
                    },
                },
            },
        };
        const appName = this.module.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(
            appName,
            l["script"],
            this.ovale.GetName()
        );
    }

    private initScriptProfiles = () => {
        const countSpecializations = GetNumSpecializations(false, false);
        if (!isLuaArray(this.ovaleOptions.db.profile.source)) {
            this.ovaleOptions.db.profile.source = {};
        }
        for (let i = 1; i <= countSpecializations; i += 1) {
            const specName = this.ovalePaperDoll.getSpecialization(
                i as SpecializationIndex
            );
            if (specName) {
                this.ovaleOptions.db.profile.source[
                    `${this.ovale.playerClass}_${specName}`
                ] =
                    this.ovaleOptions.db.profile.source[
                        `${this.ovale.playerClass}_${specName}`
                    ] ||
                    this.getDefaultScriptName(this.ovale.playerClass, specName);
            }
        }
    };
}
