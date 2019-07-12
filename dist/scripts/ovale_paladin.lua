local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_t23_paladin_protection"
    local desc = "[8.2] Simulationcraft: T23_Paladin_Protection"
    local code = [[
# Based on SimulationCraft profile "T23_Paladin_Protection".
#	class=paladin
#	spec=protection
#	talents=3200003

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=protection)

AddFunction ProtectionInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
  if target.InRange(avengers_shield) and target.IsInterruptible() Spell(avengers_shield)
  if target.InRange(hammer_of_justice) and not target.Classification(worldboss) Spell(hammer_of_justice)
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(blinding_light)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction ProtectionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
 #consecration
 Spell(consecration)
}

AddFunction ProtectionPrecombatMainPostConditions
{
}

AddFunction ProtectionPrecombatShortCdActions
{
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
 Spell(consecration)
}

AddFunction ProtectionPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless Spell(consecration)
 {
  #lights_judgment
  Spell(lights_judgment)
 }
}

AddFunction ProtectionPrecombatCdPostConditions
{
 Spell(consecration)
}

### actions.cooldowns

AddFunction ProtectionCooldownsMainActions
{
}

AddFunction ProtectionCooldownsMainPostConditions
{
}

AddFunction ProtectionCooldownsShortCdActions
{
 #seraphim,if=cooldown.shield_of_the_righteous.charges_fractional>=2
 if SpellCharges(shield_of_the_righteous count=0) >= 2 Spell(seraphim)
}

AddFunction ProtectionCooldownsShortCdPostConditions
{
}

AddFunction ProtectionCooldownsCdActions
{
 #fireblood,if=buff.avenging_wrath.up
 if BuffPresent(avenging_wrath_buff) Spell(fireblood)
 #use_item,name=azsharas_font_of_power,if=cooldown.seraphim.remains<=10|!talent.seraphim.enabled
 if SpellCooldown(seraphim) <= 10 or not Talent(seraphim_talent) ProtectionUseItemActions()

 unless SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim)
 {
  #avenging_wrath,if=buff.seraphim.up|cooldown.seraphim.remains<2|!talent.seraphim.enabled
  if BuffPresent(seraphim_buff) or SpellCooldown(seraphim) < 2 or not Talent(seraphim_talent) Spell(avenging_wrath)
  #bastion_of_light,if=cooldown.shield_of_the_righteous.charges_fractional<=0.5
  if SpellCharges(shield_of_the_righteous count=0) <= 0.5 Spell(bastion_of_light)
  #potion,if=buff.avenging_wrath.up
  if BuffPresent(avenging_wrath_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
  #use_items,if=buff.seraphim.up|!talent.seraphim.enabled
  if BuffPresent(seraphim_buff) or not Talent(seraphim_talent) ProtectionUseItemActions()
  #use_item,name=grongs_primal_rage,if=((cooldown.judgment.full_recharge_time>4|(!talent.crusaders_judgment.enabled&prev_gcd.1.judgment))&cooldown.avengers_shield.remains>4&buff.seraphim.remains>4)|(buff.seraphim.remains<4)
  if { SpellCooldown(judgment_protection) > 4 or not Talent(crusaders_judgment_talent) and PreviousGCDSpell(judgment_protection) } and SpellCooldown(avengers_shield) > 4 and BuffRemaining(seraphim_buff) > 4 or BuffRemaining(seraphim_buff) < 4 ProtectionUseItemActions()
  #use_item,name=merekthas_fang,if=!buff.avenging_wrath.up&(buff.seraphim.up|!talent.seraphim.enabled)
  if not BuffPresent(avenging_wrath_buff) and { BuffPresent(seraphim_buff) or not Talent(seraphim_talent) } ProtectionUseItemActions()
  #use_item,name=razdunks_big_red_button
  ProtectionUseItemActions()
 }
}

AddFunction ProtectionCooldownsCdPostConditions
{
 SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim)
}

### actions.default

AddFunction ProtectionDefaultMainActions
{
 #call_action_list,name=cooldowns
 ProtectionCooldownsMainActions()

 unless ProtectionCooldownsMainPostConditions()
 {
  #shield_of_the_righteous,if=(buff.avengers_valor.up&cooldown.shield_of_the_righteous.charges_fractional>=2.5)&(cooldown.seraphim.remains>gcd|!talent.seraphim.enabled)
  if BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } Spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&!talent.seraphim.enabled)|buff.seraphim.up&buff.avengers_valor.up
  if BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) Spell(shield_of_the_righteous)
  #shield_of_the_righteous,if=(buff.avenging_wrath.up&buff.avenging_wrath.remains<4&!talent.seraphim.enabled)|(buff.seraphim.remains<4&buff.seraphim.up)
  if BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) Spell(shield_of_the_righteous)
  #consecration,if=!consecration.up
  if not BuffPresent(consecration) Spell(consecration)
  #judgment,if=(cooldown.judgment.remains<gcd&cooldown.judgment.charges_fractional>1&cooldown_react)|!talent.crusaders_judgment.enabled
  if SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
  #avengers_shield,if=cooldown_react
  if not SpellCooldown(avengers_shield) > 0 Spell(avengers_shield)
  #judgment,if=cooldown_react|!talent.crusaders_judgment.enabled
  if not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
  #blessed_hammer,strikes=3
  Spell(blessed_hammer)
  #hammer_of_the_righteous
  Spell(hammer_of_the_righteous)
  #consecration
  Spell(consecration)
 }
}

