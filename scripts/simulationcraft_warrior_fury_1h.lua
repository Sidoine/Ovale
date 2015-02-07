local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warrior_fury_1h_t17m"
	local desc = "[6.0] SimulationCraft: Warrior_Fury_1h_T17M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Fury_1h_T17M".
#	class=warrior
#	spec=fury
#	talents=1321321
#	glyphs=unending_rage/raging_wind/heroic_leap

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=fury)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=fury)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=fury)

AddFunction FurySingleMindedFuryUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction FurySingleMindedFuryGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction FurySingleMindedFuryInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
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

### actions.default

AddFunction FurySingleMindedFuryDefaultMainActions
{
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 FurySingleMindedFuryMovementMainActions()
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FurySingleMindedFurySingleTargetMainActions()
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetMainActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsMainActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsMainActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeMainActions()
}

AddFunction FurySingleMindedFuryDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	FurySingleMindedFuryGetInMeleeRange()
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 FurySingleMindedFuryMovementShortCdActions()

	unless 0 > 5 and FurySingleMindedFuryMovementShortCdPostConditions()
	{
		#berserker_rage,if=buff.enrage.down|(talent.unquenchable_thirst.enabled&buff.raging_blow.down)
		if not IsEnraged() or Talent(unquenchable_thirst_talent) and BuffExpires(raging_blow_buff) Spell(berserker_rage)
		#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
		if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
		#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
		if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FurySingleMindedFurySingleTargetShortCdActions()

		unless { 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 } and FurySingleMindedFurySingleTargetShortCdPostConditions()
		{
			#call_action_list,name=single_target,if=active_enemies=1
			if Enemies() == 1 FurySingleMindedFurySingleTargetShortCdActions()

			unless Enemies() == 1 and FurySingleMindedFurySingleTargetShortCdPostConditions()
			{
				#call_action_list,name=two_targets,if=active_enemies=2
				if Enemies() == 2 FurySingleMindedFuryTwoTargetsShortCdActions()

				unless Enemies() == 2 and FurySingleMindedFuryTwoTargetsShortCdPostConditions()
				{
					#call_action_list,name=three_targets,if=active_enemies=3
					if Enemies() == 3 FurySingleMindedFuryThreeTargetsShortCdActions()

					unless Enemies() == 3 and FurySingleMindedFuryThreeTargetsShortCdPostConditions()
					{
						#call_action_list,name=aoe,if=active_enemies>3
						if Enemies() > 3 FurySingleMindedFuryAoeShortCdActions()
					}
				}
			}
		}
	}
}

AddFunction FurySingleMindedFuryDefaultCdActions
{
	#pummel
	FurySingleMindedFuryInterruptActions()

	unless 0 > 5 and FurySingleMindedFuryMovementCdPostConditions()
	{
		#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
		if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 FurySingleMindedFuryUsePotionStrength()
		#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
		if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FurySingleMindedFurySingleTargetCdActions()

		unless { 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 } and FurySingleMindedFurySingleTargetCdPostConditions()
		{
			#recklessness,if=((target.time_to_die>190|target.health.pct<20)&(buff.bloodbath.up|!talent.bloodbath.enabled))|target.time_to_die<=12|talent.anger_management.enabled
			if { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } or target.TimeToDie() <= 12 or Talent(anger_management_talent) Spell(recklessness)
			#avatar,if=(buff.recklessness.up|target.time_to_die<=30)
			if BuffPresent(recklessness_buff) or target.TimeToDie() <= 30 Spell(avatar)
			#blood_fury,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
			if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
			#berserking,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
			if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(berserking)
			#arcane_torrent,if=rage<rage.max-40
			if Rage() < MaxRage() - 40 Spell(arcane_torrent_rage)
			#call_action_list,name=single_target,if=active_enemies=1
			if Enemies() == 1 FurySingleMindedFurySingleTargetCdActions()

			unless Enemies() == 1 and FurySingleMindedFurySingleTargetCdPostConditions()
			{
				#call_action_list,name=two_targets,if=active_enemies=2
				if Enemies() == 2 FurySingleMindedFuryTwoTargetsCdActions()

				unless Enemies() == 2 and FurySingleMindedFuryTwoTargetsCdPostConditions()
				{
					#call_action_list,name=three_targets,if=active_enemies=3
					if Enemies() == 3 FurySingleMindedFuryThreeTargetsCdActions()

					unless Enemies() == 3 and FurySingleMindedFuryThreeTargetsCdPostConditions()
					{
						#call_action_list,name=aoe,if=active_enemies>3
						if Enemies() > 3 FurySingleMindedFuryAoeCdActions()
					}
				}
			}
		}
	}
}

### actions.aoe

