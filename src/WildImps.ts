import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { LuaArray, tonumber, pairs, LuaObj } from "@wowts/lua";
import { GetTime } from "@wowts/wow-mock";
import { find } from "@wowts/string";

let OvaleWildImpsBase = Ovale.NewModule("OvaleWildImps", aceEvent);
export let OvaleWildImps: OvaleWildImpsClass;
let demonData: LuaArray<{duration: number}> = {
    [55659]: {
        duration: 12
    },
    [98035]: {
        duration: 12
    },
    [103673]: {
        duration: 12
    },
    [11859]: {
        duration: 25
    },
    [89]: {
        duration: 25
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
class OvaleWildImpsClass extends OvaleWildImpsBase {
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
        let [timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId] = CombatLogGetCurrentEventInfo();
        self_serial = self_serial + 1;
        Ovale.needRefresh();
        if (sourceGUID != Ovale.playerGUID) {
            return;
        }
        if (cleuEvent == "SPELL_SUMMON") {
            let [,,,, , , , creatureId] = find(destGUID, '(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)');
            creatureId = tonumber(creatureId);
            let now = GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id == creatureId) {
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
                    self_demons[k] = undefined;
                }
            }
        } else if (cleuEvent == 'SPELL_INSTAKILL') {
            if (spellId == 196278) {
                self_demons[destGUID] = undefined;
            }
        } else if (cleuEvent == 'SPELL_CAST_SUCCESS') {
            if (spellId == 193396) {
                for (const [, d] of pairs(self_demons)) {
                    d.de = true;
                }
            }
        }
    }

    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    GetNotDemonicEmpoweredDemonsCount(creatureId, atTime) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId && !d.de) {
                count = count + 1;
            }
        }
        return count;
    }
    GetDemonsCount(creatureId, atTime) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return count;
    }
    GetRemainingDemonDuration(creatureId, atTime) {
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
}

OvaleWildImps = new OvaleWildImpsClass();
OvaleState.RegisterState(OvaleWildImps);
