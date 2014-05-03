local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Holy, Protection, Retribution"
	local code = [[
# Ovale paladin script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_paladin_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Holy
###
# Rotation from Icy Veins, "Holy Paladin Healing Guide (WoW MoP 5.4)"
#	http://www.icy-veins.com/holy-paladin-wow-pve-healing-guide

AddFunction HolySingleTargetActions
{
	if BuffCount(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if TalentPoints(sacred_shield_talent) and BuffCount(sacred_shield_holy_buff) == 0 Spell(sacred_shield_holy)
	if HolyPower() == MaxHolyPower()
	{
		if TalentPoints(eternal_flame_talent) Spell(eternal_flame)
		Spell(word_of_glory)
	}
	if target.IsFriend(no) and target.InRange(crusader_strike) Spell(crusader_strike)
	Spell(holy_shock)
	Spell(divine_light)
}

AddFunction HolyAoeActions
{
	if BuffCount(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if TalentPoints(sacred_shield_talent) and BuffCount(sacred_shield_holy_buff) == 0 Spell(sacred_shield_holy)
	if HolyPower() == MaxHolyPower()
	{
		if TalentPoints(eternal_flame_talent) Spell(eternal_flame)
		Spell(light_of_dawn)
	}
	if target.IsFriend(no) and target.InRange(crusader_strike) Spell(crusader_strike)
	Spell(holy_shock)
	Spell(holy_radiance)
}

AddFunction HolySelflessHealerAoeActions()
{
	if BuffCount(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if HolyPower() == MaxHolyPower() Spell(light_of_dawn)
	if target.IsFriend(no) and target.InRange(judgment) Spell(judgment)
	if BuffPresent(selfless_healer_buff) Spell(holy_radiance)
	Spell(holy_shock)
}

AddFunction HolyPrecombatActions
{
	if not BuffPresent(str_agi_int any=1) Spell(blessing_of_kings)
	if not BuffPresent(mastery any=1) and not BuffPresent(str_agi_int) Spell(blessing_of_might)
	if not Stance(paladin_seal_of_insight) Spell(seal_of_insight)
}

### Holy Icons

# Damage reduction cooldowns.
AddIcon mastery=1 help=cd size=small checkboxon=opt_icons_left
{
	Spell(divine_protection)
	Spell(devotion_aura)
	UseRacialSurvivalActions()
}

AddIcon mastery=1 help=cd size=small checkboxon=opt_icons_left
{
	if ManaPercent() <98 Spell(arcane_torrent_mana)
	if ManaPercent() <88 Spell(divine_plea)
	# Show "dash" icon if not in melee range.
	if target.IsFriend(no) and not target.InRange(crusader_strike) Texture(ability_druid_dash)
}

AddIcon mastery=1 help=shortcd
{
	if TalentPoints(holy_prism_talent) Spell(holy_prism)
	if TalentPoints(lights_hammer_talent) Spell(lights_hammer)
	if TalentPoints(execution_sentence_talent) Spell(execution_sentence)
}

AddIcon mastery=1 help=main
{
	HolyPrecombatActions()
	HolySingleTargetActions()
}

AddIcon mastery=1 help=aoe checkboxon=opt_aoe
{
	HolyPrecombatActions()
	if TalentPoints(selfless_healer_talent) HolySelflessHealerAoeActions()
	if not TalentPoints(selfless_healer_talent) HolyAoeActions()
}

AddIcon mastery=1 help=cd
{
	Interrupt()
	if IsRooted() Spell(hand_of_freedom)
	if TalentPoints(holy_avenger_talent) Spell(holy_avenger)
	Spell(avenging_wrath)
	Spell(divine_favor)
	Spell(guardian_of_ancient_kings_heal)
}

AddIcon mastery=1 help=cd size=small checkboxon=opt_icons_right
{
	if BuffPresent(righteous_fury) Texture(spell_holy_sealoffury)
}

AddIcon mastery=1 help=cd size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Protection
###
# Based on SimulationCraft profile "Paladin_Protection_T16H".
#	class=paladin
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bZ!201121
#	glyphs=focused_shield/alabaster_shield/divine_protection

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#judgment,if=talent.sanctified_wrath.enabled&buff.avenging_wrath.react
	#wait,sec=cooldown.judgment.remains,if=talent.sanctified_wrath.enabled&cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5
	if TalentPoints(sanctified_wrath_talent) and BuffPresent(avenging_wrath_buff) Spell(judgment wait=0.5)
	#crusader_strike
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.5
	Spell(crusader_strike wait=0.5)
	#judgment
	#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5&(cooldown.crusader_strike.remains-cooldown.judgment.remains)>=0.5
	Spell(judgment wait=0.5)
	#avengers_shield
	Spell(avengers_shield)
	#sacred_shield,if=talent.sacred_shield.enabled&target.dot.sacred_shield.remains<5
	if TalentPoints(sacred_shield_talent) and target.BuffRemains(sacred_shield_buff) < 5 Spell(sacred_shield)
	#holy_wrath
	Spell(holy_wrath)
	#hammer_of_wrath
	Spell(hammer_of_wrath usable=1)
	#holy_prism,if=talent.holy_prism.enabled
	if TalentPoints(holy_prism_talent) Spell(holy_prism)
	#sacred_shield,if=talent.sacred_shield.enabled
	if TalentPoints(sacred_shield_talent) Spell(sacred_shield)
}

AddFunction ProtectionDefaultShortCdActions
{
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react))
	if TalentPoints(eternal_flame_talent) and { BuffRemains(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } } Spell(eternal_flame)
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.bastion_of_power.react&buff.bastion_of_glory.react>=5)
	if TalentPoints(eternal_flame_talent) and { BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 } Spell(eternal_flame)
	#shield_of_the_righteous,if=holy_power>=5|buff.divine_purpose.react|incoming_damage_1500ms>=health.max*0.3
	if HolyPower() >= MaxHolyPower() or BuffPresent(divine_purpose_buff) or IncomingDamage(1.500) >= MaxHealth() * 0.3 Spell(shield_of_the_righteous)

	unless { TalentPoints(sanctified_wrath_talent) and BuffPresent(avenging_wrath_buff) and Spell(judgment) }
		or Spell(crusader_strike)
		or Spell(judgment)
		or Spell(avengers_shield)
		or { TalentPoints(sacred_shield_talent) and target.BuffRemains(sacred_shield_buff) < 5 and Spell(sacred_shield) }
		or Spell(holy_wrath)
	{
		#execution_sentence,if=talent.execution_sentence.enabled
		if TalentPoints(execution_sentence_talent) Spell(execution_sentence)
		#lights_hammer,if=talent.lights_hammer.enabled
		if TalentPoints(lights_hammer_talent) Spell(lights_hammer)

		unless Spell(hammer_of_wrath usable=1)
		{
			#consecration,if=target.debuff.flying.down&!ticking
			if target.True(not flying_debuff) and not target.DebuffPresent(consecration_debuff)
			{
				if Glyph(glyph_of_consecration) Spell(consecration_glyphed)
				if Glyph(glyph_of_consecration no) Spell(consecration)
			}
		}
	}
}

AddFunction ProtectionDefaultCdActions
{
	Interrupt()
	UseRacialInterruptActions()
	if IsRooted() Spell(hand_of_freedom)

	#blood_fury
	#avenging_wrath
	Spell(avenging_wrath)
	#holy_avenger,if=talent.holy_avenger.enabled
	if TalentPoints(holy_avenger_talent) Spell(holy_avenger)
}

AddFunction ProtectionPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#blessing_of_kings,if=(!aura.str_agi_int.up)&(aura.mastery.up)
	if not BuffPresent(str_agi_int any=1) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery any=1) and not BuffPresent(str_agi_int) Spell(blessing_of_might)
	#seal_of_insight
	if not Stance(paladin_seal_of_insight) Spell(seal_of_insight)
	#sacred_shield,if=talent.sacred_shield.enabled
	if TalentPoints(sacred_shield_talent) Spell(sacred_shield)
	#snapshot_stats
}

