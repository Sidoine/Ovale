import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { OvaleOptions } from "./Options";
import { L } from "./Localization";
import { OvalePaperDoll, SpecializationName } from "./PaperDoll";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { format, gsub, lower } from "@wowts/string";
import { pairs, LuaObj, kpairs } from "@wowts/lua";
import { ClassId, SpecializationIndex } from "@wowts/wow-mock";
import { isLuaArray } from "./tools";
import { GetNumSpecializations } from "@wowts/wow-mock";
import { OvaleDebug } from "./Debug";

let OvaleScriptsBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleScripts", aceEvent));
export let OvaleScripts: OvaleScriptsClass;
export let DEFAULT_NAME = "Ovale";
let DEFAULT_DESCRIPTION = L["Script défaut"];
const CUSTOM_NAME = "custom";
let CUSTOM_DESCRIPTION = L["Script personnalisé"];
let DISABLED_NAME = "Disabled";
let DISABLED_DESCRIPTION = L["Disabled"];
{
    let defaultDB = {
        code: "",
        source: {},
        showHiddenScripts: false
    }
    let actions = {
        code: {
            name: L["Code"],
            type: "execute",
            func: function () {
                let appName = OvaleScripts.GetName();
                AceConfigDialog.SetDefaultSize(appName, 700, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }
    for (const [k, v] of kpairs(defaultDB)) {
        OvaleOptions.defaultDB.profile[k] = v;
    }
    for (const [k, v] of pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleScripts);
}

export type ScriptType = "script" | "include";

interface Script {
    type?: ScriptType;
    desc?: string;
    className?: ClassId;
    specialization?: SpecializationName;
    code?: string;
}

class OvaleScriptsClass  extends OvaleScriptsBase {

    script:LuaObj<Script> = {}

    constructor() {
        super();
    }

    OnInitialize() {
        this.CreateOptions();
        this.RegisterScript(undefined, undefined, DEFAULT_NAME, DEFAULT_DESCRIPTION, undefined, "script");
        this.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script");
        this.RegisterScript(undefined, undefined, DISABLED_NAME, DISABLED_DESCRIPTION, undefined, "script");
        this.RegisterMessage("Ovale_StanceChanged");
        this.RegisterMessage("Ovale_ScriptChanged", "InitScriptProfiles");
    }
    OnDisable() {
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_ScriptChanged");
    }
    Ovale_StanceChanged(event: string, newStance: string, oldStance: string) {
    }
    GetDescriptions(scriptType: ScriptType | undefined) {
        let descriptionsTable: LuaObj<string> = {}
        for (const [name, script] of pairs(this.script)) {
            if ((!scriptType || script.type === scriptType) 
            && (!script.className || script.className === Ovale.playerClass)
            && (!script.specialization || OvalePaperDoll.IsSpecialization(script.specialization))) {
                if (name == DEFAULT_NAME) {
                    descriptionsTable[name] = `${script.desc} (${this.GetScriptName(name)})`;
                } else {
                    descriptionsTable[name] = script.desc;
                }
            }
        }
        return descriptionsTable;
    }
    RegisterScript(className: ClassId, specialization: SpecializationName, name: string, description: string, code: string, scriptType: ScriptType) {
        this.script[name] = this.script[name] || {};
        let script = this.script[name];
        script.type = scriptType || "script";
        script.desc = description || name;
        script.specialization = specialization;
        script.code = code || "";
        script.className = className;
    }
    UnregisterScript(name: string) {
        this.script[name] = undefined;
    }
    SetScript(name: string) {
        const oldSource = this.getCurrentSpecScriptName();
        if (oldSource !== name) {
            this.setCurrentSpecScriptName(name);
            this.SendMessage("Ovale_ScriptChanged");
        }
    }
    GetDefaultScriptName(className: ClassId, specialization: SpecializationName) {
        let name = undefined;
        let scClassName = lower(className);

        if (className === "DEMONHUNTER") {
            scClassName = "demon_hunter";
        } else if (className === "DEATHKNIGHT") {
            scClassName = "death_knight";
        }

        if (!name && specialization) {
            name = format("sc_pr_%s_%s", scClassName, specialization);
        }
        if (!(name && this.script[name])) {
            name = DISABLED_NAME;
        }
        return name;
    }
    GetScriptName(name: string) {
        return (name == DEFAULT_NAME) && this.GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll.GetSpecialization()) || name;
    }
    GetScript(name: string) {
        name = this.GetScriptName(name);
        if (name && this.script[name]) {
            return this.script[name].code;
        }
    }

    private getCurrentSpecIdentifier() {
        return `${Ovale.playerClass}_${OvalePaperDoll.GetSpecialization()}`;
    }

    getCurrentSpecScriptName() {
        return Ovale.db.profile.source[this.getCurrentSpecIdentifier()];
    }

    setCurrentSpecScriptName(source: string) {
        Ovale.db.profile.source[this.getCurrentSpecIdentifier()] = source;
    }

    CreateOptions() {
        let options = {
            name: `${Ovale.GetName()} ${L["Script"]}`,
            type: "group",
            args: {
                source: {
                    order: 10,
                    type: "select",
                    name: L["Script"],
                    width: "double",
                    values: (info: any) => {
                        const scriptType = (!Ovale.db.profile.showHiddenScripts && "script") || undefined;
                        return OvaleScripts.GetDescriptions(scriptType);
                    },
                    get: (info: any) => {
                        return this.getCurrentSpecScriptName();
                    },
                    set: (info: any, v: string) => {
                        this.SetScript(v);
                    }
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
                    get: (info: any)  => {
                        const code = OvaleScripts.GetScript(this.getCurrentSpecScriptName()) || "";
                        return gsub(code, "\t", "    ");
                    },
                    set: (info: any, v: string) => {
                        OvaleScripts.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script");
                        Ovale.db.profile.code = v;
                        this.SendMessage("Ovale_ScriptChanged");
                    }
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
                        const code = OvaleScripts.GetScript(this.getCurrentSpecScriptName());
                        OvaleScripts.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script");
                        this.setCurrentSpecScriptName(CUSTOM_NAME);
                        Ovale.db.profile.code = OvaleScripts.GetScript(CUSTOM_NAME);
                        this.SendMessage("Ovale_ScriptChanged");
                    }
                },
                showHiddenScripts: {
                    order: 40,
                    type: "toggle",
                    name: L["Show hidden"],
                    get: (info: any) => {
                        return Ovale.db.profile.showHiddenScripts;
                    },
                    set: (info: any, value: boolean) => {
                        Ovale.db.profile.showHiddenScripts = value;
                    }
                }
            }
        }
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(appName, L["Script"], Ovale.GetName());
    }

    InitScriptProfiles(){
        let countSpecializations = GetNumSpecializations(false, false);
        if(!isLuaArray(Ovale.db.profile.source)){
            Ovale.db.profile.source = {}
        }
        for(let i=1; i < countSpecializations; i += 1){
            let specName = OvalePaperDoll.GetSpecialization(i as SpecializationIndex)
            Ovale.db.profile.source[`${Ovale.playerClass}_${specName}`] = Ovale.db.profile.source[`${Ovale.playerClass}_${specName}`] || this.GetDefaultScriptName(Ovale.playerClass, specName);
        }
    }
}

OvaleScripts = new OvaleScriptsClass();