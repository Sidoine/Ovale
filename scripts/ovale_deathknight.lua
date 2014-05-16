local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Blood, Frost, Unholy"
	local code = [[
# Ovale death knight script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_deathknight_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Blood
###

AddFunction BloodPrecombatActions
{
	if not Stance(deathknight_blood_presence) Spell(blood_presence)
	Spell(horn_of_winter)
	if BuffExpires(bone_shield_buff) Spell(bone_shield)
}

AddFunction BloodSurvivalBuffPresent
{
	BuffPresent(army_of_the_dead_buff)
		or BuffPresent(bone_shield_buff)
		or BuffPresent(dancing_rune_weapon_buff)
		or BuffPresent(icebound_fortitude_buff)
		or BuffPresent(vampiric_blood_buff)
}

AddFunction BloodApplyDiseases
{
	if target.DebuffRemains(blood_plague_debuff) < 2 or target.DebuffRemains(frost_fever_debuff) < 2
	{
		if DebuffCountOnAny(blood_plague_debuff excludeTarget=1) > 0 and DebuffCountOnAny(frost_fever_debuff excludeTarget=1) > 0 and { BuffPresent(crimson_scourge_buff) or Rune(blood) >= 1 } Spell(blood_boil)
		Spell(outbreak)
	}
	if target.DebuffExpires(blood_plague_debuff) Spell(plague_strike)
	if target.DebuffExpires(frost_fever_debuff) Spell(icy_touch)
}

AddFunction BloodSingleTargetActions
{
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if IncomingDamage(5) >= MaxHealth() * 0.65 Spell(death_strike)

	if { Rune(blood) < 2 or Rune(unholy) < 2 or Rune(frost) < 2 } and Spell(outbreak) PlagueLeech()
	BloodApplyDiseases()

	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 Spell(soul_reaper_blood)

	if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
	if Rune(blood) >= 1 and { target.DebuffRemains(frost_fever_debuff) <= 10 or target.DebuffRemains(blood_plague_debuff) <= 10 } Spell(blood_boil)

	if TalentPoints(blood_tap_talent)
	{
		# Try to store one death rune in a blood rune socket.
		if BuffStacks(blood_charge_buff) >= 5 and Rune(blood) < 1 Spell(blood_tap)
		if BuffStacks(blood_charge_buff) >= 10
		{
			if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
			if Rune(unholy) < 1 or Rune(frost) < 1 Spell(blood_tap)
		}
		if Rune(blood) >= 2 Spell(heart_strike)
	}
	if TalentPoints(runic_empowerment_talent)
	{
		if Rune(blood) >= 2 Spell(heart_strike)
		if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	}
	if TalentPoints(runic_corruption_talent)
	{
		# Try to put one rune of each set on cooldown to benefit from Runic Corruption procs.
		if Rune(blood) >= 2 Spell(heart_strike)
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
	}
	if not TalentPoints(blood_tap_talent) and not TalentPoints(runic_empowerment_talent) and not TalentPoints(runic_corruption_talent)
	{
		if Rune(blood) >= 2 Spell(heart_strike)
	}

	if not Glyph(glyph_of_outbreak) or RunicPower() >= 65 Spell(rune_strike)
	Spell(horn_of_winter)

	#death_strike,if=(unholy=2|frost=2)&incoming_damage_5s>=health.max*0.4
	if { Rune(unholy) >= 2 or Rune(frost) >= 2 } and IncomingDamage(5) >= HealthPercent() * 0.4 Spell(death_strike)
}

AddFunction BloodAoeActions
{
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if IncomingDamage(5) >= MaxHealth() * 0.65 Spell(death_strike)

	if BuffPresent(crimson_scourge_buff) Spell(death_and_decay)

	if { Rune(blood) < 2 or Rune(unholy) < 2 or Rune(frost) < 2 } and Spell(outbreak) PlagueLeech()
	BloodApplyDiseases()

	if target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff)
	{
		if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
		if DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 10 and DebuffRemainsOnAny(frost_fever_debuff excludeTarget=1) < 10
		{
			if TalentPoints(roiling_blood_talent) Spell(blood_boil)
			Spell(pestilence)
		}
	}

	if TalentPoints(blood_tap_talent)
	{
		# Try to store one death rune in a blood rune socket.
		if BuffStacks(blood_charge_buff) >= 5 and Rune(blood) < 1 Spell(blood_tap)
		if BuffStacks(blood_charge_buff) >= 10
		{
			if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
			if Rune(unholy) < 1 or Rune(frost) < 1 Spell(blood_tap)
		}
		if Rune(blood) >= 2 Spell(blood_boil)
	}
	if TalentPoints(runic_empowerment_talent)
	{
		if Rune(blood) >= 2 Spell(blood_boil)
		if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
	}
	if TalentPoints(runic_corruption_talent)
	{
		# Try to put one rune of each set on cooldown to benefit from Runic Corruption procs.
		if Rune(blood) >= 2 Spell(blood_boil)
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
	}
	if not TalentPoints(blood_tap_talent) and not TalentPoints(runic_empowerment_talent) and not TalentPoints(runic_corruption_talent)
	{
		if Rune(blood) >= 2 Spell(blood_boil)
	}

	if not Glyph(glyph_of_outbreak) or RunicPower() >= 65 Spell(rune_strike)
	Spell(horn_of_winter)

	#death_strike,if=(unholy=2|frost=2)&incoming_damage_5s>=health.max*0.4
	if { Rune(unholy) >= 2 or Rune(frost) >= 2 } and IncomingDamage(5) >= HealthPercent() * 0.4 Spell(death_strike)
}

AddFunction BloodShortCdActions
{
	if not BloodSurvivalBuffPresent() Spell(bone_shield)
	if HealthPercent() < 50 Spell(vampiric_blood)
	if HealthPercent() < 90 Spell(rune_tap)
	if HealthPercent() < 50 Spell(raise_dead)
	if TalentPoints(death_pact_talent) and TotemPresent(ghoul) and HealthPercent() < 50 Spell(death_pact)

	if Rune(unholy) < 1 and Rune(frost) < 1 and ArmorSetParts(T16_tank) >= 4 Spell(dancing_rune_weapon)
	if Rune(blood) < 1 and Rune(unholy) < 1 and Rune(frost) < 1 Spell(empower_rune_weapon)
	if BuffPresent(crimson_scourge_buff) Spell(death_and_decay)
	Spell(antimagic_shell)
}

AddFunction BloodCdActions
{
	if not BloodSurvivalBuffPresent()
	{
		if HealthPercent() < 30 Spell(icebound_fortitude)
		if HealthPercent() < 80 Spell(dancing_rune_weapon)
		Spell(army_of_the_dead)
	}
}

# Blood icons.

AddIcon mastery=blood size=small checkboxon=opt_icons_left
{
	Spell(antimagic_shell)
	Spell(icebound_fortitude)
}

AddIcon mastery=blood size=small checkboxon=opt_icons_left
{
	if TalentPoints(death_pact_talent)
	{
		Spell(raise_dead)
		if TotemPresent(ghoul) Spell(death_pact)
	}
	if TalentPoints(death_siphon_talent) Spell(death_siphon)
}

AddIcon mastery=blood help=shortcd
{
	BloodShortCdActions()
}

AddIcon mastery=blood help=main
{
	if InCombat(no) BloodPrecombatActions()
	BloodSingleTargetActions()
}

AddIcon mastery=blood help=aoe checkboxon=opt_aoe
{
	if InCombat(no) BloodPrecombatActions()
	BloodAoeActions()
}

AddIcon mastery=blood help=cd
{
	Interrupt()
	UseRacialInterruptActions()
	BloodCdActions()
}

AddIcon mastery=blood size=small checkboxon=opt_icons_right
{
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 Spell(pestilence)
}

AddIcon mastery=blood size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Frost
###
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T16H".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1...0.
#	glyphs=loud_horn

AddFunction FrostDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	#if Enemies() >= 3 FrostAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	#if Enemies() < 3 FrostSingleTargetActions()
}

