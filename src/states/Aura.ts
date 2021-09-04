import { l } from "../ui/Localization";
import { DebugTools, Tracer } from "../engine/debug";
import { OvalePool } from "../tools/Pool";
import {
    AuraAppliedPayload,
    AuraAppliedDosePayload,
    AuraRemovedPayload,
    AuraRemovedDosePayload,
    AuraRefreshPayload,
    CombatLogEvent,
    SpellPayloadHeader,
} from "../engine/combat-log-event";
import {
    OvaleDataClass,
    SpellAddAurasByType,
    AuraType,
    SpellInfo,
} from "../engine/data";
import { Guids } from "../engine/guid";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleStateClass, StateModule, States } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { LastSpell, SpellCast } from "./LastSpell";
import { OvalePowerClass } from "./Power";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    pairs,
    tonumber,
    wipe,
    lualength,
    LuaObj,
    next,
    LuaArray,
    kpairs,
} from "@wowts/lua";
import { lower } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetTime, UnitAura } from "@wowts/wow-mock";
import { huge as INFINITY, huge } from "@wowts/math";
import { OvalePaperDollClass } from "./PaperDoll";
import { isNumber, isString } from "../tools/tools";
import { ConditionResult } from "../engine/condition";
import { OvaleOptionsClass } from "../ui/Options";
import { AceModule } from "@wowts/tsaddon";
import { OptionUiAll } from "../ui/acegui-helpers";

let playerGUID = "fake_guid";
let petGUIDs: LuaObj<boolean> = {};
const pool = new OvalePool<Aura | LuaObj<Aura> | LuaObj<LuaObj<Aura>>>(
    "OvaleAura_pool"
);

type UnitAuraFilter =
    | "HARMFUL"
    | "HELPFUL"
    | "HARMFUL|PLAYER"
    | "HELPFUL|PLAYER";

const unknownGuid = "0";

export const debuffTypes: LuaObj<boolean> = {
    curse: true,
    disease: true,
    enrage: true,
    magic: true,
    poison: true,
};
export const spellInfoDebuffTypes: LuaObj<string> = {};

{
    for (const [debuffType] of pairs(debuffTypes)) {
        const siDebuffType = lower(debuffType);
        spellInfoDebuffTypes[siDebuffType] = debuffType;
    }
}
const spellAuraEvents: LuaObj<boolean> = {
    SPELL_AURA_APPLIED: true,
    SPELL_AURA_REMOVED: true,
    SPELL_AURA_APPLIED_DOSE: true,
    SPELL_AURA_REMOVED_DOSE: true,
    SPELL_AURA_REFRESH: true,
    SPELL_AURA_BROKEN: true,
    SPELL_AURA_BROKEN_SPELL: true,
};
const spellPeriodicEvents: LuaObj<boolean> = {
    SPELL_PERIODIC_DAMAGE: true,
    SPELL_PERIODIC_HEAL: true,
    SPELL_PERIODIC_ENERGIZE: true,
    SPELL_PERIODIC_DRAIN: true,
    SPELL_PERIODIC_LEECH: true,
};

const array = {};

//let CLEU_SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW);

export interface Aura extends SpellCast {
    serial: number;
    stacks: number;
    start: number;
    ending: number;
    debuffType: number | string | undefined;
    filter: AuraType;
    state: boolean;
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
    cooldownEnding: number;
    combopoints?: number;
    damageMultiplier?: number;
}

type AuraDB = LuaObj<LuaObj<LuaObj<Aura>>>;

/** Either a spell id or a spell list name */
type AuraId = number | string;

export function putAura(
    auraDB: AuraDB,
    guid: string,
    auraId: AuraId,
    casterGUID: string,
    aura: Aura
) {
    let auraForGuid = auraDB[guid];
    if (!auraForGuid) {
        auraForGuid = <LuaObj<LuaObj<Aura>>>pool.get();
        auraDB[guid] = auraForGuid;
    }
    let auraForId = auraForGuid[auraId];
    if (!auraForId) {
        auraForId = <LuaObj<Aura>>pool.get();
        auraForGuid[auraId] = auraForId;
    }
    const previousAura = auraForId[casterGUID];
    if (previousAura) {
        pool.release(previousAura);
    }
    auraForId[casterGUID] = aura;
    aura.guid = guid;
    aura.spellId = <number>auraId; // TODO
    aura.source = casterGUID;
}
export function getAura(
    auraDB: AuraDB,
    guid: string,
    auraId: AuraId,
    casterGUID: string
) {
    if (
        auraDB[guid] &&
        auraDB[guid][auraId] &&
        auraDB[guid][auraId][casterGUID]
    ) {
        return auraDB[guid][auraId][casterGUID];
    }
}

function getAuraAnyCaster(auraDB: AuraDB, guid: string, auraId: AuraId) {
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

function getDebuffType(
    auraDB: AuraDB,
    guid: string,
    debuffType: AuraId,
    filter: string,
    casterGUID: string
) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [, whoseTable] of pairs(auraDB[guid])) {
            const aura = whoseTable[casterGUID];
            if (
                aura &&
                aura.debuffType == debuffType &&
                aura.filter == filter
            ) {
                if (!auraFound || auraFound.ending < aura.ending) {
                    auraFound = aura;
                }
            }
        }
    }
    return auraFound;
}

