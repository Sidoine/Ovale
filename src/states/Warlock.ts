import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import {
    GetTime,
    CombatLogGetCurrentEventInfo,
    TalentId,
    SpellId,
} from "@wowts/wow-mock";
import { find } from "@wowts/string";
import { pow } from "@wowts/math";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../engine/state";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import { Compare, OvaleConditionClass } from "../engine/condition";
import { OvaleFutureClass } from "./Future";
import { OvalePowerClass } from "./Power";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

interface CustomAura {
    customId: number;
    duration: number;
    stacks: number;
    auraName: string;
}

const CUSTOM_AURAS: LuaArray<CustomAura> = {
    [SpellId.havoc]: {
        customId: -SpellId.havoc,
        duration: 10,
        stacks: 1,
        auraName: "active_havoc",
    },
};

const enum DemonId {
    WildImp = 55659,
    Dreadstalkers = 98035,
    Darkglare = 103673,
    Doomguard = 11859,
    Infernal = 89,
    InnerDemonsWildImp = 143622,
    DemonicTyrant = 135002,
    GrimoireFelguard = 17252,
    Vilefiend = 135816,
}

const demonData: LuaArray<{ duration: number }> = {
    [DemonId.WildImp]: {
        duration: 15,
    },
    [DemonId.Dreadstalkers]: {
        duration: 12,
    },
    [DemonId.Darkglare]: {
        duration: 12,
    },
    [DemonId.Doomguard]: {
        duration: 25,
    },
    [DemonId.Infernal]: {
        duration: 25,
    },
    [DemonId.InnerDemonsWildImp]: {
        duration: 12,
    },
    [DemonId.DemonicTyrant]: {
        duration: 15,
    },
    [DemonId.GrimoireFelguard]: {
        duration: 15,
    },
    [DemonId.Vilefiend]: {
        duration: 15,
    },
};

interface Demon {
    finish: number;
    id: number;
    timestamp: number;
}

export class OvaleWarlockClass implements StateModule {
    private module: AceModule & AceEvent;
    private demonsCount: LuaObj<Demon> = {};
    private serial = 1;

    constructor(
        private ovale: OvaleClass,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private future: OvaleFutureClass,
        private power: OvalePowerClass
    ) {
        this.module = ovale.createModule(
            "OvaleWarlock",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
    }

    public registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("timetoshard", false, this.timeToShard);
        condition.RegisterCondition("demons", false, this.getDemonsCount);
        condition.RegisterCondition("demonduration", false, this.demonDuration);
        condition.RegisterCondition(
            "impsspawnedduring",
            false,
            this.impsSpawnedDuring
        );
    }

