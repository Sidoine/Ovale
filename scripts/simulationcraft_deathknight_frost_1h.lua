local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Frost_1h_T16M"
	local desc = "[6.0.2] SimulationCraft: Death_Knight_Frost_1h_T16M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T16M".
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

AddFunction DiseasesAnyTicking
{
	Talent(necrotic_plague_talent) and target.DebuffPresent(necrotic_plague_debuff) or not Talent(necrotic_plague_talent) and { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) }
}

AddFunction DiseasesTicking
{
	Talent(necrotic_plague_talent) and target.DebuffPresent(necrotic_plague_debuff) or not Talent(necrotic_plague_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff)
}

AddFunction FrostPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#frost_presence
	Spell(frost_presence)
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
	if target.TimeToDie() <= 60 and BuffPresent(potion_strength_buff) Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#call_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostAoeActions()
	#call_action_list,name=single_target,if=active_enemies<3
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
	#howling_blast,if=runic_power<88
	if RunicPower() < 88 Spell(howling_blast)
	#obliterate,if=unholy>0&runic_power<76
	if Runes(unholy 1) and RunicPower() < 76 Spell(obliterate)
	#blood_tap,if=buff.blood_charge.stack>=5
	if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech
	if DiseasesTicking() Spell(plague_leech)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
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
	#call_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if target.DebuffPresent(breath_of_sindragosa_debuff) FrostBosAoeActions()
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
	#blood_tap,if=buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react))
	if BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0)
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#breath_of_sindragosa,if=runic_power>75
	if RunicPower() > 75 Spell(breath_of_sindragosa)
	#call_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if target.DebuffPresent(breath_of_sindragosa_debuff) FrostBosStActions()
	#howling_blast,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<7&runic_power<88
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 Spell(howling_blast)
	#obliterate,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<3&runic_power<76
	if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 3 and RunicPower() < 76 Spell(obliterate)
	#defile
	Spell(defile)
	#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
	if Talent(defile_talent) and not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=buff.killing_machine.react|runic_power>88
	if BuffPresent(killing_machine_buff) or RunicPower() > 88 Spell(frost_strike)
	#frost_strike,if=cooldown.antimagic_shell.remains<1&runic_power>=50&!buff.antimagic_shell.up
	if SpellCooldown(antimagic_shell) < 1 and RunicPower() >= 50 and not BuffPresent(antimagic_shell_buff) Spell(frost_strike)
	#howling_blast,if=death>1|frost>1
	if Runes(death 2) or Runes(frost 2) Spell(howling_blast)
	#unholy_blight,if=!disease.ticking
	if not DiseasesAnyTicking() Spell(unholy_blight)
	#howling_blast,if=!talent.necrotic_plague.enabled&!dot.frost_fever.ticking
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#howling_blast,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(howling_blast)
	#plague_strike,if=!talent.necrotic_plague.enabled&!dot.blood_plague.ticking&unholy>0
	if not Talent(necrotic_plague_talent) and not target.DebuffPresent(blood_plague_debuff) and Runes(unholy 1) Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#frost_strike,if=set_bonus.tier17_2pc=1&(runic_power>=50|(cooldown.pillar_of_frost.remains<5))
	if ArmorSetBonus(T17 2) == 1 and { RunicPower() >= 50 or SpellCooldown(pillar_of_frost) < 5 } Spell(frost_strike)
	#frost_strike,if=runic_power>=50
	if RunicPower() >= 50 Spell(frost_strike)
	#obliterate,if=unholy>0&!buff.killing_machine.react
	if Runes(unholy 1) and not BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast,if=!(target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains<2)|death+frost>=2
	if not { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 35 and SpellCooldown(soul_reaper_frost) < 2 } or RuneCount(death) + RuneCount(frost) >= 2 Spell(howling_blast)
	#blood_tap,if=target.health.pct-3*(target.health.pct%target.time_to_die)>35|buff.blood_charge.stack>=8
	if { target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() > 35 or BuffStacks(blood_charge_buff) >= 8 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#blood_tap
	if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#plague_leech
	if DiseasesTicking() Spell(plague_leech)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddIcon specialization=frost help=main enemies=1
{
	if not InCombat() FrostPrecombatActions()
	FrostDefaultActions()
}

AddIcon specialization=frost help=aoe
{
	if not InCombat() FrostPrecombatActions()
	FrostDefaultActions()
}

### Required symbols
# antimagic_shell
# antimagic_shell_buff
# arcane_torrent_runicpower
# army_of_the_dead
# berserking
# blood_boil
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# breath_of_sindragosa
# breath_of_sindragosa_debuff
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
# pillar_of_frost
# pillar_of_frost_buff
# plague_leech
# plague_leech_talent
# plague_strike
# potion_strength_buff
# rime_buff
# soul_reaper_frost
# unholy_blight
# unholy_blight_talent
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
