import { l } from "./Localization";
import LibDataBroker from "@wowts/lib_data_broker-1.1";
import LibDBIcon from "@wowts/lib_d_b_icon-1.0";
import { OvaleOptionsClass } from "./Options";
import { defaultScriptName, OvaleScriptsClass } from "../engine/scripts";
import { OvaleFrameModuleClass } from "./Frame";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, LuaArray, LuaObj, kpairs, version } from "@wowts/lua";
import { insert } from "@wowts/table";
import {
    CreateFrame,
    EasyMenu,
    IsShiftKeyDown,
    UIParent,
    UIGameTooltip,
    UIFrame,
} from "@wowts/wow-mock";
import { OvalePaperDollClass } from "../states/PaperDoll";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { DebugTools } from "../engine/debug";
import { OptionUiAll } from "./acegui-helpers";

const classIcons = {
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
    ["WARRIOR"]: "Interface\\Icons\\ClassIcon_Warrior",
};
const defaultDB = {
    minimap: { hide: false },
};

interface MenuItem {
    text: string;
    isTitle?: boolean;
    func?: () => void;
}

export class OvaleDataBrokerClass {
    private broker: { text: string } = { text: "" };
    private module: AceEvent & AceModule;

    private menuFrame?: UIFrame;
    private tooltipTitle?: string;

    constructor(
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleFrameModule: OvaleFrameModuleClass,
        private ovaleOptions: OvaleOptionsClass,
        private ovale: OvaleClass,
        private ovaleDebug: DebugTools,
        private ovaleScripts: OvaleScriptsClass
    ) {
        this.module = ovale.createModule(
            "OvaleDataBroker",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        const options: LuaObj<OptionUiAll> = {
            minimap: {
                order: 25,
                type: "toggle",
                name: l["show_minimap_icon"],
                get: () => {
                    return !this.ovaleOptions.db.profile.apparence.minimap.hide;
                },
                set: (info: unknown, value: boolean) => {
                    this.ovaleOptions.db.profile.apparence.minimap.hide =
                        !value;
                    this.updateIcon();
                },
            },
        };
        for (const [k, v] of kpairs(defaultDB)) {
            this.ovaleOptions.defaultDB.profile.apparence[k] = v;
        }
        for (const [k, v] of pairs(options)) {
            this.ovaleOptions.apparence.args[k] = v;
        }
        this.ovaleOptions.registerOptions();
    }

    private handleTooltipShow = (tooltip: UIGameTooltip) => {
        this.tooltipTitle =
            this.tooltipTitle || `${this.ovale.GetName()} ${version}`;
        tooltip.SetText(this.tooltipTitle, 1, 1, 1);
        tooltip.AddLine(l["script_tooltip"]);
        tooltip.AddLine(l["middle_click_help"]);
        tooltip.AddLine(l["right_click_help"]);
        tooltip.AddLine(l["shift_right_click_help"]);
    };

    private handleClick = (fr: UIFrame, button: "LeftButton") => {
        if (button == "LeftButton") {
            const menu: LuaArray<MenuItem> = {
                1: {
                    text: l["script"],
                    isTitle: true,
                },
            };
            const scriptType =
                (!this.ovaleOptions.db.profile.showHiddenScripts && "script") ||
                undefined;
            const descriptions = this.ovaleScripts.getDescriptions(scriptType);
            for (const [name, description] of pairs(descriptions)) {
                const menuItem = {
                    text: description,
                    func: () => {
                        this.ovaleScripts.setScript(name);
                    },
                };
                insert(menu, menuItem);
            }
            this.menuFrame =
                this.menuFrame ||
                CreateFrame(
                    "Frame",
                    "OvaleDataBroker_MenuFrame",
                    UIParent,
                    "UIDropDownMenuTemplate"
                );
            EasyMenu(menu, this.menuFrame, "cursor", 0, 0, "MENU");
        } else if (button == "MiddleButton") {
            this.ovaleFrameModule.frame.toggleOptions();
        } else if (button == "RightButton") {
            if (IsShiftKeyDown()) {
                this.ovaleDebug.doTrace(true);
            } else {
                this.ovaleOptions.toggleConfig();
            }
        }
    };

    private handleInitialize = () => {
        if (LibDataBroker) {
            const broker = {
                type: "data source",
                text: "",
                icon: classIcons[this.ovale.playerClass],
                // eslint-disable-next-line @typescript-eslint/naming-convention
                OnClick: this.handleClick,
                // eslint-disable-next-line @typescript-eslint/naming-convention
                OnTooltipShow: this.handleTooltipShow,
            };
            this.broker = LibDataBroker.NewDataObject(
                this.ovale.GetName(),
                broker
            ) as { text: string };
            if (LibDBIcon) {
                LibDBIcon.Register(
                    this.ovale.GetName(),
                    this.broker,
                    this.ovaleOptions.db.profile.apparence.minimap
                );
            }
        }

        if (this.broker) {
            this.module.RegisterMessage(
                "Ovale_ProfileChanged",
                this.updateIcon
            );
            this.module.RegisterMessage(
                "Ovale_ScriptChanged",
                this.handleScriptChanged
            );
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.handleScriptChanged
            );
            this.module.RegisterEvent(
                "PLAYER_ENTERING_WORLD",
                this.handleScriptChanged
            );
            this.handleScriptChanged();
            this.updateIcon();
        }
    };

    private handleDisable = () => {
        if (this.broker) {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_ProfileChanged");
            this.module.UnregisterMessage("Ovale_ScriptChanged");
        }
    };
    private updateIcon = () => {
        if (LibDBIcon && this.broker) {
            const minimap = this.ovaleOptions.db.profile.apparence.minimap;
            LibDBIcon.Refresh(this.ovale.GetName(), minimap);
            if (minimap && minimap.hide) {
                LibDBIcon.Hide(this.ovale.GetName());
            } else {
                LibDBIcon.Show(this.ovale.GetName());
            }
        }
    };
    private handleScriptChanged = () => {
        const script =
            this.ovaleOptions.db.profile.source[
                `${
                    this.ovale.playerClass
                }_${this.ovalePaperDoll.getSpecialization()}`
            ];
        this.broker.text =
            (script == defaultScriptName &&
                this.ovaleScripts.getDefaultScriptName(
                    this.ovale.playerClass,
                    this.ovalePaperDoll.getSpecialization()
                )) ||
            script ||
            "Disabled";
    };
}
