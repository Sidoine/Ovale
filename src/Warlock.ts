import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import { GetTime, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { find } from "@wowts/string";
import { OvaleAura } from "./Aura";
import { OvalePaperDoll } from "./PaperDoll";
import { pow } from "@wowts/math";
import { OvaleSpellBook } from "./SpellBook";

let OvaleWarlockBase = Ovale.NewModule("OvaleWarlock", aceEvent);
export let OvaleWarlock: OvaleWarlockClass;

interface customAura {
    customId: number;
    duration: number;
    stacks: number;
    auraName: string;
}

let CUSTOM_AURAS: LuaArray<customAura> = {
    [80240] :{
        customId: -80240,
        duration: 10,
        stacks: 1,
        auraName: "active_havoc"
    }
}

let demonData: LuaArray<{duration: number}> = {
    [55659]: { // Wild Imp
        duration: 12
    },
    [98035]: { // Dreadstalkers
        duration: 12
    },
    [103673]: { // Darkglare
        duration: 12
    },
    [11859]: { // Doomguard
        duration: 25
    },
    [89]: { // Infernal
        duration: 25
    },
    [143622]: { // Inner Demons
        duration: 12
    },
    [135002]:{ // Demonic Tyrant
        duration: 15
    },
    [17252]: { // Grimoire Felguard
        duration: 15
    }
}

interface Demon {
    finish: number;
    id: number;
    timestamp: number;
    de?: boolean;
}

let self_demons: LuaObj<Demon> = {
}
let self_serial = 1;
class OvaleWarlockClass extends OvaleWarlockBase {
    OnInitialize() {
        if (Ovale.playerClass == "WARLOCK") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            self_demons = {}
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "WARLOCK") {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        let [, cleuEvent, , sourceGUID, , , , destGUID, , , , spellId] = CombatLogGetCurrentEventInfo();
        if (sourceGUID != Ovale.playerGUID) {
            return;
        }
        self_serial = self_serial + 1;
        if (cleuEvent == "SPELL_SUMMON") {
            let [,,,, , , , creatureId] = find(destGUID, '(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)');
            creatureId = tonumber(creatureId);
            let now = GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id == creatureId) {
                    creatureId = (creatureId == 143622) && 55659 || creatureId
                    self_demons[destGUID] = {
                        id: creatureId,
                        timestamp: now,
                        finish: now + v.duration
                    }
                    break;
                }
            }
            for (const [k, d] of pairs(self_demons)) {
                if (d.finish < now) {
                    delete self_demons[k];
                }
            }
            Ovale.needRefresh();
        } else if (cleuEvent == 'SPELL_CAST_SUCCESS') {
            if (spellId == 196277) {
                for (const [k, d] of pairs(self_demons)) {
                    if (d.id == 55659) {
                        delete self_demons[k];
                    }
                }
                Ovale.needRefresh();
            }

            const aura = CUSTOM_AURAS[spellId];
            if (aura){
                this.AddCustomAura(aura.customId, aura.stacks, aura.duration, aura.auraName);
            }
        }
    }

    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
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

    AddCustomAura(customId: number, stacks: number, duration: number, buffName: string){
        let now = GetTime()
        let expire = now + duration;
        OvaleAura.GainedAuraOnGUID(Ovale.playerGUID, now, customId, Ovale.playerGUID, "HELPFUL", false, undefined, stacks, undefined, duration, expire, false, buffName, undefined, undefined, undefined);
    }

    /**
     * Based on SimulationCraft function time_to_shard
     * Seeks to return the average expected time for the player to generate a single soul shard.
     */
    TimeToShard(now: number){
        let value = 3600;
        let creepingDeathTalent = 20;
        let tickTime = 2 / OvalePaperDoll.GetHasteMultiplier("spell", OvalePaperDoll.next);
        let [activeAgonies] = OvaleAura.AuraCount(980, "HARMFUL", true, undefined, now, undefined)
        if(activeAgonies > 0){
            value = 1 / ( 0.184 * pow( activeAgonies, -2/3 ) ) * tickTime / activeAgonies;
            if(OvaleSpellBook.IsKnownTalent(creepingDeathTalent)){
                value = value * 0.85;
            }
        }
        return value;
    }
}

OvaleWarlock = new OvaleWarlockClass();
OvaleState.RegisterState(OvaleWarlock);
