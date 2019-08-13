local __exports = LibStub:NewLibrary("ovale/scripts/ovale_deathknight", 80201)
if not __exports then return end
__exports.registerDeathKnight = function(OvaleScripts)
    do
        local name = "sc_t23_death_knight_blood"
        local desc = "[8.2] Simulationcraft: T23_Death_Knight_Blood"
        local code = [[
# Based on SimulationCraft profile "T23_Death_Knight_Blood".
#	class=deathknight
#	spec=blood
#	talents=2220022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=blood)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=blood)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=blood)

AddFunction BloodInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
  if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction BloodUseHeartEssence
{
 Spell(concentrated_flame_essence)
}

AddFunction BloodUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction BloodGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.standard

AddFunction BloodStandardMainActions
{
 #death_strike,if=runic_power.deficit<=10
 if RunicPowerDeficit() <= 10 Spell(death_strike)
 #blooddrinker,if=!buff.dancing_rune_weapon.up
 if not BuffPresent(dancing_rune_weapon_buff) Spell(blooddrinker)
 #marrowrend,if=(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20
 if { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 Spell(marrowrend)
 #blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
 if Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } Spell(blood_boil)
 #marrowrend,if=buff.bone_shield.stack<5&talent.ossuary.enabled&runic_power.deficit>=15
 if BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 Spell(marrowrend)
 #death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.1.time_to_die<10
 if RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 Spell(death_strike)
 #heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd
 if BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() Spell(heart_strike)
 #blood_boil,if=buff.dancing_rune_weapon.up
 if BuffPresent(dancing_rune_weapon_buff) Spell(blood_boil)
 #consumption
 Spell(consumption)
 #blood_boil
 Spell(blood_boil)
 #heart_strike,if=rune.time_to_3<gcd|buff.bone_shield.stack>6
 if TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 Spell(heart_strike)
}

AddFunction BloodStandardMainPostConditions
{
}

AddFunction BloodStandardShortCdActions
{
 unless RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend)
 {
  #bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up
  if RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) Spell(bonestorm)

  unless { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike)
  {
   #death_and_decay,if=spell_targets.death_and_decay>=3
   if Enemies() >= 3 Spell(death_and_decay)
   #rune_strike,if=(charges_fractional>=1.8|buff.dancing_rune_weapon.up)&rune.time_to_3>=gcd
   if { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() Spell(rune_strike)

   unless { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil)
   {
    #death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2
    if BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 Spell(death_and_decay)

    unless Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
    {
     #rune_strike
     Spell(rune_strike)
    }
   }
  }
 }
}

AddFunction BloodStandardShortCdPostConditions
{
 RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
}

AddFunction BloodStandardCdActions
{
 unless RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend)
 {
  #heart_essence,if=!buff.dancing_rune_weapon.up
  if not BuffPresent(dancing_rune_weapon_buff) BloodUseHeartEssence()

  unless Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies() >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
  {
   #use_item,name=grongs_primal_rage
   BloodUseItemActions()

   unless Spell(rune_strike)
   {
    #arcane_torrent,if=runic_power.deficit>20
    if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
   }
  }
 }
}

AddFunction BloodStandardCdPostConditions
{
 RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies() >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike) or Spell(rune_strike)
}

### actions.precombat

AddFunction BloodPrecombatMainActions
{
}

AddFunction BloodPrecombatMainPostConditions
{
}

AddFunction BloodPrecombatShortCdActions
{
}

AddFunction BloodPrecombatShortCdPostConditions
{
}

AddFunction BloodPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)
}

AddFunction BloodPrecombatCdPostConditions
{
}

### actions.default

AddFunction BloodDefaultMainActions
{
 #call_action_list,name=standard
 BloodStandardMainActions()
}

AddFunction BloodDefaultMainPostConditions
{
 BloodStandardMainPostConditions()
}

AddFunction BloodDefaultShortCdActions
{
 #auto_attack
 BloodGetInMeleeRange()
 #tombstone,if=buff.bone_shield.stack>=7
 if BuffStacks(bone_shield_buff) >= 7 Spell(tombstone)
 #call_action_list,name=standard
 BloodStandardShortCdActions()
}

AddFunction BloodDefaultShortCdPostConditions
{
 BloodStandardShortCdPostConditions()
}

AddFunction BloodDefaultCdActions
{
 BloodInterruptActions()
 #blood_fury,if=cooldown.dancing_rune_weapon.ready&(!cooldown.blooddrinker.ready|!talent.blooddrinker.enabled)
 if SpellCooldown(dancing_rune_weapon) == 0 and { not SpellCooldown(blooddrinker) == 0 or not Talent(blooddrinker_talent) } Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #use_items,if=cooldown.dancing_rune_weapon.remains>90
 if SpellCooldown(dancing_rune_weapon) > 90 BloodUseItemActions()
 #use_item,name=razdunks_big_red_button
 BloodUseItemActions()
 #use_item,name=merekthas_fang
 BloodUseItemActions()
 #potion,if=buff.dancing_rune_weapon.up
 if BuffPresent(dancing_rune_weapon_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)
 #dancing_rune_weapon,if=!talent.blooddrinker.enabled|!cooldown.blooddrinker.ready
 if not Talent(blooddrinker_talent) or not SpellCooldown(blooddrinker) == 0 Spell(dancing_rune_weapon)

 unless BuffStacks(bone_shield_buff) >= 7 and Spell(tombstone)
 {
  #call_action_list,name=standard
  BloodStandardCdActions()
 }
}

AddFunction BloodDefaultCdPostConditions
{
 BuffStacks(bone_shield_buff) >= 7 and Spell(tombstone) or BloodStandardCdPostConditions()
}

### Blood icons.

