local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_deathknight"
	local desc = "[5.4.8] Ovale: Blood, Frost, Unholy"
	local code = [[
# Ovale death knight script based on SimulationCraft.

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default specialization=!blood)

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

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(mind_freeze) Spell(mind_freeze)
		if target.Classification(worldboss no)
		{
			if Talent(asphyxiate_talent) and target.InRange(asphyxiate) Spell(asphyxiate)
			if target.InRange(strangulate) Spell(strangulate)
			Spell(arcane_torrent_runicpower)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

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
	if target.DebuffRemaining(blood_plague_debuff) < 2 or target.DebuffRemaining(frost_fever_debuff) < 2
	{
		if DebuffCountOnAny(blood_plague_debuff excludeTarget=1) > 0 and DebuffCountOnAny(frost_fever_debuff excludeTarget=1) > 0 and { BuffPresent(crimson_scourge_buff) or Rune(blood) >= 1 } Spell(blood_boil)
		Spell(outbreak)
	}
	if target.DebuffExpires(blood_plague_debuff) Spell(plague_strike)
	if target.DebuffExpires(frost_fever_debuff) Spell(icy_touch)
}

AddFunction BloodDeathStrikeCondition
{
	IncomingDamage(5) >= MaxHealth() * 0.65
}

AddFunction BloodSingleTargetLevel75Actions
{
	if Talent(blood_tap_talent)
	{
		# Don't cap FU rune pairs.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		if BuffStacks(blood_charge_buff) >= 10
		{
			# Spend any FU pairs so we can use Blood Tap twice to reactivate an FU pair as death runes.
			if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
			# Blood Tap once to reactivate one F/U death rune.
			if { Rune(unholy) < 1 and Rune(frost) < 1 } or { RunicPower() >= MaxRunicPower() - 20 } Spell(blood_tap)
		}
		# Use Blood Tap a second time to reactivate another F/U death rune to bank a full FU pair.
		if BuffStacks(blood_charge_buff) >= 5
		{
			if Rune(unholy) >= 1 and Rune(frost) < 1 Spell(blood_tap)
			if Rune(unholy) < 1 and Rune(frost) >= 1 Spell(blood_tap)
		}
		# Don't fully deplete a blood rune or else we may proc a blood rune into a death rune.
		if Rune(blood) >= 2 Spell(heart_strike)
		# Rune Strike to build Blood Charges.
		Spell(rune_strike)
	}
	if Talent(runic_empowerment_talent)
	{
		# Keep F/U runes fully depleted for Runic Empowerment procs.
		if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
		# Don't fully deplete a blood rune or else we may proc a blood rune into a death rune.
		if Rune(blood) >= 2 Spell(heart_strike)
		# Rune Strike to proc Runic Empowerment.
		Spell(rune_strike)
	}
	if Talent(runic_corruption_talent)
	{
		# Try to put one rune of each set on cooldown to benefit from Runic Corruption procs.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		if Rune(blood) >= 2 Spell(heart_strike)
		# Rune Strike to proc Runic Corruption.
		Spell(rune_strike)
	}
	if Talent(blood_tap_talent no) and Talent(runic_empowerment_talent no) and Talent(runic_corruption_talent no)
	{
		# Bank a pair of FU runes for emergency Death Strike.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		# Use up blood runes to generate runic power.
		if Rune(blood) >= 1 Spell(heart_strike)
		# Dump runic power.
		Spell(rune_strike)
	}
}

AddFunction BloodAoeLevel75Actions
{
	if Talent(blood_tap_talent)
	{
		# Don't cap FU rune pairs.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		if BuffStacks(blood_charge_buff) >= 10
		{
			# Spend any FU pairs so we can use Blood Tap twice to reactivate an FU pair as death runes.
			if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
			# Blood Tap once to reactivate one F/U death rune.
			if { Rune(unholy) < 1 and Rune(frost) < 1 } or { RunicPower() >= MaxRunicPower() - 20 } Spell(blood_tap)
		}
		# Use Blood Tap a second time to reactivate another F/U death rune to bank a full FU pair.
		if BuffStacks(blood_charge_buff) >= 5
		{
			if Rune(unholy) >= 1 and Rune(frost) < 1 Spell(blood_tap)
			if Rune(unholy) < 1 and Rune(frost) >= 1 Spell(blood_tap)
		}
		# Don't fully deplete a blood rune or else we may proc a blood rune into a death rune.
		if Rune(blood) >= 2 Spell(blood_boil)
		# Rune Strike to build Blood Charges.
		Spell(rune_strike)
	}
	if Talent(runic_empowerment_talent)
	{
		# Keep F/U runes fully depleted for Runic Empowerment procs.
		if Rune(unholy) >= 1 and Rune(frost) >= 1 Spell(death_strike)
		# Don't fully deplete a blood rune or else we may proc a blood rune into a death rune.
		if Rune(blood) >= 2 Spell(blood_boil)
		# Rune Strike to proc Runic Empowerment.
		Spell(rune_strike)
	}
	if Talent(runic_corruption_talent)
	{
		# Try to put one rune of each set on cooldown to benefit from Runic Corruption procs.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		if Rune(blood) >= 2 Spell(blood_boil)
		# Rune Strike to proc Runic Corruption.
		Spell(rune_strike)
	}
	if Talent(blood_tap_talent no) and Talent(runic_empowerment_talent no) and Talent(runic_corruption_talent no)
	{
		# Bank a pair of FU runes for emergency Death Strike.
		if Rune(unholy) >= 2 and Rune(frost) >= 2 Spell(death_strike)
		# Use up blood runes to generate runic power.
		if Rune(blood) >= 1 Spell(blood_boil)
		# Dump runic power.
		Spell(rune_strike)
	}
}

AddFunction BloodSingleTargetActions
{
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if BloodDeathStrikeCondition() Spell(death_strike)

	if { Rune(blood) < 2 or Rune(unholy) < 2 or Rune(frost) < 2 } and Spell(outbreak) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	BloodApplyDiseases()

	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35&blood>=1
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Rune(blood) >= 1 Spell(soul_reaper_blood)

	if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
	if Rune(blood) >= 1 and { target.DebuffRemaining(frost_fever_debuff) <= 10 or target.DebuffRemaining(blood_plague_debuff) <= 10 } Spell(blood_boil)

	BloodSingleTargetLevel75Actions()
	Spell(horn_of_winter)

	#death_strike,if=(unholy=2|frost=2)&incoming_damage_5s>=health.max*0.4
	if { Rune(unholy) >= 2 or Rune(frost) >= 2 } and IncomingDamage(5) >= HealthPercent() * 0.4 Spell(death_strike)
}

AddFunction BloodAoeActions
{
	#death_strike,if=incoming_damage_5s>=health.max*0.65
	if BloodDeathStrikeCondition() Spell(death_strike)

	if BuffPresent(crimson_scourge_buff) Spell(death_and_decay)

	if { Rune(blood) < 2 or Rune(unholy) < 2 or Rune(frost) < 2 } and Spell(outbreak) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	BloodApplyDiseases()

	if target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff)
	{
		if BuffPresent(crimson_scourge_buff) Spell(blood_boil)
		if DebuffRemainingOnAny(blood_plague_debuff excludeTarget=1) < 10 and DebuffRemainingOnAny(frost_fever_debuff excludeTarget=1) < 10
		{
			if Talent(roiling_blood_talent) Spell(blood_boil)
			Spell(pestilence)
		}
	}

	BloodAoeLevel75Actions()
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
	if Talent(death_pact_talent) and TotemPresent(ghoul) and HealthPercent() < 50 Spell(death_pact)

	if BloodDeathStrikeCondition()
	{
		if Rune(unholy) < 1 and Rune(frost) < 1 and ArmorSetParts(T16_tank) >= 4 Spell(dancing_rune_weapon)
		if Rune(blood) < 1 and Rune(unholy) < 1 and Rune(frost) < 1 Spell(empower_rune_weapon)
	}
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

### Blood icons.
AddCheckBox(opt_deathknight_blood "Show Blood icons" specialization=blood default)
AddCheckBox(opt_deathknight_blood_aoe L(AOE) specialization=blood default)

AddIcon specialization=blood help=shortcd checkbox=opt_deathknight_blood
{
	BloodShortCdActions()
}

AddIcon specialization=blood help=main checkbox=opt_deathknight_blood
{
	if InCombat(no) BloodPrecombatActions()
	BloodSingleTargetActions()
}

AddIcon specialization=blood help=aoe checkbox=opt_deathknight_blood checkbox=opt_deathknight_blood_aoe
{
	if InCombat(no) BloodPrecombatActions()
	BloodAoeActions()
}

AddIcon specialization=blood help=cd checkbox=opt_deathknight_blood
{
	InterruptActions()
	BloodCdActions()
}

###
### Frost
###
# Based on SimulationCraft profile "Death_Knight_Frost_1h_T16H".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1...0.
#	glyphs=loud_horn

# ActionList: FrostDualWieldPrecombatActions --> main, shortcd, cd

AddFunction FrostDualWieldPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#frost_presence
	if not Stance(deathknight_frost_presence) Spell(frost_presence)
	#snapshot_stats
}

