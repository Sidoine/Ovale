import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvalePool } from "./Pool";
import { OvaleProfiler } from "./Profiler";
import { OvaleData } from "./Data";
import { OvaleGUID } from "./GUID";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
import { lastSpell, SpellCast, PaperDollSnapshot } from "./LastSpell";
import { RegisterRequirement, UnregisterRequirement, CheckRequirements, Tokens } from "./Requirement";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, tonumber, wipe, lualength, LuaObj, next, LuaArray } from "@wowts/lua";
import { lower, sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetTime, UnitAura } from "@wowts/wow-mock";
import { huge as INFINITY, huge } from "@wowts/math";
import { OvalePaperDoll } from "./PaperDoll";
import { baseState } from "./BaseState";
import { isLuaArray } from "./tools";

export let OvaleAura: OvaleAuraClass;
let strlower = lower;
let strsub = sub;
let tconcat = concat;

let self_playerGUID: string | undefined = undefined;
let self_petGUID: LuaObj<number> = undefined;
let self_pool = new OvalePool<Aura | LuaObj<Aura> | LuaObj<LuaObj<Aura>>>("OvaleAura_pool");
let UNKNOWN_GUID = "0";
{
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
                        let helpful = OvaleAura.DebugUnitAuras("player", "HELPFUL", undefined);
                        if (helpful) {
                            output[lualength(output) + 1] = "== BUFFS ==";
                            output[lualength(output) + 1] = helpful;
                        }
                        let harmful = OvaleAura.DebugUnitAuras("player", "HARMFUL", undefined);
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
                        let helpful = OvaleAura.DebugUnitAuras("target", "HELPFUL", undefined);
                        if (helpful) {
                            output[lualength(output) + 1] = "== BUFFS ==";
                            output[lualength(output) + 1] = helpful;
                        }
                        let harmful = OvaleAura.DebugUnitAuras("target", "HARMFUL", undefined);
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
        OvaleDebug.options.args[k] = v;
    }
}
export const DEBUFF_TYPE: LuaObj<boolean> = {
    Curse: true,
    Disease: true,
    Enrage: true,
    Magic: true,
    Poison: true
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
    debuffType: number | string;
    filter: string;
    state: any;
    name: string;
    gain: number;
    spellId: number;
    visible: boolean;
    lastUpdated: number;
    duration: number;
    enrage: boolean;
    baseTick: number;
    tick: number;
    guid: string;
    source: string;
    lastTickTime: number;
    value1: number;
    value2: number;
    value3: number;
    direction: number;
    consumed: boolean;
    icon: string;
    stealable: boolean;
    snapshotTime: number;
    cooldownEnding: number;
    combopoints?: number;
    damageMultiplier?: number;
}

type AuraDB = LuaObj<LuaObj<LuaObj<Aura>>>;
type AuraId = number | string;

