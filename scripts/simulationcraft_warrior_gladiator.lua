local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Gladiator_T17M"
	local desc = "[6.0] SimulationCraft: Warrior_Gladiator_T17M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Gladiator_T17M".
#	class=warrior
#	spec=protection
#	talents=1133323
#	glyphs=unending_rage/heroic_leap/cleave

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
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

AddFunction ProtectionGladiatorDefaultActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ProtectionGladiatorMovementActions()
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
	if BuffPresent(bloodbath_buff) or BuffPresent(avatar_buff) or BuffPresent(shield_charge_buff) UsePotionArmor()
	#shield_charge,if=(!buff.shield_charge.up&!cooldown.shield_slam.remains)|charges=2
	if not BuffPresent(shield_charge_buff) and not SpellCooldown(shield_slam) > 0 or Charges(shield_charge) == 2 Spell(shield_charge)
	#berserker_rage,if=buff.enrage.down
	if BuffExpires(enrage_buff any=1) Spell(berserker_rage)
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	#heroic_strike,if=(buff.shield_charge.up|(buff.unyielding_strikes.up&rage>=50-buff.unyielding_strikes.stack*5))&target.health.pct>20
	if { BuffPresent(shield_charge_buff) or BuffPresent(unyielding_strikes_buff) and Rage() >= 50 - BuffStacks(unyielding_strikes_buff) * 5 } and target.HealthPercent() > 20 Spell(heroic_strike)
	#heroic_strike,if=buff.ultimatum.up|rage>=rage.max-20|buff.unyielding_strikes.stack>4|target.time_to_die<10
	if BuffPresent(ultimatum_buff) or Rage() >= MaxRage() - 20 or BuffStacks(unyielding_strikes_buff) > 4 or target.TimeToDie() < 10 Spell(heroic_strike)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ProtectionGladiatorSingleActions()
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ProtectionGladiatorAoeActions()
}

AddFunction ProtectionGladiatorAoeActions
{
	#revenge
	Spell(revenge)
	#shield_slam
	Spell(shield_slam)
	#dragon_roar,if=(buff.bloodbath.up|cooldown.bloodbath.remains>10)|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 10 or not Talent(bloodbath_talent) Spell(dragon_roar)
	#storm_bolt,if=(buff.bloodbath.up|cooldown.bloodbath.remains>7)|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or SpellCooldown(bloodbath) > 7 or not Talent(bloodbath_talent) Spell(storm_bolt)
	#thunder_clap,cycle_targets=1,if=dot.deep_wounds.remains<3&active_enemies>4
	if target.DebuffRemaining(deep_wounds_debuff) < 3 and Enemies() > 4 Spell(thunder_clap)
	#bladestorm,if=buff.shield_charge.down
	if BuffExpires(shield_charge_buff) Spell(bladestorm)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#thunder_clap,if=active_enemies>6
	if Enemies() > 6 Spell(thunder_clap)
	#devastate,cycle_targets=1,if=dot.deep_wounds.remains<5&cooldown.shield_slam.remains>execute_time*0.4
	if target.DebuffRemaining(deep_wounds_debuff) < 5 and SpellCooldown(shield_slam) > ExecuteTime(devastate) * 0.4 Spell(devastate)
	#devastate,if=cooldown.shield_slam.remains>execute_time*0.4
	if SpellCooldown(shield_slam) > ExecuteTime(devastate) * 0.4 Spell(devastate)
}

AddFunction ProtectionGladiatorMovementActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#shield_charge
	Spell(shield_charge)
	#storm_bolt
	Spell(storm_bolt)
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction ProtectionGladiatorPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=blackrock_barbecue
	#stance,choose=gladiator
	Spell(gladiator_stance)
	#snapshot_stats
	#potion,name=draenic_armor
	UsePotionArmor()
}

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
	#storm_bolt
	Spell(storm_bolt)
	#dragon_roar
	Spell(dragon_roar)
	#execute,if=rage>60&target.health.pct<20
	if Rage() > 60 and target.HealthPercent() < 20 Spell(execute)
	#devastate
	Spell(devastate)
}

AddIcon specialization=protection help=main enemies=1
{
	if not InCombat() ProtectionGladiatorPrecombatActions()
	ProtectionGladiatorDefaultActions()
}

AddIcon specialization=protection help=aoe
{
	if not InCombat() ProtectionGladiatorPrecombatActions()
	ProtectionGladiatorDefaultActions()
}

### Required symbols
# arcane_torrent_rage
# avatar
# avatar_buff
# berserker_rage
# berserking
# bladestorm
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# charge
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
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
