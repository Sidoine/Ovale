import { OvaleGUIDClass } from "./GUID";
import { Tokens, OvaleRequirement } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { sub } from "@wowts/string";
import { tonumber, wipe, LuaObj } from "@wowts/lua";
import { UnitHealth, UnitHealthMax, UnitGetTotalAbsorbs, UnitGetTotalHealAbsorbs, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { BaseState } from "./BaseState";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleOptionsClass } from "./Options";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { Tracer, OvaleDebugClass } from "./Debug";


let INFINITY = huge;
let CLEU_DAMAGE_EVENT = {
    DAMAGE_SHIELD: true,
    DAMAGE_SPLIT: true,
    RANGE_DAMAGE: true,
    SPELL_BUILDING_DAMAGE: true,
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_DAMAGE: true,
    SWING_DAMAGE: true,
    ENVIRONMENTAL_DAMAGE: true
}
let CLEU_HEAL_EVENT = {
    SPELL_HEAL: true,
    SPELL_PERIODIC_HEAL: true
}

export class OvaleHealthClass {
    health: LuaObj<number> = {}
    maxHealth: LuaObj<number> = {}
    absorb: LuaObj<number> = {}
    healAbsorb: LuaObj<number> = {}
    totalDamage: LuaObj<number> = {}
    totalHealing: LuaObj<number> = {}
    firstSeen: LuaObj<number> = {}
    lastUpdated: LuaObj<number> = {}
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovaleGuid: OvaleGUIDClass,
        private baseState: BaseState,
        private ovale: OvaleClass,
        private ovaleOptions: OvaleOptionsClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private requirement: OvaleRequirement
    ) {
        
        this.module = ovale.createModule("OvaleHealth", this.OnInitialize, this.OnDisable, aceEvent);
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("PLAYER_REGEN_DISABLED", this.PLAYER_REGEN_DISABLED);
        this.module.RegisterEvent("PLAYER_REGEN_ENABLED", this.PLAYER_REGEN_ENABLED);
        if (this.ovaleOptions.db.profile.apparence.frequentHealthUpdates) {
            this.module.RegisterEvent("UNIT_HEALTH_FREQUENT", this.UpdateHealth);
        } else {
            this.module.RegisterEvent("UNIT_HEALTH", this.UpdateHealth);
        }
        this.module.RegisterEvent("UNIT_MAXHEALTH", this.UpdateHealth);
        this.module.RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", this.UpdateAbsorb);
        this.module.RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", this.UpdateAbsorb);
        this.module.RegisterMessage("Ovale_UnitChanged", this.Ovale_UnitChanged);
        this.requirement.RegisterRequirement("health_pct", this.RequireHealthPercentHandler);
        this.requirement.RegisterRequirement("pet_health_pct", this.RequireHealthPercentHandler);
        this.requirement.RegisterRequirement("target_health_pct", this.RequireHealthPercentHandler);
    }
    private OnDisable = () => {
        this.requirement.UnregisterRequirement("health_pct");
        this.requirement.UnregisterRequirement("pet_health_pct");
        this.requirement.UnregisterRequirement("target_health_pct");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.module.UnregisterEvent("UNIT_HEALTH_FREQUENT");
        this.module.UnregisterEvent("UNIT_HEALTH");
        this.module.UnregisterEvent("UNIT_MAXHEALTH");
        this.module.UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED");
        this.module.UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED");
        this.module.UnregisterMessage("Ovale_UnitChanged");
    }
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [timestamp, cleuEvent, , , , , , destGUID, , , , arg12, arg13, , arg15] = CombatLogGetCurrentEventInfo();
        this.profiler.StartProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED");
        let healthUpdate = false;
        if (CLEU_DAMAGE_EVENT[<keyof typeof CLEU_DAMAGE_EVENT> cleuEvent]) {
            let amount;
            if (cleuEvent == "SWING_DAMAGE") {
                amount = arg12;
            } else if (cleuEvent == "ENVIRONMENTAL_DAMAGE") {
                amount = arg13;
            } else {
                amount = arg15;
            }
            this.tracer.Debug(cleuEvent, destGUID, amount);
            let total = this.totalDamage[destGUID] || 0;
            this.totalDamage[destGUID] = total + amount;
            healthUpdate = true;
        } else if (CLEU_HEAL_EVENT[<keyof typeof CLEU_HEAL_EVENT>cleuEvent]) {
            let amount = arg15;
            this.tracer.Debug(cleuEvent, destGUID, amount);
            let total = this.totalHealing[destGUID] || 0;
            this.totalHealing[destGUID] = total + amount;
            healthUpdate = true;
        }
        if (healthUpdate) {
            if (!this.firstSeen[destGUID]) {
                this.firstSeen[destGUID] = timestamp;
            }
            this.lastUpdated[destGUID] = timestamp;
        }
        this.profiler.StopProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED");
    }
    private PLAYER_REGEN_DISABLED = (event: string) => {
        this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
    }
    private PLAYER_REGEN_ENABLED = (event: string) => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        wipe(this.totalDamage);
        wipe(this.totalHealing);
        wipe(this.firstSeen);
        wipe(this.lastUpdated);
    }
    private Ovale_UnitChanged = (event: string, unitId: string, guid: string) => {
        this.profiler.StartProfiling("Ovale_UnitChanged");
        if (unitId == "target" || unitId == "focus") {
            this.tracer.Debug(event, unitId, guid);
            this.UpdateHealth("UNIT_HEALTH_FREQUENT", unitId);
            this.UpdateHealth("UNIT_MAXHEALTH", unitId);
            this.UpdateAbsorb("UNIT_ABSORB_AMOUNT_CHANGED", unitId);
            this.UpdateAbsorb("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unitId);
        }
        this.profiler.StopProfiling("Ovale_UnitChanged");
    }
    private UpdateAbsorb = (event: string, unitId: string) => {
        if (!unitId) {
            return;
        }
        this.profiler.StartProfiling("OvaleHealth_UpdateAbsorb");
        
        let func;
        let db;
        
        if (event == "UNIT_ABSORB_AMOUNT_CHANGED") {
            func = UnitGetTotalAbsorbs;
            db = this.absorb;
        } else if (event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") {
            func = UnitGetTotalHealAbsorbs;
            db = this.absorb;
        } else {
            this.ovale.OneTimeMessage("Warning: Invalid event (%s) in UpdateAbsorb.", event);
            return;
        }
        
        let amount = func(unitId);
        if(amount >= 0) {
            let guid = this.ovaleGuid.UnitGUID(unitId);
            this.tracer.Debug(event, unitId, guid, amount);
            if (guid) {
                db[guid] = amount;
            }
        }
        
        this.profiler.StopProfiling("OvaleHealth_UpdateHealth");
    }
    private UpdateHealth = (event: string, unitId: string) => {
        if (!unitId) {
            return;
        }
        this.profiler.StartProfiling("OvaleHealth_UpdateHealth");
        
        let func;
        let db;
        
        if (event == "UNIT_HEALTH_FREQUENT" || event == "UNIT_HEALTH") {
            func = UnitHealth;
            db = this.health;
        } else if (event == "UNIT_MAXHEALTH") {
            func = UnitHealthMax;
            db = this.maxHealth;
        } else {
            this.ovale.OneTimeMessage("Warning: Invalid event (%s) in UpdateHealth.", event);
            return;
        }
        
        let amount = func(unitId);
        if (amount) {
            let guid = this.ovaleGuid.UnitGUID(unitId);
            this.tracer.Debug(event, unitId, guid, amount);
            if (guid) {
                if (amount > 0) {
                    db[guid] = amount;
                } else {
                    db[guid] = undefined;
                    this.firstSeen[guid] = undefined;
                    this.lastUpdated[guid] = undefined;
                }
            }
        }
        this.profiler.StopProfiling("OvaleHealth_UpdateHealth");
    }
    UnitHealth(unitId: string, guid?: string) {
        return this.UnitAmount(UnitHealth, this.health, unitId, guid);
    }
    UnitHealthMax(unitId: string, guid?:string) {
        return this.UnitAmount(UnitHealthMax, this.maxHealth, unitId, guid);
    }
    UnitAbsorb(unitId: string, guid?: string) {
        return this.UnitAmount(UnitGetTotalAbsorbs, this.absorb, unitId, guid);
    }
    UnitHealAbsorb(unitId: string, guid?: string) {
        return this.UnitAmount(UnitGetTotalHealAbsorbs, this.healAbsorb, unitId, guid);
    }
    UnitAmount(func: (_: string) => number, db: LuaObj<number>, unitId: string, guid?: string): number {
        let amount;
        if (unitId) {
            guid = guid || this.ovaleGuid.UnitGUID(unitId);
            if (guid) {
                if (unitId == "target" || unitId == "focus") {
                    amount = db[guid] || 0;
                } else {
                    amount = func(unitId);
                    db[guid] = amount;
                }
            } else {
                amount = 0;
            }
        }
        return amount;
    }
    UnitTimeToDie(unitId: string, effectiveHealth?: boolean, guid?: string) {
        this.profiler.StartProfiling("OvaleHealth_UnitTimeToDie");
        let timeToDie = INFINITY;
        guid = guid || this.ovaleGuid.UnitGUID(unitId);
        if (guid) {
            let health = this.UnitHealth(unitId, guid);
            if (effectiveHealth) {
                health = health + this.UnitAbsorb(unitId, guid) - this.UnitHealAbsorb(unitId, guid);
            }
            let maxHealth = this.UnitHealthMax(unitId, guid);
            if (health && maxHealth) {
                if (health == 0) {
                    timeToDie = 0;
                    this.firstSeen[guid] = undefined;
                    this.lastUpdated[guid] = undefined;
                } else if (maxHealth > 5) {
                    let [firstSeen, lastUpdated] = [this.firstSeen[guid], this.lastUpdated[guid]];
                    let damage = this.totalDamage[guid] || 0;
                    let healing = this.totalHealing[guid] || 0;
                    if (firstSeen && lastUpdated && lastUpdated > firstSeen && damage > healing) {
                        timeToDie = health * (lastUpdated - firstSeen) / (damage - healing);
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleHealth_UnitTimeToDie");
        return timeToDie;
    }
    RequireHealthPercentHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string): [boolean, string, number] => {
        let verified = false;
        let threshold = <string>tokens[index];
        index = index + 1;
        if (threshold) {
            let isBang = false;
            if (sub(threshold, 1, 1) == "!") {
                isBang = true;
                threshold = sub(threshold, 2);
            }
            const thresholdValue = tonumber(threshold) || 0;
            let guid, unitId: string;
            if (sub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    [unitId] = this.ovaleGuid.GUIDUnit(guid);
                } else {
                    unitId = this.baseState.next.defaultTarget || "target";
                }
            } else if (sub(requirement, 1, 4) == "pet_") {
                unitId = "pet";
            } else {
                unitId = "player";
            }
            guid = guid || this.ovaleGuid.UnitGUID(unitId);
            let health = this.UnitHealth(unitId, guid) || 0;
            let maxHealth = this.UnitHealthMax(unitId, guid) || 1;
            let healthPercent = (health / maxHealth * 100) || 100;
            if (!isBang && healthPercent <= thresholdValue || isBang && healthPercent > thresholdValue) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.tracer.Log("    Require %s health > %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result);
            } else {
                this.tracer.Log("    Require %s health <= %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result);
            }
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a threshold argument.", requirement);
        }
        return [verified, requirement, index];
    }
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
}

