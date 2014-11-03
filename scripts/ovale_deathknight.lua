local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_deathknight"
	local desc = "[6.0] Ovale: Blood, Frost, Unholy"
	local code = [[
# Ovale death knight script based on SimulationCraft.

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_armor ItemName(mountains_potion) default specialization=blood)
AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default specialization=!blood)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(mountains_potion usable=1)
}

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#da!12.20..
#	glyphs=vampiric_blood/regenerative_magic

# ActionList: BloodPrecombatActions --> main, shortcd, cd

AddFunction BloodPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#blood_presence
	Spell(blood_presence)
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#snapshot_stats
}

AddFunction BloodPrecombatShortCdActions
{
	unless Spell(blood_presence)
		or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
	{
		#bone_shield
		Spell(bone_shield)
	}
}

AddFunction BloodPrecombatCdActions
{
	unless Spell(blood_presence)
		or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
	{
		#potion,name=mountains
		UsePotionArmor()
	}
}

# ActionList: BloodDefaultActions --> main, shortcd, cd

AddFunction BloodDefaultActions
{
	#auto_attack
	#conversion,if=!buff.conversion.up&runic_power>50&health.pct<90
	if not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 Spell(conversion)
	# CHANGE: Cancel conversion if the trigger conditions no longer apply.
	if BuffPresent(conversion_buff) and not { RunicPower() > 50 and HealthPercent() < 90 } Spell(conversion text=cancel)
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
	#defile
	Spell(defile)
	#death_and_decay,if=active_enemies>2
	if Enemies() > 2 Spell(death_and_decay)
	#blood_boil,if=active_enemies>2&blood=2
	if Enemies() > 2 and Rune(blood) >= 2 Spell(blood_boil)
	#plague_leech,if=(!blood&!unholy|!blood&!frost|!unholy&!frost)&cooldown.outbreak.remains<=gcd
	if { not Rune(blood) >=1 and not Rune(unholy) >= 1 or not Rune(blood) >=1 and not Rune(frost) >= 1 or not Rune(unholy) >=1 and not Rune(frost) >= 1 } and SpellCooldown(outbreak) <= GCD() Spell(plague_leech)
	#call_action_list,name=bt,if=talent.blood_tap.enabled
	if Talent(blood_tap_talent) BloodBtActions()
	#call_action_list,name=re,if=talent.runic_empowerment.enabled
	if Talent(runic_empowerment_talent) BloodReActions()
	#call_action_list,name=rc,if=talent.runic_corruption.enabled
	if Talent(runic_corruption_talent) BloodRcActions()
	#call_action_list,name=nrt,if=!talent.blood_tap.enabled&!talent.runic_empowerment.enabled&!talent.runic_corruption.enabled
	if not Talent(blood_tap_talent) and not Talent(runic_empowerment_talent) and not Talent(runic_corruption_talent) BloodNrtActions()
	#blood_boil,if=buff.crimson_scourge.react
	if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
	#death_coil
	Spell(death_coil)
}

AddFunction BloodDefaultShortCdActions
{
	unless not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 and Spell(conversion)
		or BuffPresent(conversion_buff) and not { RunicPower() > 50 and HealthPercent() < 90 } and Spell(conversion text=cancel)
		or IncomingDamage(5) >= MaxHealth() * 0.65 and Spell(death_strike)
	{
		#bone_shield,if=buff.army_of_the_dead.down&buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
		if BuffExpires(army_of_the_dead_buff) and BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(bone_shield)
		#vampiric_blood,if=health.pct<50
		if HealthPercent() < 50 Spell(vampiric_blood)
		#rune_tap,if=health.pct<50&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down&buff.icebound_fortitude.down
		if HealthPercent() < 50 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) and BuffExpires(icebound_fortitude_buff) Spell(rune_tap)
		#death_pact,if=health.pct<50
		if HealthPercent() < 50 Spell(death_pact)

		unless { not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 8 or not target.DiseasesAnyTicking() } and Spell(outbreak)
			or RunicPower() > 90 and Spell(death_coil)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(plague_strike)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(icy_touch)
			or Spell(defile)
			or Enemies() > 2 and Spell(death_and_decay)
			or Enemies() > 2 and Rune(blood) >= 2 and Spell(blood_boil)
			or Talent(blood_tap_talent) and BloodBtActions()
			or Talent(runic_empowerment_talent) and BloodReActions()
			or Talent(runic_corruption_talent) and BloodRcActions()
			or not Talent(blood_tap_talent) and not Talent(runic_empowerment_talent) and not Talent(runic_corruption_talent) and BloodNrtActions()
		{
			#death_and_decay,if=buff.crimson_scourge.react
			if BuffPresent(crimson_scourge_buff) Spell(death_and_decay)

			unless BuffPresent(crimson_scourge_buff) and Spell(blood_boil)
			{
				#empower_rune_weapon,if=!blood&!unholy&!frost
				if not Rune(blood) >= 1 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(empower_rune_weapon)
			}
		}
	}
}