export function PutAura(auraDB: AuraDB, guid: string, auraId: AuraId, casterGUID: string, aura: Aura) {
    if (!auraDB[guid]) {
        auraDB[guid] = <LuaObj<LuaObj<Aura>>>self_pool.Get();
    }
    if (!auraDB[guid][auraId]) {
        auraDB[guid][auraId] = <LuaObj<Aura>>self_pool.Get();
    }
    if (auraDB[guid][auraId][casterGUID]) {
        self_pool.Release(auraDB[guid][auraId][casterGUID]);
    }
    auraDB[guid][auraId][casterGUID] = aura;
    aura.guid = guid;
    aura.spellId = <number>auraId; // TODO
    aura.source = casterGUID;
}
export function GetAura(auraDB: AuraDB, guid: string, auraId: AuraId, casterGUID: string) {
    if (auraDB[guid] && auraDB[guid][auraId] && auraDB[guid][auraId][casterGUID]) {
        if (auraId == 215570) {
            let spellcast = lastSpell.LastInFlightSpell();
            if (spellcast && spellcast.spellId && spellcast.spellId == 190411 && spellcast.start) {
                let aura = auraDB[guid][auraId][casterGUID];
                if (aura.start && aura.start < spellcast.start) {
                    aura.ending = spellcast.start;
                }
            }
        }
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
    let auraFound: Aura;
    if (DEBUFF_TYPE[auraId]) {
        if (mine) {
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
        if (mine) {
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
                whoseTable[casterGUID] = undefined;
            }
            self_pool.Release(whoseTable);
            auraTable[auraId] = undefined;
        }
        self_pool.Release(auraTable);
        auraDB[guid] = undefined;
    }
}
export function IsWithinAuraLag(time1: number, time2: number, factor?: number) {
    factor = factor || 1;
    const auraLag = Ovale.db.profile.apparence.auraLag;
    let tolerance = factor * auraLag / 1000;
    return (time1 - time2 < tolerance) && (time2 - time1 < tolerance);
}

class AuraInterface {
    aura: AuraDB = {}
    serial: LuaObj<number> = {};
    auraSerial: number;
    bypassState: LuaObj<LuaObj<boolean>> = {}
}

let count: number;
let stacks: number;
let startChangeCount, endingChangeCount: number;
let startFirst: number, endingLast: number;


function CountMatchingActiveAura(aura: Aura) {
    OvaleState.Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending);
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

let OvaleAuraBase = OvaleState.RegisterHasState(OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleAura", aceEvent))), AuraInterface);

export class OvaleAuraClass extends OvaleAuraBase {
    constructor() {
        super();
        OvaleState.RegisterState(this);
    }

    OnInitialize() {
        self_playerGUID = Ovale.playerGUID;
        self_petGUID = OvaleGUID.petGUID;
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("UNIT_AURA");
        this.RegisterMessage("Ovale_GroupChanged", "ScanAllUnitAuras");
        this.RegisterMessage("Ovale_UnitChanged");
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
    OnDisable() {
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
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("PLAYER_UNGHOST");
        this.UnregisterEvent("UNIT_AURA");
        this.UnregisterMessage("Ovale_GroupChanged");
        this.UnregisterMessage("Ovale_UnitChanged");
        for (const [guid] of pairs(this.current.aura)) {
            RemoveAurasOnGUID(this.current.aura, guid);
        }
        self_pool.Drain();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, timestamp: number, cleuEvent: string, hideCaster: boolean, sourceGUID: string, sourceName: string, sourceFlags: number, sourceRaidFlags: number, destGUID: string, destName: string, destFlags: number, destRaidFlags: number, ...__args: any[]) {
        let [arg12, arg13, arg14, arg15, arg16, , , , , , , , ] = __args;
        let mine = (sourceGUID == self_playerGUID || OvaleGUID.IsPlayerPet(sourceGUID));
        if (mine && cleuEvent == "SPELL_MISSED") {
            let [spellId, ,] = [arg12, arg13, arg14];
            let si = OvaleData.spellInfo[spellId];
            let bypassState = this.current.bypassState;
            if (si && si.aura && si.aura.player) {
                for (const [, auraTable] of pairs(si.aura.player)) {
                    for (const [auraId] of pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {};
                        }
                        bypassState[auraId][self_playerGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.target) {
                for (const [, auraTable] of pairs(si.aura.target)) {
                    for (const [auraId] of pairs(auraTable)) {
                        if (!bypassState[auraId]) {
                            bypassState[auraId] = {};
                        }
                        bypassState[auraId][destGUID] = true;
                    }
                }
            }
            if (si && si.aura && si.aura.pet) {
                for (const [, auraTable] of pairs(si.aura.pet)) {
                    for (const [auraId,] of pairs(auraTable)) {
                        for (const [petGUID] of pairs(self_petGUID)) {
                            if (!bypassState[petGUID]) {
                                bypassState[auraId] = {
                                }
                            }
                            bypassState[auraId][petGUID] = true;
                        }
                    }
                }
            }
        }
        if (CLEU_AURA_EVENTS[cleuEvent]) {
            let [unitId] = OvaleGUID.GUIDUnit(destGUID);
            if (unitId) {
                if (!OvaleGUID.UNIT_AURA_UNIT[unitId]) {
                    this.DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId);
                    this.ScanAuras(unitId, destGUID);
                }
            } else if (mine) {
                let [spellId, spellName,] = [arg12, arg13, arg14];
                this.DebugTimestamp("%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID);
                let now = GetTime();
                if (cleuEvent == "SPELL_AURA_REMOVED" || cleuEvent == "SPELL_AURA_BROKEN" || cleuEvent == "SPELL_AURA_BROKEN_SPELL") {
                    this.LostAuraOnGUID(destGUID, now, spellId, sourceGUID);
                } else {
                    let [auraType, amount] = [arg15, arg16];
                    let filter = (auraType == "BUFF") && "HELPFUL" || "HARMFUL";
                    let si = OvaleData.spellInfo[spellId];
                    let aura = GetAuraOnGUID(this.current.aura, destGUID, spellId, filter, true);
                    let duration = 15;
                    if (aura) {
                        duration = aura.duration;
                    } else if (si && si.duration) {
                        [duration] = OvaleData.GetSpellInfoPropertyNumber(spellId, now, "duration", destGUID) || [15];
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
                    this.GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, undefined, count, undefined, duration, expirationTime, undefined, spellName);
                }
            }
        } else if (mine && CLEU_TICK_EVENTS[cleuEvent]) {
            let [spellId, ,] = [arg12, arg13, arg14];
            this.DebugTimestamp("%s: %s", cleuEvent, destGUID);
            let aura = GetAura(this.current.aura, destGUID, spellId, self_playerGUID);
            let now = GetTime();
            if (this.IsActiveAura(aura, now)) {
                let name = aura.name || "Unknown spell";
                let [baseTick, lastTickTime] = [aura.baseTick, aura.lastTickTime];
                let tick = baseTick;
                if (lastTickTime) {
                    tick = now - lastTickTime;
                } else if (!baseTick) {
                    this.Debug("    First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID);
                    let si = OvaleData.spellInfo[spellId];
                    baseTick = (si && si.tick) && si.tick || 3;
                    tick = this.GetTickLength(spellId);
                }
                aura.baseTick = baseTick;
                aura.lastTickTime = now;
                aura.tick = tick;
                this.Debug("    Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime);
                Ovale.refreshNeeded[destGUID] = true;
            }
        }
    }
    PLAYER_ENTERING_WORLD(event: string) {
        this.ScanAllUnitAuras();
    }
    PLAYER_REGEN_ENABLED(event: string) {
        this.RemoveAurasOnInactiveUnits();
        self_pool.Drain();
    }
    UNIT_AURA(event: string, unitId: string) {
        this.Debug("%s: %s", event, unitId);
        this.ScanAuras(unitId);
    }
    Ovale_UnitChanged(event: string, unitId: string, guid: string) {
        if ((unitId == "pet" || unitId == "target") && guid) {
            this.Debug(event, unitId, guid);
            this.ScanAuras(unitId, guid);
        }
    }
    ScanAllUnitAuras() {
        for (const [unitId] of pairs(OvaleGUID.UNIT_AURA_UNIT)) {
            this.ScanAuras(unitId);
        }
    }
    RemoveAurasOnInactiveUnits() {
        for (const [guid] of pairs(this.current.aura)) {
            let unitId = OvaleGUID.GUIDUnit(guid);
            if (!unitId) {
                this.Debug("Removing auras from GUID %s", guid);
                RemoveAurasOnGUID(this.current.aura, guid);
                this.current.serial[guid] = undefined;
            }
        }
    }
    IsActiveAura(aura: Aura, atTime: number) {
        let boolean = false;
        atTime = atTime || baseState.next.currentTime;
        if (aura) {
            if (aura.state) {
                if (aura.serial == this.next.auraSerial && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                    boolean = true;
                } else if (aura.consumed && IsWithinAuraLag(aura.ending, atTime)) {
                    boolean = true;
                }
            } else {
                if (aura.serial == this.current.serial[aura.guid] && aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending) {
                    boolean = true;
                } else if (aura.consumed && IsWithinAuraLag(aura.ending, atTime)) {
                    boolean = true;
                }
            }
        }
        return boolean;
    }

    GainedAuraOnGUID(guid: string, atTime: number, auraId: number, casterGUID: string, filter: string, visible: boolean, icon: string, count: number, debuffType: string, duration: number, expirationTime: number, isStealable: boolean, name: string, value1?: number, value2?: number, value3?: number) {
        this.StartProfiling("OvaleAura_GainedAuraOnGUID");
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
        aura.serial = this.current.serial[guid];
        if (!auraIsActive || !auraIsUnchanged) {
            this.Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d", filter, name, auraId, guid, atTime, aura.serial);
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
            aura.consumed = undefined;
            aura.filter = filter;
            aura.visible = visible;
            aura.icon = icon;
            aura.debuffType = debuffType;
            aura.enrage = (debuffType == "Enrage") || undefined;
            aura.stealable = isStealable;
            [aura.value1, aura.value2, aura.value3] = [value1, value2, value3];
            let mine = (casterGUID == self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                let spellcast = lastSpell.LastInFlightSpell();
                if (spellcast && spellcast.stop && !IsWithinAuraLag(spellcast.stop, atTime)) {
                    spellcast = lastSpell.lastSpellcast;
                    if (spellcast && spellcast.stop && !IsWithinAuraLag(spellcast.stop, atTime)) {
                        spellcast = undefined;
                    }
                }
                if (spellcast && spellcast.target == guid) {
                    let spellId = spellcast.spellId;
                    let spellName = OvaleSpellBook.GetSpellName(spellId) || "Unknown spell";
                    let keepSnapshot = false;
                    let si = OvaleData.spellInfo[spellId];
                    if (si && si.aura) {
                        let auraTable = OvaleGUID.IsPlayerPet(guid) && si.aura.pet || si.aura.target;
                        if (auraTable && auraTable[filter]) {
                            let spellData = auraTable[filter][auraId];
                            if (spellData == "refresh_keep_snapshot") {
                                keepSnapshot = true;
                            } else if (isLuaArray(spellData) && spellData[1] == "refresh_keep_snapshot") {
                                [keepSnapshot] = CheckRequirements(spellId, atTime, spellData, 2, guid);
                            }
                        }
                    }
                    if (keepSnapshot) {
                        this.Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, aura.snapshotTime, atTime, aura.serial);
                    } else {
                        this.Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial);
                        lastSpell.CopySpellcastInfo(spellcast, aura);
                    }
                }
                let si = OvaleData.spellInfo[auraId];
                if (si) {
                    if (si.tick) {
                        this.Debug("    %s (%s) is a periodic aura.", name, auraId);
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
                        this.Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd);
                        if (!auraIsActive) {
                            aura.cooldownEnding = aura.gain + si.buff_cd;
                        }
                    }
                }
            }
            if (!auraIsActive) {
                this.SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source);
            } else if (!auraIsUnchanged) {
                this.SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source);
            }
            Ovale.refreshNeeded[guid] = true;
        }
        this.StopProfiling("OvaleAura_GainedAuraOnGUID");
    }
    LostAuraOnGUID(guid: string, atTime: number, auraId: AuraId, casterGUID: string) {
        this.StartProfiling("OvaleAura_LostAuraOnGUID");
        let aura = GetAura(this.current.aura, guid, auraId, casterGUID);
        if (aura) {
            let filter = aura.filter;
            this.Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, guid, atTime);
            if (aura.ending > atTime) {
                aura.ending = atTime;
            }
            let mine = (casterGUID == self_playerGUID || OvaleGUID.IsPlayerPet(casterGUID));
            if (mine) {
                aura.baseTick = undefined;
                aura.lastTickTime = undefined;
                aura.tick = undefined;
                if (aura.start + aura.duration > aura.ending) {
                    let spellcast: SpellCast;
                    if (guid == self_playerGUID) {
                        spellcast = lastSpell.LastSpellSent();
                    } else {
                        spellcast = lastSpell.lastSpellcast;
                    }
                    if (spellcast) {
                        if ((spellcast.success && spellcast.stop && IsWithinAuraLag(spellcast.stop, aura.ending)) || (spellcast.queued && IsWithinAuraLag(spellcast.queued, aura.ending))) {
                            aura.consumed = true;
                            let spellName = OvaleSpellBook.GetSpellName(spellcast.spellId) || "Unknown spell";
                            this.Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.queued);
                        }
                    }
                }
            }
            aura.lastUpdated = atTime;
            this.SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source);
            Ovale.refreshNeeded[guid] = true;
        }
        this.StopProfiling("OvaleAura_LostAuraOnGUID");
    }
    ScanAuras(unitId: string, guid?: string) {
        this.StartProfiling("OvaleAura_ScanAuras");
        guid = guid || OvaleGUID.UnitGUID(unitId);
        if (guid) {
            this.DebugTimestamp("Scanning auras on %s (%s)", guid, unitId);
            let serial = this.current.serial[guid] || 0;
            serial = serial + 1;
            this.Debug("    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial);
            this.current.serial[guid] = serial;
            let i = 1;
            let filter = "HELPFUL";
            let now = GetTime();
            while (true) {
                let [name, , icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, , spellId, , , , value1, value2, value3] = UnitAura(unitId, i, filter);
                if (!name) {
                    if (filter == "HELPFUL") {
                        filter = "HARMFUL";
                        i = 1;
                    } else {
                        break;
                    }
                } else {
                    let casterGUID = OvaleGUID.UnitGUID(unitCaster);
                    if (debuffType == "") {
                        debuffType = "Enrage";
                    }
                    this.GainedAuraOnGUID(guid, now, spellId, casterGUID, filter, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3);
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
                                this.Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial);
                            }
                        }
                    }
                }
            }
            this.Debug("End scanning of auras on %s (%s).", guid, unitId);
        }
        this.StopProfiling("OvaleAura_ScanAuras");
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
            let guid, unitId, filter, mine;
            if (strsub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    unitId = OvaleGUID.GUIDUnit(guid);
                } else {
                    unitId = baseState.next.defaultTarget || "target";
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
            guid = guid || OvaleGUID.UnitGUID(unitId);
            let aura = this.GetAuraByGUID(guid, buffId, filter, mine, atTime);
            let isActiveAura = this.IsActiveAura(aura, atTime) && aura.stacks >= stacks;
            if (!isBang && isActiveAura || isBang && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                OvaleAura.Log("    Require aura %s with at least %d stack(s) NOT on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            } else {
                OvaleAura.Log("    Require aura %s with at least %d stack(s) on %s at time=%f: %s", buffName, stacks, unitId, atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a buff argument.", requirement);
        }
        return [verified, requirement, index];
    }

    RequireStealthHandler = (spellId: number, atTime: number, requirement: string, tokens, index, targetGUID): [boolean, string, number] => {
        let verified = false;
        let stealthed = tokens;
        if (index) {
            stealthed = tokens[index];
            index = index + 1;
        }
        if (stealthed) {
            stealthed = tonumber(stealthed);
            let aura = this.GetAura("player", "stealthed_buff", atTime, "HELPFUL", true);
            let isActiveAura = this.IsActiveAura(aura, atTime);
            if (stealthed == 1 && isActiveAura || stealthed != 1 && !isActiveAura) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (stealthed == 1) {
                OvaleAura.Log("    Require stealth at time=%f: %s", atTime, result);
            } else {
                OvaleAura.Log("    Require NOT stealth at time=%f: %s", atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement);
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

    DebugUnitAuras(unitId: string, filter: string, atTime: number) {
        wipe(array);
        let guid = OvaleGUID.UnitGUID(unitId);
        if (atTime && this.next.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter && !aura.state) {
                        let name = aura.name || "Unknown spell";
                        insert(array, `${name}: ${auraId}`);
                    }
                }
            }
        }
        if (this.current.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter) {
                        let name = aura.name || "Unknown spell";
                        insert(array, `${name}: ${auraId}`);
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
        let auraFound: Aura;
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
    GetStateAuraOnGUID(guid: string, auraId: AuraId, filter: string, mine: boolean, atTime: number) {
        let auraFound: Aura;
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

    CanApplySpellAura(spellData) {
        if (spellData["if_target_debuff"]) {
        } else if (spellData["if_buff"]) {
        }
    }


    GetAuraByGUID(guid: string, auraId: AuraId, filter: string, mine: boolean, atTime: number | undefined) {
        let auraFound: Aura;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of pairs(OvaleData.buffSpellList[auraId])) {
                // TODO check this tostring(id)
                let aura = this.GetStateAuraOnGUID(guid, id, filter, mine, atTime);
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    OvaleAura.Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, guid, aura.start, aura.ending);
                    auraFound = aura;
                } else {
                }
            }
            if (!auraFound) {
                OvaleAura.Log("Aura matching '%s' is missing on %s.", auraId, guid);
            }
        } else {
            auraFound = this.GetStateAuraOnGUID(guid, auraId, filter, mine, atTime);
            if (auraFound) {
                OvaleAura.Log("Aura %s found on %s with (%s, %s)", auraId, guid, auraFound.start, auraFound.ending);
            } else {
                OvaleAura.Log("Aura %s is missing on %s.", auraId, guid);
            }
        }
        return auraFound;
    }

    GetAura(unitId: string, auraId: AuraId, atTime?: number, filter?: string, mine?: boolean) {
        const guid = OvaleGUID.UnitGUID(unitId);
        if (atTime) {
            const bypassState = this.next.bypassState;
            if (!bypassState[auraId]) {
                bypassState[auraId] = {}
            }

            if (bypassState[auraId][guid]) {
                let stateAura = this.GetAuraByGUID(guid, auraId, filter, mine, atTime);
                let aura = this.GetAuraByGUID(guid, auraId, filter, mine, undefined);
                if (aura && aura.start && aura.ending && stateAura && stateAura.start && stateAura.ending && aura.start == stateAura.start && aura.ending == stateAura.ending) {
                    bypassState[auraId][guid] = false;
                    return stateAura;
                } else {
                    return aura;
                }
            }
        }
        return this.GetAuraByGUID(guid, auraId, filter, mine, atTime);
    }

    GetAuraWithProperty(unitId: string, propertyName: string, filter: string, atTime: number) {
        let count = 0;
        let guid = OvaleGUID.UnitGUID(unitId);
        let [start, ending] = [huge, 0];
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
            OvaleAura.Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending);
        } else {
            OvaleAura.Log("Aura with '%s' property is missing on %s.", propertyName, unitId);
            start = undefined;
            ending = undefined;
        }
        return [start, ending];
    }


    AuraCount(auraId: number, filter: string, mine: boolean, minStacks: number, atTime: number, excludeUnitId: string) {
        OvaleAura.StartProfiling("OvaleAura_state_AuraCount");
        minStacks = minStacks || 1;
        count = 0;
        stacks = 0;
        [startChangeCount, endingChangeCount] = [huge, huge];
        [startFirst, endingLast] = [huge, 0];
        let excludeGUID = excludeUnitId && OvaleGUID.UnitGUID(excludeUnitId) || undefined;
        for (const [guid, auraTable] of pairs(this.current.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = this.GetStateAura(guid, auraId, self_playerGUID, atTime);
                    if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                        CountMatchingActiveAura(aura);
                    }
                    for (const [petGUID] of pairs(self_petGUID)) {
                        aura = this.GetStateAura(guid, auraId, petGUID, atTime);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [casterGUID] of pairs(auraTable[auraId])) {
                        let aura = this.GetStateAura(guid, auraId, casterGUID, atTime);
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(aura);
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
                            CountMatchingActiveAura(aura);
                        }
                    }
                    for (const [petGUID] of pairs(self_petGUID)) {
                        aura = auraTable[auraId][petGUID];
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks && !aura.state) {
                            CountMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [, aura] of pairs(auraTable[auraId])) {
                        if (this.IsActiveAura(aura, atTime) && aura.filter == filter && aura.stacks >= minStacks) {
                            CountMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        OvaleAura.Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast);
        OvaleAura.StopProfiling("OvaleAura_state_AuraCount");
        return [count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast];
    }

    InitializeState() {
        this.next.aura = {}
        this.next.auraSerial = 0;
        self_playerGUID = Ovale.playerGUID;
    }
    ResetState() {
        OvaleAura.StartProfiling("OvaleAura_ResetState");
        this.next.auraSerial = this.next.auraSerial + 1;
        if (next(this.next.aura)) {
            OvaleAura.Log("Resetting aura state:");
        }
        for (const [guid, auraTable] of pairs(this.next.aura)) {
            for (const [auraId, whoseTable] of pairs(auraTable)) {
                for (const [casterGUID, aura] of pairs(whoseTable)) {
                    self_pool.Release(aura);
                    whoseTable[casterGUID] = undefined;
                    OvaleAura.Log("    Aura %d on %s removed.", auraId, guid);
                }
                if (!next(whoseTable)) {
                    self_pool.Release(whoseTable);
                    auraTable[auraId] = undefined;
                }
            }
            if (!next(auraTable)) {
                self_pool.Release(auraTable);
                this.next.aura[guid] = undefined;
            }
        }
        OvaleAura.StopProfiling("OvaleAura_ResetState");
    }
    CleanState() {
        for (const [guid] of pairs(this.next.aura)) {
            RemoveAurasOnGUID(this.next.aura, guid);
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleAura.StartProfiling("OvaleAura_ApplySpellStartCast");
        if (isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.ApplySpellAuras(spellId, self_playerGUID, startCast, si.aura.player, spellcast);
                }
                if (si.aura.target) {
                    this.ApplySpellAuras(spellId, targetGUID, startCast, si.aura.target, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = OvaleGUID.UnitGUID("pet");
                    if (petGUID) {
                        this.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        OvaleAura.StopProfiling("OvaleAura_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleAura.StartProfiling("OvaleAura_ApplySpellAfterCast");
        if (!isChanneled) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.ApplySpellAuras(spellId, self_playerGUID, endCast, si.aura.player, spellcast);
                }
                if (si.aura.pet) {
                    let petGUID = OvaleGUID.UnitGUID("pet");
                    if (petGUID) {
                        this.ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast);
                    }
                }
            }
        }
        OvaleAura.StopProfiling("OvaleAura_ApplySpellAfterCast");
    }
    ApplySpellOnHit(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleAura.StartProfiling("OvaleAura_ApplySpellAfterHit");
        if (!isChanneled) {
            let si = OvaleData.spellInfo[spellId];
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
        OvaleAura.StopProfiling("OvaleAura_ApplySpellAfterHit");
    }

    private ApplySpellAuras(spellId: number, guid: string, atTime: number, auraList, spellcast: SpellCast) {
        OvaleAura.StartProfiling("OvaleAura_state_ApplySpellAuras");
        for (const [filter, filterInfo] of pairs(auraList)) {
            for (const [auraId, spellData] of pairs(filterInfo)) {
                let duration = this.GetBaseDuration(auraId, spellcast);
                let stacks = 1;
                let count = undefined;
                let extend = 0;
                let toggle = undefined;
                let refresh = false;
                let keepSnapshot = false;
                let [verified, value, data] = OvaleData.CheckSpellAuraData(auraId, spellData, atTime, guid);
                if (value == "refresh") {
                    refresh = true;
                } else if (value == "refresh_keep_snapshot") {
                    refresh = true;
                    keepSnapshot = true;
                } else if (value == "toggle") {
                    toggle = true;
                } else if (value == "count") {
                    count = data;
                } else if (value == "extend") {
                    extend = data;
                } else if (tonumber(value)) {
                    stacks = tonumber(value);
                } else {
                    OvaleAura.Log("Unknown stack %s", stacks);
                }
                if (verified) {
                    let si = OvaleData.spellInfo[auraId];
                    let auraFound = OvaleAura.GetAuraByGUID(guid, auraId, filter, true, atTime);
                    if (OvaleAura.IsActiveAura(auraFound, atTime)) {
                        let aura: Aura;
                        if (auraFound.state) {
                            aura = auraFound;
                        } else {
                            aura = this.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, huge, atTime);
                            for (const [k, v] of pairs(auraFound)) {
                                aura[k] = v;
                            }
                            aura.serial = this.next.auraSerial;
                            OvaleAura.Log("Aura %d is copied into simulator.", auraId);
                        }
                        if (toggle) {
                            OvaleAura.Log("Aura %d is toggled off by spell %d.", auraId, spellId);
                            stacks = 0;
                        }
                        if (count && count > 0) {
                            stacks = count - aura.stacks;
                        }
                        if (refresh || extend > 0 || stacks > 0) {
                            if (refresh) {
                                OvaleAura.Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks);
                            } else if (extend > 0) {
                                OvaleAura.Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks);
                            } else {
                                let maxStacks = 1;
                                if (si && (si.max_stacks || si.maxstacks)) {
                                    maxStacks = si.max_stacks || si.maxstacks;
                                }
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks > maxStacks) {
                                    aura.stacks = maxStacks;
                                }
                                OvaleAura.Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId);
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
                            OvaleAura.Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending);
                            if (keepSnapshot) {
                                OvaleAura.Log("Aura %d keeping previous snapshot.", auraId);
                            } else if (spellcast) {
                                lastSpell.CopySpellcastInfo(spellcast, aura);
                            }
                        } else if (stacks == 0 || stacks < 0) {
                            if (stacks == 0) {
                                aura.stacks = 0;
                            } else {
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks < 0) {
                                    aura.stacks = 0;
                                }
                                OvaleAura.Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId);
                            }
                            if (aura.stacks == 0) {
                                OvaleAura.Log("Aura %d is completely removed.", auraId);
                                aura.ending = atTime;
                                aura.consumed = true;
                            }
                        }
                    } else {
                        if (toggle) {
                            OvaleAura.Log("Aura %d is toggled on by spell %d.", auraId, spellId);
                            stacks = 1;
                        }
                        if (!refresh && stacks > 0) {
                            OvaleAura.Log("New aura %d at %f on %s", auraId, atTime, guid);
                            let debuffType;
                            if (si) {
                                for (const [k, v] of pairs(SPELLINFO_DEBUFF_TYPE)) {
                                    if (si[k] == 1) {
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
                                lastSpell.CopySpellcastInfo(spellcast, aura);
                            }
                        }
                    }
                } else {
                    OvaleAura.Log("Aura %d (%s) is not applied.", auraId, spellData);
                }
            }
        }
        OvaleAura.StopProfiling("OvaleAura_state_ApplySpellAuras");
    }

    public AddAuraToGUID(guid: string, auraId: AuraId, casterGUID: string, filter: string, debuffType: string, start: number, ending: number, atTime: number, snapshot?: PaperDollSnapshot) {
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
        aura.debuffType = debuffType;
        aura.enrage = (debuffType == "Enrage") || undefined;
        OvalePaperDoll.UpdateSnapshot(aura, snapshot);
        PutAura(this.next.aura, guid, auraId, casterGUID, aura);
        return aura;
    }
    RemoveAuraOnGUID(guid: string, auraId: AuraId, filter: string, mine: boolean, atTime: number) {
        let auraFound = OvaleAura.GetAuraByGUID(guid, auraId, filter, mine, atTime);
        if (OvaleAura.IsActiveAura(auraFound, atTime)) {
            let aura;
            if (auraFound.state) {
                aura = auraFound;
            } else {
                aura = this.AddAuraToGUID(guid, auraId, auraFound.source, filter, undefined, 0, huge, atTime);
                for (const [k, v] of pairs(auraFound)) {
                    aura[k] = v;
                }
                aura.serial = this.next.auraSerial;
            }
            aura.stacks = 0;
            aura.ending = atTime;
            aura.lastUpdated = atTime;
        }
    }


    GetBaseDuration(auraId, spellcast?: SpellCast) {
        spellcast = spellcast || OvalePaperDoll.current;
        let combopoints = spellcast.combopoints || 0;
        let duration = INFINITY
        let si = OvaleData.spellInfo[auraId];
        if (si && si.duration) {
            let [value, ratio] = OvaleData.GetSpellInfoPropertyNumber(auraId, undefined, "duration", undefined, true) || [15, 1];
            if (si.add_duration_combopoints && combopoints) {
                duration = (value + si.add_duration_combopoints * combopoints) * ratio;
            } else {
                duration = value * ratio;
            }
        }
        /* Most aura durations are no longer reduced by haste
        if (si && si.haste && spellcast) {
            let hasteMultiplier = OvalePaperDoll.GetHasteMultiplier(si.haste, spellcast);
            duration = duration / hasteMultiplier;
        }
        */
        return duration;
    }
    GetTickLength(auraId, snapshot?: PaperDollSnapshot) {
        let tick = 3;
        let si = OvaleData.spellInfo[auraId];
        if (si) {
            tick = si.tick || tick;
            let hasteMultiplier = OvalePaperDoll.GetHasteMultiplier(si.haste, snapshot);
            tick = tick / hasteMultiplier;
        }
        return tick;
    }
}

OvaleAura = new OvaleAuraClass();