### Protection Icons

AddIcon mastery=protection help=cd size=small checkboxon=opt_icons_left
{
	Spell(divine_protection)
	Spell(ardent_defender)
	Spell(guardian_of_ancient_kings_tank)
	Spell(devotion_aura)
	UseRacialSurvivalActions()
}

AddIcon mastery=protection help=cd size=small checkboxon=opt_icons_left
{
	if DebuffExpires(forbearance_debuff)
	{
		Spell(lay_on_hands)
		Spell(hand_of_protection)
		Spell(divine_shield)
	}
}

AddIcon mastery=protection help=shortcd
{
	if BuffExpires(righteous_fury) Spell(righteous_fury)
	ProtectionDefaultShortCdActions()
}

AddIcon mastery=protection help=main
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon mastery=protection help=opt_aoe
{
	if InCombat(no) ProtectionPrecombatActions()

	# HotR > AS > Cons > J > HW
	Spell(hammer_of_the_righteous)
	Spell(judgment)
	Spell(avengers_shield)
	if Glyph(glyph_of_consecration) Spell(consecration_glyphed)
	if Glyph(glyph_of_consecration no) Spell(consecration)
	Spell(judgment)
	Spell(holy_wrath)
}

AddIcon mastery=protection help=cd
{
	Interrupt()
	if IsRooted() Spell(hand_of_freedom)
	ProtectionDefaultCdActions()
}

