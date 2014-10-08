local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warrior"
	local desc = "[5.4.8] Ovale: Arms, Fury, Protection"
	local code = [[
# Ovale warrior script based on SimulationCraft.

Include(ovale_common)
Include(ovale_warrior_spells)

AddCheckBox(opt_potion_armor ItemName(mountains_potion) default specialization=protection)
AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default specialization=!protection)
AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)
AddCheckBox(opt_skull_banner SpellName(skull_banner) default)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(mountains_potion usable=1)
}

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

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(pummel) Spell(pummel)
		if Glyph(glyph_of_gag_order) and target.InRange(heroic_throw) Spell(heroic_throw)
		Spell(disrupting_shout)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_rage)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Arms
###
# Based on SimulationCraft profile "Warrior_Arms_T16H".
#	class=warrior
#	spec=arms
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Za!122011
#	glyphs=unending_rage/death_from_above/sweeping_strikes/resonating_power

# ActionList: ArmsPrecombatActions --> main, offgcd, shortcd, cd

AddFunction ArmsPrecombatActions
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

AddFunction ArmsPrecombatOffGcdActions {}

AddFunction ArmsPrecombatShortCdActions {}

AddFunction ArmsPrecombatCdActions
{
	unless not Stance(warrior_battle_stance) and Spell(battle_stance)
		or Spell(battle_shout)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

# ActionList: ArmsDefaultActions --> main, offgcd, shortcd, cd

AddFunction ArmsDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 ArmsSingleTargetActions()
}

AddFunction ArmsDefaultOffGcdActions
{
	#berserker_rage,if=buff.enrage.remains<0.5
	if BuffRemaining(enrage_buff any=1) < 0.5 Spell(berserker_rage)
	#heroic_leap,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeOffGcdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 ArmsSingleTargetOffGcdActions()
}

AddFunction ArmsDefaultShortCdActions
{
	#bloodbath,if=enabled&(debuff.colossus_smash.remains>0.1|cooldown.colossus_smash.remains<5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { target.DebuffRemaining(colossus_smash_debuff) > 0.1 or SpellCooldown(colossus_smash) < 5 or target.TimeToDie() <= 20 } Spell(bloodbath)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 ArmsSingleTargetShortCdActions()
}

AddFunction ArmsDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|buff.bloodlust.react|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if Talent(bloodbath_talent no) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if Talent(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff any=1) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) or BuffPresent(recklessness_buff) } and CheckBoxOn(opt_skull_banner) Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 ArmsAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 ArmsSingleTargetCdActions()
}

# ActionList: ArmsAoeActions --> main, offgcd, shortcd, cd

AddFunction ArmsAoeActions
{
	#sweeping_strikes
	Spell(sweeping_strikes)
	#colossus_smash,if=debuff.colossus_smash.remains<1
	if target.DebuffRemaining(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#thunder_clap,target=2,if=dot.deep_wounds.attack_power*1.1<stat.attack_power
	if target.DebuffAttackPower(deep_wounds_debuff) * 1.1 < AttackPower() Spell(thunder_clap)
	#mortal_strike,if=active_enemies=2|rage<50
	if Enemies() == 2 or Rage() < 50 Spell(mortal_strike)
	#execute,if=buff.sudden_execute.down&active_enemies=2
	if BuffExpires(sudden_execute_buff) and Enemies() == 2 and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
	#slam,if=buff.sweeping_strikes.up&debuff.colossus_smash.up
	if BuffPresent(sweeping_strikes_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(slam)
	#overpower,if=active_enemies=2
	if Enemies() == 2 Spell(overpower)
	#slam,if=buff.sweeping_strikes.up
	if BuffPresent(sweeping_strikes_buff) Spell(slam)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsAoeOffGcdActions
{
	#cleave,if=rage>110&active_enemies<=4
	if Rage() > 110 and Enemies() <= 4 Spell(cleave)
}

AddFunction ArmsAoeShortCdActions
{
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(bladestorm)
	#dragon_roar,if=enabled&debuff.colossus_smash.down
	if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
}

AddFunction ArmsAoeCdActions {}

# ActionList: ArmsSingleTargetActions --> main, offgcd, shortcd, cd

AddFunction ArmsSingleTargetActions
{
	#mortal_strike,if=dot.deep_wounds.remains<1.0|buff.enrage.down|rage<10
	if target.DebuffRemaining(deep_wounds_debuff) < 1 or BuffExpires(enrage_buff any=1) or Rage() < 10 Spell(mortal_strike)
	#colossus_smash,if=debuff.colossus_smash.remains<1.0
	if target.DebuffRemaining(colossus_smash_debuff) < 1 Spell(colossus_smash)
	#mortal_strike
	Spell(mortal_strike)
	#execute,if=buff.sudden_execute.down|buff.taste_for_blood.down|rage>90|target.time_to_die<12
	if { BuffExpires(sudden_execute_buff) or BuffExpires(taste_for_blood_buff) or Rage() > 90 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
	#slam,if=target.health.pct>=20&(trinket.stacking_stat.crit.stack>=10|buff.recklessness.up)
	if target.HealthPercent() >= 20 and { BuffStacks(trinket_stacking_stat_crit_buff) >= 10 or BuffPresent(recklessness_buff) } Spell(slam)
	#overpower,if=target.health.pct>=20&rage<100|buff.sudden_execute.up
	if target.HealthPercent() >= 20 and Rage() < 100 or BuffPresent(sudden_execute_buff) Spell(overpower)
	#execute
	if BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 Spell(execute)
	#slam,if=target.health.pct>=20
	if target.HealthPercent() >= 20 Spell(slam)
	#heroic_throw
	Spell(heroic_throw)
	#battle_shout
	Spell(battle_shout)
}

AddFunction ArmsSingleTargetOffGcdActions
{
	#heroic_strike,if=rage>115|(debuff.colossus_smash.up&rage>60&set_bonus.tier16_2pc_melee)
	if Rage() > 115 or target.DebuffPresent(colossus_smash_debuff) and Rage() > 60 and ArmorSetBonus(T16_melee 2) Spell(heroic_strike)
}

AddFunction ArmsSingleTargetShortCdActions
{
	unless target.DebuffRemaining(deep_wounds_debuff) < 1 or BuffExpires(enrage_buff any=1) or Rage() < 10 and Spell(mortal_strike)
		or target.DebuffRemaining(colossus_smash_debuff) < 1 and Spell(colossus_smash)
	{
		#bladestorm,if=enabled,interrupt_if=!cooldown.colossus_smash.remains
		if Talent(bladestorm_talent) Spell(bladestorm)

		unless Spell(mortal_strike)
		{
			#storm_bolt,if=enabled&debuff.colossus_smash.up
			if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
			#dragon_roar,if=enabled&debuff.colossus_smash.down
			if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) Spell(dragon_roar)
		}
	}
}

AddFunction ArmsSingleTargetCdActions {}

### Arms icons.
AddCheckBox(opt_warrior_arms "Show Arms icons" specialization=arms default)
AddCheckBox(opt_warrior_arms_aoe L(AOE) specialization=arms default)

AddIcon specialization=arms size=small help=offgcd enemies=1 checkbox=opt_warrior_arms checkbox=!opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatOffGcdActions()
	ArmsDefaultOffGcdActions()
}

AddIcon specialization=arms size=small help=offgcd checkbox=opt_warrior_arms checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatOffGcdActions()
	ArmsDefaultOffGcdActions()
}

AddIcon specialization=arms help=shortcd enemies=1 checkbox=opt_warrior_arms checkbox=!opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatShortCdActions()
	ArmsDefaultShortCdActions()
}

