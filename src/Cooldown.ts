import { OvaleDataClass } from "./Data";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleClass } from "./Ovale";
import { LastSpell, SpellCast, SpellCastModule } from "./LastSpell";
import { RequirementMethod, OvaleRequirement } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { next, pairs, LuaObj, tonumber } from "@wowts/lua";
import { GetSpellCooldown, GetTime, GetSpellCharges } from "@wowts/wow-mock";
import { sub } from "@wowts/string";
import { States } from "./State";
import { OvalePaperDollClass, HasteType } from "./PaperDoll";
import { LuaArray } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleProfilerClass, Profiler } from "./Profiler";

let GLOBAL_COOLDOWN = 61304;
let COOLDOWN_THRESHOLD = 0.10;
// "Spell Haste" affects cast speed and spell GCD (spells, not melee abilities), but not hasted cooldowns (cd_haste in Ovale's SpellInfo)
// "Melee Haste" is in game as "Attack Speed" and affects white swing speed only, not the GCD
// "Ranged Haste" looks to be no longer used and matches "Melee Haste" usually, DK talent Icy Talons for example;  Suppression Aura in BWL does not affect Ranged Haste but does Melee Haste as of 7/29/18

interface GcdInfo {
    [1]: number;
    [2]: HasteType;
}

const BASE_GCD = {
    ["DEATHKNIGHT"]: <GcdInfo>{
        1: 1.5,
        2: "base"
    },
    ["DEMONHUNTER"]: <GcdInfo> {
        1: 1.5,
        2: "base"
    },
    ["DRUID"]: <GcdInfo> {
        1: 1.5,
        2: "spell"
    },
    ["HUNTER"]: <GcdInfo>{
        1: 1.5,
        2: "base"
    },
    ["MAGE"]: <GcdInfo>{
        1: 1.5,
        2: "spell"
    },
    ["MONK"]: <GcdInfo>{
        1: 1.0,
        2: "none"
    },
    ["PALADIN"]: <GcdInfo>{
        1: 1.5,
        2: "spell"
    },
    ["PRIEST"]: <GcdInfo>{
        1: 1.5,
        2: "spell"
    },
    ["ROGUE"]: <GcdInfo>{
        1: 1.0,
        2: "none"
    },
    ["SHAMAN"]: <GcdInfo>{
        1: 1.5,
        2: "spell"
    },
    ["WARLOCK"]: <GcdInfo>{
        1: 1.5,
        2: "spell"
    },
    ["WARRIOR"]: <GcdInfo>{
        1: 1.5,
        2: "base"
    }
}

export interface Cooldown {
    serial?: number;
    start?: number;
    charges?: number;
    duration?: number;
    enable?: boolean;
    maxCharges?: number;
    chargeStart?: number;
    chargeDuration?: number;
}

export class CooldownData {
    cd: LuaObj<Cooldown> = undefined;
}

export class OvaleCooldownClass extends States<CooldownData> implements SpellCastModule {
    
    serial = 0;
    sharedCooldown:LuaObj<LuaArray<boolean>> = {}
    gcd = {
        serial: 0,
        start: 0,
        duration: 0
    }
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    public profiler: Profiler;

