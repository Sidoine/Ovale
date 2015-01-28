local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_deathknight"
	local desc = "[6.0] Ovale: Rotations (Blood, Frost, Unholy)"
	local code = [[
# Death knight rotation functions based on SimulationCraft.

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default)
AddCheckBox(opt_melee_range L(not_in_melee_range))
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=blood)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default spcialization=!blood)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(plague_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction InterruptActions
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

###
### Blood
###
# Based on SimulationCraft profile "Death_Knight_Blood_T16M".
#	class=deathknight
#	spec=blood
#	talents=2013102

### actions.default

AddFunction BloodDefaultMainActions
{
	#conversion,if=!buff.conversion.up&runic_power>50&health.pct<90
	if not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 Spell(conversion)
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if IncomingDamage(5) >= MaxHealth() * 0.65 Spell(death_strike)
	#outbreak,if=(!talent.necrotic_plague.enabled&disease.min_remains<8)|!disease.ticking
	if not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 8 or not target.DiseasesAnyTicking() Spell(outbreak)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#plague_strike,if=(!talent.necrotic_plague.enabled&!dot.blood_plague.ticking)|(talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking)
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(plague_strike)
	#icy_touch,if=(!talent.necrotic_plague.enabled&!dot.frost_fever.ticking)|(talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking)
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(icy_touch)
	#death_strike,if=(unholy=2|frost=2)
	if Rune(unholy) >= 2 or Rune(frost) >= 2 Spell(death_strike)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Rune(blood) >= 1 Spell(soul_reaper_blood)
	#blood_boil,if=blood=2
	if Rune(blood) >= 2 Spell(blood_boil)
	#death_coil
	Spell(death_coil)
}

AddFunction BloodDefaultShortCdActions
{
	#auto_attack
	GetInMeleeRange()
	#antimagic_shell
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)

	unless not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 and Spell(conversion) or IncomingDamage(5) >= MaxHealth() * 0.65 and Spell(death_strike)
	{
		#bone_shield,if=buff.army_of_the_dead.down&buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
		if BuffExpires(army_of_the_dead_buff) and BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(bone_shield)
		#vampiric_blood,if=health.pct<50
		if HealthPercent() < 50 Spell(vampiric_blood)
		#rune_tap,if=health.pct<50&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down&buff.icebound_fortitude.down
		if HealthPercent() < 50 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) and BuffExpires(icebound_fortitude_buff) Spell(rune_tap)
		#dancing_rune_weapon,if=health.pct<80&buff.army_of_the_dead.down&buff.icebound_fortitude.down&buff.bone_shield.down&buff.vampiric_blood.down
		if HealthPercent() < 80 and BuffExpires(army_of_the_dead_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(dancing_rune_weapon)

		unless { not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 8 or not target.DiseasesAnyTicking() } and Spell(outbreak) or RunicPower() > 90 and Spell(death_coil) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(plague_strike) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(icy_touch)
		{
			#defile
			Spell(defile)

			unless { Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil)
			{
				#blood_tap
				Spell(blood_tap)
			}
		}
	}
}

AddFunction BloodDefaultCdActions
{
	#mind_freeze
	InterruptActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=draenic_armor,if=buff.potion.down&buff.blood_shield.down&!unholy&!frost
	if BuffExpires(potion_armor_buff) and BuffExpires(blood_shield_buff) and not Rune(unholy) >= 1 and not Rune(frost) >= 1 UsePotionArmor()

	unless not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 and Spell(conversion)
	{
		#lichborne,if=health.pct<90
		if HealthPercent() < 90 Spell(lichborne)

		unless IncomingDamage(5) >= MaxHealth() * 0.65 and Spell(death_strike)
		{
			#army_of_the_dead,if=buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
			if BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(army_of_the_dead)
			#icebound_fortitude,if=health.pct<30&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down
			if HealthPercent() < 30 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(icebound_fortitude)
			#death_pact,if=health.pct<50
			if HealthPercent() < 50 Spell(death_pact)

			unless { not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 8 or not target.DiseasesAnyTicking() } and Spell(outbreak) or RunicPower() > 90 and Spell(death_coil) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(plague_strike) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(icy_touch) or Spell(defile) or { Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil) or Spell(death_coil)
			{
				#empower_rune_weapon,if=!blood&!unholy&!frost
				if not Rune(blood) >= 1 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(empower_rune_weapon)
			}
		}
	}
}