function getDebuffTypeAnyCaster(
    auraDB: AuraDB,
    guid: string,
    debuffType: AuraId,
    filter: string
) {
    let auraFound;
    if (auraDB[guid]) {
        for (const [, whoseTable] of pairs(auraDB[guid])) {
            for (const [, aura] of pairs(whoseTable)) {
                if (
                    aura &&
                    aura.debuffType == debuffType &&
                    aura.filter == filter
                ) {
                    if (!auraFound || auraFound.ending < aura.ending) {
                        auraFound = aura;
                    }
                }
            }
        }
    }
    return auraFound;
}
function getAuraOnGUID(
    auraDB: AuraDB,
    guid: string,
    auraId: AuraId,
    filter: string,
    mine: boolean
) {
    let auraFound: Aura | undefined;
    if (debuffTypes[auraId]) {
        if (mine && playerGUID) {
            auraFound = getDebuffType(auraDB, guid, auraId, filter, playerGUID);
            if (!auraFound) {
                for (const [petGUID] of pairs(petGUIDs)) {
                    const aura = getDebuffType(
                        auraDB,
                        guid,
                        auraId,
                        filter,
                        petGUID
                    );
                    if (
                        aura &&
                        (!auraFound || auraFound.ending < aura.ending)
                    ) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = getDebuffTypeAnyCaster(auraDB, guid, auraId, filter);
        }
    } else {
        if (mine && playerGUID) {
            auraFound = getAura(auraDB, guid, auraId, playerGUID);
            if (!auraFound) {
                for (const [petGUID] of pairs(petGUIDs)) {
                    const aura = getAura(auraDB, guid, auraId, petGUID);
                    if (
                        aura &&
                        (!auraFound || auraFound.ending < aura.ending)
                    ) {
                        auraFound = aura;
                    }
                }
            }
        } else {
            auraFound = getAuraAnyCaster(auraDB, guid, auraId);
        }
    }
    return auraFound;
}

export function removeAurasOnGUID(auraDB: AuraDB, guid: string) {
    if (auraDB[guid]) {
        const auraTable = auraDB[guid];
        for (const [auraId, whoseTable] of pairs(auraTable)) {
            for (const [casterGUID, aura] of pairs(whoseTable)) {
                pool.release(aura);
                delete whoseTable[casterGUID];
            }
            pool.release(whoseTable);
            delete auraTable[auraId];
        }
        pool.release(auraTable);
        delete auraDB[guid];
    }
}

class AuraInterface {
    aura: AuraDB = {};
    serial: LuaObj<number> = {};
    auraSerial = 0;
}

let count: number;
let stacks: number;
let startChangeCount, endingChangeCount: number;
let startFirst: number, endingLast: number;

export class OvaleAuraClass
    extends States<AuraInterface>
    implements StateModule
{
    private debug: Tracer;
    private module: AceModule & AceEvent;

    constructor(
        private ovaleState: OvaleStateClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleData: OvaleDataClass,
        private ovaleGuid: Guids,
        private lastSpell: LastSpell,
        private ovaleOptions: OvaleOptionsClass,
        private ovaleDebug: DebugTools,
        private ovale: OvaleClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovalePower: OvalePowerClass,
        private combatLogEvent: CombatLogEvent
    ) {
        super(AuraInterface);
        this.module = ovale.createModule(
            "OvaleAura",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create("OvaleAura");
        this.ovaleState.registerState(this);
        this.addDebugOptions();
    }

    isWithinAuraLag(time1: number, time2: number, factor?: number) {
        factor = factor || 1;
        const auraLag = this.ovaleOptions.db.profile.apparence.auraLag;
        const tolerance = (factor * auraLag) / 1000;
        return time1 - time2 < tolerance && time2 - time1 < tolerance;
    }

    private countMatchingActiveAura(aura: Aura) {
        this.debug.log(
            "Counting aura %s found on %s with (%s, %s)",
            aura.spellId,
            aura.guid,
            aura.start,
            aura.ending
        );
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
        const output: LuaArray<string> = {};
        const debugOptions: LuaObj<OptionUiAll> = {
            playerAura: {
                name: l["auras_player"],
                type: "group",
                args: {
                    buff: {
                        name: l["auras_on_player"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: LuaArray<string>) => {
                            wipe(output);
                            const now = GetTime();
                            const helpful = this.debugUnitAuras(
                                "player",
                                "HELPFUL",
                                now
                            );
                            if (helpful) {
                                output[lualength(output) + 1] = "== BUFFS ==";
                                output[lualength(output) + 1] = helpful;
                            }
                            const harmful = this.debugUnitAuras(
                                "player",
                                "HARMFUL",
                                now
                            );
                            if (harmful) {
                                output[lualength(output) + 1] = "== DEBUFFS ==";
                                output[lualength(output) + 1] = harmful;
                            }
                            return concat(output, "\n");
                        },
                    },
                },
            },
            targetAura: {
                name: l["auras_target"],
                type: "group",
                args: {
                    targetbuff: {
                        name: l["auras_on_target"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: LuaArray<string>) => {
                            wipe(output);
                            const now = GetTime();
                            const helpful = this.debugUnitAuras(
                                "target",
                                "HELPFUL",
                                now
                            );
                            if (helpful) {
                                output[lualength(output) + 1] = "== BUFFS ==";
                                output[lualength(output) + 1] = helpful;
                            }
                            const harmful = this.debugUnitAuras(
                                "target",
                                "HARMFUL",
                                now
                            );
                            if (harmful) {
                                output[lualength(output) + 1] = "== DEBUFFS ==";
                                output[lualength(output) + 1] = harmful;
                            }
                            return concat(output, "\n");
                        },
                    },
                },
            },
        };
        for (const [k, v] of pairs(debugOptions)) {
            this.ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private handleInitialize = () => {
        playerGUID = this.ovale.playerGUID;
        petGUIDs = this.ovaleGuid.petGUID;
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handlePlayerEnteringWorld
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
        this.module.RegisterEvent("UNIT_AURA", this.handleUnitAura);
        this.module.RegisterMessage(
            "Ovale_GroupChanged",
            this.handleOvaleGroupChanged
        );
        this.module.RegisterMessage(
            "Ovale_UnitChanged",
            this.handleUnitChanged
        );
        this.combatLogEvent.registerEvent(
            "SPELL_MISSED",
            this,
            this.handleCombatLogEvent
        );
        for (const [event] of pairs(spellAuraEvents)) {
            this.combatLogEvent.registerEvent(
                event,
                this,
                this.handleCombatLogEvent
            );
        }
        for (const [event] of pairs(spellPeriodicEvents)) {
            this.combatLogEvent.registerEvent(
                event,
                this,
                this.handleCombatLogEvent
            );
        }
    };

    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterEvent("PLAYER_UNGHOST");
        this.module.UnregisterEvent("UNIT_AURA");
        this.module.UnregisterMessage("Ovale_GroupChanged");
        this.module.UnregisterMessage("Ovale_UnitChanged");
        this.combatLogEvent.unregisterAllEvents(this);
        pool.drain();
    };

    private handleCombatLogEvent = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        const sourceGUID = cleu.sourceGUID;
        const destGUID = cleu.sourceGUID;
        const mine =
            sourceGUID == playerGUID ||
            this.ovaleGuid.getOwnerGUIDByGUID(sourceGUID) == playerGUID;
        if (mine && cleuEvent == "SPELL_MISSED") {
            const [unitId] = this.ovaleGuid.getUnitByGUID(destGUID);
            if (unitId) {
                this.debug.debugTimestamp(
                    "%s: %s (%s)",
                    cleuEvent,
                    destGUID,
                    unitId
                );
                this.scanAuras(unitId, destGUID);
            }
        } else if (spellAuraEvents[cleuEvent]) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            const spellName = header.spellName;
            this.ovaleData.registerAuraSeen(spellId);
            const [unitId] = this.ovaleGuid.getUnitByGUID(destGUID);
            if (unitId) {
                this.debug.debugTimestamp("UnitId: ", unitId);
                if (!this.ovaleGuid.unitAuraUnits[unitId]) {
                    this.debug.debugTimestamp(
                        "%s: %s (%s)",
                        cleuEvent,
                        destGUID,
                        unitId
                    );
                    this.scanAuras(unitId, destGUID);
                }
            } else if (mine) {
                this.debug.debugTimestamp(
                    "%s: %s (%d) on %s",
                    cleuEvent,
                    spellName,
                    spellId,
                    destGUID
                );
                const now = GetTime();
                if (
                    cleuEvent == "SPELL_AURA_REMOVED" ||
                    cleuEvent == "SPELL_AURA_BROKEN" ||
                    cleuEvent == "SPELL_AURA_BROKEN_SPELL"
                ) {
                    this.lostAuraOnGUID(destGUID, now, spellId, sourceGUID);
                } else {
                    const suffix = cleu.payload.type;
                    let auraType = undefined;
                    if (suffix == "AURA_APPLIED") {
                        const payload = cleu.payload as AuraAppliedPayload;
                        auraType = payload.auraType;
                    } else if (suffix == "AURA_REMOVED") {
                        const payload = cleu.payload as AuraRemovedPayload;
                        auraType = payload.auraType;
                    } else if (suffix == "AURA_APPLIED_DOSE") {
                        const payload = cleu.payload as AuraAppliedDosePayload;
                        auraType = payload.auraType;
                    } else if (suffix == "AURA_REMOVED_DOSE") {
                        const payload = cleu.payload as AuraRemovedDosePayload;
                        auraType = payload.auraType;
                    } else if (suffix == "AURA_REFRESH") {
                        const payload = cleu.payload as AuraRefreshPayload;
                        auraType = payload.auraType;
                    }
                    const filter: AuraType =
                        (auraType && auraType == "BUFF" && "HELPFUL") ||
                        "HARMFUL";
                    const si = this.ovaleData.spellInfo[spellId];
                    const aura = getAuraOnGUID(
                        this.current.aura,
                        destGUID,
                        spellId,
                        filter,
                        true
                    );
                    let duration = 15;
                    if (aura) {
                        duration = aura.duration;
                    } else if (si && si.duration) {
                        [duration] = this.ovaleData.getSpellInfoPropertyNumber(
                            spellId,
                            now,
                            "duration",
                            destGUID
                        ) || [15];
                    }
                    const expirationTime = now + duration;
                    let count = 1;
                    if (cleuEvent == "SPELL_AURA_APPLIED") {
                        count = 1;
                    } else if (cleuEvent == "SPELL_AURA_APPLIED_DOSE") {
                        const payload = cleu.payload as AuraAppliedDosePayload;
                        count = payload.amount;
                    } else if (cleuEvent == "SPELL_AURA_REMOVED_DOSE") {
                        const payload = cleu.payload as AuraRemovedDosePayload;
                        count = payload.amount;
                    } else if (cleuEvent == "SPELL_AURA_REFRESH") {
                        count = (aura && aura.stacks) || 1;
                    }
                    this.gainedAuraOnGUID(
                        destGUID,
                        now,
                        spellId,
                        sourceGUID,
                        filter,
                        true,
                        undefined,
                        count,
                        undefined,
                        duration,
                        expirationTime,
                        false,
                        spellName
                    );
                }
            }
        } else if (mine && spellPeriodicEvents[cleuEvent] && playerGUID) {
            const header = cleu.header as SpellPayloadHeader;
            const spellId = header.spellId;
            this.ovaleData.registerAuraSeen(spellId);
            this.debug.debugTimestamp("%s: %s", cleuEvent, destGUID);
            const aura = getAura(
                this.current.aura,
                destGUID,
                spellId,
                playerGUID
            );
            const now = GetTime();
            if (aura && this.isActiveAura(aura, now)) {
                const name = aura.name || "Unknown spell";
                let [baseTick, lastTickTime] = [
                    aura.baseTick,
                    aura.lastTickTime,
                ];
                let tick;
                if (lastTickTime) {
                    tick = now - lastTickTime;
                } else if (!baseTick) {
                    this.debug.debug(
                        "    First tick seen of unknown periodic aura %s (%d) on %s.",
                        name,
                        spellId,
                        destGUID
                    );
                    const si = this.ovaleData.spellInfo[spellId];
                    baseTick = (si && si.tick && si.tick) || 3;
                    tick = this.getTickLength(spellId);
                } else {
                    tick = baseTick;
                }
                aura.baseTick = baseTick;
                aura.lastTickTime = now;
                aura.tick = tick;
                this.debug.debug(
                    "    Updating %s (%s) on %s, tick=%s, lastTickTime=%s",
                    name,
                    spellId,
                    destGUID,
                    tick,
                    lastTickTime
                );
                this.ovale.refreshNeeded[destGUID] = true;
            }
        }
    };

    private handlePlayerEnteringWorld = (event: string) => {
        this.scanAllUnitAuras();
    };

    private handlePlayerRegenEnabled = (event: string) => {
        this.removeAurasOnInactiveUnits();
        pool.drain();
    };

    private handleUnitAura = (event: string, unitId: string) => {
        this.debug.debug(event, unitId);
        this.scanAuras(unitId);
    };

    private handleOvaleGroupChanged = () => this.scanAllUnitAuras();

    private handleUnitChanged = (
        event: string,
        unitId: string,
        guid: string
    ) => {
        if ((unitId == "pet" || unitId == "target") && guid) {
            this.debug.debug(event, unitId, guid);
            this.scanAuras(unitId, guid);
        }
    };

    private scanAllUnitAuras() {
        for (const [unitId] of pairs(this.ovaleGuid.unitAuraUnits)) {
            this.scanAuras(unitId);
        }
    }

    private removeAurasOnInactiveUnits() {
        for (const [guid] of pairs(this.current.aura)) {
            const unitId = this.ovaleGuid.getUnitByGUID(guid);
            if (!unitId) {
                this.debug.debug("Removing auras from GUID %s", guid);
                removeAurasOnGUID(this.current.aura, guid);
                delete this.current.serial[guid];
            }
        }
    }

    isActiveAura(aura: Aura, atTime: number): aura is Aura {
        let boolean = false;
        if (aura.state) {
            if (
                aura.serial == this.next.auraSerial &&
                aura.stacks > 0 &&
                aura.gain <= atTime &&
                atTime <= aura.ending
            ) {
                boolean = true;
            } else if (
                aura.consumed &&
                this.isWithinAuraLag(aura.ending, atTime)
            ) {
                boolean = true;
            }
        } else {
            if (
                aura.serial == this.current.serial[aura.guid] &&
                aura.stacks > 0 &&
                aura.gain <= atTime &&
                atTime <= aura.ending
            ) {
                boolean = true;
            } else if (
                aura.consumed &&
                this.isWithinAuraLag(aura.ending, atTime)
            ) {
                boolean = true;
            }
        }
        return boolean;
    }

    gainedAuraOnGUID(
        guid: string,
        atTime: number,
        auraId: number,
        casterGUID: string,
        filter: AuraType,
        visible: boolean,
        icon: string | undefined,
        count: number,
        debuffType: string | undefined,
        duration: number,
        expirationTime: number,
        isStealable: boolean,
        name: string,
        value1?: number,
        value2?: number,
        value3?: number
    ) {
        casterGUID = casterGUID || unknownGuid;
        count = (count && count > 0 && count) || 1;
        duration = (duration && duration > 0 && duration) || INFINITY;
        expirationTime =
            (expirationTime && expirationTime > 0 && expirationTime) ||
            INFINITY;
        let aura = getAura(this.current.aura, guid, auraId, casterGUID);
        let auraIsActive;
        if (aura) {
            auraIsActive =
                aura.stacks > 0 && aura.gain <= atTime && atTime <= aura.ending;
        } else {
            aura = <Aura>pool.get();
            putAura(this.current.aura, guid, auraId, casterGUID, aura);
            auraIsActive = false;
        }
        const auraIsUnchanged =
            aura.source == casterGUID &&
            aura.duration == duration &&
            aura.ending == expirationTime &&
            aura.stacks == count &&
            aura.value1 == value1 &&
            aura.value2 == value2 &&
            aura.value3 == value3;
        aura.serial = this.current.serial[guid];
        if (!auraIsActive || !auraIsUnchanged) {
            this.debug.debug(
                "    Adding %s %s (%s) to %s at %f, aura.serial=%d, duration=%f, expirationTime=%f, auraIsActive=%s, auraIsUnchanged=%s",
                filter,
                name,
                auraId,
                guid,
                atTime,
                aura.serial,
                duration,
                expirationTime,
                (auraIsActive && "true") || "false",
                (auraIsUnchanged && "true") || "false"
            );
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
            aura.debuffType =
                (isString(debuffType) && lower(debuffType)) || debuffType;
            aura.stealable = isStealable;
            [aura.value1, aura.value2, aura.value3] = [value1, value2, value3];
            const mine =
                casterGUID == playerGUID ||
                this.ovaleGuid.getOwnerGUIDByGUID(casterGUID) == playerGUID;
            if (mine) {
                let spellcast = this.lastSpell.lastInFlightSpell();
                if (
                    spellcast &&
                    spellcast.stop &&
                    !this.isWithinAuraLag(spellcast.stop, atTime)
                ) {
                    spellcast = this.lastSpell.lastSpellcast;
                    if (
                        spellcast &&
                        spellcast.stop &&
                        !this.isWithinAuraLag(spellcast.stop, atTime)
                    ) {
                        spellcast = undefined;
                    }
                }
                if (spellcast && spellcast.targetGuid == guid) {
                    const spellId = spellcast.spellId;
                    const spellName =
                        this.ovaleSpellBook.getSpellName(spellId) ||
                        "Unknown spell";
                    this.debug.debug(
                        "    Snapshot stats for %s %s (%d) on %s applied by %s (%d), aura.serial=%d",
                        filter,
                        name,
                        auraId,
                        guid,
                        spellName,
                        spellId,
                        aura.serial
                    );
                    this.lastSpell.copySpellcastInfo(spellcast, aura);
                }
                const si = this.ovaleData.spellInfo[auraId];
                if (si) {
                    if (si.tick) {
                        this.debug.debug(
                            "    %s (%s) is a periodic aura.",
                            name,
                            auraId
                        );
                        if (!auraIsActive) {
                            aura.baseTick = si.tick;
                            if (spellcast && spellcast.targetGuid == guid) {
                                aura.tick = this.getTickLength(auraId, atTime);
                            } else {
                                aura.tick = this.getTickLength(auraId);
                            }
                        }
                    }
                    if (si.buff_cd && guid == playerGUID) {
                        this.debug.debug(
                            "    %s (%s) is applied by an item with a cooldown of %ds.",
                            name,
                            auraId,
                            si.buff_cd
                        );
                        if (!auraIsActive) {
                            aura.cooldownEnding = aura.gain + si.buff_cd;
                        }
                    }
                }
            }
            if (!auraIsActive) {
                this.module.SendMessage(
                    "Ovale_AuraAdded",
                    atTime,
                    guid,
                    auraId,
                    aura.source
                );
            } else if (!auraIsUnchanged) {
                this.module.SendMessage(
                    "Ovale_AuraChanged",
                    atTime,
                    guid,
                    auraId,
                    aura.source
                );
            }
            this.ovale.refreshNeeded[guid] = true;
        }
    }
    lostAuraOnGUID(
        guid: string,
        atTime: number,
        auraId: AuraId,
        casterGUID: string
    ) {
        const aura = getAura(this.current.aura, guid, auraId, casterGUID);
        if (aura) {
            const filter = aura.filter;
            this.debug.debug(
                "    Expiring %s %s (%d) from %s at %f.",
                filter,
                aura.name,
                auraId,
                guid,
                atTime
            );
            if (aura.ending > atTime) {
                aura.ending = atTime;
            }
            const mine =
                casterGUID == playerGUID ||
                this.ovaleGuid.getOwnerGUIDByGUID(casterGUID) == playerGUID;
            if (mine) {
                aura.baseTick = undefined;
                aura.lastTickTime = undefined;
                aura.tick = undefined;
                if (aura.start + aura.duration > aura.ending) {
                    let spellcast: SpellCast | undefined;
                    if (guid == playerGUID) {
                        spellcast = this.lastSpell.lastSpellSent();
                    } else {
                        spellcast = this.lastSpell.lastSpellcast;
                    }
                    if (spellcast) {
                        if (
                            (spellcast.success &&
                                spellcast.stop &&
                                this.isWithinAuraLag(
                                    spellcast.stop,
                                    aura.ending
                                )) ||
                            (spellcast.queued &&
                                this.isWithinAuraLag(
                                    spellcast.queued,
                                    aura.ending
                                ))
                        ) {
                            aura.consumed = true;
                            const spellName =
                                this.ovaleSpellBook.getSpellName(
                                    spellcast.spellId
                                ) || "Unknown spell";
                            this.debug.debug(
                                "    Consuming %s %s (%d) on %s with queued %s (%d) at %f.",
                                filter,
                                aura.name,
                                auraId,
                                guid,
                                spellName,
                                spellcast.spellId,
                                spellcast.queued
                            );
                        }
                    }
                }
            }
            aura.lastUpdated = atTime;
            this.module.SendMessage(
                "Ovale_AuraRemoved",
                atTime,
                guid,
                auraId,
                aura.source
            );
            this.ovale.refreshNeeded[guid] = true;
        }
    }
    scanAuras(unitId: string, guid?: string) {
        guid = guid || this.ovaleGuid.getUnitGUID(unitId);
        if (guid) {
            const harmfulFilter: UnitAuraFilter =
                (this.ovaleOptions.db.profile.apparence.fullAuraScan &&
                    "HARMFUL") ||
                "HARMFUL|PLAYER";
            const helpfulFilter: UnitAuraFilter =
                (this.ovaleOptions.db.profile.apparence.fullAuraScan &&
                    "HELPFUL") ||
                "HELPFUL|PLAYER";
            this.debug.debugTimestamp(
                "Scanning auras on %s (%s)",
                guid,
                unitId
            );
            let serial = this.current.serial[guid] || 0;
            serial = serial + 1;
            this.debug.debug(
                "    Advancing age of auras for %s (%s) to %d.",
                guid,
                unitId,
                serial
            );
            this.current.serial[guid] = serial;
            let i = 1;
            let filter: UnitAuraFilter = helpfulFilter;
            const now = GetTime();
            while (true) {
                let [
                    name,
                    icon,
                    count,
                    debuffType,
                    duration,
                    expirationTime,
                    unitCaster,
                    isStealable,
                    ,
                    spellId,
                    ,
                    ,
                    ,
                    value1,
                    value2,
                    value3,
                ] = UnitAura(unitId, i, filter);
                if (!name) {
                    if (filter == helpfulFilter) {
                        filter = harmfulFilter;
                        i = 1;
                    } else {
                        break;
                    }
                } else {
                    const casterGUID =
                        unitCaster && this.ovaleGuid.getUnitGUID(unitCaster);
                    if (casterGUID) {
                        if (debuffType == "") {
                            debuffType = "enrage";
                        }
                        const auraType: AuraType =
                            (filter === harmfulFilter && "HARMFUL") ||
                            "HELPFUL";
                        this.gainedAuraOnGUID(
                            guid,
                            now,
                            spellId,
                            casterGUID,
                            auraType,
                            true,
                            icon,
                            count,
                            debuffType,
                            duration,
                            expirationTime,
                            isStealable,
                            name,
                            value1,
                            value2,
                            value3
                        );
                    }
                    i = i + 1;
                }
            }
            if (this.current.aura[guid]) {
                const auraTable = this.current.aura[guid];
                for (const [auraId, whoseTable] of pairs(auraTable)) {
                    for (const [casterGUID, aura] of pairs(whoseTable)) {
                        if (aura.serial == serial - 1) {
                            if (aura.visible) {
                                this.lostAuraOnGUID(
                                    guid,
                                    now,
                                    tonumber(auraId),
                                    casterGUID
                                );
                            } else {
                                aura.serial = serial;
                                this.debug.debug(
                                    "    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d",
                                    aura.name,
                                    aura.spellId,
                                    aura.start,
                                    aura.ending,
                                    aura.serial
                                );
                            }
                        }
                    }
                }
            }
            this.debug.debug("End scanning of auras on %s (%s).", guid, unitId);
        }
    }

    getStateAura(
        guid: string,
        auraId: AuraId,
        casterGUID: string,
        atTime: number
    ) {
        const state = this.getState(atTime);
        let aura = getAura(state.aura, guid, auraId, casterGUID);
        if (atTime && (!aura || aura.serial < this.next.auraSerial)) {
            aura = getAura(this.current.aura, guid, auraId, casterGUID);
        }
        if (aura) {
            this.debug.log("Found aura with stack = %d", aura.stacks);
        }
        return aura;
    }

    debugUnitAuras(unitId: string, filter: AuraType, atTime: number) {
        wipe(array);
        const guid = this.ovaleGuid.getUnitGUID(unitId);
        if (atTime && guid && this.next.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (
                        this.isActiveAura(aura, atTime) &&
                        aura.filter == filter &&
                        !aura.state
                    ) {
                        const name = aura.name || "Unknown spell";
                        insert(
                            array,
                            `${name}: ${auraId} ${
                                aura.debuffType || "nil"
                            } enrage=${(aura.debuffType == "enrage" && 1) || 0}`
                        );
                    }
                }
            }
        }
        if (guid && this.current.aura[guid]) {
            for (const [auraId, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (
                        this.isActiveAura(aura, atTime) &&
                        aura.filter == filter
                    ) {
                        const name = aura.name || "Unknown spell";
                        insert(
                            array,
                            `${name}: ${auraId} ${
                                aura.debuffType || "nil"
                            } enrage=${(aura.debuffType == "enrage" && 1) || 0}`
                        );
                    }
                }
            }
        }
        if (next(array)) {
            sort(array);
            return concat(array, "\n");
        }
    }

    getStateAuraAnyCaster(
        guid: string,
        auraId: number | string,
        atTime: number
    ) {
        let auraFound;
        if (this.current.aura[guid] && this.current.aura[guid][auraId]) {
            for (const [, aura] of pairs(this.current.aura[guid][auraId])) {
                if (aura && !aura.state && this.isActiveAura(aura, atTime)) {
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

    getStateDebuffType(
        guid: string,
        debuffType: number | string,
        filter: AuraType | undefined,
        casterGUID: string,
        atTime: number
    ) {
        let auraFound: Aura | undefined = undefined;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                const aura = whoseTable[casterGUID];
                if (aura && !aura.state && this.isActiveAura(aura, atTime)) {
                    if (
                        aura.debuffType == debuffType &&
                        aura.filter == filter
                    ) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
        if (atTime && this.next.aura[guid]) {
            for (const [, whoseTable] of pairs(this.next.aura[guid])) {
                const aura = whoseTable[casterGUID];
                if (aura && aura.stacks > 0) {
                    if (
                        aura.debuffType == debuffType &&
                        aura.filter == filter
                    ) {
                        if (!auraFound || auraFound.ending < aura.ending) {
                            auraFound = aura;
                        }
                    }
                }
            }
        }
        return auraFound;
    }
    getStateDebuffTypeAnyCaster(
        guid: string,
        debuffType: number | string,
        filter: AuraType | undefined,
        atTime: number
    ) {
        let auraFound;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (
                        aura &&
                        !aura.state &&
                        this.isActiveAura(aura, atTime)
                    ) {
                        if (
                            aura.debuffType == debuffType &&
                            aura.filter == filter
                        ) {
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
                        if (
                            aura.debuffType == debuffType &&
                            aura.filter == filter
                        ) {
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
    getStateAuraOnGUID(
        guid: string,
        auraId: AuraId,
        filter: AuraType | undefined,
        mine: boolean | undefined,
        atTime: number
    ) {
        let auraFound: Aura | undefined = undefined;
        if (debuffTypes[auraId]) {
            if (mine) {
                auraFound = this.getStateDebuffType(
                    guid,
                    auraId,
                    filter,
                    playerGUID,
                    atTime
                );
                if (!auraFound) {
                    for (const [petGUID] of pairs(petGUIDs)) {
                        const aura = this.getStateDebuffType(
                            guid,
                            auraId,
                            filter,
                            petGUID,
                            atTime
                        );
                        if (
                            aura &&
                            (!auraFound || auraFound.ending < aura.ending)
                        ) {
                            auraFound = aura;
                        }
                    }
                }
            } else {
                auraFound = this.getStateDebuffTypeAnyCaster(
                    guid,
                    auraId,
                    filter,
                    atTime
                );
            }
        } else {
            if (mine) {
                let aura = this.getStateAura(guid, auraId, playerGUID, atTime);
                if (aura && aura.stacks > 0) {
                    auraFound = aura;
                } else {
                    for (const [petGUID] of pairs(petGUIDs)) {
                        aura = this.getStateAura(guid, auraId, petGUID, atTime);
                        if (aura && aura.stacks > 0) {
                            auraFound = aura;
                            break;
                        }
                    }
                }
            } else {
                auraFound = this.getStateAuraAnyCaster(guid, auraId, atTime);
            }
        }
        return auraFound;
    }

    getAuraByGUID(
        guid: string,
        auraId: AuraId,
        filter: AuraType | undefined,
        mine: boolean | undefined,
        atTime: number
    ) {
        let auraFound: Aura | undefined = undefined;
        if (this.ovaleData.buffSpellList[auraId]) {
            for (const [id] of pairs(this.ovaleData.buffSpellList[auraId])) {
                // TODO check this tostring(id)
                const aura = this.getStateAuraOnGUID(
                    guid,
                    id,
                    filter,
                    mine,
                    atTime
                );
                if (aura && (!auraFound || auraFound.ending < aura.ending)) {
                    this.debug.log(
                        "Aura %s matching '%s' found on %s with (%s, %s)",
                        id,
                        auraId,
                        guid,
                        aura.start,
                        aura.ending
                    );
                    auraFound = aura;
                }
            }
            if (!auraFound) {
                this.debug.log(
                    "Aura matching '%s' is missing on %s.",
                    auraId,
                    guid
                );
            }
        } else {
            auraFound = this.getStateAuraOnGUID(
                guid,
                auraId,
                filter,
                mine,
                atTime
            );
            if (auraFound) {
                this.debug.log(
                    "Aura %s found on %s with (%s, %s) [stacks=%d]",
                    auraId,
                    guid,
                    auraFound.start,
                    auraFound.ending,
                    auraFound.stacks
                );
            } else {
                this.debug.log(
                    "Aura %s is missing on %s (mine=%s).",
                    auraId,
                    guid,
                    mine
                );
            }
        }
        return auraFound;
    }

    getAura(
        unitId: string,
        auraId: AuraId,
        atTime: number,
        filter?: AuraType,
        mine?: boolean
    ) {
        const guid = this.ovaleGuid.getUnitGUID(unitId);
        if (!guid) return;
        if (isNumber(auraId)) this.ovaleData.registerAuraAsked(auraId);
        return this.getAuraByGUID(guid, auraId, filter, mine, atTime);
    }

    getAuraWithProperty(
        unitId: string,
        propertyName: keyof Aura,
        filter: AuraType,
        atTime: number
    ): ConditionResult {
        let count = 0;
        const guid = this.ovaleGuid.getUnitGUID(unitId);
        if (!guid) return [];
        let start: number = huge;
        let ending = 0;
        if (this.current.aura[guid]) {
            for (const [, whoseTable] of pairs(this.current.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.isActiveAura(aura, atTime) && !aura.state) {
                        if (aura[propertyName] && aura.filter == filter) {
                            count = count + 1;
                            start = (aura.gain < start && aura.gain) || start;
                            ending =
                                (aura.ending > ending && aura.ending) || ending;
                        }
                    }
                }
            }
        }
        if (this.next.aura[guid]) {
            for (const [, whoseTable] of pairs(this.next.aura[guid])) {
                for (const [, aura] of pairs(whoseTable)) {
                    if (this.isActiveAura(aura, atTime)) {
                        if (aura[propertyName] && aura.filter == filter) {
                            count = count + 1;
                            start = (aura.gain < start && aura.gain) || start;
                            ending =
                                (aura.ending > ending && aura.ending) || ending;
                        }
                    }
                }
            }
        }
        if (count > 0) {
            this.debug.log(
                "Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).",
                propertyName,
                unitId,
                count,
                start,
                ending
            );
        } else {
            this.debug.log(
                "Aura with '%s' property is missing on %s.",
                propertyName,
                unitId
            );
            return [];
        }
        return [start, ending];
    }

    auraCount(
        auraId: number,
        filter: AuraType | undefined,
        mine: boolean,
        minStacks: number | undefined,
        atTime: number,
        excludeUnitId: string | undefined
    ) {
        minStacks = minStacks || 1;
        count = 0;
        stacks = 0;
        [startChangeCount, endingChangeCount] = [huge, huge];
        [startFirst, endingLast] = [huge, 0];
        const excludeGUID =
            (excludeUnitId && this.ovaleGuid.getUnitGUID(excludeUnitId)) ||
            undefined;
        for (const [guid, auraTable] of pairs(this.current.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine && playerGUID) {
                    let aura = this.getStateAura(
                        guid,
                        auraId,
                        playerGUID,
                        atTime
                    );
                    if (
                        aura &&
                        this.isActiveAura(aura, atTime) &&
                        aura.filter == filter &&
                        aura.stacks >= minStacks &&
                        !aura.state
                    ) {
                        this.countMatchingActiveAura(aura);
                    }
                    for (const [petGUID] of pairs(petGUIDs)) {
                        aura = this.getStateAura(guid, auraId, petGUID, atTime);
                        if (
                            aura &&
                            this.isActiveAura(aura, atTime) &&
                            aura.filter == filter &&
                            aura.stacks >= minStacks &&
                            !aura.state
                        ) {
                            this.countMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [casterGUID] of pairs(auraTable[auraId])) {
                        const aura = this.getStateAura(
                            guid,
                            auraId,
                            casterGUID,
                            atTime
                        );
                        if (
                            aura &&
                            this.isActiveAura(aura, atTime) &&
                            aura.filter == filter &&
                            aura.stacks >= minStacks &&
                            !aura.state
                        ) {
                            this.countMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        for (const [guid, auraTable] of pairs(this.next.aura)) {
            if (guid != excludeGUID && auraTable[auraId]) {
                if (mine) {
                    let aura = auraTable[auraId][playerGUID];
                    if (aura) {
                        if (
                            this.isActiveAura(aura, atTime) &&
                            aura.filter == filter &&
                            aura.stacks >= minStacks
                        ) {
                            this.countMatchingActiveAura(aura);
                        }
                    }
                    for (const [petGUID] of pairs(petGUIDs)) {
                        aura = auraTable[auraId][petGUID];
                        if (
                            aura &&
                            this.isActiveAura(aura, atTime) &&
                            aura.filter == filter &&
                            aura.stacks >= minStacks &&
                            !aura.state
                        ) {
                            this.countMatchingActiveAura(aura);
                        }
                    }
                } else {
                    for (const [, aura] of pairs(auraTable[auraId])) {
                        if (
                            aura &&
                            this.isActiveAura(aura, atTime) &&
                            aura.filter == filter &&
                            aura.stacks >= minStacks
                        ) {
                            this.countMatchingActiveAura(aura);
                        }
                    }
                }
            }
        }
        this.debug.log(
            "AuraCount(%d) is %s, %s, %s, %s, %s, %s",
            auraId,
            count,
            stacks,
            startChangeCount,
            endingChangeCount,
            startFirst,
            endingLast
        );
        return [
            count,
            stacks,
            startChangeCount,
            endingChangeCount,
            startFirst,
            endingLast,
        ];
    }

    initializeState() {
        this.next.aura = {};
        this.next.auraSerial = 0;
        playerGUID = this.ovale.playerGUID;
    }
    resetState() {
        this.next.auraSerial = this.next.auraSerial + 1;
        if (next(this.next.aura)) {
            this.debug.log("Resetting aura state:");
        }
        for (const [guid, auraTable] of pairs(this.next.aura)) {
            for (const [auraId, whoseTable] of pairs(auraTable)) {
                for (const [casterGUID, aura] of pairs(whoseTable)) {
                    pool.release(aura);
                    delete whoseTable[casterGUID];
                    this.debug.log("    Aura %d on %s removed.", auraId, guid);
                }
                if (!next(whoseTable)) {
                    pool.release(whoseTable);
                    delete auraTable[auraId];
                }
            }
            if (!next(auraTable)) {
                pool.release(auraTable);
                delete this.next.aura[guid];
            }
        }
    }
    cleanState() {
        for (const [guid] of pairs(this.next.aura)) {
            removeAurasOnGUID(this.next.aura, guid);
        }
    }
    applySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        if (isChanneled) {
            const si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.applySpellAuras(
                        spellId,
                        playerGUID,
                        startCast,
                        si.aura.player,
                        spellcast
                    );
                }
                if (si.aura.target) {
                    this.applySpellAuras(
                        spellId,
                        targetGUID,
                        startCast,
                        si.aura.target,
                        spellcast
                    );
                }
                if (si.aura.pet) {
                    const petGUID = this.ovaleGuid.getUnitGUID("pet");
                    if (petGUID) {
                        this.applySpellAuras(
                            spellId,
                            petGUID,
                            startCast,
                            si.aura.pet,
                            spellcast
                        );
                    }
                }
            }
        }
    };
    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        if (!isChanneled) {
            const si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura) {
                if (si.aura.player) {
                    this.applySpellAuras(
                        spellId,
                        playerGUID,
                        endCast,
                        si.aura.player,
                        spellcast
                    );
                }
                if (si.aura.pet) {
                    const petGUID = this.ovaleGuid.getUnitGUID("pet");
                    if (petGUID) {
                        this.applySpellAuras(
                            spellId,
                            petGUID,
                            startCast,
                            si.aura.pet,
                            spellcast
                        );
                    }
                }
            }
        }
    };
    applySpellOnHit = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        if (!isChanneled) {
            const si = this.ovaleData.spellInfo[spellId];
            if (si && si.aura && si.aura.target) {
                let travelTime = si.travel_time || 0;
                if (travelTime > 0) {
                    const estimatedTravelTime = 1;
                    if (travelTime < estimatedTravelTime) {
                        travelTime = estimatedTravelTime;
                    }
                }
                const atTime = endCast + travelTime;
                this.applySpellAuras(
                    spellId,
                    targetGUID,
                    atTime,
                    si.aura.target,
                    spellcast
                );
            }
        }
    };

    private applySpellAuras(
        spellId: number,
        guid: string,
        atTime: number,
        auraList: SpellAddAurasByType,
        spellcast: SpellCast
    ) {
        for (const [filter, filterInfo] of kpairs(auraList)) {
            for (const [auraIdKey, spellData] of pairs(filterInfo)) {
                const auraId = tonumber(auraIdKey);
                const duration = this.getBaseDuration(
                    auraId,
                    spellId,
                    atTime,
                    spellcast
                );
                let stacks = 1;
                let count: number | undefined = undefined;
                let extend = 0;
                let toggle = undefined;
                let refresh = false;
                const data = this.ovaleData.checkSpellAuraData(
                    auraId,
                    spellData,
                    atTime,
                    guid
                );
                if (data.refresh) {
                    refresh = true;
                } else if (data.toggle) {
                    toggle = true;
                } else if (isNumber(data.set)) {
                    count = data.set;
                } else if (isNumber(data.extend)) {
                    extend = data.extend;
                } else if (isNumber(data.add)) {
                    stacks = data.add;
                } else {
                    this.debug.log("Aura has nothing defined");
                }
                if (data.enabled === undefined || data.enabled) {
                    const si = this.ovaleData.spellInfo[auraId];
                    const auraFound = this.getAuraByGUID(
                        guid,
                        auraId,
                        filter,
                        true,
                        atTime
                    );
                    if (auraFound && this.isActiveAura(auraFound, atTime)) {
                        let aura: Aura;
                        if (auraFound.state) {
                            aura = auraFound;
                        } else {
                            aura = this.addAuraToGUID(
                                guid,
                                auraId,
                                auraFound.source,
                                filter,
                                undefined,
                                0,
                                huge,
                                atTime
                            );
                            for (const [k, v] of kpairs(auraFound)) {
                                (<any>aura)[k] = v;
                            }
                            aura.serial = this.next.auraSerial;
                            this.debug.log(
                                "Aura %d is copied into simulator.",
                                auraId
                            );
                        }
                        if (toggle) {
                            this.debug.log(
                                "Aura %d is toggled off by spell %d.",
                                auraId,
                                spellId
                            );
                            stacks = 0;
                        }
                        if (count && count > 0) {
                            stacks = count - aura.stacks;
                        }
                        if (refresh || extend > 0 || stacks > 0) {
                            if (refresh) {
                                this.debug.log(
                                    "Aura %d is refreshed to %d stack(s).",
                                    auraId,
                                    aura.stacks
                                );
                            } else if (extend > 0) {
                                this.debug.log(
                                    "Aura %d is extended by %f seconds, preserving %d stack(s).",
                                    auraId,
                                    extend,
                                    aura.stacks
                                );
                            } else {
                                let maxStacks = 1;
                                if (si && si.max_stacks) {
                                    maxStacks = si.max_stacks;
                                }
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks > maxStacks) {
                                    aura.stacks = maxStacks;
                                }
                                this.debug.log(
                                    "Aura %d gains %d stack(s) to %d because of spell %d.",
                                    auraId,
                                    stacks,
                                    aura.stacks,
                                    spellId
                                );
                            }
                            if (extend > 0) {
                                aura.duration = aura.duration + extend;
                                aura.ending = aura.ending + extend;
                            } else {
                                aura.start = atTime;
                                if (aura.tick && aura.tick > 0) {
                                    const remainingDuration =
                                        aura.ending - atTime;
                                    const extensionDuration = 0.3 * duration;
                                    if (remainingDuration < extensionDuration) {
                                        aura.duration =
                                            remainingDuration + duration;
                                    } else {
                                        aura.duration =
                                            extensionDuration + duration;
                                    }
                                } else {
                                    aura.duration = duration;
                                }
                                aura.ending = aura.start + aura.duration;
                            }
                            aura.gain = atTime;
                            this.debug.log(
                                "Aura %d with duration %s now ending at %s",
                                auraId,
                                aura.duration,
                                aura.ending
                            );
                            if (spellcast) {
                                this.lastSpell.copySpellcastInfo(
                                    spellcast,
                                    aura
                                );
                            }
                        } else if (stacks == 0 || stacks < 0) {
                            if (stacks == 0) {
                                aura.stacks = 0;
                            } else {
                                aura.stacks = aura.stacks + stacks;
                                if (aura.stacks < 0) {
                                    aura.stacks = 0;
                                }
                                this.debug.log(
                                    "Aura %d loses %d stack(s) to %d because of spell %d.",
                                    auraId,
                                    -1 * stacks,
                                    aura.stacks,
                                    spellId
                                );
                            }
                            if (aura.stacks == 0) {
                                this.debug.log(
                                    "Aura %d is completely removed.",
                                    auraId
                                );
                                aura.ending = atTime;
                                aura.consumed = true;
                            }
                        }
                    } else {
                        if (toggle) {
                            this.debug.log(
                                "Aura %d is toggled on by spell %d.",
                                auraId,
                                spellId
                            );
                            stacks = 1;
                        }
                        if (!refresh && stacks > 0) {
                            this.debug.log(
                                "New aura %d at %f on %s",
                                auraId,
                                atTime,
                                guid
                            );
                            let debuffType;
                            if (si) {
                                for (const [k, v] of pairs(
                                    spellInfoDebuffTypes
                                )) {
                                    if (si[k as keyof SpellInfo] == 1) {
                                        debuffType = v;
                                        break;
                                    }
                                }
                            }
                            const aura = this.addAuraToGUID(
                                guid,
                                auraId,
                                playerGUID,
                                filter,
                                debuffType,
                                0,
                                huge,
                                atTime
                            );
                            aura.stacks = stacks;
                            aura.start = atTime;
                            aura.duration = duration;
                            if (si && si.tick) {
                                aura.baseTick = si.tick;
                                aura.tick = this.getTickLength(auraId, atTime);
                            }
                            aura.ending = aura.start + aura.duration;
                            aura.gain = aura.start;
                            if (spellcast) {
                                this.lastSpell.copySpellcastInfo(
                                    spellcast,
                                    aura
                                );
                            }
                        }
                    }
                } else {
                    this.debug.log(
                        "Aura %d (%s) is not applied.",
                        auraId,
                        spellData
                    );
                }
            }
        }
    }

    public addAuraToGUID(
        guid: string,
        auraId: AuraId,
        casterGUID: string,
        filter: AuraType,
        debuffType: string | undefined,
        start: number,
        ending: number,
        atTime: number
    ) {
        const aura = <Aura>pool.get();
        aura.state = true;
        aura.serial = this.next.auraSerial;
        aura.lastUpdated = atTime;
        aura.filter = filter;
        aura.start = start || 0;
        aura.ending = ending || huge;
        aura.duration = aura.ending - aura.start;
        aura.gain = aura.start;
        aura.stacks = 1;
        aura.debuffType =
            (isString(debuffType) && lower(debuffType)) || debuffType;
        putAura(this.next.aura, guid, auraId, casterGUID, aura);
        return aura;
    }
    removeAuraOnGUID(
        guid: string,
        auraId: AuraId,
        filter: AuraType,
        mine: boolean,
        atTime: number
    ) {
        const auraFound = this.getAuraByGUID(
            guid,
            auraId,
            filter,
            mine,
            atTime
        );
        if (auraFound && this.isActiveAura(auraFound, atTime)) {
            let aura;
            if (auraFound.state) {
                aura = auraFound;
            } else {
                aura = this.addAuraToGUID(
                    guid,
                    auraId,
                    auraFound.source,
                    filter,
                    undefined,
                    0,
                    huge,
                    atTime
                );
                for (const [k, v] of kpairs(auraFound)) {
                    (<any>aura)[k] = v;
                }
                aura.serial = this.next.auraSerial;
            }
            aura.stacks = 0;
            aura.ending = atTime;
            aura.lastUpdated = atTime;
        }
    }

    getBaseDuration(
        auraId: number,
        spellId?: number | string,
        atTime?: number,
        spellcast?: SpellCast
    ) {
        let duration = INFINITY;
        const si = this.ovaleData.spellInfo[auraId];
        if (si && si.duration) {
            const [value, ratio] = this.ovaleData.getSpellInfoPropertyNumber(
                auraId,
                undefined,
                "duration",
                undefined,
                true
            ) || [15, 1];
            if (si.add_duration_combopoints) {
                const powerState = this.ovalePower.getState(atTime);
                const combopoints = powerState.power.combopoints || 0;
                duration =
                    (value + si.add_duration_combopoints * combopoints) * ratio;
            } else {
                duration = value * ratio;
            }
        }
        if (si && si.half_duration && spellId) {
            if (this.ovaleData.buffSpellList[spellId]) {
                for (const [id] of pairs(
                    this.ovaleData.buffSpellList[spellId]
                )) {
                    if (id === si.half_duration) {
                        duration = duration * 0.5;
                        break;
                    }
                }
            } else if (spellId === si.half_duration) {
                duration = duration * 0.5;
            }
        }
        // Most aura durations are no longer reduced by haste
        // but the ones that do still need their reduction
        if (si && si.haste) {
            const hasteMultiplier = this.ovalePaperDoll.getHasteMultiplier(
                si.haste,
                atTime
            );
            duration = duration / hasteMultiplier;
        }
        return duration;
    }

    getTickLength(auraId: number, atTime?: number) {
        let tick = 3;
        const si = this.ovaleData.spellInfo[auraId];
        if (si) {
            tick = si.tick || tick;
            const hasteMultiplier = this.ovalePaperDoll.getHasteMultiplier(
                si.haste,
                atTime
            );
            tick = tick / hasteMultiplier;
        }
        return tick;
    }
}
