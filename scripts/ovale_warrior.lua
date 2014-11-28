local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warrior"
	local desc = "[6.0] Ovale: Arms, Fury, Protection"
	local code = [[
# Ovale warrior script based on SimulationCraft.

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=protection)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=arms)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=fury)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction GetInMeleeRange
{
	if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(pummel) Spell(pummel)
		if Glyph(glyph_of_gag_order) and target.InRange(heroic_throw) Spell(heroic_throw)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_rage)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

###
### Arms
###
# Based on SimulationCraft profile "Warrior_Arms_T17M".
#	class=warrior
#	spec=arms
#	talents=1321322
#	glyphs=unending_rage/heroic_leap/sweeping_strikes

# ActionList: ArmsDefaultActions --> main, shortcd, cd

AddFunction ArmsDefaultActions
{
	#auto_attack
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ArmsAoeActions()
}

AddFunction ArmsDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ArmsAoeShortCdActions()
}

AddFunction ArmsDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() < 25 UsePotionStrength()
	#recklessness,if=(dot.rend.ticking&(target.time_to_die>190|target.health.pct<20)&(!talent.bloodbath.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)|buff.bloodbath.up))|target.time_to_die<10
	if target.DebuffPresent(rend_debuff) and { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { not Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } or BuffPresent(bloodbath_buff) } or target.TimeToDie() < 10 Spell(recklessness)
	#bloodbath,if=(dot.rend.ticking&cooldown.colossus_smash.remains<5)|target.time_to_die<20
	if target.DebuffPresent(rend_debuff) and SpellCooldown(colossus_smash) < 5 or target.TimeToDie() < 20 Spell(bloodbath)
	#avatar,if=buff.recklessness.up|target.time_to_die<25
	if BuffPresent(recklessness_buff) or target.TimeToDie() < 25 Spell(avatar)
	#blood_fury,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleCdActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ArmsAoeCdActions()
}

# ActionList: ArmsAoeActions --> main, shortcd, cd

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#rend,if=ticks_remain<2&target.time_to_die>4
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 Spell(rend)
	#colossus_smash,if=dot.rend.ticking
	if target.DebuffPresent(rend_debuff) Spell(colossus_smash)
	#mortal_strike,if=cooldown.colossus_smash.remains>1.5&target.health.pct>20&active_enemies=2
	if SpellCooldown(colossus_smash) > 1.5 and target.HealthPercent() > 20 and Enemies() == 2 Spell(mortal_strike)
	#execute,if=((rage>60|active_enemies=2)&cooldown.colossus_smash.remains>execute_time)|debuff.colossus_smash.up|target.time_to_die<5
	if { Rage() > 60 or Enemies() == 2 } and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 Spell(execute_arms)
	#whirlwind,if=cooldown.colossus_smash.remains>1.5&(target.health.pct>20|active_enemies>3)
	if SpellCooldown(colossus_smash) > 1.5 and { target.HealthPercent() > 20 or Enemies() > 3 } Spell(whirlwind)
	#rend,cycle_targets=1,if=!ticking&target.time_to_die>8
	if not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 8 Spell(rend)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute_arms)
}

AddFunction ArmsAoeShortCdActions
{
	unless target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 and Spell(rend)
	{
		#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
		#bladestorm,if=active_enemies>5
		if Enemies() > 5 Spell(bladestorm)

		unless target.DebuffPresent(rend_debuff) and Spell(colossus_smash)
			or SpellCooldown(colossus_smash) > 1.5 and target.HealthPercent() > 20 and Enemies() == 2 and Spell(mortal_strike)
			or { { Rage() > 60 or Enemies() == 2 } and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 } and Spell(execute_arms)
		{
			#dragon_roar,if=cooldown.colossus_smash.remains>1.5&!debuff.colossus_smash.up
			if SpellCooldown(colossus_smash) > 1.5 and not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)

			unless SpellCooldown(colossus_smash) > 1.5 and { target.HealthPercent() > 20 or Enemies() > 3 } and Spell(whirlwind)
				or not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 8 and Spell(rend)
			{
				#bladestorm,if=cooldown.colossus_smash.remains>6&(!talent.ravager.enabled|cooldown.ravager.remains>6)
				if SpellCooldown(colossus_smash) > 6 and { not Talent(ravager_talent) or SpellCooldown(ravager) > 6 } Spell(bladestorm)
				#siegebreaker
				Spell(siegebreaker)
				#storm_bolt,if=cooldown.colossus_smash.remains>4|debuff.colossus_smash.up
				if SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
				#shockwave
				Spell(shockwave)
			}
		}
	}
}

AddFunction ArmsAoeCdActions {}

# ActionList: ArmsPrecombatActions --> main, shortcd, cd

AddFunction ArmsPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#stance,choose=battle
	Spell(battle_stance)
	# CHANGE: Apply raid buffs.
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	if not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) Spell(commanding_shout)
	#snapshot_stats
}

AddFunction ArmsPrecombatShortCdActions {}

