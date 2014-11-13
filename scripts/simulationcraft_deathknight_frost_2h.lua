local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Frost_2h_T17M"
	local desc = "[6.0] SimulationCraft: Death_Knight_Frost_2h_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T17M".
#	class=deathknight
#	spec=frost
#	talents=2001002

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default)

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

AddFunction FrostTwoHanderDefaultActions
{
	#auto_attack
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	if IncomingDamage(1.5) > 0 Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
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
	if Enemies() >= 3 FrostTwoHanderAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHanderSingleTargetActions()
}

AddFunction FrostTwoHanderAoeActions
{
	#unholy_blight
	Spell(unholy_blight)
	#blood_boil,if=dot.blood_plague.ticking&(!talent.unholy_blight.enabled|cooldown.unholy_blight.remains<49),line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and { not Talent(unholy_blight_talent) or SpellCooldown(unholy_blight) < 49 } and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#defile
	Spell(defile)
	#breath_of_sindragosa,if=runic_power>75
	if RunicPower() > 75 Spell(breath_of_sindragosa)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) FrostTwoHanderBosAoeActions()
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=buff.blood_charge.stack>10
	if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=runic_power>88
	if RunicPower() > 88 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>=10
	if not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) >= 10 Spell(frost_strike)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction FrostTwoHanderBosAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=buff.blood_charge.stack>10
	if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#death_and_decay,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(plague_strike)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction FrostTwoHanderBosStActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=buff.killing_machine.react&buff.blood_charge.stack>=5
	if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#blood_tap,if=buff.blood_charge.stack>=5
	if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#obliterate,if=runic_power<76
	if RunicPower() < 76 Spell(obliterate)
	#howling_blast,if=((death=1&frost=0&unholy=0)|death=0&frost=1&unholy=0)&runic_power<88
	if { Rune(death) >= 1 and Rune(death) < 2 and Rune(frost) >= 0 and Rune(frost) < 1 and Rune(unholy) >= 0 and Rune(unholy) < 1 or Rune(death) >= 0 and Rune(death) < 1 and Rune(frost) >= 1 and Rune(frost) < 2 and Rune(unholy) >= 0 and Rune(unholy) < 1 } and RunicPower() < 88 Spell(howling_blast)
}

AddFunction FrostTwoHanderPrecombatActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=calamari_crepes
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
	#snapshot_stats
	#army_of_the_dead
	Spell(army_of_the_dead)
	#potion,name=draenic_strength
	UsePotionStrength()
	#pillar_of_frost
	Spell(pillar_of_frost)
}

AddFunction FrostTwoHanderSingleTargetActions
{
	#plague_leech,if=disease.min_remains<1
	if target.DiseasesRemaining() < 1 and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#defile
	Spell(defile)
	#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
	if Talent(defile_talent) and not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#howling_blast,if=buff.rime.react&disease.min_remains>5&buff.killing_machine.react
	if BuffPresent(rime_buff) and target.DiseasesRemaining() > 5 and BuffPresent(killing_machine_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking&buff.rime.react
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) and BuffPresent(rime_buff) Spell(howling_blast)
	#outbreak,if=!disease.max_ticking
	if not target.DiseasesAnyTicking() Spell(outbreak)
	#unholy_blight,if=!disease.min_ticking
	if not target.DiseasesTicking() Spell(unholy_blight)
	#breath_of_sindragosa,if=runic_power>75
	if RunicPower() > 75 Spell(breath_of_sindragosa)
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
	#blood_tap,if=buff.blood_charge.stack>10&runic_power>76
	if BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
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
	#blood_tap,if=(buff.blood_charge.stack>10&runic_power>=20)|(blood.frac>=1.4|unholy.frac>=1.6|frost.frac>=1.6)
	if { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 or Rune(blood) >= 1.4 or Rune(unholy) >= 1.6 or Rune(frost) >= 1.6 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=!buff.killing_machine.react
	if not BuffPresent(killing_machine_buff) Spell(frost_strike)
	#plague_leech,if=(blood.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&unholy.frac<=0.95)|(frost.frac<=0.95&blood.frac<=0.95)
	if { Rune(blood) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(unholy) <= 0.95 or Rune(frost) <= 0.95 and Rune(blood) <= 0.95 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddIcon specialization=frost help=main enemies=1
{
	if not InCombat() FrostTwoHanderPrecombatActions()
	FrostTwoHanderDefaultActions()
}

AddIcon specialization=frost help=aoe
{
	if not InCombat() FrostTwoHanderPrecombatActions()
	FrostTwoHanderDefaultActions()
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
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
