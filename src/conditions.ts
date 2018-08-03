import LibBabbleCreatureType from "@wowts/lib_babble-creature_type-3.0";
import LibRangeCheck from "@wowts/lib_range_check-2.0";
import { OvaleBestAction } from "./BestAction";
import { OvaleCompile } from "./Compile";
import { OvaleCondition, TestValue, Compare, TestBoolean, ParseCondition } from "./Condition";
import { OvaleDamageTaken } from "./DamageTaken";
import { OvaleData, SpellInfo } from "./Data";
import { OvaleEquipment } from "./Equipment";
import { OvaleFuture } from "./Future";
import { OvaleGUID } from "./GUID";
import { OvaleHealth } from "./Health";
import { OvalePower } from "./Power";
import { OvaleRunes } from "./Runes";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleSpellDamage } from "./SpellDamage";
import { OvaleArtifact } from "./Artifact";
import { OvaleBossMod } from "./BossMod";
import { Ovale } from "./Ovale";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleAura } from "./Aura";
import { OvaleWildImps } from "./WildImps";
import { OvaleEnemies } from "./Enemies";
import { OvaleTotem } from "./Totem";
import { OvaleDemonHunterSoulFragments } from "./DemonHunterSoulFragments";
import { OvaleFrameModule } from "./Frame";
import { lastSpell } from "./LastSpell";
import { ipairs, pairs, type, LuaArray, LuaObj, lualength } from "@wowts/lua";
import { GetBuildInfo, GetItemCooldown, GetItemCount, GetNumTrackingTypes, GetTime, GetTrackingInfo, GetUnitSpeed, GetWeaponEnchantInfo, HasFullControl, IsStealthed, UnitCastingInfo, UnitChannelInfo, UnitClass, UnitClassification, UnitCreatureFamily, UnitCreatureType, UnitDetailedThreatSituation, UnitExists, UnitInRaid, UnitIsDead, UnitIsFriend, UnitIsPVP, UnitIsUnit, UnitLevel, UnitName, UnitPower, UnitPowerMax, UnitRace, UnitStagger } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { isValueNode } from "./AST";
import { OvaleCooldown } from "./Cooldown";
import { variables } from "./Variables";
import { OvaleStance } from "./Stance";
import { OvaleSigil } from "./DemonHunterSigils";
import { baseState } from "./BaseState";
import { OvaleSpells } from "./Spells";
import { OvaleAzerite } from "./AzeriteArmor";
let INFINITY = huge;

type BaseState = {};

// Return the target's damage reduction from armor, which seems to be 30% with most bosses
function BossArmorDamageReduction(target, state: BaseState) {
    return 0.3;
}

// Return the value of a parameter from the named spell's information.  If the value is the name of a
// function in the script, then return the compute the value of that function instead.
function ComputeParameter<T extends keyof SpellInfo>(spellId, paramName: T, state: BaseState, atTime): SpellInfo[T] {
    let si = OvaleData.GetSpellInfo(spellId);
    if (si && si[paramName]) {
        let name = si[paramName];
        let node = OvaleCompile.GetFunctionNode(name);
        if (node) {
            let [, element] = OvaleBestAction.Compute(node.child[1], state, atTime);
            if (element && isValueNode(element)) {
                let value = <number>element.value + (atTime - element.origin) * element.rate;
                return value;
            }
        } else {
            return si[paramName];
        }
    }
    return undefined;
}