AddFunction ArmsPrecombatCdActions
{
	unless Spell(battle_stance)
		or not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) and Spell(commanding_shout)
		or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout)
	{
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

# ActionList: ArmsSingleActions --> main, shortcd, cd

AddFunction ArmsSingleActions
{
	#rend,if=!ticking&target.time_to_die>4
	if not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 4 Spell(rend)
	#colossus_smash
	Spell(colossus_smash)
	#mortal_strike,if=target.health.pct>20&cooldown.colossus_smash.remains>1
	if target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 Spell(mortal_strike)
	#rend,if=!debuff.colossus_smash.up&target.time_to_die>4&remains<5.4
	if not target.DebuffPresent(colossus_smash_debuff) and target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 Spell(rend)
	#execute,if=(rage>=60&cooldown.colossus_smash.remains>execute_time)|debuff.colossus_smash.up|buff.sudden_death.react|target.time_to_die<5
	if Rage() >= 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_buff) or target.TimeToDie() < 5 Spell(execute_arms)
	#impending_victory,if=rage<40&target.health.pct>20&cooldown.colossus_smash.remains>1&cooldown.mortal_strike.remains>1
	if Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 Spell(impending_victory)
	#slam,if=(rage>20|cooldown.colossus_smash.remains>execute_time)&target.health.pct>20&cooldown.colossus_smash.remains>1&cooldown.mortal_strike.remains>1
	if { Rage() > 20 or SpellCooldown(colossus_smash) > ExecuteTime(slam) } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 Spell(slam)
	#whirlwind,if=!talent.slam.enabled&target.health.pct>20&(rage>=40|set_bonus.tier17_4pc|debuff.colossus_smash.up)&cooldown.colossus_smash.remains>1&cooldown.mortal_strike.remains>1
	if not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or ArmorSetBonus(T17 4) or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 Spell(whirlwind)
}

AddFunction ArmsSingleShortCdActions
{
	unless not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 4 and Spell(rend)
	{
		#ravager,if=cooldown.colossus_smash.remains<4
		if SpellCooldown(colossus_smash) < 4 Spell(ravager)

		unless Spell(colossus_smash)
			or target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(mortal_strike)
		{
			#storm_bolt,if=(cooldown.colossus_smash.remains>4|debuff.colossus_smash.up)&rage<90
			if { SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) } and Rage() < 90 Spell(storm_bolt)
			#siegebreaker
			Spell(siegebreaker)
			#dragon_roar,if=!debuff.colossus_smash.up
			if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)

			unless not target.DebuffPresent(colossus_smash_debuff) and target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 Spell(rend)
				or { Rage() >= 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_buff) or target.TimeToDie() < 5 } and Spell(execute_arms)
				or Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(impending_victory)
				or { Rage() > 20 or SpellCooldown(colossus_smash) > ExecuteTime(slam) } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(slam)
				or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or ArmorSetBonus(T17 4) or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(whirlwind)
			{
				#shockwave
				Spell(shockwave)
			}
		}
	}
}

AddFunction ArmsSingleCdActions {}

### Arms icons.
AddCheckBox(opt_warrior_arms_aoe L(AOE) specialization=arms default)

AddIcon specialization=arms help=shortcd enemies=1 checkbox=!opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatShortCdActions()
	ArmsDefaultShortCdActions()
}

AddIcon specialization=arms help=shortcd checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatShortCdActions()
	ArmsDefaultShortCdActions()
}

AddIcon specialization=arms help=main enemies=1
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=aoe checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=cd enemies=1 checkbox=!opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatCdActions()
	ArmsDefaultCdActions()
}

AddIcon specialization=arms help=cd checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatCdActions()
	ArmsDefaultCdActions()
}

###
### Fury (Single-Minded Fury)
###
# Based on SimulationCraft profile "Warrior_Fury_1h_T17M".
#	class=warrior
#	spec=fury
#	talents=1321321
#	glyphs=unending_rage/raging_wind/heroic_leap

# ActionList: FurySingleMindedFuryDefaultActions --> main, shortcd, cd

AddFunction FurySingleMindedFuryDefaultActions
{
	#auto_attack
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeActions()
}

AddFunction FurySingleMindedFuryDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#berserker_rage,if=buff.enrage.down|(talent.unquenchable_thirst.enabled&buff.raging_blow.down)
	if BuffExpires(enrage_buff any=1) or Talent(unquenchable_thirst_talent) and BuffExpires(raging_blow_buff) Spell(berserker_rage)
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetShortCdActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsShortCdActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeShortCdActions()
}

AddFunction FurySingleMindedFuryDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>3&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 3 and Enemies() == 1 or 600 < 5 FurySingleMindedFurySingleTargetCdActions()
	#recklessness,if=((target.time_to_die>190|target.health.pct<20)&(buff.bloodbath.up|!talent.bloodbath.enabled))|target.time_to_die<=12|talent.anger_management.enabled
	if { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } or target.TimeToDie() <= 12 or Talent(anger_management_talent) Spell(recklessness)
	#avatar,if=(buff.recklessness.up|target.time_to_die<=30)
	if BuffPresent(recklessness_buff) or target.TimeToDie() <= 30 Spell(avatar)
	#blood_fury,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetCdActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsCdActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsCdActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeCdActions()
}

