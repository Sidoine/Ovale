import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, LuaObj, pairs } from "@wowts/lua";
import { huge as infinity } from "@wowts/math";
import { AceModule } from "@wowts/tsaddon";
import { GetTime, SpellId, TalentId } from "@wowts/wow-mock";
import { DebugTools, Tracer } from "../engine/debug";
import { SpellCastEventHandler, States, StateModule } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";

interface BloodtalonsTriggerAura {
    start: number;
    ending: number;
}

class BloodtalonsData {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    brutal_slash: BloodtalonsTriggerAura = { start: 0, ending: 0 };
    // eslint-disable-next-line @typescript-eslint/naming-convention
    moonfire_cat: BloodtalonsTriggerAura = { start: 0, ending: 0 };
    rake: BloodtalonsTriggerAura = { start: 0, ending: 0 };
    shred: BloodtalonsTriggerAura = { start: 0, ending: 0 };
    // eslint-disable-next-line @typescript-eslint/naming-convention
    swipe_cat: BloodtalonsTriggerAura = { start: 0, ending: 0 };
    // eslint-disable-next-line @typescript-eslint/naming-convention
    thrash_cat: BloodtalonsTriggerAura = { start: 0, ending: 0 };
}

type BloodtalonsTrigger = keyof BloodtalonsData;

const btTriggerIdByName: LuaObj<number> = {
    brutal_slash: SpellId.brutal_slash,
    moonfire_cat: 115625,
    rake: SpellId.rake,
    shred: SpellId.shred,
    swipe_cat: 106785,
    thrash_cat: 106830,
};

const btTriggerNameById: LuaArray<BloodtalonsTrigger> = {};

for (const [name, spellId] of pairs(btTriggerIdByName)) {
    const btTrigger = name as BloodtalonsTrigger;
    btTriggerNameById[spellId] = btTrigger;
}

/* Number of seconds for the window in which abilities must be cast
 * in order to proc Bloodtalons.  The countdown starts after the GCD
 * of the cast is complete, which effectively expands the window by
 * one second.
 */
const btWindow = 4 + 1;

/* Number of combo point generators that must be cast in the window
 * in order to proc Bloodtalons.
 */
const btThreshold = 3;

// Number of charges in a Bloodtalons buff proc.
const btMaxCharges = 2;

