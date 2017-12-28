import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleAura } from "./Aura";
import { OvaleData } from "./Data";
import { OvaleEquipment } from "./Equipment";
import { OvalePaperDoll } from "./PaperDoll";
import { OvalePower } from "./Power";
import { OvaleSpellBook } from "./SpellBook";
import { Ovale } from "./Ovale";
import { OvaleState } from "./State";
import { RegisterRequirement, UnregisterRequirement } from "./Requirement";
import { lastSpell, SpellCast } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { insert, remove } from "@wowts/table";
import { GetTime, UnitPower, MAX_COMBO_POINTS, UNKNOWN } from "@wowts/wow-mock";
import { lualength, LuaArray } from "@wowts/lua";

export let OvaleComboPoints: OvaleComboPointsClass;
let ANTICIPATION = 115189;
let ANTICIPATION_DURATION = 15;
let ANTICIPATION_TALENT = 18;
let self_hasAnticipation = false;
let RUTHLESSNESS = 14161;
let self_hasRuthlessness = false;
let ENVENOM = 32645;
let self_hasAssassination4pT17 = false;

type Combo = number | "finisher";

interface ComboEvent {
    atTime: number;
    spellId: number;
    guid: string;
    reason: string;
    combo: Combo;
}

let self_pendingComboEvents: LuaArray<ComboEvent> = {}
let PENDING_THRESHOLD = 0.8;

