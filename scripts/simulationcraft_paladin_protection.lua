local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_paladin_protection_t17m"
	local desc = "[6.1] SimulationCraft: Paladin_Protection_T17M"
	local code = [[
# Based on SimulationCraft profile "Paladin_Protection_T17M".
#	class=paladin
#	spec=protection
#	talents=3032322
#	glyphs=focused_shield/divine_protection/final_wrath

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default specialization=protection)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default specialization=protection)

AddListItem(opt_using_apl normal L(normal_apl) default)
AddListItem(opt_using_apl max_dps "max_dps APL")
AddListItem(opt_using_apl max_survival "max_survival APL")

AddFunction ProtectionUsePotionArmor
{
	if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionInterruptActions
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

AddFunction ProtectionTimeToHPG
{
	if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
	if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
}

### actions.default

AddFunction ProtectionDefaultMainActions
{
	#seal_of_insight,if=talent.empowered_seals.enabled&!seal.insight&buff.uthers_insight.remains<cooldown.judgment.remains
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) < SpellCooldown(judgment) Spell(seal_of_insight)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.uthers_insight.remains>cooldown.judgment.remains&buff.liadrins_righteousness.down
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffExpires(liadrins_righteousness_buff) Spell(seal_of_righteousness)
	#avengers_shield,if=buff.grand_crusader.react&active_enemies>1&!glyph.focused_shield.enabled
	if BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#crusader_strike
	Spell(crusader_strike)
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
	unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
	{
		#judgment,cycle_targets=1,if=glyph.double_jeopardy.enabled&last_judgment_target!=target
		if Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) Spell(judgment text=double)
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
			if BuffRemaining(sacred_shield_buff) < 2 Spell(sacred_shield)
			#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
			if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
			#avengers_shield
			Spell(avengers_shield)
			#holy_prism,if=!talent.seraphim.enabled|buff.seraphim.up|cooldown.seraphim.remains>5|time<5
			if not Talent(seraphim_talent) or BuffPresent(seraphim_buff) or SpellCooldown(seraphim) > 5 or TimeInCombat() < 5 Spell(holy_prism)
			#hammer_of_wrath
			Spell(hammer_of_wrath)
			#sacred_shield,if=target.dot.sacred_shield.remains<8
			if BuffRemaining(sacred_shield_buff) < 8 Spell(sacred_shield)
			#holy_wrath
			Spell(holy_wrath)
			#seal_of_insight,if=talent.empowered_seals.enabled&!seal.insight&buff.uthers_insight.remains<=buff.liadrins_righteousness.remains
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) <= BuffRemaining(liadrins_righteousness_buff) Spell(seal_of_insight)
			#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.liadrins_righteousness.remains<=buff.uthers_insight.remains
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) <= BuffRemaining(uthers_insight_buff) Spell(seal_of_righteousness)
			#sacred_shield
			Spell(sacred_shield)
			#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
			if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
		}
	}
}

