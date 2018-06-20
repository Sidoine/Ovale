import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleAura } from "./Aura";
import { OvaleData } from "./Data";
import { OvaleGUID } from "./GUID";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleSpellBook } from "./SpellBook";
import { lastSpell, SpellCast, self_pool } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, type, lualength, LuaObj, LuaArray, wipe } from "@wowts/lua";
import { sub } from "@wowts/string";
import { insert, remove } from "@wowts/table";
import { GetSpellInfo, GetTime, UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID, UnitName } from "@wowts/wow-mock";
import { OvaleState } from "./State";
import { OvaleCooldown } from "./Cooldown";
import { OvaleStance } from "./Stance";
import { baseState } from "./BaseState";
import { isLuaArray } from "./tools";
import { CheckRequirements } from "./Requirement";

let strsub = sub;
let tremove = remove;
let self_timeAuraAdded: undefined|number = undefined;

// let SIMULATOR_LAG = 0.005;

let CLEU_AURA_EVENT: LuaObj<"hit"> = {
    SPELL_AURA_APPLIED: "hit",
    SPELL_AURA_APPLIED_DOSE: "hit",
    SPELL_AURA_BROKEN: "hit",
    SPELL_AURA_BROKEN_SPELL: "hit",
    SPELL_AURA_REFRESH: "hit",
    SPELL_AURA_REMOVED: "hit",
    SPELL_AURA_REMOVED_DOSE: "hit"
}
let CLEU_SPELLCAST_FINISH_EVENT: LuaObj<"hit" | "miss"> = {
    SPELL_DAMAGE: "hit",
    SPELL_DISPEL: "hit",
    SPELL_DISPEL_FAILED: "miss",
    SPELL_HEAL: "hit",
    SPELL_INTERRUPT: "hit",
    SPELL_MISSED: "miss",
    SPELL_STOLEN: "hit"
}
let CLEU_SPELLCAST_EVENT: LuaObj<boolean> = {
    SPELL_CAST_FAILED: true,
    SPELL_CAST_START: true,
    SPELL_CAST_SUCCESS: true
}
{
    for (const [cleuEvent, v] of pairs(CLEU_AURA_EVENT)) {
        CLEU_SPELLCAST_FINISH_EVENT[cleuEvent] = v;
    }
    for (const [cleuEvent, ] of pairs(CLEU_SPELLCAST_FINISH_EVENT)) {
        CLEU_SPELLCAST_EVENT[cleuEvent] = true;
    }
}
let SPELLCAST_AURA_ORDER: LuaArray<string> = {
    1: "target",
    2: "pet"
};
let SPELLAURALIST_AURA_VALUE: LuaObj<boolean> = {
    count: true,
    extend: true,
    refresh: true,
    refresh_keep_snapshot: true
};
let WHITE_ATTACK: LuaArray<boolean> = {
    [75]: true,
    [5019]: true,
    [6603]: true
};
let WHITE_ATTACK_NAME: LuaObj<boolean> = {};
{
    for (const [spellId] of pairs(WHITE_ATTACK)) {
        let [name] = GetSpellInfo(spellId);
        if (name) {
            WHITE_ATTACK_NAME[name] = true;
        }
    }
}

const IsSameSpellcast = function(a: SpellCast, b: SpellCast) {
    let boolean = (a.spellId == b.spellId && a.queued == b.queued);
    if (boolean) {
        if (a.channel || b.channel) {
            if (a.channel != b.channel) {
                boolean = false;
            }
        } else if (a.lineId != b.lineId) {
            boolean = false;
        }
    }
    return boolean;
}
let eventDebug = false;

export class OvaleFutureData {
    lastCastTime: LuaObj<number> = {}
    lastOffGCDSpellcast: SpellCast = {}
    lastGCDSpellcast: SpellCast = {}
    lastGCDSpellIds: LuaArray<number> = {}
    lastGCDSpellId: number;
    counter: LuaArray<number> = {}
    lastCast: LuaObj<number> = {};
    currentCast: SpellCast = {}
    nextCast: number;
    
    PushGCDSpellId(spellId: number) {
        if (this.lastGCDSpellId) {
            insert(this.lastGCDSpellIds, this.lastGCDSpellId);
            if (lualength(this.lastGCDSpellIds) > 5) {
                remove(this.lastGCDSpellIds, 1);
            }
        }
        this.lastGCDSpellId = spellId;
    }
    
