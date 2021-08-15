import {
    CombatLogEvent,
    DamagePayload,
    HealPayload,
} from "../engine/combat-log-event";
import { Guids } from "../engine/guid";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaObj, pairs, wipe } from "@wowts/lua";
import {
    UnitHealth,
    UnitHealthMax,
    UnitGetTotalAbsorbs,
    UnitGetTotalHealAbsorbs,
} from "@wowts/wow-mock";
import { huge as infinity } from "@wowts/math";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleOptionsClass } from "../ui/Options";
import { Tracer, DebugTools } from "../engine/debug";
import { oneTimeMessage } from "../tools/tools";

const healthEvent: LuaObj<boolean> = {
    DAMAGE_SHIELD: true,
    DAMAGE_SPLIT: true,
    ENVIRONMENTAL_DAMAGE: true,
    RANGE_DAMAGE: true,
    SPELL_BUILDING_DAMAGE: true,
    SPELL_DAMAGE: true,
    SPELL_HEAL: true,
    SPELL_PERIODIC_DAMAGE: true,
    SPELL_PERIODIC_HEAL: true,
    SWING_DAMAGE: true,
};

export class OvaleHealthClass {
    health: LuaObj<number> = {};
    maxHealth: LuaObj<number> = {};
    absorb: LuaObj<number> = {};
    healAbsorb: LuaObj<number> = {};
    totalDamage: LuaObj<number> = {};
    totalHealing: LuaObj<number> = {};
    firstSeen: LuaObj<number> = {};
    lastUpdated: LuaObj<number> = {};
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovaleGuid: Guids,
        ovale: OvaleClass,
        private ovaleOptions: OvaleOptionsClass,
        ovaleDebug: DebugTools,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleHealth",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.handlePlayerRegenDisabled
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
        if (this.ovaleOptions.db.profile.apparence.frequentHealthUpdates) {
            this.module.RegisterEvent("UNIT_HEALTH", this.handleUpdateHealth);
        } else {
            this.module.RegisterEvent("UNIT_HEALTH", this.handleUpdateHealth);
        }
        this.module.RegisterEvent("UNIT_MAXHEALTH", this.handleUpdateHealth);
        this.module.RegisterEvent(
            "UNIT_ABSORB_AMOUNT_CHANGED",
            this.handleUpdateAbsorb
        );
        this.module.RegisterEvent(
            "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
            this.handleUpdateAbsorb
        );
        this.module.RegisterMessage(
            "Ovale_UnitChanged",
            this.handleUnitChanged
        );
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.module.UnregisterEvent("UNIT_HEALTH");
        this.module.UnregisterEvent("UNIT_HEALTH");
        this.module.UnregisterEvent("UNIT_MAXHEALTH");
        this.module.UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED");
        this.module.UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED");
        this.module.UnregisterMessage("Ovale_UnitChanged");
    };
    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (!healthEvent[cleuEvent]) {
            return;
        }
        const cleu = this.combatLogEvent;
        const timestamp = cleu.timestamp;
        const destGUID = cleu.destGUID;
        const destName = cleu.destName;
        let healthUpdate = false;
        if (cleu.payload.type == "DAMAGE") {
            const payload = cleu.payload as DamagePayload;
            const amount = payload.amount;
            this.tracer.debug(cleuEvent, destGUID, destName, amount);
            const total = this.totalDamage[destGUID] || 0;
            this.totalDamage[destGUID] = total + amount;
            healthUpdate = true;
        } else if (cleu.payload.type == "HEAL") {
            const payload = cleu.payload as HealPayload;
            const amount = payload.amount;
            this.tracer.debug(cleuEvent, destGUID, destName, amount);
            const total = this.totalHealing[destGUID] || 0;
            this.totalHealing[destGUID] = total + amount;
            healthUpdate = true;
        }
        if (healthUpdate) {
            if (!this.firstSeen[destGUID]) {
                this.firstSeen[destGUID] = timestamp;
            }
            this.lastUpdated[destGUID] = timestamp;
        }
    };
    private handlePlayerRegenDisabled = (event: string) => {
        this.module.RegisterMessage(
            "Ovale_CombatLogEvent",
            this.handleOvaleCombatLogEvent
        );
        for (const [event] of pairs(healthEvent)) {
            this.combatLogEvent.registerEvent(event, this);
        }
    };
    private handlePlayerRegenEnabled = (event: string) => {
        this.module.UnregisterMessage("Ovale_CombatLogEvent");
        for (const [event] of pairs(healthEvent)) {
            this.combatLogEvent.unregisterEvent(event, this);
        }
        wipe(this.totalDamage);
        wipe(this.totalHealing);
        wipe(this.firstSeen);
        wipe(this.lastUpdated);
    };
    private handleUnitChanged = (
        event: string,
        unitId: string,
        guid: string
    ) => {
        if (unitId == "target" || unitId == "focus") {
            this.tracer.debug(event, unitId, guid);
            this.handleUpdateHealth("UNIT_HEALTH", unitId);
            this.handleUpdateHealth("UNIT_MAXHEALTH", unitId);
            this.handleUpdateAbsorb("UNIT_ABSORB_AMOUNT_CHANGED", unitId);
            this.handleUpdateAbsorb("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unitId);
        }
    };
    private handleUpdateAbsorb = (event: string, unitId: string) => {
        if (!unitId) {
            return;
        }

        let func;
        let db;

        if (event == "UNIT_ABSORB_AMOUNT_CHANGED") {
            func = UnitGetTotalAbsorbs;
            db = this.absorb;
        } else if (event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") {
            func = UnitGetTotalHealAbsorbs;
            db = this.absorb;
        } else {
            oneTimeMessage(
                "Warning: Invalid event (%s) in UpdateAbsorb.",
                event
            );
            return;
        }

        const amount = func(unitId);
        if (amount >= 0) {
            const guid = this.ovaleGuid.getUnitGUID(unitId);
            this.tracer.debug(event, unitId, guid, amount);
            if (guid) {
                db[guid] = amount;
            }
        }
    };
    private handleUpdateHealth = (event: string, unitId: string) => {
        if (!unitId) {
            return;
        }

        let func;
        let db;

        if (event == "UNIT_HEALTH") {
            func = UnitHealth;
            db = this.health;
        } else if (event == "UNIT_MAXHEALTH") {
            func = UnitHealthMax;
            db = this.maxHealth;
        } else {
            oneTimeMessage(
                "Warning: Invalid event (%s) in UpdateHealth.",
                event
            );
            return;
        }

        const amount = func(unitId);
        if (amount) {
            const guid = this.ovaleGuid.getUnitGUID(unitId);
            this.tracer.debug(event, unitId, guid, amount);
            if (guid) {
                if (amount > 0) {
                    db[guid] = amount;
                } else {
                    delete db[guid];
                    delete this.firstSeen[guid];
                    delete this.lastUpdated[guid];
                }
            }
        }
    };
    getUnitHealth(unitId: string, guid?: string) {
        return this.getUnitAmount(UnitHealth, this.health, unitId, guid);
    }
    getUnitHealthMax(unitId: string, guid?: string) {
        return this.getUnitAmount(UnitHealthMax, this.maxHealth, unitId, guid);
    }
    getUnitAbsorb(unitId: string, guid?: string) {
        return this.getUnitAmount(
            UnitGetTotalAbsorbs,
            this.absorb,
            unitId,
            guid
        );
    }
    getUnitHealAbsorb(unitId: string, guid?: string) {
        return this.getUnitAmount(
            UnitGetTotalHealAbsorbs,
            this.healAbsorb,
            unitId,
            guid
        );
    }
    getUnitAmount(
        func: (_: string) => number | undefined,
        db: LuaObj<number>,
        unitId: string,
        guid?: string
    ): number {
        let amount;
        if (unitId) {
            guid = guid || this.ovaleGuid.getUnitGUID(unitId);
            if (guid) {
                if (
                    (unitId === "focus" || unitId === "target") &&
                    db[guid] !== undefined
                ) {
                    amount = db[guid];
                } else {
                    amount = func(unitId);
                    if (amount !== undefined) {
                        db[guid] = amount;
                    } else {
                        amount = 0;
                    }
                }
            } else {
                amount = 0;
            }
        } else {
            amount = 0;
        }
        return amount;
    }
    getUnitTimeToDie(unitId: string, effectiveHealth?: boolean, guid?: string) {
        let timeToDie = infinity;
        guid = guid || this.ovaleGuid.getUnitGUID(unitId);
        if (guid) {
            let health = this.getUnitHealth(unitId, guid) || 0;
            if (effectiveHealth) {
                health =
                    health +
                    this.getUnitAbsorb(unitId, guid) -
                    this.getUnitHealAbsorb(unitId, guid);
            }
            const maxHealth = this.getUnitHealthMax(unitId, guid);
            if (health && maxHealth > 0) {
                if (health == 0) {
                    timeToDie = 0;
                    delete this.firstSeen[guid];
                    delete this.lastUpdated[guid];
                } else if (maxHealth > 5) {
                    const [firstSeen, lastUpdated] = [
                        this.firstSeen[guid],
                        this.lastUpdated[guid],
                    ];
                    const damage = this.totalDamage[guid] || 0;
                    const healing = this.totalHealing[guid] || 0;
                    if (
                        firstSeen &&
                        lastUpdated &&
                        lastUpdated > firstSeen &&
                        damage > healing
                    ) {
                        timeToDie =
                            (health * (lastUpdated - firstSeen)) /
                            (damage - healing);
                    }
                }
            }
        }
        return timeToDie;
    }

    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {}
}
