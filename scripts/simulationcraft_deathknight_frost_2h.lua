local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_death_knight_frost_2h_t17m"
	local desc = "[6.1] SimulationCraft: Death_Knight_Frost_2h_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T17M".
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

AddFunction FrostTwoHanderUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction FrostTwoHanderUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction FrostTwoHanderGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(plague_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction FrostTwoHanderInterruptActions
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

AddFunction FrostTwoHanderDefaultMainActions
{
	#run_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostTwoHanderAoeMainActions()
	#run_action_list,name=single_target,if=active_enemies<4
	if Enemies() < 4 FrostTwoHanderSingleTargetMainActions()
}

AddFunction FrostTwoHanderDefaultShortCdActions
{
	#auto_attack
	FrostTwoHanderGetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5 magic=1) > 0 Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#run_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostTwoHanderAoeShortCdActions()

	unless Enemies() >= 4 and FrostTwoHanderAoeShortCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<4
		if Enemies() < 4 FrostTwoHanderSingleTargetShortCdActions()
	}
}

AddFunction FrostTwoHanderDefaultCdActions
{
	#mind_freeze
	FrostTwoHanderInterruptActions()
	#potion,name=draenic_strength,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) FrostTwoHanderUsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=trinket2
	FrostTwoHanderUseItemActions()
	#run_action_list,name=aoe,if=active_enemies>=4
	if Enemies() >= 4 FrostTwoHanderAoeCdActions()

	unless Enemies() >= 4 and FrostTwoHanderAoeCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<4
		if Enemies() < 4 FrostTwoHanderSingleTargetCdActions()
	}
}

### actions.aoe

