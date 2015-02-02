local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_rogue"
	local desc = "[6.0] Ovale: Rotations (Assassination, Combat, Subtlety)"
	local code = [[
# Rogue rotation functions based on SimulationCraft.

###
### Assassination
###
# Based on SimulationCraft profile "Rogue_Assassination_T17M".
#	class=rogue
#	spec=assassination
#	talents=3000023
#	glyphs=vendetta/energy/disappearance

AddCheckBox(opt_interrupt L(interrupt) default specialization=assassination)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=assassination)

AddFunction AssassinationUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction AssassinationUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction AssassinationGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction AssassinationInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
	#rupture,if=combo_points=5&ticks_remain<3
	if ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
	#rupture,cycle_targets=1,if=active_enemies>1&!ticking&combo_points=5
	if Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 Spell(rupture)
	#mutilate,if=buff.stealth.up
	if BuffPresent(stealthed_buff any=1) Spell(mutilate)
	#slice_and_dice,if=buff.slice_and_dice.remains<5
	if BuffRemaining(slice_and_dice_buff) < 5 Spell(slice_and_dice)
	#crimson_tempest,if=combo_points>4&active_enemies>=4&remains<8
	if ComboPoints() > 4 and Enemies() >= 4 and target.DebuffRemaining(crimson_tempest_debuff) < 8 Spell(crimson_tempest)
	#fan_of_knives,if=combo_points<5&active_enemies>=4
	if ComboPoints() < 5 and Enemies() >= 4 Spell(fan_of_knives)
	#rupture,if=(remains<2|(combo_points=5&remains<=(duration*0.3)))&active_enemies=1
	if { target.DebuffRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 } and Enemies() == 1 Spell(rupture)
	#death_from_above,if=combo_points>4
	if ComboPoints() > 4 Spell(death_from_above)
	#envenom,cycle_targets=1,if=(combo_points>4&(cooldown.death_from_above.remains>2|!talent.death_from_above.enabled))&active_enemies<4&!dot.deadly_poison_dot.ticking
	if ComboPoints() > 4 and { SpellCooldown(death_from_above) > 2 or not Talent(death_from_above_talent) } and Enemies() < 4 and not target.DebuffPresent(deadly_poison_dot_debuff) Spell(envenom)
	#envenom,if=(combo_points>4&(cooldown.death_from_above.remains>2|!talent.death_from_above.enabled))&active_enemies<4&(buff.envenom.remains<=1.8|energy>55)
	if ComboPoints() > 4 and { SpellCooldown(death_from_above) > 2 or not Talent(death_from_above_talent) } and Enemies() < 4 and { BuffRemaining(envenom_buff) <= 1.8 or Energy() > 55 } Spell(envenom)
	#fan_of_knives,cycle_targets=1,if=active_enemies>2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if Enemies() > 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(fan_of_knives)
	#mutilate,cycle_targets=1,if=target.health.pct>35&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<3))&active_enemies=2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if target.HealthPercent() > 35 and { ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and Enemies() == 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(mutilate)
	#mutilate,if=target.health.pct>35&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<3))&active_enemies<5
	if target.HealthPercent() > 35 and { ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and Enemies() < 5 Spell(mutilate)
	#dispatch,cycle_targets=1,if=(combo_points<5|(talent.anticipation.enabled&anticipation_charges<4))&active_enemies=2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and Enemies() == 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(dispatch)
	#dispatch,if=(combo_points<5|(talent.anticipation.enabled&anticipation_charges<4))&active_enemies<4
	if { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and Enemies() < 4 Spell(dispatch)
	#mutilate,cycle_targets=1,if=active_enemies=2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if Enemies() == 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(mutilate)
	#mutilate,if=active_enemies<5
	if Enemies() < 5 Spell(mutilate)
}

AddFunction AssassinationDefaultShortCdActions
{
	#vanish,if=time>10&!buff.stealth.up
	if TimeInCombat() > 10 and not BuffPresent(stealthed_buff any=1) Spell(vanish)
	#auto_attack
	AssassinationGetInMeleeRange()

	unless ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture) or BuffPresent(stealthed_buff any=1) and Spell(mutilate) or BuffRemaining(slice_and_dice_buff) < 5 and Spell(slice_and_dice)
	{
		#marked_for_death,if=combo_points=0
		if ComboPoints() == 0 Spell(marked_for_death)
	}
}

AddFunction AssassinationDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|debuff.vendetta.up
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or target.DebuffPresent(vendetta_debuff) AssassinationUsePotionAgility()
	#kick
	AssassinationInterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff any=1) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=trinket2,if=active_enemies>1|(debuff.vendetta.up&active_enemies=1)
	if Enemies() > 1 or target.DebuffPresent(vendetta_debuff) and Enemies() == 1 AssassinationUseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture) or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture) or BuffPresent(stealthed_buff any=1) and Spell(mutilate) or BuffRemaining(slice_and_dice_buff) < 5 and Spell(slice_and_dice) or ComboPoints() > 4 and Enemies() >= 4 and target.DebuffRemaining(crimson_tempest_debuff) < 8 and Spell(crimson_tempest) or ComboPoints() < 5 and Enemies() >= 4 and Spell(fan_of_knives) or { target.DebuffRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= BaseDuration(rupture_debuff) * 0.3 } and Enemies() == 1 and Spell(rupture)
	{
		#shadow_reflection,if=cooldown.vendetta.remains=0
		if not SpellCooldown(vendetta) > 0 Spell(shadow_reflection)
		#vendetta,if=buff.shadow_reflection.up|!talent.shadow_reflection.enabled
		if BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) Spell(vendetta)
	}
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_surprise
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		AssassinationUsePotionAgility()
	}
}