AddFunction ProtectionDefaultMainPostConditions
{
 ProtectionCooldownsMainPostConditions()
}

AddFunction ProtectionDefaultShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()
 #call_action_list,name=cooldowns
 ProtectionCooldownsShortCdActions()
}

AddFunction ProtectionDefaultShortCdPostConditions
{
 ProtectionCooldownsShortCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
}

AddFunction ProtectionDefaultCdActions
{
 ProtectionInterruptActions()
 #call_action_list,name=cooldowns
 ProtectionCooldownsCdActions()

 unless ProtectionCooldownsCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous)
 {
  #lights_judgment,if=buff.seraphim.up&buff.seraphim.remains<3
  if BuffPresent(seraphim_buff) and BuffRemaining(seraphim_buff) < 3 Spell(lights_judgment)

  unless not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection)
  {
   #lights_judgment,if=!talent.seraphim.enabled|buff.seraphim.up
   if not Talent(seraphim_talent) or BuffPresent(seraphim_buff) Spell(lights_judgment)
  }
 }
}

AddFunction ProtectionDefaultCdPostConditions
{
 ProtectionCooldownsCdPostConditions() or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2.5 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or not BuffPresent(consecration) and Spell(consecration) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
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
# avengers_shield
# avengers_valor_buff
# avenging_wrath
# avenging_wrath_buff
# bastion_of_light
# blessed_hammer
# blinding_light
# consecration
# crusaders_judgment_talent
# fireblood
# hammer_of_justice
# hammer_of_the_righteous
# item_unbridled_fury
# judgment_protection
# lights_judgment
# rebuke
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
# war_stomp
]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end
do
    local name = "sc_t23_paladin_retribution"
    local desc = "[8.2] Simulationcraft: T23_Paladin_Retribution"
    local code = [[
# Based on SimulationCraft profile "T23_Paladin_Retribution".
#	class=paladin
#	spec=retribution
#	talents=2303103

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)


AddFunction ds_castable
{
 Enemies() >= 2 and not Talent(righteous_verdict_talent) or Enemies() >= 3 and Talent(righteous_verdict_talent) or BuffPresent(empyrean_power_buff) and target.DebuffExpires(judgment) and BuffExpires(divine_purpose_buff) and BuffExpires(avenging_wrath_autocrit_buff)
}

AddFunction wings_pool
{
 not HasEquippedItem(169314) and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > GCD() * 3 or SpellCooldown(crusade) > GCD() * 3 } or HasEquippedItem(169314) and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > GCD() * 6 or SpellCooldown(crusade) > GCD() * 6 }
}

AddFunction HoW
{
 not Talent(hammer_of_wrath_talent) or target.HealthPercent() >= 20 and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=retribution)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=retribution)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=retribution)
AddCheckBox(opt_shield_of_vengeance SpellName(shield_of_vengeance) specialization=retribution)

AddFunction RetributionInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
  if target.InRange(hammer_of_justice) and not target.Classification(worldboss) Spell(hammer_of_justice)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
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
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
 #arcane_torrent,if=!talent.wake_of_ashes.enabled
 if not Talent(wake_of_ashes_talent) Spell(arcane_torrent_holy)
}

AddFunction RetributionPrecombatCdPostConditions
{
}

### actions.generators

AddFunction RetributionGeneratorsMainActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersMainActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersMainPostConditions()
 {
  #wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>15|spell_targets.wake_of_ashes>=2)&(holy_power<=0|holy_power=1&cooldown.blade_of_justice.remains>gcd)&(cooldown.avenging_wrath.remains>10|talent.crusade.enabled&cooldown.crusade.remains>10)
  if { not False(raid_event_adds_exists) or 600 > 15 or Enemies() >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } Spell(wake_of_ashes)
  #blade_of_justice,if=holy_power<=2|(holy_power=3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW))
  if HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } Spell(blade_of_justice)
  #judgment,if=holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW))
  if HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } Spell(judgment)
  #hammer_of_wrath,if=holy_power<=4
  if HolyPower() <= 4 Spell(hammer_of_wrath)
  #consecration,if=holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2
  if HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 Spell(consecration_retribution)
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) RetributionFinishersMainActions()

  unless { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersMainPostConditions()
  {
   #crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
   if SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } Spell(crusader_strike)
   #call_action_list,name=finishers
   RetributionFinishersMainActions()

   unless RetributionFinishersMainPostConditions()
   {
    #concentrated_flame
    Spell(concentrated_flame_essence)
    #crusader_strike,if=holy_power<=4
    if HolyPower() <= 4 Spell(crusader_strike)
   }
  }
 }
}

AddFunction RetributionGeneratorsMainPostConditions
{
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersMainPostConditions() or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersMainPostConditions() or RetributionFinishersMainPostConditions()
}

AddFunction RetributionGeneratorsShortCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersShortCdActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or Enemies() >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) RetributionFinishersShortCdActions()

  unless { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike)
  {
   #call_action_list,name=finishers
   RetributionFinishersShortCdActions()
  }
 }
}

AddFunction RetributionGeneratorsShortCdPostConditions
{
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or Enemies() >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersShortCdPostConditions() or Spell(concentrated_flame_essence) or HolyPower() <= 4 and Spell(crusader_strike)
}

AddFunction RetributionGeneratorsCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersCdActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or Enemies() >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up
  if Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) RetributionFinishersCdActions()

  unless { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike)
  {
   #call_action_list,name=finishers
   RetributionFinishersCdActions()

   unless RetributionFinishersCdPostConditions() or Spell(concentrated_flame_essence) or HolyPower() <= 4 and Spell(crusader_strike)
   {
    #arcane_torrent,if=holy_power<=4
    if HolyPower() <= 4 Spell(arcane_torrent_holy)
   }
  }
 }
}

AddFunction RetributionGeneratorsCdPostConditions
{
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or Enemies() >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersCdPostConditions() or Spell(concentrated_flame_essence) or HolyPower() <= 4 and Spell(crusader_strike)
}

### actions.finishers

AddFunction RetributionFinishersMainActions
{
 #variable,name=wings_pool,value=!equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*3|cooldown.crusade.remains>gcd*3)|equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*6|cooldown.crusade.remains>gcd*6)
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2&!talent.righteous_verdict.enabled|spell_targets.divine_storm>=3&talent.righteous_verdict.enabled|buff.empyrean_power.up&debuff.judgment.down&buff.divine_purpose.down&buff.avenging_wrath_autocrit.down
 #inquisition,if=buff.avenging_wrath.down&(buff.inquisition.down|buff.inquisition.remains<8&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3)
 if BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } Spell(inquisition)
 #execution_sentence,if=spell_targets.divine_storm<=2&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>10|talent.crusade.enabled&buff.crusade.down&cooldown.crusade.remains>10|buff.crusade.stack>=7)
 if Enemies() <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } Spell(execution_sentence)
 #divine_storm,if=variable.ds_castable&variable.wings_pool&(!talent.execution_sentence.enabled|spell_targets.divine_storm<=2&cooldown.execution_sentence.remains>gcd*2|cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|buff.crusade.up&buff.crusade.stack<10)
 if ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or Enemies() <= 2 and SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } Spell(divine_storm)
 #templars_verdict,if=variable.wings_pool&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd*2|cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|buff.crusade.up&buff.crusade.stack<10)
 if wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } Spell(templars_verdict)
}

AddFunction RetributionFinishersMainPostConditions
{
}

AddFunction RetributionFinishersShortCdActions
{
}

AddFunction RetributionFinishersShortCdPostConditions
{
 BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or Enemies() <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } and Spell(execution_sentence) or ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or Enemies() <= 2 and SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(divine_storm) or wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(templars_verdict)
}

AddFunction RetributionFinishersCdActions
{
}

AddFunction RetributionFinishersCdPostConditions
{
 BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or Enemies() <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } and Spell(execution_sentence) or ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or Enemies() <= 2 and SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(divine_storm) or wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(templars_verdict)
}

### actions.cooldowns

