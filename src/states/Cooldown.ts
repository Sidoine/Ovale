import { OvaleDataClass } from "../engine/data";
import { OvaleClass } from "../Ovale";
import { LastSpell, SpellCast, SpellCastModule } from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { next, pairs, LuaObj, kpairs } from "@wowts/lua";
import { GetSpellCooldown, GetTime, GetSpellCharges } from "@wowts/wow-mock";
import { StateModule, States } from "../engine/state";
import { OvalePaperDollClass, HasteType } from "./PaperDoll";
import { LuaArray } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { isNumber } from "../tools/tools";

const globalCooldown = 61304;
const cooldownThreshold = 0.1;
// "Spell Haste" affects cast speed and spell GCD (spells, not melee abilities), but not hasted cooldowns (cd_haste in Ovale's SpellInfo)
// "Melee Haste" is in game as "Attack Speed" and affects white swing speed only, not the GCD
// "Ranged Haste" looks to be no longer used and matches "Melee Haste" usually, DK talent Icy Talons for example;  Suppression Aura in BWL does not affect Ranged Haste but does Melee Haste as of 7/29/18

interface GcdInfo {
    [1]: number;
    [2]: HasteType;
}

const baseGcds = {
    ["DEATHKNIGHT"]: <GcdInfo>{
        1: 1.5,
        2: "base",
    },
    ["DEMONHUNTER"]: <GcdInfo>{
        1: 1.5,
        2: "base",
    },
    ["DRUID"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["HUNTER"]: <GcdInfo>{
        1: 1.5,
        2: "base",
    },
    ["MAGE"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["MONK"]: <GcdInfo>{
        1: 1.0,
        2: "none",
    },
    ["PALADIN"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["PRIEST"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["ROGUE"]: <GcdInfo>{
        1: 1.0,
        2: "none",
    },
    ["SHAMAN"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["WARLOCK"]: <GcdInfo>{
        1: 1.5,
        2: "spell",
    },
    ["WARRIOR"]: <GcdInfo>{
        1: 1.5,
        2: "base",
    },
};

export interface Cooldown {
    serial?: number;
    start: number;
    charges: number;
    duration: number;
    enable: boolean;
    maxCharges: number;
    chargeStart: number;
    chargeDuration: number;
}

export class CooldownData {
    cd: LuaObj<Cooldown> = {};
}

export class OvaleCooldownClass
    extends States<CooldownData>
    implements SpellCastModule, StateModule
{
    serial = 0;
    sharedCooldown: LuaObj<LuaArray<boolean>> = {};
    gcd = {
        serial: 0,
        start: 0,
        duration: 0,
    };
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    public profiler: Profiler;

    constructor(
        private ovalePaperDoll: OvalePaperDollClass,
        private ovaleData: OvaleDataClass,
        private lastSpell: LastSpell,
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass
    ) {
        super(CooldownData);
        this.module = ovale.createModule(
            "OvaleCooldown",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create("OvaleCooldown");
        this.profiler = ovaleProfiler.create("OvaleCooldown");
    }

    private handleInitialize = () => {
        this.module.RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", this.update);
        this.module.RegisterEvent("BAG_UPDATE_COOLDOWN", this.update);
        this.module.RegisterEvent("PET_BAR_UPDATE_COOLDOWN", this.update);
        this.module.RegisterEvent("SPELL_UPDATE_CHARGES", this.update);
        this.module.RegisterEvent("SPELL_UPDATE_USABLE", this.update);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", this.update);
        this.module.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", this.update);
        this.module.RegisterEvent(
            "UNIT_SPELLCAST_INTERRUPTED",
            this.handleUnitSpellCastInterrupted
        );
        this.module.RegisterEvent("UNIT_SPELLCAST_START", this.update);
        this.module.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", this.update);
        this.module.RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", this.update);
        this.lastSpell.registerSpellcastInfo(this);
    };

    private handleDisable = () => {
        this.lastSpell.unregisterSpellcastInfo(this);
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
    };

    private handleUnitSpellCastInterrupted = (event: string, unit: string) => {
        if (unit == "player" || unit == "pet") {
            this.update(event, unit);
            this.tracer.debug("Resetting global cooldown.");
            const cd = this.gcd;
            cd.start = 0;
            cd.duration = 0;
        }
    };

    private update = (event: string, unit: string) => {
        if (!unit || unit == "player" || unit == "pet") {
            // Increments the serial: cooldowns stored in this.next.cd will be refreshed
            // TODO as ACTIONBAR_UPDATE_COOLDOWN is sent some time before UNIT_SPELLCAST_SUCCEEDED
            // it refreshes the cooldown before power updates
            this.serial = this.serial + 1;
            this.ovale.needRefresh();
            this.tracer.debug(event, this.serial);
        }
    };
    resetSharedCooldowns() {
        for (const [, spellTable] of pairs(this.sharedCooldown)) {
            for (const [spellId] of pairs(spellTable)) {
                delete spellTable[spellId];
            }
        }
    }
    isSharedCooldown(name: string | number) {
        const spellTable = this.sharedCooldown[name];
        return spellTable && next(spellTable) != undefined;
    }
    addSharedCooldown(name: string, spellId: number) {
        this.sharedCooldown[name] = this.sharedCooldown[name] || {};
        this.sharedCooldown[name][spellId] = true;
    }
    getGlobalCooldown(now?: number): [number, number] {
        const cd = this.gcd;
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            now = now || GetTime();
            if (now >= cd.start + cd.duration) {
                [cd.start, cd.duration] = GetSpellCooldown(globalCooldown);
            }
        }
        return [cd.start, cd.duration];
    }
    getSpellCooldown(
        spellId: number | string,
        atTime: number | undefined
    ): [number, number, boolean] {
        if (atTime) {
            const cd = this.getCD(spellId, atTime);
            return [cd.start, cd.duration, cd.enable];
        }
        let [cdStart, cdDuration, cdEnable] = [0, 0, true];
        if (this.sharedCooldown[spellId]) {
            for (const [id] of pairs(this.sharedCooldown[spellId])) {
                const [start, duration, enable] = this.getSpellCooldown(
                    id,
                    atTime
                );
                if (start) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                    break;
                }
            }
        } else {
            let [start, duration, enable] = GetSpellCooldown(spellId);
            this.tracer.log(
                "Call GetSpellCooldown which returned %f, %f, %d",
                start,
                duration,
                enable
            );
            if (start !== undefined && start > 0) {
                const [gcdStart, gcdDuration] = this.getGlobalCooldown();
                this.tracer.log(
                    "GlobalCooldown is %d, %d",
                    gcdStart,
                    gcdDuration
                );
                if (start + duration > gcdStart + gcdDuration) {
                    [cdStart, cdDuration, cdEnable] = [start, duration, enable];
                } else {
                    cdStart = start + duration;
                    cdDuration = 0;
                    cdEnable = enable;
                }
            } else {
                [cdStart, cdDuration, cdEnable] = [
                    start || 0,
                    duration || 0,
                    enable,
                ];
            }
        }
        return [cdStart - cooldownThreshold, cdDuration, cdEnable];
    }
    getBaseGCD(): [number, HasteType] {
        let gcd: number, haste: HasteType;
        const baseGCD = baseGcds[this.ovale.playerClass];
        if (baseGCD) {
            [gcd, haste] = [baseGCD[1], baseGCD[2]];
        } else {
            [gcd, haste] = [1.5, "spell"];
        }
        return [gcd, haste];
    }

    copySpellcastInfo = (spellcast: SpellCast, dest: SpellCast) => {
        if (spellcast.offgcd) {
            dest.offgcd = spellcast.offgcd;
        }
    };

    saveSpellcastInfo = (spellcast: SpellCast, atTime: number) => {
        const spellId = spellcast.spellId;
        if (spellId) {
            const gcd = this.ovaleData.getSpellInfoProperty(
                spellId,
                spellcast.start,
                "gcd",
                spellcast.target
            );
            if (gcd && gcd == 0) {
                spellcast.offgcd = true;
            }
        }
    };

    getCD(spellId: number | string, atTime: number) {
        this.profiler.startProfiling("OvaleCooldown_state_GetCD");
        let cdName: string | number = spellId;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.shared_cd) {
            cdName = si.shared_cd;
        }
        if (!this.next.cd[cdName]) {
            this.next.cd[cdName] = {
                start: 0,
                duration: 0,
                enable: false,
                chargeDuration: 0,
                chargeStart: 0,
                charges: 0,
                maxCharges: 0,
            };
        }
        const cd = this.next.cd[cdName];
        if (!cd.start || !cd.serial || cd.serial < this.serial) {
            this.tracer.log(
                "Didn't find an existing cd in next, look for one in current"
            );
            let [start, duration, enable] = this.getSpellCooldown(
                spellId,
                undefined
            );
            if (si && si.forcecd) {
                [start, duration] = this.getSpellCooldown(
                    si.forcecd,
                    undefined
                );
            }
            this.tracer.log("It returned %f, %f", start, duration);
            cd.serial = this.serial;
            cd.start = start - cooldownThreshold;
            cd.duration = duration;
            cd.enable = enable;
            if (isNumber(spellId)) {
                const [charges, maxCharges, chargeStart, chargeDuration] =
                    GetSpellCharges(spellId);
                if (charges) {
                    cd.charges = charges;
                    cd.maxCharges = maxCharges;
                    cd.chargeStart = chargeStart;
                    cd.chargeDuration = chargeDuration;
                }
            }
        }
        const now = atTime;
        if (cd.start) {
            if (cd.start + cd.duration <= now) {
                this.tracer.log("Spell cooldown is in the past");
                cd.start = 0;
                cd.duration = 0;
            }
        }
        if (cd.charges) {
            let charges = cd.charges;
            const maxCharges = cd.maxCharges;
            let chargeStart = cd.chargeStart;
            const chargeDuration = cd.chargeDuration;
            while (
                chargeStart + chargeDuration <= now &&
                charges < maxCharges
            ) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
            cd.charges = charges;
            cd.chargeStart = chargeStart;
        }
        this.tracer.log(
            "Cooldown of spell %d is %f + %f",
            spellId,
            cd.start,
            cd.duration
        );
        this.profiler.stopProfiling("OvaleCooldown_state_GetCD");
        return cd;
    }

    getSpellCooldownDuration(
        spellId: number,
        atTime: number,
        targetGUID: string
    ) {
        let [start, duration] = this.getSpellCooldown(spellId, atTime);
        if (duration > 0 && start + duration > atTime) {
            this.tracer.log(
                "Spell %d is on cooldown for %fs starting at %s.",
                spellId,
                duration,
                start
            );
        } else {
            [duration] = this.ovaleData.getSpellInfoPropertyNumber(
                spellId,
                atTime,
                "cd",
                targetGUID
            );
            if (duration !== undefined) {
                if (duration < 0) {
                    duration = 0;
                }
            } else {
                duration = 0;
            }
            this.tracer.log(
                "Spell %d has a base cooldown of %fs.",
                spellId,
                duration
            );
            if (duration > 0) {
                const haste = this.ovaleData.getSpellInfoProperty(
                    spellId,
                    atTime,
                    "cd_haste",
                    targetGUID
                );
                if (haste) {
                    const multiplier =
                        this.ovalePaperDoll.getBaseHasteMultiplier(atTime);
                    duration = duration / multiplier;
                }
            }
        }
        return duration;
    }

    getSpellCharges(
        spellId: number,
        atTime: number
    ): [number, number, number, number] {
        const cd = this.getCD(spellId, atTime);
        let charges = cd.charges;
        const maxCharges = cd.maxCharges;
        let chargeStart = cd.chargeStart;
        const chargeDuration = cd.chargeDuration;
        if (charges) {
            while (
                chargeStart + chargeDuration <= atTime &&
                charges < maxCharges
            ) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
        }
        return [charges, maxCharges, chargeStart, chargeDuration];
    }

    applySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleCooldown_ApplySpellStartCast");
        if (isChanneled) {
            this.applyCooldown(spellId, targetGUID, startCast);
        }
        this.profiler.stopProfiling("OvaleCooldown_ApplySpellStartCast");
    };
    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleCooldown_ApplySpellAfterCast");
        if (!isChanneled) {
            this.applyCooldown(spellId, targetGUID, endCast);
        }
        this.profiler.stopProfiling("OvaleCooldown_ApplySpellAfterCast");
    };

    initializeState() {
        this.next.cd = {};
    }
    resetState() {
        for (const [, cd] of pairs(this.next.cd)) {
            cd.serial = undefined;
        }
    }
    cleanState() {
        for (const [spellId, cd] of pairs(this.next.cd)) {
            for (const [k] of kpairs(cd)) {
                delete cd[k];
            }
            delete this.next.cd[spellId];
        }
    }

    private applyCooldown(spellId: number, targetGUID: string, atTime: number) {
        this.profiler.startProfiling("OvaleCooldown_state_ApplyCooldown");
        const cd = this.getCD(spellId, atTime);
        const duration = this.getSpellCooldownDuration(
            spellId,
            atTime,
            targetGUID
        );
        if (duration == 0) {
            cd.start = 0;
            cd.duration = 0;
            cd.enable = true;
        } else {
            cd.start = atTime;
            cd.duration = duration;
            cd.enable = true;
        }
        if (cd.charges && cd.charges > 0) {
            cd.chargeStart = cd.start;
            cd.charges = cd.charges - 1;
            if (cd.charges == 0) {
                cd.duration = cd.chargeDuration;
            }
        }
        this.tracer.log(
            "Spell %d cooldown info: start=%f, duration=%f, charges=%s",
            spellId,
            cd.start,
            cd.duration,
            cd.charges || "(nil)"
        );
        this.profiler.stopProfiling("OvaleCooldown_state_ApplyCooldown");
    }
    debugCooldown() {
        for (const [spellId, cd] of pairs(this.next.cd)) {
            if (cd.start) {
                if (cd.charges) {
                    this.tracer.print(
                        "Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f",
                        spellId,
                        cd.start,
                        cd.duration,
                        cd.charges,
                        cd.maxCharges,
                        cd.chargeStart,
                        cd.chargeDuration
                    );
                } else {
                    this.tracer.print(
                        "Spell %s cooldown: start=%f, duration=%f",
                        spellId,
                        cd.start,
                        cd.duration
                    );
                }
            }
        }
    }
}