AddFunction AssassinationPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and Spell(slice_and_dice)
}

###
### Combat
###
# Based on SimulationCraft profile "Rogue_Combat_T17M".
#	class=rogue
#	spec=combat
#	talents=3000021
#	glyphs=energy/disappearance

AddCheckBox(opt_interrupt L(interrupt) default specialization=combat)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=combat)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=combat)
AddCheckBox(opt_blade_flurry SpellName(blade_flurry) default specialization=combat)

AddFunction CombatUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction CombatUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction CombatGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction CombatInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction CombatDefaultMainActions
{
	#ambush
	Spell(ambush)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|((target.time_to_die>45&combo_points=5&buff.slice_and_dice.remains<12)&buff.deep_insight.down)
	if { BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) } and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) Spell(slice_and_dice)
	#call_action_list,name=generator,if=combo_points<5|!dot.revealing_strike.ticking|(talent.anticipation.enabled&anticipation_charges<3&buff.deep_insight.down)
	if ComboPoints() < 5 or not target.DebuffPresent(revealing_strike_debuff) or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and BuffExpires(deep_insight_buff) CombatGeneratorMainActions()
	#call_action_list,name=finisher,if=combo_points=5&dot.revealing_strike.ticking&(buff.deep_insight.up|!talent.anticipation.enabled|(talent.anticipation.enabled&anticipation_charges>=3))
	if ComboPoints() == 5 and target.DebuffPresent(revealing_strike_debuff) and { BuffPresent(deep_insight_buff) or not Talent(anticipation_talent) or Talent(anticipation_talent) and BuffStacks(anticipation_buff) >= 3 } CombatFinisherMainActions()
}

AddFunction CombatDefaultShortCdActions
{
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if { Enemies() >= 2 and not BuffPresent(blade_flurry_buff) or Enemies() < 2 and BuffPresent(blade_flurry_buff) } and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)

	unless Spell(ambush)
	{
		#auto_attack
		CombatGetInMeleeRange()
		#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4)))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<90&energy>=15)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
		if TimeInCombat() > 10 and { ComboPoints() < 3 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and { Talent(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 90 and Energy() >= 15 or Talent(subterfuge_talent) and Energy() >= 90 or not Talent(shadow_focus_talent) and not Talent(subterfuge_talent) and Energy() >= 60 } Spell(vanish)

		unless { BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) } and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) and Spell(slice_and_dice)
		{
			#marked_for_death,if=combo_points<=1&dot.revealing_strike.ticking&(!talent.shadow_reflection.enabled|buff.shadow_reflection.up|cooldown.shadow_reflection.remains>30)
			if ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) and { not Talent(shadow_reflection_talent) or BuffPresent(shadow_reflection_buff) or SpellCooldown(shadow_reflection) > 30 } Spell(marked_for_death)
		}
	}
}