AddFunction FrostDefaultShortCdActions
{
	#pillar_of_frost
	Spell(pillar_of_frost)
}

AddFunction FrostDefaultCdActions
{
	#mogu_power_potion,if=target.time_to_die<=30|(target.time_to_die<=60&buff.pillar_of_frost.up)
	if target.TimeToDie() <= 30 or { target.TimeToDie() <= 60 and BuffPresent(pillar_of_frost_buff) } UsePotionStrength()
	#empower_rune_weapon,if=target.time_to_die<=60&(buff.mogu_power_potion.up|buff.golemblood_potion.up)
	if target.TimeToDie() <= 60 and { BuffPresent(mogu_power_potion_buff) or BuffPresent(golemblood_potion_buff) } Spell(empower_rune_weapon)
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent)
	#use_item,slot=hands
	UseItemActions()
	#raise_dead
	Spell(raise_dead)
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
}

AddFunction FrostPrecombatShortCdActions
{
	if Stance(deathknight_frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostPrecombatCdActions
{
	if Stance(deathknight_frost_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#mogu_power_potion
		UsePotionStrength()
		#raise_dead
		Spell(raise_dead)
	}
}

AddFunction FrostOneHandAoeActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if TalentPoints(unholy_blight_talent) Spell(unholy_blight)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 BloodTap()
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#blood_tap,if=talent.blood_tap.enabled
	if TalentPoints(blood_tap_talent) BloodTap()
	#frost_strike
	Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#plague_leech,if=talent.plague_leech.enabled&unholy=1
	if TalentPoints(plague_leech_talent) and { Rune(unholy) >= 1 and Rune(unholy) < 2 } PlagueLeech()
	#plague_strike,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(plague_strike)
}

AddFunction FrostOneHandSingleTargetActions
{
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react)))
	if TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or { RunicPower() >= 20 and BuffPresent(killing_machine_buff) } } } BloodTap()
	#frost_strike,if=buff.killing_machine.react|runic_power>88
	if BuffPresent(killing_machine_buff) or RunicPower() > 88 Spell(frost_strike)
	#howling_blast,if=death>1|frost>1
	if Rune(death) >= 2 or Rune(frost) >= 2 Spell(howling_blast)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
	if TalentPoints(blood_tap_talent) and { { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 } } BloodTap()
	#howling_blast,if=!dot.frost_fever.ticking
	if not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#plague_strike,if=!dot.blood_plague.ticking&unholy>0
	if not target.DebuffPresent(blood_plague_debuff) and Rune(unholy) >= 1 Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=unholy>0&!buff.killing_machine.react
	if Rune(unholy) >= 1 and not BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=talent.runic_empowerment.enabled&unholy=1
	if TalentPoints(runic_empowerment_talent) and { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(frost_strike)
	#blood_tap,if=talent.blood_tap.enabled&(target.health.pct-3*(target.health.pct%target.time_to_die)>35|buff.blood_charge.stack>=8)
	if TalentPoints(blood_tap_talent) and { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } > 35 or BuffStacks(blood_charge_buff) >= 8 } BloodTap()
	#frost_strike,if=runic_power>=40
	if RunicPower() >= 40 Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#blood_tap,if=talent.blood_tap.enabled
	if TalentPoints(blood_tap_talent) BloodTap()
	#plague_leech,if=talent.plague_leech.enabled
	if TalentPoints(plague_leech_talent) PlagueLeech()
}

