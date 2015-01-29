local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warrior_arms_t17m"
	local desc = "[6.0] SimulationCraft: Warrior_Arms_T17M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Arms_T17M".
#	class=warrior
#	spec=arms
#	talents=1321322
#	glyphs=unending_rage/heroic_leap/sweeping_strikes

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

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
		#arcane_torrent,if=rage<rage.max-40
		if Rage() < MaxRage() - 40 Spell(arcane_torrent_rage)
	}
}

### actions.aoe

AddFunction ArmsAoeMainActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#rend,if=ticks_remain<2&target.time_to_die>4
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 Spell(rend)
	#colossus_smash,if=dot.rend.ticking
	if target.DebuffPresent(rend_debuff) Spell(colossus_smash)
	#mortal_strike,if=cooldown.colossus_smash.remains>1.5&target.health.pct>20&active_enemies=2
	if SpellCooldown(colossus_smash) > 1.5 and target.HealthPercent() > 20 and Enemies() == 2 Spell(mortal_strike)
	#execute,target=2,if=active_enemies=2
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
		#bladestorm
		Spell(bladestorm)

		unless target.DebuffPresent(rend_debuff) and Spell(colossus_smash) or SpellCooldown(colossus_smash) > 1.5 and target.HealthPercent() > 20 and Enemies() == 2 and Spell(mortal_strike) or { { Rage() > 60 or Enemies() == 2 } and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 } and Spell(execute_arms)
		{
			#dragon_roar,if=cooldown.colossus_smash.remains>1.5&!debuff.colossus_smash.up
			if SpellCooldown(colossus_smash) > 1.5 and not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)

			unless SpellCooldown(colossus_smash) > 1.5 and { target.HealthPercent() > 20 or Enemies() > 3 } and Spell(whirlwind) or not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 8 and Spell(rend)
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
	#food,type=blackrock_barbecue
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
		{
			#bladestorm,if=!raid_event.adds.exists&debuff.colossus_smash.up&rage<70
			if not False(raid_event_adds_exists) and target.DebuffPresent(colossus_smash_debuff) and Rage() < 70 Spell(bladestorm)

			unless target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(mortal_strike)
			{
				#storm_bolt,if=(cooldown.colossus_smash.remains>4|debuff.colossus_smash.up)&rage<90
				if { SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) } and Rage() < 90 Spell(storm_bolt)
				#siegebreaker
				Spell(siegebreaker)
				#dragon_roar,if=!debuff.colossus_smash.up
				if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)

				unless not target.DebuffPresent(colossus_smash_debuff) and target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 and Spell(rend) or { Rage() >= 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_buff) or target.TimeToDie() < 5 } and Spell(execute_arms) or Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(impending_victory) or { Rage() > 20 or SpellCooldown(colossus_smash) > ExecuteTime(slam) } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(slam) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or ArmorSetBonus(T17 4) or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(whirlwind)
				{
					#shockwave
					Spell(shockwave)
				}
			}
		}
	}
}

AddFunction ArmsSingleShortCdPostConditions
{
	not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 4 and Spell(rend) or Spell(colossus_smash) or target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and Spell(mortal_strike) or not target.DebuffPresent(colossus_smash_debuff) and target.TimeToDie() > 4 and target.DebuffRemaining(rend_debuff) < 5.4 and Spell(rend) or { Rage() >= 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_buff) or target.TimeToDie() < 5 } and Spell(execute_arms) or Rage() < 40 and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(impending_victory) or { Rage() > 20 or SpellCooldown(colossus_smash) > ExecuteTime(slam) } and target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(slam) or not Talent(slam_talent) and target.HealthPercent() > 20 and { Rage() >= 40 or ArmorSetBonus(T17 4) or target.DebuffPresent(colossus_smash_debuff) } and SpellCooldown(colossus_smash) > 1 and SpellCooldown(mortal_strike) > 1 and Spell(whirlwind)
}

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

### Required symbols
# arcane_torrent_rage
# avatar
# battle_shout
# battle_stance
# berserking
# bladestorm
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# charge
# colossus_smash
# colossus_smash_debuff
# commanding_shout
# draenic_strength_potion
# dragon_roar
# execute_arms
# glyph_of_gag_order
# heroic_leap
# heroic_throw
# impending_victory
# mortal_strike
# pummel
# quaking_palm
# ravager
# recklessness
# recklessness_buff
# rend
# rend_debuff
# shockwave
# siegebreaker
# slam
# slam_talent
# storm_bolt
# sudden_death_buff
# sweeping_strikes
# war_stomp
# whirlwind
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