AddFunction CombatDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.adrenaline_rush.up&(trinket.proc.any.react|trinket.stacking_proc.any.react|buff.archmages_greater_incandescence_agi.react))
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or BuffPresent(adrenaline_rush_buff) and { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } CombatUsePotionAgility()
	#kick
	CombatInterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>30
	if not BuffPresent(vanish_buff any=1) and SpellCooldown(vanish) > 30 Spell(preparation)
	#use_item,slot=trinket2
	CombatUseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#shadow_reflection,if=(cooldown.killing_spree.remains<10&combo_points>3)|buff.adrenaline_rush.up
	if SpellCooldown(killing_spree) < 10 and ComboPoints() > 3 or BuffPresent(adrenaline_rush_buff) Spell(shadow_reflection)

	unless Spell(ambush) or { BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) } and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) and Spell(slice_and_dice)
	{
		#call_action_list,name=adrenaline_rush,if=(energy<35|buff.bloodlust.up)&cooldown.killing_spree.remains>10
		if { Energy() < 35 or BuffPresent(burst_haste_buff any=1) } and SpellCooldown(killing_spree) > 10 CombatAdrenalineRushCdActions()
		#call_action_list,name=killing_spree,if=(energy<40|(buff.bloodlust.up&time<10)|buff.bloodlust.remains>20)&buff.adrenaline_rush.down&(!talent.shadow_reflection.enabled|cooldown.shadow_reflection.remains>30|buff.shadow_reflection.remains>3)
		if { Energy() < 40 or BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 10 or BuffRemaining(burst_haste_buff any=1) > 20 } and BuffExpires(adrenaline_rush_buff) and { not Talent(shadow_reflection_talent) or SpellCooldown(shadow_reflection) > 30 or BuffRemaining(shadow_reflection_buff) > 3 } CombatKillingSpreeCdActions()
	}
}

### actions.adrenaline_rush

AddFunction CombatAdrenalineRushCdActions
{
	#adrenaline_rush,if=time_to_die>=44
	if target.TimeToDie() >= 44 Spell(adrenaline_rush)
	#adrenaline_rush,if=time_to_die<44&(buff.archmages_greater_incandescence_agi.react|trinket.proc.any.react|trinket.stacking_proc.any.react)
	if target.TimeToDie() < 44 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) } Spell(adrenaline_rush)
	#adrenaline_rush,if=time_to_die<=buff.adrenaline_rush.duration*1.5
	if target.TimeToDie() <= BaseDuration(adrenaline_rush_buff) * 1.5 Spell(adrenaline_rush)
}

### actions.finisher

AddFunction CombatFinisherMainActions
{
	#death_from_above
	Spell(death_from_above)
	#eviscerate,if=(!talent.death_from_above.enabled|cooldown.death_from_above.remains)
	if not Talent(death_from_above_talent) or SpellCooldown(death_from_above) > 0 Spell(eviscerate)
}

### actions.generator

AddFunction CombatGeneratorMainActions
{
	#revealing_strike,if=(combo_points=4&dot.revealing_strike.remains<7.2&(target.time_to_die>dot.revealing_strike.remains+7.2)|(target.time_to_die<dot.revealing_strike.remains+7.2&ticks_remain<2))|!ticking
	if ComboPoints() == 4 and target.DebuffRemaining(revealing_strike_debuff) < 7.2 and target.TimeToDie() > target.DebuffRemaining(revealing_strike_debuff) + 7.2 or target.TimeToDie() < target.DebuffRemaining(revealing_strike_debuff) + 7.2 and target.TicksRemaining(revealing_strike_debuff) < 2 or not target.DebuffPresent(revealing_strike_debuff) Spell(revealing_strike)
	#sinister_strike,if=dot.revealing_strike.ticking
	if target.DebuffPresent(revealing_strike_debuff) Spell(sinister_strike)
}

