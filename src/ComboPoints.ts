import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { OvaleAura, auraState } from "./Aura";
import { OvaleData } from "./Data";
import { OvaleEquipment } from "./Equipment";
import { OvalePaperDoll } from "./PaperDoll";
import { OvalePower } from "./Power";
import { OvaleSpellBook } from "./SpellBook";
import { Ovale, RegisterPrinter } from "./Ovale";
import { OvaleState, StateModule } from "./State";
import { RegisterRequirement, UnregisterRequirement } from "./Requirement";
import { lastSpell } from "./LastSpell";
import { dataState } from "./DataState";
import aceEvent from "@wowts/ace_event-3.0";
import { insert, remove } from "@wowts/table";
import { GetTime, UnitPower, MAX_COMBO_POINTS, UNKNOWN } from "@wowts/wow-mock";
import { lualength } from "@wowts/lua";

let OvaleComboPointsBase = RegisterPrinter(OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleComboPoints", aceEvent))));
export let OvaleComboPoints: OvaleComboPointsClass;
let tinsert = insert;
let tremove = remove;
let API_GetTime = GetTime;
let API_UnitPower = UnitPower;
let _MAX_COMBO_POINTS = MAX_COMBO_POINTS;
let _UNKNOWN = UNKNOWN;
let ANTICIPATION = 115189;
let ANTICIPATION_DURATION = 15;
let ANTICIPATION_TALENT = 18;
let self_hasAnticipation = false;
let RUTHLESSNESS = 14161;
let self_hasRuthlessness = false;
let ENVENOM = 32645;
let self_hasAssassination4pT17 = false;
let self_pendingComboEvents = {
}
let PENDING_THRESHOLD = 0.8;

const AddPendingComboEvent = function(atTime, spellId, guid, reason, combo) {
    let comboEvent = {
        atTime: atTime,
        spellId: spellId,
        guid: guid,
        reason: reason,
        combo: combo
    }
    tinsert(self_pendingComboEvents, comboEvent);
    Ovale.needRefresh();
}
const RemovePendingComboEvents = function(atTime, spellId?, guid?, reason?, combo?) {
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
            tremove(self_pendingComboEvents, k);
            Ovale.needRefresh();
        }
    }
    return count;
}
class OvaleComboPointsClass extends OvaleComboPointsBase {
    combo = 0;

