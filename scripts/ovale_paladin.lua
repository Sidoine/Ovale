local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_paladin"
	local desc = "[6.0] Ovale: Protection, Retribution"
	local code = [[
# Ovale paladin script based on SimulationCraft.

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction GetInMeleeRange
{
	if not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

###
### Protection
###
# Based on SimulationCraft profile "Paladin_Protection_T16M".
#	class=paladin
#	spec=protection
#	talents=3132320
#	glyphs=focused_shield/alabaster_shield/divine_protection

AddFunction ProtectionRighteousFury
{
	if CheckBoxOn(opt_righteous_fury_check) and BuffExpires(righteous_fury) Spell(righteous_fury)
}

AddFunction ProtectionTimeToHPG
{
	if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
	if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
}

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
	Spell(seal_of_insight)
	#snapshot_stats
}

AddFunction ProtectionPrecombatShortCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings)
		or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might)
		or Spell(seal_of_insight)
	{
		#sacred_shield
		Spell(sacred_shield)
	}
}

AddFunction ProtectionPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings)
		or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might)
		or Spell(seal_of_insight)
		or Spell(sacred_shield)
	{
		#potion,name=mogu_power
		UsePotionStrength()
	}
}

# ActionList: ProtectionDefaultActions --> main, shortcd, cd

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#seal_of_insight,if=talent.empowered_seals.enabled&!seal.insight&buff.uthers_insight.remains<cooldown.judgment.remains
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) < SpellCooldown(judgment) Spell(seal_of_insight)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.uthers_insight.remains>cooldown.judgment.remains&buff.liadrins_righteousness.down
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffExpires(liadrins_righteousness_buff) Spell(seal_of_righteousness)
	#seal_of_truth,if=talent.empowered_seals.enabled&!seal.truth&buff.uthers_insight.remains>cooldown.judgment.remains&buff.liadrins_righteousness.remains>cooldown.judgment.remains&buff.maraads_truth.down
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffRemaining(liadrins_righteousness_buff) > SpellCooldown(judgment) and BuffExpires(maraads_truth_buff) Spell(seal_of_truth)
	#avengers_shield,if=buff.grand_crusader.react&active_enemies>1&!glyph.focused_shield.enabled
	if BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#crusader_strike
	Spell(crusader_strike)
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
	unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
	{
		#judgment
		Spell(judgment)
		#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
		unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
		{
			#avengers_shield,if=active_enemies>1&!glyph.focused_shield.enabled
			if Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
			#holy_wrath,if=talent.sanctified_wrath.enabled
			if Talent(sanctified_wrath_talent) Spell(holy_wrath)
			#avengers_shield,if=buff.grand_crusader.react
			if BuffPresent(grand_crusader_buff) Spell(avengers_shield)
			#sacred_shield,if=target.dot.sacred_shield.remains<2
			if BuffPresent(sacred_shield_buff) < 2 Spell(sacred_shield)
			#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
			if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
			#avengers_shield
			Spell(avengers_shield)
			#holy_prism
			Spell(holy_prism)
			#execution_sentence
			Spell(execution_sentence)
			#hammer_of_wrath
			Spell(hammer_of_wrath)
			#sacred_shield,if=target.dot.sacred_shield.remains<8
			if BuffPresent(sacred_shield_buff) < 8 Spell(sacred_shield)
			#holy_wrath
			Spell(holy_wrath)
			#seal_of_insight,if=talent.empowered_seals.enabled&!seal.insight&buff.uthers_insight.remains<=buff.liadrins_righteousness.remains&buff.uthers_insight.remains<=buff.maraads_truth.remains
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) <= BuffRemaining(liadrins_righteousness_buff) and BuffRemaining(uthers_insight_buff) <= BuffRemaining(maraads_truth_buff) Spell(seal_of_insight)
			#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.liadrins_righteousness.remains<=buff.uthers_insight.remains&buff.liadrins_righteousness.remains<=buff.maraads_truth.remains
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= BuffRemaining(uthers_insight_buff) and BuffRemaining(liadrins_righteousness_buff) <= BuffRemaining(maraads_truth_buff) Spell(seal_of_righteousness)
			#seal_of_truth,if=talent.empowered_seals.enabled&!seal.truth&buff.maraads_truth.remains<buff.uthers_insight.remains&buff.maraads_truth.remains<buff.liadrins_righteousness.remains
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < BuffRemaining(uthers_insight_buff) and BuffRemaining(maraads_truth_buff) < BuffRemaining(liadrins_righteousness_buff) Spell(seal_of_truth)
			#sacred_shield
			Spell(sacred_shield)
		}
	}
}