### actions.killing_spree

AddFunction CombatKillingSpreeCdActions
{
	#killing_spree,if=time_to_die>=44
	if target.TimeToDie() >= 44 Spell(killing_spree)
	#killing_spree,if=time_to_die<44&buff.archmages_greater_incandescence_agi.react&buff.archmages_greater_incandescence_agi.remains>=buff.killing_spree.duration
	if target.TimeToDie() < 44 and BuffPresent(archmages_greater_incandescence_agi_buff) and BuffRemaining(archmages_greater_incandescence_agi_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<44&trinket.proc.any.react&trinket.proc.any.remains>=buff.killing_spree.duration
	if target.TimeToDie() < 44 and BuffPresent(trinket_proc_any_buff) and BuffRemaining(trinket_proc_any_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<44&trinket.stacking_proc.any.react&trinket.stacking_proc.any.remains>=buff.killing_spree.duration
	if target.TimeToDie() < 44 and BuffPresent(trinket_stacking_proc_any_buff) and BuffRemaining(trinket_stacking_proc_any_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<=buff.killing_spree.duration*1.5
	if target.TimeToDie() <= BaseDuration(killing_spree_buff) * 1.5 Spell(killing_spree)
}

### actions.precombat

AddFunction CombatPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=frosty_stew
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction CombatPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction CombatPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) and Spell(slice_and_dice)
}

AddFunction CombatPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		CombatUsePotionAgility()
	}
}

AddFunction CombatPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Talent(marked_for_death_talent) and BuffRemaining(slice_and_dice_buff) < BaseDuration(slice_and_dice_buff) and Spell(slice_and_dice)
}

###
### Subtlety
###
# Based on SimulationCraft profile "Rogue_Subtlety_T17M".
#	class=rogue
#	spec=subtlety
#	talents=2000022
#	glyphs=energy/hemorrhaging_veins/vanish

Define(honor_among_thieves_cooldown_buff 51699)
	SpellInfo(honor_among_thieves_cooldown_buff duration=2.2)

AddCheckBox(opt_interrupt L(interrupt) default specialization=subtlety)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=subtlety)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=subtlety)