// Return the time in seconds, adjusted by the named haste effect.
function GetHastedTime(seconds, haste, state: BaseState) {
    seconds = seconds || 0;
    let multiplier = OvalePaperDoll.GetHasteMultiplier(haste, OvalePaperDoll.next);
    return seconds / multiplier;
}
{
    /** Check whether the player currently has an armor set bonus.
	@name ArmorSetBonus
	@paramsig number
	@param name The name of the armor set.
	    Valid names: T11, T12, T13, T14, T15, T16
	    Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	@param count The number of pieces needed to activate the armor set bonus.
	@return 1 if the set bonus is active, or 0 otherwise.
	@usage
	if ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements) */
    function ArmorSetBonus(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [armorSet, count] = [positionalParams[1], positionalParams[2]];
        let value = (OvaleEquipment.GetArmorSetCount(armorSet) >= count) && 1 || 0;
        return [0, INFINITY, value, 0, 0];
    }
    OvaleCondition.RegisterCondition("armorsetbonus", false, ArmorSetBonus);
}
{
    /** Get how many pieces of an armor set, e.g., Tier 14 set, are equipped by the player.
	@name ArmorSetParts
	@paramsig number or boolean
	@param name The name of the armor set.
	    Valid names: T11, T12, T13, T14, T15.
	    Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	@param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	@param number Optional. The number to compare against.
	@return The number of pieces of the named set that are equipped by the player.
	@return A boolean value for the result of the comparison.
	@usage
	if ArmorSetParts(T13) >=2 and target.HealthPercent() <60
	    Spell(ferocious_bite)
	if ArmorSetParts(T13 more 1) and TargetHealthPercent(less 60)
	    Spell(ferocious_bite) */
    function ArmorSetParts(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [armorSet, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleEquipment.GetArmorSetCount(armorSet);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("armorsetparts", false, ArmorSetParts);
}
{
    function ArtifactTraitRank(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleArtifact.TraitRank(spellId);
        return Compare(value, comparator, limit);
    }
    function HasArtifactTrait(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let value = OvaleArtifact.HasTrait(spellId);
        return TestBoolean(value, yesno);
    }
    OvaleCondition.RegisterCondition("hasartifacttrait", false, HasArtifactTrait);
    OvaleCondition.RegisterCondition("artifacttraitrank", false, ArtifactTraitRank);
}
{
    function HasAzeriteTrait(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number){
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let value = OvaleAzerite.HasTrait(spellId);
        return TestBoolean(value, yesno);
    }
    OvaleCondition.RegisterCondition("hasazeritetrait", false, HasAzeriteTrait);
}
{
    /** Get the base duration of the aura in seconds if it is applied at the current time.
	@name BaseDuration
	@paramsig number or boolean
	@param id The aura spell ID.
	@param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	@param number Optional. The number to compare against.
	@return The base duration in seconds.
	@return A boolean value for the result of the comparison.
	@see BuffDuration
	@usage
	if BaseDuration(slice_and_dice_buff) > BuffDuration(slice_and_dice_buff)
	    Spell(slice_and_dice) */

    function BaseDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value;
        if ((OvaleData.buffSpellList[auraId])) {
            let spellList = OvaleData.buffSpellList[auraId];
            for (const [id] of pairs(spellList)) {
                value = OvaleAura.GetBaseDuration(id, OvalePaperDoll.next);
                if (value != huge) {
                    break;
                }
            }
        } else {
            value = OvaleAura.GetBaseDuration(auraId, OvalePaperDoll.next);
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("baseduration", false, BaseDuration);
    OvaleCondition.RegisterCondition("buffdurationifapplied", false, BaseDuration);
    OvaleCondition.RegisterCondition("debuffdurationifapplied", false, BaseDuration);
}
{
    /** Get the value of a buff as a number.  Not all buffs return an amount.
	 @name BuffAmount
	 @paramsig number
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param value Optional. Sets which aura value to return from UnitAura().
	     Defaults to value=1.
	     Valid values: 1, 2, 3.
	 @return The value of the buff as a number.
	 @see DebuffAmount
	 @see TickValue
	 @usage
	 if DebuffAmount(stagger) >10000 Spell(purifying_brew)
	 if DebuffAmount(stagger more 10000) Spell(purifying_brew) */
    function BuffAmount(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let value = namedParams.value || 1;
        let statName = "value1";
        if (value == 1) {
            statName = "value1";
        } else if (value == 2) {
            statName = "value2";
        } else if (value == 3) {
            statName = "value3";
        }
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura[statName] || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffamount", false, BuffAmount);
    OvaleCondition.RegisterCondition("debuffamount", false, BuffAmount);
    OvaleCondition.RegisterCondition("tickvalue", false, BuffAmount);
}
{
    /** Get the player's combo points for the given aura at the time the aura was applied on the target.
	 @name BuffComboPoints
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of combo points.
	 @return A boolean value for the result of the comparison.
	 @see DebuffComboPoints
	 @usage
	 if target.DebuffComboPoints(rip) <5 Spell(rip) */
    function BuffComboPoints(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura && aura.combopoints || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcombopoints", false, BuffComboPoints);
    OvaleCondition.RegisterCondition("debuffcombopoints", false, BuffComboPoints);
}
{
    /** Get the number of seconds before a buff can be gained again.
	 @name BuffCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see DebuffCooldown
	 @usage
	 if BuffCooldown(trinket_stat_agility_buff) > 45
	     Spell(tigers_fury)
    */
    function BuffCooldown(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, cooldownEnding] = [aura.gain, aura.cooldownEnding];
            cooldownEnding = aura.cooldownEnding || 0;
            return TestValue(gain, INFINITY, 0, cooldownEnding, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcooldown", false, BuffCooldown);
    OvaleCondition.RegisterCondition("debuffcooldown", false, BuffCooldown);
}
{
    /**  Get the number of buff if the given spell list
	 @name BuffCount
	 @paramsig number or boolean
	 @param id the spell list ID	
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of buffs
	 @return A boolean value for the result of the comparison
	 */
    function BuffCount(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let spellList = OvaleData.buffSpellList[auraId];
        let count = 0;
        for (const [id] of pairs(spellList)) {
            let aura = OvaleAura.GetAura(target, id, atTime, filter, mine);
            if (OvaleAura.IsActiveAura(aura, atTime)) {
                count = count + 1;
            }
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcount", false, BuffCount);
}
{
    /** Get the duration in seconds of the cooldown before a buff can be gained again.
	 @name BuffCooldownDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see DebuffCooldown
	 @usage
	 if target.TimeToDie() > BuffCooldownDuration(trinket_stat_any_buff)
	     Item(Trinket0Slot)
     */
    function BuffCooldownDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let minCooldown = INFINITY;
        if (OvaleData.buffSpellList[auraId]) {
            for (const [id] of pairs(OvaleData.buffSpellList[auraId])) {
                let si = OvaleData.spellInfo[id];
                let cd = si && si.buff_cd;
                if (cd && minCooldown > cd) {
                    minCooldown = cd;
                }
            }
        } else {
            minCooldown = 0;
        }
        return Compare(minCooldown, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcooldownduration", false, BuffCooldownDuration);
    OvaleCondition.RegisterCondition("debuffcooldownduration", false, BuffCooldownDuration);
}
{
    /** /** Get the total count of the given aura across all targets.
	 @name BuffCountOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param stacks Optional. The minimum number of stacks of the aura required.
	     Defaults to stacks=1.
	     Valid values: any number greater than zero.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	     Defaults to excludeTarget=0.
	     Valid values: 0, 1.
	 @param count Optional. Sets whether a count or a fractional value is returned.
	     Defaults to count=1.
	     Valid values: 0, 1.
	 @return The total aura count.
	 @return A boolean value for the result of the comparison.
	 @see DebuffCountOnAny
     */
    function BuffCountOnAny(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && baseState.next.defaultTarget || undefined;
        let fractional = (namedParams.count == 0) && true || false;
        let [count, , startChangeCount, endingChangeCount, startFirst, endingLast] = OvaleAura.AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId);
        if (count > 0 && startChangeCount < INFINITY && fractional) {
            let origin = startChangeCount;
            let rate = -1 / (endingChangeCount - startChangeCount);
            let [start, ending] = [startFirst, endingLast];
            return TestValue(start, ending, count, origin, rate, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffcountonany", false, BuffCountOnAny);
    OvaleCondition.RegisterCondition("debuffcountonany", false, BuffCountOnAny);
}
{
    /** Get the current direction of an aura's stack count.
	 A negative number means the aura is decreasing in stack count.
	 A positive number means the aura is increasing in stack count.
	 @name BuffDirection
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current direction.
	 @return A boolean value for the result of the comparison.
	 @see DebuffDirection
     */
    function BuffDirection(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, , , direction] = [aura.gain, aura.start, aura.ending, aura.direction];
            return TestValue(gain, INFINITY, direction, gain, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffdirection", false, BuffDirection);
    OvaleCondition.RegisterCondition("debuffdirection", false, BuffDirection);
}
{
    /** Get the total duration of the aura from when it was first applied to when it ended.
	 @name BuffDuration
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The total duration of the aura.
	 @return A boolean value for the result of the comparison.
	 @see DebuffDuration
     */
    function BuffDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = ending - start;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffduration", false, BuffDuration);
    OvaleCondition.RegisterCondition("debuffduration", false, BuffDuration);
}
{
    /** Test if an aura is expired, or will expire after a given number of seconds.
	 @name BuffExpires
	 @paramsig boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param seconds Optional. The maximum number of seconds before the buff should expire.
	     Defaults to 0 (zero).
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
	     Defaults to haste=none.
	     Valid values: melee, spell, none.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @see DebuffExpires
	 @usage
	 if BuffExpires(stamina any=1)
	     Spell(power_word_fortitude)
	 if target.DebuffExpires(rake 2)
	     Spell(rake)
     */
    function BuffExpires(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, seconds] = [positionalParams[1], positionalParams[2]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, , ending] = [aura.gain, aura.start, aura.ending];
            seconds = GetHastedTime(seconds, namedParams.haste, state);
            if (ending - seconds <= gain) {
                return [gain, INFINITY];
            } else {
                return [ending - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("buffexpires", false, BuffExpires);
    OvaleCondition.RegisterCondition("debuffexpires", false, BuffExpires);

    /** Test if an aura is present or if the remaining time on the aura is more than the given number of seconds.
      @name BuffPresent
      @paramsig boolean
      @param id The spell ID of the aura or the name of a spell list.
      @param seconds Optional. The mininum number of seconds before the buff should expire.
          Defaults to 0 (zero).
      @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
          Defaults to any=0.
          Valid values: 0, 1.
      @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
          Defaults to haste=none.
          Valid values: melee, spell, none.
      @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
          Defaults to target=player.
          Valid values: player, target, focus, pet.
      @return A boolean value.
      @see DebuffPresent
      @usage
      if not BuffPresent(stamina any=1)
          Spell(power_word_fortitude)
      if not target.DebuffPresent(rake 2)
          Spell(rake)
      */
    function BuffPresent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, seconds] = [positionalParams[1], positionalParams[2]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, , ending] = [aura.gain, aura.start, aura.ending];
            seconds = GetHastedTime(seconds, namedParams.haste, state);
            if (ending - seconds <= gain) {
                return undefined;
            } else {
                return [gain, ending - seconds];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("buffpresent", false, BuffPresent);
    OvaleCondition.RegisterCondition("debuffpresent", false, BuffPresent);
}
{
    /** Get the time elapsed since the aura was last gained on the target.
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see DebuffGain */
    function BuffGain(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let gain = aura.gain || 0;
            return TestValue(gain, INFINITY, 0, gain, 1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffgain", false, BuffGain);
    OvaleCondition.RegisterCondition("debuffgain", false, BuffGain);
}
{
    function BuffImproved(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [, ,] = ParseCondition(positionalParams, namedParams, state);
        // TODO Not implemented
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffimproved", false, BuffImproved);
    OvaleCondition.RegisterCondition("debuffimproved", false, BuffImproved);
}
{
    /** Get the player's persistent multiplier for the given aura at the time the aura was applied on the target.
	 The persistent multiplier is snapshotted to the aura for its duration at the time the aura is applied.
	 @name BuffPersistentMultiplier
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The persistent multiplier.
	 @return A boolean value for the result of the comparison.
	 @see DebuffPersistentMultiplier
	 @usage
	 if target.DebuffPersistentMultiplier(rake) < 1 Spell(rake)
     */
    function BuffPersistentMultiplier(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura.damageMultiplier || 1;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffpersistentmultiplier", false, BuffPersistentMultiplier);
    OvaleCondition.RegisterCondition("debuffpersistentmultiplier", false, BuffPersistentMultiplier);
}
{
    /** Get the remaining time in seconds on an aura.
	 @name BuffRemaining
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds remaining on the aura.
	 @return A boolean value for the result of the comparison.
	 @see DebuffRemaining
	 @usage
	 if BuffRemaining(slice_and_dice) <2
	     Spell(slice_and_dice)
     */
    function BuffRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, , ending] = [aura.gain, aura.start, aura.ending];
            return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffremaining", false, BuffRemaining);
    OvaleCondition.RegisterCondition("debuffremaining", false, BuffRemaining);
    OvaleCondition.RegisterCondition("buffremains", false, BuffRemaining);
    OvaleCondition.RegisterCondition("debuffremains", false, BuffRemaining);
}
{
    /** Get the remaining time in seconds before the aura expires across all targets.
	 @name BuffRemainingOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param stacks Optional. The minimum number of stacks of the aura required.
	     Defaults to stacks=1.
	     Valid values: any number greater than zero.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	     Defaults to excludeTarget=0.
	     Valid values: 0, 1.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see DebuffRemainingOnAny
     */
    function BuffRemainingOnAny(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && baseState.next.defaultTarget || undefined;
        let [count, , , , startFirst, endingLast] = OvaleAura.AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId);
        if (count > 0) {
            let [start, ending] = [startFirst, endingLast];
            return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffremainingonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("debuffremainingonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("buffremainsonany", false, BuffRemainingOnAny);
    OvaleCondition.RegisterCondition("debuffremainsonany", false, BuffRemainingOnAny);
}
{
    /** Get the number of stacks of an aura on the target.
	 @name BuffStacks
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of stacks of the aura.
	 @return A boolean value for the result of the comparison.
	 @see DebuffStacks
	 @usage
	 if BuffStacks(pet_frenzy any=1) ==5
	     Spell(focus_fire)
	 if target.DebuffStacks(weakened_armor) <3
	     Spell(faerie_fire)
     */
    function BuffStacks(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let value = aura.stacks || 0;
            return TestValue(gain, ending, value, start, 0, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffstacks", false, BuffStacks);
    OvaleCondition.RegisterCondition("debuffstacks", false, BuffStacks);
}
{
    /** Get the total number of stacks of the given aura across all targets.
	 @name BuffStacksOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	     Defaults to excludeTarget=0.
	     Valid values: 0, 1.
	 @return The total number of stacks.
	 @return A boolean value for the result of the comparison.
	 @see DebuffStacksOnAny
     */
    function BuffStacksOnAny(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let excludeUnitId = (namedParams.excludeTarget == 1) && baseState.next.defaultTarget || undefined;
        let [count, stacks, , endingChangeCount, startFirst,] = OvaleAura.AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId);
        if (count > 0) {
            let [start, ending] = [startFirst, endingChangeCount];
            return TestValue(start, ending, stacks, start, 0, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }
    OvaleCondition.RegisterCondition("buffstacksonany", false, BuffStacksOnAny);
    OvaleCondition.RegisterCondition("debuffstacksonany", false, BuffStacksOnAny);
}
{
    /** Test if there is a stealable buff on the target.
	 @name BuffStealable
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.BuffStealable()
	     Spell(spellsteal)
     */
    function BuffStealable(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [target] = ParseCondition(positionalParams, namedParams, state);
        return OvaleAura.GetAuraWithProperty(target, "stealable", "HELPFUL", atTime);
    }
    OvaleCondition.RegisterCondition("buffstealable", false, BuffStealable);
}
{
    /** Check if the player can cast the given spell (not on cooldown).
	 @name CanCast
	 @paramsig boolean
	 @param id The spell ID to check.
	 @return True if the spell cast be cast; otherwise, false.
     */
    function CanCast(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let spellId = positionalParams[1];
        let [start, duration] = OvaleCooldown.GetSpellCooldown(spellId, atTime);
        return [start + duration, INFINITY];
    }
    OvaleCondition.RegisterCondition("cancast", true, CanCast);
}
{
    /** Get the cast time in seconds of the spell for the player, taking into account current haste effects.
	 @name CastTime
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see ExecuteTime
	 @usage
	 if target.DebuffRemaining(flame_shock) < CastTime(lava_burst)
	     Spell(lava_burst)
     */
    function CastTime(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        return Compare(castTime, comparator, limit);
    }

    /** Get the cast time in seconds of the spell for the player or the GCD for the player, whichever is greater.
	 @name ExecuteTime
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see CastTime
	 @usage
	 if target.DebuffRemaining(flame_shock) < ExecuteTime(lava_burst)
	     Spell(lava_burst)
     */
    function ExecuteTime(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        let gcd = OvaleFuture.GetGCD();
        let t = (castTime > gcd) && castTime || gcd;
        return Compare(t, comparator, limit);
    }
    OvaleCondition.RegisterCondition("casttime", true, CastTime);
    OvaleCondition.RegisterCondition("executetime", true, ExecuteTime);
}
{
    /** Test if the target is casting the given spell.
	 The spell may be specified either by spell ID, spell list name (as defined in SpellList),
	 "harmful" for any harmful spell, or "helpful" for any helpful spell.
	 @name Casting
	 @paramsig boolean
	 @param spell The spell to check.
	     Valid values: spell ID, spell list name, harmful, helpful
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 Define(maloriak_release_aberrations 77569)
	 if target.Casting(maloriak_release_aberrations)
	     Spell(pummel)
     */
    function Casting(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let spellId = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let start, ending, castSpellId, castSpellName;
        if (target == "player") {
            start = OvaleFuture.next.currentCast.start;
            ending = OvaleFuture.next.currentCast.stop;
            castSpellId = OvaleFuture.next.currentCast.spellId;
            castSpellName = OvaleSpellBook.GetSpellName(castSpellId);
        } else {
            let [spellName, _1, _2, startTime, endTime] = UnitCastingInfo(target);
            if (!spellName) {
                [spellName, _1, _2, startTime, endTime] = UnitChannelInfo(target);
            }
            if (spellName) {
                castSpellName = spellName;
                start = startTime / 1000;
                ending = endTime / 1000;
            }
        }
        if (castSpellId || castSpellName) {
            if (!spellId) {
                return [start, ending];
            } else if (OvaleData.buffSpellList[spellId]) {
                for (const [id] of pairs(OvaleData.buffSpellList[spellId])) {
                    if (id == castSpellId || OvaleSpellBook.GetSpellName(id) == castSpellName) {
                        return [start, ending];
                    }
                }
            } else if (spellId == "harmful" && OvaleSpellBook.IsHarmfulSpell(spellId)) {
                return [start, ending];
            } else if (spellId == "helpful" && OvaleSpellBook.IsHelpfulSpell(spellId)) {
                return [start, ending];
            } else if (spellId == castSpellId) {
                Ovale.Print("%f %f %d %s => %d (%f)", start, ending, castSpellId, castSpellName, spellId, baseState.next.currentTime);
                return [start, ending];
            } else if (type(spellId) == "number" && OvaleSpellBook.GetSpellName(spellId) == castSpellName) {
                return [start, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("casting", false, Casting);
}
{
    /** Test if all of the listed checkboxes are off.
	 @name CheckBoxOff
	 @paramsig boolean
	 @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
	 @param ... Optional. Additional checkbox names.
	 @return A boolean value.
	 @see CheckBoxOn
	 @usage
	 AddCheckBox(opt_black_arrow "Black Arrow" default)
	 if CheckBoxOff(opt_black_arrow) Spell(explosive_trap)

	 */
    function CheckBoxOff(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        for (const [, id] of ipairs(positionalParams)) {
            if (OvaleFrameModule.frame && OvaleFrameModule.frame.IsChecked(id)) {
                return undefined;
            }
        }
        return [0, INFINITY];
    }

    /** Test if all of the listed checkboxes are on.
	 @name CheckBoxOn
	 @paramsig boolean
	 @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
	 @param ... Optional. Additional checkbox names.
	 @return A boolean value.
	 @see CheckBoxOff
	 @usage
	 AddCheckBox(opt_black_arrow "Black Arrow" default)
	 if CheckBoxOn(opt_black_arrow) Spell(black_arrow)
     */
    function CheckBoxOn(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        for (const [, id] of ipairs(positionalParams)) {
            if (OvaleFrameModule.frame && !OvaleFrameModule.frame.IsChecked(id)) {
                return undefined;
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("checkboxoff", false, CheckBoxOff);
    OvaleCondition.RegisterCondition("checkboxon", false, CheckBoxOn);
}
{
    /** Test whether the target's class matches the given class.
	 @name Class
	 @paramsig boolean
	 @param class The class to check.
	     Valid values: DEATHKNIGHT, DRUID, HUNTER, MAGE, MONK, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR.
	 @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.Class(PRIEST) Spell(cheap_shot)
     */
    function Class(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [className, yesno] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let [, classToken] = UnitClass(target);
        let boolean = (classToken == className);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("class", false, Class);
}
{
    let IMBUED_BUFF_ID = 214336;

    /** Test whether the target's classification matches the given classification.
	 @name Classification
	 @paramsig boolean
	 @param classification The unit classification to check.
	     Valid values: normal, elite, worldboss.
	 @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.Classification(worldboss) Item(virmens_bite_potion)
     */
    function Classification(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [classification, yesno] = [positionalParams[1], positionalParams[2]];
        let targetClassification;
        let [target] = ParseCondition(positionalParams, namedParams, state);
        if (UnitLevel(target) < 0) {
            targetClassification = "worldboss";
        } else if (UnitExists("boss1") && OvaleGUID.UnitGUID(target) == OvaleGUID.UnitGUID("boss1")) {
            targetClassification = "worldboss";
        } else {
            let aura = OvaleAura.GetAura(target, IMBUED_BUFF_ID, atTime, "debuff", false);
            if (OvaleAura.IsActiveAura(aura, atTime)) {
                targetClassification = "worldboss";
            } else {
                targetClassification = UnitClassification(target);
                if (targetClassification == "rareelite") {
                    targetClassification = "elite";
                } else if (targetClassification == "rare") {
                    targetClassification = "normal";
                }
            }
        }
        let boolean = (targetClassification == classification);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("classification", false, Classification);
}
{
    /**  Get the current value of a script counter.
	 @name Counter
	 @paramsig number or boolean
	 @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current value the counter.
	 @return A boolean value for the result of the comparison.
     */
    function Counter(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [counter, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleFuture.GetCounter(counter, atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("counter", false, Counter);
}
{
    /** Test whether the target's creature family matches the given name.
	 Applies only to beasts that can be taken as hunter pets (e.g., cats, worms, and ravagers but not zhevras, talbuks and pterrordax),
	 demons that can be summoned by Warlocks (e.g., imps and felguards, but not demons that require enslaving such as infernals
	 and doomguards or world demons such as pit lords and armored voidwalkers), and Death Knight's pets (ghouls)
	 @name CreatureFamily
	 @paramsig boolean
	 @param name The English name of the creature family to check.
	     Valid values: Bat, Beast, Felguard, Imp, Ravager, etc.
	 @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if pet.CreatureFamily(Felguard)
	     Spell(summon_felhunter)
	 if target.CreatureFamily(Dragonkin)
	     Spell(hibernate)
     */
    function CreatureFamily(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [name, yesno] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let family = UnitCreatureFamily(target);
        let lookupTable = LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        let boolean = (lookupTable && family == lookupTable[name]);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("creaturefamily", false, CreatureFamily);
}
{
    /**  Test if the target is any of the listed creature types.
	 @name CreatureType
	 @paramsig boolean
	 @param name The English name of a creature type.
	     Valid values: Beast, Humanoid, Undead, etc.
	 @param ... Optional. Additional creature types.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.CreatureType(Humanoid Critter)
	     Spell(polymorph)
     */
    function CreatureType(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let creatureType = UnitCreatureType(target);
        let lookupTable = LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        if (lookupTable) {
            for (const [, name] of ipairs<string>(positionalParams)) {
                if (creatureType == lookupTable[name]) {
                    return [0, INFINITY];
                }
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("creaturetype", false, CreatureType);
}
{
    let AMPLIFICATION = 146051;
    let INCREASED_CRIT_EFFECT_3_PERCENT = 44797;
    /** Get the current estimated damage of a spell on the target if it is a critical strike.
	 @name CritDamage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The estimated critical strike damage of the given spell.
	 @return A boolean value for the result of the comparison.
	 @see Damage
     */
    function CritDamage(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let value = ComputeParameter(spellId, "damage", state, atTime) || 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target, state));
        }
        let critMultiplier = 2;
        {
            let aura = OvaleAura.GetAura("player", AMPLIFICATION, atTime, "HELPFUL");
            if (OvaleAura.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier + aura.value1;
            }
        }
        {
            let aura = OvaleAura.GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, atTime, "HELPFUL");
            if (OvaleAura.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier * aura.value1;
            }
        }
        value = critMultiplier * value;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("critdamage", false, CritDamage);

    /**  Get the current estimated damage of a spell on the target.
	 The script must provide a function to calculate the damage of the spell and assign it to the "damage" SpellInfo() parameter.
	 @name Damage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The estimated damage of the given spell on the target.
	 @return A boolean value for the result of the comparison.
	 @see CritDamage, LastDamage, LastEstimatedDamage
	 @usage
	 if {target.Damage(rake) / target.LastEstimateDamage(rake)} >1.1
	     Spell(rake)
     */
    function Damage(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let value = ComputeParameter(spellId, "damage", state, atTime) || 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target, state));
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("damage", false, Damage);
}
{
    /**  Get the damage taken by the player in the previous time interval.
	 @name DamageTaken
	 @paramsig number or boolean
	 @param interval The number of seconds before now.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param magic Optional. By default, all damage is counted. Set "magic=1" to count only magic damage.
	     Defaults to magic=0.
	     Valid values: 0, 1
	 @param physical Optional. By default, all damage is counted. Set "physical=1" to count only physical damage.
	     Defaults to physical=0.
	     Valid values: 0, 1
	 @return The amount of damage taken in the previous interval.
	 @return A boolean value for the result of the comparison.
	 @see IncomingDamage
	 @usage
	 if DamageTaken(5) > 50000 Spell(death_strike)
	 if DamageTaken(5 magic=1) > 0 Spell(antimagic_shell)
     */
    function DamageTaken(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [interval, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 0;
        if (interval > 0) {
            let [total, totalMagic] = OvaleDamageTaken.GetRecentDamage(interval);
            if (namedParams.magic == 1) {
                value = totalMagic;
            } else if (namedParams.physical == 1) {
                value = total - totalMagic;
            } else {
                value = total;
            }
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("damagetaken", false, DamageTaken);
    OvaleCondition.RegisterCondition("incomingdamage", false, DamageTaken);
}
{
    function Demons(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleWildImps.GetDemonsCount(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    function NotDeDemons(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleWildImps.GetNotDemonicEmpoweredDemonsCount(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    function DemonDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [creatureId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleWildImps.GetRemainingDemonDuration(creatureId, atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("demons", false, Demons);
    OvaleCondition.RegisterCondition("notdedemons", false, NotDeDemons);
    OvaleCondition.RegisterCondition("demonduration", false, DemonDuration);
}
{
    let NECROTIC_PLAGUE_TALENT = 19;
    let NECROTIC_PLAGUE_DEBUFF = 155159;
    let BLOOD_PLAGUE_DEBUFF = 55078;
    let FROST_FEVER_DEBUFF = 55095;
    function GetDiseases(target: string, state: BaseState, atTime: number) {
        let npAura, bpAura, ffAura;
        let talented = (OvaleSpellBook.GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0);
        if (talented) {
            npAura = OvaleAura.GetAura(target, NECROTIC_PLAGUE_DEBUFF, atTime, "HARMFUL", true);
        } else {
            bpAura = OvaleAura.GetAura(target, BLOOD_PLAGUE_DEBUFF, atTime, "HARMFUL", true);
            ffAura = OvaleAura.GetAura(target, FROST_FEVER_DEBUFF, atTime, "HARMFUL", true);
        }
        return [talented, npAura, bpAura, ffAura];
    }

    /** Get the remaining time in seconds before any diseases applied by the death knight will expire.
	 @name DiseasesRemaining
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function DiseasesRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, ,] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state, atTime);
        let aura;
        if (talented && OvaleAura.IsActiveAura(npAura, atTime)) {
            aura = npAura;
        } else if (!talented && OvaleAura.IsActiveAura(bpAura, atTime) && OvaleAura.IsActiveAura(ffAura, atTime)) {
            aura = (bpAura.ending < ffAura.ending) && bpAura || ffAura;
        }
        if (aura) {
            let [gain, , ending] = [aura.gain, aura.start, aura.ending];
            return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }

    /**  Test if all diseases applied by the death knight are present on the target.
	 @name DiseasesTicking
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    function DiseasesTicking(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [target, ,] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state, atTime);
        let gain, start, ending;
        if (talented && npAura) {
            [gain, start, ending] = [npAura.gain, npAura.start, npAura.ending];
        } else if (!talented && bpAura && ffAura) {
            gain = (bpAura.gain > ffAura.gain) && bpAura.gain || ffAura.gain;
            start = (bpAura.start > ffAura.start) && bpAura.start || ffAura.start;
            ending = (bpAura.ending < ffAura.ending) && bpAura.ending || ffAura.ending;
        }
        if (gain && ending && ending > gain) {
            return [gain, ending];
        }
        return undefined;
    }

    /**  Test if any diseases applied by the death knight are present on the target.
	 @name DiseasesAnyTicking
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    function DiseasesAnyTicking(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [target, ,] = ParseCondition(positionalParams, namedParams, state);
        let [talented, npAura, bpAura, ffAura] = GetDiseases(target, state, atTime);
        let aura;
        if (talented && npAura) {
            aura = npAura;
        } else if (!talented && (bpAura || ffAura)) {
            aura = bpAura || ffAura;
            if (bpAura && ffAura) {
                aura = (bpAura.ending > ffAura.ending) && bpAura || ffAura;
            }
        }
        if (aura) {
            let [gain, , ending] = [aura.gain, aura.start, aura.ending];
            if (ending > gain) {
                return [gain, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("diseasesremaining", false, DiseasesRemaining);
    OvaleCondition.RegisterCondition("diseasesticking", false, DiseasesTicking);
    OvaleCondition.RegisterCondition("diseasesanyticking", false, DiseasesAnyTicking);
}
{
    /**  Get the distance in yards to the target.
	 The distances are from LibRangeCheck-2.0, which determines distance based on spell range checks, so results are approximate.
	 You should not test for equality.
	 @name Distance
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The distance to the target.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if target.Distance(less 25)
	     Texture(ability_rogue_sprint)
     */
    function Distance(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value = LibRangeCheck && LibRangeCheck.GetRange(target) || 0;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("distance", false, Distance);
}
{
    /**  Get the number of hostile enemies on the battlefield.
	 The minimum value returned is 1.
	 @name Enemies
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param tagged Optional. By default, all enemies are counted. To count only enemies directly tagged by the player, set tagged=1.
	     Defaults to tagged=0.
	     Valid values: 0, 1.
	 @return The number of enemies.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Enemies() >4 Spell(fan_of_knives)
	 if Enemies(more 4) Spell(fan_of_knives)
     */
    function Enemies(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvaleEnemies.next.enemies;
        if (!value) {
            let useTagged = Ovale.db.profile.apparence.taggedEnemies
            if (namedParams.tagged == 0) {
                useTagged = false;
            } else if (namedParams.tagged == 1) {
                useTagged = true;
            }
            value = useTagged && OvaleEnemies.next.taggedEnemies || OvaleEnemies.next.activeEnemies;
        }
        if (value < 1) {
            value = 1;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("enemies", false, Enemies);
}
{
    /** Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
	 @name EnergyRegenRate
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current rate of energy regeneration.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if EnergyRegenRage() >11 Spell(stance_of_the_sturdy_ox)
     */
    function EnergyRegenRate(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvalePower.next.GetPowerRate("energy");
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("energyregen", false, EnergyRegenRate);
    OvaleCondition.RegisterCondition("energyregenrate", false, EnergyRegenRate);
}
{
    /** Get the remaining time in seconds the target is Enraged.
	 @name EnrageRemaining
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see IsEnraged
	 @usage
	 if EnrageRemaining() < 3 Spell(berserker_rage)
     */
    function EnrageRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let [start, ending] = OvaleAura.GetAuraWithProperty(target, "enrage", "HELPFUL", atTime);
        if (start && ending) {
            return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("enrageremaining", false, EnrageRemaining);
}
{
    /** Test if the target exists. The target may be alive or dead.
	 @name Exists
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @see Present
	 @usage
	 if pet.Exists(no) Spell(summon_imp)
     */
    function Exists(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitExists(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("exists", false, Exists);
}
{
    /** A condition that always returns false.
	 @name False
	 @paramsig boolean
	 @return A boolean value.
     */
    function False(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return undefined;
    }
    OvaleCondition.RegisterCondition("false", false, False);
}
{
    /**  Get the amount of regenerated focus per second for hunters.
	 @name FocusRegenRate
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current rate of focus regeneration.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if FocusRegenRate() >20 Spell(arcane_shot)
	 if FocusRegenRate(more 20) Spell(arcane_shot)
     */
    function FocusRegenRate(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvalePower.next.GetPowerRate("focus");
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("focusregen", false, FocusRegenRate);
    OvaleCondition.RegisterCondition("focusregenrate", false, FocusRegenRate);
}
{
    let STEADY_FOCUS = 177668;
    /** Get the amount of focus that would be regenerated during the cast time of the given spell for hunters.
	 @name FocusCastingRegen
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The amount of focus.
	 @return A boolean value for the result of the comparison.
     */
    function FocusCastingRegen(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let regenRate = OvalePower.next.GetPowerRate("focus");
        let power = 0;
        let castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
        let gcd = OvaleFuture.GetGCD();
        let castSeconds = (castTime > gcd) && castTime || gcd;
        power = power + regenRate * castSeconds;
        let aura = OvaleAura.GetAura("player", STEADY_FOCUS, atTime, "HELPFUL", true);
        if (aura) {
            let seconds = aura.ending - atTime;
            if (seconds <= 0) {
                seconds = 0;
            } else if (seconds > castSeconds) {
                seconds = castSeconds;
            }
            power = power + regenRate * 1.5 * seconds;
        }
        return Compare(power, comparator, limit);
    }
    OvaleCondition.RegisterCondition("focuscastingregen", false, FocusCastingRegen);
}
{
    /** Get the player's global cooldown in seconds.
	 @name GCD
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if GCD() <1.1 Spell(frostfire_bolt)
	 if GCD(less 1.1) Spell(frostfire_bolt)
     */
    function GCD(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvaleFuture.GetGCD();
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("gcd", false, GCD);
}
{
    /** Get the number of seconds before the player's global cooldown expires.
	 @name GCDRemaining
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the previous spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 unless SpellCooldown(seraphim) < GCDRemaining() Spell(judgment)
     */
    function GCDRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        if (OvaleFuture.next.lastGCDSpellId) {
            let duration = OvaleFuture.GetGCD(OvaleFuture.next.lastGCDSpellId, atTime, OvaleGUID.UnitGUID(target));
            let spellcast = lastSpell.LastInFlightSpell();
            let start = (spellcast && spellcast.start) || 0;
            let ending = start + duration;
            if (atTime < ending) {
                return TestValue(start, INFINITY, 0, ending, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("gcdremaining", false, GCDRemaining);
}
{
    /**  Get the value of the named state variable from the simulator.
	 @name GetState
	 @paramsig number or boolean
	 @param name The name of the state variable.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The value of the state variable.
	 @return A boolean value for the result of the comparison.
     */
    function GetState(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [name, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = variables.GetState(name);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("getstate", false, GetState);
}
{
    /** Get the duration in seconds that the simulator was most recently in the named state.
	 @name GetStateDuration
	 @paramsig number or boolean
	 @param name The name of the state variable.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function GetStateDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [name, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = variables.GetStateDuration(name);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("getstateduration", false, GetStateDuration);
}
{
    function Glyph(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [, yesno] = [positionalParams[1], positionalParams[2]];
        return TestBoolean(false, yesno);
    }
    OvaleCondition.RegisterCondition("glyph", false, Glyph);
}
{
    /**  Test if the player has a particular item equipped.
	 @name HasEquippedItem
	 @paramsig boolean
	 @param item Item to be checked whether it is equipped.
	 @param yesno Optional. If yes, then return true if the item is equipped. If no, then return true if it isn't equipped.
	     Default is yes.
	     Valid values: yes, no.
     */
    function HasEquippedItem(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [itemId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = false;
        let slotId;
        if (type(itemId) == "number") {
            slotId = OvaleEquipment.HasEquippedItem(itemId);
            if (slotId) {
                boolean = true;
            }
        } else if (OvaleData.itemList[itemId]) {
            for (const [, v] of pairs(OvaleData.itemList[itemId])) {
                slotId = OvaleEquipment.HasEquippedItem(v);
                if (slotId) {
                    boolean = true;
                    break;
                }
            }
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasequippeditem", false, HasEquippedItem);
}
{
    /** Test if the player has full control, i.e., isn't feared, charmed, etc.
	 @name HasFullControl
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if HasFullControl(no) Spell(barkskin)
     */
    function HasFullControlCondition(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let boolean = HasFullControl();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasfullcontrol", false, HasFullControlCondition);
}
{
    /** Test if the player has a shield equipped.
	 @name HasShield
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if a shield is equipped. If no, then return true if it isn't equipped.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if HasShield() Spell(shield_wall)
     */
    function HasShield(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let boolean = OvaleEquipment.HasShield();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasshield", false, HasShield);
}
{
    /** Test if the player has a particular trinket equipped.
	 @name HasTrinket
	 @paramsig boolean
	 @param id The item ID of the trinket or the name of an item list.
	 @param yesno Optional. If yes, then return true if the trinket is equipped. If no, then return true if it isn't equipped.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 ItemList(rune_of_reorigination 94532 95802 96546)
	 if HasTrinket(rune_of_reorigination) and BuffPresent(rune_of_reorigination_buff)
	     Spell(rake)
     */
    function HasTrinket(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [trinketId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean: string | undefined  = undefined;
        if (type(trinketId) == "number") {
            boolean = OvaleEquipment.HasTrinket(trinketId);
        } else if (OvaleData.itemList[trinketId]) {
            for (const [, v] of pairs(OvaleData.itemList[trinketId])) {
                boolean = OvaleEquipment.HasTrinket(v);
                if (boolean) {
                    break;
                }
            }
        }
        return TestBoolean(boolean !== undefined, yesno);
    }
    OvaleCondition.RegisterCondition("hastrinket", false, HasTrinket);
}
/* Should no longer be necessary
{
    /**  Test if the player has a weapon equipped.
	 @name HasWeapon
	 @paramsig boolean
	 @param hand Sets which hand weapon.
	     Valid values: main, off
	 @param yesno Optional. If yes, then return true if the weapon is equipped. If no, then return true if it isn't equipped.
	     Default is yes.
	     Valid values: yes, no.
	 @param type Optional. If set via type=value, then specify whether the weapon must be one-handed or two-handed.
	     Default is unset.
	     Valid values: one_handed, two_handed
	 @return A boolean value.
	 @usage
	 if HasWeapon(offhand) and BuffStacks(killing_machine) Spell(frost_strike)
     */ /*
    function HasWeapon(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [hand, yesno] = [positionalParams[1], positionalParams[2]];
        let weaponType = namedParams.type;
        let boolean = false;
        if (weaponType == "one_handed") {
            weaponType = 1;
        } else if (weaponType == "two_handed") {
            weaponType = 2;
        }
        if (hand == "offhand" || hand == "off") {
            boolean = OvaleEquipment.HasOffHandWeapon(weaponType);
        } else if (hand == "mainhand" || hand == "main") {
            boolean = OvaleEquipment.HasMainHandWeapon(weaponType);
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("hasweapon", false, HasWeapon);
}
*/
{
    /** Get the current amount of health points of the target.
	 @name Health
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health.
	 @return A boolean value for the result of the comparison.
	 @see Life
	 @usage
	 if Health() <10000 Spell(last_stand)
	 if Health(less 10000) Spell(last_stand)
     */
    function Health(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let now = GetTime();
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [health, now, -1 * health / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("health", false, Health);
    OvaleCondition.RegisterCondition("life", false, Health);

    /** Get the number of health points away from full health of the target.
	 @name HealthMissing
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current missing health.
	 @return A boolean value for the result of the comparison.
	 @see LifeMissing
	 @usage
	 if HealthMissing() <20000 Item(healthstone)
	 if HealthMissing(less 20000) Item(healthstone)
     */
    function HealthMissing(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
        if (health > 0) {
            let now = GetTime();
            let missing = maxHealth - health;
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [missing, now, health / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(maxHealth, comparator, limit);
    }
    OvaleCondition.RegisterCondition("healthmissing", false, HealthMissing);
    OvaleCondition.RegisterCondition("lifemissing", false, HealthMissing);
    /** Get the current percent level of health of the target.
	 @name HealthPercent
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health percent.
	 @return A boolean value for the result of the comparison.
	 @see LifePercent
	 @usage
	 if HealthPercent() <20 Spell(last_stand)
	 if target.HealthPercent(less 25) Spell(kill_shot)
     */
    function HealthPercent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let now = GetTime();
            let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
            let healthPercent = health / maxHealth * 100;
            let timeToDie = OvaleHealth.UnitTimeToDie(target);
            let [value, origin, rate] = [healthPercent, now, -1 * healthPercent / timeToDie];
            let [start, ending] = [now, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("healthpercent", false, HealthPercent);
    OvaleCondition.RegisterCondition("lifepercent", false, HealthPercent);

    /** Get the amount of health points of the target when it is at full health.
	 @name MaxHealth
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum health.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if target.MaxHealth() >10000000 Item(mogu_power_potion)
	 if target.MaxHealth(more 10000000) Item(mogu_power_potion)
     */
    function MaxHealth(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value = OvaleHealth.UnitHealthMax(target);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("maxhealth", false, MaxHealth);

    /**  Get the estimated number of seconds remaining before the target is dead.
	 @name TimeToDie
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see DeadIn
	 @usage
	 if target.TimeToDie() <2 and ComboPoints() >0 Spell(eviscerate)
     */
    function TimeToDie(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let now = GetTime();
        let timeToDie = OvaleHealth.UnitTimeToDie(target);
        let [value, origin, rate] = [timeToDie, now, -1];
        let [start] = [now, now + timeToDie];
        return TestValue(start, INFINITY, value, origin, rate, comparator, limit);
    }
    OvaleCondition.RegisterCondition("deadin", false, TimeToDie);
    OvaleCondition.RegisterCondition("timetodie", false, TimeToDie);

    /** Get the estimated number of seconds remaining before the target reaches the given percent of max health.
	 @name TimeToHealthPercent
	 @paramsig number or boolean
	 @param percent The percent of maximum health of the target.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TimeToDie
	 @usage
	 if target.TimeToHealthPercent(25) <15 Item(virmens_bite_potion)
     */
    function TimeToHealthPercent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [percent, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let health = OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            let maxHealth = OvaleHealth.UnitHealthMax(target) || 1;
            let healthPercent = health / maxHealth * 100;
            if (healthPercent >= percent) {
                let now = GetTime();
                let timeToDie = OvaleHealth.UnitTimeToDie(target);
                let t = timeToDie * (healthPercent - percent) / healthPercent;
                let [value, origin, rate] = [t, now, -1];
                let [start, ending] = [now, now + t];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetohealthpercent", false, TimeToHealthPercent);
    OvaleCondition.RegisterCondition("timetolifepercent", false, TimeToHealthPercent);
}
{
    /** Test if the player is in combat.
	 @name InCombat
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the player is in combat. If no, then return true if the player isn't in combat.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if InCombat(no) and Stealthed(no) Spell(stealth)
     */
    function InCombat(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let boolean = baseState.next.inCombat;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("incombat", false, InCombat);
}
{
    /** Test if the given spell is in flight for spells that have a flight time after cast, e.g., Lava Burst.
	 @name InFlightToTarget
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if the spell is in flight. If no, then return true if it isn't in flight.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if target.DebuffRemaining(haunt) <3 and not InFlightToTarget(haunt)
	     Spell(haunt)
     */
    function InFlightToTarget(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (OvaleFuture.next.currentCast.spellId == spellId) || OvaleFuture.InFlight(spellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("inflighttotarget", false, InFlightToTarget);
}
{
    /** Test if the distance from the player to the target is within the spell's range.
	 @name InRange
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if the target is in range. If no, then return true if it isn't in range.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if target.IsInterruptible() and target.InRange(kick)
	     Spell(kick)
     */
    function InRange(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = (OvaleSpells.IsSpellInRange(spellId, target) == 1);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("inrange", false, InRange);
}
{
    /** Test if the target's primary aggro is on the player.
	 Even if the target briefly targets and casts a spell on another raid member,
	 this condition returns true as long as the player is highest on the threat table.
	 @name IsAggroed
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target is aggroed. If no, then return true if it isn't aggroed.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsAggroed() Spell(feign_death)
     */
    function IsAggroed(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let [boolean] = UnitDetailedThreatSituation("player", target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isaggroed", false, IsAggroed);
}
{
    /**  Test if the target is dead.
	 @name IsDead
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target is dead. If no, then return true if it isn't dead.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if pet.IsDead() Spell(revive_pet)
     */
    function IsDead(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitIsDead(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isdead", false, IsDead);
}
{
    /** Test if the target is enraged.
	 @name IsEnraged
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if enraged. If no, then return true if not enraged.
	     Default is yes.
	     Valid values: yes.  "no" currently doesn't work.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsEnraged() Spell(soothe)
     */
    function IsEnraged(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [target] = ParseCondition(positionalParams, namedParams, state);
        return OvaleAura.GetAuraWithProperty(target, "enrage", "HELPFUL", atTime);
    }
    OvaleCondition.RegisterCondition("isenraged", false, IsEnraged);
}
{
    /**  Test if the player is feared.
	 @name IsFeared
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if feared. If no, then return true if it not feared.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if IsFeared() Spell(every_man_for_himself)
     */
    function IsFeared(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let aura = OvaleAura.GetAura("player", "fear_debuff", atTime, "HARMFUL");
        let boolean = !HasFullControl() && OvaleAura.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isfeared", false, IsFeared);
}
{
    /** Test if the target is friendly to the player.
	 @name IsFriend
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target is friendly (able to help in combat). If no, then return true if it isn't friendly.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsFriend() Spell(healing_touch)
     */
    function IsFriend(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitIsFriend("player", target);
        return TestBoolean(boolean == 1, yesno);
    }
    OvaleCondition.RegisterCondition("isfriend", false, IsFriend);
}
{
    /** Test if the player is incapacitated.
	 @name IsIncapacitated
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if incapacitated. If no, then return true if it not incapacitated.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if IsIncapacitated() Spell(every_man_for_himself)
     */
    function IsIncapacitated(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let aura = OvaleAura.GetAura("player", "incapacitate_debuff", atTime, "HARMFUL");
        let boolean = !HasFullControl() && OvaleAura.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isincapacitated", false, IsIncapacitated);
}
{
    /**  Test if the target is currently casting an interruptible spell.
	 @name IsInterruptible
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target is interruptible. If no, then return true if it isn't interruptible.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsInterruptible() Spell(kick)
     */
    function IsInterruptible(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let [name, _1, _2, _3, _4, _5, , notInterruptible] = UnitCastingInfo(target);
        if (!name) {
            [name, _1, _2, _3, _4, _5, notInterruptible] = UnitChannelInfo(target);
        }
        let boolean = notInterruptible != undefined && !notInterruptible;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isinterruptible", false, IsInterruptible);
}
{
    /**  Test if the target is flagged for PvP activity.
	 @name IsPVP
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target is flagged for PvP activity. If no, then return true if it isn't PvP-flagged.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if not target.IsFriend() and target.IsPVP() Spell(sap)
     */
    function IsPVP(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitIsPVP(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("ispvp", false, IsPVP);
}
{
    /** Test if the player is rooted.
	 @name IsRooted
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if rooted. If no, then return true if it not rooted.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if IsRooted() Item(Trinket0Slot usable=1)
     */
    function IsRooted(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let aura = OvaleAura.GetAura("player", "root_debuff", atTime, "HARMFUL");
        let boolean = OvaleAura.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isrooted", false, IsRooted);
}
{
    /** Test if the player is stunned.
	 @name IsStunned
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if stunned. If no, then return true if it not stunned.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if IsStunned() Item(Trinket0Slot usable=1)
     */
    function IsStunned(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let aura = OvaleAura.GetAura("player", "stun_debuff", atTime, "HARMFUL");
        let boolean = !HasFullControl() && OvaleAura.IsActiveAura(aura, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isstunned", false, IsStunned);
}
{
    /**  Get the current number of charges of the given item in the player's inventory.
	 @name ItemCharges
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of charges.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
	     Spell(conjure_mana_gem)
	 if ItemCount(mana_gem equal 0) or ItemCharges(mana_gem less 3)
	     Spell(conjure_mana_gem)
     */
    function ItemCharges(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = GetItemCount(itemId, false, true);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcharges", false, ItemCharges);
}
{
    /** Get the cooldown time in seconds of an item, e.g., trinket.
	 @name ItemCooldown
	 @paramsig number or boolean
	 @param id The item ID or the equipped slot name.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if not ItemCooldown(ancient_petrified_seed) > 0
	     Spell(berserk_cat)
	 if not ItemCooldown(Trinket0Slot) > 0
	     Spell(berserk_cat)
     */
    function ItemCooldown(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        if (itemId && type(itemId) != "number") {
            itemId = OvaleEquipment.GetEquippedItem(itemId);
        }
        if (itemId) {
            let [start, duration] = GetItemCooldown(itemId);
            if (start > 0 && duration > 0) {
                return TestValue(start, start + duration, duration, start, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcooldown", false, ItemCooldown);
}
{
    /** Get the current number of the given item in the player's inventory.
	 Items with more than one charge count as one item.
	 @name ItemCount
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The count of the item.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ItemCount(mana_gem) ==0 Spell(conjure_mana_gem)
	 if ItemCount(mana_gem equal 0) Spell(conjure_mana_gem)
     */
    function ItemCount(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [itemId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = GetItemCount(itemId);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("itemcount", false, ItemCount);
}
{
    /** Get the damage done by the most recent damage event for the given spell.
	 If the spell is a periodic aura, then it gives the damage done by the most recent tick.
	 @name LastDamage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The damage done.
	 @return A boolean value for the result of the comparison.
	 @see Damage, LastEstimatedDamage
	 @usage
	 if LastDamage(ignite) >10000 Spell(combustion)
	 if LastDamage(ignite more 10000) Spell(combustion)
     */
    function LastDamage(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleSpellDamage.Get(spellId);
        if (value) {
            return Compare(value, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("lastdamage", false, LastDamage);
    OvaleCondition.RegisterCondition("lastspelldamage", false, LastDamage);
}
{
    /**  Get the level of the target.
	 @name Level
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The level of the target.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Level() >=34 Spell(tiger_palm)
	 if Level(more 33) Spell(tiger_palm)
     */
    function Level(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value;
        if (target == "player") {
            value = OvalePaperDoll.level;
        } else {
            value = UnitLevel(target);
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("level", false, Level);
}
{
    /** Test if a list is currently set to the given value.
	 @name List
	 @paramsig boolean
	 @param id The name of a list. It should match one defined by AddListItem(...).
	 @param value The value to test.
	 @return A boolean value.
	 @usage
	 AddListItem(opt_curse coe "Curse of the Elements" default)
	 AddListItem(opt_curse cot "Curse of Tongues")
	 if List(opt_curse coe) Spell(curse_of_the_elements)
     */
    function List(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [name, value] = [positionalParams[1], positionalParams[2]];
        if (name && OvaleFrameModule.frame && OvaleFrameModule.frame.GetListValue(name) == value) {
            return [0, INFINITY];
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("list", false, List);
}
{
    /** Test whether the target's name matches the given name.
	 @name Name
	 @paramsig boolean
	 @param name The localized target name.
	 @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    function Name(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [name, yesno] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        if (type(name) == "number") {
            name = OvaleSpellBook.GetSpellName(name);
        }
        let targetName = UnitName(target);
        let boolean = (name == targetName);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("name", false, Name);
}
{
    /** Test if the game is on a PTR server
	 @name PTR
	 @paramsig number
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return 1 if it is a PTR realm, or 0 if it is a live realm.
	 @usage
	 if PTR() > 0 Spell(wacky_new_spell)
     */
    function PTR(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [, , , uiVersion] = GetBuildInfo();
        let value = (uiVersion > 70300) && 1 || 0;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("ptr", false, PTR);
}
{
    /** Get the persistent multiplier to the given aura if applied.
	 The persistent multiplier is snapshotted to the aura for its duration.
	 @name PersistentMultiplier
	 @paramsig number or boolean
	 @param id The aura ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The persistent multiplier.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff)
	     Spell(rake)
     */
    function PersistentMultiplier(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let value = OvaleFuture.GetDamageMultiplier(spellId, OvaleGUID.UnitGUID(target), atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("persistentmultiplier", false, PersistentMultiplier);
}
{
    /** Test if the pet exists and is alive.
	 PetPresent() is equivalent to pet.Present().
	 @name PetPresent
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @see Present
	 @usage
	 if target.IsInterruptible() and PetPresent(yes)
	     Spell(pet_pummel)
	 if PetPresent(name=Niuzao) 
	     Spell(provoke_pet)

     */
    function PetPresent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let name = namedParams.name;
        let target = "pet";
        let boolean = UnitExists(target) && !UnitIsDead(target) && (name == undefined || name == UnitName(target));
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("petpresent", false, PetPresent);
}
{
    /**  Return the maximum power of the given power type on the target.
	 */
    function MaxPower(powerType, positionalParams, namedParams, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value;
        if (target == "player") {
            value = OvalePower.current.maxPower[powerType];
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            value = UnitPowerMax(target, powerInfo.id, powerInfo.segments);
        }
        return Compare(value, comparator, limit);
    }
    /** Return the amount of power of the given power type on the target.
	 */
    function Power(powerType, positionalParams, namedParams, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let [value, origin, rate] = [OvalePower.next.power[powerType], atTime, OvalePower.next.GetPowerRate(powerType)];
            let [start, ending] = [atTime, INFINITY];
            return TestValue(start, ending, value, origin, rate, comparator, limit);
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let value = UnitPower(target, powerInfo.id);
            return Compare(value, comparator, limit);
        }
    }
    /**Return the current deficit of power from max power on the target.
	 */
    function PowerDeficit(powerType, positionalParams, namedParams, state: BaseState, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let powerMax = OvalePower.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                let [value, origin, rate] = [powerMax - OvalePower.next.power[powerType], atTime, -1 * OvalePower.next.GetPowerRate(powerType)];
                let [start, ending] = [atTime, INFINITY];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) || 0;
            if (powerMax > 0) {
                let power = UnitPower(target, powerInfo.id);
                let value = powerMax - power;
                return Compare(value, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }

    /**Return the current percent level of power (between 0 and 100) on the target.
     */
    function PowerPercent(powerType, positionalParams, namedParams, state: BaseState, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        if (target == "player") {
            let powerMax = OvalePower.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                let conversion = 100 / powerMax;
                let [value, origin, rate] = [OvalePower.next.power[powerType] * conversion, atTime, OvalePower.next.GetPowerRate(powerType) * conversion];
                if (rate > 0 && value >= 100 || rate < 0 && value == 0) {
                    rate = 0;
                }
                let [start, ending] = [atTime, INFINITY];
                return TestValue(start, ending, value, origin, rate, comparator, limit);
            }
        } else {
            let powerInfo = OvalePower.POWER_INFO[powerType];
            let powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) || 0;
            if (powerMax > 0) {
                let conversion = 100 / powerMax;
                let value = UnitPower(target, powerInfo.id) * conversion;
                return Compare(value, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }

    
    /**
     Get the current amount of alternate power displayed on the alternate power bar.
	 @name AlternatePower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current alternate power.
	 @return A boolean value for the result of the comparison.
     */
    function AlternatePower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("alternate", positionalParams, namedParams, state, atTime);
    }
    /** Get the current amount of astral power for balance druids.
	 @name AstralPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current runic power.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if AstraPower() >70 Spell(frost_strike)
	 if AstraPower(more 70) Spell(frost_strike)
     */
    function AstralPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("lunarpower", positionalParams, namedParams, state, atTime);
    }

    /**Get the current amount of stored Chi for monks.
	 @name Chi
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The amount of stored Chi.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Chi() ==4 Spell(chi_burst)
	 if Chi(more 3) Spell(chi_burst)
     */
    function Chi(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("chi", positionalParams, namedParams, state, atTime);
    }
    /**  Get the number of combo points for a feral druid or a rogue.
     @name ComboPoints
     @paramsig number or boolean
     @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
     @param number Optional. The number to compare against.
     @return The number of combo points.
     @return A boolean value for the result of the comparison.
     @usage
     if ComboPoints() >=1 Spell(savage_roar)
     */
    function ComboPoints(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("combopoints", positionalParams, namedParams, state, atTime);
    }
    /**Get the current amount of energy for feral druids, non-mistweaver monks, and rogues.
	 @name Energy
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current energy.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Energy() >70 Spell(vanish)
	 if Energy(more 70) Spell(vanish)
     */
    function Energy(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("energy", positionalParams, namedParams, state, atTime);
    }

    /**Get the current amount of focus for hunters.
	 @name Focus
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current focus.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Focus() >70 Spell(arcane_shot)
	 if Focus(more 70) Spell(arcane_shot)
     */
    function Focus(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("focus", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function Fury(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("fury", positionalParams, namedParams, state, atTime);
    }

    /** Get the current amount of holy power for a paladin.
	 @name HolyPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The amount of holy power.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if HolyPower() >=3 Spell(word_of_glory)
	 if HolyPower(more 2) Spell(word_of_glory)
     */
    function HolyPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("holypower", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function Insanity(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("insanity", positionalParams, namedParams, state, atTime);
    }

    /**  Get the current level of mana of the target.
	 @name Mana
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if {MaxMana() - Mana()} > 12500 Item(mana_gem)
        */
    function Mana(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("mana", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function Maelstrom(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("maelstrom", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function Pain(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("pain", positionalParams, namedParams, state, atTime);
    }

    /** Get the current amount of rage for guardian druids and warriors.
	 @name Rage
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current rage.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Rage() >70 Spell(heroic_strike)
	 if Rage(more 70) Spell(heroic_strike)
     */
    function Rage(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("rage", positionalParams, namedParams, state, atTime);
    }

    /** Get the current amount of runic power for death knights.
	 @name RunicPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current runic power.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if RunicPower() >70 Spell(frost_strike)
	 if RunicPower(more 70) Spell(frost_strike)
     */
    function RunicPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("runicpower", positionalParams, namedParams, state, atTime);
    }

    /** Get the current number of Shadow Orbs for shadow priests.
	 @name ShadowOrbs
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of Shadow Orbs.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ShadowOrbs() >2 Spell(mind_blast)
	 if ShadowOrbs(more 2) Spell(mind_blast)
     */
    function ShadowOrbs(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("shadoworbs", positionalParams, namedParams, state, atTime);
    }

    /** Get the current number of Soul Shards for warlocks.
	 @name SoulShards
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of Soul Shards.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if SoulShards() >0 Spell(summon_felhunter)
	 if SoulShards(more 0) Spell(summon_felhunter)
     */
    function SoulShards(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("soulshards", positionalParams, namedParams, state, atTime);
    }
    function ArcaneCharges(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Power("arcanecharges", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("alternatepower", false, AlternatePower);
    OvaleCondition.RegisterCondition("arcanecharges", false, ArcaneCharges);
    OvaleCondition.RegisterCondition("astralpower", false, AstralPower);
    OvaleCondition.RegisterCondition("chi", false, Chi);
    OvaleCondition.RegisterCondition("combopoints", false, ComboPoints);
    OvaleCondition.RegisterCondition("energy", false, Energy);
    OvaleCondition.RegisterCondition("focus", false, Focus);
    OvaleCondition.RegisterCondition("fury", false, Fury);
    OvaleCondition.RegisterCondition("holypower", false, HolyPower);
    OvaleCondition.RegisterCondition("insanity", false, Insanity);
    OvaleCondition.RegisterCondition("maelstrom", false, Maelstrom);
    OvaleCondition.RegisterCondition("mana", false, Mana);
    OvaleCondition.RegisterCondition("pain", false, Pain);
    OvaleCondition.RegisterCondition("rage", false, Rage);
    OvaleCondition.RegisterCondition("runicpower", false, RunicPower);
    OvaleCondition.RegisterCondition("shadoworbs", false, ShadowOrbs);
    OvaleCondition.RegisterCondition("soulshards", false, SoulShards);

    /** Get the number of lacking resource points for a full alternate power bar, between 0 and maximum alternate power, of the target.
	 @name AlternatePowerDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current alternate power deficit.
	 @return A boolean value for the result of the comparison.
     */
    function AlternatePowerDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("alternatepower", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	 @name AstralPowerDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current runic power deficit.
	 @return A boolean value for the result of the comparison.
     */
    function AstralPowerDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("astralpower", positionalParams, namedParams, state, atTime);
    }

    /**  Get the number of lacking resource points for full chi, between 0 and maximum chi, of the target.
	 @name ChiDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current chi deficit.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ChiDeficit() >=2 Spell(keg_smash)
	 if ChiDeficit(more 1) Spell(keg_smash)
     */
    function ChiDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("chi", positionalParams, namedParams, state, atTime);
    }
    /**
     * @name ComboPointsDeficit
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function ComboPointsDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("combopoints", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for a full energy bar, between 0 and maximum energy, of the target.
	 @name EnergyDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current energy deficit.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if EnergyDeficit() >60 Spell(tigers_fury)
	 if EnergyDeficit(more 60) Spell(tigers_fury)
     */
    function EnergyDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("energy", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for a full focus bar, between 0 and maximum focus, of the target.
	 @name FocusDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current focus deficit.
	 @return A boolean value for the result of the comparison.
     */
    function FocusDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("focus", positionalParams, namedParams, state, atTime);
    }
    function FuryDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("fury", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for full holy power, between 0 and maximum holy power, of the target.
	 @name HolyPowerDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current holy power deficit.
	 @return A boolean value for the result of the comparison.
     */
    function HolyPowerDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("holypower", positionalParams, namedParams, state, atTime);
    }

    /**  Get the number of lacking resource points for a full mana bar, between 0 and maximum mana, of the target.
	 @name ManaDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana deficit.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ManaDeficit() >30000 Item(mana_gem)
	 if ManaDeficit(more 30000) Item(mana_gem)
     */
    function ManaDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("mana", positionalParams, namedParams, state, atTime);
    }
    function PainDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("pain", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for a full rage bar, between 0 and maximum rage, of the target.
	 @name RageDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current rage deficit.
	 @return A boolean value for the result of the comparison.
     */
    function RageDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("rage", positionalParams, namedParams, state, atTime);
    }

    /** Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	 @name RunicPowerDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current runic power deficit.
	 @return A boolean value for the result of the comparison.
     */
    function RunicPowerDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("runicpower", positionalParams, namedParams, state, atTime);
    }
    /** Get the number of lacking resource points for full shadow orbs, between 0 and maximum shadow orbs, of the target.
	 @name ShadowOrbsDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current shadow orbs deficit.
	 @return A boolean value for the result of the comparison.
     */
    function ShadowOrbsDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("shadoworbs", positionalParams, namedParams, state, atTime);
    }

    /**  Get the number of lacking resource points for full soul shards, between 0 and maximum soul shards, of the target.
	 @name SoulShardsDeficit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current soul shards deficit.
	 @return A boolean value for the result of the comparison.
     */
    function SoulShardsDeficit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerDeficit("soulshards", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("alternatepowerdeficit", false, AlternatePowerDeficit);
    OvaleCondition.RegisterCondition("astralpowerdeficit", false, AstralPowerDeficit);
    OvaleCondition.RegisterCondition("chideficit", false, ChiDeficit);
    OvaleCondition.RegisterCondition("combopointsdeficit", false, ComboPointsDeficit);
    OvaleCondition.RegisterCondition("energydeficit", false, EnergyDeficit);
    OvaleCondition.RegisterCondition("focusdeficit", false, FocusDeficit);
    OvaleCondition.RegisterCondition("furydeficit", false, FuryDeficit);
    OvaleCondition.RegisterCondition("holypowerdeficit", false, HolyPowerDeficit);
    OvaleCondition.RegisterCondition("manadeficit", false, ManaDeficit);
    OvaleCondition.RegisterCondition("paindeficit", false, PainDeficit);
    OvaleCondition.RegisterCondition("ragedeficit", false, RageDeficit);
    OvaleCondition.RegisterCondition("runicpowerdeficit", false, RunicPowerDeficit);
    OvaleCondition.RegisterCondition("shadoworbsdeficit", false, ShadowOrbsDeficit);
    OvaleCondition.RegisterCondition("soulshardsdeficit", false, SoulShardsDeficit);

    /** Get the current percent level of mana (between 0 and 100) of the target.
	 @name ManaPercent
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana percent.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if ManaPercent() >90 Spell(arcane_blast)
	 if ManaPercent(more 90) Spell(arcane_blast)
     */
    function ManaPercent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerPercent("mana", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("manapercent", false, ManaPercent);

    /** Get the maximum amount of alternate power of the target.
	 Alternate power is the resource tracked by the alternate power bar in certain boss fights.
	 @name MaxAlternatePower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxAlternatePower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("alternate", positionalParams, namedParams, state, atTime);
    }
    function MaxChi(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("chi", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of Chi of the target.
	 @name MaxChi
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.

l    */
    function MaxComboPoints(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("combopoints", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of energy of the target.
	 @name MaxEnergy
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxEnergy(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("energy", positionalParams, namedParams, state, atTime);
    }

    /**  Get the maximum amount of focus of the target.
	 @name MaxFocus
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxFocus(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("focus", positionalParams, namedParams, state, atTime);
    }
    function MaxFury(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("fury", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of Holy Power of the target.
	 @name MaxHolyPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxHolyPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("holy", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of mana of the target.
	 @name MaxMana
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if {MaxMana() - Mana()} > 12500 Item(mana_gem)
     */
    function MaxMana(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("mana", positionalParams, namedParams, state, atTime);
    }
    function MaxPain(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("pain", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of rage of the target.
	 @name MaxRage
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxRage(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("rage", positionalParams, namedParams, state, atTime);
    }

    /**  Get the maximum amount of Runic Power of the target.
	 @name MaxRunicPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxRunicPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("runicpower", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of Shadow Orbs of the target.
	 @name MaxShadowOrbs
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxShadowOrbs(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("shadoworbs", positionalParams, namedParams, state, atTime);
    }

    /** Get the maximum amount of Soul Shards of the target.
	 @name MaxSoulShards
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @return A boolean value for the result of the comparison.
     */
    function MaxSoulShards(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return MaxPower("soulshards", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("maxalternatepower", false, MaxAlternatePower);
    OvaleCondition.RegisterCondition("maxchi", false, MaxChi);
    OvaleCondition.RegisterCondition("maxcombopoints", false, MaxComboPoints);
    OvaleCondition.RegisterCondition("maxenergy", false, MaxEnergy);
    OvaleCondition.RegisterCondition("maxfocus", false, MaxFocus);
    OvaleCondition.RegisterCondition("maxfury", false, MaxFury);
    OvaleCondition.RegisterCondition("maxholypower", false, MaxHolyPower);
    OvaleCondition.RegisterCondition("maxmana", false, MaxMana);
    OvaleCondition.RegisterCondition("maxpain", false, MaxPain);
    OvaleCondition.RegisterCondition("maxrage", false, MaxRage);
    OvaleCondition.RegisterCondition("maxrunicpower", false, MaxRunicPower);
    OvaleCondition.RegisterCondition("maxshadoworbs", false, MaxShadowOrbs);
    OvaleCondition.RegisterCondition("maxsoulshards", false, MaxSoulShards);
}
{
    /**  Return the amount of power of the given power type required to cast the given spell.
	 */
    function PowerCost(powerType, positionalParams, namedParams, state: BaseState, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let target = ParseCondition(positionalParams, namedParams, state, "target");
        let maxCost = (namedParams.max == 1);
        let value = OvalePower.PowerCost(spellId, powerType, atTime, target, maxCost) || 0;
        return Compare(value, comparator, limit);
    }

    /** Get the amount of energy required to cast the given spell.
	 This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	 @name EnergyCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param max Optional. Set max=1 to return the maximum energy cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of energy.
	 @return A boolean value for the result of the comparison.
     */
    function EnergyCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("energy", positionalParams, namedParams, state, atTime);
    }

    /** Get the amount of focus required to cast the given spell.
	 @name FocusCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param max Optional. Set max=1 to return the maximum focus cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of focus.
	 @return A boolean value for the result of the comparison.
     */
    function FocusCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("focus", positionalParams, namedParams, state, atTime);
    }

    /**  Get the amount of mana required to cast the given spell.
	 This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	 @name ManaCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param max Optional. Set max=1 to return the maximum mana cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of mana.
	 @return A boolean value for the result of the comparison.
     */
    function ManaCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("mana", positionalParams, namedParams, state, atTime);
    }

    /** Get the amount of rage required to cast the given spell.
	 @name RageCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param max Optional. Set max=1 to return the maximum rage cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of rage.
	 @return A boolean value for the result of the comparison.
     */
    function RageCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("rage", positionalParams, namedParams, state, atTime);
    }

    /** Get the amount of runic power required to cast the given spell.
	 @name RunicPowerCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param max Optional. Set max=1 to return the maximum runic power cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of runic power.
	 @return A boolean value for the result of the comparison.
     */
    function RunicPowerCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("runicpower", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function AstralPowerCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost("astralpower", positionalParams, namedParams, state, atTime);
    }

    /**
     * 
     * @param positionalParams 
     * @param namedParams 
     * @param state 
     * @param atTime 
     */
    function MainPowerCost(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return PowerCost(OvalePower.current.powerType, positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("powercost", true, MainPowerCost);
    OvaleCondition.RegisterCondition("astralpowercost", true, AstralPowerCost);
    OvaleCondition.RegisterCondition("energycost", true, EnergyCost);
    OvaleCondition.RegisterCondition("focuscost", true, FocusCost);
    OvaleCondition.RegisterCondition("manacost", true, ManaCost);
    OvaleCondition.RegisterCondition("ragecost", true, RageCost);
    OvaleCondition.RegisterCondition("runicpowercost", true, RunicPowerCost);
}
{
    /** Test if the target exists and is alive.
	 @name Present
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @see Exists
	 @usage
	 if target.IsInterruptible() and pet.Present(yes)
	     Spell(pet_pummel)
     */
    function Present(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitExists(target) && !UnitIsDead(target);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("present", false, Present);
}
{
    /** Test if the previous spell cast that invoked the GCD matches the given spell.
	 @name PreviousGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
     */
    function PreviousGCDSpell(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let count = namedParams.count;
        let boolean;
        if (count && count > 1) {
            boolean = (spellId == OvaleFuture.next.lastGCDSpellIds[lualength(OvaleFuture.next.lastGCDSpellIds) - count + 2]);
        } else {
            boolean = (spellId == OvaleFuture.next.lastGCDSpellId);
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousgcdspell", true, PreviousGCDSpell);
}
{
    /** Test if the previous spell cast that did not trigger the GCD matches the given spell.
	 @name PreviousOffGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
     */
    function PreviousOffGCDSpell(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (spellId == OvaleFuture.next.lastOffGCDSpellcast.spellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousoffgcdspell", true, PreviousOffGCDSpell);
}
{
    /**  Test if the previous spell cast matches the given spell.
	 @name PreviousSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
     */
    function PreviousSpell(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (spellId == OvaleFuture.next.lastGCDSpellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("previousspell", true, PreviousSpell);
}
{
    /**  Get the result of the target's level minus the player's level. This number may be negative.
	 @name RelativeLevel
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The difference in levels.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if target.RelativeLevel() >3
	     Texture(ability_rogue_sprint)
	 if target.RelativeLevel(more 3)
	     Texture(ability_rogue_sprint)
     */
    function RelativeLevel(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value, level;
        if (target == "player") {
            level = OvalePaperDoll.level;
        } else {
            level = UnitLevel(target);
        }
        if (level < 0) {
            value = 3;
        } else {
            value = level - OvalePaperDoll.level;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("relativelevel", false, RelativeLevel);
}
{
    function Refreshable(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let auraId = positionalParams[1];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let baseDuration = OvaleAura.GetBaseDuration(auraId);
            if (baseDuration === INFINITY) {
                baseDuration = aura.ending - aura.start;
            }
            let extensionDuration = 0.3 * baseDuration;
            OvaleAura.Log("ending = %s extensionDuration = %s", aura.ending, extensionDuration);
            return [aura.ending - extensionDuration, INFINITY];
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("refreshable", false, Refreshable);
    OvaleCondition.RegisterCondition("debuffrefreshable", false, Refreshable);
    OvaleCondition.RegisterCondition("buffrefreshable", false, Refreshable);
}
{
    /** Get the remaining cast time in seconds of the target's current spell cast.
	 @name RemainingCastTime
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see CastTime
	 @usage
	 if target.Casting(hour_of_twilight) and target.RemainingCastTime() <2
	     Spell(cloak_of_shadows)
     */
    function RemainingCastTime(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let [, , , startTime, endTime] = UnitCastingInfo(target);
        if (startTime && endTime) {
            startTime = startTime / 1000;
            endTime = endTime / 1000;
            return TestValue(startTime, endTime, 0, endTime, -1, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("remainingcasttime", false, RemainingCastTime);
}
{
    /**  Get the current number of active and regenerating (fractional) runes of the given type for death knights.
	 @name Rune
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of runes.
	 @return A boolean value for the result of the comparison.
	 @see RuneCount
	 @usage
	 if Rune() > 1 Spell(blood_tap)
     */
    function Rune(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [count, startCooldown, endCooldown] = OvaleRunes.RuneCount(atTime);
        if (startCooldown < INFINITY) {
            let origin = startCooldown;
            let rate = 1 / (endCooldown - startCooldown);
            let [start, ending] = [startCooldown, INFINITY];
            return TestValue(start, ending, count, origin, rate, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }

    /**  Get the current number of active runes of the given type for death knights.
	 @name RuneCount
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param death Optional. Set death=1 to include all active death runes in the count. Set death=0 to exclude all death runes.
	     Defaults to unset.
	     Valid values: unset, 0, 1
	 @return The number of runes.
	 @return A boolean value for the result of the comparison.
	 @see Rune
	 @usage
	 if RuneCount() ==2
	     Spell(obliterate)
     */
    function RuneCount(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [count, startCooldown, endCooldown] = OvaleRunes.RuneCount(atTime);
        if (startCooldown < INFINITY) {
            let [start, ending] = [startCooldown, endCooldown];
            return TestValue(start, ending, count, start, 0, comparator, limit);
        }
        return Compare(count, comparator, limit);
    }

    /**  Get the number of seconds before the player reaches the given amount of runes.
	 @name TimeToRunes
	 @paramsig number or boolean
	 @param runes. The amount of runes to reach.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeToRunes(2) > 5 Spell(horn_of_winter)
     */
    function TimeToRunes(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [runes, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let seconds = OvaleRunes.GetRunesCooldown(atTime, runes);
        if (seconds < 0) {
            seconds = 0;
        }
        return Compare(seconds, comparator, limit);
    }
    OvaleCondition.RegisterCondition("rune", false, Rune);
    OvaleCondition.RegisterCondition("runecount", false, RuneCount);
    OvaleCondition.RegisterCondition("timetorunes", false, TimeToRunes);
}
{
    /**  Returns the value of the given snapshot stat.
	 */
    function Snapshot(statName, defaultValue, positionalParams, namedParams, state: BaseState, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvalePaperDoll[statName] || defaultValue;
        return Compare(value, comparator, limit);
    }

    /**  Returns the critical strike chance of the given snapshot stat.
	 */
    function SnapshotCritChance(statName, defaultValue, positionalParams, namedParams, state: BaseState, atTime) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvalePaperDoll[statName] || defaultValue;
        if (namedParams.unlimited != 1 && value > 100) {
            value = 100;
        }
        return Compare(value, comparator, limit);
    }

    /** Get the current agility of the player.
	 @name Agility
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current agility.
	 @return A boolean value for the result of the comparison.
     */
    function Agility(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("agility", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current attack power of the player.
	 @name AttackPower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current attack power.
	 @return A boolean value for the result of the comparison.
     */
    function AttackPower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("attackPower", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current critical strike rating of the player.
	 @name CritRating
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current critical strike rating.
	 @return A boolean value for the result of the comparison.
     */
    function CritRating(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("critRating", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current haste rating of the player.
	 @name HasteRating
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current haste rating.
	 @return A boolean value for the result of the comparison.
     */
    function HasteRating(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("hasteRating", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current intellect of the player.
	 @name Intellect
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current intellect.
	 @return A boolean value for the result of the comparison.
     */
    function Intellect(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("intellect", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current mastery effect of the player.
	 Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
	 or a percent-increase to chance to trigger some effect.
	 @name MasteryEffect
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current mastery effect.
	 @return A boolean value for the result of the comparison.
     */
    function MasteryEffect(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("masteryEffect", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current mastery rating of the player.
	 @name MasteryRating
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current mastery rating.
	 @return A boolean value for the result of the comparison.
     */
    function MasteryRating(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("masteryRating", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current melee critical strike chance of the player.
	 @name MeleeCritChance
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
	 @return A boolean value for the result of the comparison.
     */
    function MeleeCritChance(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, state, atTime);
    }

    /**  Get the current percent increase to melee haste of the player.
	 @name MeleeHaste
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current percent increase to melee haste.
	 @return A boolean value for the result of the comparison.
     */
    function MeleeHaste(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("meleeHaste", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current ranged critical strike chance of the player.
	 @name RangedCritChance
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
	 @return A boolean value for the result of the comparison.
     */
    function RangedCritChance(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, state, atTime);
    }

    /**  Get the current spell critical strike chance of the player.
	 @name SpellCritChance
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
	 @return A boolean value for the result of the comparison.
     */
    function SpellCritChance(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, state, atTime);
    }

    /**  Get the current percent increase to spell haste of the player.
	 @name SpellHaste
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current percent increase to spell haste.
	 @return A boolean value for the result of the comparison.
     */
    function SpellHaste(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("spellHaste", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current spellpower of the player.
	 @name Spellpower
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current spellpower.
	 @return A boolean value for the result of the comparison.
     */
    function Spellpower(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("spellPower", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current spirit of the player.
	 @name Spirit
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current spirit.
	 @return A boolean value for the result of the comparison.
     */
    function Spirit(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("spirit", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current stamina of the player.
	 @name Stamina
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current stamina.
	 @return A boolean value for the result of the comparison.
     */
    function Stamina(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("stamina", 0, positionalParams, namedParams, state, atTime);
    }

    /** Get the current strength of the player.
	 @name Strength
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The current strength.
	 @return A boolean value for the result of the comparison.
     */
    function Strength(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("strength", 0, positionalParams, namedParams, state, atTime);
    }

    function Versatility(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("versatility", 0, positionalParams, namedParams, state, atTime);
    }

    function VersatilityRating(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return Snapshot("versatilityRating", 0, positionalParams, namedParams, state, atTime);
    }

    OvaleCondition.RegisterCondition("agility", false, Agility);
    OvaleCondition.RegisterCondition("attackpower", false, AttackPower);
    OvaleCondition.RegisterCondition("critrating", false, CritRating);
    OvaleCondition.RegisterCondition("hasterating", false, HasteRating);
    OvaleCondition.RegisterCondition("intellect", false, Intellect);
    OvaleCondition.RegisterCondition("mastery", false, MasteryEffect);
    OvaleCondition.RegisterCondition("masteryeffect", false, MasteryEffect);
    OvaleCondition.RegisterCondition("masteryrating", false, MasteryRating);
    OvaleCondition.RegisterCondition("meleecritchance", false, MeleeCritChance);
    OvaleCondition.RegisterCondition("meleehaste", false, MeleeHaste);
    OvaleCondition.RegisterCondition("rangedcritchance", false, RangedCritChance);
    OvaleCondition.RegisterCondition("spellcritchance", false, SpellCritChance);
    OvaleCondition.RegisterCondition("spellhaste", false, SpellHaste);
    OvaleCondition.RegisterCondition("spellpower", false, Spellpower);
    OvaleCondition.RegisterCondition("spirit", false, Spirit);
    OvaleCondition.RegisterCondition("stamina", false, Stamina);
    OvaleCondition.RegisterCondition("strength", false, Strength);
    OvaleCondition.RegisterCondition("versatility", false, Versatility);
    OvaleCondition.RegisterCondition("versatilityRating", false, VersatilityRating);
}
{
    /** Get the current speed of the target.
	 If the target is not moving, then this condition returns 0 (zero).
	 If the target is at running speed, then this condition returns 100.
	 @name Speed
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The speed of the target.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Speed(more 0) and not BuffPresent(aspect_of_the_fox)
	     Spell(aspect_of_the_fox)
     */
    function Speed(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let value = GetUnitSpeed(target) * 100 / 7;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("speed", false, Speed);
}
{
    /** Get the cooldown in seconds on a spell before it gains another charge.
	 @name SpellChargeCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see SpellCharges
	 @usage
	 if SpellChargeCooldown(roll) <2
	     Spell(roll usable=1)
     */
    function SpellChargeCooldown(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [charges, maxCharges, start, duration] = OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            return TestValue(start, start + duration, duration, start, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellchargecooldown", true, SpellChargeCooldown);
}
{
    /** Get the number of charges of the spell.
	 @name SpellCharges
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param count Optional. Sets whether a count or a fractional value is returned.
	     Defaults to count=1.
	     Valid values: 0, 1.
	 @return The number of charges.
	 @return A boolean value for the result of the comparison.
	 @see SpellChargeCooldown
	 @usage
	 if SpellCharges(savage_defense) >1
	     Spell(savage_defense)
     */
    function SpellCharges(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [charges, maxCharges, start, duration] = OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (!charges) {
            return undefined;
        }
        charges = charges || 0;
        maxCharges = maxCharges || 1;
        if (namedParams.count == 0 && charges < maxCharges) {
            return TestValue(atTime, INFINITY, charges + 1, start + duration, 1 / duration, comparator, limit);
        }
        return Compare(charges, comparator, limit);
    }
    OvaleCondition.RegisterCondition("charges", true, SpellCharges);
    OvaleCondition.RegisterCondition("spellcharges", true, SpellCharges);
}

{
	/** Get the number of seconds for a full recharge of the spell.
	* @name SpellFullRecharge
	* @paramsig number or boolean
	* @param id The spell ID.
	* @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	* @param number Optional. The number to compare against.
	* @usage
	* if SpellFullRecharge(dire_frenzy) < GCD()
	*     Spell(dire_frenzy) */
    function SpellFullRecharge(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        const spellId = positionalParams[1];
        const comparator = positionalParams[2];
        const limit = positionalParams[3];
        const [charges, maxCharges, start, dur] = OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            const duration = (maxCharges - charges) * dur;
            const ending = start + duration;
            return TestValue(start, ending, ending - start, start, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }

    OvaleCondition.RegisterCondition("spellfullrecharge", true, SpellFullRecharge)
}

{
    /** Get the number of seconds before any of the listed spells are ready for use.
	 @name SpellCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param ... Optional. Additional spell IDs.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TimeToSpell
	 @usage
	 if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
	     Spell(devouring_plague)
     */
    function SpellCooldown(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let comparator, limit;
        let usable = (namedParams.usable == 1);
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let earliest = INFINITY;
        for (const [i, spellId] of ipairs<number>(positionalParams)) {
            if (OvaleCondition.COMPARATOR[spellId]) {
                [comparator, limit] = [spellId, positionalParams[i + 1]];
                break;
            } else if (!usable || OvaleSpells.IsUsableSpell(spellId, atTime, OvaleGUID.UnitGUID(target))) {
                let [start, duration] = OvaleCooldown.GetSpellCooldown(spellId, atTime);
                let t = 0;
                if (start > 0 && duration > 0) {
                    t = start + duration;
                }
                if (earliest > t) {
                    earliest = t;
                }
            }
        }
        if (earliest == INFINITY) {
            return Compare(0, comparator, limit);
        } else if (earliest > 0) {
            return TestValue(0, earliest, 0, earliest, -1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcooldown", true, SpellCooldown);
}
{
    /** Get the cooldown duration in seconds for a given spell.
	 @name SpellCooldownDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function SpellCooldownDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let duration = OvaleCooldown.GetSpellCooldownDuration(spellId, atTime, target);
        return Compare(duration, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcooldownduration", true, SpellCooldownDuration);
}
{
    /** Get the recharge duration in seconds for a given spell.
	 @name SpellRechargeDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function SpellRechargeDuration(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let cd = OvaleCooldown.GetCD(spellId, atTime);
        let duration = cd.chargeDuration || OvaleCooldown.GetSpellCooldownDuration(spellId, atTime, target);
        return Compare(duration, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellrechargeduration", true, SpellRechargeDuration);
}
{
    /** Get data for the given spell defined by SpellInfo(...)
	 @name SpellData
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param key The name of the data set by SpellInfo(...).
	     Valid values are any alphanumeric string.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number data associated with the given key.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if BuffRemaining(slice_and_dice) >= SpellData(shadow_blades duration)
	     Spell(shadow_blades)
     */
    function SpellData(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, key, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]];
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            let value = si[key];
            if (value) {
                return Compare(value, comparator, limit);
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("spelldata", false, SpellData);
}
{
    /** Get data for the given spell defined by SpellInfo(...) after calculations
	 @name SpellInfoProperty
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param key The name of the data set by SpellInfo(...).
	     Valid values are any alphanumeric string.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number data associated with the given key after calculations
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Insanity() + SpellInfoProperty(mind_blast insanity) < 100
	     Spell(mind_blast)
     */
    function SpellInfoProperty(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, key, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]];
        let value = OvaleData.GetSpellInfoProperty(spellId, atTime, key, undefined);
        if (value) {
            return Compare(value, comparator, limit);
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("spellinfoproperty", false, SpellInfoProperty);
}
{
    /** Returns the number of times a spell can be cast. Generally used for spells whose casting is limited by the number of item reagents in the player's possession. .
	 @name SpellCount
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of times a spell can be cast.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if SpellCount(expel_harm) > 1
         Spell(expel_harm)  
     */
    function SpellCount(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let spellCount = OvaleSpells.GetSpellCount(spellId);
        return Compare(spellCount, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellcount", true, SpellCount);
}
{
    /** Test if the given spell is in the spellbook.
	 A spell is known if the player has learned the spell and it is in the spellbook.
	 @name SpellKnown
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if the spell has been learned.
	     If no, then return true if the player hasn't learned the spell.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @see SpellUsable
     */
    function SpellKnown(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = OvaleSpellBook.IsKnownSpell(spellId);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("spellknown", true, SpellKnown);
}
{
    /** Get the maximum number of charges of the spell.
	 @name SpellMaxCharges
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param count Optional. Sets whether a count or a fractional value is returned.
	     Defaults to count=1.
	     Valid values: 0, 1.
	 @return The number of charges.
	 @return A boolean value for the result of the comparison.
	 @see SpellChargeCooldown
	 @usage
	 if SpellCharges(savage_defense) >1
	     Spell(savage_defense)
     */
    function SpellMaxCharges(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [, maxCharges, ,] = OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (!maxCharges) {
            return undefined;
        }
        maxCharges = maxCharges || 1;
        return Compare(maxCharges, comparator, limit);
    }
    OvaleCondition.RegisterCondition("spellmaxcharges", true, SpellMaxCharges);
}
{
    /** Test if the given spell is usable.
	 A spell is usable if the player has learned the spell and meets any requirements for casting the spell.
	 Does not account for spell cooldowns or having enough of a primary (pooled) resource.
	 @name SpellUsable
	 @paramsig boolean
	 @param id The spell ID.
	 @param yesno Optional. If yes, then return true if the spell is usable. If no, then return true if it isn't usable.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @see SpellKnown
     */
    function SpellUsable(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let [isUsable, noMana] = OvaleSpells.IsUsableSpell(spellId, atTime, OvaleGUID.UnitGUID(target));
        let boolean = isUsable || noMana;
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("spellusable", true, SpellUsable);
}
{
    let LIGHT_STAGGER = 124275;
    let MODERATE_STAGGER = 124274;
    let HEAVY_STAGGER = 124273;

    /** Get the remaining amount of damage Stagger will cause to the target.
	 @name StaggerRemaining
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The amount of damage.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if StaggerRemaining() / MaxHealth() >0.4 Spell(purifying_brew)
     */
    function StaggerRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, HEAVY_STAGGER, atTime, "HARMFUL");
        if (!OvaleAura.IsActiveAura(aura, atTime)) {
            aura = OvaleAura.GetAura(target, MODERATE_STAGGER, atTime, "HARMFUL");
        }
        if (!OvaleAura.IsActiveAura(aura, atTime)) {
            aura = OvaleAura.GetAura(target, LIGHT_STAGGER, atTime, "HARMFUL");
        }
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let stagger = UnitStagger(target);
            let rate = -1 * stagger / (ending - start);
            return TestValue(gain, ending, 0, ending, rate, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("staggerremaining", false, StaggerRemaining);
    OvaleCondition.RegisterCondition("staggerremains", false, StaggerRemaining);
}
{
    /** Test if the player is in a given stance.
	 @name Stance
	 @paramsig boolean
	 @param stance The stance name or a number representing the stance index.
	 @param yesno Optional. If yes, then return true if the player is in the given stance. If no, then return true otherwise.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 unless Stance(druid_bear_form) Spell(bear_form)
     */
    function Stance(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [stance, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = OvaleStance.IsStance(stance, atTime);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("stance", false, Stance);
}
{
    /** Test if the player is currently stealthed.
	 The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
	 @name Stealthed
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if stealthed. If no, then return true if it not stealthed.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if Stealthed() or BuffPresent(shadow_dance)
	     Spell(ambush)
     */
    function Stealthed(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let boolean = OvaleAura.GetAura("player", "stealthed_buff") !== undefined || IsStealthed();
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("isstealthed", false, Stealthed);
    OvaleCondition.RegisterCondition("stealthed", false, Stealthed);
}
{
    /** Get the time elapsed in seconds since the player's previous melee swing (white attack).
	 @name LastSwing
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon's melee swing.
	     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
	     Valid values: main, off.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see NextSwing
     */
    function LastSwing(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let swing = positionalParams[1];
        let comparator, limit;
        let start;
        if (swing && swing == "main" || swing == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            start = 0;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            start = 0;
        }
        Ovale.OneTimeMessage("Warning: 'LastSwing()' is not implemented.");
        return TestValue(start, INFINITY, 0, start, 1, comparator, limit);
    }

    /** Get the time in seconds until the player's next melee swing (white attack).
	 @name NextSwing
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon's melee swing.
	     If no hand is specified, then return the time until the next swing of either hand's weapon.
	     Valid values: main, off.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds
	 @return A boolean value for the result of the comparison.
	 @see LastSwing
     */
    function NextSwing(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let swing = positionalParams[1];
        let comparator, limit;
        let ending;
        if (swing && swing == "main" || swing == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            ending = 0;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            ending = 0;
        }
        Ovale.OneTimeMessage("Warning: 'NextSwing()' is not implemented.");
        return TestValue(0, ending, 0, ending, -1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("lastswing", false, LastSwing);
    OvaleCondition.RegisterCondition("nextswing", false, NextSwing);
}
{
    /** Test if the given talent is active.
	 @name Talent
	 @paramsig boolean
	 @param id The talent ID.
	 @param yesno Optional. If yes, then return true if the talent is active. If no, then return true if it isn't active.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if Talent(blood_tap_talent) Spell(blood_tap)
     */
    function Talent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [talentId, yesno] = [positionalParams[1], positionalParams[2]];
        let boolean = (OvaleSpellBook.GetTalentPoints(talentId) > 0);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("talent", false, Talent);
    OvaleCondition.RegisterCondition("hastalent", false, Talent);
}
{
    /** Get the number of points spent in a talent (0 or 1)
	 @name TalentPoints
	 @paramsig number or boolean
	 @param talent Talent to inspect.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of talent points.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TalentPoints(blood_tap_talent) Spell(blood_tap)
     */
    function TalentPoints(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [talent, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = OvaleSpellBook.GetTalentPoints(talent);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("talentpoints", false, TalentPoints);
}
{
    /** Test if the player is the in-game target of the target.
	 @name TargetIsPlayer
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	     Default is yes.
	     Valid values: yes, no.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.TargetIsPlayer() Spell(feign_death)
     */
    function TargetIsPlayer(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let yesno = positionalParams[1];
        let [target] = ParseCondition(positionalParams, namedParams, state);
        let boolean = UnitIsUnit("player", `${target}target`);
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("istargetingplayer", false, TargetIsPlayer);
    OvaleCondition.RegisterCondition("targetisplayer", false, TargetIsPlayer);
}
{
    /** Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
	 This is a number between 0 (no threat) and 100 (will become the primary aggro target).
	 @name Threat
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of threat.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if Threat() >90 Spell(fade)
	 if Threat(more 90) Spell(fade)
     */
    function Threat(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let [, , value] = UnitDetailedThreatSituation("player", target);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("threat", false, Threat);
}
{
    /** Get the number of seconds between ticks of a periodic aura on a target.
	 @name TickTime
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param filter Optional. The type of aura to check.
	     Default is any.
	     Valid values: any, buff, debuff
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TicksRemaining
     */
    function TickTime(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        let tickTime;
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            tickTime = aura.tick;
        } else {
            tickTime = OvaleAura.GetTickLength(auraId, OvalePaperDoll.next);
        }
        if (tickTime && tickTime > 0) {
            return Compare(tickTime, comparator, limit);
        }
        return Compare(INFINITY, comparator, limit);
    }
    OvaleCondition.RegisterCondition("ticktime", false, TickTime);
}
{
    /** Get the remaining number of ticks of a periodic aura on a target.
	 @name TicksRemaining
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param filter Optional. The type of aura to check.
	     Default is any.
	     Valid values: any, buff, debuff
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of ticks.
	 @return A boolean value for the result of the comparison.
	 @see TickTime
	 @usage
	 if target.TicksRemaining(shadow_word_pain) <2
	     Spell(shadow_word_pain)
     */
    function TicksRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let [gain, , ending, tick] = [aura.gain, aura.start, aura.ending, aura.tick];
            if (tick && tick > 0) {
                return TestValue(gain, INFINITY, 1, ending, -1 / tick, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }

    /** Gets the remaining time until the next tick */
    function TickTimeRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [auraId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target, filter, mine] = ParseCondition(positionalParams, namedParams, state);
        let aura = OvaleAura.GetAura(target, auraId, atTime, filter, mine);
        if (OvaleAura.IsActiveAura(aura, atTime)) {
            const lastTickTime = aura.lastTickTime || aura.start;
            const tick = aura.tick || OvaleAura.GetTickLength(auraId, OvalePaperDoll.next);
            let remainingTime = tick - (atTime - lastTickTime);
            if (remainingTime && remainingTime > 0) {
                return Compare(remainingTime, comparator, limit);
            }
        }
        return undefined;
    }

    OvaleCondition.RegisterCondition("ticksremaining", false, TicksRemaining);
    OvaleCondition.RegisterCondition("ticksremain", false, TicksRemaining);
    OvaleCondition.RegisterCondition("ticktimeremaining", false, TickTimeRemaining);
}
{
    /** Get the number of seconds elapsed since the player entered combat.
	 @name TimeInCombat
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeInCombat(more 5) Spell(bloodlust)
     */
    function TimeInCombat(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        if (baseState.next.inCombat) {
            let start = baseState.next.combatStartTime;
            return TestValue(start, INFINITY, 0, start, 1, comparator, limit);
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timeincombat", false, TimeInCombat);
}
{
    /** Get the number of seconds elapsed since the player cast the given spell.
	 @name TimeSincePreviousSpell
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
     */
    function TimeSincePreviousSpell(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let t = OvaleFuture.TimeOfLastCast(spellId, atTime);
        return TestValue(0, INFINITY, 0, t, 1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timesincepreviousspell", false, TimeSincePreviousSpell);
}
{
    /** Get the time in seconds until the next scheduled Bloodlust cast.
	 Not implemented, always returns 3600 seconds.
	 @name TimeToBloodlust
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function TimeToBloodlust(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 3600;
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetobloodlust", false, TimeToBloodlust);
}
{
    function TimeToEclipse(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let value = 3600 * 24 * 7;
        Ovale.OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.");
        return TestValue(0, INFINITY, value, atTime, -1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetoeclipse", false, TimeToEclipse);
}
{
    /** Get the number of seconds before the player reaches the given power level.
	*/
    function TimeToPower(powerType, level, comparator, limit, state: BaseState, atTime) {
        level = level || 0;
        let power = OvalePower.next.power[powerType] || 0;
        let powerRegen = OvalePower.next.GetPowerRate(powerType) || 1;
        if (powerRegen == 0) {
            if (power == level) {
                return Compare(0, comparator, limit);
            }
            return Compare(INFINITY, comparator, limit);
        } else {
            let t = (level - power) / powerRegen;
            if (t > 0) {
                let ending = atTime + t;
                return TestValue(0, ending, 0, ending, -1, comparator, limit);
            }
            return Compare(0, comparator, limit);
        }
    }

    /** Get the number of seconds before the player reaches the given energy level for feral druids, non-mistweaver monks and rogues.
	 @name TimeToEnergy
	 @paramsig number or boolean
	 @param level. The level of energy to reach.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @see TimeToEnergyFor, TimeToMaxEnergy
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeToEnergy(100) < 1.2 Spell(sinister_strike)
     */
    function TimeToEnergy(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [level, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        return TimeToPower("energy", level, comparator, limit, state, atTime);
    }

    /** Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	 @name TimeToMaxEnergy
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @see TimeToEnergy, TimeToEnergyFor
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)
     */
    function TimeToMaxEnergy(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let powerType = "energy";
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let level = OvalePower.current.maxPower[powerType] || 0;
        return TimeToPower(powerType, level, comparator, limit, state, atTime);
    }

    /** Get the number of seconds before the player reaches the given focus level for hunters.
	 @name TimeToFocus
	 @paramsig number or boolean
	 @param level. The level of focus to reach.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @see TimeToFocusFor, TimeToMaxFocus
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeToFocus(100) < 1.2 Spell(cobra_shot)
     */
    function TimeToFocus(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [level, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        return TimeToPower("focus", level, comparator, limit, state, atTime);
    }

    /** Get the number of seconds before the player reaches maximum focus for hunters.
	 @name TimeToMaxFocus
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @see TimeToFocus, TimeToFocusFor
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeToMaxFocus() < 1.2 Spell(cobra_shot)
     */
    function TimeToMaxFocus(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let powerType = "focus";
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let level = OvalePower.current.maxPower[powerType] || 0;
        return TimeToPower(powerType, level, comparator, limit, state, atTime);
    }
    OvaleCondition.RegisterCondition("timetoenergy", false, TimeToEnergy);
    OvaleCondition.RegisterCondition("timetofocus", false, TimeToFocus);
    OvaleCondition.RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy);
    OvaleCondition.RegisterCondition("timetomaxfocus", false, TimeToMaxFocus);
}
{
    function TimeToPowerFor(powerType, positionalParams, namedParams, state: BaseState, atTime) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        if (!powerType) {
            let [, pt] = OvalePower.GetSpellCost(spellId);
            powerType = pt;
        }
        let seconds = OvalePower.TimeToPower(spellId, atTime, OvaleGUID.UnitGUID(target), powerType);
        if (seconds == 0) {
            return Compare(0, comparator, limit);
        } else if (seconds < INFINITY) {
            return TestValue(0, atTime + seconds, seconds, atTime, -1, comparator, limit);
        } else {
            return Compare(INFINITY, comparator, limit);
        }
    }
    /** Get the number of seconds before the player has enough energy to cast the given spell.
	 @name TimeToEnergyFor
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TimeToEnergyFor, TimeToMaxEnergy
     */
    function TimeToEnergyFor(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return TimeToPowerFor("energy", positionalParams, namedParams, state, atTime);
    }

    /**  Get the number of seconds before the player has enough focus to cast the given spell.
	 @name TimeToFocusFor
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TimeToFocusFor
     */
    function TimeToFocusFor(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return TimeToPowerFor("focus", positionalParams, namedParams, state, atTime);
    }
    OvaleCondition.RegisterCondition("timetoenergyfor", true, TimeToEnergyFor);
    OvaleCondition.RegisterCondition("timetofocusfor", true, TimeToFocusFor);
}
{
    /** Get the number of seconds before the spell is ready to be cast, either due to cooldown or resources.
	 @name TimeToSpell
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    function TimeToSpell(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        /*
        let [target] = ParseCondition(positionalParams, namedParams, state, "target");
        let seconds = OvaleSpells.GetTimeToSpell(spellId, atTime, OvaleGUID.UnitGUID(target));
        if (seconds == 0) {
            return Compare(0, comparator, limit);
        } else if (seconds < INFINITY) {
            return TestValue(0, atTime + seconds, seconds, atTime, -1, comparator, limit);
        } else {
            return Compare(INFINITY, comparator, limit);
        }
        */
        Ovale.OneTimeMessage("Warning: 'TimeToSpell()' is not implemented.");
        return TestValue(0, INFINITY, 0, atTime, -1, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timetospell", true, TimeToSpell);
}
{
    /** Get the time scaled by the specified haste type, defaulting to spell haste.
	 For example, if a DoT normally ticks every 3 seconds and is scaled by spell haste, then it ticks every TimeWithHaste(3 haste=spell) seconds.
	 @name TimeWithHaste
	 @paramsig number or boolean
	 @param time The time in seconds.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param haste Optional. Sets whether "time" should be lengthened or shortened due to haste.
	     Defaults to haste=spell.
	     Valid values: melee, spell.
	 @return The time in seconds scaled by haste.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if target.DebuffRemaining(flame_shock) < TimeWithHaste(3)
	     Spell(flame_shock)
     */
    function TimeWithHaste(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [seconds, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        let haste = namedParams.haste || "spell";
        let value = GetHastedTime(seconds, haste, state);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("timewithhaste", false, TimeWithHaste);
}
{
    /** Test if the totem has expired.
	 @name TotemExpires
	 @paramsig boolean
	 @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	 @param seconds Optional. The maximum number of seconds before the totem should expire.
	     Defaults to 0 (zero).
	 @return A boolean value.
	 @see TotemPresent, TotemRemaining
	 @usage
	 if TotemExpires(fire) Spell(searing_totem)
	 if TotemPresent(healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)
     */
    function TotemExpires(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [id, seconds] = [positionalParams[1], positionalParams[2]];
        seconds = seconds || 0;
        if (type(id) == "string") {
            let [, , startTime, duration] = OvaleTotem.GetTotemInfo(id);
            if (startTime) {
                return [startTime + duration - seconds, INFINITY];
            }
        } else {
            let [count, , ending] = OvaleTotem.GetTotemCount(id, atTime);
            if (count > 0) {
                return [ending - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }

    /** Test if the totem is present.
	 @name TotemPresent
	 @paramsig boolean
	 @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	 @return A boolean value.
	 @see TotemExpires, TotemRemaining
	 @usage
	 if not TotemPresent(fire) Spell(searing_totem)
	 if TotemPresent(healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)
     */
    function TotemPresent(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let id = positionalParams[1];
        if (type(id) == "string") {
            let [, , startTime, duration] = OvaleTotem.GetTotemInfo(id);
            if (startTime && duration > 0) {
                return [startTime, startTime + duration];
            }
        } else {
            let [count, start, ending] = OvaleTotem.GetTotemCount(id, atTime);
            if (count > 0) {
                return [start, ending];
            }
        }
        return undefined;
    }
    OvaleCondition.RegisterCondition("totemexpires", false, TotemExpires);
    OvaleCondition.RegisterCondition("totempresent", false, TotemPresent);

    /** Get the remaining time in seconds before a totem expires.
	 @name TotemRemaining
	 @paramsig number or boolean
	 @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @see TotemExpires, TotemPresent
	 @usage
	 if TotemRemaining(healing_stream_totem) <2 Spell(totemic_recall)
     */
    function TotemRemaining(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [id, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        if (type(id) == "string") {
            let [, , startTime, duration] = OvaleTotem.GetTotemInfo(id);
            if (startTime && duration > 0) {
                let [start, ending] = [startTime, startTime + duration];
                return TestValue(start, ending, 0, ending, -1, comparator, limit);
            }
        } else {
            let [count, start, ending] = OvaleTotem.GetTotemCount(id, atTime);
            if (count > 0) {
                return TestValue(start, ending, 0, ending, -1, comparator, limit);
            }
        }
        return Compare(0, comparator, limit);
    }
    OvaleCondition.RegisterCondition("totemremaining", false, TotemRemaining);
    OvaleCondition.RegisterCondition("totemremains", false, TotemRemaining);
}
{
    /** Check if a tracking is enabled
	@param spellId the spell id
	@return bool
     */
    function Tracking(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, yesno] = [positionalParams[1], positionalParams[2]];
        let spellName = OvaleSpellBook.GetSpellName(spellId);
        let numTrackingTypes = GetNumTrackingTypes();
        let boolean = false;
        for (let i = 1; i <= numTrackingTypes; i += 1) {
            let [name, , active] = GetTrackingInfo(i);
            if (name && name == spellName) {
                boolean = (active == 1);
                break;
            }
        }
        return TestBoolean(boolean, yesno);
    }
    OvaleCondition.RegisterCondition("tracking", false, Tracking);
}
{
    /** The travel time of a spell to the target in seconds.
	 This is a fixed guess at 0s or the travel time of the spell in the spell information if given.
	 @name TravelTime
	 @paramsig number or boolean
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if target.DebuffPresent(shadowflame_debuff) < TravelTime(hand_of_guldan) + GCD()
	     Spell(hand_of_guldan)
     */
    function TravelTime(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [spellId, comparator, limit] = [positionalParams[1], positionalParams[2], positionalParams[3]];
        //let target = ParseCondition(positionalParams, namedParams, state, "target");
        let si = spellId && OvaleData.spellInfo[spellId];
        let travelTime = 0;
        if (si) {
            travelTime = si.travel_time || si.max_travel_time || 0;
        }
        if (travelTime > 0) {
            let estimatedTravelTime = 1;
            if (travelTime < estimatedTravelTime) {
                travelTime = estimatedTravelTime;
            }
        }
        return Compare(travelTime, comparator, limit);
    }
    OvaleCondition.RegisterCondition("traveltime", true, TravelTime);
    OvaleCondition.RegisterCondition("maxtraveltime", true, TravelTime);
}
{
    /**  A condition that always returns true.
	 @name True
	 @paramsig boolean
	 @return A boolean value.
     */
    function True(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("true", false, True);
}
{
    /** The weapon DPS of the weapon in the given hand.
	 @name WeaponDPS
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon.
	     Defaults to main.
	     Valid values: main, off
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The weapon DPS.
	 @return A boolean value for the result of the comparison.
	 @usage
	 AddFunction AbilityAttackPower {
	    (AttackPower() + WeaponDPS() * 7)
	 }
     */
    function WeaponDPS(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let hand = positionalParams[1];
        let comparator, limit;
        let value = 0;
        if (hand == "offhand" || hand == "off") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            value = OvalePaperDoll.next.offHandWeaponDPS;
        } else if (hand == "mainhand" || hand == "main") {
            [comparator, limit] = [positionalParams[2], positionalParams[3]];
            value = OvalePaperDoll.next.mainHandWeaponDPS;
        } else {
            [comparator, limit] = [positionalParams[1], positionalParams[2]];
            value = OvalePaperDoll.next.mainHandWeaponDPS;
        }
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("weapondps", false, WeaponDPS);
}
{
    /** Test if the weapon imbue on the given weapon has expired or will expire after a given number of seconds.
	 @name WeaponEnchantExpires
	 @paramsig boolean
	 @param hand Sets which hand weapon.
	     Valid values: main, off.
	 @param seconds Optional. The maximum number of seconds before the weapon imbue should expire.
	     Defaults to 0 (zero).
	 @return A boolean value.
	 @usage
	 if WeaponEnchantExpires(main) Spell(windfury_weapon)
     */
    function WeaponEnchantExpires(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [hand, seconds] = [positionalParams[1], positionalParams[2]];
        seconds = seconds || 0;
        let [hasMainHandEnchant, mainHandExpiration, , hasOffHandEnchant, offHandExpiration] = GetWeaponEnchantInfo();
        let now = GetTime();
        if (hand == "mainhand" || hand == "main") {
            if (hasMainHandEnchant) {
                mainHandExpiration = mainHandExpiration / 1000;
                return [now + mainHandExpiration - seconds, INFINITY];
            }
        } else if (hand == "offhand" || hand == "off") {
            if (hasOffHandEnchant) {
                offHandExpiration = offHandExpiration / 1000;
                return [now + offHandExpiration - seconds, INFINITY];
            }
        }
        return [0, INFINITY];
    }
    OvaleCondition.RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires);
}
{
    /** Test if a sigil is charging
	 @name SigilCharging
	 @paramsig boolean
	 @param flame, silence, misery, chains
	 @return A boolean value.
	 @usage
	 if not SigilCharging(flame) Spell(sigil_of_flame)
        */
    function SigilCharging(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let charging = false;
        for (const [, v] of ipairs(positionalParams)) {
            charging = charging || OvaleSigil.IsSigilCharging(v, atTime);
        }
        return TestBoolean(charging, "yes");
    }
    OvaleCondition.RegisterCondition("sigilcharging", false, SigilCharging);
}
{
    /** Test with DBM or BigWigs (if available) whether a boss is currently engaged
	    otherwise test for known units and/or world boss
	 @name IsBossFight
	 @return A boolean value.
	 @usage
	 if IsBossFight() Spell(metamorphosis_havoc)
     */
    function IsBossFight(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let bossEngaged = baseState.next.inCombat && OvaleBossMod.IsBossEngaged(atTime);
        return TestBoolean(bossEngaged, "yes");
    }
    OvaleCondition.RegisterCondition("isbossfight", false, IsBossFight);
}
{
    /** Check for the target's race
	 @name Race
	 @param all the races you which to check for
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if Race(BloodElf) Spell(arcane_torrent)
     */
    function Race(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let isRace = false;
        let target = namedParams.target || "player";
        let [, targetRaceId] = UnitRace(target);
        for (const [, v] of ipairs(positionalParams)) {
            isRace = isRace || (v == targetRaceId);
        }
        return TestBoolean(isRace, "yes");
    }
    OvaleCondition.RegisterCondition("race", false, Race);
}
{
    /**  Check if the unit is in raid
     @name UnitInRaid
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if UnitInRaid(player) Spell(bloodlust)
     */
    function UnitInRaidCond(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let target = namedParams.target || "player";
        let raidIndex = UnitInRaid(target);
        return TestBoolean(raidIndex != undefined, "yes");
    }
    OvaleCondition.RegisterCondition("unitinraid", false, UnitInRaidCond);
}
{
    /** Check the amount of Soul Fragments for Vengeance DH
	 @usage
	 if SoulFragments() > 3 Spell(spirit_bomb)
	 */
    function SoulFragments(positionalParams: LuaArray<any>, namedParams: LuaObj<any>, state: BaseState, atTime: number) {
        let [comparator, limit] = [positionalParams[1], positionalParams[2]];
        let value = OvaleDemonHunterSoulFragments.SoulFragments(atTime);
        return Compare(value, comparator, limit);
    }
    OvaleCondition.RegisterCondition("soulfragments", false, SoulFragments);
}
