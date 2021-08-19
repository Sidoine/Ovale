import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, LuaObj, next, pairs, truthy, unpack } from "@wowts/lua";
import { find } from "@wowts/string";
import { AceModule } from "@wowts/tsaddon";
import {
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID,
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    CombatLogGetCurrentEventInfo,
    Enum,
} from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { DebugTools, Tracer } from "./debug";

// from Interface/AddOns/Blizzard_CombatLog/Blizzard_CombatLog.lua
export type CombatLogSubEvent =
    | "ENVIRONMENTAL_DAMAGE"
    | "SWING_DAMAGE"
    | "SWING_MISSED"
    | "RANGE_DAMAGE"
    | "RANGE_MISSED"
    | "SPELL_CAST_START"
    | "SPELL_CAST_SUCCESS"
    | "SPELL_CAST_FAILED"
    | "SPELL_MISSED"
    | "SPELL_DAMAGE"
    | "SPELL_HEAL"
    | "SPELL_ENERGIZE"
    | "SPELL_DRAIN"
    | "SPELL_LEECH"
    | "SPELL_SUMMON"
    | "SPELL_RESURRECT"
    | "SPELL_CREATE"
    | "SPELL_INSTAKILL"
    | "SPELL_INTERRUPT"
    | "SPELL_EXTRA_ATTACKS"
    | "SPELL_DURABILITY_DAMAGE"
    | "SPELL_DURABILITY_DAMAGE_ALL"
    | "SPELL_AURA_APPLIED"
    | "SPELL_AURA_APPLIED_DOSE"
    | "SPELL_AURA_REMOVED"
    | "SPELL_AURA_REMOVED_DOSE"
    | "SPELL_AURA_BROKEN"
    | "SPELL_AURA_BROKEN_SPELL"
    | "SPELL_AURA_REFRESH"
    | "SPELL_DISPEL"
    | "SPELL_STOLEN"
    | "ENCHANT_APPLIED"
    | "ENCHANT_REMOVED"
    | "SPELL_PERIODIC_MISSED"
    | "SPELL_PERIODIC_DAMAGE"
    | "SPELL_PERIODIC_HEAL"
    | "SPELL_PERIODIC_ENERGIZE"
    | "SPELL_PERIODIC_DRAIN"
    | "SPELL_PERIODIC_LEECH"
    | "SPELL_DISPEL_FAILED"
    | "DAMAGE_SHIELD"
    | "DAMAGE_SHIELD_MISSED"
    | "DAMAGE_SPLIT"
    | "PARTY_KILL"
    | "UNIT_DIED"
    | "UNIT_DESTROYED"
    | "SPELL_BUILDING_DAMAGE"
    | "SPELL_BUILDING_HEAL"
    | "UNIT_DISSIPATES";

export type EventPrefix =
    | "SWING"
    | "RANGE"
    | "SPELL"
    | "SPELL_PERIODIC"
    | "SPELL_BUILDING"
    | "ENVIRONMENTAL"
    | "ENCHANT_APPLIED"
    | "ENCHANT_REMOVED"
    | "PARTY_KILL"
    | "UNIT_DIED"
    | "UNIT_DESTROYED"
    | "UNIT_DISSIPATES";