AddFunction FrostDualWieldPrecombatShortCdActions
{
	unless Spell(horn_of_winter)
		or not Stance(deathknight_frost_presence) and Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostDualWieldPrecombatCdActions
{
	unless Spell(horn_of_winter)
		or not Stance(deathknight_frost_presence) and Spell(frost_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#mogu_power_potion
		UsePotionStrength()
		#raise_dead
		Spell(raise_dead)
	}
}

# ActionList: FrostDualWieldDefaultActions --> main, shortcd, cd

AddFunction FrostDualWieldDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetActions()
}

AddFunction FrostDualWieldDefaultShortCdActions
{
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	#Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostDualWieldAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetShortCdActions()
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
}

AddFunction FrostDualWieldDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

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
	if Enemies() >= 3 FrostDualWieldAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostDualWieldSingleTargetCdActions()
}

# ActionList: FrostDualWieldAoeActions --> main, shortcd, cd

AddFunction FrostDualWieldAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#plague_strike,if=unholy=2
	if Runes(unholy 2) Spell(plague_strike)
	#frost_strike
	Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#plague_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(plague_strike)
}

AddFunction FrostDualWieldAoeShortCdActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if Talent(unholy_blight_talent) Spell(unholy_blight)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)

	unless Spell(howling_blast)
	{
		#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
		if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)

		unless RunicPower() > 76 and Spell(frost_strike)
		{
			#death_and_decay,if=unholy=1
			if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)

			unless Runes(unholy 2) and Spell(plague_strike)
			{
				#blood_tap,if=talent.blood_tap.enabled
				if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

				unless Spell(frost_strike)
					or Spell(horn_of_winter)
				{
					#plague_leech,if=talent.plague_leech.enabled&unholy=1
					if Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
				}
			}
		}
	}
}

