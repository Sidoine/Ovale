local __exports = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
if not __exports then return end
__exports.registerPaladinRetributionHooves = function(OvaleScripts)
do
	local name = "hooves_ret"
	local desc = "[Hooves][8.2] Paladin: Retribution"
	local code = [[
# Based on SimulationCraft profile "T24_Paladin_Retribution".
#    class=paladin
#    spec=retribution
#    talents=3303103

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

AddIcon specialization=3 help=main 
{
	if Not mounted() and target.InRange(crusader_strike) 
	{
	  if Boss() RetributionDefaultCdActions()
				RetributionDefaultShortCdActions()
				RetributionDefaultMainActions()
	}
				
}

AddFunction wings_pool
{
 not HasEquippedItem(169314 _item) and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > GCD() * 3 or SpellCooldown(crusade) > GCD() * 3 } or HasEquippedItem(169314 _item) and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > GCD() * 6 or SpellCooldown(crusade) > GCD() * 6 }
}

AddFunction HoW
{
 not Talent(hammer_of_wrath_talent) or target.HealthPercent() >= 20 and not { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) }
}

AddFunction ds_castable
{
 enemies(tagged=1) >= 2 and not Talent(righteous_verdict_talent) or enemies(tagged=1) >= 3 and Talent(righteous_verdict_talent) or BuffPresent(empyrean_power_buff) and target.DebuffExpires(judgment) and BuffExpires(divine_purpose_retribution) and BuffExpires(avenging_wrath_autocrit_buff)
}

AddCheckBox(opt_shield_of_vengeance SpellName(shield_of_vengeance) specialization=retribution)


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
 #potion,if=(cooldown.guardian_of_azeroth.remains>90|!essence.condensed_lifeforce.major)&(buff.bloodlust.react|buff.avenging_wrath.up&buff.avenging_wrath.remains>18|buff.crusade.up&buff.crusade.remains<25)
 if { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) > 18 or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_focused_resolve usable=1)
}

AddFunction RetributionCooldownsMainPostConditions
{
}

