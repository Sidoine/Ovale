import { OvalePool } from "./Pool";
import { lualength, LuaObj, LuaArray, pairs } from "@wowts/lua";
import { remove, insert } from "@wowts/table";

export interface SpellCast extends PaperDollSnapshot {
    stop?: number;
    start?: number;
    lineId?: number;
    spellId?: number;
    spellName?: string;
    targetName?: string;
    target?: string;
    queued?: number;
    success?: number;
    auraId?: number;
    auraGUID?: string;
    channel?: boolean;
    caster?: string;
    offgcd?:boolean;
    damageMultiplier?: number;
    combo?: number;
    holy?:number;
}

export interface PaperDollSnapshot {
    snapshotTime?: number;
    agility?: number;
    intellect?: number;
    spirit?: number;
    stamina?: number;
    strength?: number;
    attackPower?: number;
    rangedAttackPower?: number;
    spellBonusDamage?: number;
    spellBonusHealing?: number;
    masteryEffect?: number;
    meleeCrit?: number;
    meleeHaste?: number;
    rangedCrit?: number;
    rangedHaste?: number;
    spellCrit?: number;
    spellHaste?: number;
    multistrike?: number;
    critRating?: number;
    hasteRating?: number;
    masteryRating?: number;
    multistrikeRating?: number;
    mainHandWeaponDamage?: number;
    offHandWeaponDamage?: number;
    baseDamageMultiplier?: number;
}

export interface SpellCastModule {
    CopySpellcastInfo: (mod: SpellCastModule, spellcast: SpellCast, dest: SpellCast) => void;
    SaveSpellcastInfo: (mod: SpellCastModule, spellcast: SpellCast, atTime: number, future?: {}) => void;
}

export const self_pool = new OvalePool<SpellCast>("OvaleFuture_pool");


class LastSpell {
    lastSpellcast = undefined;
    lastGCDSpellcast: SpellCast = {}
    queue: LuaArray<SpellCast> = {}
    modules: LuaObj<SpellCastModule> = {}
    
    LastInFlightSpell() {
        let spellcast: SpellCast;
        if (this.lastGCDSpellcast.success) {
            spellcast = this.lastGCDSpellcast;
        }
        for (let i = lualength(this.queue); i >= 1; i += -1) {
            let sc = this.queue[i];
            if (sc.success) {
                if (!spellcast || spellcast.success < sc.success) {
                    spellcast = sc;
                }
                break;
            }
        }
        return spellcast;
    }
    CopySpellcastInfo(spellcast: SpellCast, dest: SpellCast) {
        if (spellcast.damageMultiplier) {
            dest.damageMultiplier = spellcast.damageMultiplier;
        }
        for (const [, mod] of pairs(this.modules)) {
            let func = mod.CopySpellcastInfo;
            if (func) {
                func(mod, spellcast, dest);
            }
        }
    }

    RegisterSpellcastInfo(mod: SpellCastModule) {
        insert(this.modules, mod);
    }
    UnregisterSpellcastInfo(mod: SpellCastModule) {
        for (let i = lualength(this.modules); i >= 1; i += -1) {
            if (this.modules[i] == mod) {
                remove(this.modules, i);
            }
        }
    }

    LastSpellSent() {
        let spellcast: SpellCast = undefined;
        if (this.lastGCDSpellcast.success) {
            spellcast = this.lastGCDSpellcast;
        }
        for (let i = lualength(this.queue); i >= 1; i += -1) {
            let sc = this.queue[i];
            if (sc.success) {
                if (!spellcast || (spellcast.success && spellcast.success < sc.success) || (!spellcast.success && spellcast.queued < sc.success)) {
                    spellcast = sc;
                }
            } else if (!sc.start && !sc.stop) {
                if (spellcast.success && spellcast.success < sc.queued) {
                    spellcast = sc;
                } else if (spellcast.queued < sc.queued) {
                    spellcast = sc;
                }
            }
        }
        return spellcast;
    }
}

export const lastSpell = new LastSpell();