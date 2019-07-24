import { L } from "./Localization";
import LibDataBroker from "@wowts/lib_data_broker-1.1";
import LibDBIcon from "@wowts/lib_d_b_icon-1.0";
import { OvaleOptionsClass } from "./Options";
import { DEFAULT_NAME, OvaleScriptsClass } from "./Scripts";
import { OvaleVersion } from "./Version";
import { OvaleFrameModuleClass } from "./Frame";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, LuaArray } from "@wowts/lua";
import { insert } from "@wowts/table";
import { CreateFrame, EasyMenu, IsShiftKeyDown, UIParent, UIGameTooltip, UIFrame } from "@wowts/wow-mock";
import { OvalePaperDollClass } from "./PaperDoll";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { OvaleDebugClass } from "./Debug";

let CLASS_ICONS = {
    ["DEATHKNIGHT"]: "Interface\\Icons\\ClassIcon_DeathKnight",
    ["DEMONHUNTER"]: "Interface\\Icons\\ClassIcon_DemonHunter",
    ["DRUID"]: "Interface\\Icons\\ClassIcon_Druid",
    ["HUNTER"]: "Interface\\Icons\\ClassIcon_Hunter",
    ["MAGE"]: "Interface\\Icons\\ClassIcon_Mage",
    ["MONK"]: "Interface\\Icons\\ClassIcon_Monk",
    ["PALADIN"]: "Interface\\Icons\\ClassIcon_Paladin",
    ["PRIEST"]: "Interface\\Icons\\ClassIcon_Priest",
    ["ROGUE"]: "Interface\\Icons\\ClassIcon_Rogue",
    ["SHAMAN"]: "Interface\\Icons\\ClassIcon_Shaman",
    ["WARLOCK"]: "Interface\\Icons\\ClassIcon_Warlock",
    ["WARRIOR"]: "Interface\\Icons\\ClassIcon_Warrior"
}
let self_menuFrame: UIFrame = undefined;
let self_tooltipTitle: string = undefined;
let defaultDB = {
    minimap: {}
};

interface MenuItem {
    text: string;
    isTitle?: boolean;
    func?: () => void;
}

export class OvaleDataBrokerClass {
    private broker: any = undefined;
    private module: AceEvent & AceModule;

    constructor(
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleFrameModule: OvaleFrameModuleClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovale: OvaleClass,
        private ovaleDebug: OvaleDebugClass,
        private ovaleScripts: OvaleScriptsClass) {
        this.module = ovale.createModule("OvaleDataBroker", this.OnInitialize, this.OnDisable, aceEvent);
        let options = {
            minimap: {
                order: 25,
                type: "toggle",
                name: L["Show minimap icon"],
                get: (info: any) => {
                    return !this.ovaleOptions.db.profile.apparence.minimap.hide;
                },
                set: (info: any, value: boolean) => {
                    this.ovaleOptions.db.profile.apparence.minimap.hide = !value;
                    this.UpdateIcon();
                }
            }
        }
        for (const [k, v] of pairs(defaultDB)) {
            this.ovaleOptions.defaultDB.profile.apparence[k] = v;
        }
        for (const [k, v] of pairs(options)) {
            this.ovaleOptions.options.args.apparence.args[k] = v;
        }
        this.ovaleOptions.RegisterOptions(this);
    }

    private OnTooltipShow = (tooltip: UIGameTooltip) => {
        self_tooltipTitle = self_tooltipTitle || `${this.ovale.GetName()} ${OvaleVersion.version}`;
        tooltip.SetText(self_tooltipTitle, 1, 1, 1);
        tooltip.AddLine(L["Click to select the script."]);
        tooltip.AddLine(L["Middle-Click to toggle the script options panel."]);
        tooltip.AddLine(L["Right-Click for options."]);
        tooltip.AddLine(L["Shift-Right-Click for the current trace log."]);
    }

    private OnClick = (fr: any, button: "LeftButton") => {
        if (button == "LeftButton") {
            let menu:LuaArray<MenuItem> = {
                1: {
                    text: L["Script"],
                    isTitle: true
                }
            }
            const scriptType = (!this.ovaleOptions.db.profile.showHiddenScripts && "script") || undefined;
            let descriptions = this.ovaleScripts.GetDescriptions(scriptType);
            for (const [name, description] of pairs(descriptions)) {
                let menuItem = {
                    text: description,
                    func: function () {
                        this.ovaleScripts.SetScript(name);
                    }
                }
                insert(menu, menuItem);
            }
            self_menuFrame = self_menuFrame || CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate");
            EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU");
        } else if (button == "MiddleButton") {
            this.ovaleFrameModule.frame.ToggleOptions();
        } else if (button == "RightButton") {
            if (IsShiftKeyDown()) {
                this.ovaleDebug.DoTrace(true);
            } else {
                this.ovaleOptions.ToggleConfig();
            }
        }
    }

    private OnInitialize = () => {    
        if (LibDataBroker) {
            let broker = {
                type: "data source",
                text: "",
                icon: CLASS_ICONS[this.ovale.playerClass],
                OnClick: this.OnClick,
                OnTooltipShow: this.OnTooltipShow
            }
            this.broker = LibDataBroker.NewDataObject(this.ovale.GetName(), broker);
            if (LibDBIcon) {
                LibDBIcon.Register(this.ovale.GetName(), this.broker, this.ovaleOptions.db.profile.apparence.minimap);
            }
        }
   
        if (this.broker) {
            this.module.RegisterMessage("Ovale_ProfileChanged", this.UpdateIcon);
            this.module.RegisterMessage("Ovale_ScriptChanged", this.Ovale_ScriptChanged);
            this.module.RegisterMessage("Ovale_SpecializationChanged", this.Ovale_ScriptChanged);
			this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.Ovale_ScriptChanged);
            this.Ovale_ScriptChanged();
            this.UpdateIcon();
        }
    }

    private OnDisable = () => {
        if (this.broker) {
			this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_ProfileChanged");
            this.module.UnregisterMessage("Ovale_ScriptChanged");
        }
    }
    private UpdateIcon = () => {
        if (LibDBIcon && this.broker) {
            const minimap = this.ovaleOptions.db.profile.apparence.minimap
            LibDBIcon.Refresh(this.ovale.GetName(), minimap);
            if (minimap && minimap.hide) {
                LibDBIcon.Hide(this.ovale.GetName());
            } else {
                LibDBIcon.Show(this.ovale.GetName());
            }
        }
    }
    private Ovale_ScriptChanged = () => {
        const script = this.ovaleOptions.db.profile.source[`${this.ovale.playerClass}_${this.ovalePaperDoll.GetSpecialization()}`];
        this.broker.text = (script == DEFAULT_NAME && this.ovaleScripts.GetDefaultScriptName(this.ovale.playerClass, this.ovalePaperDoll.GetSpecialization())) || script || "Disabled";
    }
}
