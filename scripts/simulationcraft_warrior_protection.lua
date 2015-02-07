local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_warrior_protection_t17m"
	local desc = "[6.0] SimulationCraft: Warrior_Protection_T17M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Protection_T17M".
#	class=warrior
#	spec=protection
#	talents=1113323
#	glyphs=unending_rage/heroic_leap/cleave

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default if_stance=!warrior_gladiator_stance specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) if_stance=!warrior_gladiator_stance specialization=protection)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default if_stance=!warrior_gladiator_stance specialization=protection)

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

### Protection icons.

AddCheckBox(opt_warrior_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		ProtectionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		ProtectionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	ProtectionDefaultMainActions()
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	ProtectionDefaultMainActions()
}

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		ProtectionDefaultCdActions()
	}
}

AddIcon checkbox=opt_warrior_protection_aoe help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		ProtectionDefaultCdActions()
	}
}

### Required symbols
# arcane_torrent_rage
# avatar
# avatar_buff
# avatar_talent
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
# defensive_stance
# demoralizing_shout
# demoralizing_shout_debuff
# devastate
# draenic_armor_potion
# dragon_roar
# dragon_roar_talent
# enraged_regeneration
# enraged_regeneration_buff
# execute
# glyph_of_gag_order
# heroic_leap
# heroic_strike
# heroic_throw
# impending_victory
# impending_victory_talent
# last_stand
# last_stand_buff
# pummel
# quaking_palm
# ravager
# ravager_buff
# ravager_talent
# revenge
# shield_barrier_tank
# shield_barrier_tank_buff
# shield_block
# shield_block_buff
# shield_slam
# shield_wall
# shield_wall_buff
# shockwave
# shockwave_talent
# stoneform
# storm_bolt
# storm_bolt_talent
# sudden_death_buff
# thunder_clap
# ultimatum_buff
# unyielding_strikes_buff
# unyielding_strikes_talent
# victory_rush
# war_stomp
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
