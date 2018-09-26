import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvalePower } from "./Power";
import { OvaleState } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, LuaArray, wipe } from "@wowts/lua";
import { GetRuneCooldown, GetTime } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { sort } from "@wowts/table";
import { SpellCast, PaperDollSnapshot } from "./LastSpell";
import { OvalePaperDoll } from "./PaperDoll";

export let OvaleRunes: OvaleRunesClass;
let EMPOWER_RUNE_WEAPON = 47568;
let RUNE_SLOTS = 6;

interface Rune {
    startCooldown?: number;
    endCooldown?: number;
}

const IsActiveRune = function(rune: Rune, atTime: number) {
    return (rune.startCooldown == 0 || rune.endCooldown <= atTime);
}

class RuneData {
    rune:LuaArray<Rune> = {}
    runicpower:number = undefined;
}

let usedRune: LuaArray<number> = {}

let OvaleRunesBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleRunes", aceEvent))), RuneData);

class OvaleRunesClass extends OvaleRunesBase {
    
    OnInitialize() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                this.current.rune[slot] = {}
            }
            this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes");
            this.RegisterEvent("RUNE_POWER_UPDATE");
            this.RegisterEvent("UNIT_RANGEDDAMAGE");
            this.RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE");
            if (Ovale.playerGUID) this.UpdateAllRunes();
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEATHKNIGHT") {
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("RUNE_POWER_UPDATE");
            this.UnregisterEvent("UNIT_RANGEDDAMAGE");
            this.UnregisterEvent("UNIT_SPELL_HASTE");
            this.current.rune = {}
        }
    }
    RUNE_POWER_UPDATE(event: string, slot: number, usable: boolean) {
        this.Debug(event, slot, usable);
        this.UpdateRune(slot);
    }
    RUNE_TYPE_UPDATE(event: string, slot: number) {
        this.Debug(event, slot);
        this.UpdateRune(slot);
    }
    UNIT_RANGEDDAMAGE(event: string, unitId: string) {
        if (unitId == "player") {
            this.Debug(event);
            this.UpdateAllRunes();
        }
    }
    UpdateRune(slot: number) {
        this.StartProfiling("OvaleRunes_UpdateRune");
        let rune = this.current.rune[slot];
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
            let rune = this.current.rune[slot];
            if (IsActiveRune(rune, now)) {
                this.Print("rune[%d] is active.", slot);
            } else {
                this.Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now);
            }
        }
    }
    
    InitializeState() {
        this.next.rune = {}
        for (const [slot] of ipairs(this.current.rune)) {
            this.next.rune[slot] = {}
        }
    }
    ResetState() {
        OvaleRunes.StartProfiling("OvaleRunes_ResetState");
        for (const [slot, rune] of ipairs(this.current.rune)) {
            let stateRune = this.next.rune[slot];
            stateRune.endCooldown = rune.endCooldown;
            stateRune.startCooldown = rune.startCooldown;
        }
        OvaleRunes.StopProfiling("OvaleRunes_ResetState");
    }
    CleanState() {
        for (const [slot, rune] of ipairs(this.next.rune)) {
            wipe(rune);
            this.next.rune[slot] = undefined;
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleRunes.StartProfiling("OvaleRunes_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyRuneCost(spellId, startCast, spellcast);
        }
        OvaleRunes.StopProfiling("OvaleRunes_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvaleRunes.StartProfiling("OvaleRunes_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyRuneCost(spellId, endCast, spellcast);
            if (spellId == EMPOWER_RUNE_WEAPON) {
                for (const [slot] of ipairs(this.next.rune)) {
                    this.ReactivateRune(slot, endCast);
                }
            }
        }
        OvaleRunes.StopProfiling("OvaleRunes_ApplySpellAfterCast");
    }

    ApplyRuneCost(spellId: number, atTime: number, spellcast: SpellCast) {
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            let count = si.runes || 0;
            while (count > 0) {
                this.ConsumeRune(spellId, atTime, spellcast);
                count = count - 1;
            }
        }
    }
    ReactivateRune(slot: number, atTime: number) {
        let rune = this.next.rune[slot];
        if (rune.startCooldown > atTime) {
            rune.startCooldown = atTime;
        }
        rune.endCooldown = atTime;
    }
    ConsumeRune(spellId: number, atTime: number, snapshot: PaperDollSnapshot) {
        OvaleRunes.StartProfiling("OvaleRunes_state_ConsumeRune");
        let consumedRune: Rune;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = this.next.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                consumedRune = rune;
                break;
            }
        }
        if (consumedRune) {
            let start = atTime;
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                let rune = this.next.rune[slot];
                if (rune.endCooldown > start) {
                    start = rune.endCooldown;
                }
            }
            let duration = 10 / OvalePaperDoll.GetSpellCastSpeedPercentMultiplier(snapshot);
            consumedRune.startCooldown = start;
            consumedRune.endCooldown = start + duration;
            let runicpower = this.next.runicpower;
            runicpower = runicpower + 10;
            let maxi = OvalePower.current.maxPower.runicpower;
            this.next.runicpower = (runicpower < maxi) && runicpower || maxi;
        } 
        
        this.StopProfiling("OvaleRunes_state_ConsumeRune");
    }
    RuneCount(atTime?: number) {
        this.StartProfiling("OvaleRunes_state_RuneCount");
        const state = this.GetState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = state.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                count = count + 1;
            } else if (rune.endCooldown < endCooldown) {
                [startCooldown, endCooldown] = [rune.startCooldown, rune.endCooldown];
            }
        }
        this.StopProfiling("OvaleRunes_state_RuneCount");
        return [count, startCooldown, endCooldown];
    }

    RuneDeficit(atTime?: number) {
        this.StartProfiling("OvaleRunes_state_RuneDeficit");
        const state = this.GetState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = state.rune[slot];
            if (!IsActiveRune(rune, atTime)) {
                count = count + 1;
                if (rune.endCooldown < endCooldown) {
                   [startCooldown, endCooldown] = [rune.startCooldown, rune.endCooldown];
                }
            }
        }
        this.StopProfiling("OvaleRunes_state_RuneDeficit");
        return [count, startCooldown, endCooldown];
    }

    GetRunesCooldown(atTime: number, runes: number) {
        if (runes <= 0) {
            return 0;
        }
        if (runes > RUNE_SLOTS) {
            OvaleRunes.Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS);
            return 0;
        }
        const state = this.GetState(atTime);
        OvaleRunes.StartProfiling("OvaleRunes_state_GetRunesCooldown");
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            let rune = state.rune[slot];
            usedRune[slot] = rune.endCooldown - atTime;
        }
        sort(usedRune);
        this.StopProfiling("OvaleRunes_state_GetRunesCooldown");
        return usedRune[runes];
    }
}

OvaleRunes = new OvaleRunesClass();
OvaleState.RegisterState(OvaleRunes);
