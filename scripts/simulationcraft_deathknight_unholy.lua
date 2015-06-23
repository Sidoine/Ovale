local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_death_knight_unholy_t18m"
	local desc = "[6.2] SimulationCraft: Death_Knight_Unholy_T18M"
	local code = [[
# Based on SimulationCraft profile "Death_Knight_Unholy_T18M".
#	class=deathknight
#	spec=unholy
#	talents=2001003

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=unholy)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=unholy)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=unholy)

AddFunction UnholyUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction UnholyUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction UnholyGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(plague_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction UnholyInterruptActions
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

AddFunction UnholyDefaultMainActions
{
	#run_action_list,name=unholy
	UnholyUnholyMainActions()
}

AddFunction UnholyDefaultShortCdActions
{
	#auto_attack
	UnholyGetInMeleeRange()
	#deaths_advance,if=movement.remains>2
	if 0 > 2 Spell(deaths_advance)
	#antimagic_shell,damage=100000,if=((dot.breath_of_sindragosa.ticking&runic_power<25)|cooldown.breath_of_sindragosa.remains>40)|!talent.breath_of_sindragosa.enabled
	if { BuffPresent(breath_of_sindragosa_buff) and RunicPower() < 25 or SpellCooldown(breath_of_sindragosa) > 40 or not Talent(breath_of_sindragosa_talent) } and IncomingDamage(1.5 magic=1) > 0 Spell(antimagic_shell)
	#run_action_list,name=unholy
	UnholyUnholyShortCdActions()
}

AddFunction UnholyDefaultCdActions
{
	#mind_freeze,if=!glyph.mind_freeze.enabled
	if not Glyph(glyph_of_mind_freeze) UnholyInterruptActions()
	#blood_fury,if=!talent.breath_of_sindragosa.enabled
	if not Talent(breath_of_sindragosa_talent) Spell(blood_fury_ap)
	#berserking,if=!talent.breath_of_sindragosa.enabled
	if not Talent(breath_of_sindragosa_talent) Spell(berserking)
	#arcane_torrent,if=!talent.breath_of_sindragosa.enabled
	if not Talent(breath_of_sindragosa_talent) Spell(arcane_torrent_runicpower)
	#use_item,slot=finger1,if=!talent.breath_of_sindragosa.enabled
	if not Talent(breath_of_sindragosa_talent) UnholyUseItemActions()
	#potion,name=draenic_strength,if=(buff.dark_transformation.up&target.time_to_die<=60)&!talent.breath_of_sindragosa.enabled
	if pet.BuffPresent(dark_transformation_buff) and target.TimeToDie() <= 60 and not Talent(breath_of_sindragosa_talent) UnholyUsePotionStrength()
	#run_action_list,name=unholy
	UnholyUnholyCdActions()
}

### actions.bos

AddFunction UnholyBosMainActions
{
	#plague_strike,if=!disease.ticking
	if not target.DiseasesAnyTicking() Spell(plague_strike)
	#blood_boil,cycle_targets=1,if=(spell_targets.blood_boil>=2&!(dot.blood_plague.ticking|dot.frost_fever.ticking))|spell_targets.blood_boil>=4&(runic_power<88&runic_power>30)
	if Enemies() >= 2 and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 Spell(blood_boil)
	#festering_strike,if=(blood=2&frost=2&(((Frost-death)>0)|((Blood-death)>0)))&runic_power<80
	if Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and RunicPower() < 80 Spell(festering_strike)
	#festering_strike,if=((blood=2|frost=2)&(((Frost-death)>0)&((Blood-death)>0)))&runic_power<80
	if { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and RunicPower() < 80 Spell(festering_strike)
	#scourge_strike,if=spell_targets.blood_boil<=3&(runic_power<88&runic_power>30)
	if Enemies() <= 3 and RunicPower() < 88 and RunicPower() > 30 Spell(scourge_strike)
	#blood_boil,if=spell_targets.blood_boil>=4&(runic_power<88&runic_power>30)
	if Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 Spell(blood_boil)
	#festering_strike,if=runic_power<77
	if RunicPower() < 77 Spell(festering_strike)
	#scourge_strike,if=(spell_targets.blood_boil>=4&(runic_power<88&runic_power>30))|spell_targets.blood_boil<=3
	if Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 or Enemies() <= 3 Spell(scourge_strike)
	#dark_transformation
	Spell(dark_transformation)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#death_coil,if=buff.sudden_doom.react
	if BuffPresent(sudden_doom_buff) Spell(death_coil)
}

AddFunction UnholyBosShortCdActions
{
	#unholy_blight,if=!disease.ticking
	if not target.DiseasesAnyTicking() Spell(unholy_blight)

	unless not target.DiseasesAnyTicking() and Spell(plague_strike) or { Enemies() >= 2 and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 } and Spell(blood_boil)
	{
		#death_and_decay,if=spell_targets.death_and_decay>=2&(runic_power<88&runic_power>30)
		if Enemies() >= 2 and RunicPower() < 88 and RunicPower() > 30 Spell(death_and_decay)

		unless Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and RunicPower() < 80 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and RunicPower() < 80 and Spell(festering_strike) or Enemies() <= 3 and RunicPower() < 88 and RunicPower() > 30 and Spell(scourge_strike) or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 and Spell(blood_boil) or RunicPower() < 77 and Spell(festering_strike) or { Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 or Enemies() <= 3 } and Spell(scourge_strike) or Spell(dark_transformation)
		{
			#blood_tap,if=buff.blood_charge.stack>=5
			if BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
		}
	}
}

AddFunction UnholyBosShortCdPostConditions
{
	not target.DiseasesAnyTicking() and Spell(plague_strike) or { Enemies() >= 2 and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 } and Spell(blood_boil) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and RunicPower() < 80 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and RunicPower() < 80 and Spell(festering_strike) or Enemies() <= 3 and RunicPower() < 88 and RunicPower() > 30 and Spell(scourge_strike) or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 and Spell(blood_boil) or RunicPower() < 77 and Spell(festering_strike) or { Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 or Enemies() <= 3 } and Spell(scourge_strike) or Spell(dark_transformation) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

AddFunction UnholyBosCdActions
{
	#blood_fury,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) Spell(blood_fury_ap)
	#berserking,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) Spell(berserking)
	#use_item,slot=finger1,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyUseItemActions()
	#potion,name=draenic_strength,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyUsePotionStrength()

	unless not target.DiseasesAnyTicking() and Spell(unholy_blight) or not target.DiseasesAnyTicking() and Spell(plague_strike) or { Enemies() >= 2 and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 } and Spell(blood_boil) or Enemies() >= 2 and RunicPower() < 88 and RunicPower() > 30 and Spell(death_and_decay) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and RunicPower() < 80 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and RunicPower() < 80 and Spell(festering_strike)
	{
		#arcane_torrent,if=runic_power<70
		if RunicPower() < 70 Spell(arcane_torrent_runicpower)

		unless Enemies() <= 3 and RunicPower() < 88 and RunicPower() > 30 and Spell(scourge_strike) or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 and Spell(blood_boil) or RunicPower() < 77 and Spell(festering_strike) or { Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 or Enemies() <= 3 } and Spell(scourge_strike) or Spell(dark_transformation) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
		{
			#empower_rune_weapon,if=runic_power<60
			if RunicPower() < 60 Spell(empower_rune_weapon)
		}
	}
}

AddFunction UnholyBosCdPostConditions
{
	not target.DiseasesAnyTicking() and Spell(unholy_blight) or not target.DiseasesAnyTicking() and Spell(plague_strike) or { Enemies() >= 2 and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 } and Spell(blood_boil) or Enemies() >= 2 and RunicPower() < 88 and RunicPower() > 30 and Spell(death_and_decay) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and RunicPower() < 80 and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and RunicPower() < 80 and Spell(festering_strike) or Enemies() <= 3 and RunicPower() < 88 and RunicPower() > 30 and Spell(scourge_strike) or Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 and Spell(blood_boil) or RunicPower() < 77 and Spell(festering_strike) or { Enemies() >= 4 and RunicPower() < 88 and RunicPower() > 30 or Enemies() <= 3 } and Spell(scourge_strike) or Spell(dark_transformation) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or BuffPresent(sudden_doom_buff) and Spell(death_coil)
}

### actions.precombat

AddFunction UnholyPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=salty_squid_roll
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

AddFunction UnholyPrecombatShortCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
}

AddFunction UnholyPrecombatCdActions
{
	unless BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence)
	{
		#snapshot_stats
		#army_of_the_dead
		Spell(army_of_the_dead)
		#potion,name=draenic_strength
		UnholyUsePotionStrength()
	}
}

AddFunction UnholyPrecombatCdPostConditions
{
	BuffExpires(attack_power_multiplier_buff any=1) and Spell(horn_of_winter) or Spell(unholy_presence) or Spell(raise_dead)
}

### actions.unholy

AddFunction UnholyUnholyMainActions
{
	#plague_leech,if=((cooldown.outbreak.remains<1)|disease.min_remains<1)&((blood<1&frost<1)|(blood<1&unholy<1)|(frost<1&unholy<1))
	if { SpellCooldown(outbreak) < 1 or target.DiseasesRemaining() < 1 } and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
	#soul_reaper,if=(target.health.pct-3*(target.health.pct%target.time_to_die))<=45
	if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 45 Spell(soul_reaper_unholy)
	#run_action_list,name=bos,if=dot.breath_of_sindragosa.ticking
	if BuffPresent(breath_of_sindragosa_buff) UnholyBosMainActions()
	#outbreak,cycle_targets=1,if=!talent.necrotic_plague.enabled&(!(dot.blood_plague.ticking|dot.frost_fever.ticking))
	if not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } Spell(outbreak)
	#plague_strike,if=(!talent.necrotic_plague.enabled&!(dot.blood_plague.ticking|dot.frost_fever.ticking))|(talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking)
	if not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) Spell(plague_strike)
	#blood_boil,cycle_targets=1,if=(spell_targets.blood_boil>1&!talent.necrotic_plague.enabled)&(!(dot.blood_plague.ticking|dot.frost_fever.ticking))
	if Enemies() > 1 and not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } Spell(blood_boil)
	#scourge_strike,if=unholy=2
	if Rune(unholy) >= 2 Spell(scourge_strike)
	#festering_strike,if=talent.necrotic_plague.enabled&talent.unholy_blight.enabled&dot.necrotic_plague.remains<cooldown.unholy_blight.remains%2
	if Talent(necrotic_plague_talent) and Talent(unholy_blight_talent) and target.DebuffRemaining(necrotic_plague_debuff) < SpellCooldown(unholy_blight) / 2 Spell(festering_strike)
	#dark_transformation
	Spell(dark_transformation)
	#festering_strike,if=blood=2&frost=2&(((Frost-death)>0)|((Blood-death)>0))
	if Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } Spell(festering_strike)
	#festering_strike,if=(blood=2|frost=2)&(((Frost-death)>0)&((Blood-death)>0))
	if { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 Spell(festering_strike)
	#blood_boil,cycle_targets=1,if=(talent.necrotic_plague.enabled&!dot.necrotic_plague.ticking)&spell_targets.blood_boil>1
	if Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Enemies() > 1 Spell(blood_boil)
	#blood_boil,if=talent.breath_of_sindragosa.enabled&((spell_targets.blood_boil>=4&(blood=2|(frost=2&death=2)))&(cooldown.breath_of_sindragosa.remains>6|runic_power<75))
	if Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 } Spell(blood_boil)
	#blood_boil,if=!talent.breath_of_sindragosa.enabled&(spell_targets.blood_boil>=4&(blood=2|(frost=2&death=2)))
	if not Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } Spell(blood_boil)
	#outbreak,if=talent.necrotic_plague.enabled&debuff.necrotic_plague.stack<=14
	if Talent(necrotic_plague_talent) and target.DebuffStacks(necrotic_plague_debuff) <= 14 Spell(outbreak)
	#death_coil,if=(buff.sudden_doom.react|runic_power>80)&(buff.blood_charge.stack<=10)
	if { BuffPresent(sudden_doom_buff) or RunicPower() > 80 } and BuffStacks(blood_charge_buff) <= 10 Spell(death_coil)
	#blood_boil,if=(spell_targets.blood_boil>=4&(cooldown.breath_of_sindragosa.remains>6|runic_power<75))|(!talent.breath_of_sindragosa.enabled&spell_targets.blood_boil>=4)
	if Enemies() >= 4 and { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 } or not Talent(breath_of_sindragosa_talent) and Enemies() >= 4 Spell(blood_boil)
	#scourge_strike,if=(cooldown.breath_of_sindragosa.remains>6|runic_power<75|unholy=2)|!talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 or Rune(unholy) >= 2 or not Talent(breath_of_sindragosa_talent) Spell(scourge_strike)
	#festering_strike,if=(cooldown.breath_of_sindragosa.remains>6|runic_power<75)|!talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 or not Talent(breath_of_sindragosa_talent) Spell(festering_strike)
	#death_coil,if=(cooldown.breath_of_sindragosa.remains>20)|!talent.breath_of_sindragosa.enabled
	if SpellCooldown(breath_of_sindragosa) > 20 or not Talent(breath_of_sindragosa_talent) Spell(death_coil)
	#plague_leech
	if target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } Spell(plague_leech)
}

