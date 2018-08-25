local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_paladin_protection"
    local desc = "[8.0] Simulationcraft: PR_Paladin_Protection"
    local code = [[
# Based on SimulationCraft profile "PR_Paladin_Protection".
#	class=paladin
#	spec=protection
#	talents=1200003

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
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
}

AddFunction ProtectionPrecombatCdPostConditions
{
}

### actions.default

AddFunction ProtectionDefaultMainActions
{
 #shield_of_the_righteous,if=(buff.avengers_valor.up&cooldown.shield_of_the_righteous.charges_fractional>=2.5)&(cooldown.seraphim.remains>gcd|!talent.seraphim.enabled)
 if BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } Spell(shield_of_the_righteous)
 #shield_of_the_righteous,if=(cooldown.shield_of_the_righteous.charges_fractional=3&cooldown.avenger_shield.remains>(2*gcd))
 if SpellCharges(shield_of_the_righteous count=0) == 3 and SpellCooldown(avengers_shield) > 2 * GCD() Spell(shield_of_the_righteous)
 #shield_of_the_righteous,if=(buff.avenging_wrath.up&!talent.seraphim.enabled)|buff.seraphim.up&buff.avengers_valor.up
 if BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) Spell(shield_of_the_righteous)
 #shield_of_the_righteous,if=(buff.avenging_wrath.up&buff.avenging_wrath.remains<4&!talent.seraphim.enabled)|(buff.seraphim.remains<4&buff.seraphim.up)
 if BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) Spell(shield_of_the_righteous)
 #avengers_shield,if=((cooldown.shield_of_the_righteous.charges_fractional>2.5&!buff.avengers_valor.up)|active_enemies>=2)&cooldown_react
 if { SpellCharges(shield_of_the_righteous count=0) > 2 and not BuffPresent(avengers_valor_buff) or Enemies() >= 2 } and not SpellCooldown(avengers_shield) > 0 Spell(avengers_shield)
 #judgment,if=(cooldown.judgment.remains<gcd&cooldown.judgment.charges_fractional>1&cooldown_react)|!talent.crusaders_judgment.enabled
 if SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
 #avengers_shield,,if=cooldown_react
 if not SpellCooldown(avengers_shield) > 0 Spell(avengers_shield)
 #consecration,if=(cooldown.judgment.remains<=gcd&!talent.crusaders_judgment.enabled)|cooldown.avenger_shield.remains<=gcd&consecration.remains<gcd
 if SpellCooldown(judgment_protection) <= GCD() and not Talent(crusaders_judgment_talent) or SpellCooldown(avengers_shield) <= GCD() and BuffRemaining(consecration) < GCD() Spell(consecration)
 #consecration,if=!talent.crusaders_judgment.enabled&consecration.remains<(cooldown.judgment.remains+cooldown.avengers_shield.remains)&consecration.remains<3*gcd
 if not Talent(crusaders_judgment_talent) and BuffRemaining(consecration) < SpellCooldown(judgment_protection) + SpellCooldown(avengers_shield) and BuffRemaining(consecration) < 3 * GCD() Spell(consecration)
 #judgment,if=cooldown_react|!talent.crusaders_judgment.enabled
 if not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) Spell(judgment_protection)
 #blessed_hammer
 Spell(blessed_hammer)
 #hammer_of_the_righteous
 Spell(hammer_of_the_righteous)
 #consecration
 Spell(consecration)
}

AddFunction ProtectionDefaultMainPostConditions
{
}

AddFunction ProtectionDefaultShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()
 #seraphim,if=cooldown.shield_of_the_righteous.charges_fractional>=2
 if SpellCharges(shield_of_the_righteous count=0) >= 2 Spell(seraphim)
}

AddFunction ProtectionDefaultShortCdPostConditions
{
 BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or SpellCharges(shield_of_the_righteous count=0) == 3 and SpellCooldown(avengers_shield) > 2 * GCD() and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or { SpellCharges(shield_of_the_righteous count=0) > 2 and not BuffPresent(avengers_valor_buff) or Enemies() >= 2 } and not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) <= GCD() and not Talent(crusaders_judgment_talent) or SpellCooldown(avengers_shield) <= GCD() and BuffRemaining(consecration) < GCD() } and Spell(consecration) or not Talent(crusaders_judgment_talent) and BuffRemaining(consecration) < SpellCooldown(judgment_protection) + SpellCooldown(avengers_shield) and BuffRemaining(consecration) < 3 * GCD() and Spell(consecration) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
}

