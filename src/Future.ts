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
import { ipairs, pairs, type, lualength } from "@wowts/lua";
import { sub } from "@wowts/string";
import { insert, remove } from "@wowts/table";
import { GetSpellInfo, GetTime, UnitCastingInfo, UnitChannelInfo, UnitExists, UnitGUID, UnitName } from "@wowts/wow-mock";

let OvaleFutureBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleFuture", aceEvent)));
let strsub = sub;
let tinsert = insert;
let tremove = remove;
let self_timeAuraAdded = undefined;

let CLEU_AURA_EVENT = {
    SPELL_AURA_APPLIED: "hit",
    SPELL_AURA_APPLIED_DOSE: "hit",
    SPELL_AURA_BROKEN: "hit",
    SPELL_AURA_BROKEN_SPELL: "hit",
    SPELL_AURA_REFRESH: "hit",
    SPELL_AURA_REMOVED: "hit",
    SPELL_AURA_REMOVED_DOSE: "hit"
}
let CLEU_SPELLCAST_FINISH_EVENT = {
    SPELL_DAMAGE: "hit",
    SPELL_DISPEL: "hit",
    SPELL_DISPEL_FAILED: "miss",
    SPELL_HEAL: "hit",
    SPELL_INTERRUPT: "hit",
    SPELL_MISSED: "miss",
    SPELL_STOLEN: "hit"
}
let CLEU_SPELLCAST_EVENT = {
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
let SPELLCAST_AURA_ORDER = {
    1: "target",
    2: "pet"
}
let SPELLAURALIST_AURA_VALUE = {
    count: true,
    extend: true,
    refresh: true,
    refresh_keep_snapshot: true
}
let WHITE_ATTACK = {
    [75]: true,
    [5019]: true,
    [6603]: true
}
let WHITE_ATTACK_NAME = {
}
{
    for (const [spellId] of pairs(WHITE_ATTACK)) {
        let [name] = GetSpellInfo(spellId);
        if (name) {
            WHITE_ATTACK_NAME[name] = true;
        }
    }
}

const IsSameSpellcast = function(a, b) {
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

class OvaleFutureClass extends OvaleFutureBase {
    inCombat = undefined;
    combatStartTime = undefined;
    lastCastTime = {    }
    lastOffGCDSpellcast: SpellCast = {    }
    counter = {    }

    constructor() {
        super();
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
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, , , , , , , , , , , arg24, arg25] = __args;
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
                    let [isOffHand, multistrike] = [arg24, arg25];
                    if (isOffHand || multistrike) {
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
                        this.Debug("No spell found for %s (%d)", spellName, spellId);
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
    FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) {
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
                if (IsSameSpellcast(spellcast, this.lastOffGCDSpellcast)) {
                    this.UpdateSpellcastSnapshot(this.lastOffGCDSpellcast, self_timeAuraAdded);
                }
            }
            let delta = now - spellcast.stop;
            let targetGUID = spellcast.target;
            this.Debug("Spell %s (%d) was in flight for %s seconds.", spellName, spellId, delta);
            tremove(lastSpell.queue, i);
            self_pool.Release(spellcast);
            Ovale.needRefresh();
            this.SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish);
        }
        return finished;
    }
    PLAYER_ENTERING_WORLD(event) {
        this.StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
        this.Debug(event);
        this.StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD");
    }
    PLAYER_REGEN_DISABLED(event) {
        this.StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
        this.Debug(event, "Entering combat.");
        let now = GetTime();
        Ovale.inCombat = true;
        this.combatStartTime = now;
        Ovale.needRefresh();
        this.SendMessage("Ovale_CombatStarted", now);
        this.StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED");
    }
    PLAYER_REGEN_ENABLED(event) {
        this.StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
        this.Debug(event, "Leaving combat.");
        let now = GetTime();
        Ovale.inCombat = false;
        Ovale.needRefresh();
        this.SendMessage("Ovale_CombatEnded", now);
        this.StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED");
    }
    UNIT_SPELLCAST_CHANNEL_START(event, unitId, spell, rank, lineId, spellId) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast) {
                let [name, , , , startTime, endTime] = UnitChannelInfo(unitId);
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
    UNIT_SPELLCAST_CHANNEL_STOP(event, unitId, spell, rank, lineId, spellId) {
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
    UNIT_SPELLCAST_CHANNEL_UPDATE(event, unitId, spell, rank, lineId, spellId) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, undefined, now);
            if (spellcast && spellcast.channel) {
                let [name, , , , startTime, endTime] = UnitChannelInfo(unitId);
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
    UNIT_SPELLCAST_DELAYED(event, unitId, spell, rank, lineId, spellId) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , , startTime, endTime, , castId] = UnitCastingInfo(unitId);
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
    UNIT_SPELLCAST_SENT(event, unitId, spell, rank, targetName, lineId) {
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
            tinsert(lastSpell.queue, spellcast);
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
    UNIT_SPELLCAST_START(event, unitId, spell, rank, lineId, spellId) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UNIT_SPELLCAST_START");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, ,, , startTime, endTime, , castId] = UnitCastingInfo(unitId);
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
    UNIT_SPELLCAST_SUCCEEDED(event, unitId, spell, rank, lineId, spellId) {
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
    Ovale_AuraAdded(event, atTime, guid, auraId, caster) {
        if (guid == Ovale.playerGUID) {
            self_timeAuraAdded = atTime;
            this.UpdateSpellcastSnapshot(lastSpell.lastGCDSpellcast, atTime);
            this.UpdateSpellcastSnapshot(this.lastOffGCDSpellcast, atTime);
        }
    }
    UnitSpellcastEnded(event, unitId, spell, rank, lineId, spellId) {
        if ((unitId == "player" || unitId == "pet") && !WHITE_ATTACK[spellId]) {
            this.StartProfiling("OvaleFuture_UnitSpellcastEnded");
            this.DebugTimestamp(event, unitId, spell, rank, lineId, spellId);
            let now = GetTime();
            let [spellcast, index] = this.GetSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                this.Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event);
                if (!spellcast.success) {
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
    GetSpellcast(spell, spellId, lineId, atTime):[SpellCast, number] {
        this.StartProfiling("OvaleFuture_GetSpellcast");
        let spellcast: SpellCast, index;
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
    GetAuraFinish(spell, spellId, targetGUID, atTime) {
        this.StartProfiling("OvaleFuture_GetAuraFinish");
        let auraId, auraGUID;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.aura) {
            for (const [, unitId] of ipairs(SPELLCAST_AURA_ORDER)) {
                for (const [, auraList] of pairs(si.aura[unitId])) {
                    for (const [id, spellData] of pairs(auraList)) {
                        let [verified, value, ] = OvaleData.CheckSpellAuraData(id, spellData, atTime, targetGUID);
                        if (verified && (SPELLAURALIST_AURA_VALUE[value] || type(value) == "number" && value > 0)) {
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
    
    SaveSpellcastInfo(spellcast, atTime) {
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
    GetDamageMultiplier(spellId, targetGUID, atTime) {
        atTime = atTime || this["currentTime"] || GetTime();
        let damageMultiplier = 1;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.aura && si.aura.damage) {
            let CheckRequirements;
            for (const [filter, auraList] of pairs(si.aura.damage)) {
                for (const [auraId, spellData] of pairs(auraList)) {
                    let index, multiplier;
                    if (type(spellData) == "table") {
                        multiplier = spellData[1];
                        index = 2;
                    } else {
                        multiplier = spellData;
                    }
                    let verified;
                    if (index) {
                        verified = CheckRequirements(spellId, atTime, spellData, index, targetGUID);
                    } else {
                        verified = true;
                    }
                    if (verified) {
                        let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, auraId, filter);
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
    UpdateCounters(spellId, atTime, targetGUID) {
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
    IsActive(spellId) {
        for (const [, spellcast] of ipairs(lastSpell.queue)) {
            if (spellcast.spellId == spellId && spellcast.start) {
                return true;
            }
        }
        return false;
    }

    InFlight(spellId) {
        return this.IsActive(spellId);
    }
    
    UpdateLastSpellcast(atTime, spellcast) {
        this.StartProfiling("OvaleFuture_UpdateLastSpellcast");
        this.lastCastTime[spellcast.spellId] = atTime;
        if (spellcast.offgcd) {
            this.Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId);
            for (const [k, v] of pairs(spellcast)) {
                this.lastOffGCDSpellcast[k] = v;
            }
            lastSpell.lastSpellcast = this.lastOffGCDSpellcast;
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
            OvalePaperDoll.UpdateSnapshot(spellcast, OvalePaperDoll, true);
            if (spellcast.spellId) {
                spellcast.damageMultiplier = this.GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime);
                if (spellcast.damageMultiplier != 1) {
                    this.Debug("        persistent multiplier = %f", spellcast.damageMultiplier);
                }
            }
        }
    }
}

export const OvaleFuture = new OvaleFutureClass();