# ActionList: FurySingleMindedFuryAoeActions --> main, shortcd, cd

AddFunction FurySingleMindedFuryAoeActions
{
	#raging_blow,if=buff.meat_cleaver.stack>=3&buff.enrage.up
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack>=3
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FurySingleMindedFuryAoeShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)

	unless BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		#bladestorm,if=buff.enrage.remains>6
		if BuffRemaining(enrage_buff any=1) > 6 Spell(bladestorm)

		unless Spell(whirlwind)
			or BuffPresent(sudden_death_buff) and Spell(execute)
		{
			#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
			if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
		}
	}
}

AddFunction FurySingleMindedFuryAoeCdActions
{
	#bloodbath
	Spell(bloodbath)

	unless { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		# CHANGE: Synchronize Recklessness with Bladestorm's conditions.
		#recklessness,sync=bladestorm
		#if not SpellCooldown(bladestorm) > 0 Spell(recklessness)
		#bladestorm,if=buff.enrage.remains>6
		if BuffRemaining(enrage_buff any=1) > 6 and not SpellCooldown(bladestorm) > 0 Spell(recklessness)
	}
}

AddFunction FurySingleMindedFuryAoeCdActions {}

# ActionList: FurySingleMindedFuryPrecombatActions --> main, shortcd, cd

AddFunction FurySingleMindedFuryPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#stance,choose=battle
	Spell(battle_stance)
	# CHANGE: Apply raid buffs.
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	if not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) Spell(commanding_shout)
	#snapshot_stats
}

AddFunction FurySingleMindedFuryPrecombatShortCdActions {}

AddFunction FurySingleMindedFuryPrecombatCdActions
{
	unless Spell(battle_stance)
		or not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) and Spell(commanding_shout)
		or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout)
	{
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

# ActionList: FurySingleMindedFurySingleTargetActions --> main, shortcd, cd

AddFunction FurySingleMindedFurySingleTargetActions
{
	#wild_strike,if=rage>110&target.health.pct>20
	if Rage() > 110 and target.HealthPercent() > 20 Spell(wild_strike)
	#bloodthirst,if=(!talent.unquenchable_thirst.enabled&rage<80)|buff.enrage.down
	if not Talent(unquenchable_thirst_talent) and Rage() < 80 or BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#execute,if=buff.enrage.up|target.time_to_die<12
	if BuffPresent(enrage_buff any=1) or target.TimeToDie() < 12 Spell(execute)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#wild_strike,if=buff.enrage.up&target.health.pct>20
	if BuffPresent(enrage_buff any=1) and target.HealthPercent() > 20 Spell(wild_strike)
	#impending_victory,if=!talent.unquenchable_thirst.enabled&target.health.pct>20
	if not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 Spell(impending_victory)
	#bloodthirst
	Spell(bloodthirst)
}

AddFunction FurySingleMindedFurySingleTargetShortCdActions
{
	unless Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike)
		or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or BuffExpires(enrage_buff any=1) } and Spell(bloodthirst)
	{
		#ravager,if=buff.bloodbath.up|(!talent.bloodbath.enabled&(!raid_event.adds.exists|raid_event.adds.cooldown>60|target.time_to_die<40))
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and { not False(raid_event_adds_exists) or 600 > 60 or target.TimeToDie() < 40 } Spell(ravager)

		unless BuffPresent(sudden_death_buff) and Spell(execute)
		{
			#siegebreaker
			Spell(siegebreaker)
			#storm_bolt
			Spell(storm_bolt)

			unless BuffPresent(bloodsurge_buff) and Spell(wild_strike)
				or { BuffPresent(enrage_buff any=1) or target.TimeToDie() < 12 } and Spell(execute)
			{
				#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
				if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)

				unless BuffPresent(raging_blow_buff) and Spell(raging_blow)
					or BuffPresent(enrage_buff any=1) and target.HealthPercent() > 20 and Spell(wild_strike)
				{
					#shockwave,if=!talent.unquenchable_thirst.enabled
					if not Talent(unquenchable_thirst_talent) Spell(shockwave)
				}
			}
		}
	}
}

AddFunction FurySingleMindedFurySingleTargetCdActions
{
	#bloodbath
	Spell(bloodbath)
	#recklessness,if=target.health.pct<20&raid_event.adds.exists
	if target.HealthPercent() < 20 and False(raid_event_adds_exists) Spell(recklessness)
}

# ActionList: FurySingleMindedFuryThreeTargetsActions --> main, shortcd, cd

AddFunction FurySingleMindedFuryThreeTargetsActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.stack>=2
	if BuffStacks(meat_cleaver_buff) >= 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FurySingleMindedFuryThreeTargetsShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)

	unless { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffPresent(sudden_death_buff) and Spell(execute)
		or BuffStacks(meat_cleaver_buff) >= 2 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	}
}

AddFunction FurySingleMindedFuryThreeTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

# ActionList: FurySingleMindedFuryTwoTargetsActions --> main, shortcd, cd

AddFunction FurySingleMindedFuryTwoTargetsActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,if=target.health.pct<20|buff.sudden_death.react
	if target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.up
	if BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind,if=!buff.meat_cleaver.up
	if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
	#wild_strike,if=buff.bloodsurge.up&rage>75
	if BuffPresent(bloodsurge_buff) and Rage() > 75 Spell(wild_strike)
	#bloodthirst
	Spell(bloodthirst)
	#whirlwind,if=rage>rage.max-20
	if Rage() > MaxRage() - 20 Spell(whirlwind)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FurySingleMindedFuryTwoTargetsShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)
}

AddFunction FurySingleMindedFuryTwoTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

###
### Fury (Titan's Grip)
###
# Based on SimulationCraft profile "Warrior_Fury_2h_T17M".
#	class=warrior
#	spec=fury
#	talents=1321321
#	glyphs=unending_rage/raging_wind/heroic_leap

# ActionList: FuryTitansGripDefaultActions --> main, shortcd, cd

AddFunction FuryTitansGripDefaultActions
{
	#auto_attack
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>3&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 3 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetActions()
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeActions()
}

AddFunction FuryTitansGripDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#berserker_rage,if=buff.enrage.down|(talent.unquenchable_thirst.enabled&buff.raging_blow.down)
	if BuffExpires(enrage_buff any=1) or Talent(unquenchable_thirst_talent) and BuffExpires(raging_blow_buff) Spell(berserker_rage)
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>3&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 3 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetShortCdActions()
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetShortCdActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsShortCdActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeShortCdActions()
}

AddFunction FuryTitansGripDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>3&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 3 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetCdActions()
	#recklessness,if=((target.time_to_die>190|target.health.pct<20)&(buff.bloodbath.up|!talent.bloodbath.enabled))|target.time_to_die<=12|talent.anger_management.enabled
	if { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } or target.TimeToDie() <= 12 or Talent(anger_management_talent) Spell(recklessness)
	#avatar,if=(buff.recklessness.up|target.time_to_die<=30)
	if BuffPresent(recklessness_buff) or target.TimeToDie() <= 30 Spell(avatar)
	#blood_fury,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetCdActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsCdActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsCdActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeCdActions()
}

# ActionList: FuryTitansGripAoeActions --> main, shortcd, cd

AddFunction FuryTitansGripAoeActions
{
	#raging_blow,if=buff.meat_cleaver.stack>=3&buff.enrage.up
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack>=3
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FuryTitansGripAoeShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)

	unless BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		#bladestorm,if=buff.enrage.remains>6
		if BuffRemaining(enrage_buff any=1) > 6 Spell(bladestorm)

		unless Spell(whirlwind)
			or BuffPresent(sudden_death_buff) and Spell(execute)
		{
			#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
			if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
		}
	}
}

AddFunction FuryTitansGripAoeCdActions
{
	#bloodbath
	Spell(bloodbath)

	unless { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		# CHANGE: Synchronize Recklessness with Bladestorm's conditions.
		#recklessness,sync=bladestorm
		#if not SpellCooldown(bladestorm) > 0 Spell(recklessness)
		#bladestorm,if=buff.enrage.remains>6
		if BuffRemaining(enrage_buff any=1) > 6 and not SpellCooldown(bladestorm) > 0 Spell(recklessness)
	}
}

# ActionList: FuryTitansGripPrecombatActions --> main, shortcd, cd

AddFunction FuryTitansGripPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#stance,choose=battle
	Spell(battle_stance)
	# CHANGE: Apply raid buffs.
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	if not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) Spell(commanding_shout)
	#snapshot_stats
}

AddFunction FuryTitansGripPrecombatShortCdActions {}

