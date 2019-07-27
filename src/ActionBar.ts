import { L } from "./Localization";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleSpellBookClass } from "./SpellBook";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
import { gsub, len, match, upper } from "@wowts/string";
import { concat, sort, insert } from "@wowts/table";
import { tonumber, wipe, pairs, tostring, ipairs, lualength, _G, LuaArray, LuaObj } from "@wowts/lua";
import { GetActionInfo, GetActionText, GetBindingKey, GetBonusBarIndex, GetMacroItem, GetMacroSpell } from "@wowts/wow-mock";
import ElvUI from "@wowts/libactionbutton-1.0-elvui";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";

export class OvaleActionBarClass {
    private debugOptions = {
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

    private module: AceModule & AceEvent & AceTimer;
    private debug: Tracer;
    private profiler: Profiler;

    constructor(ovaleDebug: OvaleDebugClass, ovale: OvaleClass, ovaleProfiler: OvaleProfilerClass, private ovaleSpellBook: OvaleSpellBookClass){
        this.module = ovale.createModule("OvaleActionBar", this.OnInitialize, this.OnDisable, aceEvent, aceTimer);
        this.debug = ovaleDebug.create("OvaleActionBar");
        this.profiler = ovaleProfiler.create(this.module.GetName());
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("ACTIONBAR_SLOT_CHANGED", this.ACTIONBAR_SLOT_CHANGED);
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.UpdateActionSlots);
        this.module.RegisterEvent("UPDATE_BINDINGS", this.UPDATE_BINDINGS);
        this.module.RegisterEvent("UPDATE_BONUS_ACTIONBAR", this.UpdateActionSlots);
        this.module.RegisterEvent("SPELLS_CHANGED", this.UpdateActionSlots);
        this.module.RegisterMessage("Ovale_StanceChanged", this.UpdateActionSlots);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.UpdateActionSlots);
    }

    GetKeyBinding(slot: number) {
        let name;
        if (_G["Bartender4"]) {
            name = `CLICK BT4Button${slot}:LeftButton`;
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

    private OnDisable = () => {
        this.module.UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("UPDATE_BINDINGS");
        this.module.UnregisterEvent("UPDATE_BONUS_ACTIONBAR");
        this.module.UnregisterEvent("SPELLS_CHANGED");
        this.module.UnregisterMessage("Ovale_StanceChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    }

    private ACTIONBAR_SLOT_CHANGED = (event: string, slot: number) => {
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
    
    private UPDATE_BINDINGS = (event: string) => {
        this.debug.Debug("%s: Updating key bindings.", event);
        this.UpdateKeyBindings();
    }
    private TimerUpdateActionSlots = () => {
        this.UpdateActionSlots("TimerUpdateActionSlots");
    }
    
    private UpdateActionSlots = (event: string) => {
        this.profiler.StartProfiling("OvaleActionBar_UpdateActionSlots");
        this.debug.Debug("%s: Updating all action slot mappings.", event);
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
			if (bonus > 0) {
				start = 13;
				for (let slot = bonus - 11; slot <= bonus; slot += 1) {
					this.UpdateActionSlot(slot);
				}
			}
			for (let slot = start; slot <= 72; slot += 1) {
				this.UpdateActionSlot(slot);
			}
		}
        if (event != "TimerUpdateActionSlots") {
            this.module.ScheduleTimer(this.TimerUpdateActionSlots, 1);
        }
        this.profiler.StopProfiling("OvaleActionBar_UpdateActionSlots");
    }
    private UpdateActionSlot(slot: number) {
        this.profiler.StartProfiling("OvaleActionBar_UpdateActionSlot");
        const action = this.action[slot];
        if (this.spell[<number>action] == slot) {
            delete this.spell[<number>action];
        } else if (this.item[action] == slot) {
            delete this.item[action];
        } else if (this.macro[action] == slot) {
            delete this.macro[action];
        }
        delete this.action[slot];
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
                    let spellId = GetMacroSpell(id);
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
            this.debug.Debug("Mapping button %s to %s.", slot, this.action[slot]);
        } else {
            this.debug.Debug("Clearing mapping for button %s.", slot);
        }
        this.keybind[slot] = this.GetKeyBinding(slot);
        this.profiler.StopProfiling("OvaleActionBar_UpdateActionSlot");
    }
    UpdateKeyBindings() {
        this.profiler.StartProfiling("OvaleActionBar_UpdateKeyBindings");
        for (let slot = 1; slot <= 120; slot += 1) {
            this.keybind[slot] = this.GetKeyBinding(slot);
        }
        this.profiler.StopProfiling("OvaleActionBar_UpdateKeyBindings");
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
            insert(array, `${tostring(this.GetKeyBinding(v))}: ${tostring(k)} ${tostring(this.ovaleSpellBook.GetSpellName(k))}`);
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
