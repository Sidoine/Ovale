local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warrior"
	local desc = "[5.4] Ovale: Arms, Fury, Protection"
	local code = [[
# Ovale warrior script based on SimulationCraft.

Include(ovale_common)
Include(ovale_warrior_common)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Arms
###
# Based on SimulationCraft profile "Warrior_Arms_T16H".
#	class=warrior
#	spec=arms
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Za!122011
#	glyphs=unending_rage/death_from_above/sweeping_strikes/resonating_power

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#cleave,if=rage>110&active_enemies<=4
	if Rage() > { MaxRage() - 10 } and Enemies() <= 4 Spell(cleave)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } Spell(bladestorm)
	#dragon_roar,if=enabled&debuff.colossus_smash.down
	if TalentPoints(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
	#colossus_smash,if=debuff.colossus_smash.remains<1
	if target.DebuffRemains(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#thunder_clap,target=2,if=dot.deep_wounds.attack_power*1.1<stat.attack_power
	if target.DebuffAttackPower(deep_wounds_debuff) * 1.1 < AttackPower() Spell(thunder_clap)
	#mortal_strike,if=active_enemies=2|rage<50
	if Enemies() == 2 or Rage() < 50 Spell(mortal_strike)
	#execute,if=buff.sudden_execute.down&active_enemies=2
	if BuffExpires(sudden_execute_buff) and Enemies() == 2 Spell(execute usable=1)
	#slam,if=buff.sweeping_strikes.up&debuff.colossus_smash.up
	if BuffPresent(sweeping_strikes_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(slam)
	#overpower,if=active_enemies=2
	if Enemies() == 2 Spell(overpower)
	#slam,if=buff.sweeping_strikes.up
	if BuffPresent(sweeping_strikes_buff) Spell(slam)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsSingleTargetActions
{
	#heroic_strike,if=rage>115|(debuff.colossus_smash.up&rage>60&set_bonus.tier16_2pc_melee)
	if Rage() > { MaxRage() - 5 } or { target.DebuffPresent(colossus_smash_debuff) and Rage() > 60 and ArmorSetBonus(T16_melee 2) } Spell(heroic_strike)
	#mortal_strike,if=dot.deep_wounds.remains<1.0|buff.enrage.down|rage<10
	if target.DebuffRemains(deep_wounds_debuff) < 1 or BuffExpires(enrage_buff) or Rage() < 10 Spell(mortal_strike)
	#colossus_smash,if=debuff.colossus_smash.remains<1.0
	if target.DebuffRemains(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#mortal_strike
	Spell(mortal_strike)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#execute,if=buff.sudden_execute.down|buff.taste_for_blood.down|rage>90|target.time_to_die<12
	if BuffExpires(sudden_execute_buff) or BuffExpires(taste_for_blood_buff) or Rage() > 90 or target.TimeToDie() < 12 Spell(execute usable=1)
	#slam,if=target.health.pct>=20&(trinket.stacking_stat.crit.stack>=10|buff.recklessness.up)
	if target.HealthPercent() >= 20 and { BuffStacks(trinket_stacking_stat_crit_buff) >= 10 or BuffPresent(recklessness_buff) } Spell(slam)
	#overpower,if=target.health.pct>=20&rage<100|buff.sudden_execute.up
	if { target.HealthPercent() >= 20 and Rage() < { MaxRage() - 20 } } or BuffPresent(sudden_execute_buff) Spell(overpower)
	#execute
	Spell(execute usable=1)
	#slam,if=target.health.pct>=20
	if target.HealthPercent() >= 20 Spell(slam)
	#heroic_throw
	Spell(heroic_throw)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsSingleTargetShortCdActions
{
	unless { { Rage() > { MaxRage() - 5 } or { target.DebuffPresent(colossus_smash_debuff) and Rage() > 60 and ArmorSetBonus(T16_melee 2) } } and Spell(heroic_strike) }
		or { target.DebuffRemains(deep_wounds_debuff) < 1 or BuffExpires(enrage_buff) or Rage() < 10 and Spell(mortal_strike) }
		or { target.DebuffRemains(colossus_smash_debuff) < 1 and Spell(colossus_smash) }
	{
		#bladestorm,if=enabled,interrupt_if=!cooldown.colossus_smash.remains
		if TalentPoints(bladestorm_talent) Spell(bladestorm)

		unless Spell(mortal_strike)
			or { TalentPoints(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt) }
		{
			#dragon_roar,if=enabled&debuff.colossus_smash.down
			if TalentPoints(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
		}
	}
}

AddFunction ArmsDefaultActions
{
	#auto_attack
	#berserker_rage,if=buff.enrage.remains<0.5
	if BuffRemains(enrage_buff) < 0.5 Spell(berserker_rage)
	#run_action_list,name=aoe,if=active_enemies>=2
	#if Enemies() >= 2 ArmsAoeActions()
	#run_action_list,name=single_target,if=active_enemies<2
	#if Enemies() < 2 ArmsSingleTargetActions()
}

AddFunction ArmsDefaultShortCdActions
{
	#bloodbath,if=enabled&(debuff.colossus_smash.remains>0.1|cooldown.colossus_smash.remains<5|target.time_to_die<=20)
	if TalentPoints(bloodbath_talent) and { target.DebuffRemains(colossus_smash_debuff) > 0.1 or SpellCooldown(colossus_smash) < 5 or target.TimeToDie() <= 20 } Spell(bloodbath)

	unless { BuffRemains(enrage_buff) < 0.5 and Spell(berserker_rage) }
	{
		#heroic_leap,if=debuff.colossus_smash.up
		if target.DebuffPresent(colossus_smash_debuff) HeroicLeap()
	}
}

AddFunction ArmsDefaultCdActions
{
	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|buff.bloodlust.react|target.time_to_die<=25
	if { target.HealthPercent() < 20 and BuffPresent(recklessness_buff) } or BuffPresent(burst_haste any=1) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if not TalentPoints(bloodbath_talent) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > { 192 * BuffAmount(cooldown_reduction_strength_buff) } or target.HealthPercent() < 20 } } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > { 192 * BuffAmount(cooldown_reduction_strength_buff) } or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if TalentPoints(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff) and { { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) } or BuffPresent(recklessness_buff) } Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent)
}

AddFunction ArmsPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsPrecombatCdActions
{
	if Stance(warrior_battle_stance)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

### Arms icons.
AddCheckBox(opt_warrior_arms "Show Arms icons" specialization=arms default)

AddIcon specialization=arms size=small checkbox=opt_icons_left checkbox=opt_warrior_arms
{
	Spell(vigilance)
	Spell(demoralizing_banner)
	Spell(rallying_cry)
}

AddIcon specialization=arms size=small checkbox=opt_icons_left checkbox=opt_warrior_arms
{
	if TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(impending_victory usable=1)
	if not TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(victory_rush usable=1)
	if TalentPoints(enraged_regeneration_talent) Spell(enraged_regeneration)
}

AddIcon specialization=arms help=shortcd checkbox=opt_warrior_arms
{
	ArmsDefaultShortCdActions()
	ArmsSingleTargetShortCdActions()
}

AddIcon specialization=arms help=main checkbox=opt_warrior_arms
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
	ArmsSingleTargetActions()
}

AddIcon specialization=arms help=aoe checkbox=opt_aoe checkbox=opt_warrior_arms
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
	ArmsAoeActions()
}

AddIcon specialization=arms help=cd checkbox=opt_warrior_arms
{
	Interrupt()
	UseRacialInterruptActions()

	if InCombat(no) ArmsPrecombatCdActions()
	ArmsDefaultCdActions()
}

AddIcon specialization=arms size=small checkbox=opt_icons_right checkbox=opt_warrior_arms
{
	Spell(die_by_the_sword)
	Spell(shield_wall)
}

AddIcon specialization=arms size=small checkbox=opt_icons_right checkbox=opt_warrior_arms
{
	#shattering_throw,if=cooldown.colossus_smash.remains>5
	if target.DebuffExpires(shattering_throw_debuff) and SpellCooldown(colossus_smash) > 5 Spell(shattering_throw)

	UseItemActions()
}

###
### Fury
###
# Based on SimulationCraft profile "Warrior_Fury_1h_T16H".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!122212
#	glyphs=unending_rage/death_from_above/bull_rush

AddFunction FuryPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FuryPrecombatCdActions
{
	if Stance(warrior_battle_stance)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

AddFunction FuryDefaultCdActions
{
	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if { target.HealthPercent() < 20 and BuffPresent(recklessness_buff) } or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if not TalentPoints(bloodbath_talent) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > { 192 * BuffAmount(cooldown_reduction_strength_buff) } or target.HealthPercent() < 20 } } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > { 192 * BuffAmount(cooldown_reduction_strength_buff) } or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if TalentPoints(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff) and { { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) } or BuffPresent(recklessness_buff) } Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or { not TalentPoints(bloodbath_talent) and target.DebuffPresent(colossus_smash_debuff) } } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent)
}

