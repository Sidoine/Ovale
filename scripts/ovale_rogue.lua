local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_rogue"
	local desc = "[6.0] Ovale: Assassination, Combat, Subtlety"
	local code = [[
# Ovale rogue script based on SimulationCraft.

Include(ovale_common)
Include(ovale_rogue_spells)

Define(honor_among_thieves_cooldown_buff 51699)
	SpellInfo(honor_among_thieves_cooldown_buff duration=2.2)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GetInMeleeRange
{
	if not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if target.Classification(worldboss no)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Assassination
###
# Based on SimulationCraft profile "Rogue_Assassination_T17M".
#	class=rogue
#	spec=assassination
#	talents=3000032
#	glyphs=vendetta/energy/disappearance

# ActionList: AssassinationDefaultActions --> main, shortcd, cd

AddFunction AssassinationDefaultActions
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
	#envenom,cycle_targets=1,if=(combo_points>4&buff.envenom.remains<2&(cooldown.death_from_above.remains>2|!talent.death_from_above.enabled))&active_enemies<4&!dot.deadly_poison_dot.ticking
	if ComboPoints() > 4 and BuffRemaining(envenom_buff) < 2 and { SpellCooldown(death_from_above) > 2 or not Talent(death_from_above_talent) } and Enemies() < 4 and not target.DebuffPresent(deadly_poison_dot_debuff) Spell(envenom)
	#envenom,if=(combo_points>4&buff.envenom.remains<2&(cooldown.death_from_above.remains>2|!talent.death_from_above.enabled))&active_enemies<4
	if ComboPoints() > 4 and BuffRemaining(envenom_buff) < 2 and { SpellCooldown(death_from_above) > 2 or not Talent(death_from_above_talent) } and Enemies() < 4 Spell(envenom)
	#fan_of_knives,cycle_targets=1,if=active_enemies>2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if Enemies() > 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(fan_of_knives)
	#mutilate,cycle_targets=1,if=target.health.pct>35&combo_points<5&active_enemies=2&!dot.deadly_poison_dot.ticking&debuff.vendetta.down
	if target.HealthPercent() > 35 and ComboPoints() < 5 and Enemies() == 2 and not target.DebuffPresent(deadly_poison_dot_debuff) and target.DebuffExpires(vendetta_debuff) Spell(mutilate)
	#mutilate,if=target.health.pct>35&combo_points<5&active_enemies<5
	if target.HealthPercent() > 35 and ComboPoints() < 5 and Enemies() < 5 Spell(mutilate)
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
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#vanish,if=time>10&!buff.stealth.up
	if TimeInCombat() > 10 and not BuffPresent(stealthed_buff any=1) Spell(vanish)

	unless ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
		or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture)
		or BuffPresent(stealthed_buff any=1) and Spell(mutilate)
		or BuffRemaining(slice_and_dice_buff) < 5 and Spell(slice_and_dice)
	{
		#marked_for_death,if=combo_points=0
		if ComboPoints() == 0 Spell(marked_for_death)
	}
}

AddFunction AssassinationDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|debuff.vendetta.up
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or target.DebuffPresent(vendetta_debuff) UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>30
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 30 Spell(preparation)
	#use_item,slot=trinket2,if=active_enemies>1|(debuff.vendetta.up&active_enemies=1)
	if Enemies() > 1 or target.DebuffPresent(vendetta_debuff) and Enemies() == 1 UseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
		or Enemies() > 1 and not target.DebuffPresent(rupture_debuff) and ComboPoints() == 5 and Spell(rupture)
		or BuffPresent(stealthed_buff any=1) Spell(mutilate)
		or BuffRemaining(slice_and_dice_buff) < 5 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) and Spell(slice_and_dice)
		or ComboPoints() > 4 and Enemies() >= 4 and target.DebuffRemaining(crimson_tempest_debuff) < 8 and Spell(crimson_tempest)
		or ComboPoints() < 5 and Enemies() >= 4 and Spell(fan_of_knives)
		or { target.DebuffRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.DebuffRemaining(rupture_debuff) <= SpellData(rupture_debuff duration) * 0.3 } and Enemies() == 1 and Spell(rupture)
	{
		#shadow_reflection,if=cooldown.vendetta.remains=0
		if not SpellCooldown(vendetta) > 0 Spell(shadow_reflection)
		#vendetta,if=buff.shadow_reflection.up|!talent.shadow_reflection.enabled
		if BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) Spell(vendetta)
	}
}

# ActionList: AssassinationPrecombatActions --> main, shortcd, cd