AddFunction ProtectionDefaultCdActions
{
 #fireblood,if=buff.avenging_wrath.up
 if BuffPresent(avenging_wrath_buff) Spell(fireblood)

 unless SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim)
 {
  #avenging_wrath,if=buff.seraphim.up|cooldown.seraphim.remains<2|!talent.seraphim.enabled
  if BuffPresent(seraphim_buff) or SpellCooldown(seraphim) < 2 or not Talent(seraphim_talent) Spell(avenging_wrath)
  #potion,if=buff.avenging_wrath.up
  if BuffPresent(avenging_wrath_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)

  unless BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or SpellCharges(shield_of_the_righteous count=0) == 3 and SpellCooldown(avengers_shield) > 2 * GCD() and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous)
  {
   #use_items,if=buff.seraphim.up|!talent.seraphim.enabled
   if BuffPresent(seraphim_buff) or not Talent(seraphim_talent) ProtectionUseItemActions()
   #lights_judgment,if=buff.seraphim.up&buff.seraphim.remains<3
   if BuffPresent(seraphim_buff) and BuffRemaining(seraphim_buff) < 3 Spell(lights_judgment)

   unless { SpellCharges(shield_of_the_righteous count=0) > 2 and not BuffPresent(avengers_valor_buff) or Enemies() >= 2 } and not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) <= GCD() and not Talent(crusaders_judgment_talent) or SpellCooldown(avengers_shield) <= GCD() and BuffRemaining(consecration) < GCD() } and Spell(consecration) or not Talent(crusaders_judgment_talent) and BuffRemaining(consecration) < SpellCooldown(judgment_protection) + SpellCooldown(avengers_shield) and BuffRemaining(consecration) < 3 * GCD() and Spell(consecration) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection)
   {
    #lights_judgment,if=!talent.seraphim.enabled|buff.seraphim.up
    if not Talent(seraphim_talent) or BuffPresent(seraphim_buff) Spell(lights_judgment)
   }
  }
 }
}

AddFunction ProtectionDefaultCdPostConditions
{
 SpellCharges(shield_of_the_righteous count=0) >= 2 and Spell(seraphim) or BuffPresent(avengers_valor_buff) and SpellCharges(shield_of_the_righteous count=0) >= 2 and { SpellCooldown(seraphim) > GCD() or not Talent(seraphim_talent) } and Spell(shield_of_the_righteous) or SpellCharges(shield_of_the_righteous count=0) == 3 and SpellCooldown(avengers_shield) > 2 * GCD() and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and not Talent(seraphim_talent) or BuffPresent(seraphim_buff) and BuffPresent(avengers_valor_buff) } and Spell(shield_of_the_righteous) or { BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) < 4 and not Talent(seraphim_talent) or BuffRemaining(seraphim_buff) < 4 and BuffPresent(seraphim_buff) } and Spell(shield_of_the_righteous) or { SpellCharges(shield_of_the_righteous count=0) > 2 and not BuffPresent(avengers_valor_buff) or Enemies() >= 2 } and not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) < GCD() and SpellCharges(judgment_protection count=0) > 1 and not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or not SpellCooldown(avengers_shield) > 0 and Spell(avengers_shield) or { SpellCooldown(judgment_protection) <= GCD() and not Talent(crusaders_judgment_talent) or SpellCooldown(avengers_shield) <= GCD() and BuffRemaining(consecration) < GCD() } and Spell(consecration) or not Talent(crusaders_judgment_talent) and BuffRemaining(consecration) < SpellCooldown(judgment_protection) + SpellCooldown(avengers_shield) and BuffRemaining(consecration) < 3 * GCD() and Spell(consecration) or { not SpellCooldown(judgment_protection) > 0 or not Talent(crusaders_judgment_talent) } and Spell(judgment_protection) or Spell(blessed_hammer) or Spell(hammer_of_the_righteous) or Spell(consecration)
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
# battle_potion_of_strength
# blessed_hammer
# consecration
# crusaders_judgment_talent
# fireblood
# hammer_of_the_righteous
# judgment_protection
# lights_judgment
# rebuke
# seraphim
# seraphim_buff
# seraphim_talent
# shield_of_the_righteous
]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end
do
    local name = "sc_pr_paladin_retribution"
    local desc = "[8.0] Simulationcraft: PR_Paladin_Retribution"
    local code = [[
# Based on SimulationCraft profile "PR_Paladin_Retribution".
#	class=paladin
#	spec=retribution
#	talents=2303003

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)


AddFunction ds_castable
{
 Enemies() >= 3 or not Talent(righteous_verdict_talent) and Talent(divine_judgment_talent) and Enemies() >= 2 or HasAzeriteTrait(divine_right_trait) and target.HealthPercent() <= 20 and BuffExpires(divine_right_buff)
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
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
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
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)
}

