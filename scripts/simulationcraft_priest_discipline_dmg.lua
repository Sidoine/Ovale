local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Discipline_T17M_Dmg"
	local desc = "[6.0] SimulationCraft: Priest_Discipline_T17M_Dmg"
	local code = [[
# Based on SimulationCraft profile "Priest_Discipline_T17M_Dmg".
#	class=priest
#	spec=discipline
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

AddFunction DisciplineDefaultActions
{
	#potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 UsePotionIntellect()
	#mindbender,if=talent.mindbender.enabled
	if Talent(mindbender_talent) Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#power_infusion,if=talent.power_infusion.enabled
	if Talent(power_infusion_talent) Spell(power_infusion)
	#shadow_word_pain,if=!ticking
	if not target.DebuffPresent(shadow_word_pain_debuff) Spell(shadow_word_pain)
	#penance
	Spell(penance)
	#power_word_solace,if=talent.power_word_solace.enabled
	if Talent(power_word_solace_talent) Spell(power_word_solace)
	#holy_fire,if=!talent.power_word_solace.enabled
	if not Talent(power_word_solace_talent) Spell(holy_fire)
	#smite,if=glyph.smite.enabled&(dot.power_word_solace.remains+dot.holy_fire.remains)>cast_time
	if Glyph(glyph_of_smite) and target.DebuffRemaining(power_word_solace_debuff) + target.DebuffRemaining(holy_fire_debuff) > CastTime(smite) Spell(smite)
	#shadow_word_pain,if=remains<(duration*0.3)
	if target.DebuffRemaining(shadow_word_pain_debuff) < BaseDuration(shadow_word_pain_debuff) * 0.3 Spell(shadow_word_pain)
	#smite
	Spell(smite)
	#shadow_word_pain
	Spell(shadow_word_pain)
}

AddFunction DisciplinePrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#snapshot_stats
	#potion,name=draenic_intellect
	UsePotionIntellect()
	#smite
	Spell(smite)
}

AddIcon specialization=discipline help=main enemies=1
{
	if not InCombat() DisciplinePrecombatActions()
	DisciplineDefaultActions()
}

AddIcon specialization=discipline help=aoe
{
	if not InCombat() DisciplinePrecombatActions()
	DisciplineDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# berserking
# blood_fury_sp
# draenic_intellect_potion
# glyph_of_smite
# holy_fire
# holy_fire_debuff
# mindbender
# mindbender_talent
# penance
# power_infusion
# power_infusion_talent
# power_word_fortitude
# power_word_solace
# power_word_solace_debuff
# power_word_solace_talent
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
