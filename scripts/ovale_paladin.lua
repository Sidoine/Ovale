local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "icyveins_paladin_protection"
	local desc = "[7.0] Icy-Veins: Paladin Protection"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_legendary_ring_tank ItemName(legendary_ring_bonus_armor) default specialization=protection)

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(shield_of_the_righteous) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionDefaultMainActions
{
	if Speed() == 0 and HasEquippedItem(heathcliffs_immortality) and not BuffPresent(consecration_buff) Spell(consecration)
	if Charges(shield_of_the_righteous) <= 2*Talent(seraphim_talent) and not BuffPresent(shield_of_the_righteous_buff) and ProtectionCooldownTreshold() and (not Talent(bastion_of_light_talent) or SpellCooldown(bastion_of_light) == 0) Spell(eye_of_tyr)
	if Talent(blessed_hammer_talent) Spell(blessed_hammer)
	Spell(judgment)
	if Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) Spell(avengers_shield)
	if Speed() == 0 and not Talent(consecrated_hammer_talent) and not BuffPresent(consecration_buff) Spell(consecration)
	Spell(avengers_shield)
	Spell(blinding_light)
	if Speed() == 0 Spell(consecration)
	Spell(hammer_of_the_righteous)
}

AddFunction ProtectionDefaultAoEActions
{
	if Speed() == 0 and HasEquippedItem(heathcliffs_immortality) and not BuffPresent(consecration_buff) Spell(consecration)
	if Charges(shield_of_the_righteous) <= 2*Talent(seraphim_talent) and not BuffPresent(shield_of_the_righteous_buff) and ProtectionCooldownTreshold() and (not Talent(bastion_of_light_talent) or SpellCooldown(bastion_of_light) == 0) Spell(eye_of_tyr)
	Spell(avengers_shield)
	if Speed() == 0 and not Talent(consecrated_hammer_talent) and not BuffPresent(consecration_buff) Spell(consecration)
	if Talent(blessed_hammer_talent) Spell(blessed_hammer)
	Spell(judgment)
	Spell(blinding_light)
	if Speed() == 0 Spell(consecration)
	Spell(hammer_of_the_righteous)
}

AddFunction ProtectionDefaultShortCDActions
{
	#bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
	if Talent(bastion_of_light_talent) and Charges(shield_of_the_righteous) < 1 Spell(bastion_of_light)
	#seraphim,if=talent.seraphim.enabled&action.shield_of_the_righteous.charges>=2
	if Talent(seraphim_talent) and Charges(shield_of_the_righteous) >= 2 Spell(seraphim)
	
	ProtectionGetInMeleeRange()
	
	#shield_of_the_righteous,if=(!talent.seraphim.enabled|action.shield_of_the_righteous.charges>2)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and ProtectionCooldownTreshold() Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&talent.seraphim.enabled&buff.seraphim.up&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and ProtectionCooldownTreshold() Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&!talent.seraphim.enabled&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and ProtectionCooldownTreshold() Spell(shield_of_the_righteous)
	#light_of_the_protector,if=(health.pct<40)
	if HealthPercent() < 40 Spell(light_of_the_protector)
	#hand_of_the_protector,if=(health.pct<40)
	if HealthPercent() < 40 Spell(hand_of_the_protector)
	#light_of_the_protector,if=(incoming_damage_10000ms<health.max*1.25)&health.pct<55&talent.righteous_protector.enabled
	if IncomingDamage(10) < MaxHealth() * 1.25 and HealthPercent() < 55 and Talent(righteous_protector_talent) Spell(light_of_the_protector)
	#light_of_the_protector,if=(incoming_damage_13000ms<health.max*1.6)&health.pct<55
	if IncomingDamage(13) < MaxHealth() * 1.6 and HealthPercent() < 55 Spell(light_of_the_protector)
	#hand_of_the_protector,if=(incoming_damage_6000ms<health.max*0.7)&health.pct<65&talent.righteous_protector.enabled
	if IncomingDamage(6) < MaxHealth() * 0.7 and HealthPercent() < 65 and Talent(righteous_protector_talent) Spell(hand_of_the_protector)
	#hand_of_the_protector,if=(incoming_damage_9000ms<health.max*1.2)&health.pct<55
	if IncomingDamage(9) < MaxHealth() * 1.2 and HealthPercent() < 55 Spell(hand_of_the_protector)
}