AddFunction ProtectionDefaultShortCdActions
{
	# CHANGE: Ensure that Righteous Fury is on while tanking.
	ProtectionRighteousFury()
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
	#seraphim
	Spell(seraphim)
	#eternal_flame,if=buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react)
	if BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=buff.bastion_of_power.react&buff.bastion_of_glory.react>=5
	if BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	# CHANGE: Get into melee range for Shield of the Righteousness.
	GetInMeleeRange()
	#shield_of_the_righteous,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(holy_power>=5|incoming_damage_1500ms>=health.max*0.3)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or IncomingDamage(1.5) >= MaxHealth() * 0.3 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)

	unless Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) < SpellCooldown(judgment) and Spell(seal_of_insight)
		or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffExpires(liadrins_righteousness_buff) and Spell(seal_of_righteousness)
		or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffRemaining(liadrins_righteousness_buff) > SpellCooldown(judgment) and BuffExpires(maraads_truth_buff) and Spell(seal_of_truth)
		or BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield)
		or Enemies() >= 3 and Spell(hammer_of_the_righteous)
		or Spell(crusader_strike)
	{
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
		{
			unless Spell(judgment)
			{
				#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
				unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
					or Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield)
					or Talent(sanctified_wrath_talent) and Spell(holy_wrath)
					or BuffPresent(grand_crusader_buff) and Spell(avengers_shield)
					or BuffPresent(sacred_shield_buff) < 2 and Spell(sacred_shield)
					or Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 and Spell(holy_wrath)
					or Spell(avengers_shield)
				{
					#lights_hammer
					Spell(lights_hammer)

					unless Spell(holy_prism)
					{
						if target.True(debuff_flying_down) and Enemies() >= 3 Spell(consecration)
						
						unless Spell(execution_sentence)
							or Spell(hammer_of_wrath)
							or BuffPresent(sacred_shield_buff) < 8 and Spell(sacred_shield)
						{
							if target.True(debuff_flying_down) Spell(consecration)
							
							unless Spell(holy_wrath)
								or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) <= BuffRemaining(liadrins_righteousness_buff) and BuffRemaining(uthers_insight_buff) <= BuffRemaining(maraads_truth_buff) and Spell(seal_of_insight)
								or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= BuffRemaining(uthers_insight_buff) and BuffRemaining(liadrins_righteousness_buff) <= BuffRemaining(maraads_truth_buff) and Spell(seal_of_righteousness)
								or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < BuffRemaining(uthers_insight_buff) and BuffRemaining(maraads_truth_buff) < BuffRemaining(liadrins_righteousness_buff) and Spell(seal_of_truth)
								or Spell(sacred_shield)
							{
								#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
								if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
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
	# CHANGE: Suggest interrupt actions.
	InterruptActions()
	# CHANGE: Suggest Hand of Freedom to break root effects.
	if IsRooted() Spell(hand_of_freedom)
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#potion,name=mogu_power,if=buff.shield_of_the_righteous.down&buff.seraphim.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down&buff.ardent_defender.down
	if BuffExpires(shield_of_the_righteous_buff) and BuffExpires(seraphim_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) and BuffExpires(ardent_defender_buff) UsePotionStrength()
	#holy_avenger
	Spell(holy_avenger)

	unless Spell(seraphim)
	{
		#divine_protection,if=time<5|!talent.seraphim.enabled|(buff.seraphim.down&cooldown.seraphim.remains>5)
		if TimeInCombat() < 5 or not Talent(seraphim_talent) or BuffExpires(seraphim_buff) and SpellCooldown(seraphim) > 5 Spell(divine_protection)
		#guardian_of_ancient_kings,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down)
		if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings)
		#ardent_defender,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down)
		if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) Spell(ardent_defender)
	}
}

### Protection Icons
AddCheckBox(opt_paladin_protection_aoe L(AOE) specialization=protection default)

AddIcon specialization=protection help=shortcd enemies=1 checkbox=!opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatShortCdActions()
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=shortcd checkbox=opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatShortCdActions()
	ProtectionDefaultShortCdActions()
}

AddIcon specialization=protection help=main enemies=1
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=aoe checkbox=opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=cd enemies=1 checkbox=!opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}

AddIcon specialization=protection help=cd checkbox=opt_paladin_protection_aoe
{
	if InCombat(no) ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}

###
### Retribution
###
# Based on SimulationCraft profile "Paladin_Retribution_T16M".
#	class=paladin
#	spec=retribution
#	talents=2212230
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
	#seal_of_truth,if=active_enemies<2
	if Enemies() < 2 Spell(seal_of_truth)
	#seal_of_righteousness,if=active_enemies>=2
	if Enemies() >= 2 Spell(seal_of_righteousness)
	#snapshot_stats
	#potion,name=mogu_power
	UsePotionStrength()
}

