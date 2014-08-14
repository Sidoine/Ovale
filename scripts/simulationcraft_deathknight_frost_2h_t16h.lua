local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Frost_2h_T16H"
	local desc = "[5.4] SimulationCraft: Death_Knight_Frost_2h_T16H"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Frost_2h_T16H".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1...0.
#	glyphs=loud_horn

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
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
	#mogu_power_potion
	UsePotionStrength()
	#pillar_of_frost
	Spell(pillar_of_frost)
	#raise_dead
	Spell(raise_dead)
}

AddFunction FrostDefaultActions
{
	#auto_attack
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#mogu_power_potion,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&(buff.mogu_power_potion.up|buff.golemblood_potion.up)
	if target.TimeToDie() <= 60 and { BuffPresent(mogu_power_potion_buff) or BuffPresent(golemblood_potion_buff) } Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=hands
	UseItemActions()
	#raise_dead
	Spell(raise_dead)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostSingleTargetActions()
}

AddFunction FrostAoeActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if Talent(unholy_blight_talent) Spell(unholy_blight)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Runes(unholy 2) Spell(plague_strike)
	#blood_tap,if=talent.blood_tap.enabled
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike
	Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#plague_leech,if=talent.plague_leech.enabled&unholy=1
	if Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#plague_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(plague_strike)
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction FrostSingleTargetActions
{
	#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<1|dot.frost_fever.remains<1))
	if Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#outbreak,if=!dot.frost_fever.ticking|!dot.blood_plague.ticking
	if not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) Spell(outbreak)
	#unholy_blight,if=talent.unholy_blight.enabled&((!dot.frost_fever.ticking|!dot.blood_plague.ticking))
	if Talent(unholy_blight_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } Spell(unholy_blight)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
	if Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#howling_blast,if=!dot.frost_fever.ticking
	if not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#plague_strike,if=!dot.blood_plague.ticking
	if not target.DebuffPresent(blood_plague_debuff) Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=talent.blood_tap.enabled&buff.killing_machine.react
	if Talent(blood_tap_talent) and BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>76)
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=blood=2|frost=2|unholy=2
	if Runes(blood 2) or Runes(frost 2) or Runes(unholy 2) Spell(obliterate)
	#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<3|dot.frost_fever.remains<3))
	if Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
	if target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 Spell(outbreak)
	#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
	if Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)
	#frost_strike,if=talent.runic_empowerment.enabled&(frost=0|unholy=0|blood=0)
	if Talent(runic_empowerment_talent) and { Runes(frost 0) and not Runes(frost 1) or Runes(unholy 0) and not Runes(unholy 1) or Runes(blood 0) and not Runes(blood 1) } Spell(frost_strike)
	#frost_strike,if=talent.blood_tap.enabled&buff.blood_charge.stack<=10
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#obliterate
	Spell(obliterate)
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=20)
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	#frost_strike
	Spell(frost_strike)
	#plague_leech,if=talent.plague_leech.enabled
	if Talent(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
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
# blood_charge_buff
# blood_fury_ap
# blood_plague_debuff
# blood_tap
# blood_tap_talent
# death_and_decay
# empower_rune_weapon
# frost_fever_debuff
# frost_presence
# frost_strike
# golemblood_potion_buff
# horn_of_winter
# howling_blast
# killing_machine_buff
# mogu_power_potion
# mogu_power_potion_buff
# obliterate
# outbreak
# pestilence
# pillar_of_frost
# pillar_of_frost_buff
# plague_leech
# plague_leech_talent
# plague_strike
# raise_dead
# rime_buff
# runic_empowerment_talent
# soul_reaper_frost
# unholy_blight
# unholy_blight_talent
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
