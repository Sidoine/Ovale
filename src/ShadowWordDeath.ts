import { Ovale } from "./Ovale";
import { OvaleAura } from "./Aura";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime } from "@wowts/wow-mock";

let OvaleShadowWordDeathBase = Ovale.NewModule("OvaleShadowWordDeath", aceEvent);
export let OvaleShadowWordDeath: OvaleShadowWordDeathClass;
let self_playerGUID = undefined;
let SHADOW_WORD_DEATH = {
    [32379]: true,
    [129176]: true
}
class OvaleShadowWordDeathClass extends OvaleShadowWordDeathBase {

    spellName = "Shadow Word: Death Reset Cooldown";
    spellId = 125927;
    start = 0;
    ending = 0;
    duration = 9;
    stacks = 0;

    OnInitialize() {
        if (Ovale.playerClass == "PRIEST") {
            self_playerGUID = Ovale.playerGUID;
            this.RegisterMessage("Ovale_SpecializationChanged");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "PRIEST") {
            this.UnregisterMessage("Ovale_SpecializationChanged");
        }
    }
    Ovale_SpecializationChanged(event, specialization, previousSpecialization) {
        if (specialization == "shadow") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        } else {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, , , , arg16] = __args;
        if (sourceGUID == self_playerGUID) {
            if (cleuEvent == "SPELL_DAMAGE") {
                let [spellId, overkill] = [arg12, arg16];
                if (SHADOW_WORD_DEATH[spellId] && !(overkill && overkill > 0)) {
                    let now = GetTime();
                    this.start = now;
                    this.ending = now + this.duration;
                    this.stacks = 1;
                    OvaleAura.GainedAuraOnGUID(self_playerGUID, this.start, this.spellId, self_playerGUID, "HELPFUL", undefined, undefined, this.stacks, undefined, this.duration, this.ending, undefined, this.spellName, undefined, undefined, undefined);
                }
            }
        }
    }
}

OvaleShadowWordDeath = new OvaleShadowWordDeathClass();