AddFunction FrostDualWieldAoeCdActions
{
	unless Talent(unholy_blight_talent) and Spell(unholy_blight)
		or target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
		or target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
		or Spell(howling_blast)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and Spell(blood_tap)
		or RunicPower() > 76 and Spell(frost_strike)
		or Runes(unholy 1) and not Runes(unholy 2) and Spell(death_and_decay)
		or Runes(unholy 2) and Spell(plague_strike)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or Spell(frost_strike)
		or Spell(horn_of_winter)
		or Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
		or Runes(unholy 1) and not Runes(unholy 2) and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: FrostDualWieldSingleTargetActions --> main, shortcd, cd

AddFunction FrostDualWieldSingleTargetActions
{
	#frost_strike,if=buff.killing_machine.react|runic_power>88
	if BuffPresent(killing_machine_buff) or RunicPower() > 88 Spell(frost_strike)
	#howling_blast,if=death>1|frost>1
	if Runes(death 2) or Runes(frost 2) Spell(howling_blast)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#howling_blast,if=!dot.frost_fever.ticking
	if not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#plague_strike,if=!dot.blood_plague.ticking&unholy>0
	if not target.DebuffPresent(blood_plague_debuff) and Runes(unholy 1) Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=unholy>0&!buff.killing_machine.react
	if Runes(unholy 1) and not BuffPresent(killing_machine_buff) Spell(obliterate)
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=talent.runic_empowerment.enabled&unholy=1
	if Talent(runic_empowerment_talent) and Runes(unholy 1) and not Runes(unholy 2) Spell(frost_strike)
	#frost_strike,if=runic_power>=40
	if RunicPower() >= 40 Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
}

AddFunction FrostDualWieldSingleTargetShortCdActions
{
	#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&(runic_power>76|(runic_power>=20&buff.killing_machine.react)))
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } Spell(blood_tap)

	unless { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike)
		or { Runes(death 2) or Runes(frost 2) } and Spell(howling_blast)
	{
		#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
		if Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)

		unless target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
		{
			#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
			if Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
				or not target.DebuffPresent(blood_plague_debuff) and Runes(unholy 1) and Spell(plague_strike)
				or BuffPresent(rime_buff) and Spell(howling_blast)
				or RunicPower() > 76 and Spell(frost_strike)
				or Runes(unholy 1) and not BuffPresent(killing_machine_buff) and Spell(obliterate)
				or Spell(howling_blast)
				or Talent(runic_empowerment_talent) and Runes(unholy 1) and not Runes(unholy 2) and Spell(frost_strike)
			{
				#blood_tap,if=talent.blood_tap.enabled&(target.health.pct-3*(target.health.pct%target.time_to_die)>35|buff.blood_charge.stack>=8)
				if Talent(blood_tap_talent) and { target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } > 35 or BuffStacks(blood_charge_buff) >= 8 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

				unless RunicPower() >= 40 and Spell(frost_strike)
					or Spell(horn_of_winter)
				{
					#blood_tap,if=talent.blood_tap.enabled
					if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
					#plague_leech,if=talent.plague_leech.enabled
					if Talent(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
				}
			}
		}
	}
}