AddIcon specialization=arms help=shortcd checkbox=opt_warrior_arms checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatShortCdActions()
	ArmsDefaultShortCdActions()
}

AddIcon specialization=arms help=main enemies=1 checkbox=opt_warrior_arms
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=aoe checkbox=opt_warrior_arms checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatActions()
	ArmsDefaultActions()
}

AddIcon specialization=arms help=cd enemies=1 checkbox=opt_warrior_arms checkbox=!opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatCdActions()
	ArmsDefaultCdActions()
}

AddIcon specialization=arms help=cd checkbox=opt_warrior_arms checkbox=opt_warrior_arms_aoe
{
	if InCombat(no) ArmsPrecombatCdActions()
	ArmsDefaultCdActions()
}

###
### Fury
###
# Based on SimulationCraft profile "Warrior_Fury_1h_T16H".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!122212
#	glyphs=unending_rage/death_from_above/bull_rush

# ActionList: FurySingleMindedFuryPrecombatActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFuryPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FurySingleMindedFuryPrecombatOffGcdActions {}

AddFunction FurySingleMindedFuryPrecombatShortCdActions {}

AddFunction FurySingleMindedFuryPrecombatCdActions
{
	unless not Stance(warrior_battle_stance) and Spell(battle_stance)
		or Spell(battle_shout)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

# ActionList: FurySingleMindedFuryDefaultActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFuryDefaultActions
{
	#auto_attack
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeActions()
}

AddFunction FurySingleMindedFuryDefaultOffGcdActions
{
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetOffGcdActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsOffGcdActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsOffGcdActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeOffGcdActions()
}

AddFunction FurySingleMindedFuryDefaultShortCdActions
{
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetShortCdActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsShortCdActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsShortCdActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeShortCdActions()
}

AddFunction FurySingleMindedFuryDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if Talent(bloodbath_talent no) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if Talent(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff any=1) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) or BuffPresent(recklessness_buff) } and CheckBoxOn(opt_skull_banner) Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FurySingleMindedFurySingleTargetCdActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FurySingleMindedFuryTwoTargetsCdActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FurySingleMindedFuryThreeTargetsCdActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FurySingleMindedFuryAoeCdActions()
}

# ActionList: FurySingleMindedFuryAoeActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFuryAoeActions
{
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking&buff.enrage.down
	if not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack=3
	if BuffStacks(meat_cleaver_buff) == 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FurySingleMindedFuryAoeOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=rage>90
	if Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FurySingleMindedFuryAoeShortCdActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(bladestorm)
	
	unless not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff any=1) and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) == 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or Spell(whirlwind)
	{
		#dragon_roar,if=enabled&debuff.colossus_smash.down&(buff.bloodbath.up|!talent.bloodbath.enabled)
		if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

		unless not target.DebuffPresent(deep_wounds_debuff) and Spell(bloodthirst)
			or Spell(colossus_smash)
		{
			#storm_bolt,if=enabled
			if Talent(storm_bolt_talent) Spell(storm_bolt)
			#shockwave,if=enabled
			if Talent(shockwave_talent) Spell(shockwave)
		}
	}
}

AddFunction FurySingleMindedFuryAoeCdActions {}

# ActionList: FurySingleMindedFuryTwoTargetsActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFuryTwoTargetsActions
{
	#colossus_smash
	Spell(colossus_smash)
	#bloodthirst,cycle_targets=1,if=dot.deep_wounds.remains<5
	if target.DebuffRemaining(deep_wounds_debuff) < 5 Spell(bloodthirst)
	#bloodthirst
	Spell(bloodthirst)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#raging_blow,if=buff.meat_cleaver.up
		if BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#whirlwind,if=!buff.meat_cleaver.up
		if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
		#execute
		if BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 Spell(execute)
		#battle_shout
		Spell(battle_shout)
		#heroic_throw
		Spell(heroic_throw)
	}
}