AddFunction FuryTitansGripPrecombatCdActions
{
	unless Spell(battle_stance)
		or not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) and Spell(commanding_shout)
		or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout)
	{
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

# ActionList: FuryTitansGripSingleTargetActions --> main, shortcd, cd

AddFunction FuryTitansGripSingleTargetActions
{
	#wild_strike,if=rage>110&target.health.pct>20
	if Rage() > 110 and target.HealthPercent() > 20 Spell(wild_strike)
	#bloodthirst,if=(!talent.unquenchable_thirst.enabled&rage<80)|buff.enrage.down
	if not Talent(unquenchable_thirst_talent) and Rage() < 80 or BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#execute,if=buff.enrage.up|target.time_to_die<12
	if BuffPresent(enrage_buff any=1) or target.TimeToDie() < 12 Spell(execute)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#wild_strike,if=buff.enrage.up&target.health.pct>20
	if BuffPresent(enrage_buff any=1) and target.HealthPercent() > 20 Spell(wild_strike)
	#impending_victory,if=!talent.unquenchable_thirst.enabled&target.health.pct>20
	if not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 Spell(impending_victory)
	#bloodthirst
	Spell(bloodthirst)
}

AddFunction FuryTitansGripSingleTargetShortCdActions
{
	unless Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike)
		or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or BuffExpires(enrage_buff any=1) } and Spell(bloodthirst)
	{
		#ravager,if=buff.bloodbath.up|(!talent.bloodbath.enabled&(!raid_event.adds.exists|raid_event.adds.cooldown>60|target.time_to_die<40))
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and { not False(raid_event_adds_exists) or 600 > 60 or target.TimeToDie() < 40 } Spell(ravager)

		unless BuffPresent(sudden_death_buff) and Spell(execute)
		{
			#siegebreaker
			Spell(siegebreaker)
			#storm_bolt
			Spell(storm_bolt)

			unless BuffPresent(bloodsurge_buff) and Spell(wild_strike)
				or { BuffPresent(enrage_buff any=1) or target.TimeToDie() < 12 } and Spell(execute)
			{
				#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
				if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)

				unless BuffPresent(raging_blow_buff) and Spell(raging_blow)
					or BuffPresent(enrage_buff any=1) and target.HealthPercent() > 20 and Spell(wild_strike)
				{
					#shockwave,if=!talent.unquenchable_thirst.enabled
					if not Talent(unquenchable_thirst_talent) Spell(shockwave)
				}
			}
		}
	}
}

AddFunction FuryTitansGripSingleTargetCdActions
{
	#bloodbath
	Spell(bloodbath)
	#recklessness,if=target.health.pct<20&raid_event.adds.exists
	if target.HealthPercent() < 20 and False(raid_event_adds_exists) Spell(recklessness)
}

# ActionList: FuryTitansGripThreeTargetsActions --> main, shortcd, cd

AddFunction FuryTitansGripThreeTargetsActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.stack>=2
	if BuffStacks(meat_cleaver_buff) >= 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FuryTitansGripThreeTargetsShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)

	unless { BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst)
		or BuffPresent(sudden_death_buff) and Spell(execute)
		or BuffStacks(meat_cleaver_buff) >= 2 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	}
}

AddFunction FuryTitansGripThreeTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

# ActionList: FuryTitansGripTwoTargetsActions --> main, shortcd, cd

AddFunction FuryTitansGripTwoTargetsActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,if=target.health.pct<20|buff.sudden_death.react
	if target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.up
	if BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind,if=!buff.meat_cleaver.up
	if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
	#wild_strike,if=buff.bloodsurge.up&rage>75
	if BuffPresent(bloodsurge_buff) and Rage() > 75 Spell(wild_strike)
	#bloodthirst
	Spell(bloodthirst)
	#whirlwind,if=rage>rage.max-20
	if Rage() > MaxRage() - 20 Spell(whirlwind)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FuryTitansGripTwoTargetsShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)
}

AddFunction FuryTitansGripTwoTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

### Fury icons.
AddCheckBox(opt_warrior_fury_aoe L(AOE) specialization=fury default)

AddIcon specialization=fury help=shortcd enemies=1 checkbox=!opt_warrior_fury_aoe
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatShortCdActions()
		FurySingleMindedFuryDefaultShortCdActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatShortCdActions()
		FuryTitansGripDefaultShortCdActions()
	}
}

AddIcon specialization=fury help=shortcd checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatShortCdActions()
		FurySingleMindedFuryDefaultShortCdActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatShortCdActions()
		FuryTitansGripDefaultShortCdActions()
	}
}

AddIcon specialization=fury help=main enemies=1
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatActions()
		FurySingleMindedFuryDefaultActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatActions()
		FuryTitansGripDefaultActions()
	}
}

AddIcon specialization=fury help=aoe checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatActions()
		FurySingleMindedFuryDefaultActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatActions()
		FuryTitansGripDefaultActions()
	}
}

AddIcon specialization=fury help=cd enemies=1 checkbox=!opt_warrior_fury_aoe
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatCdActions()
		FurySingleMindedFuryDefaultCdActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatCdActions()
		FuryTitansGripDefaultCdActions()
	}
}

AddIcon specialization=fury help=cd checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=one_handed)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatCdActions()
		FurySingleMindedFuryDefaultCdActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if InCombat(no) FuryTitansGripPrecombatCdActions()
		FuryTitansGripDefaultCdActions()
	}
}

###
### Protection
###
# Based on SimulationCraft profile "Warrior_Protection_T17M".
#	class=warrior
#	spec=protection
#	talents=1113323
#	glyphs=unending_rage/heroic_leap/cleave

# ActionList: ProtectionDefaultActions --> main, shortcd, cd

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#call_action_list,name=prot
	ProtectionProtActions()
}

AddFunction ProtectionDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#berserker_rage,if=buff.enrage.down
	if BuffExpires(enrage_buff any=1) Spell(berserker_rage)
	#call_action_list,name=prot
	ProtectionProtShortCdActions()
}