AddFunction SubtletyUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction SubtletyUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction SubtletyGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction SubtletyInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
	#premeditation,if=combo_points<4|(talent.anticipation.enabled&(combo_points+anticipation_charges<9))
	if { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and ComboPoints() < 5 Spell(premeditation)
	#pool_resource,for_next=1
	#garrote,if=time<1
	if TimeInCombat() < 1 Spell(garrote)
	unless TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
		unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.remains<2|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
			unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffRemaining(find_weakness_debuff) < 2 or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=50
					#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
					unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
						unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#pool_resource,for_next=1,extra_amount=90
							#shadowmeld,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
							unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
							{
								#run_action_list,name=finisher,if=combo_points=5
								if ComboPoints() == 5 SubtletyFinisherMainActions()
								#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|(talent.anticipation.enabled&anticipation_charges<4)
								if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 SubtletyGeneratorMainActions()
							}
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyDefaultShortCdActions
{
	#pool_resource,for_next=1
	#garrote,if=time<1
	unless TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		#auto_attack
		SubtletyGetInMeleeRange()
		#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
		unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.remains<2|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
			if Energy() >= 50 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffRemaining(find_weakness_debuff) < 2 or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } Spell(shadow_dance)
			unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffRemaining(find_weakness_debuff) < 2 or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
				if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 Spell(vanish)
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=50
					#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
					unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
						if Talent(subterfuge_talent) and Energy() >= 90 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 Spell(vanish)
						unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#pool_resource,for_next=1,extra_amount=90
							#shadowmeld,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
							unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
							{
								#marked_for_death,if=combo_points=0
								if ComboPoints() == 0 Spell(marked_for_death)
							}
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&(trinket.stat.agi.react|trinket.stat.multistrike.react|buff.archmages_greater_incandescence_agi.react)|((buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&target.time_to_die<136)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and target.TimeToDie() < 136 SubtletyUsePotionAgility()
	#kick
	SubtletyInterruptActions()
	#use_item,slot=trinket2,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) SubtletyUseItemActions()
	#shadow_reflection,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(shadow_reflection)
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60&buff.shadow_dance.up
	if Energy() < 60 and BuffPresent(shadow_dance_buff) Spell(arcane_torrent_energy)
	#pool_resource,for_next=1
	#garrote,if=time<1
	unless TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
		unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.remains<2|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
			unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffRemaining(find_weakness_debuff) < 2 or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=50
					#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
					if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 Spell(shadowmeld)
					unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
						unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#pool_resource,for_next=1,extra_amount=90
							#shadowmeld,if=talent.subterfuge.enabled&energy>=90&(combo_points<4|(talent.anticipation.enabled&combo_points+anticipation_charges<9))&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.remains<2
							if Talent(subterfuge_talent) and Energy() >= 90 and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 Spell(shadowmeld)
							unless Talent(subterfuge_talent) and True(pool_energy 90) and { ComboPoints() < 4 or Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 9 } and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffRemaining(find_weakness_debuff) < 2 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
							{
								#run_action_list,name=finisher,if=combo_points=5
								if ComboPoints() == 5 SubtletyFinisherCdActions()

								unless ComboPoints() == 5 and SubtletyFinisherCdPostConditions()
								{
									#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|(talent.anticipation.enabled&anticipation_charges<4)
									if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 SubtletyGeneratorCdActions()

									unless { ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and SubtletyGeneratorCdPostConditions()
									{
										#run_action_list,name=pool
										SubtletyPoolCdActions()
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

### actions.finisher

AddFunction SubtletyFinisherMainActions
{
	#rupture,cycle_targets=1,if=(!ticking|remains<duration*0.3)&active_enemies<=8&(!talent.shadow_reflection.enabled|(buff.shadow_reflection.remains>8&dot.rupture.remains<12&buff.shadow_reflection.remains<10))&target.time_to_die>=8
	if { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 8 and { not Talent(shadow_reflection_talent) or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and BuffRemaining(shadow_reflection_buff) < 10 } and target.TimeToDie() >= 8 Spell(rupture)
	#slice_and_dice,if=(buff.slice_and_dice.remains<10.8)&buff.slice_and_dice.remains<target.time_to_die
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() Spell(slice_and_dice)
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=(active_enemies>=2&debuff.find_weakness.down)|active_enemies>=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#eviscerate,if=(energy.time_to_max<=cooldown.death_from_above.remains+action.death_from_above.execute_time)|!talent.death_from_above.enabled
	if TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) Spell(eviscerate)
}

AddFunction SubtletyFinisherCdActions
{
	unless { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 8 and { not Talent(shadow_reflection_talent) or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and BuffRemaining(shadow_reflection_buff) < 10 } and target.TimeToDie() >= 8 and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or Spell(death_from_above) or { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or { TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) } and Spell(eviscerate)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

AddFunction SubtletyFinisherCdPostConditions
{
	{ not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 8 and { not Talent(shadow_reflection_talent) or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and BuffRemaining(shadow_reflection_buff) < 10 } and target.TimeToDie() >= 8 and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or Spell(death_from_above) or { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or { TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) } and Spell(eviscerate)
}

### actions.generator

AddFunction SubtletyGeneratorMainActions
{
	#pool_resource,for_next=1
	#ambush
	Spell(ambush)
	unless SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		#fan_of_knives,if=active_enemies>1
		if Enemies() > 1 Spell(fan_of_knives)
		#hemorrhage,if=(remains<duration*0.3&target.time_to_die>=remains+duration+8&debuff.find_weakness.down)|!ticking|position_front
		if target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) + 8 and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) Spell(hemorrhage)
		#shuriken_toss,if=energy<65&energy.regen<16
		if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
		#backstab
		Spell(backstab)
	}
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+set_bonus.tier17_2pc*50+cooldown.shadow_dance.remains*energy.regen<=energy.max|energy+15+cooldown.vanish.remains*energy.regen<=energy.max)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + ArmorSetBonus(T17 2) * 50 + SpellCooldown(shadow_dance) * EnergyRegenRate() <= MaxEnergy() or Energy() + 15 + SpellCooldown(vanish) * EnergyRegenRate() <= MaxEnergy() } SubtletyPoolCdActions()
	#pool_resource,for_next=1
	#ambush
	unless SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		unless Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) + 8 and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) } and Spell(hemorrhage) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or Spell(backstab)
		{
			#run_action_list,name=pool
			SubtletyPoolCdActions()
		}
	}
}