AddFunction FuryTwoTargetsActions
{
	#bloodbath,if=enabled&((!talent.bladestorm.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20))|(talent.bladestorm.enabled))
	#if TalentPoints(bloodbath_talent) and { { not TalentPoints(bladestorm_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } } or { TalentPoints(bladestorm_talent) } } Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up)))|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if { TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } and not SpellCooldown(bladestorm) and { not TalentPoints(storm_bolt_talent) or { TalentPoints(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } } } or { not TalentPoints(bladestorm_talent) and BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 } Spell(berserker_rage)
	#cleave,if=(rage>=60&debuff.colossus_smash.up)|rage>110
	if { Rage() >= 60 and target.DebuffPresent(colossus_smash_debuff) } or Rage() > { MaxRage() - 10 } Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } HeroicLeap()
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up))
	if TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } and { not TalentPoints(storm_bolt_talent) or { TalentPoints(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } } Spell(bladestorm)
	#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
	if TalentPoints(dragon_roar_talent) and { not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } } Spell(dragon_roar)
	#colossus_smash
	Spell(colossus_smash)
	#bloodthirst,cycle_targets=1,if=dot.deep_wounds.remains<5
	if target.DebuffRemains(deep_wounds_debuff) < 5 Spell(bloodthirst)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#bloodthirst
	Spell(bloodthirst)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	if not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } Spell(bloodthirst wait=1)
	#raging_blow,if=buff.meat_cleaver.up
	if BuffPresent(meat_cleaver_buff) RagingBlow()
	#whirlwind,if=!buff.meat_cleaver.up
	if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
	#shockwave,if=enabled
	if TalentPoints(shockwave_talent) Spell(shockwave)
	#execute
	Spell(execute usable=1)
	#battle_shout
	Spell(battle_shout)
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FuryThreeTargetsActions
{
	#bloodbath,if=enabled
	#if TalentPoints(bloodbath_talent) Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if { TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } and not SpellCooldown(bladestorm) } or { not TalentPoints(bladestorm_talent) and BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 } Spell(berserker_rage)
	#cleave,if=(rage>=70&debuff.colossus_smash.up)|rage>90
	if { Rage() >= 70 and target.DebuffPresent(colossus_smash_debuff) } or Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } HeroicLeap()
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } Spell(bladestorm)
	#dragon_roar,if=enabled&!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if TalentPoints(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } Spell(dragon_roar)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#raging_blow,if=buff.meat_cleaver.stack=2
	if BuffStacks(meat_cleaver_buff) == 2 RagingBlow()
	#whirlwind
	Spell(whirlwind)
	#shockwave,if=enabled
	if TalentPoints(shockwave_talent) Spell(shockwave)
	#raging_blow
	RagingBlow()
	#battle_shout
	Spell(battle_shout)
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FuryAoeActions
{
	#bloodbath,if=enabled
	#if TalentPoints(bloodbath_talent) Spell(bloodbath)
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if { TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } and not SpellCooldown(bladestorm) } or { not TalentPoints(bladestorm_talent) and BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 } Spell(berserker_rage)
	#cleave,if=rage>90
	if Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up
	if BuffPresent(enrage_buff) HeroicLeap()
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if TalentPoints(bladestorm_talent) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } Spell(bladestorm)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking&buff.enrage.down
	if not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack=3
	if BuffStacks(meat_cleaver_buff) == 3 RagingBlow()
	#whirlwind
	Spell(whirlwind)
	#dragon_roar,if=enabled&debuff.colossus_smash.down&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if TalentPoints(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } Spell(dragon_roar)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled
	if TalentPoints(storm_bolt_talent) Spell(storm_bolt)
	#shockwave,if=enabled
	if TalentPoints(shockwave_talent) Spell(shockwave)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FuryOneHandSingleTargetActions
{
	#berserker_rage,if=buff.enrage.remains<1&cooldown.bloodthirst.remains>1
	if BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#heroic_leap,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) HeroicLeap()
	#storm_bolt,if=enabled&buff.cooldown_reduction.up&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#raging_blow,if=buff.raging_blow.stack=2&debuff.colossus_smash.up&target.health.pct>=20
	if BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 RagingBlow()
	#storm_bolt,if=enabled&buff.cooldown_reduction.down&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#bloodthirst,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)
	if not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.react&target.health.pct>=20&cooldown.bloodthirst.remains<=1
	if BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 Spell(wild_strike)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	if not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } Spell(bloodthirst wait=1)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled&buff.cooldown_reduction.down
	if TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) Spell(storm_bolt)
	#execute,if=debuff.colossus_smash.up|rage>70|target.time_to_die<12
	if target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 Spell(execute usable=1)
	#raging_blow,if=target.health.pct<20|buff.raging_blow.stack=2|(debuff.colossus_smash.up|(cooldown.bloodthirst.remains>=1&buff.raging_blow.remains<=3))
	if target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or { target.DebuffPresent(colossus_smash_debuff) or { SpellCooldown(bloodthirst) >= 1 and BuffRemains(raging_blow_buff) <= 3 } } RagingBlow()
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#raging_blow,if=cooldown.colossus_smash.remains>=3
	if SpellCooldown(colossus_smash) >= 3 RagingBlow()
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
	if TalentPoints(impending_victory_talent) and target.HealthPercent() >= 20 and SpellCooldown(colossus_smash) >= 2 Spell(impending_victory)
}

