local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Warrior_Fury_1h_T16H"
	local desc = "[5.4] SimulationCraft: Warrior_Fury_1h_T16H"
	local code = [[
# Based on SimulationCraft profile "Warrior_Fury_1h_T16H".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!122212
#	glyphs=unending_rage/death_from_above/bull_rush

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)
AddCheckBox(opt_skull_banner SpellName(skull_banner) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction FuryPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
	#mogu_power_potion
	UsePotionStrength()
}

AddFunction FuryDefaultActions
{
	#auto_attack
	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if not Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if Talent(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff any=1) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) or BuffPresent(recklessness_buff) } and CheckBoxOn(opt_skull_banner) Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleTargetActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTwoTargetsActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryThreeTargetsActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryAoeActions()
}

AddFunction FuryAoeActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and not SpellCooldown(bladestorm) or not Talent(bladestorm_talent) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=rage>90
	if Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(bladestorm)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking&buff.enrage.down
	if not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack=3
	if BuffStacks(meat_cleaver_buff) == 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#dragon_roar,if=enabled&debuff.colossus_smash.down&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(dragon_roar)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled
	if Talent(storm_bolt_talent) Spell(storm_bolt)
	#shockwave,if=enabled
	if Talent(shockwave_talent) Spell(shockwave)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FuryTwoTargetsActions
{
	#bloodbath,if=enabled&((!talent.bladestorm.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20))|(talent.bladestorm.enabled))
	if Talent(bloodbath_talent) and { not Talent(bladestorm_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } or Talent(bladestorm_talent) } Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up)))|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and not SpellCooldown(bladestorm) and { not Talent(storm_bolt_talent) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } or not Talent(bladestorm_talent) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=60&debuff.colossus_smash.up)|rage>110
	if Rage() >= 60 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 110 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up))
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and { not Talent(storm_bolt_talent) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } Spell(bladestorm)
	#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(dragon_roar)
	#colossus_smash
	Spell(colossus_smash)
	#bloodthirst,cycle_targets=1,if=dot.deep_wounds.remains<5
	if target.DebuffRemaining(deep_wounds_debuff) < 5 Spell(bloodthirst)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#bloodthirst
	Spell(bloodthirst)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#raging_blow,if=buff.meat_cleaver.up
		if BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#whirlwind,if=!buff.meat_cleaver.up
		if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
		#shockwave,if=enabled
		if Talent(shockwave_talent) Spell(shockwave)
		#execute
		if BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 Spell(execute)
		#battle_shout
		Spell(battle_shout)
		#heroic_throw
		Spell(heroic_throw)
	}
}