AddFunction AssassinationPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_surprise
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#potion,name=virmens_bite
	UsePotionAgility()
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(stealth)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions
{
	unless BuffExpires(stealthed_buff any=1) and Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction AssassinationPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#potion,name=draenic_agility
		UsePotionAgility()
	}
}

### Assassination icons.
AddCheckBox(opt_rogue_assassination_aoe L(AOE) specialization=assassination default)

AddIcon specialization=assassination help=shortcd enemies=1 checkbox=!opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatShortCdActions()
	AssassinationDefaultShortCdActions()
}

AddIcon specialization=assassination help=shortcd checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatShortCdActions()
	AssassinationDefaultShortCdActions()
}

AddIcon specialization=assassination help=main enemies=1
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon specialization=assassination help=aoe checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon specialization=assassination help=cd enemies=1 checkbox=!opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatCdActions()
	AssassinationDefaultCdActions()
}

AddIcon specialization=assassination help=cd checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatCdActions()
	AssassinationDefaultCdActions()
}

###
### Combat
###
# Based on SimulationCraft profile "Rogue_Combat_T17M".
#	class=rogue
#	spec=combat
#	talents=3111121
#	glyphs=energy/disappearance

# ActionList: CombatDefaultActions --> main, shortcd, cd

AddFunction CombatDefaultActions
{
	#ambush
	Spell(ambush)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|((target.time_to_die>45&combo_points=5&buff.slice_and_dice.remains<12)&buff.deep_insight.down)
	if BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) Spell(slice_and_dice)
	#call_action_list,name=generator,if=combo_points<5|!dot.revealing_strike.ticking|(talent.anticipation.enabled&anticipation_charges<=4&buff.deep_insight.down)
	if ComboPoints() < 5 or not target.DebuffPresent(revealing_strike_debuff) or Talent(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and BuffExpires(deep_insight_buff) CombatGeneratorActions()
	#call_action_list,name=finisher,if=combo_points=5&dot.revealing_strike.ticking&(buff.deep_insight.up|!talent.anticipation.enabled|(talent.anticipation.enabled&anticipation_charges>=4))
	if ComboPoints() == 5 and target.DebuffPresent(revealing_strike_debuff) and { BuffPresent(deep_insight_buff) or not Talent(anticipation_talent) or Talent(anticipation_talent) and BuffStacks(anticipation_buff) >= 4 } CombatFinisherActions()
}

AddFunction CombatDefaultShortCdActions
{
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) or Enemies() < 2 and BuffPresent(blade_flurry_buff) Spell(blade_flurry)

	unless Spell(ambush)
	{
		#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4)))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<90&energy>=15)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
		if TimeInCombat() > 10 and { ComboPoints() < 3 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and { Talent(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 90 and Energy() >= 15 or Talent(subterfuge_talent) and Energy() >= 90 or not Talent(shadow_focus_talent) and not Talent(subterfuge_talent) and Energy() >= 60 } Spell(vanish)

		unless BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) and Spell(slice_and_dice)
		{
			#marked_for_death,if=combo_points<=1&dot.revealing_strike.ticking&(!talent.shadow_reflection.enabled|buff.shadow_reflection.up|cooldown.shadow_reflection.remains>30)
			if ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) and { not Talent(shadow_reflection_talent) or BuffPresent(shadow_reflection_buff) or SpellCooldown(shadow_reflection) > 30 } Spell(marked_for_death)
		}
	}
}

AddFunction CombatDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.adrenaline_rush.up&(trinket.proc.any.react|trinket.stacking_proc.any.react|buff.archmages_greater_incandescence_agi.react))
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or BuffPresent(adrenaline_rush_buff) and { BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>30
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 30 Spell(preparation)
	#use_item,slot=trinket2
	UseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	#shadow_reflection,if=(cooldown.killing_spree.remains<10&combo_points>3)|buff.adrenaline_rush.up
	if SpellCooldown(killing_spree) < 10 and ComboPoints() > 3 or BuffPresent(adrenaline_rush_buff) Spell(shadow_reflection)

	unless Spell(ambush)
		or BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 12 and BuffExpires(deep_insight_buff) and Spell(slice_and_dice)
	{
		#call_action_list,name=adrenaline_rush,if=(energy<35|buff.bloodlust.up)&cooldown.killing_spree.remains>10
		if { Energy() < 35 or BuffPresent(burst_haste_buff any=1) } and SpellCooldown(killing_spree) > 10 CombatAdrenalineRushCdActions()
		#call_action_list,name=killing_spree,if=(energy<40|(buff.bloodlust.up&time<10)|buff.bloodlust.remains>20)&buff.adrenaline_rush.down&(!talent.shadow_reflection.enabled|cooldown.shadow_reflection.remains>30|buff.shadow_reflection.remains>3)
		if { Energy() < 40 or BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 10 or BuffRemaining(burst_haste_buff any=1) > 20 } and BuffExpires(adrenaline_rush_buff) and { not Talent(shadow_reflection_talent) or SpellCooldown(shadow_reflection) > 30 or BuffRemaining(shadow_reflection_buff) > 3 } CombatKillingSpreeCdActions()
	}
}