AddFunction FurySingleMindedFuryTwoTargetsOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up)))|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) and { Talent(storm_bolt_talent no) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=60&debuff.colossus_smash.up)|rage>110
	if Rage() >= 60 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 110 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FurySingleMindedFuryTwoTargetsShortCdActions
{
	#bloodbath,if=enabled&((!talent.bladestorm.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20))|(talent.bladestorm.enabled))
	if Talent(bloodbath_talent) and { Talent(bladestorm_talent no) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } or Talent(bladestorm_talent) } Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up))
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and { Talent(storm_bolt_talent no) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } Spell(bladestorm)
	#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

	unless Spell(colossus_smash)
		or target.DebuffRemaining(deep_wounds_debuff) < 5 and Spell(bloodthirst)
	{
		#storm_bolt,if=enabled&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless Spell(bloodthirst)
		{
			#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
			unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
			{
				unless BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
					or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind)
				{
					#shockwave,if=enabled
					if Talent(shockwave_talent) Spell(shockwave)
				}
			}
		}
	}
}

AddFunction FurySingleMindedFuryTwoTargetsCdActions {}

# ActionList: FurySingleMindedFurySingleTargetActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFurySingleTargetActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)
	#raging_blow,if=buff.raging_blow.stack=2&debuff.colossus_smash.up&target.health.pct>=20
	if BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bloodthirst,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)
	if not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.react&target.health.pct>=20&cooldown.bloodthirst.remains<=1
	if BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 Spell(wild_strike)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#colossus_smash
		Spell(colossus_smash)
		#execute,if=debuff.colossus_smash.up|rage>70|target.time_to_die<12
		if { target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
		#raging_blow,if=target.health.pct<20|buff.raging_blow.stack=2|(debuff.colossus_smash.up|(cooldown.bloodthirst.remains>=1&buff.raging_blow.remains<=3))
		if { target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(bloodthirst) >= 1 and BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#wild_strike,if=buff.bloodsurge.up
		if BuffPresent(bloodsurge_buff) Spell(wild_strike)
		#raging_blow,if=cooldown.colossus_smash.remains>=3
		if SpellCooldown(colossus_smash) >= 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
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

AddFunction FurySingleMindedFurySingleTargetOffGcdActions
{
	#berserker_rage,if=buff.enrage.remains<1&cooldown.bloodthirst.remains>1
	if BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#heroic_strike,if=((debuff.colossus_smash.up&rage>=40)&target.health.pct>=20)|rage>=100&buff.enrage.up
	if target.DebuffPresent(colossus_smash_debuff) and Rage() >= 40 and target.HealthPercent() >= 20 or Rage() >= 100 and BuffPresent(enrage_buff any=1) Spell(heroic_strike)
	#heroic_leap,if=debuff.colossus_smash.up
	if target.DebuffPresent(colossus_smash_debuff) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FurySingleMindedFurySingleTargetShortCdActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)
	#storm_bolt,if=enabled&buff.cooldown_reduction.up&debuff.colossus_smash.up
	if Talent(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

	unless BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
	{
		#storm_bolt,if=enabled&buff.cooldown_reduction.down&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and Spell(bloodthirst)
			or BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 and Spell(wild_strike)
		{
			#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
			unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
			{
				#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
				if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

				unless Spell(colossus_smash)
				{
					#storm_bolt,if=enabled&buff.cooldown_reduction.down
					if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) Spell(storm_bolt)

					unless { target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } and Spell(execute)
						or { target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(bloodthirst) >= 1 and BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) and Spell(raging_blow)
					{
						#bladestorm,if=enabled
						if Talent(bladestorm_talent) Spell(bladestorm)

						unless BuffPresent(bloodsurge_buff) and Spell(wild_strike)
							or SpellCooldown(colossus_smash) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
						{
							#shockwave,if=enabled
							if Talent(shockwave_talent) Spell(shockwave)
						}
					}
				}
			}
		}
	}
}

AddFunction FurySingleMindedFurySingleTargetCdActions
{
	unless Talent(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt)
		or BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and target.HealthPercent() >= 20 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt)
		or not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and Spell(bloodthirst)
		or BuffPresent(bloodsurge_buff) and target.HealthPercent() >= 20 and SpellCooldown(bloodthirst) <= 1 and Spell(wild_strike)
	{
		#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
		unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
		{
			unless Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and Spell(dragon_roar)
				or Spell(colossus_smash)
				or Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and Spell(storm_bolt)
				or { target.DebuffPresent(colossus_smash_debuff) or Rage() > 70 or target.TimeToDie() < 12 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } and Spell(execute)
				or { target.HealthPercent() < 20 or BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or SpellCooldown(bloodthirst) >= 1 and BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) and Spell(raging_blow)
				or Talent(bladestorm_talent) and Spell(bladestorm)
				or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
				or SpellCooldown(colossus_smash) >= 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
			{
				#shattering_throw,if=cooldown.colossus_smash.remains>5
				if SpellCooldown(colossus_smash) > 5 Spell(shattering_throw)
			}
		}
	}
}

# ActionList: FurySingleMindedFuryThreeTargetsActions --> main, offgcd, shortcd, cd

AddFunction FurySingleMindedFuryThreeTargetsActions
{
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#raging_blow,if=buff.meat_cleaver.stack=2
	if BuffStacks(meat_cleaver_buff) == 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#battle_shout
	Spell(battle_shout)
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FurySingleMindedFuryThreeTargetsOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=70&debuff.colossus_smash.up)|rage>90
	if Rage() >= 70 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FurySingleMindedFuryThreeTargetsShortCdActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(bladestorm)
	#dragon_roar,if=enabled&!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

	unless not target.DebuffPresent(deep_wounds_debuff) and Spell(bloodthirst)
		or Spell(colossus_smash)
	{
		#storm_bolt,if=enabled&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless BuffStacks(meat_cleaver_buff) == 2 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
			or Spell(whirlwind)
		{
			#shockwave,if=enabled
			if Talent(shockwave_talent) Spell(shockwave)
		}
	}
}