AddFunction UnholyUnholyShortCdActions
{
	unless { SpellCooldown(outbreak) < 1 or target.DiseasesRemaining() < 1 } and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 45 and Spell(soul_reaper_unholy)
	{
		#blood_tap,if=((target.health.pct-3*(target.health.pct%target.time_to_die))<=45)&cooldown.soul_reaper.remains=0
		if target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 45 and not SpellCooldown(soul_reaper_unholy) > 0 Spell(blood_tap)
		#run_action_list,name=bos,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosShortCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosShortCdPostConditions()
		{
			#unholy_blight,if=!disease.min_ticking
			if not target.DiseasesTicking() Spell(unholy_blight)

			unless not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } and Spell(outbreak) or { not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(plague_strike) or Enemies() > 1 and not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } and Spell(blood_boil)
			{
				#death_and_decay,if=spell_targets.death_and_decay>1&unholy>1
				if Enemies() > 1 and Rune(unholy) >= 2 Spell(death_and_decay)
				#defile,if=unholy=2
				if Rune(unholy) >= 2 Spell(defile)
				#blood_tap,if=talent.defile.enabled&cooldown.defile.remains=0
				if Talent(defile_talent) and not SpellCooldown(defile) > 0 Spell(blood_tap)

				unless Rune(unholy) >= 2 and Spell(scourge_strike) or Talent(necrotic_plague_talent) and Talent(unholy_blight_talent) and target.DebuffRemaining(necrotic_plague_debuff) < SpellCooldown(unholy_blight) / 2 and Spell(festering_strike) or Spell(dark_transformation) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Enemies() > 1 and Spell(blood_boil)
				{
					#defile,if=blood=2|frost=2
					if Rune(blood) >= 2 or Rune(frost) >= 2 Spell(defile)
					#death_and_decay,if=spell_targets.death_and_decay>1
					if Enemies() > 1 Spell(death_and_decay)
					#defile
					Spell(defile)

					unless Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 } and Spell(blood_boil) or not Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil)
					{
						#blood_tap,if=buff.blood_charge.stack>10
						if BuffStacks(blood_charge_buff) > 10 Spell(blood_tap)
					}
				}
			}
		}
	}
}