AddFunction ProtectionDefaultShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
	#seraphim
	Spell(seraphim)
	#eternal_flame,if=buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react)
	if BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=buff.bastion_of_power.react&buff.bastion_of_glory.react>=5
	if BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(holy_power>=5|incoming_damage_1500ms>=health.max*0.3)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or IncomingDamage(1.5) >= MaxHealth() * 0.3 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)

	unless Talent(empowered_seals_talent) and not Stance(paladin_seal_of_insight) and BuffRemaining(uthers_insight_buff) < SpellCooldown(judgment) and Spell(seal_of_insight) or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(uthers_insight_buff) > SpellCooldown(judgment) and BuffExpires(liadrins_righteousness_buff) and Spell(seal_of_righteousness) or BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield) or Enemies() >= 3 and Spell(hammer_of_the_righteous) or Spell(crusader_strike)
	{
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
		{
			unless Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) and Spell(judgment text=double) or Spell(judgment)
			{
				#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
				unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
				{
					unless Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield) or Talent(sanctified_wrath_talent) and Spell(holy_wrath) or BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or BuffRemaining(sacred_shield_buff) < 2 and Spell(sacred_shield) or Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 and Spell(holy_wrath) or Spell(avengers_shield)
					{
						#lights_hammer,if=!talent.seraphim.enabled|buff.seraphim.remains>10|cooldown.seraphim.remains<6
						if not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) > 10 or SpellCooldown(seraphim) < 6 Spell(lights_hammer)

						unless { not Talent(seraphim_talent) or BuffPresent(seraphim_buff) or SpellCooldown(seraphim) > 5 or TimeInCombat() < 5 } and Spell(holy_prism)
						{
							#consecration,if=target.debuff.flying.down&active_enemies>=3
							if target.True(debuff_flying_down) and Enemies() >= 3 Spell(consecration)
							#execution_sentence,if=!talent.seraphim.enabled|buff.seraphim.up|time<12
							if not Talent(seraphim_talent) or BuffPresent(seraphim_buff) or TimeInCombat() < 12 Spell(execution_sentence)

							unless Spell(hammer_of_wrath) or BuffRemaining(sacred_shield_buff) < 8 and Spell(sacred_shield)
							{
								#consecration,if=target.debuff.flying.down
								if target.True(debuff_flying_down) Spell(consecration)
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
	#rebuke
	ProtectionInterruptActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#holy_avenger
	Spell(holy_avenger)
	#potion,name=draenic_armor,if=buff.shield_of_the_righteous.down&buff.seraphim.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down&buff.ardent_defender.down
	if BuffExpires(shield_of_the_righteous_buff) and BuffExpires(seraphim_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) and BuffExpires(ardent_defender_buff) ProtectionUsePotionArmor()
	#divine_protection,if=time<5|!talent.seraphim.enabled|(buff.seraphim.down&cooldown.seraphim.remains>5&cooldown.seraphim.remains<9)
	if TimeInCombat() < 5 or not Talent(seraphim_talent) or BuffExpires(seraphim_buff) and SpellCooldown(seraphim) > 5 and SpellCooldown(seraphim) < 9 Spell(divine_protection)
	#guardian_of_ancient_kings,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down)
	if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings)
	#ardent_defender,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down)
	if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) Spell(ardent_defender)
}

### actions.max_dps

AddFunction ProtectionMaxDpsMainActions
{
	#avengers_shield,if=buff.grand_crusader.react&active_enemies>1&!glyph.focused_shield.enabled
	if BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
	#holy_wrath,if=talent.sanctified_wrath.enabled&(buff.seraphim.react|(glyph.final_wrath.enabled&target.health.pct<=20))
	if Talent(sanctified_wrath_talent) and { BuffPresent(seraphim_buff) or Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 } Spell(holy_wrath)
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#judgment,if=talent.empowered_seals.enabled&buff.liadrins_righteousness.down
	if Talent(empowered_seals_talent) and BuffExpires(liadrins_righteousness_buff) Spell(judgment)
	#crusader_strike
	Spell(crusader_strike)
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
	unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
	{
		#judgment,cycle_targets=1,if=glyph.double_jeopardy.enabled&last_judgment_target!=target
		if Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) Spell(judgment text=double)
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
			#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
			if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
			#avengers_shield
			Spell(avengers_shield)
			#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness
			if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) Spell(seal_of_righteousness)
			#holy_prism
			Spell(holy_prism)
			#hammer_of_wrath
			Spell(hammer_of_wrath)
			#holy_wrath
			Spell(holy_wrath)
			#sacred_shield
			Spell(sacred_shield)
			#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
			if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
		}
	}
}

AddFunction ProtectionMaxDpsShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
	#seraphim
	Spell(seraphim)
	#shield_of_the_righteous,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(holy_power>=5|talent.holy_avenger.enabled)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or Talent(holy_avenger_talent) } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)

	unless BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield) or Talent(sanctified_wrath_talent) and { BuffPresent(seraphim_buff) or Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 } and Spell(holy_wrath) or Enemies() >= 3 and Spell(hammer_of_the_righteous) or Talent(empowered_seals_talent) and BuffExpires(liadrins_righteousness_buff) and Spell(judgment) or Spell(crusader_strike)
	{
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
		{
			unless Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) and Spell(judgment text=double) or Spell(judgment)
			{
				#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
				unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
				{
					unless Enemies() > 1 and not Glyph(glyph_of_focused_shield) and Spell(avengers_shield) or Talent(sanctified_wrath_talent) and Spell(holy_wrath) or BuffPresent(grand_crusader_buff) and Spell(avengers_shield)
					{
						#execution_sentence,if=active_enemies<3
						if Enemies() < 3 Spell(execution_sentence)

						unless Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 and Spell(holy_wrath) or Spell(avengers_shield) or Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and Spell(seal_of_righteousness)
						{
							#lights_hammer
							Spell(lights_hammer)

							unless Spell(holy_prism)
							{
								#consecration,if=target.debuff.flying.down&active_enemies>=3
								if target.True(debuff_flying_down) and Enemies() >= 3 Spell(consecration)
								#execution_sentence
								Spell(execution_sentence)

								unless Spell(hammer_of_wrath)
								{
									#consecration,if=target.debuff.flying.down
									if target.True(debuff_flying_down) Spell(consecration)
								}
							}
						}
					}
				}
			}
		}
	}
}

