import { L } from "./Localization";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvalePool } from "./Pool";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleDataClass, AuraByType, AuraType, SpellInfo } from "./Data";
import { OvaleGUIDClass } from "./GUID";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleStateClass, States } from "./State";
import { OvaleClass } from "./Ovale";
import { LastSpell, SpellCast, PaperDollSnapshot } from "./LastSpell";
import { RegisterRequirement, UnregisterRequirement, CheckRequirements, Tokens } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { pairs, tonumber, wipe, lualength, LuaObj, next, LuaArray, kpairs } from "@wowts/lua";
import { lower, sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetTime, UnitAura, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { huge as INFINITY, huge } from "@wowts/math";
import { OvalePaperDollClass } from "./PaperDoll";
import { BaseState } from "./BaseState";
import { isLuaArray, isString } from "./tools";
import { ConditionResult } from "./Condition";
import { OvaleOptionsClass } from "./Options";
import { AceModule } from "@wowts/tsaddon";

let strlower = lower;
let strsub = sub;
let tconcat = concat;

let self_playerGUID: string = "fake_guid";
let self_petGUID: LuaObj<number> = {};
let self_pool = new OvalePool<Aura | LuaObj<Aura> | LuaObj<LuaObj<Aura>>>("OvaleAura_pool");

type UnitAuraFilter = "HARMFUL" | "HELPFUL" | "HARMFUL|PLAYER" | "HELPFUL|PLAYER";

let UNKNOWN_GUID = "0";

export const DEBUFF_TYPE: LuaObj<boolean> = {
    curse: true,
    disease: true,
    enrage: true,
    magic: true,
    poison: true
}
export let SPELLINFO_DEBUFF_TYPE: LuaObj<string> = {};

{
    for (const [debuffType] of pairs(DEBUFF_TYPE)) {
        let siDebuffType = strlower(debuffType);
        SPELLINFO_DEBUFF_TYPE[siDebuffType] = debuffType;
    }
}
let CLEU_AURA_EVENTS: LuaObj<boolean> = {
    SPELL_AURA_APPLIED: true,
    SPELL_AURA_REMOVED: true,
    SPELL_AURA_APPLIED_DOSE: true,
    SPELL_AURA_REMOVED_DOSE: true,
    SPELL_AURA_REFRESH: true,
    SPELL_AURA_BROKEN: true,
    SPELL_AURA_BROKEN_SPELL: true
}
let CLEU_TICK_EVENTS: LuaObj<boolean> = {
    SPELL_PERIODIC_DAMAGE: true,
    SPELL_PERIODIC_HEAL: true,
    SPELL_PERIODIC_ENERGIZE: true,
    SPELL_PERIODIC_DRAIN: true,
    SPELL_PERIODIC_LEECH: true
}


let array = {}

//let CLEU_SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW);


export interface Aura {
    serial: number;
    stacks: number;
    start: number;
    ending: number;
    debuffType: number | string | undefined;
    filter: AuraType;
    state: any;
    name: string;
    gain: number;
    spellId: number;
    visible: boolean;
    lastUpdated: number;
    duration: number;
    baseTick: number | undefined;
    tick: number | undefined;
    guid: string;
    source: string;
    lastTickTime: number | undefined;
    value1: number | undefined;
    value2: number | undefined;
    value3: number | undefined;
    direction: number;
    consumed: boolean;
    icon: string | undefined;
    stealable: boolean;
    snapshotTime: number;
    cooldownEnding: number;
    combopoints?: number;
    damageMultiplier?: number;
}

type AuraDB = LuaObj<LuaObj<LuaObj<Aura>>>;
type AuraId = number | string;

export function PutAura(auraDB: AuraDB, guid: string, auraId: AuraId, casterGUID: string, aura: Aura) {
    let auraForGuid = auraDB[guid];
    if (!auraForGuid) {
        auraForGuid = <LuaObj<LuaObj<Aura>>>self_pool.Get();
        auraDB[guid] = auraForGuid;
    }
    let auraForId = auraForGuid[auraId];
    if (!auraForId) {
        auraForId = <LuaObj<Aura>>self_pool.Get();
        auraForGuid[auraId] = auraForId;
    }
    const previousAura = auraForId[casterGUID];
    if (previousAura) {
        self_pool.Release(previousAura);
    }
    auraForId[casterGUID] = aura;
    aura.guid = guid;
    aura.spellId = <number>auraId; // TODO
    aura.source = casterGUID;
}
export function GetAura(auraDB: AuraDB, guid: string, auraId: AuraId, casterGUID: string) {
    if (auraDB[guid] && auraDB[guid][auraId] && auraDB[guid][auraId][casterGUID]) {
        return auraDB[guid][auraId][casterGUID];
    }
}

function GetAuraAnyCaster(auraDB: AuraDB, guid: string, auraId: AuraId) {
    let auraFound;
    if (auraDB[guid] && auraDB[guid][auraId]) {
        for (const [, aura] of pairs(auraDB[guid][auraId])) {
            if (!auraFound || auraFound.ending < aura.ending) {
                auraFound = aura;
            }
        }
    }
    return auraFound;
}

function GetDebuffType(auraDB: AuraDB, guid: string, debuffType: AuraId, filter: string, casterGUID: string) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [, whoseTable] of pairs(auraDB[guid])) {
            let aura = whoseTable[casterGUID];
            if (aura && aura.debuffType == debuffType && aura.filter == filter) {
                if (!auraFound || auraFound.ending < aura.ending) {
                    auraFound = aura;
                }
            }
        }
    }
    return auraFound;
}