AddFunction FurySingleMindedFuryAoeMainActions
{
	#raging_blow,if=buff.meat_cleaver.stack>=3&buff.enrage.up
	if BuffStacks(meat_cleaver_buff) >= 3 and IsEnraged() Spell(raging_blow)
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack>=3
	if BuffStacks(meat_cleaver_buff) >= 3 Spell(raging_blow)
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

	unless BuffStacks(meat_cleaver_buff) >= 3 and IsEnraged() and Spell(raging_blow) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 3 and Spell(raging_blow)
	{
		#bladestorm,if=buff.enrage.remains>6
		if EnrageRemaining() > 6 Spell(bladestorm)

		unless Spell(whirlwind) or BuffPresent(sudden_death_buff) and Spell(execute)
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

	unless { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager) or BuffStacks(meat_cleaver_buff) >= 3 and IsEnraged() and Spell(raging_blow) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 3 and Spell(raging_blow)
	{
		#recklessness,sync=bladestorm
		if EnrageRemaining() > 6 and Spell(bladestorm) Spell(recklessness)
	}
}

### actions.movement

AddFunction FurySingleMindedFuryMovementMainActions
{
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FurySingleMindedFuryMovementShortCdActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#storm_bolt
	Spell(storm_bolt)
}

AddFunction FurySingleMindedFuryMovementShortCdPostConditions
{
	Spell(heroic_throw)
}

AddFunction FurySingleMindedFuryMovementCdPostConditions
{
	Spell(storm_bolt) or Spell(heroic_throw)
}

### actions.precombat

AddFunction FurySingleMindedFuryPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#commanding_shout,if=!aura.stamina.up&aura.attack_power_multiplier.up
	if not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) Spell(commanding_shout)
	#battle_shout,if=!aura.attack_power_multiplier.up
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	#stance,choose=battle
	Spell(battle_stance)
}

AddFunction FurySingleMindedFuryPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

AddFunction FurySingleMindedFuryPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
	{
		#snapshot_stats
		#potion,name=draenic_strength
		FurySingleMindedFuryUsePotionStrength()
	}
}

AddFunction FurySingleMindedFuryPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

### actions.single_target

AddFunction FurySingleMindedFurySingleTargetMainActions
{
	#wild_strike,if=rage>110&target.health.pct>20
	if Rage() > 110 and target.HealthPercent() > 20 Spell(wild_strike)
	#bloodthirst,if=(!talent.unquenchable_thirst.enabled&rage<80)|buff.enrage.down
	if not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#execute,if=buff.enrage.up|target.time_to_die<12
	if IsEnraged() or target.TimeToDie() < 12 Spell(execute)
	#raging_blow
	Spell(raging_blow)
	#wild_strike,if=buff.enrage.up&target.health.pct>20
	if IsEnraged() and target.HealthPercent() > 20 Spell(wild_strike)
	#impending_victory,if=!talent.unquenchable_thirst.enabled&target.health.pct>20
	if not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 Spell(impending_victory)
	#bloodthirst
	Spell(bloodthirst)
}

AddFunction FurySingleMindedFurySingleTargetShortCdActions
{
	unless Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike) or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() } and Spell(bloodthirst)
	{
		#ravager,if=buff.bloodbath.up|(!talent.bloodbath.enabled&(!raid_event.adds.exists|raid_event.adds.cooldown>60|target.time_to_die<40))
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and { not False(raid_event_adds_exists) or 600 > 60 or target.TimeToDie() < 40 } Spell(ravager)

		unless BuffPresent(sudden_death_buff) and Spell(execute)
		{
			#siegebreaker
			Spell(siegebreaker)
			#storm_bolt
			Spell(storm_bolt)

			unless BuffPresent(bloodsurge_buff) and Spell(wild_strike) or { IsEnraged() or target.TimeToDie() < 12 } and Spell(execute)
			{
				#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
				if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)

				unless Spell(raging_blow) or IsEnraged() and target.HealthPercent() > 20 and Spell(wild_strike)
				{
					#bladestorm,if=!raid_event.adds.exists
					if not False(raid_event_adds_exists) Spell(bladestorm)
					#shockwave,if=!talent.unquenchable_thirst.enabled
					if not Talent(unquenchable_thirst_talent) Spell(shockwave)
				}
			}
		}
	}
}

AddFunction FurySingleMindedFurySingleTargetShortCdPostConditions
{
	Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike) or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() } and Spell(bloodthirst) or BuffPresent(sudden_death_buff) and Spell(execute) or BuffPresent(bloodsurge_buff) and Spell(wild_strike) or { IsEnraged() or target.TimeToDie() < 12 } and Spell(execute) or Spell(raging_blow) or IsEnraged() and target.HealthPercent() > 20 and Spell(wild_strike) or not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 and Spell(impending_victory) or Spell(bloodthirst)
}

AddFunction FurySingleMindedFurySingleTargetCdActions
{
	#bloodbath
	Spell(bloodbath)
	#recklessness,if=target.health.pct<20&raid_event.adds.exists
	if target.HealthPercent() < 20 and False(raid_event_adds_exists) Spell(recklessness)
}

