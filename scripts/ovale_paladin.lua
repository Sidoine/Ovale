local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_paladin"
	local desc = "[5.4.8] Ovale: Holy, Protection, Retribution"
	local code = [[
# Ovale paladin script based on SimulationCraft.

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default specialization=retribution)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction Consecration
{
	if Glyph(glyph_of_consecration) Spell(consecration_glyphed)
	if Glyph(glyph_of_consecration no) Spell(consecration)
}

AddFunction Exorcism
{
	if Glyph(glyph_of_mass_exorcism) Spell(exorcism_glyphed)
	if Glyph(glyph_of_mass_exorcism no) Spell(exorcism)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if target.Classification(worldboss no)
		{
			if Talent(fist_of_justice_talent) Spell(fist_of_justice)
			if Talent(fist_of_justice_talent no) and target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

###
### Holy
###
# Rotation from Icy Veins, "Holy Paladin Healing Guide (WoW MoP 5.4)"
#	http://www.icy-veins.com/holy-paladin-wow-pve-healing-guide

AddFunction HolySingleTargetActions
{
	if BuffCountOnAny(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if Talent(sacred_shield_talent) and BuffCountOnAny(sacred_shield_holy_buff) == 0 Spell(sacred_shield_holy)
	if HolyPower() == MaxHolyPower()
	{
		if Talent(eternal_flame_talent) Spell(eternal_flame)
		Spell(word_of_glory)
	}
	if target.IsFriend(no) and target.InRange(crusader_strike) Spell(crusader_strike)
	Spell(holy_shock)
	Spell(divine_light)
}

AddFunction HolyAoeActions
{
	if BuffCountOnAny(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if Talent(sacred_shield_talent) and BuffCountOnAny(sacred_shield_holy_buff) == 0 Spell(sacred_shield_holy)
	if HolyPower() == MaxHolyPower()
	{
		if Talent(eternal_flame_talent) Spell(eternal_flame)
		Spell(light_of_dawn)
	}
	if target.IsFriend(no) and target.InRange(crusader_strike) Spell(crusader_strike)
	Spell(holy_shock)
	Spell(holy_radiance)
}

AddFunction HolySelflessHealerAoeActions
{
	if BuffCountOnAny(beacon_of_light_buff) == 0 Spell(beacon_of_light)
	if HolyPower() == MaxHolyPower() Spell(light_of_dawn)
	if target.IsFriend(no) and target.InRange(judgment) Spell(judgment)
	if BuffPresent(selfless_healer_buff) Spell(holy_radiance)
	Spell(holy_shock)
}

AddFunction HolyPrecombatActions
{
	if BuffExpires(str_agi_int_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	if BuffExpires(mastery_buff any=1) Spell(blessing_of_might)
	if not Stance(paladin_seal_of_insight) Spell(seal_of_insight)
}

### Holy Icons
AddCheckBox(opt_paladin_holy "Show Holy icons" specialization=holy default)
AddCheckBox(opt_paladin_holy_aoe L(AOE) specialization=holy default)

AddIcon specialization=holy help=shortcd checkbox=opt_paladin_holy
{
	if Talent(holy_prism_talent) Spell(holy_prism)
	if Talent(lights_hammer_talent) Spell(lights_hammer)
	if Talent(execution_sentence_talent) Spell(execution_sentence)
}

AddIcon specialization=holy help=main checkbox=opt_paladin_holy
{
	HolyPrecombatActions()
	HolySingleTargetActions()
}

AddIcon specialization=holy help=aoe checkbox=opt_paladin_holy checkbox=opt_paladin_holy_aoe
{
	HolyPrecombatActions()
	if Talent(selfless_healer_talent) HolySelflessHealerAoeActions()
	if Talent(selfless_healer_talent no) HolyAoeActions()
}

AddIcon specialization=holy help=cd checkbox=opt_paladin_holy
{
	InterruptActions()
	if IsRooted() Spell(hand_of_freedom)
	if Talent(holy_avenger_talent) Spell(holy_avenger)
	Spell(avenging_wrath)
	Spell(divine_favor)
	Spell(guardian_of_ancient_kings_heal)
}

###
### Protection
###
# Based on SimulationCraft profile "Paladin_Protection_T16H".
#	class=paladin
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bZ!201121
#	glyphs=focused_shield/alabaster_shield/divine_protection

# ActionList: ProtectionPrecombatActions --> main, shortcd, cd

AddFunction ProtectionPrecombatActions
{
	#flask,type=earth
	#food,type=chun_tian_spring_rolls
	#blessing_of_kings,if=(!aura.str_agi_int.up)&(aura.mastery.up)
	if not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_insight
	if not Stance(paladin_seal_of_insight) Spell(seal_of_insight)
	#sacred_shield,if=talent.sacred_shield.enabled
	if Talent(sacred_shield_talent) Spell(sacred_shield)
	#snapshot_stats
}

AddFunction ProtectionPrecombatShortCdActions {}

AddFunction ProtectionPrecombatCdActions {}

# ActionList: ProtectionDefaultActions --> main, shortcd, cd

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#judgment,if=talent.sanctified_wrath.enabled&buff.avenging_wrath.react
	if Talent(sanctified_wrath_talent) and BuffPresent(avenging_wrath_buff) Spell(judgment)
	#wait,sec=cooldown.judgment.remains,if=talent.sanctified_wrath.enabled&cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5
	unless Talent(sanctified_wrath_talent) and SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.5 and SpellCooldown(judgment) > 0
	{
		#crusader_strike
		Spell(crusader_strike)
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.5
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.5 and SpellCooldown(crusader_strike) > 0
		{
			#judgment
			Spell(judgment)
			#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5&(cooldown.crusader_strike.remains-cooldown.judgment.remains)>=0.5
			unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.5 and SpellCooldown(crusader_strike) - SpellCooldown(judgment) >= 0.5 and SpellCooldown(judgment) > 0
			{
				#avengers_shield
				Spell(avengers_shield)
				#sacred_shield,if=talent.sacred_shield.enabled&target.dot.sacred_shield.remains<5
				if Talent(sacred_shield_talent) and BuffPresent(sacred_shield_buff) < 5 Spell(sacred_shield)
				#holy_wrath
				Spell(holy_wrath)
				#hammer_of_wrath
				if target.HealthPercent() < 20 Spell(hammer_of_wrath)
				#holy_prism,if=talent.holy_prism.enabled
				if Talent(holy_prism_talent) Spell(holy_prism)
				#sacred_shield,if=talent.sacred_shield.enabled
				if Talent(sacred_shield_talent) Spell(sacred_shield)
			}
		}
	}
}

AddFunction ProtectionDefaultShortCdActions
{
	#divine_protection
	Spell(divine_protection)
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react))
	if Talent(eternal_flame_talent) and BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.bastion_of_power.react&buff.bastion_of_glory.react>=5)
	if Talent(eternal_flame_talent) and BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=holy_power>=5|buff.divine_purpose.react|incoming_damage_1500ms>=health.max*0.3
	if HolyPower() >= 5 or BuffPresent(divine_purpose_buff) or IncomingDamage(1.5) >= MaxHealth() * 0.3 Spell(shield_of_the_righteous)

	unless Talent(sanctified_wrath_talent) and BuffPresent(avenging_wrath_buff) and Spell(judgment)
	{
		#wait,sec=cooldown.judgment.remains,if=talent.sanctified_wrath.enabled&cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5
		unless Talent(sanctified_wrath_talent) and SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.5 and SpellCooldown(judgment) > 0
		{
			unless Spell(crusader_strike)
			{
				#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.5
				unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.5 and SpellCooldown(crusader_strike) > 0
				{
					unless Spell(judgment)
					{
						#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.5&(cooldown.crusader_strike.remains-cooldown.judgment.remains)>=0.5
						unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.5 and SpellCooldown(crusader_strike) - SpellCooldown(judgment) >= 0.5 and SpellCooldown(judgment) > 0
						{
							unless Spell(avengers_shield)
								or Talent(sacred_shield_talent) and BuffPresent(sacred_shield_buff) < 5 and Spell(sacred_shield)
								or Spell(holy_wrath)
							{
								#execution_sentence,if=talent.execution_sentence.enabled
								if Talent(execution_sentence_talent) Spell(execution_sentence)
								#lights_hammer,if=talent.lights_hammer.enabled
								if Talent(lights_hammer_talent) Spell(lights_hammer)

								unless target.HealthPercent() < 20 and Spell(hammer_of_wrath)
								{
									#consecration,if=target.debuff.flying.down&!ticking
									if target.True(debuff_flying_down) and not target.DebuffPresent(consecration_debuff) Consecration()
								}
							}
						}
					}
				}
			}
		}
	}
}

AddFunction ProtectionDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_mana)
	#avenging_wrath
	Spell(avenging_wrath)
	#holy_avenger,if=talent.holy_avenger.enabled
	if Talent(holy_avenger_talent) Spell(holy_avenger)

	# CHANGE: Leave check for Divine Protection as we don't want to have it up with long survival CDs.
	unless Spell(divine_protection)
	{
		#guardian_of_ancient_kings,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down
		if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings_tank)
		#ardent_defender,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down
		if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_tank_buff) Spell(ardent_defender)
	}
}

