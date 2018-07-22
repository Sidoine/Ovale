import { OvaleScripts } from "../Scripts";
{
    let name = "icyveins_paladin_protection";
    let desc = "[7.3.2] Icy-Veins: Paladin Protection";
    let code = `
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=protection)

AddFunction ProtectionSelfHealCondition
{
	(HealthPercent() < 40)
		or (IncomingDamage(10) < MaxHealth() * 1.25 and HealthPercent() < 55 and Talent(righteous_protector_talent))
		or (IncomingDamage(13) < MaxHealth() * 1.6 and HealthPercent() < 55)
		or (IncomingDamage(6) < MaxHealth() * 0.7 and HealthPercent() < 65 and Talent(righteous_protector_talent))
		or (IncomingDamage(9) < MaxHealth() * 1.2 and HealthPercent() < 55)
		or (HealthPercent() < 60 and HasEquippedItem(saruans_resolve) and (SpellCharges(light_of_the_protector) >= 2 or SpellCharges(hand_of_the_protector) >= 2))
}

AddFunction PaladinHealMe
{
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if ProtectionSelfHealCondition() Spell(light_of_the_protector)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction ProtectionHasProtectiveCooldown
{
	target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff)
}

AddFunction ProtectionCooldownTreshold
{
	HealthPercent() <= 100 and not ProtectionHasProtectiveCooldown()
}

AddFunction ProtectionGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(shield_of_the_righteous) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionDefaultShortCDActions
{
	PaladinHealMe()
	#bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
	if Talent(bastion_of_light_talent) and Charges(shield_of_the_righteous) < 1 Spell(bastion_of_light)
	#seraphim,if=talent.seraphim.enabled&action.shield_of_the_righteous.charges>=2
	if Talent(seraphim_talent) and Charges(shield_of_the_righteous) >= 2 Spell(seraphim)

	ProtectionGetInMeleeRange()
	
	#max sotr charges
	if (Charges(shield_of_the_righteous) >= SpellMaxCharges(shield_of_the_righteous)) Spell(shield_of_the_righteous text=max)
	#shield_of_the_righteous,if=(!talent.seraphim.enabled|action.shield_of_the_righteous.charges>2)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not ProtectionHasProtectiveCooldown() Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&talent.seraphim.enabled&buff.seraphim.up&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not ProtectionHasProtectiveCooldown() Spell(shield_of_the_righteous)
	#shield_of_the_righteous,if=(talent.bastion_of_light.enabled&!talent.seraphim.enabled&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
	if Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not ProtectionHasProtectiveCooldown() Spell(shield_of_the_righteous)
	
	if (Charges(shield_of_the_righteous) <= 0 and BuffRemaining(shield_of_the_righteous_buff) <= 0) and ProtectionCooldownTreshold()
	{
		Spell(eye_of_tyr)
		Spell(divine_protection)
		Spell(ardent_defender)
	}
}

AddFunction ProtectionDefaultMainActions
{
	if Speed() == 0 and HasEquippedItem(heathcliffs_immortality) and not BuffPresent(consecration_buff) Spell(consecration)
	if Talent(blessed_hammer_talent) and (not PreviousGCDSpell(blessed_hammer) or Charges(blessed_hammer) == SpellMaxCharges(blessed_hammer)) Spell(blessed_hammer)
	Spell(judgment)
	if Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) Spell(avengers_shield)
	if Speed() == 0 and not Talent(consecrated_hammer_talent) and not BuffPresent(consecration_buff) Spell(consecration)
	Spell(avengers_shield)
	if Speed() == 0 Spell(consecration)
	Spell(hammer_of_the_righteous)
}

AddFunction ProtectionDefaultAoEActions
{
	if Speed() == 0 and HasEquippedItem(heathcliffs_immortality) and not BuffPresent(consecration_buff) Spell(consecration)
	Spell(avengers_shield)
	if Speed() == 0 and not Talent(consecrated_hammer_talent) and not BuffPresent(consecration_buff) Spell(consecration)
	if Talent(blessed_hammer_talent) Spell(blessed_hammer)
	Spell(judgment)
	if Speed() == 0 Spell(consecration)
	Spell(hammer_of_the_righteous)
}

AddCheckBox(opt_avenging_wrath SpellName(avenging_wrath_melee) default specialization=protection)
AddFunction ProtectionDefaultCdActions
{
	ProtectionInterruptActions()
	if CheckBoxOn(opt_avenging_wrath) and (not Talent(seraphim_talent) or BuffPresent(seraphim_buff)) Spell(avenging_wrath_melee)
	
	if (ProtectionCooldownTreshold() and HasEquippedItem(shifting_cosmic_sliver)) Spell(guardian_of_ancient_kings)
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	
	if ProtectionCooldownTreshold() Spell(eye_of_tyr)
	if ProtectionCooldownTreshold() Spell(divine_protection)
	if ProtectionCooldownTreshold() Spell(ardent_defender)
	if ProtectionCooldownTreshold() Spell(guardian_of_ancient_kings)
	if ProtectionCooldownTreshold() Spell(aegis_of_light)
	if ProtectionCooldownTreshold() and Talent(final_stand_talent) Spell(divine_shield)
	if not DebuffPresent(forbearance_debuff) and HealthPercent() < 15 Spell(lay_on_hands)

	if Talent(knight_templar_talent) and ProtectionCooldownTreshold() Spell(divine_steed)
	if ProtectionCooldownTreshold() and CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	if ProtectionCooldownTreshold() UseRacialSurvivalActions()
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
	`;
    OvaleScripts.RegisterScript("PALADIN", "protection", name, desc, code, "script");
}
{
    let name = "icyveins_paladin_holy";
    let desc = "[7.2.5] Icy-Veins: Paladin Holy";
    let code = `
	
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=holy)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=holy)

AddFunction HolyGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(crusader_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction HolyDefaultHealActions
{
	Spell(holy_shock)
	Spell(bestow_faith)
	if BuffPresent(infusion_of_light_buff) Spell(flash_of_light)
	Spell(holy_light)
}

AddFunction HolyDefaultAoeHealActions
{
	Spell(holy_shock)
	Spell(lights_hammer)
	if Talent(judgment_of_light_talent) and DebuffCountOnAny(judgement_of_light_debuff) == 0 Spell(judgment)
	if Talent(beacon_of_virtue_talent) Spell(beacon_of_virtue)
	Spell(holy_prism)
	Spell(light_of_dawn)
	HolyDefaultHealActions()
}

AddFunction HolyDefaultMainActions
{
	Spell(judgment)
	Spell(holy_shock)
	HolyGetInMeleeRange()
	Spell(crusader_strike)
	if target.Distance() <= 5 Spell(consecration)
	Spell(lights_hammer)
}

AddFunction HolyDefaultCdActions
{
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(tyrs_deliverance)
	Spell(avenging_wrath_heal)
	Spell(holy_avenger)
	Spell(aura_mastery)
}

AddIcon enemies=1 help=main specialization=holy
{
	HolyDefaultMainActions()
}

AddIcon help=mainheal specialization=holy
{
	HolyDefaultHealActions()
}

AddIcon help=aoeheal specialization=holy
{
	HolyDefaultAoeHealActions()
}

AddIcon help=cd specialization=holy
{
	HolyDefaultCdActions()
}

	`;
    OvaleScripts.RegisterScript("PALADIN", "holy", name, desc, code, "script");
}
// THE REST OF THIS FILE IS AUTOMATICALLY GENERATED
// ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.

