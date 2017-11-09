local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
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
	if ProtectionSelfHealCondition() Spell(light_of_the_protector)
	
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
	]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end
do
    local name = "icyveins_paladin_holy"
    local desc = "[7.2.5] Icy-Veins: Paladin Holy"
    local code = [[
	
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

	]]
    OvaleScripts:RegisterScript("PALADIN", "holy", name, desc, code, "script")
end
do
    local name = "sc_paladin_protection_t19"
    local desc = "[7.0] Simulationcraft: Paladin_Protection_T19"
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
]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end
do
    local name = "sc_paladin_retribution_t19"
    local desc = "[7.0] Simulationcraft: Paladin_Retribution_T19"
    local code = [[
# Based on SimulationCraft profile "Paladin_Retribution_T19P".
#	class=paladin
#	spec=retribution
#	talents=1202102

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)


AddFunction ds_castable
{
 Enemies() >= 2 or BuffStacks(scarlet_inquisitors_expurgation_buff) >= 29 and { BuffPresent(avenging_wrath_melee_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) >= 15 or SpellCooldown(crusade) > 15 and not BuffPresent(crusade_buff) or SpellCooldown(avenging_wrath_melee) > 15 }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=retribution)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=retribution)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=retribution)

AddFunction RetributionInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_holy)
  if target.InRange(hammer_of_justice) and not target.Classification(worldboss) Spell(hammer_of_justice)
  if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
 }
}

AddFunction RetributionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction RetributionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
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
 #flask,type=flask_of_the_countless_armies
 #food,type=azshari_salad
 #augmentation,type=defiled
 #snapshot_stats
 #potion,name=old_war
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
}

AddFunction RetributionPrecombatCdPostConditions
{
}

### actions.opener

AddFunction RetributionOpenerMainActions
{
 #judgment
 Spell(judgment)
 #blade_of_justice,if=equipped.137048|race.blood_elf|!cooldown.wake_of_ashes.up
 if HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } Spell(blade_of_justice)
 #divine_hammer,if=equipped.137048|race.blood_elf|!cooldown.wake_of_ashes.up
 if HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } Spell(divine_hammer)
 #wake_of_ashes
 Spell(wake_of_ashes)
}

AddFunction RetributionOpenerMainPostConditions
{
}

AddFunction RetributionOpenerShortCdActions
{
}

AddFunction RetributionOpenerShortCdPostConditions
{
 Spell(judgment) or { HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } } and Spell(blade_of_justice) or { HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } } and Spell(divine_hammer) or Spell(wake_of_ashes)
}

AddFunction RetributionOpenerCdActions
{
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #arcane_torrent,if=!set_bonus.tier20_2pc
 if not ArmorSetBonus(T20 2) Spell(arcane_torrent_holy)
}

AddFunction RetributionOpenerCdPostConditions
{
 Spell(judgment) or { HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } } and Spell(blade_of_justice) or { HasEquippedItem(137048) or Race(BloodElf) or not { not SpellCooldown(wake_of_ashes) > 0 } } and Spell(divine_hammer) or Spell(wake_of_ashes)
}

### actions.generators