    constructor(
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleData: OvaleDataClass,
        private lastSpell: LastSpell,
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private requirement: OvaleRequirement) {
        super(CooldownData);
        this.module = ovale.createModule("OvaleCooldown", this.OnInitialize, this.OnDisable, aceEvent);
        this.tracer = ovaleDebug.create("OvaleCooldown");
        this.profiler = ovaleProfiler.create("OvaleCooldown");
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", this.Update);
        this.module.RegisterEvent("BAG_UPDATE_COOLDOWN", this.Update);
        this.module.RegisterEvent("PET_BAR_UPDATE_COOLDOWN", this.Update);
        this.module.RegisterEvent("SPELL_UPDATE_CHARGES", this.Update);
        this.module.RegisterEvent("SPELL_UPDATE_USABLE", this.Update);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", this.Update);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", this.Update);
        this.module.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", this.UNIT_SPELLCAST_INTERRUPTED);
        this.module.RegisterEvent("UNIT_SPELLCAST_START", this.Update);
        this.module.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", this.Update);
        this.module.RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", this.Update);
        this.lastSpell.RegisterSpellcastInfo(this);
        this.requirement.RegisterRequirement("oncooldown", this.RequireCooldownHandler);
    }
    
    private OnDisable = () => {
        this.lastSpell.UnregisterSpellcastInfo(this);
        this.requirement.UnregisterRequirement("oncooldown");
        this.module.UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
        this.module.UnregisterEvent("BAG_UPDATE_COOLDOWN");
        this.module.UnregisterEvent("PET_BAR_UPDATE_COOLDOWN");
        this.module.UnregisterEvent("SPELL_UPDATE_CHARGES");
        this.module.UnregisterEvent("SPELL_UPDATE_USABLE");
        this.module.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START");
        this.module.UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
        this.module.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        this.module.UnregisterEvent("UNIT_SPELLCAST_START");
        this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN");
    }
    
    private UNIT_SPELLCAST_INTERRUPTED = (event: string, unit: string) => {
        if (unit == "player" || unit == "pet") {
            this.Update(event, unit);
            this.tracer.Debug("Resetting global cooldown.");
            let cd = this.gcd;
            cd.start = 0;
            cd.duration = 0;
        }
    }

    private Update = (event: string, unit: string) => {
        if (!unit || unit == "player" || unit == "pet") {
            // Increments the serial: cooldowns stored in this.next.cd will be refreshed
            // TODO as ACTIONBAR_UPDATE_COOLDOWN is sent some time before UNIT_SPELLCAST_SUCCEEDED
            // it refreshes the cooldown before power updates
            this.serial = this.serial + 1;
            this.ovale.needRefresh();
            this.tracer.Debug(event, this.serial);
        }
    }
    ResetSharedCooldowns() {
        for (const [, spellTable] of pairs(this.sharedCooldown)) {
            for (const [spellId] of pairs(spellTable)) {
                spellTable[spellId] = undefined;
            }
        }
    }
    IsSharedCooldown(name: string | number) {
        let spellTable = this.sharedCooldown[name];
        return (spellTable && next(spellTable) != undefined);
    }
    AddSharedCooldown(name: string, spellId: number) {
        this.sharedCooldown[name] = this.sharedCooldown[name] || {
        }
        this.sharedCooldown[name][spellId] = true;
    }
    GetGlobalCooldown(now?: number): [number, number] {
        let cd = this.gcd;
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            now = now || GetTime();
            if (now >= cd.start + cd.duration) {
                [cd.start, cd.duration] = GetSpellCooldown(GLOBAL_COOLDOWN);
            }
        }
        return [cd.start, cd.duration];
    }
    GetSpellCooldown(spellId: number, atTime: number | undefined):[number, number, boolean] {
        if (atTime) {
            let cd = this.GetCD(spellId, atTime);
            return [cd.start, cd.duration, cd.enable];
        }
        let [cdStart, cdDuration, cdEnable] = [0, 0, true];
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
            let [index, bookType] = this.ovaleSpellBook.GetSpellBookIndex(spellId);
            if (index && bookType) {
                [start, duration, enable] = GetSpellCooldown(index, bookType);
            } else {
                [start, duration, enable] = GetSpellCooldown(spellId);
            }
            this.tracer.Log("Call GetSpellCooldown which returned %f, %f, %d", start, duration, enable);
            if (start && start > 0) {
                let [gcdStart, gcdDuration] = this.GetGlobalCooldown();
                this.tracer.Log("GlobalCooldown is %d, %d", gcdStart, gcdDuration);
                if (start + duration > gcdStart + gcdDuration) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                } else {
                    cdStart = start + duration;
                    cdDuration = 0;
                    cdEnable = enable;
                }
            } else {
                [cdStart, cdDuration, cdEnable] = [start || 0, duration || 0, enable];
            }
        }
        return [cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable];
    }
    GetBaseGCD():[number, HasteType] {
        let gcd: number, haste: HasteType;
        let baseGCD = BASE_GCD[this.ovale.playerClass];
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
    SaveSpellcastInfo= (mod: SpellCastModule, spellcast: SpellCast) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let gcd:number| string;
            gcd = this.ovaleData.GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target);
            if (gcd && gcd == 0) {
                spellcast.offgcd = true;
            }
        }
    }
     
    GetCD(spellId: number, atTime: number) {
        this.profiler.StartProfiling("OvaleCooldown_state_GetCD");
        let cdName = spellId;
        let si = this.ovaleData.spellInfo[spellId];
        if (si && si.shared_cd) {
            cdName = si.shared_cd;
        }
        if (!this.next.cd[cdName]) {
            this.next.cd[cdName] = {}
        }
        let cd = this.next.cd[cdName];
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            this.tracer.Log("Didn't find an existing cd in next, look for one in current")
            let [start, duration, enable] = this.GetSpellCooldown(spellId, undefined);
            if (si && si.forcecd) {
                [start, duration] = this.GetSpellCooldown(si.forcecd, undefined);
            }
            this.tracer.Log("It returned %f, %f", start, duration);
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
                this.tracer.Log("Spell cooldown is in the past");
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
        this.tracer.Log("Cooldown of spell %d is %f + %f", spellId, cd.start, cd.duration);
        this.profiler.StopProfiling("OvaleCooldown_state_GetCD");
        return cd;
    }

    GetSpellCooldownDuration(spellId: number, atTime: number, targetGUID: string) {
        let [start, duration] = this.GetSpellCooldown(spellId, atTime);
        if (duration > 0 && start + duration > atTime) {
            this.tracer.Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start);
        } else {
            [duration] = this.ovaleData.GetSpellInfoPropertyNumber(spellId, atTime, "cd", targetGUID);
            if (duration) {
                if (duration < 0) {
                    duration = 0;
                }
            } else {
                duration = 0;
            }
            this.tracer.Log("Spell %d has a base cooldown of %fs.", spellId, duration);
            if (duration > 0) {
                let haste = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID);
                if (haste) {
                    let multiplier = this.ovalePaperDoll.GetBaseHasteMultiplier(this.ovalePaperDoll.next);
                    duration = duration / multiplier;
                }
            }
        }
        return duration;
    }

    GetSpellCharges(spellId: number, atTime: number): [number, number, number, number] {
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
    
    RequireCooldownHandler: RequirementMethod = (spellId, atTime, requirement, tokens, index):[boolean, string, number] => {
        let verified = false;
        let cdSpellId = <string>tokens[index];
        index = index + 1;
        if (cdSpellId) {
            let isBang = false;
            if (sub(cdSpellId, 1, 1) == "!") {
                isBang = true;
                cdSpellId = sub(cdSpellId, 2);
            }
            let cd = this.GetCD(tonumber(cdSpellId), atTime);
            verified = !isBang && cd.duration > 0 || isBang && cd.duration <= 0;
            let result = verified && "passed" || "FAILED";
            this.tracer.Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang && "OFF" || !isBang && "ON", atTime, result, cd.duration);
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement);
        }
        return [verified, requirement, index];
    }

}
