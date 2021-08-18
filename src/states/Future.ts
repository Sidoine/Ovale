import { OvaleAuraClass } from "./Aura";
import { OvaleDataClass } from "../engine/data";
import { Guids } from "../engine/guid";
import { OvalePaperDollClass, HasteType } from "./PaperDoll";
import {
    LastSpell,
    SpellCast,
    SpellCastModule,
    lastSpellCastPool,
    createSpellCast,
} from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    ipairs,
    pairs,
    lualength,
    LuaObj,
    LuaArray,
    wipe,
    kpairs,
    unpack,
} from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import {
    GetSpellInfo,
    GetTime,
    GetUnitName,
    UnitCastingInfo,
    UnitChannelInfo,
    UnitExists,
    UnitGUID,
} from "@wowts/wow-mock";
import { OvaleStateClass, StateModule, States } from "../engine/state";
import { OvaleCooldownClass } from "./Cooldown";
import { BaseState } from "./BaseState";
import { isNumber } from "../tools/tools";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import {
    CombatLogEvent,
    DamagePayload,
    SpellPayloadHeader,
} from "../engine/combat-log-event";
import { Tracer, DebugTools } from "../engine/debug";
import { OvaleStanceClass } from "./Stance";
import { OvaleSpellBookClass } from "./SpellBook";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnValueBetween,
} from "../engine/condition";
import { Runner } from "../engine/runner";

let timeAuraAdded: undefined | number = undefined;

// let SIMULATOR_LAG = 0.005;

const spellAuraEvents: LuaObj<"hit"> = {
    SPELL_AURA_APPLIED: "hit",
    SPELL_AURA_APPLIED_DOSE: "hit",
    SPELL_AURA_BROKEN: "hit",
    SPELL_AURA_BROKEN_SPELL: "hit",
    SPELL_AURA_REFRESH: "hit",
    SPELL_AURA_REMOVED: "hit",
    SPELL_AURA_REMOVED_DOSE: "hit",
};
const spellCastFinishEvents: LuaObj<"hit" | "miss"> = {
    SPELL_DAMAGE: "hit",
    SPELL_DISPEL: "hit",
    SPELL_DISPEL_FAILED: "miss",
    SPELL_HEAL: "hit",
    SPELL_INTERRUPT: "hit",
    SPELL_MISSED: "miss",
    SPELL_STOLEN: "hit",
};
const spellCastEvents: LuaObj<boolean> = {
    SPELL_CAST_FAILED: true,
    SPELL_CAST_START: true,
    SPELL_CAST_SUCCESS: true,
};
{
    for (const [cleuEvent, v] of pairs(spellAuraEvents)) {
        spellCastFinishEvents[cleuEvent] = v;
    }
    for (const [cleuEvent] of pairs(spellCastFinishEvents)) {
        spellCastEvents[cleuEvent] = true;
    }
}
const spellCastAurOrder: LuaArray<"target" | "pet"> = {
    1: "target",
    2: "pet",
};
const whiteAttackIds: LuaArray<boolean> = {
    [75]: true,
    [5019]: true,
    [6603]: true,
};
const whitAttackNames: LuaObj<boolean> = {};
{
    for (const [spellId] of pairs(whiteAttackIds)) {
        const [name] = GetSpellInfo(spellId);
        if (name) {
            whitAttackNames[name] = true;
        }
    }
}

const isSameSpellcast = function (a: SpellCast, b: SpellCast) {
    let boolean = a.spellId == b.spellId && a.queued == b.queued;
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
};

export class OvaleFutureData {
    lastCastTime: LuaObj<number> = {};
    lastOffGCDSpellcast: SpellCast = createSpellCast();
    lastGCDSpellcast: SpellCast = createSpellCast();
    lastGCDSpellIds: LuaArray<number> = {};
    lastGCDSpellId = 0;
    counter: LuaArray<number> = {};
    lastCast: LuaObj<number> = {};
    currentCast: SpellCast = createSpellCast();

    /**
     * The time at which a spell can be cast
     * (after the global cooldown or after the end of the current cast)
     */
    nextCast = 0;

    pushGCDSpellId(spellId: number) {
        if (this.lastGCDSpellId) {
            insert(this.lastGCDSpellIds, this.lastGCDSpellId);
            if (lualength(this.lastGCDSpellIds) > 5) {
                remove(this.lastGCDSpellIds, 1);
            }
        }
        this.lastGCDSpellId = spellId;
    }

    getCounter(id: number) {
        return this.counter[id] || 0;
    }
    isChanneling(atTime: number) {
        return this.currentCast.channel && atTime < this.currentCast.stop;
    }
}