AddFunction FurySingleMindedFuryThreeTargetsCdActions {}

# Based on SimulationCraft profile "Warrior_Fury_2h_T16H".
#	class=warrior
#	spec=fury
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ZZ!122012
#	glyphs=unending_rage/death_from_above/bull_rush

# ActionList: FuryTitansGripPrecombatActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripPrecombatActions
{
	#elixir,type=mad_hozen
	#food,type=black_pepper_ribs_and_shrimp
	#snapshot_stats
	#stance,choose=battle
	if not Stance(warrior_battle_stance) Spell(battle_stance)
	#battle_shout
	Spell(battle_shout)
	#mogu_power_potion
	UsePotionStrength()
}

AddFunction FuryTitansGripPrecombatOffGcdActions {}

AddFunction FuryTitansGripPrecombatShortCdActions {}

AddFunction FuryTitansGripPrecombatCdActions
{
	unless not Stance(warrior_battle_stance) and Spell(battle_stance)
		or Spell(battle_shout)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

# ActionList: FuryTitansGripDefaultActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripDefaultActions
{
	#auto_attack
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeActions()
}

AddFunction FuryTitansGripDefaultOffGcdActions
{
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetOffGcdActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsOffGcdActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsOffGcdActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeOffGcdActions()
}

AddFunction FuryTitansGripDefaultShortCdActions
{
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetShortCdActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsShortCdActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsShortCdActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeShortCdActions()
}

AddFunction FuryTitansGripDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#mogu_power_potion,if=(target.health.pct<20&buff.recklessness.up)|target.time_to_die<=25
	if target.HealthPercent() < 20 and BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 UsePotionStrength()
	#recklessness,if=!talent.bloodbath.enabled&((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20))|buff.bloodbath.up&(target.time_to_die>(192*buff.cooldown_reduction.value)|target.health.pct<20)|target.time_to_die<=12
	if Talent(bloodbath_talent no) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or BuffPresent(bloodbath_buff) and { target.TimeToDie() > 192 * BuffAmount(cooldown_reduction_strength_buff) or target.HealthPercent() < 20 } or target.TimeToDie() <= 12 Spell(recklessness)
	#avatar,if=enabled&(buff.recklessness.up|target.time_to_die<=25)
	if Talent(avatar_talent) and { BuffPresent(recklessness_buff) or target.TimeToDie() <= 25 } Spell(avatar)
	#skull_banner,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)
	if BuffExpires(skull_banner_buff any=1) and { { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 } and target.TimeToDie() > 192 and BuffPresent(cooldown_reduction_strength_buff) or BuffPresent(recklessness_buff) } and CheckBoxOn(opt_skull_banner) Spell(skull_banner)
	#use_item,slot=hands,if=!talent.bloodbath.enabled&debuff.colossus_smash.up|buff.bloodbath.up
	if Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) or BuffPresent(bloodbath_buff) UseItemActions()
	#blood_fury,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(blood_fury_ap)
	#berserking,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(berserking)
	#arcane_torrent,if=buff.cooldown_reduction.down&(buff.bloodbath.up|(!talent.bloodbath.enabled&debuff.colossus_smash.up))|buff.cooldown_reduction.up&buff.recklessness.up
	if BuffExpires(cooldown_reduction_strength_buff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) and target.DebuffPresent(colossus_smash_debuff) } or BuffPresent(cooldown_reduction_strength_buff) and BuffPresent(recklessness_buff) Spell(arcane_torrent_rage)
	#run_action_list,name=single_target,if=active_enemies=1
	if Enemies() == 1 FuryTitansGripSingleTargetActions()
	#run_action_list,name=two_targets,if=active_enemies=2
	if Enemies() == 2 FuryTitansGripTwoTargetsActions()
	#run_action_list,name=three_targets,if=active_enemies=3
	if Enemies() == 3 FuryTitansGripThreeTargetsActions()
	#run_action_list,name=aoe,if=active_enemies>3
	if Enemies() > 3 FuryTitansGripAoeActions()
}

# ActionList: FuryTitansGripDefaultActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripAoeActions
{
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking&buff.enrage.down
	if not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff any=1) Spell(bloodthirst)
	#raging_blow,if=buff.meat_cleaver.stack=3
	if BuffStacks(meat_cleaver_buff) == 3 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#battle_shout
	Spell(battle_shout)
}

AddFunction FuryTitansGripAoeOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=rage>90
	if Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up
	if BuffPresent(enrage_buff any=1) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FuryTitansGripAoeShortCdActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(bladestorm)

	unless not target.DebuffPresent(deep_wounds_debuff) and BuffExpires(enrage_buff any=1) and Spell(bloodthirst)
		or BuffStacks(meat_cleaver_buff) == 3 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or Spell(whirlwind)
	{
		#dragon_roar,if=enabled&debuff.colossus_smash.down&(buff.bloodbath.up|!talent.bloodbath.enabled)
		if Talent(dragon_roar_talent) and target.DebuffExpires(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

		unless not target.DebuffPresent(deep_wounds_debuff) and Spell(bloodthirst)
			or Spell(colossus_smash)
		{
			#storm_bolt,if=enabled
			if Talent(storm_bolt_talent) Spell(storm_bolt)
			#shockwave,if=enabled
			if Talent(shockwave_talent) Spell(shockwave)
		}
	}
}

