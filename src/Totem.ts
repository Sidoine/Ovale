import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvaleSpellBook }from "./SpellBook";
import { OvaleState } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, LuaObj, LuaArray, kpairs } from "@wowts/lua";
import { GetTotemInfo, MAX_TOTEMS } from "@wowts/wow-mock";
import { SpellCast } from "./LastSpell";
import { OvaleAura } from "./Aura";
import { OvaleFuture } from "./Future";

export let OvaleTotem: OvaleTotemClass;

let self_serial = 0;
let TOTEM_CLASS: LuaObj<boolean> = {
    DRUID: true,
    MAGE: true,
    MONK: true,
    SHAMAN: true
}

interface Totem {
    duration?: number;
    start?: number;
    serial?: number;
    name?: string;
    icon?: string;
    slot: number;
}

class TotemData {
    totems: LuaArray<Totem> = {}
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
        this.next.totems = {}
        // shamans can use the fifth slot when all of the totems are active
        // that's why we +1 it everywhere we use
        for (let slot = 1; slot <= MAX_TOTEMS+1; slot += 1) {
            this.next.totems[slot] = {slot: slot};
        }
    }
    ResetState(){        
    }
    CleanState() {
        for (const [slot, totem] of pairs(this.next.totems)) {
            for (const [k] of kpairs(totem)) {
                totem[k] = undefined;
            }
            this.next.totems[slot] = undefined;
        }
    }
    
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleTotem.StartProfiling("OvaleTotem_ApplySpellAfterCast");
        if (TOTEM_CLASS[Ovale.playerClass]) {
            let si = OvaleData.spellInfo[spellId];
            if (si && si.totem) {
                this.SummonTotem(spellId, endCast);
            }
        }
        OvaleTotem.StopProfiling("OvaleTotem_ApplySpellAfterCast");
    }

    IsActiveTotem(totem: Totem, atTime: number) {
        if (totem.serial < self_serial) {
            totem = this.GetTotem(totem.slot);
        }
        return (totem && (totem.serial == self_serial) && totem.start && totem.duration && totem.start < atTime && atTime < totem.start + totem.duration);
    }
    
    GetTotem(slot: number) {
        OvaleTotem.StartProfiling("OvaleTotem_state_GetTotem");
        let totem = this.next.totems[slot];
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
            totem.slot = slot;
            totem.serial = self_serial;
        }
        OvaleTotem.StopProfiling("OvaleTotem_state_GetTotem");
        return totem;
    }

    GetTotemInfo(spellId: number, atTime: number) {
        let start, ending;
        let count = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.totem) {
            // if can take a while for the buffs to appear
            // so if the previous GCD spell is our totem, we assume the buffs are up
            let buffPresent = (OvaleFuture.next.lastGCDSpellId == spellId);
            if (!buffPresent && si.buff_totem) {
                let aura = OvaleAura.GetAura("player", si.buff_totem, atTime, "HELPFUL");
                buffPresent = OvaleAura.IsActiveAura(aura, atTime);
            }
            if (!si.buff_totem || buffPresent) {
                let texture = OvaleSpellBook.GetSpellTexture(spellId);
                let maxTotems = si.max_totems || MAX_TOTEMS+1;
                for (const [slot] of ipairs(this.next.totems)) {
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
    
    SummonTotem(spellId: number, atTime: number) {
        OvaleTotem.StartProfiling("OvaleTotem_state_SummonTotem");
        
        let totemSlot = this.GetAvailableTotemSlot(spellId, atTime);
        
        let [name, , icon] = OvaleSpellBook.GetSpellInfo(spellId);
        let duration = OvaleData.GetSpellInfoProperty(spellId, atTime, "duration", undefined);
        let totem = this.next.totems[totemSlot];
        totem.name = name;
        totem.start = atTime;
        totem.duration = duration || 15;
        totem.icon = icon;
        totem.slot = totemSlot;
        OvaleTotem.StopProfiling("OvaleTotem_state_SummonTotem");
    }
    
    GetAvailableTotemSlot(spellId: number, atTime: number): number {
        OvaleTotem.StartProfiling("OvaleTotem_state_GetNextAvailableTotemSlot");
        let availableSlot = undefined;
        
        let si = OvaleData.spellInfo[spellId];
        if(si && si.totem) {
            let [, , icon] = OvaleSpellBook.GetSpellInfo(spellId);
            
            for(let i = 1; i <= MAX_TOTEMS+1; i+=1) {
                let totem = this.next.totems[i];
                if(availableSlot == undefined && (!this.IsActiveTotem(totem, atTime) || (si.max_totems == 1 && totem.icon == icon))) {
                    availableSlot = i;
                }
            }
            
            // all slots are occupied, take the one with the smallest duration left
            if (availableSlot == undefined) {
                availableSlot = 1;
                let firstTotem = this.next.totems[1];
                let smallestEndTime = firstTotem.start + firstTotem.duration
                for(let i = 2; i <= MAX_TOTEMS+1; i+=1) {
                    let totem = this.next.totems[i];
                    let endTime = totem.start + totem.duration
                    
                    if(endTime < smallestEndTime){
                        availableSlot = i;
                    }
                }
            }
        }
        OvaleTotem.StopProfiling("OvaleTotem_state_GetNextAvailableTotemSlot");
        return availableSlot;
    }
}

OvaleTotem = new OvaleTotemClass();
OvaleState.RegisterState(OvaleTotem);
