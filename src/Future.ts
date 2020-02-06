import { OvaleAuraClass } from "./Aura";
import { OvaleDataClass } from "./Data";
import { OvaleGUIDClass } from "./GUID";
import { OvalePaperDollClass, HasteType } from "./PaperDoll";
import { LastSpell, SpellCast, self_pool, createSpellCast } from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, pairs, type, lualength, LuaObj, LuaArray, wipe, kpairs, tonumber } from "@wowts/lua";
import { sub } from "@wowts/string";
import { insert, remove } from "@wowts/table";
import { GetSpellInfo, GetTime, UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID, UnitName, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { OvaleStateClass, States } from "./State";
import { OvaleCooldownClass } from "./Cooldown";
import { BaseState } from "./BaseState";
import { isLuaArray } from "./tools";
import { Tokens, OvaleRequirement } from "./Requirement";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { Tracer, OvaleDebugClass } from "./Debug";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { OvaleStanceClass } from "./Stance";
import { OvaleSpellBookClass } from "./SpellBook";

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
let SPELLCAST_AURA_ORDER: LuaArray<"target" | "pet"> = {
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

export class OvaleFutureData {
    inCombat: boolean = false;
    combatStartTime: number = 0;  
    lastCastTime: LuaObj<number> = {}
    lastOffGCDSpellcast: SpellCast = createSpellCast();
    lastGCDSpellcast: SpellCast = createSpellCast();
    lastGCDSpellIds: LuaArray<number> = {}
    lastGCDSpellId: number = 0;
    counter: LuaArray<number> = {}
    lastCast: LuaObj<number> = {};
    currentCast: SpellCast = createSpellCast();
    nextCast: number = 0;
   
    PushGCDSpellId(spellId: number) {
        if (this.lastGCDSpellId) {
            insert(this.lastGCDSpellIds, this.lastGCDSpellId);
            if (lualength(this.lastGCDSpellIds) > 5) {
                remove(this.lastGCDSpellIds, 1);
            }
        }
        this.lastGCDSpellId = spellId;
    }
    
    GetCounter (id: number) {
        return this.counter[id] || 0;
    }
    IsChanneling(atTime: number) {
        return this.currentCast.channel && (atTime < this.currentCast.stop);
    }
}

export class OvaleFutureClass extends States<OvaleFutureData> {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;
    constructor(
        private ovaleData: OvaleDataClass,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private baseState: BaseState,
        private ovaleCooldown: OvaleCooldownClass,
        private ovaleState: OvaleStateClass,
        private ovaleGuid: OvaleGUIDClass,
        private lastSpell: LastSpell,
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleStance: OvaleStanceClass,
        private requirement: OvaleRequirement,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        super(OvaleFutureData);
        const name = "OvaleFuture";
        this.tracer = ovaleDebug.create(name);
        this.profiler = ovaleProfiler.create(name);
        this.module = ovale.createModule(name, this.OnInitialize, this.OnDisable, aceEvent)
    }

    
    UpdateStateCounters(state: OvaleFutureData, spellId: number, atTime: number, targetGUID: string) {
        let inccounter = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID);
        if (inccounter) {
            let value = state.counter[inccounter] && state.counter[inccounter] || 0;
            state.counter[inccounter] = value + 1;
        }
        let resetcounter = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID);
        if (resetcounter) {
            state.counter[resetcounter] = 0;
        }
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.PLAYER_ENTERING_WORLD);
        this.module.RegisterEvent("PLAYER_REGEN_DISABLED", this.PLAYER_REGEN_DISABLED);
        this.module.RegisterEvent("PLAYER_REGEN_ENABLED", this.PLAYER_REGEN_ENABLED);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", this.UNIT_SPELLCAST_CHANNEL_START);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", this.UNIT_SPELLCAST_CHANNEL_STOP);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", this.UNIT_SPELLCAST_CHANNEL_UPDATE);
        this.module.RegisterEvent("UNIT_SPELLCAST_DELAYED", this.UNIT_SPELLCAST_DELAYED);
        this.module.RegisterEvent("UNIT_SPELLCAST_FAILED", this.UnitSpellcastEnded);
        this.module.RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", this.UnitSpellcastEnded);
        this.module.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", this.UnitSpellcastEnded);
        this.module.RegisterEvent("UNIT_SPELLCAST_SENT", this.UNIT_SPELLCAST_SENT);
        this.module.RegisterEvent("UNIT_SPELLCAST_START", this.UNIT_SPELLCAST_START);
        this.module.RegisterEvent("UNIT_SPELLCAST_STOP", this.UnitSpellcastEnded);
        this.module.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", this.UNIT_SPELLCAST_SUCCEEDED);
        this.module.RegisterMessage("Ovale_AuraAdded", this.Ovale_AuraAdded);
        this.module.RegisterMessage("Ovale_AuraChanged", this.Ovale_AuraChanged);
        this.requirement.RegisterRequirement("combat", this.CombatRequirement);
    }

    private OnDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.module.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.module.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
        this.module.UnregisterEvent("UNIT_SPELLCAST_DELAYED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_FAILED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
        this.module.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_SENT");
        this.module.UnregisterEvent("UNIT_SPELLCAST_START");
        this.module.UnregisterEvent("UNIT_SPELLCAST_STOP");
        this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.module.UnregisterMessage("Ovale_AuraAdded");
        this.module.UnregisterMessage("Ovale_AuraChanged");
        this.requirement.UnregisterRequirement("combat");
    }
    
    IsInCombat(atTime: number | undefined) {
        return this.GetState(atTime).inCombat;
    }
    
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        this.tracer.DebugTimestamp("COMBAT_LOG_EVENT_UNFILTERED", CombatLogGetCurrentEventInfo())
        let [, cleuEvent, , sourceGUID, sourceName, , , destGUID, destName, , , spellId, spellName, , , , , , , , , , , isOffHand] = CombatLogGetCurrentEventInfo();
        if (sourceGUID == this.ovale.playerGUID || this.ovaleGuid.IsPlayerPet(sourceGUID)) {
            this.profiler.StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED");
            if (CLEU_SPELLCAST_EVENT[cleuEvent]) {
                let now = GetTime();
                if (strsub(cleuEvent, 1, 11) == "SPELL_CAST_" && (destName && destName != "")) {
                    this.tracer.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
                    let [spellcast] = this.GetSpellcast(spellName, spellId, undefined, now);
                    if (spellcast && spellcast.targetName && spellcast.targetName == destName && spellcast.target != destGUID) {
                        this.tracer.Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID);
                        spellcast.target = destGUID;
                    }
                }
                this.tracer.DebugTimestamp("CLUE", cleuEvent);
                let finish: "hit" | "miss" | undefined = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent];
                if (cleuEvent == "SPELL_DAMAGE" || cleuEvent == "SPELL_HEAL") {
                    if (isOffHand) {
                        finish = undefined;
                    }
                }
                if (finish) {
                    let anyFinished = false;
                    for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
                        let spellcast = this.lastSpell.queue[i];
                        if (spellcast.success && (spellcast.spellId == spellId || spellcast.auraId == spellId)) {
                            if (this.FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, finish, i)) {
                                anyFinished = true;
                            }
                        }
                    }
                    if (!anyFinished) {
                        this.tracer.Debug("Found no spell to finish for %s (%d)", spellName, spellId);
                        for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
                            let spellcast = this.lastSpell.queue[i];
                            if (spellcast.success && (spellcast.spellName == spellName)) {
                                if (this.FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, finish, i)) {
                                    anyFinished = true;
                                }
                            }
                        }
                        if (!anyFinished) {
                            this.tracer.Debug("No spell found for %s", spellName, spellId);
                        }
                    }
                }
            }
            this.profiler.StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    FinishSpell(spellcast: SpellCast, cleuEvent: string, sourceName: string, sourceGUID: string, destName: string, destGUID: string, spellId: number, spellName: string, finish: "hit"|"miss", i: number) {
        let finished = false;
        if (!spellcast.auraId) {
            this.tracer.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
            if (!spellcast.channel) {
                this.tracer.Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent);
                finished = true;
            }
        } else if (CLEU_AURA_EVENT[cleuEvent] && spellcast.auraGUID && destGUID == spellcast.auraGUID) {
            this.tracer.DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName);
            this.tracer.Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID);
            finished = true;
        } else if (cleuEvent == "Ovale_AuraChanged" && spellcast.auraGUID && destGUID == spellcast.auraGUID) {
            this.tracer.Debug("Finished (%s) spell %s (%d) queued at %s after Ovale_AuraChanged was called for aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID);
            finished = true;
        }
        if (finished) {
            let now = GetTime();
            if (self_timeAuraAdded) {
                if (IsSameSpellcast(spellcast, this.lastSpell.lastGCDSpellcast)) {
                    this.UpdateSpellcastSnapshot(this.lastSpell.lastGCDSpellcast, self_timeAuraAdded);
                }
                if (IsSameSpellcast(spellcast, this.current.lastOffGCDSpellcast)) {
                    this.UpdateSpellcastSnapshot(this.current.lastOffGCDSpellcast, self_timeAuraAdded);
                }
            }
            let delta = now - spellcast.stop;
            let targetGUID = spellcast.target;
            this.tracer.Debug("Spell %s (%d) was in flight for %f seconds.", spellName, spellId, delta);
            tremove(this.lastSpell.queue, i);
            self_pool.Release(spellcast);
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish);
        }
        return finished;
    }
    private PLAYER_ENTERING_WORLD = (event: string) => {
        this.profiler.StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
        this.tracer.Debug(event);
        this.profiler.StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
    }
    private PLAYER_REGEN_DISABLED = (event: string) => {
        this.profiler.StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
        this.tracer.Debug(event, "Entering combat.");
        let now = GetTime();
        this.current.inCombat = true;
        this.current.combatStartTime = now;
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_CombatStarted", now);
        this.profiler.StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
    }
    private PLAYER_REGEN_ENABLED = (event: string) => {
        this.profiler.StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
        this.tracer.Debug(event, "Leaving combat.");
        let now = GetTime();
        this.current.inCombat = false;
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_CombatEnded", now);
        this.profiler.StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
    }
    private UNIT_SPELLCAST_CHANNEL_START = (event: string, unitId: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START");
            this.tracer.DebugTimestamp(event, unitId, spell, lineId, spellId);
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
                    this.tracer.Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime);
                    this.SaveSpellcastInfo(spellcast, now);
                    this.UpdateLastSpellcast(now, spellcast);
                    this.UpdateCounters(spellId, spellcast.start, spellcast.target);
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.Debug("Warning: not channelling a spell.");
                } else {
                    this.tracer.Debug("Warning: channelling unexpected spell %s", name);
                }
            } else {
                this.tracer.Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START");
        }
    }
    private UNIT_SPELLCAST_CHANNEL_STOP = (event: string, unitId: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP");
            this.tracer.DebugTimestamp(event, unitId, spell, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast && spellcast.channel) {
                this.tracer.Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued);
                spellcast.stop = now;
                this.UpdateLastSpellcast(now, spellcast);
                let targetGUID = spellcast.target;
                tremove(this.lastSpell.queue, index);
                self_pool.Release(spellcast);
                this.ovale.needRefresh();
                this.module.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit");
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP");
        }
    }
    private UNIT_SPELLCAST_CHANNEL_UPDATE = (event: string, unitId: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE");
            this.tracer.DebugTimestamp(event, unitId, spell, lineId, spellId);
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
                    this.tracer.Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta);
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.Debug("Warning: not channelling a spell.");
                } else {
                    this.tracer.Debug("Warning: delaying unexpected channelled spell %s.", name);
                }
            } else {
                this.tracer.Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE");
        }
    }
    private UNIT_SPELLCAST_DELAYED = (event: string, unitId: string, lineId: string, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED");
            this.tracer.DebugTimestamp(event, unitId, spell, lineId, spellId);
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
                    this.tracer.Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta);
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.Debug("Warning: not casting a spell.");
                } else {
                    this.tracer.Debug("Warning: delaying unexpected spell %s.", name);
                }
            } else {
                this.tracer.Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED");
        }
    }
    private UNIT_SPELLCAST_SENT = (event: string, unitId: string, targetName: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT");
            this.tracer.DebugTimestamp(event, unitId, spell, targetName, lineId);
            let now = GetTime();
            let caster = this.ovaleGuid.UnitGUID(unitId);
            let spellcast = self_pool.Get();
            spellcast.lineId = lineId;
            spellcast.caster = caster;
            spellcast.spellName = spell || "Unknown spell";
            spellcast.queued = now;
            insert(this.lastSpell.queue, spellcast);
            if (targetName == "") {
                this.tracer.Debug("Queueing (%d) spell %s with no target.", lualength(this.lastSpell.queue), spell);
            } else {
                spellcast.targetName = targetName;
                let [targetGUID, nextGUID] = this.ovaleGuid.NameGUID(targetName);
                if (nextGUID) {
                    let name = this.ovaleGuid.UnitName("target");
                    if (name == targetName) {
                        targetGUID = this.ovaleGuid.UnitGUID("target");
                    } else {
                        name = this.ovaleGuid.UnitName("focus");
                        if (name == targetName) {
                            targetGUID = this.ovaleGuid.UnitGUID("focus");
                        } else if (UnitExists("mouseover")) {
                            name = UnitName("mouseover");
                            if (name == targetName) {
                                targetGUID = UnitGUID("mouseover");
                            }
                        }
                    }
                    spellcast.target = targetGUID || "unknown";
                    this.tracer.Debug("Queueing (%d) spell %s to %s (possibly %s).", lualength(this.lastSpell.queue), spell, targetName, targetGUID);
                } else {
                    spellcast.target = targetGUID || "unknown";
                    this.tracer.Debug("Queueing (%d) spell %s to %s (%s).", lualength(this.lastSpell.queue), spell, targetName, targetGUID);
                }
            }
            this.SaveSpellcastInfo(spellcast, now);
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT");
        }
    }
    private UNIT_SPELLCAST_START = (event: string, unitId: string, lineId: string, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spellName = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_START");
            this.tracer.DebugTimestamp(event, unitId, spellName, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spellName, spellId, lineId, now);
            if (spellcast) {
                let [name, , , startTime, endTime, , castId] = UnitCastingInfo(unitId);
                if (lineId == castId && name == spellName) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    spellcast.spellId = spellId;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    spellcast.channel = false;
                    let delta = now - spellcast.queued;
                    this.tracer.Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spellName, spellId, startTime, delta, endTime);
                    let [auraId, auraGUID] = this.GetAuraFinish(spellId, spellcast.target, now);
                    if (auraId && auraGUID) {
                        spellcast.auraId = auraId;
                        spellcast.auraGUID = auraGUID;
                        this.tracer.Debug("Spell %s (%d) will finish after updating aura %d on %s.", spellName, spellId, auraId, auraGUID);
                    }
                    this.SaveSpellcastInfo(spellcast, now);
                    this.UpdateLastSpellcast(now, spellcast);
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.Debug("Warning: not casting a spell.");
                } else {
                    this.tracer.Debug("Warning: casting unexpected spell %s.", name);
                }
            } else {
                this.tracer.Debug("Warning: casting spell %s (%d) without previous sent data.", spellName, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_START");
        }
    }
    private UNIT_SPELLCAST_SUCCEEDED = (event: string, unitId: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            let spell = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED");
            this.tracer.DebugTimestamp(event, unitId, spell, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let success = false;
                if (!spellcast.success && spellcast.start && spellcast.stop && !spellcast.channel) {
                    this.tracer.Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop);
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
                        this.tracer.Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta);
                        let [auraId, auraGUID] = this.GetAuraFinish(spellId, spellcast.target, now);
                        if (auraId && auraGUID) {
                            spellcast.auraId = auraId;
                            spellcast.auraGUID = auraGUID;
                            this.tracer.Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID);
                        }
                        this.SaveSpellcastInfo(spellcast, now);
                        success = true;
                    } else {
                        this.tracer.Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId);
                    }
                }
                if (success) {
                    let targetGUID = spellcast.target;
                    this.UpdateLastSpellcast(now, spellcast);
                    this.next.PushGCDSpellId(spellcast.spellId);
                    this.UpdateCounters(spellId, spellcast.stop, targetGUID);
                    let finished = false;
                    let finish = "miss";
                    if (!spellcast.targetName) {
                        this.tracer.Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued);
                        finished = true;
                        finish = "hit";
                    } else if (targetGUID == this.ovale.playerGUID && this.ovaleSpellBook.IsHelpfulSpell(spellId)) {
                        this.tracer.Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued);
                        finished = true;
                        finish = "hit";
                    }
                    if (finished) {
                        tremove(this.lastSpell.queue, index);
                        self_pool.Release(spellcast);
                        this.ovale.needRefresh();
                        this.module.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish);
                    }
                }
            } else {
                this.tracer.Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED");
        }
    }
    private Ovale_AuraAdded = (event: string, atTime: number, guid: string, auraId: string, caster: string) => {
        if (guid == this.ovale.playerGUID) {
            self_timeAuraAdded = atTime;
            this.UpdateSpellcastSnapshot(this.lastSpell.lastGCDSpellcast, atTime);
            this.UpdateSpellcastSnapshot(this.current.lastOffGCDSpellcast, atTime);
        }
    }
    private Ovale_AuraChanged = (event: string, atTime: number, guid: string, auraId: string, caster: string) => {
        this.tracer.DebugTimestamp("Ovale_AuraChanged", event, atTime, guid, auraId, caster);
        if (caster == this.ovale.playerGUID) {
            // let's check if the aura matches a spell we have in flight, if so we can end it
            let anyFinished = false;
            for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
                let spellcast = this.lastSpell.queue[i];
                if (spellcast.success && (spellcast.auraId == auraId)) {
                    if (this.FinishSpell(spellcast, "Ovale_AuraChanged", caster, this.ovale.playerGUID, spellcast.targetName, guid, spellcast.spellId, spellcast.spellName, "hit", i)) {
                        anyFinished = true;
                    }
                }
            }
            if (!anyFinished) {
                this.tracer.Debug("No spell found to finish for auraId %d", auraId);
            }
        }
    }
    private UnitSpellcastEnded = (event: string, unitId: string, lineId: number, spellId: number) => {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            if(event == 'UNIT_SPELLCAST_INTERRUPTED'){
                this.next.lastGCDSpellId = 0;
            }
            let spellName = this.ovaleSpellBook.GetSpellName(spellId);
            this.profiler.StartProfiling("OvaleFuture_UnitSpellcastEnded");
            this.tracer.DebugTimestamp(event, unitId, spellName, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spellName, spellId, lineId, now);
            if (spellcast) {
                this.tracer.Debug("End casting spell %s (%d) queued at %s due to %s.", spellName, spellId, spellcast.queued, event);
                if (!spellcast.success) {
                    this.tracer.Debug("Remove spell from queue because there was no success before");
                    tremove(this.lastSpell.queue, index);
                    self_pool.Release(spellcast);
                    this.ovale.needRefresh();
                }
            } else if (lineId) {
                this.tracer.Debug("Warning: no queued spell %s (%d) found to end casting.", spellName, spellId);
            }
            this.profiler.StopProfiling("OvaleFuture_UnitSpellcastEnded");
        }
    }
    GetSpellcast(spellName: string | undefined, spellId: number, lineId: number | undefined | string, atTime: number):[SpellCast | undefined, number] {
        this.profiler.StartProfiling("OvaleFuture_GetSpellcast");
        let spellcast: SpellCast | undefined = undefined;
        let index: number = 0;
        if (!lineId || lineId != "") {
            for (const [i, sc] of ipairs(this.lastSpell.queue)) {
                if (!lineId || sc.lineId == lineId) {
                    if (spellId && sc.spellId == spellId) {
                        spellcast = sc;
                        index = i;
                        break;
                    } else if (spellName) {
                        let spellName = sc.spellName || this.ovaleSpellBook.GetSpellName(spellId);
                        if (spellName == spellName) {
                            spellcast = sc;
                            index = i;
                            break;
                        }
                    }
                }
            }
        }
        if (spellcast) {
            spellName = spellName || spellcast.spellName || this.ovaleSpellBook.GetSpellName(spellId);
            if (spellcast.targetName) {
                this.tracer.Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued);
            } else {
                this.tracer.Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued);
            }
        }
        this.profiler.StopProfiling("OvaleFuture_GetSpellcast");
        return [spellcast, index];
    }
    GetAuraFinish(spellId: number, targetGUID: string, atTime: number): [string|number|undefined, string|undefined] {
        this.profiler.StartProfiling("OvaleFuture_GetAuraFinish");
        let auraId, auraGUID;
        let si = this.ovaleData.spellInfo[spellId];
        if (si && si.aura) {
            for (const [, unitId] of ipairs(SPELLCAST_AURA_ORDER)) {
                for (const [, auraList] of kpairs(si.aura[unitId])) {
                    for (const [id, spellData] of kpairs(auraList)) {
                        let [verified, value, ] = this.ovaleData.CheckSpellAuraData(id, spellData, atTime, targetGUID);
                        if (verified && (SPELLAURALIST_AURA_VALUE[<string>value] || type(value) == "number" && value > 0)) {
                            auraId = id;
                            auraGUID = this.ovaleGuid.UnitGUID(unitId);
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
        this.profiler.StopProfiling("OvaleFuture_GetAuraFinish");
        return [auraId, auraGUID];
    }
    
    SaveSpellcastInfo(spellcast: SpellCast, atTime: number) {
        this.profiler.StartProfiling("OvaleFuture_SaveSpellcastInfo");
        this.tracer.Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName);
        if (spellcast.spellId) {
            spellcast.damageMultiplier = this.GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime);
        }
        for (const [, mod] of pairs(this.lastSpell.modules)) {
            let func = mod.SaveSpellcastInfo;
            if (func) {
                func(spellcast, atTime);
            }
        }
        this.profiler.StopProfiling("OvaleFuture_SaveSpellcastInfo");
    }
    GetDamageMultiplier(spellId: number, targetGUID: string, atTime: number) {
        let damageMultiplier = 1;
        let si = this.ovaleData.spellInfo[spellId];
        if (si && si.aura && si.aura.damage) {
            for (const [filter, auraList] of kpairs(si.aura.damage)) {
                for (const [auraId, spellData] of pairs(auraList)) {
                    let index, multiplier: number;
                    let verified;
                    if (isLuaArray(spellData)) {
                        multiplier = <number>spellData[1];
                        index = 2;
                        verified = this.requirement.CheckRequirements(spellId, atTime, spellData, index, targetGUID);
                    } else {
                        multiplier = spellData;
                        verified = true;
                    }
                    if (verified) {
                        let aura = this.ovaleAura.GetAuraByGUID(this.ovale.playerGUID, auraId, filter, false, atTime);
                        if (aura && this.ovaleAura.IsActiveAura(aura, atTime)) {
                            let siAura = this.ovaleData.spellInfo[auraId];
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
        return this.UpdateStateCounters(this.GetState(atTime), spellId, atTime, targetGUID);
    }
    
    IsActive(spellId: number) {
        for (const [, spellcast] of ipairs(this.lastSpell.queue)) {
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
        this.profiler.StartProfiling("OvaleFuture_UpdateLastSpellcast");
        this.current.lastCastTime[spellcast.spellId] = atTime;
        if (spellcast.offgcd) {
            this.tracer.Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId);
            for (const [k, v] of kpairs(spellcast)) {
                (<any>this.current.lastOffGCDSpellcast)[k] = v;
            }
            this.lastSpell.lastSpellcast = this.current.lastOffGCDSpellcast;
            this.next.lastOffGCDSpellcast = this.current.lastOffGCDSpellcast
        } else {
            this.tracer.Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId);
            for (const [k, v] of kpairs(spellcast)) {
                (<any>this.lastSpell.lastGCDSpellcast)[k] = v;
            }
            this.lastSpell.lastSpellcast = this.lastSpell.lastGCDSpellcast;
            this.next.lastGCDSpellId = this.lastSpell.lastGCDSpellcast.spellId
        }
        this.profiler.StopProfiling("OvaleFuture_UpdateLastSpellcast");
    }
    UpdateSpellcastSnapshot(spellcast: SpellCast, atTime: number) {
        if (spellcast.queued && (!spellcast.snapshotTime || (spellcast.snapshotTime < atTime && atTime < spellcast.stop + 1))) {
            if (spellcast.targetName) {
                this.tracer.Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued);
            } else {
                this.tracer.Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued);
            }
            // TODO strange, why current?
            this.ovalePaperDoll.UpdateSnapshot(spellcast, this.ovalePaperDoll.current, true);
            if (spellcast.spellId) {
                spellcast.damageMultiplier = this.GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime);
                if (spellcast.damageMultiplier != 1) {
                    this.tracer.Debug("        persistent multiplier = %f", spellcast.damageMultiplier);
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

        for (const [, value] of ipairs(this.lastSpell.queue)) {
            if (value.start && value.start <= atTime && (!value.stop || value.stop >= atTime)) {
                return value;
            }
        }
    }

    GetGCD(spellId?: number, atTime?: number, targetGUID?: string) {
        spellId = spellId || this.next.currentCast.spellId;
        if (!atTime) {
            if (this.next.currentCast.stop && this.next.currentCast.stop > this.baseState.next.currentTime) {
                atTime = this.next.currentCast.stop;
            } else {
                atTime = this.baseState.next.currentTime || this.baseState.current.currentTime;
            }
        }
        targetGUID = targetGUID || this.ovaleGuid.UnitGUID(this.baseState.next.defaultTarget);
        let gcd = spellId && this.ovaleData.GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID);
        if (!gcd) {
            let haste: HasteType;
            [gcd, haste] = this.ovaleCooldown.GetBaseGCD();
            if (this.ovale.playerClass == "MONK" && this.ovalePaperDoll.IsSpecialization("mistweaver")) {
                gcd = 1.5;
                haste = "spell";
            } else if (this.ovale.playerClass == "DRUID") {
                if (this.ovaleStance.IsStance("druid_cat_form", atTime)) {
                    gcd = 1.0;
                    haste = "none";
                }
            }
            let gcdHaste = spellId && this.ovaleData.GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID);
            if (gcdHaste) {
                haste = gcdHaste;
            } else {
                let siHaste = spellId && this.ovaleData.GetSpellInfoProperty(spellId, atTime, "haste", targetGUID);
                if (siHaste) {
                    haste = siHaste;
                }
            }
            let multiplier = this.ovalePaperDoll.GetHasteMultiplier(haste, this.ovalePaperDoll.next);
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
        this.profiler.StartProfiling("OvaleFuture_ResetState");
        const now = this.baseState.next.currentTime;
        this.tracer.Log("Reset state with current time = %f", now);
        this.next.inCombat = this.current.inCombat;
        this.next.combatStartTime = this.current.combatStartTime || 0;
        this.next.nextCast = now;
        wipe(this.next.lastCast);
        wipe(OvaleFutureClass.staticSpellcast);
        this.next.currentCast = OvaleFutureClass.staticSpellcast;
        let reason = "";
        let [start, duration] = this.ovaleCooldown.GetGlobalCooldown(now);
        if (start && start > 0) {
            let ending = start + duration;
            if (this.next.nextCast < ending) {
                this.next.nextCast = ending;
                reason = " (waiting for GCD)";
            }
        }
        let lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound;
        for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
            let spellcast = this.lastSpell.queue[i];
            if (spellcast.spellId && spellcast.start) {
                this.tracer.Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop);
                if (!lastSpellcastFound) {
                    // this.next.lastCast = spellcast;
                    if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                        this.next.currentCast = spellcast
                    }
                    lastSpellcastFound = true;
                }
                if (!lastGCDSpellcastFound && !spellcast.offgcd) {
                    // this.next.PushGCDSpellId(spellcast.spellId);
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
            let spellcast = this.lastSpell.lastSpellcast;
            if (spellcast) {
                // this.next.lastCast = spellcast;
                if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                    this.next.currentCast = spellcast;
                }
            }
        }
        if (!lastGCDSpellcastFound) {
            let spellcast = this.lastSpell.lastGCDSpellcast;
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
        this.tracer.Log("    nextCast = %f%s", this.next.nextCast, reason);
        for (const [k, v] of pairs(this.current.counter)) {
            this.next.counter[k] = v;
        }
        this.profiler.StopProfiling("OvaleFuture_ResetState");
    }
    CleanState() {
        for (const [k] of pairs(this.next.lastCast)) {
            delete this.next.lastCast[k];
        }
        for (const [k] of pairs(this.next.counter)) {
            delete this.next.counter[k];
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleFuture_ApplySpellStartCast");
        if (channel) {
            this.UpdateCounters(spellId, startCast, targetGUID);
        }
        this.profiler.StopProfiling("OvaleFuture_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, channel: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleFuture_ApplySpellAfterCast");
        if (!channel) {
            this.UpdateCounters(spellId, endCast, targetGUID);
        }
        this.profiler.StopProfiling("OvaleFuture_ApplySpellAfterCast");
    }

    static staticSpellcast: SpellCast = createSpellCast();

    
    ApplySpell(spellId:number, targetGUID:string, startCast:number, endCast?:number, channel?: boolean, spellcast?: SpellCast) {
        channel = channel || false;
        this.profiler.StartProfiling("OvaleFuture_state_ApplySpell");
        if (spellId) {
            if (!targetGUID) {
                targetGUID = this.ovale.playerGUID;
            }
            let castTime;
            if (startCast && endCast) {
                castTime = endCast - startCast;
            } else {
                castTime = this.ovaleSpellBook.GetCastTime(spellId) || 0;
                startCast = startCast || this.next.nextCast;
                endCast = endCast || (startCast + castTime);
            }
            if (!spellcast) {
                spellcast = OvaleFutureClass.staticSpellcast;
                wipe(spellcast);
                spellcast.caster = this.ovale.playerGUID;
                spellcast.spellId = spellId;
                spellcast.spellName = this.ovaleSpellBook.GetSpellName(spellId) || "unknown spell";
                spellcast.target = targetGUID;
                spellcast.targetName = this.ovaleGuid.GUIDName(targetGUID) || "target";
                spellcast.start = startCast;
                spellcast.stop = endCast;
                spellcast.channel = channel;
                this.ovalePaperDoll.UpdateSnapshot(spellcast, this.ovalePaperDoll.next);
                let atTime = channel && startCast || endCast;
                for (const [, mod] of pairs(this.lastSpell.modules)) {
                    let func = mod.SaveSpellcastInfo;
                    if (func) {
                        func(spellcast, atTime, this.ovalePaperDoll.next);
                    }
                }
            }
            // this.next.lastCast = this.next.currentCast;
            this.next.currentCast = spellcast;
            this.next.lastCast[spellId] = endCast;
            let gcd = this.GetGCD(spellId, startCast, targetGUID);
            let nextCast = (castTime > gcd) && endCast || (startCast + gcd);
            if (this.next.nextCast < nextCast) {
                this.next.nextCast = nextCast;
            }
            // if (gcd > 0) {
            //     this.next.PushGCDSpellId(spellId);
            // } else {
            //     this.next.lastOffGCDSpellcast = this.next.currentCast;
            // }
            // let now = GetTime();
            // if (startCast >= now) {
            //     baseState.next.currentTime = startCast + SIMULATOR_LAG;
            // } else {
            //     baseState.next.currentTime = now;
            // }
            this.tracer.Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, this.baseState.next.currentTime, nextCast, endCast, targetGUID);
            if (!this.next.inCombat && this.ovaleSpellBook.IsHarmfulSpell(spellId)) {
                this.next.inCombat = true;
                if (channel) {
                    this.next.combatStartTime = startCast;
                } else {
                    this.next.combatStartTime = endCast;
                }
            }
            if (startCast > this.baseState.next.currentTime) {
                this.ovaleState.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            if (endCast > this.baseState.next.currentTime) {
                this.ovaleState.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            this.ovaleState.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast);
        }
        this.profiler.StopProfiling("OvaleFuture_state_ApplySpell");
    }

    
    ApplyInFlightSpells() {
        this.profiler.StartProfiling("OvaleFuture_ApplyInFlightSpells");
        let now = GetTime();
        let index = 1;
        while (index <= lualength(this.lastSpell.queue)) {
            let spellcast = this.lastSpell.queue[index];
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
                        this.tracer.Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f, start=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop, spellcast.start);
                    } else {
                        this.tracer.Log("Active spell %s (%d) is %s, now=%f, endCast=%f, start=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop, spellcast.start);
                    }
                    this.ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast);
                } else {
                    if (spellcast.target) {
                        this.tracer.Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target);
                    } else {
                        this.tracer.Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId);
                    }
                    remove(this.lastSpell.queue, index);
                    self_pool.Release(spellcast);
                    index = index - 1;
                }
            }
            index = index + 1;
        }
        this.profiler.StopProfiling("OvaleFuture_ApplyInFlightSpells");
    }
    
    CombatRequirement = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string | undefined):[boolean, string, number] => {
        let verified = false;
        let combatFlag = tokens[index]; 
        index = index + 1;
        
        if(combatFlag) {
            combatFlag = tonumber(combatFlag);
            if(combatFlag == 1 && this.IsInCombat(atTime) || combatFlag != 1 && !this.IsInCombat(atTime))
            {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (combatFlag == 1) {
                this.tracer.Log("    Require combat at time=%f: %s", atTime, result);
            } else {
                this.tracer.Log("    Require NOT combat at time=%f: %s", atTime, result);
            }
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement);
        }
        return [verified, requirement, index];
    }
}