AddFunction FurySingleTargetActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)
	#berserker_rage,if=buff.enrage.remains<1&cooldown.bloodthirst.remains>1
	if BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#heroic_strike,if=((debuff.colossus_smash.up&rage>=40)&target.health.pct>=20)|rage>=100&buff.enrage.up
	if target.DebuffPresent(colossus_smash_debuff) and Rage() >= 40 and target.HealthPercent() >= 20 or Rage() >= 100 and BuffPresent(enrage_buff any=1) Spell(heroic_strike)
	#heroic_leap,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#storm_bolt,if=enabled&buff.cooldown_reduction.up&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#raging_blow,if=buff.raging_blow.stack=2&debuff.colossus_smash.up&target.health.pct>=20
	if BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#storm_bolt,if=enabled&buff.cooldown_reduction.down&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#bloodthirst,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)
	if not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.react&target.health.pct>=20&cooldown.bloodthirst.remains<=1
	if BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 Spell(wild_strike)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
		if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(dragon_roar)
		#colossus_smash
		Spell(colossus_smash)
		#storm_bolt,if=enabled&buff.cooldown_reduction.down
		if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) Spell(storm_bolt)
		#execute,if=debuff.colossus_smash.up|rage>70|target.time_to_die<12
		if { target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
		#raging_blow,if=target.health.pct<20|buff.raging_blow.stack=2|(debuff.colossus_smash.up|(cooldown.bloodthirst.remains>=1&buff.raging_blow.remains<=3))
		if { target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(bloodthirst) >= 1 and BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#bladestorm,if=enabled
		if Talent(bladestorm_talent) Spell(bladestorm)
		#wild_strike,if=buff.bloodsurge.up
		if BuffPresent(bloodsurge_buff) Spell(wild_strike)
		#raging_blow,if=cooldown.colossus_smash.remains>=3
		if SpellCooldown(colossus_smash) >= 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#shattering_throw,if=cooldown.colossus_smash.remains>5
		if SpellCooldown(colossus_smash) > 5 Spell(shattering_throw)
		#shockwave,if=enabled
		if Talent(shockwave_talent) Spell(shockwave)
		#heroic_throw,if=debuff.colossus_smash.down&rage<60
		if target.DebuffExpires(colossus_smash_debuff) and Rage() < 60 Spell(heroic_throw)
		#battle_shout,if=rage<70&!debuff.colossus_smash.up
		if Rage() < 70 and not target.DebuffPresent(colossus_smash_debuff) Spell(battle_shout)
		#wild_strike,if=debuff.colossus_smash.up&target.health.pct>=20
		if target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 Spell(wild_strike)
		#battle_shout,if=rage<70
		if Rage() < 70 Spell(battle_shout)
		#wild_strike,if=cooldown.colossus_smash.remains>=2&rage>=70&target.health.pct>=20
		if SpellCooldown(colossus_smash) >= 2 and Rage() >= 70 and target.HealthPercent() >= 20 Spell(wild_strike)
		#impending_victory,if=enabled&target.health.pct>=20&cooldown.colossus_smash.remains>=2
		if Talent(impending_victory_talent) and target.HealthPercent() >= 20 and SpellCooldown(colossus_smash) >= 2 and BuffPresent(victorious_buff) Spell(impending_victory)
	}
}

AddFunction FuryThreeTargetsActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } and not SpellCooldown(bladestorm) or not Talent(bladestorm_talent) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=70&debuff.colossus_smash.up)|rage>90
	if Rage() >= 70 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(bladestorm)
	#dragon_roar,if=enabled&!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not Talent(bloodbath_talent) } Spell(dragon_roar)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#raging_blow,if=buff.meat_cleaver.stack=2
	if BuffStacks(meat_cleaver_buff) == 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#shockwave,if=enabled
	if Talent(shockwave_talent) Spell(shockwave)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#battle_shout
	Spell(battle_shout)
	#heroic_throw
	Spell(heroic_throw)
}

AddIcon specialization=fury help=main enemies=1
{
	if InCombat(no) FuryPrecombatActions()
	FuryDefaultActions()
}

AddIcon specialization=fury help=aoe
{
	if InCombat(no) FuryPrecombatActions()
	FuryDefaultActions()
}

### Required symbols
# arcane_torrent_rage
# avatar
# avatar_talent
# battle_shout
# battle_stance
# berserker_rage
# berserking
# bladestorm
# bladestorm_talent
# blood_fury_ap
# bloodbath
# bloodbath_buff
# bloodbath_talent
# bloodsurge_buff
# bloodthirst
# cleave
# colossus_smash
# colossus_smash_debuff
# cooldown_reduction_strength_buff
# death_sentence_buff
# deep_wounds_debuff
# dragon_roar
# dragon_roar_talent
# execute
# heroic_leap
# heroic_strike
# heroic_throw
# impending_victory
# impending_victory_talent
# meat_cleaver_buff
# mogu_power_potion
# raging_blow
# raging_blow_buff
# recklessness
# recklessness_buff
# shattering_throw
# shockwave
# shockwave_talent
# skull_banner
# storm_bolt
# storm_bolt_talent
# victorious_buff
# whirlwind
# wild_strike
]]
	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "reference")
end