AddFunction FuryTitansGripAoeCdActions {}

# ActionList: FuryTitansGripTwoTargetsActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripTwoTargetsActions
{
	#colossus_smash
	Spell(colossus_smash)
	#bloodthirst,cycle_targets=1,if=dot.deep_wounds.remains<5
	if target.DebuffRemaining(deep_wounds_debuff) < 5 Spell(bloodthirst)
	#bloodthirst
	Spell(bloodthirst)
	#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#raging_blow,if=buff.meat_cleaver.up
		if BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#whirlwind,if=!buff.meat_cleaver.up
		if not BuffPresent(meat_cleaver_buff) Spell(whirlwind)
		#execute
		if BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 Spell(execute)
		#battle_shout
		Spell(battle_shout)
		#heroic_throw
		Spell(heroic_throw)
	}
}

AddFunction FuryTitansGripTwoTargetsOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up)))|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) and { Talent(storm_bolt_talent no) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=60&debuff.colossus_smash.up)|rage>110
	if Rage() >= 60 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 110 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FuryTitansGripTwoTargetsShortCdActions
{
	#bloodbath,if=enabled&((!talent.bladestorm.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20))|(talent.bladestorm.enabled))
	if Talent(bloodbath_talent) and { Talent(bladestorm_talent no) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } or Talent(bladestorm_talent) } Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up))
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and { Talent(storm_bolt_talent no) or Talent(storm_bolt_talent) and not target.DebuffPresent(colossus_smash_debuff) } Spell(bladestorm)
	#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

	unless Spell(colossus_smash)
		or target.DebuffRemaining(deep_wounds_debuff) < 5 and Spell(bloodthirst)
	{
		#storm_bolt,if=enabled&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless Spell(bloodthirst)
		{
			#wait,sec=cooldown.bloodthirst.remains,if=!(target.health.pct<20&debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
			unless not { target.HealthPercent() < 20 and target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
			{
				unless BuffPresent(meat_cleaver_buff) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
					or not BuffPresent(meat_cleaver_buff) and Spell(whirlwind)
				{
					#shockwave,if=enabled
					if Talent(shockwave_talent) Spell(shockwave)
				}
			}
		}
	}
}

AddFunction FuryTitansGripTwoTargetsCdActions {}

# ActionList: FuryTitansGripSingleTargetActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripSingleTargetActions
{
	#bloodthirst,if=!buff.enrage.up
	if not BuffPresent(enrage_buff any=1) Spell(bloodthirst)
	#raging_blow,if=buff.raging_blow.stack=2&debuff.colossus_smash.up
	if BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#bloodthirst
	Spell(bloodthirst)
	#wild_strike,if=buff.bloodsurge.react&cooldown.bloodthirst.remains<=1&cooldown.bloodthirst.remains>0.3
	if BuffPresent(bloodsurge_buff) and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0.3 Spell(wild_strike)
	#wait,sec=cooldown.bloodthirst.remains,if=!(debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#colossus_smash
		Spell(colossus_smash)
		#execute,if=buff.raging_blow.stack<2&(((rage>70&!debuff.colossus_smash.up)|debuff.colossus_smash.up)|trinket.proc.strength.up)|target.time_to_die<5
		if { BuffStacks(raging_blow_buff) < 2 and { Rage() > 70 and not target.DebuffPresent(colossus_smash_debuff) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(trinket_proc_strength_buff) } or target.TimeToDie() < 5 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } Spell(execute)
		#raging_blow,if=buff.raging_blow.stack=2|debuff.colossus_smash.up|buff.raging_blow.remains<=3
		if { BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#raging_blow,if=cooldown.colossus_smash.remains>=1
		if SpellCooldown(colossus_smash) >= 1 and BuffPresent(raging_blow_buff) Spell(raging_blow)
		#wild_strike,if=buff.bloodsurge.up
		if BuffPresent(bloodsurge_buff) Spell(wild_strike)
		#heroic_throw,if=debuff.colossus_smash.down&rage<60
		if target.DebuffExpires(colossus_smash_debuff) and Rage() < 60 Spell(heroic_throw)
		#wild_strike,if=debuff.colossus_smash.up
		if target.DebuffPresent(colossus_smash_debuff) Spell(wild_strike)
		#battle_shout,if=rage<70
		if Rage() < 70 Spell(battle_shout)
		#impending_victory,if=enabled&cooldown.colossus_smash.remains>=1.5
		if Talent(impending_victory_talent) and SpellCooldown(colossus_smash) >= 1.5 and BuffPresent(victorious_buff) Spell(impending_victory)
		#wild_strike,if=cooldown.colossus_smash.remains>=2&rage>=70
		if SpellCooldown(colossus_smash) >= 2 and Rage() >= 70 Spell(wild_strike)
	}
}

AddFunction FuryTitansGripSingleTargetOffGcdActions
{
	#berserker_rage,if=buff.enrage.remains<1&cooldown.bloodthirst.remains>1
	if BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#heroic_strike,if=(debuff.colossus_smash.up&rage>=40|rage>=100)&buff.enrage.up
	if { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 40 or Rage() >= 100 } and BuffPresent(enrage_buff any=1) Spell(heroic_strike)
	#heroic_leap,if=debuff.colossus_smash.up&buff.enrage.up
	if target.DebuffPresent(colossus_smash_debuff) and BuffPresent(enrage_buff any=1) and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
	#wait,sec=cooldown.bloodthirst.remains,if=!(debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
	unless not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
	{
		#berserker_rage,if=buff.raging_blow.stack<=1&target.health.pct>=20
		if BuffStacks(raging_blow_buff) <= 1 and target.HealthPercent() >= 20 Spell(berserker_rage)
	}
}