# ActionList: CombatAdrenalineRushActions --> cd

AddFunction CombatAdrenalineRushCdActions
{
	#adrenaline_rush,if=time_to_die>=44
	if TimeToDie() >= 44 Spell(adrenaline_rush)
	#adrenaline_rush,if=time_to_die<44&(buff.archmages_greater_incandescence_agi.react|trinket.proc.any.react|trinket.stacking_proc.any.react)
	if TimeToDie() < 44 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) } Spell(adrenaline_rush)
	#adrenaline_rush,if=time_to_die<=buff.adrenaline_rush.duration*1.5
	if TimeToDie() <= BaseDuration(adrenaline_rush_buff) * 1.5 Spell(adrenaline_rush)
}

# ActionList: CombatFinisherActions --> main

AddFunction CombatFinisherActions
{
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=active_enemies>6&remains<2
	if Enemies() > 6 and target.DebuffRemaining(crimson_tempest_debuff) < 2 Spell(crimson_tempest)
	#crimson_tempest,if=active_enemies>8
	if Enemies() > 8 Spell(crimson_tempest)
	Spell(eviscerate)
}

# ActionList: CombatGeneratorActions --> main

AddFunction CombatGeneratorActions
{
	#revealing_strike,if=(combo_points=4&dot.revealing_strike.remains<7.2&(target.time_to_die>dot.revealing_strike.remains+7.2)|(target.time_to_die<dot.revealing_strike.remains+7.2&ticks_remain<2))|!ticking
	if ComboPoints() == 4 and target.DebuffRemaining(revealing_strike_debuff) < 7.2 and target.TimeToDie() > target.DebuffRemaining(revealing_strike_debuff) + 7.2 or target.TimeToDie() < target.DebuffRemaining(revealing_strike_debuff) + 7.2 and target.TicksRemaining(revealing_strike_debuff) < 2 or not target.DebuffPresent(revealing_strike_debuff) Spell(revealing_strike)
	#sinister_strike,if=dot.revealing_strike.ticking
	if target.DebuffPresent(revealing_strike_debuff) Spell(sinister_strike)
}

# ActionList: CombatKillingSpreeActions --> cd

AddFunction CombatKillingSpreeCdActions
{
	#killing_spree,if=time_to_die>=44
	if TimeToDie() >= 44 Spell(killing_spree)
	#killing_spree,if=time_to_die<44&buff.archmages_greater_incandescence_agi.react&buff.archmages_greater_incandescence_agi.remains>=buff.killing_spree.duration
	if TimeToDie() < 44 and BuffPresent(archmages_greater_incandescence_agi_buff) and BuffRemaining(archmages_greater_incandescence_agi_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<44&trinket.proc.any.react&trinket.proc.any.remains>=buff.killing_spree.duration
	if TimeToDie() < 44 and BuffPresent(trinket_proc_any_buff) and BuffRemaining(trinket_proc_any_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<44&trinket.stacking_proc.any.react&trinket.stacking_proc.any.remains>=buff.killing_spree.duration
	if TimeToDie() < 44 and BuffPresent(trinket_stacking_proc_any_buff) and BuffRemaining(trinket_stacking_proc_any_buff) >= BaseDuration(killing_spree_buff) Spell(killing_spree)
	#killing_spree,if=time_to_die<=buff.killing_spree.duration*1.5
	if TimeToDie() <= BaseDuration(killing_spree_buff) * 1.5 Spell(killing_spree)
}

# ActionList: CombatPrecombatActions --> main, shortcd, cd

AddFunction CombatPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=frosty_stew
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#potion,name=draenic_agility
	UsePotionAgility()
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(stealth)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction CombatPrecombatShortCdActions
{
	unless BuffExpires(stealthed_buff any=1) and Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction CombatPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

### Combat icons.
AddCheckBox(opt_rogue_combat_aoe L(AOE) specialization=combat default)

AddIcon specialization=combat help=shortcd enemies=1 checkbox=!opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatShortCdActions()
	CombatDefaultShortCdActions()
}

AddIcon specialization=combat help=shortcd checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatShortCdActions()
	CombatDefaultShortCdActions()
}

AddIcon specialization=combat help=main enemies=1
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon specialization=combat help=aoe checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon specialization=combat help=cd enemies=1 checkbox=!opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatCdActions()
	CombatDefaultCdActions()
}