    constructor() {
        super();
        if (Ovale.playerClass == "ROGUE" || Ovale.playerClass == "DRUID") {
            this.RegisterEvent("PLAYER_ENTERING_WORLD", () => this.Update());
            this.RegisterEvent("PLAYER_TARGET_CHANGED");
            this.RegisterEvent("UNIT_POWER");
            this.RegisterEvent("Ovale_EquipmentChanged");
            this.RegisterMessage("Ovale_SpellFinished");
            this.RegisterMessage("Ovale_TalentsChanged");
            RegisterRequirement("combo", "RequireComboPointsHandler", this);
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
    PLAYER_TARGET_CHANGED(event, cause) {
        if (cause == "NIL" || cause == "down") {
        } else {
            this.Update();
        }
    }
    UNIT_POWER(event, unitId, powerToken) {
        if (powerToken != OvalePower.POWER_INFO.combopoints.token) {
            return;
        }
        if (unitId == "player") {
            let oldCombo = this.combo;
            this.Update();
            let difference = this.combo - oldCombo;
            this.DebugTimestamp("%s: %d -> %d.", event, oldCombo, this.combo);
            let now = API_GetTime();
            RemovePendingComboEvents(now);
            let pendingMatched = false;
            if (lualength(self_pendingComboEvents) > 0) {
                let comboEvent = self_pendingComboEvents[1];
                let [spellId, , reason, combo] = [comboEvent.spellId, comboEvent.guid, comboEvent.reason, comboEvent.combo];
                if (combo == difference || (combo == "finisher" && this.combo == 0 && difference < 0)) {
                    this.Debug("    Matches pending %s event for %d.", reason, spellId);
                    pendingMatched = true;
                    tremove(self_pendingComboEvents, 1);
                }
            }
        }
    }
    Ovale_EquipmentChanged(event) {
        self_hasAssassination4pT17 = (Ovale.playerClass == "ROGUE" && OvalePaperDoll.IsSpecialization("assassination") && OvaleEquipment.GetArmorSetCount("T17") >= 4);
    }
    Ovale_SpellFinished(event, atTime, spellId, targetGUID, finish) {
        this.Debug("%s (%f): Spell %d finished (%s) on %s", event, atTime, spellId, finish, targetGUID || _UNKNOWN);
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo == "finisher" && finish == "hit") {
            this.Debug("    Spell %d hit and consumed all combo points.", spellId);
            AddPendingComboEvent(atTime, spellId, targetGUID, "finisher", "finisher");
            if (self_hasRuthlessness && this.combo == _MAX_COMBO_POINTS) {
                this.Debug("    Spell %d has 100% chance to grant an extra combo point from Ruthlessness.", spellId);
                AddPendingComboEvent(atTime, spellId, targetGUID, "Ruthlessness", 1);
            }
            if (self_hasAssassination4pT17 && spellId == ENVENOM) {
                this.Debug("    Spell %d refunds 1 combo point from Assassination 4pT17 set bonus.", spellId);
                AddPendingComboEvent(atTime, spellId, targetGUID, "Assassination 4pT17", 1);
            }
            if (self_hasAnticipation && targetGUID != Ovale.playerGUID) {
                if (OvaleSpellBook.IsHarmfulSpell(spellId)) {
                    let aura = OvaleAura.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true);
                    if (OvaleAura.IsActiveAura(aura, atTime)) {
                        this.Debug("    Spell %d hit with %d Anticipation charges.", spellId, aura.stacks);
                        AddPendingComboEvent(atTime, spellId, targetGUID, "Anticipation", aura.stacks);
                    }
                }
            }
        }
    }
    Ovale_TalentsChanged(event) {
        if (Ovale.playerClass == "ROGUE") {
            self_hasAnticipation = OvaleSpellBook.GetTalentPoints(ANTICIPATION_TALENT) > 0;
            self_hasRuthlessness = OvaleSpellBook.IsKnownSpell(RUTHLESSNESS);
        }
    }
    Update() {
        this.StartProfiling("OvaleComboPoints_Update");
        this.combo = API_UnitPower("player", 4);
        Ovale.needRefresh();
        this.StopProfiling("OvaleComboPoints_Update");
    }
    GetComboPoints() {
        let now = API_GetTime();
        RemovePendingComboEvents(now);
        let total = this.combo;
        for (let k = 1; k <= lualength(self_pendingComboEvents); k += 1) {
            let combo = self_pendingComboEvents[k].combo;
            if (combo == "finisher") {
                total = 0;
            } else {
                total = total + combo;
            }
            if (total > _MAX_COMBO_POINTS) {
                total = _MAX_COMBO_POINTS;
            }
        }
        return total;
    }
    DebugComboPoints() {
        this.Print("Player has %d combo points.", this.combo);
    }
    ComboPointCost(spellId, atTime, targetGUID) {
        this.StartProfiling("OvaleComboPoints_ComboPointCost");
        let spellCost = 0;
        let spellRefund = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo) {
            let GetAura, IsActiveAura;
            let GetSpellInfoProperty;
            let auraModule, dataModule;
            [GetAura, auraModule] = this.GetMethod("GetAura", OvaleAura);
            [IsActiveAura, auraModule] = this.GetMethod("IsActiveAura", OvaleAura);
            [GetSpellInfoProperty, dataModule] = this.GetMethod("GetSpellInfoProperty", OvaleData);
            let cost = GetSpellInfoProperty(dataModule, spellId, atTime, "combo", targetGUID);
            if (cost == "finisher") {
                cost = this.GetComboPoints();
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
                    let aura = GetAura(auraModule, "player", buffExtra, undefined, true);
                    let isActiveAura = IsActiveAura(auraModule, aura, atTime);
                    if (isActiveAura) {
                        let buffAmount = si.buff_combo_amount || 1;
                        cost = cost + buffAmount;
                    }
                }
                cost = -1 * cost;
            }
            spellCost = cost;
            let refundParam = "refund_combo";
            let refund = GetSpellInfoProperty(dataModule, spellId, atTime, refundParam, targetGUID);
            if (refund == "cost") {
                refund = spellCost;
            }
            spellRefund = refund || 0;
        }
        this.StopProfiling("OvaleComboPoints_ComboPointCost");
        return [spellCost, spellRefund];
    }
    RequireComboPointsHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let cost = tokens;
        if (index) {
            cost = tokens[index];
            index = index + 1;
        }
        if (cost) {
            cost = this.ComboPointCost(spellId, atTime, targetGUID);
            if (cost > 0) {
                let power = this.GetComboPoints();
                if (power >= cost) {
                    verified = true;
                }
            } else {
                verified = true;
            }
            if (cost > 0) {
                let result = verified && "passed" || "FAILED";
                this.Log("    Require %d combo point(s) at time=%f: %s", cost, atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement);
        }
        return [verified, requirement, index];
    }
    CopySpellcastInfo(spellcast, dest) {
        if (spellcast.combo) {
            dest.combo = spellcast.combo;
        }
    }
    SaveSpellcastInfo = (module, spellcast, atTime, state:ComboPointsState) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let si = OvaleData.spellInfo[spellId];
            if (si) {
                let comboPointModule = state || this;
                if (si.combo == "finisher") {
                    let combo;
                    if (state) {
                        combo =  dataState.GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target);
                    }
                    else{
                        combo =  OvaleData.GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target);
                    }
                    if (combo == "finisher") {
                        let min_combo = si.min_combo || si.mincombo || 1;
                        if (comboPointModule.combo >= min_combo) {
                            combo = comboPointModule.combo;
                        } else {
                            combo = min_combo;
                        }
                    } else if (combo == 0) {
                        combo = _MAX_COMBO_POINTS;
                    }
                    spellcast.combo = combo;
                }
            }
        }
    }    
}

