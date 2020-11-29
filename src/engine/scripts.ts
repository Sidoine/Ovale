import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "../ui/Localization";
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
import { OvaleDebugClass, Tracer } from "./debug";
import { OptionUiAll } from "../ui/acegui-helpers";

export const DEFAULT_NAME = "Ovale";
const DEFAULT_DESCRIPTION = L["Script défaut"];
const CUSTOM_NAME = "custom";
const CUSTOM_DESCRIPTION = L["Script personnalisé"];
const DISABLED_NAME = "Disabled";
const DISABLED_DESCRIPTION = L["Disabled"];

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
        ovaleDebug: OvaleDebugClass
    ) {
        this.module = ovale.createModule(
            "OvaleScripts",
            this.OnInitialize,
            this.OnDisable,
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
                name: L["Code"],
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
        ovaleOptions.RegisterOptions();
    }

    private OnInitialize = () => {
        this.CreateOptions();
        this.RegisterScript(
            undefined,
            undefined,
            DEFAULT_NAME,
            DEFAULT_DESCRIPTION,
            undefined,
            "script"
        );
        this.RegisterScript(
            this.ovale.playerClass,
            undefined,
            CUSTOM_NAME,
            CUSTOM_DESCRIPTION,
            this.ovaleOptions.db.profile.code,
            "script"
        );
        this.RegisterScript(
            undefined,
            undefined,
            DISABLED_NAME,
            DISABLED_DESCRIPTION,
            undefined,
            "script"
        );
        this.module.RegisterMessage(
            "Ovale_ScriptChanged",
            this.InitScriptProfiles
        );
    };
    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_ScriptChanged");
    };
    GetDescriptions(scriptType: ScriptType | undefined) {
        const descriptionsTable: LuaObj<string> = {};
        for (const [name, script] of pairs(this.script)) {
            if (
                (!scriptType || script.type === scriptType) &&
                (!script.className ||
                    script.className === this.ovale.playerClass) &&
                (!script.specialization ||
                    this.ovalePaperDoll.IsSpecialization(script.specialization))
            ) {
                if (name == DEFAULT_NAME) {
                    descriptionsTable[name] = `${
                        script.desc
                    } (${this.GetScriptName(name)})`;
                } else {
                    descriptionsTable[name] = script.desc || "No description";
                }
            }
        }
        return descriptionsTable;
    }
    RegisterScript(
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
    UnregisterScript(name: string) {
        delete this.script[name];
    }
    SetScript(name: string) {
        const oldSource = this.getCurrentSpecScriptName();
        if (oldSource !== name) {
            this.setCurrentSpecScriptName(name);
            this.module.SendMessage("Ovale_ScriptChanged");
        }
    }
    GetDefaultScriptName(
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
            name = format("sc_t25_%s_%s", scClassName, specialization);
            if (!this.script[name]) {
                this.tracer.Log(`Script ${name} not found`);
                name = DISABLED_NAME;
            }
        } else {
            return DISABLED_NAME;
        }
        return name;
    }
    GetScriptName(name: string) {
        return (
            (name == DEFAULT_NAME &&
                this.GetDefaultScriptName(
                    this.ovale.playerClass,
                    this.ovalePaperDoll.GetSpecialization()
                )) ||
            name
        );
    }
    GetScript(name: string) {
        name = this.GetScriptName(name);
        if (name && this.script[name]) {
            return this.script[name].code;
        }
        return undefined;
    }
    GetScriptOrDefault(name: string) {
        return (
            this.GetScript(name) ||
            this.GetScript(
                this.GetDefaultScriptName(
                    this.ovale.playerClass,
                    this.ovalePaperDoll.GetSpecialization()
                )
            )
        );
    }

    private getCurrentSpecIdentifier() {
        return `${
            this.ovale.playerClass
        }_${this.ovalePaperDoll.GetSpecialization()}`;
    }

    getCurrentSpecScriptName() {
        return this.ovaleOptions.db.profile.source[
            this.getCurrentSpecIdentifier()
        ];
    }

    setCurrentSpecScriptName(source: string) {
        this.ovaleOptions.db.profile.source[
            this.getCurrentSpecIdentifier()
        ] = source;
    }

    CreateOptions() {
        const options = {
            name: `${this.ovale.GetName()} ${L["Script"]}`,
            type: "group",
            args: {
                source: {
                    order: 10,
                    type: "select",
                    name: L["Script"],
                    width: "double",
                    values: (info: any) => {
                        const scriptType =
                            (!this.ovaleOptions.db.profile.showHiddenScripts &&
                                "script") ||
                            undefined;
                        return this.GetDescriptions(scriptType);
                    },
                    get: (info: any) => {
                        return this.getCurrentSpecScriptName();
                    },
                    set: (info: any, v: string) => {
                        this.SetScript(v);
                    },
                },
                script: {
                    order: 20,
                    type: "input",
                    multiline: 25,
                    name: L["Script"],
                    width: "full",
                    disabled: () => {
                        return this.getCurrentSpecScriptName() !== CUSTOM_NAME;
                    },
                    get: (info: any) => {
                        const code =
                            this.GetScript(this.getCurrentSpecScriptName()) ||
                            "";
                        return gsub(code, "\t", "    ");
                    },
                    set: (info: any, v: string) => {
                        this.RegisterScript(
                            this.ovale.playerClass,
                            undefined,
                            CUSTOM_NAME,
                            CUSTOM_DESCRIPTION,
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
                    name: L["Copier sur Script personnalisé"],
                    disabled: () => {
                        return this.getCurrentSpecScriptName() === CUSTOM_NAME;
                    },
                    confirm: () => {
                        return L["Ecraser le Script personnalisé préexistant?"];
                    },
                    func: () => {
                        const code = this.GetScript(
                            this.getCurrentSpecScriptName()
                        );
                        this.RegisterScript(
                            this.ovale.playerClass,
                            undefined,
                            CUSTOM_NAME,
                            CUSTOM_DESCRIPTION,
                            code,
                            "script"
                        );
                        this.setCurrentSpecScriptName(CUSTOM_NAME);
                        const script = this.GetScript(CUSTOM_NAME);
                        if (script) this.ovaleOptions.db.profile.code = script;
                        this.module.SendMessage("Ovale_ScriptChanged");
                    },
                },
                showHiddenScripts: {
                    order: 40,
                    type: "toggle",
                    name: L["Show hidden"],
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
            L["Script"],
            this.ovale.GetName()
        );
    }

    private InitScriptProfiles = () => {
        const countSpecializations = GetNumSpecializations(false, false);
        if (!isLuaArray(this.ovaleOptions.db.profile.source)) {
            this.ovaleOptions.db.profile.source = {};
        }
        for (let i = 1; i < countSpecializations; i += 1) {
            const specName = this.ovalePaperDoll.GetSpecialization(
                i as SpecializationIndex
            );
            if (specName) {
                this.ovaleOptions.db.profile.source[
                    `${this.ovale.playerClass}_${specName}`
                ] =
                    this.ovaleOptions.db.profile.source[
                        `${this.ovale.playerClass}_${specName}`
                    ] ||
                    this.GetDefaultScriptName(this.ovale.playerClass, specName);
            }
        }
    };
}