### Protection Icons
AddCheckBox(opt_paladin_protection "Show Protection icons" specialization=protection default)
AddCheckBox(opt_paladin_protection_aoe L(AOE) specialization=protection default)

AddIcon specialization=protection help=shortcd checkbox=opt_paladin_protection
{
	if InCombat(no) ProtectionPrecombatShortCdActions()
	if BuffExpires(righteous_fury) Spell(righteous_fury)
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=main checkbox=opt_paladin_protection
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=aoe checkbox=opt_paladin_protection checkbox=opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatActions()

	# HotR > AS > Cons > J > HW
	Spell(hammer_of_the_righteous)
	Spell(judgment)
	Spell(avengers_shield)
	Consecration()
	Spell(judgment)
	Spell(holy_wrath)
}

AddIcon specialization=protection help=cd checkbox=opt_paladin_protection
{
	if InCombat(no) ProtectionPrecombatCdActions()
	if IsRooted() Spell(hand_of_freedom)
	ProtectionDefaultCdActions()
}

###
### Retribution
###
# Based on SimulationCraft profile "Paladin_Retribution_T16H".
#	class=paladin
#	spec=retribution
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bb!110112
#	glyphs=double_jeopardy/mass_exorcism

# ActionList: RetributionPrecombatActions --> main, shortcd, cd