function AddPendingComboEvent(atTime: number, spellId: number, guid: string, reason: string, combo: Combo) {
    let comboEvent = {
        atTime: atTime,
        spellId: spellId,
        guid: guid,
        reason: reason,
        combo: combo
    }
    insert(self_pendingComboEvents, comboEvent);
    Ovale.needRefresh();
}
function RemovePendingComboEvents(atTime: number, spellId?: number, guid?: string, reason?: string, combo?: Combo) {
    let count = 0;
    for (let k = lualength(self_pendingComboEvents); k >= 1; k += -1) {
        let comboEvent = self_pendingComboEvents[k];
        if ((atTime && atTime - comboEvent.atTime > PENDING_THRESHOLD) || (comboEvent.spellId == spellId && comboEvent.guid == guid && (!reason || comboEvent.reason == reason) && (!combo || comboEvent.combo == combo))) {
            if (comboEvent.combo == "finisher") {
                OvaleComboPoints.Debug("Removing expired %s event: spell %d combo point finisher from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.reason);
            } else {
                OvaleComboPoints.Debug("Removing expired %s event: spell %d for %d combo points from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.combo, comboEvent.reason);
            }
            count = count + 1;
            remove(self_pendingComboEvents, k);
            Ovale.needRefresh();
        }
    }
    return count;
}

class ComboPointsData {
    combo = 0;
}

let OvaleComboPointsBase = OvaleState.RegisterHasState(OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleComboPoints", aceEvent))), ComboPointsData);

class OvaleComboPointsClass extends OvaleComboPointsBase {
    
    OnInitialize() {
        if (Ovale.playerClass == "ROGUE" || Ovale.playerClass == "DRUID") {
            this.RegisterEvent("PLAYER_ENTERING_WORLD", this.Update);
            this.RegisterEvent("PLAYER_TARGET_CHANGED");
            this.RegisterEvent("UNIT_POWER");
            this.RegisterEvent("Ovale_EquipmentChanged");
            this.RegisterMessage("Ovale_SpellFinished");
            this.RegisterMessage("Ovale_TalentsChanged");
            RegisterRequirement("combo", this.RequireComboPointsHandler);
            lastSpell.RegisterSpellcastInfo(this);
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "ROGUE" || Ovale.playerClass == "DRUID") {
            lastSpell.UnregisterSpellcastInfo(this);
            UnregisterRequirement("combo");
            this.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.UnregisterEvent("PLAYER_TARGET_CHANGED");
            this.UnregisterEvent("UNIT_POWER");
            this.UnregisterEvent("Ovale_EquipmentChanged");
            this.UnregisterMessage("Ovale_SpellFinished");
            this.UnregisterMessage("Ovale_TalentsChanged");
        }
    }
    PLAYER_TARGET_CHANGED(event: string, cause: string) {
        if (cause == "NIL" || cause == "down") {
        } else {
            this.Update();
        }
    }
    UNIT_POWER(event: string, unitId: string, powerToken: string) {
        if (powerToken != OvalePower.POWER_INFO.combopoints.token) {
            return;
        }
        if (unitId == "player") {
            let oldCombo = this.current.combo;
            this.Update();
            let difference = this.current.combo - oldCombo;
            this.DebugTimestamp("%s: %d -> %d.", event, oldCombo, this.current.combo);
            let now = GetTime();
            RemovePendingComboEvents(now);
            if (lualength(self_pendingComboEvents) > 0) {
                let comboEvent = self_pendingComboEvents[1];
                let [spellId, , reason, combo] = [comboEvent.spellId, comboEvent.guid, comboEvent.reason, comboEvent.combo];
                if (combo == difference || (combo == "finisher" && this.current.combo == 0 && difference < 0)) {
                    this.Debug("    Matches pending %s event for %d.", reason, spellId);
                    remove(self_pendingComboEvents, 1);
                }
            }
        }
    }
    Ovale_EquipmentChanged(event: string) {
        self_hasAssassination4pT17 = (Ovale.playerClass == "ROGUE" && OvalePaperDoll.IsSpecialization("assassination") && OvaleEquipment.GetArmorSetCount("T17") >= 4);
    }
    Ovale_SpellFinished(event: string, atTime: number, spellId: number, targetGUID: string, finish: string) {
        this.Debug("%s (%f): Spell %d finished (%s) on %s", event, atTime, spellId, finish, targetGUID || UNKNOWN);
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo == "finisher" && finish == "hit") {
            this.Debug("    Spell %d hit and consumed all combo points.", spellId);
            AddPendingComboEvent(atTime, spellId, targetGUID, "finisher", "finisher");
            if (self_hasRuthlessness && this.current.combo == MAX_COMBO_POINTS) {
                this.Debug("    Spell %d has 100% chance to grant an extra combo point from Ruthlessness.", spellId);
                AddPendingComboEvent(atTime, spellId, targetGUID, "Ruthlessness", 1);
            }
            if (self_hasAssassination4pT17 && spellId == ENVENOM) {
                this.Debug("    Spell %d refunds 1 combo point from Assassination 4pT17 set bonus.", spellId);
                AddPendingComboEvent(atTime, spellId, targetGUID, "Assassination 4pT17", 1);
            }
            if (self_hasAnticipation && targetGUID != Ovale.playerGUID) {
                if (OvaleSpellBook.IsHarmfulSpell(spellId)) {
                    let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, atTime);
                    if (OvaleAura.IsActiveAura(aura, atTime)) {
                        this.Debug("    Spell %d hit with %d Anticipation charges.", spellId, aura.stacks);
                        AddPendingComboEvent(atTime, spellId, targetGUID, "Anticipation", aura.stacks);
                    }
                }
            }
        }
    }
    Ovale_TalentsChanged(event: string) {
        if (Ovale.playerClass == "ROGUE") {
            self_hasAnticipation = OvaleSpellBook.GetTalentPoints(ANTICIPATION_TALENT) > 0;
            self_hasRuthlessness = OvaleSpellBook.IsKnownSpell(RUTHLESSNESS);
        }
    }
    Update = () => {
        this.StartProfiling("OvaleComboPoints_Update");
        this.current.combo = UnitPower("player", 4);
        Ovale.needRefresh();
        this.StopProfiling("OvaleComboPoints_Update");
    }
    GetComboPoints(atTime: number|undefined) {
        if (atTime == undefined) {
            let now = GetTime();
            RemovePendingComboEvents(now);
            let total = this.current.combo;
            for (let k = 1; k <= lualength(self_pendingComboEvents); k += 1) {
                let combo = self_pendingComboEvents[k].combo;
                if (combo == "finisher") {
                    total = 0;
                } else {
                    total = total + combo;
                }
                if (total > MAX_COMBO_POINTS) {
                    total = MAX_COMBO_POINTS;
                }
            }
            return total;
        }
        return this.next.combo;        
    }
    DebugComboPoints() {
        this.Print("Player has %d combo points.", this.current.combo);
    }
    ComboPointCost(spellId: number, atTime: number, targetGUID: string):[number, number] {
        this.StartProfiling("OvaleComboPoints_ComboPointCost");
        let spellCost = 0;
        let spellRefund = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo) {
            let cost = OvaleData.GetSpellInfoProperty(spellId, atTime, "combo", targetGUID);
            if (cost == "finisher") {
                cost = this.GetComboPoints(atTime);
                let minCost = si.min_combo || si.mincombo || 1;
                let maxCost = si.max_combo;
                if (cost < minCost) {
                    cost = minCost;
                }
                if (maxCost && cost > maxCost) {
                    cost = maxCost;
                }
            } else {
                let buffExtra = si.buff_combo;
                if (buffExtra) {
                    let aura = OvaleAura.GetAura("player", buffExtra, atTime, undefined, true);
                    let isActiveAura = OvaleAura.IsActiveAura(aura, atTime);
                    if (isActiveAura) {
                        let buffAmount = si.buff_combo_amount || 1;
                        cost = <number>cost + buffAmount;
                    }
                }
                cost = -1 * <number>cost;
            }
            spellCost = cost;
            let refund = OvaleData.GetSpellInfoProperty(spellId, atTime, "refund_combo", targetGUID);
            if (refund == "cost") {
                refund = spellCost;
            }
            spellRefund = <number>refund || 0;
        }
        this.StopProfiling("OvaleComboPoints_ComboPointCost");
        return [spellCost, spellRefund];
    }
    RequireComboPointsHandler = (spellId: number, atTime: number, requirement: string, tokens: LuaArray<string>, index: number, targetGUID: string):[boolean, string, number] => {
        let verified = false;
        let cost = tokens;
        if (index) {
            cost = tokens[index];
            index = index + 1;
        }
        if (cost) {
            let [costValue] = this.ComboPointCost(spellId, atTime, targetGUID);
            if (costValue > 0) {
                let power = this.GetComboPoints(atTime);
                if (power >= costValue) {
                    verified = true;
                }
            } else {
                verified = true;
            }
            if (costValue > 0) {
                let result = verified && "passed" || "FAILED";
                this.Log("    Require %d combo point(s) at time=%f: %s", costValue, atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement);
        }
        return [verified, requirement, index];
    }
    CopySpellcastInfo = (mod: this, spellcast: SpellCast, dest) => {
        if (spellcast.combo) {
            dest.combo = spellcast.combo;
        }
    }
    SaveSpellcastInfo = (module: this, spellcast: SpellCast, atTime, state:{}) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let si = OvaleData.spellInfo[spellId];
            if (si) {
                if (si.combo == "finisher") {
                    let combo;
                    combo =  OvaleData.GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target);
                    if (combo == "finisher") {
                        let min_combo = si.min_combo || si.mincombo || 1;
                        if (this.current.combo >= min_combo) {
                            combo = this.current.combo;
                        } else {
                            combo = min_combo;
                        }
                    } else if (combo == 0) {
                        combo = MAX_COMBO_POINTS;
                    }
                    spellcast.combo = combo;
                }
            }
        }
    }    
    
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast) {
        OvaleComboPoints.StartProfiling("OvaleComboPoints_ApplySpellAfterCast");
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo) {
            let [cost, refund] = this.ComboPointCost(spellId, endCast, targetGUID);
            let power = this.next.combo;
            power = power - cost + refund;
            if (power <= 0) {
                power = 0;
                if (self_hasRuthlessness && this.next.combo == MAX_COMBO_POINTS) {
                    OvaleComboPoints.Log("Spell %d grants one extra combo point from Ruthlessness.", spellId);
                    power = power + 1;
                }
                if (self_hasAnticipation && this.next.combo > 0) {
                    let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast);
                    if (OvaleAura.IsActiveAura(aura, endCast)) {
                        power = power + aura.stacks;
                        OvaleAura.RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast);
                        if (power > MAX_COMBO_POINTS) {
                            power = MAX_COMBO_POINTS;
                        }
                    }
                }
            }
            if (power > MAX_COMBO_POINTS) {
                if (self_hasAnticipation && !si.temp_combo) {
                    let stacks = power - MAX_COMBO_POINTS;
                    let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast);
                    if (OvaleAura.IsActiveAura(aura, endCast)) {
                        stacks = stacks + aura.stacks;
                        if (stacks > MAX_COMBO_POINTS) {
                            stacks = MAX_COMBO_POINTS;
                        }
                    }
                    let start = endCast;
                    let ending = start + ANTICIPATION_DURATION;
                    aura = OvaleAura.AddAuraToGUID(Ovale.playerGUID, ANTICIPATION, Ovale.playerGUID, "HELPFUL", undefined, start, ending, start);
                    aura.stacks = stacks;
                }
                power = MAX_COMBO_POINTS;
            }
            this.next.combo = power;
        }
        OvaleComboPoints.StopProfiling("OvaleComboPoints_ApplySpellAfterCast");
    }
    
    InitializeState() {
        this.next.combo = 0;
    }
    ResetState() {
        this.next.combo = this.GetComboPoints(undefined);
        for (let k = 1; k <= lualength(self_pendingComboEvents); k += 1) {
            let comboEvent = self_pendingComboEvents[k];
            if (comboEvent.reason == "Anticipation") {
                OvaleAura.RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, comboEvent.atTime);
                break;
            }
        }
    }

    CleanState(): void {
    }

}
OvaleComboPoints = new OvaleComboPointsClass();

OvaleState.RegisterState(OvaleComboPoints);