export class Bloodtalons
    extends States<BloodtalonsData>
    implements StateModule
{
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private hasBloodtalonsHandlers = false;

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private aura: OvaleAuraClass,
        private paperDoll: OvalePaperDollClass,
        private spellBook: OvaleSpellBookClass
    ) {
        super(BloodtalonsData);
        this.module = ovale.createModule(
            "Bloodtalons",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        if (this.ovale.playerClass == "DRUID") {
            this.module.RegisterEvent(
                "PLAYER_ENTERING_WORLD",
                this.onUpdateBloodtalonsHandlers
            );
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.onUpdateBloodtalonsHandlers
            );
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.onUpdateBloodtalonsHandlers
            );
        }
    };

    private onDisable = () => {
        if (this.ovale.playerClass == "DRUID") {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_TalentsChanged");
            this.unregisterBloodtalonsHandlers();
        }
    };

    private onUpdateBloodtalonsHandlers = (event: string) => {
        const hasBloodtalonsTalent =
            this.paperDoll.isSpecialization("feral") &&
            this.spellBook.getTalentPoints(TalentId.bloodtalons_talent) > 0;
        if (hasBloodtalonsTalent) {
            this.registerBloodtalonsHandlers();
        } else {
            this.unregisterBloodtalonsHandlers();
        }
    };

    private registerBloodtalonsHandlers = () => {
        if (!this.hasBloodtalonsHandlers) {
            this.tracer.debug("Installing Bloodtalons event handlers.");
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_SUCCEEDED",
                this.onUnitSpellCastSucceeded
            );
            this.module.RegisterMessage(
                "Ovale_AuraAdded",
                this.onOvaleAuraAddedOrChanged
            );
            this.module.RegisterMessage(
                "Ovale_AuraChanged",
                this.onOvaleAuraAddedOrChanged
            );
            this.hasBloodtalonsHandlers = true;
        }
    };

    private unregisterBloodtalonsHandlers = () => {
        if (this.hasBloodtalonsHandlers) {
            this.tracer.debug("Removing Bloodtalons event handlers.");
            this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            this.module.UnregisterMessage("Ovale_AuraAdded");
            this.module.UnregisterMessage("Ovale_AuraChanged");
            this.hasBloodtalonsHandlers = false;
        }
    };

    private onUnitSpellCastSucceeded = (
        event: string,
        unit: string,
        castGUID: string,
        spellId: number
    ) => {
        if (unit === "player") {
            const name = btTriggerNameById[spellId];
            if (name) {
                const now = GetTime();
                const btTrigger = name as BloodtalonsTrigger;
                const aura = this.current[btTrigger];
                aura.start = now;
                aura.ending = now + btWindow;
                if (this.tracer.isDebugging()) {
                    const [active] = this.getActiveTrigger();
                    this.tracer.debug(
                        `active: ${active}, ${name} (${spellId})`
                    );
                }
            }
        }
    };

    private onOvaleAuraAddedOrChanged = (
        event: string,
        atTime: number,
        guid: string,
        auraId: number,
        caster: string
    ) => {
        if (
            guid === caster &&
            guid === this.ovale.playerGUID &&
            auraId === SpellId.bloodtalons_buff
        ) {
            let resetTriggers = false;
            if (event === "Ovale_AuraAdded") {
                resetTriggers = true;
            } else if (event === "Ovale_AuraChanged") {
                const aura = this.aura.getAuraByGUID(
                    guid,
                    auraId,
                    undefined,
                    true,
                    atTime
                );
                if (aura) {
                    // Bloodtalons procced again if it's at max stacks.
                    resetTriggers = aura.stacks === btMaxCharges;
                }
            }
            if (resetTriggers) {
                this.tracer.debug("active: 0, Bloodtalons proc!");
                for (const [name] of pairs(btTriggerIdByName)) {
                    const btTrigger = name as BloodtalonsTrigger;
                    const aura = this.current[btTrigger];
                    aura.start = 0;
                    aura.ending = 0;
                }
            }
        }
    };

    getActiveTrigger(atTime?: number, name?: string) {
        const state = this.getState(atTime);
        atTime = atTime || GetTime();
        if (name === undefined) {
            let numActive = 0;
            let start = 0;
            let ending = infinity;
            for (const [name] of pairs(btTriggerIdByName)) {
                const btTrigger = name as BloodtalonsTrigger;
                const aura = state[btTrigger];
                if (aura.start <= atTime && atTime < aura.ending) {
                    numActive += 1;
                    if (start < aura.start) {
                        start = aura.start;
                    }
                    if (ending > aura.ending) {
                        ending = aura.ending;
                    }
                }
            }
            if (numActive > 0) {
                return [numActive, start, ending];
            }
        } else if (btTriggerIdByName[name]) {
            const btTrigger = name as BloodtalonsTrigger;
            const aura = state[btTrigger];
            if (aura.start <= atTime && atTime < aura.ending) {
                return [1, aura.start, aura.ending];
            }
        }
        return [0, 0, infinity];
    }

    // State module

    initializeState() {}

    resetState() {
        if (this.hasBloodtalonsHandlers) {
            const current = this.current;
            const state = this.next;
            for (const [name] of pairs(btTriggerIdByName)) {
                const btTrigger = name as BloodtalonsTrigger;
                state[btTrigger].start = current[btTrigger].start;
                state[btTrigger].ending = current[btTrigger].ending;
            }
        }
    }

    cleanState() {}

    applySpellAfterCast: SpellCastEventHandler = (
        spellId,
        targetGUID,
        startCast,
        endCast,
        channel,
        spellcast
    ) => {
        if (this.hasBloodtalonsHandlers) {
            const name = btTriggerNameById[spellId];
            if (name) {
                const btTrigger = name as BloodtalonsTrigger;
                const aura = this.next[btTrigger];
                aura.start = endCast;
                aura.ending = endCast + btWindow;
                const [active] = this.getActiveTrigger(endCast);
                if (active >= btThreshold) {
                    for (const [name] of pairs(btTriggerIdByName)) {
                        const trigger = name as BloodtalonsTrigger;
                        const triggerAura = this.next[trigger];
                        triggerAura.start = 0;
                        triggerAura.ending = 0;
                    }
                }
                this.triggerBloodtalons(endCast);
            }
        }
    };

    private triggerBloodtalons = (atTime: number) => {
        this.tracer.log("Triggering Bloodtalons.");
        const aura = this.aura.addAuraToGUID(
            this.ovale.playerGUID,
            SpellId.bloodtalons_buff,
            this.ovale.playerGUID,
            "HELPFUL",
            undefined,
            atTime,
            atTime + 30, // Bloodtalons lasts 30 seconds
            atTime
        );
        aura.stacks = btMaxCharges;
    };
}
