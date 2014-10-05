local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_rogue"
	local desc = "[5.4.8] Ovale: Assassination, Combat, Subtlety"
	local code = [[
# Ovale rogue script based on SimulationCraft.

Include(ovale_common)
Include(ovale_rogue_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_tricks_of_the_trade SpellName(tricks_of_the_trade) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if target.Classification(worldboss no)
		{
			if target.InRange(kidney_shot) Spell(kidney_shot)
			if target.InRange(cheap_shot) and BuffPresent(stealthed_buff any=1) Spell(cheap_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddFunction Stealth
{
	if Talent(subterfuge_talent) Spell(stealth_subterfuge)
	if Talent(subterfuge_talent no) Spell(stealth)
}

###
### Assassination
###
# Based on SimulationCraft profile "Rogue_Assassination_T16H".
#	class=rogue
#	spec=assassination
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ca!200002
#	glyphs=vendetta

# ActionList: AssassinationPrecombatActions --> main, shortcd, cd

AddFunction AssassinationPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#stealth
	if BuffExpires(stealthed_buff any=1) Stealth()
	#marked_for_death,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions {}

AddFunction AssassinationPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#virmens_bite_potion
		UsePotionAgility()
	}
}

# ActionList: AssassinationDefaultActions --> main, shortcd, cd

AddFunction AssassinationDefaultActions
{
	#auto_attack
	#mutilate,if=buff.stealth.up
	if BuffPresent(stealthed_buff any=1) Spell(mutilate)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemaining(slice_and_dice_buff) < 2 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#dispatch,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 and { target.HealthPercent() < 35 or BuffPresent(blindside_buff) } Spell(dispatch)
	#mutilate,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 Spell(mutilate)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if Talent(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	# CHANGE: Only Rupture if the target will still be alive for at least half of the ticks.
	#rupture,if=ticks_remain<2|(combo_points=5&ticks_remain<3)
	#if target.TicksRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
	if { target.TicksRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 } and target.TimeToDie() > DebuffDurationIfApplied(rupture) / 2 Spell(rupture)
	#fan_of_knives,if=combo_points<5&active_enemies>=4
	if ComboPoints() < 5 and Enemies() >= 4 Spell(fan_of_knives)
	# CHANGE: Always pool energy for Envenom.
	#envenom,if=combo_points>4
	#envenom,if=combo_points>=2&buff.slice_and_dice.remains<3
	#dispatch,if=combo_points<5
	#mutilate
	# Always use Envenom to refresh Slice and Dice if Slice and Dice is on its last tick.
	if ComboPoints() >= 1 and BuffRemaining(slice_and_dice_buff) < 3 Spell(envenom)
	# Pool energy for 4CP+ Envenom to prevent clipping the previous Envenom buff unless we will cap on energy.
	if Talent(anticipation_talent) and ComboPoints() > 4 or not Talent(anticipation_talent) and ComboPoints() >= 4
	{
		if BuffRemaining(envenom_buff) < 1 or TimeToMaxEnergy() < 1 Spell(envenom)
	}
	# Combo point builders.
	unless Talent(anticipation_talent) and ComboPoints() > 4 or not Talent(anticipation_talent) and ComboPoints() >= 4
	{
		if target.HealthPercent() < 35 or BuffPresent(blindside_buff) Spell(dispatch)
		Spell(mutilate)
	}
}

AddFunction AssassinationDefaultShortCdActions
{
	# CHANGE: Display Shadowstep or "up arrow" texture if not in melee range of target.
	if not target.InRange(kick)
	{
		if Talent(shadowstep_talent) Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}

	# CHANGE: Use Tricks of the Trade on cooldown.
	if CheckBoxOn(opt_tricks_of_the_trade) and Glyph(glyph_of_tricks_of_the_trade no) Spell(tricks_of_the_trade)
	#vanish,if=time>10&!buff.stealth.up&!buff.shadow_blades.up
	if TimeInCombat() > 10 and not BuffPresent(stealthed_buff any=1) and not BuffPresent(shadow_blades_buff) Spell(vanish)
}

AddFunction AssassinationDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands
	UseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless BuffPresent(stealthed_buff any=1) and Spell(mutilate)
	{
		#shadow_blades,if=buff.bloodlust.react|time>60
		# CHANGE: Don't wait till one minute after combat begins to cast Shadow Blades.
		#         Instead, wait only 6 seconds so that Slice and Dice and Rupture have
		#         a chance to be applied first.
		#if BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 60 Spell(shadow_blades)
		if BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 6 Spell(shadow_blades)

		unless BuffRemaining(slice_and_dice_buff) < 2 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) and Spell(slice_and_dice)
			or target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 and { target.HealthPercent() < 35 or BuffPresent(blindside_buff) } and Spell(dispatch)
			or target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 and Spell(mutilate)
			or target.TicksRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 and Spell(rupture)
			or ComboPoints() < 5 and Enemies() >= 4 and Spell(fan_of_knives)
		{
			#vendetta
			Spell(vendetta)
		}
	}
}

### Assassination icons.
AddCheckBox(opt_rogue_assassination "Show Assassination icons" specialization=assassination default)
AddCheckBox(opt_rogue_assassination_aoe L(AOE) specialization=assassination default)

AddIcon specialization=assassination help=shortcd enemies=1 checkbox=opt_rogue_assassination checkbox=!opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatShortCdActions()
	AssassinationDefaultShortCdActions()
}

