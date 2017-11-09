import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleData } from "./Data";
import { OvaleSpellBook } from "./SpellBook";
import { Ovale } from "./Ovale";
import { lastSpell } from "./LastSpell";
import { RegisterRequirement, UnregisterRequirement } from "./Requirement";
import { DataState } from "./DataState";
import aceEvent from "@wowts/ace_event-3.0";
import { next, pairs } from "@wowts/lua";
import { GetSpellCooldown, GetTime } from "@wowts/wow-mock";

let OvaleCooldownBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleCooldown", aceEvent)));
export let OvaleCooldown: OvaleCooldownClass;
let GLOBAL_COOLDOWN = 61304;
let COOLDOWN_THRESHOLD = 0.10;
let BASE_GCD = {
    ["DEATHKNIGHT"]: {
        1: 1.5,
        2: "melee"
    },
    ["DEMONHUNTER"]: {
        1: 1.5,
        2: "melee"
    },
    ["DRUID"]: {
        1: 1.5,
        2: "spell"
    },
    ["HUNTER"]: {
        1: 1.5,
        2: "ranged"
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
        2: "melee"
    }
}

class OvaleCooldownClass extends OvaleCooldownBase {

    serial = 0;
    sharedCooldown = {}
    gcd = {
        serial: 0,
        start: 0,
        duration: 0
    }

    constructor() {
        super();
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
        RegisterRequirement("oncooldown", "RequireCooldownHandler", this);
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
    UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId) {
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
    GetSpellCooldown(spellId):[number, number, number] {
        let [cdStart, cdDuration, cdEnable] = [0, 0, 1];
        if (this.sharedCooldown[spellId]) {
            for (const [id] of pairs(this.sharedCooldown[spellId])) {
                let [start, duration, enable] = this.GetSpellCooldown(id);
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
            if (start && start > 0) {
                let [gcdStart, gcdDuration] = this.GetGlobalCooldown();
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
    CopySpellcastInfo(spellcast, dest) {
        if (spellcast.offgcd) {
            dest.offgcd = spellcast.offgcd;
        }
    }
    SaveSpellcastInfo= (mod: OvaleCooldownClass, spellcast, atTime, state: DataState) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let gcd:number| string;
            if (state) {
                gcd = state.GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target);
            } 
            else{
                gcd = OvaleData.GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target);
            }
            if (gcd && gcd == 0) {
                spellcast.offgcd = true;
            }
        }
    }
    
}

OvaleCooldown = new OvaleCooldownClass();