AddFunction ProtectionDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#blood_fury,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(arcane_torrent_rage)
	#call_action_list,name=prot
	ProtectionProtCdActions()
}

# ActionList: ProtectionPrecombatActions --> main, shortcd, cd

AddFunction ProtectionPrecombatActions
{
	#flask,type=greater_draenic_stamina_flask
	#food,type=blackrock_barbecue
	#stance,choose=defensive
	Spell(defensive_stance)
	# CHANGE: Apply raid buffs.
	if not BuffPresent(stamina_buff any=1) Spell(commanding_shout)
	if not BuffPresent(attack_power_multiplier_buff any=1) and not BuffPresent(stamina_buff) Spell(battle_shout)
	#snapshot_stats
}

AddFunction ProtectionPrecombatShortCdActions {}

AddFunction ProtectionPrecombatCdActions
{
	unless Spell(defensive_stance)
		or not BuffPresent(attack_power_multiplier_buff any=1) and not BuffPresent(stamina_buff) and Spell(battle_shout)
		or not BuffPresent(stamina_buff any=1) and Spell(commanding_shout)
	{
		#shield_wall
		Spell(shield_wall)
		#potion,name=draenic_armor
		UsePotionArmor()
	}
}

# ActionList: ProtectionProtAoeActions --> main, shortcd, cd

AddFunction ProtectionProtAoeActions
{
	#thunder_clap,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(thunder_clap)
	#shield_slam,if=buff.shield_block.up
	if BuffPresent(shield_block_buff) Spell(shield_slam)
	#revenge
	Spell(revenge)
	#thunder_clap
	Spell(thunder_clap)
	#shield_slam
	Spell(shield_slam)
	#shield_slam
	Spell(shield_slam)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionProtAoeShortCdActions
{
	unless not target.DebuffPresent(deep_wounds_debuff) and Spell(thunder_clap)
	{
		#heroic_strike,if=buff.ultimatum.up|rage>110|(talent.unyielding_strikes.enabled&buff.unyielding_strikes.stack>=6)
		if BuffPresent(ultimatum_buff) or Rage() > 110 or Talent(unyielding_strikes_talent) and BuffStacks(unyielding_strikes_buff) >= 6 Spell(heroic_strike)
		#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
		if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)

		unless BuffPresent(shield_block_buff) and Spell(shield_slam)
		{
			#ravager,if=(buff.avatar.up|cooldown.avatar.remains>10)|!talent.avatar.enabled
			if BuffPresent(avatar_buff) or SpellCooldown(avatar) > 10 or not Talent(avatar_talent) Spell(ravager)
			#dragon_roar,if=(buff.bloodbath.up|cooldown.bloodbath.remains>10)|!talent.bloodbath.enabled
			if BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 10 or not Talent(bloodbath_talent) Spell(dragon_roar)
			#shockwave
			Spell(shockwave)

			unless Spell(revenge)
				or Spell(thunder_clap)
				or Spell(shield_slam)
			{
				#storm_bolt
				Spell(storm_bolt)
			}
		}
	}
}

AddFunction ProtectionProtAoeCdActions
{
	#bloodbath
	Spell(bloodbath)
	#avatar
	Spell(avatar)
}

# ActionList: ProtectionProtActions --> main, shortcd, cd

AddFunction ProtectionProtActions
{
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeActions()
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#impending_victory,if=talent.impending_victory.enabled&cooldown.shield_slam.remains<=execute_time
	if Talent(impending_victory_talent) and SpellCooldown(shield_slam) <= ExecuteTime(impending_victory) Spell(impending_victory)
	#victory_rush,if=!talent.impending_victory.enabled&cooldown.shield_slam.remains<=execute_time
	if not Talent(impending_victory_talent) and SpellCooldown(shield_slam) <= ExecuteTime(victory_rush) and BuffPresent(victorious_buff) Spell(victory_rush)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionProtShortCdActions
{
	#shield_block,if=!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up)
	if not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) } Spell(shield_block)
	#shield_barrier,if=buff.shield_barrier.down&((buff.shield_block.down&action.shield_block.charges_fractional<0.75)|rage>=85)
	if BuffExpires(shield_barrier_tank_buff) and { BuffExpires(shield_block_buff) and Charges(shield_block count=0) < 0.75 or Rage() >= 85 } Spell(shield_barrier_tank)
	#demoralizing_shout,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(demoralizing_shout)
	# CHANGE: Only suggest Enraged Regeneration at below 80% health.
	#enraged_regeneration,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	#if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(enraged_regeneration)
	if HealthPercent() < 80 and IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(enraged_regeneration)
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeShortCdActions()
	#heroic_strike,if=buff.ultimatum.up|(talent.unyielding_strikes.enabled&buff.unyielding_strikes.stack>=6)
	if BuffPresent(ultimatum_buff) or Talent(unyielding_strikes_talent) and BuffStacks(unyielding_strikes_buff) >= 6 Spell(heroic_strike)

	unless Spell(shield_slam)
		or Spell(revenge)
	{
		#ravager
		Spell(ravager)
		#storm_bolt
		Spell(storm_bolt)
		#dragon_roar
		Spell(dragon_roar)
	}
}