AddFunction FrostTwoHanderAoeMainActions
{
	#blood_boil,if=dot.blood_plague.ticking&(!talent.unholy_blight.enabled|cooldown.unholy_blight.remains<49),line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeMainActions()
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

AddFunction FrostTwoHanderAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
	{
		#defile
		Spell(defile)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeShortCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosAoeShortCdPostConditions() or Spell(howling_blast)
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

AddFunction FrostTwoHanderAoeShortCdPostConditions
{
	target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosAoeShortCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

AddFunction FrostTwoHanderAoeCdActions
{
	unless Spell(unholy_blight) or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or Spell(defile)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosAoeCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

AddFunction FrostTwoHanderAoeCdPostConditions
{
	Spell(unholy_blight) or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil) or Spell(defile) or BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosAoeCdPostConditions() or Spell(howling_blast) or RunicPower() > 88 and Spell(frost_strike) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

### actions.bos_aoe

AddFunction FrostTwoHanderBosAoeMainActions
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

AddFunction FrostTwoHanderBosAoeShortCdActions
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

AddFunction FrostTwoHanderBosAoeShortCdPostConditions
{
	Spell(howling_blast) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

AddFunction FrostTwoHanderBosAoeCdActions
{
	unless Spell(howling_blast) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

AddFunction FrostTwoHanderBosAoeCdPostConditions
{
	Spell(howling_blast) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(plague_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(plague_strike)
}

### actions.bos_st

AddFunction FrostTwoHanderBosStMainActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#obliterate,if=runic_power<76
	if RunicPower() < 76 Spell(obliterate)
	#howling_blast,if=((death=1&frost=0&unholy=0)|death=0&frost=1&unholy=0)&runic_power<88
	if { Rune(death) >= 1 and Rune(death) < 2 and Rune(frost) >= 0 and Rune(frost) < 1 and Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(death) >= 0 and Rune(death) < 1 and Rune(frost) >= 1 and Rune(frost) < 2 and Rune(unholy) >= 0 and Rune(unholy) < 1 } and RunicPower() < 88 Spell(howling_blast)
}

AddFunction FrostTwoHanderBosStShortCdActions
{
	unless BuffPresent(killing_machine_buff) and Spell(obliterate)
	{
		#blood_tap,if=buff.killing_machine.react&buff.blood_charge.stack>=5
		if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
		{
			#blood_tap,if=buff.blood_charge.stack>=5
			if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction FrostTwoHanderBosStShortCdPostConditions
{
	BuffPresent(killing_machine_buff) and Spell(obliterate) or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 76 and Spell(obliterate) or { Rune(death) >= 1 and Rune(death) < 2 and Rune(frost) >= 0 and Rune(frost) < 1 and Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(death) >= 0 and Rune(death) < 1 and Rune(frost) >= 1 and Rune(frost) < 2 and Rune(unholy) >= 0 and Rune(unholy) < 1 } and RunicPower() < 88 and Spell(howling_blast)
}

AddFunction FrostTwoHanderBosStCdPostConditions
{
	BuffPresent(killing_machine_buff) and Spell(obliterate) or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or RunicPower() < 76 and Spell(obliterate) or { Rune(death) >= 1 and Rune(death) < 2 and Rune(frost) >= 0 and Rune(frost) < 1 and Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(death) >= 0 and Rune(death) < 1 and Rune(frost) >= 1 and Rune(frost) < 2 and Rune(unholy) >= 0 and Rune(unholy) < 1 } and RunicPower() < 88 and Spell(howling_blast)
}

### actions.precombat

AddFunction FrostTwoHanderPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=salty_squid_roll
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
}

AddFunction FrostTwoHanderPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostTwoHanderPrecombatShortCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
}

AddFunction FrostTwoHanderPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=draenic_strength
		FrostTwoHanderUsePotionStrength()
	}
}

AddFunction FrostTwoHanderPrecombatCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(frost_presence)
}

### actions.single_target

AddFunction FrostTwoHanderSingleTargetMainActions
{
	#plague_leech,if=disease.min_remains<1
	if target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#howling_blast,if=buff.rime.react&disease.min_remains>5&buff.killing_machine.react
	if BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking&buff.rime.react
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) Spell(howling_blast)
	#outbreak,if=!disease.max_ticking
	if not target.DiseasesAnyTicking() Spell(outbreak)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosStMainActions()
	#obliterate,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<7&runic_power<76
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 Spell(obliterate)
	#howling_blast,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<3&runic_power<88
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 88 Spell(howling_blast)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#howling_blast,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(howling_blast)
	#plague_strike,if=!talent.necrotic_plague.enabled&!dot.blood_plague.ticking
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) Spell(plague_strike)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#howling_blast,if=buff.rime.react&disease.min_remains>5&(blood.frac>=1.8|unholy.frac>=1.8|frost.frac>=1.8)
	if BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } Spell(howling_blast)
	#obliterate,if=blood.frac>=1.8|unholy.frac>=1.8|frost.frac>=1.8
	if Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 Spell(obliterate)
	#plague_leech,if=disease.min_remains<3&((blood.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&blood.frac<=0.95))
	if target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#frost_strike,if=talent.runic_empowerment.enabled&(frost=0|unholy=0|blood=0)&(!buff.killing_machine.react|!obliterate.ready_in<=1)
	if Talent(runic_empowerment_talent) and { Rune(frost) >= 0 and Rune(frost) < 1 or Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(blood) >= 0 and Rune(blood) < 1 } and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } Spell(frost_strike)
	#frost_strike,if=talent.blood_tap.enabled&buff.blood_charge.stack<=10&(!buff.killing_machine.react|!obliterate.ready_in<=1)
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } Spell(frost_strike)
	#howling_blast,if=buff.rime.react&disease.min_remains>5
	if BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 Spell(howling_blast)
	#obliterate,if=blood.frac>=1.5|unholy.frac>=1.6|frost.frac>=1.6|buff.bloodlust.up|cooldown.plague_leech.remains<=4
	if Rune(blood) >= 1.5 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 or BuffPresent(burst_haste_buff any=1) or SpellCooldown(plague_leech) <= 4 Spell(obliterate)
	#frost_strike,if=!buff.killing_machine.react
	if not BuffPresent(killing_machine_buff) Spell(frost_strike)
	#plague_leech,if=(blood.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&blood.frac<=0.95)
	if { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction FrostTwoHanderSingleTargetShortCdActions
{
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 Spell(blood_tap)
		#defile
		Spell(defile)
		#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
		if Talent(defile_talent) and not SpellCooldown(defile) > 0 Spell(blood_tap)

		unless BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(obliterate)
		{
			#blood_tap,if=buff.killing_machine.react
			if BuffPresent(killing_machine_buff) Spell(blood_tap)

			unless not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) and Spell(howling_blast) or not target.DiseasesAnyTicking() and Spell(outbreak)
			{
				#unholy_blight,if=!disease.min_ticking
				if not target.DiseasesTicking() Spell(unholy_blight)
				#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
				if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosStShortCdActions()

				unless BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosStShortCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Spell(obliterate) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 88 and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike)
				{
					#blood_tap,if=buff.blood_charge.stack>10&runic_power>76
					if BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 Spell(blood_tap)

					unless RunicPower() > 76 and Spell(frost_strike) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(howling_blast) or { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(obliterate) or target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Talent(runic_empowerment_talent) and { Rune(frost) >= 0 and Rune(frost) < 1 or Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(blood) >= 0 and Rune(blood) < 1 } and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike) or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and Spell(howling_blast) or { Rune(blood) >= 1.5 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 or BuffPresent(burst_haste_buff any=1) or SpellCooldown(plague_leech) <= 4 } and Spell(obliterate)
					{
						#blood_tap,if=(buff.blood_charge.stack>10&runic_power>=20)|(blood.frac>=1.4|unholy.frac>=1.6|frost.frac>=1.6)
						if BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 or Rune(blood) >= 1.4 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 Spell(blood_tap)
					}
				}
			}
		}
	}
}

