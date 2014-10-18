local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Paladin_Protection_T16M"
	local desc = "[6.0.2] SimulationCraft: Paladin_Protection_T16M"
	local code = [[
# Based on SimulationCraft profile "Paladin_Protection_T16M".
#	class=paladin
#	spec=protection
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#bZ!202121.
#	glyphs=focused_shield/alabaster_shield/divine_protection

Include(ovale_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default)

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

AddFunction Consecration
{
	Spell(consecration)
	Spell(consecration_glyph_of_consecration)
	Spell(consecration_glyph_of_the_consecrator)
}

AddFunction GetInMeleeRange
{
	if not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionRighteousFury
{
	if CheckBoxOn(opt_righteous_fury_check) and BuffExpires(righteous_fury) Spell(righteous_fury)
}

AddFunction ProtectionTimeToHPG
{
	if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
	if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
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
	Spell(seal_of_insight)
	#sacred_shield
	Spell(sacred_shield)
	#snapshot_stats
	#potion,name=mogu_power
	UsePotionStrength()
}

AddFunction ProtectionDefaultActions
{
	#auto_attack
	#speed_of_light,if=movement.remains>1
	if 0 > 1 Spell(speed_of_light)
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	Spell(arcane_torrent_holy)
	#run_action_list,name=max_dps,if=role.attack|0
	if False(role_attack) or 0 ProtectionMaxDpsActions()
	#run_action_list,name=max_survival,if=0
	if 0 ProtectionMaxSurvivalActions()
	#potion,name=mogu_power,if=buff.shield_of_the_righteous.down&buff.seraphim.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down&buff.ardent_defender.down
	if BuffExpires(shield_of_the_righteous_buff) and BuffExpires(seraphim_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) and BuffExpires(ardent_defender_buff) UsePotionStrength()
	#holy_avenger
	Spell(holy_avenger)
	#seraphim
	Spell(seraphim)
	#divine_protection,if=time<5|!talent.seraphim.enabled|(buff.seraphim.down&cooldown.seraphim.remains>5)
	if TimeInCombat() < 5 or not Talent(seraphim_talent) or BuffExpires(seraphim_buff) and SpellCooldown(seraphim) > 5 Spell(divine_protection)
	#guardian_of_ancient_kings,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down)
	if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings)
	#ardent_defender,if=time<5|(buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down)
	if TimeInCombat() < 5 or BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) Spell(ardent_defender)
	#eternal_flame,if=buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react)
	if BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=buff.bastion_of_power.react&buff.bastion_of_glory.react>=5
	if BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=(holy_power>=5|buff.divine_purpose.react|incoming_damage_1500ms>=health.max*0.3)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or BuffPresent(divine_purpose_buff) or IncomingDamage(1.5) >= MaxHealth() * 0.3 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)
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
	#judgment
	Spell(judgment)
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
	#lights_hammer
	Spell(lights_hammer)
	#holy_prism
	Spell(holy_prism)
	#consecration,if=target.debuff.flying.down&active_enemies>=3
	if target.True(debuff_flying_down) and Enemies() >= 3 Consecration()
	#execution_sentence
	Spell(execution_sentence)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#sacred_shield,if=target.dot.sacred_shield.remains<8
	if BuffPresent(sacred_shield_buff) < 8 Spell(sacred_shield)
	#consecration,if=target.debuff.flying.down
	if target.True(debuff_flying_down) Consecration()
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
	#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
	if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
}