AddFunction ProtectionProtCdActions
{
	#shield_wall,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(shield_wall)
	#last_stand,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(last_stand)
	#potion,name=draenic_armor,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)|target.time_to_die<=25
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } or target.TimeToDie() <= 25 UsePotionArmor()
	#stoneform,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(stoneform)
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeCdActions()
	#bloodbath,if=talent.bloodbath.enabled&((cooldown.dragon_roar.remains=0&talent.dragon_roar.enabled)|(cooldown.storm_bolt.remains=0&talent.storm_bolt.enabled)|talent.shockwave.enabled)
	if Talent(bloodbath_talent) and { not SpellCooldown(dragon_roar) > 0 and Talent(dragon_roar_talent) or not SpellCooldown(storm_bolt) > 0 and Talent(storm_bolt_talent) or Talent(shockwave_talent) } Spell(bloodbath)
	#avatar,if=talent.avatar.enabled&((cooldown.ravager.remains=0&talent.ravager.enabled)|(cooldown.dragon_roar.remains=0&talent.dragon_roar.enabled)|(talent.storm_bolt.enabled&cooldown.storm_bolt.remains=0)|(!(talent.dragon_roar.enabled|talent.ravager.enabled|talent.storm_bolt.enabled)))
	if Talent(avatar_talent) and { not SpellCooldown(ravager) > 0 and Talent(ravager_talent) or not SpellCooldown(dragon_roar) > 0 and Talent(dragon_roar_talent) or Talent(storm_bolt_talent) and not SpellCooldown(storm_bolt) > 0 or not { Talent(dragon_roar_talent) or Talent(ravager_talent) or Talent(storm_bolt_talent) } } Spell(avatar)
}

# Based on SimulationCraft profile "Warrior_Gladiator_T17M".
#	class=warrior
#	spec=protection
#	talents=1133323
#	glyphs=unending_rage/heroic_leap/cleave

# ActionList: ProtectionGladiatorDefaultActions --> main, shortcd, cd

AddFunction ProtectionGladiatorDefaultActions
{
	#auto_attack
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ProtectionGladiatorSingleActions()
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ProtectionGladiatorAoeActions()
}

AddFunction ProtectionGladiatorDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#shield_charge,if=(!buff.shield_charge.up&!cooldown.shield_slam.remains)|charges=2
	if not BuffPresent(shield_charge_buff) and not SpellCooldown(shield_slam) > 0 or Charges(shield_charge) == 2 Spell(shield_charge)
	#berserker_rage,if=buff.enrage.down
	if BuffExpires(enrage_buff any=1) Spell(berserker_rage)
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	# CHANGE: Get within melee range of the target.
	GetInMeleeRange()
	#heroic_strike,if=(buff.shield_charge.up|(buff.unyielding_strikes.up&rage>=50-buff.unyielding_strikes.stack*5))&target.health.pct>20
	if { BuffPresent(shield_charge_buff) or BuffPresent(unyielding_strikes_buff) and Rage() >= 50 - BuffStacks(unyielding_strikes_buff) * 5 } and target.HealthPercent() > 20 Spell(heroic_strike)
	#heroic_strike,if=buff.ultimatum.up|rage>=rage.max-20|buff.unyielding_strikes.stack>4|target.time_to_die<10
	if BuffPresent(ultimatum_buff) or Rage() >= MaxRage() - 20 or BuffStacks(unyielding_strikes_buff) > 4 or target.TimeToDie() < 10 Spell(heroic_strike)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ProtectionGladiatorSingleShortCdActions()
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ProtectionGladiatorAoeShortCdActions()
}

AddFunction ProtectionGladiatorDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#avatar
	Spell(avatar)
	#bloodbath
	Spell(bloodbath)
	#blood_fury,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up|target.time_to_die<10
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) or target.TimeToDie() < 10 Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up|target.time_to_die<10
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) or target.TimeToDie() < 10 Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up|target.time_to_die<10
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) or target.TimeToDie() < 10 Spell(arcane_torrent_rage)
	#potion,name=draenic_armor,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) UsePotionArmor()
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ProtectionGladiatorSingleCdActions()
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ProtectionGladiatorAoeCdActions()
}

# ActionList: ProtectionGladiatorAoeActions --> main, shortcd, cd

AddFunction ProtectionGladiatorAoeActions
{
	#revenge
	Spell(revenge)
	#shield_slam
	Spell(shield_slam)
	#thunder_clap,cycle_targets=1,if=dot.deep_wounds.remains<3&active_enemies>4
	if target.DebuffRemaining(deep_wounds_debuff) < 3 and Enemies() > 4 Spell(thunder_clap)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#thunder_clap,if=active_enemies>6
	if Enemies() > 6 Spell(thunder_clap)
	#devastate,cycle_targets=1,if=dot.deep_wounds.remains<5&cooldown.shield_slam.remains>execute_time*0.4
	if target.DebuffRemaining(deep_wounds_debuff) < 5 and SpellCooldown(shield_slam) > ExecuteTime(devastate) * 0.4 Spell(devastate)
	#devastate,if=cooldown.shield_slam.remains>execute_time*0.4
	if SpellCooldown(shield_slam) > ExecuteTime(devastate) * 0.4 Spell(devastate)
}

