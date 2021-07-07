import { OvalePool } from "../tools/Pool";
import { lualength, LuaObj, LuaArray, pairs } from "@wowts/lua";
import { remove, insert } from "@wowts/table";
import { Powers } from "./Power";

export interface SpellCast extends PaperDollSnapshot {
    stop: number;
    start: number;
    lineId?: string;
    spellId: number;
    spellName: string;
    targetName: string;
    targetGuid: string;
    queued: number;
    success?: number;
    auraId?: number | string;
    auraGUID?: string;
    channel?: boolean;
    caster?: string;
    castByPlayer?: boolean;
    offgcd?: boolean;
    damageMultiplier?: number;
    combopoints?: number;
}

export function createSpellCast(): SpellCast {
    return {
        spellId: 0,
        stop: 0,
        start: 0,
        queued: 0,
        hastePercent: 0,
        meleeAttackSpeedPercent: 0,
        rangedAttackSpeedPercent: 0,
        spellCastSpeedPercent: 0,
        masteryEffect: 0,
        targetGuid: "unknown",
        targetName: "target",
        spellName: "Unknown spell",
    };
}

export interface PaperDollSnapshot extends Powers {
    snapshotTime?: number;

    strength?: number;
    agility?: number;
    intellect?: number;
    stamina?: number;
    // spirit?: number;

    attackPower?: number;
    spellPower?: number;
    //rangedAttackPower?: number;
    //spellBonusDamage?: number;
    //spellBonusHealing?: number;

    critRating?: number;
    meleeCrit?: number;
    rangedCrit?: number;
    spellCrit?: number;

    hasteRating?: number;
    hastePercent: number;
    meleeAttackSpeedPercent: number;
    rangedAttackSpeedPercent: number;
    spellCastSpeedPercent: number;

    masteryRating?: number;
    masteryEffect: number;

    versatilityRating?: number;
    versatility?: number;

    mainHandWeaponDPS?: number;
    offHandWeaponDPS?: number;
    baseDamageMultiplier?: number;
}

export interface SpellCastModule {
    copySpellcastInfo: (spellcast: SpellCast, dest: SpellCast) => void;
    saveSpellcastInfo: (
        spellcast: SpellCast,
        atTime: number,
        future?: PaperDollSnapshot
    ) => void;
}

export const lastSpellCastPool = new OvalePool<SpellCast>("OvaleFuture_pool");

export class LastSpell {
    lastSpellcast: SpellCast | undefined = undefined;
    lastGCDSpellcast: SpellCast = createSpellCast();
    queue: LuaArray<SpellCast> = {};
    modules: LuaObj<SpellCastModule> = {};

    lastInFlightSpell() {
        let spellcast: SpellCast | undefined = undefined;
        if (this.lastGCDSpellcast.success) {
            spellcast = this.lastGCDSpellcast;
        }
        for (let i = lualength(this.queue); i >= 1; i += -1) {
            const sc = this.queue[i];
            if (sc.success) {
                if (
                    spellcast === undefined ||
                    spellcast.success === undefined ||
                    spellcast.success < sc.success
                ) {
                    spellcast = sc;
                }
                break;
            }
        }
        return spellcast;
    }
    copySpellcastInfo(spellcast: SpellCast, dest: SpellCast) {
        if (spellcast.damageMultiplier) {
            dest.damageMultiplier = spellcast.damageMultiplier;
        }
        for (const [, mod] of pairs(this.modules)) {
            const func = mod.copySpellcastInfo;
            if (func) {
                func(spellcast, dest);
            }
        }
    }

    registerSpellcastInfo(mod: SpellCastModule) {
        insert(this.modules, mod);
    }
    unregisterSpellcastInfo(mod: SpellCastModule) {
        for (let i = lualength(this.modules); i >= 1; i += -1) {
            if (this.modules[i] == mod) {
                remove(this.modules, i);
            }
        }
    }

    lastSpellSent() {
        let spellcast: SpellCast | undefined = undefined;
        if (this.lastGCDSpellcast.success) {
            spellcast = this.lastGCDSpellcast;
        }
        for (let i = lualength(this.queue); i >= 1; i += -1) {
            const sc = this.queue[i];
            if (sc.success) {
                if (
                    !spellcast ||
                    (spellcast.success && spellcast.success < sc.success) ||
                    (!spellcast.success &&
                        spellcast.queued &&
                        spellcast.queued < sc.success)
                ) {
                    spellcast = sc;
                }
            } else if (!sc.start && !sc.stop && sc.queued) {
                if (
                    !spellcast ||
                    (spellcast.success && spellcast.success < sc.queued)
                ) {
                    spellcast = sc;
                } else if (spellcast.queued && spellcast.queued < sc.queued) {
                    spellcast = sc;
                }
            }
        }
        return spellcast;
    }
}