AddFunction FuryTitansGripSingleTargetShortCdActions
{
	#bloodbath,if=enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)
	if Talent(bloodbath_talent) and { SpellCooldown(colossus_smash) < 2 or target.DebuffRemaining(colossus_smash_debuff) >= 5 or target.TimeToDie() <= 20 } Spell(bloodbath)

	unless not BuffPresent(enrage_buff any=1) and Spell(bloodthirst)
	{
		#storm_bolt,if=enabled&buff.cooldown_reduction.up&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		{
			#storm_bolt,if=enabled&buff.cooldown_reduction.down&debuff.colossus_smash.up
			if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)
			#dragon_roar,if=enabled&(!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled))
			if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

			unless Spell(bloodthirst)
				or BuffPresent(bloodsurge_buff) and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0.3 and Spell(wild_strike)
			{
				#wait,sec=cooldown.bloodthirst.remains,if=!(debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
				unless not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
				{
					unless Spell(colossus_smash)
					{
						#storm_bolt,if=enabled&buff.cooldown_reduction.down
						if Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) Spell(storm_bolt)

						unless { BuffStacks(raging_blow_buff) < 2 and { Rage() > 70 and not target.DebuffPresent(colossus_smash_debuff) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(trinket_proc_strength_buff) } or target.TimeToDie() < 5 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } and Spell(execute)
							or { BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) and Spell(raging_blow)
						{
							#bladestorm,if=enabled,interrupt_if=cooldown.bloodthirst.remains<1
							if Talent(bladestorm_talent) Spell(bladestorm)

							unless SpellCooldown(colossus_smash) >= 1 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
								or BuffPresent(bloodsurge_buff) and Spell(wild_strike)
							{
								#shockwave,if=enabled
								if Talent(shockwave_talent) Spell(shockwave)
							}
						}
					}
				}
			}
		}
	}
}

AddFunction FuryTitansGripSingleTargetCdActions
{
	unless not BuffPresent(enrage_buff any=1) and Spell(bloodthirst)
		or Talent(storm_bolt_talent) and BuffPresent(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt)
		or BuffStacks(raging_blow_buff) == 2 and target.DebuffPresent(colossus_smash_debuff) and BuffPresent(raging_blow_buff) and Spell(raging_blow)
		or Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(storm_bolt)
		or Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and Spell(dragon_roar)
		or Spell(bloodthirst)
		or BuffPresent(bloodsurge_buff) and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0.3 and Spell(wild_strike)
	{
		#wait,sec=cooldown.bloodthirst.remains,if=!(debuff.colossus_smash.up&rage>=30&buff.enrage.up)&cooldown.bloodthirst.remains<=1
		unless not { target.DebuffPresent(colossus_smash_debuff) and Rage() >= 30 and BuffPresent(enrage_buff any=1) } and SpellCooldown(bloodthirst) <= 1 and SpellCooldown(bloodthirst) > 0
		{
			unless Spell(colossus_smash)
				or Talent(storm_bolt_talent) and BuffExpires(cooldown_reduction_strength_buff) and Spell(storm_bolt)
				or { BuffStacks(raging_blow_buff) < 2 and { Rage() > 70 and not target.DebuffPresent(colossus_smash_debuff) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(trinket_proc_strength_buff) } or target.TimeToDie() < 5 } and { BuffPresent(death_sentence_buff) or target.HealthPercent() < 20 } and Spell(execute)
				or { BuffStacks(raging_blow_buff) == 2 or target.DebuffPresent(colossus_smash_debuff) or BuffRemaining(raging_blow_buff) <= 3 } and BuffPresent(raging_blow_buff) and Spell(raging_blow)
				or Talent(bladestorm_talent) and Spell(bladestorm)
				or SpellCooldown(colossus_smash) >= 1 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
				or BuffPresent(bloodsurge_buff) Spell(wild_strike)
			{
				#shattering_throw,if=cooldown.colossus_smash.remains>5
				if SpellCooldown(colossus_smash) > 5 Spell(shattering_throw)
			}
		}
	}
}

# ActionList: FuryTitansGripSingleTargetActions --> main, offgcd, shortcd, cd

AddFunction FuryTitansGripThreeTargetsActions
{
	#bloodthirst,cycle_targets=1,if=!dot.deep_wounds.ticking
	if not target.DebuffPresent(deep_wounds_debuff) Spell(bloodthirst)
	#colossus_smash
	Spell(colossus_smash)
	#raging_blow,if=buff.meat_cleaver.stack=2
	if BuffStacks(meat_cleaver_buff) == 2 and BuffPresent(raging_blow_buff) Spell(raging_blow)
	#whirlwind
	Spell(whirlwind)
	#raging_blow
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
	#battle_shout
	Spell(battle_shout)
	#heroic_throw
	Spell(heroic_throw)
}