AddFunction RetributionPrecombatShortCdActions {}

AddFunction RetributionPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings)
		or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might)
		or Enemies() < 2 and Spell(seal_of_truth)
		or Enemies() >= 2 and Spell(seal_of_righteousness)
	{
		#potion,name=mogu_power
		UsePotionStrength()
	}
}

# ActionList: RetributionDefaultActions --> main, shortcd, cd

AddFunction RetributionDefaultActions
{
	#auto_attack
	#seraphim
	Spell(seraphim)
	#call_action_list,name=aoe,if=active_enemies>=5
	if Enemies() >= 5 RetributionAoeActions()
	#call_action_list,name=cleave,if=active_enemies>=3
	if Enemies() >= 3 RetributionCleaveActions()
	#call_action_list,name=single
	RetributionSingleActions()
}

AddFunction RetributionDefaultShortCdActions
{
	# CHANGE: Check that Righteous Fury is toggled off.
	RighteousFuryOff()
	#speed_of_light,if=movement.distance>5
	if 0 > 5 Spell(speed_of_light)
	#execution_sentence
	Spell(execution_sentence)
	#lights_hammer
	Spell(lights_hammer)
}

AddFunction RetributionDefaultCdActions
{
	#rebuke
	InterruptActions()
	#potion,name=mogu_power,if=(buff.bloodlust.react|buff.avenging_wrath.up|target.time_to_die<=40)
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_melee_buff) or target.TimeToDie() <= 40 UsePotionStrength()

	unless Spell(execution_sentence)
		or Spell(lights_hammer)
	{
		#holy_avenger,sync=seraphim,if=talent.seraphim.enabled
		if not SpellCooldown(seraphim) > 0 and Talent(seraphim_talent) Spell(holy_avenger)
		#holy_avenger,if=holy_power<=2&!talent.seraphim.enabled
		if HolyPower() <= 2 and not Talent(seraphim_talent) Spell(holy_avenger)
		#avenging_wrath,sync=seraphim,if=talent.seraphim.enabled
		if not SpellCooldown(seraphim) > 0 and Talent(seraphim_talent) Spell(avenging_wrath_melee)
		#avenging_wrath,if=!talent.seraphim.enabled
		if not Talent(seraphim_talent) Spell(avenging_wrath_melee)
		#blood_fury
		Spell(blood_fury_apsp)
		#berserking
		Spell(berserking)
		#arcane_torrent
		Spell(arcane_torrent_holy)
	}
}

# ActionList: RetributionAoeActions --> main

AddFunction RetributionAoeActions
{
	#divine_storm,if=holy_power=5&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() == 5 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(divine_storm)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Spell(exorcism)
	#hammer_of_the_righteous
	Spell(hammer_of_the_righteous)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<=5
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= 5 Spell(judgment)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#divine_storm,if=(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 Spell(divine_storm)
	#exorcism,if=glyph.mass_exorcism.enabled
	if Glyph(glyph_of_mass_exorcism) Spell(exorcism)
	#judgment
	Spell(judgment)
	#exorcism
	Spell(exorcism)
	#holy_prism
	Spell(holy_prism)
}

# ActionList: RetributionSingleActions --> main

