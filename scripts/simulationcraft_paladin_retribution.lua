local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Paladin_Retribution_T16M"
	local desc = "[6.0] SimulationCraft: Paladin_Retribution_T16M"
	local code = [[
# Based on SimulationCraft profile "Paladin_Retribution_T16M".
#	class=paladin
#	spec=retribution
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bb!110112.
#	glyphs=double_jeopardy/mass_exorcism

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction Exorcism
{
	Spell(exorcism)
	Spell(exorcism_glyphed)
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

AddFunction RetributionPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#blessing_of_kings,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_truth,if=active_enemies<2
	if Enemies() < 2 Spell(seal_of_truth)
	#seal_of_righteousness,if=active_enemies>=2
	if Enemies() >= 2 Spell(seal_of_righteousness)
	#snapshot_stats
	#potion,name=mogu_power
	UsePotionStrength()
}

AddFunction RetributionDefaultActions
{
	#rebuke
	InterruptActions()
	#potion,name=mogu_power,if=(buff.bloodlust.react|buff.avenging_wrath.up|target.time_to_die<=40)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_melee_buff) or target.TimeToDie() <= 40 UsePotionStrength()
	#auto_attack
	#speed_of_light,if=movement.distance>5
	if 0 > 5 Spell(speed_of_light)
	#execution_sentence
	Spell(execution_sentence)
	#lights_hammer
	Spell(lights_hammer)
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
	#seraphim
	Spell(seraphim)
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 RetributionAoeActions()
	#call_action_list,name=cleave,if=active_enemies>=3
	if Enemies() >= 3 RetributionCleaveActions()
	#call_action_list,name=single
	RetributionSingleActions()
}

AddFunction RetributionAoeActions
{
	#divine_storm,if=holy_power=5&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() == 5 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(divine_storm)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Exorcism()
	#hammer_of_the_righteous
	Spell(hammer_of_the_righteous)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<=5
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= 5 Spell(judgment)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#divine_storm,if=(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 Spell(divine_storm)
	#exorcism,if=glyph.mass_exorcism.enabled
	if Glyph(glyph_of_mass_exorcism) Exorcism()
	#judgment
	Spell(judgment)
	#exorcism
	Exorcism()
	#holy_prism
	Spell(holy_prism)
}

AddFunction RetributionSingleActions
{
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&active_enemies=2&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Enemies() == 2 and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power=5&active_enemies=2&buff.final_verdict.up
	if HolyPower() == 5 and Enemies() == 2 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&(talent.seraphim.enabled&cooldown.seraphim.remains<=4)
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Talent(seraphim_talent) and SpellCooldown(seraphim) <= 4 Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 4 Spell(templars_verdict)
	#final_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(final_verdict)
	#final_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 4 Spell(final_verdict)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#judgment,if=talent.empowered_seals.enabled&((seal.truth&buff.maraads_truth.remains<cooldown.judgment.duration*2)|(seal.righteousness&buff.liadrins_righteousness.remains<cooldown.judgment.duration*2))
	if Talent(empowered_seals_talent) and { Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) * 2 or Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) * 2 } Spell(judgment)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Exorcism()
	#seal_of_truth,if=talent.empowered_seals.enabled&buff.maraads_truth.remains<(cooldown.judgment.duration)&buff.maraads_truth.remains<=3
	if Talent(empowered_seals_talent) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) and BuffRemaining(maraads_truth_buff) <= 3 Spell(seal_of_truth)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(final_verdict)
	#templars_verdict,if=(buff.avenging_wrath.up|talent.divine_purpose.enabled)&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if { BuffPresent(avenging_wrath_melee_buff) or Talent(divine_purpose_talent) } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#divine_storm,if=talent.divine_purpose.enabled&buff.divine_crusader.react&!talent.final_verdict.enabled
	if Talent(divine_purpose_talent) and BuffPresent(divine_crusader_buff) and not Talent(final_verdict_talent) Spell(divine_storm)
	#crusader_strike
	Spell(crusader_strike)
	#final_verdict
	Spell(final_verdict)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&buff.liadrins_righteousness.remains<(cooldown.judgment.duration)&buff.liadrins_righteousness.remains<=3
	if Talent(empowered_seals_talent) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) and BuffRemaining(liadrins_righteousness_buff) <= 3 Spell(seal_of_righteousness)
	#judgment
	Spell(judgment)
	#divine_storm,if=buff.divine_crusader.react&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and not Talent(final_verdict_talent) Spell(divine_storm)
	#templars_verdict,if=holy_power>=4&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() >= 4 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#exorcism
	Exorcism()
	#templars_verdict,if=holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#holy_prism
	Spell(holy_prism)
}

AddFunction RetributionCleaveActions
{
	#final_verdict,if=buff.final_verdict.down&holy_power=5
	if BuffExpires(final_verdict_buff) and HolyPower() == 5 Spell(final_verdict)
	#divine_storm,if=holy_power=5&buff.final_verdict.up
	if HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=holy_power=5&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)&!talent.final_verdict.enabled
	if HolyPower() == 5 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Exorcism()
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<=5
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= 5 Spell(judgment)
	#divine_storm,if=(!talent.seraphim.enabled|cooldown.seraphim.remains>4)&!talent.final_verdict.enabled
	if { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#crusader_strike
	Spell(crusader_strike)
	#divine_storm,if=buff.final_verdict.up
	if BuffPresent(final_verdict_buff) Spell(divine_storm)
	#judgment
	Spell(judgment)
	#exorcism
	Exorcism()
	#holy_prism
	Spell(holy_prism)
}

AddIcon specialization=retribution help=main enemies=1
{
	if not InCombat() RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon specialization=retribution help=aoe
{
	if not InCombat() RetributionPrecombatActions()
	RetributionDefaultActions()
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
# divine_purpose_talent
# divine_storm
# empowered_seals_talent
# execution_sentence
# exorcism
# exorcism_glyphed
# final_verdict
# final_verdict_buff
# final_verdict_talent
# fist_of_justice
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
# mogu_power_potion
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
