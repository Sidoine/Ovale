import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleSpellBook } from "./SpellBook";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import aceTimer from "@wowts/ace_timer-3.0";
import { gsub, len, match, upper } from "@wowts/string";
import { concat, sort, insert } from "@wowts/table";
import { tonumber, wipe, pairs, tostring, ipairs, lualength, _G, LuaArray, LuaObj } from "@wowts/lua";
import { GetActionInfo, GetActionText, GetBindingKey, GetBonusBarIndex, GetMacroItem, GetMacroSpell } from "@wowts/wow-mock";
import ElvUI from "@wowts/libactionbutton-1.0-elvui";

const OvaleActionBarBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleActionBar", aceEvent, aceTimer)));
class OvaleActionBarClass extends OvaleActionBarBase {
    debugOptions = {
        actionbar: {
            name: L["Action bar"],
            type: "group",
            args: {
                spellbook: {
                    name: L["Action bar"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info: string) => {
                        return this.DebugActions();
                    }
                }
            }
        }
    }
    action: LuaArray<number | string> = {}
    keybind: LuaObj<string> = {}
    spell: LuaArray<number> = {}
    macro: LuaObj<number> = {}
    item: LuaObj<number> = {}

    constructor(){
        super();
        for (const [k, v] of pairs(this.debugOptions)) {
            OvaleDebug.options.args[k] = v;
        }
    }

    OnInitialize() {
        this.RegisterEvent("ACTIONBAR_SLOT_CHANGED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", event => this.UpdateActionSlots(event));
        this.RegisterEvent("UPDATE_BINDINGS");
        this.RegisterEvent("UPDATE_BONUS_ACTIONBAR", event => this.UpdateActionSlots(event));
        this.RegisterEvent("SPELLS_CHANGED", event => this.UpdateActionSlots(event));
        this.RegisterMessage("Ovale_StanceChanged", event => this.UpdateActionSlots(event));
        this.RegisterMessage("Ovale_TalentsChanged", event => this.UpdateActionSlots(event));
    }

    GetKeyBinding(slot: number) {
        let name;
        if (_G["Bartender4"] && slot > 12) {
            name = `CLICK BT4Button ${slot}:LeftButton`;
        } else {
            if (slot <= 24 || slot > 72) {
                name = `ACTIONBUTTON${((slot - 1) % 12) + 1}`;
            } else if (slot <= 36) {
                name = `MULTIACTIONBAR3BUTTON${slot - 24}`;
            } else if (slot <= 48) {
                name = `MULTIACTIONBAR4BUTTON${slot - 36}`;
            } else if (slot <= 60) {
                name = `MULTIACTIONBAR2BUTTON${slot - 48}`;
            } else {
                name = `MULTIACTIONBAR1BUTTON${slot - 60}`;
            }
        }
        let key = name && GetBindingKey(name);
        if (key && len(key) > 4) {
            key = upper(key);
            key = gsub(key, "%s+", "");
            key = gsub(key, "ALT%-", "A");
            key = gsub(key, "CTRL%-", "C");
            key = gsub(key, "SHIFT%-", "S");
            key = gsub(key, "NUMPAD", "N");
            key = gsub(key, "PLUS", "+");
            key = gsub(key, "MINUS", "-");
            key = gsub(key, "MULTIPLY", "*");
            key = gsub(key, "DIVIDE", "/");
            key = gsub(key, "BUTTON", "B")
        }
        return key;
    }

