local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_paladin_holy_t17m"
	local desc = "[6.0] SimulationCraft: Paladin_Holy_T17M"
	local code = [[
# Based on SimulationCraft profile "Paladin_Holy_T17M".
#	class=paladin
#	spec=holy
#	talents=2132232
#	glyphs=divinity/protector_of_the_innocent/

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default)
AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default)

AddFunction UsePotionMana
{
	if CheckBoxOn(opt_potion_mana) Item(draenic_mana_potion usable=1)
}

AddFunction InterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
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

AddFunction HolyDefaultMainActions
{
	#judgment,if=talent.selfless_healer.enabled&buff.selfless_healer.stack<3
	if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) < 3 Spell(judgment)
	#word_of_glory,if=holy_power>=3
	if HolyPower() >= 3 Spell(word_of_glory)
	#wait,if=target.health.pct>=75&mana.pct<=10
	unless target.HealthPercent() >= 75 and ManaPercent() <= 10
	{
		#holy_shock,if=holy_power<=3
		if HolyPower() <= 3 Spell(holy_shock)
		#flash_of_light,if=target.health.pct<=30
		if target.HealthPercent() <= 30 Spell(flash_of_light)
		#judgment,if=holy_power<3
		if HolyPower() < 3 Spell(judgment)
		#holy_light
		Spell(holy_light)
	}
}

AddFunction HolyDefaultShortCdActions
{
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
}

AddFunction HolyDefaultCdActions
{
	#mana_potion,if=mana.pct<=75
	if ManaPercent() <= 75 UsePotionMana()
	#auto_attack
	#rebuke
	InterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#avenging_wrath
	Spell(avenging_wrath_heal)
	#lay_on_hands,if=incoming_damage_5s>health.max*0.7
	if IncomingDamage(5) > MaxHealth() * 0.7 Spell(lay_on_hands)

	unless Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) < 3 and Spell(judgment) or HolyPower() >= 3 and Spell(word_of_glory)
	{
		#wait,if=target.health.pct>=75&mana.pct<=10
		unless target.HealthPercent() >= 75 and ManaPercent() <= 10
		{
			unless HolyPower() <= 3 and Spell(holy_shock) or target.HealthPercent() <= 30 and Spell(flash_of_light) or HolyPower() < 3 and Spell(judgment)
			{
				#lay_on_hands,if=mana.pct<5
				if ManaPercent() < 5 Spell(lay_on_hands)
			}
		}
	}
}

### actions.precombat

AddFunction HolyPrecombatMainActions
{
	#flask,type=greater_draenic_intellect_flask
	#food,type=blackrock_barbecue
	#blessing_of_kings,if=(!aura.str_agi_int.up)&(aura.mastery.up)
	if not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_insight
	Spell(seal_of_insight)
	#beacon_of_light,target=healing_target
	Spell(beacon_of_light text=healing_target)
}

### Holy icons.
AddCheckBox(opt_paladin_holy_aoe L(AOE) specialization=holy default)

AddIcon specialization=holy help=shortcd enemies=1 checkbox=!opt_paladin_holy_aoe
{
	HolyDefaultShortCdActions()
}

AddIcon specialization=holy help=shortcd checkbox=opt_paladin_holy_aoe
{
	HolyDefaultShortCdActions()
}

AddIcon specialization=holy help=main enemies=1
{
	if not InCombat() HolyPrecombatMainActions()
	HolyDefaultMainActions()
}

AddIcon specialization=holy help=aoe checkbox=opt_paladin_holy_aoe
{
	if not InCombat() HolyPrecombatMainActions()
	HolyDefaultMainActions()
}

AddIcon specialization=holy help=cd enemies=1 checkbox=!opt_paladin_holy_aoe
{
	HolyDefaultCdActions()
}

AddIcon specialization=holy help=cd checkbox=opt_paladin_holy_aoe
{
	HolyDefaultCdActions()
}

### Required symbols
# arcane_torrent_holy
# avenging_wrath_heal
# beacon_of_light
# berserking
# blessing_of_kings
# blessing_of_might
# blinding_light
# blood_fury_apsp
# draenic_mana_potion
# fist_of_justice
# flash_of_light
# hammer_of_justice
# holy_light
# holy_shock
# judgment
# lay_on_hands
# quaking_palm
# rebuke
# righteous_fury
# seal_of_insight
# selfless_healer_buff
# selfless_healer_talent
# speed_of_light
# war_stomp
# word_of_glory
]]
	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "reference")
end
