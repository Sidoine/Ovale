local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Discipline_T17M_Heal"
	local desc = "[6.0] SimulationCraft: Priest_Discipline_T17M_Heal"
	local code = [[
# Based on SimulationCraft profile "Priest_Discipline_T17M_Heal".
#	class=priest
#	spec=discipline
#	talents=3223232
#	glyphs=prayer_of_mending/circle_of_healing/deep_wells

Include(ovale_common)
Include(ovale_priest_spells)

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
	#power_word_solace,if=talent.power_word_solace.enabled
	if Talent(power_word_solace_talent) Spell(power_word_solace)
	#mindbender,if=talent.mindbender.enabled&mana.pct<80
	if Talent(mindbender_talent) and ManaPercent() < 80 Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
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

AddFunction DisciplinePrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#snapshot_stats
	#potion,name=draenic_intellect
	UsePotionIntellect()
	#prayer_of_mending
	Spell(prayer_of_mending)
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
