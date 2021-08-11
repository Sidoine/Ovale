import LibBabbleCreatureType from "@wowts/lib_babble-creature_type-3.0";
import LibRangeCheck from "@wowts/lib_range_check-2.0";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    parseCondition,
    ParameterInfo,
    returnBoolean,
    returnConstant,
    returnValue,
    returnValueBetween,
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
import { Guids } from "../engine/guid";
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
import { isNumber, KeyCheck, oneTimeMessage } from "../tools/tools";

// Return the target's damage reduction from armor, which seems to be 30% with most bosses
function bossArmorDamageReduction(target: string) {
    return 0.3;
}
// Return a Capitalized word
function capitalize(word: string): string {
    if (!word) return word;
    return upper(sub(word, 1, 1)) + lower(sub(word, 2));
}

const amplification = 146051;
const increasedCritEffect3Percents = 44797;
const imbuedBuffId = 214336;
const steadyFocus = 177668;

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
    computeParameter<T extends SpellInfoProperty>(
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
        return this.data.getSpellInfoProperty(
            spellId,
            atTime,
            paramName,
            undefined
        );
    }

    /** Return the time in seconds, adjusted by the named haste effect. */
    getHastedTime(
        seconds: number,
        haste: HasteType | undefined,
        atTime?: number
    ) {
        seconds = seconds || 0;
        const multiplier = this.paperDoll.getHasteMultiplier(haste, atTime);
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
    private getArmorSetBonus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        oneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0");
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
    private getArmorSetParts = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 0;
        oneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0");
        return returnConstant(value);
    };

    private azeriteEssenceIsMajor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.azeriteEssence.isMajorEssence(essenceId);
        return returnBoolean(value);
    };
    private azeriteEssenceIsMinor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.azeriteEssence.isMinorEssence(essenceId);
        return returnBoolean(value);
    };
    private azeriteEssenceIsEnabled = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value =
            this.azeriteEssence.isMajorEssence(essenceId) ||
            this.azeriteEssence.isMinorEssence(essenceId);
        return returnBoolean(value);
    };
    private azeriteEssenceRank = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const essenceId = positionalParams[1];
        const value = this.azeriteEssence.essenceRank(essenceId);
        return returnConstant(value);
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

    private baseDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        let value = 0;
        if (this.data.buffSpellList[auraId]) {
            const spellList = this.data.buffSpellList[auraId];
            for (const [id] of pairs(spellList)) {
                value = this.auras.getBaseDuration(id, undefined, atTime);
                if (value != INFINITY) {
                    break;
                }
            }
        } else {
            value = this.auras.getBaseDuration(auraId, undefined, atTime);
        }
        return returnConstant(value);
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
    private buffAmount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
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
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            const value = aura[statName] || 0;
            return returnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return returnConstant(0);
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
    private buffComboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const combopoints = 0;
        oneTimeMessage("Warning: 'BuffComboPoints()' is not implemented.");
        return returnConstant(combopoints);
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
    private buffCooldown: ConditionFunction = (
        positionalParams,
        namedParams,
        atTime
    ) => {
        const auraId = positionalParams[1];

        if (!isNumber(auraId)) return [];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            const gain = aura.gain;
            const cooldownEnding = aura.cooldownEnding || 0;
            return returnValueBetween(gain, INFINITY, 0, cooldownEnding, -1);
        }
        return returnConstant(0);
    };

    /**  Get the number of buff if the given spell list
	 @name BuffCount
	 @paramsig number or boolean
	 @param id the spell list ID	
	 @return The number of buffs
	 */
    private buffCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const spellList = this.data.buffSpellList[auraId];
        let count = 0;
        for (const [id] of pairs(spellList)) {
            const aura = this.auras.getAura(target, id, atTime, filter, mine);
            if (aura && this.auras.isActiveAura(aura, atTime)) {
                count = count + 1;
            }
        }
        return returnConstant(count);
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
    private buffCooldownDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        let minCooldown = INFINITY;
        if (this.data.buffSpellList[auraId]) {
            for (const [id] of pairs(this.data.buffSpellList[auraId])) {
                const si = this.data.spellInfo[id];
                const cd = si && si.buff_cd;
                if (cd && minCooldown > cd) {
                    minCooldown = cd;
                }
            }
        } else {
            minCooldown = 0;
        }
        return returnConstant(minCooldown);
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
    private buffCountOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.parseCondition(
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
        ] = this.auras.auraCount(
            auraId,
            filter,
            mine,
            namedParams.stacks as number | undefined,
            atTime,
            excludeUnitId
        );
        if (count > 0 && startChangeCount < INFINITY && fractional) {
            const rate = -1 / (endingChangeCount - startChangeCount);
            return returnValueBetween(
                startFirst,
                endingLast,
                count,
                startChangeCount,
                rate
            );
        }
        return returnConstant(count);
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
    private buffDirection = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            return returnValueBetween(
                aura.gain,
                INFINITY,
                aura.direction,
                aura.gain,
                0
            );
        }
        return returnConstant(0);
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
    private buffDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            const duration = aura.ending - aura.start;
            return returnValueBetween(
                aura.gain,
                aura.ending,
                duration,
                aura.start,
                0
            );
        }
        return returnConstant(0);
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
    private buffExpires: ConditionFunction = (
        positionalParams,
        namedParams,
        atTime
    ): ConditionResult => {
        const [auraId, seconds] = [
            positionalParams[1],
            positionalParams[2] || 0,
        ];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        if (!isNumber(auraId) || !isNumber(seconds)) return [];
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            const hastedSeconds = this.getHastedTime(
                seconds,
                namedParams.haste as HasteType,
                atTime
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
    private buffPresent = (
        atTime: number,
        auraId: number,
        target: Target,
        filter: "HARMFUL" | "HELPFUL",
        mine: boolean,
        seconds: number,
        haste: HasteType
    ): ConditionResult => {
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            const [gain, , ending] = [aura.gain, aura.start, aura.ending];
            seconds = this.getHastedTime(seconds, haste, atTime);
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
    private buffGain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            const gain = aura.gain || 0;
            return returnValueBetween(gain, INFINITY, 0, gain, 1);
        }
        return returnConstant(0);
    };

    private buffImproved = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let [, ,] = this.parseCondition(positionalParams, namedParams);
        // TODO Not implemented
        return returnConstant(0);
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
    private buffPersistentMultiplier = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            const value = aura.damageMultiplier || 1;
            return returnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return returnConstant(1);
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
    private buffRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && aura.ending >= atTime) {
            return returnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return returnConstant(0);
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
    private buffRemainingOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const excludeUnitId =
            (namedParams.excludeTarget == 1 && this.baseState.defaultTarget) ||
            undefined;
        const [count, , , , startFirst, endingLast] = this.auras.auraCount(
            auraId,
            filter,
            mine,
            namedParams.stacks as number | undefined,
            atTime,
            excludeUnitId
        );
        if (count > 0) {
            return returnValueBetween(startFirst, INFINITY, 0, endingLast, -1);
        }
        return returnConstant(0);
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
    private buffStacks = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            const value = aura.stacks || 0;
            return returnValueBetween(
                aura.gain,
                aura.ending,
                value,
                aura.start,
                0
            );
        }
        return returnConstant(0);
    };

    private maxStacks = (
        positionalParams: PositionalParameters,
        namedParameters: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1] as number;
        const spellInfo = this.data.getSpellOrListInfo(auraId);
        const maxStacks = (spellInfo && spellInfo.max_stacks) || 0;
        return returnConstant(maxStacks);
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
    private buffStacksOnAny = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const excludeUnitId =
            (namedParams.excludeTarget == 1 && this.baseState.defaultTarget) ||
            undefined;
        const [count, stacks, , endingChangeCount, startFirst] =
            this.auras.auraCount(
                auraId,
                filter,
                mine,
                1,
                atTime,
                excludeUnitId
            );
        if (count > 0) {
            return returnValueBetween(
                startFirst,
                endingChangeCount,
                stacks,
                startFirst,
                0
            );
        }
        return returnConstant(count);
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
    private buffStealable = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        return this.auras.getAuraWithProperty(
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
    private canCast = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const [start, duration] = this.cooldown.getSpellCooldown(
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
    private castTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const castTime = this.spellBook.getCastTime(spellId) || 0;
        return returnConstant(castTime);
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
    private executeTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const castTime = this.spellBook.getCastTime(spellId) || 0;
        const gcd = this.future.getGCD(atTime);
        const t = (castTime > gcd && castTime) || gcd;
        return returnConstant(t);
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
    private casting = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(positionalParams, namedParams);
        let start, ending, castSpellId, castSpellName;
        if (target == "player") {
            start = this.future.next.currentCast.start;
            ending = this.future.next.currentCast.stop;
            castSpellId = this.future.next.currentCast.spellId;
            castSpellName = this.spellBook.getSpellName(castSpellId);
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
            } else if (this.data.buffSpellList[spellId]) {
                for (const [id] of pairs(this.data.buffSpellList[spellId])) {
                    if (
                        id == castSpellId ||
                        this.spellBook.getSpellName(id) == castSpellName
                    ) {
                        return [start, ending];
                    }
                }
            } else if (
                spellId == "harmful" &&
                this.spellBook.isHarmfulSpell(spellId)
            ) {
                return [start, ending];
            } else if (
                spellId == "helpful" &&
                this.spellBook.isHelpfulSpell(spellId)
            ) {
                return [start, ending];
            } else if (spellId == castSpellId) {
                oneTimeMessage(
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
                this.spellBook.getSpellName(spellId) == castSpellName
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
    private checkBoxOff = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        for (const [, id] of ipairs(positionalParams)) {
            if (
                this.frameModule.frame &&
                this.frameModule.frame.isChecked(id)
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
    private checkBoxOn = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        for (const [, id] of ipairs(positionalParams)) {
            if (
                this.frameModule.frame &&
                !this.frameModule.frame.isChecked(id)
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
    private getClass = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const className = positionalParams[1];
        const [target] = this.parseCondition(positionalParams, namedParams);

        let classToken;
        if (target == "player") {
            classToken = this.paperDoll.class;
        } else {
            [, classToken] = UnitClass(target);
        }
        const boolean = classToken == upper(className);
        return returnBoolean(boolean);
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
    private classification = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const classification = positionalParams[1];
        let targetClassification;
        const [target] = this.parseCondition(positionalParams, namedParams);
        if (UnitLevel(target) < 0) {
            targetClassification = "worldboss";
        } else if (
            UnitExists("boss1") &&
            this.guids.getUnitGUID(target) == this.guids.getUnitGUID("boss1")
        ) {
            targetClassification = "worldboss";
        } else {
            const aura = this.auras.getAura(
                target,
                imbuedBuffId,
                atTime,
                "HARMFUL",
                false
            );
            if (aura && this.auras.isActiveAura(aura, atTime)) {
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
        return returnBoolean(boolean);
    };

    /**  Get the current value of a script counter.
	 @name Counter
	 @paramsig number or boolean
	 @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
	 @return The current value the counter.
     */
    private counter = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const counter = positionalParams[1];
        const value = this.future.getCounter(counter, atTime);
        return returnConstant(value);
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
    private creatureFamily = (_: number, name: string, target: string) => {
        name = capitalize(name);
        const family = UnitCreatureFamily(target);
        const lookupTable =
            LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        return returnBoolean(lookupTable && family == lookupTable[name]);
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
    private creatureType = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const creatureType = UnitCreatureType(target);
        const lookupTable =
            LibBabbleCreatureType && LibBabbleCreatureType.GetLookupTable();
        if (lookupTable) {
            for (const [, name] of ipairs<string>(positionalParams)) {
                const capitalizedName: string = capitalize(name);
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
    private critDamage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        let value = this.computeParameter(spellId, "damage", atTime) || 0;
        const si = this.data.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - bossArmorDamageReduction(target));
        }
        let critMultiplier = 2;
        {
            const aura = this.auras.getAura(
                "player",
                amplification,
                atTime,
                "HELPFUL"
            );
            if (aura && this.auras.isActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier + (aura.value1 || 0);
            }
        }
        {
            const aura = this.auras.getAura(
                "player",
                increasedCritEffect3Percents,
                atTime,
                "HELPFUL"
            );
            if (aura && this.auras.isActiveAura(aura, atTime)) {
                critMultiplier = critMultiplier * (aura.value1 || 0);
            }
        }
        value = critMultiplier * value;
        return returnConstant(value);
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
    private damage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        let value = this.computeParameter(spellId, "damage", atTime) || 0;
        const si = this.data.spellInfo[spellId];
        if (si && si.physical == 1) {
            value = value * (1 - bossArmorDamageReduction(target));
        }
        return returnConstant(value);
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
    private getDamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [total] = this.damageTaken.getRecentDamage(interval);
            value = total;
        }
        return returnConstant(value);
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
    private magicDamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [, totalMagic] = this.damageTaken.getRecentDamage(interval);
            value = totalMagic;
        }
        return returnConstant(value);
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
    private physicalDamageTaken = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const interval = positionalParams[1];
        let value = 0;
        if (interval > 0) {
            const [total, totalMagic] =
                this.damageTaken.getRecentDamage(interval);
            value = total - totalMagic;
        }
        return returnConstant(value);
    };

    getDiseases(
        target: string,
        atTime: number
    ): [Aura | undefined, Aura | undefined] {
        const bpAura = this.auras.getAura(
            target,
            SpellId.blood_plague,
            atTime,
            "HARMFUL",
            true
        );
        const ffAura = this.auras.getAura(
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
    private diseasesRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target, ,] = this.parseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.getDiseases(target, atTime);
        let aura;
        if (
            bpAura &&
            this.auras.isActiveAura(bpAura, atTime) &&
            ffAura &&
            this.auras.isActiveAura(ffAura, atTime)
        ) {
            aura = (bpAura.ending < ffAura.ending && bpAura) || ffAura;
        }
        if (aura) {
            return returnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return returnConstant(0);
    };

    /**  Test if all diseases applied by the death knight are present on the target.
	 @name DiseasesTicking
	 @paramsig boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return A boolean value.
     */
    private diseasesTicking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target, ,] = this.parseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.getDiseases(target, atTime);
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
    private diseasesAnyTicking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target, ,] = this.parseCondition(positionalParams, namedParams);
        const [bpAura, ffAura] = this.getDiseases(target, atTime);
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
    private distance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const value = (LibRangeCheck && LibRangeCheck.GetRange(target)) || 0;
        return returnConstant(value);
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
    private getEnemies = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let value = this.enemies.next.enemies;
        if (!value) {
            let useTagged =
                this.ovaleOptions.db.profile.apparence.taggedEnemies;
            if (namedParams.tagged == 0) {
                useTagged = false;
            } else if (namedParams.tagged == 1) {
                useTagged = true;
            }
            value =
                (useTagged && this.enemies.next.taggedEnemies) ||
                this.enemies.next.activeEnemies;
        }
        if (value < 1) {
            value = 1;
        }
        return returnConstant(value);
    };

    /** Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
	 @name EnergyRegenRate
	 @paramsig number or boolean
	 @return The current rate of energy regeneration.
	 @usage
	 if EnergyRegenRage() >11 Spell(stance_of_the_sturdy_ox)
     */
    private energyRegenRate = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.powers.getPowerRateAt(
            this.powers.next,
            "energy",
            atTime
        );
        return returnConstant(value);
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
    private enrageRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const aura = this.auras.getAura(
            target,
            "enrage",
            atTime,
            "HELPFUL",
            false
        );
        if (aura && aura.ending >= atTime) {
            return returnValueBetween(aura.gain, INFINITY, 0, aura.ending, -1);
        }
        return returnConstant(0);
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
    private exists = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitExists(target);
        return returnBoolean(boolean);
    };

    /** A condition that always returns false.
	 @name False
	 @paramsig boolean
	 @return A boolean value.
     */
    private getFalse: ConditionFunction = (
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
    private focusRegenRate = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.powers.getPowerRateAt(
            this.powers.next,
            "focus",
            atTime
        );
        return returnConstant(value);
    };

    /** Get the amount of focus that would be regenerated during the cast time of the given spell for hunters.
	 @name FocusCastingRegen
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The amount of focus.
     */
    private focusCastingRegen = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const regenRate = this.powers.getPowerRateAt(
            this.powers.next,
            "focus",
            atTime
        );
        let power = 0;
        const castTime = this.spellBook.getCastTime(spellId) || 0;
        const gcd = this.future.getGCD(atTime);
        const castSeconds = (castTime > gcd && castTime) || gcd;
        power = power + regenRate * castSeconds;
        const aura = this.auras.getAura(
            "player",
            steadyFocus,
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
        return returnConstant(power);
    };

    /** Get the player's global cooldown in seconds.
	 @name GCD
	 @paramsig number or boolean
	 @return The number of seconds.
	 @usage
	 if GCD() < 1.1 Spell(frostfire_bolt)
     */
    private getGCD = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.future.getGCD(atTime);
        return returnConstant(value);
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
    private getGCDRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        if (this.future.next.lastGCDSpellId) {
            const duration = this.future.getGCD(
                this.future.next.lastGCDSpellId,
                atTime,
                this.guids.getUnitGUID(target)
            );
            const spellcast = this.lastSpell.lastInFlightSpell();
            const start = (spellcast && spellcast.start) || 0;
            const ending = start + duration;
            if (atTime < ending) {
                return returnValueBetween(start, INFINITY, 0, ending, -1);
            }
        }
        return returnConstant(0);
    };

    private glyph = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return returnBoolean(false);
    };

    /** Test if the player has full control, i.e., isn't feared, charmed, etc.
	 @name HasFullControl
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if not HasFullControl() Spell(barkskin)
     */
    private hasFullControlCondition = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = HasFullControl();
        return returnBoolean(boolean);
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
    private getHealth = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health = this.health.getUnitHealth(target) || 0;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const timeToDie = this.health.getUnitTimeToDie(target);
            const rate = (-1 * health) / timeToDie;
            return returnValueBetween(now, INFINITY, health, now, rate);
        }
        return returnConstant(0);
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
    private effectiveHealth = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health =
            this.health.getUnitHealth(target) +
                this.health.getUnitAbsorb(target) -
                this.health.getUnitHealAbsorb(target) || 0;

        const now = this.baseState.currentTime;
        const timeToDie = this.health.getUnitTimeToDie(target);
        const rate = (-1 * health) / timeToDie;
        return returnValueBetween(now, INFINITY, health, now, rate);
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
    private healthMissing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health = this.health.getUnitHealth(target) || 0;
        const maxHealth = this.health.getUnitHealthMax(target) || 1;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const missing = maxHealth - health;
            const timeToDie = this.health.getUnitTimeToDie(target);
            const rate = health / timeToDie;
            return returnValueBetween(now, INFINITY, missing, now, rate);
        }
        return returnConstant(maxHealth);
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
    private healthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health = this.health.getUnitHealth(target) || 0;
        if (health > 0) {
            const now = this.baseState.currentTime;
            const maxHealth = this.health.getUnitHealthMax(target) || 1;
            const healthPct = (health / maxHealth) * 100;
            const timeToDie = this.health.getUnitTimeToDie(target);
            const rate = (-1 * healthPct) / timeToDie;
            return returnValueBetween(now, INFINITY, healthPct, now, rate);
        }
        return returnConstant(0);
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
    private effectiveHealthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health =
            this.health.getUnitHealth(target) +
                this.health.getUnitAbsorb(target) -
                this.health.getUnitHealAbsorb(target) || 0;

        const now = this.baseState.currentTime;
        const maxHealth = this.health.getUnitHealthMax(target) || 1;
        const healthPct = (health / maxHealth) * 100;
        const timeToDie = this.health.getUnitTimeToDie(target);
        const rate = (-1 * healthPct) / timeToDie;
        return returnValueBetween(now, INFINITY, healthPct, now, rate);
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
    private maxHealth = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const value = this.health.getUnitHealthMax(target);
        return returnConstant(value);
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
    private timeToDie = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const now = this.baseState.currentTime;
        const timeToDie = this.health.getUnitTimeToDie(target);
        return returnValueBetween(now, INFINITY, timeToDie, now, -1);
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
    private timeToHealthPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const percent = positionalParams[1];
        const [target] = this.parseCondition(positionalParams, namedParams);
        const health = this.health.getUnitHealth(target) || 0;
        if (health > 0) {
            const maxHealth = this.health.getUnitHealthMax(target) || 1;
            const healthPct = (health / maxHealth) * 100;
            if (healthPct >= percent) {
                const now = this.baseState.currentTime;
                const timeToDie = this.health.getUnitTimeToDie(target);
                const t = (timeToDie * (healthPct - percent)) / healthPct;
                return returnValueBetween(now, now + t, t, now, -1);
            }
        }
        return returnConstant(0);
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
    private inFlightToTarget = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const boolean =
            this.future.next.currentCast.spellId == spellId ||
            this.future.isInFlight(spellId);
        return returnBoolean(boolean);
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
    private inRange = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = this.spells.isSpellInRange(spellId, target);
        return returnBoolean(boolean || false);
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
    private isAggroed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const [boolean] = UnitDetailedThreatSituation("player", target);
        return returnBoolean(boolean || false);
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
    private isDead = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitIsDead(target);
        return returnBoolean(boolean || false);
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
    private isEnraged = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const aura = this.auras.getAura(
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
    private isFeared = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            this.lossOfControl.hasLossOfControl("FEAR", atTime) ||
            this.lossOfControl.hasLossOfControl("FEAR_MECHANIC", atTime);
        return returnBoolean(boolean);
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
    private isFriend = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitIsFriend("player", target);
        return returnBoolean(boolean);
    };

    /** Test if the player is incapacitated.
	 @name IsIncapacitated
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsIncapacitated() Spell(every_man_for_himself)
     */
    private isIncapacitated = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            this.lossOfControl.hasLossOfControl("CONFUSE", atTime) ||
            this.lossOfControl.hasLossOfControl("STUN", atTime);
        return returnBoolean(boolean);
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
    private isInterruptible = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        let [name, , , , , , , notInterruptible] = UnitCastingInfo(target);
        if (!name) {
            [name, , , , , , notInterruptible] = UnitChannelInfo(target);
        }
        const boolean = notInterruptible != undefined && !notInterruptible;
        return returnBoolean(boolean);
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
    private isPVP = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitIsPVP(target);
        return returnBoolean(boolean);
    };
    /** Test if the player is rooted.
	 @name IsRooted
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsRooted() Item(Trinket0Slot usable=1)
     */
    private isRooted = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = this.lossOfControl.hasLossOfControl("ROOT", atTime);
        return returnBoolean(boolean);
    };

    /** Test if the player is stunned.
	 @name IsStunned
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if IsStunned() Item(Trinket0Slot usable=1)
     */
    private isStunned = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = this.lossOfControl.hasLossOfControl(
            "STUN_MECHANIC",
            atTime
        );
        return returnBoolean(boolean);
    };
    /**  Get the current number of charges of the given item in the player's inventory.
	 @name ItemCharges
	 @paramsig number or boolean
	 @return The number of charges.
	 @usage
	 if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
	     Spell(conjure_mana_gem)
     */
    private itemCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        const value = GetItemCount(itemId, false, true);
        return returnConstant(value);
    };

    /** Get the current number of the given item in the player's inventory.
	 Items with more than one charge count as one item.
	 @name ItemCount
	 @paramsig number or boolean
	 @return The count of the item.
	 @usage
	 if ItemCount(mana_gem) == 0 Spell(conjure_mana_gem)
     */
    private itemCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        const value = GetItemCount(itemId);
        return returnConstant(value);
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
    private lastDamage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const spellId = positionalParams[1];
        const value = this.spellDamage.getSpellDamage(spellId);
        if (value) {
            return returnConstant(value);
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
    private level = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        let value;
        if (target == "player") {
            value = this.paperDoll.level;
        } else {
            value = UnitLevel(target);
        }
        return returnConstant(value);
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
    private list = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [name, value] = [positionalParams[1], positionalParams[2]];
        if (
            name &&
            this.frameModule.frame &&
            this.frameModule.frame.getListValue(name) == value
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
    private name = (atTime: number, target: string) => {
        const [name] = UnitName(target);
        return returnConstant(name);
    };

    /** Test if the game is on a PTR server
	 @name PTR
	 @paramsig number
	 @return 1 if it is a PTR realm, or 0 if it is a live realm.
	 @usage
	 if PTR() > 0 Spell(wacky_new_spell)
     */
    private isPtr = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [version, , , uiVersion] = GetBuildInfo();
        const value = ((version > "9.0.2" || uiVersion > 90002) && 1) || 0;
        return returnConstant(value);
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
    private persistentMultiplier: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.guids.getUnitGUID(target);
        if (!targetGuid) return [];
        const value = this.future.getDamageMultiplier(
            spellId,
            targetGuid,
            atTime
        );
        return returnConstant(value);
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
    private petPresent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const name = namedParams.name;
        const target = "pet";
        let value = false;
        if (UnitExists(target) && !UnitIsDead(target)) {
            if (name == undefined) {
                value = true;
            } else {
                const [petName] = UnitName(target);
                value = name == petName;
            }
        }
        return returnBoolean(value);
    };

    /**  Return the maximum power of the given power type on the target.
     */
    private maxPower(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.parseCondition(positionalParams, namedParams);
        let value;
        if (target == "player") {
            value = this.powers.current.maxPower[powerType];
        } else {
            const powerInfo = this.powers.powerInfos[powerType];
            value =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
        }
        return returnConstant(value);
    }
    /** Return the amount of power of the given power type on the target.
     */
    private power(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.parseCondition(positionalParams, namedParams);
        if (target == "player") {
            const value = this.powers.next.power[powerType] || 0;
            const rate = this.powers.getPowerRateAt(
                this.powers.next,
                powerType,
                atTime
            );
            return returnValueBetween(atTime, INFINITY, value, atTime, rate);
        } else {
            const powerInfo = this.powers.powerInfos[powerType];
            const value = (powerInfo && UnitPower(target, powerInfo.id)) || 0;
            return returnConstant(value);
        }
    }
    /**Return the current deficit of power from max power on the target.
     */
    private powerDeficit(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.parseCondition(positionalParams, namedParams);
        if (target == "player") {
            const powerMax = this.powers.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                const power = this.powers.next.power[powerType] || 0;
                const rate = this.powers.getPowerRateAt(
                    this.powers.next,
                    powerType,
                    atTime
                );
                return returnValueBetween(
                    atTime,
                    INFINITY,
                    powerMax - power,
                    atTime,
                    -1 * rate
                );
            }
        } else {
            const powerInfo = this.powers.powerInfos[powerType];
            const powerMax =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
            if (powerMax > 0) {
                const power =
                    (powerInfo && UnitPower(target, powerInfo.id)) || 0;
                const value = powerMax - power;
                return returnConstant(value);
            }
        }
        return returnConstant(0);
    }

    /**Return the current percent level of power (between 0 and 100) on the target.
     */
    private powerPercent(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const [target] = this.parseCondition(positionalParams, namedParams);
        if (target == "player") {
            const powerMax = this.powers.current.maxPower[powerType] || 0;
            if (powerMax > 0) {
                const ratio = 100 / powerMax;
                const power = this.powers.next.power[powerType] || 0;
                let rate =
                    ratio *
                    this.powers.getPowerRateAt(
                        this.powers.next,
                        powerType,
                        atTime
                    );
                if (
                    (rate > 0 && power >= powerMax) ||
                    (rate < 0 && power == 0)
                ) {
                    rate = 0;
                }
                return returnValueBetween(
                    atTime,
                    INFINITY,
                    power * ratio,
                    atTime,
                    rate
                );
            }
        } else {
            const powerInfo = this.powers.powerInfos[powerType];
            const powerMax =
                (powerInfo &&
                    UnitPowerMax(target, powerInfo.id, powerInfo.segments)) ||
                0;
            if (powerMax > 0) {
                const ratio = 100 / powerMax;
                const value =
                    (powerInfo && ratio * UnitPower(target, powerInfo.id)) || 0;
                return returnConstant(value);
            }
        }
        return returnConstant(0);
    }

    /**
     Get the current amount of alternate power displayed on the alternate power bar.
	 @name AlternatePower
	 @paramsig number or boolean
	 @return The current alternate power.
     */
    private alternatePower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("alternate", positionalParams, namedParams, atTime);
    };
    /** Get the current amount of astral power for balance druids.
	 @name AstralPower
	 @paramsig number or boolean
	 @return The current runic power.
	 @usage
	 if AstraPower() > 70 Spell(frost_strike)
     */
    private astralPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("lunarpower", positionalParams, namedParams, atTime);
    };

    /**Get the current amount of stored Chi for monks.
	 @name Chi
	 @paramsig number or boolean
	 @return The amount of stored Chi.
	 @usage
	 if Chi() == 4 Spell(chi_burst)
     */
    private chi = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("chi", positionalParams, namedParams, atTime);
    };
    /**  Get the number of combo points for a feral druid or a rogue.
     @name ComboPoints
     @paramsig number or boolean
     @return The number of combo points.
     @usage
     if ComboPoints() >=1 Spell(savage_roar)
     */
    private comboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("combopoints", positionalParams, namedParams, atTime);
    };
    /**Get the current amount of energy for feral druids, non-mistweaver monks, and rogues.
	 @name Energy
	 @paramsig number or boolean
	 @return The current energy.
	 @usage
	 if Energy() > 70 Spell(vanish)
     */
    private energy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("energy", positionalParams, namedParams, atTime);
    };

    /**Get the current amount of focus for hunters.
	 @name Focus
	 @paramsig number or boolean
	 @return The current focus.
	 @usage
	 if Focus() > 70 Spell(arcane_shot)
     */
    private focus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("focus", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private fury = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("fury", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of holy power for a paladin.
	 @name HolyPower
	 @paramsig number or boolean
	 @return The amount of holy power.
	 @usage
	 if HolyPower() >= 3 Spell(word_of_glory)
     */
    private holyPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("holypower", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private insanity = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("insanity", positionalParams, namedParams, atTime);
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
    private mana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("mana", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private maelstrom = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("maelstrom", positionalParams, namedParams, atTime);
    };

    /**
     *
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private pain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("pain", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of rage for guardian druids and warriors.
	 @name Rage
	 @paramsig number or boolean
	 @return The current rage.
	 @usage
	 if Rage() > 70 Spell(heroic_strike)
     */
    private rage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("rage", positionalParams, namedParams, atTime);
    };

    /** Get the current amount of runic power for death knights.
	 @name RunicPower
	 @paramsig number or boolean
	 @return The current runic power.
	 @usage
	 if RunicPower() > 70 Spell(frost_strike)
     */
    private runicPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("runicpower", positionalParams, namedParams, atTime);
    };

    /** Get the current number of Soul Shards for warlocks.
	 @name SoulShards
	 @paramsig number or boolean
	 @return The number of Soul Shards.
	 @usage
	 if SoulShards() > 0 Spell(summon_felhunter)
     */
    private soulShards = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power("soulshards", positionalParams, namedParams, atTime);
    };
    private arcaneCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.power(
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
    private alternatePowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private astralPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private chiDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit("chi", positionalParams, namedParams, atTime);
    };
    /**
     * @name ComboPointsDeficit
     * @param positionalParams
     * @param namedParams
     * @param state
     * @param atTime
     */
    private comboPointsDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private energyDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private focusDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
            "focus",
            positionalParams,
            namedParams,
            atTime
        );
    };
    private furyDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit("fury", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for full holy power, between 0 and maximum holy power, of the target.
	 @name HolyPowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current holy power deficit.
     */
    private holyPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private manaDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit("mana", positionalParams, namedParams, atTime);
    };
    private painDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit("pain", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for a full rage bar, between 0 and maximum rage, of the target.
	 @name RageDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current rage deficit.
     */
    private rageDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit("rage", positionalParams, namedParams, atTime);
    };

    /** Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	 @name RunicPowerDeficit
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The current runic power deficit.
     */
    private runicPowerDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private soulShardsDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerDeficit(
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
    private manaPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerPercent("mana", positionalParams, namedParams, atTime);
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
    private maxAlternatePower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
            "alternate",
            positionalParams,
            namedParams,
            atTime
        );
    };
    private maxChi = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("chi", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of Chi of the target.
	 @name MaxChi
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.

l    */
    private maxComboPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
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
    private maxEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("energy", positionalParams, namedParams, atTime);
    };

    /**  Get the maximum amount of focus of the target.
	 @name MaxFocus
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private maxFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("focus", positionalParams, namedParams, atTime);
    };
    private maxFury = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("fury", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of Holy Power of the target.
	 @name MaxHolyPower
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private maxHolyPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
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
    private maxMana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("mana", positionalParams, namedParams, atTime);
    };
    private maxPain = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("pain", positionalParams, namedParams, atTime);
    };

    /** Get the maximum amount of rage of the target.
	 @name MaxRage
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private maxRage = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower("rage", positionalParams, namedParams, atTime);
    };

    /**  Get the maximum amount of Runic Power of the target.
	 @name MaxRunicPower
	 @paramsig number or boolean
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The maximum value.
     */
    private maxRunicPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
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
    private maxSoulShards = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
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
    private maxArcaneCharges = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.maxPower(
            "arcanecharges",
            positionalParams,
            namedParams,
            atTime
        );
    };

    /**  Return the amount of power of the given power type required to cast the given spell.
     */
    private powerCost(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const spell = <number>positionalParams[1];
        const spellId = this.spellBook.getKnownSpellId(spell);
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const maxCost = namedParams.max == 1;
        const [value] = (spellId &&
            this.powers.powerCost(
                spellId,
                powerType,
                atTime,
                target,
                maxCost
            )) || [0];
        return returnConstant(value);
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
    private energyCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost("energy", positionalParams, namedParams, atTime);
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
    private focusCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost("focus", positionalParams, namedParams, atTime);
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
    private manaCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost("mana", positionalParams, namedParams, atTime);
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
    private rageCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost("rage", positionalParams, namedParams, atTime);
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
    private runicPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost(
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
    private astralPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost(
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
    private mainPowerCost = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.powerCost(
            this.powers.current.powerType,
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
    private present = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitExists(target) && !UnitIsDead(target);
        return returnBoolean(boolean);
    };

    /** Test if the previous spell cast that invoked the GCD matches the given spell.
	 @name PreviousGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private previousGCDSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.spellBook.getKnownSpellId(spell);
        const count = namedParams.count as number | undefined;
        let boolean;
        if (count && count > 1) {
            boolean =
                spellId ==
                this.future.next.lastGCDSpellIds[
                    lualength(this.future.next.lastGCDSpellIds) - count + 2
                ];
        } else {
            boolean = spellId == this.future.next.lastGCDSpellId;
        }
        return returnBoolean(boolean);
    };

    /** Test if the previous spell cast that did not trigger the GCD matches the given spell.
	 @name PreviousOffGCDSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private previousOffGCDSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.spellBook.getKnownSpellId(spell);
        const boolean = spellId == this.future.next.lastOffGCDSpellcast.spellId;
        return returnBoolean(boolean);
    };

    /**  Test if the previous spell cast matches the given spell.
	 @name PreviousSpell
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
     */
    private previousSpell = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.spellBook.getKnownSpellId(spell);
        const boolean = spellId == this.future.next.lastGCDSpellId;
        return returnBoolean(boolean);
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
    private relativeLevel = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        let value, level;
        if (target == "player") {
            level = this.paperDoll.level;
        } else {
            level = UnitLevel(target);
        }
        if (level < 0) {
            value = 3;
        } else {
            value = level - this.paperDoll.level;
        }
        return returnConstant(value);
    };

    private refreshable = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            let baseDuration = this.auras.getBaseDuration(
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
    private remainingCastTime: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        let [, , , startTime, endTime] = UnitCastingInfo(target);
        if (startTime && endTime) {
            startTime = startTime / 1000;
            endTime = endTime / 1000;
            return returnValueBetween(startTime, endTime, 0, endTime, -1);
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
    private rune = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] =
            this.runes.runeCount(atTime);
        if (startCooldown < INFINITY) {
            const rate = 1 / (endCooldown - startCooldown);
            return returnValueBetween(
                startCooldown,
                INFINITY,
                count,
                startCooldown,
                rate
            );
        }
        return returnConstant(count);
    };

    private runeDeficit = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] =
            this.runes.runeDeficit(atTime);
        if (startCooldown < INFINITY) {
            const rate = -1 / (endCooldown - startCooldown);
            return returnValueBetween(
                startCooldown,
                INFINITY,
                count,
                startCooldown,
                rate
            );
        }
        return returnConstant(count);
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
    private runeCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [count, startCooldown, endCooldown] =
            this.runes.runeCount(atTime);
        if (startCooldown < INFINITY) {
            return returnValueBetween(
                startCooldown,
                endCooldown,
                count,
                startCooldown,
                0
            );
        }
        return returnConstant(count);
    };

    /**  Get the number of seconds before the player reaches the given amount of runes.
	 @name TimeToRunes
	 @paramsig number or boolean
	 @param runes. The amount of runes to reach.
	 @return The number of seconds.
	 @usage
	 if TimeToRunes(2) > 5 Spell(horn_of_winter)
     */
    private timeToRunes = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const runes = positionalParams[1];
        let seconds = this.runes.getRunesCooldown(atTime, runes);
        if (seconds < 0) {
            seconds = 0;
        }
        return returnValue(seconds, atTime, -1);
    };

    /**  Returns the value of the given snapshot stat.
     */
    private snapshot(
        statName: keyof PaperDollData,
        defaultValue: number,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        const value = this.paperDoll.getState(atTime)[statName] || defaultValue;
        return returnConstant(value);
    }

    /**  Returns the critical strike chance of the given snapshot stat.
     */
    private snapshotCritChance(
        statName: keyof PaperDollData,
        defaultValue: number,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        let value = this.paperDoll.getState(atTime)[statName] || defaultValue;
        if (namedParams.unlimited != 1 && value > 100) {
            value = 100;
        }
        return returnConstant(value);
    }

    /** Get the current agility of the player.
	 @name Agility
	 @paramsig number or boolean
	 @return The current agility.
     */
    private agility = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private attackPower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private critRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private hasteRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private intellect = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private masteryEffect = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private masteryRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private meleeCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshotCritChance(
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
    private meleeAttackSpeedPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private rangedCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshotCritChance(
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
    private spellCritChance = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshotCritChance(
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
    private spellCastSpeedPercent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private spellpower = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private stamina = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private strength = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
            "strength",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    private versatility = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
            "versatility",
            0,
            positionalParams,
            namedParams,
            atTime
        );
    };

    private versatilityRating = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.snapshot(
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
    private speed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const value = (GetUnitSpeed(target) * 100) / 7;
        return returnConstant(value);
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
    private spellChargeCooldown = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [charges, maxCharges, start, duration] =
            this.cooldown.getSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            const ending = start + duration;
            return returnValueBetween(start, ending, duration, start, -1);
        }
        return returnConstant(0);
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
    private spellCharges: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [charges, maxCharges, start, duration] =
            this.cooldown.getSpellCharges(spellId, atTime);
        if (namedParams.count == 0 && charges < maxCharges) {
            return returnValueBetween(
                atTime,
                INFINITY,
                charges + 1,
                start + duration,
                1 / duration
            );
        }
        return returnConstant(charges);
    };

    /** Get the number of seconds for a full recharge of the spell.
     * @name SpellFullRecharge
     * @paramsig number or boolean
     * @param id The spell ID.
     * @usage
     * if SpellFullRecharge(dire_frenzy) < GCD()
     *     Spell(dire_frenzy) */
    private spellFullRecharge = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [charges, maxCharges, start, chargeDuration] =
            this.cooldown.getSpellCharges(spellId, atTime);
        if (charges && charges < maxCharges) {
            const duration = (maxCharges - charges) * chargeDuration;
            const ending = start + duration;
            return returnValueBetween(start, ending, duration, start, -1);
        }
        return returnConstant(0);
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
    private spellCooldown: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const usable = namedParams.usable == 1;
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.guids.getUnitGUID(target);
        if (!targetGuid) return [];
        let earliest = INFINITY;
        for (const [, spellId] of ipairs(positionalParams)) {
            if (
                !usable ||
                this.spells.isUsableSpell(spellId, atTime, targetGuid)
            ) {
                const [start, duration] = this.cooldown.getSpellCooldown(
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
            return returnConstant(0);
        } else if (earliest > 0) {
            return returnValue(0, earliest, -1);
        }
        return returnConstant(0);
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
    private spellCooldownDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const duration = this.cooldown.getSpellCooldownDuration(
            spellId,
            atTime,
            target
        );
        return returnConstant(duration);
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
    private spellRechargeDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const cd = this.cooldown.getCD(spellId, atTime);
        const duration =
            cd.chargeDuration ||
            this.cooldown.getSpellCooldownDuration(spellId, atTime, target);
        return returnConstant(duration);
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
    private spellData: ConditionFunction = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [spellId, key] = [
            <number>positionalParams[1],
            <keyof SpellInfo>positionalParams[2],
        ];
        const si = this.data.spellInfo[spellId];
        if (si) {
            const value = si[key];
            if (value) {
                return returnConstant(<number>value);
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
    private spellInfoProperty: ConditionFunction = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [spellId, key] = [
            <number>positionalParams[1],
            <SpellInfoProperty>positionalParams[2],
        ];
        const value = this.data.getSpellInfoProperty(
            spellId,
            atTime,
            key,
            undefined
        );
        if (value) {
            return returnConstant(<number>value);
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
    private spellCount = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const spellCount = this.spells.getSpellCount(spellId);
        return returnConstant(spellCount);
    };

    /** Test if the given spell is in the spellbook.
	 A spell is known if the player has learned the spell and it is in the spellbook.
	 @name SpellKnown
	 @paramsig boolean
	 @param id The spell ID.
	 @return A boolean value.
	 @see SpellUsable
     */
    private spellKnown = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const boolean = this.spellBook.isKnownSpell(spellId);
        return returnBoolean(boolean);
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
    private spellMaxCharges: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        let [, maxCharges, ,] = this.cooldown.getSpellCharges(spellId, atTime);
        if (!maxCharges) {
            return [];
        }
        maxCharges = maxCharges || 1;
        return returnConstant(maxCharges);
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
    private spellUsable: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.guids.getUnitGUID(target);
        if (!targetGuid) return [];
        const [isUsable, noMana] = this.spells.isUsableSpell(
            spellId,
            atTime,
            targetGuid
        );
        const boolean = isUsable || noMana;
        return returnBoolean(boolean);
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
    private stealthed = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean =
            this.auras.getAura(
                "player",
                "stealthed_buff",
                atTime,
                "HELPFUL"
            ) !== undefined || IsStealthed();
        return returnBoolean(boolean);
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
    private lastSwing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        //const swing = positionalParams[1];
        const start = 0;
        oneTimeMessage("Warning: 'LastSwing()' is not implemented.");
        return returnValueBetween(start, INFINITY, 0, start, 1);
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
    private nextSwing = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        //const swing = positionalParams[1];
        const ending = 0;
        oneTimeMessage("Warning: 'NextSwing()' is not implemented.");
        return returnValueBetween(0, ending, 0, ending, -1);
    };

    /** Test if the given talent is active.
	 @name Talent
	 @paramsig boolean
	 @param id The talent ID.
	 @return A boolean value.
	 @usage
	 if Talent(blood_tap_talent) Spell(blood_tap)
     */
    private talent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const talentId = positionalParams[1];
        const boolean = this.spellBook.getTalentPoints(talentId) > 0;
        return returnBoolean(boolean);
    };

    /** Get the number of points spent in a talent (0 or 1)
	 @name TalentPoints
	 @paramsig number or boolean
	 @param talent Talent to inspect.
	 @return The number of talent points.
	 @usage
	 if TalentPoints(blood_tap_talent) Spell(blood_tap)
     */
    private talentPoints = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const talent = positionalParams[1];
        const value = this.spellBook.getTalentPoints(talent);
        return returnConstant(value);
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
    private targetIsPlayer = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        const boolean = UnitIsUnit("player", `${target}target`);
        return returnBoolean(boolean);
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
    private threat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const [, , value] = UnitDetailedThreatSituation("player", target);
        return returnConstant(value);
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
    private tickTime = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = <number>positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        let tickTime;
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            tickTime = aura.tick;
        } else {
            tickTime = this.auras.getTickLength(auraId, atTime);
        }
        if (tickTime && tickTime > 0) {
            return returnConstant(tickTime);
        }
        return returnConstant(INFINITY);
    };

    private currentTickTime = (
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = <number>positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        let tickTime;
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            tickTime = aura.tick || 0;
        } else {
            tickTime = 0;
        }
        return returnConstant(tickTime);
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
    private ticksRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura) {
            const tick = aura.tick;
            if (tick && tick > 0) {
                return returnValueBetween(
                    aura.gain,
                    INFINITY,
                    1,
                    aura.ending,
                    -1 / tick
                );
            }
        }
        return returnConstant(0);
    };

    /** Gets the remaining time until the next tick */
    private tickTimeRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const auraId = positionalParams[1];
        const [target, filter, mine] = this.parseCondition(
            positionalParams,
            namedParams
        );
        const aura = this.auras.getAura(target, auraId, atTime, filter, mine);
        if (aura && this.auras.isActiveAura(aura, atTime)) {
            const lastTickTime = aura.lastTickTime || aura.start;
            const tick = aura.tick || this.auras.getTickLength(auraId, atTime);
            const remainingTime = tick - (atTime - lastTickTime);
            if (remainingTime && remainingTime > 0) {
                return returnValueBetween(
                    aura.gain,
                    INFINITY,
                    tick,
                    lastTickTime,
                    -1
                );
            }
        }
        return returnConstant(0);
    };

    /** Get the number of seconds elapsed since the player cast the given spell.
	 @name TimeSincePreviousSpell
	 @paramsig number or boolean
	 @param id The spell ID.
	 @return The number of seconds.
	 @usage
	 if TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
     */
    private timeSincePreviousSpell: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spell = positionalParams[1];
        const spellId = this.spellBook.getKnownSpellId(spell);
        if (!spellId) return [];
        const t = this.future.getTimeOfLastCast(spellId, atTime);
        return returnValue(0, t, 1);
    };

    /** Get the time in seconds until the next scheduled Bloodlust cast.
	 Not implemented, always returns 3600 seconds.
	 @name TimeToBloodlust
	 @paramsig number or boolean
	 @return The number of seconds.
     */
    private timeToBloodlust = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 3600;
        return returnConstant(value);
    };

    private timeToEclipse = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = 3600 * 24 * 7;
        oneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.");
        return returnValue(value, atTime, -1);
    };

    /** Get the number of seconds before the player reaches the given power level.
     */
    private timeToPower(powerType: PowerType, level: number, atTime: number) {
        level = level || 0;
        const seconds = this.powers.getTimeToPowerAt(
            this.powers.next,
            level,
            powerType,
            atTime
        );
        if (seconds == 0) {
            return returnConstant(0);
        } else if (seconds < INFINITY) {
            // XXX Why isn't this (atTime, atTime + seconds)?
            return returnValueBetween(0, atTime + seconds, seconds, atTime, -1);
        } else {
            return returnConstant(INFINITY);
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
    private timeToEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const level = positionalParams[1];
        return this.timeToPower("energy", level, atTime);
    };

    /** Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	 @name TimeToMaxEnergy
	 @paramsig number or boolean
	 @return The number of seconds.
	 @see TimeToEnergy, TimeToEnergyFor
	 @usage
	 if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)
     */
    private timeToMaxEnergy = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType = "energy";
        const level = this.powers.current.maxPower[powerType] || 0;
        return this.timeToPower(powerType, level, atTime);
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
    private timeToFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const level = positionalParams[1];
        return this.timeToPower("focus", level, atTime);
    };

    /** Get the number of seconds before the player reaches maximum focus for hunters.
	 @name TimeToMaxFocus
	 @paramsig number or boolean
	 @return The number of seconds.
	 @see TimeToFocus, TimeToFocusFor
	 @usage
	 if TimeToMaxFocus() < 1.2 Spell(cobra_shot)
     */
    private timeToMaxFocus = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType: PowerType = "focus";
        const level = this.powers.current.maxPower[powerType] || 0;
        return this.timeToPower(powerType, level, atTime);
    };

    private timeToMaxMana = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const powerType: PowerType = "mana";
        const level = this.powers.current.maxPower[powerType] || 0;
        return this.timeToPower(powerType, level, atTime);
    };

    private timeToPowerFor(
        powerType: PowerType,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult {
        const spellId = <number>positionalParams[1];
        const [target] = this.parseCondition(
            positionalParams,
            namedParams,
            "target"
        );
        const targetGuid = this.guids.getUnitGUID(target);
        if (!targetGuid) return [];
        const seconds = this.spells.timeToPowerForSpell(
            spellId,
            atTime,
            targetGuid,
            powerType
        );
        if (seconds == 0) {
            return returnConstant(0);
        } else if (seconds < INFINITY) {
            // XXX Why isn't this (atTime, atTime + seconds)?
            return returnValueBetween(0, atTime + seconds, seconds, atTime, -1);
        } else {
            return returnConstant(INFINITY);
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
    private timeToEnergyFor: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.timeToPowerFor(
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
    private timeToFocusFor = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        return this.timeToPowerFor(
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
    private timeToSpell = (
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
        oneTimeMessage("Warning: 'TimeToSpell()' is not implemented.");
        return returnValue(0, atTime, -1);
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
    private timeWithHaste = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const seconds = positionalParams[1];
        const haste = (namedParams.haste as HasteType) || "spell";
        const value = this.getHastedTime(seconds, haste, atTime);
        return returnConstant(value);
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
    private totemExpires = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const id = positionalParams[1];
        let seconds = positionalParams[2];
        seconds = seconds || 0;
        const [count, , ending] = this.totem.getTotemInfo(id, atTime);
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
    private totemPresent = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const id = positionalParams[1];
        const [count, start, ending] = this.totem.getTotemInfo(id, atTime);
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
    private totemRemaining = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const id = positionalParams[1];
        const [count, start, ending] = this.totem.getTotemInfo(id, atTime);
        if (
            count !== undefined &&
            start !== undefined &&
            ending !== undefined &&
            count > 0
        ) {
            return returnValueBetween(start, ending, 0, ending, -1);
        }
        return returnConstant(0);
    };

    /** Check if a tracking is enabled
	@param spellId the spell id
	@return bool
     */
    private tracking = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const spellName = this.spellBook.getSpellName(spellId);
        const numTrackingTypes = GetNumTrackingTypes();
        let boolean = false;
        for (let i = 1; i <= numTrackingTypes; i += 1) {
            const [name, , active] = GetTrackingInfo(i);
            if (name && name == spellName) {
                boolean = active == 1;
                break;
            }
        }
        return returnBoolean(boolean);
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
    private travelTime = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        //let target = private ParseCondition = (positionalParams, namedParams, "target");
        const si = spellId && this.data.spellInfo[spellId];
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
        return returnConstant(travelTime);
    };

    /**  A condition that always returns true.
	 @name True
	 @paramsig boolean
	 @return A boolean value.
     */
    private getTrue = (
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
    private weaponDPS = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const hand = positionalParams[1];
        let value = 0;
        if (hand == "offhand" || hand == "off") {
            value = this.paperDoll.current.offHandWeaponDPS || 0;
        } else if (hand == "mainhand" || hand == "main") {
            value = this.paperDoll.current.mainHandWeaponDPS || 0;
        } else {
            value = this.paperDoll.current.mainHandWeaponDPS || 0;
        }
        return returnConstant(value);
    };

    /** Test if a sigil is charging
	 @name SigilCharging
	 @paramsig boolean
	 @param flame, silence, misery, chains
	 @return A boolean value.
	 @usage
	 if not SigilCharging(flame) Spell(sigil_of_flame)
        */
    private sigilCharging = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        let charging = false;
        for (const [, v] of ipairs(positionalParams)) {
            charging = charging || this.sigil.isSigilCharging(v, atTime);
        }
        return returnBoolean(charging);
    };

    /** Test with DBM or BigWigs (if available) whether a boss is currently engaged
	    otherwise test for known units and/or world boss
	 @name IsBossFight
	 @return A boolean value.
	 @usage
	 if IsBossFight() Spell(metamorphosis_havoc)
     */
    private isBossFight = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const bossEngaged = this.bossMod.isBossEngaged(atTime);
        return returnBoolean(bossEngaged);
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
    private race = (
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
        return returnBoolean(isRace);
    };

    /**  Check if the unit is in a party
     @name UnitInParty
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if not UnitInParty() Spell(maul)
     */
    private unitInPartyCond = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const target = (namedParams.target as string | undefined) || "player";
        const boolean = UnitInParty(target);
        return returnBoolean(boolean);
    };

    /**  Check if the unit is in raid
     @name UnitInRaid
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @usage
	 if UnitInRaid() Spell(bloodlust)
     */
    private unitInRaidCond = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const target = (namedParams.target as string | undefined) || "player";
        const raidIndex = UnitInRaid(target);
        return returnBoolean(raidIndex != undefined);
    };

    /** Check the amount of Soul Fragments for Vengeance DH
	 @usage
	 if SoulFragments() > 3 Spell(spirit_bomb)
	 */
    private soulFragments = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const value = this.demonHunterSoulFragments.soulFragments(atTime);
        return returnConstant(value);
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
    private hasDebuffType = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ): ConditionResult => {
        const [target] = this.parseCondition(positionalParams, namedParams);
        for (const [, debuffType] of ipairs(positionalParams)) {
            const aura = this.auras.getAura(
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
        const incantersFlowBuff = this.data.getSpellOrListInfo(spellId);
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
        const aura = this.auras.getAura("player", spellId, atTime, "HELPFUL");
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
        if (posLo === buffPos || posHi === buffPos) return returnValue(0, 0, 0);
        const ticksLo = (tickCycle + posLo - buffPos) % tickCycle;
        const ticksHi = (tickCycle + posHi - buffPos) % tickCycle;
        const tickTime = aura.tick;
        const tickRem = tickTime - (atTime - aura.lastTickTime);
        const value = tickRem + tickTime * (min(ticksLo, ticksHi) - 1);
        return returnValue(value, atTime, -1);
    };

    private message: ConditionFunction = (positionalParameters) => {
        oneTimeMessage(positionalParameters[1] as string);
        return returnConstant(0);
    };

    private parseCondition(
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        defaultTarget?: string
    ) {
        return parseCondition(namedParams, this.baseState, defaultTarget);
    }

    constructor(
        ovaleCondition: OvaleConditionClass,
        private data: OvaleDataClass,
        private paperDoll: OvalePaperDollClass,
        private azeriteEssence: OvaleAzeriteEssenceClass,
        private auras: OvaleAuraClass,
        private baseState: BaseState,
        private cooldown: OvaleCooldownClass,
        private future: OvaleFutureClass,
        private spellBook: OvaleSpellBookClass,
        private frameModule: OvaleFrameModuleClass,
        private guids: Guids,
        private damageTaken: OvaleDamageTakenClass,
        private powers: OvalePowerClass,
        private enemies: OvaleEnemiesClass,
        private lastSpell: LastSpell,
        private health: OvaleHealthClass,
        private ovaleOptions: OvaleOptionsClass,
        private lossOfControl: OvaleLossOfControlClass,
        private spellDamage: OvaleSpellDamageClass,
        private totem: OvaleTotemClass,
        private sigil: OvaleSigilClass,
        private demonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass,
        private runes: OvaleRunesClass,
        private bossMod: OvaleBossModClass,
        private spells: OvaleSpellsClass
    ) {
        ovaleCondition.registerCondition("message", false, this.message);

        ovaleCondition.registerCondition("present", false, this.present);
        ovaleCondition.registerCondition(
            "stacktimeto",
            false,
            this.stackTimeTo
        );
        ovaleCondition.registerCondition(
            "armorsetbonus",
            false,
            this.getArmorSetBonus
        );
        ovaleCondition.registerCondition(
            "armorsetparts",
            false,
            this.getArmorSetParts
        );
        ovaleCondition.registerCondition(
            "azeriteessenceismajor",
            false,
            this.azeriteEssenceIsMajor
        );
        ovaleCondition.registerCondition(
            "azeriteessenceisminor",
            false,
            this.azeriteEssenceIsMinor
        );
        ovaleCondition.registerCondition(
            "azeriteessenceisenabled",
            false,
            this.azeriteEssenceIsEnabled
        );
        ovaleCondition.registerCondition(
            "azeriteessencerank",
            false,
            this.azeriteEssenceRank
        );
        ovaleCondition.registerCondition(
            "baseduration",
            false,
            this.baseDuration
        );
        ovaleCondition.registerCondition(
            "buffdurationifapplied",
            false,
            this.baseDuration
        );
        ovaleCondition.registerCondition(
            "debuffdurationifapplied",
            false,
            this.baseDuration
        );
        ovaleCondition.registerCondition("buffamount", false, this.buffAmount);
        ovaleCondition.registerCondition(
            "debuffamount",
            false,
            this.buffAmount
        );
        ovaleCondition.registerCondition("tickvalue", false, this.buffAmount);
        ovaleCondition.registerCondition(
            "buffcombopoints",
            false,
            this.buffComboPoints
        );
        ovaleCondition.registerCondition(
            "debuffcombopoints",
            false,
            this.buffComboPoints
        );
        ovaleCondition.registerCondition(
            "buffcooldown",
            false,
            this.buffCooldown
        );
        ovaleCondition.registerCondition(
            "debuffcooldown",
            false,
            this.buffCooldown
        );
        ovaleCondition.registerCondition("buffcount", false, this.buffCount);
        ovaleCondition.registerCondition(
            "buffcooldownduration",
            false,
            this.buffCooldownDuration
        );
        ovaleCondition.registerCondition(
            "debuffcooldownduration",
            false,
            this.buffCooldownDuration
        );
        ovaleCondition.registerCondition(
            "buffcountonany",
            false,
            this.buffCountOnAny
        );
        ovaleCondition.registerCondition(
            "debuffcountonany",
            false,
            this.buffCountOnAny
        );
        ovaleCondition.registerCondition(
            "buffdirection",
            false,
            this.buffDirection
        );
        ovaleCondition.registerCondition(
            "debuffdirection",
            false,
            this.buffDirection
        );
        ovaleCondition.registerCondition(
            "buffduration",
            false,
            this.buffDuration
        );
        ovaleCondition.registerCondition(
            "debuffduration",
            false,
            this.buffDuration
        );
        ovaleCondition.registerCondition(
            "buffexpires",
            false,
            this.buffExpires
        );
        ovaleCondition.registerCondition(
            "debuffexpires",
            false,
            this.buffExpires
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
            this.buffPresent,
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
        ovaleCondition.registerCondition("buffgain", false, this.buffGain);
        ovaleCondition.registerCondition("debuffgain", false, this.buffGain);
        ovaleCondition.registerCondition(
            "buffimproved",
            false,
            this.buffImproved
        );
        ovaleCondition.registerCondition(
            "debuffimproved",
            false,
            this.buffImproved
        );
        ovaleCondition.registerCondition(
            "buffpersistentmultiplier",
            false,
            this.buffPersistentMultiplier
        );
        ovaleCondition.registerCondition(
            "debuffpersistentmultiplier",
            false,
            this.buffPersistentMultiplier
        );
        ovaleCondition.registerCondition(
            "buffremaining",
            false,
            this.buffRemaining
        );
        ovaleCondition.registerCondition(
            "debuffremaining",
            false,
            this.buffRemaining
        );
        ovaleCondition.registerCondition(
            "buffremains",
            false,
            this.buffRemaining
        );
        ovaleCondition.registerCondition(
            "debuffremains",
            false,
            this.buffRemaining
        );
        ovaleCondition.registerCondition(
            "buffremainingonany",
            false,
            this.buffRemainingOnAny
        );
        ovaleCondition.registerCondition(
            "debuffremainingonany",
            false,
            this.buffRemainingOnAny
        );
        ovaleCondition.registerCondition(
            "buffremainsonany",
            false,
            this.buffRemainingOnAny
        );
        ovaleCondition.registerCondition(
            "debuffremainsonany",
            false,
            this.buffRemainingOnAny
        );
        ovaleCondition.registerCondition("buffstacks", false, this.buffStacks);
        ovaleCondition.registerCondition(
            "debuffstacks",
            false,
            this.buffStacks
        );
        ovaleCondition.registerCondition("maxstacks", true, this.maxStacks);
        ovaleCondition.registerCondition(
            "buffstacksonany",
            false,
            this.buffStacksOnAny
        );
        ovaleCondition.registerCondition(
            "debuffstacksonany",
            false,
            this.buffStacksOnAny
        );
        ovaleCondition.registerCondition(
            "buffstealable",
            false,
            this.buffStealable
        );
        ovaleCondition.registerCondition("cancast", true, this.canCast);
        ovaleCondition.registerCondition("casttime", true, this.castTime);
        ovaleCondition.registerCondition("executetime", true, this.executeTime);
        ovaleCondition.registerCondition("casting", false, this.casting);
        ovaleCondition.registerCondition(
            "checkboxoff",
            false,
            this.checkBoxOff
        );
        ovaleCondition.registerCondition("checkboxon", false, this.checkBoxOn);
        ovaleCondition.registerCondition("class", false, this.getClass);
        ovaleCondition.registerCondition(
            "classification",
            false,
            this.classification
        );
        ovaleCondition.registerCondition("counter", false, this.counter);
        ovaleCondition.register(
            "creaturefamily",
            this.creatureFamily,
            { type: "none" },
            { name: "name", type: "string", optional: false },
            targetParameter
        );
        ovaleCondition.registerCondition(
            "creaturetype",
            false,
            this.creatureType
        );
        ovaleCondition.registerCondition("critdamage", false, this.critDamage);
        ovaleCondition.registerCondition("damage", false, this.damage);
        ovaleCondition.registerCondition(
            "damagetaken",
            false,
            this.getDamageTaken
        );
        ovaleCondition.registerCondition(
            "incomingdamage",
            false,
            this.getDamageTaken
        );
        ovaleCondition.registerCondition(
            "magicdamagetaken",
            false,
            this.magicDamageTaken
        );
        ovaleCondition.registerCondition(
            "incomingmagicdamage",
            false,
            this.magicDamageTaken
        );
        ovaleCondition.registerCondition(
            "physicaldamagetaken",
            false,
            this.physicalDamageTaken
        );
        ovaleCondition.registerCondition(
            "incomingphysicaldamage",
            false,
            this.physicalDamageTaken
        );
        ovaleCondition.registerCondition(
            "diseasesremaining",
            false,
            this.diseasesRemaining
        );
        ovaleCondition.registerCondition(
            "diseasesticking",
            false,
            this.diseasesTicking
        );
        ovaleCondition.registerCondition(
            "diseasesanyticking",
            false,
            this.diseasesAnyTicking
        );
        ovaleCondition.registerCondition("distance", false, this.distance);
        ovaleCondition.registerCondition("enemies", false, this.getEnemies);
        ovaleCondition.registerCondition(
            "energyregen",
            false,
            this.energyRegenRate
        );
        ovaleCondition.registerCondition(
            "energyregenrate",
            false,
            this.energyRegenRate
        );
        ovaleCondition.registerCondition(
            "enrageremaining",
            false,
            this.enrageRemaining
        );
        ovaleCondition.registerCondition("exists", false, this.exists);
        ovaleCondition.registerCondition("never", false, this.getFalse);
        ovaleCondition.registerCondition(
            "focusregen",
            false,
            this.focusRegenRate
        );
        ovaleCondition.registerCondition(
            "focusregenrate",
            false,
            this.focusRegenRate
        );
        ovaleCondition.registerCondition(
            "focuscastingregen",
            false,
            this.focusCastingRegen
        );
        ovaleCondition.registerCondition("gcd", false, this.getGCD);
        ovaleCondition.registerCondition(
            "gcdremaining",
            false,
            this.getGCDRemaining
        );
        ovaleCondition.registerCondition("glyph", false, this.glyph);
        ovaleCondition.registerCondition(
            "hasfullcontrol",
            false,
            this.hasFullControlCondition
        );
        ovaleCondition.registerCondition("health", false, this.getHealth);
        ovaleCondition.registerCondition("life", false, this.getHealth);
        ovaleCondition.registerCondition(
            "effectivehealth",
            false,
            this.effectiveHealth
        );
        ovaleCondition.registerCondition(
            "healthmissing",
            false,
            this.healthMissing
        );
        ovaleCondition.registerCondition(
            "lifemissing",
            false,
            this.healthMissing
        );
        ovaleCondition.registerCondition(
            "healthpercent",
            false,
            this.healthPercent
        );
        ovaleCondition.registerCondition(
            "lifepercent",
            false,
            this.healthPercent
        );
        ovaleCondition.registerCondition(
            "effectivehealthpercent",
            false,
            this.effectiveHealthPercent
        );
        ovaleCondition.registerCondition("maxhealth", false, this.maxHealth);
        ovaleCondition.registerCondition("deadin", false, this.timeToDie);
        ovaleCondition.registerCondition("timetodie", false, this.timeToDie);
        ovaleCondition.registerCondition(
            "timetohealthpercent",
            false,
            this.timeToHealthPercent
        );
        ovaleCondition.registerCondition(
            "timetolifepercent",
            false,
            this.timeToHealthPercent
        );
        ovaleCondition.registerCondition(
            "inflighttotarget",
            false,
            this.inFlightToTarget
        );
        ovaleCondition.registerCondition("inrange", false, this.inRange);
        ovaleCondition.registerCondition("isaggroed", false, this.isAggroed);
        ovaleCondition.registerCondition("isdead", false, this.isDead);
        ovaleCondition.registerCondition("isenraged", false, this.isEnraged);
        ovaleCondition.registerCondition("isfeared", false, this.isFeared);
        ovaleCondition.registerCondition("isfriend", false, this.isFriend);
        ovaleCondition.registerCondition(
            "isincapacitated",
            false,
            this.isIncapacitated
        );
        ovaleCondition.registerCondition(
            "isinterruptible",
            false,
            this.isInterruptible
        );
        ovaleCondition.registerCondition("ispvp", false, this.isPVP);
        ovaleCondition.registerCondition("isrooted", false, this.isRooted);
        ovaleCondition.registerCondition("isstunned", false, this.isStunned);
        ovaleCondition.registerCondition(
            "itemcharges",
            false,
            this.itemCharges
        );
        ovaleCondition.registerCondition("itemcount", false, this.itemCount);
        ovaleCondition.registerCondition("lastdamage", false, this.lastDamage);
        ovaleCondition.registerCondition(
            "lastspelldamage",
            false,
            this.lastDamage
        );
        ovaleCondition.registerCondition("level", false, this.level);
        ovaleCondition.registerCondition("list", false, this.list);
        ovaleCondition.register(
            "name",
            this.name,
            { type: "string" },
            targetParameter
        );
        ovaleCondition.registerCondition("ptr", false, this.isPtr);
        ovaleCondition.registerCondition(
            "persistentmultiplier",
            false,
            this.persistentMultiplier
        );
        ovaleCondition.registerCondition("petpresent", false, this.petPresent);
        ovaleCondition.registerCondition(
            "alternatepower",
            false,
            this.alternatePower
        );
        ovaleCondition.registerCondition(
            "arcanecharges",
            false,
            this.arcaneCharges
        );
        ovaleCondition.registerCondition(
            "astralpower",
            false,
            this.astralPower
        );
        ovaleCondition.registerCondition("chi", false, this.chi);
        ovaleCondition.registerCondition(
            "combopoints",
            false,
            this.comboPoints
        );
        ovaleCondition.registerCondition("energy", false, this.energy);
        ovaleCondition.registerCondition("focus", false, this.focus);
        ovaleCondition.registerCondition("fury", false, this.fury);
        ovaleCondition.registerCondition("holypower", false, this.holyPower);
        ovaleCondition.registerCondition("insanity", false, this.insanity);
        ovaleCondition.registerCondition("maelstrom", false, this.maelstrom);
        ovaleCondition.registerCondition("mana", false, this.mana);
        ovaleCondition.registerCondition("pain", false, this.pain);
        ovaleCondition.registerCondition("rage", false, this.rage);
        ovaleCondition.registerCondition("runicpower", false, this.runicPower);
        ovaleCondition.registerCondition("soulshards", false, this.soulShards);
        ovaleCondition.registerCondition(
            "alternatepowerdeficit",
            false,
            this.alternatePowerDeficit
        );
        ovaleCondition.registerCondition(
            "astralpowerdeficit",
            false,
            this.astralPowerDeficit
        );
        ovaleCondition.registerCondition("chideficit", false, this.chiDeficit);
        ovaleCondition.registerCondition(
            "combopointsdeficit",
            false,
            this.comboPointsDeficit
        );
        ovaleCondition.registerCondition(
            "energydeficit",
            false,
            this.energyDeficit
        );
        ovaleCondition.registerCondition(
            "focusdeficit",
            false,
            this.focusDeficit
        );
        ovaleCondition.registerCondition(
            "furydeficit",
            false,
            this.furyDeficit
        );
        ovaleCondition.registerCondition(
            "holypowerdeficit",
            false,
            this.holyPowerDeficit
        );
        ovaleCondition.registerCondition(
            "manadeficit",
            false,
            this.manaDeficit
        );
        ovaleCondition.registerCondition(
            "paindeficit",
            false,
            this.painDeficit
        );
        ovaleCondition.registerCondition(
            "ragedeficit",
            false,
            this.rageDeficit
        );
        ovaleCondition.registerCondition(
            "runicpowerdeficit",
            false,
            this.runicPowerDeficit
        );
        ovaleCondition.registerCondition(
            "soulshardsdeficit",
            false,
            this.soulShardsDeficit
        );
        ovaleCondition.registerCondition(
            "manapercent",
            false,
            this.manaPercent
        );
        ovaleCondition.registerCondition(
            "maxalternatepower",
            false,
            this.maxAlternatePower
        );
        ovaleCondition.registerCondition(
            "maxarcanecharges",
            false,
            this.maxArcaneCharges
        );
        ovaleCondition.registerCondition("maxchi", false, this.maxChi);
        ovaleCondition.registerCondition(
            "maxcombopoints",
            false,
            this.maxComboPoints
        );
        ovaleCondition.registerCondition("maxenergy", false, this.maxEnergy);
        ovaleCondition.registerCondition("maxfocus", false, this.maxFocus);
        ovaleCondition.registerCondition("maxfury", false, this.maxFury);
        ovaleCondition.registerCondition(
            "maxholypower",
            false,
            this.maxHolyPower
        );
        ovaleCondition.registerCondition("maxmana", false, this.maxMana);
        ovaleCondition.registerCondition("maxpain", false, this.maxPain);
        ovaleCondition.registerCondition("maxrage", false, this.maxRage);
        ovaleCondition.registerCondition(
            "maxrunicpower",
            false,
            this.maxRunicPower
        );
        ovaleCondition.registerCondition(
            "maxsoulshards",
            false,
            this.maxSoulShards
        );
        ovaleCondition.registerCondition("powercost", true, this.mainPowerCost);
        ovaleCondition.registerCondition(
            "astralpowercost",
            true,
            this.astralPowerCost
        );
        ovaleCondition.registerCondition("energycost", true, this.energyCost);
        ovaleCondition.registerCondition("focuscost", true, this.focusCost);
        ovaleCondition.registerCondition("manacost", true, this.manaCost);
        ovaleCondition.registerCondition("ragecost", true, this.rageCost);
        ovaleCondition.registerCondition(
            "runicpowercost",
            true,
            this.runicPowerCost
        );
        ovaleCondition.registerCondition(
            "previousgcdspell",
            true,
            this.previousGCDSpell
        );
        ovaleCondition.registerCondition(
            "previousoffgcdspell",
            true,
            this.previousOffGCDSpell
        );
        ovaleCondition.registerCondition(
            "previousspell",
            true,
            this.previousSpell
        );
        ovaleCondition.registerCondition(
            "relativelevel",
            false,
            this.relativeLevel
        );
        ovaleCondition.registerCondition(
            "refreshable",
            false,
            this.refreshable
        );
        ovaleCondition.registerCondition(
            "debuffrefreshable",
            false,
            this.refreshable
        );
        ovaleCondition.registerCondition(
            "buffrefreshable",
            false,
            this.refreshable
        );
        ovaleCondition.registerCondition(
            "remainingcasttime",
            false,
            this.remainingCastTime
        );
        ovaleCondition.registerCondition("rune", false, this.rune);
        ovaleCondition.registerCondition("runecount", false, this.runeCount);
        ovaleCondition.registerCondition(
            "timetorunes",
            false,
            this.timeToRunes
        );
        ovaleCondition.registerCondition(
            "runedeficit",
            false,
            this.runeDeficit
        );
        ovaleCondition.registerCondition("agility", false, this.agility);
        ovaleCondition.registerCondition(
            "attackpower",
            false,
            this.attackPower
        );
        ovaleCondition.registerCondition("critrating", false, this.critRating);
        ovaleCondition.registerCondition(
            "hasterating",
            false,
            this.hasteRating
        );
        ovaleCondition.registerCondition("intellect", false, this.intellect);
        ovaleCondition.registerCondition("mastery", false, this.masteryEffect);
        ovaleCondition.registerCondition(
            "masteryeffect",
            false,
            this.masteryEffect
        );
        ovaleCondition.registerCondition(
            "masteryrating",
            false,
            this.masteryRating
        );
        ovaleCondition.registerCondition(
            "meleecritchance",
            false,
            this.meleeCritChance
        );
        ovaleCondition.registerCondition(
            "meleeattackspeedpercent",
            false,
            this.meleeAttackSpeedPercent
        );
        ovaleCondition.registerCondition(
            "rangedcritchance",
            false,
            this.rangedCritChance
        );
        ovaleCondition.registerCondition(
            "spellcritchance",
            false,
            this.spellCritChance
        );
        ovaleCondition.registerCondition(
            "spellcastspeedpercent",
            false,
            this.spellCastSpeedPercent
        );
        ovaleCondition.registerCondition("spellpower", false, this.spellpower);
        ovaleCondition.registerCondition("stamina", false, this.stamina);
        ovaleCondition.registerCondition("strength", false, this.strength);
        ovaleCondition.registerCondition(
            "versatility",
            false,
            this.versatility
        );
        ovaleCondition.registerCondition(
            "versatilityRating",
            false,
            this.versatilityRating
        );
        ovaleCondition.registerCondition("speed", false, this.speed);
        ovaleCondition.registerCondition(
            "spellchargecooldown",
            true,
            this.spellChargeCooldown
        );
        ovaleCondition.registerCondition("charges", true, this.spellCharges);
        ovaleCondition.registerCondition(
            "spellcharges",
            true,
            this.spellCharges
        );
        ovaleCondition.registerCondition(
            "spellfullrecharge",
            true,
            this.spellFullRecharge
        );
        ovaleCondition.registerCondition(
            "spellcooldown",
            true,
            this.spellCooldown
        );
        ovaleCondition.registerCondition(
            "spellcooldownduration",
            true,
            this.spellCooldownDuration
        );
        ovaleCondition.registerCondition(
            "spellrechargeduration",
            true,
            this.spellRechargeDuration
        );
        ovaleCondition.registerCondition("spelldata", false, this.spellData);
        ovaleCondition.registerCondition(
            "spellinfoproperty",
            false,
            this.spellInfoProperty
        );
        ovaleCondition.registerCondition("spellcount", true, this.spellCount);
        ovaleCondition.registerCondition("spellknown", true, this.spellKnown);
        ovaleCondition.registerCondition(
            "spellmaxcharges",
            true,
            this.spellMaxCharges
        );
        ovaleCondition.registerCondition("spellusable", true, this.spellUsable);
        ovaleCondition.registerCondition("isstealthed", false, this.stealthed);
        ovaleCondition.registerCondition("stealthed", false, this.stealthed);
        ovaleCondition.registerCondition("lastswing", false, this.lastSwing);
        ovaleCondition.registerCondition("nextswing", false, this.nextSwing);
        ovaleCondition.registerCondition("talent", false, this.talent);
        ovaleCondition.registerCondition("hastalent", false, this.talent);
        ovaleCondition.registerCondition(
            "talentpoints",
            false,
            this.talentPoints
        );
        ovaleCondition.registerCondition(
            "istargetingplayer",
            false,
            this.targetIsPlayer
        );
        ovaleCondition.registerCondition(
            "targetisplayer",
            false,
            this.targetIsPlayer
        );
        ovaleCondition.registerCondition("threat", false, this.threat);
        ovaleCondition.registerCondition("ticktime", false, this.tickTime);
        ovaleCondition.registerCondition(
            "currentticktime",
            false,
            this.currentTickTime
        );
        ovaleCondition.registerCondition(
            "ticksremaining",
            false,
            this.ticksRemaining
        );
        ovaleCondition.registerCondition(
            "ticksremain",
            false,
            this.ticksRemaining
        );
        ovaleCondition.registerCondition(
            "ticktimeremaining",
            false,
            this.tickTimeRemaining
        );
        ovaleCondition.registerCondition(
            "timesincepreviousspell",
            false,
            this.timeSincePreviousSpell
        );
        ovaleCondition.registerCondition(
            "timetobloodlust",
            false,
            this.timeToBloodlust
        );
        ovaleCondition.registerCondition(
            "timetoeclipse",
            false,
            this.timeToEclipse
        );
        ovaleCondition.registerCondition(
            "timetoenergy",
            false,
            this.timeToEnergy
        );
        ovaleCondition.registerCondition(
            "timetofocus",
            false,
            this.timeToFocus
        );
        ovaleCondition.registerCondition(
            "timetomaxenergy",
            false,
            this.timeToMaxEnergy
        );
        ovaleCondition.registerCondition(
            "timetomaxfocus",
            false,
            this.timeToMaxFocus
        );
        ovaleCondition.registerCondition(
            "timetomaxmana",
            false,
            this.timeToMaxMana
        );
        ovaleCondition.registerCondition(
            "timetoenergyfor",
            true,
            this.timeToEnergyFor
        );
        ovaleCondition.registerCondition(
            "timetofocusfor",
            true,
            this.timeToFocusFor
        );
        ovaleCondition.registerCondition("timetospell", true, this.timeToSpell);
        ovaleCondition.registerCondition(
            "timewithhaste",
            false,
            this.timeWithHaste
        );
        ovaleCondition.registerCondition(
            "totemexpires",
            false,
            this.totemExpires
        );
        ovaleCondition.registerCondition(
            "totempresent",
            false,
            this.totemPresent
        );
        ovaleCondition.registerCondition(
            "totemremaining",
            false,
            this.totemRemaining
        );
        ovaleCondition.registerCondition(
            "totemremains",
            false,
            this.totemRemaining
        );
        ovaleCondition.registerCondition("tracking", false, this.tracking);
        ovaleCondition.registerCondition("traveltime", true, this.travelTime);
        ovaleCondition.registerCondition(
            "maxtraveltime",
            true,
            this.travelTime
        );
        ovaleCondition.registerCondition("always", false, this.getTrue);
        ovaleCondition.registerCondition("weapondps", false, this.weaponDPS);
        ovaleCondition.registerCondition(
            "sigilcharging",
            false,
            this.sigilCharging
        );
        ovaleCondition.registerCondition(
            "isbossfight",
            false,
            this.isBossFight
        );
        ovaleCondition.registerCondition("race", false, this.race);
        ovaleCondition.registerCondition(
            "unitinparty",
            false,
            this.unitInPartyCond
        );
        ovaleCondition.registerCondition(
            "unitinraid",
            false,
            this.unitInRaidCond
        );
        ovaleCondition.registerCondition(
            "soulfragments",
            false,
            this.soulFragments
        );
        ovaleCondition.registerCondition(
            "hasdebufftype",
            false,
            this.hasDebuffType
        );
    }
}