    private OnInitialize = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.RegisterEvent(
                "COMBAT_LOG_EVENT_UNFILTERED",
                this.COMBAT_LOG_EVENT_UNFILTERED
            );
            this.demonsCount = {};
        }
    };

    private OnDisable = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };

    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        const [
            ,
            cleuEvent,
            ,
            sourceGUID,
            ,
            ,
            ,
            destGUID,
            ,
            ,
            ,
            spellId,
        ] = CombatLogGetCurrentEventInfo();
        if (sourceGUID != this.ovale.playerGUID) {
            return;
        }
        this.serial = this.serial + 1;
        if (cleuEvent == "SPELL_SUMMON") {
            let [, , , , , , , creatureId] = find(
                destGUID,
                "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)"
            );
            creatureId = tonumber(creatureId);

            const now = GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id === creatureId) {
                    this.demonsCount[destGUID] = {
                        id: creatureId,
                        timestamp: now,
                        finish: now + v.duration,
                    };
                    break;
                }
            }
            for (const [k, d] of pairs(this.demonsCount)) {
                if (d.finish < now) {
                    delete this.demonsCount[k];
                }
            }
            this.ovale.needRefresh();
        } else if (cleuEvent == "SPELL_CAST_SUCCESS") {
            // Implosion removes all the wild imps
            if (spellId == SpellId.implosion) {
                for (const [k, d] of pairs(this.demonsCount)) {
                    if (
                        d.id == DemonId.WildImp ||
                        d.id == DemonId.InnerDemonsWildImp
                    ) {
                        delete this.demonsCount[k];
                    }
                }
                this.ovale.needRefresh();
            }

            const aura = CUSTOM_AURAS[spellId];
            if (aura) {
                this.addCustomAura(
                    aura.customId,
                    aura.stacks,
                    aura.duration,
                    aura.auraName
                );
            }
        }
    };

    CleanState(): void {}
    InitializeState(): void {}
    ResetState(): void {}

    private impsSpawnedDuring = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [ms, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[3],
        ];
        const delay = (ms || 0) / 1000;
        let impsSpawned = 0;
        // check for hand of guldan
        if (this.future.next.currentCast.spellId == SpellId.hand_of_guldan) {
            let soulshards = this.power.current.power["soulshards"] || 0;
            if (soulshards >= 3) {
                soulshards = 3;
            }
            impsSpawned = impsSpawned + soulshards;
        }

        // inner demons talent
        const talented =
            this.ovaleSpellBook.GetTalentPoints(TalentId.inner_demons_talent) >
            0;
        if (talented) {
            const value = this.getRemainingDemonDuration(
                DemonId.InnerDemonsWildImp,
                atTime + delay
            );
            if (value <= 0) {
                impsSpawned = impsSpawned + 1;
            }
        }
        return Compare(impsSpawned, comparator, limit);
    };

    private getDemonsCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [creatureId, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[3],
        ];
        let count = 0;
        for (const [, d] of pairs(this.demonsCount)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return Compare(count, comparator, limit);
    };

    private demonDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [creatureId, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[3],
        ];
        const value = this.getRemainingDemonDuration(creatureId, atTime);
        return Compare(value, comparator, limit);
    };

    private getRemainingDemonDuration(creatureId: number, atTime: number) {
        let max = 0;
        for (const [, d] of pairs(this.demonsCount)) {
            if (d.finish >= atTime && d.id == creatureId) {
                const remaining = d.finish - atTime;
                if (remaining > max) {
                    max = remaining;
                }
            }
        }
        return max;
    }

    private addCustomAura(
        customId: number,
        stacks: number,
        duration: number,
        buffName: string
    ) {
        const now = GetTime();
        const expire = now + duration;
        this.ovaleAura.GainedAuraOnGUID(
            this.ovale.playerGUID,
            now,
            customId,
            this.ovale.playerGUID,
            "HELPFUL",
            false,
            undefined,
            stacks,
            undefined,
            duration,
            expire,
            false,
            buffName,
            undefined,
            undefined,
            undefined
        );
    }

    /**
     * Based on SimulationCraft function time_to_shard
     * Seeks to return the average expected time for the player to generate a single soul shard.
     */
    private getTimeToShard(now: number) {
        let value = 3600;
        const tickTime =
            2 /
            this.ovalePaperDoll.GetHasteMultiplier(
                "spell",
                this.ovalePaperDoll.next
            );
        const [activeAgonies] = this.ovaleAura.AuraCount(
            SpellId.agony,
            "HARMFUL",
            true,
            undefined,
            now,
            undefined
        );
        if (activeAgonies > 0) {
            value =
                ((1 / (0.184 * pow(activeAgonies, -2 / 3))) * tickTime) /
                activeAgonies;
            if (
                this.ovaleSpellBook.IsKnownTalent(
                    TalentId.creeping_death_talent
                )
            ) {
                value = value * 0.85;
            }
        }
        return value;
    }

    private timeToShard = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [comparator, limit] = [positionalParams[1], positionalParams[2]];
        const value = this.getTimeToShard(atTime);
        return Compare(value, comparator, limit);
    };
}