AddCheckBox(opt_deathknight_blood_aoe L(AOE) default specialization=blood)

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=shortcd specialization=blood
{
 if not InCombat() BloodPrecombatShortCdActions()
 unless not InCombat() and BloodPrecombatShortCdPostConditions()
 {
  BloodDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_deathknight_blood_aoe help=shortcd specialization=blood
{
 if not InCombat() BloodPrecombatShortCdActions()
 unless not InCombat() and BloodPrecombatShortCdPostConditions()
 {
  BloodDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=blood
{
 if not InCombat() BloodPrecombatMainActions()
 unless not InCombat() and BloodPrecombatMainPostConditions()
 {
  BloodDefaultMainActions()
 }
}

AddIcon checkbox=opt_deathknight_blood_aoe help=aoe specialization=blood
{
 if not InCombat() BloodPrecombatMainActions()
 unless not InCombat() and BloodPrecombatMainPostConditions()
 {
  BloodDefaultMainActions()
 }
}

AddIcon checkbox=!opt_deathknight_blood_aoe enemies=1 help=cd specialization=blood
{
 if not InCombat() BloodPrecombatCdActions()
 unless not InCombat() and BloodPrecombatCdPostConditions()
 {
  BloodDefaultCdActions()
 }
}

AddIcon checkbox=opt_deathknight_blood_aoe help=cd specialization=blood
{
 if not InCombat() BloodPrecombatCdActions()
 unless not InCombat() and BloodPrecombatCdPostConditions()
 {
  BloodDefaultCdActions()
 }
}

### Required symbols
# arcane_torrent_runicpower
# asphyxiate
# berserking
# blood_boil
# blood_fury_ap
# blooddrinker
# blooddrinker_talent
# bone_shield_buff
# bonestorm
# concentrated_flame_essence
# consumption
# crimson_scourge_buff
# dancing_rune_weapon
# dancing_rune_weapon_buff
# death_and_decay
# death_strike
# heart_strike
# heartbreaker_talent
# hemostasis_buff
# item_battle_potion_of_strength
# marrowrend
# mind_freeze
# ossuary_talent
# rapid_decomposition_talent
# rune_strike
# tombstone
# war_stomp
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "blood", name, desc, code, "script")
    end
    do
        local name = "sc_t23_death_knight_frost"
        local desc = "[8.2] Simulationcraft: T23_Death_Knight_Frost"
        local code = [[
# Based on SimulationCraft profile "T23_Death_Knight_Frost".
#	class=deathknight
#	spec=frost
#	talents=3102013

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)


AddFunction other_on_use_equipped
{
 HasEquippedItem(notorious_gladiators_badge_item) or HasEquippedItem(sinister_gladiators_badge_item) or HasEquippedItem(sinister_gladiators_medallion_item) or HasEquippedItem(vial_of_animated_blood_item) or HasEquippedItem(first_mates_spyglass_item) or HasEquippedItem(jes_howler_item) or HasEquippedItem(notorious_gladiators_medallion_item)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=frost)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
  if target.Distance(less 12) and not target.Classification(worldboss) Spell(blinding_sleet)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction FrostUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction FrostGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.standard

AddFunction FrostStandardMainActions
{
 #remorseless_winter
 Spell(remorseless_winter)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=!buff.frozen_pulse.up&talent.frozen_pulse.enabled
 if not BuffPresent(frozen_pulse_buff) and Talent(frozen_pulse_talent) Spell(obliterate)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&rune.time_to_4>=gcd
 if BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() Spell(frostscythe)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #frost_strike
 Spell(frost_strike)
 #horn_of_winter
 Spell(horn_of_winter)
}

AddFunction FrostStandardMainPostConditions
{
}

AddFunction FrostStandardShortCdActions
{
}

AddFunction FrostStandardShortCdPostConditions
{
 Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or not BuffPresent(frozen_pulse_buff) and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
}

AddFunction FrostStandardCdActions
{
 unless Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or not BuffPresent(frozen_pulse_buff) and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
 {
  #arcane_torrent
  Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostStandardCdPostConditions
{
 Spell(remorseless_winter) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or not BuffPresent(frozen_pulse_buff) and Talent(frozen_pulse_talent) and Spell(obliterate) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and TimeToRunes(4) >= GCD() and Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(frost_strike) or Spell(horn_of_winter)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
}

AddFunction FrostPrecombatShortCdPostConditions
{
}

AddFunction FrostPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)
}

AddFunction FrostPrecombatCdPostConditions
{
}

### actions.obliteration

AddFunction FrostObliterationMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 Spell(obliterate)
 #obliterate,if=!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 Spell(obliterate)
 #frostscythe,if=(buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance)))&spell_targets.frostscythe>=2
 if { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Enemies() >= 2 Spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } Spell(obliterate)
 #obliterate,if=buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } Spell(obliterate)
 #glacial_advance,if=(!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd)&spell_targets.glacial_advance>=2
 if { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 Spell(glacial_advance)
 #howling_blast,if=buff.rime.up&spell_targets.howling_blast>=2
 if BuffPresent(rime_buff) and Enemies() >= 2 Spell(howling_blast)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() and not Talent(frostscythe_talent) Spell(frost_strike)
 #frost_strike,if=!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd
 if not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate
 Spell(obliterate)
}

AddFunction FrostObliterationMainPostConditions
{
}

AddFunction FrostObliterationShortCdActions
{
}

AddFunction FrostObliterationShortCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Enemies() >= 2 and Spell(frostscythe) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies() >= 2 and Spell(howling_blast) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() and not Talent(frostscythe_talent) } and Spell(frost_strike) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and Spell(obliterate) or Spell(obliterate)
}

AddFunction FrostObliterationCdActions
{
}

AddFunction FrostObliterationCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Enemies() >= 2 and Spell(frostscythe) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies() >= 2 and Spell(howling_blast) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() and not Talent(frostscythe_talent) } and Spell(frost_strike) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and Spell(obliterate) or Spell(obliterate)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up&dot.concentrated_flame_burn.remains=0
 if not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #chill_streak,if=buff.pillar_of_frost.remains<5|target.1.time_to_die<5
 if BuffRemaining(pillar_of_frost_buff) < 5 or target.TimeToDie() < 5 Spell(chill_streak)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<11
 if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 11 Spell(the_unbound_force)
 #focused_azerite_beam,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
 if not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) Spell(focused_azerite_beam)

 unless not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
 {
  #purifying_blast,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) Spell(purifying_blast)
  #worldvein_resonance,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) Spell(worldvein_resonance_essence)
  #ripple_in_space,if=!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up
  if not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) Spell(ripple_in_space_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 #blood_of_the_enemy,if=buff.pillar_of_frost.remains<10&cooldown.breath_of_sindragosa.remains|buff.pillar_of_frost.remains<10&!talent.breath_of_sindragosa.enabled
 if BuffRemaining(pillar_of_frost_buff) < 10 and SpellCooldown(breath_of_sindragosa) > 0 or BuffRemaining(pillar_of_frost_buff) < 10 and not Talent(breath_of_sindragosa_talent) Spell(blood_of_the_enemy)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)

 unless { BuffRemaining(pillar_of_frost_buff) < 5 or target.TimeToDie() < 5 } and Spell(chill_streak) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 11 } and Spell(the_unbound_force) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(focused_azerite_beam) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(purifying_blast) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(worldvein_resonance_essence) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(ripple_in_space_essence)
 {
  #memory_of_lucid_dreams,if=buff.empower_rune_weapon.remains<5&buff.breath_of_sindragosa.up|(rune.time_to_2>gcd&runic_power<50)
  if BuffRemaining(empower_rune_weapon_buff) < 5 and BuffPresent(breath_of_sindragosa_buff) or TimeToRunes(2) > GCD() and RunicPower() < 50 Spell(memory_of_lucid_dreams_essence)
 }
}

