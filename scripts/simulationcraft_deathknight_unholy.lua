local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Death_Knight_Unholy_T17M"
	local desc = "[6.0] SimulationCraft: Death_Knight_Unholy_T17M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Unholy_T17M".
#	class=deathknight
#	spec=unholy
#	talents=2001002

Include(ovale_common)
Include(ovale_deathknight_spells)

AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
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

AddFunction UnholyDefaultMainActions
{
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeMainActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetMainActions()
}

AddFunction UnholyDefaultShortCdActions
{
	#auto_attack
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
	#potion,name=draenic_strength,if=buff.dark_transformation.up&target.time_to_die<=60
	if pet.BuffPresent(dark_transformation_buff any=1) and target.TimeToDie() <= 60 UsePotionStrength()
	#run_action_list,name=aoe,if=active_enemies>=2
	if Enemies() >= 2 UnholyAoeCdActions()
	#run_action_list,name=single_target,if=active_enemies<2
	if Enemies() < 2 UnholySingleTargetCdActions()
}

### actions.aoe

AddFunction UnholyAoeMainActions
{
	#run_action_list,name=spread,if=!dot.blood_plague.ticking|!dot.frost_fever.ticking
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) UnholySpreadMainActions()
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeMainActions()
	#blood_boil,if=blood=2|(frost=2&death=2)
	if Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 Spell(blood_boil)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#soul_reaper,if=target.health.pct-3*(target.health.pct%target.time_to_die)<=45
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 Spell(soul_reaper_unholy)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>90|buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1)
	if RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 Spell(death_coil)
	#blood_boil
	Spell(blood_boil)
	#icy_touch
	Spell(icy_touch)
	#scourge_strike,if=unholy=1
	if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#death_coil
	Spell(death_coil)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction UnholyAoeShortCdActions
{
	#unholy_blight
	Spell(unholy_blight)
	#defile
	Spell(defile)
	#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeShortCdActions()

	unless { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil) or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
	{
		#blood_tap,if=level<=90&buff.shadow_infusion.stack=5
		if Level() <= 90 and BuffStacks(shadow_infusion_buff) == 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		#defile
		Spell(defile)
		#death_and_decay,if=unholy=1
		if Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(death_and_decay)

		unless target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike)
		{
			#blood_tap,if=buff.blood_charge.stack>10
			if BuffStacks(blood_charge_buff) > 10 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

			unless { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil)
			{
				#blood_tap
				if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
			}
		}
	}
}

AddFunction UnholyAoeCdActions
{
	unless Spell(unholy_blight)
	{
		unless Spell(defile)
		{
			#breath_of_sindragosa,if=runic_power>75
			if RunicPower() > 75 Spell(breath_of_sindragosa)
			#run_action_list,name=bos_aoe,if=dot.breath_of_sindragosa.ticking
			if BuffPresent(breath_of_sindragosa_buff) UnholyBosAoeCdActions()

			unless { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil)
			{
				#summon_gargoyle
				Spell(summon_gargoyle)

				unless BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation) or Spell(defile) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(death_and_decay) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy) or Rune(unholy) >= 2 and Spell(scourge_strike) or { RunicPower() > 90 or BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or Spell(blood_boil) or Spell(icy_touch) or Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
				{
					#empower_rune_weapon
					Spell(empower_rune_weapon)
				}
			}
		}
	}
}

### actions.bos_aoe

AddFunction UnholyBosAoeMainActions
{
	#blood_boil,if=runic_power<88
	if RunicPower() < 88 Spell(blood_boil)
	#scourge_strike,if=runic_power<88&unholy=1
	if RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 Spell(scourge_strike)
	#icy_touch,if=runic_power<88
	if RunicPower() < 88 Spell(icy_touch)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosAoeShortCdActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)

	unless RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosAoeCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 88 and Spell(blood_boil) or RunicPower() < 88 and Rune(unholy) >= 1 and Rune(unholy) < 2 and Spell(scourge_strike) or RunicPower() < 88 and Spell(icy_touch) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

### actions.bos_st