function GetDebuffTypeAnyCaster(auraDB: AuraDB, guid: string, debuffType: AuraId, filter: string) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [, whoseTable] of pairs(auraDB[guid])) {
            for (const [, aura] of pairs(whoseTable)) {
                if (aura && aura.debuffType == debuffType && aura.filter == filter) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
    }
    return auraFound;
}
function GetAuraOnGUID(auraDB: AuraDB, guid: string, auraId: AuraId, filter: string, mine: boolean) {
    let auraFound: Aura | undefined;
    if (DEBUFF_TYPE[auraId]) {
        if (mine && self_playerGUID) {
            auraFound = GetDebuffType(auraDB, guid, auraId, filter, self_playerGUID);
            if (!auraFound) {
                for (const [petGUID] of pairs(self_petGUID)) {
                    let aura = GetDebuffType(auraDB, guid, auraId, filter, petGUID);
                    if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter);
        }
    } else {
        if (mine && self_playerGUID) {
            auraFound = GetAura(auraDB, guid, auraId, self_playerGUID);
            if (!auraFound) {
                for (const [petGUID] of pairs(self_petGUID)) {
                    let aura = GetAura(auraDB, guid, auraId, petGUID);
                    if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = GetAuraAnyCaster(auraDB, guid, auraId);
        }
    }
    return auraFound;
}

export function RemoveAurasOnGUID(auraDB: AuraDB, guid: string) {
    if (auraDB[guid]) {
        let auraTable = auraDB[guid];
        for (const [auraId, whoseTable] of pairs(auraTable)) {
            for (const [casterGUID, aura] of pairs(whoseTable)) {
                self_pool.Release(aura);
                delete whoseTable[casterGUID];
            }
            self_pool.Release(whoseTable);
            delete auraTable[auraId];
        }
        self_pool.Release(auraTable);
        delete auraDB[guid];
    }
}

class AuraInterface {
    aura: AuraDB = {}
    serial: LuaObj<number> = {};
    auraSerial: number = 0;
}

let count: number;
let stacks: number;
let startChangeCount, endingChangeCount: number;
let startFirst: number, endingLast: number;

export class OvaleAuraClass extends States<AuraInterface> {
    private debug: Tracer;
    private module: AceModule & AceEvent;
    private profiler: Profiler;

    constructor(
        private ovaleState: OvaleStateClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private baseState: BaseState,
        private ovaleData: OvaleDataClass,
        private ovaleGuid: OvaleGUIDClass,
        private lastSpell: LastSpell,
        private ovaleOptions: OvaleOptionsClass,
        private ovaleDebug: OvaleDebugClass,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleSpellBook: OvaleSpellBookClass) {
        super(AuraInterface);
        this.module = ovale.createModule("OvaleAura", this.OnInitialize, this.OnDisable, aceEvent);
        this.debug = ovaleDebug.create("OvaleAura");
        this.profiler = ovaleProfiler.create("OvaleAura");
        this.ovaleState.RegisterState(this);
        this.addDebugOptions();
    }

    IsWithinAuraLag(time1: number, time2: number, factor?: number) {
        factor = factor || 1;
        const auraLag = this.ovaleOptions.db.profile.apparence.auraLag;
        let tolerance = factor * auraLag / 1000;
        return (time1 - time2 < tolerance) && (time2 - time1 < tolerance);
    }

    private CountMatchingActiveAura(aura: Aura) {
        this.debug.Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending);
        count = count + 1;
        stacks = stacks + aura.stacks;
        if (aura.ending < endingChangeCount) {
            [startChangeCount, endingChangeCount] = [aura.gain, aura.ending];
        }
        if (aura.gain < startFirst) {
            startFirst = aura.gain;
        }
        if (aura.ending > endingLast) {
            endingLast = aura.ending;
        }
    }

    private addDebugOptions() {
        
        let output: LuaArray<string> = {}
        let debugOptions = {
            playerAura: {
                name: L["Auras (player)"],
                type: "group",
                args: {
                    buff: {
                        name: L["Auras on the player"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: function (info: LuaArray<string>) {
                            wipe(output);
                            let now = GetTime()
                            let helpful = this.DebugUnitAuras("player", "HELPFUL", now);
                            if (helpful) {
                                output[lualength(output) + 1] = "== BUFFS ==";
                                output[lualength(output) + 1] = helpful;
                            }
                            let harmful = this.DebugUnitAuras("player", "HARMFUL", now);
                            if (harmful) {
                                output[lualength(output) + 1] = "== DEBUFFS ==";
                                output[lualength(output) + 1] = harmful;
                            }
                            return tconcat(output, "\n");
                        }
                    }
                }
            },
            targetAura: {
                name: L["Auras (target)"],
                type: "group",
                args: {
                    targetbuff: {
                        name: L["Auras on the target"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: function (info: LuaArray<string>) {
                            wipe(output);
                            let now = GetTime()
                            let helpful = this.DebugUnitAuras("target", "HELPFUL", now);
                            if (helpful) {
                                output[lualength(output) + 1] = "== BUFFS ==";
                                output[lualength(output) + 1] = helpful;
                            }
                            let harmful = this.DebugUnitAuras("target", "HARMFUL", now);
                            if (harmful) {
                                output[lualength(output) + 1] = "== DEBUFFS ==";
                                output[lualength(output) + 1] = harmful;
                            }
                            return tconcat(output, "\n");
                        }
                    }
                }
            }
        }
        for (const [k, v] of pairs(debugOptions)) {
            this.ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private OnInitialize = () => {
        self_playerGUID = this.ovale.playerGUID;
        self_petGUID = this.ovaleGuid.petGUID;
        this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.PLAYER_ENTERING_WORLD);
        this.module.RegisterEvent("PLAYER_REGEN_ENABLED", this.PLAYER_REGEN_ENABLED);
        this.module.RegisterEvent("UNIT_AURA", this.UNIT_AURA);
        this.module.RegisterMessage("Ovale_GroupChanged", this.handleOvaleGroupChanged);
        this.module.RegisterMessage("Ovale_UnitChanged", this.Ovale_UnitChanged);
        RegisterRequirement("buff", this.RequireBuffHandler);
        RegisterRequirement("buff_any", this.RequireBuffHandler);
        RegisterRequirement("debuff", this.RequireBuffHandler);
        RegisterRequirement("debuff_any", this.RequireBuffHandler);
        RegisterRequirement("pet_buff", this.RequireBuffHandler);
        RegisterRequirement("pet_debuff", this.RequireBuffHandler);
        RegisterRequirement("stealth", this.RequireStealthHandler);
        RegisterRequirement("stealthed", this.RequireStealthHandler);
        RegisterRequirement("target_buff", this.RequireBuffHandler);
        RegisterRequirement("target_buff_any", this.RequireBuffHandler);
        RegisterRequirement("target_debuff", this.RequireBuffHandler);
        RegisterRequirement("target_debuff_any", this.RequireBuffHandler);
    }
    
    private OnDisable = () => {
        UnregisterRequirement("buff");
        UnregisterRequirement("buff_any");
        UnregisterRequirement("debuff");
        UnregisterRequirement("debuff_any");
        UnregisterRequirement("pet_buff");
        UnregisterRequirement("pet_debuff");
        UnregisterRequirement("stealth");
        UnregisterRequirement("stealthed");
        UnregisterRequirement("target_buff");
        UnregisterRequirement("target_buff_any");
        UnregisterRequirement("target_debuff");
        UnregisterRequirement("target_debuff_any");
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_UNGHOST");
        this.module.UnregisterEvent("UNIT_AURA");
        this.module.UnregisterMessage("Ovale_GroupChanged");
        this.module.UnregisterMessage("Ovale_UnitChanged");
        for (const [guid] of pairs(this.current.aura)) {
            RemoveAurasOnGUID(this.current.aura, guid);
        }
        self_pool.Drain();
    }
    
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        this.debug.DebugTimestamp("COMBAT_LOG_EVENT_UNFILTERED", CombatLogGetCurrentEventInfo())
        let [, cleuEvent, , sourceGUID, , , , destGUID, , , , spellId, spellName, , auraType, amount] = CombatLogGetCurrentEventInfo();
        let mine = (sourceGUID == self_playerGUID || this.ovaleGuid.IsPlayerPet(sourceGUID));
        if (mine && cleuEvent == "SPELL_MISSED") {
            let [unitId] = this.ovaleGuid.GUIDUnit(destGUID);
            if (unitId) {
                this.debug.DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId);
                this.ScanAuras(unitId, destGUID);
            }
        }
        if (CLEU_AURA_EVENTS[cleuEvent]) {
            let [unitId] = this.ovaleGuid.GUIDUnit(destGUID);
            this.debug.DebugTimestamp("UnitId: ", unitId);
            if (unitId) {
                if (!this.ovaleGuid.UNIT_AURA_UNIT[unitId]) {
                    this.debug.DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId);
                    this.ScanAuras(unitId, destGUID);
                } 
            } else if (mine) {
                this.debug.DebugTimestamp("%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID);
                let now = GetTime();
                if (cleuEvent == "SPELL_AURA_REMOVED" || cleuEvent == "SPELL_AURA_BROKEN" || cleuEvent == "SPELL_AURA_BROKEN_SPELL") {
                    this.LostAuraOnGUID(destGUID, now, spellId, sourceGUID);
                } else {
                    let filter: AuraType = (auraType == "BUFF") && "HELPFUL" || "HARMFUL";
                    let si = this.ovaleData.spellInfo[spellId];
                    let aura = GetAuraOnGUID(this.current.aura, destGUID, spellId, filter, true);
                    let duration = 15;
                    if (aura) {
                        duration = aura.duration;
                    } else if (si && si.duration) {
                        [duration] = this.ovaleData.GetSpellInfoPropertyNumber(spellId, now, "duration", destGUID) || [15];
                    }
                    let expirationTime = now + duration;
                    let count;
                    if (cleuEvent == "SPELL_AURA_APPLIED") {
                        count = 1;
                    } else if (cleuEvent == "SPELL_AURA_APPLIED_DOSE" || cleuEvent == "SPELL_AURA_REMOVED_DOSE") {
                        count = amount;
                    } else if (cleuEvent == "SPELL_AURA_REFRESH") {
                        count = aura && aura.stacks || 1;
                    }
                    this.GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, undefined, count, undefined, duration, expirationTime, false, spellName);
                }
            }
        } else if (mine && CLEU_TICK_EVENTS[cleuEvent] && self_playerGUID) {
            this.debug.DebugTimestamp("%s: %s", cleuEvent, destGUID);
            let aura = GetAura(this.current.aura, destGUID, spellId, self_playerGUID);
            let now = GetTime();
            if (aura && this.IsActiveAura(aura, now)) {
                let name = aura.name || "Unknown spell";
                let [baseTick, lastTickTime] = [aura.baseTick, aura.lastTickTime];
                let tick;
                if (lastTickTime) {
                    tick = now - lastTickTime;
                } else if (!baseTick) {
                    this.debug.Debug("    First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID);
                    let si = this.ovaleData.spellInfo[spellId];
                    baseTick = (si && si.tick) && si.tick || 3;
                    tick = this.GetTickLength(spellId);
                } else {
                    tick = baseTick;
                }
                aura.baseTick = baseTick;
                aura.lastTickTime = now;
                aura.tick = tick;
                this.debug.Debug("    Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime);
                this.ovale.refreshNeeded[destGUID] = true;
            }
        }
    }
    
    private PLAYER_ENTERING_WORLD = (event: string) => {
        this.ScanAllUnitAuras();
    }

    private PLAYER_REGEN_ENABLED = (event: string) => {
        this.RemoveAurasOnInactiveUnits();
        self_pool.Drain();
    }

    private UNIT_AURA = (event: string, unitId: string) => {
        this.debug.Debug(event, unitId);
        this.ScanAuras(unitId);
    }
    
    private handleOvaleGroupChanged = () => this.ScanAllUnitAuras();

    private Ovale_UnitChanged = (event: string, unitId: string, guid: string) => {
        if ((unitId == "pet" || unitId == "target") && guid) {
            this.debug.Debug(event, unitId, guid);
            this.ScanAuras(unitId, guid);
        }
    }
    
    private ScanAllUnitAuras() {
        for (const [unitId] of pairs(this.ovaleGuid.UNIT_AURA_UNIT)) {
            this.ScanAuras(unitId);
        }
    }
    
    private RemoveAurasOnInactiveUnits() {
        for (const [guid] of pairs(this.current.aura)) {
            let unitId = this.ovaleGuid.GUIDUnit(guid);
            if (!unitId) {
                this.debug.Debug("Removing auras from GUID %s", guid);
                RemoveAurasOnGUID(this.current.aura, guid);
                delete this.current.serial[guid];
            }
        }
    }
    IsActiveAura(aura: Aura | undefined, atTime: number) : aura is Aura {
        let boolean = false;
        atTime = atTime || this.baseState.next.currentTime;
        if (aura) {
            if (aura.state) {
                if (aura.serial == this.next.auraSerial && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                    boolean = true;
                } else if (aura.consumed && this.IsWithinAuraLag(aura.ending, atTime)) {
                    boolean = true;
                }
            } else {
                if (aura.serial == this.current.serial[aura.guid] && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                    boolean = true;
                } else if (aura.consumed && this.IsWithinAuraLag(aura.ending, atTime)) {
                    boolean = true;
                }
            }
        }
        return boolean;
    }

    GainedAuraOnGUID(guid: string, atTime: number, auraId: number, casterGUID: string, filter: AuraType, visible: boolean, icon: string | undefined, count: number, debuffType: string | undefined, duration: number, expirationTime: number, isStealable: boolean, name: string, value1?: number, value2?: number, value3?: number) {
        this.profiler.StartProfiling("OvaleAura_GainedAuraOnGUID");
        casterGUID = casterGUID || UNKNOWN_GUID;
        count = (count && count > 0) && count || 1;
        duration = (duration && duration > 0) && duration || INFINITY;
        expirationTime = (expirationTime && expirationTime > 0) && expirationTime || INFINITY;
        let aura = GetAura(this.current.aura, guid, auraId, casterGUID);
        let auraIsActive;
        if (aura) {
            auraIsActive = (aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending);
        } else {
            aura = <Aura>self_pool.Get();
            PutAura(this.current.aura, guid, auraId, casterGUID, aura);
            auraIsActive = false;
        }
        let auraIsUnchanged = (aura.source == casterGUID && aura.duration == duration && aura.ending == expirationTime && aura.stacks == count && aura.value1 == value1 && aura.value2 == value2 && aura.value3 == value3);
        aura.serial = this.current.serial[guid]!;
        if (!auraIsActive || !auraIsUnchanged) {
            this.debug.Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d, duration=%f, expirationTime=%f, auraIsActive=%s, auraIsUnchanged=%s", filter, name, auraId, guid, atTime, aura.serial, duration, expirationTime, auraIsActive && "true" || "false", auraIsUnchanged && "true" || "false");
            aura.name = name;
            aura.duration = duration;
            aura.ending = expirationTime;
            if (duration < INFINITY && expirationTime < INFINITY) {
                aura.start = expirationTime - duration;
            } else {
                aura.start = atTime;
            }
            aura.gain = atTime;
            aura.lastUpdated = atTime;
            let direction = aura.direction || 1;
            if (aura.stacks) {
                if (aura.stacks < count) {
                    direction = 1;
                } else if (aura.stacks > count) {
                    direction = -1;
                }
            }
            aura.direction = direction;
            aura.stacks = count;
            aura.consumed = false;
            aura.filter = filter;
            aura.visible = visible;
            aura.icon = icon;
            aura.debuffType = isString(debuffType) && lower(debuffType) || debuffType;
            aura.stealable = isStealable;
            [aura.value1, aura.value2, aura.value3] = [value1, value2, value3];
            let mine = (casterGUID == self_playerGUID || this.ovaleGuid.IsPlayerPet(casterGUID));
            if (mine) {
                let spellcast = this.lastSpell.LastInFlightSpell();
                if (spellcast && spellcast.stop && !this.IsWithinAuraLag(spellcast.stop, atTime)) {
                    spellcast = this.lastSpell.lastSpellcast;
                    if (spellcast && spellcast.stop && !this.IsWithinAuraLag(spellcast.stop, atTime)) {
                        spellcast = undefined;
                    }
                }
                if (spellcast && spellcast.target == guid) {
                    let spellId = spellcast.spellId;
                    let spellName = this.ovaleSpellBook.GetSpellName(spellId) || "Unknown spell";
                    let keepSnapshot = false;
                    let si = this.ovaleData.spellInfo[spellId];
                    if (si && si.aura) {
                        let auraTable = this.ovaleGuid.IsPlayerPet(guid) && si.aura.pet || si.aura.target;
                        if (auraTable && auraTable[filter]) {
                            let spellData = auraTable[filter]![auraId];
                            if (spellData == "refresh_keep_snapshot") {
                                keepSnapshot = true;
                            } else if (isLuaArray(spellData) && spellData[1] == "refresh_keep_snapshot") {
                                [keepSnapshot] = CheckRequirements(spellId, atTime, spellData, 2, guid);
                            }
                        }
                    }
                    if (keepSnapshot) {
                        this.debug.Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, aura.snapshotTime, atTime, aura.serial);
                    } else {
                        this.debug.Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial);
                        this.lastSpell.CopySpellcastInfo(spellcast, aura);
                    }
                }
                let si = this.ovaleData.spellInfo[auraId];
                if (si) {
                    if (si.tick) {
                        this.debug.Debug("    %s (%s) is a periodic aura.", name, auraId);
                        if (!auraIsActive) {
                            aura.baseTick = si.tick;
                            if (spellcast && spellcast.target == guid) {
                                aura.tick = this.GetTickLength(auraId, spellcast);
                            } else {
                                aura.tick = this.GetTickLength(auraId);
                            }
                        }
                    }
                    if (si.buff_cd && guid == self_playerGUID) {
                        this.debug.Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd);
                        if (!auraIsActive) {
                            aura.cooldownEnding = aura.gain + si.buff_cd;
                        }
                    }
                }
            }
            if (!auraIsActive) {
                this.module.SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source);
            } else if (!auraIsUnchanged) {
                this.module.SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source);
            }
            this.ovale.refreshNeeded[guid] = true;
        }
        this.profiler.StopProfiling("OvaleAura_GainedAuraOnGUID");
    }
    LostAuraOnGUID(guid: string, atTime: number, auraId: AuraId, casterGUID: string) {
        this.profiler.StartProfiling("OvaleAura_LostAuraOnGUID");
        let aura = GetAura(this.current.aura, guid, auraId, casterGUID);
        if (aura) {
            let filter = aura.filter;
            this.debug.Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, guid, atTime);
            if (aura.ending > atTime) {
                aura.ending = atTime;
            }
            let mine = (casterGUID == self_playerGUID || this.ovaleGuid.IsPlayerPet(casterGUID));
            if (mine) {
                aura.baseTick = undefined;
                aura.lastTickTime = undefined;
                aura.tick = undefined;
                if (aura.start + aura.duration > aura.ending) {
                    let spellcast: SpellCast | undefined;
                    if (guid == self_playerGUID) {
                        spellcast = this.lastSpell.LastSpellSent();
                    } else {
                        spellcast = this.lastSpell.lastSpellcast;
                    }
                    if (spellcast) {
                        if ((spellcast.success && spellcast.stop && this.IsWithinAuraLag(spellcast.stop, aura.ending)) || (spellcast.queued && this.IsWithinAuraLag(spellcast.queued, aura.ending))) {
                            aura.consumed = true;
                            let spellName = this.ovaleSpellBook.GetSpellName(spellcast.spellId) || "Unknown spell";
                            this.debug.Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.queued);
                        }
                    }
                }
            }
            aura.lastUpdated = atTime;
            this.module.SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source);
            this.ovale.refreshNeeded[guid] = true;
        }
        this.profiler.StopProfiling("OvaleAura_LostAuraOnGUID");
    }
    ScanAuras(unitId: string, guid?: string) {
        this.profiler.StartProfiling("OvaleAura_ScanAuras");
        guid = guid || this.ovaleGuid.UnitGUID(unitId);
        if (guid) {
            const harmfulFilter: UnitAuraFilter = (this.ovaleOptions.db.profile.apparence.fullAuraScan) && 'HARMFUL' || 'HARMFUL|PLAYER';
            const helpfulFilter: UnitAuraFilter = (this.ovaleOptions.db.profile.apparence.fullAuraScan) && 'HELPFUL' || 'HELPFUL|PLAYER';
            this.debug.DebugTimestamp("Scanning auras on %s (%s)", guid, unitId);
            let serial = this.current.serial[guid] || 0;
            serial = serial + 1;
            this.debug.Debug("    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial);
            this.current.serial[guid] = serial;
            let i = 1;
            let filter: UnitAuraFilter = helpfulFilter;
            let now = GetTime();
            while (true) {
                let [name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, , spellId, , , , value1, value2, value3] = UnitAura(unitId, i, filter);
                if (!name) {
                    if (filter == helpfulFilter) {
                        filter = harmfulFilter;
                        i = 1;
                    } else {
                        break;
                    }
                } else {
                    const casterGUID = unitCaster && this.ovaleGuid.UnitGUID(unitCaster);
                    if (debuffType == "") {
                        debuffType = "enrage";
                    }
                    const auraType: AuraType = (filter === harmfulFilter && "HARMFUL") || "HELPFUL";
                    this.GainedAuraOnGUID(guid, now, spellId, casterGUID, auraType, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3);
                    i = i + 1;
                }
            }
            if (this.current.aura[guid]) {
                let auraTable = this.current.aura[guid];
                for (const [auraId, whoseTable] of pairs(auraTable)) {
                    for (const [casterGUID, aura] of pairs(whoseTable)) {
                        if (aura.serial == serial - 1) {
                            if (aura.visible) {
                                this.LostAuraOnGUID(guid, now, tonumber(auraId), casterGUID);
                            } else {
                                aura.serial = serial;
                                this.debug.Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial);
                            }
                        }
                    }
                }
            }
            this.debug.Debug("End scanning of auras on %s (%s).", guid, unitId);
        }
        this.profiler.StopProfiling("OvaleAura_ScanAuras");
    }

    RequireBuffHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string): [boolean, string, number] => {
        let verified = false;
        let stacks = 1;
        let buffName = <string>tokens[index];
        index = index + 1;
        let count = tonumber(tokens[index]);
        if (count) {
            stacks = count;
            index = index + 1;
        }
        if (buffName) {
            let isBang = false;
            if (strsub(buffName, 1, 1) == "!") {
                isBang = true;
                buffName = strsub(buffName, 2);
            }
            const buffId = tonumber(buffName) || buffName;
            let guid, unitId: string, filter: AuraType, mine;
            if (strsub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    const [unitIdForGuid] = this.ovaleGuid.GUIDUnit(guid);
                    unitId = unitIdForGuid;
                } else {
                    unitId = this.baseState.next.defaultTarget || "target";
                }
                filter = (strsub(requirement, 8, 11) == "buff") && "HELPFUL" || "HARMFUL";
                mine = !(strsub(requirement, -4) == "_any");
            } else if (strsub(requirement, 1, 4) == "pet_") {
                unitId = "pet";
                filter = (strsub(requirement, 5, 11) == "buff") && "HELPFUL" || "HARMFUL";
                mine = false;
            } else {
                unitId = "player";
                filter = (strsub(requirement, 1, 4) == "buff") && "HELPFUL" || "HARMFUL";
                mine = !(strsub(requirement, -4) == "_any");
            }
            guid = guid || this.ovaleGuid.UnitGUID(unitId);
            let aura = this.GetAuraByGUID(guid, buffId, filter, mine, atTime);
            let isActiveAura = this.IsActiveAura(aura, atTime) && aura.stacks >= stacks;
            if (!isBang && isActiveAura || isBang && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.debug.Log("    Require aura %s with at least %d stack(s) NOT on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            } else {
                this.debug.Log("    Require aura %s with at least %d stack(s) on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            }
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a buff argument.", requirement);
        }
        return [verified, requirement, index];
    }

    RequireStealthHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string): [boolean, string, number] => {
        let verified = false;
        let stealthed = tokens[index];
        index = index + 1;
        
        if (stealthed) {
            stealthed = tonumber(stealthed);
            let aura = this.GetAura("player", "stealthed_buff", atTime, "HELPFUL", true);
            let isActiveAura = this.IsActiveAura(aura, atTime);
            if (stealthed == 1 && isActiveAura || stealthed != 1 && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (stealthed == 1) {
                this.debug.Log("    Require stealth at time=%f: %s", atTime, result);
            } else {
                this.debug.Log("    Require NOT stealth at time=%f: %s", atTime, result);
            }
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement);
        }
        return [verified, requirement, index];
    }

    GetStateAura(guid: string, auraId: AuraId, casterGUID: string, atTime: number) {
        const state = this.GetState(atTime);
        let aura = GetAura(state.aura, guid, auraId, casterGUID);
        if (atTime && (!aura || aura.serial < this.next.auraSerial)) {
            aura = GetAura(this.current.aura, guid, auraId, casterGUID);
        }
        return aura;
    }

    DebugUnitAuras(unitId: string, filter: AuraType, atTime: number) {
        wipe(array);
        let guid = this.ovaleGuid.UnitGUID(unitId);
        if (atTime && this.next.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter && !aura.state) {
                        let name = aura.name || "Unknown spell";
                        insert(array, `${name}: ${auraId} ${(aura.debuffType || "nil")} enrage=${(aura.debuffType == "enrage" && 1 || 0)}`);
                    }
                }
            }
        }
        if (this.current.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter) {
                        let name = aura.name || "Unknown spell";
                        insert(array, `${name}: ${auraId} ${(aura.debuffType || "nil")} enrage=${(aura.debuffType == "enrage" && 1 || 0)}`);
                    }
                }
            }
        }
        if (next(array)) {
            sort(array);
            return concat(array, "\n");
        }
    }


    GetStateAuraAnyCaster(guid: string, auraId: number | string, atTime: number) {
        let auraFound;
        if (this.current.aura[guid] && this.current.aura[guid][auraId]) {
            for (const [, aura] of pairs(this.current.aura[guid][auraId])) {
                if (aura && !aura.state && this.IsActiveAura(aura, atTime)) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }

        if (atTime && this.next.aura[guid] && this.next.aura[guid][auraId]) {
            for (const [, aura] of pairs(this.next.aura[guid][auraId])) {
                if (aura.stacks > 0) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
        return auraFound;
    }

    GetStateDebuffType(guid: string, debuffType: number | string, filter: string, casterGUID: string, atTime: number) {
        let auraFound: Aura | undefined = undefined;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                let aura = whoseTable[casterGUID];
                if (aura && !aura.state && this.IsActiveAura(aura, atTime)) {
                    if (aura.debuffType == debuffType && aura.filter == filter) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
        if (atTime && this.next.aura[guid]) {
            for (const [, whoseTable] of pairs(this.next.aura[guid])) {
                let aura = whoseTable[casterGUID];
                if (aura && aura.stacks > 0) {
                    if (aura.debuffType == debuffType && aura.filter == filter) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
        return auraFound;
    }
    GetStateDebuffTypeAnyCaster(guid: string, debuffType: number | string, filter: string, atTime: number) {
        let auraFound;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (aura && !aura.state && this.IsActiveAura(aura, atTime)) {
                        if (aura.debuffType == debuffType && aura.filter == filter) {
                            if (!auraFound || auraFound.ending < aura.ending) {
                                auraFound = aura;
                            }
                        }
                    }
                }
            }
        }
        if (atTime && this.next.aura[guid]) {
            for (const [, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (aura && !aura.state && aura.stacks > 0) {
                        if (aura.debuffType == debuffType && aura.filter == filter) {
                            if (!auraFound || auraFound.ending < aura.ending) {
                                auraFound = aura;
                            }
                        }
                    }
                }
            }
        }
        return auraFound;
    }
    GetStateAuraOnGUID(guid: string, auraId: AuraId, filter: string, mine: boolean | undefined, atTime: number) {
        let auraFound: Aura | undefined = undefined;
        if (DEBUFF_TYPE[auraId]) {
            if (mine) {
                auraFound = this.GetStateDebuffType(guid, auraId, filter, self_playerGUID, atTime);
                if (!auraFound) {
                    for (const [petGUID] of pairs(self_petGUID)) {
                        let aura = this.GetStateDebuffType(guid, auraId, filter, petGUID, atTime);
                        if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                            auraFound = aura;
                        }
                    }
                }
            } else {
                auraFound = this.GetStateDebuffTypeAnyCaster(guid, auraId, filter, atTime);
            }
        } else {
            if (mine) {
                let aura = this.GetStateAura(guid, auraId, self_playerGUID, atTime);
                if (aura && aura.stacks > 0) {
                    auraFound = aura;
                } else {
                    for (const [petGUID] of pairs(self_petGUID)) {
                        aura = this.GetStateAura(guid, auraId, petGUID, atTime);
                        if (aura && aura.stacks > 0) {
                            auraFound = aura;
                            break;
                        }
                    }
                }
            } else {
                auraFound = this.GetStateAuraAnyCaster(guid, auraId, atTime);
            }
        }
        return auraFound;
    }

    GetAuraByGUID(guid: string, auraId: AuraId, filter: AuraType, mine: boolean | undefined, atTime: number) {
        let auraFound: Aura | undefined = undefined;
        if (this.ovaleData.buffSpellList[auraId]) {
            for (const [id] of pairs(this.ovaleData.buffSpellList[auraId])) {
                // TODO check this tostring(id)
                let aura = this.GetStateAuraOnGUID(guid, id, filter, mine, atTime);
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    this.debug.Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, guid, aura.start, aura.ending);
                    auraFound = aura;
                } else {
                }
            }
            if (!auraFound) {
                this.debug.Log("Aura matching '%s' is missing on %s.", auraId, guid);
            }
        } else {
            auraFound = this.GetStateAuraOnGUID(guid, auraId, filter, mine, atTime);
            if (auraFound) {
                this.debug.Log("Aura %s found on %s with (%s, %s) [stacks=%d]", auraId, guid, auraFound.start, auraFound.ending, auraFound.stacks);
            } else {
                this.debug.Log("Aura %s is missing on %s.", auraId, guid);
            }
        }
        return auraFound;
    }

    GetAura(unitId: string, auraId: AuraId, atTime: number, filter: AuraType, mine?: boolean) {
        const guid = this.ovaleGuid.UnitGUID(unitId);
        return this.GetAuraByGUID(guid, auraId, filter, mine, atTime);
    }

    GetAuraWithProperty(unitId: string, propertyName: keyof Aura, filter: AuraType, atTime: number): ConditionResult {
        let count = 0;
        let guid = this.ovaleGuid.UnitGUID(unitId);
        let start: number | undefined = huge;
        let ending: number | undefined = 0;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime) && !aura.state) {
                        if (aura[propertyName] && aura.filter == filter) {
                            count = count + 1;
                            start = (aura.gain < start) && aura.gain || start;
                            ending = (aura.ending > ending) && aura.ending || ending;
                        }
                    }
                }
            }
        }
        if (this.next.aura[guid]) {
            for (const [, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime)) {
                        if (aura[propertyName] && aura.filter == filter) {
                            count = count + 1;
                            start = (aura.gain < start) && aura.gain || start;
                            ending = (aura.ending > ending) && aura.ending || ending;
                        }
                    }
                }
            }
        }
        if (count > 0) {
            this.debug.Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending);
        } else {
            this.debug.Log("Aura with '%s' property is missing on %s.", propertyName, unitId);
            start = undefined;
            ending = undefined;
        }
        return [start, ending];
    }

    AuraCount(auraId: number, filter: AuraType, mine: boolean, minStacks: number | undefined, atTime: number, excludeUnitId: string | undefined) {
        this.profiler.StartProfiling("OvaleAura_state_AuraCount");
        minStacks = minStacks || 1;
        count = 0;
        stacks = 0;
        [startChangeCount, endingChangeCount] = [huge, huge];
        [startFirst, endingLast] = [huge, 0];
        let excludeGUID = excludeUnitId && this.ovaleGuid.UnitGUID(excludeUnitId) || undefined;
        for (const [guid, auraTable] of pairs(this.current.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine && self_playerGUID) {
                    let aura = this.GetStateAura(guid, auraId, self_playerGUID, atTime);
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                        this.CountMatchingActiveAura(aura);
                    }
                    for (const [petGUID] of pairs(self_petGUID)) {
                        aura = this.GetStateAura(guid, auraId, petGUID, atTime);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [casterGUID] of pairs(auraTable[auraId])) {
                        let aura = this.GetStateAura(guid, auraId, casterGUID, atTime);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        for (const [guid, auraTable] of pairs(this.next.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = auraTable[auraId][self_playerGUID];
                    if (aura) {
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                    for (const [petGUID] of pairs(self_petGUID)) {
                        aura = auraTable[auraId][petGUID];
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [, aura] of pairs(auraTable[auraId])) {
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            this.CountMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        this.debug.Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast);
        this.profiler.StopProfiling("OvaleAura_state_AuraCount");
        return [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast];
    }

    InitializeState() {
        this.next.aura = {}
        this.next.auraSerial = 0;
        self_playerGUID = this.ovale.playerGUID;
    }
    ResetState() {
        this.profiler.StartProfiling("OvaleAura_ResetState");
        this.next.auraSerial = this.next.auraSerial + 1;
        if (next(this.next.aura)) {
            this.debug.Log("Resetting aura state:");
        }
        for (const [guid, auraTable] of pairs(this.next.aura)) {
            for (const [auraId, whoseTable] of pairs(auraTable)) {
                for (const [casterGUID, aura] of pairs(whoseTable)) {
                    self_pool.Release(aura);
                    delete whoseTable[casterGUID];
                    this.debug.Log("    Aura %d on %s removed.", auraId, guid);
                }
                if (!next(whoseTable)) {
                    self_pool.Release(whoseTable);
                    delete auraTable[auraId];
                }
            }
            if (!next(auraTable)) {
                self_pool.Release(auraTable);
                delete this.next.aura[guid];
            }
        }
        this.profiler.StopProfiling("OvaleAura_ResetState");
    }
    CleanState() {
        for (const [guid] of pairs(this.next.aura)) {
            RemoveAurasOnGUID(this.next.aura, guid);
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleAura_ApplySpellStartCast");
        if (isChanneled) {
            let si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.ApplySpellAuras(spellId, self_playerGUID, startCast, si.aura.player, spellcast);
                }
                if (si.aura.target) {
                    this.ApplySpellAuras(spellId, targetGUID, startCast, si.aura.target, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = this.ovaleGuid.UnitGUID("pet");
                    if (petGUID) {
                        this.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAura_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleAura_ApplySpellAfterCast");
        if (!isChanneled) {
            let si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.ApplySpellAuras(spellId, self_playerGUID, endCast, si.aura.player, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = this.ovaleGuid.UnitGUID("pet");
                    if (petGUID) {
                        this.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAura_ApplySpellAfterCast");
    }
    ApplySpellOnHit(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleAura_ApplySpellAfterHit");
        if (!isChanneled) {
            let si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura && si.aura.target) {
                let travelTime = si.travel_time || 0;
                if (travelTime > 0) {
                    let estimatedTravelTime = 1;
                    if (travelTime < estimatedTravelTime) {
                        travelTime = estimatedTravelTime;
                    }
                }
                let atTime = endCast + travelTime;
                this.ApplySpellAuras(spellId, targetGUID, atTime, si.aura.target, spellcast);
            }
        }
        this.profiler.StopProfiling("OvaleAura_ApplySpellAfterHit");
    }

    private ApplySpellAuras(spellId: number, guid: string, atTime: number, auraList: AuraByType, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleAura_state_ApplySpellAuras");
        for (const [filter, filterInfo] of kpairs(auraList)) {
            for (const [auraIdKey, spellData] of pairs(filterInfo)) {
                const auraId = tonumber(auraIdKey);
                let duration = this.GetBaseDuration(auraId, spellcast);
                let stacks = 1;
                let count: number | undefined = undefined;
                let extend = 0;
                let toggle = undefined;
                let refresh = false;
                let keepSnapshot = false;
                let [verified, value, data] = this.ovaleData.CheckSpellAuraData(auraId, spellData, atTime, guid);
                if (value == "refresh") {
                    refresh = true;
                } else if (value == "refresh_keep_snapshot") {
                    refresh = true;
                    keepSnapshot = true;
                } else if (value == "toggle") {
                    toggle = true;
                } else if (value == "count") {
                    count = <number>data;
                } else if (value == "extend") {
                    extend = <number>data;
                } else if (tonumber(value)) {
                    stacks = tonumber(value);
                } else {
                    this.debug.Log("Unknown stack %s", stacks);
                }
                if (verified) {
                    let si = this.ovaleData.spellInfo[auraId];
                    let auraFound = this.GetAuraByGUID(guid, auraId, filter, true, atTime);
                    let isActiveAura = this.IsActiveAura(auraFound, atTime)
                    this.debug.Log("Aura found, checking if it is Active at %f => IsActiveAura=%s", atTime, isActiveAura && "true" || "FALSE");
                    if (isActiveAura) {
                        let aura: Aura;
                        if (auraFound.state) {
                            aura = auraFound;
                        } else {
                            aura = this.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, huge, atTime);
                            for (const [k, v] of kpairs(auraFound)) {
                                aura[k] = v;
                            }
                            aura.serial = this.next.auraSerial;
                            this.debug.Log("Aura %d is copied into simulator.", auraId);
                        }
                        if (toggle) {
                            this.debug.Log("Aura %d is toggled off by spell %d.", auraId, spellId);
                            stacks = 0;
                        }
                        if (count && count > 0) {
                            stacks = count - aura.stacks;
                        }
                        if (refresh || extend > 0 || stacks > 0) {
                            if (refresh) {
                                this.debug.Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks);
                            } else if (extend > 0) {
                                this.debug.Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks);
                            } else {
                                let maxStacks = 1;
                                if (si && si.max_stacks) {
                                    maxStacks = si.max_stacks;
                                }
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks > maxStacks) {
                                    aura.stacks = maxStacks;
                                }
                                this.debug.Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId);
                            }
                            if (extend > 0) {
                                aura.duration = aura.duration + extend;
                                aura.ending = aura.ending + extend;
                            } else {
                                aura.start = atTime;
                                if (aura.tick && aura.tick > 0) {
                                    let remainingDuration = aura.ending - atTime;
                                    let extensionDuration = 0.3 * duration;
                                    if (remainingDuration < extensionDuration) {
                                        aura.duration = remainingDuration + duration;
                                    } else {
                                        aura.duration = extensionDuration + duration;
                                    }
                                } else {
                                    aura.duration = duration;
                                }
                                aura.ending = aura.start + aura.duration;
                            }
                            aura.gain = atTime;
                            this.debug.Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending);
                            if (keepSnapshot) {
                                this.debug.Log("Aura %d keeping previous snapshot.", auraId);
                            } else if (spellcast) {
                                this.lastSpell.CopySpellcastInfo(spellcast, aura);
                            }
                        } else if (stacks == 0 || stacks < 0) {
                            if (stacks == 0) {
                                aura.stacks = 0;
                            } else {
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks < 0) {
                                    aura.stacks = 0;
                                }
                                this.debug.Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId);
                            }
                            if (aura.stacks == 0) {
                                this.debug.Log("Aura %d is completely removed.", auraId);
                                aura.ending = atTime;
                                aura.consumed = true;
                            }
                        }
                    } else {
                        if (toggle) {
                            this.debug.Log("Aura %d is toggled on by spell %d.", auraId, spellId);
                            stacks = 1;
                        }
                        if (!refresh && stacks > 0) {
                            this.debug.Log("New aura %d at %f on %s", auraId, atTime, guid);
                            let debuffType;
                            if (si) {
                                for (const [k, v] of pairs(SPELLINFO_DEBUFF_TYPE)) {
                                    if (si[k as keyof SpellInfo] == 1) {
                                        debuffType = v;
                                        break;
                                    }
                                }
                            }
                            let aura = this.AddAuraToGUID(guid, auraId, self_playerGUID, filter, debuffType, 0, huge, atTime);
                            aura.stacks = stacks;
                            aura.start = atTime;
                            aura.duration = duration;
                            if (si && si.tick) {
                                aura.baseTick = si.tick;
                                aura.tick = this.GetTickLength(auraId, spellcast);
                            }
                            aura.ending = aura.start + aura.duration;
                            aura.gain = aura.start;
                            if (spellcast) {
                                this.lastSpell.CopySpellcastInfo(spellcast, aura);
                            }
                        }
                    }
                } else {
                    this.debug.Log("Aura %d (%s) is not applied.", auraId, spellData);
                }
            }
        }
        this.profiler.StopProfiling("OvaleAura_state_ApplySpellAuras");
    }

    public AddAuraToGUID(guid: string, auraId: AuraId, casterGUID: string, filter: AuraType, debuffType: string | undefined, start: number, ending: number, atTime: number, snapshot?: PaperDollSnapshot) {
        let aura = <Aura>self_pool.Get();
        aura.state = true;
        aura.serial = this.next.auraSerial;
        aura.lastUpdated = atTime;
        aura.filter = filter;
        aura.start = start || 0;
        aura.ending = ending || huge;
        aura.duration = aura.ending - aura.start;
        aura.gain = aura.start;
        aura.stacks = 1;
        aura.debuffType = isString(debuffType) && lower(debuffType) || debuffType;
        this.ovalePaperDoll.UpdateSnapshot(aura, snapshot);
        PutAura(this.next.aura, guid, auraId, casterGUID, aura);
        return aura;
    }
    RemoveAuraOnGUID(guid: string, auraId: AuraId, filter: AuraType, mine: boolean, atTime: number) {
        let auraFound = this.GetAuraByGUID(guid, auraId, filter, mine, atTime);
        if (this.IsActiveAura(auraFound, atTime)) {
            let aura;
            if (auraFound.state) {
                aura = auraFound;
            } else {
                aura = this.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, huge, atTime);
                for (const [k, v] of kpairs(auraFound)) {
                    aura[k] = v;
                }
                aura.serial = this.next.auraSerial;
            }
            aura.stacks = 0;
            aura.ending = atTime;
            aura.lastUpdated = atTime;
        }
    }


    GetBaseDuration(auraId: number, spellcast?: SpellCast) {
        spellcast = spellcast || this.ovalePaperDoll.current;
        let combopoints = spellcast.combopoints || 0;
        let duration = INFINITY
        let si = this.ovaleData.spellInfo[auraId];
        if (si && si.duration) {
            let [value, ratio] = this.ovaleData.GetSpellInfoPropertyNumber(auraId, undefined, "duration", undefined, true) || [15, 1];
            if (si.add_duration_combopoints && combopoints) {
                duration = (value + si.add_duration_combopoints * combopoints) * ratio;
            } else {
                duration = value * ratio;
            }
        }
        // Most aura durations are no longer reduced by haste
        // but the ones that do still need their reduction
        if (si && si.haste && spellcast) {
            let hasteMultiplier = this.ovalePaperDoll.GetHasteMultiplier(si.haste, spellcast);
            duration = duration / hasteMultiplier;
        }
        return duration;
    }
    GetTickLength(auraId: number, snapshot?: PaperDollSnapshot) {
        let tick = 3;
        let si = this.ovaleData.spellInfo[auraId];
        if (si) {
            tick = si.tick || tick;
            let hasteMultiplier = this.ovalePaperDoll.GetHasteMultiplier(si.haste, snapshot);
            tick = tick / hasteMultiplier;
        }
        return tick;
    }
}

