local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warrior"
	local desc = "[6.0] Ovale: Rotations (Arms, Fury, Protection)"
	local code = [[
# Warrior rotation functions based on SimulationCraft.

###
### Arms
###
# Based on SimulationCraft profile "Warrior_Arms_T17M".
#	class=warrior
#	spec=arms
#	talents=1321322
#	glyphs=unending_rage/heroic_leap/sweeping_strikes

AddCheckBox(opt_interrupt L(interrupt) default specialization=arms)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=arms)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=arms)

AddFunction ArmsUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction ArmsGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction ArmsInterruptActions
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

AddFunction ArmsDefaultMainActions
{
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ArmsMovementMainActions()
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleMainActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ArmsAoeMainActions()
}

AddFunction ArmsDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	ArmsGetInMeleeRange()
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ArmsMovementShortCdActions()

	unless 0 > 5 and ArmsMovementShortCdPostConditions()
	{
		#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
		if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
		#call_action_list,name=single,if=active_enemies=1
		if Enemies() == 1 ArmsSingleShortCdActions()

		unless Enemies() == 1 and ArmsSingleShortCdPostConditions()
		{
			#call_action_list,name=aoe,if=active_enemies>1
			if Enemies() > 1 ArmsAoeShortCdActions()
		}
	}
}

AddFunction ArmsDefaultCdActions
{
	#pummel
	ArmsInterruptActions()

	unless 0 > 5 and ArmsMovementCdPostConditions()
	{
		#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<25
		if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() < 25 ArmsUsePotionStrength()
		#recklessness,if=(dot.rend.ticking&(target.time_to_die>190|target.health.pct<20)&((!talent.bloodbath.enabled&debuff.colossus_smash.up&(!cooldown.bladestorm.remains|!talent.bladestorm.enabled))|buff.bloodbath.up))|target.time_to_die<10
		if target.DebuffPresent(rend_debuff) and { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) and { not SpellCooldown(bladestorm) > 0 or not Talent(bladestorm_talent) } or BuffPresent(bloodbath_buff) } or target.TimeToDie() < 10 Spell(recklessness)
		#bloodbath,if=(dot.rend.ticking&cooldown.colossus_smash.remains<5&((talent.ravager.enabled&prev_gcd.ravager)|!talent.ravager.enabled))|target.time_to_die<20
		if target.DebuffPresent(rend_debuff) and SpellCooldown(colossus_smash) < 5 and { Talent(ravager_talent) and PreviousGCDSpell(ravager) or not Talent(ravager_talent) } or target.TimeToDie() < 20 Spell(bloodbath)
		#avatar,if=buff.recklessness.up|target.time_to_die<25
		if BuffPresent(recklessness_buff) or target.TimeToDie() < 25 Spell(avatar)
		#blood_fury,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
		#berserking,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
		if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(berserking)
		#arcane_torrent,if=rage<rage.max-40
		if Rage() < MaxRage() - 40 Spell(arcane_torrent_rage)
	}
}

### actions.aoe

AddFunction ArmsAoeMainActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#rend,if=ticks_remain<2&target.time_to_die>4&(target.health.pct>20|!debuff.colossus_smash.up)
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 and { target.HealthPercent() > 20 or not target.DebuffPresent(colossus_smash_debuff) } Spell(rend)
	#rend,cycle_targets=1,max_cycle_targets=2,if=ticks_remain<2&target.time_to_die>8&!buff.colossus_smash_up.up&talent.taste_for_blood.enabled
	if DebuffCountOnAny(rend_debuff) < Enemies() and DebuffCountOnAny(rend_debuff) <= 2 and target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 8 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Talent(taste_for_blood_talent) Spell(rend)
	#rend,cycle_targets=1,if=ticks_remain<2&target.time_to_die-remains>18&!buff.colossus_smash_up.up&active_enemies<=8
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() - target.DebuffRemaining(rend_debuff) > 18 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Enemies() <= 8 Spell(rend)
	#colossus_smash,if=dot.rend.ticking
	if target.DebuffPresent(rend_debuff) Spell(colossus_smash)
	#execute,cycle_targets=1,if=!buff.sudden_death.react&active_enemies<=8&((rage>72&cooldown.colossus_smash.remains>gcd)|rage>80|target.time_to_die<5|debuff.colossus_smash.up)
	if not BuffPresent(sudden_death_buff) and Enemies() <= 8 and { Rage() > 72 and SpellCooldown(colossus_smash) > GCD() or Rage() > 80 or target.TimeToDie() < 5 or target.DebuffPresent(colossus_smash_debuff) } Spell(execute_arms)
	#mortal_strike,if=target.health.pct>20&active_enemies<=5
	if target.HealthPercent() > 20 and Enemies() <= 5 Spell(mortal_strike)
	#thunder_clap,if=(target.health.pct>20|active_enemies>=9)&glyph.resonating_power.enabled
	if { target.HealthPercent() > 20 or Enemies() >= 9 } and Glyph(glyph_of_resonating_power) Spell(thunder_clap)
	#rend,cycle_targets=1,if=ticks_remain<2&target.time_to_die>8&!buff.colossus_smash_up.up&active_enemies>=9&rage<50&!talent.taste_for_blood.enabled
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 8 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Enemies() >= 9 and Rage() < 50 and not Talent(taste_for_blood_talent) Spell(rend)
	#whirlwind,if=target.health.pct>20|active_enemies>=9
	if target.HealthPercent() > 20 or Enemies() >= 9 Spell(whirlwind)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute_arms)
}