### actions.precombat

AddFunction BloodPrecombatMainActions
{
	#flask,type=greater_draenic_stamina_flask
	#food,type=talador_surf_and_turf
	#blood_presence
	Spell(blood_presence)
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
}

AddFunction BloodPrecombatShortCdActions
{
	unless Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
	{
		#bone_shield
		Spell(bone_shield)
	}
}

AddFunction BloodPrecombatShortCdPostConditions
{
	Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
}

AddFunction BloodPrecombatCdActions
{
	unless Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
	{
		#snapshot_stats
		#potion,name=draenic_armor
		UsePotionArmor()
	}
}

AddFunction BloodPrecombatCdPostConditions
{
	Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
}

###
### Frost (dual-wield)
###
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T17M".
#	class=deathknight
#	spec=frost
#	talents=2001002

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
	GetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
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
	InterruptActions()
	#potion,name=draenic_strength,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=trinket2
	UseItemActions()
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
	#food,type=sleeper_surprise
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
		UsePotionStrength()
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
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
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
	if not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 Spell(howling_blast)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction FrostDualWieldSingleTargetShortCdActions
{
	#blood_tap,if=buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react))
	if BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } Spell(blood_tap)

	unless target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 Spell(blood_tap)
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

				unless not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike) or RunicPower() > 76 and Spell(frost_strike) or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate) or { not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast)
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
	unless target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and FrostDualWieldBosStCdPostConditions() or Spell(defile) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Spell(howling_blast) or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike) or SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) and Spell(frost_strike) or { Rune(death) >= 2 or Rune(frost) >= 2 } and Spell(howling_blast) or not target.DiseasesAnyTicking() and Spell(unholy_blight) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike) or RunicPower() > 76 and Spell(frost_strike) or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate) or { not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

###
### Frost (two-hander)
###
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T17M".
#	class=deathknight
#	spec=frost
#	talents=2001002

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
	GetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
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
	InterruptActions()
	#potion,name=draenic_strength,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=trinket2
	UseItemActions()
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
	#food,type=calamari_crepes
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
		UsePotionStrength()
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
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
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
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 Spell(blood_tap)
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
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost) or Spell(defile) or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(obliterate) or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) and Spell(howling_blast) or not target.DiseasesAnyTicking() and Spell(outbreak) or not target.DiseasesTicking() and Spell(unholy_blight)
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

###
### Unholy
###
# Based on SimulationCraft profile "Death_Knight_Unholy_T17M".
#	class=deathknight
#	spec=unholy
#	talents=2001002

### actions.default

AddFunction UnholyDefaultMainActions
{
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeMainActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetMainActions()
}

AddFunction UnholyDefaultShortCdActions
{
	#auto_attack
	GetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeShortCdActions()

	unless Enemies() >= 2 and UnholyAoeShortCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<2
		if Enemies() < 2 UnholySingleTargetShortCdActions()
	}
}

AddFunction UnholyDefaultCdActions
{
	#mind_freeze
	InterruptActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=draenic_strength,if=buff.dark_transformation.up&target.time_to_die<=60
	if pet.BuffPresent(dark_transformation_buff any=1) and target.TimeToDie() <= 60 UsePotionStrength()
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeCdActions()

	unless Enemies() >= 2 and UnholyAoeCdPostConditions()
	{
		#run_action_list,name=single_target,if=active_enemies<2
		if Enemies() < 2 UnholySingleTargetCdActions()
	}
}

### actions.aoe

