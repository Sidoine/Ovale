local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Holy_T17M_DMG"
	local desc = "[6.0] SimulationCraft: Priest_Holy_T17M_DMG"
	local code = [[
# Based on SimulationCraft profile "Priest_Holy_T17M_DMG".
#	class=priest
#	spec=holy
#	talents=3223232
#	glyphs=smite/holy_fire/inquisitor

Include(ovale_common)
Include(ovale_priest_spells)

AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		Spell(silence)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

AddFunction HolyDefaultActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 UsePotionIntellect()
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#power_infusion,if=talent.power_infusion.enabled
	if Talent(power_infusion_talent) Spell(power_infusion)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadow_word_pain,cycle_targets=1,max_cycle_targets=5,if=miss_react&!ticking
	if DebuffCountOnAny(shadow_word_pain_debuff) <= Enemies() and DebuffCountOnAny(shadow_word_pain_debuff) <= 5 and True(miss_react) and not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#power_word_solace
	Spell(power_word_solace)
	#mind_sear,if=active_enemies>=4
	if Enemies() >= 4 Spell(mind_sear)
	#holy_fire
	Spell(holy_fire)
	#smite
	Spell(smite)
	#holy_word,moving=1
	if Speed() > 0 Spell(holy_word)
	#shadow_word_pain,moving=1
	if Speed() > 0 Spell(shadow_word_pain)
}

AddFunction HolyPrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#chakra_chastise
	Spell(chakra_chastise)
	#snapshot_stats
	#potion,name=draenic_intellect
	UsePotionIntellect()
	#smite
	Spell(smite)
}

AddIcon specialization=holy help=main enemies=1
{
	if not InCombat() HolyPrecombatActions()
	HolyDefaultActions()
}

AddIcon specialization=holy help=aoe
{
	if not InCombat() HolyPrecombatActions()
	HolyDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# berserking
# blood_fury_sp
# chakra_chastise
# draenic_intellect_potion
# holy_fire
# holy_word
# mind_sear
# mindbender
# mindbender_talent
# power_infusion
# power_infusion_talent
# power_word_fortitude
# power_word_solace
# quaking_palm
# shadow_word_pain
# shadow_word_pain_debuff
# shadowfiend
# silence
# smite
# war_stomp
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "reference")
end