AddFunction FrostOneHandSingleTargetShortCdActions
{
	unless { TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or { RunicPower() >= 20 and BuffPresent(killing_machine_buff) } } } }
		or { { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike) }
		or { Rune(death) >= 2 or Rune(frost) >= 2 }
	{
		#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
		if TalentPoints(unholy_blight_talent) and { { target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 } } Spell(unholy_blight)
	}
}

# Based on SimulationCraft profile "Death_Knight_Frost_2h_T16H".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1...0.
#	glyphs=loud_horn

AddFunction FrostTwoHandAoeActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if TalentPoints(unholy_blight_talent) Spell(unholy_blight)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#howling_blast
	Spell(howling_blast)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 BloodTap()
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#death_and_decay,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(death_and_decay)
	#plague_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(plague_strike)
	#blood_tap,if=talent.blood_tap.enabled
	if TalentPoints(blood_tap_talent) BloodTap()
	#frost_strike
	Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#plague_leech,if=talent.plague_leech.enabled&unholy=1
	if TalentPoints(plague_leech_talent) and { Rune(unholy) >= 1 and Rune(unholy) < 2 } PlagueLeech()
	#plague_strike,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(plague_strike)
}

AddFunction FrostTwoHandSingleTargetActions
{
	#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<1|dot.frost_fever.remains<1))
	if TalentPoints(plague_leech_talent) and { { target.DebuffRemains(blood_plague_debuff) < 1 or target.DebuffRemains(frost_fever_debuff) < 1 } } PlagueLeech()
	#outbreak,if=!dot.frost_fever.ticking|!dot.blood_plague.ticking
	if not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) Spell(outbreak)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
	if TalentPoints(blood_tap_talent) and { { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 } } BloodTap()
	#howling_blast,if=!dot.frost_fever.ticking
	if not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#plague_strike,if=!dot.blood_plague.ticking
	if not target.DebuffPresent(blood_plague_debuff) Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#blood_tap,if=talent.blood_tap.enabled&buff.killing_machine.react
	if TalentPoints(blood_tap_talent) and BuffPresent(killing_machine_buff) BloodTap()
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>76)
	if TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 } BloodTap()
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=blood=2|frost=2|unholy=2
	if Rune(blood) >= 2 or Rune(frost) >= 2 or Rune(unholy) >= 2 Spell(obliterate)
	#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<3|dot.frost_fever.remains<3))
	if TalentPoints(plague_leech_talent) and { { target.DebuffRemains(blood_plague_debuff) < 3 or target.DebuffRemains(frost_fever_debuff) < 3 } } PlagueLeech()
	#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
	if target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 Spell(outbreak)
	#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
	if TalentPoints(unholy_blight_talent) and { { target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 } } Spell(unholy_blight)
	#frost_strike,if=talent.runic_empowerment.enabled&(frost=0|unholy=0|blood=0)
	if TalentPoints(runic_empowerment_talent) and { Rune(frost) < 1 or Rune(unholy) < 1 or Rune(blood) < 1 } Spell(frost_strike)
	#frost_strike,if=talent.blood_tap.enabled&buff.blood_charge.stack<=10
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#obliterate
	Spell(obliterate)
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=20)
	if TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 } BloodTap()
	#frost_strike
	Spell(frost_strike)
	#plague_leech,if=talent.plague_leech.enabled
	if TalentPoints(plague_leech_talent) PlagueLeech()
}