AddFunction UnholyAoeMainActions
{
	#run_action_list,name=spread,if=(!dot.blood_plague.ticking|!dot.frost_fever.ticking)&!dot.necrotic_plague.ticking
	if { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and not target.DebuffPresent(necrotic_plague_debuff) UnholySpreadMainActions()
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeMainActions()
	#blood_boil,if=blood=2|(frost=2&death=2)
	if Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 Spell(blood_boil)
	#dark_transformation
	Spell(dark_transformation)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=45
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#scourge_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction UnholyAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and not target.DebuffPresent(necrotic_plague_debuff) and UnholySpreadShortCdPostConditions()
	{
		#defile
		Spell(defile)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeShortCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosAoeShortCdPostConditions() or { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil) or Spell(dark_transformation)
		{
			#blood_tap,if=level<=90&buff.shadow_infusion.stack=5
			if Level() <= 90 and BuffStacks(shadow_infusion_buff) == 5 Spell(blood_tap)
			#defile
			Spell(defile)
			#death_and_decay,if=unholy=1
			if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)

			unless target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike)
			{
				#blood_tap,if=buff.blood_charge.stack>10
				if BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)

				unless { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil)
				{
					#blood_tap
					Spell(blood_tap)
				}
			}
		}
	}
}

AddFunction UnholyAoeShortCdPostConditions
{
	{ not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and not target.DebuffPresent(necrotic_plague_debuff) and UnholySpreadShortCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and UnholyBosAoeShortCdPostConditions() or { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil) or Spell(dark_transformation) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike) or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
}

AddFunction UnholyAoeCdActions
{
	unless Spell(unholy_blight)
	{
		unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and not target.DebuffPresent(necrotic_plague_debuff) and UnholySpreadCdPostConditions() or Spell(defile)
		{
			#breath_of_sindragosa,if=runic_power>75
			if RunicPower() > 75 Spell(breath_of_sindragosa)
			#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
			if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeCdActions()

			unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosAoeCdPostConditions() or { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil)
			{
				#summon_gargoyle
				Spell(summon_gargoyle)

				unless Spell(dark_transformation) or Spell(defile) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike) or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
				{
					#empower_rune_weapon
					Spell(empower_rune_weapon)
				}
			}
		}
	}
}

AddFunction UnholyAoeCdPostConditions
{
	Spell(unholy_blight) or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and not target.DebuffPresent(necrotic_plague_debuff) and UnholySpreadCdPostConditions() or Spell(defile) or BuffPresent(breath_of_sindragosa_buff) and UnholyBosAoeCdPostConditions() or { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil) or Spell(dark_transformation) or Spell(defile) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike) or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
}

### actions.bos_aoe

AddFunction UnholyBosAoeMainActions
{
	#blood_boil,if=runic_power<88
	if RunicPower() < 88 Spell(blood_boil)
	#scourge_strike,if=runic_power<88&unholy=1
	if RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#icy_touch,if=runic_power<88
	if RunicPower() < 88 Spell(icy_touch)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosAoeShortCdActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)

	unless RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosAoeShortCdPostConditions
{
	RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

AddFunction UnholyBosAoeCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

AddFunction UnholyBosAoeCdPostConditions
{
	RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

### actions.bos_st

AddFunction UnholyBosStMainActions
{
	#festering_strike,if=runic_power<77
	if RunicPower() < 77 Spell(festering_strike)
	#scourge_strike,if=runic_power<88
	if RunicPower() < 88 Spell(scourge_strike)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosStShortCdActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)

	unless RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosStShortCdPostConditions
{
	RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

AddFunction UnholyBosStCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

AddFunction UnholyBosStCdPostConditions
{
	RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

### actions.precombat

AddFunction UnholyPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=calamari_crepes
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#unholy_presence
	Spell(unholy_presence)
}

AddFunction UnholyPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
	{
		#raise_dead
		Spell(raise_dead)
	}
}

AddFunction UnholyPrecombatShortCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
}

AddFunction UnholyPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

AddFunction UnholyPrecombatCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence) or Spell(raise_dead)
}

### actions.single_target