AddFunction ArmsAoeShortCdActions
{
	unless target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 and { target.HealthPercent() > 20 or not target.DebuffPresent(colossus_smash_debuff) } and Spell(rend) or DebuffCountOnAny(rend_debuff) < Enemies() and DebuffCountOnAny(rend_debuff) <= 2 and target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 8 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Talent(taste_for_blood_talent) and Spell(rend) or target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() - target.DebuffRemaining(rend_debuff) > 18 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Enemies() <= 8 and Spell(rend)
	{
		#ravager,if=buff.bloodbath.up|cooldown.colossus_smash.remains<4
		if BuffPresent(bloodbath_buff) or SpellCooldown(colossus_smash) < 4 Spell(ravager)
		#bladestorm,if=((debuff.colossus_smash.up|cooldown.colossus_smash.remains>3)&target.health.pct>20)|(target.health.pct<20&rage<30&cooldown.colossus_smash.remains>4)
		if { target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(colossus_smash) > 3 } and target.HealthPercent() > 20 or target.HealthPercent() < 20 and Rage() < 30 and SpellCooldown(colossus_smash) > 4 Spell(bladestorm)

		unless target.DebuffPresent(rend_debuff) and Spell(colossus_smash) or not BuffPresent(sudden_death_buff) and Enemies() <= 8 and { Rage() > 72 and SpellCooldown(colossus_smash) > GCD() or Rage() > 80 or target.TimeToDie() < 5 or target.DebuffPresent(colossus_smash_debuff) } and Spell(execute_arms) or target.HealthPercent() > 20 and Enemies() <= 5 and Spell(mortal_strike)
		{
			#dragon_roar,if=!debuff.colossus_smash.up
			if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)

			unless { target.HealthPercent() > 20 or Enemies() >= 9 } and Glyph(glyph_of_resonating_power) and Spell(thunder_clap) or target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 8 and not DebuffCountOnAny(colossus_smash_debuff) > 0 and Enemies() >= 9 and Rage() < 50 and not Talent(taste_for_blood_talent) and Spell(rend) or { target.HealthPercent() > 20 or Enemies() >= 9 } and Spell(whirlwind)
			{
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

### actions.movement

AddFunction ArmsMovementMainActions
{
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction ArmsMovementShortCdActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#storm_bolt
	Spell(storm_bolt)
}

AddFunction ArmsMovementShortCdPostConditions
{
	Spell(heroic_throw)
}

AddFunction ArmsMovementCdPostConditions
{
	Spell(storm_bolt) or Spell(heroic_throw)
}

### actions.precombat

AddFunction ArmsPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=sleeper_surprise
	#commanding_shout,if=!aura.stamina.up&aura.attack_power_multiplier.up
	if not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) Spell(commanding_shout)
	#battle_shout,if=!aura.attack_power_multiplier.up
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	#stance,choose=battle
	Spell(battle_stance)
}

AddFunction ArmsPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

AddFunction ArmsPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
	{
		#snapshot_stats
		#potion,name=draenic_strength
		ArmsUsePotionStrength()
	}
}

AddFunction ArmsPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

### actions.single

AddFunction ArmsSingleMainActions
{
	#rend,if=target.time_to_die>4&dot.rend.remains<5.4&(target.health.pct>20|!debuff.colossus_smash.up)
	if target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 and { target.HealthPercent() > 20 or not target.DebuffPresent(colossus_smash_debuff) } Spell(rend)
	#colossus_smash
	Spell(colossus_smash)
	#mortal_strike,if=target.health.pct>20
	if target.HealthPercent() > 20 Spell(mortal_strike)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute_arms)
	#execute,if=!buff.sudden_death.react&(rage>72&cooldown.colossus_smash.remains>gcd)|debuff.colossus_smash.up|target.time_to_die<5
	if not BuffPresent(sudden_death_buff) and Rage() > 72 and SpellCooldown(colossus_smash) > GCD() or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 Spell(execute_arms)
	#impending_victory,if=rage<40&target.health.pct>20&cooldown.colossus_smash.remains>1
	if Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 Spell(impending_victory)
	#slam,if=(rage>20|cooldown.colossus_smash.remains>gcd)&target.health.pct>20&cooldown.colossus_smash.remains>1
	if { Rage() > 20 or SpellCooldown(colossus_smash) > GCD() } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 Spell(slam)
	#thunder_clap,if=!talent.slam.enabled&target.health.pct>20&(rage>=40|debuff.colossus_smash.up)&glyph.resonating_power.enabled&cooldown.colossus_smash.remains>gcd
	if not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and Glyph(glyph_of_resonating_power) and SpellCooldown(colossus_smash) > GCD() Spell(thunder_clap)
	#whirlwind,if=!talent.slam.enabled&target.health.pct>20&(rage>=40|debuff.colossus_smash.up)&cooldown.colossus_smash.remains>gcd
	if not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > GCD() Spell(whirlwind)
}