AddFunction FrostTwoHandSingleTargetShortCdActions
{
	unless { TalentPoints(plague_leech_talent) and { { target.DebuffRemains(blood_plague_debuff) < 1 or target.DebuffRemains(frost_fever_debuff) < 1 } } and PlagueLeech() }
		or { { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak) }
	{
		#unholy_blight,if=talent.unholy_blight.enabled&((!dot.frost_fever.ticking|!dot.blood_plague.ticking))
		if TalentPoints(unholy_blight_talent) and { { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } } Spell(unholy_blight)
	}
}

### Frost icons.

AddIcon mastery=frost size=small checkboxon=opt_icons_left
{
	Spell(antimagic_shell)
	Spell(icebound_fortitude)
}

AddIcon mastery=frost size=small checkboxon=opt_icons_left
{
	if TalentPoints(death_pact_talent)
	{
		Spell(raise_dead)
		if TotemPresent(ghoul) Spell(death_pact)
	}
	if TalentPoints(death_siphon_talent) Spell(death_siphon)
}

AddIcon mastery=frost help=shortcd
{
	if InCombat(no) FrostPrecombatShortCdActions()
	FrostDefaultShortCdActions()
	if HasWeapon(offhand) FrostOneHandSingleTargetShortCdActions()
	if HasWeapon(offhand no) FrostTwoHandSingleTargetShortCdActions()
}