AddFunction UnholySingleTargetMainActions
{
	#plague_leech,if=(cooldown.outbreak.remains<1)&((blood<1&frost<1)|(blood<1&unholy<1)|(frost<1&unholy<1))
	if SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_leech,if=((blood<1&frost<1)|(blood<1&unholy<1)|(frost<1&unholy<1))&disease.min_remains<3
	if { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesRemaining() < 3 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_leech,if=disease.min_remains<1
	if target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#outbreak,if=!talent.necrotic_plague.enabled&!disease.ticking
	if not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() Spell(outbreak)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#soul_reaper,if=(target.health.pct-3*(target.health.pct%target.time_to_die))<=45
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 Spell(soul_reaper_unholy)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosStMainActions()
	#scourge_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(scourge_strike)
	#festering_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<76&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) Spell(festering_strike)
	#plague_strike,if=!disease.ticking&unholy=2
	if not target.DiseasesAnyTicking() and Rune(unholy) >= 2 Spell(plague_strike)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>80
	if RunicPower() > 80 Spell(death_coil)
	#festering_strike,if=blood=2&frost=2&(((Frost-death)>0)|((Blood-death)>0))
	if Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } Spell(festering_strike)
	#festering_strike,if=(blood=2|frost=2)&(((Frost-death)>0)&((Blood-death)>0))
	if { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 Spell(festering_strike)
	#plague_strike,if=!disease.ticking&(blood=2|frost=2)
	if not target.DiseasesAnyTicking() and { Rune(blood) >= 2 or Rune(frost) >= 2 } Spell(plague_strike)
	#scourge_strike,if=blood=2|frost=2
	if Rune(blood) >= 2 or Rune(frost) >= 2 Spell(scourge_strike)
	#festering_strike,if=((Blood-death)>1)
	if Rune(blood death=0) > 1 Spell(festering_strike)
	#blood_boil,if=((Blood-death)>1)
	if Rune(blood death=0) > 1 Spell(blood_boil)
	#festering_strike,if=((Frost-death)>1)
	if Rune(frost death=0) > 1 Spell(festering_strike)
	#plague_strike,if=!disease.ticking
	if not target.DiseasesAnyTicking() Spell(plague_strike)
	#dark_transformation
	Spell(dark_transformation)
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1)
	if BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 Spell(death_coil)
	#scourge_strike,if=!((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)|(Unholy>=2)
	if not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 Spell(scourge_strike)
	#festering_strike,if=!((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)|(((Frost-death)>0)&((Blood-death)>0))
	if not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(frost death=0) > 0 and Rune(blood death=0) > 0 Spell(festering_strike)
	#death_coil
	Spell(death_coil)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#scourge_strike,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(scourge_strike)
	#festering_strike,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(festering_strike)
	#blood_boil,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(blood_boil)
	#icy_touch,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(icy_touch)
}

AddFunction UnholySingleTargetShortCdActions
{
	unless SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesRemaining() < 3 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(outbreak)
	{
		#unholy_blight,if=!talent.necrotic_plague.enabled&disease.min_remains<3
		if not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 3 Spell(unholy_blight)
		#unholy_blight,if=talent.necrotic_plague.enabled&dot.necrotic_plague.remains<1
		if Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 Spell(unholy_blight)

		unless RunicPower() > 90 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy)
		{
			#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
			if BuffPresent(breath_of_sindragosa_buff) UnholyBosStShortCdActions()

			unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosStShortCdPostConditions()
			{
				#death_and_decay,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
				if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(death_and_decay)

				unless SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike)
				{
					#blood_tap,if=((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)&cooldown.soul_reaper.remains=0
					if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and not SpellCooldown(soul_reaper_unholy) > 0 Spell(blood_tap)
					#death_and_decay,if=unholy=2
					if Rune(unholy) >= 2 Spell(death_and_decay)
					#defile,if=unholy=2
					if Rune(unholy) >= 2 Spell(defile)

					unless not target.DiseasesAnyTicking() and Rune(unholy) >= 2 and Spell(plague_strike) or Rune(unholy) >= 2 and Spell(scourge_strike) or RunicPower() > 80 and Spell(death_coil) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike)
					{
						#defile,if=blood=2|frost=2
						if Rune(blood) >= 2 or Rune(frost) >= 2 Spell(defile)

						unless not target.DiseasesAnyTicking() and { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(plague_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(scourge_strike) or Rune(blood death=0) > 1 and Spell(festering_strike) or Rune(blood death=0) > 1 and Spell(blood_boil) or Rune(frost death=0) > 1 and Spell(festering_strike)
						{
							#blood_tap,if=((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)&cooldown.soul_reaper.remains=0
							if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and not SpellCooldown(soul_reaper_unholy) > 0 Spell(blood_tap)
							#death_and_decay
							Spell(death_and_decay)
							#defile
							Spell(defile)
							#blood_tap,if=cooldown.defile.remains=0
							if not SpellCooldown(defile) > 0 Spell(blood_tap)

							unless not target.DiseasesAnyTicking() and Spell(plague_strike) or Spell(dark_transformation)
							{
								#blood_tap,if=buff.blood_charge.stack>10&(buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1))
								if BuffStacks(blood_charge_buff) > 10 and { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } Spell(blood_tap)

								unless { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 } and Spell(scourge_strike)
								{
									#blood_tap
									Spell(blood_tap)
								}
							}
						}
					}
				}
			}
		}
	}
}