AddFunction ArmsSingleShortCdActions
{
	unless target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 and { target.HealthPercent() > 20 or not target.DebuffPresent(colossus_smash_debuff) } and Spell(rend)
	{
		#ravager,if=cooldown.colossus_smash.remains<4&(!raid_event.adds.exists|raid_event.adds.in>55)
		if SpellCooldown(colossus_smash) < 4 and { not False(raid_event_adds_exists) or 600 > 55 } Spell(ravager)

		unless Spell(colossus_smash) or target.HealthPercent() > 20 and Spell(mortal_strike)
		{
			#bladestorm,if=(((debuff.colossus_smash.up|cooldown.colossus_smash.remains>3)&target.health.pct>20)|(target.health.pct<20&rage<30&cooldown.colossus_smash.remains>4))&(!raid_event.adds.exists|raid_event.adds.in>55|(talent.anger_management.enabled&raid_event.adds.in>40))
			if { { target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(colossus_smash) > 3 } and target.HealthPercent() > 20 or target.HealthPercent() < 20 and Rage() < 30 and SpellCooldown(colossus_smash) > 4 } and { not False(raid_event_adds_exists) or 600 > 55 or Talent(anger_management_talent) and 600 > 40 } Spell(bladestorm)
			#storm_bolt,if=target.health.pct>20|(target.health.pct<20&!debuff.colossus_smash.up)
			if target.HealthPercent() > 20 or target.HealthPercent() < 20 and not target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
			#siegebreaker
			Spell(siegebreaker)
			#dragon_roar,if=!debuff.colossus_smash.up&(!raid_event.adds.exists|raid_event.adds.in>55|(talent.anger_management.enabled&raid_event.adds.in>40))
			if not target.DebuffPresent(colossus_smash_debuff) and { not False(raid_event_adds_exists) or 600 > 55 or Talent(anger_management_talent) and 600 > 40 } Spell(dragon_roar)

			unless BuffPresent(sudden_death_buff) and Spell(execute_arms) or { not BuffPresent(sudden_death_buff) and Rage() > 72 and SpellCooldown(colossus_smash) > GCD() or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 } and Spell(execute_arms) or Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(impending_victory) or { Rage() > 20 or SpellCooldown(colossus_smash) > GCD() } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(slam) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and Glyph(glyph_of_resonating_power) and SpellCooldown(colossus_smash) > GCD() and Spell(thunder_clap) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > GCD() and Spell(whirlwind)
			{
				#shockwave
				Spell(shockwave)
			}
		}
	}
}

AddFunction ArmsSingleShortCdPostConditions
{
	target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 and { target.HealthPercent() > 20 or not target.DebuffPresent(colossus_smash_debuff) } and Spell(rend) or Spell(colossus_smash) or target.HealthPercent() > 20 and Spell(mortal_strike) or BuffPresent(sudden_death_buff) and Spell(execute_arms) or { not BuffPresent(sudden_death_buff) and Rage() > 72 and SpellCooldown(colossus_smash) > GCD() or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 } and Spell(execute_arms) or Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(impending_victory) or { Rage() > 20 or SpellCooldown(colossus_smash) > GCD() } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(slam) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and Glyph(glyph_of_resonating_power) and SpellCooldown(colossus_smash) > GCD() and Spell(thunder_clap) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > GCD() and Spell(whirlwind)
}

###
### Fury (Single-Minded Fury)
###
# Based on SimulationCraft profile "Warrior_Fury_1h_T17M".
#	class=warrior
#	spec=fury
#	talents=1321321
#	glyphs=unending_rage/raging_wind/heroic_leap

AddCheckBox(opt_interrupt L(interrupt) default specialization=fury)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=fury)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=fury)

AddFunction FuryUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction FuryGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction FuryInterruptActions
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
	FuryGetInMeleeRange()
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
	FuryInterruptActions()

	unless 0 > 5 and FurySingleMindedFuryMovementCdPostConditions()
	{
		#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
		if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 FuryUsePotionStrength()
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
		FuryUsePotionStrength()
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

###
### Fury (Titan's Grip)
###
# Based on SimulationCraft profile "Warrior_Fury_2h_T17M".
#	class=warrior
#	spec=fury
#	talents=1321321
#	glyphs=unending_rage/raging_wind/heroic_leap

AddCheckBox(opt_interrupt L(interrupt) default specialization=fury)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=fury)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=fury)

AddFunction FuryUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction FuryGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction FuryInterruptActions
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

AddFunction FuryTitansGripDefaultMainActions
{
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 FuryTitansGripMovementMainActions()
	#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
	if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetMainActions()
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetMainActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsMainActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsMainActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeMainActions()
}

AddFunction FuryTitansGripDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	FuryGetInMeleeRange()
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 FuryTitansGripMovementShortCdActions()

	unless 0 > 5 and FuryTitansGripMovementShortCdPostConditions()
	{
		#berserker_rage,if=buff.enrage.down|(talent.unquenchable_thirst.enabled&buff.raging_blow.down)
		if not IsEnraged() or Talent(unquenchable_thirst_talent) and BuffExpires(raging_blow_buff) Spell(berserker_rage)
		#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
		if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
		#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
		if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetShortCdActions()

		unless { 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 } and FuryTitansGripSingleTargetShortCdPostConditions()
		{
			#call_action_list,name=single_target,if=active_enemies=1
			if Enemies() == 1 FuryTitansGripSingleTargetShortCdActions()

			unless Enemies() == 1 and FuryTitansGripSingleTargetShortCdPostConditions()
			{
				#call_action_list,name=two_targets,if=active_enemies=2
				if Enemies() == 2 FuryTitansGripTwoTargetsShortCdActions()

				unless Enemies() == 2 and FuryTitansGripTwoTargetsShortCdPostConditions()
				{
					#call_action_list,name=three_targets,if=active_enemies=3
					if Enemies() == 3 FuryTitansGripThreeTargetsShortCdActions()

					unless Enemies() == 3 and FuryTitansGripThreeTargetsShortCdPostConditions()
					{
						#call_action_list,name=aoe,if=active_enemies>3
						if Enemies() > 3 FuryTitansGripAoeShortCdActions()
					}
				}
			}
		}
	}
}