AddFunction FrostDualWieldSingleTargetCdActions
{
	unless Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and { RunicPower() > 76 or RunicPower() >= 20 and BuffPresent(killing_machine_buff) } and Spell(blood_tap)
		or { BuffPresent(killing_machine_buff) or RunicPower() > 88 } and Spell(frost_strike)
		or { Runes(death 2) or Runes(frost 2) } and Spell(howling_blast)
		or Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(unholy_blight)
		or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
		or Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
		or not target.DebuffPresent(blood_plague_debuff) and Runes(unholy 1) and Spell(plague_strike)
		or BuffPresent(rime_buff) and Spell(howling_blast)
		or RunicPower() > 76 and Spell(frost_strike)
		or Runes(unholy 1) and not BuffPresent(killing_machine_buff) and Spell(obliterate)
		or Spell(howling_blast)
		or Talent(runic_empowerment_talent) and Runes(unholy 1) and not Runes(unholy 2) and Spell(frost_strike)
		or Talent(blood_tap_talent) and { target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } > 35 or BuffStacks(blood_charge_buff) >= 8 } and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or RunicPower() >= 40 and Spell(frost_strike)
		or Spell(horn_of_winter)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or Talent(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# Based on SimulationCraft profile "Death_Knight_Frost_2h_T16H".
#	class=deathknight
#	spec=frost
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#dZ!1...0.
#	glyphs=loud_horn

# ActionList: FrostTwoHandedPrecombatActions --> main, shortcd, cd

AddFunction FrostTwoHandedPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#horn_of_winter
	Spell(horn_of_winter)
	#frost_presence
	if not Stance(deathknight_frost_presence) Spell(frost_presence)
	#snapshot_stats
}

AddFunction FrostTwoHandedPrecombatShortCdActions
{
	unless Spell(horn_of_winter)
		or not Stance(deathknight_frost_presence) and Spell(frost_presence)
	{
		#pillar_of_frost
		Spell(pillar_of_frost)
	}
}

AddFunction FrostTwoHandedPrecombatCdActions
{
	unless Spell(horn_of_winter)
		or not Stance(deathknight_frost_presence) and Spell(frost_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#mogu_power_potion
		UsePotionStrength()
		#raise_dead
		Spell(raise_dead)
	}
}

# ActionList: FrostTwoHandedDefaultActions --> main, shortcd, cd

AddFunction FrostTwoHandedDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostTwoHandedAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHandedSingleTargetActions()
}

AddFunction FrostTwoHandedDefaultShortCdActions
{
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	#Spell(antimagic_shell)
	#pillar_of_frost
	Spell(pillar_of_frost)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 FrostTwoHandedAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHandedSingleTargetShortCdActions()
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
}

AddFunction FrostTwoHandedDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

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
	if Enemies() >= 3 FrostTwoHandedAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 FrostTwoHandedSingleTargetCdActions()
}

# ActionList: FrostTwoHandedAoeActions --> main, shortcd, cd

AddFunction FrostTwoHandedAoeActions
{
	#howling_blast
	Spell(howling_blast)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#plague_strike,if=unholy=2
	if Runes(unholy 2) Spell(plague_strike)
	#frost_strike
	Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#plague_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(plague_strike)
}

AddFunction FrostTwoHandedAoeShortCdActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if Talent(unholy_blight_talent) Spell(unholy_blight)
	#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
	#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
	if target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)

	unless Spell(howling_blast)
	{
		#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
		if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)

		unless RunicPower() > 76 and Spell(frost_strike)
		{
			#death_and_decay,if=unholy=1
			if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)

			unless Runes(unholy 2) and Spell(plague_strike)
			{
				#blood_tap,if=talent.blood_tap.enabled
				if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

				unless Spell(frost_strike)
					or Spell(horn_of_winter)
				{
					#plague_leech,if=talent.plague_leech.enabled&unholy=1
					if Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
				}
			}
		}
	}
}

