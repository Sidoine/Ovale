local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Fury_1h_T16M"
	local desc = "[6.0.2] SimulationCraft: Warrior_Fury_1h_T16M"
	local code = [[
# Based on SimulationCraft profile "Warrior_Fury_1h_T16M".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!011021.
#	glyphs=unending_rage/death_from_above/raging_wind

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction FurySingleMindedFuryPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#stance,choose=battle
	Spell(battle_stance)
	#snapshot_stats
	#potion,name=mogu_power
	UsePotionStrength()
}

AddFunction FurySingleMindedFuryDefaultActions
{
	#charge
	Spell(charge)
	#auto_attack
	#call_action_list,name=movement,if=movement.distance>5
	if 0 > 5 FurySingleMindedFuryMovementActions()
	#potion,name=mogu_power,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=((target.time_to_die>190|target.health.pct<20)&(buff.bloodbath.up|!talent.bloodbath.enabled))|target.time_to_die<=10|talent.anger_management.enabled
	if { target.TimeToDie() > 190 or target.HealthPercent() < 20 } and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } or target.TimeToDie() <= 10 or Talent(anger_management_talent) Spell(recklessness)
	#avatar,if=(buff.recklessness.up|target.time_to_die<=25)
	if BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 Spell(avatar)
	#berserker_rage,if=buff.enrage.down|(talent.unquenchable_thirst.enabled&buff.raging_blow.down)
	if BuffExpires(enrage_buff any=1) or Talent(unquenchable_thirst_talent) and BuffExpires(raging_blow_buff) Spell(berserker_rage)
	#blood_fury,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.bloodbath.up|!talent.bloodbath.enabled|buff.recklessness.up
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) or BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
	if { 0 > 25 and 0 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#call_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetActions()
	#call_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsActions()
	#call_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsActions()
	#call_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeActions()
}

AddFunction FurySingleMindedFuryAoeActions
{
	#bloodbath
	Spell(bloodbath)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#raging_blow,if=buff.meat_cleaver.stack>=3&buff.enrage.up
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(enrage_buff any=1) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack>=3
	if BuffStacks(meat_cleaver_buff) >= 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)
	#whirlwind
	Spell(whirlwind)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FurySingleMindedFuryTwoTargetsActions
{
	#bloodbath
	Spell(bloodbath)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)
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

AddFunction FurySingleMindedFurySingleTargetActions
{
	#bloodbath
	Spell(bloodbath)
	#wild_strike,if=rage>110&target.health.pct>20
	if Rage() > 110 and target.HealthPercent() > 20 Spell(wild_strike)
	#bloodthirst,if=!talent.unquenchable_thirst.enabled&(buff.enrage.down|rage<80)
	if not Talent(unquenchable_thirst_talent) and { BuffExpires(enrage_buff any=1) or Rage() < 80 } Spell(bloodthirst)
	#bloodthirst,if=talent.unquenchable_thirst.enabled&buff.enrage.down
	if Talent(unquenchable_thirst_talent) and BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#siegebreaker
	Spell(siegebreaker)
	#storm_bolt
	Spell(storm_bolt)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#execute,if=buff.enrage.up|target.time_to_die<12
	if BuffPresent(enrage_buff any=1) or target.TimeToDie() < 12 Spell(execute)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#wild_strike,if=buff.enrage.up&target.health.pct>20
	if BuffPresent(enrage_buff any=1) and target.HealthPercent() > 20 Spell(wild_strike)
	#shockwave,if=!talent.unquenchable_thirst.enabled
	if not Talent(unquenchable_thirst_talent) Spell(shockwave)
	#impending_victory,if=!talent.unquenchable_thirst.enabled&target.health.pct>20
	if not Talent(unquenchable_thirst_talent) and target.HealthPercent() > 20 and BuffPresent(victorious_buff) Spell(impending_victory)
	#bloodthirst
	Spell(bloodthirst)
}

AddFunction FurySingleMindedFuryThreeTargetsActions
{
	#bloodbath
	Spell(bloodbath)
	#ravager,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(ravager)
	#bladestorm,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) Spell(bladestorm)
	#bloodthirst,if=buff.enrage.down|rage<50|buff.raging_blow.down
	if BuffExpires(enrage_buff any=1) or Rage() < 50 or BuffExpires(raging_blow_buff) Spell(bloodthirst)
	#execute,if=buff.sudden_death.react
	if BuffPresent(sudden_death_buff) Spell(execute)
	#raging_blow,if=buff.meat_cleaver.stack>=2
	if BuffStacks(meat_cleaver_buff) >= 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#dragon_roar,if=buff.bloodbath.up|!talent.bloodbath.enabled
	if BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) Spell(dragon_roar)
	#whirlwind
	Spell(whirlwind)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
}

AddFunction FurySingleMindedFuryMovementActions
{
	#heroic_leap
	if CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#storm_bolt
	Spell(storm_bolt)
	#heroic_throw
	Spell(heroic_throw)
}

AddIcon specialization=fury help=main enemies=1
{
	if not InCombat() FurySingleMindedFuryPrecombatActions()
	FurySingleMindedFuryDefaultActions()
}

AddIcon specialization=fury help=aoe
{
	if not InCombat() FurySingleMindedFuryPrecombatActions()
	FurySingleMindedFuryDefaultActions()
}

### Required symbols
# anger_management_talent
# arcane_torrent_rage
# avatar
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
# dragon_roar
# execute
# heroic_leap
# heroic_throw
# impending_victory
# meat_cleaver_buff
# mogu_power_potion
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
# victorious_buff
# whirlwind
# wild_strike
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
