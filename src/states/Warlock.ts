import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import { GetTime, TalentId, SpellId } from "@wowts/wow-mock";
import { find } from "@wowts/string";
import { pow } from "@wowts/math";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../engine/state";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleConditionClass, returnConstant } from "../engine/condition";
import { OvaleFutureClass } from "./Future";
import { OvalePowerClass } from "./Power";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";
import { CombatLogEvent, SpellPayloadHeader } from "../engine/combat-log-event";

interface CustomAura {
    customId: number;
    duration: number;
    stacks: number;
    auraName: string;
}

const customAuras: LuaArray<CustomAura> = {
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
        private power: OvalePowerClass,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleWarlock",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    public registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("timetoshard", false, this.timeToShard);
        condition.registerCondition("demons", false, this.getDemonsCount);
        condition.registerCondition("demonduration", false, this.demonDuration);
        condition.registerCondition(
            "impsspawnedduring",
            false,
            this.impsSpawnedDuring
        );
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.RegisterMessage(
                "Ovale_CombatLogEvent",
                this.handleOvaleCombatLogEvent
            );
            this.combatLogEvent.registerEvent("SPELL_SUMMON", this);
            this.combatLogEvent.registerEvent("SPELL_CAST_SUCCESS", this);
            this.demonsCount = {};
        }
    };

    private handleDisable = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.UnregisterMessage("Ovale_CombatLogEvent");
            this.combatLogEvent.unregisterEvent("SPELL_SUMMON", this);
            this.combatLogEvent.unregisterEvent("SPELL_CAST_SUCCESS", this);
        }
    };

    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (cleuEvent != "SPELL_SUMMON" && cleuEvent != "SPELL_CAST_SUCCESS") {
            return;
        }
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.ovale.playerGUID) {
            this.serial = this.serial + 1;
            if (cleuEvent == "SPELL_SUMMON") {
                const destGUID = cleu.destGUID;
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
                const header = cleu.header as SpellPayloadHeader;
                const spellId = header.spellId;
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

                const aura = customAuras[spellId];
                if (aura) {
                    this.addCustomAura(
                        aura.customId,
                        aura.stacks,
                        aura.duration,
                        aura.auraName
                    );
                }
            }
        }
    };

    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {}

    private impsSpawnedDuring = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const ms = positionalParams[1];
        const delay = (ms || 0) / 1000;
        let impsSpawned = 0;
        // check for Hand of Guldan
        if (this.future.next.currentCast.spellId == SpellId.hand_of_guldan) {
            let soulshards = this.power.current.power["soulshards"] || 0;
            if (soulshards >= 3) {
                soulshards = 3;
            }
            impsSpawned = impsSpawned + soulshards;
        }

        // inner demons talent
        const talented =
            this.ovaleSpellBook.getTalentPoints(TalentId.inner_demons_talent) >
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
        return returnConstant(impsSpawned);
    };

    private getDemonsCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const creatureId = positionalParams[1];
        let count = 0;
        for (const [, d] of pairs(this.demonsCount)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return returnConstant(count);
    };

    private demonDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const creatureId = positionalParams[1];
        const value = this.getRemainingDemonDuration(creatureId, atTime);
        return returnConstant(value);
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
        this.ovaleAura.gainedAuraOnGUID(
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
    private getTimeToShard(atTime: number) {
        let value = 3600;
        const tickTime =
            2 / this.ovalePaperDoll.getHasteMultiplier("spell", atTime);
        const [activeAgonies] = this.ovaleAura.auraCount(
            SpellId.agony,
            "HARMFUL",
            true,
            undefined,
            atTime,
            undefined
        );
        if (activeAgonies > 0) {
            value =
                ((1 / (0.184 * pow(activeAgonies, -2 / 3))) * tickTime) /
                activeAgonies;
            if (
                this.ovaleSpellBook.isKnownTalent(
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
        const value = this.getTimeToShard(atTime);
        return returnConstant(value);
    };
}