AddFunction FrostTwoHandedAoeCdActions
{
	unless Talent(unholy_blight_talent) and Spell(unholy_blight)
		or target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
		or target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
		or Spell(howling_blast)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and Spell(blood_tap)
		or RunicPower() > 76 and Spell(frost_strike)
		or Runes(unholy 1) and not Runes(unholy 2) and Spell(death_and_decay)
		or Runes(unholy 2) and Spell(plague_strike)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or Spell(frost_strike)
		or Spell(horn_of_winter)
		or Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
		or Runes(unholy 1) and not Runes(unholy 2) and Spell(plague_strike)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

# ActionList: FrostTwoHandedSingleTargetActions --> main, shortcd, cd

AddFunction FrostTwoHandedSingleTargetActions
{
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_frost)
	#howling_blast,if=!dot.frost_fever.ticking
	if not target.DebuffPresent(frost_fever_debuff) Spell(howling_blast)
	#plague_strike,if=!dot.blood_plague.ticking
	if not target.DebuffPresent(blood_plague_debuff) Spell(plague_strike)
	#howling_blast,if=buff.rime.react
	if BuffPresent(rime_buff) Spell(howling_blast)
	#obliterate,if=buff.killing_machine.react
	if BuffPresent(killing_machine_buff) Spell(obliterate)
	#frost_strike,if=runic_power>76
	if RunicPower() > 76 Spell(frost_strike)
	#obliterate,if=blood=2|frost=2|unholy=2
	if Runes(blood 2) or Runes(frost 2) or Runes(unholy 2) Spell(obliterate)
	#frost_strike,if=talent.runic_empowerment.enabled&(frost=0|unholy=0|blood=0)
	if Talent(runic_empowerment_talent) and { Runes(frost 0) and not Runes(frost 1) or Runes(unholy 0) and not Runes(unholy 1) or Runes(blood 0) and not Runes(blood 1) } Spell(frost_strike)
	#frost_strike,if=talent.blood_tap.enabled&buff.blood_charge.stack<=10
	if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 Spell(frost_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#obliterate
	Spell(obliterate)
	#frost_strike
	Spell(frost_strike)
}

AddFunction FrostTwoHandedSingleTargetShortCdActions
{
	#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<1|dot.frost_fever.remains<1))
	if Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
	#outbreak,if=!dot.frost_fever.ticking|!dot.blood_plague.ticking
	if not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) Spell(outbreak)
	#unholy_blight,if=talent.unholy_blight.enabled&((!dot.frost_fever.ticking|!dot.blood_plague.ticking))
	if Talent(unholy_blight_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } Spell(unholy_blight)

	unless target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
	{
		#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
		if Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
			or not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike)
			or BuffPresent(rime_buff) and Spell(howling_blast)
			or BuffPresent(killing_machine_buff) and Spell(obliterate)
		{
			#blood_tap,if=talent.blood_tap.enabled&buff.killing_machine.react
			if Talent(blood_tap_talent) and BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
			#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>76)
			if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 Spell(blood_tap)

			unless RunicPower() > 76 and Spell(frost_strike)
				or { Runes(blood 2) or Runes(frost 2) or Runes(unholy 2) } and Spell(obliterate)
			{
				#plague_leech,if=talent.plague_leech.enabled&((dot.blood_plague.remains<3|dot.frost_fever.remains<3))
				if Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
				#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
				if target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 Spell(outbreak)
				#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
				if Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)

				unless Talent(runic_empowerment_talent) and { Runes(frost 0) and not Runes(frost 1) or Runes(unholy 0) and not Runes(unholy 1) or Runes(blood 0) and not Runes(blood 1) } and Spell(frost_strike)
					or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and Spell(frost_strike)
					or Spell(horn_of_winter)
					or Spell(obliterate)
				{
					#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=20)
					if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 Spell(blood_tap)

					unless Spell(frost_strike)
					{
						#plague_leech,if=talent.plague_leech.enabled
						if Talent(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
					}
				}
			}
		}
	}
}