# Righteous Fury indicator.
AddIcon mastery=protection help=cd size=small checkboxon=opt_icons_right
{
	if BuffPresent(righteous_fury) Texture(spell_holy_sealoffury)
}

AddIcon mastery=protection help=cd size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Retribution
###
# Based on SimulationCraft profile "Paladin_Retribution_T16H".
#	class=paladin
#	spec=retribution
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bb!110112
#	glyphs=double_jeopardy/mass_exorcism

AddFunction RetributionDefaultActions
{
	#auto_attack
	#inquisition,if=(buff.inquisition.down|buff.inquisition.remains<=2)&(holy_power>=3|target.time_to_die<holy_power*20|buff.divine_purpose.react)
	if { BuffExpires(inquisition_buff) or BuffRemains(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } Spell(inquisition)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5
	if BuffPresent(divine_crusader_buff) and HolyPower() == MaxHolyPower() Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == MaxHolyPower() or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemains(divine_purpose_buff) < 4 Spell(templars_verdict)
	#hammer_of_wrath
	#wait,sec=cooldown.hammer_of_wrath.remains,if=cooldown.hammer_of_wrath.remains>0&cooldown.hammer_of_wrath.remains<=0.2
	Spell(hammer_of_wrath usable=1 wait=0.2)
	#divine_storm,if=buff.divine_crusader.react&buff.avenging_wrath.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(avenging_wrath_buff) Spell(divine_storm)
	#templars_verdict,if=buff.avenging_wrath.up
	if BuffPresent(avenging_wrath_buff) Spell(templars_verdict)
	#crusader_strike
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.2
	Spell(crusader_strike wait=0.2)
	#judgment
	#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.2
	Spell(judgment wait=0.2)
	#divine_storm,if=buff.divine_crusader.react
	if BuffPresent(divine_crusader_buff) Spell(divine_storm)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#exorcism
	#wait,sec=cooldown.exorcism.remains,if=cooldown.exorcism.remains>0&cooldown.exorcism.remains<=0.2
	if Glyph(glyph_of_mass_exorcism no) Spell(exorcism wait=0.2)
	if Glyph(glyph_of_mass_exorcism) Spell(exorcism_glyphed wait=0.2)
	#templars_verdict,if=buff.tier15_4pc_melee.up&active_enemies<4
	if BuffPresent(tier15_4pc_melee_buff) Spell(templars_verdict)
	#templars_verdict,if=buff.inquisition.remains>4
	if BuffRemains(inquisition_buff) > 4 Spell(templars_verdict)
	#holy_prism,if=talent.holy_prism.enabled
	if TalentPoints(holy_prism_talent) Spell(holy_prism)
}

AddFunction RetributionDefaultAoeActions
{
	#auto_attack
	#inquisition,if=(buff.inquisition.down|buff.inquisition.remains<=2)&(holy_power>=3|target.time_to_die<holy_power*20|buff.divine_purpose.react)
	if { BuffExpires(inquisition_buff) or BuffRemains(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } Spell(inquisition)
	#divine_storm,if=active_enemies>=2&(holy_power=5|buff.divine_purpose.react|(buff.holy_avenger.up&holy_power>=3))
	if HolyPower() == MaxHolyPower() or BuffPresent(divine_purpose_buff) or { BuffPresent(holy_avenger_buff) and HolyPower() >= 3 } Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5
	if BuffPresent(divine_crusader_buff) and HolyPower() == MaxHolyPower() Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == MaxHolyPower() or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemains(divine_purpose_buff) < 4 Spell(templars_verdict)
	#hammer_of_wrath
	#wait,sec=cooldown.hammer_of_wrath.remains,if=cooldown.hammer_of_wrath.remains>0&cooldown.hammer_of_wrath.remains<=0.2
	Spell(hammer_of_wrath usable=1 wait=0.2)
	#divine_storm,if=buff.divine_crusader.react&buff.avenging_wrath.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(avenging_wrath_buff) Spell(divine_storm)
	#templars_verdict,if=buff.avenging_wrath.up
	if BuffPresent(avenging_wrath_buff) Spell(templars_verdict)
	#hammer_of_the_righteous,if=active_enemies>=4
	Spell(hammer_of_the_righteous)
	#exorcism,if=active_enemies>=2&active_enemies<=4&set_bonus.tier15_2pc_melee&glyph.mass_exorcism.enabled
	if ArmorSetBonus(T15_melee 2) and Glyph(glyph_of_mass_exorcism) Spell(exorcism_glyphed)
	#judgment
	#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.2
	Spell(judgment wait=0.2)
	#divine_storm,if=buff.divine_crusader.react
	if BuffPresent(divine_crusader_buff) Spell(divine_storm)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#exorcism
	#wait,sec=cooldown.exorcism.remains,if=cooldown.exorcism.remains>0&cooldown.exorcism.remains<=0.2
	if Glyph(glyph_of_mass_exorcism no) Spell(exorcism wait=0.2)
	if Glyph(glyph_of_mass_exorcism) Spell(exorcism_glyphed wait=0.2)
	#divine_storm,if=active_enemies>=2&buff.inquisition.remains>4
	if BuffRemains(inquisition_buff) > 4 Spell(divine_storm)
	#holy_prism,if=talent.holy_prism.enabled
	if TalentPoints(holy_prism_talent) Spell(holy_prism)
}

AddFunction RetributionDefaultShortCdActions
{
	unless { BuffExpires(inquisition_buff) or BuffRemains(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) }
	{
		#avenging_wrath,if=buff.inquisition.up
		if BuffPresent(inquisition_buff) Spell(avenging_wrath)
		#execution_sentence,if=talent.execution_sentence.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
		if TalentPoints(execution_sentence_talent) and { BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } } Spell(execution_sentence)
		#lights_hammer,if=talent.lights_hammer.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
		if TalentPoints(lights_hammer_talent) and { BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } } Spell(lights_hammer)
	}
}