AddFunction ProtectionMaxDpsCdActions
{
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#holy_avenger
	Spell(holy_avenger)
	#potion,name=draenic_armor,if=buff.holy_avenger.up|(!talent.holy_avenger.enabled&(buff.seraphim.up|(!talent.seraphim.enabled&buff.bloodlust.react)))|target.time_to_die<=20
	if BuffPresent(holy_avenger_buff) or not Talent(holy_avenger_talent) and { BuffPresent(seraphim_buff) or not Talent(seraphim_talent) and BuffPresent(burst_haste_buff any=1) } or target.TimeToDie() <= 20 ProtectionUsePotionArmor()
}

### actions.max_survival

AddFunction ProtectionMaxSurvivalMainActions
{
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#crusader_strike
	Spell(crusader_strike)
	#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
	unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
	{
		#judgment,cycle_targets=1,if=glyph.double_jeopardy.enabled&last_judgment_target!=target
		if Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) Spell(judgment text=double)
		#judgment
		Spell(judgment)
		#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
		unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
		{
			#avengers_shield,if=buff.grand_crusader.react&active_enemies>1
			if BuffPresent(grand_crusader_buff) and Enemies() > 1 Spell(avengers_shield)
			#holy_wrath,if=talent.sanctified_wrath.enabled
			if Talent(sanctified_wrath_talent) Spell(holy_wrath)
			#avengers_shield,if=buff.grand_crusader.react
			if BuffPresent(grand_crusader_buff) Spell(avengers_shield)
			#sacred_shield,if=target.dot.sacred_shield.remains<2
			if BuffRemaining(sacred_shield_buff) < 2 Spell(sacred_shield)
			#avengers_shield
			Spell(avengers_shield)
			#holy_prism
			Spell(holy_prism)
			#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
			if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
			#hammer_of_wrath
			Spell(hammer_of_wrath)
			#sacred_shield,if=target.dot.sacred_shield.remains<8
			if BuffRemaining(sacred_shield_buff) < 8 Spell(sacred_shield)
			#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
			if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
			#holy_wrath
			Spell(holy_wrath)
			#sacred_shield
			Spell(sacred_shield)
		}
	}
}

AddFunction ProtectionMaxSurvivalShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
	#seraphim,if=buff.divine_protection.down&cooldown.divine_protection.remains>0
	if BuffExpires(divine_protection_buff) and SpellCooldown(divine_protection) > 0 Spell(seraphim)
	#eternal_flame,if=buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react)
	if BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=buff.bastion_of_power.react&buff.bastion_of_glory.react>=5
	if BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=buff.divine_purpose.react
	if BuffPresent(divine_purpose_buff) Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(holy_power>=5|incoming_damage_1500ms>=health.max*0.3)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or IncomingDamage(1.5) >= MaxHealth() * 0.3 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)

	unless Enemies() >= 3 and Spell(hammer_of_the_righteous) or Spell(crusader_strike)
	{
		#wait,sec=cooldown.crusader_strike.remains,if=cooldown.crusader_strike.remains>0&cooldown.crusader_strike.remains<=0.35
		unless SpellCooldown(crusader_strike) > 0 and SpellCooldown(crusader_strike) <= 0.35 and SpellCooldown(crusader_strike) > 0
		{
			unless Glyph(glyph_of_double_jeopardy) and BuffPresent(glyph_of_double_jeopardy_buff) and Spell(judgment text=double) or Spell(judgment)
			{
				#wait,sec=cooldown.judgment.remains,if=cooldown.judgment.remains>0&cooldown.judgment.remains<=0.35
				unless SpellCooldown(judgment) > 0 and SpellCooldown(judgment) <= 0.35 and SpellCooldown(judgment) > 0
				{
					unless BuffPresent(grand_crusader_buff) and Enemies() > 1 and Spell(avengers_shield) or Talent(sanctified_wrath_talent) and Spell(holy_wrath) or BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or BuffRemaining(sacred_shield_buff) < 2 and Spell(sacred_shield) or Spell(avengers_shield)
					{
						#lights_hammer
						Spell(lights_hammer)

						unless Spell(holy_prism)
						{
							#consecration,if=target.debuff.flying.down&active_enemies>=3
							if target.True(debuff_flying_down) and Enemies() >= 3 Spell(consecration)
							#execution_sentence
							Spell(execution_sentence)

							unless Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 and Spell(flash_of_light) or Spell(hammer_of_wrath) or BuffRemaining(sacred_shield_buff) < 8 and Spell(sacred_shield) or Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 and Spell(holy_wrath)
							{
								#consecration,if=target.debuff.flying.down&!ticking
								if target.True(debuff_flying_down) and not target.DebuffPresent(consecration_debuff) Spell(consecration)
							}
						}
					}
				}
			}
		}
	}
}

AddFunction ProtectionMaxSurvivalCdActions
{
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#holy_avenger
	Spell(holy_avenger)
	#potion,name=draenic_armor,if=buff.shield_of_the_righteous.down&buff.seraphim.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down&buff.ardent_defender.down
	if BuffExpires(shield_of_the_righteous_buff) and BuffExpires(seraphim_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) and BuffExpires(ardent_defender_buff) ProtectionUsePotionArmor()
	#divine_protection,if=time<5|!talent.seraphim.enabled|(buff.seraphim.down&cooldown.seraphim.remains>5&cooldown.seraphim.remains<9)
	if TimeInCombat() < 5 or not Talent(seraphim_talent) or BuffExpires(seraphim_buff) and SpellCooldown(seraphim) > 5 and SpellCooldown(seraphim) < 9 Spell(divine_protection)
	#guardian_of_ancient_kings,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings)
	#ardent_defender,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) Spell(ardent_defender)
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
	#flask,type=greater_draenic_stamina_flask
	#flask,type=greater_draenic_strength_flask,if=role.attack|using_apl.max_dps
	#food,type=whiptail_fillet
	#food,type=pickled_eel,if=role.attack|using_apl.max_dps
	#blessing_of_kings,if=(!aura.str_agi_int.up)&(aura.mastery.up)
	if not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if not BuffPresent(mastery_buff any=1) Spell(blessing_of_might)
	#seal_of_insight,if=!using_apl.max_dps|using_apl.max_survival
	if not List(opt_using_apl max_dps) or List(opt_using_apl max_survival) Spell(seal_of_insight)
	#seal_of_righteousness,if=role.attack|using_apl.max_dps
	if False(role_attack) or List(opt_using_apl max_dps) Spell(seal_of_righteousness)
	#righteous_fury,if=buff.righteous_fury.down
	if BuffExpires(righteous_fury_buff) and CheckBoxOn(opt_righteous_fury_check) Spell(righteous_fury)
	#sacred_shield
	Spell(sacred_shield)
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings) or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might) or { not List(opt_using_apl max_dps) or List(opt_using_apl max_survival) } and Spell(seal_of_insight) or { False(role_attack) or List(opt_using_apl max_dps) } and Spell(seal_of_righteousness) or BuffExpires(righteous_fury_buff) and CheckBoxOn(opt_righteous_fury_check) and Spell(righteous_fury) or Spell(sacred_shield)
}

AddFunction ProtectionPrecombatCdActions
{
	unless not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings) or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might) or { not List(opt_using_apl max_dps) or List(opt_using_apl max_survival) } and Spell(seal_of_insight) or { False(role_attack) or List(opt_using_apl max_dps) } and Spell(seal_of_righteousness) or BuffExpires(righteous_fury_buff) and CheckBoxOn(opt_righteous_fury_check) and Spell(righteous_fury) or Spell(sacred_shield)
	{
		#snapshot_stats
		#potion,name=draenic_armor
		ProtectionUsePotionArmor()
	}
}