    UpdateCounters(spellId: number, atTime: number, targetGUID: string) {
        let inccounter = OvaleData.GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID);
        if (inccounter) {
            let value = this.counter[inccounter] && this.counter[inccounter] || 0;
            this.counter[inccounter] = value + 1;
        }
        let resetcounter = OvaleData.GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID);
        if (resetcounter) {
            this.counter[resetcounter] = 0;
        }
    }

    GetCounter (id: number) {
        return this.counter[id] || 0;
    }
    IsChanneling(atTime: number) {
        return this.currentCast.channel && (atTime < this.currentCast.stop);
    }
}

let OvaleFutureBase = OvaleState.RegisterHasState(OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleFuture", aceEvent))), OvaleFutureData);

export class OvaleFutureClass extends OvaleFutureBase {
    constructor() {
        super();
        OvaleState.RegisterState(this);
    }

    OnInitialize() {
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD");
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
        this.RegisterEvent("UNIT_SPELLCAST_DELAYED");
        this.RegisterEvent("UNIT_SPELLCAST_FAILED", "UnitSpellcastEnded");
        this.RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "UnitSpellcastEnded");
        this.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UnitSpellcastEnded");
        this.RegisterEvent("UNIT_SPELLCAST_SENT");
        this.RegisterEvent("UNIT_SPELLCAST_START");
        this.RegisterEvent("UNIT_SPELLCAST_STOP", "UnitSpellcastEnded");
        this.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.RegisterMessage("Ovale_AuraAdded");
    }

    OnDisable() {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
        this.UnregisterEvent("UNIT_SPELLCAST_DELAYED");
        this.UnregisterEvent("UNIT_SPELLCAST_FAILED");
        this.UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
        this.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.UnregisterEvent("UNIT_SPELLCAST_SENT");
        this.UnregisterEvent("UNIT_SPELLCAST_START");
        this.UnregisterEvent("UNIT_SPELLCAST_STOP");
        this.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.UnregisterMessage("Ovale_AuraAdded");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, timestamp: number, cleuEvent: string, hideCaster: boolean, sourceGUID: string, sourceName: string, sourceFlags: number, sourceRaidFlags: number, destGUID: string, destName: string, destFlags: number, destRaidFlags: number, ...__args: any[]) {
        let [arg12, arg13, , , , , , , , , , , arg24] = __args;
        if (sourceGUID == Ovale.playerGUID || OvaleGUID.IsPlayerPet(sourceGUID)) {
            this.StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED");
            if (CLEU_SPELLCAST_EVENT[cleuEvent]) {
                let now = GetTime();
                let [spellId, spellName] = [arg12, arg13];
                let eventDebug = false;
                let delta = 0;
                if (strsub(cleuEvent, 1, 11) == "SPELL_CAST_" && (destName && destName != "")) {
                    if (!eventDebug) {
                        this.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
                        eventDebug = true;
                    }
                    let [spellcast] = this.GetSpellcast(spellName, spellId, undefined, now);
                    if (spellcast && spellcast.targetName && spellcast.targetName == destName && spellcast.target != destGUID) {
                        this.Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID);
                        spellcast.target = destGUID;
                    }
                }
                let finish = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent];
                if (cleuEvent == "SPELL_DAMAGE" || cleuEvent == "SPELL_HEAL") {
                    let [isOffHand] = [arg24];
                    if (isOffHand) {
                        finish = undefined;
                    }
                }
                if (finish) {
                    let anyFinished = false;
                    for (let i = lualength(lastSpell.queue); i >= 1; i += -1) {
                        let spellcast = lastSpell.queue[i];
                        if (spellcast.success && (spellcast.spellId == spellId || spellcast.auraId == spellId)) {
                            if (this.FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)) {
                                anyFinished = true;
                            }
                        }
                    }
                    if (!anyFinished) {
                        this.Debug("Found no spell to finish for %s (%d)", spellName, spellId);
                        for (let i = lualength(lastSpell.queue); i >= 1; i += -1) {
                            let spellcast = lastSpell.queue[i];
                            if (spellcast.success && (spellcast.spellName == spellName)) {
                                if (this.FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)) {
                                    anyFinished = true;
                                }
                            }
                        }
                        if (!anyFinished) {
                            this.Debug("No spell found for %s", spellName, spellId);
                        }
                    }
                }
            }
            this.StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    FinishSpell(spellcast: SpellCast, cleuEvent: string, sourceName: string, sourceGUID: string, destName: string, destGUID: string, spellId: number, spellName: string, delta: number, finish: "hit"|"miss", i: number) {
        let finished = false;
        if (!spellcast.auraId) {
            if (!eventDebug) {
                this.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
                eventDebug = true;
            }
            if (!spellcast.channel) {
                this.Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent);
                finished = true;
            }
        } else if (CLEU_AURA_EVENT[cleuEvent] && spellcast.auraGUID && destGUID == spellcast.auraGUID) {
            if (!eventDebug) {
                this.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
                eventDebug = true;
            }
            this.Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID);
            finished = true;
        }
        if (finished) {
            let now = GetTime();
            if (self_timeAuraAdded) {
                if (IsSameSpellcast(spellcast, lastSpell.lastGCDSpellcast)) {
                    this.UpdateSpellcastSnapshot(lastSpell.lastGCDSpellcast, self_timeAuraAdded);
                }
                if (IsSameSpellcast(spellcast, this.current.lastOffGCDSpellcast)) {
                    this.UpdateSpellcastSnapshot(this.current.lastOffGCDSpellcast, self_timeAuraAdded);
                }
            }
            let delta = now - spellcast.stop;
            let targetGUID = spellcast.target;
            this.Debug("Spell %s (%d) was in flight for %f seconds.", spellName, spellId, delta);
            tremove(lastSpell.queue, i);
            self_pool.Release(spellcast);
            Ovale.needRefresh();
            this.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish);
        }
        return finished;
    }
    PLAYER_ENTERING_WORLD(event: string) {
        this.StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
        this.Debug(event);
        this.StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
    }
    PLAYER_REGEN_DISABLED(event: string) {
        this.StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
        this.Debug(event, "Entering combat.");
        let now = GetTime();
        baseState.current.inCombat = true;
        baseState.current.combatStartTime = now;
        Ovale.needRefresh();
        this.SendMessage("Ovale_CombatStarted", now);
        this.StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
    }
    PLAYER_REGEN_ENABLED(event: string) {
        this.StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
        this.Debug(event, "Leaving combat.");
        let now = GetTime();
        baseState.current.inCombat = false;
        Ovale.needRefresh();
        this.SendMessage("Ovale_CombatEnded", now);
        this.StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
    }
    UNIT_SPELLCAST_CHANNEL_START(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast) {
                let [name, , , startTime, endTime] = UnitChannelInfo(unitId);
                if (name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    spellcast.channel = true;
                    spellcast.spellId = spellId;
                    spellcast.success = now;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    let delta = now - spellcast.queued;
                    this.Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime);
                    this.SaveSpellcastInfo(spellcast, now);
                    this.UpdateLastSpellcast(now, spellcast);
                    this.UpdateCounters(spellId, spellcast.start, spellcast.target);
                    Ovale.needRefresh();
                } else if (!name) {
                    this.Debug("Warning: not channelling a spell.");
                } else {
                    this.Debug("Warning: channelling unexpected spell %s", name);
                }
            } else {
                this.Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START");
        }
    }
    UNIT_SPELLCAST_CHANNEL_STOP(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast && spellcast.channel) {
                this.Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued);
                spellcast.stop = now;
                this.UpdateLastSpellcast(now, spellcast);
                let targetGUID = spellcast.target;
                tremove(lastSpell.queue, index);
                self_pool.Release(spellcast);
                Ovale.needRefresh();
                this.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit");
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP");
        }
    }
    UNIT_SPELLCAST_CHANNEL_UPDATE(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast && spellcast.channel) {
                let [name, , , startTime, endTime] = UnitChannelInfo(unitId);
                if (name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    let delta = endTime - spellcast.stop;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    this.Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta);
                    Ovale.needRefresh();
                } else if (!name) {
                    this.Debug("Warning: not channelling a spell.");
                } else {
                    this.Debug("Warning: delaying unexpected channelled spell %s.", name);
                }
            } else {
                this.Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE");
        }
    }
    UNIT_SPELLCAST_DELAYED(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , startTime, endTime, , castId] = UnitCastingInfo(unitId);
                if (lineId == castId && name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    let delta = endTime - spellcast.stop;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    this.Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta);
                    Ovale.needRefresh();
                } else if (!name) {
                    this.Debug("Warning: not casting a spell.");
                } else {
                    this.Debug("Warning: delaying unexpected spell %s.", name);
                }
            } else {
                this.Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED");
        }
    }
    UNIT_SPELLCAST_SENT(event: string, unitId: string, spell: string, rank: number, targetName: string, lineId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK_NAME[spell]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT");
            this.DebugTimestamp(event, unitId, spell, rank, targetName, lineId);
            let now = GetTime();
            let caster = OvaleGUID.UnitGUID(unitId);
            let spellcast = self_pool.Get();
            spellcast.lineId = lineId;
            spellcast.caster = caster;
            spellcast.spellName = spell;
            spellcast.queued = now;
            insert(lastSpell.queue, spellcast);
            if (targetName == "") {
                this.Debug("Queueing (%d) spell %s with no target.", lualength(lastSpell.queue), spell);
            } else {
                spellcast.targetName = targetName;
                let [targetGUID, nextGUID] = OvaleGUID.NameGUID(targetName);
                if (nextGUID) {
                    let name = OvaleGUID.UnitName("target");
                    if (name == targetName) {
                        targetGUID = OvaleGUID.UnitGUID("target");
                    } else {
                        name = OvaleGUID.UnitName("focus");
                        if (name == targetName) {
                            targetGUID = OvaleGUID.UnitGUID("focus");
                        } else if (UnitExists("mouseover")) {
                            name = UnitName("mouseover");
                            if (name == targetName) {
                                targetGUID = UnitGUID("mouseover");
                            }
                        }
                    }
                    spellcast.target = targetGUID;
                    this.Debug("Queueing (%d) spell %s to %s (possibly %s).", lualength(lastSpell.queue), spell, targetName, targetGUID);
                } else {
                    spellcast.target = targetGUID;
                    this.Debug("Queueing (%d) spell %s to %s (%s).", lualength(lastSpell.queue), spell, targetName, targetGUID);
                }
            }
            this.SaveSpellcastInfo(spellcast, now);
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT");
        }
    }
    UNIT_SPELLCAST_START(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_START");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , startTime, endTime, , castId] = UnitCastingInfo(unitId);
                if (lineId == castId && name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    spellcast.spellId = spellId;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    spellcast.channel = false;
                    let delta = now - spellcast.queued;
                    this.Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spell, spellId, startTime, delta, endTime);
                    let [auraId, auraGUID] = this.GetAuraFinish(spell, spellId, spellcast.target, now);
                    if (auraId && auraGUID) {
                        spellcast.auraId = auraId;
                        spellcast.auraGUID = auraGUID;
                        this.Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID);
                    }
                    this.SaveSpellcastInfo(spellcast, now);
                    Ovale.needRefresh();
                } else if (!name) {
                    this.Debug("Warning: not casting a spell.");
                } else {
                    this.Debug("Warning: casting unexpected spell %s.", name);
                }
            } else {
                this.Debug("Warning: casting spell %s (%d) without previous sent data.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_START");
        }
    }
    UNIT_SPELLCAST_SUCCEEDED(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let success = false;
                if (!spellcast.success && spellcast.start && spellcast.stop && !spellcast.channel) {
                    this.Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop);
                    spellcast.success = now;
                    this.UpdateSpellcastSnapshot(spellcast, now);
                    success = true;
                } else {
                    let name = UnitChannelInfo(unitId);
                    if (!name) {
                        let now = GetTime();
                        spellcast.spellId = spellId;
                        spellcast.start = now;
                        spellcast.stop = now;
                        spellcast.channel = false;
                        spellcast.success = now;
                        let delta = now - spellcast.queued;
                        this.Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta);
                        let [auraId, auraGUID] = this.GetAuraFinish(spell, spellId, spellcast.target, now);
                        if (auraId && auraGUID) {
                            spellcast.auraId = auraId;
                            spellcast.auraGUID = auraGUID;
                            this.Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID);
                        }
                        this.SaveSpellcastInfo(spellcast, now);
                        success = true;
                    } else {
                        this.Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId);
                    }
                }
                if (success) {
                    let targetGUID = spellcast.target;
                    this.UpdateLastSpellcast(now, spellcast);
                    this.UpdateCounters(spellId, spellcast.stop, targetGUID);
                    let finished = false;
                    let finish = "miss";
                    if (!spellcast.targetName) {
                        this.Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued);
                        finished = true;
                        finish = "hit";
                    } else if (targetGUID == Ovale.playerGUID && OvaleSpellBook.IsHelpfulSpell(spellId)) {
                        this.Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued);
                        finished = true;
                        finish = "hit";
                    }
                    if (finished) {
                        tremove(lastSpell.queue, index);
                        self_pool.Release(spellcast);
                        Ovale.needRefresh();
                        this.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish);
                    }
                }
            } else {
                this.Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED");
        }
    }
    Ovale_AuraAdded(event: string, atTime: number, guid: string, auraId: string, caster: string) {
        if (guid == Ovale.playerGUID) {
            self_timeAuraAdded = atTime;
            this.UpdateSpellcastSnapshot(lastSpell.lastGCDSpellcast, atTime);
            this.UpdateSpellcastSnapshot(this.current.lastOffGCDSpellcast, atTime);
        }
    }
    UnitSpellcastEnded(event: string, unitId: string, spell: string, rank: number, lineId: number, spellId: number) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UnitSpellcastEnded");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                this.Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event);
                if (!spellcast.success) {
                    this.Debug("Remove spell from queue because there was no success before");
                    tremove(lastSpell.queue, index);
                    self_pool.Release(spellcast);
                    Ovale.needRefresh();
                }
            } else if (lineId) {
                this.Debug("Warning: no queued spell %s (%d) found to end casting.", spell, spellId);
            }
            this.StopProfiling("OvaleFuture_UnitSpellcastEnded");
        }
    }
    GetSpellcast(spell: string, spellId: number, lineId: number | undefined | string, atTime: number):[SpellCast, number] {
        this.StartProfiling("OvaleFuture_GetSpellcast");
        let spellcast: SpellCast, index: number;
        if (!lineId || lineId != "") {
            for (const [i, sc] of ipairs(lastSpell.queue)) {
                if (!lineId || sc.lineId == lineId) {
                    if (spellId && sc.spellId == spellId) {
                        spellcast = sc;
                        index = i;
                        break;
                    } else if (spell) {
                        let spellName = sc.spellName || OvaleSpellBook.GetSpellName(spellId);
                        if (spell == spellName) {
                            spellcast = sc;
                            index = i;
                            break;
                        }
                    }
                }
            }
        }
        if (spellcast) {
            let spellName = spell || spellcast.spellName || OvaleSpellBook.GetSpellName(spellId);
            if (spellcast.targetName) {
                this.Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued);
            } else {
                this.Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued);
            }
        }
        this.StopProfiling("OvaleFuture_GetSpellcast");
        return [spellcast, index];
    }
    GetAuraFinish(spell: string, spellId: number, targetGUID: string, atTime: number): [number, string] {
        this.StartProfiling("OvaleFuture_GetAuraFinish");
        let auraId, auraGUID;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.aura) {
            for (const [, unitId] of ipairs(SPELLCAST_AURA_ORDER)) {
                for (const [, auraList] of pairs(si.aura[unitId])) {
                    for (const [id, spellData] of pairs(auraList)) {
                        let [verified, value, ] = OvaleData.CheckSpellAuraData(id, spellData, atTime, targetGUID);
                        if (verified && (SPELLAURALIST_AURA_VALUE[<string>value] || type(value) == "number" && value > 0)) {
                            auraId = id;
                            auraGUID = OvaleGUID.UnitGUID(unitId);
                            break;
                        }
                    }
                    if (auraId) {
                        break;
                    }
                }
                if (auraId) {
                    break;
                }
            }
        }
        this.StopProfiling("OvaleFuture_GetAuraFinish");
        return [auraId, auraGUID];
    }
    
    SaveSpellcastInfo(spellcast: SpellCast, atTime: number) {
        this.StartProfiling("OvaleFuture_SaveSpellcastInfo");
        this.Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName);
        if (spellcast.spellId) {
            spellcast.damageMultiplier = this.GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime);
        }
        for (const [, mod] of pairs(lastSpell.modules)) {
            let func = mod.SaveSpellcastInfo;
            if (func) {
                func(mod, spellcast, atTime);
            }
        }
        this.StopProfiling("OvaleFuture_SaveSpellcastInfo");
    }
    GetDamageMultiplier(spellId: number, targetGUID: string, atTime: number) {
        let damageMultiplier = 1;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.aura && si.aura.damage) {
            for (const [filter, auraList] of pairs(si.aura.damage)) {
                for (const [auraId, spellData] of pairs(auraList)) {
                    let index, multiplier: number;
                    let verified;
                    if (isLuaArray(spellData)) {
                        multiplier = <number>spellData[1];
                        index = 2;
                        verified = CheckRequirements(spellId, atTime, spellData, index, targetGUID);
                    } else {
                        multiplier = spellData;
                        verified = true;
                    }
                    if (verified) {
                        let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, auraId, filter, false, atTime);
                        let isActiveAura = OvaleAura.IsActiveAura(aura, atTime);
                        if (isActiveAura) {
                            let siAura = OvaleData.spellInfo[auraId];
                            if (siAura && siAura.stacking && siAura.stacking > 0) {
                                multiplier = 1 + (multiplier - 1) * aura.stacks;
                            }
                            damageMultiplier = damageMultiplier * multiplier;
                        }
                    }
                }
            }
        }
        return damageMultiplier;
    }
    UpdateCounters(spellId: number, atTime: number, targetGUID: string) {
        return this.GetState(atTime).UpdateCounters(spellId, atTime, targetGUID);
    }
    
    IsActive(spellId: number) {
        for (const [, spellcast] of ipairs(lastSpell.queue)) {
            if (spellcast.spellId == spellId && spellcast.start) {
                return true;
            }
        }
        return false;
    }

    InFlight(spellId: number) {
        return this.IsActive(spellId);
    }
    
    UpdateLastSpellcast(atTime: number, spellcast: SpellCast) {
        this.StartProfiling("OvaleFuture_UpdateLastSpellcast");
        this.current.lastCastTime[spellcast.spellId] = atTime;
        if (spellcast.offgcd) {
            this.Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId);
            for (const [k, v] of pairs(spellcast)) {
                this.current.lastOffGCDSpellcast[k] = v;
            }
            lastSpell.lastSpellcast = this.current.lastOffGCDSpellcast;
        } else {
            this.Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId);
            for (const [k, v] of pairs(spellcast)) {
                lastSpell.lastGCDSpellcast[k] = v;
            }
            lastSpell.lastSpellcast = lastSpell.lastGCDSpellcast;
        }
        this.StopProfiling("OvaleFuture_UpdateLastSpellcast");
    }
    UpdateSpellcastSnapshot(spellcast: SpellCast, atTime: number) {
        if (spellcast.queued && (!spellcast.snapshotTime || (spellcast.snapshotTime < atTime && atTime < spellcast.stop + 1))) {
            if (spellcast.targetName) {
                this.Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued);
            } else {
                this.Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued);
            }
            // TODO strange, why current?
            OvalePaperDoll.UpdateSnapshot(spellcast, OvalePaperDoll.current, true);
            if (spellcast.spellId) {
                spellcast.damageMultiplier = this.GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime);
                if (spellcast.damageMultiplier != 1) {
                    this.Debug("        persistent multiplier = %f", spellcast.damageMultiplier);
                }
            }
        }
    }
    
    GetCounter(id: number, atTime: number) {
        return this.GetState(atTime).counter[id] || 0;
    }
    
    TimeOfLastCast(spellId: number, atTime: number) {
        if (!atTime) return this.current.lastCastTime[spellId];
        return this.next.lastCastTime[spellId] || this.current.lastCastTime[spellId] || 0;
    }
    
    IsChanneling(atTime: number) {
        return this.GetState(atTime).IsChanneling(atTime);
    }

    GetCurrentCast(atTime: number) {
        if (atTime && this.next.currentCast && this.next.currentCast.start <= atTime && this.next.currentCast.stop >= atTime) {
            return this.next.currentCast;
        }

        for (const [, value] of ipairs(lastSpell.queue)) {
            if (value.start && value.start <= atTime && (!value.stop || value.stop >= atTime)) {
                return value;
            }
        }
    }

    GetGCD(spellId?: number, atTime?: number, targetGUID?: string) {
        spellId = spellId || this.next.currentCast.spellId;
        if (!atTime) {
            if (this.next.currentCast.stop && this.next.currentCast.stop > baseState.next.currentTime) {
                atTime = this.next.currentCast.stop;
            } else {
                atTime = baseState.next.currentTime || baseState.current.currentTime;
            }
        }
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.next.defaultTarget);
        let gcd = spellId && <number>OvaleData.GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID);
        if (!gcd) {
            let haste;
            [gcd, haste] = OvaleCooldown.GetBaseGCD();
            if (Ovale.playerClass == "MONK" && OvalePaperDoll.IsSpecialization("mistweaver")) {
                gcd = 1.5;
                haste = "spell";
            } else if (Ovale.playerClass == "DRUID") {
                if (OvaleStance.IsStance("druid_cat_form", atTime)) {
                    gcd = 1.0;
                    haste = false;
                }
            }
            let gcdHaste = spellId && OvaleData.GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID);
            if (gcdHaste) {
                haste = gcdHaste;
            } else {
                let siHaste = spellId && OvaleData.GetSpellInfoProperty(spellId, atTime, "haste", targetGUID);
                if (siHaste) {
                    haste = siHaste;
                }
            }
            let multiplier = OvalePaperDoll.GetHasteMultiplier(haste, OvalePaperDoll.next);
            gcd = gcd / multiplier;
            gcd = (gcd > 0.750) && gcd || 0.750;
        }
        return gcd;
    }

    InitializeState() {
        this.next.lastCast = {}
        this.next.counter = {}
    }
    ResetState() {
        OvaleFuture.StartProfiling("OvaleFuture_ResetState");
        const now = baseState.next.currentTime;
        this.Log("Reset state with current time = %f", now);
        this.next.nextCast = now;
        wipe(this.next.lastCast);
        wipe(OvaleFutureClass.staticSpellcast);
        this.next.currentCast = OvaleFutureClass.staticSpellcast;
        let reason = "";
        let [start, duration] = OvaleCooldown.GetGlobalCooldown(now);
        if (start && start > 0) {
            let ending = start + duration;
            if (this.next.nextCast < ending) {
                this.next.nextCast = ending;
                reason = " (waiting for GCD)";
            }
        }
        let lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound;
        for (let i = lualength(lastSpell.queue); i >= 1; i += -1) {
            let spellcast = lastSpell.queue[i];
            if (spellcast.spellId && spellcast.start) {
                OvaleFuture.Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop);
                if (!lastSpellcastFound) {
                    // this.next.lastCast = spellcast;
                    if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                        this.next.currentCast = spellcast
                    }
                    lastSpellcastFound = true;
                }
                if (!lastGCDSpellcastFound && !spellcast.offgcd) {
                    this.next.PushGCDSpellId(spellcast.spellId);
                    if (spellcast.stop && this.next.nextCast < spellcast.stop) {
                        this.next.nextCast = spellcast.stop;
                        reason = " (waiting for spellcast)";
                    }
                    lastGCDSpellcastFound = true;
                }
                if (!lastOffGCDSpellcastFound && spellcast.offgcd) {
                    this.next.lastOffGCDSpellcast = spellcast;
                    lastOffGCDSpellcastFound = true;
                }
            }
            if (lastGCDSpellcastFound && lastOffGCDSpellcastFound && lastSpellcastFound) {
                break;
            }
        }
        if (!lastSpellcastFound) {
            let spellcast = lastSpell.lastSpellcast;
            if (spellcast) {
                // this.next.lastCast = spellcast;
                if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                    this.next.currentCast = spellcast;
                }
            }
        }
        if (!lastGCDSpellcastFound) {
            let spellcast = lastSpell.lastGCDSpellcast;
            if (spellcast) {
                this.next.lastGCDSpellcast = spellcast;
                if (spellcast.stop && this.next.nextCast < spellcast.stop) {
                    this.next.nextCast = spellcast.stop;
                    reason = " (waiting for spellcast)";
                }
            }
        }
        if (!lastOffGCDSpellcastFound) {
            this.next.lastOffGCDSpellcast = this.current.lastOffGCDSpellcast;
        }
        // OvaleFuture.Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", this.next.lastSpellId, this.lastGCDSpellId, this.lastOffGCDSpellId);
        OvaleFuture.Log("    nextCast = %f%s", this.next.nextCast, reason);
        for (const [k, v] of pairs(this.current.counter)) {
            this.next.counter[k] = v;
        }
        OvaleFuture.StopProfiling("OvaleFuture_ResetState");
    }
    CleanState() {
        for (const [k] of pairs(this.next.lastCast)) {
            this.next.lastCast[k] = undefined;
        }
        for (const [k] of pairs(this.next.counter)) {
            this.next.counter[k] = undefined;
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        OvaleFuture.StartProfiling("OvaleFuture_ApplySpellStartCast");
        if (channel) {
            OvaleFuture.UpdateCounters(spellId, startCast, targetGUID);
        }
        OvaleFuture.StopProfiling("OvaleFuture_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        OvaleFuture.StartProfiling("OvaleFuture_ApplySpellAfterCast");
        if (!channel) {
            OvaleFuture.UpdateCounters(spellId, endCast, targetGUID);
        }
        OvaleFuture.StopProfiling("OvaleFuture_ApplySpellAfterCast");
    }

    static staticSpellcast = {}

    
    ApplySpell(spellId:number, targetGUID:string, startCast:number, endCast?:number, channel?: boolean, spellcast?: SpellCast) {
        OvaleFuture.StartProfiling("OvaleFuture_state_ApplySpell");
        if (spellId) {
            if (!targetGUID) {
                targetGUID = Ovale.playerGUID;
            }
            let castTime;
            if (startCast && endCast) {
                castTime = endCast - startCast;
            } else {
                castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
                startCast = startCast || this.next.nextCast;
                endCast = endCast || (startCast + castTime);
            }
            if (!spellcast) {
                spellcast = OvaleFutureClass.staticSpellcast;
                wipe(spellcast);
                spellcast.caster = Ovale.playerGUID;
                spellcast.spellId = spellId;
                spellcast.spellName = OvaleSpellBook.GetSpellName(spellId);
                spellcast.target = targetGUID;
                spellcast.targetName = OvaleGUID.GUIDName(targetGUID);
                spellcast.start = startCast;
                spellcast.stop = endCast;
                spellcast.channel = channel;
                OvalePaperDoll.UpdateSnapshot(spellcast, OvalePaperDoll.next);
                let atTime = channel && startCast || endCast;
                for (const [, mod] of pairs(lastSpell.modules)) {
                    let func = mod.SaveSpellcastInfo;
                    if (func) {
                        func(mod, spellcast, atTime, OvalePaperDoll.next);
                    }
                }
            }
            // this.next.lastCast = this.next.currentCast;
            this.next.currentCast = spellcast;
            this.next.lastCast[spellId] = endCast;
            let gcd = OvaleFuture.GetGCD(spellId, startCast, targetGUID);
            let nextCast = (castTime > gcd) && endCast || (startCast + gcd);
            if (this.next.nextCast < nextCast) {
                this.next.nextCast = nextCast;
            }
            if (gcd > 0) {
                this.next.PushGCDSpellId(spellId);
            } else {
                this.next.lastOffGCDSpellcast = this.next.currentCast;
            }
            // let now = GetTime();
            // if (startCast >= now) {
            //     baseState.next.currentTime = startCast + SIMULATOR_LAG;
            // } else {
            //     baseState.next.currentTime = now;
            // }
            OvaleFuture.Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, baseState.next.currentTime, nextCast, endCast, targetGUID);
            if (!baseState.next.inCombat && OvaleSpellBook.IsHarmfulSpell(spellId)) {
                baseState.next.inCombat = true;
                if (channel) {
                    baseState.next.combatStartTime = startCast;
                } else {
                    baseState.next.combatStartTime = endCast;
                }
            }
            if (startCast > baseState.next.currentTime) {
                OvaleState.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            if (endCast > baseState.next.currentTime) {
                OvaleState.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            OvaleState.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast);
        }
        OvaleFuture.StopProfiling("OvaleFuture_state_ApplySpell");
    }

    
    ApplyInFlightSpells() {
        this.StartProfiling("OvaleFuture_ApplyInFlightSpells");
        let now = GetTime();
        let index = 1;
        while (index <= lualength(lastSpell.queue)) {
            let spellcast = lastSpell.queue[index];
            if (spellcast.stop) {
                let isValid = false;
                let description;
                if (now < spellcast.stop) {
                    isValid = true;
                    description = spellcast.channel && "channelling" || "being cast";
                } else if (now < spellcast.stop + 5) {
                    isValid = true;
                    description = "in flight";
                }
                if (isValid) {
                    if (spellcast.target) {
                        OvaleState.Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop);
                    } else {
                        OvaleState.Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop);
                    }
                    this.ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast);
                } else {
                    if (spellcast.target) {
                        this.Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target);
                    } else {
                        this.Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId);
                    }
                    remove(lastSpell.queue, index);
                    self_pool.Release(spellcast);
                    index = index - 1;
                }
            }
            index = index + 1;
        }
        this.StopProfiling("OvaleFuture_ApplyInFlightSpells");
    }
}

export const OvaleFuture = new OvaleFutureClass();