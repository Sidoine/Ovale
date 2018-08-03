import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvaleSpellBook }from "./SpellBook";
import { OvaleState } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, LuaObj, LuaArray } from "@wowts/lua";
import { GetTotemInfo, AIR_TOTEM_SLOT, EARTH_TOTEM_SLOT, FIRE_TOTEM_SLOT, MAX_TOTEMS, WATER_TOTEM_SLOT } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { SpellCast } from "./LastSpell";
import { OvaleAura } from "./Aura";

export let OvaleTotem: OvaleTotemClass;


const INFINITY = huge;

let self_serial = 0;
let TOTEM_CLASS: LuaObj<boolean> = {
    DRUID: true,
    MAGE: true,
    MONK: true,
    SHAMAN: true
}
let TOTEM_SLOT: LuaObj<number> = {
    air: AIR_TOTEM_SLOT,
    earth: EARTH_TOTEM_SLOT,
    fire: FIRE_TOTEM_SLOT,
    water: WATER_TOTEM_SLOT,
    spirit_wolf: 1
}
let TOTEMIC_RECALL = 36936;

interface Totem {
    duration?: number;
    start?: number;
    serial?: number;
    name?: string;
    icon?: string;
}

class TotemData {
    totem: LuaArray<Totem> = {}
}

let OvaleTotemBase = OvaleState.RegisterHasState(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleTotem", aceEvent)), TotemData);

class OvaleTotemClass extends OvaleTotemBase {
    
    OnInitialize() {
        if (TOTEM_CLASS[Ovale.playerClass]) {
            this.RegisterEvent("PLAYER_ENTERING_WORLD", "Update");
            this.RegisterEvent("PLAYER_TALENT_UPDATE", "Update");
            this.RegisterEvent("PLAYER_TOTEM_UPDATE", "Update");
            this.RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update");
        }
    }
    OnDisable() {
        if (TOTEM_CLASS[Ovale.playerClass]) {
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("PLAYER_TALENT_UPDATE");
            this.UnregisterEvent("PLAYER_TOTEM_UPDATE");
            this.UnregisterEvent("UPDATE_SHAPESHIFT_FORM");
        }
    }
    Update() {
        self_serial = self_serial + 1;
        Ovale.needRefresh();
    }

    InitializeState() {
        this.next.totem = {}
        for (let slot = 1; slot <= MAX_TOTEMS; slot += 1) {
            this.next.totem[slot] = {}
        }
    }
    ResetState(){        
    }
    CleanState() {
        for (const [slot, totem] of pairs(this.next.totem)) {
            for (const [k] of pairs(totem)) {
                totem[k] = undefined;
            }
            this.next.totem[slot] = undefined;
        }
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast ) {
        OvaleTotem.StartProfiling("OvaleTotem_ApplySpellAfterCast");
        if (Ovale.playerClass == "SHAMAN" && spellId == TOTEMIC_RECALL) {
            for (const [slot] of ipairs(this.next.totem)) {
                this.DestroyTotem(slot, endCast);
            }
        } else {
            let atTime = endCast;
            let slot = this.GetTotemSlot(spellId, atTime);
            if (slot) {
                this.SummonTotem(spellId, slot, atTime);
            }
        }
        OvaleTotem.StopProfiling("OvaleTotem_ApplySpellAfterCast");
    }

    IsActiveTotem(totem, atTime?) {
        let boolean = false;
        if (totem && (totem.serial == self_serial) && totem.start && totem.duration && totem.start < atTime && atTime < totem.start + totem.duration) {
            boolean = true;
        }
        return boolean;
    }
    GetTotem(slot) {
        OvaleTotem.StartProfiling("OvaleTotem_state_GetTotem");
        slot = TOTEM_SLOT[slot] || slot;
        let totem = this.next.totem[slot];
        if (totem && (!totem.serial || totem.serial < self_serial)) {
            let [haveTotem, name, startTime, duration, icon] = GetTotemInfo(slot);
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
            totem.serial = self_serial;
        }
        OvaleTotem.StopProfiling("OvaleTotem_state_GetTotem");
        return totem;
    }
    GetTotemInfo(slot) {
        let haveTotem, name, startTime, duration, icon;
        slot = TOTEM_SLOT[slot] || slot;
        let totem = this.GetTotem(slot);
        if (totem) {
            haveTotem = this.IsActiveTotem(totem);
            name = totem.name;
            startTime = totem.start;
            duration = totem.duration;
            icon = totem.icon;
        }
        return [haveTotem, name, startTime, duration, icon];
    }
    GetTotemCount(spellId, atTime) {
        let start, ending;
        let count = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.totem) {
            let buffPresent = true;
            if (si.buff_totem) {
                let aura = OvaleAura.GetAura("player", si.buff_totem, atTime);
                buffPresent = OvaleAura.IsActiveAura(aura, atTime);
            }
            if (buffPresent) {
                let texture = OvaleSpellBook.GetSpellTexture(spellId);
                let maxTotems = si.max_totems || 1;
                for (const [slot] of ipairs(this.next.totem)) {
                    let totem = this.GetTotem(slot);
                    if (this.IsActiveTotem(totem, atTime) && totem.icon == texture) {
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
        }
        return [count, start, ending];
    }
    GetTotemSlot(spellId, atTime) {
        OvaleTotem.StartProfiling("OvaleTotem_state_GetTotemSlot");
        let totemSlot;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.totem) {
            totemSlot = TOTEM_SLOT[si.totem];
            if (!totemSlot) {
                let availableSlot;
                for (const [slot] of ipairs(this.next.totem)) {
                    let totem = this.GetTotem(slot);
                    if (!this.IsActiveTotem(totem, atTime)) {
                        availableSlot = slot;
                        break;
                    }
                }
                let texture = OvaleSpellBook.GetSpellTexture(spellId);
                let maxTotems = si.max_totems || 1;
                let count = 0;
                let start = INFINITY;
                for (const [slot] of ipairs(this.next.totem)) {
                    let totem = this.GetTotem(slot);
                    if (this.IsActiveTotem(totem, atTime) && totem.icon == texture) {
                        count = count + 1;
                        if (start > totem.start) {
                            start = totem.start;
                            totemSlot = slot;
                        }
                    }
                }
                if (count < maxTotems) {
                    totemSlot = availableSlot;
                }
            }
            totemSlot = totemSlot || 1;
        }
        OvaleTotem.StopProfiling("OvaleTotem_state_GetTotemSlot");
        return totemSlot;
    }
    SummonTotem(spellId, slot, atTime) {
        OvaleTotem.StartProfiling("OvaleTotem_state_SummonTotem");
        slot = TOTEM_SLOT[slot] || slot;
        let [name, , icon] = OvaleSpellBook.GetSpellInfo(spellId);
        let duration = OvaleData.GetSpellInfoProperty(spellId, atTime, "duration", undefined);
        let totem = this.next.totem[slot];
        totem.name = name;
        totem.start = atTime;
        totem.duration = duration || 15;
        totem.icon = icon;
        OvaleTotem.StopProfiling("OvaleTotem_state_SummonTotem");
    }
    DestroyTotem(slot, atTime) {
        OvaleTotem.StartProfiling("OvaleTotem_state_DestroyTotem");
        slot = TOTEM_SLOT[slot] || slot;
        let totem = this.next.totem[slot];
        let duration = atTime - totem.start;
        if (duration < 0) {
            duration = 0;
        }
        totem.duration = duration;
        OvaleTotem.StopProfiling("OvaleTotem_state_DestroyTotem");
    }
}

OvaleTotem = new OvaleTotemClass();
OvaleState.RegisterState(OvaleTotem);