AddFunction FuryTitansGripThreeTargetsOffGcdActions
{
	#berserker_rage,if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } and not SpellCooldown(bladestorm) or Talent(bladestorm_talent no) and BuffRemaining(enrage_buff any=1) < 1 and SpellCooldown(bloodthirst) > 1 Spell(berserker_rage)
	#cleave,if=(rage>=70&debuff.colossus_smash.up)|rage>90
	if Rage() >= 70 and target.DebuffPresent(colossus_smash_debuff) or Rage() > 90 Spell(cleave)
	#heroic_leap,if=buff.enrage.up&(debuff.colossus_smash.up&buff.cooldown_reduction.up|!buff.cooldown_reduction.up)
	if BuffPresent(enrage_buff any=1) and { target.DebuffPresent(colossus_smash_debuff) and BuffPresent(cooldown_reduction_strength_buff) or not BuffPresent(cooldown_reduction_strength_buff) } and CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction FuryTitansGripThreeTargetsShortCdActions
{
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#bladestorm,if=enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(bladestorm_talent) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(bladestorm)
	#dragon_roar,if=enabled&!debuff.colossus_smash.up&(buff.bloodbath.up|!talent.bloodbath.enabled)
	if Talent(dragon_roar_talent) and not target.DebuffPresent(colossus_smash_debuff) and { BuffPresent(bloodbath_buff) or Talent(bloodbath_talent no) } Spell(dragon_roar)

	unless not target.DebuffPresent(deep_wounds_debuff) and Spell(bloodthirst)
		or Spell(colossus_smash)
	{
		#storm_bolt,if=enabled&debuff.colossus_smash.up
		if Talent(storm_bolt_talent) and target.DebuffPresent(colossus_smash_debuff) Spell(storm_bolt)

		unless BuffStacks(meat_cleaver_buff) == 2 and BuffPresent(raging_blow_buff) and Spell(raging_blow)
			or Spell(whirlwind)
		{
			#shockwave,if=enabled
			if Talent(shockwave_talent) Spell(shockwave)
		}
	}
}

AddFunction FuryTitansGripThreeTargetsCdActions {}

### Fury icons.
AddCheckBox(opt_warrior_fury "Show Fury icons" specialization=fury default)
AddCheckBox(opt_warrior_fury_aoe L(AOE) specialization=fury default)

AddIcon specialization=fury size=small help=offgcd enemies=1 checkbox=opt_warrior_fury checkbox=!opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatOffGcdActions()
		FurySingleMindedFuryDefaultOffGcdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatOffGcdActions()
		FuryTitansGripDefaultOffGcdActions()
	}
}

AddIcon specialization=fury size=small help=offgcd checkbox=opt_warrior_fury checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatOffGcdActions()
		FurySingleMindedFuryDefaultOffGcdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatOffGcdActions()
		FuryTitansGripDefaultOffGcdActions()
	}
}

AddIcon specialization=fury help=shortcd enemies=1 checkbox=opt_warrior_fury checkbox=!opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatShortCdActions()
		FurySingleMindedFuryDefaultShortCdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatShortCdActions()
		FuryTitansGripDefaultShortCdActions()
	}
}

AddIcon specialization=fury help=shortcd checkbox=opt_warrior_fury checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatShortCdActions()
		FurySingleMindedFuryDefaultShortCdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatShortCdActions()
		FuryTitansGripDefaultShortCdActions()
	}
}

AddIcon specialization=fury help=main enemies=1 checkbox=opt_warrior_fury
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatActions()
		FurySingleMindedFuryDefaultActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatActions()
		FuryTitansGripDefaultActions()
	}
}

AddIcon specialization=fury help=aoe checkbox=opt_warrior_fury checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatActions()
		FurySingleMindedFuryDefaultActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatActions()
		FuryTitansGripDefaultActions()
	}
}

AddIcon specialization=fury help=cd enemies=1 checkbox=opt_warrior_fury checkbox=!opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatCdActions()
		FurySingleMindedFuryDefaultCdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatCdActions()
		FuryTitansGripDefaultCdActions()
	}
}

AddIcon specialization=fury help=cd checkbox=opt_warrior_fury checkbox=opt_warrior_fury_aoe
{
	if HasWeapon(main type=1h)
	{
		if InCombat(no) FurySingleMindedFuryPrecombatCdActions()
		FurySingleMindedFuryDefaultCdActions()
	}
	if HasWeapon(main type=2h)
	{
		if InCombat(no) FuryTitansGripPrecombatCdActions()
		FuryTitansGripDefaultCdActions()
	}
}

###
### Protection
###
# Based on SimulationCraft profile "Warrior_Protection_T16H".
#	class=warrior
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Zb!.00110
#	glyphs=unending_rage/hold_the_line/heavy_repercussions

# ActionList: ProtectionPrecombatActions --> main, offgcd, shortcd, cd

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

AddFunction ProtectionPrecombatOffGcdActions {}

AddFunction ProtectionPrecombatShortCdActions {}

AddFunction ProtectionPrecombatCdActions
{
	unless not Stance(warrior_defensive_stance) and Spell(defensive_stance)
		or Spell(battle_shout)
	{
		#mountains_potion
		UsePotionArmor()
	}
}

# ActionList: ProtectionDefaultActions --> main, offgcd, shortcd, cd

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsActions()
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationActions()
}

AddFunction ProtectionDefaultOffGcdActions
{
	# CHANGE: Use Cleave instead of Heroic Strike when tanking multiple mobs.
	if Enemies() > 2 and { BuffPresent(ultimatum_buff) or BuffPresent(glyph_incite_buff) } Spell(cleave)
	#heroic_strike,if=buff.ultimatum.up|buff.glyph_incite.up
	if BuffPresent(ultimatum_buff) or BuffPresent(glyph_incite_buff) Spell(heroic_strike)
	#berserker_rage,if=buff.enrage.down&rage<=rage.max-10
	if BuffExpires(enrage_buff any=1) and Rage() <= MaxRage() - 10 Spell(berserker_rage)
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsOffGcdActions()
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationOffGcdActions()
}

AddFunction ProtectionDefaultShortCdActions
{
	#shield_block
	Spell(shield_block)
	#shield_barrier,if=incoming_damage_1500ms>health.max*0.3|rage>rage.max-20
	if IncomingDamage(1.5) > MaxHealth() * 0.3 or Rage() > MaxRage() - 20 Spell(shield_barrier)
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsShortCdActions()
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationShortCdActions()
}