AddFunction BloodDefaultCdActions
{
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=mountains,if=buff.potion.down&buff.blood_shield.down&!unholy&!frost
	if BuffExpires(potion_armor_buff) and BuffExpires(blood_shield_buff) and not Rune(unholy) >= 1 and not Rune(frost) >= 1 UsePotionArmor()
	#antimagic_shell
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)

	unless not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 and Spell(conversion)
		or BuffPresent(conversion_buff) and not { RunicPower() > 50 and HealthPercent() < 90 } and Spell(conversion text=cancel)
	{
		#lichborne,if=health.pct<90
		if HealthPercent() < 90 Spell(lichborne)

		unless IncomingDamage(5) >= MaxHealth() * 0.65 and Spell(death_strike)
		{
			#army_of_the_dead,if=buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
			if BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(army_of_the_dead)
			#icebound_fortitude,if=health.pct<30&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down
			if HealthPercent() < 30 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(icebound_fortitude)
			#dancing_rune_weapon,if=health.pct<80&buff.army_of_the_dead.down&buff.icebound_fortitude.down&buff.bone_shield.down&buff.vampiric_blood.down
			if HealthPercent() < 80 and BuffExpires(army_of_the_dead_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(dancing_rune_weapon)
		}
	}
}

# ActionList: BloodBtActions --> main

AddFunction BloodBtActions
{
	#death_strike,if=unholy=2&frost=2
	if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
	#blood_tap,if=buff.blood_charge.stack>=5&!blood
	if BuffStacks(blood_charge_buff) >= 5 and not Rune(blood) >= 1 Spell(blood_tap)
	#death_strike,if=buff.blood_charge.stack>=10&unholy&frost
	if BuffStacks(blood_charge_buff) >= 10 and Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	#blood_tap,if=buff.blood_charge.stack>=10&!unholy&!frost
	if BuffStacks(blood_charge_buff) >= 10 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(blood_tap)
	#blood_tap,if=buff.blood_charge.stack>=5&(unholy&!frost|!unholy&frost)
	if BuffStacks(blood_charge_buff) >= 5 and { Rune(unholy) >= 1 and not Rune(frost) >= 1 or not Rune(unholy) >= 1 and Rune(frost) >= 1 } Spell(blood_tap)
	#blood_tap,if=buff.blood_charge.stack>=5&blood.death&!unholy&!frost XXX
	if BuffStacks(blood_charge_buff) >= 5 and DeathRune(blood) >= 1 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(blood_tap)
	#call_action_list,name=blood,if=blood>=2|(blood&!blood.death) XXX
	if Rune(blood) >= 2 or Rune(blood) >= 1 and DeathRune(blood) < 1 BloodBloodActions()
}

# ActionList: BloodReActions --> main

AddFunction BloodReActions
{
	#death_strike,if=unholy&frost
	if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	#call_action_list,name=blood,if=blood=2
	if Rune(blood) >= 2 BloodBloodActions()
}

# ActionList: BloodRcActions --> main

AddFunction BloodRcActions
{
	#death_strike,if=unholy=2&frost=2
	if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
	#call_action_list,name=blood,if=blood=2
	if Rune(blood) >= 2 BloodBloodActions()
}

# ActionList: BloodNrtActions --> main

AddFunction BloodNrtActions
{
	#death_strike,if=unholy=2&frost=2
	if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
	#call_action_list,name=blood,if=blood>=1
	if Rune(blood) >= 1 BloodBloodActions()
}

# ActionList: BloodBloodActions --> main

AddFunction BloodBloodActions
{
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_blood)
	#blood_boil
	Spell(blood_boil)
}

### Blood icons
AddCheckBox(opt_deathknight_blood_aoe L(AOE) specialization=blood default)

AddIcon specialization=blood help=shortcd enemies=1 checkbox=!opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatShortCdActions()
	BloodDefaultShortCdActions()
}

AddIcon specialization=blood help=shortcd checkbox=opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatShortCdActions()
	BloodDefaultShortCdActions()
}

