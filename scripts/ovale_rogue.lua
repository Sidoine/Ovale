local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_rogue"
	local desc = "[6.0] Ovale: Assassination, Combat, Subtlety"
	local code = [[
# Ovale rogue script based on SimulationCraft.

Include(ovale_common)
Include(ovale_rogue_spells)

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
	#marked_for_death,if=combo_points=0
	if ComboPoints() == 0 Spell(marked_for_death)
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
}

AddFunction AssassinationDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
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
	#marked_for_death
	Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions {}

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
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(target.time_to_die>45&combo_points=5&buff.slice_and_dice.remains<10.8)
	if BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 10.8 Spell(slice_and_dice)
	#marked_for_death,if=combo_points<=1&dot.revealing_strike.ticking&(!talent.shadow_reflection.enabled|buff.shadow_reflection.up|cooldown.shadow_reflection.remains>30)
	if ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) and { not Talent(shadow_reflection_talent) or BuffPresent(shadow_reflection_buff) or SpellCooldown(shadow_reflection) > 30 } Spell(marked_for_death)
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
		#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4)))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
		if TimeInCombat() > 10 and { ComboPoints() < 3 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and { Talent(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 or Talent(subterfuge_talent) and Energy() >= 90 or not Talent(shadow_focus_talent) and not Talent(subterfuge_talent) and Energy() >= 60 } Spell(vanish)

		unless BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 10.8 and Spell(slice_and_dice)
		{
			#killing_spree,if=(energy<40|(buff.bloodlust.up&time<10)|buff.bloodlust.remains>20)&buff.adrenaline_rush.down&(!talent.shadow_reflection.enabled|cooldown.shadow_reflection.remains>30|buff.shadow_reflection.remains>3)
			if { Energy() < 40 or BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 10 or BuffRemaining(burst_haste_buff any=1) > 20 } and BuffExpires(adrenaline_rush_buff) and { not Talent(shadow_reflection_talent) or SpellCooldown(shadow_reflection) > 30 or BuffRemaining(shadow_reflection_buff) > 3 } Spell(killing_spree)
		}
	}
}

AddFunction CombatDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
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
		or BuffRemaining(slice_and_dice_buff) < 2 or target.TimeToDie() > 45 and ComboPoints() == 5 and BuffRemaining(slice_and_dice_buff) < 10.8 and Spell(slice_and_dice)
		or { Energy() < 40 or BuffPresent(burst_haste_buff any=1) and TimeInCombat() < 10 or BuffRemaining(burst_haste_buff any=1) > 20 } and BuffExpires(adrenaline_rush_buff) and { not Talent(shadow_reflection_talent) or SpellCooldown(shadow_reflection) > 30 or BuffRemaining(shadow_reflection_buff) > 3 } and Spell(killing_spree)
	{
		#adrenaline_rush,if=(energy<35|buff.bloodlust.up)&cooldown.killing_spree.remains>10
		if { Energy() < 35 or BuffPresent(burst_haste_buff any=1) } and SpellCooldown(killing_spree) > 10 Spell(adrenaline_rush)
	}
}

# ActionList: CombatFinisherActions --> main

AddFunction CombatFinisherActions
{
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=active_enemies>1&remains<4
	if Enemies() > 1 and target.DebuffRemaining(crimson_tempest_debuff) < 4 Spell(crimson_tempest)
	#crimson_tempest,if=active_enemies>2
	if Enemies() > 2 Spell(crimson_tempest)
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
	#marked_for_death
	Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction CombatPrecombatShortCdActions {}

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
#	talents=3111132
#	glyphs=energy/hemorrhaging_veins

# ActionList: SubtletyDefaultActions --> main, shortcd, cd

AddFunction SubtletyDefaultActions
{
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 Spell(premeditation)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() Spell(ambush)
	unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		#pool_resource,for_next=1,extra_amount=75
		#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
		unless BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(75)
		{
			#pool_resource,for_next=1,extra_amount=45
			#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			unless Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45)
			{
				#marked_for_death,if=combo_points=0
				if ComboPoints() == 0 Spell(marked_for_death)
				#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
				if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorActions()
				#run_action_list,name=finisher,if=combo_points=5
				if ComboPoints() == 5 SubtletyFinisherActions()
				#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
				if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorActions()
			}
		}
	}
}

