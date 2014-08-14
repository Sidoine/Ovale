local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Paladin_Protection_T16H"
	local desc = "[5.4] SimulationCraft: Paladin_Protection_T16H"
	local code = [[
# Based on SimulationCraft profile "Paladin_Protection_T16H".
#	class=paladin
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bZ!201121
#	glyphs=focused_shield/alabaster_shield/divine_protection

Include(ovale_common)
Include(ovale_paladin_spells)

AddFunction Consecration
{
	if Glyph(glyph_of_consecration) Spell(consecration_glyphed)
	if Glyph(glyph_of_consecration no) Spell(consecration)
}

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

AddFunction ProtectionDefaultActions
{
	#auto_attack
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
	#divine_protection
	Spell(divine_protection)
	#guardian_of_ancient_kings,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings_tank)
	#ardent_defender,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_tank_buff) Spell(ardent_defender)
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react))
	if Talent(eternal_flame_talent) and BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=talent.eternal_flame.enabled&(buff.bastion_of_power.react&buff.bastion_of_glory.react>=5)
	if Talent(eternal_flame_talent) and BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=holy_power>=5|buff.divine_purpose.react|incoming_damage_1500ms>=health.max*0.3
	if HolyPower() >= 5 or BuffPresent(divine_purpose_buff) or IncomingDamage(1.5) >= MaxHealth() * 0.3 Spell(shield_of_the_righteous)
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
				#execution_sentence,if=talent.execution_sentence.enabled
				if Talent(execution_sentence_talent) Spell(execution_sentence)
				#lights_hammer,if=talent.lights_hammer.enabled
				if Talent(lights_hammer_talent) Spell(lights_hammer)
				#hammer_of_wrath
				if target.HealthPercent() < 20 Spell(hammer_of_wrath)
				#consecration,if=target.debuff.flying.down&!ticking
				if target.True(debuff_flying_down) and not target.DebuffPresent(consecration_debuff) Consecration()
				#holy_prism,if=talent.holy_prism.enabled
				if Talent(holy_prism_talent) Spell(holy_prism)
				#sacred_shield,if=talent.sacred_shield.enabled
				if Talent(sacred_shield_talent) Spell(sacred_shield)
			}
		}
	}
}

AddIcon specialization=protection help=main enemies=1
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=aoe
{
	if InCombat(no) ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

### Required symbols
# arcane_torrent_mana
# ardent_defender
# avengers_shield
# avenging_wrath
# avenging_wrath_buff
# bastion_of_glory_buff
# bastion_of_power_buff
# berserking
# blessing_of_kings
# blessing_of_might
# blood_fury_apsp
# consecration
# consecration_debuff
# consecration_glyphed
# crusader_strike
# divine_protection
# divine_protection_buff
# divine_purpose_buff
# eternal_flame
# eternal_flame_buff
# eternal_flame_talent
# execution_sentence
# execution_sentence_talent
# glyph_of_consecration
# guardian_of_ancient_kings_tank
# guardian_of_ancient_kings_tank_buff
# hammer_of_wrath
# holy_avenger
# holy_avenger_buff
# holy_avenger_talent
# holy_prism
# holy_prism_talent
# holy_wrath
# judgment
# lights_hammer
# lights_hammer_talent
# sacred_shield
# sacred_shield_buff
# sacred_shield_talent
# sanctified_wrath_talent
# seal_of_insight
# shield_of_the_righteous
# shield_of_the_righteous_buff
]]
	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "reference")
end
