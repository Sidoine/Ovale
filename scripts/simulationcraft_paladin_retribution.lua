local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Paladin_Retribution_T17M"
	local desc = "[6.0] SimulationCraft: Paladin_Retribution_T17M"
	local code = [[
# Based on SimulationCraft profile "Paladin_Retribution_T17M".
#	class=paladin
#	spec=retribution
#	talents=2112333
#	glyphs=winged_vengeance/templars_verdict/righteous_retreat/fire_from_the_heavens/judgment

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default)

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

AddFunction GetInMeleeRange
{
	if not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if not target.Classification(worldboss)
		{
			if target.InRange(fist_of_justice) Spell(fist_of_justice)
			if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			Spell(blinding_light)
			Spell(arcane_torrent_holy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

AddFunction RighteousFuryOff
{
	if CheckBoxOn(opt_righteous_fury_check) and BuffPresent(righteous_fury) Texture(spell_holy_sealoffury text=cancel)
}

### actions.default

AddFunction RetributionDefaultMainActions
{
	#judgment,if=talent.empowered_seals.enabled&time<2
	if Talent(empowered_seals_talent) and TimeInCombat() < 2 Spell(judgment)
	#wait,sec=cooldown.seraphim.remains,if=talent.seraphim.enabled&cooldown.seraphim.remains>0&cooldown.seraphim.remains<gcd.max&holy_power>=5
	unless Talent(seraphim_talent) and SpellCooldown(seraphim) > 0 and SpellCooldown(seraphim) < GCD() and HolyPower() >= 5 and SpellCooldown(seraphim) > 0
	{
		#call_action_list,name=cleave,if=active_enemies>=3
		if Enemies() >= 3 RetributionCleaveMainActions()
		#call_action_list,name=single
		RetributionSingleMainActions()
	}
}

AddFunction RetributionDefaultShortCdActions
{
	#auto_attack
	#speed_of_light,if=movement.distance>5
	if 0 > 5 Spell(speed_of_light)

	unless Talent(empowered_seals_talent) and TimeInCombat() < 2 and Spell(judgment)
	{
		#execution_sentence
		Spell(execution_sentence)
		#lights_hammer
		Spell(lights_hammer)
		#seraphim
		Spell(seraphim)
	}
}

AddFunction RetributionDefaultCdActions
{
	#rebuke
	InterruptActions()
	#potion,name=draenic_strength,if=(buff.bloodlust.react|buff.avenging_wrath.up|target.time_to_die<=40)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_melee_buff) or target.TimeToDie() <= 40 UsePotionStrength()

	unless Talent(empowered_seals_talent) and TimeInCombat() < 2 and Spell(judgment) or Spell(execution_sentence) or Spell(lights_hammer)
	{
		#use_item,name=vial_of_convulsive_shadows,if=buff.avenging_wrath.up
		if BuffPresent(avenging_wrath_melee_buff) UseItemActions()
		#holy_avenger,sync=seraphim,if=talent.seraphim.enabled
		if not SpellCooldown(seraphim) > 0 and Talent(seraphim_talent) Spell(holy_avenger)
		#holy_avenger,if=holy_power<=2&!talent.seraphim.enabled
		if HolyPower() <= 2 and not Talent(seraphim_talent) Spell(holy_avenger)
		#avenging_wrath,sync=seraphim,if=talent.seraphim.enabled
		if not SpellCooldown(seraphim) > 0 and Talent(seraphim_talent) Spell(avenging_wrath_melee)
		#avenging_wrath,if=!talent.seraphim.enabled
		if not Talent(seraphim_talent) Spell(avenging_wrath_melee)
		#blood_fury
		Spell(blood_fury_apsp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_holy)
	}
}

### actions.cleave

AddFunction RetributionCleaveMainActions
{
	#final_verdict,if=buff.final_verdict.down&holy_power=5
	if BuffExpires(final_verdict_buff) and HolyPower() == 5 Spell(final_verdict)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=holy_power=5&buff.final_verdict.up
	if HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power=5&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*4)&!talent.final_verdict.enabled
	if HolyPower() == 5 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 4 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Spell(exorcism)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<=5
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= 5 Spell(judgment)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up&(buff.avenging_wrath.up|target.health.pct<35)
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(divine_storm)
	#divine_storm,if=buff.final_verdict.up&(buff.avenging_wrath.up|target.health.pct<35)
	if BuffPresent(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(divine_storm)
	#final_verdict,if=buff.final_verdict.down&(buff.avenging_wrath.up|target.health.pct<35)
	if BuffExpires(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(final_verdict)
	#divine_storm,if=buff.divine_crusader.react&(buff.avenging_wrath.up|target.health.pct<35)&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=(buff.avenging_wrath.up|target.health.pct<35)&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*5)&!talent.final_verdict.enabled
	if { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 5 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#hammer_of_the_righteous,if=active_enemies>=4&holy_power<5
	if Enemies() >= 4 and HolyPower() < 5 Spell(hammer_of_the_righteous)
	#crusader_strike,if=holy_power<5
	if HolyPower() < 5 Spell(crusader_strike)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_purpose.react&buff.final_verdict.up
	if BuffPresent(divine_purpose_buff) and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=holy_power>=4&buff.final_verdict.up
	if HolyPower() >= 4 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict,if=buff.divine_purpose.react&buff.final_verdict.down
	if BuffPresent(divine_purpose_buff) and BuffExpires(final_verdict_buff) Spell(final_verdict)
	#final_verdict,if=holy_power>=4&buff.final_verdict.down
	if HolyPower() >= 4 and BuffExpires(final_verdict_buff) Spell(final_verdict)
	#divine_storm,if=buff.divine_crusader.react&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power>=4&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*5)&!talent.final_verdict.enabled
	if HolyPower() >= 4 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 5 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#exorcism,if=glyph.mass_exorcism.enabled&holy_power<5
	if Glyph(glyph_of_mass_exorcism) and HolyPower() < 5 Spell(exorcism)
	#judgment,cycle_targets=1,if=glyph.double_jeopardy.enabled&holy_power<5
	if Glyph(glyph_of_double_jeopardy) and HolyPower() < 5 Spell(judgment)
	#judgment,if=holy_power<5
	if HolyPower() < 5 Spell(judgment)
	#exorcism,if=holy_power<5
	if HolyPower() < 5 Spell(exorcism)
	#divine_storm,if=holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*6)&!talent.final_verdict.enabled
	if HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 6 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power>=3&buff.final_verdict.up
	if HolyPower() >= 3 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict,if=holy_power>=3&buff.final_verdict.down
	if HolyPower() >= 3 and BuffExpires(final_verdict_buff) Spell(final_verdict)
}

### actions.precombat

AddFunction RetributionPrecombatMainActions
{
	#flask,type=greater_draenic_strength_flask
	#food,type=sleeper_surprise
	#blessing_of_kings,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_truth,if=active_enemies<2
	if Enemies() < 2 Spell(seal_of_truth)
	#seal_of_righteousness,if=active_enemies>=2
	if Enemies() >= 2 Spell(seal_of_righteousness)
}

AddFunction RetributionPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings) or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might) or Enemies() < 2 and Spell(seal_of_truth) or Enemies() >= 2 and Spell(seal_of_righteousness)
	{
		#snapshot_stats
		#potion,name=draenic_strength
		UsePotionStrength()
	}
}

### actions.single

AddFunction RetributionSingleMainActions
{
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&active_enemies=2&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Enemies() == 2 and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power=5&active_enemies=2&buff.final_verdict.up
	if HolyPower() == 5 and Enemies() == 2 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&(talent.seraphim.enabled&cooldown.seraphim.remains<gcd*4)
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Talent(seraphim_talent) and SpellCooldown(seraphim) < GCD() * 4 Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*4)
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 4 } Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<3
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 3 Spell(templars_verdict)
	#divine_storm,if=buff.divine_crusader.react&buff.divine_crusader.remains<3&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and BuffRemaining(divine_crusader_buff) < 3 and not Talent(final_verdict_talent) Spell(divine_storm)
	#final_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(final_verdict)
	#final_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<3
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 3 Spell(final_verdict)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#judgment,if=talent.empowered_seals.enabled&seal.truth&buff.maraads_truth.remains<cooldown.judgment.duration
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) Spell(judgment)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<cooldown.judgment.duration
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) Spell(judgment)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Spell(exorcism)
	#seal_of_truth,if=talent.empowered_seals.enabled&buff.maraads_truth.down
	if Talent(empowered_seals_talent) and BuffExpires(maraads_truth_buff) Spell(seal_of_truth)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&buff.liadrins_righteousness.down&!buff.avenging_wrath.up&!buff.bloodlust.up
	if Talent(empowered_seals_talent) and BuffExpires(liadrins_righteousness_buff) and not BuffPresent(avenging_wrath_melee_buff) and not BuffPresent(burst_haste_buff any=1) Spell(seal_of_righteousness)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up&(buff.avenging_wrath.up|target.health.pct<35)
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(divine_storm)
	#divine_storm,if=active_enemies=2&buff.final_verdict.up&(buff.avenging_wrath.up|target.health.pct<35)
	if Enemies() == 2 and BuffPresent(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(divine_storm)
	#final_verdict,if=buff.avenging_wrath.up|target.health.pct<35
	if BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 Spell(final_verdict)
	#templars_verdict,if=buff.avenging_wrath.up|target.health.pct<35&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*5)
	if BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 5 } Spell(templars_verdict)
	#crusader_strike,if=holy_power<5
	if HolyPower() < 5 Spell(crusader_strike)
	#divine_storm,if=buff.divine_crusader.react&(buff.avenging_wrath.up|target.health.pct<35)&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#judgment,cycle_targets=1,if=last_judgment_target!=target&glyph.double_jeopardy.enabled&holy_power<5
	if True(last_judgement_target) and Glyph(glyph_of_double_jeopardy) and HolyPower() < 5 Spell(judgment)
	#exorcism,if=glyph.mass_exorcism.enabled&active_enemies>=2&holy_power<5&!glyph.double_jeopardy.enabled
	if Glyph(glyph_of_mass_exorcism) and Enemies() >= 2 and HolyPower() < 5 and not Glyph(glyph_of_double_jeopardy) Spell(exorcism)
	#judgment,,if=holy_power<5
	if HolyPower() < 5 Spell(judgment)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=active_enemies=2&holy_power>=4&buff.final_verdict.up
	if Enemies() == 2 and HolyPower() >= 4 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(final_verdict)
	#final_verdict,if=holy_power>=4
	if HolyPower() >= 4 Spell(final_verdict)
	#divine_storm,if=buff.divine_crusader.react&active_enemies=2&holy_power>=4&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and Enemies() == 2 and HolyPower() >= 4 and not Talent(final_verdict_talent) Spell(divine_storm)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#divine_storm,if=buff.divine_crusader.react&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and not Talent(final_verdict_talent) Spell(divine_storm)
	#templars_verdict,if=holy_power>=4&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*5)
	if HolyPower() >= 4 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 5 } Spell(templars_verdict)
	#seal_of_truth,if=talent.empowered_seals.enabled&buff.maraads_truth.remains<cooldown.judgment.duration
	if Talent(empowered_seals_talent) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) Spell(seal_of_truth)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&buff.liadrins_righteousness.remains<cooldown.judgment.duration&!buff.bloodlust.up
	if Talent(empowered_seals_talent) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) and not BuffPresent(burst_haste_buff any=1) Spell(seal_of_righteousness)
	#exorcism,if=holy_power<5
	if HolyPower() < 5 Spell(exorcism)
	#divine_storm,if=active_enemies=2&holy_power>=3&buff.final_verdict.up
	if Enemies() == 2 and HolyPower() >= 3 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict,if=holy_power>=3
	if HolyPower() >= 3 Spell(final_verdict)
	#templars_verdict,if=holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>gcd*6)
	if HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > GCD() * 6 } Spell(templars_verdict)
	#holy_prism
	Spell(holy_prism)
}