AddFunction FrostTwoHandedSingleTargetCdActions
{
	unless Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
		or { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak)
		or Talent(unholy_blight_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(unholy_blight)
		or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_frost)
		or Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_frost) > 0 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or not target.DebuffPresent(frost_fever_debuff) and Spell(howling_blast)
		or not target.DebuffPresent(blood_plague_debuff) and Spell(plague_strike)
		or BuffPresent(rime_buff) and Spell(howling_blast)
		or BuffPresent(killing_machine_buff) and Spell(obliterate)
		or Talent(blood_tap_talent) and BuffPresent(killing_machine_buff) and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() > 76 and Spell(blood_tap)
		or RunicPower() > 76 and Spell(frost_strike)
		or { Runes(blood 2) or Runes(frost 2) or Runes(unholy 2) } and Spell(obliterate)
		or Talent(plague_leech_talent) and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
		or { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(outbreak)
		or Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(unholy_blight)
		or Talent(runic_empowerment_talent) and { Runes(frost 0) and not Runes(frost 1) or Runes(unholy 0) and not Runes(unholy 1) or Runes(blood 0) and not Runes(blood 1) } and Spell(frost_strike)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) <= 10 and Spell(frost_strike)
		or Spell(horn_of_winter)
		or Spell(obliterate)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 20 and Spell(blood_tap)
		or Spell(frost_strike)
		or Talent(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

### Frost icons.
AddCheckBox(opt_deathknight_frost "Show Frost icons" specialization=frost default)
AddCheckBox(opt_deathknight_frost_aoe L(AOE) specialization=frost default)

AddIcon specialization=frost help=shortcd enemies=1 checkbox=opt_deathknight_frost checkbox=!opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatShortCdActions()
		FrostDualWieldDefaultShortCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatShortCdActions()
		FrostTwoHandedDefaultShortCdActions()
	}
}

AddIcon specialization=frost help=shortcd checkbox=opt_deathknight_frost checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatShortCdActions()
		FrostDualWieldDefaultShortCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatShortCdActions()
		FrostTwoHandedDefaultShortCdActions()
	}
}

AddIcon specialization=frost help=main enemies=1 checkbox=opt_deathknight_frost
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatActions()
		FrostDualWieldDefaultActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatActions()
		FrostTwoHandedDefaultActions()
	}
}

AddIcon specialization=frost help=aoe checkbox=opt_deathknight_frost checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatActions()
		FrostDualWieldDefaultActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatActions()
		FrostTwoHandedDefaultActions()
	}
}

AddIcon specialization=frost help=cd enemies=1 checkbox=opt_deathknight_frost checkbox=!opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatCdActions()
		FrostDualWieldDefaultCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatCdActions()
		FrostTwoHandedDefaultCdActions()
	}
}

AddIcon specialization=frost help=cd checkbox=opt_deathknight_frost checkbox=opt_deathknight_frost_aoe
{
	if HasWeapon(offhand)
	{
		if InCombat(no) FrostDualWieldPrecombatCdActions()
		FrostDualWieldDefaultCdActions()
	}
	if HasWeapon(offhand no)
	{
		if InCombat(no) FrostTwoHandedPrecombatCdActions()
		FrostTwoHandedDefaultCdActions()
	}
}

###
### Unholy
###
# Based on SimulationCraft profile "Death_Knight_Unholy_T16H".
#	class=deathknight
#	spec=unholy
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#db!2...0.

# ActionList: UnholyPrecombatActions --> main, shortcd, cd

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

AddFunction UnholyPrecombatShortCdActions {}

AddFunction UnholyPrecombatCdActions
{
	unless Spell(horn_of_winter)
		or not Stance(deathknight_unholy_presence) and Spell(unholy_presence)
	{
		#army_of_the_dead
		Spell(army_of_the_dead)
		#mogu_power_potion
		UsePotionStrength()
		#raise_dead
		Spell(raise_dead)
	}
}

# ActionList: UnholyDefaultActions --> main, shortcd, cd

AddFunction UnholyDefaultActions
{
	#auto_attack
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 UnholyAoeActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 UnholySingleTargetActions()
}

AddFunction UnholyDefaultShortCdActions
{
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	#Spell(antimagic_shell)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 UnholyAoeShortCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 UnholySingleTargetShortCdActions()
	# CHANGE: Suggest Anti-Magic Shell after other short CD spells.
	#antimagic_shell,damage=100000
	Spell(antimagic_shell)
}

AddFunction UnholyDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_runicpower)
	#use_item,slot=hands
	UseItemActions()
	#mogu_power_potion,if=buff.dark_transformation.up&target.time_to_die<=60
	if pet.BuffPresent(dark_transformation_buff any=1) and target.TimeToDie() <= 60 UsePotionStrength()
	#unholy_frenzy,if=time>=4
	if TimeInCombat() >= 4 Spell(unholy_frenzy)
	#run_action_list,name=aoe,if=active_enemies>=3
	if Enemies() >= 3 UnholyAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<3
	if Enemies() < 3 UnholySingleTargetCdActions()
}

# ActionList: UnholyAoeActions --> main, shortcd, cd