AddFunction FuryTitansGripDefaultCdActions
{
	#pummel
	FuryInterruptActions()

	unless 0 > 5 and FuryTitansGripMovementCdPostConditions()
	{
		#potion,name=draenic_strength,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
		if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 FuryUsePotionStrength()
		#call_action_list,name=single_target,if=(raid_event.adds.cooldown<60&raid_event.adds.count>2&active_enemies=1)|raid_event.movement.cooldown<5
		if 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 FuryTitansGripSingleTargetCdActions()

		unless { 600 < 60 and 0 > 2 and Enemies() == 1 or 600 < 5 } and FuryTitansGripSingleTargetCdPostConditions()
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
			if Enemies() == 1 FuryTitansGripSingleTargetCdActions()

			unless Enemies() == 1 and FuryTitansGripSingleTargetCdPostConditions()
			{
				#call_action_list,name=two_targets,if=active_enemies=2
				if Enemies() == 2 FuryTitansGripTwoTargetsCdActions()

				unless Enemies() == 2 and FuryTitansGripTwoTargetsCdPostConditions()
				{
					#call_action_list,name=three_targets,if=active_enemies=3
					if Enemies() == 3 FuryTitansGripThreeTargetsCdActions()

					unless Enemies() == 3 and FuryTitansGripThreeTargetsCdPostConditions()
					{
						#call_action_list,name=aoe,if=active_enemies>3
						if Enemies() > 3 FuryTitansGripAoeCdActions()
					}
				}
			}
		}
	}
}

### actions.aoe

AddFunction FuryTitansGripAoeMainActions
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

AddFunction FuryTitansGripAoeShortCdActions
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

AddFunction FuryTitansGripAoeCdActions
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

AddFunction FuryTitansGripMovementMainActions
{
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FuryTitansGripMovementShortCdActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#storm_bolt
	Spell(storm_bolt)
}

AddFunction FuryTitansGripMovementShortCdPostConditions
{
	Spell(heroic_throw)
}

AddFunction FuryTitansGripMovementCdPostConditions
{
	Spell(storm_bolt) or Spell(heroic_throw)
}

### actions.precombat

AddFunction FuryTitansGripPrecombatMainActions
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

AddFunction FuryTitansGripPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

AddFunction FuryTitansGripPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
	{
		#snapshot_stats
		#potion,name=draenic_strength
		FuryUsePotionStrength()
	}
}

AddFunction FuryTitansGripPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(battle_stance)
}

### actions.single_target

AddFunction FuryTitansGripSingleTargetMainActions
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

AddFunction FuryTitansGripSingleTargetShortCdActions
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

AddFunction FuryTitansGripSingleTargetShortCdPostConditions
{
	Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike) or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() } and Spell(bloodthirst) or BuffPresent(sudden_death_buff) and Spell(execute) or BuffPresent(bloodsurge_buff) and Spell(wild_strike) or { IsEnraged() or target.TimeToDie() < 12 } and Spell(execute) or Spell(raging_blow) or IsEnraged() and target.HealthPercent() > 20 and Spell(wild_strike) or not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 and Spell(impending_victory) or Spell(bloodthirst)
}

AddFunction FuryTitansGripSingleTargetCdActions
{
	#bloodbath
	Spell(bloodbath)
	#recklessness,if=target.health.pct<20&raid_event.adds.exists
	if target.HealthPercent() < 20 and False(raid_event_adds_exists) Spell(recklessness)
}

AddFunction FuryTitansGripSingleTargetCdPostConditions
{
	Rage() > 110 and target.HealthPercent() > 20 and Spell(wild_strike) or { not Talent(unquenchable_thirst_talent) and Rage() < 80 or not IsEnraged() } and Spell(bloodthirst) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and { not False(raid_event_adds_exists) or 600 > 60 or target.TimeToDie() < 40 } } and Spell(ravager) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(siegebreaker) or Spell(storm_bolt) or BuffPresent(bloodsurge_buff) and Spell(wild_strike) or { IsEnraged() or target.TimeToDie() < 12 } and Spell(execute) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or Spell(raging_blow) or IsEnraged() and target.HealthPercent() > 20 and Spell(wild_strike) or not False(raid_event_adds_exists) and Spell(bladestorm) or not Talent(unquenchable_thirst_talent) and Spell(shockwave) or not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 and Spell(impending_victory) or Spell(bloodthirst)
}

### actions.three_targets

AddFunction FuryTitansGripThreeTargetsMainActions
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

AddFunction FuryTitansGripThreeTargetsShortCdActions
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