AddFunction ProtectionCooldownTreshold
{
	HealthPercent() <= 100 
		and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) }
		and not { Talent(seraphim_talent) and BuffPresent(seraphim_buff) }
}

AddCheckBox(opt_avenging_wrath SpellName(avenging_wrath_melee) default specialization=protection)
AddFunction ProtectionDefaultCdActions
{
	ProtectionInterruptActions()
	if CheckBoxOn(opt_avenging_wrath) and (not Talent(seraphim_talent) or BuffPresent(seraphim_buff)) Spell(avenging_wrath_melee)
	
	if ProtectionCooldownTreshold() Spell(ardent_defender)
	if ProtectionCooldownTreshold() Spell(aegis_of_light)
	if ProtectionCooldownTreshold() Spell(guardian_of_ancient_kings)
	if not DebuffPresent(forbearance_debuff) and Talent(final_stand_talent) and ProtectionCooldownTreshold() Spell(divine_shield)
	if not DebuffPresent(forbearance_debuff) and HealthPercent() < 15 Spell(lay_on_hands)

	if Talent(knight_templar_talent) and ProtectionCooldownTreshold() Spell(divine_steed)
	if ProtectionCooldownTreshold() Item(unbending_potion usable=1)
	if ProtectionCooldownTreshold() Spell(stoneform)
}

AddFunction ProtectionInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if target.InRange(avengers_shield) Spell(avengers_shield)
		if not target.Classification(worldboss)
		{
			if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			if target.Distance(less 10) Spell(blinding_light)
			if target.Distance(less 8) Spell(arcane_torrent_holy)
			if target.Distance(less 8) Spell(war_stomp)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddIcon help=shortcd specialization=protection
{
	ProtectionDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=protection
{
	ProtectionDefaultMainActions()
}

AddIcon help=aoe specialization=protection
{
	ProtectionDefaultAoEActions()
}

AddIcon help=cd specialization=protection
{
	#if not InCombat() ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}
	]]
	OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end


-- THE REST OF THIS FILE IS AUTOMATICALLY GENERATED.
-- ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.

do
	local name = "simulationcraft_paladin_protection_t19p"
	local desc = "[7.0] SimulationCraft: Paladin_Protection_T19P"
	local code = [[
# Based on SimulationCraft profile "Paladin_Protection_T19P".
#	class=paladin
#	spec=protection
#	talents=2231223

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default specialization=protection)

AddFunction ProtectionUsePotionStrength
{
	if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
}

AddFunction ProtectionUseItemActions
{
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction ProtectionDefaultMainActions
{
	#arcane_torrent
	#call_action_list,name=prot
	ProtectionProtMainActions()
}

AddFunction ProtectionDefaultMainPostConditions
{
	ProtectionProtMainPostConditions()
}

AddFunction ProtectionDefaultShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
	#arcane_torrent
	#call_action_list,name=prot
	ProtectionProtShortCdActions()
}

AddFunction ProtectionDefaultShortCdPostConditions
{
	ProtectionProtShortCdPostConditions()
}

AddFunction ProtectionDefaultCdActions
{
	#use_item,name=shivermaws_jawbone
	ProtectionUseItemActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent
	#call_action_list,name=prot
	ProtectionProtCdActions()
}

AddFunction ProtectionDefaultCdPostConditions
{
	ProtectionProtCdPostConditions()
}

### actions.max_dps

AddFunction ProtectionMaxDpsMainActions
{
}

AddFunction ProtectionMaxDpsMainPostConditions
{
}

AddFunction ProtectionMaxDpsShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
}

AddFunction ProtectionMaxDpsShortCdPostConditions
{
}

AddFunction ProtectionMaxDpsCdActions
{
	#use_item,name=shivermaws_jawbone
	ProtectionUseItemActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
}

AddFunction ProtectionMaxDpsCdPostConditions
{
}

### actions.max_survival

AddFunction ProtectionMaxSurvivalMainActions
{
}

AddFunction ProtectionMaxSurvivalMainPostConditions
{
}

AddFunction ProtectionMaxSurvivalShortCdActions
{
	#auto_attack
	ProtectionGetInMeleeRange()
}

AddFunction ProtectionMaxSurvivalShortCdPostConditions
{
}

AddFunction ProtectionMaxSurvivalCdActions
{
	#use_item,name=shivermaws_jawbone
	ProtectionUseItemActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
}

AddFunction ProtectionMaxSurvivalCdPostConditions
{
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
}

AddFunction ProtectionPrecombatMainPostConditions
{
}

AddFunction ProtectionPrecombatShortCdActions
{
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
}

AddFunction ProtectionPrecombatCdActions
{
}

AddFunction ProtectionPrecombatCdPostConditions
{
}

### actions.prot

AddFunction ProtectionProtMainActions
{
	#judgment
	Spell(judgment)
	#avengers_shield,if=talent.crusaders_judgment.enabled&buff.grand_crusader.up
	if Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) Spell(avengers_shield)
	#blessed_hammer
	Spell(blessed_hammer)
	#avengers_shield
	Spell(avengers_shield)
	#consecration
	Spell(consecration)
	#blinding_light
	Spell(blinding_light)
	#hammer_of_the_righteous
	Spell(hammer_of_the_righteous)
}