AddFunction RetributionPrecombatActions
{
	#flask,type=winters_bite
	#food,type=black_pepper_ribs_and_shrimp
	#blessing_of_kings,if=!aura.str_agi_int.up
	if not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_truth,if=active_enemies<4
	if Enemies() < 4 and not Stance(paladin_seal_of_truth) Spell(seal_of_truth)
	#seal_of_righteousness,if=active_enemies>=4
	if Enemies() >= 4 and not Stance(paladin_seal_of_righteousness) Spell(seal_of_righteousness)
	#snapshot_stats
}

AddFunction RetributionPrecombatShortCdActions {}

AddFunction RetributionPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings)
		or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might)
		or Enemies() < 4 and not Stance(paladin_seal_of_truth) and Spell(seal_of_truth)
		or Enemies() >= 4 and not Stance(paladin_seal_of_righteousness) and Spell(seal_of_righteousness)
	{
		#mogu_power_potion
		UsePotionStrength()
	}
}

# ActionList: RetributionDefaultActions --> main, shortcd, cd

AddFunction RetributionDefaultActions
{
	#auto_attack
	#inquisition,if=(buff.inquisition.down|buff.inquisition.remains<=2)&(holy_power>=3|target.time_to_die<holy_power*20|buff.divine_purpose.react)
	if { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } Spell(inquisition)
	#divine_storm,if=active_enemies>=2&(holy_power=5|buff.divine_purpose.react|(buff.holy_avenger.up&holy_power>=3))
	if Enemies() >= 2 and { HolyPower() == 5 or BuffPresent(divine_purpose_buff) or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 } Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 4 Spell(templars_verdict)
	#hammer_of_wrath
	if target.HealthPercent() < 20 or BuffPresent(avenging_wrath_buff) Spell(hammer_of_wrath)
	#wait,sec=cooldown.hammer_of_wrath.remains,if=cooldown.hammer_of_wrath.remains>0&cooldown.hammer_of_wrath.remains<=0.2
	unless SpellCooldown(hammer_of_wrath) > 0 and SpellCooldown(hammer_of_wrath) <= 0.2
	{
		#divine_storm,if=buff.divine_crusader.react&buff.avenging_wrath.up
		if BuffPresent(divine_crusader_buff) and BuffPresent(avenging_wrath_buff) Spell(divine_storm)
		#templars_verdict,if=buff.avenging_wrath.up
		if BuffPresent(avenging_wrath_buff) Spell(templars_verdict)
		#hammer_of_the_righteous,if=active_enemies>=4
		if Enemies() >= 4 Spell(hammer_of_the_righteous)
		#crusader_strike
		Spell(crusader_strike)
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.2
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.2
		{
			#exorcism,if=active_enemies>=2&active_enemies<=4&set_bonus.tier15_2pc_melee&glyph.mass_exorcism.enabled
			if Enemies() >= 2 and Enemies() <= 4 and ArmorSetBonus(T15_melee 2) and Glyph(glyph_of_mass_exorcism) Exorcism()
			#judgment
			Spell(judgment)
			#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.2
			unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.2
			{
				#divine_storm,if=buff.divine_crusader.react
				if BuffPresent(divine_crusader_buff) Spell(divine_storm)
				#templars_verdict,if=buff.divine_purpose.react
				if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
				#exorcism
				Exorcism()
				#wait,sec=cooldown.exorcism.remains,if=cooldown.exorcism.remains>0&cooldown.exorcism.remains<=0.2
				unless SpellCooldown(exorcism) > 0 and SpellCooldown(exorcism) <= 0.2
				{
					#templars_verdict,if=buff.tier15_4pc_melee.up&active_enemies<4
					if BuffPresent(tier15_4pc_melee_buff) and Enemies() < 4 Spell(templars_verdict)
					#divine_storm,if=active_enemies>=2&buff.inquisition.remains>4
					if Enemies() >= 2 and BuffRemaining(inquisition_buff) > 4 Spell(divine_storm)
					#templars_verdict,if=buff.inquisition.remains>4
					if BuffRemaining(inquisition_buff) > 4 Spell(templars_verdict)
					#holy_prism,if=talent.holy_prism.enabled
					if Talent(holy_prism_talent) Spell(holy_prism)
				}
			}
		}
	}
}

