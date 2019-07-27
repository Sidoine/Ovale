local __exports = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
if not __exports then return end
__exports.registerDeathKnightBloodXeltor = function(OvaleScripts)
do
	local name = "xeltor_blood"
	local desc = "[Xel][8.2] Death Knight: Blood"
	local code = [[
# Common functions.
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

# Blood
AddIcon specialization=1 help=main
{
	if InCombat() InterruptActions()
	
	if target.InRange(heart_strike) and HasFullControl()
    {
		BloodDefaultCdActions()

		BloodDefaultShortCdActions()

		if not target.DebuffPresent(blood_plague_debuff) Spell(blood_boil)
		BloodDefaultMainActions()
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
		if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
	}
}

AddFunction BloodUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
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
 # BloodGetInMeleeRange()
 #vampiric_blood,if=incoming_damage_5s>health.max*0.60|health<=health.max*0.30
 if IncomingDamage(5) > MaxHealth() * 0.6 or Health() <= MaxHealth() * 0.3 Spell(vampiric_blood)
 #tombstone,if=buff.bone_shield.stack>=7&incoming_damage_5s>health.max*0.10
 if BuffStacks(bone_shield_buff) >= 7 and IncomingDamage(5) > MaxHealth() * 0.1 Spell(tombstone)
 #death_chain,if=spell_targets.death_chain>=3
 # if Enemies(tagged=1) >= 3 Spell(death_chain)
 #call_action_list,name=standard
 BloodStandardShortCdActions()
}

AddFunction BloodDefaultShortCdPostConditions
{
 BloodStandardShortCdPostConditions()
}

AddFunction BloodDefaultCdActions
{
 # BloodInterruptActions()
 #blood_fury,if=cooldown.dancing_rune_weapon.ready&(!cooldown.blooddrinker.ready|!talent.blooddrinker.enabled)
 if SpellCooldown(dancing_rune_weapon) == 0 and { not SpellCooldown(blooddrinker) == 0 or not Talent(blooddrinker_talent) } Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #use_items,if=(buff.icebound_fortitude.up|buff.vampiric_blood.up)|(cooldown.icebound_fortitude.remains>gcd&cooldown.vampiric_blood.remains>gcd&(incoming_damage_5s>health.max*0.60|health<=health.max*0.30))
 if BuffPresent(icebound_fortitude_buff) or BuffPresent(vampiric_blood_buff) or SpellCooldown(icebound_fortitude) > GCD() and SpellCooldown(vampiric_blood) > GCD() and { IncomingDamage(5) > MaxHealth() * 0.6 or Health() <= MaxHealth() * 0.3 } BloodUseItemActions()
 #icebound_fortitude,if=incoming_damage_5s>health.max*0.60&buff.vampiric_blood.down&cooldown.vampiric_blood.remains>gcd|health<=health.max*0.30
 if IncomingDamage(5) > MaxHealth() * 0.6 and BuffExpires(vampiric_blood_buff) and SpellCooldown(vampiric_blood) > GCD() or Health() <= MaxHealth() * 0.3 Spell(icebound_fortitude)
 #dancing_rune_weapon,if=(!talent.blooddrinker.enabled|!cooldown.blooddrinker.ready)&(buff.icebound_fortitude.up|buff.vampiric_blood.up|spell_targets.blood_boil>2)
 if { not Talent(blooddrinker_talent) or not SpellCooldown(blooddrinker) == 0 } and { BuffPresent(icebound_fortitude_buff) or BuffPresent(vampiric_blood_buff) or Enemies(tagged=1) > 2 } Spell(dancing_rune_weapon)

 unless BuffStacks(bone_shield_buff) >= 7 and IncomingDamage(5) > MaxHealth() * 0.1 and Spell(tombstone) or Enemies(tagged=1) >= 3
 {
  #call_action_list,name=standard
  BloodStandardCdActions()
 }
}

AddFunction BloodDefaultCdPostConditions
{
 BuffStacks(bone_shield_buff) >= 7 and IncomingDamage(5) > MaxHealth() * 0.1 and Spell(tombstone) or Enemies(tagged=1) >= 3 or BloodStandardCdPostConditions()
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
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)
}

AddFunction BloodPrecombatCdPostConditions
{
}

### actions.standard