AddFunction ProtectionProtMainPostConditions
{
}

AddFunction ProtectionProtShortCdActions
{
	#seraphim,if=talent.seraphim.enabled&action.shield_of_the_righteous.charges>=2
	if Talent(seraphim_talent) and Charges(shield_of_the_righteous) >= 2 Spell(seraphim)
	#shield_of_the_righteous,if=(!talent.seraphim.enabled|action.shield_of_the_righteous.charges>2)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
	if { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&talent.seraphim.enabled&buff.seraphim.up&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
	if Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&!talent.seraphim.enabled&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
	if Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
	#light_of_the_protector,if=(health.pct<40)
	if HealthPercent() < 40 Spell(light_of_the_protector)
	#hand_of_the_protector,if=(health.pct<40)
	if HealthPercent() < 40 Spell(hand_of_the_protector)
	#light_of_the_protector,if=(incoming_damage_10000ms<health.max*1.25)&health.pct<55&talent.righteous_protector.enabled
	if IncomingDamage(10) < MaxHealth() * 1.25 and HealthPercent() < 55 and Talent(righteous_protector_talent) Spell(light_of_the_protector)
	#light_of_the_protector,if=(incoming_damage_13000ms<health.max*1.6)&health.pct<55
	if IncomingDamage(13) < MaxHealth() * 1.6 and HealthPercent() < 55 Spell(light_of_the_protector)
	#hand_of_the_protector,if=(incoming_damage_6000ms<health.max*0.7)&health.pct<65&talent.righteous_protector.enabled
	if IncomingDamage(6) < MaxHealth() * 0.7 and HealthPercent() < 65 and Talent(righteous_protector_talent) Spell(hand_of_the_protector)
	#hand_of_the_protector,if=(incoming_damage_9000ms<health.max*1.2)&health.pct<55
	if IncomingDamage(9) < MaxHealth() * 1.2 and HealthPercent() < 55 Spell(hand_of_the_protector)
}

AddFunction ProtectionProtShortCdPostConditions
{
	Spell(judgment) or Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or Spell(blessed_hammer) or Spell(avengers_shield) or Spell(consecration) or Spell(blinding_light) or Spell(hammer_of_the_righteous)
}

AddFunction ProtectionProtCdActions
{
	#bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
	if Talent(bastion_of_light_talent) and Charges(shield_of_the_righteous) < 1 Spell(bastion_of_light)
	#divine_steed,if=talent.knight_templar.enabled&incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(knight_templar_talent) and IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(divine_steed)
	#eye_of_tyr,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(eye_of_tyr)
	#aegis_of_light,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(aegis_of_light)
	#guardian_of_ancient_kings,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(guardian_of_ancient_kings)
	#divine_shield,if=talent.final_stand.enabled&incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(final_stand_talent) and IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(divine_shield)
	#ardent_defender,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(ardent_defender)
	#lay_on_hands,if=health.pct<15
	if HealthPercent() < 15 Spell(lay_on_hands)
	#potion,name=unbending_potion
	#potion,name=draenic_strength,if=incoming_damage_2500ms>health.max*0.4&&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)|target.time_to_die<=25
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_strength_buff) } or target.TimeToDie() <= 25 ProtectionUsePotionStrength()
	#stoneform,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if IncomingDamage(2.5) > MaxHealth() * 0.4 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_strength_buff) } Spell(stoneform)
	#avenging_wrath,if=!talent.seraphim.enabled
	if not Talent(seraphim_talent) Spell(avenging_wrath_melee)
	#avenging_wrath,if=talent.seraphim.enabled&buff.seraphim.up
	if Talent(seraphim_talent) and BuffPresent(seraphim_buff) Spell(avenging_wrath_melee)
}

