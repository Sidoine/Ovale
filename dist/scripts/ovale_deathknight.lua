local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_deathknight_blood"
    local desc = "[7.3.2] Icy-Veins: DeathKnight Blood"
    local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=blood)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=blood)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=blood)

AddFunction BloodDefaultShortCDActions
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
	if not BuffPresent(rune_tap_buff) Spell(rune_tap)
	if Rune() <= 2 Spell(blood_tap)
}

AddFunction BloodDefaultMainActions
{
	BloodHealMe()
	if InCombat() and BuffExpires(bone_shield_buff 3) Spell(marrowrend)
	if target.DebuffRefreshable(blood_plague_debuff) Spell(blood_boil)
	if not BuffPresent(death_and_decay_buff) and BuffPresent(crimson_scourge_buff) and Talent(rapid_decomposition_talent) Spell(death_and_decay)
	if RunicPower() >= 100 and target.TimeToDie() >= 10 Spell(bonestorm)
	if RunicPowerDeficit() <= 20 Spell(death_strike)
	if BuffStacks(bone_shield_buff) <= 2+4*Talent(ossuary_talent) Spell(marrowrend)
	if not BuffPresent(death_and_decay_buff) and Rune() >= 3 and Talent(rapid_decomposition_talent) Spell(death_and_decay)
	if not target.DebuffPresent(mark_of_blood_debuff) Spell(mark_of_blood)
	if Rune() >= 3 or RunicPower() < 45 Spell(heart_strike)
	Spell(consumption)
	Spell(blood_boil)
}

AddFunction BloodDefaultAoEActions
{
	BloodHealMe()
	if RunicPower() >= 100 Spell(bonestorm)
	if InCombat() and BuffExpires(bone_shield_buff 3) Spell(marrowrend)
	if DebuffCountOnAny(blood_plague_debuff) < Enemies(tagged=1) Spell(blood_boil)
	if not BuffPresent(death_and_decay_buff) and BuffPresent(crimson_scourge_buff) Spell(death_and_decay)
	if RunicPowerDeficit() <= 20 Spell(death_strike)
	if BuffStacks(bone_shield_buff) <= 2+4*Talent(ossuary_talent) Spell(marrowrend)
	if not BuffPresent(death_and_decay_buff) and Enemies() >= 3 Spell(death_and_decay)
	if not target.DebuffPresent(mark_of_blood_debuff) Spell(mark_of_blood)
	if Rune() >= 3 or RunicPower() < 45 Spell(heart_strike)
	Spell(consumption)
	Spell(blood_boil)
}

 AddFunction BloodHealMe
 {
	unless(DebuffPresent(healing_immunity_debuff)) 
	{
		if HealthPercent() <= 70 Spell(death_strike)
		if (DamageTaken(5) * 0.2) > (Health() / 100 * 25) Spell(death_strike)
		if (BuffStacks(bone_shield_buff) * 3) > (100 - HealthPercent()) Spell(tombstone)
		if HealthPercent() <= 70 Spell(consumption)
		if (HealthPercent() < 35) UseHealthPotions()
	}
}

AddFunction BloodDefaultCdActions
{
	BloodInterruptActions()
	if IncomingDamage(1.5 magic=1) > 0 spell(antimagic_shell)
	if (HasEquippedItem(shifting_cosmic_sliver)) Spell(icebound_fortitude)
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	Spell(vampiric_blood)
	Spell(icebound_fortitude)
	if target.InRange(blood_mirror) Spell(blood_mirror)
	Spell(dancing_rune_weapon)
	if BuffStacks(bone_shield_buff) >= 5 Spell(tombstone)
	if CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	UseRacialSurvivalActions()
}

AddFunction BloodInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
		if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
	}
}

AddCheckBox(opt_deathknight_blood_aoe L(AOE) default specialization=blood)

AddIcon help=shortcd specialization=blood
{
	BloodDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=blood
{
	BloodDefaultMainActions()
}

AddIcon checkbox=opt_deathknight_blood_aoe help=aoe specialization=blood
{
	BloodDefaultAoEActions()
}

AddIcon help=cd specialization=blood
{
	#if not InCombat() ProtectionPrecombatCdActions()
	BloodDefaultCdActions()
}
]]
    OvaleScripts:RegisterScript("DEATHKNIGHT", "blood", name, desc, code, "script")