AddIcon specialization=combat help=cd checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatCdActions()
	CombatDefaultCdActions()
}

###
### Subtlety
###
# Based on SimulationCraft profile "Rogue_Subtlety_T17M".
#	class=rogue
#	spec=subtlety
#	talents=3111122
#	glyphs=energy/hemorrhaging_veins

# ActionList: SubtletyDefaultActions --> main, shortcd, cd

AddFunction SubtletyDefaultActions
{
	# CHANGE: Ovale doesn't do integer division so change the comparator for the "combo_points" condition to ">=".
	#slice_and_dice,if=buff.slice_and_dice.remains<10.8&buff.slice_and_dice.remains<target.time_to_die&combo_points=((target.time_to_die-buff.slice_and_dice.remains)%6)+1
	#if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() == { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 Spell(slice_and_dice)
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 Spell(slice_and_dice)
	#premeditation,if=combo_points<=4&!(buff.shadow_dance.up&energy>100&combo_points>1)&!buff.subterfuge.up|(buff.subterfuge.up&debuff.find_weakness.up)
	if ComboPoints() <= 4 and not { BuffPresent(shadow_dance_buff) and Energy() > 100 and ComboPoints() > 1 } and not BuffPresent(subterfuge_buff) or BuffPresent(subterfuge_buff) and target.DebuffPresent(find_weakness_debuff) Spell(premeditation)
	#pool_resource,for_next=1
	#garrote,if=!ticking&time<1
	if not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 Spell(garrote)
	unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		# CHANGE: Wait until 0.3s before Subterfuge expires.
		#wait,sec=1,if=buff.subterfuge.remains>1.1&buff.subterfuge.remains<1.3&time>6
		#unless BuffRemaining(subterfuge_buff) > 1.1 and BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and 1
		unless BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) > 0.3
		{
			#pool_resource,for_next=1
			#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)&(time<1.2|buff.shadow_dance.up|time>5)
			if ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } Spell(ambush)
			unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
			{
				#pool_resource,for_next=1,extra_amount=50
				#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
				unless { BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=50
					#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
					unless Talent(shadow_focus_talent) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
						unless Talent(subterfuge_talent) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
							if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorActions()
							#run_action_list,name=finisher,if=combo_points=5
							if ComboPoints() == 5 SubtletyFinisherActions()
							#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|talent.anticipation.enabled
							if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) SubtletyGeneratorActions()
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyDefaultShortCdActions
{
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	unless BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 and Spell(slice_and_dice)
		or { ComboPoints() <= 4 and not { BuffPresent(shadow_dance_buff) and Energy() > 100 and ComboPoints() > 1 } and not BuffPresent(subterfuge_buff) or BuffPresent(subterfuge_buff) and target.DebuffPresent(find_weakness_debuff) } and Spell(premeditation)
	{
		#pool_resource,for_next=1
		#garrote,if=!ticking&time<1
		unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
		{
			# CHANGE: Wait until 0.3s before Subterfuge expires.
			#wait,sec=1,if=buff.subterfuge.remains>1.1&buff.subterfuge.remains<1.3&time>6
			#unless BuffRemaining(subterfuge_buff) > 1.1 and BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and 1
			unless BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) > 0.3
			{
				#pool_resource,for_next=1
				#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)&(time<1.2|buff.shadow_dance.up|time>5)
				unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
				{
					#pool_resource,for_next=1,extra_amount=50
					#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
					if Energy() >= 50 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } Spell(shadow_dance)
					#Remove any 'Energy() >= 50' condition from the following statement.
					unless { BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=50
						#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
						if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
						unless Talent(shadow_focus_talent) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
						{
							#pool_resource,for_next=1,extra_amount=90
							#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
							if Talent(subterfuge_talent) and Energy() >= 90 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
							unless Talent(subterfuge_talent) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
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
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|buff.shadow_dance.up&(trinket.proc.agi.react|trinket.proc.multistrike.react|trinket.stacking_proc.agi.react|trinket.stacking_proc.multistrike.react|buff.archmages_greater_incandescence_agi.react)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or BuffPresent(shadow_dance_buff) and { BuffPresent(trinket_proc_agi_buff) or BuffPresent(trinket_proc_multistrike_buff) or BuffPresent(trinket_stacking_proc_agi_buff) or BuffPresent(trinket_stacking_proc_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } UsePotionAgility()
	#kick
	InterruptActions()
	#use_item,slot=trinket2,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#shadow_reflection,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(shadow_reflection)
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60&buff.shadow_dance.up
	if Energy() < 60 and BuffPresent(shadow_dance_buff) Spell(arcane_torrent_energy)

	unless BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 and Spell(slice_and_dice)
		or { ComboPoints() <= 4 and not { BuffPresent(shadow_dance_buff) and Energy() > 100 and ComboPoints() > 1 } and not BuffPresent(subterfuge_buff) or BuffPresent(subterfuge_buff) and target.DebuffPresent(find_weakness_debuff) } and Spell(premeditation)
	{
		#pool_resource,for_next=1
		#garrote,if=!ticking&time<1
		unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
		{
			# CHANGE: Wait until 0.3s before Subterfuge expires.
			#wait,sec=1,if=buff.subterfuge.remains>1.1&buff.subterfuge.remains<1.3&time>6
			#unless BuffRemaining(subterfuge_buff) > 1.1 and BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and 1
			unless BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) > 0.3
			{
				#pool_resource,for_next=1
				#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)&(time<1.2|buff.shadow_dance.up|time>5)
				unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
				{
					#pool_resource,for_next=1,extra_amount=50
					#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
					unless { BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=50
						#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
						unless Talent(shadow_focus_talent) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
						{
							#pool_resource,for_next=1,extra_amount=90
							#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
							unless Talent(subterfuge_talent) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
							{
								#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
								if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorCdActions()
								#run_action_list,name=finisher,if=combo_points=5
								if ComboPoints() == 5 SubtletyFinisherCdActions()
								#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|talent.anticipation.enabled
								if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) SubtletyGeneratorCdActions()
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

# ActionList: SubtletyFinisherActions --> main, cd

AddFunction SubtletyFinisherActions
{
	#rupture,cycle_targets=1,if=(!ticking|remains<duration*0.3)&active_enemies<=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(rupture)
	#slice_and_dice,if=buff.slice_and_dice.remains<10.8&buff.slice_and_dice.remains<target.time_to_die
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() Spell(slice_and_dice)
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=(active_enemies>=3&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() >= 3 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(eviscerate)
}

AddFunction SubtletyFinisherCdActions
{
	unless { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } and Spell(rupture)
		or BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice)
		or Spell(death_from_above)
		or Enemies() >= 3 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } and Spell(crimson_tempest)
		or Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } and Spell(eviscerate)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

# ActionList: SubtletyGeneratorActions --> main, cd

AddFunction SubtletyGeneratorActions
{
	#fan_of_knives,if=active_enemies>1
	if Enemies() > 1 Spell(fan_of_knives)
	#shuriken_toss,if=energy<65&energy.regen<16
	if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
	#hemorrhage,if=position_front
	if False(position_front) Spell(hemorrhage)
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegenRate() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegenRate() < 60 } SubtletyPoolCdActions()

	unless Enemies() > 1 and Spell(fan_of_knives)
		or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss)
		or Spell(backstab)
		or False(position_front) and Spell(hemorrhage)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

# ActionList: SubtletyPoolActions --> cd

AddFunction SubtletyPoolCdActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

# ActionList: SubtletyPrecombatActions --> main, shortcd, cd

AddFunction SubtletyPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=calamari_crepes
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(stealth)
	# CHANGE: Only cast Premeditation if it not at the combo point cap.
	#premeditation
	#Spell(premeditation)
	if ComboPoints() <= 4 Spell(premeditation)
	# CHANGE: Only refresh Slice and Dice out of combat if less than 18s remaining.
	#slice_and_dice
	#Spell(slice_and_dice)
	if BuffRemaining(slice_and_dice_buff) < 18 Spell(slice_and_dice)
	#honor_among_thieves,cooldown=2.2,cooldown_stddev=0.1
}

AddFunction SubtletyPrecombatShortCdActions {}

AddFunction SubtletyPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#potion,name=draenic_agility
		UsePotionAgility()
	}
}

### Subtlety icons.
AddCheckBox(opt_rogue_subtlety_aoe L(AOE) specialization=subtlety default)

AddIcon specialization=subtlety help=shortcd enemies=1 checkbox=!opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatShortCdActions()
	SubtletyDefaultShortCdActions()
}

AddIcon specialization=subtlety help=shortcd checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatShortCdActions()
	SubtletyDefaultShortCdActions()
}

AddIcon specialization=subtlety help=main enemies=1
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=aoe checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=cd enemies=1 checkbox=!opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatCdActions()
	SubtletyDefaultCdActions()
}

AddIcon specialization=subtlety help=cd checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatCdActions()
	SubtletyDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("ROGUE", "Ovale", desc, code, "script")
end