AddFunction ProtectionProtCdPostConditions
{
	Spell(judgment) or Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or Spell(blessed_hammer) or Spell(avengers_shield) or Spell(consecration) or Spell(blinding_light) or Spell(hammer_of_the_righteous)
}

### Protection icons.

AddCheckBox(opt_paladin_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=shortcd specialization=protection
{
	if not InCombat() ProtectionPrecombatShortCdActions()
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		ProtectionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_paladin_protection_aoe help=shortcd specialization=protection
{
	if not InCombat() ProtectionPrecombatShortCdActions()
	unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
	{
		ProtectionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	unless not InCombat() and ProtectionPrecombatMainPostConditions()
	{
		ProtectionDefaultMainActions()
	}
}

AddIcon checkbox=opt_paladin_protection_aoe help=aoe specialization=protection
{
	if not InCombat() ProtectionPrecombatMainActions()
	unless not InCombat() and ProtectionPrecombatMainPostConditions()
	{
		ProtectionDefaultMainActions()
	}
}

AddIcon checkbox=!opt_paladin_protection_aoe enemies=1 help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		ProtectionDefaultCdActions()
	}
}

AddIcon checkbox=opt_paladin_protection_aoe help=cd specialization=protection
{
	if not InCombat() ProtectionPrecombatCdActions()
	unless not InCombat() and ProtectionPrecombatCdPostConditions()
	{
		ProtectionDefaultCdActions()
	}
}

### Required symbols
# aegis_of_light
# aegis_of_light_buff
# ardent_defender
# ardent_defender_buff
# avengers_shield
# avenging_wrath_melee
# bastion_of_light
# bastion_of_light_talent
# berserking
# blessed_hammer
# blinding_light
# blood_fury_apsp
# consecration
# crusaders_judgment_talent
# divine_shield
# divine_shield_buff
# divine_steed
# draenic_strength_potion
# eye_of_tyr
# eye_of_tyr_debuff
# final_stand_talent
# grand_crusader_buff
# guardian_of_ancient_kings
# guardian_of_ancient_kings_buff
# hammer_of_the_righteous
# hand_of_the_protector
# judgment
# knight_templar_talent
# lay_on_hands
# light_of_the_protector
# potion_buff
# potion_strength_buff
# rebuke
# righteous_protector_talent
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
# stoneform
]]
	OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end

do
	local name = "simulationcraft_paladin_retribution_t19p"
	local desc = "[7.0] SimulationCraft: Paladin_Retribution_T19P"
	local code = [[
# Based on SimulationCraft profile "Paladin_Retribution_T19P".
#	class=paladin
#	spec=retribution
#	talents=2212212

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=retribution)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=retribution)