AddIcon specialization=assassination help=shortcd checkbox=opt_rogue_assassination checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatShortCdActions()
	AssassinationDefaultShortCdActions()
}

AddIcon specialization=assassination help=main enemies=1 checkbox=opt_rogue_assassination
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon specialization=assassination help=aoe checkbox=opt_rogue_assassination checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon specialization=assassination help=cd enemies=1 checkbox=opt_rogue_assassination checkbox=!opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatCdActions()
	AssassinationDefaultCdActions()
}

AddIcon specialization=assassination help=cd checkbox=opt_rogue_assassination checkbox=opt_rogue_assassination_aoe
{
	if InCombat(no) AssassinationPrecombatCdActions()
	AssassinationDefaultCdActions()
}

###
### Combat
###
# Based on SimulationCraft profile "Rogue_Combat_T16H".
#	class=rogue
#	spec=combat
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cZ!200002

# ActionList: CombatPrecombatActions --> main, shortcd, cd

AddFunction CombatPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#stealth
	if BuffExpires(stealthed_buff any=1) Stealth()
	#marked_for_death,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction CombatPrecombatShortCdActions {}

AddFunction CombatPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#virmens_bite_potion
		UsePotionAgility()
	}
}

# ActionList: CombatDefaultActions --> main, shortcd, cd

AddFunction CombatDefaultActions
{
	#auto_attack
	#ambush
	if BuffPresent(stealthed_buff any=1) Spell(ambush)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	if { BuffRemaining(slice_and_dice_buff) < 2 or BuffRemaining(slice_and_dice_buff) < 15 and BuffStacks(bandits_guile_buff) == 11 and ComboPoints() >= 4 } and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#marked_for_death,if=talent.marked_for_death.enabled&(combo_points<=1&dot.revealing_strike.ticking)
	if Talent(marked_for_death_talent) and ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) Spell(marked_for_death)
	#run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
	if ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and not target.DebuffPresent(revealing_strike_debuff) CombatGeneratorActions()
	#run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
	if Talent(anticipation_talent no) or BuffPresent(deep_insight_buff) or SpellCooldown(shadow_blades) <= 11 or BuffStacks(anticipation_buff) >= 4 or BuffPresent(shadow_blades_buff) and BuffStacks(anticipation_buff) >= 3 CombatFinisherActions()
	#run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points
	if Energy() > 60 or BuffExpires(deep_insight_buff) or BuffRemaining(deep_insight_buff) > 5 - ComboPoints() CombatGeneratorActions()
}

AddFunction CombatDefaultShortCdActions
{
	# CHANGE: Display Shadowstep or "up arrow" texture if not in melee range of target.
	if not target.InRange(kick)
	{
		if Talent(shadowstep_talent) Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}

	# CHANGE: Use Tricks of the Trade on cooldown.
	if CheckBoxOn(opt_tricks_of_the_trade) and Glyph(glyph_of_tricks_of_the_trade no) Spell(tricks_of_the_trade)
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) or Enemies() < 2 and BuffPresent(blade_flurry_buff) Spell(blade_flurry)

	unless BuffPresent(stealthed_buff any=1) and Spell(ambush)
	{
		#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(buff.shadow_blades.down&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4))))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
		if TimeInCombat() > 10 and { ComboPoints() < 3 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffExpires(shadow_blades_buff) and { ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } } and { Talent(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 or Talent(subterfuge_talent) and Energy() >= 90 or Talent(shadow_focus_talent no) and Talent(subterfuge_talent no) and Energy() >= 60 } Spell(vanish)
		#killing_spree,if=energy<50
		if Energy() < 50 Spell(killing_spree)
	}
}

AddFunction CombatDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) UseItemActions()
	#blood_fury,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(blood_fury_ap)
	#berserking,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)

	unless BuffPresent(stealthed_buff any=1) and Spell(ambush)
		or Energy() < 50 and Spell(killing_spree)
	{
		#shadow_blades,if=time>5
		if TimeInCombat() > 5 Spell(shadow_blades)
		#adrenaline_rush,if=energy<35|buff.shadow_blades.up
		if Energy() < 35 or BuffPresent(shadow_blades_buff) Spell(adrenaline_rush)
	}
}