AddFunction FuryTitansGripThreeTargetsShortCdPostConditions
{
	{ not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 2 and Spell(raging_blow) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(whirlwind) or Spell(bloodthirst) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

AddFunction FuryTitansGripThreeTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

AddFunction FuryTitansGripThreeTargetsCdPostConditions
{
	{ BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager) or IsEnraged() and Spell(bladestorm) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or BuffStacks(meat_cleaver_buff) >= 2 and Spell(raging_blow) or BuffPresent(sudden_death_buff) and Spell(execute) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or Spell(whirlwind) or Spell(bloodthirst) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

### actions.two_targets

AddFunction FuryTitansGripTwoTargetsMainActions
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

AddFunction FuryTitansGripTwoTargetsShortCdActions
{
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#bladestorm,if=buff.enrage.up
	if IsEnraged() Spell(bladestorm)
}

AddFunction FuryTitansGripTwoTargetsShortCdPostConditions
{
	{ not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or { target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) } and Spell(execute) or BuffPresent(meat_cleaver_buff) and Spell(raging_blow) or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Rage() > 75 and Spell(wild_strike) or Spell(bloodthirst) or Rage() > MaxRage() - 20 and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

AddFunction FuryTitansGripTwoTargetsCdActions
{
	#bloodbath
	Spell(bloodbath)
}

AddFunction FuryTitansGripTwoTargetsCdPostConditions
{
	{ BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(ravager) or { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and Spell(dragon_roar) or IsEnraged() and Spell(bladestorm) or { not IsEnraged() or Rage() < 50 or BuffExpires(raging_blow_buff) } and Spell(bloodthirst) or { target.HealthPercent() < 20 or BuffPresent(sudden_death_buff) } and Spell(execute) or BuffPresent(meat_cleaver_buff) and Spell(raging_blow) or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Rage() > 75 and Spell(wild_strike) or Spell(bloodthirst) or Rage() > MaxRage() - 20 and Spell(whirlwind) or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
}

###
### Protection (Gladiator)
###
# Based on SimulationCraft profile "Warrior_Gladiator_T17M".
#	class=warrior
#	spec=protection
#	talents=1133323
#	glyphs=unending_rage/heroic_leap/cleave

AddCheckBox(opt_interrupt L(interrupt) default if_stance=warrior_gladiator_stance specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) if_stance=warrior_gladiator_stance specialization=protection)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default if_stance=warrior_gladiator_stance specialization=protection)

AddFunction ProtectionGladiatorUsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction ProtectionGladiatorGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction ProtectionGladiatorInterruptActions
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

AddFunction ProtectionGladiatorDefaultMainActions
{
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ProtectionGladiatorMovementMainActions()
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ProtectionGladiatorSingleMainActions()
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ProtectionGladiatorAoeMainActions()
}

AddFunction ProtectionGladiatorDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	ProtectionGladiatorGetInMeleeRange()
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ProtectionGladiatorMovementShortCdActions()

	unless 0 > 5 and ProtectionGladiatorMovementShortCdPostConditions()
	{
		#shield_charge,if=(!buff.shield_charge.up&!cooldown.shield_slam.remains)|charges=2
		if not BuffPresent(shield_charge_buff) and not SpellCooldown(shield_slam) > 0 or Charges(shield_charge) == 2 Spell(shield_charge)
		#berserker_rage,if=buff.enrage.down
		if not IsEnraged() Spell(berserker_rage)
		#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
		if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
		#heroic_strike,if=(buff.shield_charge.up|(buff.unyielding_strikes.up&rage>=50-buff.unyielding_strikes.stack*5))&target.health.pct>20
		if { BuffPresent(shield_charge_buff) or BuffPresent(unyielding_strikes_buff) and Rage() >= 50 - BuffStacks(unyielding_strikes_buff) * 5 } and target.HealthPercent() > 20 Spell(heroic_strike)
		#heroic_strike,if=buff.ultimatum.up|rage>=rage.max-20|buff.unyielding_strikes.stack>4|target.time_to_die<10
		if BuffPresent(ultimatum_buff) or Rage() >= MaxRage() - 20 or BuffStacks(unyielding_strikes_buff) > 4 or target.TimeToDie() < 10 Spell(heroic_strike)
		#call_action_list,name=single,if=active_enemies=1
		if Enemies() == 1 ProtectionGladiatorSingleShortCdActions()

		unless Enemies() == 1 and ProtectionGladiatorSingleShortCdPostConditions()
		{
			#call_action_list,name=aoe,if=active_enemies>=2
			if Enemies() >= 2 ProtectionGladiatorAoeShortCdActions()
		}
	}
}

AddFunction ProtectionGladiatorDefaultCdActions
{
	#pummel
	ProtectionGladiatorInterruptActions()

	unless 0 > 5 and ProtectionGladiatorMovementCdPostConditions()
	{
		#avatar
		Spell(avatar)
		#bloodbath
		Spell(bloodbath)
		#blood_fury,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up|target.time_to_die<10
		if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) or target.TimeToDie() < 10 Spell(blood_fury_ap)
		#berserking,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up|target.time_to_die<10
		if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) or target.TimeToDie() < 10 Spell(berserking)
		#arcane_torrent,if=rage<rage.max-40
		if Rage() < MaxRage() - 40 Spell(arcane_torrent_rage)
		#potion,name=draenic_armor,if=buff.bloodbath.up|buff.avatar.up|buff.shield_charge.up
		if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) ProtectionGladiatorUsePotionArmor()
	}
}

### actions.aoe

AddFunction ProtectionGladiatorAoeMainActions
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
	unless Spell(revenge) or Spell(shield_slam)
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

### actions.movement

AddFunction ProtectionGladiatorMovementMainActions
{
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction ProtectionGladiatorMovementShortCdActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#shield_charge
	Spell(shield_charge)
	#storm_bolt
	Spell(storm_bolt)
}

AddFunction ProtectionGladiatorMovementShortCdPostConditions
{
	Spell(heroic_throw)
}