AddFunction FuryOneHandSingleTargetShortCdActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if TalentPoints(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)

	unless { BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 and Spell(berserker_rage) }
	{
		#heroic_strike,if=((debuff.colossus_smash.up&rage>=40)&target.health.pct>=20)|rage>=100&buff.enrage.up
		if { { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 40 } and target.HealthPercent() >= 20 } or Rage() >= { MaxRage() - 20 } and BuffPresent(enrage_buff) Spell(heroic_strike)

		unless { target.DebuffPresent(colossus_smash_debuff) and HeroicLeap() }
			or { TalentPoints(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt) }
			or { BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 and RagingBlow() }
			or { TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt) }
			or { BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 and Spell(wild_strike) }
			or { not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } and SpellCooldown(bloodthirst) <= 1 }
		{
			#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
			if TalentPoints(dragon_roar_talent) and { not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } } Spell(dragon_roar)

			unless Spell(colossus_smash)
				or { TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and Spell(storm_bolt) }
				or { { target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 } and Spell(execute usable=1) }
				or { { target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or { target.DebuffPresent(colossus_smash_debuff) or { SpellCooldown(bloodthirst) >= 1 and BuffRemains(raging_blow_buff) <= 3 } } } and RagingBlow() }
			{
				#bladestorm,if=enabled
				if TalentPoints(bladestorm_talent) Spell(bladestorm)

				unless { BuffPresent(bloodsurge_buff) and Spell(wild_strike) }
					or { SpellCooldown(colossus_smash) >= 3 and RagingBlow() }
				{
					#shockwave,if=enabled
					if TalentPoints(shockwave_talent) Spell(shockwave)
				}
			}
		}
	}
}

