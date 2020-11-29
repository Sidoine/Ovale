import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, pairs, LuaObj, LuaArray, kpairs } from "@wowts/lua";
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
import { OvaleDebugClass, Tracer } from "../engine/debug";

let self_serial = 0;
const TOTEM_CLASS: LuaObj<boolean> = {
    DRUID: true,
    MAGE: true,
    MONK: true,
    PALADIN: true,
    SHAMAN: true,
};

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
        ovaleDebug: OvaleDebugClass
    ) {
        super(TotemData);
        this.debug = ovaleDebug.create("OvaleTotem");
        this.module = ovale.createModule(
            "OvaleTotem",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        ovaleState.RegisterState(this);
    }

    private OnInitialize = () => {
        if (TOTEM_CLASS[this.ovale.playerClass]) {
            this.debug.DebugTimestamp(
                "Initialzing OvaleTotem for class %s",
                this.ovale.playerClass
            );
            this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.Update);
            this.module.RegisterEvent("PLAYER_TALENT_UPDATE", this.Update);
            this.module.RegisterEvent("PLAYER_TOTEM_UPDATE", this.Update);
            this.module.RegisterEvent("UPDATE_SHAPESHIFT_FORM", this.Update);
        } else {
            this.debug.DebugTimestamp(
                "Class %s is not a TOTEM_CLASS!",
                this.ovale.playerClass
            );
        }
    };

    private OnDisable = () => {
        if (TOTEM_CLASS[this.ovale.playerClass]) {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterEvent("PLAYER_TALENT_UPDATE");
            this.module.UnregisterEvent("PLAYER_TOTEM_UPDATE");
            this.module.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        }
    };
    private Update = () => {
        self_serial = self_serial + 1;
        this.ovale.needRefresh();
    };

    InitializeState() {
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
    ResetState() {}
    CleanState() {
        for (const [slot, totem] of pairs(this.next.totems)) {
            for (const [k] of kpairs(totem)) {
                delete totem[k];
            }
            delete this.next.totems[slot];
        }
    }

    ApplySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvaleTotem_ApplySpellAfterCast");
        if (TOTEM_CLASS[this.ovale.playerClass]) {
            this.debug.Log(
                "OvaleTotem_ApplySpellAfterCast: spellId %s, endCast %s",
                spellId,
                endCast
            );
            const si = this.ovaleData.spellInfo[spellId];
            if (si && si.totem) {
                this.SummonTotem(spellId, endCast);
            }
        }
        this.profiler.StopProfiling("OvaleTotem_ApplySpellAfterCast");
    };

    IsActiveTotem(totem: Totem, atTime: number) {
        if (!totem) return false;
        if (!totem.serial || totem.serial < self_serial) {
            totem = this.GetTotem(totem.slot);
        }
        return (
            totem &&
            totem.serial == self_serial &&
            totem.start &&
            totem.duration &&
            totem.start < atTime &&
            atTime < totem.start + totem.duration
        );
    }

    GetTotem(slot: number) {
        this.profiler.StartProfiling("OvaleTotem_state_GetTotem");
        const totem = this.next.totems[slot];
        if (totem && (!totem.serial || totem.serial < self_serial)) {
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
            totem.serial = self_serial;
        }
        this.profiler.StopProfiling("OvaleTotem_state_GetTotem");
        return totem;
    }

    GetTotemInfo(spellId: number, atTime: number) {
        let start, ending;
        let count = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.totem) {
            this.debug.Log("Spell %s is a totem spell", spellId);
            // it can take a while for the buffs to appear
            // so if the previous GCD spell is our totem, we assume the buffs are up
            let buffPresent = this.ovaleFuture.next.lastGCDSpellId == spellId;
            if (!buffPresent && si.buff_totem) {
                const aura = this.ovaleAura.GetAura(
                    "player",
                    si.buff_totem,
                    atTime,
                    "HELPFUL"
                );
                buffPresent =
                    (aura && this.ovaleAura.IsActiveAura(aura, atTime)) ||
                    false;
            }
            if (!si.buff_totem || buffPresent) {
                const texture = this.ovaleSpellBook.GetSpellTexture(spellId);
                const maxTotems = si.max_totems || MAX_TOTEMS + 1;
                for (const [slot] of ipairs(this.next.totems)) {
                    const totem = this.GetTotem(slot);
                    if (
                        this.IsActiveTotem(totem, atTime) &&
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
            this.debug.Log("Spell %s is NOT a totem spell", spellId);
        }
        return [count, start, ending];
    }

    SummonTotem(spellId: number, atTime: number) {
        this.profiler.StartProfiling("OvaleTotem_state_SummonTotem");

        const totemSlot = this.GetAvailableTotemSlot(spellId, atTime);
        if (totemSlot) {
            const [name, , icon] = this.ovaleSpellBook.GetSpellInfo(spellId);
            const duration = this.ovaleData.GetSpellInfoProperty(
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
        }
        this.profiler.StopProfiling("OvaleTotem_state_SummonTotem");
    }

    GetAvailableTotemSlot(spellId: number, atTime: number): number | undefined {
        this.profiler.StartProfiling(
            "OvaleTotem_state_GetNextAvailableTotemSlot"
        );
        let availableSlot = undefined;

        const si = this.ovaleData.spellInfo[spellId];
        if (si && si.totem) {
            const [, , icon] = this.ovaleSpellBook.GetSpellInfo(spellId);

            for (let i = 1; i <= MAX_TOTEMS + 1; i += 1) {
                const totem = this.next.totems[i];
                if (
                    availableSlot == undefined &&
                    (!this.IsActiveTotem(totem, atTime) ||
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
        this.profiler.StopProfiling(
            "OvaleTotem_state_GetNextAvailableTotemSlot"
        );
        return availableSlot;
    }
}