{
	const name = "sc_paladin_protection_t19"
	const desc = "[7.0] Simulationcraft: Paladin_Protection_T19"
	const code = `
# Based on SimulationCraft profile "Paladin_Protection_T19P".
#	class=paladin
#	spec=protection
#	talents=2231223

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=protection)

AddFunction ProtectionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.prot

AddFunction ProtectionProtMainActions
{
 #shield_of_the_righteous,if=(!talent.seraphim.enabled|action.shield_of_the_righteous.charges>2)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
 if { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
 #shield_of_the_righteous,if=(talent.bastion_of_light.enabled&talent.seraphim.enabled&buff.seraphim.up&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
 if Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
 #shield_of_the_righteous,if=(talent.bastion_of_light.enabled&!talent.seraphim.enabled&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up&buff.aegis_of_light.up&buff.ardent_defender.up&buff.guardian_of_ancient_kings.up&buff.divine_shield.up&buff.potion.up)
 if Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } Spell(shield_of_the_righteous)
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

 unless { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous)
 {
  #light_of_the_protector,if=(health.pct<40)
  if HealthPercent() < 40 Spell(light_of_the_protector)
  #hand_of_the_protector,if=(health.pct<40)
  if HealthPercent() < 40 Spell(hand_of_the_protector)
  #light_of_the_protector,if=(incoming_damage_10000ms<health.max*1.25)&health.pct<55&talent.righteous_protector.enabled
  if IncomingDamage(10) < MaxHealth() * 1 and HealthPercent() < 55 and Talent(righteous_protector_talent) Spell(light_of_the_protector)
  #light_of_the_protector,if=(incoming_damage_13000ms<health.max*1.6)&health.pct<55
  if IncomingDamage(13) < MaxHealth() * 1 and HealthPercent() < 55 Spell(light_of_the_protector)
  #hand_of_the_protector,if=(incoming_damage_6000ms<health.max*0.7)&health.pct<65&talent.righteous_protector.enabled
  if IncomingDamage(6) < MaxHealth() * 0 and HealthPercent() < 65 and Talent(righteous_protector_talent) Spell(hand_of_the_protector)
  #hand_of_the_protector,if=(incoming_damage_9000ms<health.max*1.2)&health.pct<55
  if IncomingDamage(9) < MaxHealth() * 1 and HealthPercent() < 55 Spell(hand_of_the_protector)
 }
}

AddFunction ProtectionProtShortCdPostConditions
{
 { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Spell(judgment) or Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or Spell(blessed_hammer) or Spell(avengers_shield) or Spell(consecration) or Spell(hammer_of_the_righteous)
}

AddFunction ProtectionProtCdActions
{
 unless Talent(seraphim_talent) and Charges(shield_of_the_righteous) >= 2 and Spell(seraphim) or { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous)
 {
  #bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
  if Talent(bastion_of_light_talent) and Charges(shield_of_the_righteous) < 1 Spell(bastion_of_light)

  unless HealthPercent() < 40 and Spell(light_of_the_protector) or HealthPercent() < 40 and Spell(hand_of_the_protector) or IncomingDamage(10) < MaxHealth() * 1 and HealthPercent() < 55 and Talent(righteous_protector_talent) and Spell(light_of_the_protector) or IncomingDamage(13) < MaxHealth() * 1 and HealthPercent() < 55 and Spell(light_of_the_protector) or IncomingDamage(6) < MaxHealth() * 0 and HealthPercent() < 65 and Talent(righteous_protector_talent) and Spell(hand_of_the_protector) or IncomingDamage(9) < MaxHealth() * 1 and HealthPercent() < 55 and Spell(hand_of_the_protector)
  {
   #divine_steed,if=talent.knight_templar.enabled&incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if Talent(knight_templar_talent) and IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(divine_steed)
   #eye_of_tyr,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(eye_of_tyr)
   #aegis_of_light,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(aegis_of_light)
   #guardian_of_ancient_kings,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(guardian_of_ancient_kings)
   #divine_shield,if=talent.final_stand.enabled&incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if Talent(final_stand_talent) and IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(divine_shield)
   #ardent_defender,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(ardent_defender)
   #lay_on_hands,if=health.pct<15
   if HealthPercent() < 15 Spell(lay_on_hands)
   #potion,name=unbending_potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(unbending_potion usable=1)
   #potion,name=draenic_strength,if=incoming_damage_2500ms>health.max*0.4&&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)|target.time_to_die<=25
   if { IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } or target.TimeToDie() <= 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
   #stoneform,if=incoming_damage_2500ms>health.max*0.4&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
   if IncomingDamage(2) > MaxHealth() * 0 and not { target.DebuffPresent(eye_of_tyr_debuff) or BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff) } Spell(stoneform)
   #avenging_wrath,if=!talent.seraphim.enabled
   if not Talent(seraphim_talent) Spell(avenging_wrath_melee)
   #avenging_wrath,if=talent.seraphim.enabled&buff.seraphim.up
   if Talent(seraphim_talent) and BuffPresent(seraphim_buff) Spell(avenging_wrath_melee)

   unless Spell(judgment) or Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or Spell(blessed_hammer) or Spell(avengers_shield) or Spell(consecration)
   {
    #blinding_light
    Spell(blinding_light)
   }
  }
 }
}

AddFunction ProtectionProtCdPostConditions
{
 Talent(seraphim_talent) and Charges(shield_of_the_righteous) >= 2 and Spell(seraphim) or { not Talent(seraphim_talent) or Charges(shield_of_the_righteous) > 2 } and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and not SpellCooldown(bastion_of_light) > 0 and not { target.DebuffPresent(eye_of_tyr_debuff) and BuffPresent(aegis_of_light_buff) and BuffPresent(ardent_defender_buff) and BuffPresent(guardian_of_ancient_kings_buff) and BuffPresent(divine_shield_buff) and BuffPresent(potion_buff) } and Spell(shield_of_the_righteous) or HealthPercent() < 40 and Spell(light_of_the_protector) or HealthPercent() < 40 and Spell(hand_of_the_protector) or IncomingDamage(10) < MaxHealth() * 1 and HealthPercent() < 55 and Talent(righteous_protector_talent) and Spell(light_of_the_protector) or IncomingDamage(13) < MaxHealth() * 1 and HealthPercent() < 55 and Spell(light_of_the_protector) or IncomingDamage(6) < MaxHealth() * 0 and HealthPercent() < 65 and Talent(righteous_protector_talent) and Spell(hand_of_the_protector) or IncomingDamage(9) < MaxHealth() * 1 and HealthPercent() < 55 and Spell(hand_of_the_protector) or Spell(judgment) or Talent(crusaders_judgment_talent) and BuffPresent(grand_crusader_buff) and Spell(avengers_shield) or Spell(blessed_hammer) or Spell(avengers_shield) or Spell(consecration) or Spell(hammer_of_the_righteous)
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
 #flask,type=flask_of_ten_thousand_scars
 #flask,type=flask_of_the_countless_armies,if=role.attack|using_apl.max_dps
 #food,type=seedbattered_fish_plate
 #food,type=azshari_salad,if=role.attack|using_apl.max_dps
 #snapshot_stats
 #potion,name=unbending_potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(unbending_potion usable=1)
}

AddFunction ProtectionPrecombatCdPostConditions
{
}

### actions.max_survival

AddFunction ProtectionMaxsurvivalMainActions
{
}

AddFunction ProtectionMaxsurvivalMainPostConditions
{
}

AddFunction ProtectionMaxsurvivalShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()
}

AddFunction ProtectionMaxsurvivalShortCdPostConditions
{
}

AddFunction ProtectionMaxsurvivalCdActions
{
 #use_item,name=shivermaws_jawbone
 ProtectionUseItemActions()
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
}

AddFunction ProtectionMaxsurvivalCdPostConditions
{
}

### actions.max_dps

AddFunction ProtectionMaxdpsMainActions
{
}

AddFunction ProtectionMaxdpsMainPostConditions
{
}

AddFunction ProtectionMaxdpsShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()
}

AddFunction ProtectionMaxdpsShortCdPostConditions
{
}

AddFunction ProtectionMaxdpsCdActions
{
 #use_item,name=shivermaws_jawbone
 ProtectionUseItemActions()
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
}

AddFunction ProtectionMaxdpsCdPostConditions
{
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
# seraphim
# seraphim_talent
# shield_of_the_righteous
# eye_of_tyr_debuff
# aegis_of_light_buff
# ardent_defender_buff
# guardian_of_ancient_kings_buff
# divine_shield_buff
# potion_buff
# bastion_of_light_talent
# seraphim_buff
# bastion_of_light
# light_of_the_protector
# hand_of_the_protector
# righteous_protector_talent
# divine_steed
# knight_templar_talent
# eye_of_tyr
# aegis_of_light
# guardian_of_ancient_kings
# divine_shield
# final_stand_talent
# ardent_defender
# lay_on_hands
# unbending_potion
# draenic_strength_potion
# stoneform
# avenging_wrath_melee
# judgment
# avengers_shield
# crusaders_judgment_talent
# grand_crusader_buff
# blessed_hammer
# consecration
# blinding_light
# hammer_of_the_righteous
# blood_fury_apsp
# berserking
# rebuke
`
	OvaleScripts.RegisterScript("PALADIN", "protection", name, desc, code, "script")
}