# Based on SimulationCraft profile "Warrior_Fury_2h_T16H".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!122012
#	glyphs=unending_rage/death_from_above/bull_rush

AddFunction FuryTwoHandSingleTargetActions
{
	#berserker_rage,if=buff.enrage.remains<1&cooldown.bloodthirst.remains>1
	if BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#heroic_leap,if=debuff.colossus_smash.up&buff.enrage.up
	if target.DebuffPresent(colossus_smash_debuff) and BuffPresent(enrage_buff) HeroicLeap()
	#bloodthirst,if=!buff.enrage.up
	if not BuffPresent(enrage_buff) Spell(bloodthirst)
	#storm_bolt,if=enabled&buff.cooldown_reduction.up&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#raging_blow,if=buff.raging_blow.stack=2&debuff.colossus_smash.up
	if BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) RagingBlow()
	#storm_bolt,if=enabled&buff.cooldown_reduction.down&debuff.colossus_smash.up
	if TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.react&cooldown.bloodthirst.remains<=1&cooldown.bloodthirst.remains>0.3
	if BuffPresent(bloodsurge_buff) and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0.3 Spell(wild_strike)
	#wait,sec=cooldown.bloodthirst.remains,if=!(debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	if not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } and SpellCooldown(bloodthirst) <= 1 Spell(bloodthirst wait=1)
	#colossus_smash
	Spell(colossus_smash)
	#storm_bolt,if=enabled&buff.cooldown_reduction.down
	if TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) Spell(storm_bolt)
	#execute,if=buff.raging_blow.stack<2&(((rage>70&!debuff.colossus_smash.up)|debuff.colossus_smash.up)|trinket.proc.strength.up)|target.time_to_die<5
	if BuffStacks(raging_blow_buff) < 2 and { { { Rage() > 70 and not target.DebuffPresent(colossus_smash_debuff) } or target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(trinket_proc_strength_buff) } or target.TimeToDie() < 5 Spell(execute usable=1)
	#berserker_rage,if=buff.raging_blow.stack<=1&target.health.pct>=20
	if BuffStacks(raging_blow_buff) <= 1 and target.HealthPercent() >= 20 Spell(berserker_rage)
	#raging_blow,if=buff.raging_blow.stack=2|debuff.colossus_smash.up|buff.raging_blow.remains<=3
	if BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or BuffRemains(raging_blow_buff) <= 3 RagingBlow()
	#raging_blow,if=cooldown.colossus_smash.remains>=1
	if SpellCooldown(colossus_smash) >= 1 RagingBlow()
	#wild_strike,if=buff.bloodsurge.up
	if BuffPresent(bloodsurge_buff) Spell(wild_strike)
	#heroic_throw,if=debuff.colossus_smash.down&rage<60
	if target.DebuffExpires(colossus_smash_debuff) and Rage() < 60 Spell(heroic_throw)
	#wild_strike,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) Spell(wild_strike)
	#battle_shout,if=rage<70
	if Rage() < 70 Spell(battle_shout)
	#impending_victory,if=enabled&cooldown.colossus_smash.remains>=1.5
	if TalentPoints(impending_victory_talent) and SpellCooldown(colossus_smash) >= 1.5 Spell(impending_victory)
	#wild_strike,if=cooldown.colossus_smash.remains>=2&rage>=70
	if SpellCooldown(colossus_smash) >= 2 and Rage() >= 70 Spell(wild_strike)
}