AddFunction UnholySingleTargetCdActions
{
	unless SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesRemaining() < 3 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(outbreak) or not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 3 and Spell(unholy_blight) or Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and Spell(unholy_blight) or RunicPower() > 90 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosStCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosStCdPostConditions() or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(death_and_decay) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike) or Rune(unholy) >= 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(defile) or not target.DiseasesAnyTicking() and Rune(unholy) >= 2 and Spell(plague_strike) or Rune(unholy) >= 2 and Spell(scourge_strike) or RunicPower() > 80 and Spell(death_coil) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(defile) or not target.DiseasesAnyTicking() and { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(plague_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(scourge_strike) or Rune(blood death=0) > 1 and Spell(festering_strike) or Rune(blood death=0) > 1 and Spell(blood_boil) or Rune(frost death=0) > 1 and Spell(festering_strike)
		{
			#summon_gargoyle
			Spell(summon_gargoyle)

			unless Spell(death_and_decay) or Spell(defile) or not target.DiseasesAnyTicking() and Spell(plague_strike) or Spell(dark_transformation) or { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 } and Spell(scourge_strike) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(frost death=0) > 0 and Rune(blood death=0) > 0 } and Spell(festering_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(scourge_strike) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(festering_strike) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(blood_boil) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(icy_touch)
			{
				#empower_rune_weapon,if=blood<1&unholy<1&frost<1
				if Rune(blood) < 1 and Rune(unholy) < 1 and Rune(frost) < 1 Spell(empower_rune_weapon)
			}
		}
	}
}

### actions.spread

AddFunction UnholySpreadMainActions
{
	#blood_boil,cycle_targets=1,if=!disease.ticking&!talent.necrotic_plague.enabled
	if not target.DiseasesAnyTicking() and not Talent(necrotic_plague_talent) Spell(blood_boil)
	#outbreak,if=!talent.necrotic_plague.enabled&!disease.ticking
	if not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() Spell(outbreak)
	#outbreak,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(outbreak)
	#plague_strike,if=!talent.necrotic_plague.enabled&!disease.ticking
	if not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() Spell(plague_strike)
	#plague_strike,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(plague_strike)
}

AddFunction UnholySpreadShortCdPostConditions
{
	not target.DiseasesAnyTicking() and not Talent(necrotic_plague_talent) and Spell(blood_boil) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(outbreak) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(outbreak) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(plague_strike) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(plague_strike)
}

AddFunction UnholySpreadCdPostConditions
{
	not target.DiseasesAnyTicking() and not Talent(necrotic_plague_talent) and Spell(blood_boil) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(outbreak) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(outbreak) or not Talent(necrotic_plague_talent) and not target.DiseasesAnyTicking() and Spell(plague_strike) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(plague_strike)
}
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "include")
end

