import { OvalePool } from "../tools/Pool";
import { lualength, LuaObj, LuaArray, pairs } from "@wowts/lua";
import { remove, insert } from "@wowts/table";
import { Powers } from "./Power";

export interface SpellCast extends Powers {
    stop: number;
    start: number;
    lineId?: string;
    spellId: number;
    spellName: string;
    targetName: string;
    target: string;
    queued: number;
    success?: number;
    auraId?: number | string;
    auraGUID?: string;
    channel?: boolean;
    caster?: string;
    castByPlayer?: boolean;
    offgcd?: boolean;
    damageMultiplier?: number;
}

export function createSpellCast(): SpellCast {
    return {
        spellId: 0,
        stop: 0,
        start: 0,
        queued: 0,
        target: "unknown",
        targetName: "target",
        spellName: "Unknown spell",
    };
}

export interface SpellCastModule {
    copySpellcastInfo: (spellcast: SpellCast, dest: SpellCast) => void;
    saveSpellcastInfo: (spellcast: SpellCast, atTime: number) => void;
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
        for (const [, mod] of pairs(this.modules)) {
            if (mod.copySpellcastInfo) {
                mod.copySpellcastInfo(spellcast, dest);
            }
        }
    }

    saveSpellcastInfo(spellcast: SpellCast, atTime: number) {
        for (const [, mod] of pairs(this.modules)) {
            if (mod.saveSpellcastInfo) {
                mod.saveSpellcastInfo(spellcast, atTime);
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