AddFunction RetributionUseItemActions
{
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction RetributionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction RetributionInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if target.InRange(avengers_shield) Spell(avengers_shield)
		if not target.Classification(worldboss)
		{
			if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			if target.Distance(less 10) Spell(blinding_light)
			if target.Distance(less 8) Spell(arcane_torrent_holy)
			if target.Distance(less 8) Spell(war_stomp)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction RetributionDefaultMainActions
{
	#judgment,if=time<2
	if TimeInCombat() < 2 Spell(judgment)
	#blade_of_justice,if=time<2&(equipped.137048|race.blood_elf)
	if TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } Spell(blade_of_justice)
	#divine_hammer,if=time<2&(equipped.137048|race.blood_elf)
	if TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } Spell(divine_hammer)
	#wake_of_ashes,if=holy_power<=1&time<2
	if HolyPower() <= 1 and TimeInCombat() < 2 Spell(wake_of_ashes)
	#execution_sentence,if=spell_targets.divine_storm<=3&(cooldown.judgment.remains<gcd*4.5|debuff.judgment.remains>gcd*4.67)&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
	if Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4.5 or target.DebuffRemaining(judgment_debuff) > GCD() * 4.67 } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } Spell(execution_sentence)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&buff.divine_purpose.up&buff.divine_purpose.remains<gcd*2
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 Spell(divine_storm)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&holy_power>=5&buff.divine_purpose.react
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) Spell(divine_storm)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&holy_power>=3&buff.crusade.up&(buff.crusade.stack<15|buff.bloodlust.up)
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } Spell(divine_storm)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&holy_power>=5&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*3)
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } Spell(divine_storm)
	#templars_verdict,if=debuff.judgment.up&buff.divine_purpose.up&buff.divine_purpose.remains<gcd*2
	if target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 Spell(templars_verdict)
	#templars_verdict,if=debuff.judgment.up&holy_power>=5&buff.divine_purpose.react
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#templars_verdict,if=debuff.judgment.up&holy_power>=3&buff.crusade.up&(buff.crusade.stack<15|buff.bloodlust.up)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } Spell(templars_verdict)
	#templars_verdict,if=debuff.judgment.up&holy_power>=5&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*3)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } Spell(templars_verdict)
	#divine_storm,if=debuff.judgment.up&holy_power>=3&spell_targets.divine_storm>=2&(cooldown.wake_of_ashes.remains<gcd*2&artifact.wake_of_ashes.enabled|buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains<gcd)&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*4)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } Spell(divine_storm)
	#templars_verdict,if=debuff.judgment.up&holy_power>=3&(cooldown.wake_of_ashes.remains<gcd*2&artifact.wake_of_ashes.enabled|buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains<gcd)&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*4)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } Spell(templars_verdict)
	#wake_of_ashes,if=holy_power=0|holy_power=1&(cooldown.blade_of_justice.remains>gcd|cooldown.divine_hammer.remains>gcd)|holy_power=2&(cooldown.zeal.charges_fractional<=0.65|cooldown.crusader_strike.charges_fractional<=0.65)
	if HolyPower() == 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0.65 or SpellCharges(crusader_strike count=0) <= 0.65 } Spell(wake_of_ashes)
	#blade_of_justice,if=holy_power<=3&buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains>gcd&buff.whisper_of_the_nathrezim.remains<gcd*3&debuff.judgment.up&debuff.judgment.remains>gcd*2
	if HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 Spell(blade_of_justice)
	#divine_hammer,if=holy_power<=3&buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains>gcd&buff.whisper_of_the_nathrezim.remains<gcd*3&debuff.judgment.up&debuff.judgment.remains>gcd*2
	if HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 Spell(divine_hammer)
	#blade_of_justice,if=talent.blade_of_wrath.enabled&holy_power<=3
	if Talent(blade_of_wrath_talent) and HolyPower() <= 3 Spell(blade_of_justice)
	#zeal,if=charges=2&holy_power<=4
	if Charges(zeal) == 2 and HolyPower() <= 4 Spell(zeal)
	#crusader_strike,if=charges=2&holy_power<=4
	if Charges(crusader_strike) == 2 and HolyPower() <= 4 Spell(crusader_strike)
	#blade_of_justice,if=holy_power<=2|(holy_power<=3&(cooldown.zeal.charges_fractional<=1.34|cooldown.crusader_strike.charges_fractional<=1.34))
	if HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } Spell(blade_of_justice)
	#divine_hammer,if=holy_power<=2|(holy_power<=3&(cooldown.zeal.charges_fractional<=1.34|cooldown.crusader_strike.charges_fractional<=1.34))
	if HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } Spell(divine_hammer)
	#judgment,if=holy_power>=3|((cooldown.zeal.charges_fractional<=1.67|cooldown.crusader_strike.charges_fractional<=1.67)&(cooldown.divine_hammer.remains>gcd|cooldown.blade_of_justice.remains>gcd))|(talent.greater_judgment.enabled&target.health.pct>50)
	if HolyPower() >= 3 or { SpellCharges(zeal count=0) <= 1.67 or SpellCharges(crusader_strike count=0) <= 1.67 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } or Talent(greater_judgment_talent) and target.HealthPercent() > 50 Spell(judgment)
	#consecration
	Spell(consecration)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&buff.divine_purpose.react
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) Spell(divine_storm)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&buff.the_fires_of_justice.react&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*3)
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } Spell(divine_storm)
	#divine_storm,if=debuff.judgment.up&spell_targets.divine_storm>=2&(holy_power>=4|((cooldown.zeal.charges_fractional<=1.34|cooldown.crusader_strike.charges_fractional<=1.34)&(cooldown.divine_hammer.remains>gcd|cooldown.blade_of_justice.remains>gcd)))&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*4)
	if target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } Spell(divine_storm)
	#templars_verdict,if=debuff.judgment.up&buff.divine_purpose.react
	if target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) Spell(templars_verdict)
	#templars_verdict,if=debuff.judgment.up&buff.the_fires_of_justice.react&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*3)
	if target.DebuffPresent(judgment_debuff) and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } Spell(templars_verdict)
	#templars_verdict,if=debuff.judgment.up&(holy_power>=4|((cooldown.zeal.charges_fractional<=1.34|cooldown.crusader_strike.charges_fractional<=1.34)&(cooldown.divine_hammer.remains>gcd|cooldown.blade_of_justice.remains>gcd)))&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*4)
	if target.DebuffPresent(judgment_debuff) and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } Spell(templars_verdict)
	#zeal,if=holy_power<=4
	if HolyPower() <= 4 Spell(zeal)
	#crusader_strike,if=holy_power<=4
	if HolyPower() <= 4 Spell(crusader_strike)
	#divine_storm,if=debuff.judgment.up&holy_power>=3&spell_targets.divine_storm>=2&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*5)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } Spell(divine_storm)
	#templars_verdict,if=debuff.judgment.up&holy_power>=3&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*5)
	if target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } Spell(templars_verdict)
}

