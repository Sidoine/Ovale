local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_priest_discipline_t17m_dmg"
	local desc = "[6.1] SimulationCraft: Priest_Discipline_T17M_Dmg"
	local code = [[
# Based on SimulationCraft profile "Priest_Discipline_T17M_Dmg".
#	class=priest
#	spec=discipline
#	talents=3223232
#	glyphs=smite/holy_fire/inquisitor

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=discipline)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=discipline)

AddFunction DisciplineUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction DisciplineInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
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

### actions.default

AddFunction DisciplineDefaultMainActions
{
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

AddFunction DisciplineDefaultCdActions
{
	#silence
	DisciplineInterruptActions()
	#potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 40 DisciplineUsePotionIntellect()
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
}

### actions.precombat

AddFunction DisciplinePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=salty_squid_roll
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#smite
	Spell(smite)
}

AddFunction DisciplinePrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		DisciplineUsePotionIntellect()
	}
}

AddFunction DisciplinePrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or Spell(smite)
}

### Discipline icons.

AddCheckBox(opt_priest_discipline_aoe L(AOE) default specialization=discipline)

AddIcon enemies=1 help=main specialization=discipline
{
	if not InCombat() DisciplinePrecombatMainActions()
	DisciplineDefaultMainActions()
}

AddIcon checkbox=opt_priest_discipline_aoe help=aoe specialization=discipline
{
	if not InCombat() DisciplinePrecombatMainActions()
	DisciplineDefaultMainActions()
}

AddIcon checkbox=!opt_priest_discipline_aoe enemies=1 help=cd specialization=discipline
{
	if not InCombat() DisciplinePrecombatCdActions()
	unless not InCombat() and DisciplinePrecombatCdPostConditions()
	{
		DisciplineDefaultCdActions()
	}
}

AddIcon checkbox=opt_priest_discipline_aoe help=cd specialization=discipline
{
	if not InCombat() DisciplinePrecombatCdActions()
	unless not InCombat() and DisciplinePrecombatCdPostConditions()
	{
		DisciplineDefaultCdActions()
	}
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
	OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
end