AddFunction ProtectionMaxDpsActions
{
	#potion,name=mogu_power,if=buff.holy_avenger.react|buff.bloodlust.react|target.time_to_die<=60
	if BuffPresent(holy_avenger_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 UsePotionStrength()
	#holy_avenger
	Spell(holy_avenger)
	#seraphim
	Spell(seraphim)
	#shield_of_the_righteous,if=(holy_power>=5|buff.divine_purpose.react|talent.holy_avenger.enabled)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or BuffPresent(divine_purpose_buff) or Talent(holy_avenger_talent) } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)
	#avengers_shield,if=buff.grand_crusader.react&active_enemies>1&!glyph.focused_shield.enabled
	if BuffPresent(grand_crusader_buff) and Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#holy_wrath,if=talent.sanctified_wrath.enabled&buff.seraphim.react
	if Talent(sanctified_wrath_talent) and BuffPresent(seraphim_buff) Spell(holy_wrath)
	#crusader_strike
	Spell(crusader_strike)
	#judgment
	Spell(judgment)
	#avengers_shield,if=active_enemies>1&!glyph.focused_shield.enabled
	if Enemies() > 1 and not Glyph(glyph_of_focused_shield) Spell(avengers_shield)
	#holy_wrath,if=talent.sanctified_wrath.enabled
	if Talent(sanctified_wrath_talent) Spell(holy_wrath)
	#avengers_shield,if=buff.grand_crusader.react
	if BuffPresent(grand_crusader_buff) Spell(avengers_shield)
	#execution_sentence
	Spell(execution_sentence)
	#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
	if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
	#avengers_shield
	Spell(avengers_shield)
	#seal_of_truth,if=talent.empowered_seals.enabled&!seal.truth&buff.maraads_truth.remains<cooldown.judgment.remains
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < SpellCooldown(judgment) Spell(seal_of_truth)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.maraads_truth.remains>cooldown.judgment.remains&buff.liadrins_righteousness.down
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(maraads_truth_buff) > SpellCooldown(judgment) and BuffExpires(liadrins_righteousness_buff) Spell(seal_of_righteousness)
	#lights_hammer
	Spell(lights_hammer)
	#holy_prism
	Spell(holy_prism)
	#consecration,if=target.debuff.flying.down&active_enemies>=3
	if target.True(debuff_flying_down) and Enemies() >= 3 Consecration()
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#consecration,if=target.debuff.flying.down
	if target.True(debuff_flying_down) Consecration()
	#holy_wrath
	Spell(holy_wrath)
	#seal_of_truth,if=talent.empowered_seals.enabled&!seal.truth&buff.maraads_truth.remains<buff.liadrins_righteousness.remains
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_truth) and BuffRemaining(maraads_truth_buff) < BuffRemaining(liadrins_righteousness_buff) Spell(seal_of_truth)
	#seal_of_righteousness,if=talent.empowered_seals.enabled&!seal.righteousness&buff.liadrins_righteousness.remains<buff.maraads_truth.remains
	if Talent(empowered_seals_talent) and not Stance(paladin_seal_of_righteousness) and BuffRemaining(liadrins_righteousness_buff) < BuffRemaining(maraads_truth_buff) Spell(seal_of_righteousness)
	#sacred_shield
	Spell(sacred_shield)
	#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
	if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
}