AddFunction RetributionDefaultMainPostConditions
{
}

AddFunction RetributionDefaultShortCdActions
{
	#auto_attack
	RetributionGetInMeleeRange()

	unless TimeInCombat() < 2 and Spell(judgment) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(blade_of_justice) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(divine_hammer) or HolyPower() <= 1 and TimeInCombat() < 2 and Spell(wake_of_ashes)
	{
		#shield_of_vengeance
		Spell(shield_of_vengeance)
	}
}

AddFunction RetributionDefaultShortCdPostConditions
{
	TimeInCombat() < 2 and Spell(judgment) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(blade_of_justice) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(divine_hammer) or HolyPower() <= 1 and TimeInCombat() < 2 and Spell(wake_of_ashes) or Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4.5 or target.DebuffRemaining(judgment_debuff) > GCD() * 4.67 } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(execution_sentence) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(templars_verdict) or { HolyPower() == 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0.65 or SpellCharges(crusader_strike count=0) <= 0.65 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 and Spell(blade_of_justice) or HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 and Spell(divine_hammer) or Talent(blade_of_wrath_talent) and HolyPower() <= 3 and Spell(blade_of_justice) or Charges(zeal) == 2 and HolyPower() <= 4 and Spell(zeal) or Charges(crusader_strike) == 2 and HolyPower() <= 4 and Spell(crusader_strike) or { HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } } and Spell(divine_hammer) or { HolyPower() >= 3 or { SpellCharges(zeal count=0) <= 1.67 or SpellCharges(crusader_strike count=0) <= 1.67 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } or Talent(greater_judgment_talent) and target.HealthPercent() > 50 } and Spell(judgment) or Spell(consecration) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(templars_verdict) or HolyPower() <= 4 and Spell(zeal) or HolyPower() <= 4 and Spell(crusader_strike) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } and Spell(templars_verdict)
}