    ParseHyperlink(hyperlink: string) {
        let [color, linkType, linkData, text] = match(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
        return [color, linkType, linkData, text];
    }

    OnDisable() {
        this.UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("UPDATE_BINDINGS");
        this.UnregisterEvent("UPDATE_BONUS_ACTIONBAR");
        this.UnregisterEvent("SPELLS_CHANGED");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }

    ACTIONBAR_SLOT_CHANGED(event: string, slot: number) {
        slot = tonumber(slot);
        if (slot == 0) {
            this.UpdateActionSlots(event);
		} else if (ElvUI) {
			let elvUIButtons = ElvUI.buttonRegistry;
			for (const [btn] of pairs(elvUIButtons)) {
				let s = btn.GetAttribute("action");
				if (s == slot) {
					this.UpdateActionSlot(slot);
				}
			}
        } else if (slot) {
            let bonus = tonumber(GetBonusBarIndex()) * 12;
            let bonusStart = (bonus > 0) && (bonus - 11) || 1;
            let isBonus = slot >= bonusStart && slot < bonusStart + 12;
            if (isBonus || slot > 12 && slot < 73) {
                this.UpdateActionSlot(slot);
            }
        }
    }
    UPDATE_BINDINGS(event: string) {
        this.Debug("%s: Updating key bindings.", event);
        this.UpdateKeyBindings();
    }
    TimerUpdateActionSlots() {
        this.UpdateActionSlots("TimerUpdateActionSlots");
    }
    UpdateActionSlots(event: string) {
        this.StartProfiling("OvaleActionBar_UpdateActionSlots");
        this.Debug("%s: Updating all action slot mappings.", event);
        wipe(this.action);
        wipe(this.item);
        wipe(this.macro);
        wipe(this.spell);
        if (ElvUI) {
			let elvUIButtons = ElvUI.buttonRegistry;
			for (const [btn] of pairs(elvUIButtons)) {
				let s = btn.GetAttribute("action");
				this.UpdateActionSlot(s);
			}
		} else {
			let start = 1;
			let bonus = tonumber(GetBonusBarIndex()) * 12;
			if (bonus > 0 && !_G["Bartender4"]) {
				start = 13;
				for (let slot = bonus - 11; slot <= bonus; slot += 1) {
					this.UpdateActionSlot(slot);
				}
			}
			for (let slot = start; slot <= 72; slot += 1) {
				this.UpdateActionSlot(slot);
			}
			if (event != "TimerUpdateActionSlots") {
				this.ScheduleTimer("TimerUpdateActionSlots", 1);
			}
		}
        this.StopProfiling("OvaleActionBar_UpdateActionSlots");
    }
    UpdateActionSlot(slot: number) {
        this.StartProfiling("OvaleActionBar_UpdateActionSlot");
        let action = this.action[slot];
        if (this.spell[action] == slot) {
            this.spell[action] = undefined;
        } else if (this.item[action] == slot) {
            this.item[action] = undefined;
        } else if (this.macro[action] == slot) {
            this.macro[action] = undefined;
        }
        this.action[slot] = undefined;
        let [actionType, actionId] = GetActionInfo(slot);
        if (actionType == "spell") {
            const id = tonumber(actionId);
            if (id) {
                if (!this.spell[id] || slot < this.spell[id]) {
                    this.spell[id] = slot;
                }
                this.action[slot] = id;
            }
        } else if (actionType == "item") {
            const id = tonumber(actionId);
            if (id) {
                if (!this.item[id] || slot < this.item[id]) {
                    this.item[id] = slot;
                }
                this.action[slot] = id;
            }
        } else if (actionType == "macro") {
            const id = tonumber(actionId);
            if (id) {
                let actionText = GetActionText(slot);
                if (actionText) {
                    if (!this.macro[actionText] || slot < this.macro[actionText]) {
                        this.macro[actionText] = slot;
                    }
                    let [, , spellId] = GetMacroSpell(id);
                    if (spellId) {
                        if (!this.spell[spellId] || slot < this.spell[spellId]) {
                            this.spell[spellId] = slot;
                        }
                        this.action[slot] = spellId;
                    } else {
                        let [, hyperlink] = GetMacroItem(id);
                        if (hyperlink) {
                            let [, , linkData] = this.ParseHyperlink(hyperlink);
                            let itemIdText = gsub(linkData, ":.*", "");
                            const itemId = tonumber(itemIdText);
                            if (itemId) {
                                if (!this.item[itemId] || slot < this.item[itemId]) {
                                    this.item[itemId] = slot;
                                }
                                this.action[slot] = itemId;
                            }
                        }
                    }
                    if (!this.action[slot]) {
                        this.action[slot] = actionText;
                    }
                }
            }
        }
        if (this.action[slot]) {
            this.Debug("Mapping button %s to %s.", slot, this.action[slot]);
        } else {
            this.Debug("Clearing mapping for button %s.", slot);
        }
        this.keybind[slot] = this.GetKeyBinding(slot);
        this.StopProfiling("OvaleActionBar_UpdateActionSlot");
    }
    UpdateKeyBindings() {
        this.StartProfiling("OvaleActionBar_UpdateKeyBindings");
        for (let slot = 1; slot <= 120; slot += 1) {
            this.keybind[slot] = this.GetKeyBinding(slot);
        }
        this.StopProfiling("OvaleActionBar_UpdateKeyBindings");
    }
    GetForSpell(spellId: number) {
        return this.spell[spellId];
    }
    GetForMacro(macroName: string) {
        return this.macro[macroName];
    }
    GetForItem(itemId: number) {
        return this.item[itemId];
    }
    GetBinding(slot: number) {
        return this.keybind[slot];
    }

    output: LuaArray<string> = {}
    OutputTableValues(output: string, tbl: any) {}

    DebugActions() {
        wipe(this.output);
        let array: LuaArray<string> = {}
        
        for (const [k, v] of pairs(this.spell)) {
            insert(array, `${tostring(this.GetKeyBinding(v))}: ${tostring(k)} ${tostring(OvaleSpellBook.GetSpellName(k))}`);
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        let total = 0;
        for (const [] of pairs(this.spell)) {
            total = total + 1;
        }
        this.output[lualength(this.output) + 1] = `Total spells: ${total}`;
        return concat(this.output, "\n");
    }
}

export const OvaleActionBar = new OvaleActionBarClass();