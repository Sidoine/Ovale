local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Blood_T16M"
	local desc = "[6.0] SimulationCraft: Death_Knight_Blood_T16M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Blood_T16M".
#	class=deathknight
#	spec=blood
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#da!12.20..
#	glyphs=vampiric_blood/regenerative_magic

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_armor ItemName(mountains_potion) default)

AddFunction UsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(mountains_potion usable=1)
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

AddFunction BloodPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#blood_presence
	Spell(blood_presence)
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#snapshot_stats
	#potion,name=mountains
	UsePotionArmor()
	#bone_shield
	Spell(bone_shield)
}

AddFunction BloodDefaultActions
{
	#auto_attack
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#potion,name=mountains,if=buff.potion.down&buff.blood_shield.down&!unholy&!frost
	if BuffExpires(potion_armor_buff) and BuffExpires(blood_shield_buff) and not RuneCount(unholy) and not RuneCount(frost) UsePotionArmor()
	#antimagic_shell
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#conversion,if=!buff.conversion.up&runic_power>50&health.pct<90
	if not BuffPresent(conversion_buff) and RunicPower() > 50 and HealthPercent() < 90 Spell(conversion)
	#lichborne,if=health.pct<90
	if HealthPercent() < 90 Spell(lichborne)
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if IncomingDamage(5) >= MaxHealth() * 0.65 Spell(death_strike)
	#army_of_the_dead,if=buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
	if BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(army_of_the_dead)
	#bone_shield,if=buff.army_of_the_dead.down&buff.bone_shield.down&buff.dancing_rune_weapon.down&buff.icebound_fortitude.down&buff.vampiric_blood.down
	if BuffExpires(army_of_the_dead_buff) and BuffExpires(bone_shield_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(vampiric_blood_buff) Spell(bone_shield)
	#vampiric_blood,if=health.pct<50
	if HealthPercent() < 50 Spell(vampiric_blood)
	#icebound_fortitude,if=health.pct<30&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down
	if HealthPercent() < 30 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(icebound_fortitude)
	#rune_tap,if=health.pct<50&buff.army_of_the_dead.down&buff.dancing_rune_weapon.down&buff.bone_shield.down&buff.vampiric_blood.down&buff.icebound_fortitude.down
	if HealthPercent() < 50 and BuffExpires(army_of_the_dead_buff) and BuffExpires(dancing_rune_weapon_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) and BuffExpires(icebound_fortitude_buff) Spell(rune_tap)
	#dancing_rune_weapon,if=health.pct<80&buff.army_of_the_dead.down&buff.icebound_fortitude.down&buff.bone_shield.down&buff.vampiric_blood.down
	if HealthPercent() < 80 and BuffExpires(army_of_the_dead_buff) and BuffExpires(icebound_fortitude_buff) and BuffExpires(bone_shield_buff) and BuffExpires(vampiric_blood_buff) Spell(dancing_rune_weapon)
	#death_pact,if=health.pct<50
	if HealthPercent() < 50 Spell(death_pact)
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
	#death_strike,if=(unholy=2|frost=2)
	if Runes(unholy 2) or Runes(frost 2) Spell(death_strike)
	#death_coil,if=runic_power>70
	if RunicPower() > 70 Spell(death_coil)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and Runes(blood 1) Spell(soul_reaper_blood)
	#blood_boil,if=blood=2
	if Runes(blood 2) Spell(blood_boil)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#death_coil
	Spell(death_coil)
	#empower_rune_weapon,if=!blood&!unholy&!frost
	if not RuneCount(blood) and not RuneCount(unholy) and not RuneCount(frost) Spell(empower_rune_weapon)
}

AddIcon specialization=blood help=main enemies=1
{
	if not InCombat() BloodPrecombatActions()
	BloodDefaultActions()
}

AddIcon specialization=blood help=aoe
{
	if not InCombat() BloodPrecombatActions()
	BloodDefaultActions()
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
# empower_rune_weapon
# frost_fever_debuff
# horn_of_winter
# icebound_fortitude
# icebound_fortitude_buff
# icy_touch
# lichborne
# mind_freeze
# mountains_potion
# necrotic_plague_debuff
# necrotic_plague_talent
# outbreak
# plague_strike
# potion_armor_buff
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