AddFunction RetributionDefaultCdActions
{
	#rebuke
	Interrupt()
	#mogu_power_potion,if=(buff.bloodlust.react|(buff.ancient_power.up&buff.avenging_wrath.up)|target.time_to_die<=40)
	if { BuffPresent(burst_haste any=1) or { BuffPresent(ancient_power_buff) and BuffPresent(avenging_wrath_buff) } or target.TimeToDie() <= 40 } UsePotionStrength()

	unless { BuffExpires(inquisition_buff) or BuffRemains(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) }
	{
		#guardian_of_ancient_kings,if=buff.inquisition.up
		if BuffPresent(inquisition_buff) Spell(guardian_of_ancient_kings_melee)
		#holy_avenger,if=talent.holy_avenger.enabled&(buff.inquisition.up&holy_power<=2)
		if TalentPoints(holy_avenger_talent) and { BuffPresent(inquisition_buff) and HolyPower() <= 2 } Spell(holy_avenger)
		#use_item,name=gauntlets_of_winged_triumph,if=buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12)
		if BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } UseItemActions()
		#blood_fury
		UseRacialActions()
	}
}

AddFunction RetributionPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#blessing_of_kings,if=!aura.str_agi_int.up
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(str_agi_int any=1)
	{
		Spell(blessing_of_kings)
		if not BuffPresent(mastery any=1) Spell(blessing_of_might)
	}
	#seal_of_truth,if=active_enemies<4
	if not Stance(paladin_seal_of_truth) Spell(seal_of_truth)
	#snapshot_stats
}

AddFunction RetributionPrecombatCdActions
{
	#mogu_power_potion
	UsePotionStrength()
}

### Retribution Icons

AddIcon mastery=retribution help=cd size=small checkboxon=opt_icons_left
{
	if IsRooted()
	{
		Spell(hand_of_freedom)
		Spell(emancipate)
	}
}

AddIcon mastery=retribution help=cd size=small checkboxon=opt_icons_left
{
	Spell(lay_on_hands)
	Spell(hand_of_protection)
	if DebuffExpires(forbearance_debuff) Spell(divine_shield)
}

AddIcon mastery=retribution help=shortcd
{
	RetributionDefaultShortCdActions()
}

AddIcon mastery=retribution help=main
{
	RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon mastery=retribution help=aoe checkboxon=opt_aoe
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultAoeActions()
}

AddIcon mastery=retribution help=cd
{
	if InCombat(no) RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}

AddIcon mastery=retribution help=cd size=small checkboxon=opt_icons_right
{
	#seal_of_righteousness,if=active_enemies>=4
	if Enemies() >= 4 and not Stance(paladin_seal_of_righteousness) Spell(seal_of_righteousness)
	if BuffPresent(righteous_fury) Texture(spell_holy_sealoffury)
}

AddIcon mastery=retribution help=cd size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("PALADIN", name, desc, code)
end
