import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import { GetTime, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { find } from "@wowts/string";
import { pow } from "@wowts/math";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../State";
import { OvaleAuraClass } from "./Aura";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "../SpellBook";

interface customAura {
    customId: number;
    duration: number;
    stacks: number;
    auraName: string;
}

let CUSTOM_AURAS: LuaArray<customAura> = {
    [80240]: {
        customId: -80240,
        duration: 10,
        stacks: 1,
        auraName: "active_havoc",
    },
};

let demonData: LuaArray<{ duration: number }> = {
    [55659]: {
        // Wild Imp
        duration: 12,
    },
    [98035]: {
        // Dreadstalkers
        duration: 12,
    },
    [103673]: {
        // Darkglare
        duration: 12,
    },
    [11859]: {
        // Doomguard
        duration: 25,
    },
    [89]: {
        // Infernal
        duration: 25,
    },
    [143622]: {
        // Inner Demons
        duration: 12,
    },
    [135002]: {
        // Demonic Tyrant
        duration: 15,
    },
    [17252]: {
        // Grimoire Felguard
        duration: 15,
    },
    [135816]: {
        // Vilefiend
        duration: 15,
    },
};

interface Demon {
    finish: number;
    id: number;
    timestamp: number;
    de?: boolean;
}

let self_demons: LuaObj<Demon> = {};
let self_serial = 1;
export class OvaleWarlockClass implements StateModule {
    private module: AceModule & AceEvent;

    constructor(
        private ovale: OvaleClass,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        this.module = ovale.createModule(
            "OvaleWarlock",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
    }

    private OnInitialize = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.RegisterEvent(
                "COMBAT_LOG_EVENT_UNFILTERED",
                this.COMBAT_LOG_EVENT_UNFILTERED
            );
            self_demons = {};
        }
    };

    private OnDisable = () => {
        if (this.ovale.playerClass == "WARLOCK") {
            this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };

    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [
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
        self_serial = self_serial + 1;
        if (cleuEvent == "SPELL_SUMMON") {
            let [, , , , , , , creatureId] = find(
                destGUID,
                "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)"
            );
            creatureId = tonumber(creatureId);
            let now = GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id == creatureId) {
                    self_demons[destGUID] = {
                        id: creatureId,
                        timestamp: now,
                        finish: now + v.duration,
                    };
                    break;
                }
            }
            for (const [k, d] of pairs(self_demons)) {
                if (d.finish < now) {
                    delete self_demons[k];
                }
            }
            this.ovale.needRefresh();
        } else if (cleuEvent == "SPELL_CAST_SUCCESS") {
            if (spellId == 196277) {
                for (const [k, d] of pairs(self_demons)) {
                    if (d.id == 55659 || d.id == 143622) {
                        delete self_demons[k];
                    }
                }
                this.ovale.needRefresh();
            }

            const aura = CUSTOM_AURAS[spellId];
            if (aura) {
                this.AddCustomAura(
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
    GetNotDemonicEmpoweredDemonsCount(creatureId: number, atTime: number) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId && !d.de) {
                count = count + 1;
            }
        }
        return count;
    }
    GetDemonsCount(creatureId: number, atTime: number) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return count;
    }
    GetRemainingDemonDuration(creatureId: number, atTime: number) {
        let max = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId) {
                let remaining = d.finish - atTime;
                if (remaining > max) {
                    max = remaining;
                }
            }
        }
        return max;
    }

    AddCustomAura(
        customId: number,
        stacks: number,
        duration: number,
        buffName: string
    ) {
        let now = GetTime();
        let expire = now + duration;
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
    TimeToShard(now: number) {
        let value = 3600;
        let creepingDeathTalent = 20;
        let tickTime =
            2 /
            this.ovalePaperDoll.GetHasteMultiplier(
                "spell",
                this.ovalePaperDoll.next
            );
        let [activeAgonies] = this.ovaleAura.AuraCount(
            980,
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
            if (this.ovaleSpellBook.IsKnownTalent(creepingDeathTalent)) {
                value = value * 0.85;
            }
        }
        return value;
    }
}