end
do
    local name = "sc_pr_death_knight_blood"
    local desc = "[8.0] Simulationcraft: PR_Death_Knight_Blood"
    local code = [[
# Based on SimulationCraft profile "PR_Death_Knight_Blood".
#	class=deathknight
#	spec=blood
#	talents=3222022

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
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
 }
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
 #marrowrend,if=(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20
 if { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 Spell(marrowrend)
 #blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
 if Charges(blood_boil count=0) >= 1 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } Spell(blood_boil)
 #marrowrend,if=buff.bone_shield.stack<5&talent.ossuary.enabled&runic_power.deficit>=15
 if BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 Spell(marrowrend)
 #death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.time_to_die<10
 if RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 Spell(death_strike)
 #heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd
 if BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() Spell(heart_strike)
 #blood_boil,if=buff.dancing_rune_weapon.up
 if BuffPresent(dancing_rune_weapon_buff) Spell(blood_boil)
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
 unless RunicPowerDeficit() <= 10 and Spell(death_strike)
 {
  #blooddrinker,if=!buff.dancing_rune_weapon.up
  if not BuffPresent(dancing_rune_weapon_buff) Spell(blooddrinker)

  unless { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend)
  {
   #bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up
   if RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) Spell(bonestorm)

   unless { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike)
   {
    #death_and_decay,if=spell_targets.death_and_decay>=3
    if Enemies() >= 3 Spell(death_and_decay)
    #rune_strike,if=(charges_fractional>=1.8|buff.dancing_rune_weapon.up)&rune.time_to_3>=gcd
    if { Charges(rune_strike count=0) >= 1 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() Spell(rune_strike)

    unless { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil)
    {
     #death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2
     if BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 Spell(death_and_decay)
     #consumption
     Spell(consumption)

     unless Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
     {
      #rune_strike
      Spell(rune_strike)
     }
    }
   }
  }
 }
}

AddFunction BloodStandardShortCdPostConditions
{
 RunicPowerDeficit() <= 10 and Spell(death_strike) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
}

AddFunction BloodStandardCdActions
{
 unless RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies() >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike) or Spell(rune_strike)
 {
  #arcane_torrent,if=runic_power.deficit>20
  if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
 }
}

AddFunction BloodStandardCdPostConditions
{
 RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1 and { BuffStacks(hemostasis_buff) <= 5 - Enemies() or Enemies() > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies() * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies() >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies() >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike) or Spell(rune_strike)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
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
 #mind_freeze
 BloodInterruptActions()
 #blood_fury,if=cooldown.dancing_rune_weapon.ready&(!cooldown.blooddrinker.ready|!talent.blooddrinker.enabled)
 if SpellCooldown(dancing_rune_weapon) == 0 and { not SpellCooldown(blooddrinker) == 0 or not Talent(blooddrinker_talent) } Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #use_items
 BloodUseItemActions()
 #potion,if=buff.dancing_rune_weapon.up
 if BuffPresent(dancing_rune_weapon_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
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
# battle_potion_of_strength
# berserking
# blood_boil
# blood_fury_ap
# blooddrinker
# blooddrinker_talent
# bone_shield_buff
# bonestorm
# consumption
# crimson_scourge_buff
# dancing_rune_weapon
# dancing_rune_weapon_buff
# death_and_decay
# death_strike
# heart_strike
# heartbreaker_talent
# hemostasis_buff
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
    local name = "sc_pr_death_knight_frost"
    local desc = "[8.0] Simulationcraft: PR_Death_Knight_Frost"
    local code = [[
# Based on SimulationCraft profile "PR_Death_Knight_Frost".
#	class=deathknight
#	spec=frost
#	talents=3302013

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=frost)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.Distance(less 12) and not target.Classification(worldboss) Spell(blinding_sleet)
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
}

AddFunction FrostPrecombatCdPostConditions
{
}

### actions.obliteration

AddFunction FrostObliterationMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #obliterate,if=!talent.frostscythe.enabled&!buff.rime.up&spell_targets.howling_blast>=3
 if not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 Spell(obliterate)
 #frostscythe,if=(buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance)))&(rune.time_to_4>gcd|spell_targets.frostscythe>=2)
 if { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies() >= 2 } Spell(frostscythe)
 #obliterate,if=buff.killing_machine.react|(buff.killing_machine.up&(prev_gcd.1.frost_strike|prev_gcd.1.howling_blast|prev_gcd.1.glacial_advance))
 if BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } Spell(obliterate)
 #glacial_advance,if=(!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd)&spell_targets.glacial_advance>=2
 if { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 Spell(glacial_advance)
 #howling_blast,if=buff.rime.up&spell_targets.howling_blast>=2
 if BuffPresent(rime_buff) and Enemies() >= 2 Spell(howling_blast)
 #frost_strike,if=!buff.rime.up|runic_power.deficit<10|rune.time_to_2>gcd
 if not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
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
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies() >= 2 } and Spell(frostscythe) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies() >= 2 and Spell(howling_blast) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Spell(obliterate)
}