AddFunction FuryTwoHandSingleTargetShortCdActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if TalentPoints(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemains(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)

	unless { BuffRemains(enrage_buff) < 1 and SpellCooldown(bloodthirst) > 1 and Spell(berserker_rage) }
	{
		#heroic_strike,if=(debuff.colossus_smash.up&rage>=40|rage>=100)&buff.enrage.up
		if { { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 40 } or Rage() >= { MaxRage() - 20 } } and BuffPresent(enrage_buff) Spell(heroic_strike)

		unless { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(enrage_buff) and HeroicLeap() }
			or { not BuffPresent(enrage_buff) and Spell(bloodthirst) }
			or { TalentPoints(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt) }
			or { BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and RagingBlow() }
			or { TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt) }
		{
			#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
			if TalentPoints(dragon_roar_talent) and { not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or not TalentPoints(bloodbath_talent) } } Spell(dragon_roar)

			unless Spell(bloodthirst)
				or { BuffPresent(bloodsurge_buff) and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0.3 and Spell(wild_strike) }
				or { not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff) } and SpellCooldown(bloodthirst) <= 1 }
				or Spell(colossus_smash)
				or { TalentPoints(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and Spell(storm_bolt) }
				or { { BuffStacks(raging_blow_buff) < 2 and { { { Rage() > 70 and not target.DebuffPresent(colossus_smash_debuff) } or target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(trinket_proc_strength_buff) } or target.TimeToDie() < 5 } and Spell(execute usable=1) }
				or { BuffStacks(raging_blow_buff) <= 1 and target.HealthPercent() >= 20 and Spell(berserker_rage) }
				or { { BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or BuffRemains(raging_blow_buff) <= 3 } and RagingBlow() }
			{
				#bladestorm,if=enabled,interrupt_if=cooldown.bloodthirst.remains<1
				if TalentPoints(bladestorm_talent) Spell(bladestorm)

				unless { SpellCooldown(colossus_smash) >= 1 and RagingBlow() }
					or { BuffPresent(bloodsurge_buff) and Spell(wild_strike) }
				{
					#shockwave,if=enabled
					if TalentPoints(shockwave_talent) Spell(shockwave)
				}
			}
		}
	}
}