AddIcon mastery=frost help=main
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
	if HasWeapon(offhand) FrostOneHandSingleTargetActions()
	if HasWeapon(offhand no) FrostTwoHandSingleTargetActions()
}

AddIcon mastery=frost help=aoe checkboxon=opt_aoe
{
	if InCombat(no) FrostPrecombatActions()
	FrostDefaultActions()
	if HasWeapon(offhand) FrostOneHandAoeActions()
	if HasWeapon(offhand no) FrostTwoHandAoeActions()
}

AddIcon mastery=frost help=cd
{
	if InCombat(no) FrostPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	FrostDefaultCdActions()
}

AddIcon mastery=frost size=small checkboxon=opt_icons_right
{
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 Spell(pestilence)
}

AddIcon mastery=frost size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Unholy
###
# Based on SimulationCraft profile "Death_Knight_Unholy_T16H".
#	class=deathknight
#	spec=unholy
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#db!2...0.

AddFunction UnholyAoeActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if TalentPoints(unholy_blight_talent) Spell(unholy_blight)
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and DebuffRemainsOnAny(blood_plague_debuff excludeTarget=1) < 2 Spell(pestilence)
	#dark_transformation
	Spell(dark_transformation)
	#blood_tap,if=talent.blood_tap.enabled&buff.shadow_infusion.stack=5
	if TalentPoints(blood_tap_talent) and BuffStacks(shadow_infusion_buff) == 5 BloodTap()
	#blood_boil,if=blood=2|death=2
	if Rune(blood) >= 2 or { Rune(death) >= 2 and Rune(death) < 3 } Spell(blood_boil)
	#death_and_decay,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(death_and_decay)
	#soul_reaper,if=unholy=2&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if Rune(unholy) >= 2 and target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 BloodTap()
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or { BuffExpires(dark_transformation_buff) and Rune(unholy) <= 1 } Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#soul_reaper,if=unholy=1&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } and target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=1
	if { Rune(unholy) >= 1 and Rune(unholy) < 2 } Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#blood_tap,if=talent.blood_tap.enabled
	if TalentPoints(blood_tap_talent) BloodTap()
	#plague_leech,if=talent.plague_leech.enabled&unholy=1
	if TalentPoints(plague_leech_talent) and { Rune(unholy) >= 1 and Rune(unholy) < 2 } PlagueLeech()
	#horn_of_winter
	Spell(horn_of_winter)
}

AddFunction UnholySingleTargetActions
{
	#outbreak,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } Spell(outbreak)
	#plague_strike,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } Spell(plague_strike)
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=32)
	if TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 } BloodTap()
	#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
	if target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 Spell(outbreak)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
	if TalentPoints(blood_tap_talent) and { { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 } } BloodTap()
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#dark_transformation
	Spell(dark_transformation)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#death_and_decay,if=unholy=2
	if Rune(unholy) >= 2 Spell(death_and_decay)
	#blood_tap,if=talent.blood_tap.enabled&(unholy=2&cooldown.death_and_decay.remains=0)
	if TalentPoints(blood_tap_talent) and { Rune(unholy) >= 2 and not SpellCooldown(death_and_decay) > 0 } BloodTap()
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#festering_strike,if=blood=2&frost=2
	if Rune(blood) >= 2 and Rune(frost) >= 2 Spell(festering_strike)
	#death_and_decay
	Spell(death_and_decay)
	#blood_tap,if=talent.blood_tap.enabled&cooldown.death_and_decay.remains=0
	if TalentPoints(blood_tap_talent) and not SpellCooldown(death_and_decay) > 0 BloodTap()
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if BuffPresent(sudden_doom_buff) or { BuffExpires(dark_transformation_buff) and Rune(unholy) <= 1 } Spell(death_coil)
	#scourge_strike
	Spell(scourge_strike)
	#plague_leech,if=talent.plague_leech.enabled&cooldown.outbreak.remains<1
	if TalentPoints(plague_leech_talent) and SpellCooldown(outbreak) < 1 PlagueLeech()
	#festering_strike
	Spell(festering_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#death_coil
	Spell(death_coil)
	#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>=8
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 8 BloodTap()
	#empower_rune_weapon
	Spell(empower_rune_weapon)
}