AddFunction ProtectionGladiatorAoeShortCdActions
{
	unless Spell(revenge)
		or Spell(shield_slam)
	{
		#dragon_roar,if=(buff.bloodbath.up|cooldown.bloodbath.remains>10)|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 10 or not Talent(bloodbath_talent) Spell(dragon_roar)
		#storm_bolt,if=(buff.bloodbath.up|cooldown.bloodbath.remains>7)|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 7 or not Talent(bloodbath_talent) Spell(storm_bolt)

		unless target.DebuffRemaining(deep_wounds_debuff) < 3 and Enemies() > 4 and Spell(thunder_clap)
		{
			#bladestorm,if=buff.shield_charge.down
			if BuffExpires(shield_charge_buff) Spell(bladestorm)
		}
	}
}

AddFunction ProtectionGladiatorAoeCdActions {}

# ActionList: ProtectionGladiatorPrecombatActions --> main, shortcd, cd

AddFunction ProtectionGladiatorPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#stance,choose=gladiator
	Spell(gladiator_stance)
	# CHANGE: Apply raid buffs.
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	if not BuffPresent(stamina_buff any=1) and not BuffPresent(attack_power_multiplier_buff) Spell(commanding_shout)
	#snapshot_stats
}

AddFunction ProtectionGladiatorPrecombatShortCdActions {}

AddFunction ProtectionGladiatorPrecombatCdActions
{
	unless Spell(gladiator_stance)
		or not BuffPresent(attack_power_multiplier_buff any=1) and not BuffPresent(stamina_buff) and Spell(battle_shout)
		or not BuffPresent(stamina_buff any=1) and Spell(commanding_shout)
	{
		#potion,name=draenic_armor
		UsePotionArmor()
	}
}

# ActionList: ProtectionGladiatorSingleActions --> main, shortcd, cd

AddFunction ProtectionGladiatorSingleActions
{
	#devastate,if=buff.unyielding_strikes.stack>0&buff.unyielding_strikes.stack<6&buff.unyielding_strikes.remains<1.5
	if BuffStacks(unyielding_strikes_buff) > 0 and BuffStacks(unyielding_strikes_buff) < 6 and BuffRemaining(unyielding_strikes_buff) < 1.5 Spell(devastate)
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#execute,if=rage>60&target.health.pct<20
	if Rage() > 60 and target.HealthPercent() < 20 Spell(execute)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionGladiatorSingleShortCdActions
{
	unless BuffStacks(unyielding_strikes_buff) > 0 and BuffStacks(unyielding_strikes_buff) < 6 and BuffRemaining(unyielding_strikes_buff) < 1.5 and Spell(devastate)
		or Spell(shield_slam)
		or Spell(revenge)
		or BuffPresent(sudden_death_buff) and Spell(execute)
	{
		#storm_bolt
		Spell(storm_bolt)
		#dragon_roar
		Spell(dragon_roar)
	}
}

AddFunction ProtectionGladiatorSingleCdActions {}

### Protection icons.
AddCheckBox(opt_warrior_protection_aoe L(AOE) specialization=protection default)

AddIcon specialization=protection help=shortcd enemies=1 checkbox=!opt_warrior_protection_aoe
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatShortCdActions()
		ProtectionGladiatorDefaultShortCdActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatShortCdActions()
		ProtectionDefaultShortCdActions()
	}
}

AddIcon specialization=protection help=shortcd checkbox=opt_warrior_protection_aoe
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatShortCdActions()
		ProtectionGladiatorDefaultShortCdActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatShortCdActions()
		ProtectionDefaultShortCdActions()
	}
}

AddIcon specialization=protection help=main enemies=1
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatActions()
		ProtectionGladiatorDefaultActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatActions()
		ProtectionDefaultActions()
	}
}

AddIcon specialization=protection help=aoe checkbox=opt_warrior_protection_aoe
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatActions()
		ProtectionGladiatorDefaultActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatActions()
		ProtectionDefaultActions()
	}
}

AddIcon specialization=protection help=cd enemies=1 checkbox=!opt_warrior_protection_aoe
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatCdActions()
		ProtectionGladiatorDefaultCdActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatCdActions()
		ProtectionDefaultCdActions()
	}
}

AddIcon specialization=protection help=cd checkbox=opt_warrior_protection_aoe
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionGladiatorPrecombatCdActions()
		ProtectionGladiatorDefaultCdActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if InCombat(no) ProtectionPrecombatCdActions()
		ProtectionDefaultCdActions()
	}
}
]]

	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("WARRIOR", "Ovale", desc, code, "script")
end