OvaleComboPoints = new OvaleComboPointsClass();

export class ComboPointsState implements StateModule {
    combo = undefined;
    
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        OvaleComboPoints.StartProfiling("OvaleComboPoints_ApplySpellAfterCast");
        let si = OvaleData.spellInfo[spellId];
        if (si && si.combo) {
            let [cost, refund] = this.ComboPointCost(spellId, endCast, targetGUID);
            let power = this.combo;
            power = power - cost + refund;
            if (power <= 0) {
                power = 0;
                if (self_hasRuthlessness && this.combo == _MAX_COMBO_POINTS) {
                    OvaleComboPoints.Log("Spell %d grants one extra combo point from Ruthlessness.", spellId);
                    power = power + 1;
                }
                if (self_hasAnticipation && this.combo > 0) {
                    let aura = auraState.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true);
                    if (auraState.IsActiveAura(aura, endCast)) {
                        power = power + aura.stacks;
                        auraState.RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast);
                        if (power > _MAX_COMBO_POINTS) {
                            power = _MAX_COMBO_POINTS;
                        }
                    }
                }
            }
            if (power > _MAX_COMBO_POINTS) {
                if (self_hasAnticipation && !si.temp_combo) {
                    let stacks = power - _MAX_COMBO_POINTS;
                    let aura = auraState.GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true);
                    if (auraState.IsActiveAura(aura, endCast)) {
                        stacks = stacks + aura.stacks;
                        if (stacks > _MAX_COMBO_POINTS) {
                            stacks = _MAX_COMBO_POINTS;
                        }
                    }
                    let start = endCast;
                    let ending = start + ANTICIPATION_DURATION;
                    aura = auraState.AddAuraToGUID(Ovale.playerGUID, ANTICIPATION, Ovale.playerGUID, "HELPFUL", undefined, start, ending);
                    aura.stacks = stacks;
                }
                power = _MAX_COMBO_POINTS;
            }
            this.combo = power;
        }
        OvaleComboPoints.StopProfiling("OvaleComboPoints_ApplySpellAfterCast");
    }
    
    GetComboPoints() {
        return this.combo;
    }
    ComboPointCost(spellId, atTime, targetGUID) {
        return OvaleComboPoints.ComboPointCost(spellId, atTime, targetGUID);
    } 

    RequireComboPointsHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvaleComboPoints.RequireComboPointsHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }    

    InitializeState() {
        this.combo = 0;
    }
    ResetState() {
        this.combo = this.GetComboPoints();
        for (let k = 1; k <= lualength(self_pendingComboEvents); k += 1) {
            let comboEvent = self_pendingComboEvents[k];
            if (comboEvent.reason == "Anticipation") {
                auraState.RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, comboEvent.atTime);
                break;
            }
        }
    }

    CleanState(): void {
    }

}

export const comboPointsState = new ComboPointsState();
OvaleState.RegisterState(comboPointsState);