AddFunction FurySingleMindedFurySingleTargetCdPostConditions
{
	Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike) or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() } and Spell(bloodthirst) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and { not False(raid_event_adds_exists) or 600 > 60 or target.TimeToDie() < 40 } } and Spell(ravager) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(siegebreaker) or Spell(storm_bolt) or BuffPresent(bloodsurge_buff) and Spell(wild_strike) or { IsEnraged() or target.TimeToDie() < 12 } and Spell(execute) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or Spell(raging_blow) or IsEnraged() and target.HealthPercent() > 20 and Spell(wild_strike) or not False(raid_event_adds_exists) and Spell(bladestorm) or not Talent(unquenchable_thirst_talent) and Spell(shockwave) or not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 and Spell(impending_victory) or Spell(bloodthirst)
}

### actions.three_targets

AddFunction FurySingleMindedFuryThreeTargetsMainActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack>=2
	if BuffStacks(meat_cleaver_buff) >= 2 Spell(raging_blow)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
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
	if IsEnraged() Spell(bladestorm)

	unless { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 2 and Spell(raging_blow) or BuffPresent(sudden_death_buff) and Spell(execute)
	{
		#execute,target=2
		#execute,target=3
		#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	}
}

AddFunction FurySingleMindedFuryThreeTargetsShortCdPostConditions
{
	{ not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 2 and Spell(raging_blow) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(whirlwind) or Spell(bloodthirst) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

AddFunction FurySingleMindedFuryThreeTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

AddFunction FurySingleMindedFuryThreeTargetsCdPostConditions
{
	{ BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager) or IsEnraged() and Spell(bladestorm) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 2 and Spell(raging_blow) or BuffPresent(sudden_death_buff) and Spell(execute) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or Spell(whirlwind) or Spell(bloodthirst) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

### actions.two_targets

AddFunction FurySingleMindedFuryTwoTargetsMainActions
{
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,target=2
	#execute,if=target.health.pct<20|buff.sudden_death.react
	if target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.up
	if BuffPresent(meat_cleaver_buff) Spell(raging_blow)
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
	if IsEnraged() Spell(bladestorm)
}

AddFunction FurySingleMindedFuryTwoTargetsShortCdPostConditions
{
	{ not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or { target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) } and Spell(execute) or BuffPresent(meat_cleaver_buff) and Spell(raging_blow) or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Rage() > 75 and Spell(wild_strike) or Spell(bloodthirst) or Rage() > MaxRage() - 20 and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

AddFunction FurySingleMindedFuryTwoTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

AddFunction FurySingleMindedFuryTwoTargetsCdPostConditions
{
	{ BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or IsEnraged() and Spell(bladestorm) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or { target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) } and Spell(execute) or BuffPresent(meat_cleaver_buff) and Spell(raging_blow) or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Rage() > 75 and Spell(wild_strike) or Spell(bloodthirst) or Rage() > MaxRage() - 20 and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

### Fury icons.

AddCheckBox(opt_warrior_fury_aoe L(AOE) default specialization=fury)

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=shortcd specialization=fury
{
	unless not InCombat() and FurySingleMindedFuryPrecombatShortCdPostConditions()
	{
		FurySingleMindedFuryDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warrior_fury_aoe help=shortcd specialization=fury
{
	unless not InCombat() and FurySingleMindedFuryPrecombatShortCdPostConditions()
	{
		FurySingleMindedFuryDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=fury
{
	if not InCombat() FurySingleMindedFuryPrecombatMainActions()
	FurySingleMindedFuryDefaultMainActions()
}

AddIcon checkbox=opt_warrior_fury_aoe help=aoe specialization=fury
{
	if not InCombat() FurySingleMindedFuryPrecombatMainActions()
	FurySingleMindedFuryDefaultMainActions()
}

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=cd specialization=fury
{
	if not InCombat() FurySingleMindedFuryPrecombatCdActions()
	unless not InCombat() and FurySingleMindedFuryPrecombatCdPostConditions()
	{
		FurySingleMindedFuryDefaultCdActions()
	}
}

AddIcon checkbox=opt_warrior_fury_aoe help=cd specialization=fury
{
	if not InCombat() FurySingleMindedFuryPrecombatCdActions()
	unless not InCombat() and FurySingleMindedFuryPrecombatCdPostConditions()
	{
		FurySingleMindedFuryDefaultCdActions()
	}
}

### Required symbols
# anger_management_talent
# arcane_torrent_rage
# avatar
# battle_shout
# battle_stance
# berserker_rage
# berserking
# bladestorm
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# bloodsurge_buff
# bloodthirst
# charge
# commanding_shout
# draenic_strength_potion
# dragon_roar
# execute
# glyph_of_gag_order
# heroic_leap
# heroic_throw
# impending_victory
# meat_cleaver_buff
# pummel
# quaking_palm
# raging_blow
# raging_blow_buff
# ravager
# recklessness
# recklessness_buff
# shockwave
# siegebreaker
# storm_bolt
# sudden_death_buff
# unquenchable_thirst_talent
# war_stomp
# whirlwind
# wild_strike
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