AddFunction RetributionDefaultShortCdActions
{
	unless { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } and Spell(inquisition)
	{
		#avenging_wrath,if=buff.inquisition.up
		if BuffPresent(inquisition_buff) Spell(avenging_wrath)
		#execution_sentence,if=talent.execution_sentence.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
		if Talent(execution_sentence_talent) and BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } Spell(execution_sentence)
		#lights_hammer,if=talent.lights_hammer.enabled&(buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12))
		if Talent(lights_hammer_talent) and BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } Spell(lights_hammer)
	}
}

AddFunction RetributionDefaultCdActions
{
	#rebuke
	InterruptActions()
	#mogu_power_potion,if=(buff.bloodlust.react|(buff.ancient_power.up&buff.avenging_wrath.up)|target.time_to_die<=40)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(ancient_power_buff) and BuffPresent(avenging_wrath_buff) or target.TimeToDie() <= 40 UsePotionStrength()

	unless { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) <= 2 } and { HolyPower() >= 3 or target.TimeToDie() < HolyPower() * 20 or BuffPresent(divine_purpose_buff) } and Spell(inquisition)
	{
		#guardian_of_ancient_kings,if=buff.inquisition.up
		if BuffPresent(inquisition_buff) Spell(guardian_of_ancient_kings_melee)
		#holy_avenger,if=talent.holy_avenger.enabled&(buff.inquisition.up&holy_power<=2)
		if Talent(holy_avenger_talent) and BuffPresent(inquisition_buff) and HolyPower() <= 2 Spell(holy_avenger)
		#use_item,name=gauntlets_of_winged_triumph,if=buff.inquisition.up&(buff.ancient_power.down|buff.ancient_power.stack=12)
		if BuffPresent(inquisition_buff) and { BuffExpires(ancient_power_buff) or BuffStacks(ancient_power_buff) == 12 } UseItemActions()
		#blood_fury
		Spell(blood_fury_apsp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_mana)
	}
}

### Retribution Icons
AddCheckBox(opt_paladin_retribution "Show Retribution icons" specialization=retribution default)
AddCheckBox(opt_paladin_retribution_aoe L(AOE) specialization=retribution default)

AddIcon specialization=retribution help=shortcd enemies=1 checkbox=opt_paladin_retribution checkbox=!opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatShortCdActions()
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=shortcd checkbox=opt_paladin_retribution checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatShortCdActions()
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=main enemies=1 checkbox=opt_paladin_retribution
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon specialization=retribution help=aoe checkbox=opt_paladin_retribution checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon specialization=retribution help=cd enemies=1 checkbox=opt_paladin_retribution checkbox=!opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}

AddIcon specialization=retribution help=cd checkbox=opt_paladin_retribution checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("PALADIN", "Ovale", desc, code, "script")
end