AddFunction UnholyBosStMainActions
{
	#festering_strike,if=runic_power<77
	if RunicPower() < 77 Spell(festering_strike)
	#scourge_strike,if=runic_power<88
	if RunicPower() < 88 Spell(scourge_strike)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosStShortCdActions
{
	#death_and_decay,if=runic_power<88
	if RunicPower() < 88 Spell(death_and_decay)

	unless RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike)
	{
		#blood_tap,if=buff.blood_charge.stack>=5
		if BuffStacks(blood_charge_buff) >= 5 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
	}
}

AddFunction UnholyBosStCdActions
{
	unless RunicPower() < 88 and Spell(death_and_decay) or RunicPower() < 77 and Spell(festering_strike) or RunicPower() < 88 and Spell(scourge_strike) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
	{
		#empower_rune_weapon
		Spell(empower_rune_weapon)
	}
}

### actions.precombat

AddFunction UnholyPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=calamari_crepes
	#horn_of_winter
	if BuffExpires(attack_power_multiplier_buff any=1) Spell(horn_of_winter)
	#unholy_presence
	Spell(unholy_presence)
}

AddFunction UnholyPrecombatShortCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
	{
		#raise_dead
		Spell(raise_dead)
	}
}

AddFunction UnholyPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

### actions.single_target

