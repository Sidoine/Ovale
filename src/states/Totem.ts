import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, pairs, LuaArray, kpairs } from "@wowts/lua";
import { GetTotemInfo, MAX_TOTEMS } from "@wowts/wow-mock";
import { SpellCast } from "./LastSpell";
import { OvaleStateClass, StateModule, States } from "../engine/state";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { OvaleFutureClass } from "./Future";
import { OvaleAuraClass } from "./Aura";
import { OvaleSpellBookClass } from "./SpellBook";
import { DebugTools, Tracer } from "../engine/debug";

let serial = 0;

interface Totem {
    duration: number;
    start: number;
    serial: number;
    name?: string;
    icon?: string;
    slot: number;
}

class TotemData {
    totems: LuaArray<Totem> = {};
}

export class OvaleTotemClass extends States<TotemData> implements StateModule {
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private debug: Tracer;

    constructor(
        private ovale: OvaleClass,
        ovaleState: OvaleStateClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private ovaleFuture: OvaleFutureClass,
        private ovaleAura: OvaleAuraClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        ovaleDebug: DebugTools
    ) {
        super(TotemData);
        this.debug = ovaleDebug.create("OvaleTotem");
        this.module = ovale.createModule(
            "OvaleTotem",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        ovaleState.registerState(this);
    }

    private handleInitialize = () => {
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.update);
        this.module.RegisterEvent("PLAYER_TALENT_UPDATE", this.update);
        this.module.RegisterEvent("PLAYER_TOTEM_UPDATE", this.update);
        this.module.RegisterEvent("UPDATE_SHAPESHIFT_FORM", this.update);
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_TALENT_UPDATE");
        this.module.UnregisterEvent("PLAYER_TOTEM_UPDATE");
        this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
    };
    private update = () => {
        serial = serial + 1;
        this.ovale.needRefresh();
    };

    initializeState() {
        this.next.totems = {};
        // shamans can use the fifth slot when all of the totems are active
        // that's why we +1 it everywhere we use
        for (let slot = 1; slot <= MAX_TOTEMS + 1; slot += 1) {
            this.next.totems[slot] = {
                slot: slot,
                serial: 0,
                start: 0,
                duration: 0,
            };
        }
    }
    resetState() {}
    cleanState() {
        for (const [slot, totem] of pairs(this.next.totems)) {
            for (const [k] of kpairs(totem)) {
                delete totem[k];
            }
            delete this.next.totems[slot];
        }
    }

    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleTotem_ApplySpellAfterCast");
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.totem) {
            this.summonTotem(spellId, endCast);
        }
        this.profiler.stopProfiling("OvaleTotem_ApplySpellAfterCast");
    };

    isActiveTotem(totem: Totem, atTime: number) {
        if (!totem) return false;
        if (!totem.serial || totem.serial < serial) {
            totem = this.getTotem(totem.slot);
        }
        return (
            totem &&
            totem.serial == serial &&
            totem.start &&
            totem.duration &&
            totem.start < atTime &&
            atTime < totem.start + totem.duration
        );
    }

    getTotem(slot: number) {
        this.profiler.startProfiling("OvaleTotem_state_GetTotem");
        const totem = this.next.totems[slot];
        if (totem && (!totem.serial || totem.serial < serial)) {
            const [haveTotem, name, startTime, duration, icon] = GetTotemInfo(
                slot
            );
            if (haveTotem) {
                totem.name = name;
                totem.start = startTime;
                totem.duration = duration;
                totem.icon = icon;
            } else {
                totem.name = "";
                totem.start = 0;
                totem.duration = 0;
                totem.icon = "";
            }
            totem.slot = slot;
            totem.serial = serial;
        }
        this.profiler.stopProfiling("OvaleTotem_state_GetTotem");
        return totem;
    }

    getTotemInfo(spellId: number, atTime: number) {
        let start, ending;
        let count = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.totem) {
            this.debug.log("Spell %s is a totem spell", spellId);
            // it can take a while for the buffs to appear
            // so if the previous GCD spell is our totem, we assume the buffs are up
            let buffPresent = this.ovaleFuture.next.lastGCDSpellId == spellId;
            if (!buffPresent && si.buff_totem) {
                const aura = this.ovaleAura.getAura(
                    "player",
                    si.buff_totem,
                    atTime,
                    "HELPFUL"
                );
                buffPresent =
                    (aura && this.ovaleAura.isActiveAura(aura, atTime)) ||
                    false;
            }
            if (!si.buff_totem || buffPresent) {
                const texture = this.ovaleSpellBook.getSpellTexture(spellId);
                const maxTotems = si.max_totems || MAX_TOTEMS + 1;
                for (const [slot] of ipairs(this.next.totems)) {
                    const totem = this.getTotem(slot);
                    if (
                        this.isActiveTotem(totem, atTime) &&
                        totem.icon == texture
                    ) {
                        count = count + 1;
                        if (!start || start > totem.start) {
                            start = totem.start;
                        }
                        if (!ending || ending < totem.start + totem.duration) {
                            ending = totem.start + totem.duration;
                        }
                    }
                    if (count >= maxTotems) {
                        break;
                    }
                }
            }
        } else {
            this.debug.log("Spell %s is NOT a totem spell", spellId);
        }
        return [count, start, ending];
    }

    summonTotem(spellId: number, atTime: number) {
        this.profiler.startProfiling("OvaleTotem_state_SummonTotem");

        const totemSlot = this.getAvailableTotemSlot(spellId, atTime);
        if (totemSlot) {
            const [name, , icon] = this.ovaleSpellBook.getSpellInfo(spellId);
            const duration = this.ovaleData.getSpellInfoProperty(
                spellId,
                atTime,
                "duration",
                undefined
            );
            const totem = this.next.totems[totemSlot];
            totem.name = name;
            totem.start = atTime;
            totem.duration = duration || 15;
            totem.icon = icon;
            totem.slot = totemSlot;
            this.debug.log(
                "Spell ID '%d' summoned a totem in state slot %d",
                spellId,
                totemSlot
            );
        }
        this.profiler.stopProfiling("OvaleTotem_state_SummonTotem");
    }

    getAvailableTotemSlot(spellId: number, atTime: number): number | undefined {
        this.profiler.startProfiling(
            "OvaleTotem_state_GetNextAvailableTotemSlot"
        );
        let availableSlot = undefined;

        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.totem) {
            const [, , icon] = this.ovaleSpellBook.getSpellInfo(spellId);

            for (let i = 1; i <= MAX_TOTEMS + 1; i += 1) {
                const totem = this.next.totems[i];
                if (
                    availableSlot == undefined &&
                    (!this.isActiveTotem(totem, atTime) ||
                        (si.max_totems == 1 && totem.icon == icon))
                ) {
                    availableSlot = i;
                }
            }

            // all slots are occupied, take the one with the smallest duration left
            if (availableSlot == undefined) {
                availableSlot = 1;
                const firstTotem = this.next.totems[1];
                const smallestEndTime = firstTotem.start + firstTotem.duration;
                for (let i = 2; i <= MAX_TOTEMS + 1; i += 1) {
                    const totem = this.next.totems[i];
                    const endTime = totem.start + totem.duration;

                    if (endTime < smallestEndTime) {
                        availableSlot = i;
                    }
                }
            }
        }
        this.profiler.stopProfiling(
            "OvaleTotem_state_GetNextAvailableTotemSlot"
        );
        return availableSlot;
    }
}