AddFunction RetributionCooldownsShortCdActions
{
 unless { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) > 18 or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
 {
  #shield_of_vengeance,if=buff.seething_rage.down&buff.memory_of_lucid_dreams.down
  if BuffExpires(seething_rage_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) Spell(shield_of_vengeance)
  #the_unbound_force,if=time<=2|buff.reckless_force.up
  if TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #blood_of_the_enemy,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
  if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 Spell(blood_of_the_enemy)
  #worldvein_resonance,if=cooldown.avenging_wrath.remains<gcd&holy_power>=3|cooldown.crusade.remains<gcd&holy_power>=4|cooldown.avenging_wrath.remains>=45|cooldown.crusade.remains>=45
  if SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 Spell(worldvein_resonance_essence)
  #focused_azerite_beam,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)&!(buff.avenging_wrath.up|buff.crusade.up)&(cooldown.blade_of_justice.remains>gcd*3&cooldown.judgment.remains>gcd*3)
  if { not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 } and not { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 Spell(focused_azerite_beam)
  #purifying_blast,if=(!raid_event.adds.exists|raid_event.adds.in>30|spell_targets.divine_storm>=2)
  if not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 Spell(purifying_blast)
 }
}

AddFunction RetributionCooldownsShortCdPostConditions
{
 { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) > 18 or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
}

AddFunction RetributionCooldownsCdActions
{
 unless { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) > 18 or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
 {
  #lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
  if enemies(tagged=1) >= 2 or not False(raid_event_adds_exists) or 600 > 75 Spell(lights_judgment)
  #fireblood,if=buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10
  if BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 Spell(fireblood)

  unless BuffExpires(seething_rage_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) and Spell(shield_of_vengeance)
  {

   unless { TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) } and Spell(the_unbound_force)
   {
    #guardian_of_azeroth,if=!talent.crusade.enabled&(cooldown.avenging_wrath.remains<5&holy_power>=3&(buff.inquisition.up|!talent.inquisition.enabled)|cooldown.avenging_wrath.remains>=45)|(talent.crusade.enabled&cooldown.crusade.remains<gcd&holy_power>=4|holy_power>=3&time<10&talent.wake_of_ashes.enabled|cooldown.crusade.remains>=45)
    if not Talent(crusade_talent) and { SpellCooldown(avenging_wrath) < 5 and HolyPower() >= 3 and { BuffPresent(inquisition_buff) or not Talent(inquisition_talent) } or SpellCooldown(avenging_wrath) >= 45 } or Talent(crusade_talent) and SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or HolyPower() >= 3 and TimeInCombat() < 10 and Talent(wake_of_ashes_talent) or SpellCooldown(crusade) >= 45 Spell(guardian_of_azeroth)

    unless { SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 } and Spell(worldvein_resonance_essence) or { not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 } and not { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam)
    {
     #memory_of_lucid_dreams,if=(buff.avenging_wrath.up|buff.crusade.up&buff.crusade.stack=10)&holy_power<=3
     if { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) == 10 } and HolyPower() <= 3 Spell(memory_of_lucid_dreams_essence)

     unless { not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 } and Spell(purifying_blast)
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
}

AddFunction RetributionCooldownsCdPostConditions
{
 { SpellCooldown(guardian_of_azeroth) > 90 or not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) } and { BuffPresent(bloodlust) or BuffPresent(avenging_wrath_buff) and BuffRemaining(avenging_wrath_buff) > 18 or BuffPresent(crusade_buff) and BuffRemaining(crusade_buff) < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1) or BuffExpires(seething_rage_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and CheckBoxOn(opt_shield_of_vengeance) and Spell(shield_of_vengeance) or { TimeInCombat() <= 2 or BuffPresent(reckless_force_buff) } and Spell(the_unbound_force) or { SpellCooldown(avenging_wrath) < GCD() and HolyPower() >= 3 or SpellCooldown(crusade) < GCD() and HolyPower() >= 4 or SpellCooldown(avenging_wrath) >= 45 or SpellCooldown(crusade) >= 45 } and Spell(worldvein_resonance_essence) or { not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 } and not { BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and SpellCooldown(blade_of_justice) > GCD() * 3 and SpellCooldown(judgment) > GCD() * 3 and Spell(focused_azerite_beam) or { not False(raid_event_adds_exists) or 600 > 30 or enemies(tagged=1) >= 2 } and Spell(purifying_blast)
}

### actions.finishers

AddFunction RetributionFinishersMainActions
{
 #variable,name=wings_pool,value=!equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*3|cooldown.crusade.remains>gcd*3)|equipped.169314&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>gcd*6|cooldown.crusade.remains>gcd*6)
 #variable,name=ds_castable,value=spell_targets.divine_storm>=2&!talent.righteous_verdict.enabled|spell_targets.divine_storm>=3&talent.righteous_verdict.enabled|buff.empyrean_power.up&debuff.judgment.down&buff.divine_purpose.down&buff.avenging_wrath_autocrit.down
 #inquisition,if=buff.avenging_wrath.down&(buff.inquisition.down|buff.inquisition.remains<8&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3)
 if BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } Spell(inquisition)
 #execution_sentence,if=spell_targets.divine_storm<=2&(!talent.crusade.enabled&cooldown.avenging_wrath.remains>10|talent.crusade.enabled&buff.crusade.down&cooldown.crusade.remains>10|buff.crusade.stack>=7)
 if enemies(tagged=1) <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } Spell(execution_sentence)
 #divine_storm,if=variable.ds_castable&variable.wings_pool&((!talent.execution_sentence.enabled|(spell_targets.divine_storm>=2|cooldown.execution_sentence.remains>gcd*2))|(cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|cooldown.crusade.remains>gcd*3&cooldown.crusade.remains<10|buff.crusade.up&buff.crusade.stack<10))
 if ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or enemies(tagged=1) >= 2 or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } Spell(divine_storm)
 #templars_verdict,if=variable.wings_pool&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd*2|cooldown.avenging_wrath.remains>gcd*3&cooldown.avenging_wrath.remains<10|cooldown.crusade.remains>gcd*3&cooldown.crusade.remains<10|buff.crusade.up&buff.crusade.stack<10)
 if wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } Spell(templars_verdict)
}

AddFunction RetributionFinishersMainPostConditions
{
}

AddFunction RetributionFinishersShortCdActions
{
}

AddFunction RetributionFinishersShortCdPostConditions
{
 BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or enemies(tagged=1) <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } and Spell(execution_sentence) or ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or enemies(tagged=1) >= 2 or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(divine_storm) or wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(templars_verdict)
}

AddFunction RetributionFinishersCdActions
{
}

