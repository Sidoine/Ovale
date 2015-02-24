local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_death_knight_blood_t17m"
	local desc = "[6.1] SimulationCraft: Death_Knight_Blood_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Blood_T17M".
#	class=deathknight
#	spec=blood
#	talents=2012102

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=blood)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=blood)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=blood)

AddFunction BloodUsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction BloodGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(plague_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction BloodInterruptActions
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
	#plague_leech,if=((!blood&!unholy)|(!blood&!frost)|(!unholy&!frost))&cooldown.outbreak.remains<=gcd
	if { not Rune(blood) >= 1 and not Rune(unholy) >= 1 or not Rune(blood) >= 1 and not Rune(frost) >= 1 or not Rune(unholy) >= 1 and not Rune(frost) >= 1 } and SpellCooldown(outbreak) <= GCD() and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#call_action_list,name=bt,if=talent.blood_tap.enabled
	if Talent(blood_tap_talent) BloodBtMainActions()
	#call_action_list,name=re,if=talent.runic_empowerment.enabled
	if Talent(runic_empowerment_talent) BloodReMainActions()
	#call_action_list,name=rc,if=talent.runic_corruption.enabled
	if Talent(runic_corruption_talent) BloodRcMainActions()
	#call_action_list,name=nrt,if=!talent.blood_tap.enabled&!talent.runic_empowerment.enabled&!talent.runic_corruption.enabled
	if not Talent(blood_tap_talent) and not Talent(runic_empowerment_talent) and not Talent(runic_corruption_talent) BloodNrtMainActions()
	#blood_boil,if=buff.crimson_scourge.react
	if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
	#death_coil
	Spell(death_coil)
}

AddFunction BloodDefaultShortCdActions
{
	#auto_attack
	BloodGetInMeleeRange()
	#antimagic_shell
	if IncomingDamage(1.5 magic=1) > 0 Spell(antimagic_shell)

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

			unless { not Rune(blood) >= 1 and not Rune(unholy) >= 1 or not Rune(blood) >= 1 and not Rune(frost) >= 1 or not Rune(unholy) >= 1 and not Rune(frost) >= 1 } and SpellCooldown(outbreak) <= GCD() and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
			{
				unless Talent(blood_tap_talent) and BloodBtShortCdPostConditions()
				{
					unless Talent(runic_empowerment_talent) and BloodReShortCdPostConditions()
					{
						unless Talent(runic_corruption_talent) and BloodRcShortCdPostConditions()
						{
							unless not Talent(blood_tap_talent) and not Talent(runic_empowerment_talent) and not Talent(runic_corruption_talent) and BloodNrtShortCdPostConditions()
							{
								#defile,if=buff.crimson_scourge.react
								if BuffPresent(crimson_scourge_buff) Spell(defile)
								#death_and_decay,if=buff.crimson_scourge.react
								if BuffPresent(crimson_scourge_buff) Spell(death_and_decay)
							}
						}
					}
				}
			}
		}
	}
}

AddFunction BloodDefaultCdActions
{
	#mind_freeze
	BloodInterruptActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=draenic_armor,if=buff.potion.down&buff.blood_shield.down&!unholy&!frost
	if BuffExpires(potion_armor_buff) and BuffExpires(blood_shield_buff) and not Rune(unholy) >= 1 and not Rune(frost) >= 1 BloodUsePotionArmor()

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

			unless { not Talent(necrotic_plague_talent) and target.DiseasesRemaining() < 8 or not target.DiseasesAnyTicking() } and Spell(outbreak) or RunicPower() > 90 and Spell(death_coil) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(plague_strike) or { not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(icy_touch) or Spell(defile) or { not Rune(blood) >= 1 and not Rune(unholy) >= 1 or not Rune(blood) >= 1 and not Rune(frost) >= 1 or not Rune(unholy) >= 1 and not Rune(frost) >= 1 } and SpellCooldown(outbreak) <= GCD() and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
			{
				unless Talent(blood_tap_talent) and BloodBtCdPostConditions()
				{
					unless Talent(runic_empowerment_talent) and BloodReCdPostConditions()
					{
						unless Talent(runic_corruption_talent) and BloodRcCdPostConditions()
						{
							unless not Talent(blood_tap_talent) and not Talent(runic_empowerment_talent) and not Talent(runic_corruption_talent) and BloodNrtCdPostConditions() or BuffPresent(crimson_scourge_buff) and Spell(defile) or BuffPresent(crimson_scourge_buff) and Spell(death_and_decay) or BuffPresent(crimson_scourge_buff) and Spell(blood_boil) or Spell(death_coil)
							{
								#empower_rune_weapon,if=!blood&!unholy&!frost
								if not Rune(blood) >= 1 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(empower_rune_weapon)
							}
						}
					}
				}
			}
		}
	}
}

### actions.bt