export interface PayloadHeader {
    type: EventPrefix;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface SwingPayloadHeader extends PayloadHeader {}

export interface RangePayloadHeader extends PayloadHeader {
    spellId: number;
    spellName: string;
    school: number;
}

export interface SpellPayloadHeader extends PayloadHeader {
    spellId: number;
    spellName: string;
    school: number;
}

export interface SpellPeriodicPayloadHeader extends PayloadHeader {
    spellId: number;
    spellName: string;
    school: number;
}

export interface SpellBuildingPayloadHeader extends PayloadHeader {
    spellId: number;
    spellName: string;
    school: number;
}

export interface EnchantAppliedPayloadHeader extends PayloadHeader {
    spellName: string;
    itemId: number;
    itemName: string;
}

export interface EnchantRemovedPayloadHeader extends PayloadHeader {
    spellName: string;
    itemId: number;
    itemName: string;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface PartyKillPayloadHeader extends PayloadHeader {}

export interface UnitDiedPayloadHeader extends PayloadHeader {
    recapId: number;
    unconsciousOnDeath: boolean;
}

export interface UnitDestroyedPayloadHeader extends PayloadHeader {
    recapId: number;
    unconsciousOnDeath: boolean;
}

export interface UnitDissipatesPayloadHeader extends PayloadHeader {
    recapId: number;
    unconsciousOnDeath: boolean;
}

type EnvironmentalType =
    | "Drowning"
    | "Falling"
    | "Fatigue"
    | "Fire"
    | "Lava"
    | "Slime";

export interface EnvironmentalPayloadHeader extends PayloadHeader {
    environmentalType: EnvironmentalType;
}

export type EventSuffix =
    | "DAMAGE"
    | "MISSED"
    | "HEAL"
    | "HEAL_ABSORBED"
    | "ENERGIZE"
    | "DRAIN"
    | "LEECH"
    | "INTERRUPT"
    | "DISPEL"
    | "DISPEL_FAILED"
    | "STOLEN"
    | "EXTRA_ATTACKS"
    | "AURA_APPLIED"
    | "AURA_REMOVED"
    | "AURA_APPLIED_DOSE"
    | "AURA_REMOVED_DOSE"
    | "AURA_REFRESH"
    | "AURA_BROKEN"
    | "AURA_BROKEN_SPELL"
    | "CAST_START"
    | "CAST_SUCCESS"
    | "CAST_FAILED"
    | "INSTAKILL"
    | "DURABILITY_DAMAGE"
    | "DURABILITY_DAMAGE_ALL"
    | "CREATE"
    | "SUMMON"
    | "DISSIPATES";

type AuraType = "BUFF" | "DEBUFF";

type MissType =
    | "ABSORB"
    | "BLOCK"
    | "DEFLECT"
    | "DODGE"
    | "EVADE"
    | "IMMUNE"
    | "MISS"
    | "PARRY"
    | "REFLECT"
    | "RESIST";

export interface Payload {
    type: EventSuffix;
}

export interface DamagePayload extends Payload {
    amount: number;
    overkill: number;
    school: number;
    resisted: number;
    blocked: number;
    absorbed: number;
    critical: boolean;
    glancing: boolean;
    crushing: boolean;
    isOffHand: boolean;
}

export interface MissedPayload extends Payload {
    missType: MissType;
    isOffHand: boolean;
    amountMissed: number;
    critical: boolean;
}

export interface HealPayload extends Payload {
    amount: number;
    overhealing: number;
    absorbed: number;
    critical: boolean;
}

export interface HealAbsorbedPayload extends Payload {
    guid: string;
    name: string;
    flags: number;
    raidFlags: number;
    spellId: number;
    spellName: string;
    school: number;
    amount: number;
}

export interface EnergizePayload extends Payload {
    amount: number;
    overEnergize: number;
    powerType: number; // Enum.PowerType
    alternatePowerType: number; // Enum.PowerType
}

export interface DrainPayload extends Payload {
    amount: number;
    powerType: number; // Enum.PowerType
    extraAmount: number;
}

export interface LeechPayload extends Payload {
    amount: number;
    powerType: number; // Enum.PowerType
    extraAmount: number;
}

export interface InterruptPayload extends Payload {
    spellId: number;
    spellName: string;
    school: number;
}

export interface DispelPayload extends Payload {
    spellId: number;
    spellName: string;
    school: number;
    auraType: AuraType;
}

export interface DispelFailedPayload extends Payload {
    spellId: number;
    spellName: string;
    school: number;
}

export interface StolenPayload extends Payload {
    spellId: number;
    spellName: string;
    school: number;
    auraType: AuraType;
}

export interface ExtraAttacksPayload extends Payload {
    amount: number;
}

export interface AuraAppliedPayload extends Payload {
    auraType: AuraType;
    amount: number;
}

export interface AuraRemovedPayload extends Payload {
    auraType: AuraType;
    amount: number;
}

export interface AuraAppliedDosePayload extends Payload {
    auraType: AuraType;
    amount: number;
}

export interface AuraRemovedDosePayload extends Payload {
    auraType: AuraType;
    amount: number;
}

export interface AuraRefreshPayload extends Payload {
    auraType: AuraType;
    amount: number;
}

export interface AuraBrokenPayload extends Payload {
    auraType: AuraType;
}

export interface AuraBrokenSpellPayload extends Payload {
    spellId: number;
    spellName: string;
    school: number;
    auraType: AuraType;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface CastStartPayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface CastSuccessPayload extends Payload {}

export interface CastFailedPayload extends Payload {
    failedType: string;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface InstaKillPayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DurabilityDamagePayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DurabilityDamageAllPayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface CreatePayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface SummonPayload extends Payload {}
// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DissipatesPayload extends Payload {}

export const unitFlag: LuaObj<LuaObj<number>> = {
    type: {
        mask: 0xfc00, // COMBATLOG_OBJECT_TYPE_MASK
        object: 0x4000, // COMBATLOG_OBJECT_TYPE_OBJECT
        guardian: 0x2000, // COMBATLOG_OBJECT_TYPE_GUARDIAN
        pet: 0x1000, // COMBATLOG_OBJECT_TYPE_PET
        npc: 0x800, // COMBATLOG_OBJECT_TYPE_NPC
        player: 0x400, // COMBATLOG_OBJECT_TYPE_PLAYER
    },
    controller: {
        mask: 0x300, // COMBATLOG_OBJECT_CONTROL_MASK
        npc: 0x200, // COMBATLOG_OBJECT_CONTROL_NPC
        player: 0x100, // COMBATLOG_OBJECT_CONTROL_PLAYER
    },
    reaction: {
        mask: 0xf0, // COMBATLOG_OBJECT_REACTION_MASK
        hostile: 0x40, // COMBATLOG_OBJECT_REACTION_HOSTILE
        neutral: 0x20, // COMBATLOG_OBJECT_REACTION_NEUTRAL
        friendly: COMBATLOG_OBJECT_REACTION_FRIENDLY,
    },
    affiliation: {
        mask: 0xf, // COMBATLOG_OBJECT_AFFILIATION_MASK
        outsider: 0x8, // COMBATLOG_OBJECT_AFFILIATION_MASK
        raid: COMBATLOG_OBJECT_AFFILIATION_RAID,
        party: COMBATLOG_OBJECT_AFFILIATION_PARTY,
        mine: COMBATLOG_OBJECT_AFFILIATION_MINE,
    },
};

export const raidFlag: LuaObj<LuaObj<number>> = {
    raidTarget: {
        mask: 0xff, // COMBATLOG_OBJECT_RAIDTARGET_MASK
        skull: 0x80, // COMBATLOG_OBJECT_RAIDTARGET8
        cross: 0x40, // COMBATLOG_OBJECT_RAIDTARGET7
        square: 0x20, // COMBATLOG_OBJECT_RAIDTARGET6
        moon: 0x10, // COMBATLOG_OBJECT_RAIDTARGET5
        triangle: 0x8, // COMBATLOG_OBJECT_RAIDTARGET4
        diamond: 0x4, // COMBATLOG_OBJECT_RAIDTARGET3
        circle: 0x2, // COMBATLOG_OBJECT_RAIDTARGET2
        star: 0x1, // COMBATLOG_OBJECT_RAIDTARGET1
    },
};

type CombatLogEventHandler = (event: string) => void;
type CombatLogEventHandlerRegistry = LuaObj<LuaObj<CombatLogEventHandler>>;

export class CombatLogEvent {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private registry: CombatLogEventHandlerRegistry = {};
    private pendingRegistry: CombatLogEventHandlerRegistry = {};
    private fireDepth = 0;
    private arg: LuaArray<any> = {};

