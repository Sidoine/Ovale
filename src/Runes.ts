import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvalePower } from "./Power";
import { OvaleState, baseState, StateModule } from "./State";
import { paperDollState } from "./PaperDoll";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, LuaArray } from "@wowts/lua";
import { GetRuneCooldown, GetTime } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { sort } from "@wowts/table";
import { SpellCast, PaperDollSnapshot } from "./LastSpell";

let OvaleRunesBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleRunes", aceEvent)));
export let OvaleRunes: OvaleRunesClass;
let EMPOWER_RUNE_WEAPON = 47568;
let RUNE_SLOTS = 6;

interface Rune {
    startCooldown?: number;
    endCooldown?: number;
}

const IsActiveRune = function(rune: Rune, atTime) {
    return (rune.startCooldown == 0 || rune.endCooldown <= atTime);
}
class OvaleRunesClass extends OvaleRunesBase {
    rune:LuaArray<Rune> = {}
    
    OnInitialize() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                this.rune[slot] = {}
            }
            this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes");
            this.RegisterEvent("RUNE_POWER_UPDATE");
            this.RegisterEvent("RUNE_TYPE_UPDATE");
            this.RegisterEvent("UNIT_RANGEDDAMAGE");
            this.RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE");
            if (Ovale.playerGUID) this.UpdateAllRunes();
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("RUNE_POWER_UPDATE");
            this.UnregisterEvent("RUNE_TYPE_UPDATE");
            this.UnregisterEvent("UNIT_RANGEDDAMAGE");
            this.UnregisterEvent("UNIT_SPELL_HASTE");
            this.rune = {}
        }
    }
    RUNE_POWER_UPDATE(event, slot, usable) {
        this.Debug(event, slot, usable);
        this.UpdateRune(slot);
    }
    RUNE_TYPE_UPDATE(event, slot) {
        this.Debug(event, slot);
        this.UpdateRune(slot);
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.Debug(event);
            this.UpdateAllRunes();
        }
    }
    UpdateRune(slot) {
        this.StartProfiling("OvaleRunes_UpdateRune");
        let rune = this.rune[slot];
        let [start, duration] = GetRuneCooldown(slot);
        if (start && duration) {
            if (start > 0) {
                rune.startCooldown = start;
                rune.endCooldown = start + duration;
            } else {
                rune.startCooldown = 0;
                rune.endCooldown = 0;
            }
            Ovale.needRefresh();
        } else {
            this.Debug("Warning: rune information for slot %d not available.", slot);
        }
        this.StopProfiling("OvaleRunes_UpdateRune");
    }
    UpdateAllRunes() {
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            this.UpdateRune(slot);
        }
    }
    DebugRunes() {
        let now = GetTime();
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.rune[slot];
            if (IsActiveRune(rune, now)) {
                this.Print("rune[%d] is active.", slot);
            } else {
                this.Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now);
            }
        }
    }
}

let usedRune = {
}

class RunesState implements StateModule {
    rune: LuaArray<Rune> = undefined;
    runicpower:number = undefined;

    InitializeState() {
        this.rune = {}
        for (const [slot] of ipairs(OvaleRunes.rune)) {
            this.rune[slot] = {}
        }
    }
    ResetState() {
        OvaleRunes.StartProfiling("OvaleRunes_ResetState");
        for (const [slot, rune] of ipairs(OvaleRunes.rune)) {
            let stateRune = this.rune[slot];
            for (const [k, v] of pairs(rune)) {
                stateRune[k] = v;
            }
        }
        OvaleRunes.StopProfiling("OvaleRunes_ResetState");
    }
    CleanState() {
        for (const [slot, rune] of ipairs(this.rune)) {
            for (const [k] of pairs(rune)) {
                rune[k] = undefined;
            }
            this.rune[slot] = undefined;
        }
    }
    ApplySpellStartCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast) {
        OvaleRunes.StartProfiling("OvaleRunes_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyRuneCost(spellId, startCast, spellcast);
        }
        OvaleRunes.StopProfiling("OvaleRunes_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast) {
        OvaleRunes.StartProfiling("OvaleRunes_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyRuneCost(spellId, endCast, spellcast);
            if (spellId == EMPOWER_RUNE_WEAPON) {
                for (const [slot] of ipairs(this.rune)) {
                    this.ReactivateRune(slot, endCast);
                }
            }
        }
        OvaleRunes.StopProfiling("OvaleRunes_ApplySpellAfterCast");
    }

    DebugRunes() {
        OvaleRunes.Print("Current rune state:");
        let now = baseState.currentTime;
        for (const [slot, rune] of ipairs(this.rune)) {
            if (IsActiveRune(rune, now)) {
                OvaleRunes.Print("    rune[%d] is active.", slot);
            } else {
                OvaleRunes.Print("    rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now);
            }
        }
    }
    ApplyRuneCost(spellId, atTime, spellcast: SpellCast) {
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            let count = si.runes || 0;
            while (count > 0) {
                this.ConsumeRune(spellId, atTime, spellcast);
                count = count - 1;
            }
        }
    }
    ReactivateRune(slot, atTime) {
        let rune = this.rune[slot];
        if (atTime < baseState.currentTime) {
            atTime = baseState.currentTime;
        }
        if (rune.startCooldown > atTime) {
            rune.startCooldown = atTime;
        }
        rune.endCooldown = atTime;
    }
    ConsumeRune(spellId: number, atTime: number, snapshot: PaperDollSnapshot) {
        OvaleRunes.StartProfiling("OvaleRunes_state_ConsumeRune");
        let consumedRune: Rune;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                consumedRune = rune;
                break;
            }
        }
        if (consumedRune) {
            let start = atTime;
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                let rune = this.rune[slot];
                if (rune.endCooldown > start) {
                    start = rune.endCooldown;
                }
            }
            let duration = 10 / paperDollState.GetSpellHasteMultiplier(snapshot);
            consumedRune.startCooldown = start;
            consumedRune.endCooldown = start + duration;
            let runicpower = this.runicpower;
            runicpower = runicpower + 10;
            let maxi = OvalePower.maxPower.runicpower;
            this.runicpower = (runicpower < maxi) && runicpower || maxi;
        } 
        
        OvaleRunes.StopProfiling("OvaleRunes_state_ConsumeRune");
    }
    RuneCount(atTime) {
        OvaleRunes.StartProfiling("OvaleRunes_state_RuneCount");
        atTime = atTime || baseState.currentTime;
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                count = count + 1;
            } else if (rune.endCooldown < endCooldown) {
                [startCooldown, endCooldown] = [rune.startCooldown, rune.endCooldown];
            }
        }
        OvaleRunes.StopProfiling("OvaleRunes_state_RuneCount");
        return [count, startCooldown, endCooldown];
    }
    GetRunesCooldown(atTime, runes) {
        if (runes <= 0) {
            return 0;
        }
        if (runes > RUNE_SLOTS) {
            OvaleRunes.Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS);
            return 0;
        }
        OvaleRunes.StartProfiling("OvaleRunes_state_GetRunesCooldown");
        atTime = atTime || baseState.currentTime;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.rune[slot];
            usedRune[slot] = rune.endCooldown - atTime;
        }
        sort(usedRune);
        OvaleRunes.StopProfiling("OvaleRunes_state_GetRunesCooldown");
        return usedRune[runes];
    }
}

export const runesState = new RunesState();
OvaleState.RegisterState(runesState);

OvaleRunes = new OvaleRunesClass();