AddFunction FrostTwoHanderSingleTargetCdActions
{
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost) or Spell(defile) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(obliterate) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) and Spell(howling_blast) or not target.DiseasesAnyTicking() and Spell(outbreak) or not target.DiseasesTicking() and Spell(unholy_blight)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)

		unless BuffPresent(breath_of_sindragosa_buff) and FrostTwoHanderBosStCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Spell(obliterate) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 88 and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike) or RunicPower() > 76 and Spell(frost_strike) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(howling_blast) or { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(obliterate) or target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or Talent(runic_empowerment_talent) and { Rune(frost) >= 0 and Rune(frost) < 1 or Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(blood) >= 0 and Rune(blood) < 1 } and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike) or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and Spell(howling_blast) or { Rune(blood) >= 1.5 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 or BuffPresent(burst_haste_buff any=1) or SpellCooldown(plague_leech) <= 4 } and Spell(obliterate) or not BuffPresent(killing_machine_buff) and Spell(frost_strike) or { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
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
	if not InCombat() FrostTwoHanderPrecombatShortCdActions()
	unless not InCombat() and FrostTwoHanderPrecombatShortCdPostConditions()
	{
		FrostTwoHanderDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=shortcd specialization=frost
{
	if not InCombat() FrostTwoHanderPrecombatShortCdActions()
	unless not InCombat() and FrostTwoHanderPrecombatShortCdPostConditions()
	{
		FrostTwoHanderDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=frost
{
	if not InCombat() FrostTwoHanderPrecombatMainActions()
	FrostTwoHanderDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_frost_aoe help=aoe specialization=frost
{
	if not InCombat() FrostTwoHanderPrecombatMainActions()
	FrostTwoHanderDefaultMainActions()
}

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=cd specialization=frost
{
	if not InCombat() FrostTwoHanderPrecombatCdActions()
	unless not InCombat() and FrostTwoHanderPrecombatCdPostConditions()
	{
		FrostTwoHanderDefaultCdActions()
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=cd specialization=frost
{
	if not InCombat() FrostTwoHanderPrecombatCdActions()
	unless not InCombat() and FrostTwoHanderPrecombatCdPostConditions()
	{
		FrostTwoHanderDefaultCdActions()
	}
}

### Required symbols
# antimagic_shell
# arcane_torrent_runicpower
# army_of_the_dead
# asphyxiate
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# blood_tap_talent
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
# outbreak
# pillar_of_frost
# pillar_of_frost_buff
# plague_leech
# plague_strike
# potion_strength_buff
# quaking_palm
# rime_buff
# runic_empowerment_talent
# soul_reaper_frost
# strangulate
# unholy_blight
# unholy_blight_talent
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
end