AddIcon specialization=blood help=main enemies=1
{
	if InCombat(no) BloodPrecombatActions()
	BloodDefaultActions()
}

AddIcon specialization=blood help=aoe checkbox=opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatActions()
	BloodDefaultActions()
}

AddIcon specialization=blood help=cd enemies=1 checkbox=!opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatCdActions()
	BloodDefaultCdActions()
}

AddIcon specialization=blood help=cd checkbox=opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatCdActions()
	BloodDefaultCdActions()
}

###
### Frost (dual-wield)
###
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T16M".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1..0...

# ActionList: FrostDualWieldPrecombatActions --> main, shortcd, cd

AddFunction FrostDualWieldPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
	#snapshot_stats
}

AddFunction FrostDualWieldPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostDualWieldPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(frost_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=mogu_power
		UsePotionStrength()
	}
}

# ActionList: FrostDualWieldDefaultActions --> main, shortcd, cd

AddFunction FrostDualWieldDefaultActions
{
	#auto_attack
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeActions()
	#call_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetActions()
}

AddFunction FrostDualWieldDefaultShortCdActions
{
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeShortCdActions()
	#call_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetShortCdActions()
}

AddFunction FrostDualWieldDefaultCdActions
{
	#potion,name=mogu_power,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetCdActions()
}

# ActionList: FrostDualWieldBosStActions --> main, shortcd, cd

AddFunction FrostDualWieldBosStActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and target.DiseasesTicking() Spell(plague_leech)
	#howling_blast,if=runic_power<88
	if RunicPower() < 88 Spell(howling_blast)
	#obliterate,if=unholy>0&runic_power<76
	if Rune(unholy) >= 1 and RunicPower() < 76 Spell(obliterate)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
}

