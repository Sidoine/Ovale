local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Blood_T17M"
	local desc = "[6.0] SimulationCraft: Death_Knight_Blood_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Blood_T17M".
#	class=deathknight
#	spec=blood
#	talents=2013102

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
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
				if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
			}
		}
	}
}

AddFunction BloodDefaultCdActions
{
	#auto_attack
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

AddFunction BloodPrecombatCdActions
{
	unless Spell(blood_presence) or BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter)
	{
		#snapshot_stats
		#potion,name=draenic_armor
		UsePotionArmor()
	}
}

### Blood icons.
AddCheckBox(opt_deathknight_blood_aoe L(AOE) specialization=blood default)

AddIcon specialization=blood help=shortcd enemies=1 checkbox=!opt_deathknight_blood_aoe
{
	if not InCombat() BloodPrecombatShortCdActions()
	BloodDefaultShortCdActions()
}

AddIcon specialization=blood help=shortcd checkbox=opt_deathknight_blood_aoe
{
	if not InCombat() BloodPrecombatShortCdActions()
	BloodDefaultShortCdActions()
}

AddIcon specialization=blood help=main enemies=1
{
	if not InCombat() BloodPrecombatMainActions()
	BloodDefaultMainActions()
}

AddIcon specialization=blood help=aoe checkbox=opt_deathknight_blood_aoe
{
	if not InCombat() BloodPrecombatMainActions()
	BloodDefaultMainActions()
}

AddIcon specialization=blood help=cd enemies=1 checkbox=!opt_deathknight_blood_aoe
{
	if not InCombat() BloodPrecombatCdActions()
	BloodDefaultCdActions()
}

AddIcon specialization=blood help=cd checkbox=opt_deathknight_blood_aoe
{
	if not InCombat() BloodPrecombatCdActions()
	BloodDefaultCdActions()
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
# bone_shield
# bone_shield_buff
# conversion
# conversion_buff
# dancing_rune_weapon
# dancing_rune_weapon_buff
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
# plague_strike
# quaking_palm
# rune_tap
# soul_reaper_blood
# strangulate
# vampiric_blood
# vampiric_blood_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