AddFunction UnholySingleTargetShortCdActions
{
	unless { AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } and Spell(outbreak) }
		or { AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } and Spell(plague_strike) }
		or { TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 } }
	{
		#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
		if TalentPoints(unholy_blight_talent) and { { target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 } } Spell(unholy_blight)
	}
}

AddFunction UnholySingleTargetCdActions
{
	unless { AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } and Spell(outbreak) }
		or { AttackPower() > { target.DebuffAttackPower(blood_plague_debuff) * 1.1 } and TimeInCombat() > 15 and not { SpellCooldown(unholy_blight) > 79 } and Spell(plague_strike) }
		or { TalentPoints(blood_tap_talent) and { BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 } }
		or { TalentPoints(unholy_blight_talent) and { { target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 } } and Spell(unholy_blight) }
		or { target.DebuffRemains(frost_fever_debuff) < 3 or target.DebuffRemains(blood_plague_debuff) < 3 and Spell(outbreak) }
		or { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy) }
		or { TalentPoints(blood_tap_talent) and { { target.HealthPercent() -3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 } } and BloodTap() }
		or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) and Spell(plague_strike) }
	{
		#summon_gargoyle
		Spell(summon_gargoyle)
	}
}

AddFunction UnholyDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	#if Enemies() >= 3 UnholyAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	#if Enemies() < 3 UnholySingleTargetActions()
}

AddFunction UnholyDefaultCdActions
{
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent)
	#use_item,slot=hands
	UseItemActions()
	#mogu_power_potion,if=buff.dark_transformation.up&target.time_to_die<=60
	if BuffPresent(dark_transformation_buff) and target.TimeToDie() <= 60 UsePotionStrength()
	#unholy_frenzy,if=time>=4
	if TimeInCombat() >= 4 Spell(unholy_frenzy)
}

AddFunction UnholyPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#unholy_presence
	if not Stance(deathknight_unholy_presence) Spell(unholy_presence)
	#snapshot_stats
}

AddFunction UnholyPrecombatCdActions
{
	if Stance(deathknight_unholy_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#mogu_power_potion
		UsePotionStrength()
		#raise_dead
		Spell(raise_dead)
	}
}

### Unholy icons.

AddIcon mastery=unholy size=small checkboxon=opt_icons_left
{
	Spell(antimagic_shell)
	Spell(icebound_fortitude)
}

AddIcon mastery=unholy size=small checkboxon=opt_icons_left
{
	if TalentPoints(death_pact_talent)
	{
		Spell(raise_dead)
		if TotemPresent(ghoul) Spell(death_pact)
	}
	if TalentPoints(death_siphon_talent) Spell(death_siphon)
}

AddIcon mastery=unholy help=shortcd
{
	UnholyDefaultShortCdActions()
	UnholySingleTargetShortCdActions()
}

AddIcon mastery=unholy help=main
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
	UnholySingleTargetActions()
}

AddIcon mastery=unholy help=aoe checkboxon=opt_aoe
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
	UnholyAoeActions()
}

AddIcon mastery=unholy help=cd
{
	if InCombat(no) UnholyPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	UnholyDefaultCdActions()
	UnholySingleTargetCdActions()
}

AddIcon mastery=unholy size=small checkboxon=opt_icons_right
{
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(plague_leech_talent) Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and TalentPoints(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 Spell(pestilence)
}

AddIcon mastery=unholy size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code)
end
