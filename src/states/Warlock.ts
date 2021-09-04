import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import { GetTime, TalentId, SpellId } from "@wowts/wow-mock";
import { find } from "@wowts/string";
import { pow } from "@wowts/math";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../engine/state";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
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

export const enum DemonId {
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
    private demonsCount: LuaObj<Demon> = {};
    private serial = 1;

    constructor(
        private ovale: OvaleClass,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combatLogEvent: CombatLogEvent
    ) {
        ovale.createModule(
            "OvaleWarlock",
            this.handleInitialize,
            this.handleDisable
        );
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.combatLogEvent.registerEvent(
                "SPELL_SUMMON",
                this,
                this.handleCombatLogEvent
            );
            this.combatLogEvent.registerEvent(
                "SPELL_CAST_SUCCESS",
                this,
                this.handleCombatLogEvent
            );
            this.demonsCount = {};
        }
    };

    private handleDisable = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.combatLogEvent.unregisterAllEvents(this);
        }
    };

    private handleCombatLogEvent = (cleuEvent: string) => {
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

    getDemonsCount(creatureId: number, atTime?: number) {
        atTime = atTime || GetTime();
        let count = 0;
        for (const [, d] of pairs(this.demonsCount)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return count;
    }

    getRemainingDemonDuration(creatureId: number, atTime?: number) {
        atTime = atTime || GetTime();
        let max = 0;
        for (const [, d] of pairs(this.demonsCount)) {
            if (d.finish >= atTime && d.id == creatureId) {
                const remaining = d.finish - atTime;
                if (max < remaining) {
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

    getTimeToShard(atTime: number) {
        let average = 3600;
        const tickTime =
            2 / this.ovalePaperDoll.getHasteMultiplier("spell", atTime);
        const [numAgonies] = this.ovaleAura.auraCount(
            SpellId.agony,
            "HARMFUL",
            true,
            undefined,
            atTime,
            undefined
        );
        if (numAgonies > 0) {
            /* This calculation is lifted directly from simc:sc_warlock.cpp,
             * and is the average expected time for the player to generate
             * one Soul Shard ("time_to_shard").
             */
            average =
                ((1 / (0.184 * pow(numAgonies, -2 / 3))) * tickTime) /
                numAgonies;
            const hasCreepingDeath = this.ovaleSpellBook.isKnownTalent(
                TalentId.creeping_death_talent
            );
            if (hasCreepingDeath) {
                // Creeping Death makes Agony deal its full damage 15% faster.
                average = average / 1.15;
            }
        }
        return average;
    }
}