AddFunction BloodStandardMainActions
{
 #death_strike,if=runic_power.deficit<=10
 if RunicPowerDeficit() <= 10 Spell(death_strike)
 #blooddrinker,if=!buff.dancing_rune_weapon.up&health<health.max*0.90
 if not BuffPresent(dancing_rune_weapon_buff) and Health() < MaxHealth() * 0.9 Spell(blooddrinker)
 #marrowrend,if=(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20
 if { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 Spell(marrowrend)
 #blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
 if Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies(tagged=1) or Enemies(tagged=1) > 2 } Spell(blood_boil)
 #marrowrend,if=buff.bone_shield.stack<5&talent.ossuary.enabled&runic_power.deficit>=15
 if BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 Spell(marrowrend)
 #death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.time_to_die<10
 if RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies(tagged=1) * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 Spell(death_strike)
 #death_and_decay,if=spell_targets.death_and_decay>=3
 if Enemies(tagged=1) >= 3 Spell(death_and_decay)
 #heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd
 if BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD()
 {
  #blood_for_blood,if=health>health.max*0.50&buff.blood_for_blood.remains<=gcd
  # if Health() >= MaxHealth() * 0.75 and BuffRemaining(blood_for_blood_buff) <= GCD() Spell(blood_for_blood)
  Spell(heart_strike)
 }
 #blood_boil,if=buff.dancing_rune_weapon.up
 if BuffPresent(dancing_rune_weapon_buff) Spell(blood_boil)
 #death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2
 if { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies(tagged=1) >= 2 } Spell(death_and_decay)
 #consumption
 Spell(consumption)
 #blood_boil
 Spell(blood_boil)
 #heart_strike,if=rune.time_to_3<gcd|buff.bone_shield.stack>6
 if TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6
 {
  #blood_for_blood,if=health>health.max*0.50&buff.blood_for_blood.remains<=gcd
  # if Health() >= MaxHealth() * 0.75 and BuffRemaining(blood_for_blood_buff) <= GCD() Spell(blood_for_blood)
  Spell(heart_strike)
 }
}

AddFunction BloodStandardMainPostConditions
{
}

AddFunction BloodStandardShortCdActions
{
 unless RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Health() < MaxHealth() * 0.9 and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies(tagged=1) or Enemies(tagged=1) > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend)
 {
  #bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up
  if RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) Spell(bonestorm)

  unless { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies(tagged=1) * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies(tagged=1) >= 3 and Spell(death_and_decay)
  {
   #rune_strike,if=(charges_fractional>=1.8|buff.dancing_rune_weapon.up)&rune.time_to_3>=gcd
   if { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() Spell(rune_strike)

   unless { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies(tagged=1) >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil)
   {

    unless { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
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
 RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Health() < MaxHealth() * 0.9 and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies(tagged=1) or Enemies(tagged=1) > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies(tagged=1) * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies(tagged=1) >= 3 and Spell(death_and_decay) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies(tagged=1) >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike)
}

AddFunction BloodStandardCdActions
{
 unless RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Health() < MaxHealth() * 0.9 and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies(tagged=1) or Enemies(tagged=1) > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies(tagged=1) * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies(tagged=1) >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies(tagged=1) >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike) or Spell(rune_strike)
 {
  #arcane_torrent,if=runic_power.deficit>20
  if RunicPowerDeficit() > 20 Spell(arcane_torrent_runicpower)
 }
}

AddFunction BloodStandardCdPostConditions
{
 RunicPowerDeficit() <= 10 and Spell(death_strike) or not BuffPresent(dancing_rune_weapon_buff) and Health() < MaxHealth() * 0.9 and Spell(blooddrinker) or { BuffRemaining(bone_shield_buff) <= TimeToRunes(3) or BuffRemaining(bone_shield_buff) <= GCD() + { SpellCooldown(blooddrinker) == 0 } * TalentPoints(blooddrinker_talent) * 2 or BuffStacks(bone_shield_buff) < 3 } and RunicPowerDeficit() >= 20 and Spell(marrowrend) or Charges(blood_boil count=0) >= 1.8 and { BuffStacks(hemostasis_buff) <= 5 - Enemies(tagged=1) or Enemies(tagged=1) > 2 } and Spell(blood_boil) or BuffStacks(bone_shield_buff) < 5 and Talent(ossuary_talent) and RunicPowerDeficit() >= 15 and Spell(marrowrend) or RunicPower() >= 100 and not BuffPresent(dancing_rune_weapon_buff) and Spell(bonestorm) or { RunicPowerDeficit() <= 15 + BuffPresent(dancing_rune_weapon_buff) * 5 + Enemies(tagged=1) * TalentPoints(heartbreaker_talent) * 2 or target.TimeToDie() < 10 } and Spell(death_strike) or Enemies(tagged=1) >= 3 and Spell(death_and_decay) or { Charges(rune_strike count=0) >= 1.8 or BuffPresent(dancing_rune_weapon_buff) } and TimeToRunes(3) >= GCD() and Spell(rune_strike) or { BuffPresent(dancing_rune_weapon_buff) or TimeToRunes(4) < GCD() } and Spell(heart_strike) or BuffPresent(dancing_rune_weapon_buff) and Spell(blood_boil) or { BuffPresent(crimson_scourge_buff) or Talent(rapid_decomposition_talent) or Enemies(tagged=1) >= 2 } and Spell(death_and_decay) or Spell(consumption) or Spell(blood_boil) or { TimeToRunes(3) < GCD() or BuffStacks(bone_shield_buff) > 6 } and Spell(heart_strike) or Spell(rune_strike)
}
]]

		OvaleScripts:RegisterScript("DEATHKNIGHT", "blood", name, desc, code, "script")
	end
end