AddFunction UnholyAoeActions
{
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#blood_boil,if=blood=2|death=2
	if Runes(blood 2) or Runes(death 2) and not Runes(death 3) Spell(blood_boil)
	#soul_reaper,if=unholy=2&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Runes(unholy 2) Spell(scourge_strike)
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#soul_reaper,if=unholy=1&target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if Runes(unholy 1) and not Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=1
	if Runes(unholy 1) and not Runes(unholy 2) Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#horn_of_winter
	Spell(horn_of_winter)
}

AddFunction UnholyAoeShortCdActions
{
	#unholy_blight,if=talent.unholy_blight.enabled
	if Talent(unholy_blight_talent) Spell(unholy_blight)

	unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
	{
		#pestilence,if=dot.blood_plague.ticking&talent.plague_leech.enabled,line_cd=28
		if target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
		#pestilence,if=dot.blood_plague.ticking&talent.unholy_blight.enabled&cooldown.unholy_blight.remains<49,line_cd=28
		if target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)
		#dark_transformation
		if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
		#blood_tap,if=talent.blood_tap.enabled&buff.shadow_infusion.stack=5
		if Talent(blood_tap_talent) and BuffStacks(shadow_infusion_buff) == 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

		unless { Runes(blood 2) or Runes(death 2) and not Runes(death 3) } and Spell(blood_boil)
		{
			#death_and_decay,if=unholy=1
			if Runes(unholy 1) and not Runes(unholy 2) Spell(death_and_decay)

			unless Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
				or Runes(unholy 2) and Spell(scourge_strike)
			{
				#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>10
				if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)

				unless { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) } and Spell(death_coil)
					or Spell(blood_boil)
					or Spell(icy_touch)
					or Runes(unholy 1) and not Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
					or Runes(unholy 1) and not Runes(unholy 2) and Spell(scourge_strike)
					or Spell(death_coil)
				{
					#blood_tap,if=talent.blood_tap.enabled
					if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
					#plague_leech,if=talent.plague_leech.enabled&unholy=1
					if Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
				}
			}
		}
	}
}

AddFunction UnholyAoeCdActions
{
	unless Talent(unholy_blight_talent) and Spell(unholy_blight)
		or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
		or target.DebuffPresent(blood_plague_debuff) and Talent(plague_leech_talent) and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
		or target.DebuffPresent(blood_plague_debuff) and Talent(unholy_blight_talent) and SpellCooldown(unholy_blight) < 49 and TimeSincePreviousSpell(pestilence) > 28 and Spell(pestilence)
	{
		#summon_gargoyle
		Spell(summon_gargoyle)

		unless BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
			or Talent(blood_tap_talent) and BuffStacks(shadow_infusion_buff) == 5 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
			or { Runes(blood 2) or Runes(death 2) and not Runes(death 3) } and Spell(blood_boil)
			or Runes(unholy 1) and not Runes(unholy 2) and Spell(death_and_decay)
			or Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
			or Runes(unholy 2) and Spell(scourge_strike)
			or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and Spell(blood_tap)
			or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) } and Spell(death_coil)
			or Spell(blood_boil)
			or Spell(icy_touch)
			or Runes(unholy 1) and not Runes(unholy 2) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
			or Runes(unholy 1) and not Runes(unholy 2) and Spell(scourge_strike)
			or Spell(death_coil)
			or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
			or Talent(plague_leech_talent) and Runes(unholy 1) and not Runes(unholy 2) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
			or Spell(horn_of_winter)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

# ActionList: UnholySingleTargetActions --> main, shortcd, cd

AddFunction UnholySingleTargetActions
{
	#plague_strike,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 Spell(plague_strike)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=35
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 Spell(soul_reaper_unholy)
	#plague_strike,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#scourge_strike,if=unholy=2
	if Runes(unholy 2) Spell(scourge_strike)
	#festering_strike,if=blood=2&frost=2
	if Runes(blood 2) and Runes(frost 2) Spell(festering_strike)
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&rune.unholy<=1)
	if BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) Spell(death_coil)
	#scourge_strike
	Spell(scourge_strike)
	#festering_strike
	Spell(festering_strike)
	#horn_of_winter
	Spell(horn_of_winter)
	#death_coil
	Spell(death_coil)
}

