import { Ovale } from "./Ovale";
import { OvaleAura } from "./Aura";
import { OvaleEquipment } from "./Equipment";
import { OvalePaperDoll } from "./PaperDoll";
import aceEvent from "@wowts/ace_event-3.0";
import { exp, huge as INFINITY } from "@wowts/math";
import { pairs } from "@wowts/lua";
import { GetTime, INVSLOT_TRINKET1, INVSLOT_TRINKET2 } from "@wowts/wow-mock";

let OvalePassiveAuraBase = Ovale.NewModule("OvalePassiveAura", aceEvent);
export let OvalePassiveAura: OvalePassiveAuraClass;
let self_playerGUID = undefined;
let TRINKET_SLOTS = {
    1: INVSLOT_TRINKET1,
    2: INVSLOT_TRINKET2
}
let AURA_NAME = {
}
let INCREASED_CRIT_EFFECT_3_PERCENT = 44797;
{
    AURA_NAME[INCREASED_CRIT_EFFECT_3_PERCENT] = "3% Increased Critical Effect";
}
let INCREASED_CRIT_EFFECT = {
    [INCREASED_CRIT_EFFECT_3_PERCENT]: 1.03
}
let INCREASED_CRIT_META_GEM = {
    [32409]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [34220]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [41285]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [41398]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [52291]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [52297]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [68778]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [68779]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [68780]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [76884]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [76885]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [76886]: INCREASED_CRIT_EFFECT_3_PERCENT,
    [76888]: INCREASED_CRIT_EFFECT_3_PERCENT
}
let AMPLIFICATION = 146051;
{
    AURA_NAME[AMPLIFICATION] = "Amplification";
}
let AMPLIFICATION_TRINKET = {
    [102293]: AMPLIFICATION,
    [104426]: AMPLIFICATION,
    [104675]: AMPLIFICATION,
    [104924]: AMPLIFICATION,
    [105173]: AMPLIFICATION,
    [105422]: AMPLIFICATION,
    [102299]: AMPLIFICATION,
    [104478]: AMPLIFICATION,
    [104727]: AMPLIFICATION,
    [104976]: AMPLIFICATION,
    [105225]: AMPLIFICATION,
    [105474]: AMPLIFICATION,
    [102305]: AMPLIFICATION,
    [104613]: AMPLIFICATION,
    [104862]: AMPLIFICATION,
    [105111]: AMPLIFICATION,
    [105360]: AMPLIFICATION,
    [105609]: AMPLIFICATION
}
let READINESS_AGILITY_DPS = 146019;
let READINESS_STRENGTH_DPS = 145955;
let READINESS_TANK = 146025;
{
    AURA_NAME[READINESS_AGILITY_DPS] = "Readiness";
    AURA_NAME[READINESS_STRENGTH_DPS] = "Readiness";
    AURA_NAME[READINESS_TANK] = "Readiness";
}
let READINESS_TRINKET = {
    [102292]: READINESS_AGILITY_DPS,
    [104476]: READINESS_AGILITY_DPS,
    [104725]: READINESS_AGILITY_DPS,
    [104974]: READINESS_AGILITY_DPS,
    [105223]: READINESS_AGILITY_DPS,
    [105472]: READINESS_AGILITY_DPS,
    [102298]: READINESS_STRENGTH_DPS,
    [104495]: READINESS_STRENGTH_DPS,
    [104744]: READINESS_STRENGTH_DPS,
    [104993]: READINESS_STRENGTH_DPS,
    [105242]: READINESS_STRENGTH_DPS,
    [105491]: READINESS_STRENGTH_DPS,
    [102306]: READINESS_TANK,
    [104572]: READINESS_TANK,
    [104821]: READINESS_TANK,
    [105070]: READINESS_TANK,
    [105319]: READINESS_TANK,
    [105568]: READINESS_TANK
}
let READINESS_ROLE = {
    DEATHKNIGHT: {
        blood: READINESS_TANK,
        frost: READINESS_STRENGTH_DPS,
        unholy: READINESS_STRENGTH_DPS
    },
    DRUID: {
        feral: READINESS_AGILITY_DPS,
        guardian: READINESS_TANK
    },
    HUNTER: {
        beast_mastery: READINESS_AGILITY_DPS,
        marksmanship: READINESS_AGILITY_DPS,
        survival: READINESS_AGILITY_DPS
    },
    MONK: {
        brewmaster: READINESS_TANK,
        windwalker: READINESS_AGILITY_DPS
    },
    PALADIN: {
        protection: READINESS_TANK,
        retribution: READINESS_STRENGTH_DPS
    },
    ROGUE: {
        assassination: READINESS_AGILITY_DPS,
        combat: READINESS_AGILITY_DPS,
        subtlety: READINESS_AGILITY_DPS
    },
    SHAMAN: {
        enhancement: READINESS_AGILITY_DPS
    },
    WARRIOR: {
        arms: READINESS_STRENGTH_DPS,
        fury: READINESS_STRENGTH_DPS,
        protection: READINESS_TANK
    }
}
class OvalePassiveAuraClass extends OvalePassiveAuraBase {
    OnInitialize() {
        self_playerGUID = Ovale.playerGUID;
        this.RegisterMessage("Ovale_EquipmentChanged");
        this.RegisterMessage("Ovale_SpecializationChanged");
    }
    OnDisable() {
        this.UnregisterMessage("Ovale_EquipmentChanged");
        this.UnregisterMessage("Ovale_SpecializationChanged");
    }
    Ovale_EquipmentChanged() {
        this.UpdateIncreasedCritEffectMetaGem();
        this.UpdateAmplification();
        this.UpdateReadiness();
    }
    Ovale_SpecializationChanged() {
        this.UpdateReadiness();
    }
    UpdateIncreasedCritEffectMetaGem() {
        let metaGem = OvaleEquipment.metaGem;
        let spellId = metaGem && INCREASED_CRIT_META_GEM[metaGem];
        let now = GetTime();
        if (spellId) {
            let name = AURA_NAME[spellId];
            let start = now;
            let duration = INFINITY;
            let ending = INFINITY;
            let stacks = 1;
            let value = INCREASED_CRIT_EFFECT[spellId];
            OvaleAura.GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", undefined, undefined, stacks, undefined, duration, ending, undefined, name, value, undefined, undefined);
        } else {
            OvaleAura.LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID);
        }
    }
    UpdateAmplification() {
        let hasAmplification = false;
        let critDamageIncrease = 0;
        let statMultiplier = 1;
        for (const [, slot] of pairs(TRINKET_SLOTS)) {
            let [trinket] = OvaleEquipment.GetEquippedItem(slot);
            if (trinket && AMPLIFICATION_TRINKET[trinket]) {
                hasAmplification = true;
                let [ilevel] = OvaleEquipment.GetEquippedItemLevel(slot);
                if (ilevel == undefined) ilevel = 528;

                let amplificationEffect = exp((ilevel - 528) * 0.009327061882 + 1.713797928);
                if (OvalePaperDoll.level >= 90) {
                    amplificationEffect = amplificationEffect * (100 - OvalePaperDoll.level) / 10;
                    amplificationEffect = amplificationEffect > 1 && amplificationEffect || 1;
                }
                critDamageIncrease = critDamageIncrease + amplificationEffect / 100;
                statMultiplier = statMultiplier * (1 + amplificationEffect / 100);
            }
        }
        let now = GetTime();
        let spellId = AMPLIFICATION;
        if (hasAmplification) {
            let name = AURA_NAME[spellId];
            let start = now;
            let duration = INFINITY;
            let ending = INFINITY;
            let stacks = 1;
            let value1 = critDamageIncrease;
            let value2 = statMultiplier;
            OvaleAura.GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", undefined, undefined, stacks, undefined, duration, ending, undefined, name, value1, value2, undefined);
        } else {
            OvaleAura.LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID);
        }
    }
    UpdateReadiness() {
        let specialization = OvalePaperDoll.GetSpecialization();
        let spellId = READINESS_ROLE[Ovale.playerClass] && READINESS_ROLE[Ovale.playerClass][specialization];
        if (spellId) {
            let hasReadiness = false;
            let cdMultiplier;
            for (const [, slot] of pairs(TRINKET_SLOTS)) {
                let [trinket] = OvaleEquipment.GetEquippedItem(slot);
                let readinessId = trinket && READINESS_TRINKET[trinket];
                if (readinessId) {
                    hasReadiness = true;
                    let [ilevel] = OvaleEquipment.GetEquippedItemLevel(slot);
                    ilevel = ilevel || 528;
                    let cdRecoveryRateIncrease = exp((ilevel - 528) * 0.009317881032 + 3.434954478);
                    if (readinessId == READINESS_TANK) {
                        cdRecoveryRateIncrease = cdRecoveryRateIncrease / 2;
                    }
                    if (OvalePaperDoll.level >= 90) {
                        cdRecoveryRateIncrease = cdRecoveryRateIncrease * (100 - OvalePaperDoll.level) / 10;
                    }
                    cdMultiplier = 1 / (1 + cdRecoveryRateIncrease / 100);
                    cdMultiplier = cdMultiplier < 0.9 && cdMultiplier || 0.9;
                    break;
                }
            }
            let now = GetTime();
            if (hasReadiness) {
                let name = AURA_NAME[spellId];
                let start = now;
                let duration = INFINITY;
                let ending = INFINITY;
                let stacks = 1;
                let value = cdMultiplier;
                OvaleAura.GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", undefined, undefined, stacks, undefined, duration, ending, undefined, name, value, undefined, undefined);
            } else {
                OvaleAura.LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID);
            }
        }
    }
}

OvalePassiveAura = new OvalePassiveAuraClass();