AddFunction ProtectionGladiatorMovementCdPostConditions
{
	Spell(storm_bolt) or Spell(heroic_throw)
}

### actions.precombat

AddFunction ProtectionGladiatorPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#commanding_shout,if=!aura.stamina.up&aura.attack_power_multiplier.up
	if not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) Spell(commanding_shout)
	#battle_shout,if=!aura.attack_power_multiplier.up
	if not BuffPresent(attack_power_multiplier_buff any=1) Spell(battle_shout)
	#stance,choose=gladiator
	Spell(gladiator_stance)
}

AddFunction ProtectionGladiatorPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(gladiator_stance)
}

AddFunction ProtectionGladiatorPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(gladiator_stance)
	{
		#snapshot_stats
		#potion,name=draenic_armor
		ProtectionGladiatorUsePotionArmor()
	}
}

AddFunction ProtectionGladiatorPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and BuffPresent(attack_power_multiplier_buff any=1) and BuffExpires(attack_power_multiplier_buff) and Spell(commanding_shout) or not BuffPresent(attack_power_multiplier_buff any=1) and Spell(battle_shout) or Spell(gladiator_stance)
}

### actions.single

AddFunction ProtectionGladiatorSingleMainActions
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
	unless BuffStacks(unyielding_strikes_buff) > 0 and BuffStacks(unyielding_strikes_buff) < 6 and BuffRemaining(unyielding_strikes_buff) < 1.5 and Spell(devastate) or Spell(shield_slam) or Spell(revenge) or BuffPresent(sudden_death_buff) and Spell(execute)
	{
		#storm_bolt
		Spell(storm_bolt)
		#dragon_roar
		Spell(dragon_roar)
	}
}

AddFunction ProtectionGladiatorSingleShortCdPostConditions
{
	BuffStacks(unyielding_strikes_buff) > 0 and BuffStacks(unyielding_strikes_buff) < 6 and BuffRemaining(unyielding_strikes_buff) < 1.5 and Spell(devastate) or Spell(shield_slam) or Spell(revenge) or BuffPresent(sudden_death_buff) and Spell(execute) or Rage() > 60 and target.HealthPercent() < 20 and Spell(execute) or Spell(devastate)
}

###
### Protection
###
# Based on SimulationCraft profile "Warrior_Protection_T17M".
#	class=warrior
#	spec=protection
#	talents=1113323
#	glyphs=unending_rage/heroic_leap/cleave

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=protection)

AddFunction ProtectionUsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range)
	{
		if target.InRange(charge) Spell(charge)
		if target.InRange(charge) Spell(heroic_leap)
		if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction ProtectionInterruptActions
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

AddFunction ProtectionDefaultMainActions
{
	#call_action_list,name=prot
	ProtectionProtMainActions()
}

AddFunction ProtectionDefaultShortCdActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	ProtectionGetInMeleeRange()
	#berserker_rage,if=buff.enrage.down
	if not IsEnraged() Spell(berserker_rage)
	#call_action_list,name=prot
	ProtectionProtShortCdActions()
}

AddFunction ProtectionDefaultCdActions
{
	#pummel
	ProtectionInterruptActions()
	#blood_fury,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|buff.avatar.up
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) Spell(arcane_torrent_rage)
	#call_action_list,name=prot
	ProtectionProtCdActions()
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
	#flask,type=greater_draenic_stamina_flask
	#food,type=blackrock_barbecue
	#battle_shout,if=!aura.attack_power_multiplier.up&aura.stamina.up
	if not BuffPresent(attack_power_multiplier_buff any=1) and BuffPresent(stamina_buff any=1) and BuffExpires(stamina_buff) Spell(battle_shout)
	#commanding_shout,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(commanding_shout)
	#stance,choose=defensive
	Spell(defensive_stance)
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
	not BuffPresent(attack_power_multiplier_buff any=1) and BuffPresent(stamina_buff any=1) and BuffExpires(stamina_buff) and Spell(battle_shout) or not BuffPresent(stamina_buff any=1) and Spell(commanding_shout) or Spell(defensive_stance)
}

AddFunction ProtectionPrecombatCdActions
{
	unless not BuffPresent(attack_power_multiplier_buff any=1) and BuffPresent(stamina_buff any=1) and BuffExpires(stamina_buff) and Spell(battle_shout) or not BuffPresent(stamina_buff any=1) and Spell(commanding_shout) or Spell(defensive_stance)
	{
		#snapshot_stats
		#shield_wall
		Spell(shield_wall)
		#potion,name=draenic_armor
		ProtectionUsePotionArmor()
	}
}

AddFunction ProtectionPrecombatCdPostConditions
{
	not BuffPresent(attack_power_multiplier_buff any=1) and BuffPresent(stamina_buff any=1) and BuffExpires(stamina_buff) and Spell(battle_shout) or not BuffPresent(stamina_buff any=1) and Spell(commanding_shout) or Spell(defensive_stance)
}

### actions.prot