# ActionList: CombatGeneratorActions --> main

AddFunction CombatGeneratorActions
{
	#fan_of_knives,line_cd=5,if=active_enemies>=4
	if Enemies() >= 4 and TimeSincePreviousSpell(fan_of_knives) > 5 Spell(fan_of_knives)
	#revealing_strike,if=ticks_remain<2
	if target.TicksRemaining(revealing_strike_debuff) < 2 Spell(revealing_strike)
	#sinister_strike
	Spell(sinister_strike)
}

# ActionList: CombatFinisherActions --> main

AddFunction CombatFinisherActions
{
	#rupture,if=ticks_remain<2&target.time_to_die>=26&(active_enemies<2|!buff.blade_flurry.up)
	if target.TicksRemaining(rupture_debuff) < 2 and target.TimeToDie() >= 26 and { Enemies() < 2 or not BuffPresent(blade_flurry_buff) } Spell(rupture)
	#crimson_tempest,if=active_enemies>=7&dot.crimson_tempest_dot.ticks_remain<=2
	if Enemies() >= 7 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 Spell(crimson_tempest)
	#eviscerate
	Spell(eviscerate)
}

### Combat icons.
AddCheckBox(opt_rogue_combat "Show Combat icons" specialization=combat default)
AddCheckBox(opt_rogue_combat_aoe L(AOE) specialization=combat default)

AddIcon specialization=combat help=shortcd enemies=1 checkbox=opt_rogue_combat checkbox=!opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatShortCdActions()
	CombatDefaultShortCdActions()
}

AddIcon specialization=combat help=shortcd checkbox=opt_rogue_combat checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatShortCdActions()
	CombatDefaultShortCdActions()
}

AddIcon specialization=combat help=main enemies=1 checkbox=opt_rogue_combat
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon specialization=combat help=aoe checkbox=opt_rogue_combat checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon specialization=combat help=cd enemies=1 checkbox=opt_rogue_combat checkbox=!opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatCdActions()
	CombatDefaultCdActions()
}

AddIcon specialization=combat help=cd checkbox=opt_rogue_combat checkbox=opt_rogue_combat_aoe
{
	if InCombat(no) CombatPrecombatCdActions()
	CombatDefaultCdActions()
}

###
### Subtlety
###
# Based on SimulationCraft profile "Rogue_Subtlety_T16H".
#	class=rogue
#	spec=subtlety
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cb!200002

# ActionList: SubtletyPrecombatActions --> main, shortcd, cd

AddFunction SubtletyPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#stealth
	if BuffExpires(stealthed_buff any=1) Stealth()
	#premeditation
	if BuffPresent(stealthed_buff any=1) Spell(premeditation)
	#slice_and_dice
	if BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction SubtletyPrecombatShortCdActions {}

AddFunction SubtletyPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#virmens_bite_potion
		UsePotionAgility()
	}
}

# ActionList: SubtletyPoolActions --> main, shortcd, cd

AddFunction SubtletyPoolActions {}

AddFunction SubtletyPoolShortCdActions {}

AddFunction SubtletyPoolCdActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

# ActionList: SubtletyDefaultActions --> main, shortcd, cd

AddFunction SubtletyDefaultActions
{
	#auto_attack
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 and BuffPresent(stealthed_buff any=1) Spell(premeditation)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } Spell(ambush)
	unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } and not SpellCooldown(ambush) > 0
	{
		#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
		if Talent(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
		#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
		if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorActions()
		#run_action_list,name=finisher,if=combo_points=5
		if ComboPoints() == 5 SubtletyFinisherActions()
		#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
		if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorActions()
		#run_action_list,name=pool
		SubtletyPoolActions()
	}
}

AddFunction SubtletyDefaultShortCdActions
{
	# CHANGE: Display Shadowstep or "up arrow" texture if not in melee range of target.
	if not target.InRange(kick)
	{
		if Talent(shadowstep_talent) Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}

	# CHANGE: Use Tricks of the Trade on cooldown.
	if CheckBoxOn(opt_tricks_of_the_trade) and Glyph(glyph_of_tricks_of_the_trade no) Spell(tricks_of_the_trade)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } and not SpellCooldown(ambush) > 0
	{
		#pool_resource,for_next=1,extra_amount=75
		#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
		if Energy() >= 75 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) Spell(shadow_dance)
		unless BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(shadow_dance) > 0
		{
			#pool_resource,for_next=1,extra_amount=45
			#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			if Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
			unless Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(vanish) > 0
			{
				unless Talent(marked_for_death_talent) and ComboPoints() == 0 and Spell(marked_for_death)
				{
					#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
					if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorShortCdActions()
					#run_action_list,name=finisher,if=combo_points=5
					if ComboPoints() == 5 SubtletyFinisherShortCdActions()
					#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
					if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorShortCdActions()
					#run_action_list,name=pool
					SubtletyPoolShortCdActions()
				}
			}
		}
	}
}