AddFunction RetributionCooldownsMainActions
{
 #focused_azerite_beam,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)&(buff.avenging_wrath.down|buff.crusade.down)&(cooldown.blade_of_justice.remains>gcd*3&cooldown.judgment.remains>gcd*3)
 if { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 Spell(focused_azerite_beam)
}

AddFunction RetributionCooldownsMainPostConditions
{
}

AddFunction RetributionCooldownsShortCdActions
{
 #shield_of_vengeance,if=buff.seething_rage.down&buff.memory_of_lucid_dreams.down
 if BuffExpires(seething_rage) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) Spell(shield_of_vengeance)
 #the_unbound_force,if=time<=2|buff.reckless_force.up
 if TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) Spell(the_unbound_force)
 #worldvein_resonance,if=cooldown.avenging_wrath.remains<gcd&holy_power>=3|cooldown.crusade.remains<gcd&holy_power>=4|cooldown.avenging_wrath.remains>=45|cooldown.crusade.remains>=45
 if SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 Spell(worldvein_resonance_essence)

 unless { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam)
 {
  #purifying_blast,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)
  if not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 Spell(purifying_blast)
 }
}

AddFunction RetributionCooldownsShortCdPostConditions
{
 { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam)
}

AddFunction RetributionCooldownsCdActions
{
 #potion,if=(cooldown.guardian_of_azeroth.remains>90|!essence.condensed_lifeforce.major)&(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25)
 if { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
 #lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
 if Enemies() >= 2 or not False(raid_event_adds_exists) or 600 > 75 Spell(lights_judgment)
 #fireblood,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
 if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 Spell(fireblood)

 unless BuffExpires(seething_rage) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) and Spell(shield_of_vengeance)
 {
  #use_item,name=ramping_amplitude_gigavolt_engine,if=(buff.avenging_wrath.up|buff.crusade.up)
  if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) RetributionUseItemActions()

  unless { TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) } and Spell(the_unbound_force)
  {
   #blood_of_the_enemy,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
   if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 Spell(blood_of_the_enemy)
   #guardian_of_azeroth,if=!talent.crusade.enabled&(cooldown.avenging_wrath.remains<5&holy_power>=3&(buff.inquisition.up|!talent.inquisition.enabled)|cooldown.avenging_wrath.remains>=45)|(talent.crusade.enabled&cooldown.crusade.remains<gcd&holy_power>=4|holy_power>=3&time<10&talent.wake_of_ashes.enabled|cooldown.crusade.remains>=45)
   if not Talent(crusade_talent) and { SpellCooldown(avenging_wrath) < 5 and HolyPower() >= 3 and { BuffPresent(inquisition_buff) or not Talent(inquisition_talent) } or SpellCooldown(avenging_wrath) >= 45 } or Talent(crusade_talent) and SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or HolyPower() >= 3 and TimeInCombat() < 10 and Talent(wake_of_ashes_talent) or SpellCooldown(crusade) >= 45 Spell(guardian_of_azeroth)

   unless { SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 } and Spell(worldvein_resonance_essence) or { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam)
   {
    #memory_of_lucid_dreams,if=(buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10)&holy_power<=3
    if { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 } and HolyPower() <= 3 Spell(memory_of_lucid_dreams_essence)

    unless { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and Spell(purifying_blast)
    {
     #avenging_wrath,if=(!talent.inquisition.enabled|buff.inquisition.up)&holy_power>=3
     if { not Talent(inquisition_talent) or BuffPresent(inquisition_buff) } and HolyPower() >= 3 Spell(avenging_wrath)
     #crusade,if=holy_power>=4|holy_power>=3&time<10&talent.wake_of_ashes.enabled
     if HolyPower() >= 4 or HolyPower() >= 3 and TimeInCombat() < 10 and Talent(wake_of_ashes_talent) Spell(crusade)
    }
   }
  }
 }
}

AddFunction RetributionCooldownsCdPostConditions
{
 BuffExpires(seething_rage) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) and Spell(shield_of_vengeance) or { TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) } and Spell(the_unbound_force) or { SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 } and Spell(worldvein_resonance_essence) or { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and { BuffExpires(avenging_wrath_buff) or BuffExpires(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam) or { not False(raid_event_adds_exists) or 600 > 30 or Enemies() >= 2 } and Spell(purifying_blast)
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
# 169314
# arcane_torrent_holy
# avenging_wrath
# avenging_wrath_autocrit_buff
# avenging_wrath_buff
# blade_of_justice
# blood_of_the_enemy
# bloodlust
# concentrated_flame_essence
# condensed_lifeforce_essence_id
# consecration_retribution
# crusade
# crusade_buff
# crusade_talent
# crusader_strike
# divine_purpose_buff
# divine_storm
# empyrean_power_buff
# execution_sentence
# execution_sentence_talent
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# hammer_of_justice
# hammer_of_wrath
# hammer_of_wrath_talent
# inquisition
# inquisition_buff
# inquisition_talent
# item_focused_resolve
# judgment
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# purifying_blast
# rebuke
# reckless_force_buff
# righteous_verdict_talent
# seething_rage
# shield_of_vengeance
# templars_verdict
# the_unbound_force
# wake_of_ashes
# wake_of_ashes_talent
# war_stomp
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
end
