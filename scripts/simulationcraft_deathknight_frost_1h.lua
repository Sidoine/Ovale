local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_death_knight_frost_1h_t17m"
	local desc = "[6.1] SimulationCraft: Death_Knight_Frost_1h_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T17M".
#	class=deathknight
#	spec=frost
#	talents=2001002

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=frost)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=frost)

AddFunction FrostDualWieldUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction FrostDualWieldUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction FrostDualWieldGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(plague_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction FrostDualWieldInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(mind_freeze) Spell(mind_freeze)
		if not target.Classification(worldboss)
		{
			if target.InRange(asphyxiate) Spell(asphyxiate)
			if target.InRange(strangulate) Spell(strangulate)
			Spell(arcane_torrent_runicpower)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction FrostDualWieldDefaultMainActions
{
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeMainActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetMainActions()
}

AddFunction FrostDualWieldDefaultShortCdActions
{
	#auto_attack
	FrostDualWieldGetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5 magic=1) > 0 Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeShortCdActions()

	unless Enemies() >= 3 and FrostDualWieldAoeShortCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<3
		if Enemies() < 3 FrostDualWieldSingleTargetShortCdActions()
	}
}

AddFunction FrostDualWieldDefaultCdActions
{
	#mind_freeze
	FrostDualWieldInterruptActions()
	#potion,name=draenic_strength,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) FrostDualWieldUsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=trinket2
	FrostDualWieldUseItemActions()
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeCdActions()

	unless Enemies() >= 3 and FrostDualWieldAoeCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<3
		if Enemies() < 3 FrostDualWieldSingleTargetCdActions()
	}
}

### actions.aoe

AddFunction FrostDualWieldAoeMainActions
{
	#blood_boil,if=dot.blood_plague.ticking&(!talent.unholy_blight.enabled|cooldown.unholy_blight.remains<49),line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosAoeMainActions()
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=runic_power>88
	if RunicPower() > 88 Spell(frost_strike)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#frost_strike,if=!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>=10
	if not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 Spell(frost_strike)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostDualWieldAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
	{
		#defile
		Spell(defile)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosAoeShortCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosAoeShortCdPostConditions() or Spell(howling_blast)
		{
			#blood_tap,if=buff.blood_charge.stack>10
			if BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)

			unless RunicPower() > 88 and Spell(frost_strike)
			{
				#death_and_decay,if=unholy=1
				if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)

				unless Rune(unholy) >= 2 and Spell(plague_strike)
				{
					#blood_tap
					Spell(blood_tap)
				}
			}
		}
	}
}