{
	const name = "sc_paladin_retribution_t21"
	const desc = "[8.0] Simulationcraft: Paladin_Retribution_T21"
	const code = `
# Based on SimulationCraft profile "T21_Paladin_Retribution".
#    class=paladin
#    spec=retribution
#    talents=2303003

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)


AddFunction ds_castable
{
 Enemies() >= 3 or Talent(divine_judgment_talent) and Enemies() >= 2 or HasAzeriteTrait(divine_right) and target.HealthPercent() <= 20 and BuffExpires(divine_right_buff)
}

AddFunction HoW
{
 not Talent(hammer_of_wrath_talent) or target.HealthPercent() >= 20 and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=retribution)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=retribution)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=retribution)

AddFunction RetributionInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
  if target.InRange(hammer_of_justice) and not target.Classification(worldboss) Spell(hammer_of_justice)
  if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_holy)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction RetributionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.default

AddFunction RetributionDefaultMainActions
{
 #call_action_list,name=cooldowns
 RetributionCooldownsMainActions()

 unless RetributionCooldownsMainPostConditions()
 {
  #call_action_list,name=generators
  RetributionGeneratorsMainActions()
 }
}

AddFunction RetributionDefaultMainPostConditions
{
 RetributionCooldownsMainPostConditions() or RetributionGeneratorsMainPostConditions()
}

AddFunction RetributionDefaultShortCdActions
{
 #auto_attack
 RetributionGetInMeleeRange()
 #call_action_list,name=cooldowns
 RetributionCooldownsShortCdActions()

 unless RetributionCooldownsShortCdPostConditions()
 {
  #call_action_list,name=generators
  RetributionGeneratorsShortCdActions()
 }
}

AddFunction RetributionDefaultShortCdPostConditions
{
 RetributionCooldownsShortCdPostConditions() or RetributionGeneratorsShortCdPostConditions()
}

AddFunction RetributionDefaultCdActions
{
 #rebuke
 RetributionInterruptActions()
 #call_action_list,name=cooldowns
 RetributionCooldownsCdActions()

 unless RetributionCooldownsCdPostConditions()
 {
  #call_action_list,name=generators
  RetributionGeneratorsCdActions()
 }
}

AddFunction RetributionDefaultCdPostConditions
{
 RetributionCooldownsCdPostConditions() or RetributionGeneratorsCdPostConditions()
}

### actions.cooldowns

AddFunction RetributionCooldownsMainActions
{
}

AddFunction RetributionCooldownsMainPostConditions
{
}

AddFunction RetributionCooldownsShortCdActions
{
 #shield_of_vengeance
 Spell(shield_of_vengeance)
}

AddFunction RetributionCooldownsShortCdPostConditions
{
}

AddFunction RetributionCooldownsCdActions
{
 #potion,if=(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25|target.time_to_die<=40)
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 or target.TimeToDie() <= 40 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
 #lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
 if Enemies() >= 2 or not False(raid_event_adds_exists) or 600 > 75 Spell(lights_judgment)

 unless Spell(shield_of_vengeance)
 {
  #avenging_wrath,if=buff.inquisition.up|!talent.inquisition.enabled
  if BuffPresent(inquisition_buff) or not Talent(inquisition_talent) Spell(avenging_wrath)
  #crusade,if=holy_power>=4
  if HolyPower() >= 4 Spell(crusade)
 }
}

AddFunction RetributionCooldownsCdPostConditions
{
 Spell(shield_of_vengeance)
}

### actions.finishers

AddFunction RetributionFinishersMainActions
{
 #variable,name=ds_castable,value=spell_targets.divine_storm>=3|talent.divine_judgment.enabled&spell_targets.divine_storm>=2|azerite.divine_right.enabled&target.health.pct<=20&buff.divine_right.down
 #inquisition,if=buff.inquisition.down|buff.inquisition.remains<5&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3
 if BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 5 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 Spell(inquisition)
 #execution_sentence,if=spell_targets.divine_storm<=3&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
 if Enemies() <= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } Spell(execution_sentence)
 #divine_storm,if=variable.ds_castable&buff.divine_purpose.react
 if ds_castable() and BuffPresent(divine_purpose_buff) Spell(divine_storm)
 #divine_storm,if=variable.ds_castable&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
 if ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } Spell(divine_storm)
 #templars_verdict,if=buff.divine_purpose.react&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd)
 if BuffPresent(divine_purpose_buff) and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } Spell(templars_verdict)
 #templars_verdict,if=(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)&(!talent.execution_sentence.enabled|buff.crusade.up&buff.crusade.stack<10|cooldown.execution_sentence.remains>gcd*2)
 if { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 or SpellCooldown(execution_sentence) > GCD() * 2 } Spell(templars_verdict)
}

AddFunction RetributionFinishersMainPostConditions
{
}

AddFunction RetributionFinishersShortCdActions
{
}

AddFunction RetributionFinishersShortCdPostConditions
{
 { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 5 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or Enemies() <= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(execution_sentence) or ds_castable() and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(divine_storm) or BuffPresent(divine_purpose_buff) and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } and Spell(templars_verdict) or { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 or SpellCooldown(execution_sentence) > GCD() * 2 } and Spell(templars_verdict)
}

AddFunction RetributionFinishersCdActions
{
}

AddFunction RetributionFinishersCdPostConditions
{
 { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 5 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or Enemies() <= 3 and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(execution_sentence) or ds_castable() and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(divine_storm) or BuffPresent(divine_purpose_buff) and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } and Spell(templars_verdict) or { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 or SpellCooldown(execution_sentence) > GCD() * 2 } and Spell(templars_verdict)
}

### actions.generators

AddFunction RetributionGeneratorsMainActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5
 if HolyPower() >= 5 RetributionFinishersMainActions()

 unless HolyPower() >= 5 and RetributionFinishersMainPostConditions()
 {
  #wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>20)&(holy_power<=0|holy_power=1&cooldown.blade_of_justice.remains>gcd)
  if { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } Spell(wake_of_ashes)
  #blade_of_justice,if=holy_power<=2|(holy_power=3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW))
  if HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } Spell(blade_of_justice)
  #judgment,if=holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW))
  if HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } Spell(judgment)
  #hammer_of_wrath,if=holy_power<=4
  if HolyPower() <= 4 Spell(hammer_of_wrath)
  #consecration,if=holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2
  if HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 Spell(consecration)
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersMainActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersMainPostConditions()
  {
   #crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
   if SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration) > GCD() * 2 } Spell(crusader_strike)
   #call_action_list,name=finishers
   RetributionFinishersMainActions()

   unless RetributionFinishersMainPostConditions()
   {
    #crusader_strike,if=holy_power<=4
    if HolyPower() <= 4 Spell(crusader_strike)
   }
  }
 }
}

AddFunction RetributionGeneratorsMainPostConditions
{
 HolyPower() >= 5 and RetributionFinishersMainPostConditions() or Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersMainPostConditions() or RetributionFinishersMainPostConditions()
}

AddFunction RetributionGeneratorsShortCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5
 if HolyPower() >= 5 RetributionFinishersShortCdActions()

 unless HolyPower() >= 5 and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersShortCdActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration) > GCD() * 2 } and Spell(crusader_strike)
  {
   #call_action_list,name=finishers
   RetributionFinishersShortCdActions()
  }
 }
}

AddFunction RetributionGeneratorsShortCdPostConditions
{
 HolyPower() >= 5 and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration) or Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersShortCdPostConditions() or HolyPower() <= 4 and Spell(crusader_strike)
}

AddFunction RetributionGeneratorsCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5
 if HolyPower() >= 5 RetributionFinishersCdActions()

 unless HolyPower() >= 5 and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersCdActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration) > GCD() * 2 } and Spell(crusader_strike)
  {
   #call_action_list,name=finishers
   RetributionFinishersCdActions()

   unless RetributionFinishersCdPostConditions() or HolyPower() <= 4 and Spell(crusader_strike)
   {
    #arcane_torrent,if=(debuff.execution_sentence.up|(talent.hammer_of_wrath.enabled&(target.health.pct>=20|buff.avenging_wrath.down|buff.crusade.down))|!talent.execution_sentence.enabled|!talent.hammer_of_wrath.enabled)&holy_power<=4
    if { target.DebuffPresent(execution_sentence_debuff) or Talent(hammer_of_wrath_talent) and { target.HealthPercent() >= 20 or BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } or not Talent(execution_sentence_talent) or not Talent(hammer_of_wrath_talent) } and HolyPower() <= 4 Spell(arcane_torrent_holy)
   }
  }
 }
}

AddFunction RetributionGeneratorsCdPostConditions
{
 HolyPower() >= 5 and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration) or Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersCdPostConditions() or HolyPower() <= 4 and Spell(crusader_strike)
}

### actions.precombat

AddFunction RetributionPrecombatMainActions
{
}

AddFunction RetributionPrecombatMainPostConditions
{
}

AddFunction RetributionPrecombatShortCdActions
{
}

AddFunction RetributionPrecombatShortCdPostConditions
{
}

AddFunction RetributionPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
}

AddFunction RetributionPrecombatCdPostConditions
{
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
# old_war_potion
# avenging_wrath_buff
# crusade_buff
# lights_judgment
# shield_of_vengeance
# avenging_wrath
# inquisition_buff
# inquisition_talent
# crusade
# divine_judgment_talent
# divine_right
# divine_right_buff
# inquisition
# execution_sentence_talent
# execution_sentence
# crusade_talent
# divine_storm
# divine_purpose_buff
# templars_verdict
# hammer_of_wrath_talent
# wake_of_ashes
# blade_of_justice
# hammer_of_wrath
# judgment
# consecration
# crusader_strike
# arcane_torrent_holy
# execution_sentence_debuff
# rebuke
# hammer_of_justice
# war_stomp   
`
	OvaleScripts.RegisterScript("PALADIN", "retribution", name, desc, code, "script")
}