AddFunction ProtectionPrecombatCdPostConditions
{
	not BuffPresent(str_agi_int_buff any=1) and BuffPresent(mastery_buff any=1) and BuffExpires(mastery_buff) and Spell(blessing_of_kings) or not BuffPresent(mastery_buff any=1) and Spell(blessing_of_might) or { not List(opt_using_apl max_dps) or List(opt_using_apl max_survival) } and Spell(seal_of_insight) or { False(role_attack) or List(opt_using_apl max_dps) } and Spell(seal_of_righteousness) or BuffExpires(righteous_fury_buff) and CheckBoxOn(opt_righteous_fury_check) and Spell(righteous_fury) or Spell(sacred_shield)
}

### Protection icons.

AddCheckBox(opt_paladin_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		if List(opt_using_apl normal) ProtectionDefaultShortCdActions()
		if List(opt_using_apl max_survival) ProtectionMaxSurvivalShortCdActions()
		if List(opt_using_apl max_dps) ProtectionMaxDpsShortCdActions()
	}
}

AddIcon checkbox=opt_paladin_protection_aoe help=shortcd specialization=protection
{
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		if List(opt_using_apl normal) ProtectionDefaultShortCdActions()
		if List(opt_using_apl max_survival) ProtectionMaxSurvivalShortCdActions()
		if List(opt_using_apl max_dps) ProtectionMaxDpsShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	if List(opt_using_apl normal) ProtectionDefaultMainActions()
	if List(opt_using_apl max_survival) ProtectionMaxSurvivalMainActions()
	if List(opt_using_apl max_dps) ProtectionMaxDpsMainActions()
}

AddIcon checkbox=opt_paladin_protection_aoe help=aoe specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	if List(opt_using_apl normal) ProtectionDefaultMainActions()
	if List(opt_using_apl max_survival) ProtectionMaxSurvivalMainActions()
	if List(opt_using_apl max_dps) ProtectionMaxDpsMainActions()
}

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		if List(opt_using_apl normal) ProtectionDefaultCdActions()
		if List(opt_using_apl max_survival) ProtectionMaxSurvivalCdActions()
		if List(opt_using_apl max_dps) ProtectionMaxDpsCdActions()
	}
}

AddIcon checkbox=opt_paladin_protection_aoe help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		if List(opt_using_apl normal) ProtectionDefaultCdActions()
		if List(opt_using_apl max_survival) ProtectionMaxSurvivalCdActions()
		if List(opt_using_apl max_dps) ProtectionMaxDpsCdActions()
	}
}

### Required symbols
# arcane_torrent_holy
# ardent_defender
# ardent_defender_buff
# avengers_shield
# bastion_of_glory_buff
# bastion_of_power_buff
# berserking
# blessing_of_kings
# blessing_of_might
# blinding_light
# blood_fury_apsp
# consecration
# consecration_debuff
# crusader_strike
# divine_protection
# divine_protection_buff
# divine_purpose_buff
# draenic_armor_potion
# empowered_seals_talent
# eternal_flame
# eternal_flame_buff
# execution_sentence
# fist_of_justice
# flash_of_light
# glyph_of_double_jeopardy
# glyph_of_double_jeopardy_buff
# glyph_of_final_wrath
# glyph_of_focused_shield
# grand_crusader_buff
# guardian_of_ancient_kings
# guardian_of_ancient_kings_buff
# hammer_of_justice
# hammer_of_the_righteous
# hammer_of_wrath
# holy_avenger
# holy_avenger_buff
# holy_avenger_talent
# holy_prism
# holy_wrath
# judgment
# liadrins_righteousness_buff
# lights_hammer
# quaking_palm
# rebuke
# righteous_fury
# righteous_fury_buff
# sacred_shield
# sacred_shield_buff
# sanctified_wrath_talent
# seal_of_insight
# seal_of_righteousness
# selfless_healer_buff
# selfless_healer_talent
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
# shield_of_the_righteous_buff
# speed_of_light
# uthers_insight_buff
# war_stomp
]]
	OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end
