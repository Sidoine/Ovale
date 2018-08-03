import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleData } from "./Data";
import { OvaleSpellBook } from "./SpellBook";
import { Ovale } from "./Ovale";
import { lastSpell, SpellCast, SpellCastModule } from "./LastSpell";
import { RegisterRequirement, UnregisterRequirement } from "./Requirement";
import aceEvent from "@wowts/ace_event-3.0";
import { next, pairs, LuaObj } from "@wowts/lua";
import { GetSpellCooldown, GetTime, GetSpellCharges } from "@wowts/wow-mock";
import { sub } from "@wowts/string";
import { OvaleState } from "./State";
import { OvalePaperDoll } from "./PaperDoll";
import { LuaArray } from "@wowts/lua";

export let OvaleCooldown: OvaleCooldownClass;
let GLOBAL_COOLDOWN = 61304;
let COOLDOWN_THRESHOLD = 0.10;
// "Spell Haste" affects cast speed and spell GCD (spells, not melee abilities), but not hasted cooldowns (cd_haste in Ovale's SpellInfo)
// "Melee Haste" is in game as "Attack Speed" and affects white swing speed only, not the GCD
// "Ranged Haste" looks to be no longer used and matches "Melee Haste" usually, DK talent Icy Talons for example;  Suppression Aura in BWL does not affect Ranged Haste but does Melee Haste as of 7/29/18
let BASE_GCD = {
    ["DEATHKNIGHT"]: {
        1: 1.5,
        2: "base"
    },
    ["DEMONHUNTER"]: {
        1: 1.5,
        2: "base"
    },
    ["DRUID"]: {
        1: 1.5,
        2: "spell"
    },
    ["HUNTER"]: {
        1: 1.5,
        2: "base"
    },
    ["MAGE"]: {
        1: 1.5,
        2: "spell"
    },
    ["MONK"]: {
        1: 1.0,
        2: false
    },
    ["PALADIN"]: {
        1: 1.5,
        2: "spell"
    },
    ["PRIEST"]: {
        1: 1.5,
        2: "spell"
    },
    ["ROGUE"]: {
        1: 1.0,
        2: false
    },
    ["SHAMAN"]: {
        1: 1.5,
        2: "spell"
    },
    ["WARLOCK"]: {
        1: 1.5,
        2: "spell"
    },
    ["WARRIOR"]: {
        1: 1.5,
        2: "base"
    }
}

export interface Cooldown {
    serial?: number;
    start?: number;
    charges?: number;
    duration?: number;
    enable?: number;
    maxCharges?: number;
    chargeStart?: number;
    chargeDuration?: number;
}

export class CooldownData {
    cd: LuaObj<Cooldown> = undefined;
}

const OvaleCooldownBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleCooldown", aceEvent))), CooldownData);

class OvaleCooldownClass extends OvaleCooldownBase implements SpellCastModule {
    
    serial = 0;
    sharedCooldown:LuaObj<LuaArray<boolean>> = {}
    gcd = {
        serial: 0,
        start: 0,
        duration: 0
    }

