local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Frost_2h_T16M"
	local desc = "[6.0.2] SimulationCraft: Death_Knight_Frost_2h_T16M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T16M".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1..0...

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction DiseasesRemaining
{
	if Talent(necrotic_plague_talent) target.DebuffRemaining(necrotic_plague_debuff)
	if Talent(necrotic_plague_talent no)
	{
		if target.DebuffRemaining(blood_plague_debuff) < target.DebuffRemaining(frost_fever_debuff) target.DebuffRemaining(blood_plague_debuff)
		if target.DebuffRemaining(blood_plague_debuff) >= target.DebuffRemaining(frost_fever_debuff) target.DebuffRemaining(frost_fever_debuff)
	}
}

AddFunction DiseasesTicking
{
	Talent(necrotic_plague_talent) and target.DebuffPresent(necrotic_plague_debuff) or Talent(necrotic_plague_talent no) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff)
}

AddFunction FrostPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#frost_presence
	if not Stance(deathknight_frost_presence) Spell(frost_presence)
	#snapshot_stats
	#army_of_the_dead
	Spell(army_of_the_dead)
	#potion,name=mogu_power
	UsePotionStrength()
	#pillar_of_frost
	Spell(pillar_of_frost)
}

AddFunction FrostDefaultActions
{
	#auto_attack
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#potion,name=mogu_power,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&buff.potion.up
	if target.TimeToDie() <= 60 and BuffPresent(potion_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostSingleTargetActions()
}

AddFunction FrostBosStActions
{
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=buff.killing_machine.react&buff.blood_charge.stack>=5
	if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and DiseasesTicking() Spell(plague_leech)
	#blood_tap,if=buff.blood_charge.stack>=5
	if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech
	if DiseasesTicking() Spell(plague_leech)
	#obliterate,if=runic_power<76
	if RunicPower() < 76 Spell(obliterate)
	#howling_blast,if=((death=1&frost=0&unholy=0)|death=0&frost=1&unholy=0)&runic_power<88
	if { Runes(death 1) and not Runes(death 2) and Runes(frost 0) and not Runes(frost 1) and Runes(unholy 0) and not Runes(unholy 1) or Runes(death 0) and not Runes(death 1) and Runes(frost 1) and not Runes(frost 2) and Runes(unholy 0) and not Runes(unholy 1) } and RunicPower() < 88 Spell(howling_blast)
}

AddFunction FrostAoeActions
{
	#unholy_blight
	Spell(unholy_blight)
	#blood_boil,if=!talent.necrotic_plague.enabled&dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if not Talent(necrotic_plague_talent) and target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#blood_boil,if=!talent.necrotic_plague.enabled&dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if not Talent(necrotic_plague_talent) and target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(blood_boil) > 28 Spell(blood_boil)
	#defile
	Spell(defile)
	#breath_of_sindragosa,if=runic_power>75
	if RunicPower() > 75 Spell(breath_of_sindragosa)
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=buff.blood_charge.stack>10
	if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Runes(unholy 2) Spell(plague_strike)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike
	Spell(frost_strike)
	#plague_leech,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) and DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(plague_strike)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction FrostBosAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=buff.blood_charge.stack>10
	if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#death_and_decay,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Runes(unholy 2) Spell(plague_strike)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) and DiseasesTicking() Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(plague_strike)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction FrostSingleTargetActions
{
	#plague_leech,if=disease.min_remains<1
	if DiseasesRemaining() < 1 and DiseasesTicking() Spell(plague_leech)
	#defile
	Spell(defile)
	#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
	if Talent(defile_talent) and not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#outbreak,if=!disease.min_ticking
	if not DiseasesTicking() Spell(outbreak)
	#unholy_blight,if=!disease.min_ticking
	if not DiseasesTicking() Spell(unholy_blight)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#breath_of_sindragosa,if=runic_power>75
	if RunicPower() > 75 Spell(breath_of_sindragosa)
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
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#blood_tap,if=buff.blood_charge.stack>10&runic_power>76
	if BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=blood=2|frost=2|unholy=2
	if Runes(blood 2) or Runes(frost 2) or Runes(unholy 2) Spell(obliterate)
	#plague_leech,if=disease.min_remains<3
	if DiseasesRemaining() < 3 and DiseasesTicking() Spell(plague_leech)
	#outbreak,if=disease.min_remains<3
	if DiseasesRemaining() < 3 Spell(outbreak)
	#unholy_blight,if=disease.min_remains<3
	if DiseasesRemaining() < 3 Spell(unholy_blight)
	#frost_strike,if=talent.runic_empowerment.enabled&(frost=0|unholy=0|blood=0)
	if Talent(runic_empowerment_talent) and { Runes(frost 0) and not Runes(frost 1) or Runes(unholy 0) and not Runes(unholy 1) or Runes(blood 0) and not Runes(blood 1) } Spell(frost_strike)
	#frost_strike,if=talent.blood_tap.enabled&buff.blood_charge.stack<=10
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 Spell(frost_strike)
	#obliterate
	Spell(obliterate)
	#blood_tap,if=buff.blood_charge.stack>10&runic_power>=20
	if BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike
	Spell(frost_strike)
	#plague_leech
	if DiseasesTicking() Spell(plague_leech)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddIcon specialization=frost help=main enemies=1
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
}

### Required symbols
# antimagic_shell
# arcane_torrent_runicpower
# army_of_the_dead
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# blood_tap_talent
# breath_of_sindragosa
# breath_of_sindragosa_talent
# death_and_decay
# deaths_advance
# defile
# defile_talent
# empower_rune_weapon
# frost_fever_debuff
# frost_presence
# frost_strike
# horn_of_winter
# howling_blast
# killing_machine_buff
# mogu_power_potion
# necrotic_plague_debuff
# necrotic_plague_talent
# obliterate
# outbreak
# pillar_of_frost
# pillar_of_frost_buff
# plague_leech
# plague_leech_talent
# plague_strike
# potion_buff
# rime_buff
# runic_empowerment_talent
# soul_reaper_frost
# unholy_blight
# unholy_blight_talent
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