AddFunction UnholyUnholyCdActions
{
	unless { SpellCooldown(outbreak) < 1 or target.DiseasesRemaining() < 1 } and { Rune(blood) < 1 and Rune(frost) < 1 or Rune(blood) < 1 and Rune(unholy) < 1 or Rune(frost) < 1 and Rune(unholy) < 1 } and target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech) or target.HealthPercent() - 3 * { target.HealthPercent() / target.TimeToDie() } <= 45 and Spell(soul_reaper_unholy)
	{
		#summon_gargoyle
		Spell(summon_gargoyle)
		#breath_of_sindragosa,if=runic_power>75
		if RunicPower() > 75 Spell(breath_of_sindragosa)
		#run_action_list,name=bos,if=dot.breath_of_sindragosa.ticking
		if BuffPresent(breath_of_sindragosa_buff) UnholyBosCdActions()

		unless BuffPresent(breath_of_sindragosa_buff) and UnholyBosCdPostConditions() or not target.DiseasesTicking() and Spell(unholy_blight) or not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } and Spell(outbreak) or { not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) } and Spell(plague_strike) or Enemies() > 1 and not Talent(necrotic_plague_talent) and not { target.DebuffPresent(blood_plague_debuff) or target.DebuffPresent(frost_fever_debuff) } and Spell(blood_boil) or Enemies() > 1 and Rune(unholy) >= 2 and Spell(death_and_decay) or Rune(unholy) >= 2 and Spell(defile) or Rune(unholy) >= 2 and Spell(scourge_strike) or Talent(necrotic_plague_talent) and Talent(unholy_blight_talent) and target.DebuffRemaining(necrotic_plague_debuff) < SpellCooldown(unholy_blight) / 2 and Spell(festering_strike) or Spell(dark_transformation) or Rune(blood) >= 2 and Rune(frost) >= 2 and { Rune(frost death=0) > 0 or Rune(blood death=0) > 0 } and Spell(festering_strike) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Rune(frost death=0) > 0 and Rune(blood death=0) > 0 and Spell(festering_strike) or Talent(necrotic_plague_talent) and not target.DebuffPresent(necrotic_plague_debuff) and Enemies() > 1 and Spell(blood_boil) or { Rune(blood) >= 2 or Rune(frost) >= 2 } and Spell(defile) or Enemies() > 1 and Spell(death_and_decay) or Spell(defile) or Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 } and Spell(blood_boil) or not Talent(breath_of_sindragosa_talent) and Enemies() >= 4 and { Rune(blood) >= 2 or Rune(frost) >= 2 and Rune(death) >= 2 and Rune(death) < 3 } and Spell(blood_boil) or Talent(necrotic_plague_talent) and target.DebuffStacks(necrotic_plague_debuff) <= 14 and Spell(outbreak) or { BuffPresent(sudden_doom_buff) or RunicPower() > 80 } and BuffStacks(blood_charge_buff) <= 10 and Spell(death_coil) or { Enemies() >= 4 and { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 } or not Talent(breath_of_sindragosa_talent) and Enemies() >= 4 } and Spell(blood_boil) or { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 or Rune(unholy) >= 2 or not Talent(breath_of_sindragosa_talent) } and Spell(scourge_strike) or { SpellCooldown(breath_of_sindragosa) > 6 or RunicPower() < 75 or not Talent(breath_of_sindragosa_talent) } and Spell(festering_strike) or { SpellCooldown(breath_of_sindragosa) > 20 or not Talent(breath_of_sindragosa_talent) } and Spell(death_coil) or target.DiseasesTicking() and { Rune(blood) < 1 or Rune(frost) < 1 or Rune(unholy) < 1 } and Spell(plague_leech)
		{
			#empower_rune_weapon,if=!talent.breath_of_sindragosa.enabled
			if not Talent(breath_of_sindragosa_talent) Spell(empower_rune_weapon)
		}
	}
}