    OnInitialize() {
        this.RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("BAG_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "Update");
        this.RegisterEvent("SPELL_UPDATE_CHARGES", "Update");
        this.RegisterEvent("SPELL_UPDATE_USABLE", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.RegisterEvent("UNIT_SPELLCAST_START", "Update");
        this.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update");
        this.RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "Update");
        lastSpell.RegisterSpellcastInfo(this);
        RegisterRequirement("oncooldown", this.RequireCooldownHandler);
    }
    OnDisable() {
       lastSpell.UnregisterSpellcastInfo(this);
        UnregisterRequirement("oncooldown");
        this.UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
        this.UnregisterEvent("BAG_UPDATE_COOLDOWN");
        this.UnregisterEvent("PET_BAR_UPDATE_COOLDOWN");
        this.UnregisterEvent("SPELL_UPDATE_CHARGES");
        this.UnregisterEvent("SPELL_UPDATE_USABLE");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.UnregisterEvent("UNIT_SPELLCAST_START");
        this.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN");
    }
    UNIT_SPELLCAST_INTERRUPTED(event, unit, lineId, spellId) {
        if (unit == "player" || unit == "pet") {
            this.Update(event, unit);
            this.Debug("Resetting global cooldown.");
            let cd = this.gcd;
            cd.start = 0;
            cd.duration = 0;
        }
    }
    Update(event, unit) {
        if (!unit || unit == "player" || unit == "pet") {
            // Increments the serial: cooldowns stored in this.next.cd will be refreshed
            // TODO as ACTIONBAR_UPDATE_COOLDOWN is sent some time before UNIT_SPELLCAST_SUCCEEDED
            // it refreshes the cooldown before power updates
            this.serial = this.serial + 1;
            Ovale.needRefresh();
            this.Debug(event, this.serial);
        }
    }
    ResetSharedCooldowns() {
        for (const [, spellTable] of pairs(this.sharedCooldown)) {
            for (const [spellId] of pairs(spellTable)) {
                spellTable[spellId] = undefined;
            }
        }
    }
    IsSharedCooldown(name) {
        let spellTable = this.sharedCooldown[name];
        return (spellTable && next(spellTable) != undefined);
    }
    AddSharedCooldown(name, spellId) {
        this.sharedCooldown[name] = this.sharedCooldown[name] || {
        }
        this.sharedCooldown[name][spellId] = true;
    }
    GetGlobalCooldown(now?) {
        let cd = this.gcd;
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            now = now || GetTime();
            if (now >= cd.start + cd.duration) {
                [cd.start, cd.duration] = GetSpellCooldown(GLOBAL_COOLDOWN);
            }
        }
        return [cd.start, cd.duration];
    }
    GetSpellCooldown(spellId: number, atTime: number | undefined):[number, number, number] {
        if (atTime) {
            let cd = this.GetCD(spellId, atTime);
            return [cd.start, cd.duration, cd.enable];
        }
        let [cdStart, cdDuration, cdEnable] = [0, 0, 1];
        if (this.sharedCooldown[spellId]) {
            for (const [id] of pairs(this.sharedCooldown[spellId])) {
                let [start, duration, enable] = this.GetSpellCooldown(id, atTime);
                if (start) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                    break;
                }
            }
        } else {
            let start, duration, enable;
            let [index, bookType] = OvaleSpellBook.GetSpellBookIndex(spellId);
            if (index && bookType) {
                [start, duration, enable] = GetSpellCooldown(index, bookType);
            } else {
                [start, duration, enable] = GetSpellCooldown(spellId);
            }
            this.Log("Call GetSpellCooldown which returned %f, %f, %d", start, duration, enable);
            if (start && start > 0) {
                let [gcdStart, gcdDuration] = this.GetGlobalCooldown();
                this.Log("GlobalCooldown is %d, %d", gcdStart, gcdDuration);
                if (start + duration > gcdStart + gcdDuration) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                } else {
                    cdStart = start + duration;
                    cdDuration = 0;
                    cdEnable = enable;
                }
            } else {
                [cdStart, cdDuration, cdEnable] = [start || 0, duration, enable];
            }
        }
        return [cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable];
    }
    GetBaseGCD() {
        let gcd, haste;
        let baseGCD = BASE_GCD[Ovale.playerClass];
        if (baseGCD) {
            [gcd, haste] = [baseGCD[1], baseGCD[2]];
        } else {
            [gcd, haste] = [1.5, "spell"];
        }
        return [gcd, haste];
    }
    CopySpellcastInfo = (mod: SpellCastModule, spellcast: SpellCast, dest: SpellCast) => {
        if (spellcast.offgcd) {
            dest.offgcd = spellcast.offgcd;
        }
    }
    SaveSpellcastInfo= (mod: SpellCastModule, spellcast: SpellCast, atTime, state: {}) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let gcd:number| string;
            gcd = OvaleData.GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target);
            if (gcd && gcd == 0) {
                spellcast.offgcd = true;
            }
        }
    }
     
    GetCD(spellId: number, atTime: number) {
        OvaleCooldown.StartProfiling("OvaleCooldown_state_GetCD");
        let cdName = spellId;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.shared_cd) {
            cdName = si.shared_cd;
        }
        if (!this.next.cd[cdName]) {
            this.next.cd[cdName] = {}
        }
        let cd = this.next.cd[cdName];
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            this.Log("Didn't find an existing cd in next, look for one in current")
            let [start, duration, enable] = this.GetSpellCooldown(spellId, undefined);
            if (si && si.forcecd) {
                [start, duration] = this.GetSpellCooldown(si.forcecd, undefined);
            }
            this.Log("It returned %f, %f", start, duration);
            cd.serial = this.serial;
            cd.start = start - COOLDOWN_THRESHOLD;
            cd.duration = duration;
            cd.enable = enable;
            let [charges, maxCharges, chargeStart, chargeDuration] = GetSpellCharges(spellId);
            if (charges) {
                cd.charges = charges;
                cd.maxCharges = maxCharges;
                cd.chargeStart = chargeStart;
                cd.chargeDuration = chargeDuration;
            }
        }
        let now = atTime;
        if (cd.start) {
            if (cd.start + cd.duration <= now) {
                this.Log("Spell cooldown is in the past");
                cd.start = 0;
                cd.duration = 0;
            }
        }
        if (cd.charges) {
            let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
            while (chargeStart + chargeDuration <= now && charges < maxCharges) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
            cd.charges = charges;
            cd.chargeStart = chargeStart;
        }
        this.Log("Cooldown of spell %d is %f + %f", spellId, cd.start, cd.duration);
        this.StopProfiling("OvaleCooldown_state_GetCD");
        return cd;
    }

    GetSpellCooldownDuration(spellId: number, atTime: number, targetGUID: string) {
        let [start, duration] = this.GetSpellCooldown(spellId, atTime);
        if (duration > 0 && start + duration > atTime) {
            OvaleCooldown.Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start);
        } else {
            [duration] = OvaleData.GetSpellInfoPropertyNumber(spellId, atTime, "cd", targetGUID);
            if (duration) {
                if (duration < 0) {
                    duration = 0;
                }
            } else {
                duration = 0;
            }
            OvaleCooldown.Log("Spell %d has a base cooldown of %fs.", spellId, duration);
            if (duration > 0) {
                let haste = OvaleData.GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID);
                if (haste) {
                    let multiplier = OvalePaperDoll.GetBaseHasteMultiplier(OvalePaperDoll.next);
                    duration = duration / multiplier;
                }
            }
        }
        return duration;
    }
    GetSpellCharges(spellId: number, atTime: number) {
        let cd = this.GetCD(spellId, atTime);
        let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
        if (charges) {
            while (chargeStart + chargeDuration <= atTime && charges < maxCharges) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
        }
        return [charges, maxCharges, chargeStart, chargeDuration];
    }    

    
    RequireCooldownHandler = (spellId, atTime, requirement, tokens, index, targetGUID):[boolean, string, number] => {
        let cdSpellId = tokens;
        let verified = false;
        if (index) {
            cdSpellId = tokens[index];
            index = index + 1;
        }
        if (cdSpellId) {
            let isBang = false;
            if (sub(cdSpellId, 1, 1) == "!") {
                isBang = true;
                cdSpellId = sub(cdSpellId, 2);
            }
            let cd = this.GetCD(cdSpellId, atTime);
            verified = !isBang && cd.duration > 0 || isBang && cd.duration <= 0;
            let result = verified && "passed" || "FAILED";
            this.Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang && "OFF" || !isBang && "ON", atTime, result, cd.duration);
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement);
        }
        return [verified, requirement, index];
    }

}

OvaleCooldown = new OvaleCooldownClass();