AddFunction RetributionDefaultCdActions
{
	#rebuke
	RetributionInterruptActions()
	#potion,name=old_war,if=(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25|target.time_to_die<=40)
	#use_item,name=faulty_countermeasure,if=(buff.avenging_wrath.up|buff.crusade.up)
	if BuffPresent(avenging_wrath_melee_buff) or BuffPresent(crusade_buff) RetributionUseItemActions()
	#blood_fury
	Spell(blood_fury_apsp)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=holy_power<5&(buff.crusade.up|buff.avenging_wrath.up|time<2)
	if HolyPower() < 5 and { BuffPresent(crusade_buff) or BuffPresent(avenging_wrath_melee_buff) or TimeInCombat() < 2 } Spell(arcane_torrent_holy)

	unless TimeInCombat() < 2 and Spell(judgment) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(blade_of_justice) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(divine_hammer) or HolyPower() <= 1 and TimeInCombat() < 2 and Spell(wake_of_ashes)
	{
		#holy_wrath
		Spell(holy_wrath)
		#avenging_wrath
		Spell(avenging_wrath_melee)

		unless Spell(shield_of_vengeance)
		{
			#crusade,if=holy_power>=5&!equipped.137048|((equipped.137048|race.blood_elf)&time<2|time>2&holy_power>=4)
			if HolyPower() >= 5 and not HasEquippedItem(137048) or { HasEquippedItem(137048) or Race(BloodElf) } and TimeInCombat() < 2 or TimeInCombat() > 2 and HolyPower() >= 4 Spell(crusade)
		}
	}
}

AddFunction RetributionDefaultCdPostConditions
{
	TimeInCombat() < 2 and Spell(judgment) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(blade_of_justice) or TimeInCombat() < 2 and { HasEquippedItem(137048) or Race(BloodElf) } and Spell(divine_hammer) or HolyPower() <= 1 and TimeInCombat() < 2 and Spell(wake_of_ashes) or Spell(shield_of_vengeance) or Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4.5 or target.DebuffRemaining(judgment_debuff) > GCD() * 4.67 } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(execution_sentence) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) and BuffRemaining(divine_purpose_buff) < GCD() * 2 and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and BuffPresent(crusade_buff) and { BuffStacks(crusade_buff) < 15 or BuffPresent(burst_haste_buff any=1) } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 5 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { SpellCooldown(wake_of_ashes) < GCD() * 2 and HasArtifactTrait(wake_of_ashes) or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(templars_verdict) or { HolyPower() == 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0.65 or SpellCharges(crusader_strike count=0) <= 0.65 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 and Spell(blade_of_justice) or HolyPower() <= 3 and BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) > GCD() and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 3 and target.DebuffPresent(judgment_debuff) and target.DebuffRemaining(judgment_debuff) > GCD() * 2 and Spell(divine_hammer) or Talent(blade_of_wrath_talent) and HolyPower() <= 3 and Spell(blade_of_justice) or Charges(zeal) == 2 and HolyPower() <= 4 and Spell(zeal) or Charges(crusader_strike) == 2 and HolyPower() <= 4 and Spell(crusader_strike) or { HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 3 and { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } } and Spell(divine_hammer) or { HolyPower() >= 3 or { SpellCharges(zeal count=0) <= 1.67 or SpellCharges(crusader_strike count=0) <= 1.67 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } or Talent(greater_judgment_talent) and target.HealthPercent() > 50 } and Spell(judgment) or Spell(consecration) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and Enemies() >= 2 and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and BuffPresent(the_fires_of_justice_buff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 3 } and Spell(templars_verdict) or target.DebuffPresent(judgment_debuff) and { HolyPower() >= 4 or { SpellCharges(zeal count=0) <= 1.34 or SpellCharges(crusader_strike count=0) <= 1.34 } and { SpellCooldown(divine_hammer) > GCD() or SpellCooldown(blade_of_justice) > GCD() } } and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 4 } and Spell(templars_verdict) or HolyPower() <= 4 and Spell(zeal) or HolyPower() <= 4 and Spell(crusader_strike) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and Enemies() >= 2 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } and Spell(divine_storm) or target.DebuffPresent(judgment_debuff) and HolyPower() >= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 5 } and Spell(templars_verdict)
}