AddFunction FrostDualWieldBosStShortCdActions
{
	unless BuffPresent(killing_machine_buff) and Spell(obliterate)
	{
		#blood_tap,if=buff.killing_machine.react&buff.blood_charge.stack>=5
		if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless BuffPresent(killing_machine_buff) and target.DiseasesTicking() and Spell(plague_leech)
			or RunicPower() < 88 Spell(howling_blast)
			or Rune(unholy) >= 1 and RunicPower() < 76 Spell(obliterate)
		{
			#blood_tap,if=buff.blood_charge.stack>=5
			if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction FrostDualWieldBosStCdActions
{
	unless BuffPresent(killing_machine_buff) and Spell(obliterate)
		or BuffPresent(killing_machine_buff) and target.DiseasesTicking() and Spell(plague_leech)
		or RunicPower() < 88 and Spell(howling_blast)
		or Rune(unholy) >= 1 and RunicPower() < 76 and Spell(obliterate)
		or target.DiseasesTicking() Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: FrostDualWieldAoeActions --> main, shortcd, cd

AddFunction FrostDualWieldAoeActions
{
	#blood_boil,if=dot.blood_plague.ticking&(!talent.unholy_blight.enabled|cooldown.unholy_blight.remains<49),line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#defile
	Spell(defile)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if target.DebuffPresent(breath_of_sindragosa_debuff) FrostDualWieldBosAoeActions()
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=runic_power>88
	if RunicPower() > 88 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#frost_strike,if=!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>=10
	if not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 Spell(frost_strike)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostDualWieldAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
		or Spell(defile)
	{
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if target.DebuffPresent(breath_of_sindragosa_debuff) FrostDualWieldBosAoeShortCdActions()

		unless Spell(howling_blast)
		{
			#blood_tap,if=buff.blood_charge.stack>10
			if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless RunicPower() > 88 and Spell(frost_strike)
				or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
				or Rune(unholy) >= 2 and Spell(plague_strike)
			{
				#blood_tap
				if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
			}
		}
	}
}

AddFunction FrostDualWieldAoeCdActions
{
	unless Spell(unholy_blight)
		or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
		or Spell(defile)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosAoeCdActions()

		unless Spell(howling_blast)
			or RunicPower() > 88 and Spell(frost_strike)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
			or Rune(unholy) >= 2 and Spell(plague_strike)
			or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike)
			or target.DiseasesTicking() and Spell(plague_leech)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(plague_strike)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

# ActionList: FrostDualWieldBosAoeActions --> main, shortcd, cd

AddFunction FrostDualWieldBosAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostDualWieldBosAoeShortCdActions
{
	unless Spell(howling_blast)
	{
		#blood_tap,if=buff.blood_charge.stack>10
		if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
			or Rune(unholy) >= 2 and Spell(plague_strike)
		{
			#blood_tap
			if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction FrostDualWieldBosAoeCdActions
{
	unless Spell(howling_blast)
		or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
		or Rune(unholy) >= 2 and Spell(plague_strike)
		or target.DiseasesTicking() and Spell(plague_leech)
		or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: FrostDualWieldSingleTargetActions --> main, shortcd, cd

AddFunction FrostDualWieldSingleTargetActions
{
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStActions()
	#defile
	Spell(defile)
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
	#frost_strike,if=runic_power>=76
	if RunicPower() >= 76 Spell(frost_strike)
	#obliterate,if=unholy>0&!buff.killing_machine.react
	if Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast,if=!(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains<3)|death+frost>=2
	if not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 Spell(howling_blast)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
}

AddFunction FrostDualWieldSingleTargetShortCdActions
{
	#blood_tap,if=buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react))
	if BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

	unless target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostDualWieldBosStShortCdActions()

		unless Spell(defile)
		{
			#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
			if Talent(defile_talent) and not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Spell(howling_blast)
				or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 and Spell(obliterate)
				or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike)
				or SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) and Spell(frost_strike)
				or { Rune(death) >= 2 or Rune(frost) >= 2 } and Spell(howling_blast)
			{
				#unholy_blight,if=!disease.ticking
				if not target.DiseasesAnyTicking() Spell(unholy_blight)

				unless not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
					or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast)
					or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike)
					or BuffPresent(rime_buff) and Spell(howling_blast)
					or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike)
					or RunicPower() >= 76 and Spell(frost_strike)
					or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate)
					or { not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast)
				{
					#blood_tap
					if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
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

		unless Spell(defile)
			or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Spell(howling_blast)
			or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 and Spell(obliterate)
			or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike)
			or SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) and Spell(frost_strike)
			or { Rune(death) >= 2 or Rune(frost) >= 2 } and Spell(howling_blast)
			or not target.DiseasesAnyTicking() and Spell(unholy_blight)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
			or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 and Spell(plague_strike)
			or BuffPresent(rime_buff) and Spell(howling_blast)
			or ArmorSetBonus(T17 2) == 1 and RunicPower() >= 50 and SpellCooldown(pillar_of_frost) < 5 and Spell(frost_strike)
			or RunicPower() >= 76 and Spell(frost_strike)
			or Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) and Spell(obliterate)
			or { not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 3 } or RuneCount(death) + RuneCount(frost) >= 2 } and Spell(howling_blast)
			or target.DiseasesTicking() and Spell(plague_leech)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

###
### Frost (two-hander)
###
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T16M".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1..0...

# ActionList: FrostTwoHanderPrecombatActions --> main, shortcd, cd

AddFunction FrostTwoHanderPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
	#snapshot_stats
}

AddFunction FrostTwoHanderPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostTwoHanderPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(frost_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=mogu_power
		UsePotionStrength()
	}
}

# ActionList: FrostTwoHanderDefaultActions --> main, shortcd, cd

AddFunction FrostTwoHanderDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostTwoHanderAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHanderSingleTargetActions()
}

AddFunction FrostTwoHanderDefaultShortCdActions
{
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostTwoHanderAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHanderSingleTargetShortCdActions()
}

AddFunction FrostTwoHanderDefaultCdActions
{
	#potion,name=mogu_power,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostTwoHanderAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHanderSingleTargetCdActions()
}

# ActionList: FrostTwoHanderBosStActions --> main, shortcd, cd

AddFunction FrostTwoHanderBosStActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and target.DiseasesTicking() Spell(plague_leech)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
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
		if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless BuffPresent(killing_machine_buff) and target.DiseasesTicking() and Spell(plague_leech)
		{
			#blood_tap,if=buff.blood_charge.stack>=5
			if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}	
}

AddFunction FrostTwoHanderBosStCdActions {}

# ActionList: FrostTwoHanderAoeActions --> main, shortcd, cd

AddFunction FrostTwoHanderAoeActions
{
	#blood_boil,if=dot.blood_plague.ticking&(!talent.unholy_blight.enabled|cooldown.unholy_blight.remains<49),line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#defile
	Spell(defile)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeActions()
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=runic_power>88
	if RunicPower() > 88 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#frost_strike,if=!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>=10
	if not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 Spell(frost_strike)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostTwoHanderAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
		or Spell(defile)
	{
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeShortCdActions()

		unless Spell(howling_blast)
		{
			#blood_tap,if=buff.blood_charge.stack>10
			if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless RunicPower() > 88 and Spell(frost_strike)
				or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
				or Rune(unholy) >= 2 and Spell(plague_strike)
			{
				#blood_tap
				if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
			}
		}
	}
}