AddFunction UnholySingleTargetMainActions
{
	#plague_leech,if=(cooldown.outbreak.remains<1)&((blood<1&frost<1)|(blood<1&unholy<1)|(frost<1&unholy<1))
	if SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_leech,if=((blood<1&frost<1)|(blood<1&unholy<1)|(frost<1&unholy<1))&(dot.blood_plague.remains<3|dot.frost_fever.remains<3)
	if { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#plague_leech,if=(dot.blood_plague.remains<1|dot.frost_fever.remains<1)
	if { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#outbreak,if=!talent.necrotic_plague.enabled&(!dot.frost_fever.ticking|!dot.blood_plague.ticking)
	if not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } Spell(outbreak)
	#death_coil,if=runic_power>90
	if RunicPower() > 90 Spell(death_coil)
	#soul_reaper,if=(target.health.pct-3*(target.health.pct%target.time_to_die))<=45
	if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 Spell(soul_reaper_unholy)
	#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosStMainActions()
	#scourge_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(scourge_strike)
	#festering_strike,if=cooldown.breath_of_sindragosa.remains<7&runic_power<76&talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) Spell(festering_strike)
	#plague_strike,if=(!dot.blood_plague.ticking|!dot.frost_fever.ticking)&unholy=2
	if { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Rune(unholy) >= 2 Spell(plague_strike)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#death_coil,if=runic_power>80
	if RunicPower() > 80 Spell(death_coil)
	#festering_strike,if=blood=2&frost=2&(((Frost-death)>0)|((Blood-death)>0))
	if Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } Spell(festering_strike)
	#festering_strike,if=(blood=2|frost=2)&(((Frost-death)>0)&((Blood-death)>0))
	if { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 Spell(festering_strike)
	#plague_strike,if=(!dot.blood_plague.ticking|!dot.frost_fever.ticking)&(blood=2|frost=2)
	if { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and { Rune(blood) >= 2 or Rune(frost) >= 2 } Spell(plague_strike)
	#scourge_strike,if=blood=2|frost=2
	if Rune(blood) >= 2 or Rune(frost) >= 2 Spell(scourge_strike)
	#festering_strike,if=((Blood-death)>1)
	if Rune(blood death=0) > 1 Spell(festering_strike)
	#blood_boil,if=((Blood-death)>1)
	if Rune(blood death=0) > 1 Spell(blood_boil)
	#festering_strike,if=((Frost-death)>1)
	if Rune(frost death=0) > 1 Spell(festering_strike)
	#plague_strike,if=(!dot.blood_plague.ticking|!dot.frost_fever.ticking)
	if not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) Spell(plague_strike)
	#dark_transformation
	if BuffStacks(shadow_infusion_buff) >= 5 Spell(dark_transformation)
	#death_coil,if=buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1)
	if BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 Spell(death_coil)
	#scourge_strike,if=!((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)|(Unholy>=2)
	if not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 Spell(scourge_strike)
	#festering_strike,if=!((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)|(((Frost-death)>0)&((Blood-death)>0))
	if not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(frost death=0) > 0 and Rune(blood death=0) > 0 Spell(festering_strike)
	#death_coil
	Spell(death_coil)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#scourge_strike,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(scourge_strike)
	#festering_strike,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(festering_strike)
	#blood_boil,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(blood_boil)
	#icy_touch,if=cooldown.empower_rune_weapon.remains=0
	if not SpellCooldown(empower_rune_weapon) > 0 Spell(icy_touch)
}

AddFunction UnholySingleTargetShortCdActions
{
	unless SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak)
	{
		#unholy_blight,if=!talent.necrotic_plague.enabled&(dot.frost_fever.remains<3|dot.blood_plague.remains<3)
		if not Talent(necrotic_plague_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } Spell(unholy_blight)
		#unholy_blight,if=talent.necrotic_plague.enabled&dot.necrotic_plague.remains<1
		if Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 Spell(unholy_blight)

		unless RunicPower() > 90 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy)
		{
			#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
			if BuffPresent(breath_of_sindragosa_buff) UnholyBosStShortCdActions()
			#death_and_decay,if=cooldown.breath_of_sindragosa.remains<7&runic_power<88&talent.breath_of_sindragosa.enabled
			if SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) Spell(death_and_decay)

			unless SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike)
			{
				#blood_tap,if=((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)&cooldown.soul_reaper.remains=0
				if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
				#death_and_decay,if=unholy=2
				if Rune(unholy) >= 2 Spell(death_and_decay)
				#defile,if=unholy=2
				if Rune(unholy) >= 2 Spell(defile)

				unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Rune(unholy) >= 2 and Spell(plague_strike) or Rune(unholy) >= 2 and Spell(scourge_strike) or RunicPower() > 80 and Spell(death_coil) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike)
				{
					#defile,if=blood=2|frost=2
					if Rune(blood) >= 2 or Rune(frost) >= 2 Spell(defile)

					unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(plague_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(scourge_strike) or Rune(blood death=0) > 1 and Spell(festering_strike) or Rune(blood death=0) > 1 and Spell(blood_boil) or Rune(frost death=0) > 1 and Spell(festering_strike)
					{
						#blood_tap,if=((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)&cooldown.soul_reaper.remains=0
						if target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and not SpellCooldown(soul_reaper_unholy) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
						#death_and_decay
						Spell(death_and_decay)
						#defile
						Spell(defile)
						#blood_tap,if=cooldown.defile.remains=0
						if not SpellCooldown(defile) > 0 and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

						unless { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike) or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation)
						{
							#blood_tap,if=buff.blood_charge.stack>10&(buff.sudden_doom.react|(buff.dark_transformation.down&unholy<=1))
							if BuffStacks(blood_charge_buff) > 10 and { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)

							unless { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 } and Spell(scourge_strike)
							{
								#blood_tap
								if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
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
	unless SpellCooldown(outbreak) < 1 and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and { target.DebuffRemaining(blood_plague_debuff) < 3 or target.DebuffRemaining(frost_fever_debuff) < 3 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or { target.DebuffRemaining(blood_plague_debuff) < 1 or target.DebuffRemaining(frost_fever_debuff) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not Talent(necrotic_plague_talent) and { not target.DebuffPresent(frost_fever_debuff) or not target.DebuffPresent(blood_plague_debuff) } and Spell(outbreak) or not Talent(necrotic_plague_talent) and { target.DebuffRemaining(frost_fever_debuff) < 3 or target.DebuffRemaining(blood_plague_debuff) < 3 } and Spell(unholy_blight) or Talent(necrotic_plague_talent) and target.DebuffRemaining(necrotic_plague_debuff) < 1 and Spell(unholy_blight) or RunicPower() > 90 and Spell(death_coil) or target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 and Spell(soul_reaper_unholy)
	{
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos_st,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosStCdActions()

		unless SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(death_and_decay) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 88 and Talent(breath_of_sindragosa_talent) and Spell(scourge_strike) or SpellCooldown(breath_of_sindragosa) < 7 and RunicPower() < 76 and Talent(breath_of_sindragosa_talent) and Spell(festering_strike) or Rune(unholy) >= 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(defile) or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Rune(unholy) >= 2 and Spell(plague_strike) or Rune(unholy) >= 2 and Spell(scourge_strike) or RunicPower() > 80 and Spell(death_coil) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(defile) or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(plague_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(scourge_strike) or Rune(blood death=0) > 1 and Spell(festering_strike) or Rune(blood death=0) > 1 and Spell(blood_boil) or Rune(frost death=0) > 1 and Spell(festering_strike)
		{
			#summon_gargoyle
			Spell(summon_gargoyle)

			unless Spell(death_and_decay) or Spell(defile) or { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } and Spell(plague_strike) or BuffStacks(shadow_infusion_buff) >= 5 and Spell(dark_transformation) or { BuffPresent(sudden_doom_buff) or pet.BuffExpires(dark_transformation_buff any=1) and Rune(unholy) < 2 } and Spell(death_coil) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(unholy death=1) >= 2 } and Spell(scourge_strike) or { not target.HealthPercent() - 3 * target.HealthPercent() / target.TimeToDie() <= 45 or Rune(frost death=0) > 0 and Rune(blood death=0) > 0 } and Spell(festering_strike) or Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(scourge_strike) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(festering_strike) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(blood_boil) or not SpellCooldown(empower_rune_weapon) > 0 and Spell(icy_touch)
			{
				#empower_rune_weapon,if=blood<1&unholy<1&frost<1
				if Rune(blood) < 1 and Rune(unholy) < 1 and Rune(frost) < 1 Spell(empower_rune_weapon)
			}
		}
	}
}

### actions.spread

AddFunction UnholySpreadMainActions
{
	#blood_boil,cycle_targets=1,if=dot.blood_plague.ticking|dot.frost_fever.ticking
	if target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) Spell(blood_boil)
	#outbreak,if=!talent.necrotic_plague.enabled&(!dot.blood_plague.ticking|!dot.frost_fever.ticking)
	if not Talent(necrotic_plague_talent) and { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } Spell(outbreak)
	#outbreak,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(outbreak)
	#plague_strike,if=!talent.necrotic_plague.enabled&(!dot.blood_plague.ticking|!dot.frost_fever.ticking)
	if not Talent(necrotic_plague_talent) and { not target.DebuffPresent(blood_plague_debuff) or not target.DebuffPresent(frost_fever_debuff) } Spell(plague_strike)
	#plague_strike,if=talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(plague_strike)
}

### Unholy icons.
AddCheckBox(opt_deathknight_unholy_aoe L(AOE) specialization=unholy default)

AddIcon specialization=unholy help=shortcd enemies=1 checkbox=!opt_deathknight_unholy_aoe
{
	if not InCombat() UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=shortcd checkbox=opt_deathknight_unholy_aoe
{
	if not InCombat() UnholyPrecombatShortCdActions()
	UnholyDefaultShortCdActions()
}

AddIcon specialization=unholy help=main enemies=1
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon specialization=unholy help=aoe checkbox=opt_deathknight_unholy_aoe
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon specialization=unholy help=cd enemies=1 checkbox=!opt_deathknight_unholy_aoe
{
	if not InCombat() UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
}

AddIcon specialization=unholy help=cd checkbox=opt_deathknight_unholy_aoe
{
	if not InCombat() UnholyPrecombatCdActions()
	UnholyDefaultCdActions()
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
# breath_of_sindragosa
# breath_of_sindragosa_buff
# breath_of_sindragosa_talent
# dark_transformation
# dark_transformation_buff
# death_and_decay
# death_coil
# deaths_advance
# defile
# draenic_strength_potion
# empower_rune_weapon
# festering_strike
# frost_fever_debuff
# horn_of_winter
# icy_touch
# mind_freeze
# necrotic_plague_debuff
# necrotic_plague_talent
# outbreak
# plague_leech
# plague_strike
# quaking_palm
# raise_dead
# scourge_strike
# shadow_infusion_buff
# soul_reaper_unholy
# strangulate
# sudden_doom_buff
# summon_gargoyle
# unholy_blight
# unholy_presence
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "reference")
end
