local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_priest_discipline_t17m_heal"
	local desc = "[6.0] SimulationCraft: Priest_Discipline_T17M_Heal"
	local code = [[
# Based on SimulationCraft profile "Priest_Discipline_T17M_Heal".
#	class=priest
#	spec=discipline
#	talents=3223232
#	glyphs=prayer_of_mending/circle_of_healing/deep_wells

Include(ovale_common)
Include(ovale_priest_spells)

AddCheckBox(opt_interrupt L(interrupt) default)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default)
AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction UsePotionMana
{
	if CheckBoxOn(opt_potion_mana) Item(draenic_mana_potion usable=1)
}

AddFunction InterruptActions
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
	#power_word_solace,if=talent.power_word_solace.enabled
	if Talent(power_word_solace_talent) Spell(power_word_solace)
	#power_word_shield
	Spell(power_word_shield)
	#penance_heal,if=buff.borrowed_time.up
	if BuffPresent(borrowed_time_buff) Spell(penance_heal)
	#penance_heal
	Spell(penance_heal)
	#flash_heal,if=buff.surge_of_light.react
	if BuffPresent(surge_of_light_buff) Spell(flash_heal)
	#heal,if=buff.power_infusion.up|mana.pct>20
	if BuffPresent(power_infusion_buff) or ManaPercent() > 20 Spell(heal)
	#prayer_of_mending
	Spell(prayer_of_mending)
	#heal
	Spell(heal)
}

AddFunction DisciplineDefaultCdActions
{
	#silence
	InterruptActions()
	#mana_potion,if=mana.pct<=75
	if ManaPercent() <= 75 UsePotionMana()
	#blood_fury
	Spell(blood_fury_sp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#power_infusion,if=talent.power_infusion.enabled
	if Talent(power_infusion_talent) Spell(power_infusion)

	unless Talent(power_word_solace_talent) and Spell(power_word_solace)
	{
		#mindbender,if=talent.mindbender.enabled&mana.pct<80
		if Talent(mindbender_talent) and ManaPercent() < 80 Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

### actions.precombat

AddFunction DisciplinePrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#prayer_of_mending
	Spell(prayer_of_mending)
}

AddFunction DisciplinePrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		UsePotionIntellect()
	}
}

### Discipline icons.

AddCheckBox(opt_priest_discipline_aoe L(AOE) default specialization=discipline)

AddIcon checkbox=!opt_priest_discipline_aoe enemies=1 help=shortcd specialization=discipline
{
}

AddIcon checkbox=opt_priest_discipline_aoe help=shortcd specialization=discipline
{
}

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
	DisciplineDefaultCdActions()
}

AddIcon checkbox=opt_priest_discipline_aoe help=cd specialization=discipline
{
	if not InCombat() DisciplinePrecombatCdActions()
	DisciplineDefaultCdActions()
}

### Required symbols
# arcane_torrent_mana
# berserking
# blood_fury_sp
# borrowed_time_buff
# draenic_intellect_potion
# draenic_mana_potion
# flash_heal
# heal
# mindbender
# mindbender_talent
# penance_heal
# power_infusion
# power_infusion_buff
# power_infusion_talent
# power_word_fortitude
# power_word_shield
# power_word_solace
# power_word_solace_talent
# prayer_of_mending
# quaking_palm
# shadowfiend
# silence
# surge_of_light_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "reference")
end