AddFunction FrostTwoHanderAoeCdActions
{
	unless Spell(unholy_blight)
		or target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 and Spell(blood_boil)
		or Spell(defile)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeCdActions()

		unless Spell(howling_blast)
			or BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
			or RunicPower() > 88 and Spell(frost_strike)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
			or Rune(unholy) >= 2 and Spell(plague_strike)
			or { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 } and Spell(frost_strike)
			or target.DiseasesTicking() and Spell(plague_leech)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(plague_strike)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

# ActionList: FrostTwoHanderBosAoeActions --> main, shortcd, cd

AddFunction FrostTwoHanderBosAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
}

AddFunction FrostTwoHanderBosAoeShortCdActions
{
	unless Spell(howling_blast)
	{
		#blood_tap,if=buff.blood_charge.stack>10
		if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
			or Rune(unholy) >= 2 and Spell(plague_strike)
		{
			#blood_tap
			if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction FrostTwoHanderBosAoeCdActions
{
	unless Spell(howling_blast)
		or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
		or Rune(unholy) >= 2 and Spell(plague_strike)
		or target.DiseasesTicking() and Spell(plague_leech)
		or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: FrostTwoHanderSingleTargetActions --> main, shortcd, cd

AddFunction FrostTwoHanderSingleTargetActions
{
	#plague_leech,if=disease.min_remains<1
	if target.DiseasesRemaining() < 1 and target.DiseasesTicking() Spell(plague_leech)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
	#defile
	Spell(defile)
	#howling_blast,if=buff.rime.react&disease.min_remains>5&buff.killing_machine.react
	if BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking&buff.rime.react
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) Spell(howling_blast)
	#outbreak,if=!disease.max_ticking
	if not target.DiseasesAnyTicking() Spell(outbreak)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosStActions()
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
	if target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() Spell(plague_leech)
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
	if { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() Spell(plague_leech)
}

AddFunction FrostTwoHanderSingleTargetShortCdActions
{
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless Spell(defile)
		{
			#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
			if Talent(defile_talent) and not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) and Spell(howling_blast)
				or BuffPresent(killing_machine_buff) and Spell(obliterate)
			{
				#blood_tap,if=buff.killing_machine.react
				if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

				unless not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) and Spell(howling_blast)
					or not target.DiseasesAnyTicking() and Spell(outbreak)
				{
					#unholy_blight,if=!disease.min_ticking
					if not target.DiseasesTicking() Spell(unholy_blight)
					#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
					if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosStShortCdActions()

					unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Spell(obliterate)
						or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 88 and Spell(howling_blast)
						or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
						or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast)
						or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike)
					{
						#blood_tap,if=buff.blood_charge.stack>10&runic_power>76
						if BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

						unless RunicPower() > 76 and Spell(frost_strike)
							or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(howling_blast)
							or { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(obliterate)
							or target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and Spell(plague_leech)
							or Talent(runic_empowerment_talent) and { Rune(frost) >= 0 and not Rune(frost) >= 1 or Rune(unholy) >= 0 and not Rune(unholy) >= 1 or Rune(blood) >= 0 and not Rune(blood) >= 1 } and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike)
							or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike)
							or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and Spell(howling_blast)
							or { Rune(blood) >= 1.5 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 or BuffPresent(burst_haste_buff any=1) or SpellCooldown(plague_leech) <= 4 } and Spell(obliterate)
						{
							#blood_tap,if=(buff.blood_charge.stack>10&runic_power>=20)|(blood.frac>=1.4|unholy.frac>=1.6|frost.frac>=1.6)
							if { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 or Rune(blood) >= 1.4 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
						}
					}
				}
			}
		}
	}
}