    timestamp = 0;
    subEvent: CombatLogSubEvent = "SWING_DAMAGE";
    hideCaster = false;
    sourceGUID = "";
    sourceName = "";
    sourceFlags = 0;
    sourceRaidFlags = 0;
    destGUID = "";
    destName = "";
    destFlags = 0;
    destRaidFlags = 0;
    header: PayloadHeader = { type: "SWING" };
    payload: Payload = { type: "DAMAGE" };

    constructor(ovale: OvaleClass, debug: DebugTools) {
        this.module = ovale.createModule(
            "CombatLogEvent",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        this.module.RegisterEvent(
            "COMBAT_LOG_EVENT_UNFILTERED",
            this.onCombatLogEventUnfiltered
        );
    };

    private onDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    };

    private onCombatLogEventUnfiltered = (event: string) => {
        const arg = this.arg;
        [
            arg[1],
            arg[2],
            arg[3],
            arg[4],
            arg[5],
            arg[6],
            arg[7],
            arg[8],
            arg[9],
            arg[10],
            arg[11],
            arg[12],
            arg[13],
            arg[14],
            arg[15],
            arg[16],
            arg[17],
            arg[18],
            arg[19],
            arg[20],
            arg[21],
            arg[22],
            arg[23],
            arg[24],
        ] = CombatLogGetCurrentEventInfo();

        const subEvent = arg[2];
        const handlers = this.registry[subEvent];
        const isRegisteredEvent = (handlers && next(handlers) && true) || false;
        if (!isRegisteredEvent) return;

        this.timestamp = (arg[1] as number) || 0;
        this.subEvent = subEvent as CombatLogSubEvent;
        this.hideCaster = ((arg[3] as boolean) && true) || false;
        this.sourceGUID = (arg[4] as string) || "";
        this.sourceName = (arg[5] as string) || "";
        this.sourceFlags = (arg[6] as number) || 0;
        this.sourceRaidFlags = arg[7] as number;
        this.destGUID = (arg[8] as string) || "";
        this.destName = (arg[9] as string) || "";
        this.destFlags = (arg[10] as number) || 0;
        this.destRaidFlags = (arg[11] as number) || 0;

        if (subEvent == "ENCHANT_APPLIED") {
            const header = this.header as EnchantAppliedPayloadHeader;
            header.type = "ENCHANT_APPLIED";
            header.spellName = (arg[12] as string) || "";
            header.itemId = (arg[13] as number) || 0;
            header.itemName = (arg[14] as string) || "";
        } else if (subEvent == "ENCHANT_REMOVED") {
            const header = this.header as EnchantRemovedPayloadHeader;
            header.type = "ENCHANT_APPLIED";
            header.spellName = (arg[12] as string) || "";
            header.itemId = (arg[13] as number) || 0;
            header.itemName = (arg[14] as string) || "";
        } else if (subEvent == "PARTY_KILL") {
            this.header.type = "PARTY_KILL";
        } else if (subEvent == "UNIT_DIED") {
            const header = this.header as UnitDiedPayloadHeader;
            header.type = "UNIT_DIED";
            header.recapId = (arg[12] as number) || 1;
            header.unconsciousOnDeath = ((arg[13] as boolean) && true) || false;
        } else if (subEvent == "UNIT_DESTROYED") {
            const header = this.header as UnitDestroyedPayloadHeader;
            header.type = "UNIT_DESTROYED";
            header.recapId = (arg[12] as number) || 1;
            header.unconsciousOnDeath = ((arg[13] as boolean) && true) || false;
        } else if (subEvent == "UNIT_DISSIPATES") {
            const header = this.header as UnitDissipatesPayloadHeader;
            header.type = "UNIT_DISSIPATES";
            header.recapId = (arg[12] as number) || 1;
            header.unconsciousOnDeath = ((arg[13] as boolean) && true) || false;
        } else {
            let index = 12;
            if (truthy(find(subEvent, "^SWING_"))) {
                this.header.type = "SWING";
                index = 12;
            } else if (truthy(find(subEvent, "^RANGE_"))) {
                const header = this.header as RangePayloadHeader;
                header.type = "RANGE";
                header.spellId = (arg[12] as number) || 0;
                header.spellName = (arg[13] as string) || "";
                header.school = (arg[14] as number) || 0;
                index = 15;
            } else if (truthy(find(subEvent, "^SPELL_PERIODIC_"))) {
                const header = this.header as SpellPeriodicPayloadHeader;
                header.type = "SPELL_PERIODIC";
                header.spellId = (arg[12] as number) || 0;
                header.spellName = (arg[13] as string) || "";
                header.school = (arg[14] as number) || 0;
                index = 15;
            } else if (truthy(find(subEvent, "^SPELL_BUILDING"))) {
                const header = this.header as SpellBuildingPayloadHeader;
                header.type = "SPELL_BUILDING";
                header.spellId = (arg[12] as number) || 0;
                header.spellName = (arg[13] as string) || "";
                header.school = (arg[14] as number) || 0;
                index = 15;
            } else if (
                truthy(find(subEvent, "^SPELL_")) ||
                truthy(find(subEvent, "^DAMAGE_"))
            ) {
                const header = this.header as SpellPayloadHeader;
                header.type = "SPELL";
                header.spellId = (arg[12] as number) || 0;
                header.spellName = (arg[13] as string) || "";
                header.school = (arg[14] as number) || 0;
                index = 15;
            } else if (truthy(find(subEvent, "^ENVIRONMENTAL"))) {
                const header = this.header as EnvironmentalPayloadHeader;
                header.type = "ENVIRONMENTAL";
                header.environmentalType =
                    (arg[12] as EnvironmentalType) || "Fire";
                index = 13;
            }
            if (
                truthy(find(subEvent, "_DAMAGE$")) ||
                truthy(find(subEvent, "_SPLIT$")) ||
                truthy(find(subEvent, "_SHIELD$"))
            ) {
                const payload = this.payload as DamagePayload;
                payload.type = "DAMAGE";
                payload.amount = (arg[index] as number) || 0;
                payload.overkill = (arg[index + 1] as number) || 0;
                payload.school = (arg[index + 2] as number) || 0;
                payload.resisted = (arg[index + 3] as number) || 0;
                payload.blocked = (arg[index + 4] as number) || 0;
                payload.absorbed = (arg[index + 5] as number) || 0;
                payload.critical =
                    ((arg[index + 6] as boolean) && true) || false;
                payload.glancing =
                    ((arg[index + 7] as boolean) && true) || false;
                payload.crushing =
                    ((arg[index + 8] as boolean) && true) || false;
                payload.isOffHand =
                    ((arg[index + 9] as boolean) && true) || false;
            } else if (truthy(find(subEvent, "_MISSED$"))) {
                const payload = this.payload as MissedPayload;
                payload.type = "MISSED";
                payload.missType = (arg[index] as MissType) || "MISS";
                payload.isOffHand =
                    ((arg[index + 1] as boolean) && true) || false;
                payload.amountMissed = (arg[index + 2] as number) || 0;
                payload.critical =
                    ((arg[index + 3] as boolean) && true) || false;
            } else if (truthy(find(subEvent, "_HEAL$"))) {
                const payload = this.payload as HealPayload;
                payload.type = "HEAL";
                payload.amount = (arg[index] as number) || 0;
                payload.overhealing = (arg[index + 2] as number) || 0;
                payload.absorbed = (arg[index + 3] as number) || 0;
                payload.critical =
                    ((arg[index + 4] as boolean) && true) || false;
            } else if (truthy(find(subEvent, "_HEAL_ABSORBED$"))) {
                const payload = this.payload as HealAbsorbedPayload;
                payload.type = "HEAL_ABSORBED";
                payload.guid = (arg[index] as string) || "";
                payload.name = (arg[index + 1] as string) || "";
                payload.flags = (arg[index + 2] as number) || 0;
                payload.raidFlags = (arg[index + 3] as number) || 0;
                payload.spellId = (arg[index + 4] as number) || 0;
                payload.spellName = (arg[index + 5] as string) || "";
                payload.school = (arg[index + 6] as number) || 0;
                payload.amount = (arg[index + 7] as number) || 0;
            } else if (truthy(find(subEvent, "_ENERGIZE$"))) {
                const payload = this.payload as EnergizePayload;
                payload.type = "ENERGIZE";
                payload.amount = (arg[index] as number) || 0;
                payload.overEnergize = (arg[index + 1] as number) || 0;
                payload.powerType =
                    (arg[index + 2] as number) || Enum.PowerType.None;
                payload.alternatePowerType =
                    (arg[index + 3] as number) || Enum.PowerType.Alternate;
            } else if (truthy(find(subEvent, "_DRAIN$"))) {
                const payload = this.payload as DrainPayload;
                payload.type = "DRAIN";
                payload.amount = (arg[index] as number) || 0;
                payload.powerType =
                    (arg[index + 1] as number) || Enum.PowerType.None;
                payload.extraAmount = (arg[index + 2] as number) || 0;
            } else if (truthy(find(subEvent, "_LEECH$"))) {
                const payload = this.payload as LeechPayload;
                payload.type = "LEECH";
                payload.amount = (arg[index] as number) || 0;
                payload.powerType =
                    (arg[index + 1] as number) || Enum.PowerType.None;
                payload.extraAmount = (arg[index + 2] as number) || 0;
            } else if (truthy(find(subEvent, "_INTERRUPT$"))) {
                const payload = this.payload as InterruptPayload;
                payload.type = "INTERRUPT";
                payload.spellId = (arg[index] as number) || 0;
                payload.spellName = (arg[index + 1] as string) || "";
                payload.school = (arg[index + 2] as number) || 0;
            } else if (truthy(find(subEvent, "_DISPEL$"))) {
                const payload = this.payload as DispelPayload;
                payload.type = "DISPEL";
                payload.spellId = (arg[index] as number) || 0;
                payload.spellName = (arg[index + 1] as string) || "";
                payload.school = (arg[index + 2] as number) || 0;
                payload.auraType = (arg[index + 3] as AuraType) || "DEBUFF";
            } else if (truthy(find(subEvent, "_DISPEL_FAILED$"))) {
                const payload = this.payload as DispelFailedPayload;
                payload.type = "DISPEL_FAILED";
                payload.spellId = (arg[index] as number) || 0;
                payload.spellName = (arg[index + 1] as string) || "";
                payload.school = (arg[index + 2] as number) || 0;
            } else if (truthy(find(subEvent, "_STOLEN$"))) {
                const payload = this.payload as StolenPayload;
                payload.type = "STOLEN";
                payload.spellId = (arg[index] as number) || 0;
                payload.spellName = (arg[index + 1] as string) || "";
                payload.school = (arg[index + 2] as number) || 0;
                payload.auraType = (arg[index + 3] as AuraType) || "DEBUFF";
            } else if (truthy(find(subEvent, "_EXTRA_ATTACKS$"))) {
                const payload = this.payload as ExtraAttacksPayload;
                payload.type = "EXTRA_ATTACKS";
                payload.amount = (arg[index] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_APPLIED$"))) {
                const payload = this.payload as AuraAppliedPayload;
                payload.type = "AURA_APPLIED";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
                payload.amount = (arg[index + 1] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_REMOVED$"))) {
                const payload = this.payload as AuraRemovedPayload;
                payload.type = "AURA_REMOVED";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
                payload.amount = (arg[index + 1] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_APPLIED_DOSE$"))) {
                const payload = this.payload as AuraAppliedDosePayload;
                payload.type = "AURA_APPLIED_DOSE";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
                payload.amount = (arg[index + 1] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_REMOVED_DOSE$"))) {
                const payload = this.payload as AuraRemovedDosePayload;
                payload.type = "AURA_REMOVED_DOSE";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
                payload.amount = (arg[index + 1] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_REFRESH$"))) {
                const payload = this.payload as AuraRefreshPayload;
                payload.type = "AURA_REFRESH";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
                payload.amount = (arg[index + 1] as number) || 0;
            } else if (truthy(find(subEvent, "_AURA_BROKEN$"))) {
                const payload = this.payload as AuraBrokenPayload;
                payload.type = "AURA_BROKEN";
                payload.auraType = (arg[index] as AuraType) || "DEBUFF";
            } else if (truthy(find(subEvent, "_AURA_BROKEN_SPELL$"))) {
                const payload = this.payload as AuraBrokenSpellPayload;
                payload.type = "AURA_BROKEN_SPELL";
                payload.spellId = (arg[index] as number) || 0;
                payload.spellName = (arg[index + 1] as string) || "";
                payload.school = (arg[index + 2] as number) || 0;
                payload.auraType = (arg[index + 3] as AuraType) || "DEBUFF";
            } else if (truthy(find(subEvent, "_CAST_START$"))) {
                this.payload.type = "CAST_START";
            } else if (truthy(find(subEvent, "_CAST_SUCCESS$"))) {
                this.payload.type = "CAST_SUCCESS";
            } else if (truthy(find(subEvent, "_CAST_FAILED$"))) {
                const payload = this.payload as CastFailedPayload;
                payload.type = "CAST_FAILED";
                payload.failedType = (arg[index] as string) || "CAST_FAILED";
            } else if (truthy(find(subEvent, "_INSTAKILL$"))) {
                this.payload.type = "INSTAKILL";
            } else if (truthy(find(subEvent, "_DURABILITY_DAMAGE$"))) {
                this.payload.type = "DURABILITY_DAMAGE";
            } else if (truthy(find(subEvent, "_DURABILITY_DAMAGE_ALL$"))) {
                this.payload.type = "DURABILITY_DAMAGE_ALL";
            } else if (truthy(find(subEvent, "_CREATE$"))) {
                this.payload.type = "CREATE";
            } else if (truthy(find(subEvent, "_SUMMON$"))) {
                this.payload.type = "SUMMON";
            } else if (truthy(find(subEvent, "_DISSIPATES$"))) {
                this.payload.type = "DISSIPATES";
            }
        }
        this.tracer.debug(this.subEvent, this.getCurrentEventInfo());
        this.fire(this.subEvent);
    };

    fire = (event: string) => {
        if (this.registry[event]) {
            this.fireDepth += 1;
            for (const [, handler] of pairs(this.registry[event])) {
                handler(event);
            }
            this.fireDepth -= 1;
            if (this.fireDepth == 0) {
                // Add all pending registrations to the main registry.
                for (const [event, handlers] of pairs(this.pendingRegistry)) {
                    for (const [token, handler] of pairs(handlers)) {
                        this.insertEventHandler(
                            this.registry,
                            event,
                            token,
                            handler
                        );
                    }
                }
            }
        }
    };

    private insertEventHandler = (
        registry: CombatLogEventHandlerRegistry,
        event: string,
        token: any,
        handler: CombatLogEventHandler
    ) => {
        const handlers = registry[event] || {};
        // Pretend to cast to string to satisfy Typescript.
        const key = token as unknown as string;
        handlers[key] = handler;
        registry[event] = handlers;
    };

    private removeEventHandler = (
        registry: CombatLogEventHandlerRegistry,
        event: string,
        token: any
    ) => {
        const handlers = registry[event];
        if (handlers) {
            // Pretend to cast to string to satisfy Typescript.
            const key = token as unknown as string;
            delete handlers[key];
            if (!next(handlers)) {
                delete registry[event];
            }
        }
    };

    registerEvent = (
        event: string,
        token: any,
        handler: CombatLogEventHandler
    ) => {
        if (this.fireDepth > 0) {
            this.insertEventHandler(
                this.pendingRegistry,
                event,
                token,
                handler
            );
        } else {
            this.insertEventHandler(this.registry, event, token, handler);
        }
    };

    unregisterEvent = (event: string, token: any) => {
        this.removeEventHandler(this.pendingRegistry, event, token);
        this.removeEventHandler(this.registry, event, token);
    };

    unregisterAllEvents = (token: any) => {
        for (const [event] of pairs(this.registry)) {
            this.unregisterEvent(event, token);
        }
    };

    getCurrentEventInfo() {
        return unpack(this.arg);
    }
}