AddFunction FrostObliterationCdActions
{
}

AddFunction FrostObliterationCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or not Talent(frostscythe_talent) and not BuffPresent(rime_buff) and Enemies() >= 3 and Spell(obliterate) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and { TimeToRunes(4) > GCD() or Enemies() >= 2 } and Spell(frostscythe) or { BuffPresent(killing_machine_buff) or BuffPresent(killing_machine_buff) and { PreviousGCDSpell(frost_strike) or PreviousGCDSpell(howling_blast) or PreviousGCDSpell(glacial_advance) } } and Spell(obliterate) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Enemies() >= 2 and Spell(glacial_advance) or BuffPresent(rime_buff) and Enemies() >= 2 and Spell(howling_blast) or { not BuffPresent(rime_buff) or RunicPowerDeficit() < 10 or TimeToRunes(2) > GCD() } and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or Spell(obliterate)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
 if { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #pillar_of_frost,if=cooldown.empower_rune_weapon.remains
 if SpellCooldown(empower_rune_weapon) > 0 Spell(pillar_of_frost)
 #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
 if { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #use_items
 FrostUseItemActions()
 #use_item,name=horn_of_valor,if=buff.pillar_of_frost.up&(!talent.breath_of_sindragosa.enabled|!cooldown.breath_of_sindragosa.remains)
 if BuffPresent(pillar_of_frost_buff) and { not Talent(breath_of_sindragosa_talent) or not SpellCooldown(breath_of_sindragosa) > 0 } FrostUseItemActions()
 #potion,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)
 #blood_fury,if=buff.pillar_of_frost.up&buff.empower_rune_weapon.up
 if BuffPresent(pillar_of_frost_buff) and BuffPresent(empower_rune_weapon_buff) Spell(blood_fury_ap)
 #berserking,if=buff.pillar_of_frost.up
 if BuffPresent(pillar_of_frost_buff) Spell(berserking)

 unless SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost)
 {
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&!talent.breath_of_sindragosa.enabled&rune.time_to_5>gcd&runic_power.deficit>=10
  if SpellCooldown(pillar_of_frost) == 0 and not Talent(breath_of_sindragosa_talent) and TimeToRunes(5) > GCD() and RunicPowerDeficit() >= 10 Spell(empower_rune_weapon)
  #empower_rune_weapon,if=cooldown.pillar_of_frost.ready&talent.breath_of_sindragosa.enabled&rune>=3&runic_power>60
  if SpellCooldown(pillar_of_frost) == 0 and Talent(breath_of_sindragosa_talent) and Rune() >= 3 and RunicPower() > 60 Spell(empower_rune_weapon)
  #call_action_list,name=cold_heart,if=(equipped.cold_heart|talent.cold_heart.enabled)&(((buff.cold_heart_item.stack>=10|buff.cold_heart_talent.stack>=10)&debuff.razorice.stack=5)|target.time_to_die<=gcd)
  if { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } FrostColdheartCdActions()

  unless { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartCdPostConditions()
  {
   #frostwyrms_fury,if=(buff.pillar_of_frost.remains<=gcd&buff.pillar_of_frost.up)
   if BuffRemaining(pillar_of_frost_buff) <= GCD() and BuffPresent(pillar_of_frost_buff) Spell(frostwyrms_fury)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 SpellCooldown(empower_rune_weapon) > 0 and Spell(pillar_of_frost) or { HasEquippedItem(cold_heart_item) or Talent(cold_heart_talent) } and { { DebuffStacks(cold_heart_item) >= 10 or BuffStacks(cold_heart_buff) >= 10 } and target.DebuffStacks(razorice_debuff) == 5 or target.TimeToDie() <= GCD() } and FrostColdheartCdPostConditions()
}

### actions.cold_heart

AddFunction FrostColdheartMainActions
{
 #chains_of_ice,if=(buff.cold_heart_item.stack>5|buff.cold_heart_talent.stack>5)&target.time_to_die<gcd
 if { DebuffStacks(cold_heart_item) > 5 or BuffStacks(cold_heart_buff) > 5 } and target.TimeToDie() < GCD() Spell(chains_of_ice)
 #chains_of_ice,if=(buff.pillar_of_frost.remains<=gcd*(1+cooldown.frostwyrms_fury.ready)|buff.pillar_of_frost.remains<rune.time_to_3)&buff.pillar_of_frost.up
 if { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) Spell(chains_of_ice)
}

AddFunction FrostColdheartMainPostConditions
{
}

AddFunction FrostColdheartShortCdActions
{
}

AddFunction FrostColdheartShortCdPostConditions
{
 { DebuffStacks(cold_heart_item) > 5 or BuffStacks(cold_heart_buff) > 5 } and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and Spell(chains_of_ice)
}

AddFunction FrostColdheartCdActions
{
}

AddFunction FrostColdheartCdPostConditions
{
 { DebuffStacks(cold_heart_item) > 5 or BuffStacks(cold_heart_buff) > 5 } and target.TimeToDie() < GCD() and Spell(chains_of_ice) or { BuffRemaining(pillar_of_frost_buff) <= GCD() * { 1 + { SpellCooldown(frostwyrms_fury) == 0 } } or BuffRemaining(pillar_of_frost_buff) < TimeToRunes(3) } and BuffPresent(pillar_of_frost_buff) and Spell(chains_of_ice)
}

### actions.bos_ticking

AddFunction FrostBostickingMainActions
{
 #obliterate,if=runic_power<=30
 if RunicPower() <= 30 Spell(obliterate)
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=rune.time_to_5<gcd|runic_power<=45
 if TimeToRunes(5) < GCD() or RunicPower() <= 45 Spell(obliterate)
 #frostscythe,if=buff.killing_machine.up
 if BuffPresent(killing_machine_buff) Spell(frostscythe)
 #horn_of_winter,if=runic_power.deficit>=30&rune.time_to_3>gcd
 if RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() Spell(horn_of_winter)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe,if=spell_targets.frostscythe>=2
 if Enemies() >= 2 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>25|rune>3
 if RunicPowerDeficit() > 25 or Rune() >= 4 Spell(obliterate)
}

AddFunction FrostBostickingMainPostConditions
{
}

AddFunction FrostBostickingShortCdActions
{
}

AddFunction FrostBostickingShortCdPostConditions
{
 RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
}

AddFunction FrostBostickingCdActions
{
 unless RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
 {
  #arcane_torrent,if=runic_power.deficit>20
  if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostBostickingCdPostConditions
{
 RunicPower() <= 30 and Spell(obliterate) or Talent(gathering_storm_talent) and Spell(remorseless_winter) or BuffPresent(rime_buff) and Spell(howling_blast) or { TimeToRunes(5) < GCD() or RunicPower() <= 45 } and Spell(obliterate) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() >= 30 and TimeToRunes(3) > GCD() and Spell(horn_of_winter) or Spell(remorseless_winter) or Enemies() >= 2 and Spell(frostscythe) or { RunicPowerDeficit() > 25 or Rune() >= 4 } and Spell(obliterate)
}

### actions.bos_pooling

AddFunction FrostBospoolingMainActions
{
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #obliterate,if=rune.time_to_4<gcd&runic_power.deficit>=25
 if TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 Spell(obliterate)
 #glacial_advance,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>rune.time_to_4
 if RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) Spell(glacial_advance)
 #frost_strike,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>rune.time_to_4
 if RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) Spell(frost_strike)
 #frostscythe,if=buff.killing_machine.up&runic_power.deficit>(15+talent.runic_attenuation.enabled*3)
 if BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>=(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&spell_targets.glacial_advance>=2
 if SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 Spell(glacial_advance)
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
 BuffPresent(rime_buff) and Spell(howling_blast) or TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(glacial_advance) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frostscythe) or RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 and Spell(glacial_advance) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

AddFunction FrostBospoolingCdActions
{
}

AddFunction FrostBospoolingCdPostConditions
{
 BuffPresent(rime_buff) and Spell(howling_blast) or TimeToRunes(4) < GCD() and RunicPowerDeficit() >= 25 and Spell(obliterate) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(glacial_advance) or RunicPowerDeficit() < 20 and SpellCooldown(pillar_of_frost) > TimeToRunes(4) and Spell(frost_strike) or BuffPresent(killing_machine_buff) and RunicPowerDeficit() > 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frostscythe) or RunicPowerDeficit() >= 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Enemies() >= 2 and Spell(glacial_advance) or SpellCooldown(pillar_of_frost) > TimeToRunes(4) and RunicPowerDeficit() < 40 and Spell(frost_strike)
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #remorseless_winter,if=talent.gathering_storm.enabled
 if Talent(gathering_storm_talent) Spell(remorseless_winter)
 #glacial_advance,if=talent.frostscythe.enabled
 if Talent(frostscythe_talent) Spell(glacial_advance)
 #frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm.enabled
 if SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) Spell(frost_strike)
 #howling_blast,if=buff.rime.up
 if BuffPresent(rime_buff) Spell(howling_blast)
 #frostscythe,if=buff.killing_machine.up
 if BuffPresent(killing_machine_buff) Spell(frostscythe)
 #glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(glacial_advance)
 #frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 Spell(frost_strike)
 #remorseless_winter
 Spell(remorseless_winter)
 #frostscythe
 Spell(frostscythe)
 #obliterate,if=runic_power.deficit>(25+talent.runic_attenuation.enabled*3)
 if RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 Spell(obliterate)
 #glacial_advance
 Spell(glacial_advance)
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
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
}

AddFunction FrostAoeCdActions
{
 unless Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
 {
  #arcane_torrent
  Spell(arcane_torrent_runicpower)
 }
}

AddFunction FrostAoeCdPostConditions
{
 Talent(gathering_storm_talent) and Spell(remorseless_winter) or Talent(frostscythe_talent) and Spell(glacial_advance) or SpellCooldown(remorseless_winter) <= 2 * GCD() and Talent(gathering_storm_talent) and Spell(frost_strike) or BuffPresent(rime_buff) and Spell(howling_blast) or BuffPresent(killing_machine_buff) and Spell(frostscythe) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(glacial_advance) or RunicPowerDeficit() < 15 + TalentPoints(runic_attenuation_talent) * 3 and Spell(frost_strike) or Spell(remorseless_winter) or Spell(frostscythe) or RunicPowerDeficit() > 25 + TalentPoints(runic_attenuation_talent) * 3 and Spell(obliterate) or Spell(glacial_advance) or Spell(frost_strike) or Spell(horn_of_winter)
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
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
  if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBospoolingMainActions()

  unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingMainPostConditions()
  {
   #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
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

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingMainPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingMainPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationMainPostConditions() or Enemies() >= 2 and FrostAoeMainPostConditions() or FrostStandardMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #auto_attack
 FrostGetInMeleeRange()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
   if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBospoolingShortCdActions()

   unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingShortCdPostConditions()
   {
    #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
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

AddFunction FrostDefaultShortCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostCooldownsShortCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingShortCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingShortCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationShortCdPostConditions() or Enemies() >= 2 and FrostAoeShortCdPostConditions() or FrostStandardShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #mind_freeze
 FrostInterruptActions()

 unless not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike)
 {
  #breath_of_sindragosa,if=cooldown.empower_rune_weapon.remains&cooldown.pillar_of_frost.remains
  if SpellCooldown(empower_rune_weapon) > 0 and SpellCooldown(pillar_of_frost) > 0 Spell(breath_of_sindragosa)
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa.enabled&cooldown.breath_of_sindragosa.remains<5
   if Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 FrostBospoolingCdActions()

   unless Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingCdPostConditions()
   {
    #run_action_list,name=bos_ticking,if=dot.breath_of_sindragosa.ticking
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

AddFunction FrostDefaultCdPostConditions
{
 not target.DebuffPresent(frost_fever_debuff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(howling_blast) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and Enemies() >= 2 and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(glacial_advance) or BuffRemaining(icy_talons_buff) <= GCD() and BuffPresent(icy_talons_buff) and { not Talent(breath_of_sindragosa_talent) or SpellCooldown(breath_of_sindragosa) > 15 } and Spell(frost_strike) or FrostCooldownsCdPostConditions() or Talent(breath_of_sindragosa_talent) and SpellCooldown(breath_of_sindragosa) < 5 and FrostBospoolingCdPostConditions() or BuffPresent(breath_of_sindragosa_buff) and FrostBostickingCdPostConditions() or BuffPresent(pillar_of_frost_buff) and Talent(obliteration_talent) and FrostObliterationCdPostConditions() or Enemies() >= 2 and FrostAoeCdPostConditions() or FrostStandardCdPostConditions()
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
# battle_potion_of_strength
# berserking
# blinding_sleet
# blood_fury_ap
# breath_of_sindragosa
# breath_of_sindragosa_buff
# breath_of_sindragosa_talent
# chains_of_ice
# cold_heart_buff
# cold_heart_item
# cold_heart_talent
# death_strike
# empower_rune_weapon
# empower_rune_weapon_buff
# frost_fever_debuff
# frost_strike
# frostscythe
# frostscythe_talent
# frostwyrms_fury
# frozen_pulse_buff
# frozen_pulse_talent
# gathering_storm_talent
# glacial_advance
# horn_of_winter
# howling_blast
# icy_talons_buff
# killing_machine_buff
# mind_freeze
# obliterate
# obliteration_talent
# pillar_of_frost
# pillar_of_frost_buff
# razorice_debuff
# remorseless_winter
# rime_buff
# runic_attenuation_talent
# war_stomp
]]
    OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
end
do
    local name = "sc_pr_death_knight_unholy"
    local desc = "[8.0] Simulationcraft: PR_Death_Knight_Unholy"
    local code = [[
# Based on SimulationCraft profile "PR_Death_Knight_Unholy".
#	class=deathknight
#	spec=unholy
#	talents=2203022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)


AddFunction pooling_for_gargoyle
{
 SpellCooldown(summon_gargoyle) < 5 and { SpellCooldown(dark_transformation) < 5 or not HasEquippedItem(taktheritrixs_shoulderpads_item) } and Talent(summon_gargoyle_talent)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=unholy)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=unholy)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=unholy)

AddFunction UnholyInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
  if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)

 unless Spell(raise_dead)
 {
  #army_of_the_dead
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
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 Spell(festering_strike)
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
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or SpellCooldown(apocalypse) > 0 and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyGenericCdActions
{
}

AddFunction UnholyGenericCdPostConditions
{
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 and Spell(death_and_decay) or SpellCooldown(apocalypse) > 0 and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.cooldowns

AddFunction UnholyCooldownsMainActions
{
 #call_action_list,name=cold_heart,if=equipped.cold_heart&buff.cold_heart_item.stack>10
 if HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 UnholyColdheartMainActions()
}

AddFunction UnholyCooldownsMainPostConditions
{
 HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 and UnholyColdheartMainPostConditions()
}

AddFunction UnholyCooldownsShortCdActions
{
 #call_action_list,name=cold_heart,if=equipped.cold_heart&buff.cold_heart_item.stack>10
 if HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 UnholyColdheartShortCdActions()

 unless HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 and UnholyColdheartShortCdPostConditions()
 {
  #apocalypse,if=debuff.festering_wound.stack>=4
  if target.DebuffStacks(festering_wound_debuff) >= 4 Spell(apocalypse)
  #dark_transformation,if=(equipped.137075&cooldown.summon_gargoyle.remains>40)|(!equipped.137075|!talent.summon_gargoyle.enabled)
  if HasEquippedItem(taktheritrixs_shoulderpads_item) and SpellCooldown(summon_gargoyle) > 40 or not HasEquippedItem(taktheritrixs_shoulderpads_item) or not Talent(summon_gargoyle_talent) Spell(dark_transformation)
  #unholy_frenzy,if=debuff.festering_wound.stack<4
  if target.DebuffStacks(festering_wound_debuff) < 4 Spell(unholy_frenzy)
  #unholy_frenzy,if=active_enemies>=2&((cooldown.death_and_decay.remains<=gcd&!talent.defile.enabled)|(cooldown.defile.remains<=gcd&talent.defile.enabled))
  if Enemies() >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } Spell(unholy_frenzy)
  #soul_reaper,target_if=(target.time_to_die<8|rune<=2)&!buff.unholy_frenzy.up
  if { target.TimeToDie() < 8 or Rune() < 3 } and not BuffPresent(unholy_frenzy_buff) Spell(soul_reaper)
  #unholy_blight
  Spell(unholy_blight)
 }
}

AddFunction UnholyCooldownsShortCdPostConditions
{
 HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 and UnholyColdheartShortCdPostConditions()
}

AddFunction UnholyCooldownsCdActions
{
 #call_action_list,name=cold_heart,if=equipped.cold_heart&buff.cold_heart_item.stack>10
 if HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 UnholyColdheartCdActions()

 unless HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 and UnholyColdheartCdPostConditions()
 {
  #army_of_the_dead
  Spell(army_of_the_dead)

  unless target.DebuffStacks(festering_wound_debuff) >= 4 and Spell(apocalypse) or { HasEquippedItem(taktheritrixs_shoulderpads_item) and SpellCooldown(summon_gargoyle) > 40 or not HasEquippedItem(taktheritrixs_shoulderpads_item) or not Talent(summon_gargoyle_talent) } and Spell(dark_transformation)
  {
   #summon_gargoyle,if=runic_power.deficit<14
   if RunicPowerDeficit() < 14 Spell(summon_gargoyle)
  }
 }
}

AddFunction UnholyCooldownsCdPostConditions
{
 HasEquippedItem(cold_heart_item) and DebuffStacks(cold_heart_item) > 10 and UnholyColdheartCdPostConditions() or target.DebuffStacks(festering_wound_debuff) >= 4 and Spell(apocalypse) or { HasEquippedItem(taktheritrixs_shoulderpads_item) and SpellCooldown(summon_gargoyle) > 40 or not HasEquippedItem(taktheritrixs_shoulderpads_item) or not Talent(summon_gargoyle_talent) } and Spell(dark_transformation) or target.DebuffStacks(festering_wound_debuff) < 4 and Spell(unholy_frenzy) or Enemies() >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } and Spell(unholy_frenzy) or { target.TimeToDie() < 8 or Rune() < 3 } and not BuffPresent(unholy_frenzy_buff) and Spell(soul_reaper) or Spell(unholy_blight)
}

### actions.cold_heart

AddFunction UnholyColdheartMainActions
{
 #chains_of_ice,if=buff.unholy_strength.remains<gcd&buff.unholy_strength.react&buff.cold_heart_item.stack>16
 if BuffRemaining(unholy_strength_buff) < GCD() and BuffPresent(unholy_strength_buff) and DebuffStacks(cold_heart_item) > 16 Spell(chains_of_ice)
 #chains_of_ice,if=buff.master_of_ghouls.remains<gcd&buff.master_of_ghouls.up&buff.cold_heart_item.stack>17
 if BuffRemaining(master_of_ghouls_buff) < GCD() and BuffPresent(master_of_ghouls_buff) and DebuffStacks(cold_heart_item) > 17 Spell(chains_of_ice)
 #chains_of_ice,if=buff.cold_heart_item.stack=20&buff.unholy_strength.react
 if DebuffStacks(cold_heart_item) == 20 and BuffPresent(unholy_strength_buff) Spell(chains_of_ice)
}

AddFunction UnholyColdheartMainPostConditions
{
}

AddFunction UnholyColdheartShortCdActions
{
}

AddFunction UnholyColdheartShortCdPostConditions
{
 BuffRemaining(unholy_strength_buff) < GCD() and BuffPresent(unholy_strength_buff) and DebuffStacks(cold_heart_item) > 16 and Spell(chains_of_ice) or BuffRemaining(master_of_ghouls_buff) < GCD() and BuffPresent(master_of_ghouls_buff) and DebuffStacks(cold_heart_item) > 17 and Spell(chains_of_ice) or DebuffStacks(cold_heart_item) == 20 and BuffPresent(unholy_strength_buff) and Spell(chains_of_ice)
}

AddFunction UnholyColdheartCdActions
{
}

AddFunction UnholyColdheartCdPostConditions
{
 BuffRemaining(unholy_strength_buff) < GCD() and BuffPresent(unholy_strength_buff) and DebuffStacks(cold_heart_item) > 16 and Spell(chains_of_ice) or BuffRemaining(master_of_ghouls_buff) < GCD() and BuffPresent(master_of_ghouls_buff) and DebuffStacks(cold_heart_item) > 17 and Spell(chains_of_ice) or DebuffStacks(cold_heart_item) == 20 and BuffPresent(unholy_strength_buff) and Spell(chains_of_ice)
}

### actions.aoe

AddFunction UnholyAoeMainActions
{
 #defile
 Spell(defile)
 #epidemic,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() Spell(epidemic)
 #death_coil,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 Spell(scourge_strike)
 #clawing_shadows,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 Spell(clawing_shadows)
 #epidemic,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(epidemic)
 #festering_strike,if=talent.bursting_sores.enabled&spell_targets.bursting_sores>=2&debuff.festering_wound.stack<=1
 if Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 Spell(festering_strike)
 #death_coil,if=buff.sudden_doom.react&rune.deficit>=4
 if BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 Spell(death_coil)
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() Spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 Spell(festering_strike)
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
 Spell(defile) or BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() and Spell(epidemic) or BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and Spell(epidemic) or Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyAoeCdActions
{
}

AddFunction UnholyAoeCdPostConditions
{
 SpellCooldown(apocalypse) > 0 and Spell(death_and_decay) or Spell(defile) or BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() and Spell(epidemic) or BuffPresent(death_and_decay) and Rune() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and Spell(epidemic) or Talent(bursting_sores_talent) and Enemies() >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and SpellCooldown(army_of_the_dead) > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and SpellCooldown(army_of_the_dead) > 5 and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.default

AddFunction UnholyDefaultMainActions
{
 #outbreak,target_if=(dot.virulent_plague.tick_time_remains+tick_time<=dot.virulent_plague.remains)&dot.virulent_plague.remains<=gcd
 if target.TickTimeRemaining(virulent_plague_debuff) + target.TickTime(virulent_plague_debuff) <= target.DebuffRemaining(virulent_plague_debuff) and target.DebuffRemaining(virulent_plague_debuff) <= GCD() Spell(outbreak)
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

AddFunction UnholyDefaultMainPostConditions
{
 UnholyCooldownsMainPostConditions() or Enemies() >= 2 and UnholyAoeMainPostConditions() or UnholyGenericMainPostConditions()
}

AddFunction UnholyDefaultShortCdActions
{
 #auto_attack
 UnholyGetInMeleeRange()

 unless target.TickTimeRemaining(virulent_plague_debuff) + target.TickTime(virulent_plague_debuff) <= target.DebuffRemaining(virulent_plague_debuff) and target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
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

AddFunction UnholyDefaultShortCdPostConditions
{
 target.TickTimeRemaining(virulent_plague_debuff) + target.TickTime(virulent_plague_debuff) <= target.DebuffRemaining(virulent_plague_debuff) and target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyCooldownsShortCdPostConditions() or Enemies() >= 2 and UnholyAoeShortCdPostConditions() or UnholyGenericShortCdPostConditions()
}

AddFunction UnholyDefaultCdActions
{
 #mind_freeze
 UnholyInterruptActions()
 #variable,name=pooling_for_gargoyle,value=(cooldown.summon_gargoyle.remains<5&(cooldown.dark_transformation.remains<5|!equipped.137075))&talent.summon_gargoyle.enabled
 #arcane_torrent,if=runic_power.deficit>65&(pet.gargoyle.active|!talent.summon_gargoyle.enabled)&rune.deficit>=5
 if RunicPowerDeficit() > 65 and { pet.Present() or not Talent(summon_gargoyle_talent) } and RuneDeficit() >= 5 Spell(arcane_torrent_runicpower)
 #blood_fury,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.Present() or not Talent(summon_gargoyle_talent) Spell(blood_fury_ap)
 #berserking,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.Present() or not Talent(summon_gargoyle_talent) Spell(berserking)
 #use_items
 UnholyUseItemActions()
 #use_item,name=feloiled_infernal_machine,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.Present() or not Talent(summon_gargoyle_talent) UnholyUseItemActions()
 #use_item,name=ring_of_collapsing_futures,if=(buff.temptation.stack=0&target.time_to_die>60)|target.time_to_die<60
 if BuffStacks(temptation_buff) == 0 and target.TimeToDie() > 60 or target.TimeToDie() < 60 UnholyUseItemActions()
 #potion,if=cooldown.army_of_the_dead.ready|pet.gargoyle.active|buff.unholy_frenzy.up
 if { SpellCooldown(army_of_the_dead) == 0 or pet.Present() or BuffPresent(unholy_frenzy_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_strength usable=1)

 unless target.TickTimeRemaining(virulent_plague_debuff) + target.TickTime(virulent_plague_debuff) <= target.DebuffRemaining(virulent_plague_debuff) and target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
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

AddFunction UnholyDefaultCdPostConditions
{
 target.TickTimeRemaining(virulent_plague_debuff) + target.TickTime(virulent_plague_debuff) <= target.DebuffRemaining(virulent_plague_debuff) and target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyCooldownsCdPostConditions() or Enemies() >= 2 and UnholyAoeCdPostConditions() or UnholyGenericCdPostConditions()
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
# army_of_the_dead
# asphyxiate
# battle_potion_of_strength
# berserking
# blood_fury_ap
# bursting_sores_talent
# chains_of_ice
# clawing_shadows
# cold_heart_item
# dark_transformation
# death_and_decay
# death_coil
# death_strike
# defile
# defile_talent
# epidemic
# festering_strike
# festering_wound_debuff
# master_of_ghouls_buff
# mind_freeze
# outbreak
# pestilence_talent
# raise_dead
# scourge_strike
# soul_reaper
# sudden_doom_buff
# summon_gargoyle
# summon_gargoyle_talent
# taktheritrixs_shoulderpads_item
# temptation_buff
# unholy_blight
# unholy_frenzy
# unholy_frenzy_buff
# unholy_strength_buff
# virulent_plague_debuff
# war_stomp
]]
    OvaleScripts:RegisterScript("DEATHKNIGHT", "unholy", name, desc, code, "script")
end