AddFunction FrostTwoHanderSingleTargetCdActions
{
	unless target.DiseasesRemaining() < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_frost)
		or Spell(defile)
		or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) and Spell(howling_blast)
		or BuffPresent(killing_machine_buff) Spell(obliterate)
		or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) and Spell(howling_blast)
		or not target.DiseasesAnyTicking() and Spell(outbreak)
		or not target.DiseasesTicking() and Spell(unholy_blight)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosStCdActions()

		unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Spell(obliterate)
			or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 88 and Spell(howling_blast)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
			or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(howling_blast)
			or not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike)
			or RunicPower() > 76 and Spell(frost_strike)
			or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(howling_blast)
			or { Rune(blood) >= 1.8 or Rune(unholy) >= 1.8 or Rune(frost) >= 1.8 } and Spell(obliterate)
			or target.DiseasesRemaining() < 3 and { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and Spell(plague_leech)
			or Talent(runic_empowerment_talent) and { Rune(frost) >= 0 and not Rune(frost) >= 1 or Rune(unholy) >= 0 and not Rune(unholy) >= 1 or Rune(blood) >= 0 and not Rune(blood) >= 1 } and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike)
			or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and { not BuffPresent(killing_machine_buff) or not TimeToSpell(obliterate) <= 1 } and Spell(frost_strike)
			or BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and Spell(howling_blast)
			or { Rune(blood) >= 1.5 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 or BuffPresent(burst_haste_buff any=1) or SpellCooldown(plague_leech) <= 4 } and Spell(obliterate)
			or not BuffPresent(killing_machine_buff) and Spell(frost_strike)
			or { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and Spell(plague_leech)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

### Frost icons.
AddCheckBox(opt_deathknight_frost_aoe L(AOE) specialization=frost default)

AddIcon specialization=frost help=shortcd enemies=1 checkbox=!opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatShortCdActions()
		FrostDualWieldDefaultShortCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatShortCdActions()
		FrostTwoHanderDefaultShortCdActions()
	}
}

AddIcon specialization=frost help=shortcd checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatShortCdActions()
		FrostDualWieldDefaultShortCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatShortCdActions()
		FrostTwoHanderDefaultShortCdActions()
	}
}

AddIcon specialization=frost help=main enemies=1
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatActions()
		FrostDualWieldDefaultActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatActions()
		FrostTwoHanderDefaultActions()
	}
}

AddIcon specialization=frost help=aoe checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatActions()
		FrostDualWieldDefaultActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatActions()
		FrostTwoHanderDefaultActions()
	}
}

AddIcon specialization=frost help=cd enemies=1 checkbox=!opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatCdActions()
		FrostDualWieldDefaultCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatCdActions()
		FrostTwoHanderDefaultCdActions()
	}
}

AddIcon specialization=frost help=cd checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatCdActions()
		FrostDualWieldDefaultCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHanderPrecombatCdActions()
		FrostTwoHanderDefaultCdActions()
	}
}

###
### Unholy
###
# Based on SimulationCraft profile "Death_Knight_Unholy_T16M".
#	class=deathknight
#	spec=unholy
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#db!1..2...

# ActionList: UnholyPrecombatActions --> main, shortcd, cd

AddFunction UnholyPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#unholy_presence
	Spell(unholy_presence)
	#snapshot_stats
}

AddFunction UnholyPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(unholy_presence)
	{
		#raise_dead
		Spell(raise_dead)
	}
}

AddFunction UnholyPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
		or Spell(unholy_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=mogu_power
		UsePotionStrength()
	}
}

# ActionList: UnholyDefaultActions --> main, shortcd, cd

AddFunction UnholyDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetActions()
}

AddFunction UnholyDefaultShortCdActions
{
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetShortCdActions()
}

AddFunction UnholyDefaultCdActions
{
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=mogu_power,if=buff.dark_transformation.up&target.time_to_die<=60
	if pet.BuffPresent(dark_transformation_buff any=1) and target.TimeToDie() <= 60 UsePotionStrength()
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetCdActions()
}

# ActionList: UnholyBosStActions --> main, shortcd, cd

AddFunction UnholyBosStActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)
	#festering_strike,if=runic_power<77
	if RunicPower() < 77 Spell(festering_strike)
	#scourge_strike,if=runic_power<88
	if RunicPower() < 88 Spell(scourge_strike)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosStShortCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay)
		or RunicPower() < 77 and Spell(festering_strike)
		or RunicPower() < 88 and Spell(scourge_strike)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosStCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay)
		or RunicPower() < 77 and Spell(festering_strike)
		or RunicPower() < 88 and Spell(scourge_strike)
		or target.DiseasesTicking() and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: UnholyAoeActions --> main, shortcd, cd

AddFunction UnholyAoeActions
{
	#plague_strike,if=!disease.ticking
	if not target.DiseasesAnyTicking() Spell(plague_strike)
	#defile
	Spell(defile)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeActions()
	#blood_boil,if=blood=2|(frost=2&death=2)
	if Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 Spell(blood_boil)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#defile
	Spell(defile)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#scourge_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#plague_leech,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 and target.DiseasesTicking() Spell(plague_leech)
}