AddFunction ProtectionProtMainActions
{
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeMainActions()
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#impending_victory,if=talent.impending_victory.enabled&cooldown.shield_slam.remains<=execute_time
	if Talent(impending_victory_talent) and SpellCooldown(shield_slam) <= ExecuteTime(impending_victory) Spell(impending_victory)
	#victory_rush,if=!talent.impending_victory.enabled&cooldown.shield_slam.remains<=execute_time
	if not Talent(impending_victory_talent) and SpellCooldown(shield_slam) <= ExecuteTime(victory_rush) Spell(victory_rush)
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
	#enraged_regeneration,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } and HealthPercent() < 80 Spell(enraged_regeneration)
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeShortCdActions()

	unless Enemies() > 3 and ProtectionProtAoeShortCdPostConditions()
	{
		#heroic_strike,if=buff.ultimatum.up|(talent.unyielding_strikes.enabled&buff.unyielding_strikes.stack>=6)
		if BuffPresent(ultimatum_buff) or Talent(unyielding_strikes_talent) and BuffStacks(unyielding_strikes_buff) >= 6 Spell(heroic_strike)

		unless Spell(shield_slam) or Spell(revenge)
		{
			#ravager
			Spell(ravager)
			#storm_bolt
			Spell(storm_bolt)
			#dragon_roar
			Spell(dragon_roar)
		}
	}
}

AddFunction ProtectionProtCdActions
{
	#shield_wall,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(shield_wall)
	#last_stand,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(last_stand)
	#potion,name=draenic_armor,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)|target.time_to_die<=25
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } or target.TimeToDie() <= 25 ProtectionUsePotionArmor()
	#stoneform,if=incoming_damage_2500ms>health.max*0.1&!(debuff.demoralizing_shout.up|buff.ravager.up|buff.shield_wall.up|buff.last_stand.up|buff.enraged_regeneration.up|buff.shield_block.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.1 and not { target.DebuffPresent(demoralizing_shout_debuff) or BuffPresent(ravager_buff) or BuffPresent(shield_wall_buff) or BuffPresent(last_stand_buff) or BuffPresent(enraged_regeneration_buff) or BuffPresent(shield_block_buff) or BuffPresent(potion_armor_buff) } Spell(stoneform)
	#call_action_list,name=prot_aoe,if=active_enemies>3
	if Enemies() > 3 ProtectionProtAoeCdActions()

	unless Enemies() > 3 and ProtectionProtAoeCdPostConditions()
	{
		#bloodbath,if=talent.bloodbath.enabled&((cooldown.dragon_roar.remains=0&talent.dragon_roar.enabled)|(cooldown.storm_bolt.remains=0&talent.storm_bolt.enabled)|talent.shockwave.enabled)
		if Talent(bloodbath_talent) and { not SpellCooldown(dragon_roar) > 0 and Talent(dragon_roar_talent) or not SpellCooldown(storm_bolt) > 0 and Talent(storm_bolt_talent) or Talent(shockwave_talent) } Spell(bloodbath)
		#avatar,if=talent.avatar.enabled&((cooldown.ravager.remains=0&talent.ravager.enabled)|(cooldown.dragon_roar.remains=0&talent.dragon_roar.enabled)|(talent.storm_bolt.enabled&cooldown.storm_bolt.remains=0)|(!(talent.dragon_roar.enabled|talent.ravager.enabled|talent.storm_bolt.enabled)))
		if Talent(avatar_talent) and { not SpellCooldown(ravager) > 0 and Talent(ravager_talent) or not SpellCooldown(dragon_roar) > 0 and Talent(dragon_roar_talent) or Talent(storm_bolt_talent) and not SpellCooldown(storm_bolt) > 0 or not { Talent(dragon_roar_talent) or Talent(ravager_talent) or Talent(storm_bolt_talent) } } Spell(avatar)
	}
}

### actions.prot_aoe

AddFunction ProtectionProtAoeMainActions
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

			unless Spell(revenge) or Spell(thunder_clap)
			{
				#bladestorm
				Spell(bladestorm)

				unless Spell(shield_slam)
				{
					#storm_bolt
					Spell(storm_bolt)
				}
			}
		}
	}
}

AddFunction ProtectionProtAoeShortCdPostConditions
{
	not target.DebuffPresent(deep_wounds_debuff) and Spell(thunder_clap) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Spell(revenge) or Spell(thunder_clap) or Spell(shield_slam) or Spell(shield_slam) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(devastate)
}

AddFunction ProtectionProtAoeCdActions
{
	#bloodbath
	Spell(bloodbath)
	#avatar
	Spell(avatar)
}