AddFunction RetributionSingleActions
{
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&active_enemies=2&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Enemies() == 2 and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=holy_power=5&active_enemies=2&buff.final_verdict.up
	if HolyPower() == 5 and Enemies() == 2 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&holy_power=5&(talent.seraphim.enabled&cooldown.seraphim.remains<=4)
	if BuffPresent(divine_crusader_buff) and HolyPower() == 5 and Talent(seraphim_talent) and SpellCooldown(seraphim) <= 4 Spell(divine_storm)
	#templars_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#templars_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 4 Spell(templars_verdict)
	#divine_storm,if=buff.divine_crusader.react&buff.divine_crusader.remains<4&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and BuffRemaining(divine_crusader_buff) < 4 and not Talent(final_verdict_talent) Spell(divine_storm)
	#final_verdict,if=holy_power=5|buff.holy_avenger.up&holy_power>=3
	if HolyPower() == 5 or BuffPresent(holy_avenger_buff) and HolyPower() >= 3 Spell(final_verdict)
	#final_verdict,if=buff.divine_purpose.react&buff.divine_purpose.remains<4
	if BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < 4 Spell(final_verdict)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#judgment,if=talent.empowered_seals.enabled&((seal.truth&buff.maraads_truth.remains<cooldown.judgment.duration*2)|(seal.righteousness&buff.liadrins_righteousness.remains<cooldown.judgment.duration*2))
	if Talent(empowered_seals_talent) and { Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) * 2 or Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) * 2 } Spell(judgment)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Spell(exorcism)
	#seal_of_truth,if=talent.empowered_seals.enabled&buff.maraads_truth.remains<(cooldown.judgment.duration)&buff.maraads_truth.remains<=3
	if Talent(empowered_seals_talent) and BuffRemaining(maraads_truth_buff) < SpellCooldownDuration(judgment) and BuffRemaining(maraads_truth_buff) <= 3 Spell(seal_of_truth)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up&(buff.avenging_wrath.up|target.health.pct<35)
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } Spell(divine_storm)
	#final_verdict,if=buff.divine_purpose.react|target.health.pct<35
	if BuffPresent(divine_purpose_buff) or target.HealthPercent() < 35 Spell(final_verdict)
	#templars_verdict,if=buff.avenging_wrath.up|target.health.pct<35&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#crusader_strike
	Spell(crusader_strike)
	#divine_storm,if=buff.divine_crusader.react&(buff.avenging_wrath.up|target.health.pct<35)&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and { BuffPresent(avenging_wrath_melee_buff) or target.HealthPercent() < 35 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#divine_storm,if=buff.divine_crusader.react&buff.final_verdict.up
	if BuffPresent(divine_crusader_buff) and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#final_verdict
	Spell(final_verdict)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&buff.liadrins_righteousness.remains<(cooldown.judgment.duration)&buff.liadrins_righteousness.remains<=3
	if Talent(empowered_seals_talent) and BuffRemaining(liadrins_righteousness_buff) < SpellCooldownDuration(judgment) and BuffRemaining(liadrins_righteousness_buff) <= 3 Spell(seal_of_righteousness)
	#judgment
	Spell(judgment)
	#templars_verdict,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#divine_storm,if=buff.divine_crusader.react&!talent.final_verdict.enabled
	if BuffPresent(divine_crusader_buff) and not Talent(final_verdict_talent) Spell(divine_storm)
	#templars_verdict,if=holy_power>=4&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() >= 4 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#exorcism
	Spell(exorcism)
	#templars_verdict,if=holy_power>=3&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)
	if HolyPower() >= 3 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } Spell(templars_verdict)
	#holy_prism
	Spell(holy_prism)
}

# ActionList: RetributionCleaveActions --> main

AddFunction RetributionCleaveActions
{
	#final_verdict,if=buff.final_verdict.down&holy_power=5
	if BuffExpires(final_verdict_buff) and HolyPower() == 5 Spell(final_verdict)
	#divine_storm,if=holy_power=5&buff.final_verdict.up
	if HolyPower() == 5 and BuffPresent(final_verdict_buff) Spell(divine_storm)
	#divine_storm,if=holy_power=5&(!talent.seraphim.enabled|cooldown.seraphim.remains>4)&!talent.final_verdict.enabled
	if HolyPower() == 5 and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#exorcism,if=buff.blazing_contempt.up&holy_power<=2&buff.holy_avenger.down
	if BuffPresent(blazing_contempt_buff) and HolyPower() <= 2 and BuffExpires(holy_avenger_buff) Spell(exorcism)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#judgment,if=talent.empowered_seals.enabled&seal.righteousness&buff.liadrins_righteousness.remains<=5
	if Talent(empowered_seals_talent) and Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= 5 Spell(judgment)
	#divine_storm,if=(!talent.seraphim.enabled|cooldown.seraphim.remains>4)&!talent.final_verdict.enabled
	if { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 4 } and not Talent(final_verdict_talent) Spell(divine_storm)
	#crusader_strike
	Spell(crusader_strike)
	#final_verdict,if=buff.final_verdict.down
	if BuffExpires(final_verdict_buff) Spell(final_verdict)
	#divine_storm,if=buff.final_verdict.up
	if BuffPresent(final_verdict_buff) Spell(divine_storm)
	#judgment
	Spell(judgment)
	#exorcism
	Spell(exorcism)
	#holy_prism
	Spell(holy_prism)
}

### Retribution Icons
AddCheckBox(opt_paladin_retribution_aoe L(AOE) specialization=retribution default)

AddIcon specialization=retribution help=shortcd enemies=1 checkbox=!opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatShortCdActions()
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=shortcd checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatShortCdActions()
	RetributionDefaultShortCdActions()
}

AddIcon specialization=retribution help=main enemies=1
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon specialization=retribution help=aoe checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatActions()
	RetributionDefaultActions()
}

AddIcon specialization=retribution help=cd enemies=1 checkbox=!opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}

AddIcon specialization=retribution help=cd checkbox=opt_paladin_retribution_aoe
{
	if InCombat(no) RetributionPrecombatCdActions()
	RetributionDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("PALADIN", "Ovale", desc, code, "script")
end