do
	local name = "Ovale"	-- The default script.
	local desc = "[6.0] Ovale: Blood, Frost, Unholy"
	local code = [[
# Ovale death knight script based on SimulationCraft.

# Death knight rotation functions.
Include(ovale_deathknight)

### Blood icons.

AddCheckBox(opt_deathknight_blood_aoe L(AOE) default specialization=blood)

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=shortcd specialization=blood
{
	if not InCombat() BloodPrecombatShortCdActions()
	unless not InCombat() and BloodPrecombatShortCdPostConditions()
	{
		BloodDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_deathknight_blood_aoe help=shortcd specialization=blood
{
	if not InCombat() BloodPrecombatShortCdActions()
	unless not InCombat() and BloodPrecombatShortCdPostConditions()
	{
		BloodDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=blood
{
	if not InCombat() BloodPrecombatMainActions()
	BloodDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_blood_aoe help=aoe specialization=blood
{
	if not InCombat() BloodPrecombatMainActions()
	BloodDefaultMainActions()
}

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=cd specialization=blood
{
	if not InCombat() BloodPrecombatCdActions()
	unless not InCombat() and BloodPrecombatCdPostConditions()
	{
		BloodDefaultCdActions()
	}
}

AddIcon checkbox=opt_deathknight_blood_aoe help=cd specialization=blood
{
	if not InCombat() BloodPrecombatCdActions()
	unless not InCombat() and BloodPrecombatCdPostConditions()
	{
		BloodDefaultCdActions()
	}
}

### Frost icons.

AddCheckBox(opt_deathknight_frost_aoe L(AOE) default specialization=frost)

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=shortcd specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatShortCdActions()
		unless not InCombat() and FrostDualWieldPrecombatShortCdPostConditions()
		{
			FrostDualWieldDefaultShortCdActions()
		}
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatShortCdActions()
		unless not InCombat() and FrostTwoHanderPrecombatShortCdPostConditions()
		{
			FrostTwoHanderDefaultShortCdActions()
		}
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=shortcd specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatShortCdActions()
		unless not InCombat() and FrostDualWieldPrecombatShortCdPostConditions()
		{
			FrostDualWieldDefaultShortCdActions()
		}
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatShortCdActions()
		unless not InCombat() and FrostTwoHanderPrecombatShortCdPostConditions()
		{
			FrostTwoHanderDefaultShortCdActions()
		}
	}
}

AddIcon enemies=1 help=main specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatMainActions()
		FrostDualWieldDefaultMainActions()
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatMainActions()
		FrostTwoHanderDefaultMainActions()
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=aoe specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatMainActions()
		FrostDualWieldDefaultMainActions()
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatMainActions()
		FrostTwoHanderDefaultMainActions()
	}
}

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=cd specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatCdActions()
		unless not InCombat() and FrostDualWieldPrecombatCdPostConditions()
		{
			FrostDualWieldDefaultCdActions()
		}
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatCdActions()
		unless not InCombat() and FrostTwoHanderPrecombatCdPostConditions()
		{
			FrostTwoHanderDefaultCdActions()
		}
	}
}

AddIcon checkbox=opt_deathknight_frost_aoe help=cd specialization=frost
{
	if HasWeapon(offhand)
	{
		if not InCombat() FrostDualWieldPrecombatCdActions()
		unless not InCombat() and FrostDualWieldPrecombatCdPostConditions()
		{
			FrostDualWieldDefaultCdActions()
		}
	}
	if HasWeapon(offhand no)
	{
		if not InCombat() FrostTwoHanderPrecombatCdActions()
		unless not InCombat() and FrostTwoHanderPrecombatCdPostConditions()
		{
			FrostTwoHanderDefaultCdActions()
		}
	}
}

### Unholy icons.

AddCheckBox(opt_deathknight_unholy_aoe L(AOE) default specialization=unholy)

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=shortcd specialization=unholy
{
	if not InCombat() UnholyPrecombatShortCdActions()
	unless not InCombat() and UnholyPrecombatShortCdPostConditions()
	{
		UnholyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=shortcd specialization=unholy
{
	if not InCombat() UnholyPrecombatShortCdActions()
	unless not InCombat() and UnholyPrecombatShortCdPostConditions()
	{
		UnholyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=unholy
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=aoe specialization=unholy
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=cd specialization=unholy
{
	if not InCombat() UnholyPrecombatCdActions()
	unless not InCombat() and UnholyPrecombatCdPostConditions()
	{
		UnholyDefaultCdActions()
	}
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=cd specialization=unholy
{
	if not InCombat() UnholyPrecombatCdActions()
	unless not InCombat() and UnholyPrecombatCdPostConditions()
	{
		UnholyDefaultCdActions()
	}
}
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "script")
end
