import LibBabbleCreatureType from "@wowts/lib_babble-creature_type-3.0";
import LibRangeCheck from "@wowts/lib_range_check-2.0";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    ParseCondition,
    ParameterInfo,
    ReturnBoolean,
    ReturnConstant,
    ReturnValue,
    ReturnValueBetween,
} from "../engine/condition";
import { SpellInfo, OvaleDataClass, SpellInfoProperty } from "../engine/data";
import { PowerType, OvalePowerClass } from "./Power";
import { HasteType, PaperDollData, OvalePaperDollClass } from "./PaperDoll";
import { Aura, OvaleAuraClass } from "./Aura";
import { ipairs, pairs, type, LuaArray, lualength } from "@wowts/lua";
import {
    GetBuildInfo,
    GetItemCount,
    GetNumTrackingTypes,
    GetTrackingInfo,
    GetUnitSpeed,
    HasFullControl,
    IsStealthed,
    SpellId,
    UnitCastingInfo,
    UnitChannelInfo,
    UnitClass,
    UnitClassification,
    UnitCreatureFamily,
    UnitCreatureType,
    UnitDetailedThreatSituation,
    UnitExists,
    UnitInParty,
    UnitInRaid,
    UnitIsDead,
    UnitIsFriend,
    UnitIsPVP,
    UnitIsUnit,
    UnitLevel,
    UnitName,
    UnitPower,
    UnitPowerMax,
    UnitRace,
} from "@wowts/wow-mock";
import { huge as INFINITY, min } from "@wowts/math";
import {
    PositionalParameters,
    NamedParametersOf,
    AstFunctionNode,
} from "../engine/ast";
import { OvaleSpellsClass } from "./Spells";
import { lower, upper, sub } from "@wowts/string";
import { OvaleAzeriteEssenceClass } from "./AzeriteEssence";
import { BaseState } from "./BaseState";
import { OvaleFutureClass } from "./Future";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleFrameModuleClass } from "../ui/Frame";
import { OvaleGUIDClass } from "../engine/guid";
import { OvaleDamageTakenClass } from "./DamageTaken";
import { OvaleEnemiesClass } from "./Enemies";
import { OvaleCooldownClass } from "./Cooldown";
import { LastSpell } from "./LastSpell";
import { OvaleHealthClass } from "./Health";
import { OvaleOptionsClass } from "../ui/Options";
import { OvaleLossOfControlClass } from "./LossOfControl";
import { OvaleSpellDamageClass } from "./SpellDamage";
import { OvaleTotemClass } from "./Totem";
import { OvaleDemonHunterSoulFragmentsClass } from "./DemonHunterSoulFragments";
import { OvaleSigilClass } from "./DemonHunterSigils";
import { OvaleRunesClass } from "./Runes";
import { OvaleBossModClass } from "./BossMod";
import { isNumber, KeyCheck, OneTimeMessage } from "../tools/tools";

// Return the target's damage reduction from armor, which seems to be 30% with most bosses
function BossArmorDamageReduction(target: string) {
    return 0.3;
}
// Return a Capitalized word
function Capitalize(word: string): string {
    if (!word) return word;
    return upper(sub(word, 1, 1)) + lower(sub(word, 2));
}

const AMPLIFICATION = 146051;
const INCREASED_CRIT_EFFECT_3_PERCENT = 44797;
const IMBUED_BUFF_ID = 214336;
const STEADY_FOCUS = 177668;

type Target =
    | "player"
    | "target"
    | "focus"
    | "cycle"
    | "pet"
    | "pettarget"
    | "targettarget";

const checkHaste: KeyCheck<HasteType> = {
    base: true,
    melee: true,
    none: true,
    ranged: true,
    spell: true,
};

type Filter = "HARMFUL" | "HELPFUL";

const mapFilter: Record<"buff" | "debuff", Filter> = {
    buff: "HELPFUL",
    debuff: "HARMFUL",
};

export class OvaleConditions {
    /**
     * Return the value of a parameter from the named spell's information.  If the value is the name of a
     * in the script, then return the compute the value of that instead.
     * @param spellId The spell id
     * @param paramName The name of the parameter
     * @param atTime The time
     */
    ComputeParameter<T extends SpellInfoProperty>(
        spellId: number,
        paramName: T,
        atTime: number
    ): SpellInfo[T] | undefined {
        // let si = this.OvaleData.GetSpellInfo(spellId);
        // if (si && si[paramName]) {
        //     let name = si[paramName];
        //     let node = this.OvaleCompile.GetFunctionNode(<string>name);
        //     if (node) {
        //         let result = this.runner.Compute(node.child[1], atTime);
        //         if (result.type === "value") {
        //             let value =
        //                 <number>result.value +
        //                 (atTime - element.origin) * element.rate;
        //             return <any>value;
        //         }
        //     } else {
        //         return si[paramName];
        //     }
        // }
        // return undefined;
        return this.OvaleData.GetSpellInfoProperty(
            spellId,
            atTime,
            paramName,
            undefined
        );
    }