AddFunction ProtectionDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#mountains_potion,if=incoming_damage_2500ms>health.max*0.6&(buff.shield_wall.down&buff.last_stand.down)
	if IncomingDamage(2.5) > MaxHealth() * 0.6 and BuffExpires(shield_wall_buff) and BuffExpires(last_stand_buff) UsePotionArmor()
	#use_item,slot=trinket2
	UseItemActions()
	#shield_wall,if=incoming_damage_2500ms>health.max*0.6
	if IncomingDamage(2.5) > MaxHealth() * 0.6 Spell(shield_wall)
	#run_action_list,name=dps_cds,if=buff.vengeance.value>health.max*0.20
	if BuffAmount(vengeance_buff) > MaxHealth() * 0.2 ProtectionDpsCdsCdActions()
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationCdActions()
}

# ActionList: ProtectionNormalRotationActions --> main, offgcd, shortcd, cd

AddFunction ProtectionNormalRotationActions
{
	# CHANGE: Use Thunder Clap on cooldown when tanking multiple mobs.
	if Enemies() > 2 Spell(thunder_clap)
	#shield_slam
	Spell(shield_slam)
	#revenge
	Spell(revenge)
	#battle_shout,if=rage<=rage.max-20
	if Rage() <= MaxRage() - 20 Spell(battle_shout)
	#thunder_clap,if=glyph.resonating_power.enabled|target.debuff.weakened_blows.down
	if Glyph(glyph_of_resonating_power) or target.DebuffExpires(weakened_blows_debuff any=1) Spell(thunder_clap)
	#impending_victory,if=enabled
	if Talent(impending_victory_talent) and BuffPresent(victorious_buff) Spell(impending_victory)
	#victory_rush,if=!talent.impending_victory.enabled
	if Talent(impending_victory_talent no) and BuffPresent(victorious_buff) Spell(victory_rush)
	#devastate
	Spell(devastate)
}

AddFunction ProtectionNormalRotationOffGcdActions {}

AddFunction ProtectionNormalRotationShortCdActions
{
	unless Enemies() > 2 and Spell(thunder_clap)
		or Spell(shield_slam)
	{
		# CHANGE: Use Level 60 talent on cooldown if tanking multiple mobs.
		if Enemies() > 2
		{
			#dragon_roar,if=enabled
			if Talent(dragon_roar_talent) Spell(dragon_roar)
			#shockwave,if=enabled
			if Talent(shockwave_talent) Spell(shockwave)
			#bladestorm,if=enabled
			if Talent(bladestorm_talent) Spell(bladestorm)
		}

		unless Spell(revenge)
			or Rage() <= MaxRage() - 20 and Spell(battle_shout)
			or { Glyph(glyph_of_resonating_power) or target.DebuffExpires(weakened_blows_debuff any=1) } and Spell(thunder_clap)
		{
			#demoralizing_shout
			Spell(demoralizing_shout)
		}
	}
}

AddFunction ProtectionNormalRotationCdActions {}

# ActionList: ProtectionDpsCdsActions --> main, offgcd, shortcd, cd

AddFunction ProtectionDpsCdsActions
{
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationActions()
}

AddFunction ProtectionDpsCdsOffGcdActions
{
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationOffGcdActions()
}

AddFunction ProtectionDpsCdsShortCdActions
{
	#avatar,if=enabled
	if Talent(avatar_talent) Spell(avatar)
	#bloodbath,if=enabled
	if Talent(bloodbath_talent) Spell(bloodbath)
	#dragon_roar,if=enabled
	if Talent(dragon_roar_talent) Spell(dragon_roar)
	#storm_bolt,if=enabled
	if Talent(storm_bolt_talent) Spell(storm_bolt)
	#shockwave,if=enabled
	if Talent(shockwave_talent) Spell(shockwave)
	#bladestorm,if=enabled
	if Talent(bladestorm_talent) Spell(bladestorm)
	#run_action_list,name=normal_rotation
	ProtectionNormalRotationShortCdActions()
}

AddFunction ProtectionDpsCdsCdActions
{
	#avatar,if=enabled
	if Talent(avatar_talent) Spell(avatar)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_rage)

	unless Talent(dragon_roar_talent) and Spell(dragon_roar)
	{
		#shattering_throw
		Spell(shattering_throw)
		#skull_banner
		if CheckBoxOn(opt_skull_banner) Spell(skull_banner)
		#recklessness
		Spell(recklessness)

		unless Talent(storm_bolt_talent) and Spell(storm_bolt)
			or Talent(shockwave_talent) and Spell(shockwave)
		{
			#run_action_list,name=normal_rotation
			ProtectionNormalRotationCdActions()
		}
	}
}

### Protection icons.
AddCheckBox(opt_warrior_protection "Show Protection icons" specialization=protection default)
AddCheckBox(opt_warrior_protection_aoe L(AOE) specialization=protection default)

AddIcon specialization=protection size=small help=offgcd enemies=1 checkbox=opt_warrior_protection checkbox=!opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatOffGcdActions()
	ProtectionDefaultOffGcdActions()
}

AddIcon specialization=protection size=small help=offgcd checkbox=opt_warrior_protection checkbox=opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatOffGcdActions()
	ProtectionDefaultOffGcdActions()
}

AddIcon specialization=protection help=shortcd enemies=1 checkbox=opt_warrior_protection checkbox=!opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatShortCdActions()
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=shortcd checkbox=opt_warrior_protection checkbox=opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatShortCdActions()
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=main enemies=1 checkbox=opt_warrior_protection
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=aoe checkbox=opt_warrior_protection checkbox=opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionNormalRotationActions()
}

AddIcon specialization=protection help=cd enemies=1 checkbox=opt_warrior_protection checkbox=!opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}

AddIcon specialization=protection help=cd checkbox=opt_warrior_protection checkbox=opt_warrior_protection_aoe
{
	if InCombat(no) ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("WARRIOR", "Ovale", desc, code, "script")
end