AddFunction FrostDualWieldAoeShortCdPostConditions
{
	target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosAoeShortCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

AddFunction FrostDualWieldAoeCdActions
{
	unless Spell(unholy_blight) or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or Spell(defile)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosAoeCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosAoeCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

AddFunction FrostDualWieldAoeCdPostConditions
{
	Spell(unholy_blight) or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or Spell(defile) or BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosAoeCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

### actions.bos_aoe

AddFunction FrostDualWieldBosAoeMainActions
{
	#howling_blast
	Spell(howling_blast)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostDualWieldBosAoeShortCdActions
{
	unless Spell(howling_blast)
	{
		#blood_tap,if=buff.blood_charge.stack>10
		if BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)
		#death_and_decay,if=unholy=1
		if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)

		unless Rune(unholy) >= 2 and Spell(plague_strike)
		{
			#blood_tap
			Spell(blood_tap)
		}
	}
}

AddFunction FrostDualWieldBosAoeShortCdPostConditions
{
	Spell(howling_blast) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

AddFunction FrostDualWieldBosAoeCdActions
{
	unless Spell(howling_blast) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

AddFunction FrostDualWieldBosAoeCdPostConditions
{
	Spell(howling_blast) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

### actions.bos_st

AddFunction FrostDualWieldBosStMainActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#howling_blast,if=runic_power<88
	if RunicPower() < 88 Spell(howling_blast)
	#obliterate,if=unholy>0&runic_power<76
	if Rune(unholy) >= 1 and RunicPower() < 76 Spell(obliterate)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction FrostDualWieldBosStShortCdActions
{
	unless BuffPresent(killing_machine_buff) and Spell(obliterate)
	{
		#blood_tap,if=buff.killing_machine.react&buff.blood_charge.stack>=5
		if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 88 and Spell(howling_blast) or Rune(unholy) >= 1 and RunicPower() < 76 and Spell(obliterate)
		{
			#blood_tap,if=buff.blood_charge.stack>=5
			if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction FrostDualWieldBosStShortCdPostConditions
{
	BuffPresent(killing_machine_buff) and Spell(obliterate) or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 88 and Spell(howling_blast) or Rune(unholy) >= 1 and RunicPower() < 76 and Spell(obliterate) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
}

AddFunction FrostDualWieldBosStCdActions
{
	unless BuffPresent(killing_machine_buff) and Spell(obliterate) or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 88 and Spell(howling_blast) or Rune(unholy) >= 1 and RunicPower() < 76 and Spell(obliterate) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

AddFunction FrostDualWieldBosStCdPostConditions
{
	BuffPresent(killing_machine_buff) and Spell(obliterate) or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 88 and Spell(howling_blast) or Rune(unholy) >= 1 and RunicPower() < 76 and Spell(obliterate) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
}

### actions.precombat

AddFunction FrostDualWieldPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=sleeper_sushi
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
}

AddFunction FrostDualWieldPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostDualWieldPrecombatShortCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
}

AddFunction FrostDualWieldPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=draenic_strength
		FrostDualWieldUsePotionStrength()
	}
}

AddFunction FrostDualWieldPrecombatCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
}

### actions.single_target

AddFunction FrostDualWieldSingleTargetMainActions
{
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStMainActions()
	#howling_blast,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<7&runic_power<88
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 Spell(howling_blast)
	#obliterate,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<3&runic_power<76
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 Spell(obliterate)
	#frost_strike,if=buff.killing_machine.react|runic_power>88
	if BuffPresent(killing_machine_buff) or RunicPower() > 88 Spell(frost_strike)
	#frost_strike,if=cooldown.antimagic_shell.remains<1&runic_power>=50&!buff.antimagic_shell.up
	if SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) Spell(frost_strike)
	#howling_blast,if=death>1|frost>1
	if Rune(death) >= 2 or Rune(frost) >= 2 Spell(howling_blast)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#howling_blast,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(howling_blast)
	#plague_strike,if=!talent.necrotic_plague.enabled&!dot.blood_plague.ticking&unholy>0
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#frost_strike,if=set_bonus.tier17_2pc=1&(runic_power>=50&(cooldown.pillar_of_frost.remains<5))
	if ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 Spell(frost_strike)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=unholy>0&!buff.killing_machine.react
	if Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast,if=!(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains<3)|death+frost>=2
	if not { target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 Spell(howling_blast)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction FrostDualWieldSingleTargetShortCdActions
{
	#blood_tap,if=buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react))
	if BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } Spell(blood_tap)

	unless target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 Spell(blood_tap)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStShortCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosStShortCdPostConditions()
		{
			#defile
			Spell(defile)
			#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
			if Talent(defile_talent) and not SpellCooldown(defile) > 0 Spell(blood_tap)

			unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Spell(howling_blast) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike) or SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) and Spell(frost_strike) or { Rune(death) >= 2 or Rune(frost) >= 2 } and Spell(howling_blast)
			{
				#unholy_blight,if=!disease.ticking
				if not target.DiseasesAnyTicking() Spell(unholy_blight)

				unless not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike) or RunicPower() > 76 and Spell(frost_strike) or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate) or { not { target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast)
				{
					#blood_tap
					Spell(blood_tap)
				}
			}
		}
	}
}

AddFunction FrostDualWieldSingleTargetCdActions
{
	unless target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosStCdPostConditions() or Spell(defile) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Spell(howling_blast) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike) or SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) and Spell(frost_strike) or { Rune(death) >= 2 or Rune(frost) >= 2 } and Spell(howling_blast) or not target.DiseasesAnyTicking() and Spell(unholy_blight) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike) or RunicPower() > 76 and Spell(frost_strike) or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate) or { not { target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

### Frost icons.

AddCheckBox(opt_deathknight_frost_aoe L(AOE) default specialization=frost)

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=shortcd specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatShortCdActions()
	unless not InCombat() and FrostDualWieldPrecombatShortCdPostConditions()
	{
		FrostDualWieldDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=shortcd specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatShortCdActions()
	unless not InCombat() and FrostDualWieldPrecombatShortCdPostConditions()
	{
		FrostDualWieldDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatMainActions()
	FrostDualWieldDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_frost_aoe help=aoe specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatMainActions()
	FrostDualWieldDefaultMainActions()
}

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=cd specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatCdActions()
	unless not InCombat() and FrostDualWieldPrecombatCdPostConditions()
	{
		FrostDualWieldDefaultCdActions()
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=cd specialization=frost
{
	if not InCombat() FrostDualWieldPrecombatCdActions()
	unless not InCombat() and FrostDualWieldPrecombatCdPostConditions()
	{
		FrostDualWieldDefaultCdActions()
	}
}

### Required symbols
# antimagic_shell
# antimagic_shell_buff
# arcane_torrent_runicpower
# army_of_the_dead
# asphyxiate
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# breath_of_sindragosa
# breath_of_sindragosa_buff
# breath_of_sindragosa_talent
# death_and_decay
# deaths_advance
# defile
# defile_talent
# draenic_strength_potion
# empower_rune_weapon
# frost_fever_debuff
# frost_presence
# frost_strike
# horn_of_winter
# howling_blast
# killing_machine_buff
# mind_freeze
# necrotic_plague_debuff
# necrotic_plague_talent
# obliterate
# pillar_of_frost
# pillar_of_frost_buff
# plague_leech
# plague_strike
# potion_strength_buff
# quaking_palm
# rime_buff
# soul_reaper_frost
# strangulate
# unholy_blight
# unholy_blight_talent
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
end