    /** Return the time in seconds, adjusted by the named haste effect. */
    GetHastedTime(seconds: number, haste: HasteType | undefined) {
        seconds = seconds || 0;
        const multiplier = this.OvalePaperDoll.GetHasteMultiplier(
            haste,
            this.OvalePaperDoll.next
        );
        return seconds / multiplier;
    }

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
    private ArmorSetBonus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0");
        const value = 0;
        return [0, INFINITY, value, 0, 0];
    };

    /** Get how many pieces of an armor set, e.g., Tier 14 set, are equipped by the player.
	@name ArmorSetParts
	@paramsig number or boolean
	@param name The name of the armor set.
	    Valid names: T11, T12, T13, T14, T15.
	    Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	@return The number of pieces of the named set that are equipped by the player.
	@usage
	if ArmorSetParts(T13) >=2 and target.HealthPercent() <60
	    Spell(ferocious_bite) */
    private ArmorSetParts = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 0;
        OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0");
        return ReturnConstant(value);
    };

    private AzeriteEssenceIsMajor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.OvaleAzeriteEssence.IsMajorEssence(essenceId);
        return ReturnBoolean(value);
    };
    private AzeriteEssenceIsMinor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.OvaleAzeriteEssence.IsMinorEssence(essenceId);
        return ReturnBoolean(value);
    };
    private AzeriteEssenceIsEnabled = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value =
            this.OvaleAzeriteEssence.IsMajorEssence(essenceId) ||
            this.OvaleAzeriteEssence.IsMinorEssence(essenceId);
        return ReturnBoolean(value);
    };
    private AzeriteEssenceRank = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.OvaleAzeriteEssence.EssenceRank(essenceId);
        return ReturnConstant(value);
    };

    /** Get the base duration of the aura in seconds if it is applied at the current time.
	@name BaseDuration
	@paramsig number or boolean
	@param id The aura spell ID.
	@return The base duration in seconds.
	@see BuffDuration
	@usage
	if BaseDuration(slice_and_dice_buff) > BuffDuration(slice_and_dice_buff)
	    Spell(slice_and_dice) */

    private BaseDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        let value = 0;
        if (this.OvaleData.buffSpellList[auraId]) {
            const spellList = this.OvaleData.buffSpellList[auraId];
            for (const [id] of pairs(spellList)) {
                value = this.OvaleAura.GetBaseDuration(
                    id,
                    undefined,
                    atTime,
                    this.OvalePaperDoll.next
                );
                if (value != INFINITY) {
                    break;
                }
            }
        } else {
            value = this.OvaleAura.GetBaseDuration(
                auraId,
                undefined,
                atTime,
                this.OvalePaperDoll.next
            );
        }
        return ReturnConstant(value);
    };

    /** Get the value of a buff as a number.  Not all buffs return an amount.
	 @name BuffAmount
	 @paramsig number
	 @param id The spell ID of the aura or the name of a spell list.
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
	 if DebuffAmount(stagger) >10000 Spell(purifying_brew) */
    private BuffAmount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const value = namedParams.value || 1;
        let statName: "value1" | "value2" | "value3" = "value1";
        if (value == 1) {
            statName = "value1";
        } else if (value == 2) {
            statName = "value2";
        } else if (value == 3) {
            statName = "value3";
        }
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const value = aura[statName] || 0;
            return ReturnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return ReturnConstant(0);
    };

    /** Get the player's combo points for the given aura at the time the aura was applied on the target.
	 @name BuffComboPoints
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of combo points.
	 @see DebuffComboPoints
	 @usage
	 if target.DebuffComboPoints(rip) <5 Spell(rip) */
    private BuffComboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const value = (aura && aura.combopoints) || 0;
            return ReturnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return ReturnConstant(0);
    };

    /** Get the number of seconds before a buff can be gained again.
	 @name BuffCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see DebuffCooldown
	 @usage
	 if BuffCooldown(trinket_stat_agility_buff) > 45
	     Spell(tigers_fury)
    */
    private BuffCooldown: ConditionFunction = (
        positionalParams,
        namedParams,
        atTime
    ) => {
        const auraId = positionalParams[1];

        if (!isNumber(auraId)) return [];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            const gain = aura.gain;
            const cooldownEnding = aura.cooldownEnding || 0;
            return ReturnValueBetween(gain, INFINITY, 0, cooldownEnding, -1);
        }
        return ReturnConstant(0);
    };

    /**  Get the number of buff if the given spell list
	 @name BuffCount
	 @paramsig number or boolean
	 @param id the spell list ID	
	 @return The number of buffs
	 */
    private BuffCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const spellList = this.OvaleData.buffSpellList[auraId];
        let count = 0;
        for (const [id] of pairs(spellList)) {
            const aura = this.OvaleAura.GetAura(
                target,
                id,
                atTime,
                filter,
                mine
            );
            if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
                count = count + 1;
            }
        }
        return ReturnConstant(count);
    };

    /** Get the duration in seconds of the cooldown before a buff can be gained again.
	 @name BuffCooldownDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see DebuffCooldown
	 @usage
	 if target.TimeToDie() > BuffCooldownDuration(trinket_stat_any_buff)
	     Item(Trinket0Slot)
     */
    private BuffCooldownDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        let minCooldown = INFINITY;
        if (this.OvaleData.buffSpellList[auraId]) {
            for (const [id] of pairs(this.OvaleData.buffSpellList[auraId])) {
                const si = this.OvaleData.spellInfo[id];
                const cd = si && si.buff_cd;
                if (cd && minCooldown > cd) {
                    minCooldown = cd;
                }
            }
        } else {
            minCooldown = 0;
        }
        return ReturnConstant(minCooldown);
    };

    /** /** Get the total count of the given aura across all targets.
	 @name BuffCountOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
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
	 @see DebuffCountOnAny
     */
    private BuffCountOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const excludeUnitId =
            (namedParams.excludeTarget == 1 && this.baseState.defaultTarget) ||
            undefined;
        const fractional = (namedParams.count == 0 && true) || false;
        const [
            count,
            ,
            startChangeCount,
            endingChangeCount,
            startFirst,
            endingLast,
        ] = this.OvaleAura.AuraCount(
            auraId,
            filter,
            mine,
            namedParams.stacks as number | undefined,
            atTime,
            excludeUnitId
        );
        if (count > 0 && startChangeCount < INFINITY && fractional) {
            const rate = -1 / (endingChangeCount - startChangeCount);
            return ReturnValueBetween(
                startFirst,
                endingLast,
                count,
                startChangeCount,
                rate
            );
        }
        return ReturnConstant(count);
    };

    /** Get the current direction of an aura's stack count.
	 A negative number means the aura is decreasing in stack count.
	 A positive number means the aura is increasing in stack count.
	 @name BuffDirection
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current direction.
	 @see DebuffDirection
     */
    private BuffDirection = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            return ReturnValueBetween(
                aura.gain,
                INFINITY,
                aura.direction,
                aura.gain,
                0
            );
        }
        return ReturnConstant(0);
    };

    /** Get the total duration of the aura from when it was first applied to when it ended.
	 @name BuffDuration
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The total duration of the aura.
	 @see DebuffDuration
     */
    private BuffDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const duration = aura.ending - aura.start;
            return ReturnValueBetween(
                aura.gain,
                aura.ending,
                duration,
                aura.start,
                0
            );
        }
        return ReturnConstant(0);
    };

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
    private BuffExpires: ConditionFunction = (
        positionalParams,
        namedParams,
        atTime
    ): ConditionResult => {
        const [auraId, seconds] = [
            positionalParams[1],
            positionalParams[2] || 0,
        ];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        if (!isNumber(auraId) || !isNumber(seconds)) return [];
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            const hastedSeconds = this.GetHastedTime(
                seconds,
                namedParams.haste as HasteType
            );
            if (ending - hastedSeconds <= gain) {
                return [gain, INFINITY];
            } else {
                return [ending - hastedSeconds, INFINITY];
            }
        }
        return [0, INFINITY];
    };

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
    private BuffPresent = (
        atTime: number,
        auraId: number,
        target: Target,
        filter: "HARMFUL" | "HELPFUL",
        mine: boolean,
        seconds: number,
        haste: HasteType
    ): ConditionResult => {
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            seconds = this.GetHastedTime(seconds, haste);
            if (ending - seconds <= gain) {
                return [];
            } else {
                return [gain, ending - seconds];
            }
        }
        return [];
    };

    /** Get the time elapsed since the aura was last gained on the target.
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see DebuffGain */
    private BuffGain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            const gain = aura.gain || 0;
            return ReturnValueBetween(gain, INFINITY, 0, gain, 1);
        }
        return ReturnConstant(0);
    };

    private BuffImproved = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let [, ,] = this.ParseCondition(positionalParams, namedParams);
        // TODO Not implemented
        return ReturnConstant(0);
    };

    /** Get the player's persistent multiplier for the given aura at the time the aura was applied on the target.
	 The persistent multiplier is snapshotted to the aura for its duration at the time the aura is applied.
	 @name BuffPersistentMultiplier
	 @paramsig number or boolean
	 @param id The aura spell ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The persistent multiplier.
	 @see DebuffPersistentMultiplier
	 @usage
	 if target.DebuffPersistentMultiplier(rake) < 1 Spell(rake)
     */
    private BuffPersistentMultiplier = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const value = aura.damageMultiplier || 1;
            return ReturnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return ReturnConstant(1);
    };

    /** Get the remaining time in seconds on an aura.
	 @name BuffRemaining
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds remaining on the aura.
	 @see DebuffRemaining
	 @usage
	 if BuffRemaining(slice_and_dice) <2
	     Spell(slice_and_dice)
     */
    private BuffRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && aura.ending >= atTime) {
            return ReturnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return ReturnConstant(0);
    };

    /** Get the remaining time in seconds before the aura expires across all targets.
	 @name BuffRemainingOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
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
	 @see DebuffRemainingOnAny
     */
    private BuffRemainingOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const excludeUnitId =
            (namedParams.excludeTarget == 1 && this.baseState.defaultTarget) ||
            undefined;
        const [count, , , , startFirst, endingLast] = this.OvaleAura.AuraCount(
            auraId,
            filter,
            mine,
            namedParams.stacks as number | undefined,
            atTime,
            excludeUnitId
        );
        if (count > 0) {
            return ReturnValueBetween(startFirst, INFINITY, 0, endingLast, -1);
        }
        return ReturnConstant(0);
    };

    /** Get the number of stacks of an aura on the target.
	 @name BuffStacks
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of stacks of the aura.
	 @see DebuffStacks
	 @usage
	 if BuffStacks(pet_frenzy any=1) ==5
	     Spell(focus_fire)
	 if target.DebuffStacks(weakened_armor) <3
	     Spell(faerie_fire)
     */
    private BuffStacks = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const value = aura.stacks || 0;
            return ReturnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return ReturnConstant(0);
    };

    private maxStacks = (
        positionalParams: PositionalParameters,
        namedParameters: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1] as number;
        const spellInfo = this.OvaleData.GetSpellInfo(auraId);
        const maxStacks = (spellInfo && spellInfo.max_stacks) || 0;
        return ReturnConstant(maxStacks);
    };

    /** Get the total number of stacks of the given aura across all targets.
	 @name BuffStacksOnAny
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	     Defaults to any=0.
	     Valid values: 0, 1.
	 @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	     Defaults to excludeTarget=0.
	     Valid values: 0, 1.
	 @return The total number of stacks.
	 @see DebuffStacksOnAny
     */
    private BuffStacksOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const excludeUnitId =
            (namedParams.excludeTarget == 1 && this.baseState.defaultTarget) ||
            undefined;
        const [
            count,
            stacks,
            ,
            endingChangeCount,
            startFirst,
        ] = this.OvaleAura.AuraCount(
            auraId,
            filter,
            mine,
            1,
            atTime,
            excludeUnitId
        );
        if (count > 0) {
            return ReturnValueBetween(
                startFirst,
                endingChangeCount,
                stacks,
                startFirst,
                0
            );
        }
        return ReturnConstant(count);
    };

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
    private BuffStealable = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        return this.OvaleAura.GetAuraWithProperty(
            target,
            "stealable",
            "HELPFUL",
            atTime
        );
    };

    /** Check if the player can cast the given spell (not on cooldown).
	 @name CanCast
	 @paramsig boolean
	 @param id The spell ID to check.
	 @return True if the spell cast be cast; otherwise, false.
     */
    private CanCast = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const [start, duration] = this.OvaleCooldown.GetSpellCooldown(
            spellId,
            atTime
        );
        return [start + duration, INFINITY];
    };

    /** Get the cast time in seconds of the spell for the player, taking into account current haste effects.
	 @name CastTime
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see ExecuteTime
	 @usage
	 if target.DebuffRemaining(flame_shock) < CastTime(lava_burst)
	     Spell(lava_burst)
     */
    private CastTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const castTime = this.OvaleSpellBook.GetCastTime(spellId) || 0;
        return ReturnConstant(castTime);
    };

    /** Get the cast time in seconds of the spell for the player or the GCD for the player, whichever is greater.
	 @name ExecuteTime
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see CastTime
	 @usage
	 if target.DebuffRemaining(flame_shock) < ExecuteTime(lava_burst)
	     Spell(lava_burst)
     */
    private ExecuteTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const castTime = this.OvaleSpellBook.GetCastTime(spellId) || 0;
        const gcd = this.OvaleFuture.GetGCD(atTime);
        const t = (castTime > gcd && castTime) || gcd;
        return ReturnConstant(t);
    };

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
    private Casting = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let start, ending, castSpellId, castSpellName;
        if (target == "player") {
            start = this.OvaleFuture.next.currentCast.start;
            ending = this.OvaleFuture.next.currentCast.stop;
            castSpellId = this.OvaleFuture.next.currentCast.spellId;
            castSpellName = this.OvaleSpellBook.GetSpellName(castSpellId);
        } else {
            let [spellName, , , startTime, endTime] = UnitCastingInfo(target);
            if (!spellName) {
                [spellName, , , startTime, endTime] = UnitChannelInfo(target);
            }
            if (spellName) {
                castSpellName = spellName;
                start = startTime / 1000;
                ending = endTime / 1000;
            }
        }
        if ((castSpellId || castSpellName) && start && ending) {
            if (!spellId) {
                return [start, ending];
            } else if (this.OvaleData.buffSpellList[spellId]) {
                for (const [id] of pairs(
                    this.OvaleData.buffSpellList[spellId]
                )) {
                    if (
                        id == castSpellId ||
                        this.OvaleSpellBook.GetSpellName(id) == castSpellName
                    ) {
                        return [start, ending];
                    }
                }
            } else if (
                spellId == "harmful" &&
                this.OvaleSpellBook.IsHarmfulSpell(spellId)
            ) {
                return [start, ending];
            } else if (
                spellId == "helpful" &&
                this.OvaleSpellBook.IsHelpfulSpell(spellId)
            ) {
                return [start, ending];
            } else if (spellId == castSpellId) {
                OneTimeMessage(
                    "%f %f %d %s => %d (%f)",
                    start,
                    ending,
                    castSpellId,
                    castSpellName,
                    spellId,
                    this.baseState.currentTime
                );
                return [start, ending];
            } else if (
                type(spellId) == "number" &&
                this.OvaleSpellBook.GetSpellName(spellId) == castSpellName
            ) {
                return [start, ending];
            }
        }
        return [];
    };

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
    private CheckBoxOff = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        for (const [, id] of ipairs(positionalParams)) {
            if (
                this.OvaleFrameModule.frame &&
                this.OvaleFrameModule.frame.IsChecked(id)
            ) {
                return [];
            }
        }
        return [0, INFINITY];
    };

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
    private CheckBoxOn = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        for (const [, id] of ipairs(positionalParams)) {
            if (
                this.OvaleFrameModule.frame &&
                !this.OvaleFrameModule.frame.IsChecked(id)
            ) {
                return [];
            }
        }
        return [0, INFINITY];
    };

    /** Test whether the target's class matches the given class.
	 @name Class
	 @paramsig boolean
	 @param class The class to check.
	     Valid values: DEATHKNIGHT, DRUID, HUNTER, MAGE, MONK, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.Class(PRIEST) Spell(cheap_shot)
     */
    private Class = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const className = positionalParams[1];
        const [target] = this.ParseCondition(positionalParams, namedParams);

        let classToken;
        if (target == "player") {
            classToken = this.OvalePaperDoll.class;
        } else {
            [, classToken] = UnitClass(target);
        }
        const boolean = classToken == upper(className);
        return ReturnBoolean(boolean);
    };

    /** Test whether the target's classification matches the given classification.
	 @name Classification
	 @paramsig boolean
	 @param classification The unit classification to check.
	     Valid values: normal, elite, worldboss.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.Classification(worldboss) Item(virmens_bite_potion)
     */
    private Classification = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const classification = positionalParams[1];
        let targetClassification;
        const [target] = this.ParseCondition(positionalParams, namedParams);
        if (UnitLevel(target) < 0) {
            targetClassification = "worldboss";
        } else if (
            UnitExists("boss1") &&
            this.OvaleGUID.UnitGUID(target) == this.OvaleGUID.UnitGUID("boss1")
        ) {
            targetClassification = "worldboss";
        } else {
            const aura = this.OvaleAura.GetAura(
                target,
                IMBUED_BUFF_ID,
                atTime,
                "HARMFUL",
                false
            );
            if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
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
        const boolean = targetClassification == classification;
        return ReturnBoolean(boolean);
    };

    /**  Get the current value of a script counter.
	 @name Counter
	 @paramsig number or boolean
	 @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
	 @return The current value the counter.
     */
    private Counter = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const counter = positionalParams[1];
        const value = this.OvaleFuture.GetCounter(counter, atTime);
        return ReturnConstant(value);
    };

    /** Test whether the target's creature family matches the given name.
	 Applies only to beasts that can be taken as hunter pets (e.g., cats, worms, and ravagers but not zhevras, talbuks and pterrordax),
	 demons that can be summoned by Warlocks (e.g., imps and felguards, but not demons that require enslaving such as infernals
	 and doomguards or world demons such as pit lords and armored voidwalkers), and Death Knight's pets (ghouls)
	 @name CreatureFamily
	 @paramsig boolean
	 @param name The English name of the creature family to check.
	     Valid values: Bat, Beast, Felguard, Imp, Ravager, etc.
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
    private CreatureFamily = (_: number, name: string, target: string) => {
        name = Capitalize(name);
        const family = UnitCreatureFamily(target);
        const lookupTable =
            LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        return ReturnBoolean(lookupTable && family == lookupTable[name]);
    };

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
    private CreatureType = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const creatureType = UnitCreatureType(target);
        const lookupTable =
            LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        if (lookupTable) {
            for (const [, name] of ipairs<string>(positionalParams)) {
                const capitalizedName: string = Capitalize(name);
                if (creatureType == lookupTable[capitalizedName]) {
                    return [0, INFINITY];
                }
            }
        }
        return [];
    };

    /** Get the current estimated damage of a spell on the target if it is a critical strike.
	 @name CritDamage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The estimated critical strike damage of the given spell.
	 @see Damage
     */
    private CritDamage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        let value = this.ComputeParameter(spellId, "damage", atTime) || 0;
        const si = this.OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target));
        }
        let critMultiplier = 2;
        {
            const aura = this.OvaleAura.GetAura(
                "player",
                AMPLIFICATION,
                atTime,
                "HELPFUL"
            );
            if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier + (aura.value1 || 0);
            }
        }
        {
            const aura = this.OvaleAura.GetAura(
                "player",
                INCREASED_CRIT_EFFECT_3_PERCENT,
                atTime,
                "HELPFUL"
            );
            if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier * (aura.value1 || 0);
            }
        }
        value = critMultiplier * value;
        return ReturnConstant(value);
    };

    /**  Get the current estimated damage of a spell on the target.
	 The script must provide a to calculate the damage of the spell and assign it to the "damage" SpellInfo() parameter.
	 @name Damage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The estimated damage of the given spell on the target.
	 @see CritDamage, LastDamage, LastEstimatedDamage
	 @usage
	 if {target.Damage(rake) / target.LastEstimateDamage(rake)} >1.1
	     Spell(rake)
     */
    private Damage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        let value = this.ComputeParameter(spellId, "damage", atTime) || 0;
        const si = this.OvaleData.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - BossArmorDamageReduction(target));
        }
        return ReturnConstant(value);
    };

    /**  Get the total damage taken by the player in the previous time interval.
	 @name DamageTaken
	 @paramsig number or boolean
	 @param interval The number of seconds before now.
	 @return The amount of damage taken in the previous interval.
	 @see IncomingDamage
	 @usage
	 if DamageTaken(5) > 50000 Spell(death_strike)
     */
    private DamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [total] = this.OvaleDamageTaken.GetRecentDamage(interval);
            value = total;
        }
        return ReturnConstant(value);
    };

    /**  Get the magic damage taken by the player in the previous time interval.
	 @name MagicDamageTaken
	 @paramsig number or boolean
	 @param interval The number of seconds before now.
	 @return The amount of magic damage taken in the previous interval.
	 @see IncomingMagicDamage
	 @usage
	 if MagicDamageTaken(1.5) > 0 Spell(antimagic_shell)
     */
    private MagicDamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [, totalMagic] = this.OvaleDamageTaken.GetRecentDamage(
                interval
            );
            value = totalMagic;
        }
        return ReturnConstant(value);
    };

    /**  Get the physical damage taken by the player in the previous time interval.
	 @name PhysicalDamageTaken
	 @paramsig number or boolean
	 @param interval The number of seconds before now.
	 @return The amount of physical damage taken in the previous interval.
	 @see IncomingPhysicalDamage
	 @usage
	 if PhysicalDamageTaken(1.5) > 0 Spell(shield_block)
     */
    private PhysicalDamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [total, totalMagic] = this.OvaleDamageTaken.GetRecentDamage(
                interval
            );
            value = total - totalMagic;
        }
        return ReturnConstant(value);
    };

    GetDiseases(
        target: string,
        atTime: number
    ): [Aura | undefined, Aura | undefined] {
        const bpAura = this.OvaleAura.GetAura(
            target,
            SpellId.blood_plague,
            atTime,
            "HARMFUL",
            true
        );
        const ffAura = this.OvaleAura.GetAura(
            target,
            SpellId.frost_fever,
            atTime,
            "HARMFUL",
            true
        );
        return [bpAura, ffAura];
    }

    /** Get the remaining time in seconds before any diseases applied by the death knight will expire.
	 @name DiseasesRemaining
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
     */
    private DiseasesRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target, ,] = this.ParseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.GetDiseases(target, atTime);
        let aura;
        if (
            bpAura &&
            this.OvaleAura.IsActiveAura(bpAura, atTime) &&
            ffAura &&
            this.OvaleAura.IsActiveAura(ffAura, atTime)
        ) {
            aura = (bpAura.ending < ffAura.ending && bpAura) || ffAura;
        }
        if (aura) {
            return ReturnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return ReturnConstant(0);
    };

    /**  Test if all diseases applied by the death knight are present on the target.
	 @name DiseasesTicking
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    private DiseasesTicking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target, ,] = this.ParseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.GetDiseases(target, atTime);
        let gain, ending;
        if (bpAura && ffAura) {
            gain = (bpAura.gain > ffAura.gain && bpAura.gain) || ffAura.gain;
            //start = (bpAura.start > ffAura.start) && bpAura.start || ffAura.start;
            ending =
                (bpAura.ending < ffAura.ending && bpAura.ending) ||
                ffAura.ending;
        }
        if (gain && ending && ending > gain) {
            return [gain, ending];
        }
        return [];
    };

    /**  Test if any diseases applied by the death knight are present on the target.
	 @name DiseasesAnyTicking
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    private DiseasesAnyTicking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target, ,] = this.ParseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.GetDiseases(target, atTime);
        let aura;
        if (bpAura || ffAura) {
            aura = bpAura || ffAura;
            if (bpAura && ffAura) {
                aura = (bpAura.ending > ffAura.ending && bpAura) || ffAura;
            }
        }
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            if (ending > gain) {
                return [gain, ending];
            }
        }
        return [];
    };

    /**  Get the distance in yards to the target.
	 The distances are from LibRangeCheck-2.0, which determines distance based on spell range checks, so results are approximate.
	 You should not test for equality.
	 @name Distance
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The distance to the target.
	 @usage
	 if target.Distance() < 25
	     Texture(ability_rogue_sprint)
     */
    private Distance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const value = (LibRangeCheck && LibRangeCheck.GetRange(target)) || 0;
        return ReturnConstant(value);
    };

    /**  Get the number of hostile enemies on the battlefield.
	 The minimum value returned is 1.
	 @name Enemies
	 @paramsig number or boolean
	 @param tagged Optional. By default, all enemies are counted. To count only enemies directly tagged by the player, set tagged=1.
	     Defaults to tagged=0.
	     Valid values: 0, 1.
	 @return The number of enemies.
	 @usage
	 if Enemies() > 4 Spell(fan_of_knives)
     */
    private Enemies = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let value = this.OvaleEnemies.next.enemies;
        if (!value) {
            let useTagged = this.ovaleOptions.db.profile.apparence
                .taggedEnemies;
            if (namedParams.tagged == 0) {
                useTagged = false;
            } else if (namedParams.tagged == 1) {
                useTagged = true;
            }
            value =
                (useTagged && this.OvaleEnemies.next.taggedEnemies) ||
                this.OvaleEnemies.next.activeEnemies;
        }
        if (value < 1) {
            value = 1;
        }
        return ReturnConstant(value);
    };

    /** Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
	 @name EnergyRegenRate
	 @paramsig number or boolean
	 @return The current rate of energy regeneration.
	 @usage
	 if EnergyRegenRage() >11 Spell(stance_of_the_sturdy_ox)
     */
    private EnergyRegenRate = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.OvalePower.getPowerRateAt(
            this.OvalePower.next,
            "energy",
            atTime
        );
        return ReturnConstant(value);
    };

    /** Get the remaining time in seconds the target is Enraged.
	 @name EnrageRemaining
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see IsEnraged
	 @usage
	 if EnrageRemaining() < 3 Spell(berserker_rage)
     */
    private EnrageRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const aura = this.OvaleAura.GetAura(
            target,
            "enrage",
            atTime,
            "HELPFUL",
            false
        );
        if (aura && aura.ending >= atTime) {
            return ReturnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return ReturnConstant(0);
    };

    /** Test if the target exists. The target may be alive or dead.
	 @name Exists
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @see Present
	 @usage
	 if not pet.Exists() Spell(summon_imp)
     */
    private Exists = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitExists(target);
        return ReturnBoolean(boolean);
    };

    /** A condition that always returns false.
	 @name False
	 @paramsig boolean
	 @return A boolean value.
     */
    False: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return [];
    };

    /**  Get the amount of regenerated focus per second for hunters.
	 @name FocusRegenRate
	 @paramsig number or boolean
	 @return The current rate of focus regeneration.
	 @usage
	 if FocusRegenRate() > 20 Spell(arcane_shot)
     */
    private FocusRegenRate = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.OvalePower.getPowerRateAt(
            this.OvalePower.next,
            "focus",
            atTime
        );
        return ReturnConstant(value);
    };

    /** Get the amount of focus that would be regenerated during the cast time of the given spell for hunters.
	 @name FocusCastingRegen
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The amount of focus.
     */
    private FocusCastingRegen = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const regenRate = this.OvalePower.getPowerRateAt(
            this.OvalePower.next,
            "focus",
            atTime
        );
        let power = 0;
        const castTime = this.OvaleSpellBook.GetCastTime(spellId) || 0;
        const gcd = this.OvaleFuture.GetGCD(atTime);
        const castSeconds = (castTime > gcd && castTime) || gcd;
        power = power + regenRate * castSeconds;
        const aura = this.OvaleAura.GetAura(
            "player",
            STEADY_FOCUS,
            atTime,
            "HELPFUL",
            true
        );
        if (aura) {
            let seconds = aura.ending - atTime;
            if (seconds <= 0) {
                seconds = 0;
            } else if (seconds > castSeconds) {
                seconds = castSeconds;
            }
            power = power + regenRate * 1.5 * seconds;
        }
        return ReturnConstant(power);
    };

    /** Get the player's global cooldown in seconds.
	 @name GCD
	 @paramsig number or boolean
	 @return The number of seconds.
	 @usage
	 if GCD() < 1.1 Spell(frostfire_bolt)
     */
    private GCD = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.OvaleFuture.GetGCD(atTime);
        return ReturnConstant(value);
    };

    /** Get the number of seconds before the player's global cooldown expires.
	 @name GCDRemaining
	 @paramsig number or boolean
	 @param target Optional. Sets the target of the previous spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @usage
	 unless SpellCooldown(seraphim) < GCDRemaining() Spell(judgment)
     */
    private GCDRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        if (this.OvaleFuture.next.lastGCDSpellId) {
            const duration = this.OvaleFuture.GetGCD(
                this.OvaleFuture.next.lastGCDSpellId,
                atTime,
                this.OvaleGUID.UnitGUID(target)
            );
            const spellcast = this.lastSpell.LastInFlightSpell();
            const start = (spellcast && spellcast.start) || 0;
            const ending = start + duration;
            if (atTime < ending) {
                return ReturnValueBetween(start, INFINITY, 0, ending, -1);
            }
        }
        return ReturnConstant(0);
    };

    private Glyph = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return ReturnBoolean(false);
    };

    /** Test if the player has full control, i.e., isn't feared, charmed, etc.
	 @name HasFullControl
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if not HasFullControl() Spell(barkskin)
     */
    private HasFullControlCondition = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = HasFullControl();
        return ReturnBoolean(boolean);
    };

    /** Get the current amount of health points of the target.
	 @name Health
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health.
	 @see Life
	 @usage
	 if Health() < 10000 Spell(last_stand)
     */
    private Health = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health = this.OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
            const rate = (-1 * health) / timeToDie;
            return ReturnValueBetween(now, INFINITY, health, now, rate);
        }
        return ReturnConstant(0);
    };

    /** Get the current amount of health points of the target including absorbs.
	 @name EffectiveHealth
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health including absorbs.
	 @see Life
	 @usage
	 if EffectiveHealth() < 10000 Spell(last_stand)
     */
    private EffectiveHealth = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health =
            this.OvaleHealth.UnitHealth(target) +
                this.OvaleHealth.UnitAbsorb(target) -
                this.OvaleHealth.UnitHealAbsorb(target) || 0;

        const now = this.baseState.currentTime;
        const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
        const rate = (-1 * health) / timeToDie;
        return ReturnValueBetween(now, INFINITY, health, now, rate);
    };

    /** Get the number of health points away from full health of the target.
	 @name HealthMissing
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current missing health.
	 @see LifeMissing
	 @usage
	 if HealthMissing() < 20000 Item(healthstone)
     */
    private HealthMissing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health = this.OvaleHealth.UnitHealth(target) || 0;
        const maxHealth = this.OvaleHealth.UnitHealthMax(target) || 1;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const missing = maxHealth - health;
            const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
            const rate = health / timeToDie;
            return ReturnValueBetween(now, INFINITY, missing, now, rate);
        }
        return ReturnConstant(maxHealth);
    };

    /** Get the current percent level of health of the target.
	 @name HealthPercent
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health percent.
	 @see LifePercent
	 @usage
	 if HealthPercent() < 20 Spell(last_stand)
	 if target.HealthPercent() < 25 Spell(kill_shot)
     */
    private HealthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health = this.OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const maxHealth = this.OvaleHealth.UnitHealthMax(target) || 1;
            const healthPct = (health / maxHealth) * 100;
            const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
            const rate = (-1 * healthPct) / timeToDie;
            return ReturnValueBetween(now, INFINITY, healthPct, now, rate);
        }
        return ReturnConstant(0);
    };

    /** Get the current effective percent level of health of the target (including absorbs).
	 @name EffectiveHealthPercent
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current health percent including absorbs.
	 @usage
	 if EffectiveHealthPercent() < 20 Spell(last_stand)
	 if target.EffectiveHealthPercent() < 25 Spell(kill_shot)
     */
    private EffectiveHealthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health =
            this.OvaleHealth.UnitHealth(target) +
                this.OvaleHealth.UnitAbsorb(target) -
                this.OvaleHealth.UnitHealAbsorb(target) || 0;

        const now = this.baseState.currentTime;
        const maxHealth = this.OvaleHealth.UnitHealthMax(target) || 1;
        const healthPct = (health / maxHealth) * 100;
        const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
        const rate = (-1 * healthPct) / timeToDie;
        return ReturnValueBetween(now, INFINITY, healthPct, now, rate);
    };

    /** Get the amount of health points of the target when it is at full health.
	 @name MaxHealth
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum health.
	 @usage
	 if target.MaxHealth() > 10000000 Item(mogu_power_potion)
     */
    private MaxHealth = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const value = this.OvaleHealth.UnitHealthMax(target);
        return ReturnConstant(value);
    };

    /**  Get the estimated number of seconds remaining before the target is dead.
	 @name TimeToDie
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see DeadIn
	 @usage
	 if target.TimeToDie() <2 and ComboPoints() >0 Spell(eviscerate)
     */
    private TimeToDie = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const now = this.baseState.currentTime;
        const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
        return ReturnValueBetween(now, INFINITY, timeToDie, now, -1);
    };

    /** Get the estimated number of seconds remaining before the target reaches the given percent of max health.
	 @name TimeToHealthPercent
	 @paramsig number or boolean
	 @param percent The percent of maximum health of the target.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see TimeToDie
	 @usage
	 if target.TimeToHealthPercent(25) <15 Item(virmens_bite_potion)
     */
    private TimeToHealthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const percent = positionalParams[1];
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const health = this.OvaleHealth.UnitHealth(target) || 0;
        if (health > 0) {
            const maxHealth = this.OvaleHealth.UnitHealthMax(target) || 1;
            const healthPct = (health / maxHealth) * 100;
            if (healthPct >= percent) {
                const now = this.baseState.currentTime;
                const timeToDie = this.OvaleHealth.UnitTimeToDie(target);
                const t = (timeToDie * (healthPct - percent)) / healthPct;
                return ReturnValueBetween(now, now + t, t, now, -1);
            }
        }
        return ReturnConstant(0);
    };

    /** Test if the given spell is in flight for spells that have a flight time after cast, e.g., Lava Burst.
	 @name InFlightToTarget
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
	 @usage
	 if target.DebuffRemaining(haunt) <3 and not InFlightToTarget(haunt)
	     Spell(haunt)
     */
    private InFlightToTarget = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const boolean =
            this.OvaleFuture.next.currentCast.spellId == spellId ||
            this.OvaleFuture.InFlight(spellId);
        return ReturnBoolean(boolean);
    };

    /** Test if the distance from the player to the target is within the spell's range.
	 @name InRange
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
	 @usage
	 if target.IsInterruptible() and target.InRange(kick)
	     Spell(kick)
     */
    private InRange = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = this.OvaleSpells.IsSpellInRange(spellId, target);
        return ReturnBoolean(boolean || false);
    };

    /** Test if the target's primary aggro is on the player.
	 Even if the target briefly targets and casts a spell on another raid member,
	 this condition returns true as long as the player is highest on the threat table.
	 @name IsAggroed
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsAggroed() Spell(feign_death)
     */
    private IsAggroed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const [boolean] = UnitDetailedThreatSituation("player", target);
        return ReturnBoolean(boolean || false);
    };

    /**  Test if the target is dead.
	 @name IsDead
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if pet.IsDead() Spell(revive_pet)
     */
    private IsDead = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitIsDead(target);
        return ReturnBoolean(boolean || false);
    };

    /** Test if the target is enraged.
	 @name IsEnraged
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsEnraged() Spell(soothe)
     */
    private IsEnraged = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const aura = this.OvaleAura.GetAura(
            target,
            "enrage",
            atTime,
            "HELPFUL",
            false
        );
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            return [gain, ending];
        }
        return [];
    };

    /**  Test if the player is feared.
	 @name IsFeared
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsFeared() Spell(every_man_for_himself)
     */
    private IsFeared = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            !HasFullControl() &&
            this.OvaleLossOfControl.HasLossOfControl("FEAR", atTime);
        return ReturnBoolean(boolean);
    };

    /** Test if the target is friendly to the player.
	 @name IsFriend
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsFriend() Spell(healing_touch)
     */
    private IsFriend = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitIsFriend("player", target);
        return ReturnBoolean(boolean);
    };

    /** Test if the player is incapacitated.
	 @name IsIncapacitated
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsIncapacitated() Spell(every_man_for_himself)
     */
    private IsIncapacitated = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            !HasFullControl() &&
            this.OvaleLossOfControl.HasLossOfControl("CONFUSE", atTime);
        return ReturnBoolean(boolean);
    };

    /**  Test if the target is currently casting an interruptible spell.
	 @name IsInterruptible
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.IsInterruptible() Spell(kick)
     */
    private IsInterruptible = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let [name, , , , , , , notInterruptible] = UnitCastingInfo(target);
        if (!name) {
            [name, , , , , , notInterruptible] = UnitChannelInfo(target);
        }
        const boolean = notInterruptible != undefined && !notInterruptible;
        return ReturnBoolean(boolean);
    };

    /**  Test if the target is flagged for PvP activity.
	 @name IsPVP
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if not target.IsFriend() and target.IsPVP() Spell(sap)
     */
    private IsPVP = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitIsPVP(target);
        return ReturnBoolean(boolean);
    };
    /** Test if the player is rooted.
	 @name IsRooted
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsRooted() Item(Trinket0Slot usable=1)
     */
    private IsRooted = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = this.OvaleLossOfControl.HasLossOfControl(
            "ROOT",
            atTime
        );
        return ReturnBoolean(boolean);
    };

    /** Test if the player is stunned.
	 @name IsStunned
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsStunned() Item(Trinket0Slot usable=1)
     */
    private IsStunned = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            !HasFullControl() &&
            this.OvaleLossOfControl.HasLossOfControl("STUN_MECHANIC", atTime);
        return ReturnBoolean(boolean);
    };
    /**  Get the current number of charges of the given item in the player's inventory.
	 @name ItemCharges
	 @paramsig number or boolean
	 @return The number of charges.
	 @usage
	 if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
	     Spell(conjure_mana_gem)
     */
    private ItemCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        const value = GetItemCount(itemId, false, true);
        return ReturnConstant(value);
    };

    /** Get the current number of the given item in the player's inventory.
	 Items with more than one charge count as one item.
	 @name ItemCount
	 @paramsig number or boolean
	 @return The count of the item.
	 @usage
	 if ItemCount(mana_gem) == 0 Spell(conjure_mana_gem)
     */
    private ItemCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        const value = GetItemCount(itemId);
        return ReturnConstant(value);
    };

    /** Get the damage done by the most recent damage event for the given spell.
	 If the spell is a periodic aura, then it gives the damage done by the most recent tick.
	 @name LastDamage
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The damage done.
	 @see Damage, LastEstimatedDamage
	 @usage
	 if LastDamage(ignite) > 10000 Spell(combustion)
     */
    private LastDamage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const value = this.OvaleSpellDamage.Get(spellId);
        if (value) {
            return ReturnConstant(value);
        }
        return [];
    };

    /**  Get the level of the target.
	 @name Level
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The level of the target.
	 @usage
	 if Level() >= 34 Spell(tiger_palm)
     */
    private Level = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let value;
        if (target == "player") {
            value = this.OvalePaperDoll.level;
        } else {
            value = UnitLevel(target);
        }
        return ReturnConstant(value);
    };
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
    private List = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [name, value] = [positionalParams[1], positionalParams[2]];
        if (
            name &&
            this.OvaleFrameModule.frame &&
            this.OvaleFrameModule.frame.GetListValue(name) == value
        ) {
            return [0, INFINITY];
        }
        return [];
    };

    /** Test whether the target's name matches the given name.
	 @name Name
	 @paramsig boolean
	 @param name The localized target name.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    private Name = (atTime: number, target: string) => {
        return ReturnConstant(UnitName(target));
    };

    /** Test if the game is on a PTR server
	 @name PTR
	 @paramsig number
	 @return 1 if it is a PTR realm, or 0 if it is a live realm.
	 @usage
	 if PTR() > 0 Spell(wacky_new_spell)
     */
    private PTR = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [version, , , uiVersion] = GetBuildInfo();
        const value = ((version > "9.0.2" || uiVersion > 90002) && 1) || 0;
        return ReturnConstant(value);
    };

    /** Get the persistent multiplier to the given aura if applied.
	 The persistent multiplier is snapshotted to the aura for its duration.
	 @name PersistentMultiplier
	 @paramsig number or boolean
	 @param id The aura ID.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The persistent multiplier.
	 @usage
	 if PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff)
	     Spell(rake)
     */
    private PersistentMultiplier: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.OvaleGUID.UnitGUID(target);
        if (!targetGuid) return [];
        const value = this.OvaleFuture.GetDamageMultiplier(
            spellId,
            targetGuid,
            atTime
        );
        return ReturnConstant(value);
    };

    /** Test if the pet exists and is alive.
	 PetPresent() is equivalent to pet.Present().
	 @name PetPresent
	 @paramsig boolean
	 @return A boolean value.
	 @see Present
	 @usage
	 if target.IsInterruptible() and PetPresent(yes)
	     Spell(pet_pummel)
	 if PetPresent(name=Niuzao) 
	     Spell(provoke_pet)

     */
    private PetPresent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const name = namedParams.name;
        const target = "pet";
        const boolean =
            UnitExists(target) &&
            !UnitIsDead(target) &&
            (name == undefined || name == UnitName(target));
        return ReturnBoolean(boolean);
    };

    /**  Return the maximum power of the given power type on the target.
     */
    private MaxPower(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let value;
        if (target == "player") {
            value = this.OvalePower.current.maxPower[powerType];
        } else {
            const powerInfo = this.OvalePower.POWER_INFO[powerType];
            value =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
        }
        return ReturnConstant(value);
    }
    /** Return the amount of power of the given power type on the target.
     */
    private Power(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        if (target == "player") {
            const value = this.OvalePower.next.power[powerType] || 0;
            const rate = this.OvalePower.getPowerRateAt(
                this.OvalePower.next,
                powerType,
                atTime
            );
            return ReturnValueBetween(atTime, INFINITY, value, atTime, rate);
        } else {
            const powerInfo = this.OvalePower.POWER_INFO[powerType];
            const value = (powerInfo && UnitPower(target, powerInfo.id)) || 0;
            return ReturnConstant(value);
        }
    }
    /**Return the current deficit of power from max power on the target.
     */
    private PowerDeficit(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        if (target == "player") {
            const powerMax = this.OvalePower.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                const power = this.OvalePower.next.power[powerType] || 0;
                const rate = this.OvalePower.getPowerRateAt(
                    this.OvalePower.next,
                    powerType,
                    atTime
                );
                return ReturnValueBetween(
                    atTime,
                    INFINITY,
                    powerMax - power,
                    atTime,
                    -1 * rate
                );
            }
        } else {
            const powerInfo = this.OvalePower.POWER_INFO[powerType];
            const powerMax =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
            if (powerMax > 0) {
                const power =
                    (powerInfo && UnitPower(target, powerInfo.id)) || 0;
                const value = powerMax - power;
                return ReturnConstant(value);
            }
        }
        return ReturnConstant(0);
    }

    /**Return the current percent level of power (between 0 and 100) on the target.
     */
    private PowerPercent(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        if (target == "player") {
            const powerMax = this.OvalePower.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                const ratio = 100 / powerMax;
                const power = this.OvalePower.next.power[powerType] || 0;
                let rate =
                    ratio *
                    this.OvalePower.getPowerRateAt(
                        this.OvalePower.next,
                        powerType,
                        atTime
                    );
                if (
                    (rate > 0 && power >= powerMax) ||
                    (rate < 0 && power == 0)
                ) {
                    rate = 0;
                }
                return ReturnValueBetween(
                    atTime,
                    INFINITY,
                    power * ratio,
                    atTime,
                    rate
                );
            }
        } else {
            const powerInfo = this.OvalePower.POWER_INFO[powerType];
            const powerMax =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
            if (powerMax > 0) {
                const ratio = 100 / powerMax;
                const value =
                    (powerInfo && ratio * UnitPower(target, powerInfo.id)) || 0;
                return ReturnConstant(value);
            }
        }
        return ReturnConstant(0);
    }

    /**
     Get the current amount of alternate power displayed on the alternate power bar.
	 @name AlternatePower
	 @paramsig number or boolean
	 @return The current alternate power.
     */
    private AlternatePower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("alternate", positionalParams, namedParams, atTime);
    };
    /** Get the current amount of astral power for balance druids.
	 @name AstralPower
	 @paramsig number or boolean
	 @return The current runic power.
	 @usage
	 if AstraPower() > 70 Spell(frost_strike)
     */
    private AstralPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("lunarpower", positionalParams, namedParams, atTime);
    };

    /**Get the current amount of stored Chi for monks.
	 @name Chi
	 @paramsig number or boolean
	 @return The amount of stored Chi.
	 @usage
	 if Chi() == 4 Spell(chi_burst)
     */
    private Chi = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("chi", positionalParams, namedParams, atTime);
    };
    /**  Get the number of combo points for a feral druid or a rogue.
     @name ComboPoints
     @paramsig number or boolean
     @return The number of combo points.
     @usage
     if ComboPoints() >=1 Spell(savage_roar)
     */
    private ComboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("combopoints", positionalParams, namedParams, atTime);
    };
    /**Get the current amount of energy for feral druids, non-mistweaver monks, and rogues.
	 @name Energy
	 @paramsig number or boolean
	 @return The current energy.
	 @usage
	 if Energy() > 70 Spell(vanish)
     */
    private Energy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("energy", positionalParams, namedParams, atTime);
    };

    /**Get the current amount of focus for hunters.
	 @name Focus
	 @paramsig number or boolean
	 @return The current focus.
	 @usage
	 if Focus() > 70 Spell(arcane_shot)
     */
    private Focus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("focus", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private Fury = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("fury", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of holy power for a paladin.
	 @name HolyPower
	 @paramsig number or boolean
	 @return The amount of holy power.
	 @usage
	 if HolyPower() >= 3 Spell(word_of_glory)
     */
    private HolyPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("holypower", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private Insanity = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("insanity", positionalParams, namedParams, atTime);
    };

    /**  Get the current level of mana of the target.
	 @name Mana
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana.
	 @usage
	 if {MaxMana() - Mana()} > 12500 Item(mana_gem)
        */
    private Mana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("mana", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private Maelstrom = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("maelstrom", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private Pain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("pain", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of rage for guardian druids and warriors.
	 @name Rage
	 @paramsig number or boolean
	 @return The current rage.
	 @usage
	 if Rage() > 70 Spell(heroic_strike)
     */
    private Rage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("rage", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of runic power for death knights.
	 @name RunicPower
	 @paramsig number or boolean
	 @return The current runic power.
	 @usage
	 if RunicPower() > 70 Spell(frost_strike)
     */
    private RunicPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("runicpower", positionalParams, namedParams, atTime);
    };

    /** Get the current number of Soul Shards for warlocks.
	 @name SoulShards
	 @paramsig number or boolean
	 @return The number of Soul Shards.
	 @usage
	 if SoulShards() > 0 Spell(summon_felhunter)
     */
    private SoulShards = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power("soulshards", positionalParams, namedParams, atTime);
    };
    private ArcaneCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Power(
            "arcanecharges",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the number of lacking resource points for a full alternate power bar, between 0 and maximum alternate power, of the target.
	 @name AlternatePowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current alternate power deficit.
     */
    private AlternatePowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "alternate",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	 @name AstralPowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current runic power deficit.
     */
    private AstralPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "lunarpower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the number of lacking resource points for full chi, between 0 and maximum chi, of the target.
	 @name ChiDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current chi deficit.
	 @usage
	 if ChiDeficit() >= 2 Spell(keg_smash)
     */
    private ChiDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit("chi", positionalParams, namedParams, atTime);
    };
    /**
     * @name ComboPointsDeficit
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private ComboPointsDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "combopoints",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the number of lacking resource points for a full energy bar, between 0 and maximum energy, of the target.
	 @name EnergyDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current energy deficit.
	 @usage
	 if EnergyDeficit() > 60 Spell(tigers_fury)
     */
    private EnergyDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "energy",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the number of lacking resource points for a full focus bar, between 0 and maximum focus, of the target.
	 @name FocusDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current focus deficit.
     */
    private FocusDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "focus",
            positionalParams,
            namedParams,
            atTime
        );
    };
    private FuryDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit("fury", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for full holy power, between 0 and maximum holy power, of the target.
	 @name HolyPowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current holy power deficit.
     */
    private HolyPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "holypower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the number of lacking resource points for a full mana bar, between 0 and maximum mana, of the target.
	 @name ManaDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana deficit.
	 @usage
	 if ManaDeficit() > 30000 Item(mana_gem)
     */
    private ManaDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit("mana", positionalParams, namedParams, atTime);
    };
    private PainDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit("pain", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for a full rage bar, between 0 and maximum rage, of the target.
	 @name RageDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current rage deficit.
     */
    private RageDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit("rage", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	 @name RunicPowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current runic power deficit.
     */
    private RunicPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "runicpower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the number of lacking resource points for full soul shards, between 0 and maximum soul shards, of the target.
	 @name SoulShardsDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current soul shards deficit.
     */
    private SoulShardsDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerDeficit(
            "soulshards",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current percent level of mana (between 0 and 100) of the target.
	 @name ManaPercent
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current mana percent.
	 @usage
	 if ManaPercent() > 90 Spell(arcane_blast)
     */
    private ManaPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerPercent("mana", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of alternate power of the target.
	 Alternate power is the resource tracked by the alternate power bar in certain boss fights.
	 @name MaxAlternatePower
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxAlternatePower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "alternate",
            positionalParams,
            namedParams,
            atTime
        );
    };
    private MaxChi = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("chi", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of Chi of the target.
	 @name MaxChi
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.

l    */
    private MaxComboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "combopoints",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the maximum amount of energy of the target.
	 @name MaxEnergy
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("energy", positionalParams, namedParams, atTime);
    };

    /**  Get the maximum amount of focus of the target.
	 @name MaxFocus
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("focus", positionalParams, namedParams, atTime);
    };
    private MaxFury = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("fury", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of Holy Power of the target.
	 @name MaxHolyPower
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxHolyPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "holypower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the maximum amount of mana of the target.
	 @name MaxMana
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
	 @usage
	 if {MaxMana() - Mana()} > 12500 Item(mana_gem)
     */
    private MaxMana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("mana", positionalParams, namedParams, atTime);
    };
    private MaxPain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("pain", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of rage of the target.
	 @name MaxRage
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxRage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower("rage", positionalParams, namedParams, atTime);
    };

    /**  Get the maximum amount of Runic Power of the target.
	 @name MaxRunicPower
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxRunicPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "runicpower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the maximum amount of Soul Shards of the target.
	 @name MaxSoulShards
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxSoulShards = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "soulshards",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the maximum amount of Arcane Charges of the target.
	 @name MaxArcaneCharges
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private MaxArcaneCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.MaxPower(
            "arcanecharges",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Return the amount of power of the given power type required to cast the given spell.
     */
    private PowerCost(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const spell = <number>positionalParams[1];
        const spellId = this.OvaleSpellBook.getKnownSpellId(spell);
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const maxCost = namedParams.max == 1;
        const [value] = (spellId &&
            this.OvalePower.PowerCost(
                spellId,
                powerType,
                atTime,
                target,
                maxCost
            )) || [0];
        return ReturnConstant(value);
    }

    /** Get the amount of energy required to cast the given spell.
	 This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	 @name EnergyCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param max Optional. Set max=1 to return the maximum energy cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of energy.
     */
    private EnergyCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost("energy", positionalParams, namedParams, atTime);
    };

    /** Get the amount of focus required to cast the given spell.
	 @name FocusCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param max Optional. Set max=1 to return the maximum focus cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of focus.
     */
    private FocusCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost("focus", positionalParams, namedParams, atTime);
    };

    /**  Get the amount of mana required to cast the given spell.
	 This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	 @name ManaCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param max Optional. Set max=1 to return the maximum mana cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of mana.
     */
    private ManaCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost("mana", positionalParams, namedParams, atTime);
    };

    /** Get the amount of rage required to cast the given spell.
	 @name RageCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param max Optional. Set max=1 to return the maximum rage cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of rage.
     */
    private RageCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost("rage", positionalParams, namedParams, atTime);
    };

    /** Get the amount of runic power required to cast the given spell.
	 @name RunicPowerCost
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param max Optional. Set max=1 to return the maximum runic power cost for the spell.
	     Defaults to max=0.
	     Valid values: 0, 1
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of runic power.
     */
    private RunicPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost(
            "runicpower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private AstralPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost(
            "lunarpower",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private MainPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.PowerCost(
            this.OvalePower.current.powerType,
            positionalParams,
            namedParams,
            atTime
        );
    };
    /** Test if the target exists and is alive.
	 @name Present
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @see Exists
	 @usage
	 if target.IsInterruptible() and pet.Present(yes)
	     Spell(pet_pummel)
     */
    private Present = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitExists(target) && !UnitIsDead(target);
        return ReturnBoolean(boolean);
    };

    /** Test if the previous spell cast that invoked the GCD matches the given spell.
	 @name PreviousGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private PreviousGCDSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.OvaleSpellBook.getKnownSpellId(spell);
        const count = namedParams.count as number | undefined;
        let boolean;
        if (count && count > 1) {
            boolean =
                spellId ==
                this.OvaleFuture.next.lastGCDSpellIds[
                    lualength(this.OvaleFuture.next.lastGCDSpellIds) - count + 2
                ];
        } else {
            boolean = spellId == this.OvaleFuture.next.lastGCDSpellId;
        }
        return ReturnBoolean(boolean);
    };

    /** Test if the previous spell cast that did not trigger the GCD matches the given spell.
	 @name PreviousOffGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private PreviousOffGCDSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.OvaleSpellBook.getKnownSpellId(spell);
        const boolean =
            spellId == this.OvaleFuture.next.lastOffGCDSpellcast.spellId;
        return ReturnBoolean(boolean);
    };

    /**  Test if the previous spell cast matches the given spell.
	 @name PreviousSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private PreviousSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.OvaleSpellBook.getKnownSpellId(spell);
        const boolean = spellId == this.OvaleFuture.next.lastGCDSpellId;
        return ReturnBoolean(boolean);
    };

    /**  Get the result of the target's level minus the player's level. This number may be negative.
	 @name RelativeLevel
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The difference in levels.
	 @usage
	 if target.RelativeLevel() > 3
	     Texture(ability_rogue_sprint)
     */
    private RelativeLevel = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let value, level;
        if (target == "player") {
            level = this.OvalePaperDoll.level;
        } else {
            level = UnitLevel(target);
        }
        if (level < 0) {
            value = 3;
        } else {
            value = level - this.OvalePaperDoll.level;
        }
        return ReturnConstant(value);
    };

    private Refreshable = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            let baseDuration = this.OvaleAura.GetBaseDuration(
                auraId,
                undefined,
                atTime
            );
            if (baseDuration === INFINITY) {
                baseDuration = aura.ending - aura.start;
            }
            const extensionDuration = 0.3 * baseDuration;
            return [aura.ending - extensionDuration, INFINITY];
        }
        return [0, INFINITY];
    };

    /** Get the remaining cast time in seconds of the target's current spell cast.
	 @name RemainingCastTime
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see CastTime
	 @usage
	 if target.Casting(hour_of_twilight) and target.RemainingCastTime() <2
	     Spell(cloak_of_shadows)
     */
    private RemainingCastTime: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        let [, , , startTime, endTime] = UnitCastingInfo(target);
        if (startTime && endTime) {
            startTime = startTime / 1000;
            endTime = endTime / 1000;
            return ReturnValueBetween(startTime, endTime, 0, endTime, -1);
        }
        return [];
    };

    /**  Get the current number of active and regenerating (fractional) runes of the given type for death knights.
	 @name Rune
	 @paramsig number or boolean
	 @return The number of runes.
	 @see RuneCount
	 @usage
	 if Rune() > 1 Spell(blood_tap)
     */
    private Rune = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] = this.OvaleRunes.RuneCount(
            atTime
        );
        if (startCooldown < INFINITY) {
            const rate = 1 / (endCooldown - startCooldown);
            return ReturnValueBetween(
                startCooldown,
                INFINITY,
                count,
                startCooldown,
                rate
            );
        }
        return ReturnConstant(count);
    };

    private RuneDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] = this.OvaleRunes.RuneDeficit(
            atTime
        );
        if (startCooldown < INFINITY) {
            const rate = -1 / (endCooldown - startCooldown);
            return ReturnValueBetween(
                startCooldown,
                INFINITY,
                count,
                startCooldown,
                rate
            );
        }
        return ReturnConstant(count);
    };

    /**  Get the current number of active runes of the given type for death knights.
	 @name RuneCount
	 @paramsig number or boolean
	 @param death Optional. Set death=1 to include all active death runes in the count. Set death=0 to exclude all death runes.
	     Defaults to unset.
	     Valid values: unset, 0, 1
	 @return The number of runes.
	 @see Rune
	 @usage
	 if RuneCount() ==2
	     Spell(obliterate)
     */
    private RuneCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] = this.OvaleRunes.RuneCount(
            atTime
        );
        if (startCooldown < INFINITY) {
            return ReturnValueBetween(
                startCooldown,
                endCooldown,
                count,
                startCooldown,
                0
            );
        }
        return ReturnConstant(count);
    };

    /**  Get the number of seconds before the player reaches the given amount of runes.
	 @name TimeToRunes
	 @paramsig number or boolean
	 @param runes. The amount of runes to reach.
	 @return The number of seconds.
	 @usage
	 if TimeToRunes(2) > 5 Spell(horn_of_winter)
     */
    private TimeToRunes = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const runes = positionalParams[1];
        let seconds = this.OvaleRunes.GetRunesCooldown(atTime, runes);
        if (seconds < 0) {
            seconds = 0;
        }
        return ReturnValue(seconds, atTime, -1);
    };

    /**  Returns the value of the given snapshot stat.
     */
    private Snapshot(
        statName: keyof PaperDollData,
        defaultValue: number,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const value =
            this.OvalePaperDoll.GetState(atTime)[statName] || defaultValue;
        return ReturnConstant(value);
    }

    /**  Returns the critical strike chance of the given snapshot stat.
     */
    private SnapshotCritChance(
        statName: keyof PaperDollData,
        defaultValue: number,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        let value =
            this.OvalePaperDoll.GetState(atTime)[statName] || defaultValue;
        if (namedParams.unlimited != 1 && value > 100) {
            value = 100;
        }
        return ReturnConstant(value);
    }

    /** Get the current agility of the player.
	 @name Agility
	 @paramsig number or boolean
	 @return The current agility.
     */
    private Agility = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "agility",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current attack power of the player.
	 @name AttackPower
	 @paramsig number or boolean
	 @return The current attack power.
     */
    private AttackPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "attackPower",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current critical strike rating of the player.
	 @name CritRating
	 @paramsig number or boolean
	 @return The current critical strike rating.
     */
    private CritRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "critRating",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current haste rating of the player.
	 @name HasteRating
	 @paramsig number or boolean
	 @return The current haste rating.
     */
    private HasteRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "hasteRating",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current intellect of the player.
	 @name Intellect
	 @paramsig number or boolean
	 @return The current intellect.
     */
    private Intellect = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "intellect",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current mastery effect of the player.
	 Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
	 or a percent-increase to chance to trigger some effect.
	 @name MasteryEffect
	 @paramsig number or boolean
	 @return The current mastery effect.
     */
    private MasteryEffect = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "masteryEffect",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current mastery rating of the player.
	 @name MasteryRating
	 @paramsig number or boolean
	 @return The current mastery rating.
     */
    private MasteryRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "masteryRating",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current melee critical strike chance of the player.
	 @name MeleeCritChance
	 @paramsig number or boolean
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
     */
    private MeleeCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.SnapshotCritChance(
            "meleeCrit",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the current percent increase to melee haste of the player.
	 @name MeleeAttackSpeedPercent
	 @paramsig number or boolean
	 @return The current percent increase to melee haste.
     */
    private MeleeAttackSpeedPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "meleeAttackSpeedPercent",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current ranged critical strike chance of the player.
	 @name RangedCritChance
	 @paramsig number or boolean
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
     */
    private RangedCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.SnapshotCritChance(
            "rangedCrit",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the current spell critical strike chance of the player.
	 @name SpellCritChance
	 @paramsig number or boolean
	 @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	     Defaults to unlimited=0.
	     Valid values: 0, 1
	 @return The current critical strike chance (in percent).
     */
    private SpellCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.SnapshotCritChance(
            "spellCrit",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the current percent increase to spell haste of the player.
	 @name SpellCastSpeedPercent
	 @paramsig number or boolean
	 @return The current percent increase to spell haste.
     */
    private SpellCastSpeedPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "spellCastSpeedPercent",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current spellpower of the player.
	 @name Spellpower
	 @paramsig number or boolean
	 @return The current spellpower.
     */
    private Spellpower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "spellPower",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current stamina of the player.
	 @name Stamina
	 @paramsig number or boolean
	 @return The current stamina.
     */
    private Stamina = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "stamina",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current strength of the player.
	 @name Strength
	 @paramsig number or boolean
	 @return The current strength.
     */
    private Strength = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "strength",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    private Versatility = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "versatility",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    private VersatilityRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.Snapshot(
            "versatilityRating",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the current speed of the target.
	 If the target is not moving, then this condition returns 0 (zero).
	 If the target is at running speed, then this condition returns 100.
	 @name Speed
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The speed of the target.
	 @usage
	 if Speed() > 0 and not BuffPresent(aspect_of_the_fox)
	     Spell(aspect_of_the_fox)
     */
    private Speed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const value = (GetUnitSpeed(target) * 100) / 7;
        return ReturnConstant(value);
    };

    /** Get the cooldown in seconds on a spell before it gains another charge.
	 @name SpellChargeCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see SpellCharges
	 @usage
	 if SpellChargeCooldown(roll) <2
	     Spell(roll usable=1)
     */
    private SpellChargeCooldown = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [
            charges,
            maxCharges,
            start,
            duration,
        ] = this.OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            const ending = start + duration;
            return ReturnValueBetween(start, ending, duration, start, -1);
        }
        return ReturnConstant(0);
    };

    /** Get the number of charges of the spell.
	 @name SpellCharges
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param count Optional. Sets whether a count or a fractional value is returned.
	     Defaults to count=1.
	     Valid values: 0, 1.
	 @return The number of charges.
	 @see SpellChargeCooldown
	 @usage
	 if SpellCharges(savage_defense) >1
	     Spell(savage_defense)
     */
    private SpellCharges: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [
            charges,
            maxCharges,
            start,
            duration,
        ] = this.OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (namedParams.count == 0 && charges < maxCharges) {
            return ReturnValueBetween(
                atTime,
                INFINITY,
                charges + 1,
                start + duration,
                1 / duration
            );
        }
        return ReturnConstant(charges);
    };

    /** Get the number of seconds for a full recharge of the spell.
     * @name SpellFullRecharge
     * @paramsig number or boolean
     * @param id The spell ID.
     * @usage
     * if SpellFullRecharge(dire_frenzy) < GCD()
     *     Spell(dire_frenzy) */
    private SpellFullRecharge = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [
            charges,
            maxCharges,
            start,
            chargeDuration,
        ] = this.OvaleCooldown.GetSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            const duration = (maxCharges - charges) * chargeDuration;
            const ending = start + duration;
            return ReturnValueBetween(start, ending, duration, start, -1);
        }
        return ReturnConstant(0);
    };

    /** Get the number of seconds before any of the listed spells are ready for use.
	 @name SpellCooldown
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param ... Optional. Additional spell IDs.
	 @return The number of seconds.
	 @see TimeToSpell
	 @usage
	 if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
	     Spell(devouring_plague)
     */
    private SpellCooldown: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const usable = namedParams.usable == 1;
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.OvaleGUID.UnitGUID(target);
        if (!targetGuid) return [];
        let earliest = INFINITY;
        for (const [, spellId] of ipairs(positionalParams)) {
            if (
                !usable ||
                this.OvaleSpells.IsUsableSpell(spellId, atTime, targetGuid)
            ) {
                const [start, duration] = this.OvaleCooldown.GetSpellCooldown(
                    spellId,
                    atTime
                );
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
            return ReturnConstant(0);
        } else if (earliest > 0) {
            return ReturnValue(0, earliest, -1);
        }
        return ReturnConstant(0);
    };

    /** Get the cooldown duration in seconds for a given spell.
	 @name SpellCooldownDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
     */
    private SpellCooldownDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const duration = this.OvaleCooldown.GetSpellCooldownDuration(
            spellId,
            atTime,
            target
        );
        return ReturnConstant(duration);
    };

    /** Get the recharge duration in seconds for a given spell.
	 @name SpellRechargeDuration
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
     */
    private SpellRechargeDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const cd = this.OvaleCooldown.GetCD(spellId, atTime);
        const duration =
            cd.chargeDuration ||
            this.OvaleCooldown.GetSpellCooldownDuration(
                spellId,
                atTime,
                target
            );
        return ReturnConstant(duration);
    };

    /** Get data for the given spell defined by SpellInfo(...)
	 @name SpellData
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param key The name of the data set by SpellInfo(...).
	     Valid values are any alphanumeric string.
	 @return The number data associated with the given key.
	 @usage
	 if BuffRemaining(slice_and_dice) >= SpellData(shadow_blades duration)
	     Spell(shadow_blades)
     */
    private SpellData: ConditionFunction = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [spellId, key] = [
            <number>positionalParams[1],
            <keyof SpellInfo>positionalParams[2],
        ];
        const si = this.OvaleData.spellInfo[spellId];
        if (si) {
            const value = si[key];
            if (value) {
                return ReturnConstant(<number>value);
            }
        }
        return [];
    };

    /** Get data for the given spell defined by SpellInfo(...) after calculations
	 @name SpellInfoProperty
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param key The name of the data set by SpellInfo(...).
	     Valid values are any alphanumeric string.
	 @return The number data associated with the given key after calculations
	 @usage
	 if Insanity() + SpellInfoProperty(mind_blast insanity) < 100
	     Spell(mind_blast)
     */
    private SpellInfoProperty: ConditionFunction = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [spellId, key] = [
            <number>positionalParams[1],
            <SpellInfoProperty>positionalParams[2],
        ];
        const value = this.OvaleData.GetSpellInfoProperty(
            spellId,
            atTime,
            key,
            undefined
        );
        if (value) {
            return ReturnConstant(<number>value);
        }
        return [];
    };

    /** Returns the number of times a spell can be cast. Generally used for spells whose casting is limited by the number of item reagents in the player's possession. .
	 @name SpellCount
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of times a spell can be cast.
	 @usage
	 if SpellCount(expel_harm) > 1
         Spell(expel_harm)  
     */
    private SpellCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const spellCount = this.OvaleSpells.GetSpellCount(spellId);
        return ReturnConstant(spellCount);
    };

    /** Test if the given spell is in the spellbook.
	 A spell is known if the player has learned the spell and it is in the spellbook.
	 @name SpellKnown
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
	 @see SpellUsable
     */
    private SpellKnown = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const boolean = this.OvaleSpellBook.IsKnownSpell(spellId);
        return ReturnBoolean(boolean);
    };

    /** Get the maximum number of charges of the spell.
	 @name SpellMaxCharges
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param count Optional. Sets whether a count or a fractional value is returned.
	     Defaults to count=1.
	     Valid values: 0, 1.
	 @return The number of charges.
	 @see SpellChargeCooldown
	 @usage
	 if SpellCharges(savage_defense) >1
	     Spell(savage_defense)
     */
    private SpellMaxCharges: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        let [, maxCharges, ,] = this.OvaleCooldown.GetSpellCharges(
            spellId,
            atTime
        );
        if (!maxCharges) {
            return [];
        }
        maxCharges = maxCharges || 1;
        return ReturnConstant(maxCharges);
    };

    /** Test if the given spell is usable.
	 A spell is usable if the player has learned the spell and meets any requirements for casting the spell.
	 Does not account for spell cooldowns or having enough of a primary (pooled) resource.
	 @name SpellUsable
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
	 @see SpellKnown
     */
    private SpellUsable: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.OvaleGUID.UnitGUID(target);
        if (!targetGuid) return [];
        const [isUsable, noMana] = this.OvaleSpells.IsUsableSpell(
            spellId,
            atTime,
            targetGuid
        );
        const boolean = isUsable || noMana;
        return ReturnBoolean(boolean);
    };

    /** Test if the player is currently stealthed.
	 The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
	 @name Stealthed
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if Stealthed() or BuffPresent(shadow_dance)
	     Spell(ambush)
     */
    private Stealthed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            this.OvaleAura.GetAura(
                "player",
                "stealthed_buff",
                atTime,
                "HELPFUL"
            ) !== undefined || IsStealthed();
        return ReturnBoolean(boolean);
    };

    /** Get the time elapsed in seconds since the player's previous melee swing (white attack).
	 @name LastSwing
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon's melee swing.
	     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
	     Valid values: main, off.
	 @return The number of seconds.
	 @see NextSwing
     */
    private LastSwing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        //const swing = positionalParams[1];
        const start = 0;
        OneTimeMessage("Warning: 'LastSwing()' is not implemented.");
        return ReturnValueBetween(start, INFINITY, 0, start, 1);
    };

    /** Get the time in seconds until the player's next melee swing (white attack).
	 @name NextSwing
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon's melee swing.
	     If no hand is specified, then return the time until the next swing of either hand's weapon.
	     Valid values: main, off.
	 @return The number of seconds
	 @see LastSwing
     */
    private NextSwing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        //const swing = positionalParams[1];
        const ending = 0;
        OneTimeMessage("Warning: 'NextSwing()' is not implemented.");
        return ReturnValueBetween(0, ending, 0, ending, -1);
    };

    /** Test if the given talent is active.
	 @name Talent
	 @paramsig boolean
	 @param id The talent ID.
	 @return A boolean value.
	 @usage
	 if Talent(blood_tap_talent) Spell(blood_tap)
     */
    private Talent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const talentId = positionalParams[1];
        const boolean = this.OvaleSpellBook.GetTalentPoints(talentId) > 0;
        return ReturnBoolean(boolean);
    };

    /** Get the number of points spent in a talent (0 or 1)
	 @name TalentPoints
	 @paramsig number or boolean
	 @param talent Talent to inspect.
	 @return The number of talent points.
	 @usage
	 if TalentPoints(blood_tap_talent) Spell(blood_tap)
     */
    private TalentPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const talent = positionalParams[1];
        const value = this.OvaleSpellBook.GetTalentPoints(talent);
        return ReturnConstant(value);
    };

    /** Test if the player is the in-game target of the target.
	 @name TargetIsPlayer
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if target.TargetIsPlayer() Spell(feign_death)
     */
    private TargetIsPlayer = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        const boolean = UnitIsUnit("player", `${target}target`);
        return ReturnBoolean(boolean);
    };

    /** Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
	 This is a number between 0 (no threat) and 100 (will become the primary aggro target).
	 @name Threat
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The amount of threat.
	 @usage
	 if Threat() > 90 Spell(fade)
     */
    private Threat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const [, , value] = UnitDetailedThreatSituation("player", target);
        return ReturnConstant(value);
    };

    /** Get the number of seconds between ticks of a periodic aura on a target.
	 @name TickTime
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param filter Optional. The type of aura to check.
	     Default is any.
	     Valid values: any, buff, debuff
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see TicksRemaining
     */
    private TickTime = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = <number>positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        let tickTime;
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            tickTime = aura.tick;
        } else {
            tickTime = this.OvaleAura.GetTickLength(
                auraId,
                this.OvalePaperDoll.next
            );
        }
        if (tickTime && tickTime > 0) {
            return ReturnConstant(tickTime);
        }
        return ReturnConstant(INFINITY);
    };

    private CurrentTickTime = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = <number>positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        let tickTime;
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            tickTime = aura.tick || 0;
        } else {
            tickTime = 0;
        }
        return ReturnConstant(tickTime);
    };

    /** Get the remaining number of ticks of a periodic aura on a target.
	 @name TicksRemaining
	 @paramsig number or boolean
	 @param id The spell ID of the aura or the name of a spell list.
	 @param filter Optional. The type of aura to check.
	     Default is any.
	     Valid values: any, buff, debuff
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The number of ticks.
	 @see TickTime
	 @usage
	 if target.TicksRemaining(shadow_word_pain) <2
	     Spell(shadow_word_pain)
     */
    private TicksRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura) {
            const tick = aura.tick;
            if (tick && tick > 0) {
                return ReturnValueBetween(
                    aura.gain,
                    INFINITY,
                    1,
                    aura.ending,
                    -1 / tick
                );
            }
        }
        return ReturnConstant(0);
    };

    /** Gets the remaining time until the next tick */
    private TickTimeRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.ParseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.OvaleAura.GetAura(
            target,
            auraId,
            atTime,
            filter,
            mine
        );
        if (aura && this.OvaleAura.IsActiveAura(aura, atTime)) {
            const lastTickTime = aura.lastTickTime || aura.start;
            const tick =
                aura.tick ||
                this.OvaleAura.GetTickLength(auraId, this.OvalePaperDoll.next);
            const remainingTime = tick - (atTime - lastTickTime);
            if (remainingTime && remainingTime > 0) {
                return ReturnValueBetween(
                    aura.gain,
                    INFINITY,
                    tick,
                    lastTickTime,
                    -1
                );
            }
        }
        return ReturnConstant(0);
    };

    /** Get the number of seconds elapsed since the player cast the given spell.
	 @name TimeSincePreviousSpell
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @usage
	 if TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
     */
    private TimeSincePreviousSpell: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.OvaleSpellBook.getKnownSpellId(spell);
        if (!spellId) return [];
        const t = this.OvaleFuture.TimeOfLastCast(spellId, atTime);
        return ReturnValue(0, t, 1);
    };

    /** Get the time in seconds until the next scheduled Bloodlust cast.
	 Not implemented, always returns 3600 seconds.
	 @name TimeToBloodlust
	 @paramsig number or boolean
	 @return The number of seconds.
     */
    private TimeToBloodlust = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 3600;
        return ReturnConstant(value);
    };

    private TimeToEclipse = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 3600 * 24 * 7;
        OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.");
        return ReturnValue(value, atTime, -1);
    };

    /** Get the number of seconds before the player reaches the given power level.
     */
    private TimeToPower(powerType: PowerType, level: number, atTime: number) {
        level = level || 0;
        const seconds = this.OvalePower.getTimeToPowerAt(
            this.OvalePower.next,
            level,
            powerType,
            atTime
        );
        if (seconds == 0) {
            return ReturnConstant(0);
        } else if (seconds < INFINITY) {
            // XXX Why isn't this (atTime, atTime + seconds)?
            return ReturnValueBetween(0, atTime + seconds, seconds, atTime, -1);
        } else {
            return ReturnConstant(INFINITY);
        }
    }

    /** Get the number of seconds before the player reaches the given energy level for feral druids, non-mistweaver monks and rogues.
	 @name TimeToEnergy
	 @paramsig number or boolean
	 @param level. The level of energy to reach.
	 @return The number of seconds.
	 @see TimeToEnergyFor, TimeToMaxEnergy
	 @usage
	 if TimeToEnergy(100) < 1.2 Spell(sinister_strike)
     */
    private TimeToEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const level = positionalParams[1];
        return this.TimeToPower("energy", level, atTime);
    };

    /** Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	 @name TimeToMaxEnergy
	 @paramsig number or boolean
	 @return The number of seconds.
	 @see TimeToEnergy, TimeToEnergyFor
	 @usage
	 if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)
     */
    private TimeToMaxEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType = "energy";
        const level = this.OvalePower.current.maxPower[powerType] || 0;
        return this.TimeToPower(powerType, level, atTime);
    };

    /** Get the number of seconds before the player reaches the given focus level for hunters.
	 @name TimeToFocus
	 @paramsig number or boolean
	 @param level. The level of focus to reach.
	 @return The number of seconds.
	 @see TimeToFocusFor, TimeToMaxFocus
	 @usage
	 if TimeToFocus(100) < 1.2 Spell(cobra_shot)
     */
    private TimeToFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const level = positionalParams[1];
        return this.TimeToPower("focus", level, atTime);
    };

    /** Get the number of seconds before the player reaches maximum focus for hunters.
	 @name TimeToMaxFocus
	 @paramsig number or boolean
	 @return The number of seconds.
	 @see TimeToFocus, TimeToFocusFor
	 @usage
	 if TimeToMaxFocus() < 1.2 Spell(cobra_shot)
     */
    private TimeToMaxFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType: PowerType = "focus";
        const level = this.OvalePower.current.maxPower[powerType] || 0;
        return this.TimeToPower(powerType, level, atTime);
    };

    private TimeToMaxMana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType: PowerType = "mana";
        const level = this.OvalePower.current.maxPower[powerType] || 0;
        return this.TimeToPower(powerType, level, atTime);
    };

    private TimeToPowerFor(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult {
        const spellId = <number>positionalParams[1];
        const [target] = this.ParseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.OvaleGUID.UnitGUID(target);
        if (!targetGuid) return [];
        const seconds = this.OvaleSpells.TimeToPowerForSpell(
            spellId,
            atTime,
            targetGuid,
            powerType
        );
        if (seconds == 0) {
            return ReturnConstant(0);
        } else if (seconds < INFINITY) {
            // XXX Why isn't this (atTime, atTime + seconds)?
            return ReturnValueBetween(0, atTime + seconds, seconds, atTime, -1);
        } else {
            return ReturnConstant(INFINITY);
        }
    }
    /** Get the number of seconds before the player has enough energy to cast the given spell.
	 @name TimeToEnergyFor
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @see TimeToEnergyFor, TimeToMaxEnergy
     */
    private TimeToEnergyFor: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.TimeToPowerFor(
            "energy",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Get the number of seconds before the player has enough focus to cast the given spell.
	 @name TimeToFocusFor
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @see TimeToFocusFor
     */
    private TimeToFocusFor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.TimeToPowerFor(
            "focus",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /** Get the number of seconds before the spell is ready to be cast, either due to cooldown or resources.
	 @name TimeToSpell
	 @paramsig number or boolean
	 @param id The spell ID.
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
     */
    private TimeToSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        /*
        let [target] = private ParseCondition = (positionalParams, namedParams, "target");
        let seconds = OvaleSpells.GetTimeToSpell(spellId, atTime, OvaleGUID.UnitGUID(target));
        if (seconds == 0) {
            return ReturnConstant(0);
        } else if (seconds < INFINITY) {
            return ReturnValueBetween(0, atTime + seconds, seconds, atTime, -1);
        } else {
            return ReturnConstant(INFINITY);
        }
        */
        OneTimeMessage("Warning: 'TimeToSpell()' is not implemented.");
        return ReturnValue(0, atTime, -1);
    };
    /** Get the time scaled by the specified haste type, defaulting to spell haste.
	 For example, if a DoT normally ticks every 3 seconds and is scaled by spell haste, then it ticks every TimeWithHaste(3 haste=spell) seconds.
	 @name TimeWithHaste
	 @paramsig number or boolean
	 @param time The time in seconds.
	 @param haste Optional. Sets whether "time" should be lengthened or shortened due to haste.
	     Defaults to haste=spell.
	     Valid values: melee, spell.
	 @return The time in seconds scaled by haste.
	 @usage
	 if target.DebuffRemaining(flame_shock) < TimeWithHaste(3)
	     Spell(flame_shock)
     */
    private TimeWithHaste = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const seconds = positionalParams[1];
        const haste = (namedParams.haste as HasteType) || "spell";
        const value = this.GetHastedTime(seconds, haste);
        return ReturnConstant(value);
    };

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
    private TotemExpires = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const id = positionalParams[1];
        let seconds = positionalParams[2];
        seconds = seconds || 0;
        const [count, , ending] = this.OvaleTotem.GetTotemInfo(id, atTime);
        if (count !== undefined && ending !== undefined && count > 0) {
            return [ending - seconds, INFINITY];
        }
        return [0, INFINITY];
    };

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
    private TotemPresent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const id = positionalParams[1];
        const [count, start, ending] = this.OvaleTotem.GetTotemInfo(id, atTime);
        if (
            count !== undefined &&
            ending !== undefined &&
            start !== undefined &&
            count > 0
        ) {
            return [start, ending];
        }
        return [];
    };

    /** Get the remaining time in seconds before a totem expires.
	 @name TotemRemaining
	 @paramsig number or boolean
	 @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	 @return The number of seconds.
	 @see TotemExpires, TotemPresent
	 @usage
	 if TotemRemaining(healing_stream_totem) <2 Spell(totemic_recall)
     */
    private TotemRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const id = positionalParams[1];
        const [count, start, ending] = this.OvaleTotem.GetTotemInfo(id, atTime);
        if (
            count !== undefined &&
            start !== undefined &&
            ending !== undefined &&
            count > 0
        ) {
            return ReturnValueBetween(start, ending, 0, ending, -1);
        }
        return ReturnConstant(0);
    };

    /** Check if a tracking is enabled
	@param spellId the spell id
	@return bool
     */
    private Tracking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const spellName = this.OvaleSpellBook.GetSpellName(spellId);
        const numTrackingTypes = GetNumTrackingTypes();
        let boolean = false;
        for (let i = 1; i <= numTrackingTypes; i += 1) {
            const [name, , active] = GetTrackingInfo(i);
            if (name && name == spellName) {
                boolean = active == 1;
                break;
            }
        }
        return ReturnBoolean(boolean);
    };

    /** The travel time of a spell to the target in seconds.
	 This is a fixed guess at 0s or the travel time of the spell in the spell information if given.
	 @name TravelTime
	 @paramsig number or boolean
	 @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	     Defaults to target=target.
	     Valid values: player, target, focus, pet.
	 @return The number of seconds.
	 @usage
	 if target.DebuffPresent(shadowflame_debuff) < TravelTime(hand_of_guldan) + GCD()
	     Spell(hand_of_guldan)
     */
    private TravelTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        //let target = private ParseCondition = (positionalParams, namedParams, "target");
        const si = spellId && this.OvaleData.spellInfo[spellId];
        let travelTime = 0;
        if (si) {
            travelTime = si.travel_time || si.max_travel_time || 0;
        }
        if (travelTime > 0) {
            const estimatedTravelTime = 1;
            if (travelTime < estimatedTravelTime) {
                travelTime = estimatedTravelTime;
            }
        }
        return ReturnConstant(travelTime);
    };

    /**  A condition that always returns true.
	 @name True
	 @paramsig boolean
	 @return A boolean value.
     */
    private True = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        return [0, INFINITY];
    };

    /** The weapon DPS of the weapon in the given hand.
	 @name WeaponDPS
	 @paramsig number or boolean
	 @param hand Optional. Sets which hand weapon.
	     Defaults to main.
	     Valid values: main, off
	 @return The weapon DPS.
	 @usage
	 AddFunction AbilityAttackPower {
	    (AttackPower() + WeaponDPS() * 7)
	 }
     */
    private WeaponDPS = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const hand = positionalParams[1];
        let value = 0;
        if (hand == "offhand" || hand == "off") {
            value = this.OvalePaperDoll.current.offHandWeaponDPS || 0;
        } else if (hand == "mainhand" || hand == "main") {
            value = this.OvalePaperDoll.current.mainHandWeaponDPS || 0;
        } else {
            value = this.OvalePaperDoll.current.mainHandWeaponDPS || 0;
        }
        return ReturnConstant(value);
    };

    /** Test if a sigil is charging
	 @name SigilCharging
	 @paramsig boolean
	 @param flame, silence, misery, chains
	 @return A boolean value.
	 @usage
	 if not SigilCharging(flame) Spell(sigil_of_flame)
        */
    private SigilCharging = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let charging = false;
        for (const [, v] of ipairs(positionalParams)) {
            charging = charging || this.OvaleSigil.IsSigilCharging(v, atTime);
        }
        return ReturnBoolean(charging);
    };

    /** Test with DBM or BigWigs (if available) whether a boss is currently engaged
	    otherwise test for known units and/or world boss
	 @name IsBossFight
	 @return A boolean value.
	 @usage
	 if IsBossFight() Spell(metamorphosis_havoc)
     */
    private IsBossFight = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const bossEngaged = this.OvaleBossMod.IsBossEngaged(atTime);
        return ReturnBoolean(bossEngaged);
    };

    /** Check for the target's race
	 @name Race
	 @param all the races you which to check for
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if Race(BloodElf) Spell(arcane_torrent)
     */
    private Race = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let isRace = false;
        const target = (namedParams.target as string | undefined) || "player";
        const [, targetRaceId] = UnitRace(target);
        for (const [, v] of ipairs(positionalParams)) {
            isRace = isRace || v == targetRaceId;
        }
        return ReturnBoolean(isRace);
    };

    /**  Check if the unit is in a party
     @name UnitInParty
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if not UnitInParty() Spell(maul)
     */
    private UnitInPartyCond = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const target = (namedParams.target as string | undefined) || "player";
        const boolean = UnitInParty(target);
        return ReturnBoolean(boolean);
    };

    /**  Check if the unit is in raid
     @name UnitInRaid
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if UnitInRaid() Spell(bloodlust)
     */
    private UnitInRaidCond = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const target = (namedParams.target as string | undefined) || "player";
        const raidIndex = UnitInRaid(target);
        return ReturnBoolean(raidIndex != undefined);
    };

    /** Check the amount of Soul Fragments for Vengeance DH
	 @usage
	 if SoulFragments() > 3 Spell(spirit_bomb)
	 */
    private SoulFragments = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.OvaleDemonHunterSoulFragments.SoulFragments(atTime);
        return ReturnConstant(value);
    };

    /** Test if a specific dispel type is present.
	 @name HasDebuffType
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
	 @usage
	 if player.HasDebuffType(magic) Spell(dispel)
     */
    private HasDebuffType = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.ParseCondition(positionalParams, namedParams);
        for (const [, debuffType] of ipairs(positionalParams)) {
            const aura = this.OvaleAura.GetAura(
                target,
                lower(debuffType),
                atTime,
                (target == "player" && "HARMFUL") || "HELPFUL",
                false
            );
            if (aura) {
                const [gain, , ending] = [aura.gain, aura.start, aura.ending];
                return [gain, ending];
            }
        }
        return [];
    };

    private stackTimeTo = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = <number>positionalParams[1];
        const stacks = <number>positionalParams[2];
        const direction = <string>positionalParams[3];
        const incantersFlowBuff = this.OvaleData.GetSpellInfo(spellId);
        const tickCycle =
            (incantersFlowBuff && (incantersFlowBuff.max_stacks || 5) * 2) || 0;
        let posLo: number;
        let posHi: number;
        if (direction === "up") {
            posLo = stacks;
            posHi = stacks;
        } else if (direction === "down") {
            posLo = tickCycle - stacks + 1;
            posHi = posLo;
        } else {
            posLo = stacks;
            posHi = tickCycle - stacks + 1;
        }
        const aura = this.OvaleAura.GetAura(
            "player",
            spellId,
            atTime,
            "HELPFUL"
        );
        if (
            !aura ||
            aura.tick === undefined ||
            aura.lastTickTime === undefined
        ) {
            return [];
        }
        let buffPos;
        const buffStacks = aura.stacks;
        if (aura.direction < 0) {
            buffPos = tickCycle - buffStacks + 1;
        } else {
            buffPos = buffStacks;
        }
        if (posLo === buffPos || posHi === buffPos) return ReturnValue(0, 0, 0);
        const ticksLo = (tickCycle + posLo - buffPos) % tickCycle;
        const ticksHi = (tickCycle + posHi - buffPos) % tickCycle;
        const tickTime = aura.tick;
        const tickRem = tickTime - (atTime - aura.lastTickTime);
        const value = tickRem + tickTime * (min(ticksLo, ticksHi) - 1);
        return ReturnValue(value, atTime, -1);
    };

    private message: ConditionFunction = (positionalParameters) => {
        OneTimeMessage(positionalParameters[1] as string);
        return ReturnConstant(0);
    };

    private ParseCondition(
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        defaultTarget?: string
    ) {
        return ParseCondition(namedParams, this.baseState, defaultTarget);
    }

    constructor(
        ovaleCondition: OvaleConditionClass,
        private OvaleData: OvaleDataClass,
        private OvalePaperDoll: OvalePaperDollClass,
        private OvaleAzeriteEssence: OvaleAzeriteEssenceClass,
        private OvaleAura: OvaleAuraClass,
        private baseState: BaseState,
        private OvaleCooldown: OvaleCooldownClass,
        private OvaleFuture: OvaleFutureClass,
        private OvaleSpellBook: OvaleSpellBookClass,
        private OvaleFrameModule: OvaleFrameModuleClass,
        private OvaleGUID: OvaleGUIDClass,
        private OvaleDamageTaken: OvaleDamageTakenClass,
        private OvalePower: OvalePowerClass,
        private OvaleEnemies: OvaleEnemiesClass,
        private lastSpell: LastSpell,
        private OvaleHealth: OvaleHealthClass,
        private ovaleOptions: OvaleOptionsClass,
        private OvaleLossOfControl: OvaleLossOfControlClass,
        private OvaleSpellDamage: OvaleSpellDamageClass,
        private OvaleTotem: OvaleTotemClass,
        private OvaleSigil: OvaleSigilClass,
        private OvaleDemonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass,
        private OvaleRunes: OvaleRunesClass,
        private OvaleBossMod: OvaleBossModClass,
        private OvaleSpells: OvaleSpellsClass
    ) {
        ovaleCondition.RegisterCondition("message", false, this.message);

        ovaleCondition.RegisterCondition("present", false, this.Present);
        ovaleCondition.RegisterCondition(
            "stacktimeto",
            false,
            this.stackTimeTo
        );
        ovaleCondition.RegisterCondition(
            "armorsetbonus",
            false,
            this.ArmorSetBonus
        );
        ovaleCondition.RegisterCondition(
            "armorsetparts",
            false,
            this.ArmorSetParts
        );
        ovaleCondition.RegisterCondition(
            "azeriteessenceismajor",
            false,
            this.AzeriteEssenceIsMajor
        );
        ovaleCondition.RegisterCondition(
            "azeriteessenceisminor",
            false,
            this.AzeriteEssenceIsMinor
        );
        ovaleCondition.RegisterCondition(
            "azeriteessenceisenabled",
            false,
            this.AzeriteEssenceIsEnabled
        );
        ovaleCondition.RegisterCondition(
            "azeriteessencerank",
            false,
            this.AzeriteEssenceRank
        );
        ovaleCondition.RegisterCondition(
            "baseduration",
            false,
            this.BaseDuration
        );
        ovaleCondition.RegisterCondition(
            "buffdurationifapplied",
            false,
            this.BaseDuration
        );
        ovaleCondition.RegisterCondition(
            "debuffdurationifapplied",
            false,
            this.BaseDuration
        );
        ovaleCondition.RegisterCondition("buffamount", false, this.BuffAmount);
        ovaleCondition.RegisterCondition(
            "debuffamount",
            false,
            this.BuffAmount
        );
        ovaleCondition.RegisterCondition("tickvalue", false, this.BuffAmount);
        ovaleCondition.RegisterCondition(
            "buffcombopoints",
            false,
            this.BuffComboPoints
        );
        ovaleCondition.RegisterCondition(
            "debuffcombopoints",
            false,
            this.BuffComboPoints
        );
        ovaleCondition.RegisterCondition(
            "buffcooldown",
            false,
            this.BuffCooldown
        );
        ovaleCondition.RegisterCondition(
            "debuffcooldown",
            false,
            this.BuffCooldown
        );
        ovaleCondition.RegisterCondition("buffcount", false, this.BuffCount);
        ovaleCondition.RegisterCondition(
            "buffcooldownduration",
            false,
            this.BuffCooldownDuration
        );
        ovaleCondition.RegisterCondition(
            "debuffcooldownduration",
            false,
            this.BuffCooldownDuration
        );
        ovaleCondition.RegisterCondition(
            "buffcountonany",
            false,
            this.BuffCountOnAny
        );
        ovaleCondition.RegisterCondition(
            "debuffcountonany",
            false,
            this.BuffCountOnAny
        );
        ovaleCondition.RegisterCondition(
            "buffdirection",
            false,
            this.BuffDirection
        );
        ovaleCondition.RegisterCondition(
            "debuffdirection",
            false,
            this.BuffDirection
        );
        ovaleCondition.RegisterCondition(
            "buffduration",
            false,
            this.BuffDuration
        );
        ovaleCondition.RegisterCondition(
            "debuffduration",
            false,
            this.BuffDuration
        );
        ovaleCondition.RegisterCondition(
            "buffexpires",
            false,
            this.BuffExpires
        );
        ovaleCondition.RegisterCondition(
            "debuffexpires",
            false,
            this.BuffExpires
        );

        const targetParameter: ParameterInfo<Target> = {
            name: "target",
            optional: true,
            defaultValue: "player",
            type: "string",
        };

        const filterParameter: ParameterInfo<Filter> = {
            name: "filter",
            optional: true,
            defaultValue: "buff",
            type: "string",
            mapValues: mapFilter,
        };

        const mineParameter: ParameterInfo<boolean> = {
            name: "mine",
            type: "boolean",
            defaultValue: true,
            optional: true,
        };

        // TODO remove buff/debuff from the name
        ovaleCondition.register(
            "buffpresent",
            this.BuffPresent,
            { type: "number" },
            { name: "aura", type: "number", isSpell: true, optional: false },
            targetParameter,
            filterParameter,
            mineParameter,
            {
                name: "seconds",
                type: "number",
                defaultValue: 0,
                optional: true,
            },
            {
                name: "haste",
                type: "string",
                checkTokens: checkHaste,
                defaultValue: "none",
                optional: true,
            }
        );
        ovaleCondition.registerAlias("buffpresent", "debuffpresent");
        ovaleCondition.RegisterCondition("buffgain", false, this.BuffGain);
        ovaleCondition.RegisterCondition("debuffgain", false, this.BuffGain);
        ovaleCondition.RegisterCondition(
            "buffimproved",
            false,
            this.BuffImproved
        );
        ovaleCondition.RegisterCondition(
            "debuffimproved",
            false,
            this.BuffImproved
        );
        ovaleCondition.RegisterCondition(
            "buffpersistentmultiplier",
            false,
            this.BuffPersistentMultiplier
        );
        ovaleCondition.RegisterCondition(
            "debuffpersistentmultiplier",
            false,
            this.BuffPersistentMultiplier
        );
        ovaleCondition.RegisterCondition(
            "buffremaining",
            false,
            this.BuffRemaining
        );
        ovaleCondition.RegisterCondition(
            "debuffremaining",
            false,
            this.BuffRemaining
        );
        ovaleCondition.RegisterCondition(
            "buffremains",
            false,
            this.BuffRemaining
        );
        ovaleCondition.RegisterCondition(
            "debuffremains",
            false,
            this.BuffRemaining
        );
        ovaleCondition.RegisterCondition(
            "buffremainingonany",
            false,
            this.BuffRemainingOnAny
        );
        ovaleCondition.RegisterCondition(
            "debuffremainingonany",
            false,
            this.BuffRemainingOnAny
        );
        ovaleCondition.RegisterCondition(
            "buffremainsonany",
            false,
            this.BuffRemainingOnAny
        );
        ovaleCondition.RegisterCondition(
            "debuffremainsonany",
            false,
            this.BuffRemainingOnAny
        );
        ovaleCondition.RegisterCondition("buffstacks", false, this.BuffStacks);
        ovaleCondition.RegisterCondition(
            "debuffstacks",
            false,
            this.BuffStacks
        );
        ovaleCondition.RegisterCondition("maxstacks", true, this.maxStacks);
        ovaleCondition.RegisterCondition(
            "buffstacksonany",
            false,
            this.BuffStacksOnAny
        );
        ovaleCondition.RegisterCondition(
            "debuffstacksonany",
            false,
            this.BuffStacksOnAny
        );
        ovaleCondition.RegisterCondition(
            "buffstealable",
            false,
            this.BuffStealable
        );
        ovaleCondition.RegisterCondition("cancast", true, this.CanCast);
        ovaleCondition.RegisterCondition("casttime", true, this.CastTime);
        ovaleCondition.RegisterCondition("executetime", true, this.ExecuteTime);
        ovaleCondition.RegisterCondition("casting", false, this.Casting);
        ovaleCondition.RegisterCondition(
            "checkboxoff",
            false,
            this.CheckBoxOff
        );
        ovaleCondition.RegisterCondition("checkboxon", false, this.CheckBoxOn);
        ovaleCondition.RegisterCondition("class", false, this.Class);
        ovaleCondition.RegisterCondition(
            "classification",
            false,
            this.Classification
        );
        ovaleCondition.RegisterCondition("counter", false, this.Counter);
        ovaleCondition.register(
            "creaturefamily",
            this.CreatureFamily,
            { type: "none" },
            { name: "name", type: "string", optional: false },
            targetParameter
        );
        ovaleCondition.RegisterCondition(
            "creaturetype",
            false,
            this.CreatureType
        );
        ovaleCondition.RegisterCondition("critdamage", false, this.CritDamage);
        ovaleCondition.RegisterCondition("damage", false, this.Damage);
        ovaleCondition.RegisterCondition(
            "damagetaken",
            false,
            this.DamageTaken
        );
        ovaleCondition.RegisterCondition(
            "incomingdamage",
            false,
            this.DamageTaken
        );
        ovaleCondition.RegisterCondition(
            "magicdamagetaken",
            false,
            this.MagicDamageTaken
        );
        ovaleCondition.RegisterCondition(
            "incomingmagicdamage",
            false,
            this.MagicDamageTaken
        );
        ovaleCondition.RegisterCondition(
            "physicaldamagetaken",
            false,
            this.PhysicalDamageTaken
        );
        ovaleCondition.RegisterCondition(
            "incomingphysicaldamage",
            false,
            this.PhysicalDamageTaken
        );
        ovaleCondition.RegisterCondition(
            "diseasesremaining",
            false,
            this.DiseasesRemaining
        );
        ovaleCondition.RegisterCondition(
            "diseasesticking",
            false,
            this.DiseasesTicking
        );
        ovaleCondition.RegisterCondition(
            "diseasesanyticking",
            false,
            this.DiseasesAnyTicking
        );
        ovaleCondition.RegisterCondition("distance", false, this.Distance);
        ovaleCondition.RegisterCondition("enemies", false, this.Enemies);
        ovaleCondition.RegisterCondition(
            "energyregen",
            false,
            this.EnergyRegenRate
        );
        ovaleCondition.RegisterCondition(
            "energyregenrate",
            false,
            this.EnergyRegenRate
        );
        ovaleCondition.RegisterCondition(
            "enrageremaining",
            false,
            this.EnrageRemaining
        );
        ovaleCondition.RegisterCondition("exists", false, this.Exists);
        ovaleCondition.RegisterCondition("never", false, this.False);
        ovaleCondition.RegisterCondition(
            "focusregen",
            false,
            this.FocusRegenRate
        );
        ovaleCondition.RegisterCondition(
            "focusregenrate",
            false,
            this.FocusRegenRate
        );
        ovaleCondition.RegisterCondition(
            "focuscastingregen",
            false,
            this.FocusCastingRegen
        );
        ovaleCondition.RegisterCondition("gcd", false, this.GCD);
        ovaleCondition.RegisterCondition(
            "gcdremaining",
            false,
            this.GCDRemaining
        );
        ovaleCondition.RegisterCondition("glyph", false, this.Glyph);
        ovaleCondition.RegisterCondition(
            "hasfullcontrol",
            false,
            this.HasFullControlCondition
        );
        ovaleCondition.RegisterCondition("health", false, this.Health);
        ovaleCondition.RegisterCondition("life", false, this.Health);
        ovaleCondition.RegisterCondition(
            "effectivehealth",
            false,
            this.EffectiveHealth
        );
        ovaleCondition.RegisterCondition(
            "healthmissing",
            false,
            this.HealthMissing
        );
        ovaleCondition.RegisterCondition(
            "lifemissing",
            false,
            this.HealthMissing
        );
        ovaleCondition.RegisterCondition(
            "healthpercent",
            false,
            this.HealthPercent
        );
        ovaleCondition.RegisterCondition(
            "lifepercent",
            false,
            this.HealthPercent
        );
        ovaleCondition.RegisterCondition(
            "effectivehealthpercent",
            false,
            this.EffectiveHealthPercent
        );
        ovaleCondition.RegisterCondition("maxhealth", false, this.MaxHealth);
        ovaleCondition.RegisterCondition("deadin", false, this.TimeToDie);
        ovaleCondition.RegisterCondition("timetodie", false, this.TimeToDie);
        ovaleCondition.RegisterCondition(
            "timetohealthpercent",
            false,
            this.TimeToHealthPercent
        );
        ovaleCondition.RegisterCondition(
            "timetolifepercent",
            false,
            this.TimeToHealthPercent
        );
        ovaleCondition.RegisterCondition(
            "inflighttotarget",
            false,
            this.InFlightToTarget
        );
        ovaleCondition.RegisterCondition("inrange", false, this.InRange);
        ovaleCondition.RegisterCondition("isaggroed", false, this.IsAggroed);
        ovaleCondition.RegisterCondition("isdead", false, this.IsDead);
        ovaleCondition.RegisterCondition("isenraged", false, this.IsEnraged);
        ovaleCondition.RegisterCondition("isfeared", false, this.IsFeared);
        ovaleCondition.RegisterCondition("isfriend", false, this.IsFriend);
        ovaleCondition.RegisterCondition(
            "isincapacitated",
            false,
            this.IsIncapacitated
        );
        ovaleCondition.RegisterCondition(
            "isinterruptible",
            false,
            this.IsInterruptible
        );
        ovaleCondition.RegisterCondition("ispvp", false, this.IsPVP);
        ovaleCondition.RegisterCondition("isrooted", false, this.IsRooted);
        ovaleCondition.RegisterCondition("isstunned", false, this.IsStunned);
        ovaleCondition.RegisterCondition(
            "itemcharges",
            false,
            this.ItemCharges
        );
        ovaleCondition.RegisterCondition("itemcount", false, this.ItemCount);
        ovaleCondition.RegisterCondition("lastdamage", false, this.LastDamage);
        ovaleCondition.RegisterCondition(
            "lastspelldamage",
            false,
            this.LastDamage
        );
        ovaleCondition.RegisterCondition("level", false, this.Level);
        ovaleCondition.RegisterCondition("list", false, this.List);
        ovaleCondition.register(
            "name",
            this.Name,
            { type: "string" },
            targetParameter
        );
        ovaleCondition.RegisterCondition("ptr", false, this.PTR);
        ovaleCondition.RegisterCondition(
            "persistentmultiplier",
            false,
            this.PersistentMultiplier
        );
        ovaleCondition.RegisterCondition("petpresent", false, this.PetPresent);
        ovaleCondition.RegisterCondition(
            "alternatepower",
            false,
            this.AlternatePower
        );
        ovaleCondition.RegisterCondition(
            "arcanecharges",
            false,
            this.ArcaneCharges
        );
        ovaleCondition.RegisterCondition(
            "astralpower",
            false,
            this.AstralPower
        );
        ovaleCondition.RegisterCondition("chi", false, this.Chi);
        ovaleCondition.RegisterCondition(
            "combopoints",
            false,
            this.ComboPoints
        );
        ovaleCondition.RegisterCondition("energy", false, this.Energy);
        ovaleCondition.RegisterCondition("focus", false, this.Focus);
        ovaleCondition.RegisterCondition("fury", false, this.Fury);
        ovaleCondition.RegisterCondition("holypower", false, this.HolyPower);
        ovaleCondition.RegisterCondition("insanity", false, this.Insanity);
        ovaleCondition.RegisterCondition("maelstrom", false, this.Maelstrom);
        ovaleCondition.RegisterCondition("mana", false, this.Mana);
        ovaleCondition.RegisterCondition("pain", false, this.Pain);
        ovaleCondition.RegisterCondition("rage", false, this.Rage);
        ovaleCondition.RegisterCondition("runicpower", false, this.RunicPower);
        ovaleCondition.RegisterCondition("soulshards", false, this.SoulShards);
        ovaleCondition.RegisterCondition(
            "alternatepowerdeficit",
            false,
            this.AlternatePowerDeficit
        );
        ovaleCondition.RegisterCondition(
            "astralpowerdeficit",
            false,
            this.AstralPowerDeficit
        );
        ovaleCondition.RegisterCondition("chideficit", false, this.ChiDeficit);
        ovaleCondition.RegisterCondition(
            "combopointsdeficit",
            false,
            this.ComboPointsDeficit
        );
        ovaleCondition.RegisterCondition(
            "energydeficit",
            false,
            this.EnergyDeficit
        );
        ovaleCondition.RegisterCondition(
            "focusdeficit",
            false,
            this.FocusDeficit
        );
        ovaleCondition.RegisterCondition(
            "furydeficit",
            false,
            this.FuryDeficit
        );
        ovaleCondition.RegisterCondition(
            "holypowerdeficit",
            false,
            this.HolyPowerDeficit
        );
        ovaleCondition.RegisterCondition(
            "manadeficit",
            false,
            this.ManaDeficit
        );
        ovaleCondition.RegisterCondition(
            "paindeficit",
            false,
            this.PainDeficit
        );
        ovaleCondition.RegisterCondition(
            "ragedeficit",
            false,
            this.RageDeficit
        );
        ovaleCondition.RegisterCondition(
            "runicpowerdeficit",
            false,
            this.RunicPowerDeficit
        );
        ovaleCondition.RegisterCondition(
            "soulshardsdeficit",
            false,
            this.SoulShardsDeficit
        );
        ovaleCondition.RegisterCondition(
            "manapercent",
            false,
            this.ManaPercent
        );
        ovaleCondition.RegisterCondition(
            "maxalternatepower",
            false,
            this.MaxAlternatePower
        );
        ovaleCondition.RegisterCondition(
            "maxarcanecharges",
            false,
            this.MaxArcaneCharges
        );
        ovaleCondition.RegisterCondition("maxchi", false, this.MaxChi);
        ovaleCondition.RegisterCondition(
            "maxcombopoints",
            false,
            this.MaxComboPoints
        );
        ovaleCondition.RegisterCondition("maxenergy", false, this.MaxEnergy);
        ovaleCondition.RegisterCondition("maxfocus", false, this.MaxFocus);
        ovaleCondition.RegisterCondition("maxfury", false, this.MaxFury);
        ovaleCondition.RegisterCondition(
            "maxholypower",
            false,
            this.MaxHolyPower
        );
        ovaleCondition.RegisterCondition("maxmana", false, this.MaxMana);
        ovaleCondition.RegisterCondition("maxpain", false, this.MaxPain);
        ovaleCondition.RegisterCondition("maxrage", false, this.MaxRage);
        ovaleCondition.RegisterCondition(
            "maxrunicpower",
            false,
            this.MaxRunicPower
        );
        ovaleCondition.RegisterCondition(
            "maxsoulshards",
            false,
            this.MaxSoulShards
        );
        ovaleCondition.RegisterCondition("powercost", true, this.MainPowerCost);
        ovaleCondition.RegisterCondition(
            "astralpowercost",
            true,
            this.AstralPowerCost
        );
        ovaleCondition.RegisterCondition("energycost", true, this.EnergyCost);
        ovaleCondition.RegisterCondition("focuscost", true, this.FocusCost);
        ovaleCondition.RegisterCondition("manacost", true, this.ManaCost);
        ovaleCondition.RegisterCondition("ragecost", true, this.RageCost);
        ovaleCondition.RegisterCondition(
            "runicpowercost",
            true,
            this.RunicPowerCost
        );
        ovaleCondition.RegisterCondition(
            "previousgcdspell",
            true,
            this.PreviousGCDSpell
        );
        ovaleCondition.RegisterCondition(
            "previousoffgcdspell",
            true,
            this.PreviousOffGCDSpell
        );
        ovaleCondition.RegisterCondition(
            "previousspell",
            true,
            this.PreviousSpell
        );
        ovaleCondition.RegisterCondition(
            "relativelevel",
            false,
            this.RelativeLevel
        );
        ovaleCondition.RegisterCondition(
            "refreshable",
            false,
            this.Refreshable
        );
        ovaleCondition.RegisterCondition(
            "debuffrefreshable",
            false,
            this.Refreshable
        );
        ovaleCondition.RegisterCondition(
            "buffrefreshable",
            false,
            this.Refreshable
        );
        ovaleCondition.RegisterCondition(
            "remainingcasttime",
            false,
            this.RemainingCastTime
        );
        ovaleCondition.RegisterCondition("rune", false, this.Rune);
        ovaleCondition.RegisterCondition("runecount", false, this.RuneCount);
        ovaleCondition.RegisterCondition(
            "timetorunes",
            false,
            this.TimeToRunes
        );
        ovaleCondition.RegisterCondition(
            "runedeficit",
            false,
            this.RuneDeficit
        );
        ovaleCondition.RegisterCondition("agility", false, this.Agility);
        ovaleCondition.RegisterCondition(
            "attackpower",
            false,
            this.AttackPower
        );
        ovaleCondition.RegisterCondition("critrating", false, this.CritRating);
        ovaleCondition.RegisterCondition(
            "hasterating",
            false,
            this.HasteRating
        );
        ovaleCondition.RegisterCondition("intellect", false, this.Intellect);
        ovaleCondition.RegisterCondition("mastery", false, this.MasteryEffect);
        ovaleCondition.RegisterCondition(
            "masteryeffect",
            false,
            this.MasteryEffect
        );
        ovaleCondition.RegisterCondition(
            "masteryrating",
            false,
            this.MasteryRating
        );
        ovaleCondition.RegisterCondition(
            "meleecritchance",
            false,
            this.MeleeCritChance
        );
        ovaleCondition.RegisterCondition(
            "meleeattackspeedpercent",
            false,
            this.MeleeAttackSpeedPercent
        );
        ovaleCondition.RegisterCondition(
            "rangedcritchance",
            false,
            this.RangedCritChance
        );
        ovaleCondition.RegisterCondition(
            "spellcritchance",
            false,
            this.SpellCritChance
        );
        ovaleCondition.RegisterCondition(
            "spellcastspeedpercent",
            false,
            this.SpellCastSpeedPercent
        );
        ovaleCondition.RegisterCondition("spellpower", false, this.Spellpower);
        ovaleCondition.RegisterCondition("stamina", false, this.Stamina);
        ovaleCondition.RegisterCondition("strength", false, this.Strength);
        ovaleCondition.RegisterCondition(
            "versatility",
            false,
            this.Versatility
        );
        ovaleCondition.RegisterCondition(
            "versatilityRating",
            false,
            this.VersatilityRating
        );
        ovaleCondition.RegisterCondition("speed", false, this.Speed);
        ovaleCondition.RegisterCondition(
            "spellchargecooldown",
            true,
            this.SpellChargeCooldown
        );
        ovaleCondition.RegisterCondition("charges", true, this.SpellCharges);
        ovaleCondition.RegisterCondition(
            "spellcharges",
            true,
            this.SpellCharges
        );
        ovaleCondition.RegisterCondition(
            "spellfullrecharge",
            true,
            this.SpellFullRecharge
        );
        ovaleCondition.RegisterCondition(
            "spellcooldown",
            true,
            this.SpellCooldown
        );
        ovaleCondition.RegisterCondition(
            "spellcooldownduration",
            true,
            this.SpellCooldownDuration
        );
        ovaleCondition.RegisterCondition(
            "spellrechargeduration",
            true,
            this.SpellRechargeDuration
        );
        ovaleCondition.RegisterCondition("spelldata", false, this.SpellData);
        ovaleCondition.RegisterCondition(
            "spellinfoproperty",
            false,
            this.SpellInfoProperty
        );
        ovaleCondition.RegisterCondition("spellcount", true, this.SpellCount);
        ovaleCondition.RegisterCondition("spellknown", true, this.SpellKnown);
        ovaleCondition.RegisterCondition(
            "spellmaxcharges",
            true,
            this.SpellMaxCharges
        );
        ovaleCondition.RegisterCondition("spellusable", true, this.SpellUsable);
        ovaleCondition.RegisterCondition("isstealthed", false, this.Stealthed);
        ovaleCondition.RegisterCondition("stealthed", false, this.Stealthed);
        ovaleCondition.RegisterCondition("lastswing", false, this.LastSwing);
        ovaleCondition.RegisterCondition("nextswing", false, this.NextSwing);
        ovaleCondition.RegisterCondition("talent", false, this.Talent);
        ovaleCondition.RegisterCondition("hastalent", false, this.Talent);
        ovaleCondition.RegisterCondition(
            "talentpoints",
            false,
            this.TalentPoints
        );
        ovaleCondition.RegisterCondition(
            "istargetingplayer",
            false,
            this.TargetIsPlayer
        );
        ovaleCondition.RegisterCondition(
            "targetisplayer",
            false,
            this.TargetIsPlayer
        );
        ovaleCondition.RegisterCondition("threat", false, this.Threat);
        ovaleCondition.RegisterCondition("ticktime", false, this.TickTime);
        ovaleCondition.RegisterCondition(
            "currentticktime",
            false,
            this.CurrentTickTime
        );
        ovaleCondition.RegisterCondition(
            "ticksremaining",
            false,
            this.TicksRemaining
        );
        ovaleCondition.RegisterCondition(
            "ticksremain",
            false,
            this.TicksRemaining
        );
        ovaleCondition.RegisterCondition(
            "ticktimeremaining",
            false,
            this.TickTimeRemaining
        );
        ovaleCondition.RegisterCondition(
            "timesincepreviousspell",
            false,
            this.TimeSincePreviousSpell
        );
        ovaleCondition.RegisterCondition(
            "timetobloodlust",
            false,
            this.TimeToBloodlust
        );
        ovaleCondition.RegisterCondition(
            "timetoeclipse",
            false,
            this.TimeToEclipse
        );
        ovaleCondition.RegisterCondition(
            "timetoenergy",
            false,
            this.TimeToEnergy
        );
        ovaleCondition.RegisterCondition(
            "timetofocus",
            false,
            this.TimeToFocus
        );
        ovaleCondition.RegisterCondition(
            "timetomaxenergy",
            false,
            this.TimeToMaxEnergy
        );
        ovaleCondition.RegisterCondition(
            "timetomaxfocus",
            false,
            this.TimeToMaxFocus
        );
        ovaleCondition.RegisterCondition(
            "timetomaxmana",
            false,
            this.TimeToMaxMana
        );
        ovaleCondition.RegisterCondition(
            "timetoenergyfor",
            true,
            this.TimeToEnergyFor
        );
        ovaleCondition.RegisterCondition(
            "timetofocusfor",
            true,
            this.TimeToFocusFor
        );
        ovaleCondition.RegisterCondition("timetospell", true, this.TimeToSpell);
        ovaleCondition.RegisterCondition(
            "timewithhaste",
            false,
            this.TimeWithHaste
        );
        ovaleCondition.RegisterCondition(
            "totemexpires",
            false,
            this.TotemExpires
        );
        ovaleCondition.RegisterCondition(
            "totempresent",
            false,
            this.TotemPresent
        );
        ovaleCondition.RegisterCondition(
            "totemremaining",
            false,
            this.TotemRemaining
        );
        ovaleCondition.RegisterCondition(
            "totemremains",
            false,
            this.TotemRemaining
        );
        ovaleCondition.RegisterCondition("tracking", false, this.Tracking);
        ovaleCondition.RegisterCondition("traveltime", true, this.TravelTime);
        ovaleCondition.RegisterCondition(
            "maxtraveltime",
            true,
            this.TravelTime
        );
        ovaleCondition.RegisterCondition("always", false, this.True);
        ovaleCondition.RegisterCondition("weapondps", false, this.WeaponDPS);
        ovaleCondition.RegisterCondition(
            "sigilcharging",
            false,
            this.SigilCharging
        );
        ovaleCondition.RegisterCondition(
            "isbossfight",
            false,
            this.IsBossFight
        );
        ovaleCondition.RegisterCondition("race", false, this.Race);
        ovaleCondition.RegisterCondition(
            "unitinparty",
            false,
            this.UnitInPartyCond
        );
        ovaleCondition.RegisterCondition(
            "unitinraid",
            false,
            this.UnitInRaidCond
        );
        ovaleCondition.RegisterCondition(
            "soulfragments",
            false,
            this.SoulFragments
        );
        ovaleCondition.RegisterCondition(
            "hasdebufftype",
            false,
            this.HasDebuffType
        );
    }
}
