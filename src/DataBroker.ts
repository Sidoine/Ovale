import { L } from "./Localization";
import LibDataBroker from "@wowts/lib_data_broker-1.1";
import LibDBIcon from "@wowts/lib_d_b_icon-1.0";
import { OvaleDebug } from "./Debug";
import { OvaleOptions } from "./Options";
import { Ovale } from "./Ovale";
import { OvaleScripts } from "./Scripts";
import { OvaleVersion } from "./Version";
import { OvaleFrameModule } from "./Frame";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, LuaArray } from "@wowts/lua";
import { insert } from "@wowts/table";
import { CreateFrame, EasyMenu, IsShiftKeyDown, UIParent, UIGameTooltip, UIFrame } from "@wowts/wow-mock";
import { OvalePaperDoll } from "./PaperDoll";

let OvaleDataBrokerBase = Ovale.NewModule("OvaleDataBroker", aceEvent);
export let OvaleDataBroker: OvaleDataBrokerClass;

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
{
    let defaultDB = {
        minimap: {
        }
    }
    let options = {
        minimap: {
            order: 25,
            type: "toggle",
            name: L["Show minimap icon"],
            get: function (info: any) {
                return !Ovale.db.profile.apparence.minimap.hide;
            },
            set: function (info: any, value: boolean) {
                Ovale.db.profile.apparence.minimap.hide = !value;
                OvaleDataBroker.UpdateIcon();
            }
        }
    }
    for (const [k, v] of pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile.apparence[k] = v;
    }
    for (const [k, v] of pairs(options)) {
        OvaleOptions.options.args.apparence.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleDataBroker);
}

interface MenuItem {
    text: string;
    isTitle?: boolean;
    func?: () => void;
}

const OnClick = function(fr: any, button: "LeftButton") {
    if (button == "LeftButton") {
        let menu:LuaArray<MenuItem> = {
            1: {
                text: L["Script"],
                isTitle: true
            }
        }
        const scriptType = (!Ovale.db.profile.showHiddenScripts && "script") || undefined;
        let descriptions = OvaleScripts.GetDescriptions(scriptType);
        for (const [name, description] of pairs(descriptions)) {
            let menuItem = {
                text: description,
                func: function () {
                    OvaleScripts.SetScript(name);
                }
            }
            insert(menu, menuItem);
        }
        self_menuFrame = self_menuFrame || CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate");
        EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU");
    } else if (button == "MiddleButton") {
        OvaleFrameModule.frame.ToggleOptions();
    } else if (button == "RightButton") {
        if (IsShiftKeyDown()) {
            OvaleDebug.DoTrace(true);
        } else {
            OvaleOptions.ToggleConfig();
        }
    }
}
const OnTooltipShow = function(tooltip: UIGameTooltip) {
    self_tooltipTitle = self_tooltipTitle || `${Ovale.GetName()} ${OvaleVersion.version}`;
    tooltip.SetText(self_tooltipTitle, 1, 1, 1);
    tooltip.AddLine(L["Click to select the script."]);
    tooltip.AddLine(L["Middle-Click to toggle the script options panel."]);
    tooltip.AddLine(L["Right-Click for options."]);
    tooltip.AddLine(L["Shift-Right-Click for the current trace log."]);
}

class OvaleDataBrokerClass extends OvaleDataBrokerBase {
    broker: any = undefined;
    OnInitialize() {    
        if (LibDataBroker) {
            let broker = {
                type: "data source",
                text: "",
                icon: CLASS_ICONS[Ovale.playerClass],
                OnClick: OnClick,
                OnTooltipShow: OnTooltipShow
            }
            this.broker = LibDataBroker.NewDataObject(Ovale.GetName(), broker);
            if (LibDBIcon) {
                LibDBIcon.Register(Ovale.GetName(), this.broker, Ovale.db.profile.apparence.minimap);
            }
        }
   
        if (this.broker) {
            this.RegisterMessage("Ovale_ProfileChanged", "UpdateIcon");
            this.RegisterMessage("Ovale_ScriptChanged");
            this.Ovale_ScriptChanged();
            this.UpdateIcon();
        }
    }

    OnDisable() {
        if (this.broker) {
            this.UnregisterMessage("Ovale_ProfileChanged");
            this.UnregisterMessage("Ovale_ScriptChanged");
        }
    }
    UpdateIcon() {
        if (LibDBIcon && this.broker) {
            const minimap = Ovale.db.profile.apparence.minimap
            LibDBIcon.Refresh(Ovale.GetName(), minimap);
            if (minimap && minimap.hide) {
                LibDBIcon.Hide(Ovale.GetName());
            } else {
                LibDBIcon.Show(Ovale.GetName());
            }
        }
    }
    Ovale_ScriptChanged() {
        let specName = OvalePaperDoll.GetSpecialization()
        this.broker.text = Ovale.db.profile.source[specName];
    }
}

OvaleDataBroker = new OvaleDataBrokerClass();