AddFunction RetributionPrecombatCdPostConditions
{
}

### actions.opener

AddFunction RetributionOpenerMainActions
{
}

AddFunction RetributionOpenerMainPostConditions
{
}

AddFunction RetributionOpenerShortCdActions
{
}

AddFunction RetributionOpenerShortCdPostConditions
{
}

AddFunction RetributionOpenerCdActions
{
}

AddFunction RetributionOpenerCdPostConditions
{
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
  if HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 Spell(consecration_retribution)
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersMainActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersMainPostConditions()
  {
   #crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
   if SpellCharges(crusader_strike count=0) >= 1 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } Spell(crusader_strike)
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

 unless HolyPower() >= 5 and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersShortCdActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike)
  {
   #call_action_list,name=finishers
   RetributionFinishersShortCdActions()
  }
 }
}

AddFunction RetributionGeneratorsShortCdPostConditions
{
 HolyPower() >= 5 and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersShortCdPostConditions() or HolyPower() <= 4 and Spell(crusader_strike)
}

AddFunction RetributionGeneratorsCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
 #call_action_list,name=finishers,if=holy_power>=5
 if HolyPower() >= 5 RetributionFinishersCdActions()

 unless HolyPower() >= 5 and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
 {
  #call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
  if Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } RetributionFinishersCdActions()

  unless Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike)
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
 HolyPower() >= 5 and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 20 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or Talent(hammer_of_wrath_talent) and { target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and { BuffPresent(divine_purpose_buff) or BuffStacks(crusade_buff) < 10 } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersCdPostConditions() or HolyPower() <= 4 and Spell(crusader_strike)
}

### actions.finishers

AddFunction RetributionFinishersMainActions
{
 #variable,name=ds_castable,value=spell_targets.divine_storm>=3|!talent.righteous_verdict.enabled&talent.divine_judgment.enabled&spell_targets.divine_storm>=2|azerite.divine_right.enabled&target.health.pct<=20&buff.divine_right.down
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
 #use_item,name=jes_howler,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
 if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 RetributionUseItemActions()
 #potion,if=(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25|target.time_to_die<=40)
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 or target.TimeToDie() <= 40 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)
 #lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
 if Enemies() >= 2 or not False(raid_event_adds_exists) or 600 > 75 Spell(lights_judgment)
 #fireblood,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
 if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 Spell(fireblood)

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

### actions.default

AddFunction RetributionDefaultMainActions
{
 #call_action_list,name=opener
 RetributionOpenerMainActions()

 unless RetributionOpenerMainPostConditions()
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
 RetributionOpenerMainPostConditions() or RetributionCooldownsMainPostConditions() or RetributionGeneratorsMainPostConditions()
}

AddFunction RetributionDefaultShortCdActions
{
 #auto_attack
 RetributionGetInMeleeRange()
 #call_action_list,name=opener
 RetributionOpenerShortCdActions()

 unless RetributionOpenerShortCdPostConditions()
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
 RetributionOpenerShortCdPostConditions() or RetributionCooldownsShortCdPostConditions() or RetributionGeneratorsShortCdPostConditions()
}

AddFunction RetributionDefaultCdActions
{
 #rebuke
 RetributionInterruptActions()
 #call_action_list,name=opener
 RetributionOpenerCdActions()

 unless RetributionOpenerCdPostConditions()
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
 RetributionOpenerCdPostConditions() or RetributionCooldownsCdPostConditions() or RetributionGeneratorsCdPostConditions()
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
# arcane_torrent_holy
# avenging_wrath
# avenging_wrath_buff
# blade_of_justice
# bursting_blood
# consecration_retribution
# crusade
# crusade_buff
# crusade_talent
# crusader_strike
# divine_judgment_talent
# divine_purpose_buff
# divine_right_buff
# divine_right_trait
# divine_storm
# execution_sentence
# execution_sentence_debuff
# execution_sentence_talent
# fireblood
# hammer_of_justice
# hammer_of_wrath
# hammer_of_wrath_talent
# inquisition
# inquisition_buff
# inquisition_talent
# judgment
# lights_judgment
# rebuke
# righteous_verdict_talent
# shield_of_vengeance
# templars_verdict
# wake_of_ashes
# war_stomp
]]
    OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
end