AddFunction ProtectionProtAoeCdPostConditions
{
	not target.DebuffPresent(deep_wounds_debuff) and Spell(thunder_clap) or BuffPresent(shield_block_buff) and Spell(shield_slam) or { BuffPresent(avatar_buff) or SpellCooldown(avatar) > 10 or not Talent(avatar_talent) } and Spell(ravager) or { BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 10 or not Talent(bloodbath_talent) } and Spell(dragon_roar) or Spell(shockwave) or Spell(revenge) or Spell(thunder_clap) or Spell(bladestorm) or Spell(shield_slam) or Spell(storm_bolt) or Spell(shield_slam) or BuffPresent(sudden_death_buff) and Spell(execute) or Spell(devastate)
}
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Arms, Fury, Protection"
	local code = [[
# Ovale warrior script based on SimulationCraft.

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)
Include(ovale_warrior)

### Arms icons.

AddCheckBox(opt_warrior_arms_aoe L(AOE) default specialization=arms)

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=shortcd specialization=arms
{
	unless not InCombat() and ArmsPrecombatShortCdPostConditions()
	{
		ArmsDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warrior_arms_aoe help=shortcd specialization=arms
{
	unless not InCombat() and ArmsPrecombatShortCdPostConditions()
	{
		ArmsDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=arms
{
	if not InCombat() ArmsPrecombatMainActions()
	ArmsDefaultMainActions()
}

AddIcon checkbox=opt_warrior_arms_aoe help=aoe specialization=arms
{
	if not InCombat() ArmsPrecombatMainActions()
	ArmsDefaultMainActions()
}

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=cd specialization=arms
{
	if not InCombat() ArmsPrecombatCdActions()
	unless not InCombat() and ArmsPrecombatCdPostConditions()
	{
		ArmsDefaultCdActions()
	}
}

AddIcon checkbox=opt_warrior_arms_aoe help=cd specialization=arms
{
	if not InCombat() ArmsPrecombatCdActions()
	unless not InCombat() and ArmsPrecombatCdPostConditions()
	{
		ArmsDefaultCdActions()
	}
}

### Fury icons.

AddCheckBox(opt_warrior_fury_aoe L(AOE) default specialization=fury)

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=shortcd specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		unless not InCombat() and FurySingleMindedFuryPrecombatShortCdPostConditions()
		{
			FurySingleMindedFuryDefaultShortCdActions()
		}
	}
	if HasWeapon(main type=two_handed)
	{
		unless not InCombat() and FuryTitansGripPrecombatShortCdPostConditions()
		{
			FuryTitansGripDefaultShortCdActions()
		}
	}
}

AddIcon checkbox=opt_warrior_fury_aoe help=shortcd specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		unless not InCombat() and FurySingleMindedFuryPrecombatShortCdPostConditions()
		{
			FurySingleMindedFuryDefaultShortCdActions()
		}
	}
	if HasWeapon(main type=two_handed)
	{
		unless not InCombat() and FuryTitansGripPrecombatShortCdPostConditions()
		{
			FuryTitansGripDefaultShortCdActions()
		}
	}
}

AddIcon enemies=1 help=main specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		if not InCombat() FurySingleMindedFuryPrecombatMainActions()
		FurySingleMindedFuryDefaultMainActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if not InCombat() FuryTitansGripPrecombatMainActions()
		FuryTitansGripDefaultMainActions()
	}
}

AddIcon checkbox=opt_warrior_fury_aoe help=aoe specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		if not InCombat() FurySingleMindedFuryPrecombatMainActions()
		FurySingleMindedFuryDefaultMainActions()
	}
	if HasWeapon(main type=two_handed)
	{
		if not InCombat() FuryTitansGripPrecombatMainActions()
		FuryTitansGripDefaultMainActions()
	}
}

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=cd specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		if not InCombat() FurySingleMindedFuryPrecombatCdActions()
		unless not InCombat() and FurySingleMindedFuryPrecombatCdPostConditions()
		{
			FurySingleMindedFuryDefaultCdActions()
		}
	}
	if HasWeapon(main type=two_handed)
	{
		if not InCombat() FuryTitansGripPrecombatCdActions()
		unless not InCombat() and FuryTitansGripPrecombatCdPostConditions()
		{
			FuryTitansGripDefaultCdActions()
		}
	}
}

AddIcon checkbox=opt_warrior_fury_aoe help=cd specialization=fury
{
	if HasWeapon(main type=one_handed)
	{
		if not InCombat() FurySingleMindedFuryPrecombatCdActions()
		unless not InCombat() and FurySingleMindedFuryPrecombatCdPostConditions()
		{
			FurySingleMindedFuryDefaultCdActions()
		}
	}
	if HasWeapon(main type=two_handed)
	{
		if not InCombat() FuryTitansGripPrecombatCdActions()
		unless not InCombat() and FuryTitansGripPrecombatCdPostConditions()
		{
			FuryTitansGripDefaultCdActions()
		}
	}
}

### Protection icons.

AddCheckBox(opt_warrior_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=shortcd specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		unless not InCombat() and ProtectionGladiatorPrecombatShortCdPostConditions()
		{
			ProtectionGladiatorDefaultShortCdActions()
		}
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
		{
			ProtectionDefaultShortCdActions()
		}
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=shortcd specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		unless not InCombat() and ProtectionGladiatorPrecombatShortCdPostConditions()
		{
			ProtectionGladiatorDefaultShortCdActions()
		}
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
		{
			ProtectionDefaultShortCdActions()
		}
	}
}

AddIcon enemies=1 help=main specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionGladiatorPrecombatMainActions()
		ProtectionGladiatorDefaultMainActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionPrecombatMainActions()
		ProtectionDefaultMainActions()
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionGladiatorPrecombatMainActions()
		ProtectionGladiatorDefaultMainActions()
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionPrecombatMainActions()
		ProtectionDefaultMainActions()
	}
}

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=cd specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionGladiatorPrecombatCdActions()
		unless not InCombat() and ProtectionGladiatorPrecombatCdPostConditions()
		{
			ProtectionGladiatorDefaultCdActions()
		}
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionPrecombatCdActions()
		unless not InCombat() and ProtectionPrecombatCdPostConditions()
		{
			ProtectionDefaultCdActions()
		}
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=cd specialization=protection
{
	if Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionGladiatorPrecombatCdActions()
		unless not InCombat() and ProtectionGladiatorPrecombatCdPostConditions()
		{
			ProtectionGladiatorDefaultCdActions()
		}
	}
	unless Talent(gladiators_resolve_talent) and Stance(warrior_gladiator_stance)
	{
		if not InCombat() ProtectionPrecombatCdActions()
		unless not InCombat() and ProtectionPrecombatCdPostConditions()
		{
			ProtectionDefaultCdActions()
		}
	}
}
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "script")
end