AddFunction SubtletyDefaultShortCdActions
{
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	unless ComboPoints() <= 4 and Spell(premeditation)
	{
		#pool_resource,for_next=1
		#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
		unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
		{
			#pool_resource,for_next=1,extra_amount=75
			#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
			if Energy() >= 75 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) Spell(shadow_dance)
			unless BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(75)
			{
				#pool_resource,for_next=1,extra_amount=45
				#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
				if Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
			}
		}
	}
}

AddFunction SubtletyDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#use_item,slot=trinket2,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless ComboPoints() <= 4 and Spell(premeditation)
	{
		#pool_resource,for_next=1
		#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
		unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
		{
			#pool_resource,for_next=1,extra_amount=75
			#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
			unless BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(75)
			{
				#pool_resource,for_next=1,extra_amount=45
				#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
				unless Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45)
				{
					#shadow_reflection,if=buff.shadow_dance.up
					if BuffPresent(shadow_dance_buff) Spell(shadow_reflection)
					#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
					if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorCdActions()
					#run_action_list,name=finisher,if=combo_points=5
					if ComboPoints() == 5 SubtletyFinisherCdActions()
					#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
					if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorCdActions()
					#run_action_list,name=pool
					SubtletyPoolActions()
				}
			}
		}
	}
}

# ActionList: SubtletyFinisherActions --> main, cd

AddFunction SubtletyFinisherActions
{
	#slice_and_dice,if=buff.slice_and_dice.remains<4
	if BuffRemaining(slice_and_dice_buff) < 4 and BuffRemaining(slice_and_dice_buff) < 0.3 * BaseDuration(slice_and_dice_buff) Spell(slice_and_dice)
	#death_from_above
	Spell(death_from_above)
	#rupture,cycle_targets=1,if=(!ticking|remains<duration*0.3)&active_enemies<=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(rupture)
	#crimson_tempest,if=(active_enemies>3&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(eviscerate)
}

AddFunction SubtletyFinisherCdActions
{
	unless BuffRemaining(slice_and_dice_buff) < 4 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) and Spell(slice_and_dice)
		or Spell(death_from_above)
		or { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < target.DebuffDurationIfApplied(rupture_debuff) * 0.3 } and Enemies() <= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } and Spell(rupture)
		or { Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest)
		or { Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(eviscerate)
	{
		#run_action_list,name=pool
		SubtletyPoolActions()
	}
}

# ActionList: SubtletyGeneratorActions --> main, cd

AddFunction SubtletyGeneratorActions
{
	#fan_of_knives,if=active_enemies>1
	if Enemies() > 1 Spell(fan_of_knives)
	#hemorrhage,if=(remains<8&target.time_to_die>10)|position_front
	if target.DebuffRemaining(hemorrhage_debuff) < 8 and target.TimeToDie() > 10 or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=energy<65&energy.regen<16
	if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegenRate() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegenRate() < 60 } SubtletyPoolActions()

	unless Enemies() > 1 and Spell(fan_of_knives)
		or { target.DebuffRemaining(hemorrhage_debuff) < 8 and target.TimeToDie() > 10 or False(position_front) } and Spell(hemorrhage)
		or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss)
		or Spell(backstab)
	{
		#run_action_list,name=pool
		SubtletyPoolActions()
	}
}

# ActionList: SubtletyPoolActions --> cd

AddFunction SubtletyPoolActions
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
	#premeditation
	Spell(premeditation)
	#slice_and_dice
	if BuffRemaining(slice_and_dice_buff) < 0.3 * BaseDuration(slice_and_dice_buff) Spell(slice_and_dice)
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