AddFunction UnholyAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)

	unless not target.DiseasesAnyTicking() and Spell(plague_strike)
		or Spell(defile)
	{
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeShortCdActions()

		unless { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil)
		{
			#summon_gargoyle
			Spell(summon_gargoyle)

			unless BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
			{
				#blood_tap,if=buff.shadow_infusion.stack=5
				if BuffStacks(shadow_infusion_buff) == 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

				unless Spell(defile)
					or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
					or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_unholy)
					or Rune(unholy) >= 2 and Spell(scourge_strike)
				{
					#blood_tap,if=buff.blood_charge.stack>10
					if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

					unless { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 } and Spell(death_coil)
						or Spell(blood_boil)
						or Spell(icy_touch)
						or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(scourge_strike)
						or Spell(death_coil)
					{
						#blood_tap
						if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
					}
				}
			}
		}
	}
}

AddFunction UnholyAoeCdActions
{
	unless Spell(unholy_blight)
		or not target.DiseasesAnyTicking() and Spell(plague_strike)
		or Spell(defile)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeCdActions()

		unless { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil)
			or Spell(summon_gargoyle)
			or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
			or Spell(defile)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(death_and_decay)
			or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_unholy)
			or Rune(unholy) >= 2 and Spell(scourge_strike)
			or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 } and Spell(death_coil)
			or Spell(blood_boil)
			or Spell(icy_touch)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(scourge_strike)
			or Spell(death_coil)
			or Rune(unholy) >= 1 and not Rune(unholy) >= 2 and target.DiseasesTicking() and Spell(plague_leech)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

# ActionList: UnholyBosAoeActions --> main, shortcd, cd

AddFunction UnholyBosAoeActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)
	#blood_boil,if=runic_power<88
	if RunicPower() < 88 Spell(blood_boil)
	#scourge_strike,if=runic_power<88&unholy=1
	if RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#icy_touch,if=runic_power<88
	if RunicPower() < 88 Spell(icy_touch)
	#plague_leech
	if target.DiseasesTicking() Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosAoeShortCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay)
		or RunicPower() < 88 and Spell(blood_boil)
		or RunicPower() < 88 and Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(scourge_strike)
		or RunicPower() < 88 and Spell(icy_touch)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosAoeCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay)
		or RunicPower() < 88 and Spell(blood_boil)
		or RunicPower() < 88 and Rune(unholy) >= 1 and not Rune(unholy) >= 2 and Spell(scourge_strike)
		or RunicPower() < 88 and Spell(icy_touch)
		or target.DiseasesTicking() and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: UnholySingleTargetActions --> main, shortcd, cd

AddFunction UnholySingleTargetActions
{
	#plague_leech,if=cooldown.outbreak.remains<1
	if SpellCooldown(outbreak) < 1 and target.DiseasesTicking() Spell(plague_leech)
	#plague_leech,if=!talent.necrotic_plague.enabled&(dot.blood_plague.remains<1&dot.frost_fever.remains<1)
	if not Talent(necrotic_plague_talent) and target.DebuffRemaining(blood_plague_debuff) < 1 and target.DebuffRemaining(frost_fever_debuff) < 1 and target.DiseasesTicking() Spell(plague_leech)
	#plague_leech,if=talent.necrotic_plague.enabled&(dot.necrotic_plague.remains<1)
	if Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and target.DiseasesTicking() Spell(plague_leech)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_unholy)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#defile
	Spell(defile)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#outbreak,if=!talent.necrotic_plague.enabled&(!dot.frost_fever.ticking|!dot.blood_plague.ticking)
	if not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } Spell(outbreak)
	#outbreak,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(outbreak)
	#plague_strike,if=!talent.necrotic_plague.enabled&(!dot.blood_plague.ticking|!dot.frost_fever.ticking)
	if not Talent(necrotic_plague_talent) and { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } Spell(plague_strike)
	#plague_strike,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(plague_strike)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosStActions()
	#death_and_decay,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(death_and_decay)
	#scourge_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(scourge_strike)
	#festering_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<76&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) Spell(festering_strike)
	#death_and_decay,if=unholy=2
	if Rune(unholy) >= 2 Spell(death_and_decay)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>80
	if RunicPower() > 80 Spell(death_coil)
	#festering_strike,if=blood=2&frost=2
	if Rune(blood) >= 2 and Rune(frost) >= 2 Spell(festering_strike)
	#death_and_decay
	Spell(death_and_decay)
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 Spell(death_coil)
	#scourge_strike,if=!(target.health.pct-3*(target.health.pct%target.time_to_die)<=35)|(unholy>=1&death>=1)|(death>=2)
	if not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 or Rune(unholy) >= 1 and Rune(death) >= 1 or Rune(death) >= 2 Spell(scourge_strike)
	#festering_strike
	Spell(festering_strike)
	#death_coil
	Spell(death_coil)
}

