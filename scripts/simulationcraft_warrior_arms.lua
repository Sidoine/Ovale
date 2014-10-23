local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Arms_T16M"
	local desc = "[6.0.2] SimulationCraft: Warrior_Arms_T16M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Arms_T16M".
#	class=warrior
#	spec=arms
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Za!020011.
#	glyphs=unending_rage/death_from_above/sweeping_strikes/resonating_power

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
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
	Spell(charge)
	#auto_attack
	#call_action_list,name=movement,if=movement.distance>8
	if 0 > 8 ArmsMovementActions()
	#potion,name=mogu_power,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=(target.time_to_die>190|target.health.pct<20)&(!talent.bloodbath.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)|buff.bloodbath.up)|target.time_to_die<=10
	if { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { not Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } or BuffPresent(bloodbath_buff) } or target.TimeToDie() <= 10 Spell(recklessness)
	#bloodbath,if=(active_enemies=1&cooldown.colossus_smash.remains<5)|target.time_to_die<=20
	if Enemies() == 1 and SpellCooldown(colossus_smash) < 5 or target.TimeToDie() <= 20 Spell(bloodbath)
	#avatar,if=buff.recklessness.up|target.time_to_die<=25
	if BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 Spell(avatar)
	#blood_fury,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up)|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#heroic_leap,if=debuff.colossus_smash.up&rage>70
	if target.DebuffPresent(colossus_smash_debuff) and Rage() > 70 and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#call_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeActions()
	#call_action_list,name=single,if=active_enemies=1
	if Enemies() == 1 ArmsSingleActions()
}

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#bladestorm
	Spell(bladestorm)
	#rend,if=active_enemies<=4&ticks_remain<2
	if Enemies() <= 4 and target.TicksRemaining(rend_debuff) < 2 Spell(rend)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#colossus_smash
	Spell(colossus_smash)
	#dragon_roar,if=!debuff.colossus_smash.up
	if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)
	#execute,if=active_enemies<=3&((rage>60&cooldown.colossus_smash.remains>execute_time)|debuff.colossus_smash.up|target.time_to_die<5)
	if Enemies() <= 3 and { Rage() > 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute) or target.DebuffPresent(colossus_smash_debuff) or target.TimeToDie() < 5 } Spell(execute)
	#whirlwind,if=active_enemies>=4|(active_enemies<=3&(rage>60|cooldown.colossus_smash.remains>execute_time)&target.health.pct>20)
	if Enemies() >= 4 or Enemies() <= 3 and { Rage() > 60 or SpellCooldown(colossus_smash) > ExecuteTime(whirlwind) } and target.HealthPercent() > 20 Spell(whirlwind)
	#bladestorm,interrupt_if=!cooldown.colossus_smash.remains|!cooldown.ravager.remains
	Spell(bladestorm)
	#rend,cycle_targets=1,if=!ticking
	if not target.DebuffPresent(rend_debuff) Spell(rend)
	#siegebreaker,if=active_enemies=2
	if Enemies() == 2 Spell(siegebreaker)
	#storm_bolt,if=cooldown.colossus_smash.remains>4|debuff.colossus_smash.up
	if SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#shockwave
	Spell(shockwave)
}

AddFunction ArmsSingleActions
{
	#rend,if=ticks_remain<2&target.time_to_die>4
	if target.TicksRemaining(rend_debuff) < 2 and target.TimeToDie() > 4 Spell(rend)
	#mortal_strike,if=target.health.pct>20
	if target.HealthPercent() > 20 Spell(mortal_strike)
	#ravager,if=cooldown.colossus_smash.remains<3
	if SpellCooldown(colossus_smash) < 3 Spell(ravager)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=(cooldown.colossus_smash.remains>4|debuff.colossus_smash.up)&rage<90
	if { SpellCooldown(colossus_smash) > 4 or target.DebuffPresent(colossus_smash_debuff) } and Rage() < 90 Spell(storm_bolt)
	#siegebreaker
	Spell(siegebreaker)
	#dragon_roar,if=!debuff.colossus_smash.up
	if not target.DebuffPresent(colossus_smash_debuff) Spell(dragon_roar)
	#execute,if=(rage>60&cooldown.colossus_smash.remains>execute_time)|debuff.colossus_smash.up|buff.sudden_death.react|target.time_to_die<5
	if Rage() > 60 and SpellCooldown(colossus_smash) > ExecuteTime(execute) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(sudden_death_buff) or target.TimeToDie() < 5 Spell(execute)
	#impending_victory,if=rage<30&!debuff.colossus_smash.up&target.health.pct>20
	if Rage() < 30 and not target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() > 20 and BuffPresent(victorious_buff) Spell(impending_victory)
	#slam,if=(rage>20|cooldown.colossus_smash.remains>execute_time)&target.health.pct>20
	if { Rage() > 20 or SpellCooldown(colossus_smash) > ExecuteTime(slam) } and target.HealthPercent() > 20 Spell(slam)
	#whirlwind,if=target.health.pct>20&!talent.slam.enabled&(rage>40|set_bonus.tier17_4pc)
	if target.HealthPercent() > 20 and not Talent(slam_talent) and { Rage() > 40 or ArmorSetBonus(T17 4) } Spell(whirlwind)
	#shockwave
	Spell(shockwave)
}

AddFunction ArmsMovementActions
{
	#heroic_leap
	if CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
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
# execute
# heroic_leap
# heroic_throw
# impending_victory
# mogu_power_potion
# mortal_strike
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
# victorious_buff
# whirlwind
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