AddFunction RetributionGeneratorsMainActions
{
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2|(buff.scarlet_inquisitors_expurgation.stack>=29&(buff.avenging_wrath.up|(buff.crusade.up&buff.crusade.stack>=15)|(cooldown.crusade.remains>15&!buff.crusade.up)|cooldown.avenging_wrath.remains>15))
 #call_action_list,name=finishers,if=(buff.crusade.up&buff.crusade.stack<15|buff.liadrins_fury_unleashed.up)|(artifact.ashes_to_ashes.enabled&cooldown.wake_of_ashes.remains<gcd*2)
 if BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 RetributionFinishersMainActions()

 unless { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersMainPostConditions()
 {
  #call_action_list,name=finishers,if=talent.execution_sentence.enabled&(cooldown.judgment.remains<gcd*4.25|debuff.judgment.remains>gcd*4.25)&cooldown.execution_sentence.up|buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains<gcd*1.5
  if Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 RetributionFinishersMainActions()

  unless { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersMainPostConditions()
  {
   #judgment,if=dot.execution_sentence.ticking&dot.execution_sentence.remains<gcd*2&debuff.judgment.remains<gcd*2
   if target.DebuffPresent(execution_sentence_debuff) and target.DebuffRemaining(execution_sentence_debuff) < GCD() * 2 and target.DebuffRemaining(judgment_ret_debuff) < GCD() * 2 Spell(judgment)
   #blade_of_justice,if=holy_power<=2&(set_bonus.tier20_2pc|set_bonus.tier20_4pc)
   if HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } Spell(blade_of_justice)
   #divine_hammer,if=holy_power<=2&(set_bonus.tier20_2pc|set_bonus.tier20_4pc)
   if HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } Spell(divine_hammer)
   #wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>15)&(holy_power<=0|holy_power=1&(cooldown.blade_of_justice.remains>gcd|cooldown.divine_hammer.remains>gcd)|holy_power=2&((cooldown.zeal.charges_fractional<=0.65|cooldown.crusader_strike.charges_fractional<=0.65)))
   if { not False(raid_event_adds_exists) or 600 > 15 } and { HolyPower() <= 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0 or SpellCharges(crusader_strike count=0) <= 0 } } Spell(wake_of_ashes)
   #blade_of_justice,if=holy_power<=3&!set_bonus.tier20_4pc
   if HolyPower() <= 3 and not ArmorSetBonus(T20 4) Spell(blade_of_justice)
   #divine_hammer,if=holy_power<=3&!set_bonus.tier20_4pc
   if HolyPower() <= 3 and not ArmorSetBonus(T20 4) Spell(divine_hammer)
   #judgment
   Spell(judgment)
   #call_action_list,name=finishers,if=buff.divine_purpose.up
   if BuffPresent(divine_purpose_buff) RetributionFinishersMainActions()

   unless BuffPresent(divine_purpose_buff) and RetributionFinishersMainPostConditions()
   {
    #zeal,if=cooldown.zeal.charges_fractional>=1.65&holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|cooldown.divine_hammer.remains>gcd*2)&debuff.judgment.remains>gcd
    if SpellCharges(zeal count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() Spell(zeal)
    #crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.65&holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|cooldown.divine_hammer.remains>gcd*2)&debuff.judgment.remains>gcd&(talent.greater_judgment.enabled|!set_bonus.tier20_4pc&talent.the_fires_of_justice.enabled)
    if SpellCharges(crusader_strike count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and { Talent(greater_judgment_talent) or not ArmorSetBonus(T20 4) and Talent(the_fires_of_justice_talent) } Spell(crusader_strike)
    #consecration
    Spell(consecration)
    #call_action_list,name=finishers
    RetributionFinishersMainActions()

    unless RetributionFinishersMainPostConditions()
    {
     #zeal
     Spell(zeal)
     #crusader_strike
     Spell(crusader_strike)
    }
   }
  }
 }
}

AddFunction RetributionGeneratorsMainPostConditions
{
 { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersMainPostConditions() or { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersMainPostConditions() or BuffPresent(divine_purpose_buff) and RetributionFinishersMainPostConditions() or RetributionFinishersMainPostConditions()
}

AddFunction RetributionGeneratorsShortCdActions
{
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2|(buff.scarlet_inquisitors_expurgation.stack>=29&(buff.avenging_wrath.up|(buff.crusade.up&buff.crusade.stack>=15)|(cooldown.crusade.remains>15&!buff.crusade.up)|cooldown.avenging_wrath.remains>15))
 #call_action_list,name=finishers,if=(buff.crusade.up&buff.crusade.stack<15|buff.liadrins_fury_unleashed.up)|(artifact.ashes_to_ashes.enabled&cooldown.wake_of_ashes.remains<gcd*2)
 if BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 RetributionFinishersShortCdActions()

 unless { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersShortCdPostConditions()
 {
  #call_action_list,name=finishers,if=talent.execution_sentence.enabled&(cooldown.judgment.remains<gcd*4.25|debuff.judgment.remains>gcd*4.25)&cooldown.execution_sentence.up|buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains<gcd*1.5
  if Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 RetributionFinishersShortCdActions()

  unless { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersShortCdPostConditions() or target.DebuffPresent(execution_sentence_debuff) and target.DebuffRemaining(execution_sentence_debuff) < GCD() * 2 and target.DebuffRemaining(judgment_ret_debuff) < GCD() * 2 and Spell(judgment) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(blade_of_justice) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(divine_hammer) or { not False(raid_event_adds_exists) or 600 > 15 } and { HolyPower() <= 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0 or SpellCharges(crusader_strike count=0) <= 0 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(blade_of_justice) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(divine_hammer) or Spell(judgment)
  {
   #call_action_list,name=finishers,if=buff.divine_purpose.up
   if BuffPresent(divine_purpose_buff) RetributionFinishersShortCdActions()

   unless BuffPresent(divine_purpose_buff) and RetributionFinishersShortCdPostConditions() or SpellCharges(zeal count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and Spell(zeal) or SpellCharges(crusader_strike count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and { Talent(greater_judgment_talent) or not ArmorSetBonus(T20 4) and Talent(the_fires_of_justice_talent) } and Spell(crusader_strike) or Spell(consecration)
   {
    #hammer_of_justice,if=equipped.137065&target.health.pct>=75&holy_power<=4
    if HasEquippedItem(137065) and target.HealthPercent() >= 75 and HolyPower() <= 4 Spell(hammer_of_justice)
    #call_action_list,name=finishers
    RetributionFinishersShortCdActions()
   }
  }
 }
}

AddFunction RetributionGeneratorsShortCdPostConditions
{
 { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersShortCdPostConditions() or { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersShortCdPostConditions() or target.DebuffPresent(execution_sentence_debuff) and target.DebuffRemaining(execution_sentence_debuff) < GCD() * 2 and target.DebuffRemaining(judgment_ret_debuff) < GCD() * 2 and Spell(judgment) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(blade_of_justice) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(divine_hammer) or { not False(raid_event_adds_exists) or 600 > 15 } and { HolyPower() <= 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0 or SpellCharges(crusader_strike count=0) <= 0 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(blade_of_justice) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(divine_hammer) or Spell(judgment) or BuffPresent(divine_purpose_buff) and RetributionFinishersShortCdPostConditions() or SpellCharges(zeal count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and Spell(zeal) or SpellCharges(crusader_strike count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and { Talent(greater_judgment_talent) or not ArmorSetBonus(T20 4) and Talent(the_fires_of_justice_talent) } and Spell(crusader_strike) or Spell(consecration) or RetributionFinishersShortCdPostConditions() or Spell(zeal) or Spell(crusader_strike)
}

AddFunction RetributionGeneratorsCdActions
{
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2|(buff.scarlet_inquisitors_expurgation.stack>=29&(buff.avenging_wrath.up|(buff.crusade.up&buff.crusade.stack>=15)|(cooldown.crusade.remains>15&!buff.crusade.up)|cooldown.avenging_wrath.remains>15))
 #call_action_list,name=finishers,if=(buff.crusade.up&buff.crusade.stack<15|buff.liadrins_fury_unleashed.up)|(artifact.ashes_to_ashes.enabled&cooldown.wake_of_ashes.remains<gcd*2)
 if BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 RetributionFinishersCdActions()

 unless { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersCdPostConditions()
 {
  #call_action_list,name=finishers,if=talent.execution_sentence.enabled&(cooldown.judgment.remains<gcd*4.25|debuff.judgment.remains>gcd*4.25)&cooldown.execution_sentence.up|buff.whisper_of_the_nathrezim.up&buff.whisper_of_the_nathrezim.remains<gcd*1.5
  if Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 RetributionFinishersCdActions()

  unless { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersCdPostConditions() or target.DebuffPresent(execution_sentence_debuff) and target.DebuffRemaining(execution_sentence_debuff) < GCD() * 2 and target.DebuffRemaining(judgment_ret_debuff) < GCD() * 2 and Spell(judgment) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(blade_of_justice) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(divine_hammer) or { not False(raid_event_adds_exists) or 600 > 15 } and { HolyPower() <= 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0 or SpellCharges(crusader_strike count=0) <= 0 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(blade_of_justice) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(divine_hammer) or Spell(judgment)
  {
   #call_action_list,name=finishers,if=buff.divine_purpose.up
   if BuffPresent(divine_purpose_buff) RetributionFinishersCdActions()

   unless BuffPresent(divine_purpose_buff) and RetributionFinishersCdPostConditions() or SpellCharges(zeal count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and Spell(zeal) or SpellCharges(crusader_strike count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and { Talent(greater_judgment_talent) or not ArmorSetBonus(T20 4) and Talent(the_fires_of_justice_talent) } and Spell(crusader_strike) or Spell(consecration) or HasEquippedItem(137065) and target.HealthPercent() >= 75 and HolyPower() <= 4 and Spell(hammer_of_justice)
   {
    #call_action_list,name=finishers
    RetributionFinishersCdActions()
   }
  }
 }
}

AddFunction RetributionGeneratorsCdPostConditions
{
 { BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 15 or BuffPresent(liadrins_fury_unleashed_buff) or HasArtifactTrait(ashes_to_ashes) and SpellCooldown(wake_of_ashes) < GCD() * 2 } and RetributionFinishersCdPostConditions() or { Talent(execution_sentence_talent) and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and not SpellCooldown(execution_sentence) > 0 or BuffPresent(whisper_of_the_nathrezim_buff) and BuffRemaining(whisper_of_the_nathrezim_buff) < GCD() * 1 } and RetributionFinishersCdPostConditions() or target.DebuffPresent(execution_sentence_debuff) and target.DebuffRemaining(execution_sentence_debuff) < GCD() * 2 and target.DebuffRemaining(judgment_ret_debuff) < GCD() * 2 and Spell(judgment) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(blade_of_justice) or HolyPower() <= 2 and { ArmorSetBonus(T20 2) or ArmorSetBonus(T20 4) } and Spell(divine_hammer) or { not False(raid_event_adds_exists) or 600 > 15 } and { HolyPower() <= 0 or HolyPower() == 1 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } or HolyPower() == 2 and { SpellCharges(zeal count=0) <= 0 or SpellCharges(crusader_strike count=0) <= 0 } } and Spell(wake_of_ashes) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(blade_of_justice) or HolyPower() <= 3 and not ArmorSetBonus(T20 4) and Spell(divine_hammer) or Spell(judgment) or BuffPresent(divine_purpose_buff) and RetributionFinishersCdPostConditions() or SpellCharges(zeal count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and Spell(zeal) or SpellCharges(crusader_strike count=0) >= 1 and HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or SpellCooldown(divine_hammer) > GCD() * 2 } and target.DebuffRemaining(judgment_ret_debuff) > GCD() and { Talent(greater_judgment_talent) or not ArmorSetBonus(T20 4) and Talent(the_fires_of_justice_talent) } and Spell(crusader_strike) or Spell(consecration) or HasEquippedItem(137065) and target.HealthPercent() >= 75 and HolyPower() <= 4 and Spell(hammer_of_justice) or RetributionFinishersCdPostConditions() or Spell(zeal) or Spell(crusader_strike)
}

### actions.finishers

AddFunction RetributionFinishersMainActions
{
 #execution_sentence,if=spell_targets.divine_storm<=3&(cooldown.judgment.remains<gcd*4.25|debuff.judgment.remains>gcd*4.25)
 if Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } Spell(execution_sentence)
 #divine_storm,if=debuff.judgment.up&variable.ds_castable&buff.divine_purpose.react
 if target.DebuffPresent(judgment_ret_debuff) and ds_castable() and BuffPresent(divine_purpose_buff) Spell(divine_storm)
 #divine_storm,if=debuff.judgment.up&variable.ds_castable&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
 if target.DebuffPresent(judgment_ret_debuff) and ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } Spell(divine_storm)
 #justicars_vengeance,if=debuff.judgment.up&buff.divine_purpose.react&!equipped.137020
 if target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) and not HasEquippedItem(137020) Spell(justicars_vengeance)
 #templars_verdict,if=debuff.judgment.up&buff.divine_purpose.react
 if target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) Spell(templars_verdict)
 #templars_verdict,if=debuff.judgment.up&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd)
 if target.DebuffPresent(judgment_ret_debuff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } Spell(templars_verdict)
}

AddFunction RetributionFinishersMainPostConditions
{
}

AddFunction RetributionFinishersShortCdActions
{
}

AddFunction RetributionFinishersShortCdPostConditions
{
 Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and Spell(execution_sentence) or target.DebuffPresent(judgment_ret_debuff) and ds_castable() and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_ret_debuff) and ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(divine_storm) or target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) and not HasEquippedItem(137020) and Spell(justicars_vengeance) or target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_ret_debuff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } and Spell(templars_verdict)
}

AddFunction RetributionFinishersCdActions
{
}

AddFunction RetributionFinishersCdPostConditions
{
 Enemies() <= 3 and { SpellCooldown(judgment) < GCD() * 4 or target.DebuffRemaining(judgment_ret_debuff) > GCD() * 4 } and Spell(execution_sentence) or target.DebuffPresent(judgment_ret_debuff) and ds_castable() and BuffPresent(divine_purpose_buff) and Spell(divine_storm) or target.DebuffPresent(judgment_ret_debuff) and ds_castable() and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and Spell(divine_storm) or target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) and not HasEquippedItem(137020) and Spell(justicars_vengeance) or target.DebuffPresent(judgment_ret_debuff) and BuffPresent(divine_purpose_buff) and Spell(templars_verdict) or target.DebuffPresent(judgment_ret_debuff) and { not Talent(crusade_talent) or SpellCooldown(crusade) > GCD() * 2 } and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() } and Spell(templars_verdict)
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
 #use_item,name=faulty_countermeasure,if=(buff.avenging_wrath.up|buff.crusade.up)
 if BuffPresent(avenging_wrath_melee_buff) or BuffPresent(crusade_buff) RetributionUseItemActions()
 #potion,name=old_war,if=(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25|target.time_to_die<=40)
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_melee_buff) or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 or target.TimeToDie() <= 40 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war_potion usable=1)
 #blood_fury
 Spell(blood_fury_apsp)
 #berserking
 Spell(berserking)
 #arcane_torrent,if=(buff.crusade.up|buff.avenging_wrath.up)&holy_power=2&(cooldown.blade_of_justice.remains>gcd|cooldown.divine_hammer.remains>gcd)
 if { BuffPresent(crusade_buff) or BuffPresent(avenging_wrath_melee_buff) } and HolyPower() == 2 and { SpellCooldown(blade_of_justice) > GCD() or SpellCooldown(divine_hammer) > GCD() } Spell(arcane_torrent_holy)
 #holy_wrath
 Spell(holy_wrath)

 unless Spell(shield_of_vengeance)
 {
  #avenging_wrath
  Spell(avenging_wrath_melee)
  #crusade,if=holy_power>=3|((equipped.137048|race.blood_elf)&holy_power>=2)
  if HolyPower() >= 3 or { HasEquippedItem(137048) or Race(BloodElf) } and HolyPower() >= 2 Spell(crusade)
 }
}

AddFunction RetributionCooldownsCdPostConditions
{
 Spell(shield_of_vengeance)
}

### actions.default

AddFunction RetributionDefaultMainActions
{
 #call_action_list,name=opener,if=time<2
 if TimeInCombat() < 2 RetributionOpenerMainActions()

 unless TimeInCombat() < 2 and RetributionOpenerMainPostConditions()
 {
  #call_action_list,name=cooldowns
  RetributionCooldownsMainActions()

  unless RetributionCooldownsMainPostConditions()
  {
   #call_action_list,name=generators
   RetributionGeneratorsMainActions()
  }
 }
}

AddFunction RetributionDefaultMainPostConditions
{
 TimeInCombat() < 2 and RetributionOpenerMainPostConditions() or RetributionCooldownsMainPostConditions() or RetributionGeneratorsMainPostConditions()
}

AddFunction RetributionDefaultShortCdActions
{
 #auto_attack
 RetributionGetInMeleeRange()
 #call_action_list,name=opener,if=time<2
 if TimeInCombat() < 2 RetributionOpenerShortCdActions()

 unless TimeInCombat() < 2 and RetributionOpenerShortCdPostConditions()
 {
  #call_action_list,name=cooldowns
  RetributionCooldownsShortCdActions()

  unless RetributionCooldownsShortCdPostConditions()
  {
   #call_action_list,name=generators
   RetributionGeneratorsShortCdActions()
  }
 }
}

AddFunction RetributionDefaultShortCdPostConditions
{
 TimeInCombat() < 2 and RetributionOpenerShortCdPostConditions() or RetributionCooldownsShortCdPostConditions() or RetributionGeneratorsShortCdPostConditions()
}

AddFunction RetributionDefaultCdActions
{
 #rebuke
 RetributionInterruptActions()
 #call_action_list,name=opener,if=time<2
 if TimeInCombat() < 2 RetributionOpenerCdActions()

 unless TimeInCombat() < 2 and RetributionOpenerCdPostConditions()
 {
  #call_action_list,name=cooldowns
  RetributionCooldownsCdActions()

  unless RetributionCooldownsCdPostConditions()
  {
   #call_action_list,name=generators
   RetributionGeneratorsCdActions()
  }
 }
}

AddFunction RetributionDefaultCdPostConditions
{
 TimeInCombat() < 2 and RetributionOpenerCdPostConditions() or RetributionCooldownsCdPostConditions() or RetributionGeneratorsCdPostConditions()
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
# blood_fury_apsp
# berserking
# arcane_torrent_holy
# judgment
# blade_of_justice
# 137048
# wake_of_ashes
# divine_hammer
# scarlet_inquisitors_expurgation_buff
# avenging_wrath_melee_buff
# crusade_buff
# crusade
# avenging_wrath_melee
# liadrins_fury_unleashed_buff
# ashes_to_ashes
# execution_sentence_talent
# judgment_ret_debuff
# execution_sentence
# whisper_of_the_nathrezim_buff
# execution_sentence_debuff
# zeal
# crusader_strike
# divine_purpose_buff
# greater_judgment_talent
# the_fires_of_justice_talent
# consecration
# hammer_of_justice
# 137065
# divine_storm
# crusade_talent
# justicars_vengeance
# 137020
# templars_verdict
# holy_wrath
# shield_of_vengeance
# rebuke
# war_stomp
]]
    OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
end