AddFunction BloodBtMainActions
{
	#death_strike,if=unholy=2|frost=2
	if Rune(unholy) >= 2 or Rune(frost) >= 2 Spell(death_strike)
	#blood_tap,if=buff.blood_charge.stack>=5&!blood
	if BuffStacks(blood_charge_buff) >= 5 and not Rune(blood) >= 1 Spell(blood_tap)
	#death_strike,if=buff.blood_charge.stack>=10&unholy&frost
	if BuffStacks(blood_charge_buff) >= 10 and Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	#blood_tap,if=buff.blood_charge.stack>=10&!unholy&!frost
	if BuffStacks(blood_charge_buff) >= 10 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(blood_tap)
	#blood_tap,if=buff.blood_charge.stack>=5&(!unholy|!frost)
	if BuffStacks(blood_charge_buff) >= 5 and { not Rune(unholy) >= 1 or not Rune(frost) >= 1 } Spell(blood_tap)
	#blood_tap,if=buff.blood_charge.stack>=5&blood.death&!unholy&!frost
	if BuffStacks(blood_charge_buff) >= 5 and DeathRune(blood) >= 1 and not Rune(unholy) >= 1 and not Rune(frost) >= 1 Spell(blood_tap)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&(blood=2|(blood&!blood.death))
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and { Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 } Spell(soul_reaper_blood)
	#blood_boil,if=blood=2|(blood&!blood.death)
	if Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 Spell(blood_boil)
}

AddFunction BloodBtShortCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or BuffStacks(blood_charge_buff) >= 10 and Rune(unholy) >= 1 and Rune(frost) >= 1 and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and { Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 } and Spell(soul_reaper_blood) or { Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 } and Spell(blood_boil)
}

AddFunction BloodBtCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or BuffStacks(blood_charge_buff) >= 10 and Rune(unholy) >= 1 and Rune(frost) >= 1 and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and { Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 } and Spell(soul_reaper_blood) or { Rune(blood) >= 2 or Rune(blood) >= 1 and not DeathRune(blood) >= 1 } and Spell(blood_boil)
}

### actions.nrt

AddFunction BloodNrtMainActions
{
	#death_strike,if=unholy=2|frost=2
	if Rune(unholy) >= 2 or Rune(frost) >= 2 Spell(death_strike)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 Spell(soul_reaper_blood)
	#blood_boil,if=blood>=1
	if Rune(blood) >= 1 Spell(blood_boil)
}

AddFunction BloodNrtShortCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 1 and Spell(blood_boil)
}

AddFunction BloodNrtCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 1 and Spell(blood_boil)
}

### actions.precombat

AddFunction BloodPrecombatMainActions
{
	#flask,type=greater_draenic_stamina_flask
	#food,type=whiptail_fillet
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
		BloodUsePotionArmor()
	}
}

AddFunction BloodPrecombatCdPostConditions
{
	Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
}

### actions.rc

AddFunction BloodRcMainActions
{
	#death_strike,if=unholy=2|frost=2
	if Rune(unholy) >= 2 or Rune(frost) >= 2 Spell(death_strike)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 Spell(soul_reaper_blood)
	#blood_boil,if=blood=2
	if Rune(blood) >= 2 Spell(blood_boil)
}

AddFunction BloodRcShortCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil)
}

AddFunction BloodRcCdPostConditions
{
	{ Rune(unholy) >= 2 or Rune(frost) >= 2 } and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil)
}

### actions.re

AddFunction BloodReMainActions
{
	#death_strike,if=unholy&frost
	if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood=2
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 2 Spell(soul_reaper_blood)
	#blood_boil,if=blood=2
	if Rune(blood) >= 2 Spell(blood_boil)
}

AddFunction BloodReShortCdPostConditions
{
	Rune(unholy) >= 1 and Rune(frost) >= 1 and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 2 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil)
}

AddFunction BloodReCdPostConditions
{
	Rune(unholy) >= 1 and Rune(frost) >= 1 and Spell(death_strike) or RunicPower() > 70 and Spell(death_coil) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 2 and Spell(soul_reaper_blood) or Rune(blood) >= 2 and Spell(blood_boil)
}

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

### Required symbols
# antimagic_shell
# arcane_torrent_runicpower
# army_of_the_dead
# army_of_the_dead_buff
# asphyxiate
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_presence
# blood_shield_buff
# blood_tap
# blood_tap_talent
# bone_shield
# bone_shield_buff
# conversion
# conversion_buff
# crimson_scourge_buff
# dancing_rune_weapon
# dancing_rune_weapon_buff
# death_and_decay
# death_coil
# death_pact
# death_strike
# defile
# draenic_armor_potion
# empower_rune_weapon
# frost_fever_debuff
# horn_of_winter
# icebound_fortitude
# icebound_fortitude_buff
# icy_touch
# lichborne
# mind_freeze
# necrotic_plague_debuff
# necrotic_plague_talent
# outbreak
# plague_leech
# plague_strike
# potion_armor_buff
# quaking_palm
# rune_tap
# runic_corruption_talent
# runic_empowerment_talent
# soul_reaper_blood
# strangulate
# vampiric_blood
# vampiric_blood_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", "blood", name, desc, code, "script")
end