### Fury icons.
AddCheckBox(opt_warrior_fury "Show Fury icons" specialization=fury default)

AddIcon specialization=fury size=small checkbox=opt_icons_left checkbox=opt_warrior_fury
{
	Spell(vigilance)
	Spell(demoralizing_banner)
	Spell(rallying_cry)
}

AddIcon specialization=fury size=small checkbox=opt_icons_left checkbox=opt_warrior_fury
{
	if TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(impending_victory usable=1)
	if not TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(victory_rush usable=1)
	if TalentPoints(enraged_regeneration_talent) Spell(enraged_regeneration)
}

AddIcon specialization=fury help=shortcd checkbox=opt_warrior_fury
{
	if HasWeapon(main type=1h) FuryOneHandSingleTargetShortCdActions()
	if HasWeapon(main type=2h) FuryTwoHandSingleTargetShortCdActions()
}

AddIcon specialization=fury help=main checkbox=opt_warrior_fury
{
	if InCombat(no) FuryPrecombatActions()
	if HasWeapon(main type=1h) FuryOneHandSingleTargetActions()
	if HasWeapon(main type=2h) FuryTwoHandSingleTargetActions()
}

AddIcon specialization=fury help=aoe checkbox=opt_aoe checkbox=opt_warrior_fury
{
	if InCombat(no) FuryPrecombatActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() <= 2 FuryTwoTargetsActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryThreeTargetsActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryAoeActions()
}

AddIcon specialization=fury help=cd checkbox=opt_warrior_fury
{
	Interrupt()
	UseRacialInterruptActions()

	if InCombat(no) FuryPrecombatCdActions()
	FuryDefaultCdActions()
}

AddIcon specialization=fury size=small checkbox=opt_icons_right checkbox=opt_warrior_fury
{
	Spell(die_by_the_sword)
	Spell(shield_wall)
}

AddIcon specialization=fury size=small checkbox=opt_icons_right checkbox=opt_warrior_fury
{
	#shattering_throw,if=cooldown.colossus_smash.remains>5
	if target.DebuffExpires(shattering_throw_debuff) and SpellCooldown(colossus_smash) > 5 Spell(shattering_throw)

	UseItemActions()
}

###
### Protection
###
# Based on SimulationCraft profile "Warrior_Protection_T16H".
#	class=warrior
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Zb!.00110
#	glyphs=unending_rage/hold_the_line/heavy_repercussions

AddFunction ProtectionDpsCdsActions
{
	#avatar,if=enabled
	if TalentPoints(avatar_talent) Spell(avatar)
	#bloodbath,if=enabled
	if TalentPoints(bloodbath_talent) Spell(bloodbath)
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent)
	#dragon_roar,if=enabled
	if TalentPoints(dragon_roar_talent) Spell(dragon_roar)
	#shattering_throw
	Spell(shattering_throw)
	#skull_banner
	Spell(skull_banner)
	#recklessness
	Spell(recklessness)
	#storm_bolt,if=enabled
	if TalentPoints(storm_bolt_talent) Spell(storm_bolt)
	#shockwave,if=enabled
	if TalentPoints(shockwave_talent) Spell(shockwave)
	#bladestorm,if=enabled
	if TalentPoints(bladestorm_talent) Spell(bladestorm)
}