AddFunction UnholySingleTargetShortCdActions
{
	unless SpellCooldown(outbreak) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or not Talent(necrotic_plague_talent) and target.DebuffRemaining(blood_plague_debuff) < 1 and target.DebuffRemaining(frost_fever_debuff) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_unholy)
	{
		#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
		if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		#summon_gargoyle
		Spell(summon_gargoyle)

		unless RunicPower() > 90 and Spell(death_coil)
			or Spell(defile)
			or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
		{
			#unholy_blight,if=!talent.necrotic_plague.enabled&(dot.frost_fever.remains<3|dot.blood_plague.remains<3)
			if not Talent(necrotic_plague_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)
			#unholy_blight,if=talent.necrotic_plague.enabled&dot.necrotic_plague.remains<1
			if Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 Spell(unholy_blight)

			unless not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak)
				or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(outbreak)
				or not Talent(necrotic_plague_talent) and { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
				or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(plague_strike)
			{
				#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
				if BuffPresent(breath_of_sindragosa_buff) UnholyBosStShortCdActions()

				unless SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(death_and_decay)
					or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike)
					or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike)
					or Rune(unholy) >= 2 and Spell(death_and_decay)
				{
					#blood_tap,if=unholy=2&cooldown.death_and_decay.remains=0
					if Rune(unholy) >= 2 and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

					unless Rune(unholy) >= 2 and Spell(scourge_strike)
						or RunicPower() > 80 and Spell(death_coil)
						or Rune(blood) >= 2 and Rune(frost) >= 2 and Spell(festering_strike)
						or Spell(death_and_decay)
					{
						#blood_tap,if=cooldown.death_and_decay.remains=0
						if not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
						#blood_tap,if=buff.blood_charge.stack>10&(buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1))
						if BuffStacks(blood_charge_buff) > 10 and { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

						unless BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 and Spell(death_coil)
							or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 or Rune(unholy) >= 1 and Rune(death) >= 1 or Rune(death) >= 2 } and Spell(scourge_strike)
							or Spell(festering_strike)
						{
							#blood_tap,if=buff.blood_charge.stack>=10&runic_power>=30
							if BuffStacks(blood_charge_buff) >= 10 and RunicPower() >= 30 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
						}
					}
				}
			}
		}
	}
}

AddFunction UnholySingleTargetCdActions
{
	unless SpellCooldown(outbreak) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or not Talent(necrotic_plague_talent) and target.DebuffRemaining(blood_plague_debuff) < 1 and target.DebuffRemaining(frost_fever_debuff) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and target.DiseasesTicking() and Spell(plague_leech)
		or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Spell(soul_reaper_unholy)
		or Spell(summon_gargoyle)
		or RunicPower() > 90 and Spell(death_coil)
		or Spell(defile)
		or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
		or not Talent(necrotic_plague_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(unholy_blight)
		or Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and Spell(unholy_blight)
		or not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak)
		or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(outbreak)
		or not Talent(necrotic_plague_talent) and { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
		or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Spell(plague_strike)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosStCdActions()

		unless SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(death_and_decay)
			or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike)
			or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike)
			or Rune(unholy) >= 2 and Spell(death_and_decay)
			or Rune(unholy) >= 2 and Spell(scourge_strike)
			or RunicPower() > 80 and Spell(death_coil)
			or Rune(blood) >= 2 and Rune(frost) >= 2 and Spell(festering_strike)
			or Spell(death_and_decay)
			or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Rune(unholy) >= 2 and Spell(death_coil)
			or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 or Rune(unholy) >= 1 and Rune(death) >= 1 or Rune(death) >= 2 } and Spell(scourge_strike)
			or Spell(festering_strike)
			or Spell(death_coil)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

### Unholy icons.
AddCheckBox(opt_deathknight_unholy_aoe L(AOE) specialization=unholy default)

AddIcon specialization=unholy help=shortcd enemies=1 checkbox=!opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=shortcd checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=main enemies=1
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

AddIcon specialization=unholy help=aoe checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

AddIcon specialization=unholy help=cd enemies=1 checkbox=!opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
}

AddIcon specialization=unholy help=cd checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("DEATHKNIGHT", "Ovale", desc, code, "script")
end
