local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_priest_holy_t17m_heal"
	local desc = "[6.1] SimulationCraft: Priest_Holy_T17M_Heal"
	local code = [[
# Based on SimulationCraft profile "Priest_Holy_T17M_Heal".
#	class=priest
#	spec=holy
#	talents=3223332
#	glyphs=prayer_of_mending/circle_of_healing/deep_wells

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_priest_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=holy)
AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default specialization=holy)
AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default specialization=holy)

AddFunction HolyUsePotionIntellect
{
	if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
}

AddFunction HolyUsePotionMana
{
	if CheckBoxOn(opt_potion_mana) Item(draenic_mana_potion usable=1)
}

AddFunction HolyInterruptActions
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

AddFunction HolyDefaultMainActions
{
	#power_word_solace,if=talent.power_word_solace.enabled
	if Talent(power_word_solace_talent) Spell(power_word_solace)
	#prayer_of_mending,if=buff.divine_insight.up
	if BuffPresent(divine_insight_buff) Spell(prayer_of_mending)
	#flash_heal,if=buff.surge_of_light.up
	if BuffPresent(surge_of_light_buff) Spell(flash_heal)
	#circle_of_healing
	Spell(circle_of_healing)
	#renew,if=!ticking
	if not BuffPresent(renew_buff) Spell(renew)
	#heal,if=buff.serendipity.react>=2&mana.pct>40
	if BuffStacks(serendipity_buff) >= 2 and ManaPercent() > 40 Spell(heal)
	#prayer_of_mending
	Spell(prayer_of_mending)
	#heal
	Spell(heal)
}

AddFunction HolyDefaultShortCdActions
{
	unless Talent(power_word_solace_talent) and Spell(power_word_solace) or BuffPresent(divine_insight_buff) and Spell(prayer_of_mending) or BuffPresent(surge_of_light_buff) and Spell(flash_heal) or Spell(circle_of_healing)
	{
		#holy_word
		Spell(holy_word)
		#halo,if=talent.halo.enabled
		if Talent(halo_talent) Spell(halo_heal)
		#cascade,if=talent.cascade.enabled
		if Talent(cascade_talent) Spell(cascade_heal)
		#divine_star,if=talent.divine_star.enabled
		if Talent(divine_star_talent) Spell(divine_star_heal)
	}
}

AddFunction HolyDefaultCdActions
{
	#silence
	HolyInterruptActions()
	#mana_potion,if=mana.pct<=75
	if ManaPercent() <= 75 HolyUsePotionMana()
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

	unless Talent(power_word_solace_talent) and Spell(power_word_solace)
	{
		#mindbender,if=talent.mindbender.enabled&mana.pct<80
		if Talent(mindbender_talent) and ManaPercent() < 80 Spell(mindbender)
		#shadowfiend,if=!talent.mindbender.enabled
		if not Talent(mindbender_talent) Spell(shadowfiend)
	}
}

### actions.precombat

AddFunction HolyPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=salty_squid_roll
	#power_word_fortitude,if=!aura.stamina.up
	if not BuffPresent(stamina_buff any=1) Spell(power_word_fortitude)
	#prayer_of_mending
	Spell(prayer_of_mending)
}

AddFunction HolyPrecombatShortCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude)
	{
		#chakra_serenity
		Spell(chakra_serenity)
	}
}

AddFunction HolyPrecombatShortCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or Spell(prayer_of_mending)
}

AddFunction HolyPrecombatCdActions
{
	unless not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or Spell(chakra_serenity)
	{
		#snapshot_stats
		#potion,name=draenic_intellect
		HolyUsePotionIntellect()
	}
}

AddFunction HolyPrecombatCdPostConditions
{
	not BuffPresent(stamina_buff any=1) and Spell(power_word_fortitude) or Spell(chakra_serenity) or Spell(prayer_of_mending)
}

### Holy icons.

AddCheckBox(opt_priest_holy_aoe L(AOE) default specialization=holy)

AddIcon checkbox=!opt_priest_holy_aoe enemies=1 help=shortcd specialization=holy
{
	if not InCombat() HolyPrecombatShortCdActions()
	unless not InCombat() and HolyPrecombatShortCdPostConditions()
	{
		HolyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_priest_holy_aoe help=shortcd specialization=holy
{
	if not InCombat() HolyPrecombatShortCdActions()
	unless not InCombat() and HolyPrecombatShortCdPostConditions()
	{
		HolyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=holy
{
	if not InCombat() HolyPrecombatMainActions()
	HolyDefaultMainActions()
}

AddIcon checkbox=opt_priest_holy_aoe help=aoe specialization=holy
{
	if not InCombat() HolyPrecombatMainActions()
	HolyDefaultMainActions()
}

AddIcon checkbox=!opt_priest_holy_aoe enemies=1 help=cd specialization=holy
{
	if not InCombat() HolyPrecombatCdActions()
	unless not InCombat() and HolyPrecombatCdPostConditions()
	{
		HolyDefaultCdActions()
	}
}

AddIcon checkbox=opt_priest_holy_aoe help=cd specialization=holy
{
	if not InCombat() HolyPrecombatCdActions()
	unless not InCombat() and HolyPrecombatCdPostConditions()
	{
		HolyDefaultCdActions()
	}
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
	OvaleScripts:RegisterScript("PRIEST", "holy", name, desc, code, "script")
end