AddFunction SubtletyGeneratorCdPostConditions
{
	not { SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush) } and { Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) + 8 and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) } and Spell(hemorrhage) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or Spell(backstab) }
}

### actions.pool

AddFunction SubtletyPoolCdActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff any=1) and SpellCooldown(vanish) > 60 Spell(preparation)
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=calamari_crepes
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#premeditation,if=!talent.marked_for_death.enabled
	if not Talent(marked_for_death_talent) and ComboPoints() < 5 Spell(premeditation)
	#slice_and_dice,if=buff.slice_and_dice.remains<18
	if BuffRemaining(slice_and_dice_buff) < 18 Spell(slice_and_dice)
	#premeditation
	if ComboPoints() < 5 Spell(premeditation)
}

AddFunction SubtletyPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or BuffRemaining(slice_and_dice_buff) < 18 and Spell(slice_and_dice)
}

AddFunction SubtletyPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		SubtletyUsePotionAgility()
	}
}

AddFunction SubtletyPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or BuffRemaining(slice_and_dice_buff) < 18 and Spell(slice_and_dice)
}
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Assassination, Combat, Subtlety"
	local code = [[
# Ovale rogue script based on SimulationCraft.

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)
Include(ovale_rogue)

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe L(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
	if not InCombat() AssassinationPrecombatShortCdActions()
	unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
	{
		AssassinationDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
	if not InCombat() AssassinationPrecombatMainActions()
	AssassinationDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
	if not InCombat() AssassinationPrecombatCdActions()
	unless not InCombat() and AssassinationPrecombatCdPostConditions()
	{
		AssassinationDefaultCdActions()
	}
}

### Combat icons.

AddCheckBox(opt_rogue_combat_aoe L(AOE) default specialization=combat)

AddIcon checkbox=!opt_rogue_combat_aoe enemies=1 help=shortcd specialization=combat
{
	if not InCombat() CombatPrecombatShortCdActions()
	unless not InCombat() and CombatPrecombatShortCdPostConditions()
	{
		CombatDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_combat_aoe help=shortcd specialization=combat
{
	if not InCombat() CombatPrecombatShortCdActions()
	unless not InCombat() and CombatPrecombatShortCdPostConditions()
	{
		CombatDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=combat
{
	if not InCombat() CombatPrecombatMainActions()
	CombatDefaultMainActions()
}

AddIcon checkbox=opt_rogue_combat_aoe help=aoe specialization=combat
{
	if not InCombat() CombatPrecombatMainActions()
	CombatDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_combat_aoe enemies=1 help=cd specialization=combat
{
	if not InCombat() CombatPrecombatCdActions()
	unless not InCombat() and CombatPrecombatCdPostConditions()
	{
		CombatDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_combat_aoe help=cd specialization=combat
{
	if not InCombat() CombatPrecombatCdActions()
	unless not InCombat() and CombatPrecombatCdPostConditions()
	{
		CombatDefaultCdActions()
	}
}

### Subtlety icons.

AddCheckBox(opt_rogue_subtlety_aoe L(AOE) default specialization=subtlety)

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=shortcd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatShortCdActions()
	unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
	{
		SubtletyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=shortcd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatShortCdActions()
	unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
	{
		SubtletyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=subtlety
{
	if not InCombat() SubtletyPrecombatMainActions()
	SubtletyDefaultMainActions()
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=aoe specialization=subtlety
{
	if not InCombat() SubtletyPrecombatMainActions()
	SubtletyDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=cd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatCdActions()
	unless not InCombat() and SubtletyPrecombatCdPostConditions()
	{
		SubtletyDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=cd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatCdActions()
	unless not InCombat() and SubtletyPrecombatCdPostConditions()
	{
		SubtletyDefaultCdActions()
	}
}
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "script")
end