AddFunction ProtectionMaxSurvivalActions
{
	#potion,name=mogu_power,if=buff.shield_of_the_righteous.down&buff.seraphim.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down&buff.ardent_defender.down
	if BuffExpires(shield_of_the_righteous_buff) and BuffExpires(seraphim_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) and BuffExpires(ardent_defender_buff) UsePotionStrength()
	#holy_avenger
	Spell(holy_avenger)
	#divine_protection,if=buff.seraphim.down
	if BuffExpires(seraphim_buff) Spell(divine_protection)
	#seraphim,if=buff.divine_protection.down&cooldown.divine_protection.remains>0
	if BuffExpires(divine_protection_buff) and SpellCooldown(divine_protection) > 0 Spell(seraphim)
	#guardian_of_ancient_kings,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) Spell(guardian_of_ancient_kings)
	#ardent_defender,if=buff.holy_avenger.down&buff.shield_of_the_righteous.down&buff.divine_protection.down&buff.guardian_of_ancient_kings.down
	if BuffExpires(holy_avenger_buff) and BuffExpires(shield_of_the_righteous_buff) and BuffExpires(divine_protection_buff) and BuffExpires(guardian_of_ancient_kings_buff) Spell(ardent_defender)
	#eternal_flame,if=buff.eternal_flame.remains<2&buff.bastion_of_glory.react>2&(holy_power>=3|buff.divine_purpose.react|buff.bastion_of_power.react)
	if BuffRemaining(eternal_flame_buff) < 2 and BuffStacks(bastion_of_glory_buff) > 2 and { HolyPower() >= 3 or BuffPresent(divine_purpose_buff) or BuffPresent(bastion_of_power_buff) } Spell(eternal_flame)
	#eternal_flame,if=buff.bastion_of_power.react&buff.bastion_of_glory.react>=5
	if BuffPresent(bastion_of_power_buff) and BuffStacks(bastion_of_glory_buff) >= 5 Spell(eternal_flame)
	#shield_of_the_righteous,if=(holy_power>=5|buff.divine_purpose.react|incoming_damage_1500ms>=health.max*0.3)&(!talent.seraphim.enabled|cooldown.seraphim.remains>5)
	if { HolyPower() >= 5 or BuffPresent(divine_purpose_buff) or IncomingDamage(1.5) >= MaxHealth() * 0.3 } and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > 5 } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=buff.holy_avenger.remains>time_to_hpg&(!talent.seraphim.enabled|cooldown.seraphim.remains>time_to_hpg)
	if BuffRemaining(holy_avenger_buff) > ProtectionTimeToHPG() and { not Talent(seraphim_talent) or SpellCooldown(seraphim) > ProtectionTimeToHPG() } Spell(shield_of_the_righteous)
	#hammer_of_the_righteous,if=active_enemies>=3
	if Enemies() >= 3 Spell(hammer_of_the_righteous)
	#crusader_strike
	Spell(crusader_strike)
	#judgment
	Spell(judgment)
	#avengers_shield,if=buff.grand_crusader.react&active_enemies>1
	if BuffPresent(grand_crusader_buff) and Enemies() > 1 Spell(avengers_shield)
	#holy_wrath,if=talent.sanctified_wrath.enabled
	if Talent(sanctified_wrath_talent) Spell(holy_wrath)
	#avengers_shield,if=buff.grand_crusader.react
	if BuffPresent(grand_crusader_buff) Spell(avengers_shield)
	#sacred_shield,if=target.dot.sacred_shield.remains<2
	if BuffPresent(sacred_shield_buff) < 2 Spell(sacred_shield)
	#avengers_shield
	Spell(avengers_shield)
	#lights_hammer
	Spell(lights_hammer)
	#holy_prism
	Spell(holy_prism)
	#consecration,if=target.debuff.flying.down&active_enemies>=3
	if target.True(debuff_flying_down) and Enemies() >= 3 Consecration()
	#execution_sentence
	Spell(execution_sentence)
	#flash_of_light,if=talent.selfless_healer.enabled&buff.selfless_healer.stack>=3
	if Talent(selfless_healer_talent) and BuffStacks(selfless_healer_buff) >= 3 Spell(flash_of_light)
	#hammer_of_wrath
	Spell(hammer_of_wrath)
	#sacred_shield,if=target.dot.sacred_shield.remains<8
	if BuffPresent(sacred_shield_buff) < 8 Spell(sacred_shield)
	#holy_wrath,if=glyph.final_wrath.enabled&target.health.pct<=20
	if Glyph(glyph_of_final_wrath) and target.HealthPercent() <= 20 Spell(holy_wrath)
	#consecration,if=target.debuff.flying.down&!ticking
	if target.True(debuff_flying_down) and not target.DebuffPresent(consecration_debuff) Consecration()
	#holy_wrath
	Spell(holy_wrath)
	#sacred_shield
	Spell(sacred_shield)
}

AddIcon specialization=protection help=main enemies=1
{
	if not InCombat() ProtectionPrecombatActions()
	ProtectionDefaultActions()
}

AddIcon specialization=protection help=aoe
{
	if not InCombat() ProtectionPrecombatActions()
	ProtectionDefaultActions()
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
# blood_fury_apsp
# consecration
# consecration_debuff
# consecration_glyph_of_consecration
# consecration_glyph_of_the_consecrator
# crusader_strike
# divine_protection
# divine_protection_buff
# divine_purpose_buff
# empowered_seals_talent
# eternal_flame
# eternal_flame_buff
# execution_sentence
# flash_of_light
# glyph_of_consecration
# glyph_of_final_wrath
# glyph_of_focused_shield
# glyph_of_the_consecrator
# grand_crusader_buff
# guardian_of_ancient_kings
# guardian_of_ancient_kings_buff
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
# maraads_truth_buff
# mogu_power_potion
# rebuke
# righteous_fury
# sacred_shield
# sacred_shield_buff
# sanctified_wrath_talent
# seal_of_insight
# seal_of_righteousness
# seal_of_truth
# selfless_healer_buff
# selfless_healer_talent
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
# shield_of_the_righteous_buff
# speed_of_light
# uthers_insight_buff
]]
	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "reference")
end