AddFunction SubtletyDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#use_item,slot=hands,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#shadow_blades
	Spell(shadow_blades)

	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } and not SpellCooldown(ambush) > 0
	{
		#pool_resource,for_next=1,extra_amount=75
		#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
		unless BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(shadow_dance) > 0
		{
			#pool_resource,for_next=1,extra_amount=45
			#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			unless Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(vanish) > 0
			{
				#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
				if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorCdActions()
				#run_action_list,name=finisher,if=combo_points=5
				if ComboPoints() == 5 SubtletyFinisherCdActions()
				#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
				if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorCdActions()
				#run_action_list,name=pool
				SubtletyPoolCdActions()
			}
		}
	}
}

# ActionList: SubtletyGeneratorActions --> main, shortcd, cd

AddFunction SubtletyGeneratorActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolActions()
	#fan_of_knives,if=active_enemies>=4
	if Enemies() >= 4 Spell(fan_of_knives)
	#hemorrhage,if=remains<3|position_front
	if target.DebuffRemaining(hemorrhage_debuff) < 3 or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=talent.shuriken_toss.enabled&(energy<65&energy.regen<16)
	if Talent(shuriken_toss_talent) and Energy() < 65 and EnergyRegen() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyGeneratorShortCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolShortCdActions()

	unless Enemies() >= 4 and Spell(fan_of_knives)
		or { target.DebuffRemaining(hemorrhage_debuff) < 3 or False(position_front) } and Spell(hemorrhage)
		or Talent(shuriken_toss_talent) and Energy() < 65 and EnergyRegen() < 16 and Spell(shuriken_toss)
		or Spell(backstab)
	{
		#run_action_list,name=pool
		SubtletyPoolShortCdActions()
	}
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolCdActions()

	unless Enemies() >= 4 and Spell(fan_of_knives)
		or { target.DebuffRemaining(hemorrhage_debuff) < 3 or False(position_front) } and Spell(hemorrhage)
		or Talent(shuriken_toss_talent) and Energy() < 65 and EnergyRegen() < 16 and Spell(shuriken_toss)
		or Spell(backstab)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

# ActionList: SubtletyFinisherActions --> main, shortcd, cd

AddFunction SubtletyFinisherActions
{
	#slice_and_dice,if=buff.slice_and_dice.remains<4
	if BuffRemaining(slice_and_dice_buff) < 4 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#rupture,if=ticks_remain<2&active_enemies<3
	if target.TicksRemaining(rupture_debuff) < 2 and Enemies() < 3 Spell(rupture)
	#crimson_tempest,if=(active_enemies>1&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5
	if Enemies() > 1 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)
	if Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 Spell(eviscerate)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyFinisherShortCdActions
{
	unless BuffRemaining(slice_and_dice_buff) < 4 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) and Spell(slice_and_dice)
		or target.TicksRemaining(rupture_debuff) < 2 and Enemies() < 3 and Spell(rupture)
		or { Enemies() > 1 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 } and Spell(crimson_tempest)
		or Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and Spell(eviscerate)
	{
		#run_action_list,name=pool
		SubtletyPoolShortCdActions()
	}
}

AddFunction SubtletyFinisherCdActions
{
	unless BuffRemaining(slice_and_dice_buff) < 4 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) and Spell(slice_and_dice)
		or target.TicksRemaining(rupture_debuff) < 2 and Enemies() < 3 and Spell(rupture)
		or { Enemies() > 1 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 } and Spell(crimson_tempest)
		or Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and Spell(eviscerate)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

### Subtlety icons.
AddCheckBox(opt_rogue_subtlety "Show Subtlety icons" specialization=subtlety default)
AddCheckBox(opt_rogue_subtlety_aoe L(AOE) specialization=subtlety default)

AddIcon specialization=subtlety help=shortcd enemies=1 checkbox=opt_rogue_subtlety checkbox=!opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatShortCdActions()
	SubtletyDefaultShortCdActions()
}

AddIcon specialization=subtlety help=shortcd checkbox=opt_rogue_subtlety checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatShortCdActions()
	SubtletyDefaultShortCdActions()
}

AddIcon specialization=subtlety help=main enemies=1 checkbox=opt_rogue_subtlety
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=aoe checkbox=opt_rogue_subtlety checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=cd enemies=1 checkbox=opt_rogue_subtlety checkbox=!opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatCdActions()
	SubtletyDefaultCdActions()
}

AddIcon specialization=subtlety help=cd checkbox=opt_rogue_subtlety checkbox=opt_rogue_subtlety_aoe
{
	if InCombat(no) SubtletyPrecombatCdActions()
	SubtletyDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("ROGUE", "Ovale", desc, code, "script")
end