AddFunction UnholySingleTargetShortCdActions
{
	#outbreak,if=stat.attack_power>(dot.blood_plague.attack_power*1.1)&time>15&!(cooldown.unholy_blight.remains>79)
	if AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 Spell(outbreak)

	unless AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 and Spell(plague_strike)
	{
		#blood_tap,if=talent.blood_tap.enabled&(buff.blood_charge.stack>10&runic_power>=32)
		if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 Spell(blood_tap)
		#unholy_blight,if=talent.unholy_blight.enabled&((dot.frost_fever.remains<3|dot.blood_plague.remains<3))
		if Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)
		#outbreak,if=dot.frost_fever.remains<3|dot.blood_plague.remains<3
		if target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 Spell(outbreak)

		unless target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
		{
			#blood_tap,if=talent.blood_tap.enabled&((target.health.pct-3*(target.health.pct%target.time_to_die)<=35&cooldown.soul_reaper.remains=0))
			if Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
			{
				#dark_transformation
				if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)

				unless RunicPower() > 90 and Spell(death_coil)
				{
					#death_and_decay,if=unholy=2
					if Runes(unholy 2) Spell(death_and_decay)
					#blood_tap,if=talent.blood_tap.enabled&(unholy=2&cooldown.death_and_decay.remains=0)
					if Talent(blood_tap_talent) and Runes(unholy 2) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

					unless Runes(unholy 2) and Spell(scourge_strike)
						or Runes(blood 2) and Runes(frost 2) and Spell(festering_strike)
					{
						#death_and_decay
						Spell(death_and_decay)
						#blood_tap,if=talent.blood_tap.enabled&cooldown.death_and_decay.remains=0
						if Talent(blood_tap_talent) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

						unless { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) } and Spell(death_coil)
							or Spell(scourge_strike)
						{
							#plague_leech,if=talent.plague_leech.enabled&cooldown.outbreak.remains<1
							if Talent(plague_leech_talent) and SpellCooldown(outbreak) < 1 and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)

							unless Spell(festering_strike)
								or Spell(horn_of_winter)
								or Spell(death_coil)
							{
								#blood_tap,if=talent.blood_tap.enabled&buff.blood_charge.stack>=8
								if Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 8 Spell(blood_tap)
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
	unless AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 and Spell(outbreak)
		or AttackPower() > target.DebuffAttackPower(blood_plague_debuff) * 1.1 and TimeInCombat() > 15 and not SpellCooldown(unholy_blight) > 79 and Spell(plague_strike)
		or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) > 10 and RunicPower() >= 32 and Spell(blood_tap)
		or Talent(unholy_blight_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(unholy_blight)
		or { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(outbreak)
		or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and Spell(soul_reaper_unholy)
		or Talent(blood_tap_talent) and target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 35 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
		or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike)
	{
		#summon_gargoyle
		Spell(summon_gargoyle)

		unless BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
			or RunicPower() > 90 and Spell(death_coil)
			or Runes(unholy 2) and Spell(death_and_decay)
			or Talent(blood_tap_talent) and Runes(unholy 2) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
			or Runes(unholy 2) and Spell(scourge_strike)
			or Runes(blood 2) and Runes(frost 2) and Spell(festering_strike)
			or Spell(death_and_decay)
			or Talent(blood_tap_talent) and not SpellCooldown(death_and_decay) > 0 and BuffStacks(blood_charge_buff) >= 5 and Spell(blood_tap)
			or { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and not Runes(unholy 2) } and Spell(death_coil)
			or Spell(scourge_strike)
			or Talent(plague_leech_talent) and SpellCooldown(outbreak) < 1 and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) and Spell(plague_leech)
			or Spell(festering_strike)
			or Spell(horn_of_winter)
			or Spell(death_coil)
			or Talent(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 8 and Spell(blood_tap)
		{
			#empower_rune_weapon
			Spell(empower_rune_weapon)
		}
	}
}

### Unholy icons.
AddCheckBox(opt_deathknight_unholy "Show Unholy icons" specialization=unholy default)
AddCheckBox(opt_deathknight_unholy_aoe L(AOE) specialization=unholy default)

AddIcon specialization=unholy help=shortcd enemies=1 checkbox=opt_deathknight_unholy checkbox=!opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=shortcd checkbox=opt_deathknight_unholy checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=main enemies=1 checkbox=opt_deathknight_unholy
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

AddIcon specialization=unholy help=aoe checkbox=opt_deathknight_unholy checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatActions()
	UnholyDefaultActions()
}

AddIcon specialization=unholy help=cd enemies=1 checkbox=opt_deathknight_unholy checkbox=!opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
}

AddIcon specialization=unholy help=cd checkbox=opt_deathknight_unholy checkbox=opt_deathknight_unholy_aoe
{
	if InCombat(no) UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("DEATHKNIGHT", "Ovale", desc, code, "script")
end
