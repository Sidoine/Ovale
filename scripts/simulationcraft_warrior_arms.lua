local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Arms_T16M"
	local desc = "[6.0] SimulationCraft: Warrior_Arms_T16M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Arms_T16M".
#	class=warrior
#	spec=arms
#	talents=1311320
#	glyphs=unending_rage/heroic_leap/sweeping_strikes

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
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

AddFunction ArmsPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#stance,choose=battle
	Spell(battle_stance)
	#snapshot_stats
	#potion,name=mogu_power
	UsePotionStrength()
}

AddFunction ArmsDefaultActions
{
	#charge
	if target.InRange(charge) Spell(charge)
	#auto_attack
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 ArmsMovementActions()
	#potion,name=mogu_power,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<25
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
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 600 > 45 or not False(raid_event_movement_exists) } and target.InRange(charge) Spell(heroic_leap)
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleActions()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 ArmsAoeActions()
}

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#rend,if=ticks_remain<2&target.time_to_die>4
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 Spell(rend)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#bladestorm,if=active_enemies>5
	if Enemies() > 5 Spell(bladestorm)
	#colossus_smash,if=dot.rend.ticking
	if target.DebuffPresent(rend_debuff) Spell(colossus_smash)
	#mortal_strike,if=cooldown.colossus_smash.remains>1.5&target.health.pct>20&active_enemies=2
	if SpellCooldown(colossus_smash) > 1.5 and target.HealthPercent() > 20 and Enemies() == 2 Spell(mortal_strike)
	#execute,if=((rage>60|active_enemies=2)&cooldown.colossus_smash.remains>execute_time)|debuff.colossus_smash.up|target.time_to_die<5
	if { Rage() > 60 or Enemies() == 2 } and SpellCooldown(colossus_smash) > ExecuteTime(execute_arms) or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 Spell(execute_arms)
	#dragon_roar,if=cooldown.colossus_smash.remains>1.5&!debuff.colossus_smash.up
	if SpellCooldown(colossus_smash) > 1.5 and not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)
	#whirlwind,if=cooldown.colossus_smash.remains>1.5&(target.health.pct>20|active_enemies>3)
	if SpellCooldown(colossus_smash) > 1.5 and { target.HealthPercent() > 20 or Enemies() > 3 } Spell(whirlwind)
	#rend,cycle_targets=1,if=!ticking&target.time_to_die>8
	if not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 8 Spell(rend)
	#bladestorm,if=cooldown.colossus_smash.remains>6&(!talent.ravager.enabled|cooldown.ravager.remains>6)
	if SpellCooldown(colossus_smash) > 6 and { not Talent(ravager_talent) or SpellCooldown(ravager) > 6 } Spell(bladestorm)
	#siegebreaker
	Spell(siegebreaker)
	#storm_bolt,if=cooldown.colossus_smash.remains>4|debuff.colossus_smash.up
	if SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#shockwave
	Spell(shockwave)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute_arms)
}

AddFunction ArmsSingleActions
{
	#rend,if=!ticking&target.time_to_die>4
	if not target.DebuffPresent(rend_debuff) and target.TimeToDie() > 4 Spell(rend)
	#ravager,if=cooldown.colossus_smash.remains<4
	if SpellCooldown(colossus_smash) < 4 Spell(ravager)
	#colossus_smash
	Spell(colossus_smash)
	#mortal_strike,if=target.health.pct>20&cooldown.colossus_smash.remains>1
	if target.HealthPercent() > 20 and SpellCooldown(colossus_smash) > 1 Spell(mortal_strike)
	#storm_bolt,if=(cooldown.colossus_smash.remains>4|debuff.colossus_smash.up)&rage<90
	if { SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) } and Rage() < 90 Spell(storm_bolt)
	#siegebreaker
	Spell(siegebreaker)
	#dragon_roar,if=!debuff.colossus_smash.up
	if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)
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
	#shockwave
	Spell(shockwave)
}

AddFunction ArmsMovementActions
{
	#heroic_leap
	if target.InRange(charge) Spell(heroic_leap)
	#storm_bolt
	Spell(storm_bolt)
	#heroic_throw
	Spell(heroic_throw)
}

AddIcon specialization=arms help=main enemies=1
{
	if not InCombat() ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=aoe
{
	if not InCombat() ArmsPrecombatActions()
	ArmsDefaultActions()
}

### Required symbols
# arcane_torrent_rage
# avatar
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
# dragon_roar
# execute_arms
# glyph_of_gag_order
# heroic_leap
# heroic_throw
# impending_victory
# mogu_power_potion
# mortal_strike
# pummel
# quaking_palm
# ravager
# ravager_talent
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