### Unholy icons.

AddCheckBox(opt_deathknight_unholy_aoe L(AOE) default specialization=unholy)

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=shortcd specialization=unholy
{
	if not InCombat() UnholyPrecombatShortCdActions()
	unless not InCombat() and UnholyPrecombatShortCdPostConditions()
	{
		UnholyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=shortcd specialization=unholy
{
	if not InCombat() UnholyPrecombatShortCdActions()
	unless not InCombat() and UnholyPrecombatShortCdPostConditions()
	{
		UnholyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=unholy
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=aoe specialization=unholy
{
	if not InCombat() UnholyPrecombatMainActions()
	UnholyDefaultMainActions()
}

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=cd specialization=unholy
{
	if not InCombat() UnholyPrecombatCdActions()
	unless not InCombat() and UnholyPrecombatCdPostConditions()
	{
		UnholyDefaultCdActions()
	}
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=cd specialization=unholy
{
	if not InCombat() UnholyPrecombatCdActions()
	unless not InCombat() and UnholyPrecombatCdPostConditions()
	{
		UnholyDefaultCdActions()
	}
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
# defile_talent
# draenic_strength_potion
# empower_rune_weapon
# festering_strike
# frost_fever_debuff
# glyph_of_mind_freeze
# horn_of_winter
# mind_freeze
# necrotic_plague_debuff
# necrotic_plague_talent
# outbreak
# plague_leech
# plague_strike
# quaking_palm
# raise_dead
# scourge_strike
# soul_reaper_unholy
# strangulate
# sudden_doom_buff
# summon_gargoyle
# unholy_blight
# unholy_blight_talent
# unholy_presence
# war_stomp
]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", "unholy", name, desc, code, "script")
end
