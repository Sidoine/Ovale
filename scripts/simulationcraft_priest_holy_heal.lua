local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Priest_Holy_T17M_Heal"
	local desc = "[6.0] SimulationCraft: Priest_Holy_T17M_Heal"
	local code = [[
# Based on SimulationCraft profile "Priest_Holy_T17M_Heal".
#	class=priest
#	spec=holy
#	talents=3223332
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

AddFunction HolyDefaultActions
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
	#lightwell
	Spell(lightwell)
	#power_word_solace,if=talent.power_word_solace.enabled
	if Talent(power_word_solace_talent) Spell(power_word_solace)
	#mindbender,if=talent.mindbender.enabled&mana.pct<80
	if Talent(mindbender_talent) and ManaPercent() < 80 Spell(mindbender)
	#shadowfiend,if=!talent.mindbender.enabled
	if not Talent(mindbender_talent) Spell(shadowfiend)
	#prayer_of_mending,if=buff.divine_insight.up
	if BuffPresent(divine_insight_buff) Spell(prayer_of_mending)
	#flash_heal,if=buff.surge_of_light.up
	if BuffPresent(surge_of_light_buff) Spell(flash_heal)
	#circle_of_healing
	Spell(circle_of_healing)
	#holy_word
	Spell(holy_word)
	#halo,if=talent.halo.enabled
	if Talent(halo_talent) Spell(halo_heal)
	#cascade,if=talent.cascade.enabled
	if Talent(cascade_talent) Spell(cascade_heal)
	#divine_star,if=talent.divine_star.enabled
	if Talent(divine_star_talent) Spell(divine_star_heal)
	#renew,if=!ticking
	if not BuffPresent(renew_buff) Spell(renew)
	#heal,if=buff.serendipity.react>=2&mana.pct>40
	if BuffStacks(serendipity_buff) >= 2 and ManaPercent() > 40 Spell(heal)
	#prayer_of_mending
	Spell(prayer_of_mending)
	#heal
	Spell(heal)
}

AddFunction HolyPrecombatActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=calamari_crepes
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#chakra_serenity
	Spell(chakra_serenity)
	#snapshot_stats
	#potion,name=draenic_intellect
	UsePotionIntellect()
	#prayer_of_mending
	Spell(prayer_of_mending)
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
# cascade_heal
# cascade_talent
# chakra_serenity
# circle_of_healing
# divine_insight_buff
# divine_star_heal
# divine_star_talent
# draenic_intellect_potion
# draenic_mana_potion
# flash_heal
# halo_heal
# halo_talent
# heal
# holy_word
# lightwell
# mindbender
# mindbender_talent
# power_infusion
# power_infusion_talent
# power_word_fortitude
# power_word_solace
# power_word_solace_talent
# prayer_of_mending
# quaking_palm
# renew
# renew_buff
# serendipity_buff
# shadowfiend
# silence
# surge_of_light_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "reference")
end
