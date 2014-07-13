local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Paladin_Retribution_T16H"
	local desc = "[5.4] SimulationCraft: Paladin_Retribution_T16H" 
	local code = [[
# Based on SimulationCraft profile "Paladin_Retribution_T16H".
#	class=paladin
#	spec=retribution
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bb!110112
#	glyphs=double_jeopardy/mass_exorcism

Include(ovale_common)
Include(ovale_paladin_common)

AddFunction RetributionDefaultActions
{
	#rebuke
	Interrupt()
	#mogu_power_potion,if=(buff.bloodlust.react|(buff.ancient_power.up&buff.avenging_wrath.up)|target.time_to_die<=40)
	if { BuffPresent(burst_haste any=1) or { BuffPresent(ancient_power_buff) and BuffPresent(avenging_wrath_buff) } or target.TimeToDie() <= 40 } UsePotionStrength()
	#auto_attack
	#inquisition,if=(buff.inquisition.down|buff.inquisition.remains<=2)&(holy_power>=3|target.time_to_die<holy_power*20|buff.divine_purpose.react)
	if { BuffExpires(inquisition_buff) or BuffRemains(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } Spell(inquisition)
	#avenging_wrath,if=buff.inquisition.up
	if BuffPresent(inquisition_buff) Spell(avenging_wrath)
	#guardian_of_ancient_kings,if=buff.inquisition.up
	if BuffPresent(inquisition_buff) Spell(guardian_of_ancient_kings_melee)
	#holy_avenger,if=talent.holy_avenger.enabled&(buff.inquisition.up&holy_power<=2)
	if TalentPoints(holy_avenger_talent) and { BuffPresent(inquisition_buff) and HolyPower() <= 2 } Spell(holy_avenger)
	#use_item,name=gauntlets_of_winged_triumph,if=buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12)
	if BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } UseItemActions()
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#execution_sentence,if=talent.execution_sentence.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
	if TalentPoints(execution_sentence_talent) and { BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } } Spell(execution_sentence)
	#lights_hammer,if=talent.lights_hammer.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
	if TalentPoints(lights_hammer_talent) and { BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } } Spell(lights_hammer)
	#divine_storm,if=active_enemies>=2&(holy_power=5|buff.divine_purpose.react|(buff.holy_avenger.up&holy_power>=3))
	if Enemies() >= 2 and { HolyPower() == 5 or BuffPresent(divine_purpose_buff) or { BuffPresent(holy_avenger_buff) and HolyPower() >= 3 } } Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemains(divine_purpose_buff) < 4 Spell(templars_verdict)
	#hammer_of_wrath
	Spell(hammer_of_wrath usable=1)
	#wait,sec=cooldown.hammer_of_wrath.remains,if=cooldown.hammer_of_wrath.remains>0&cooldown.hammer_of_wrath.remains<=0.2
	if SpellCooldown(hammer_of_wrath) > 0 and SpellCooldown(hammer_of_wrath) <= 0.2 wait Spell(hammer_of_wrath)
	#divine_storm,if=buff.divine_crusader.react&buff.avenging_wrath.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(avenging_wrath_buff) Spell(divine_storm)
	#templars_verdict,if=buff.avenging_wrath.up
	if BuffPresent(avenging_wrath_buff) Spell(templars_verdict)
	#hammer_of_the_righteous,if=active_enemies>=4
	if Enemies() >= 4 Spell(hammer_of_the_righteous)
	#crusader_strike
	Spell(crusader_strike)
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.2
	if SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.2 wait Spell(crusader_strike)
	#exorcism,if=active_enemies>=2&active_enemies<=4&set_bonus.tier15_2pc_melee&glyph.mass_exorcism.enabled
	if Enemies() >= 2 and Enemies() <= 4 and ArmorSetBonus(T15_melee 2) and Glyph(glyph_of_mass_exorcism) Spell(exorcism)
	#judgment
	Spell(judgment)
	#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.2
	if SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.2 wait Spell(judgment)
	#divine_storm,if=buff.divine_crusader.react
	if BuffPresent(divine_crusader_buff) Spell(divine_storm)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#exorcism
	Spell(exorcism)
	#wait,sec=cooldown.exorcism.remains,if=cooldown.exorcism.remains>0&cooldown.exorcism.remains<=0.2
	if SpellCooldown(exorcism) > 0 and SpellCooldown(exorcism) <= 0.2 wait Spell(exorcism)
	#templars_verdict,if=buff.tier15_4pc_melee.up&active_enemies<4
	if BuffPresent(tier15_4pc_melee_buff) and Enemies() < 4 Spell(templars_verdict)
	#divine_storm,if=active_enemies>=2&buff.inquisition.remains>4
	if Enemies() >= 2 and BuffRemains(inquisition_buff) > 4 Spell(divine_storm)
	#templars_verdict,if=buff.inquisition.remains>4
	if BuffRemains(inquisition_buff) > 4 Spell(templars_verdict)
	#holy_prism,if=talent.holy_prism.enabled
	if TalentPoints(holy_prism_talent) Spell(holy_prism)
}

AddFunction RetributionPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#blessing_of_kings,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int any=1) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery any=1) Spell(blessing_of_might)
	#seal_of_truth,if=active_enemies<4
	if Enemies() < 4 if not Stance(paladin_seal_of_truth) Spell(seal_of_truth)
	#seal_of_righteousness,if=active_enemies>=4
	if Enemies() >= 4 if not Stance(paladin_seal_of_righteousness) Spell(seal_of_righteousness)
	#snapshot_stats
	#mogu_power_potion
	UsePotionStrength()
}

AddIcon mastery=retribution help=main
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultActions()
}

### Required symbols
# ancient_power_buff
# arcane_torrent_mana
# avenging_wrath
# avenging_wrath_buff
# berserking
# blessing_of_kings
# blessing_of_might
# blood_fury
# crusader_strike
# divine_crusader_buff
# divine_purpose_buff
# divine_storm
# execution_sentence
# execution_sentence_talent
# exorcism
# glyph_of_mass_exorcism
# guardian_of_ancient_kings_melee
# hammer_of_the_righteous
# hammer_of_wrath
# holy_avenger
# holy_avenger_buff
# holy_avenger_talent
# holy_prism
# holy_prism_talent
# inquisition
# inquisition_buff
# judgment
# lights_hammer
# lights_hammer_talent
# mastery
# mogu_power_potion
# rebuke
# seal_of_righteousness
# seal_of_truth
# str_agi_int
# templars_verdict
# tier15_4pc_melee_buff
]]
	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "reference")
end