### Retribution icons.
AddCheckBox(opt_paladin_retribution_aoe L(AOE) specialization=retribution default)

AddIcon specialization=retribution help=shortcd enemies=1 checkbox=!opt_paladin_retribution_aoe
{
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=shortcd checkbox=opt_paladin_retribution_aoe
{
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=main enemies=1
{
	if not InCombat() RetributionPrecombatMainActions()
	RetributionDefaultMainActions()
}

AddIcon specialization=retribution help=aoe checkbox=opt_paladin_retribution_aoe
{
	if not InCombat() RetributionPrecombatMainActions()
	RetributionDefaultMainActions()
}

AddIcon specialization=retribution help=cd enemies=1 checkbox=!opt_paladin_retribution_aoe
{
	if not InCombat() RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}

AddIcon specialization=retribution help=cd checkbox=opt_paladin_retribution_aoe
{
	if not InCombat() RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}

### Required symbols
# arcane_torrent_holy
# avenging_wrath_melee
# avenging_wrath_melee_buff
# berserking
# blazing_contempt_buff
# blessing_of_kings
# blessing_of_might
# blinding_light
# blood_fury_apsp
# crusader_strike
# divine_crusader_buff
# divine_purpose_buff
# divine_storm
# draenic_strength_potion
# empowered_seals_talent
# execution_sentence
# exorcism
# final_verdict
# final_verdict_buff
# final_verdict_talent
# fist_of_justice
# glyph_of_double_jeopardy
# glyph_of_mass_exorcism
# hammer_of_justice
# hammer_of_the_righteous
# hammer_of_wrath
# holy_avenger
# holy_avenger_buff
# holy_prism
# judgment
# liadrins_righteousness_buff
# lights_hammer
# maraads_truth_buff
# quaking_palm
# rebuke
# righteous_fury
# seal_of_righteousness
# seal_of_truth
# seraphim
# seraphim_talent
# speed_of_light
# templars_verdict
# war_stomp
]]
	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "reference")
end
