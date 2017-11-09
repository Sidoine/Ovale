import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { OvaleOptions } from "./Options";
import { L } from "./Localization";
import { OvalePaperDoll } from "./PaperDoll";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { format, gsub, lower } from "@wowts/string";
import { pairs } from "@wowts/lua";

let OvaleScriptsBase = Ovale.NewModule("OvaleScripts", aceEvent);
export let OvaleScripts: OvaleScriptsClass;
let DEFAULT_NAME = "Ovale";
let DEFAULT_DESCRIPTION = L["Script défaut"];
let CUSTOM_NAME = "custom";
let CUSTOM_DESCRIPTION = L["Script personnalisé"];
let DISABLED_NAME = "Disabled";
let DISABLED_DESCRIPTION = L["Disabled"];
{
    let defaultDB = {
        code: "",
        source: "Ovale",
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
    for (const [k, v] of pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile[k] = v;
    }
    for (const [k, v] of pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleScripts);
}

interface Script {

}

class OvaleScriptsClass  extends OvaleScriptsBase {

    script:Script = {}

    constructor() {
        super();
    }

    OnInitialize() {
        this.CreateOptions();
        this.RegisterScript(undefined, undefined, DEFAULT_NAME, DEFAULT_DESCRIPTION, undefined, "script");
        this.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script");
        this.RegisterScript(undefined, undefined, DISABLED_NAME, DISABLED_DESCRIPTION, undefined, "script");
        this.RegisterMessage("Ovale_StanceChanged");
    }
    OnDisable() {
        this.UnregisterMessage("Ovale_StanceChanged");
    }
    Ovale_StanceChanged(event, newStance, oldStance) {
    }
    GetDescriptions(scriptType) {
        let descriptionsTable = {
        }
        for (const [name, script] of pairs(this.script)) {
            if ((!scriptType || script.type == scriptType) && (!script.specialization || OvalePaperDoll.IsSpecialization(script.specialization))) {
                if (name == DEFAULT_NAME) {
                    descriptionsTable[name] = `${script.desc} (${this.GetScriptName(name)})`;
                } else {
                    descriptionsTable[name] = script.desc;
                }
            }
        }
        return descriptionsTable;
    }
    RegisterScript(className, specialization, name, description, code, scriptType) {
        if (!className || className == Ovale.playerClass) {
            this.script[name] = this.script[name] || {
            }
            let script = this.script[name];
            script.type = scriptType || "script";
            script.desc = description || name;
            script.specialization = specialization;
            script.code = code || "";
        }
    }
    UnregisterScript(name) {
        this.script[name] = undefined;
    }
    SetScript(name) {
        const oldSource = Ovale.db.profile.source;
        if (oldSource != name) {
            Ovale.db.profile.source = name;
            this.SendMessage("Ovale_ScriptChanged");
        }
    }
    GetDefaultScriptName(className, specialization) {
        let name;
        if (className == "DEATHKNIGHT") {
            if (specialization == "blood") {
                name = "icyveins_deathknight_blood";
            } else if (specialization == "frost") {
                name = "sc_death_knight_frost_t19";
            } else if (specialization == "unholy") {
                name = "sc_death_knight_unholy_t19";
            }
        } else if (className == "DEMONHUNTER") {
            if (specialization == "vengeance") {
                name = "icyveins_demonhunter_vengeance";
            } else if (specialization == "havoc") {
                name = "sc_demon_hunter_havoc_t19";
            }
        } else if (className == "DRUID") {
            if (specialization == "restoration") {
                name = DISABLED_NAME;
            } else if (specialization == "guardian") {
                name = "icyveins_druid_guardian";
            }
        } else if (className == "MONK") {
            if (specialization == "mistweaver") {
                name = DISABLED_NAME;
            } else if (specialization == "brewmaster") {
                name = "icyveins_monk_brewmaster";
            }
        } else if (className == "PALADIN") {
            if (specialization == "holy") {
                name = "icyveins_paladin_holy";
            } else if (specialization == "protection") {
                name = "icyveins_paladin_protection";
            }
        } else if (className == "PRIEST") {
            if (specialization == "discipline") {
                name = "icyveins_priest_discipline";
            } else if (specialization == "holy") {
                name = DISABLED_NAME;
            }
        } else if (className == "SHAMAN") {
            if (specialization == "restoration") {
                name = DISABLED_NAME;
            }
        } else if (className == "WARRIOR") {
            if (specialization == "protection") {
                name = "icyveins_warrior_protection";
            }
        }
        if (!name && specialization) {
            name = format("sc_%s_%s_t19", lower(className), specialization);
        }
        if (!(name && this.script[name])) {
            name = DISABLED_NAME;
        }
        return name;
    }
    GetScriptName(name) {
        return (name == DEFAULT_NAME) && this.GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll.GetSpecialization()) || name;
    }
    GetScript(name) {
        name = this.GetScriptName(name);
        if (name && this.script[name]) {
            return this.script[name].code;
        }
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
                    values: (info) => {
                        let scriptType = !Ovale.db.profile.showHiddenScripts && "script";
                        return OvaleScripts.GetDescriptions(scriptType);
                    },
                    get: (info) => {
                        return Ovale.db.profile.source;
                    },
                    set: (info, v) => {
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
                        return Ovale.db.profile.source != CUSTOM_NAME;
                    },
                    get: (info)  => {
                        let code = OvaleScripts.GetScript(Ovale.db.profile.source);
                        code = code || "";
                        return gsub(code, "\t", "    ");
                    },
                    set: (info, v) => {
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
                        return Ovale.db.profile.source == CUSTOM_NAME;
                    },
                    confirm: () => {
                        return L["Ecraser le Script personnalisé préexistant?"];
                    },
                    func: () => {
                        let code = OvaleScripts.GetScript(Ovale.db.profile.source);
                        OvaleScripts.RegisterScript(Ovale.playerClass, undefined, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script");
                        Ovale.db.profile.source = CUSTOM_NAME;
                        Ovale.db.profile.code = OvaleScripts.GetScript(CUSTOM_NAME);
                        this.SendMessage("Ovale_ScriptChanged");
                    }
                },
                showHiddenScripts: {
                    order: 40,
                    type: "toggle",
                    name: L["Show hidden"],
                    get: (info) => {
                        return Ovale.db.profile.showHiddenScripts;
                    },
                    set: (info, value) => {
                        Ovale.db.profile.showHiddenScripts = value;
                    }
                }
            }
        }
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(appName, L["Script"], Ovale.GetName());
    }
}

OvaleScripts = new OvaleScriptsClass();