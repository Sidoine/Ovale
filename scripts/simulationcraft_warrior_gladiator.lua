local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warrior_gladiator_t17m"
	local desc = "[6.1] SimulationCraft: Warrior_Gladiator_T17M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Gladiator_T17M".
#	class=warrior
#	spec=protection
#	talents=1133323
#	glyphs=unending_rage/heroic_leap/cleave

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

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
		#avatar
		Spell(avatar)
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
	#food,type=pickled_eel
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

### Protection icons.

AddCheckBox(opt_warrior_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionGladiatorPrecombatShortCdPostConditions()
	{
		ProtectionGladiatorDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionGladiatorPrecombatShortCdPostConditions()
	{
		ProtectionGladiatorDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=protection
{
	if not InCombat() ProtectionGladiatorPrecombatMainActions()
	ProtectionGladiatorDefaultMainActions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
	if not InCombat() ProtectionGladiatorPrecombatMainActions()
	ProtectionGladiatorDefaultMainActions()
}

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=cd specialization=protection
{
	if not InCombat() ProtectionGladiatorPrecombatCdActions()
	unless not InCombat() and ProtectionGladiatorPrecombatCdPostConditions()
	{
		ProtectionGladiatorDefaultCdActions()
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=cd specialization=protection
{
	if not InCombat() ProtectionGladiatorPrecombatCdActions()
	unless not InCombat() and ProtectionGladiatorPrecombatCdPostConditions()
	{
		ProtectionGladiatorDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_rage
# avatar
# avatar_buff
# battle_shout
# berserker_rage
# berserking
# bladestorm
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# charge
# commanding_shout
# deep_wounds_debuff
# devastate
# draenic_armor_potion
# dragon_roar
# execute
# gladiator_stance
# glyph_of_gag_order
# heroic_leap
# heroic_strike
# heroic_throw
# pummel
# quaking_palm
# revenge
# shield_charge
# shield_charge_buff
# shield_slam
# storm_bolt
# sudden_death_buff
# thunder_clap
# ultimatum_buff
# unyielding_strikes_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
end