AddFunction FrostEssencesCdPostConditions
{
 { BuffRemaining(pillar_of_frost_buff) < 5 or target.TimeToDie() < 5 } and Spell(chill_streak) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 11 } and Spell(the_unbound_force) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(focused_azerite_beam) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(purifying_blast) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(worldvein_resonance_essence) or not BuffPresent(pillar_of_frost_buff) and not BuffPresent(breath_of_sindragosa_buff) and Spell(ripple_in_space_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
 if Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #pillar_of_frost,if=cooldown.empower_rune_weapon.remains
 if SpellCooldown(empower_rune_weapon) > 0 Spell(pillar_of_frost)
 #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
 if Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #use_item,name=azsharas_font_of_power,if=(cooldown.empowered_rune_weapon.ready&!variable.other_on_use_equipped)|(cooldown.pillar_of_frost.remains<=10&variable.other_on_use_equipped)
 if SpellCooldown(empower_rune_weapon) == 0 and not other_on_use_equipped() or SpellCooldown(pillar_of_frost) <= 10 and other_on_use_equipped() FrostUseItemActions()
 #use_item,name=lurkers_insidious_gift,if=talent.breath_of_sindragosa.enabled&((cooldown.pillar_of_frost.remains<=10&variable.other_on_use_equipped)|(buff.pillar_of_frost.up&!variable.other_on_use_equipped))|(buff.pillar_of_frost.up&!talent.breath_of_sindragosa.enabled)
 if Talent(breath_of_sindragosa_talent) and { SpellCooldown(pillar_of_frost) <= 10 and other_on_use_equipped() or BuffPresent(pillar_of_frost_buff) and not other_on_use_equipped() } or BuffPresent(pillar_of_frost_buff) and not Talent(breath_of_sindragosa_talent) FrostUseItemActions()
 #use_item,name=cyclotronic_blast,if=!buff.pillar_of_frost.up
 if not BuffPresent(pillar_of_frost_buff) FrostUseItemActions()
 #use_item,name=ashvanes_razor_coral,if=cooldown.empower_rune_weapon.remains>110|cooldown.breath_of_sindragosa.remains>90|time<50|target.1.time_to_die<21
 if SpellCooldown(empower_rune_weapon) > 110 or SpellCooldown(breath_of_sindragosa) > 90 or TimeInCombat() < 50 or target.TimeToDie() < 21 FrostUseItemActions()
 #use_items,if=(cooldown.pillar_of_frost.ready|cooldown.pillar_of_frost.remains>20)&(!talent.breath_of_sindragosa.enabled|cooldown.empower_rune_weapon.remains>95)
 if { SpellCooldown(pillar_of_frost) == 0 or SpellCooldown(pillar_of_frost) > 20 } and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(empower_rune_weapon) > 95 } FrostUseItemActions()
 #use_item,name=jes_howler,if=(equipped.lurkers_insidious_gift&buff.pillar_of_frost.remains)|(!equipped.lurkers_insidious_gift&buff.pillar_of_frost.remains<12&buff.pillar_of_frost.up)
 if HasEquippedItem(lurkers_insidious_gift_item) and BuffPresent(pillar_of_frost_buff) or not HasEquippedItem(lurkers_insidious_gift_item) and BuffRemaining(pillar_of_frost_buff) < 12 and BuffPresent(pillar_of_frost_buff) FrostUseItemActions()
 #use_item,name=knot_of_ancient_fury,if=cooldown.empower_rune_weapon.remains>40
 if SpellCooldown(empower_rune_weapon) > 40 FrostUseItemActions()
 #use_item,name=grongs_primal_rage,if=rune<=3&!buff.pillar_of_frost.up&(!buff.breath_of_sindragosa.up|!talent.breath_of_sindragosa.enabled)
 if RuneCount() <= 3 and not BuffPresent(pillar_of_frost_buff) and { not BuffPresent(breath_of_sindragosa_buff) or not Talent(breath_of_sindragosa_talent) } FrostUseItemActions()
 #use_item,name=razdunks_big_red_button
 FrostUseItemActions()
 #use_item,name=merekthas_fang,if=!buff.breath_of_sindragosa.up&!buff.pillar_of_frost.up
 if not BuffPresent(breath_of_sindragosa_buff) and not BuffPresent(pillar_of_frost_buff) FrostUseItemActions()
 #potion,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)
 #blood_fury,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) Spell(blood_fury_ap)
 #berserking,if=buff.pillar_of_frost.up
 if BuffPresent(pillar_of_frost_buff) Spell(berserking)

 unless SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost)
 {
  #breath_of_sindragosa,use_off_gcd=1,if=cooldown.empower_rune_weapon.remains&cooldown.pillar_of_frost.remains
  if SpellCooldown(empower_rune_weapon) > 0 and SpellCooldown(pillar_of_frost) > 0 Spell(breath_of_sindragosa)
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&!talent.breath_of_sindragosa.enabled&rune.time_to_5>gcd&runic_power.deficit>=10|target.1.time_to_die<20
  if SpellCooldown(pillar_of_frost) == 0 and not Talent(breath_of_sindragosa_talent) and TimeToRunes(5) > GCD() and RunicPowerDeficit() >= 10 or target.TimeToDie() < 20 Spell(empower_rune_weapon)
  #empower_rune_weapon,if=(cooldown.pillar_of_frost.ready|target.1.time_to_die<20)&talent.breath_of_sindragosa.enabled&runic_power>60
  if { SpellCooldown(pillar_of_frost) == 0 or target.TimeToDie() < 20 } and Talent(breath_of_sindragosa_talent) and RunicPower() > 60 Spell(empower_rune_weapon)
  #call_action_list,name=cold_heart,if=talent.cold_heart.enabled&((buff.cold_heart.stack>=10&debuff.razorice.stack=5)|target.1.time_to_die<=gcd)
  if Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartCdActions()

  unless Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartCdPostConditions()
  {
   #frostwyrms_fury,if=(buff.pillar_of_frost.remains<=gcd|(buff.pillar_of_frost.remains<8&buff.unholy_strength.remains<=gcd&buff.unholy_strength.up))&buff.pillar_of_frost.up&azerite.icy_citadel.rank<=2
   if { BuffRemaining(pillar_of_frost_buff) <= GCD() or BuffRemaining(pillar_of_frost_buff) < 8 and BuffRemaining(unholy_strength_buff) <= GCD() and BuffPresent(unholy_strength_buff) } and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 Spell(frostwyrms_fury)
   #frostwyrms_fury,if=(buff.icy_citadel.remains<=gcd|(buff.icy_citadel.remains<8&buff.unholy_strength.remains<=gcd&buff.unholy_strength.up))&buff.icy_citadel.up&azerite.icy_citadel.rank>2
   if { BuffRemaining(icy_citadel_buff) <= GCD() or BuffRemaining(icy_citadel_buff) < 8 and BuffRemaining(unholy_strength_buff) <= GCD() and BuffPresent(unholy_strength_buff) } and BuffPresent(icy_citadel_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 Spell(frostwyrms_fury)
   #frostwyrms_fury,if=target.1.time_to_die<gcd|(target.1.time_to_die<cooldown.pillar_of_frost.remains&buff.unholy_strength.up)
   if target.TimeToDie() < GCD() or target.TimeToDie() < SpellCooldown(pillar_of_frost) and BuffPresent(unholy_strength_buff) Spell(frostwyrms_fury)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost) or Talent(cold_heart_talent) and { BuffStacks(cold_heart_buff) >= 10 and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartCdPostConditions()
}

### actions.cold_heart

AddFunction FrostColdheartMainActions
{
 #chains_of_ice,if=buff.cold_heart.stack>5&target.1.time_to_die<gcd
 if BuffStacks(cold_heart_buff) > 5 and target.TimeToDie() < GCD() Spell(chains_of_ice)
 #chains_of_ice,if=(buff.pillar_of_frost.remains<=gcd*(1+cooldown.frostwyrms_fury.ready)|buff.pillar_of_frost.remains<rune.time_to_3)&buff.pillar_of_frost.up&azerite.icy_citadel.rank<=2
 if { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 Spell(chains_of_ice)
 #chains_of_ice,if=buff.pillar_of_frost.remains<8&buff.unholy_strength.remains<gcd*(1+cooldown.frostwyrms_fury.ready)&buff.unholy_strength.remains&buff.pillar_of_frost.up&azerite.icy_citadel.rank<=2
 if BuffRemaining(pillar_of_frost_buff) < 8 and BuffRemaining(unholy_strength_buff) < GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } and BuffPresent(unholy_strength_buff) and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 Spell(chains_of_ice)
 #chains_of_ice,if=(buff.icy_citadel.remains<4|buff.icy_citadel.remains<rune.time_to_3)&buff.icy_citadel.up&azerite.icy_citadel.rank>2
 if { BuffRemaining(icy_citadel_buff) < 4 or BuffRemaining(icy_citadel_buff) < TimeToRunes(3) } and BuffPresent(icy_citadel_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 Spell(chains_of_ice)
 #chains_of_ice,if=buff.icy_citadel.up&buff.unholy_strength.up&azerite.icy_citadel.rank>2
 if BuffPresent(icy_citadel_buff) and BuffPresent(unholy_strength_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 Spell(chains_of_ice)
}

AddFunction FrostColdheartMainPostConditions
{
}

AddFunction FrostColdheartShortCdActions
{
}

AddFunction FrostColdheartShortCdPostConditions
{
 BuffStacks(cold_heart_buff) > 5 and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 and Spell(chains_of_ice) or BuffRemaining(pillar_of_frost_buff) < 8 and BuffRemaining(unholy_strength_buff) < GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } and BuffPresent(unholy_strength_buff) and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 and Spell(chains_of_ice) or { BuffRemaining(icy_citadel_buff) < 4 or BuffRemaining(icy_citadel_buff) < TimeToRunes(3) } and BuffPresent(icy_citadel_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 and Spell(chains_of_ice) or BuffPresent(icy_citadel_buff) and BuffPresent(unholy_strength_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 and Spell(chains_of_ice)
}

AddFunction FrostColdheartCdActions
{
}

AddFunction FrostColdheartCdPostConditions
{
 BuffStacks(cold_heart_buff) > 5 and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 and Spell(chains_of_ice) or BuffRemaining(pillar_of_frost_buff) < 8 and BuffRemaining(unholy_strength_buff) < GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } and BuffPresent(unholy_strength_buff) and BuffPresent(pillar_of_frost_buff) and AzeriteTraitRank(icy_citadel_trait) <= 2 and Spell(chains_of_ice) or { BuffRemaining(icy_citadel_buff) < 4 or BuffRemaining(icy_citadel_buff) < TimeToRunes(3) } and BuffPresent(icy_citadel_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 and Spell(chains_of_ice) or BuffPresent(icy_citadel_buff) and BuffPresent(unholy_strength_buff) and AzeriteTraitRank(icy_citadel_trait) > 2 and Spell(chains_of_ice)
}

### actions.bos_ticking

AddFunction FrostBostickingMainActions
{
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power<=30&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPower() <= 30 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=runic_power<=32
 if RunicPower() <= 32 Spell(obliterate)
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&rune.time_to_5<gcd|runic_power<=45&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and TimeToRunes(5) < GCD() or RunicPower() <= 45 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=rune.time_to_5<gcd|runic_power<=45
 if TimeToRunes(5) < GCD() or RunicPower() <= 45 Spell(obliterate)
 #frostscythe,if=buff.killing_machine.up&spell_targets.frostscythe>=2
 if BuffPresent(killing_machine_buff) and Enemies() >= 2 Spell(frostscythe)
 #horn_of_winter,if=runic_power.deficit>=32&rune.time_to_3>gcd
 if RunicPowerDeficit() >= 32 and TimeToRunes(3) > GCD() Spell(horn_of_winter)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe,if=spell_targets.frostscythe>=2
 if Enemies() >= 2 Spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>25|rune>3&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 or RuneCount() > 3 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=runic_power.deficit>25|rune>3
 if RunicPowerDeficit() > 25 or RuneCount() > 3 Spell(obliterate)
}

AddFunction FrostBostickingMainPostConditions
{
}

AddFunction FrostBostickingShortCdActions
{
}

AddFunction FrostBostickingShortCdPostConditions
{
 { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPower() <= 30 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPower() <= 32 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and TimeToRunes(5) < GCD() or RunicPower() <= 45 and not Talent(frostscythe_talent) } and Spell(obliterate) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Enemies() >= 2 and Spell(frostscythe) or RunicPowerDeficit() >= 32 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 or RuneCount() > 3 and not Talent(frostscythe_talent) } and Spell(obliterate) or { RunicPowerDeficit() > 25 or RuneCount() > 3 } and Spell(obliterate)
}

AddFunction FrostBostickingCdActions
{
 unless { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPower() <= 30 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPower() <= 32 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and TimeToRunes(5) < GCD() or RunicPower() <= 45 and not Talent(frostscythe_talent) } and Spell(obliterate) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Enemies() >= 2 and Spell(frostscythe) or RunicPowerDeficit() >= 32 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 or RuneCount() > 3 and not Talent(frostscythe_talent) } and Spell(obliterate) or { RunicPowerDeficit() > 25 or RuneCount() > 3 } and Spell(obliterate)
 {
  #arcane_torrent,if=runic_power.deficit>20
  if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostBostickingCdPostConditions
{
 { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPower() <= 30 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPower() <= 32 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and TimeToRunes(5) < GCD() or RunicPower() <= 45 and not Talent(frostscythe_talent) } and Spell(obliterate) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Enemies() >= 2 and Spell(frostscythe) or RunicPowerDeficit() >= 32 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 or RuneCount() > 3 and not Talent(frostscythe_talent) } and Spell(obliterate) or { RunicPowerDeficit() > 25 or RuneCount() > 3 } and Spell(obliterate)
}

### actions.bos_pooling

AddFunction FrostBospoolingMainActions
{
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&&runic_power.deficit>=25&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 25 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=runic_power.deficit>=25
 if RunicPowerDeficit() >= 25 Spell(obliterate)
 #glacial_advance,if=runic_power.deficit<20&spell_targets.glacial_advance>=2&cooldown.pillar_of_frost.remains>5
 if RunicPowerDeficit() < 20 and Enemies() >= 2 and SpellCooldown(pillar_of_frost) > 5 Spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit<20&!talent.frostscythe.enabled&cooldown.pillar_of_frost.remains>5
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 20 and not Talent(frostscythe_talent) and SpellCooldown(pillar_of_frost) > 5 Spell(frost_strike)
 #frost_strike,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>5
 if RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > 5 Spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&runic_power.deficit>(15+talent.runic_attenuation.enabled*3)&spell_targets.frostscythe>=2
 if BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 Spell(frostscythe)
 #frostscythe,if=runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)&spell_targets.frostscythe>=2
 if RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 Spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=runic_power.deficit>=(35+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&spell_targets.glacial_advance>=2
 if SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 Spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and not Talent(frostscythe_talent) Spell(frost_strike)
 #frost_strike,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40
 if SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 Spell(frost_strike)
}

AddFunction FrostBospoolingMainPostConditions
{
}

AddFunction FrostBospoolingShortCdActions
{
}

AddFunction FrostBospoolingShortCdPostConditions
{
 BuffPresent(rime_buff) and Spell(howling_blast) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 25 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and Enemies() >= 2 and SpellCooldown(pillar_of_frost) > 5 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 20 and not Talent(frostscythe_talent) and SpellCooldown(pillar_of_frost) > 5 and Spell(frost_strike) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > 5 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 and Spell(frostscythe) or RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 and Spell(frostscythe) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and not Talent(frostscythe_talent) and Spell(frost_strike) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

AddFunction FrostBospoolingCdActions
{
}

AddFunction FrostBospoolingCdPostConditions
{
 BuffPresent(rime_buff) and Spell(howling_blast) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 25 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and Enemies() >= 2 and SpellCooldown(pillar_of_frost) > 5 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 20 and not Talent(frostscythe_talent) and SpellCooldown(pillar_of_frost) > 5 and Spell(frost_strike) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > 5 and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 and Spell(frostscythe) or RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and Enemies() >= 2 and Spell(frostscythe) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() >= 35 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and not Talent(frostscythe_talent) and Spell(frost_strike) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled|(azerite.frozen_tempest.rank&spell_targets.remorseless_winter>=3&!buff.rime.up)
 if Talent(gathering_storm_talent) or AzeriteTraitRank(frozen_tempest_trait) and Enemies() >= 3 and not BuffPresent(rime_buff) Spell(remorseless_winter)
 #glacial_advance,if=talent.frostscythe.enabled
 if Talent(frostscythe_talent) Spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and not Talent(frostscythe_talent) Spell(frost_strike)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #frostscythe,if=buff.killing_machine.up
 if BuffPresent(killing_machine_buff) Spell(frostscythe)
 #glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit<(15+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) Spell(frost_strike)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) Spell(frost_strike)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe
 Spell(frostscythe)
 #obliterate,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&runic_power.deficit>(25+talent.runic_attenuation.enabled*3)&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) Spell(obliterate)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance
 Spell(glacial_advance)
 #frost_strike,target_if=(debuff.razorice.stack<5|debuff.razorice.remains<10)&!talent.frostscythe.enabled
 if { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) Spell(frost_strike)
 #frost_strike
 Spell(frost_strike)
 #horn_of_winter
 Spell(horn_of_winter)
}

AddFunction FrostAoeMainPostConditions
{
}

AddFunction FrostAoeShortCdActions
{
}

AddFunction FrostAoeShortCdPostConditions
{
 { Talent(gathering_storm_talent) or AzeriteTraitRank(frozen_tempest_trait) and Enemies() >= 3 and not BuffPresent(rime_buff) } and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and not Talent(frostscythe_talent) and Spell(frost_strike) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(frost_strike) or Spell(horn_of_winter)
}

AddFunction FrostAoeCdActions
{
 unless { Talent(gathering_storm_talent) or AzeriteTraitRank(frozen_tempest_trait) and Enemies() >= 3 and not BuffPresent(rime_buff) } and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and not Talent(frostscythe_talent) and Spell(frost_strike) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(frost_strike) or Spell(horn_of_winter)
 {
  #arcane_torrent
  Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostAoeCdPostConditions
{
 { Talent(gathering_storm_talent) or AzeriteTraitRank(frozen_tempest_trait) and Enemies() >= 3 and not BuffPresent(rime_buff) } and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and not Talent(frostscythe_talent) and Spell(frost_strike) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and not Talent(frostscythe_talent) and Spell(obliterate) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or { target.DebuffStacks(razorice_debuff) < 5 or target.DebuffRemaining(razorice_debuff) < 10 } and not Talent(frostscythe_talent) and Spell(frost_strike) or Spell(frost_strike) or Spell(horn_of_winter)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #howling_blast,if=!dot.frost_fever.ticking&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(howling_blast)
 #glacial_advance,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&spell_targets.glacial_advance>=2&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(glacial_advance)
 #frost_strike,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
 if BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } Spell(frost_strike)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #call_action_list,name=cooldowns
  FrostCooldownsMainActions()

  unless FrostCooldownsMainPostConditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
   if Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } FrostBospoolingMainActions()

   unless Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingMainPostConditions()
   {
    #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
    if BuffPresent(breath_of_sindragosa_buff) FrostBostickingMainActions()

    unless BuffPresent(breath_of_sindragosa_buff) and FrostBostickingMainPostConditions()
    {
     #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
     if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationMainActions()

     unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationMainPostConditions()
     {
      #run_action_list,name=aoe,if=active_enemies>=2
      if Enemies() >= 2 FrostAoeMainActions()

      unless Enemies() >= 2 and FrostAoeMainPostConditions()
      {
       #call_action_list,name=standard
       FrostStandardMainActions()
      }
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostCooldownsMainPostConditions() or Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingMainPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingMainPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationMainPostConditions() or Enemies() >= 2 and FrostAoeMainPostConditions() or FrostStandardMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #auto_attack
 FrostGetInMeleeRange()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #call_action_list,name=cooldowns
   FrostCooldownsShortCdActions()

   unless FrostCooldownsShortCdPostConditions()
   {
    #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
    if Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } FrostBospoolingShortCdActions()

    unless Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingShortCdPostConditions()
    {
     #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
     if BuffPresent(breath_of_sindragosa_buff) FrostBostickingShortCdActions()

     unless BuffPresent(breath_of_sindragosa_buff) and FrostBostickingShortCdPostConditions()
     {
      #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
      if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationShortCdActions()

      unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationShortCdPostConditions()
      {
       #run_action_list,name=aoe,if=active_enemies>=2
       if Enemies() >= 2 FrostAoeShortCdActions()

       unless Enemies() >= 2 and FrostAoeShortCdPostConditions()
       {
        #call_action_list,name=standard
        FrostStandardShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostEssencesShortCdPostConditions() or FrostCooldownsShortCdPostConditions() or Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingShortCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingShortCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationShortCdPostConditions() or Enemies() >= 2 and FrostAoeShortCdPostConditions() or FrostStandardShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 FrostInterruptActions()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions()
  {
   #call_action_list,name=cooldowns
   FrostCooldownsCdActions()

   unless FrostCooldownsCdPostConditions()
   {
    #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&((cooldown.breath_of_sindragosa.remains=0&cooldown.pillar_of_frost.remains<10)|(cooldown.breath_of_sindragosa.remains<20&target.1.time_to_die<35))
    if Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } FrostBospoolingCdActions()

    unless Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingCdPostConditions()
    {
     #run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up
     if BuffPresent(breath_of_sindragosa_buff) FrostBostickingCdActions()

     unless BuffPresent(breath_of_sindragosa_buff) and FrostBostickingCdPostConditions()
     {
      #run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration.enabled
      if BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) FrostObliterationCdActions()

      unless BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationCdPostConditions()
      {
       #run_action_list,name=aoe,if=active_enemies>=2
       if Enemies() >= 2 FrostAoeCdActions()

       unless Enemies() >= 2 and FrostAoeCdPostConditions()
       {
        #call_action_list,name=standard
        FrostStandardCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostEssencesCdPostConditions() or FrostCooldownsCdPostConditions() or Talent(breath_of_sindragosa_talent) and { not SpellCooldown(breath_of_sindragosa) > 0 and SpellCooldown(pillar_of_frost) < 10 or SpellCooldown(breath_of_sindragosa) < 20 and target.TimeToDie() < 35 } and FrostBospoolingCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationCdPostConditions() or Enemies() >= 2 and FrostAoeCdPostConditions() or FrostStandardCdPostConditions()
}

### Frost icons.

AddCheckBox(opt_deathknight_frost_aoe L(AOE) default specialization=frost)

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not InCombat() FrostPrecombatShortCdActions()
 unless not InCombat() and FrostPrecombatShortCdPostConditions()
 {
  FrostDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_deathknight_frost_aoe help=shortcd specialization=frost
{
 if not InCombat() FrostPrecombatShortCdActions()
 unless not InCombat() and FrostPrecombatShortCdPostConditions()
 {
  FrostDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=frost
{
 if not InCombat() FrostPrecombatMainActions()
 unless not InCombat() and FrostPrecombatMainPostConditions()
 {
  FrostDefaultMainActions()
 }
}

AddIcon checkbox=opt_deathknight_frost_aoe help=aoe specialization=frost
{
 if not InCombat() FrostPrecombatMainActions()
 unless not InCombat() and FrostPrecombatMainPostConditions()
 {
  FrostDefaultMainActions()
 }
}

AddIcon checkbox=!opt_deathknight_frost_aoe enemies=1 help=cd specialization=frost
{
 if not InCombat() FrostPrecombatCdActions()
 unless not InCombat() and FrostPrecombatCdPostConditions()
 {
  FrostDefaultCdActions()
 }
}

AddIcon checkbox=opt_deathknight_frost_aoe help=cd specialization=frost
{
 if not InCombat() FrostPrecombatCdActions()
 unless not InCombat() and FrostPrecombatCdPostConditions()
 {
  FrostDefaultCdActions()
 }
}

### Required symbols
# arcane_torrent_runicpower
# berserking
# blinding_sleet
# blood_fury_ap
# blood_of_the_enemy
# breath_of_sindragosa
# breath_of_sindragosa_buff
# breath_of_sindragosa_talent
# chains_of_ice
# chill_streak
# cold_heart_buff
# cold_heart_talent
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# death_strike
# empower_rune_weapon
# empower_rune_weapon_buff
# first_mates_spyglass_item
# focused_azerite_beam
# frost_fever_debuff
# frost_strike
# frostscythe
# frostscythe_talent
# frostwyrms_fury
# frozen_pulse_buff
# frozen_pulse_talent
# frozen_tempest_trait
# gathering_storm_talent
# glacial_advance
# guardian_of_azeroth
# horn_of_winter
# howling_blast
# icy_citadel_buff
# icy_citadel_trait
# icy_talons_buff
# item_battle_potion_of_strength
# jes_howler_item
# killing_machine_buff
# lurkers_insidious_gift_item
# memory_of_lucid_dreams_essence
# mind_freeze
# notorious_gladiators_badge_item
# notorious_gladiators_medallion_item
# obliterate
# obliteration_talent
# pillar_of_frost
# pillar_of_frost_buff
# purifying_blast
# razorice_debuff
# reckless_force_buff
# reckless_force_counter
# remorseless_winter
# rime_buff
# ripple_in_space_essence
# runic_attenuation_talent
# sinister_gladiators_badge_item
# sinister_gladiators_medallion_item
# the_unbound_force
# unholy_strength_buff
# vial_of_animated_blood_item
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t23_death_knight_unholy"
        local desc = "[8.2] Simulationcraft: T23_Death_Knight_Unholy"
        local code = [[
# Based on SimulationCraft profile "T23_Death_Knight_Unholy".
#	class=deathknight
#	spec=unholy
#	talents=2203032

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)


AddFunction pooling_for_gargoyle
{
 SpellCooldown(summon_gargoyle) < 5 and Talent(summon_gargoyle_talent)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=unholy)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=unholy)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=unholy)

AddFunction UnholyInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
  if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction UnholyUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction UnholyGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.precombat

AddFunction UnholyPrecombatMainActions
{
}

AddFunction UnholyPrecombatMainPostConditions
{
}

AddFunction UnholyPrecombatShortCdActions
{
 #raise_dead
 Spell(raise_dead)
}

AddFunction UnholyPrecombatShortCdPostConditions
{
}

AddFunction UnholyPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)

 unless Spell(raise_dead)
 {
  #use_item,name=azsharas_font_of_power
  UnholyUseItemActions()
  #army_of_the_dead,delay=2
  Spell(army_of_the_dead)
 }
}

AddFunction UnholyPrecombatCdPostConditions
{
 Spell(raise_dead)
}

### actions.generic

AddFunction UnholyGenericMainActions
{
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() Spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() Spell(death_coil)
 #defile,if=cooldown.apocalypse.remains
 if SpellCooldown(apocalypse) > 0 Spell(defile)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 Spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(death_coil)
}

AddFunction UnholyGenericMainPostConditions
{
}

AddFunction UnholyGenericShortCdActions
{
 unless { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil)
 {
  #death_and_decay,if=talent.pestilence.enabled&cooldown.apocalypse.remains
  if Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 Spell(death_and_decay)
 }
}

AddFunction UnholyGenericShortCdPostConditions
{
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or SpellCooldown(apocalypse) > 0 and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyGenericCdActions
{
}

AddFunction UnholyGenericCdPostConditions
{
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 and Spell(death_and_decay) or SpellCooldown(apocalypse) > 0 and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.essences

AddFunction UnholyEssencesMainActions
{
 #concentrated_flame,if=dot.concentrated_flame_burn.remains=0
 if not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 Spell(concentrated_flame_essence)
}

AddFunction UnholyEssencesMainPostConditions
{
}

AddFunction UnholyEssencesShortCdActions
{
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<11
 if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 11 Spell(the_unbound_force)
 #focused_azerite_beam,if=!death_and_decay.ticking
 if not BuffPresent(death_and_decay) Spell(focused_azerite_beam)

 unless not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
 {
  #purifying_blast,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(purifying_blast)
  #worldvein_resonance,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(worldvein_resonance_essence)
  #ripple_in_space,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(ripple_in_space_essence)
 }
}

AddFunction UnholyEssencesShortCdPostConditions
{
 not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
}

AddFunction UnholyEssencesCdActions
{
 #memory_of_lucid_dreams,if=rune.time_to_1>gcd&runic_power<40
 if TimeToRunes(1) > GCD() and RunicPower() < 40 Spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=(cooldown.death_and_decay.remains&spell_targets.death_and_decay>1)|(cooldown.defile.remains&spell_targets.defile>1)|(cooldown.apocalypse.remains&cooldown.death_and_decay.ready)
 if SpellCooldown(death_and_decay) > 0 and Enemies() > 1 or SpellCooldown(defile) > 0 and Enemies() > 1 or SpellCooldown(apocalypse) > 0 and SpellCooldown(death_and_decay) == 0 Spell(blood_of_the_enemy)
 #guardian_of_azeroth,if=cooldown.apocalypse.ready
 if SpellCooldown(apocalypse) == 0 Spell(guardian_of_azeroth)
}

AddFunction UnholyEssencesCdPostConditions
{
 { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 11 } and Spell(the_unbound_force) or not BuffPresent(death_and_decay) and Spell(focused_azerite_beam) or not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or not BuffPresent(death_and_decay) and Spell(purifying_blast) or not BuffPresent(death_and_decay) and Spell(worldvein_resonance_essence) or not BuffPresent(death_and_decay) and Spell(ripple_in_space_essence)
}

### actions.cooldowns

AddFunction UnholyCooldownsMainActions
{
}

AddFunction UnholyCooldownsMainPostConditions
{
}

AddFunction UnholyCooldownsShortCdActions
{
 #apocalypse,if=debuff.festering_wound.stack>=4
 if target.DebuffStacks(festering_wound_debuff) >= 4 Spell(apocalypse)
 #dark_transformation,if=!raid_event.adds.exists|raid_event.adds.in>15
 if not False(raid_event_adds_exists) or 600 > 15 Spell(dark_transformation)
 #unholy_frenzy,if=debuff.festering_wound.stack<4&!(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)
 if target.DebuffStacks(festering_wound_debuff) < 4 and not { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } Spell(unholy_frenzy)
 #unholy_frenzy,if=cooldown.apocalypse.remains<2&(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)
 if SpellCooldown(apocalypse) < 2 and { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } Spell(unholy_frenzy)
 #unholy_frenzy,if=active_enemies>=2&((cooldown.death_and_decay.remains<=gcd&!talent.defile.enabled)|(cooldown.defile.remains<=gcd&talent.defile.enabled))
 if Enemies() >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } Spell(unholy_frenzy)
 #soul_reaper,target_if=target.time_to_die<8&target.time_to_die>4
 if target.TimeToDie() < 8 and target.TimeToDie() > 4 Spell(soul_reaper)
 #soul_reaper,if=(!raid_event.adds.exists|raid_event.adds.in>20)&rune<=(1-buff.unholy_frenzy.up)
 if { not False(raid_event_adds_exists) or 600 > 20 } and RuneCount() <= 1 - BuffPresent(unholy_frenzy_buff) Spell(soul_reaper)
 #unholy_blight
 Spell(unholy_blight)
}

AddFunction UnholyCooldownsShortCdPostConditions
{
}

AddFunction UnholyCooldownsCdActions
{
 #army_of_the_dead
 Spell(army_of_the_dead)

 unless target.DebuffStacks(festering_wound_debuff) >= 4 and Spell(apocalypse) or { not False(raid_event_adds_exists) or 600 > 15 } and Spell(dark_transformation)
 {
  #summon_gargoyle,if=runic_power.deficit<14
  if RunicPowerDeficit() < 14 Spell(summon_gargoyle)
 }
}

AddFunction UnholyCooldownsCdPostConditions
{
 target.DebuffStacks(festering_wound_debuff) >= 4 and Spell(apocalypse) or { not False(raid_event_adds_exists) or 600 > 15 } and Spell(dark_transformation) or target.DebuffStacks(festering_wound_debuff) < 4 and not { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and Spell(unholy_frenzy) or SpellCooldown(apocalypse) < 2 and { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and Spell(unholy_frenzy) or Enemies() >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } and Spell(unholy_frenzy) or target.TimeToDie() < 8 and target.TimeToDie() > 4 and Spell(soul_reaper) or { not False(raid_event_adds_exists) or 600 > 20 } and RuneCount() <= 1 - BuffPresent(unholy_frenzy_buff) and Spell(soul_reaper) or Spell(unholy_blight)
}

### actions.aoe

AddFunction UnholyAoeMainActions
{
 #defile
 Spell(defile)
 #epidemic,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() Spell(epidemic)
 #death_coil,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 Spell(scourge_strike)
 #clawing_shadows,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 Spell(clawing_shadows)
 #epidemic,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(epidemic)
 #festering_strike,target_if=debuff.festering_wound.stack<=1&cooldown.death_and_decay.remains
 if target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 Spell(festering_strike)
 #festering_strike,if=talent.bursting_sores.enabled&spell_targets.bursting_sores>=2&debuff.festering_wound.stack<=1
 if Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 Spell(festering_strike)
 #death_coil,if=buff.sudden_doom.react&rune.deficit>=4
 if BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 Spell(death_coil)
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() Spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 Spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(death_coil)
}

AddFunction UnholyAoeMainPostConditions
{
}

AddFunction UnholyAoeShortCdActions
{
 #death_and_decay,if=cooldown.apocalypse.remains
 if SpellCooldown(apocalypse) > 0 Spell(death_and_decay)
}

AddFunction UnholyAoeShortCdPostConditions
{
 Spell(defile) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(epidemic) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and Spell(epidemic) or target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 and Spell(festering_strike) or Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyAoeCdActions
{
}

AddFunction UnholyAoeCdPostConditions
{
 SpellCooldown(apocalypse) > 0 and Spell(death_and_decay) or Spell(defile) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(epidemic) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and Spell(epidemic) or target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 and Spell(festering_strike) or Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.default

AddFunction UnholyDefaultMainActions
{
 #outbreak,target_if=dot.virulent_plague.remains<=gcd
 if target.DebuffRemaining(virulent_plague_debuff) <= GCD() Spell(outbreak)
 #call_action_list,name=essences
 UnholyEssencesMainActions()

 unless UnholyEssencesMainPostConditions()
 {
  #call_action_list,name=cooldowns
  UnholyCooldownsMainActions()

  unless UnholyCooldownsMainPostConditions()
  {
   #run_action_list,name=aoe,if=active_enemies>=2
   if Enemies() >= 2 UnholyAoeMainActions()

   unless Enemies() >= 2 and UnholyAoeMainPostConditions()
   {
    #call_action_list,name=generic
    UnholyGenericMainActions()
   }
  }
 }
}

AddFunction UnholyDefaultMainPostConditions
{
 UnholyEssencesMainPostConditions() or UnholyCooldownsMainPostConditions() or Enemies() >= 2 and UnholyAoeMainPostConditions() or UnholyGenericMainPostConditions()
}

AddFunction UnholyDefaultShortCdActions
{
 #auto_attack
 UnholyGetInMeleeRange()

 unless target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
 {
  #call_action_list,name=essences
  UnholyEssencesShortCdActions()

  unless UnholyEssencesShortCdPostConditions()
  {
   #call_action_list,name=cooldowns
   UnholyCooldownsShortCdActions()

   unless UnholyCooldownsShortCdPostConditions()
   {
    #run_action_list,name=aoe,if=active_enemies>=2
    if Enemies() >= 2 UnholyAoeShortCdActions()

    unless Enemies() >= 2 and UnholyAoeShortCdPostConditions()
    {
     #call_action_list,name=generic
     UnholyGenericShortCdActions()
    }
   }
  }
 }
}

AddFunction UnholyDefaultShortCdPostConditions
{
 target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyEssencesShortCdPostConditions() or UnholyCooldownsShortCdPostConditions() or Enemies() >= 2 and UnholyAoeShortCdPostConditions() or UnholyGenericShortCdPostConditions()
}

AddFunction UnholyDefaultCdActions
{
 UnholyInterruptActions()
 #variable,name=pooling_for_gargoyle,value=cooldown.summon_gargoyle.remains<5&talent.summon_gargoyle.enabled
 #arcane_torrent,if=runic_power.deficit>65&(pet.gargoyle.active|!talent.summon_gargoyle.enabled)&rune.deficit>=5
 if RunicPowerDeficit() > 65 and { pet.Present() or not Talent(summon_gargoyle_talent) } and RuneDeficit() >= 5 Spell(arcane_torrent_runicpower)
 #blood_fury,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.Present() or not Talent(summon_gargoyle_talent) Spell(blood_fury_ap)
 #berserking,if=buff.unholy_frenzy.up|pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if BuffPresent(unholy_frenzy_buff) or pet.Present() or not Talent(summon_gargoyle_talent) Spell(berserking)
 #use_items,if=time>20|!equipped.ramping_amplitude_gigavolt_engine|!equipped.vision_of_demise
 if TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or not HasEquippedItem(vision_of_demise_item) UnholyUseItemActions()
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack<1
 if target.DebuffStacks(razor_coral) < 1 UnholyUseItemActions()
 #use_item,name=ashvanes_razor_coral,if=(cooldown.apocalypse.ready&debuff.festering_wound.stack>=4&debuff.razor_coral_debuff.stack>=1)|buff.unholy_frenzy.up
 if SpellCooldown(apocalypse) == 0 and target.DebuffStacks(festering_wound_debuff) >= 4 and target.DebuffStacks(razor_coral) >= 1 or BuffPresent(unholy_frenzy_buff) UnholyUseItemActions()
 #use_item,name=vision_of_demise,if=(cooldown.apocalypse.ready&debuff.festering_wound.stack>=4&essence.vision_of_perfection.enabled)|buff.unholy_frenzy.up|pet.gargoyle.active
 if SpellCooldown(apocalypse) == 0 and target.DebuffStacks(festering_wound_debuff) >= 4 and AzeriteEssenceIsEnabled(vision_of_perfection_essence_id) or BuffPresent(unholy_frenzy_buff) or pet.Present() UnholyUseItemActions()
 #use_item,name=ramping_amplitude_gigavolt_engine,if=cooldown.apocalypse.remains<2|talent.army_of_the_damned.enabled|raid_event.adds.in<5
 if SpellCooldown(apocalypse) < 2 or Talent(army_of_the_damned_talent) or 600 < 5 UnholyUseItemActions()
 #use_item,name=bygone_bee_almanac,if=cooldown.summon_gargoyle.remains>60|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if SpellCooldown(summon_gargoyle) > 60 or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=jes_howler,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if pet.Present() or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=galecallers_beak,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if pet.Present() or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=grongs_primal_rage,if=rune<=3&(time>20|!equipped.ramping_amplitude_gigavolt_engine)
 if RuneCount() <= 3 and { TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) } UnholyUseItemActions()
 #potion,if=cooldown.army_of_the_dead.ready|pet.gargoyle.active|buff.unholy_frenzy.up
 if { SpellCooldown(army_of_the_dead) == 0 or pet.Present() or BuffPresent(unholy_frenzy_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)

 unless target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
 {
  #call_action_list,name=essences
  UnholyEssencesCdActions()

  unless UnholyEssencesCdPostConditions()
  {
   #call_action_list,name=cooldowns
   UnholyCooldownsCdActions()

   unless UnholyCooldownsCdPostConditions()
   {
    #run_action_list,name=aoe,if=active_enemies>=2
    if Enemies() >= 2 UnholyAoeCdActions()

    unless Enemies() >= 2 and UnholyAoeCdPostConditions()
    {
     #call_action_list,name=generic
     UnholyGenericCdActions()
    }
   }
  }
 }
}

AddFunction UnholyDefaultCdPostConditions
{
 target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyEssencesCdPostConditions() or UnholyCooldownsCdPostConditions() or Enemies() >= 2 and UnholyAoeCdPostConditions() or UnholyGenericCdPostConditions()
}

### Unholy icons.

AddCheckBox(opt_deathknight_unholy_aoe L(AOE) default specialization=unholy)

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=shortcd specialization=unholy
{
 if not InCombat() UnholyPrecombatShortCdActions()
 unless not InCombat() and UnholyPrecombatShortCdPostConditions()
 {
  UnholyDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=shortcd specialization=unholy
{
 if not InCombat() UnholyPrecombatShortCdActions()
 unless not InCombat() and UnholyPrecombatShortCdPostConditions()
 {
  UnholyDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=unholy
{
 if not InCombat() UnholyPrecombatMainActions()
 unless not InCombat() and UnholyPrecombatMainPostConditions()
 {
  UnholyDefaultMainActions()
 }
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=aoe specialization=unholy
{
 if not InCombat() UnholyPrecombatMainActions()
 unless not InCombat() and UnholyPrecombatMainPostConditions()
 {
  UnholyDefaultMainActions()
 }
}

AddIcon checkbox=!opt_deathknight_unholy_aoe enemies=1 help=cd specialization=unholy
{
 if not InCombat() UnholyPrecombatCdActions()
 unless not InCombat() and UnholyPrecombatCdPostConditions()
 {
  UnholyDefaultCdActions()
 }
}

AddIcon checkbox=opt_deathknight_unholy_aoe help=cd specialization=unholy
{
 if not InCombat() UnholyPrecombatCdActions()
 unless not InCombat() and UnholyPrecombatCdPostConditions()
 {
  UnholyDefaultCdActions()
 }
}

### Required symbols
# apocalypse
# arcane_torrent_runicpower
# army_of_the_damned_talent
# army_of_the_dead
# asphyxiate
# berserking
# blood_fury_ap
# blood_of_the_enemy
# bursting_sores_talent
# clawing_shadows
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# dark_transformation
# death_and_decay
# death_coil
# death_strike
# defile
# defile_talent
# epidemic
# festering_strike
# festering_wound_debuff
# focused_azerite_beam
# guardian_of_azeroth
# item_battle_potion_of_strength
# magus_of_the_dead_trait
# memory_of_lucid_dreams_essence
# mind_freeze
# outbreak
# pestilence_talent
# purifying_blast
# raise_dead
# ramping_amplitude_gigavolt_engine_item
# razor_coral
# reckless_force_buff
# reckless_force_counter
# ripple_in_space_essence
# scourge_strike
# soul_reaper
# sudden_doom_buff
# summon_gargoyle
# summon_gargoyle_talent
# the_unbound_force
# unholy_blight
# unholy_frenzy
# unholy_frenzy_buff
# virulent_plague_debuff
# vision_of_demise_item
# vision_of_perfection_essence_id
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEATHKNIGHT", "unholy", name, desc, code, "script")
    end
end