AddFunction ProtectionNormalRotationActions
{
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#battle_shout,if=rage<=rage.max-20
	if Rage() <= MaxRage() -20 Spell(battle_shout)
	#thunder_clap,if=glyph.resonating_power.enabled|target.debuff.weakened_blows.down
	if Glyph(glyph_of_resonating_power) or target.DebuffExpires(weakened_blows_debuff) Spell(thunder_clap)
	#demoralizing_shout
	Spell(demoralizing_shout)
	#impending_victory,if=enabled
	if TalentPoints(impending_victory_talent) Spell(impending_victory)
	#victory_rush,if=!talent.impending_victory.enabled
	if not TalentPoints(impending_victory_talent) Spell(victory_rush)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#berserker_rage,if=buff.enrage.down&rage<=rage.max-10
	if BuffExpires(enrage_buff) and Rage() <= MaxRage() -10 Spell(berserker_rage)
}

AddFunction ProtectionDefaultShortCdActions
{
	#auto_attack
	#heroic_strike,if=buff.ultimatum.up|buff.glyph_incite.up
	if BuffPresent(ultimatum_buff) or BuffPresent(glyph_incite_buff) Spell(heroic_strike)
	#shield_block
	Spell(shield_block)
	#shield_barrier,if=incoming_damage_1500ms>health.max*0.3|rage>rage.max-20
	if IncomingDamage(1.500) > MaxHealth() * 0.3 or Rage() > MaxRage() -20 Spell(shield_barrier)
}

AddFunction ProtectionDefaultCdActions
{
	#mountains_potion,if=incoming_damage_2500ms>health.max*0.6&(buff.shield_wall.down&buff.last_stand.down)
	if IncomingDamage(2.500) > MaxHealth() * 0.6 and { BuffExpires(shield_wall_buff) and BuffExpires(last_stand_buff) } Spell(mountains_potion)
	#shield_wall,if=incoming_damage_2500ms>health.max*0.6
	if IncomingDamage(2.500) > MaxHealth() * 0.6 Spell(shield_wall)
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsActions()
}

AddFunction ProtectionAoeActions
{
	if BuffPresent(ultimatum_buff) or BuffPresent(glyph_incite_buff) Spell(cleave)
	ProtectionDefaultActions()
	Spell(thunder_clap)
	ProtectionNormalRotationActions()
}

AddFunction ProtectionPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#snapshot_stats
	#stance,choose=defensive
	if not Stance(warrior_defensive_stance) Spell(defensive_stance)
	#battle_shout
	Spell(battle_shout)
}

### Protection icons.
AddCheckBox(opt_warrior_protection "Show Protection icons" specialization=protection default)

AddIcon specialization=protection size=small checkbox=opt_icons_left checkbox=opt_warrior_protection
{
	Spell(vigilance)
	Spell(demoralizing_banner)
	Spell(rallying_cry)
}

AddIcon specialization=protection size=small checkbox=opt_icons_left checkbox=opt_warrior_protection
{
	if TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(impending_victory usable=1)
	if not TalentPoints(impending_victory_talent) and HealthPercent() < 80 Spell(victory_rush usable=1)
	if TalentPoints(enraged_regeneration_talent) Spell(enraged_regeneration)
}

AddIcon specialization=protection help=shortcd checkbox=opt_warrior_protection
{
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=main checkbox=opt_warrior_protection
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
	ProtectionNormalRotationActions()
}

AddIcon specialization=protection help=aoe checkbox=opt_aoe checkbox=opt_warrior_protection
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionAoeActions()
}

AddIcon specialization=protection help=cd checkbox=opt_warrior_protection
{
	Interrupt()
	UseRacialInterruptActions()
	ProtectionDefaultCdActions()
}

AddIcon specialization=protection size=small checkbox=opt_icons_right checkbox=opt_warrior_protection
{
	Spell(die_by_the_sword)
	Spell(shield_wall)
}

AddIcon specialization=protection size=small checkbox=opt_icons_right checkbox=opt_warrior_protection
{
	#shattering_throw
	if target.DebuffExpires(shattering_throw_debuff) Spell(shattering_throw)

	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("WARRIOR", "Ovale", desc, code, "script")
end