export class OvaleFutureClass
    extends States<OvaleFutureData>
    implements SpellCastModule, StateModule
{
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    constructor(
        private ovaleData: OvaleDataClass,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private baseState: BaseState,
        private ovaleCooldown: OvaleCooldownClass,
        private ovaleState: OvaleStateClass,
        private ovaleGuid: Guids,
        private lastSpell: LastSpell,
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        private ovaleStance: OvaleStanceClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combatLogEvent: CombatLogEvent,
        private runner: Runner
    ) {
        super(OvaleFutureData);
        const name = "OvaleFuture";
        this.tracer = ovaleDebug.create(name);
        this.module = ovale.createModule(
            name,
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    public registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("channeling", true, this.isChanneling);
    }

    private isChanneling: ConditionFunction = (
        positionalParameters,
        namedParameters,
        atTime
    ) => {
        const [spellId] = unpack(positionalParameters);
        const state = this.getState(atTime);
        if (state.currentCast.spellId !== spellId || !state.currentCast.channel)
            return [];
        return returnValueBetween(
            state.currentCast.start,
            state.currentCast.stop,
            1,
            state.currentCast.start,
            0
        );
    };

    updateStateCounters(
        state: OvaleFutureData,
        spellId: number,
        atTime: number,
        targetGUID: string
    ) {
        const inccounter = this.ovaleData.getSpellInfoProperty(
            spellId,
            atTime,
            "inccounter",
            targetGUID
        );
        if (inccounter) {
            const value =
                (state.counter[inccounter] && state.counter[inccounter]) || 0;
            state.counter[inccounter] = value + 1;
        }
        const resetcounter = this.ovaleData.getSpellInfoProperty(
            spellId,
            atTime,
            "resetcounter",
            targetGUID
        );
        if (resetcounter) {
            state.counter[resetcounter] = 0;
        }
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handlePlayerEnteringWorld
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_CHANNEL_START",
            this.handleUnitSpellCastChannelStart
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_CHANNEL_STOP",
            this.handleSpellCastChannelStop
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_CHANNEL_UPDATE",
            this.handleSpellCastChannelUpdate
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_DELAYED",
            this.handleUnitSpellCastDelayed
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_FAILED",
            this.handleUnitSpellcastEnded
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_FAILED_QUIET",
            this.handleUnitSpellcastEnded
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_INTERRUPTED",
            this.handleUnitSpellcastEnded
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_SENT",
            this.handleUnitSpellCastSent
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_START",
            this.handleUnitSpellCastStart
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_STOP",
            this.handleUnitSpellcastEnded
        );
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_SUCCEEDED",
            this.handleUnitSpellCastSucceeded
        );
        this.module.RegisterMessage("Ovale_AuraAdded", this.handleAuraAdded);
        this.module.RegisterMessage(
            "Ovale_AuraChanged",
            this.handleAuraChanged
        );
        for (const [event] of pairs(spellCastEvents)) {
            this.combatLogEvent.registerEvent(
                event,
                this,
                this.handleCombatLogEvent
            );
        }
        this.lastSpell.registerSpellcastInfo(this);
    };

    private handleDisable = () => {
        this.lastSpell.unregisterSpellcastInfo(this);
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
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
        this.combatLogEvent.unregisterAllEvents(this);
    };

    private handleCombatLogEvent = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        const sourceGUID = cleu.sourceGUID;
        const sourceName = cleu.sourceName;
        const destGUID = cleu.destGUID;
        const destName = cleu.destName;
        if (
            sourceGUID == this.ovale.playerGUID ||
            this.ovaleGuid.getOwnerGUIDByGUID(sourceGUID) ==
                this.ovale.playerGUID
        ) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            const spellName = header.spellName;
            if (
                (cleuEvent == "SPELL_CAST_FAILED" ||
                    cleuEvent == "SPELL_CAST_START" ||
                    cleuEvent == "SPELL_CAST_SUCCESS") &&
                destName &&
                destName != ""
            ) {
                this.tracer.debugTimestamp(
                    cleuEvent,
                    cleu.getCurrentEventInfo()
                );
                const now = GetTime();
                const [spellcast] = this.getSpellcast(
                    spellName,
                    spellId,
                    undefined,
                    now
                );
                if (
                    spellcast &&
                    spellcast.targetName &&
                    spellcast.targetName == destName &&
                    spellcast.target != destGUID
                ) {
                    this.tracer.debug(
                        "Disambiguating target of spell %s (%d) to %s (%s).",
                        spellName,
                        spellId,
                        destName,
                        destGUID
                    );
                    spellcast.target = destGUID;
                }
            }
            this.tracer.debugTimestamp(cleuEvent, cleu.getCurrentEventInfo());
            let finish: "hit" | "miss" | undefined =
                spellCastFinishEvents[cleuEvent];
            if (cleu.payload.type == "DAMAGE") {
                const payload = cleu.payload as DamagePayload;
                if (payload.isOffHand) {
                    finish = undefined;
                }
            }
            if (finish) {
                let anyFinished = false;
                for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
                    const spellcast = this.lastSpell.queue[i];
                    if (
                        spellcast.success &&
                        (spellcast.spellId == spellId ||
                            spellcast.auraId == spellId)
                    ) {
                        if (
                            this.finishSpell(
                                spellcast,
                                cleuEvent,
                                sourceName,
                                sourceGUID,
                                destName,
                                destGUID,
                                spellId,
                                spellName,
                                finish,
                                i
                            )
                        ) {
                            anyFinished = true;
                        }
                    }
                }
                if (!anyFinished) {
                    this.tracer.debug(
                        "Found no spell to finish for %s (%d)",
                        spellName,
                        spellId
                    );
                    for (
                        let i = lualength(this.lastSpell.queue);
                        i >= 1;
                        i += -1
                    ) {
                        const spellcast = this.lastSpell.queue[i];
                        if (
                            spellcast.success &&
                            spellcast.spellName == spellName
                        ) {
                            if (
                                this.finishSpell(
                                    spellcast,
                                    cleuEvent,
                                    sourceName,
                                    sourceGUID,
                                    destName,
                                    destGUID,
                                    spellId,
                                    spellName,
                                    finish,
                                    i
                                )
                            ) {
                                anyFinished = true;
                            }
                        }
                    }
                    if (!anyFinished) {
                        this.tracer.debug(
                            "No spell found for %s",
                            spellName,
                            spellId
                        );
                    }
                }
            }
        }
    };

    finishSpell(
        spellcast: SpellCast,
        cleuEvent: string,
        sourceName: string,
        sourceGUID: string,
        destName: string,
        destGUID: string,
        spellId: number,
        spellName: string,
        finish: "hit" | "miss",
        i: number
    ) {
        let finished = false;
        if (!spellcast.auraId) {
            this.tracer.debugTimestamp(
                "CLEU",
                cleuEvent,
                sourceName,
                sourceGUID,
                destName,
                destGUID,
                spellId,
                spellName
            );
            if (!spellcast.channel) {
                this.tracer.debug(
                    "Finished (%s) spell %s (%d) queued at %s due to %s.",
                    finish,
                    spellName,
                    spellId,
                    spellcast.queued,
                    cleuEvent
                );
                finished = true;
            }
        } else if (
            spellAuraEvents[cleuEvent] &&
            spellcast.auraGUID &&
            destGUID == spellcast.auraGUID
        ) {
            this.tracer.debugTimestamp(
                "CLEU",
                cleuEvent,
                sourceName,
                sourceGUID,
                destName,
                destGUID,
                spellId,
                spellName
            );
            this.tracer.debug(
                "Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.",
                finish,
                spellName,
                spellId,
                spellcast.queued,
                spellcast.auraId,
                spellcast.auraGUID
            );
            finished = true;
        } else if (
            cleuEvent == "Ovale_AuraChanged" &&
            spellcast.auraGUID &&
            destGUID == spellcast.auraGUID
        ) {
            this.tracer.debug(
                "Finished (%s) spell %s (%d) queued at %s after Ovale_AuraChanged was called for aura %d on %s.",
                finish,
                spellName,
                spellId,
                spellcast.queued,
                spellcast.auraId,
                spellcast.auraGUID
            );
            finished = true;
        }
        if (finished) {
            const now = GetTime();
            if (timeAuraAdded) {
                if (
                    isSameSpellcast(spellcast, this.lastSpell.lastGCDSpellcast)
                ) {
                    this.updateSpellcastInfo(
                        this.lastSpell.lastGCDSpellcast,
                        timeAuraAdded
                    );
                }
                if (
                    isSameSpellcast(spellcast, this.current.lastOffGCDSpellcast)
                ) {
                    this.updateSpellcastInfo(
                        this.current.lastOffGCDSpellcast,
                        timeAuraAdded
                    );
                }
            }
            const delta = now - spellcast.stop;
            const targetGUID = spellcast.target;
            this.tracer.debug(
                "Spell %s (%d) was in flight for %f seconds.",
                spellName,
                spellId,
                delta
            );
            remove(this.lastSpell.queue, i);
            lastSpellCastPool.release(spellcast);
            this.ovale.needRefresh();
            this.module.SendMessage(
                "Ovale_SpellFinished",
                now,
                spellId,
                targetGUID,
                finish
            );
        }
        return finished;
    }
    private handlePlayerEnteringWorld = (event: string) => {
        this.tracer.debug(event);
    };
    private handleUnitSpellCastChannelStart = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(event, unitId, spell, lineId, spellId);
            const now = GetTime();
            const [spellcast] = this.getSpellcast(
                spell,
                spellId,
                undefined,
                now
            );
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
                    const delta = now - spellcast.queued;
                    this.tracer.debug(
                        "Channelling spell %s (%d): start = %s (+%s), ending = %s",
                        spell,
                        spellId,
                        startTime,
                        delta,
                        endTime
                    );
                    this.lastSpell.saveSpellcastInfo(spellcast, now);
                    this.updateLastSpellcast(now, spellcast);
                    this.updateCounters(
                        spellId,
                        spellcast.start,
                        spellcast.target
                    );
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.debug("Warning: not channelling a spell.");
                } else {
                    this.tracer.debug(
                        "Warning: channelling unexpected spell %s",
                        name
                    );
                }
            } else {
                this.tracer.debug(
                    "Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.",
                    spell,
                    spellId
                );
            }
        }
    };
    private handleSpellCastChannelStop = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(event, unitId, spell, lineId, spellId);
            const now = GetTime();
            const [spellcast, index] = this.getSpellcast(
                spell,
                spellId,
                undefined,
                now
            );
            if (spellcast && spellcast.channel) {
                this.tracer.debug(
                    "Finished channelling spell %s (%d) queued at %s.",
                    spell,
                    spellId,
                    spellcast.queued
                );
                spellcast.stop = now;
                this.updateLastSpellcast(now, spellcast);
                const targetGUID = spellcast.target;
                remove(this.lastSpell.queue, index);
                lastSpellCastPool.release(spellcast);
                this.ovale.needRefresh();
                this.module.SendMessage(
                    "Ovale_SpellFinished",
                    now,
                    spellId,
                    targetGUID,
                    "hit"
                );
            }
        }
    };
    private handleSpellCastChannelUpdate = (
        event: string,
        unitId: string,
        lineId: number,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(event, unitId, spell, lineId, spellId);
            const now = GetTime();
            const [spellcast] = this.getSpellcast(
                spell,
                spellId,
                undefined,
                now
            );
            if (spellcast && spellcast.channel) {
                let [name, , , startTime, endTime] = UnitChannelInfo(unitId);
                if (name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    const delta = endTime - spellcast.stop;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    this.tracer.debug(
                        "Updating channelled spell %s (%d) to ending = %s (+%s).",
                        spell,
                        spellId,
                        endTime,
                        delta
                    );
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.debug("Warning: not channelling a spell.");
                } else {
                    this.tracer.debug(
                        "Warning: delaying unexpected channelled spell %s.",
                        name
                    );
                }
            } else {
                this.tracer.debug(
                    "Warning: no queued, channelled spell %s (%d) found to update.",
                    spell,
                    spellId
                );
            }
        }
    };
    private handleUnitSpellCastDelayed = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(event, unitId, spell, lineId, spellId);
            const now = GetTime();
            const [spellcast] = this.getSpellcast(spell, spellId, lineId, now);
            if (spellcast) {
                let [name, , , startTime, endTime, , castId] =
                    UnitCastingInfo(unitId);
                if (lineId == castId && name == spell) {
                    startTime = startTime / 1000;
                    endTime = endTime / 1000;
                    const delta = endTime - spellcast.stop;
                    spellcast.start = startTime;
                    spellcast.stop = endTime;
                    this.tracer.debug(
                        "Delaying spell %s (%d) to ending = %s (+%s).",
                        spell,
                        spellId,
                        endTime,
                        delta
                    );
                    this.ovale.needRefresh();
                } else if (!name) {
                    this.tracer.debug("Warning: not casting a spell.");
                } else {
                    this.tracer.debug(
                        "Warning: delaying unexpected spell %s.",
                        name
                    );
                }
            } else {
                this.tracer.debug(
                    "Warning: no queued spell %s (%d) found to delay.",
                    spell,
                    spellId
                );
            }
        }
    };

    private addSpellCast(
        lineId: string,
        unitId: string,
        spellName: string | undefined,
        spellId: number,
        targetName: string | undefined
    ): SpellCast {
        const now = GetTime();
        const caster = this.ovaleGuid.getUnitGUID(unitId);
        const spellcast = lastSpellCastPool.get();
        spellcast.lineId = lineId;
        spellcast.caster = caster;
        spellcast.castByPlayer = caster === this.ovale.playerGUID;
        spellcast.spellId = spellId;
        spellcast.spellName = spellName || "Unknown spell";
        spellcast.queued = now;
        insert(this.lastSpell.queue, spellcast);
        if (targetName == "" || targetName == undefined) {
            this.tracer.debug(
                "Queueing (%d) spell %s with no target.",
                lualength(this.lastSpell.queue),
                spellName
            );
        } else {
            spellcast.targetName = targetName;
            let [targetGUID, nextGUID] =
                this.ovaleGuid.getGUIDByName(targetName);
            if (nextGUID) {
                let name = this.ovaleGuid.getUnitName("target");
                if (name == targetName) {
                    targetGUID = this.ovaleGuid.getUnitGUID("target");
                } else {
                    name = this.ovaleGuid.getUnitName("focus");
                    if (name == targetName) {
                        targetGUID = this.ovaleGuid.getUnitGUID("focus");
                    } else if (UnitExists("mouseover")) {
                        name = GetUnitName("mouseover", true);
                        if (name == targetName) {
                            targetGUID = UnitGUID("mouseover");
                        }
                    }
                }
                spellcast.target = targetGUID || "unknown";
                this.tracer.debug(
                    "Queueing (%d) spell %s to %s (possibly %s).",
                    lualength(this.lastSpell.queue),
                    spellName,
                    targetName,
                    targetGUID
                );
            } else {
                spellcast.target = targetGUID || "unknown";
                this.tracer.debug(
                    "Queueing (%d) spell %s to %s (%s).",
                    lualength(this.lastSpell.queue),
                    spellName,
                    targetName,
                    targetGUID
                );
            }
        }
        this.lastSpell.saveSpellcastInfo(spellcast, now);
        return spellcast;
    }

    private handleUnitSpellCastSent = (
        event: string,
        unitId: string,
        targetName: string,
        lineId: string,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            const spellName = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(
                event,
                unitId,
                spellName,
                targetName,
                lineId
            );
            this.addSpellCast(lineId, unitId, spellName, spellId, targetName);
        }
    };
    private handleUnitSpellCastStart = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            this.ovaleData.registerSpellCast(spellId);
            const spellName = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(
                event,
                unitId,
                spellName,
                lineId,
                spellId
            );
            const now = GetTime();
            let [spellcast] = this.getSpellcast(
                spellName,
                spellId,
                lineId,
                now
            );
            if (!spellcast) {
                this.tracer.debug(
                    "Warning: casting spell %s (%d) without previous sent data.",
                    spellName,
                    spellId
                );
                spellcast = this.addSpellCast(
                    lineId,
                    unitId,
                    spellName,
                    spellId,
                    undefined
                );
            }
            let [name, , , startTime, endTime, , castId] =
                UnitCastingInfo(unitId);
            if (lineId == castId && name == spellName) {
                startTime = startTime / 1000;
                endTime = endTime / 1000;
                spellcast.spellId = spellId;
                spellcast.start = startTime;
                spellcast.stop = endTime;
                spellcast.channel = false;
                const delta = now - spellcast.queued;
                this.tracer.debug(
                    "Casting spell %s (%d): start = %s (+%s), ending = %s.",
                    spellName,
                    spellId,
                    startTime,
                    delta,
                    endTime
                );
                const [auraId, auraGUID] = this.getAuraFinish(
                    spellId,
                    spellcast.target,
                    now
                );
                if (auraId && auraGUID) {
                    spellcast.auraId = auraId;
                    spellcast.auraGUID = auraGUID;
                    this.tracer.debug(
                        "Spell %s (%d) will finish after updating aura %d on %s.",
                        spellName,
                        spellId,
                        auraId,
                        auraGUID
                    );
                }
                this.lastSpell.saveSpellcastInfo(spellcast, now);
                this.updateLastSpellcast(now, spellcast);
                this.ovale.needRefresh();
            } else if (!name) {
                this.tracer.debug("Warning: not casting a spell.");
            } else {
                this.tracer.debug(
                    "Warning: casting unexpected spell %s.",
                    name
                );
            }
        }
    };
    private handleUnitSpellCastSucceeded = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            this.ovaleData.registerSpellCast(spellId);
            const spell = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(event, unitId, spell, lineId, spellId);
            const now = GetTime();
            const [spellcast, index] = this.getSpellcast(
                spell,
                spellId,
                lineId,
                now
            );
            if (spellcast) {
                let success = false;
                if (
                    !spellcast.success &&
                    spellcast.start &&
                    spellcast.stop &&
                    !spellcast.channel
                ) {
                    this.tracer.debug(
                        "Succeeded casting spell %s (%d) at %s, now in flight.",
                        spell,
                        spellId,
                        spellcast.stop
                    );
                    spellcast.success = now;
                    this.updateSpellcastInfo(spellcast, now);
                    success = true;
                } else {
                    const name = UnitChannelInfo(unitId);
                    if (!name) {
                        const now = GetTime();
                        spellcast.spellId = spellId;
                        spellcast.start = now;
                        spellcast.stop = now;
                        spellcast.channel = false;
                        spellcast.success = now;
                        const delta = now - spellcast.queued;
                        this.tracer.debug(
                            "Instant-cast spell %s (%d): start = %s (+%s).",
                            spell,
                            spellId,
                            now,
                            delta
                        );
                        const [auraId, auraGUID] = this.getAuraFinish(
                            spellId,
                            spellcast.target,
                            now
                        );
                        if (auraId && auraGUID) {
                            spellcast.auraId = auraId;
                            spellcast.auraGUID = auraGUID;
                            this.tracer.debug(
                                "Spell %s (%d) will finish after updating aura %d on %s.",
                                spell,
                                spellId,
                                auraId,
                                auraGUID
                            );
                        }
                        this.lastSpell.saveSpellcastInfo(spellcast, now);
                        success = true;
                    } else {
                        this.tracer.debug(
                            "Succeeded casting spell %s (%d) but it is channelled.",
                            spell,
                            spellId
                        );
                    }
                }
                if (success) {
                    const targetGUID = spellcast.target;
                    this.updateLastSpellcast(now, spellcast);
                    if (!spellcast.offgcd)
                        this.next.pushGCDSpellId(spellcast.spellId);
                    this.updateCounters(spellId, spellcast.stop, targetGUID);
                    let finished = false;
                    let finish = "miss";
                    if (!spellcast.targetName) {
                        this.tracer.debug(
                            "Finished spell %s (%d) with no target queued at %s.",
                            spell,
                            spellId,
                            spellcast.queued
                        );
                        finished = true;
                        finish = "hit";
                    } else if (
                        targetGUID == this.ovale.playerGUID &&
                        this.ovaleSpellBook.isHelpfulSpell(spellId)
                    ) {
                        this.tracer.debug(
                            "Finished helpful spell %s (%d) cast on player queued at %s.",
                            spell,
                            spellId,
                            spellcast.queued
                        );
                        finished = true;
                        finish = "hit";
                    }
                    if (finished) {
                        remove(this.lastSpell.queue, index);
                        lastSpellCastPool.release(spellcast);
                        this.ovale.needRefresh();
                        this.module.SendMessage(
                            "Ovale_SpellFinished",
                            now,
                            spellId,
                            targetGUID,
                            finish
                        );
                    }
                }
            } else {
                this.tracer.debug(
                    "Warning: no queued spell %s (%d) found to successfully complete casting.",
                    spell,
                    spellId
                );
            }
        }
    };

    private handleAuraAdded = (
        event: string,
        atTime: number,
        guid: string,
        auraId: string,
        caster: string
    ) => {
        if (guid == this.ovale.playerGUID) {
            timeAuraAdded = atTime;
            this.updateSpellcastInfo(this.lastSpell.lastGCDSpellcast, atTime);
            this.updateSpellcastInfo(this.current.lastOffGCDSpellcast, atTime);
        }
    };

    private handleAuraChanged = (
        event: string,
        atTime: number,
        guid: string,
        auraId: string,
        caster: string
    ) => {
        this.tracer.debugTimestamp(
            "Ovale_AuraChanged",
            event,
            atTime,
            guid,
            auraId,
            caster
        );
        if (caster == this.ovale.playerGUID) {
            // let's check if the aura matches a spell we have in flight, if so we can end it
            let anyFinished = false;
            for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
                const spellcast = this.lastSpell.queue[i];
                if (spellcast.success && spellcast.auraId == auraId) {
                    if (
                        this.finishSpell(
                            spellcast,
                            "Ovale_AuraChanged",
                            caster,
                            this.ovale.playerGUID,
                            spellcast.targetName,
                            guid,
                            spellcast.spellId,
                            spellcast.spellName,
                            "hit",
                            i
                        )
                    ) {
                        anyFinished = true;
                    }
                }
            }
            if (!anyFinished) {
                this.tracer.debug(
                    "No spell found to finish for auraId %d",
                    auraId
                );
            }
        }
    };
    private handleUnitSpellcastEnded = (
        event: string,
        unitId: string,
        lineId: string,
        spellId: number
    ) => {
        if (
            (unitId == "player" || unitId == "pet") &&
            !whiteAttackIds[spellId]
        ) {
            if (event == "UNIT_SPELLCAST_INTERRUPTED") {
                this.next.lastGCDSpellId = 0;
            }
            const spellName = this.ovaleSpellBook.getSpellName(spellId);
            this.tracer.debugTimestamp(
                event,
                unitId,
                spellName,
                lineId,
                spellId
            );
            const now = GetTime();
            const [spellcast, index] = this.getSpellcast(
                spellName,
                spellId,
                lineId,
                now
            );
            if (spellcast) {
                this.tracer.debug(
                    "End casting spell %s (%d) queued at %s due to %s.",
                    spellName,
                    spellId,
                    spellcast.queued,
                    event
                );
                if (!spellcast.success) {
                    this.tracer.debug(
                        "Remove spell from queue because there was no success before"
                    );
                    remove(this.lastSpell.queue, index);
                    lastSpellCastPool.release(spellcast);
                    this.ovale.needRefresh();
                }
            } else if (lineId) {
                this.tracer.debug(
                    "Warning: no queued spell %s (%d) found to end casting.",
                    spellName,
                    spellId
                );
            }
        }
    };

    getSpellcast(
        spellName: string | undefined,
        spellId: number,
        lineId: undefined | string,
        atTime: number
    ): [SpellCast | undefined, number] {
        let spellcast: SpellCast | undefined = undefined;
        let index = 0;
        if (!lineId || lineId != "") {
            for (const [i, sc] of ipairs(this.lastSpell.queue)) {
                if (!lineId || sc.lineId == lineId) {
                    if (spellId && sc.spellId == spellId) {
                        spellcast = sc;
                        index = i;
                        break;
                    } else if (spellName) {
                        const spellName =
                            sc.spellName ||
                            this.ovaleSpellBook.getSpellName(spellId);
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
            spellName =
                spellName ||
                spellcast.spellName ||
                this.ovaleSpellBook.getSpellName(spellId);
            if (spellcast.targetName) {
                this.tracer.debug(
                    "Found spellcast for %s to %s queued at %f.",
                    spellName,
                    spellcast.targetName,
                    spellcast.queued
                );
            } else {
                this.tracer.debug(
                    "Found spellcast for %s with no target queued at %f.",
                    spellName,
                    spellcast.queued
                );
            }
        }
        return [spellcast, index];
    }

    getAuraFinish(
        spellId: number,
        targetGUID: string,
        atTime: number
    ): [string | number | undefined, string | undefined] {
        let auraId, auraGUID;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.aura) {
            for (const [, unitId] of ipairs(spellCastAurOrder)) {
                for (const [, auraList] of kpairs(si.aura[unitId])) {
                    for (const [id, spellData] of kpairs(auraList)) {
                        const value = this.ovaleData.checkSpellAuraData(
                            id,
                            spellData,
                            atTime,
                            targetGUID
                        );
                        if (
                            (value.enabled === undefined || value.enabled) &&
                            isNumber(value.add) &&
                            value.add > 0
                        ) {
                            auraId = id;
                            auraGUID = this.ovaleGuid.getUnitGUID(unitId);
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
        return [auraId, auraGUID];
    }

    copySpellcastInfo = (spellcast: SpellCast, dest: SpellCast) => {
        dest.damageMultiplier = spellcast.damageMultiplier;
    };

    saveSpellcastInfo = (spellcast: SpellCast, atTime: number) => {
        if (spellcast.spellId) {
            spellcast.damageMultiplier = this.getDamageMultiplier(
                spellcast.spellId,
                spellcast.target,
                atTime
            );
        }
    };

    getDamageMultiplier(spellId: number, targetGUID: string, atTime: number) {
        let damageMultiplier = 1;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.aura && si.aura.damage) {
            for (const [filter, auraList] of kpairs(si.aura.damage)) {
                for (const [auraId, spellData] of pairs(auraList)) {
                    let multiplier: number;
                    let verified;
                    // if (isLuaArray(spellData)) {
                    //     multiplier = <number>spellData[1];
                    //     index = 2;
                    //     [verified] = this.requirement.CheckRequirements(
                    //         spellId,
                    //         atTime,
                    //         spellData,
                    //         index,
                    //         targetGUID
                    //     );
                    // } else {
                    const [, namedParameters] = this.runner.computeParameters(
                        spellData,
                        atTime
                    );
                    multiplier = namedParameters.set as number;
                    verified =
                        namedParameters.enabled === undefined ||
                        namedParameters.enabled;
                    // }
                    if (verified) {
                        const aura = this.ovaleAura.getAuraByGUID(
                            this.ovale.playerGUID,
                            auraId,
                            filter,
                            false,
                            atTime
                        );
                        if (aura && this.ovaleAura.isActiveAura(aura, atTime)) {
                            const siAura = this.ovaleData.spellInfo[auraId];
                            if (
                                siAura &&
                                siAura.stacking &&
                                siAura.stacking > 0
                            ) {
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

    updateCounters(spellId: number, atTime: number, targetGUID: string) {
        return this.updateStateCounters(
            this.getState(atTime),
            spellId,
            atTime,
            targetGUID
        );
    }

    isActive(spellId: number) {
        for (const [, spellcast] of ipairs(this.lastSpell.queue)) {
            if (spellcast.spellId == spellId && spellcast.start) {
                return true;
            }
        }
        return false;
    }

    isInFlight(spellId: number) {
        return this.isActive(spellId);
    }

    updateLastSpellcast(atTime: number, spellcast: SpellCast) {
        this.current.lastCastTime[spellcast.spellId] = atTime;
        if (spellcast.castByPlayer) {
            if (spellcast.offgcd) {
                this.tracer.debug(
                    "    Caching spell %s (%d) as most recent off-GCD spellcast.",
                    spellcast.spellName,
                    spellcast.spellId
                );
                for (const [k, v] of kpairs(spellcast)) {
                    (<any>this.current.lastOffGCDSpellcast)[k] = v;
                }
                this.lastSpell.lastSpellcast = this.current.lastOffGCDSpellcast;
                this.next.lastOffGCDSpellcast =
                    this.current.lastOffGCDSpellcast;
            } else {
                this.tracer.debug(
                    "    Caching spell %s (%d) as most recent GCD spellcast.",
                    spellcast.spellName,
                    spellcast.spellId
                );
                for (const [k, v] of kpairs(spellcast)) {
                    (<any>this.lastSpell.lastGCDSpellcast)[k] = v;
                }
                this.lastSpell.lastSpellcast = this.lastSpell.lastGCDSpellcast;
                this.next.lastGCDSpellId =
                    this.lastSpell.lastGCDSpellcast.spellId;
            }
        }
    }

    updateSpellcastInfo(spellcast: SpellCast, atTime: number) {
        if (spellcast.queued) {
            if (spellcast.targetName) {
                this.tracer.debug(
                    "    Updating to state at time=%s for spell %s to %s (%s) queued at %s.",
                    atTime,
                    spellcast.spellName,
                    spellcast.targetName,
                    spellcast.target,
                    spellcast.queued
                );
            } else {
                this.tracer.debug(
                    "    Updating to state at time=%s for spell %s with no target queued at %s.",
                    atTime,
                    spellcast.spellName,
                    spellcast.queued
                );
            }
            this.lastSpell.saveSpellcastInfo(spellcast, atTime);
            if (spellcast.damageMultiplier != 1) {
                this.tracer.debug(
                    "        persistent multiplier = %f",
                    spellcast.damageMultiplier
                );
            }
        }
    }

    getCounter(id: number, atTime: number) {
        return this.getState(atTime).counter[id] || 0;
    }

    getTimeOfLastCast(spellId: number, atTime: number) {
        if (!atTime) return this.current.lastCastTime[spellId];
        return (
            this.next.lastCastTime[spellId] ||
            this.current.lastCastTime[spellId] ||
            0
        );
    }

    isChannelingAtTime(atTime: number) {
        return this.getState(atTime).isChanneling(atTime);
    }

    getCurrentCast(atTime: number) {
        if (
            atTime &&
            this.next.currentCast &&
            this.next.currentCast.start <= atTime &&
            this.next.currentCast.stop >= atTime
        ) {
            return this.next.currentCast;
        }

        for (const [, value] of ipairs(this.lastSpell.queue)) {
            if (
                value.start &&
                value.start <= atTime &&
                (!value.stop || value.stop >= atTime)
            ) {
                return value;
            }
        }
    }

    getGCD(atTime: number, spellId?: number, targetGUID?: string) {
        spellId = spellId || this.next.currentCast.spellId;
        targetGUID =
            targetGUID ||
            this.ovaleGuid.getUnitGUID(this.baseState.defaultTarget);
        let gcd =
            spellId &&
            this.ovaleData.getSpellInfoProperty(
                spellId,
                atTime,
                "gcd",
                targetGUID
            );
        if (!gcd) {
            let haste: HasteType;
            [gcd, haste] = this.ovaleCooldown.getBaseGCD();
            if (
                this.ovale.playerClass == "MONK" &&
                this.ovalePaperDoll.isSpecialization("mistweaver")
            ) {
                gcd = 1.5;
                haste = "spell";
            } else if (this.ovale.playerClass == "DRUID") {
                if (this.ovaleStance.isStance("druid_cat_form", atTime)) {
                    gcd = 1.0;
                    haste = "none";
                }
            }
            const gcdHaste =
                spellId &&
                this.ovaleData.getSpellInfoProperty(
                    spellId,
                    atTime,
                    "gcd_haste",
                    targetGUID
                );
            if (gcdHaste) {
                haste = gcdHaste;
            } else {
                const siHaste =
                    spellId &&
                    this.ovaleData.getSpellInfoProperty(
                        spellId,
                        atTime,
                        "haste",
                        targetGUID
                    );
                if (siHaste) {
                    haste = siHaste;
                }
            }
            const multiplier = this.ovalePaperDoll.getHasteMultiplier(
                haste,
                atTime
            );
            gcd = gcd / multiplier;
            gcd = (gcd > 0.75 && gcd) || 0.75;
        }
        return gcd;
    }

    initializeState() {
        this.next.lastCast = {};
        this.next.counter = {};
    }

    resetState() {
        const now = this.baseState.currentTime;
        this.tracer.log("Reset state with current time = %f", now);
        this.next.nextCast = now;
        wipe(this.next.lastCast);
        wipe(OvaleFutureClass.staticSpellcast);
        this.next.currentCast = OvaleFutureClass.staticSpellcast;
        let reason = "";
        const [start, duration] = this.ovaleCooldown.getGlobalCooldown(now);
        if (start && start > 0) {
            const ending = start + duration;
            if (this.next.nextCast < ending) {
                this.next.nextCast = ending;
                reason = " (waiting for GCD)";
            }
        }
        let lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound;
        for (let i = lualength(this.lastSpell.queue); i >= 1; i += -1) {
            const spellcast = this.lastSpell.queue[i];
            if (spellcast.spellId && spellcast.start) {
                this.tracer.log(
                    "    Found cast %d of spell %s (%d), start = %s, stop = %s.",
                    i,
                    spellcast.spellName,
                    spellcast.spellId,
                    spellcast.start,
                    spellcast.stop
                );
                if (!lastSpellcastFound) {
                    // this.next.lastCast = spellcast;
                    if (
                        spellcast.start &&
                        spellcast.stop &&
                        spellcast.start <= now &&
                        now < spellcast.stop
                    ) {
                        this.next.currentCast = spellcast;
                    }
                    lastSpellcastFound = true;
                }
                if (
                    !lastGCDSpellcastFound &&
                    !spellcast.offgcd &&
                    spellcast.castByPlayer
                ) {
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
            if (
                lastGCDSpellcastFound &&
                lastOffGCDSpellcastFound &&
                lastSpellcastFound
            ) {
                break;
            }
        }
        if (!lastSpellcastFound) {
            const spellcast = this.lastSpell.lastSpellcast;
            if (spellcast) {
                // this.next.lastCast = spellcast;
                if (
                    spellcast.start &&
                    spellcast.stop &&
                    spellcast.start <= now &&
                    now < spellcast.stop
                ) {
                    this.next.currentCast = spellcast;
                }
            }
        }
        if (!lastGCDSpellcastFound) {
            const spellcast = this.lastSpell.lastGCDSpellcast;
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
        this.tracer.log("    nextCast = %f%s", this.next.nextCast, reason);
        for (const [k, v] of pairs(this.current.counter)) {
            this.next.counter[k] = v;
        }
    }

    cleanState() {
        for (const [k] of pairs(this.next.lastCast)) {
            delete this.next.lastCast[k];
        }
        for (const [k] of pairs(this.next.counter)) {
            delete this.next.counter[k];
        }
    }

    applySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) => {
        if (channel) {
            this.updateCounters(spellId, startCast, targetGUID);
        }
    };

    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) => {
        if (!channel) {
            this.updateCounters(spellId, endCast, targetGUID);
        }
    };

    static staticSpellcast: SpellCast = createSpellCast();

    applySpell(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast?: number,
        channel?: boolean,
        spellcast?: SpellCast
    ) {
        channel = channel || false;
        if (spellId) {
            if (!targetGUID) {
                targetGUID = this.ovale.playerGUID;
            }
            let castTime;
            if (startCast && endCast) {
                castTime = endCast - startCast;
            } else {
                castTime = this.ovaleSpellBook.getCastTime(spellId) || 0;
                startCast = startCast || this.next.nextCast;
                endCast = endCast || startCast + castTime;
            }
            if (!spellcast) {
                spellcast = OvaleFutureClass.staticSpellcast;
                wipe(spellcast);
                spellcast.caster = this.ovale.playerGUID;
                spellcast.castByPlayer = true;
                spellcast.spellId = spellId;
                spellcast.spellName =
                    this.ovaleSpellBook.getSpellName(spellId) ||
                    "unknown spell";
                spellcast.target = targetGUID;
                spellcast.targetName =
                    this.ovaleGuid.getNameByGUID(targetGUID) || "target";
                spellcast.start = startCast;
                spellcast.stop = endCast;
                spellcast.channel = channel;
                const atTime = (channel && startCast) || endCast;
                this.lastSpell.saveSpellcastInfo(spellcast, atTime);
            }
            // this.next.lastCast = this.next.currentCast;
            if (spellcast.castByPlayer) {
                this.next.currentCast = spellcast;
                this.next.lastCast[spellId] = endCast;
                const gcd = this.getGCD(spellId, startCast, targetGUID);
                const nextCast = (castTime > gcd && endCast) || startCast + gcd;
                if (this.next.nextCast < nextCast) {
                    this.next.nextCast = nextCast;
                }

                this.tracer.log(
                    "Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s",
                    spellId,
                    startCast,
                    this.baseState.currentTime,
                    nextCast,
                    endCast,
                    targetGUID
                );
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

            if (startCast > this.baseState.currentTime) {
                this.ovaleState.applySpellStartCast(
                    spellId,
                    targetGUID,
                    startCast,
                    endCast,
                    channel,
                    spellcast
                );
            }
            if (endCast > this.baseState.currentTime) {
                this.ovaleState.applySpellAfterCast(
                    spellId,
                    targetGUID,
                    startCast,
                    endCast,
                    channel,
                    spellcast
                );
            }
            this.ovaleState.applySpellOnHit(
                spellId,
                targetGUID,
                startCast,
                endCast,
                channel,
                spellcast
            );
        }
    }

    applyInFlightSpells() {
        const now = GetTime();
        let index = 1;
        while (index <= lualength(this.lastSpell.queue)) {
            const spellcast = this.lastSpell.queue[index];
            this.tracer.log(
                "Spell cast %s %d %d",
                spellcast.spellName,
                spellcast.spellId,
                spellcast.stop
            );
            if (spellcast.stop) {
                let isValid = false;
                let description;
                if (now < spellcast.stop) {
                    isValid = true;
                    description =
                        (spellcast.channel && "channelling") || "being cast";
                } else if (now < spellcast.stop + 5) {
                    isValid = true;
                    description = "in flight";
                }
                if (isValid) {
                    if (spellcast.target) {
                        this.tracer.log(
                            "Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f, start=%f",
                            spellcast.spellName,
                            spellcast.spellId,
                            description,
                            spellcast.targetName,
                            spellcast.target,
                            now,
                            spellcast.stop,
                            spellcast.start
                        );
                    } else {
                        this.tracer.log(
                            "Active spell %s (%d) is %s, now=%f, endCast=%f, start=%f",
                            spellcast.spellName,
                            spellcast.spellId,
                            description,
                            now,
                            spellcast.stop,
                            spellcast.start
                        );
                    }
                    this.applySpell(
                        spellcast.spellId,
                        spellcast.target,
                        spellcast.start,
                        spellcast.stop,
                        spellcast.channel,
                        spellcast
                    );
                } else {
                    if (spellcast.target) {
                        this.tracer.debug(
                            "Warning: removing active spell %s (%d) to %s (%s) that should have finished.",
                            spellcast.spellName,
                            spellcast.spellId,
                            spellcast.targetName,
                            spellcast.target
                        );
                    } else {
                        this.tracer.debug(
                            "Warning: removing active spell %s (%d) that should have finished.",
                            spellcast.spellName,
                            spellcast.spellId
                        );
                    }
                    remove(this.lastSpell.queue, index);
                    lastSpellCastPool.release(spellcast);
                    index = index - 1;
                }
            }
            index = index + 1;
        }
    }
}
