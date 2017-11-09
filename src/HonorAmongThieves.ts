import { Ovale } from "./Ovale";
import { OvaleAura } from "./Aura";
import {  OvaleData } from "./Data";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";

let OvaleHonorAmongThievesBase = Ovale.NewModule("OvaleHonorAmongThieves", aceEvent);
export let OvaleHonorAmongThieves: OvaleHonorAmongThievesClass;
let self_playerGUID = undefined;
let HONOR_AMONG_THIEVES = 51699;
let MEAN_TIME_TO_HAT = 2.2;
class OvaleHonorAmongThievesClass extends OvaleHonorAmongThievesBase {
    spellName = "Honor Among Thieves Cooldown";
    spellId = HONOR_AMONG_THIEVES;
    start = 0;
    ending = 0;
    duration = MEAN_TIME_TO_HAT;
    stacks = 0;

    OnInitialize() {
        if (Ovale.playerClass == "ROGUE") {
            self_playerGUID = Ovale.playerGUID;
            this.RegisterMessage("Ovale_SpecializationChanged");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "ROGUE") {
            this.UnregisterMessage("Ovale_SpecializationChanged");
        }
    }
    Ovale_SpecializationChanged(event, specialization, previousSpecialization) {
        if (specialization == "subtlety") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        } else {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, , , , arg16, , , , , , , , , ] = __args;
        if (sourceGUID == self_playerGUID && destGUID == self_playerGUID && cleuEvent == "SPELL_ENERGIZE") {
            let [spellId, powerType] = [arg12, arg16];
            if (spellId == HONOR_AMONG_THIEVES && powerType == 4) {
                let now = GetTime();
                this.start = now;
                let duration = <number>OvaleData.GetSpellInfoProperty(HONOR_AMONG_THIEVES, now, "duration", destGUID) || MEAN_TIME_TO_HAT;
                this.duration = duration;
                this.ending = this.start + duration;
                this.stacks = 1;
                OvaleAura.GainedAuraOnGUID(self_playerGUID, this.start, this.spellId, self_playerGUID, "HELPFUL", undefined, undefined, this.stacks, undefined, this.duration, this.ending, undefined, this.spellName, undefined, undefined, undefined);
            }
        }
    }
}
OvaleHonorAmongThieves = new OvaleHonorAmongThievesClass();