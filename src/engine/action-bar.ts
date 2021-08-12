import { l } from "../ui/Localization";
import { DebugTools, Tracer } from "./debug";
import { OvaleSpellBookClass } from "../states/SpellBook";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
import { gsub, len, match, upper } from "@wowts/string";
import { concat, sort, insert } from "@wowts/table";
import {
    tonumber,
    wipe,
    pairs,
    tostring,
    ipairs,
    lualength,
    _G,
    LuaArray,
    LuaObj,
} from "@wowts/lua";
import {
    GetActionInfo,
    GetActionText,
    GetBindingKey,
    GetBonusBarIndex,
    GetMacroItem,
    GetMacroSpell,
    UIFrame,
} from "@wowts/wow-mock";
import ElvUI from "@wowts/libactionbutton-1.0-elvui";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OptionUiAll } from "../ui/acegui-helpers";

const actionBars: LuaArray<string> = {
    1: "ActionButton",
    2: "MultiBarRightButton",
    3: "MultiBarLeftButton",
    4: "MultiBarBottomRightButton",
    5: "MultiBarBottomLeftButton",
};

export class OvaleActionBarClass {
    private debugOptions: LuaObj<OptionUiAll> = {
        actionbar: {
            name: l["action_bar"],
            type: "group",
            args: {
                spellbook: {
                    name: l["action_bar"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: () => {
                        return this.debugActions();
                    },
                },
            },
        },
    };
    action: LuaArray<number | string> = {};
    keybind: LuaObj<string> = {};
    spell: LuaArray<number> = {};
    macro: LuaObj<number> = {};
    item: LuaObj<number> = {};

    private module: AceModule & AceEvent & AceTimer;
    private debug: Tracer;

    constructor(
        ovaleDebug: DebugTools,
        ovale: OvaleClass,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        this.module = ovale.createModule(
            "OvaleActionBar",
            this.handleInitialize,
            this.handleDisable,
            aceEvent,
            aceTimer
        );
        this.debug = ovaleDebug.create("OvaleActionBar");
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "ACTIONBAR_SLOT_CHANGED",
            this.handleActionBarSlotChanged
        );
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handleActionSlotUpdate
        );
        this.module.RegisterEvent("UPDATE_BINDINGS", this.handleUpdateBindings);
        this.module.RegisterEvent(
            "UPDATE_BONUS_ACTIONBAR",
            this.handleActionSlotUpdate
        );
        this.module.RegisterEvent(
            "SPELLS_CHANGED",
            this.handleActionSlotUpdate
        );
        this.module.RegisterMessage(
            "Ovale_StanceChanged",
            this.handleActionSlotUpdate
        );
        this.module.RegisterMessage(
            "Ovale_TalentsChanged",
            this.handleActionSlotUpdate
        );
    };

    private getKeyBinding(slot: number) {
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
            key = gsub(key, "BUTTON", "B");
        }
        return key;
    }

    private parseHyperlink(hyperlink: string) {
        const [color, linkType, linkData, text] = match(
            hyperlink,
            "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?"
        );
        return [color, linkType, linkData, text];
    }

    private handleDisable = () => {
        this.module.UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("UPDATE_BINDINGS");
        this.module.UnregisterEvent("UPDATE_BONUS_ACTIONBAR");
        this.module.UnregisterEvent("SPELLS_CHANGED");
        this.module.UnregisterMessage("Ovale_StanceChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };

    private handleActionBarSlotChanged = (event: string, slot: number) => {
        slot = tonumber(slot);
        if (slot == 0) {
            this.handleActionSlotUpdate(event);
        } else if (ElvUI) {
            const elvUIButtons = ElvUI.buttonRegistry;
            for (const [btn] of pairs(elvUIButtons)) {
                const s = btn.GetAttribute("action");
                if (s == slot) {
                    this.updateActionSlot(slot);
                }
            }
        } else if (slot) {
            const bonus = tonumber(GetBonusBarIndex()) * 12;
            const bonusStart = (bonus > 0 && bonus - 11) || 1;
            const isBonus = slot >= bonusStart && slot < bonusStart + 12;
            if (isBonus || (slot > 12 && slot < 73)) {
                this.updateActionSlot(slot);
            }
        }
    };

    private handleUpdateBindings = (event: string) => {
        this.debug.debug("%s: Updating key bindings.", event);
        this.updateKeyBindings();
    };
    private handleTimerUpdateActionSlots = () => {
        this.handleActionSlotUpdate("TimerUpdateActionSlots");
    };

    private handleActionSlotUpdate = (event: string) => {
        this.debug.debug("%s: Updating all action slot mappings.", event);
        wipe(this.action);
        wipe(this.item);
        wipe(this.macro);
        wipe(this.spell);
        if (ElvUI) {
            const elvUIButtons = ElvUI.buttonRegistry;
            for (const [btn] of pairs(elvUIButtons)) {
                const s = btn.GetAttribute("action");
                this.updateActionSlot(s);
            }
        } else {
            let start = 1;
            const bonus = tonumber(GetBonusBarIndex()) * 12;
            if (bonus > 0) {
                start = 13;
                for (let slot = bonus - 11; slot <= bonus; slot += 1) {
                    this.updateActionSlot(slot);
                }
            }
            for (let slot = start; slot <= 72; slot += 1) {
                this.updateActionSlot(slot);
            }
        }
        if (event != "TimerUpdateActionSlots") {
            this.module.ScheduleTimer(this.handleTimerUpdateActionSlots, 1);
        }
    };
    private updateActionSlot(slot: number) {
        const action = this.action[slot];
        if (this.spell[<number>action] == slot) {
            delete this.spell[<number>action];
        } else if (this.item[action] == slot) {
            delete this.item[action];
        } else if (this.macro[action] == slot) {
            delete this.macro[action];
        }
        delete this.action[slot];
        const [actionType, actionId] = GetActionInfo(slot);
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
                const actionText = GetActionText(slot);
                if (actionText) {
                    if (
                        !this.macro[actionText] ||
                        slot < this.macro[actionText]
                    ) {
                        this.macro[actionText] = slot;
                    }
                    const spellId = GetMacroSpell(id);
                    if (spellId) {
                        if (
                            !this.spell[spellId] ||
                            slot < this.spell[spellId]
                        ) {
                            this.spell[spellId] = slot;
                        }
                        this.action[slot] = spellId;
                    } else {
                        const [, hyperlink] = GetMacroItem(id);
                        if (hyperlink) {
                            const [, , linkData] =
                                this.parseHyperlink(hyperlink);
                            const itemIdText = gsub(linkData, ":.*", "");
                            const itemId = tonumber(itemIdText);
                            if (itemId) {
                                if (
                                    !this.item[itemId] ||
                                    slot < this.item[itemId]
                                ) {
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
            this.debug.debug(
                "Mapping button %s to %s.",
                slot,
                this.action[slot]
            );
        } else {
            this.debug.debug("Clearing mapping for button %s.", slot);
        }
        this.keybind[slot] = this.getKeyBinding(slot);
    }
    private updateKeyBindings() {
        for (let slot = 1; slot <= 120; slot += 1) {
            this.keybind[slot] = this.getKeyBinding(slot);
        }
    }
    getSpellActionSlot(spellId: number) {
        return this.spell[spellId];
    }
    getMacroActionSlot(macroName: string) {
        return this.macro[macroName];
    }
    getItemActionSlot(itemId: number) {
        return this.item[itemId];
    }
    getBindings(slot: number) {
        return this.keybind[slot];
    }
    getFrame(slot: number): UIFrame {
        let name;
        if (_G["Bartender4"]) {
            name = `BT4Button${slot}`;
        } else {
            if (slot <= 24 || slot > 72) {
                name = `ActionButton${((slot - 1) % 12) + 1}`;
            } else {
                const slotIndex = slot - 1;
                const actionBar = (slotIndex - (slotIndex % 12)) / 12;
                name = `${actionBars[actionBar]}${(slotIndex % 12) + 1}`;
            }
        }
        return _G[name];
    }

    private output: LuaArray<string> = {};

    private debugActions() {
        wipe(this.output);
        const array: LuaArray<string> = {};

        for (const [k, v] of pairs(this.spell)) {
            insert(
                array,
                `${tostring(this.getKeyBinding(v))}: ${tostring(k)} ${tostring(
                    this.ovaleSpellBook.getSpellName(k)
                )}`
            );
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