### actions.precombat

AddFunction RetributionPrecombatMainActions
{
	#flask,type=flask_of_the_countless_armies
	#food,type=azshari_salad
	#augmentation,type=defiled
	Spell(augmentation)
}

AddFunction RetributionPrecombatMainPostConditions
{
}

AddFunction RetributionPrecombatShortCdActions
{
}

AddFunction RetributionPrecombatShortCdPostConditions
{
	Spell(augmentation)
}

AddFunction RetributionPrecombatCdActions
{
}

AddFunction RetributionPrecombatCdPostConditions
{
	Spell(augmentation)
}

### Retribution icons.

AddCheckBox(opt_paladin_retribution_aoe L(AOE) default specialization=retribution)

AddIcon checkbox=!opt_paladin_retribution_aoe enemies=1 help=shortcd specialization=retribution
{
	if not InCombat() RetributionPrecombatShortCdActions()
	unless not InCombat() and RetributionPrecombatShortCdPostConditions()
	{
		RetributionDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_paladin_retribution_aoe help=shortcd specialization=retribution
{
	if not InCombat() RetributionPrecombatShortCdActions()
	unless not InCombat() and RetributionPrecombatShortCdPostConditions()
	{
		RetributionDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=retribution
{
	if not InCombat() RetributionPrecombatMainActions()
	unless not InCombat() and RetributionPrecombatMainPostConditions()
	{
		RetributionDefaultMainActions()
	}
}

AddIcon checkbox=opt_paladin_retribution_aoe help=aoe specialization=retribution
{
	if not InCombat() RetributionPrecombatMainActions()
	unless not InCombat() and RetributionPrecombatMainPostConditions()
	{
		RetributionDefaultMainActions()
	}
}

AddIcon checkbox=!opt_paladin_retribution_aoe enemies=1 help=cd specialization=retribution
{
	if not InCombat() RetributionPrecombatCdActions()
	unless not InCombat() and RetributionPrecombatCdPostConditions()
	{
		RetributionDefaultCdActions()
	}
}

AddIcon checkbox=opt_paladin_retribution_aoe help=cd specialization=retribution
{
	if not InCombat() RetributionPrecombatCdActions()
	unless not InCombat() and RetributionPrecombatCdPostConditions()
	{
		RetributionDefaultCdActions()
	}
}

### Required symbols
# 137048
# arcane_torrent_holy
# augmentation
# avenging_wrath_melee
# avenging_wrath_melee_buff
# berserking
# blade_of_justice
# blade_of_wrath_talent
# blinding_light
# blood_fury_apsp
# consecration
# crusade
# crusade_buff
# crusade_talent
# crusader_strike
# divine_hammer
# divine_purpose_buff
# divine_storm
# execution_sentence
# greater_judgment_talent
# hammer_of_justice
# holy_wrath
# judgment
# judgment_debuff
# quaking_palm
# rebuke
# shield_of_vengeance
# templars_verdict
# the_fires_of_justice_buff
# wake_of_ashes
# war_stomp
# whisper_of_the_nathrezim_buff
# zeal
]]
	OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
end