AddFunction RetributionFinishersCdPostConditions
{
 BuffExpires(avenging_wrath_buff) and { BuffExpires(inquisition_buff) or BuffRemaining(inquisition_buff) < 8 and HolyPower() >= 3 or Talent(execution_sentence_talent) and SpellCooldown(execution_sentence) < 10 and BuffRemaining(inquisition_buff) < 15 or SpellCooldown(avenging_wrath) < 15 and BuffRemaining(inquisition_buff) < 20 and HolyPower() >= 3 } and Spell(inquisition) or enemies(tagged=1) <= 2 and { not Talent(crusade_talent) and SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and BuffExpires(crusade_buff) and SpellCooldown(crusade) > 10 or BuffStacks(crusade_buff) >= 7 } and Spell(execution_sentence) or ds_castable() and wings_pool() and { not Talent(execution_sentence_talent) or enemies(tagged=1) >= 2 or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(divine_storm) or wings_pool() and { not Talent(execution_sentence_talent) or SpellCooldown(execution_sentence) > GCD() * 2 or SpellCooldown(avenging_wrath) > GCD() * 3 and SpellCooldown(avenging_wrath) < 10 or SpellCooldown(crusade) > GCD() * 3 and SpellCooldown(crusade) < 10 or BuffPresent(crusade_buff) and BuffStacks(crusade_buff) < 10 } and Spell(templars_verdict)
}

### actions.generators

AddFunction RetributionGeneratorsMainActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersMainActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersMainPostConditions()
 {
  #wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>15|spell_targets.wake_of_ashes>=2)&(holy_power<=0|holy_power=1&cooldown.blade_of_justice.remains>gcd)&(cooldown.avenging_wrath.remains>10|talent.crusade.enabled&cooldown.crusade.remains>10)
  if { not False(raid_event_adds_exists) or 600 > 15 or enemies(tagged=1) >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } Spell(wake_of_ashes)
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
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersMainPostConditions() or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersMainPostConditions() or RetributionFinishersMainPostConditions()
}

AddFunction RetributionGeneratorsShortCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersShortCdActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or enemies(tagged=1) >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
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
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersShortCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or enemies(tagged=1) >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersShortCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersShortCdPostConditions() or Spell(concentrated_flame_essence) or HolyPower() <= 4 and Spell(crusader_strike)
}

AddFunction RetributionGeneratorsCdActions
{
 #variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&!(buff.avenging_wrath.up|buff.crusade.up))
 #call_action_list,name=finishers,if=holy_power>=5|buff.memory_of_lucid_dreams.up|buff.seething_rage.up|buff.inquisition.down&holy_power>=3
 if HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 RetributionFinishersCdActions()

 unless { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or enemies(tagged=1) >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution)
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
 { HolyPower() >= 5 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(seething_rage_buff) or BuffExpires(inquisition_buff) and HolyPower() >= 3 } and RetributionFinishersCdPostConditions() or { not False(raid_event_adds_exists) or 600 > 15 or enemies(tagged=1) >= 2 } and { HolyPower() <= 0 or HolyPower() == 1 and SpellCooldown(blade_of_justice) > GCD() } and { SpellCooldown(avenging_wrath) > 10 or Talent(crusade_talent) and SpellCooldown(crusade) > 10 } and Spell(wake_of_ashes) or { HolyPower() <= 2 or HolyPower() == 3 and { SpellCooldown(hammer_of_wrath) > GCD() * 2 or HoW() } } and Spell(blade_of_justice) or { HolyPower() <= 2 or HolyPower() <= 4 and { SpellCooldown(blade_of_justice) > GCD() * 2 or HoW() } } and Spell(judgment) or HolyPower() <= 4 and Spell(hammer_of_wrath) or { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 } and Spell(consecration_retribution) or { Talent(hammer_of_wrath_talent) and target.HealthPercent() <= 20 or BuffPresent(avenging_wrath_buff) or BuffPresent(crusade_buff) } and RetributionFinishersCdPostConditions() or SpellCharges(crusader_strike count=0) >= 1.75 and { HolyPower() <= 2 or HolyPower() <= 3 and SpellCooldown(blade_of_justice) > GCD() * 2 or HolyPower() == 4 and SpellCooldown(blade_of_justice) > GCD() * 2 and SpellCooldown(judgment) > GCD() * 2 and SpellCooldown(consecration_retribution) > GCD() * 2 } and Spell(crusader_strike) or RetributionFinishersCdPostConditions() or Spell(concentrated_flame_essence) or HolyPower() <= 4 and Spell(crusader_strike)
}

### actions.precombat

AddFunction RetributionPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_focused_resolve usable=1)
}

AddFunction RetributionPrecombatMainPostConditions
{
}

AddFunction RetributionPrecombatShortCdActions
{
}

AddFunction RetributionPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
}

AddFunction RetributionPrecombatCdActions
{
 unless CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
 {
  #arcane_torrent,if=!talent.wake_of_ashes.enabled
  if not Talent(wake_of_ashes_talent) Spell(arcane_torrent_holy)
 }
}

AddFunction RetributionPrecombatCdPostConditions
{
 CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) and Item(item_potion_of_focused_resolve usable=1)
}

]]

		OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
	end
end
