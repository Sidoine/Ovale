local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_warlock_affliction_pr"
    local desc = "[8.0] Simulationcraft: Warlock_Affliction_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Affliction".
#    class=warlock
#    spec=affliction
#    talents=3302023
#    pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)


AddFunction padding
{
 ExecuteTime(shadow_bolt) * HasAzeriteTrait(cascading_calamity_trait)
}

AddFunction spammable_seed
{
 Talent(sow_the_seeds_talent) and Enemies() >= 3 or Talent(siphon_life_talent) and Enemies() >= 5 or Enemies() >= 8
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=affliction)

AddFunction AfflictionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.default

AddFunction AfflictionDefaultMainActions
{
 #drain_soul,interrupt_global=1,chain=1,cycle_targets=1,if=target.time_to_die<=gcd&soul_shard<5
 if target.TimeToDie() <= GCD() and SoulShards() < 5 Spell(drain_soul)
 #haunt
 Spell(haunt)
 #agony,cycle_targets=1,if=remains<=gcd
 if target.DebuffRemaining(agony_debuff) <= GCD() Spell(agony)
 #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&talent.absolute_corruption.enabled&active_enemies=2&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=execute_time*2+travel_time&!action.shadow_bolt.in_flight
 if Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt) * 2 + TravelTime(shadow_bolt) and not InFlightToTarget(shadow_bolt) Spell(shadow_bolt)
 #vile_taint,if=time>20
 if TimeInCombat() > 20 Spell(vile_taint)
 #seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight
 if target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) Spell(seed_of_corruption)
 #agony,cycle_targets=1,max_cycle_targets=6,if=talent.creeping_death.enabled&target.time_to_die>10&refreshable
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 6 and Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) Spell(agony)
 #agony,cycle_targets=1,max_cycle_targets=8,if=(!talent.creeping_death.enabled)&target.time_to_die>10&refreshable
 if DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 8 and not Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) Spell(agony)
 #siphon_life,cycle_targets=1,max_cycle_targets=1,if=refreshable&target.time_to_die>10&((!(cooldown.summon_darkglare.remains<=soul_shard*action.unstable_affliction.execute_time)&active_enemies>=8)|active_enemies=1)
 if DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 1 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() >= 8 or Enemies() == 1 } Spell(siphon_life)
 #siphon_life,cycle_targets=1,max_cycle_targets=2,if=refreshable&target.time_to_die>10&((!(cooldown.summon_darkglare.remains<=soul_shard*action.unstable_affliction.execute_time)&active_enemies=7)|active_enemies=2)
 if DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 2 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 7 or Enemies() == 2 } Spell(siphon_life)
 #siphon_life,cycle_targets=1,max_cycle_targets=3,if=refreshable&target.time_to_die>10&((!(cooldown.summon_darkglare.remains<=soul_shard*action.unstable_affliction.execute_time)&active_enemies=6)|active_enemies=3)
 if DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 3 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 6 or Enemies() == 3 } Spell(siphon_life)
 #siphon_life,cycle_targets=1,max_cycle_targets=4,if=refreshable&target.time_to_die>10&((!(cooldown.summon_darkglare.remains<=soul_shard*action.unstable_affliction.execute_time)&active_enemies=5)|active_enemies=4)
 if DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 4 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 5 or Enemies() == 4 } Spell(siphon_life)
 #corruption,cycle_targets=1,if=active_enemies<3+talent.writhe_in_agony.enabled&refreshable&target.time_to_die>10
 if Enemies() < 3 + TalentPoints(writhe_in_agony_talent) and target.Refreshable(corruption_debuff) and target.TimeToDie() > 10 Spell(corruption)
 #vile_taint
 Spell(vile_taint)
 #unstable_affliction,if=soul_shard>=5
 if SoulShards() >= 5 Spell(unstable_affliction)
 #unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*execute_time
 if SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) Spell(unstable_affliction)
 #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
 if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersMainActions()

 unless { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions()
 {
  #seed_of_corruption,if=variable.spammable_seed
  if spammable_seed() Spell(seed_of_corruption)
  #unstable_affliction,if=!prev_gcd.1.summon_darkglare&!variable.spammable_seed&(talent.deathbolt.enabled&cooldown.deathbolt.remains<=execute_time&!azerite.cascading_calamity.enabled|soul_shard>=2&target.time_to_die>4+execute_time&active_enemies=1|target.time_to_die<=8+execute_time*soul_shard)
  if not PreviousGCDSpell(summon_darkglare) and not spammable_seed() and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or SoulShards() >= 2 and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } Spell(unstable_affliction)
  #unstable_affliction,if=!variable.spammable_seed&contagion<=cast_time+variable.padding
  if not spammable_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() Spell(unstable_affliction)
  #unstable_affliction,cycle_targets=1,if=!variable.spammable_seed&(!talent.deathbolt.enabled|cooldown.deathbolt.remains>time_to_shard|soul_shard>1)&contagion<=cast_time+variable.padding
  if not spammable_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() Spell(unstable_affliction)
  #call_action_list,name=fillers
  AfflictionFillersMainActions()
 }
}

AddFunction AfflictionDefaultMainPostConditions
{
 { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions() or AfflictionFillersMainPostConditions()
}

AddFunction AfflictionDefaultShortCdActions
{
 unless target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Spell(haunt) or target.DebuffRemaining(agony_debuff) <= GCD() and Spell(agony) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt) * 2 + TravelTime(shadow_bolt) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt)
 {
  #phantom_singularity,if=time>40
  if TimeInCombat() > 40 Spell(phantom_singularity)

  unless TimeInCombat() > 20 and Spell(vile_taint) or target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 6 and Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 8 and not Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 1 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() >= 8 or Enemies() == 1 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 2 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 7 or Enemies() == 2 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 3 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 6 or Enemies() == 3 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 4 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 5 or Enemies() == 4 } and Spell(siphon_life) or Enemies() < 3 + TalentPoints(writhe_in_agony_talent) and target.Refreshable(corruption_debuff) and target.TimeToDie() > 10 and Spell(corruption) or Spell(vile_taint) or SoulShards() >= 5 and Spell(unstable_affliction) or SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Spell(unstable_affliction)
  {
   #phantom_singularity
   Spell(phantom_singularity)
   #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
   if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersShortCdActions()

   unless { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersShortCdPostConditions() or spammable_seed() and Spell(seed_of_corruption) or not PreviousGCDSpell(summon_darkglare) and not spammable_seed() and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or SoulShards() >= 2 and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not spammable_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not spammable_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction)
   {
    #call_action_list,name=fillers
    AfflictionFillersShortCdActions()
   }
  }
 }
}

AddFunction AfflictionDefaultShortCdPostConditions
{
 target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Spell(haunt) or target.DebuffRemaining(agony_debuff) <= GCD() and Spell(agony) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt) * 2 + TravelTime(shadow_bolt) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt) or TimeInCombat() > 20 and Spell(vile_taint) or target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 6 and Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 8 and not Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 1 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() >= 8 or Enemies() == 1 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 2 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 7 or Enemies() == 2 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 3 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 6 or Enemies() == 3 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 4 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 5 or Enemies() == 4 } and Spell(siphon_life) or Enemies() < 3 + TalentPoints(writhe_in_agony_talent) and target.Refreshable(corruption_debuff) and target.TimeToDie() > 10 and Spell(corruption) or Spell(vile_taint) or SoulShards() >= 5 and Spell(unstable_affliction) or SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersShortCdPostConditions() or spammable_seed() and Spell(seed_of_corruption) or not PreviousGCDSpell(summon_darkglare) and not spammable_seed() and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or SoulShards() >= 2 and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not spammable_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not spammable_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or AfflictionFillersShortCdPostConditions()
}

AddFunction AfflictionDefaultCdActions
{
 #variable,name=spammable_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5|spell_targets.seed_of_corruption>=8
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #potion,if=(talent.dark_soul_misery.enabled&cooldown.summon_darkglare.up&cooldown.dark_soul.up)|cooldown.summon_darkglare.up|target.time_to_die<30
 if { Talent(dark_soul_misery_talent) and not SpellCooldown(summon_darkglare) > 0 and not SpellCooldown(dark_soul_misery) > 0 or not SpellCooldown(summon_darkglare) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #use_items,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } AfflictionUseItemActions()
 #fireblood,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(fireblood)
 #blood_fury,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(blood_fury_sp)

 unless target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Spell(haunt)
 {
  #summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)
  if target.DebuffPresent(agony_debuff) and target.DebuffPresent(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) > 0 } Spell(summon_darkglare)

  unless target.DebuffRemaining(agony_debuff) <= GCD() and Spell(agony) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt) * 2 + TravelTime(shadow_bolt) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt) or TimeInCombat() > 40 and Spell(phantom_singularity) or TimeInCombat() > 20 and Spell(vile_taint) or target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 6 and Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 8 and not Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 1 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() >= 8 or Enemies() == 1 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 2 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 7 or Enemies() == 2 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 3 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 6 or Enemies() == 3 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 4 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 5 or Enemies() == 4 } and Spell(siphon_life) or Enemies() < 3 + TalentPoints(writhe_in_agony_talent) and target.Refreshable(corruption_debuff) and target.TimeToDie() > 10 and Spell(corruption)
  {
   #dark_soul
   Spell(dark_soul_misery)

   unless Spell(vile_taint)
   {
    #berserking
    Spell(berserking)

    unless SoulShards() >= 5 and Spell(unstable_affliction) or SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Spell(unstable_affliction) or Spell(phantom_singularity)
    {
     #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
     if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersCdActions()

     unless { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersCdPostConditions() or spammable_seed() and Spell(seed_of_corruption) or not PreviousGCDSpell(summon_darkglare) and not spammable_seed() and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or SoulShards() >= 2 and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not spammable_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not spammable_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction)
     {
      #call_action_list,name=fillers
      AfflictionFillersCdActions()
     }
    }
   }
  }
 }
}

AddFunction AfflictionDefaultCdPostConditions
{
 target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Spell(haunt) or target.DebuffRemaining(agony_debuff) <= GCD() and Spell(agony) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt) * 2 + TravelTime(shadow_bolt) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt) or TimeInCombat() > 40 and Spell(phantom_singularity) or TimeInCombat() > 20 and Spell(vile_taint) or target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 6 and Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(agony_debuff) < Enemies() and DebuffCountOnAny(agony_debuff) <= 8 and not Talent(creeping_death_talent) and target.TimeToDie() > 10 and target.Refreshable(agony_debuff) and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 1 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() >= 8 or Enemies() == 1 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 2 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 7 or Enemies() == 2 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 3 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 6 or Enemies() == 3 } and Spell(siphon_life) or DebuffCountOnAny(siphon_life_debuff) < Enemies() and DebuffCountOnAny(siphon_life_debuff) <= 4 and target.Refreshable(siphon_life_debuff) and target.TimeToDie() > 10 and { not SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Enemies() == 5 or Enemies() == 4 } and Spell(siphon_life) or Enemies() < 3 + TalentPoints(writhe_in_agony_talent) and target.Refreshable(corruption_debuff) and target.TimeToDie() > 10 and Spell(corruption) or Spell(vile_taint) or SoulShards() >= 5 and Spell(unstable_affliction) or SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and Spell(unstable_affliction) or Spell(phantom_singularity) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersCdPostConditions() or spammable_seed() and Spell(seed_of_corruption) or not PreviousGCDSpell(summon_darkglare) and not spammable_seed() and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or SoulShards() >= 2 and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not spammable_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not spammable_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or AfflictionFillersCdPostConditions()
}

### actions.fillers

AddFunction AfflictionFillersMainActions
{
 #shadow_bolt,if=buff.movement.up&buff.nightfall.remains
 if Speed() > 0 and BuffPresent(nightfall_buff) Spell(shadow_bolt)
 #agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
 if Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } Spell(agony)
 #siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
 if Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } Spell(siphon_life)
 #corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
 if Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) Spell(corruption)
 #drain_life,if=(buff.inevitable_demise.stack>=90&(cooldown.deathbolt.remains>execute_time|!talent.deathbolt.enabled)&(cooldown.phantom_singularity.remains>execute_time|!talent.phantom_singularity.enabled)&(cooldown.dark_soul.remains>execute_time|!talent.dark_soul_misery.enabled)&(cooldown.vile_taint.remains>execute_time|!talent.vile_taint.enabled)&cooldown.summon_darkglare.remains>execute_time+10|buff.inevitable_demise.stack>30&target.time_to_die<=10)
 if BuffStacks(inevitable_demise_buff) >= 90 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 Spell(drain_life)
 #drain_soul,interrupt_global=1,chain=1,cycle_targets=1,if=target.time_to_die<=gcd
 if target.TimeToDie() <= GCD() Spell(drain_soul)
 #drain_soul,interrupt_global=1,chain=1
 Spell(drain_soul)
 #shadow_bolt,cycle_targets=1,if=talent.shadow_embrace.enabled&talent.absolute_corruption.enabled&active_enemies=2&!debuff.shadow_embrace.remains&!action.shadow_bolt.in_flight
 if Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt) Spell(shadow_bolt)
 #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&talent.absolute_corruption.enabled&active_enemies=2
 if Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 Spell(shadow_bolt)
 #shadow_bolt
 Spell(shadow_bolt)
}

AddFunction AfflictionFillersMainPostConditions
{
}

AddFunction AfflictionFillersShortCdActions
{
 #deathbolt
 Spell(deathbolt)
}

AddFunction AfflictionFillersShortCdPostConditions
{
 Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 90 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 } and Spell(drain_life) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and Spell(shadow_bolt) or Spell(shadow_bolt)
}

AddFunction AfflictionFillersCdActions
{
}

AddFunction AfflictionFillersCdPostConditions
{
 Spell(deathbolt) or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 90 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 } and Spell(drain_life) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt) and Spell(shadow_bolt) or Talent(shadow_embrace_talent) and Talent(absolute_corruption_talent) and Enemies() == 2 and Spell(shadow_bolt) or Spell(shadow_bolt)
}

### actions.precombat

AddFunction AfflictionPrecombatMainActions
{
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
 #seed_of_corruption,if=spell_targets.seed_of_corruption_aoe>=3
 if Enemies() >= 3 Spell(seed_of_corruption)
 #haunt
 Spell(haunt)
 #shadow_bolt,if=!talent.haunt.enabled&spell_targets.seed_of_corruption_aoe<3
 if not Talent(haunt_talent) and Enemies() < 3 Spell(shadow_bolt)
}

AddFunction AfflictionPrecombatMainPostConditions
{
}

AddFunction AfflictionPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.Present() Spell(summon_imp)
}

AddFunction AfflictionPrecombatShortCdPostConditions
{
 Enemies() >= 3 and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies() < 3 and Spell(shadow_bolt)
}

AddFunction AfflictionPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_imp)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction AfflictionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Enemies() >= 3 and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies() < 3 and Spell(shadow_bolt)
}

### Affliction icons.

AddCheckBox(opt_warlock_affliction_aoe L(AOE) default specialization=affliction)

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=shortcd specialization=affliction
{
 if not InCombat() AfflictionPrecombatShortCdActions()
 unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
 {
  AfflictionDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=shortcd specialization=affliction
{
 if not InCombat() AfflictionPrecombatShortCdActions()
 unless not InCombat() and AfflictionPrecombatShortCdPostConditions()
 {
  AfflictionDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=affliction
{
 if not InCombat() AfflictionPrecombatMainActions()
 unless not InCombat() and AfflictionPrecombatMainPostConditions()
 {
  AfflictionDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=aoe specialization=affliction
{
 if not InCombat() AfflictionPrecombatMainActions()
 unless not InCombat() and AfflictionPrecombatMainPostConditions()
 {
  AfflictionDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=cd specialization=affliction
{
 if not InCombat() AfflictionPrecombatCdActions()
 unless not InCombat() and AfflictionPrecombatCdPostConditions()
 {
  AfflictionDefaultCdActions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=cd specialization=affliction
{
 if not InCombat() AfflictionPrecombatCdActions()
 unless not InCombat() and AfflictionPrecombatCdPostConditions()
 {
  AfflictionDefaultCdActions()
 }
}

### Required symbols
# absolute_corruption_talent
# agony
# agony_debuff
# battle_potion_of_intellect
# berserking
# blood_fury_sp
# cascading_calamity_trait
# corruption
# corruption_debuff
# creeping_death_talent
# dark_soul_misery
# dark_soul_misery_talent
# deathbolt
# deathbolt_talent
# drain_life
# drain_soul
# fireblood
# grimoire_of_sacrifice
# grimoire_of_sacrifice_talent
# haunt
# haunt_talent
# inevitable_demise_buff
# nightfall_buff
# phantom_singularity
# phantom_singularity_talent
# seed_of_corruption
# seed_of_corruption_debuff
# shadow_bolt
# shadow_embrace_debuff
# shadow_embrace_talent
# siphon_life
# siphon_life_debuff
# siphon_life_talent
# sow_the_seeds_talent
# summon_darkglare
# summon_imp
# unstable_affliction
# vile_taint
# vile_taint_talent
# writhe_in_agony_talent

]]
    OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
end
do
    local name = "sc_warlock_demonology_pr"
    local desc = "[8.0] Simulationcraft: Warlock_Demonology_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Demonology".
#    class=warlock
#    spec=demonology
#    talents=1103021
#    pet=felguard

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=demonology)

AddFunction DemonologyUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
 #doom,if=!ticking&time_to_die>30&spell_targets.implosion<2
 if not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 Spell(doom)
 #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
 if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherPortalMainActions()

 unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalMainPostConditions()
 {
  #call_action_list,name=implosion,if=spell_targets.implosion>1
  if Enemies() > 1 DemonologyImplosionMainActions()

  unless Enemies() > 1 and DemonologyImplosionMainPostConditions()
  {
   #call_dreadstalkers,if=equipped.132369|(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
   if HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
   #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
   if Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 Spell(power_siphon)
   #doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
   if Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 Spell(doom)
   #hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
   if SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } Spell(hand_of_guldan)
   #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
   if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
   #demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<10|cooldown.summon_demonic_tyrant.remains>22)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25)
   if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } Spell(demonbolt)
   #call_action_list,name=build_a_shard
   DemonologyBuildAShardMainActions()
  }
 }
}

AddFunction DemonologyDefaultMainPostConditions
{
 Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalMainPostConditions() or Enemies() > 1 and DemonologyImplosionMainPostConditions() or DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyDefaultShortCdActions
{
 unless not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom)
 {
  #demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
  if Demons(wild_imp) < 6 or DebuffPresent(demonic_power) or Enemies() < 2 Spell(demonic_strength)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherPortalShortCdActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalShortCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionShortCdActions()

   unless Enemies() > 1 and DemonologyImplosionShortCdPostConditions()
   {
    #summon_vilefiend,if=equipped.132369|cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

    unless { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
    {
     #summon_demonic_tyrant,if=equipped.132369|(buff.dreadstalkers.remains>cast_time&(buff.wild_imps.stack>=3|prev_gcd.1.hand_of_guldan)&(soul_shard<3|buff.dreadstalkers.remains<gcd*2.7|buff.grimoire_felguard.remains<gcd*2.7))
     if HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } Spell(summon_demonic_tyrant)

     unless Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt)
     {
      #call_action_list,name=build_a_shard
      DemonologyBuildAShardShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultShortCdPostConditions
{
 not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalShortCdPostConditions() or Enemies() > 1 and DemonologyImplosionShortCdPostConditions() or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyDefaultCdActions
{
 #potion,if=pet.demonic_tyrant.active|target.time_to_die<30
 if { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #use_items,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 DemonologyUseItemActions()
 #berserking,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(berserking)
 #blood_fury,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(blood_fury_sp)
 #fireblood,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(fireblood)

 unless not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or { Demons(wild_imp) < 6 or DebuffPresent(demonic_power) or Enemies() < 2 } and Spell(demonic_strength)
 {
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherPortalCdActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionCdActions()

   unless Enemies() > 1 and DemonologyImplosionCdPostConditions()
   {
    #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
    if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

    unless { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt)
    {
     #call_action_list,name=build_a_shard
     DemonologyBuildAShardCdActions()
    }
   }
  }
 }
}

AddFunction DemonologyDefaultCdPostConditions
{
 not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or { Demons(wild_imp) < 6 or DebuffPresent(demonic_power) or Enemies() < 2 } and Spell(demonic_strength) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherPortalCdPostConditions() or Enemies() > 1 and DemonologyImplosionCdPostConditions() or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt) or DemonologyBuildAShardCdPostConditions()
}

### actions.build_a_shard

AddFunction DemonologyBuildAShardMainActions
{
 #demonbolt,if=azerite.forbidden_knowledge.enabled&buff.forbidden_knowledge.react&!buff.demonic_core.react&cooldown.summon_demonic_tyrant.remains>20
 if HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 Spell(demonbolt)
 #soul_strike
 Spell(soul_strike)
 #shadow_bolt
 Spell(shadow_bolt)
}

AddFunction DemonologyBuildAShardMainPostConditions
{
}

AddFunction DemonologyBuildAShardShortCdActions
{
}

AddFunction DemonologyBuildAShardShortCdPostConditions
{
 HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 and Spell(demonbolt) or Spell(soul_strike) or Spell(shadow_bolt)
}

AddFunction DemonologyBuildAShardCdActions
{
}

AddFunction DemonologyBuildAShardCdPostConditions
{
 HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 and Spell(demonbolt) or Spell(soul_strike) or Spell(shadow_bolt)
}

### actions.implosion

AddFunction DemonologyImplosionMainActions
{
 #implosion,if=(buff.wild_imps.stack>=6&(soul_shard<3|prev_gcd.1.call_dreadstalkers|buff.wild_imps.stack>=9|prev_gcd.1.bilescourge_bombers|(!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan))&!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&buff.demonic_power.down)|(time_to_die<3&buff.wild_imps.stack>0)|(prev_gcd.2.call_dreadstalkers&buff.wild_imps.stack>2&!talent.demonic_calling.enabled)
 if Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) Spell(implosion)
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard>=5
 if SoulShards() >= 5 Spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&(((prev_gcd.2.hand_of_guldan|buff.wild_imps.stack>=3)&buff.wild_imps.stack<9)|cooldown.summon_demonic_tyrant.remains<=gcd*2|buff.demonic_power.remains>gcd*2)
 if SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } Spell(hand_of_guldan)
 #demonbolt,if=prev_gcd.1.hand_of_guldan&soul_shard>=1&(buff.wild_imps.stack<=3|prev_gcd.3.hand_of_guldan)&soul_shard<4&buff.demonic_core.up
 if PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) Spell(demonbolt)
 #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
 if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.up&(buff.demonic_core.stack>=3|buff.demonic_core.remains<=gcd*5.7)
 if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } Spell(demonbolt)
 #doom,cycle_targets=1,max_cycle_targets=7,if=refreshable
 if DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) Spell(doom)
 #call_action_list,name=build_a_shard
 DemonologyBuildAShardMainActions()
}

AddFunction DemonologyImplosionMainPostConditions
{
 DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyImplosionShortCdActions
{
 unless { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #summon_demonic_tyrant
  Spell(summon_demonic_tyrant)

  unless SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
  {
   #summon_vilefiend,if=(cooldown.summon_demonic_tyrant.remains>40&spell_targets.implosion<=2)|cooldown.summon_demonic_tyrant.remains<12
   if SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)
   #bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
   if SpellCooldown(summon_demonic_tyrant) > 9 Spell(bilescourge_bombers)

   unless SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildAShardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyImplosionShortCdPostConditions
{
 { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyImplosionCdActions
{
 unless { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

  unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Spell(summon_demonic_tyrant) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildAShardCdActions()
  }
 }
}

AddFunction DemonologyImplosionCdPostConditions
{
 { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Spell(summon_demonic_tyrant) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildAShardCdPostConditions()
}

### actions.nether_portal

AddFunction DemonologyNetherPortalMainActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingMainActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingMainPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherPortalActiveMainActions()
 }
}

AddFunction DemonologyNetherPortalMainPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingMainPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherPortalActiveMainPostConditions()
}

AddFunction DemonologyNetherPortalShortCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingShortCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingShortCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherPortalActiveShortCdActions()
 }
}

AddFunction DemonologyNetherPortalShortCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingShortCdPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherPortalActiveShortCdPostConditions()
}

AddFunction DemonologyNetherPortalCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherPortalActiveCdActions()
 }
}

AddFunction DemonologyNetherPortalCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingCdPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherPortalActiveCdPostConditions()
}

### actions.nether_portal_active

AddFunction DemonologyNetherPortalActiveMainActions
{
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
 #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
 if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildAShardMainActions()

 unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardMainPostConditions()
 {
  #hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(160+action.hand_of_guldan.cast_time)
  if SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) Spell(hand_of_guldan)
  #demonbolt,if=buff.demonic_core.up
  if BuffPresent(demonic_core_buff) Spell(demonbolt)
  #call_action_list,name=build_a_shard
  DemonologyBuildAShardMainActions()
 }
}

AddFunction DemonologyNetherPortalActiveMainPostConditions
{
 SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardMainPostConditions() or DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyNetherPortalActiveShortCdActions
{
 #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
 if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

 unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildAShardShortCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan)
  {
   #summon_demonic_tyrant,if=buff.nether_portal.remains<10&soul_shard=0
   if BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 Spell(summon_demonic_tyrant)
   #summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+5.5
   if BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 Spell(summon_demonic_tyrant)

   unless BuffPresent(demonic_core_buff) and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildAShardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyNetherPortalActiveShortCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyNetherPortalActiveCdActions
{
 #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
 if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

 unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildAShardCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and Spell(demonbolt)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildAShardCdActions()
  }
 }
}

AddFunction DemonologyNetherPortalActiveCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildAShardCdPostConditions()
}

### actions.nether_portal_building

AddFunction DemonologyNetherPortalBuildingMainActions
{
 #call_dreadstalkers
 Spell(call_dreadstalkers)
 #hand_of_guldan,if=cooldown.call_dreadstalkers.remains>18&soul_shard>=3
 if SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 Spell(hand_of_guldan)
 #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&soul_shard>=3
 if Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 Spell(power_siphon)
 #hand_of_guldan,if=soul_shard>=5
 if SoulShards() >= 5 Spell(hand_of_guldan)
 #call_action_list,name=build_a_shard
 DemonologyBuildAShardMainActions()
}

AddFunction DemonologyNetherPortalBuildingMainPostConditions
{
 DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyNetherPortalBuildingShortCdActions
{
 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildAShardShortCdActions()
 }
}

AddFunction DemonologyNetherPortalBuildingShortCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyNetherPortalBuildingCdActions
{
 #nether_portal,if=soul_shard>=5&(!talent.power_siphon.enabled|buff.demonic_core.up)
 if SoulShards() >= 5 and { not Talent(power_siphon_talent) or BuffPresent(demonic_core_buff) } Spell(nether_portal)

 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildAShardCdActions()
 }
}

AddFunction DemonologyNetherPortalBuildingCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildAShardCdPostConditions()
}

### actions.precombat

AddFunction DemonologyPrecombatMainActions
{
 #inner_demons,if=talent.inner_demons.enabled
 if Talent(inner_demons_talent) Spell(inner_demons)
 #demonbolt
 Spell(demonbolt)
}

AddFunction DemonologyPrecombatMainPostConditions
{
}

AddFunction DemonologyPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.Present() Spell(summon_felguard)
}

AddFunction DemonologyPrecombatShortCdPostConditions
{
 Talent(inner_demons_talent) and Spell(inner_demons) or Spell(demonbolt)
}

AddFunction DemonologyPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_felguard) or Talent(inner_demons_talent) and Spell(inner_demons)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction DemonologyPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_felguard) or Talent(inner_demons_talent) and Spell(inner_demons) or Spell(demonbolt)
}

### Demonology icons.

AddCheckBox(opt_warlock_demonology_aoe L(AOE) default specialization=demonology)

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=shortcd specialization=demonology
{
 if not InCombat() DemonologyPrecombatShortCdActions()
 unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
 {
  DemonologyDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=shortcd specialization=demonology
{
 if not InCombat() DemonologyPrecombatShortCdActions()
 unless not InCombat() and DemonologyPrecombatShortCdPostConditions()
 {
  DemonologyDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=demonology
{
 if not InCombat() DemonologyPrecombatMainActions()
 unless not InCombat() and DemonologyPrecombatMainPostConditions()
 {
  DemonologyDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=aoe specialization=demonology
{
 if not InCombat() DemonologyPrecombatMainActions()
 unless not InCombat() and DemonologyPrecombatMainPostConditions()
 {
  DemonologyDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=cd specialization=demonology
{
 if not InCombat() DemonologyPrecombatCdActions()
 unless not InCombat() and DemonologyPrecombatCdPostConditions()
 {
  DemonologyDefaultCdActions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=cd specialization=demonology
{
 if not InCombat() DemonologyPrecombatCdActions()
 unless not InCombat() and DemonologyPrecombatCdPostConditions()
 {
  DemonologyDefaultCdActions()
 }
}

### Required symbols
# battle_potion_of_intellect
# berserking
# bilescourge_bombers
# bilescourge_bombers_talent
# blood_fury_sp
# call_dreadstalkers
# demonbolt
# demonic_calling_buff
# demonic_calling_talent
# demonic_core_buff
# demonic_power
# demonic_strength
# doom
# doom_debuff
# doom_talent
# fireblood
# forbidden_knowledge_buff
# forbidden_knowledge_trait
# grimoire_felguard
# hand_of_guldan
# implosion
# inner_demons
# inner_demons_talent
# nether_portal
# nether_portal_buff
# nether_portal_talent
# power_siphon
# power_siphon_talent
# shadow_bolt
# soul_strike
# summon_demonic_tyrant
# summon_felguard
# summon_vilefiend
# summon_vilefiend_talent
# wilfreds_sigil_of_superior_summoning_item

]]
    OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
end
do
    local name = "sc_warlock_destruction_pr"
    local desc = "[8.0] Simulationcraft: Warlock_Destruction_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Destruction".
#    class=warlock
#    spec=destruction
#    talents=1203023
#    pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=destruction)

AddFunction DestructionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3&talent.cataclysm.enabled
 if Enemies() >= 3 and Talent(cataclysm_talent) DestructionCataMainActions()

 unless Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataMainPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 and Talent(fire_and_brimstone_talent) DestructionFnbMainActions()

  unless Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbMainPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3&talent.inferno.enabled
   if Enemies() >= 3 and Talent(inferno_talent) DestructionInfMainActions()

   unless Enemies() >= 3 and Talent(inferno_talent) and DestructionInfMainPostConditions()
   {
    #immolate,cycle_targets=1,if=!debuff.havoc.remains&(refreshable|talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains-action.chaos_bolt.travel_time-5<duration*0.3)
    if not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } Spell(immolate)
    #call_action_list,name=cds
    DestructionCdsMainActions()

    unless DestructionCdsMainPostConditions()
    {
     #channel_demonfire
     Spell(channel_demonfire)
     #soul_fire,cycle_targets=1,if=!debuff.havoc.remains
     if not target.DebuffPresent(havoc_debuff) Spell(soul_fire)
     #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&execute_time+travel_time<target.time_to_die&(talent.internal_combustion.enabled|!talent.internal_combustion.enabled&soul_shard>=4|(talent.eradication.enabled&debuff.eradication.remains<=cast_time)|buff.dark_soul_instability.remains>cast_time|pet.infernal.active&talent.grimoire_of_supremacy.enabled)
     if not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { Talent(internal_combustion_talent) or not Talent(internal_combustion_talent) and SoulShards() >= 4 or Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 and Talent(grimoire_of_supremacy_talent) } Spell(chaos_bolt)
     #conflagrate,cycle_targets=1,if=!debuff.havoc.remains&((talent.flashover.enabled&buff.backdraft.stack<=2)|(!talent.flashover.enabled&buff.backdraft.stack<2))
     if not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or not Talent(flashover_talent) and BuffStacks(backdraft_buff) < 2 } Spell(conflagrate)
     #shadowburn,cycle_targets=1,if=!debuff.havoc.remains&((charges=2|!buff.backdraft.remains|buff.backdraft.remains>buff.backdraft.stack*action.incinerate.execute_time))
     if not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } Spell(shadowburn)
     #incinerate,cycle_targets=1,if=!debuff.havoc.remains
     if not target.DebuffPresent(havoc_debuff) Spell(incinerate)
    }
   }
  }
 }
}

AddFunction DestructionDefaultMainPostConditions
{
 Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataMainPostConditions() or Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbMainPostConditions() or Enemies() >= 3 and Talent(inferno_talent) and DestructionInfMainPostConditions() or DestructionCdsMainPostConditions()
}

AddFunction DestructionDefaultShortCdActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3&talent.cataclysm.enabled
 if Enemies() >= 3 and Talent(cataclysm_talent) DestructionCataShortCdActions()

 unless Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataShortCdPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 and Talent(fire_and_brimstone_talent) DestructionFnbShortCdActions()

  unless Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbShortCdPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3&talent.inferno.enabled
   if Enemies() >= 3 and Talent(inferno_talent) DestructionInfShortCdActions()

   unless Enemies() >= 3 and Talent(inferno_talent) and DestructionInfShortCdPostConditions() or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate)
   {
    #call_action_list,name=cds
    DestructionCdsShortCdActions()

    unless DestructionCdsShortCdPostConditions()
    {
     #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10
     if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() > 1 Spell(havoc)
     #havoc,if=active_enemies>1
     if Enemies() > 1 and Enemies() > 1 Spell(havoc)

     unless Spell(channel_demonfire)
     {
      #cataclysm
      Spell(cataclysm)
     }
    }
   }
  }
 }
}

AddFunction DestructionDefaultShortCdPostConditions
{
 Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataShortCdPostConditions() or Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbShortCdPostConditions() or Enemies() >= 3 and Talent(inferno_talent) and DestructionInfShortCdPostConditions() or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate) or DestructionCdsShortCdPostConditions() or Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { Talent(internal_combustion_talent) or not Talent(internal_combustion_talent) and SoulShards() >= 4 or Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 and Talent(grimoire_of_supremacy_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or not Talent(flashover_talent) and BuffStacks(backdraft_buff) < 2 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionDefaultCdActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3&talent.cataclysm.enabled
 if Enemies() >= 3 and Talent(cataclysm_talent) DestructionCataCdActions()

 unless Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataCdPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 and Talent(fire_and_brimstone_talent) DestructionFnbCdActions()

  unless Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbCdPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3&talent.inferno.enabled
   if Enemies() >= 3 and Talent(inferno_talent) DestructionInfCdActions()

   unless Enemies() >= 3 and Talent(inferno_talent) and DestructionInfCdPostConditions() or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate)
   {
    #call_action_list,name=cds
    DestructionCdsCdActions()
   }
  }
 }
}

AddFunction DestructionDefaultCdPostConditions
{
 Enemies() >= 3 and Talent(cataclysm_talent) and DestructionCataCdPostConditions() or Enemies() >= 3 and Talent(fire_and_brimstone_talent) and DestructionFnbCdPostConditions() or Enemies() >= 3 and Talent(inferno_talent) and DestructionInfCdPostConditions() or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate) or DestructionCdsCdPostConditions() or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() > 1 and Spell(havoc) or Enemies() > 1 and Enemies() > 1 and Spell(havoc) or Spell(channel_demonfire) or Spell(cataclysm) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { Talent(internal_combustion_talent) or not Talent(internal_combustion_talent) and SoulShards() >= 4 or Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 and Talent(grimoire_of_supremacy_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or not Talent(flashover_talent) and BuffStacks(backdraft_buff) < 2 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

### actions.cata

AddFunction DestructionCataMainActions
{
 #call_action_list,name=cds
 DestructionCdsMainActions()

 unless DestructionCdsMainPostConditions()
 {
  #rain_of_fire,if=soul_shard>=4.5
  if SoulShards() >= 4.5 Spell(rain_of_fire)
  #immolate,if=talent.channel_demonfire.enabled&!remains&cooldown.channel_demonfire.remains<=action.chaos_bolt.execute_time
  if Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) Spell(immolate)
  #channel_demonfire
  Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&active_enemies<=8&((108*spell_targets.rain_of_fire%3)<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=4
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 Spell(chaos_bolt)
  #immolate,cycle_targets=1,if=!debuff.havoc.remains&refreshable&remains<=cooldown.cataclysm.remains
  if not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and target.DebuffRemaining(immolate_debuff) <= SpellCooldown(cataclysm) Spell(immolate)
  #rain_of_fire
  Spell(rain_of_fire)
  #soul_fire,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(soul_fire)
  #conflagrate,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(conflagrate)
  #shadowburn,cycle_targets=1,if=!debuff.havoc.remains&((charges=2|!buff.backdraft.remains|buff.backdraft.remains>buff.backdraft.stack*action.incinerate.execute_time))
  if not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } Spell(shadowburn)
  #incinerate,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(incinerate)
 }
}

AddFunction DestructionCataMainPostConditions
{
 DestructionCdsMainPostConditions()
}

AddFunction DestructionCataShortCdActions
{
 #call_action_list,name=cds
 DestructionCdsShortCdActions()

 unless DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire)
 {
  #cataclysm
  Spell(cataclysm)

  unless Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=8&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 8 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=8&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if Enemies() <= 8 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

   unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
   {
    #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4
    if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Enemies() > 1 Spell(havoc)
    #havoc,if=spell_targets.rain_of_fire<=4
    if Enemies() <= 4 and Enemies() > 1 Spell(havoc)
   }
  }
 }
}

AddFunction DestructionCataShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and target.DebuffRemaining(immolate_debuff) <= SpellCooldown(cataclysm) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionCataCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionCataCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Spell(cataclysm) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 8 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 8 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and target.DebuffRemaining(immolate_debuff) <= SpellCooldown(cataclysm) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

### actions.cds

AddFunction DestructionCdsMainActions
{
}

AddFunction DestructionCdsMainPostConditions
{
}

AddFunction DestructionCdsShortCdActions
{
}

AddFunction DestructionCdsShortCdPostConditions
{
}

AddFunction DestructionCdsCdActions
{
 #summon_infernal,if=target.time_to_die>=210|!cooldown.dark_soul_instability.remains|target.time_to_die<=30+gcd|!talent.dark_soul_instability.enabled
 if target.TimeToDie() >= 210 or not SpellCooldown(dark_soul_instability) > 0 or target.TimeToDie() <= 30 + GCD() or not Talent(dark_soul_instability_talent) Spell(summon_infernal)
 #dark_soul_instability,if=target.time_to_die>=140|pet.infernal.active|target.time_to_die<=20+gcd
 if target.TimeToDie() >= 140 or DemonDuration(infernal) > 0 or target.TimeToDie() <= 20 + GCD() Spell(dark_soul_instability)
 #potion,if=pet.infernal.active|target.time_to_die<65
 if { DemonDuration(infernal) > 0 or target.TimeToDie() < 65 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #berserking
 Spell(berserking)
 #blood_fury
 Spell(blood_fury_sp)
 #fireblood
 Spell(fireblood)
 #use_items
 DestructionUseItemActions()
}

AddFunction DestructionCdsCdPostConditions
{
}

### actions.fnb

AddFunction DestructionFnbMainActions
{
 #call_action_list,name=cds
 DestructionCdsMainActions()

 unless DestructionCdsMainPostConditions()
 {
  #rain_of_fire,if=soul_shard>=4.5
  if SoulShards() >= 4.5 Spell(rain_of_fire)
  #immolate,if=talent.channel_demonfire.enabled&!remains&cooldown.channel_demonfire.remains<=action.chaos_bolt.execute_time
  if Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) Spell(immolate)
  #channel_demonfire
  Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&active_enemies<=4&((108*spell_targets.rain_of_fire%3)<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=4
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 Spell(chaos_bolt)
  #immolate,cycle_targets=1,if=!debuff.havoc.remains&refreshable&spell_targets.incinerate<=8
  if not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 Spell(immolate)
  #rain_of_fire
  Spell(rain_of_fire)
  #soul_fire,cycle_targets=1,if=!debuff.havoc.remains&spell_targets.incinerate=3
  if not target.DebuffPresent(havoc_debuff) and Enemies() == 3 Spell(soul_fire)
  #conflagrate,cycle_targets=1,if=!debuff.havoc.remains&(talent.flashover.enabled&buff.backdraft.stack<=2|spell_targets.incinerate<=7|talent.roaring_blaze.enabled&spell_targets.incinerate<=9)
  if not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 or Talent(roaring_blaze_talent) and Enemies() <= 9 } Spell(conflagrate)
  #incinerate,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(incinerate)
 }
}

AddFunction DestructionFnbMainPostConditions
{
 DestructionCdsMainPostConditions()
}

AddFunction DestructionFnbShortCdActions
{
 #call_action_list,name=cds
 DestructionCdsShortCdActions()

 unless DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire)
 {
  #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
  if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
  #havoc,if=spell_targets.rain_of_fire<=4&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
  if Enemies() <= 4 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

  unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=4
   if Enemies() <= 4 and Enemies() > 1 Spell(havoc)
  }
 }
}

AddFunction DestructionFnbShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Enemies() == 3 and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 or Talent(roaring_blaze_talent) and Enemies() <= 9 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionFnbCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionFnbCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and 108 * Enemies() / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Enemies() == 3 and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 or Talent(roaring_blaze_talent) and Enemies() <= 9 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

### actions.inf

AddFunction DestructionInfMainActions
{
 #call_action_list,name=cds
 DestructionCdsMainActions()

 unless DestructionCdsMainPostConditions()
 {
  #rain_of_fire,if=soul_shard>=4.5
  if SoulShards() >= 4.5 Spell(rain_of_fire)
  #immolate,if=talent.channel_demonfire.enabled&!remains&cooldown.channel_demonfire.remains<=action.chaos_bolt.execute_time
  if Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) Spell(immolate)
  #channel_demonfire
  Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&spell_targets.rain_of_fire<=4+talent.internal_combustion.enabled&((108*spell_targets.rain_of_fire%(3-0.16*spell_targets.rain_of_fire))<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and 108 * Enemies() / { 3 - 0.16 * Enemies() } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=3&(talent.eradication.enabled|talent.internal_combustion.enabled)
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } Spell(chaos_bolt)
  #immolate,cycle_targets=1,if=!debuff.havoc.remains&refreshable
  if not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) Spell(immolate)
  #rain_of_fire
  Spell(rain_of_fire)
  #soul_fire,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(soul_fire)
  #conflagrate,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(conflagrate)
  #shadowburn,cycle_targets=1,if=!debuff.havoc.remains&((charges=2|!buff.backdraft.remains|buff.backdraft.remains>buff.backdraft.stack*action.incinerate.execute_time))
  if not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } Spell(shadowburn)
  #incinerate,cycle_targets=1,if=!debuff.havoc.remains
  if not target.DebuffPresent(havoc_debuff) Spell(incinerate)
 }
}

AddFunction DestructionInfMainPostConditions
{
 DestructionCdsMainPostConditions()
}

AddFunction DestructionInfShortCdActions
{
 #call_action_list,name=cds
 DestructionCdsShortCdActions()

 unless DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire)
 {
  #cataclysm
  Spell(cataclysm)

  unless Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4+talent.internal_combustion.enabled&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=4+talent.internal_combustion.enabled&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if Enemies() <= 4 + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

   unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and 108 * Enemies() / { 3 - 0.16 * Enemies() } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
   {
    #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=3&(talent.eradication.enabled|talent.internal_combustion.enabled)
    if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 Spell(havoc)
    #havoc,if=spell_targets.rain_of_fire<=3&(talent.eradication.enabled|talent.internal_combustion.enabled)
    if Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 Spell(havoc)
   }
  }
 }
}

AddFunction DestructionInfShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and 108 * Enemies() / { 3 - 0.16 * Enemies() } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionInfCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionInfCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Spell(cataclysm) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + TalentPoints(internal_combustion_talent) and 108 * Enemies() / { 3 - 0.16 * Enemies() } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 and Spell(havoc) or Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

### actions.precombat

AddFunction DestructionPrecombatMainActions
{
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
 #soul_fire
 Spell(soul_fire)
 #incinerate,if=!talent.soul_fire.enabled
 if not Talent(soul_fire_talent) Spell(incinerate)
}

AddFunction DestructionPrecombatMainPostConditions
{
}

AddFunction DestructionPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.Present() Spell(summon_imp)
}

AddFunction DestructionPrecombatShortCdPostConditions
{
 Spell(soul_fire) or not Talent(soul_fire_talent) and Spell(incinerate)
}

AddFunction DestructionPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_imp)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction DestructionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Spell(soul_fire) or not Talent(soul_fire_talent) and Spell(incinerate)
}

### Destruction icons.

AddCheckBox(opt_warlock_destruction_aoe L(AOE) default specialization=destruction)

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=shortcd specialization=destruction
{
 if not InCombat() DestructionPrecombatShortCdActions()
 unless not InCombat() and DestructionPrecombatShortCdPostConditions()
 {
  DestructionDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=shortcd specialization=destruction
{
 if not InCombat() DestructionPrecombatShortCdActions()
 unless not InCombat() and DestructionPrecombatShortCdPostConditions()
 {
  DestructionDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=destruction
{
 if not InCombat() DestructionPrecombatMainActions()
 unless not InCombat() and DestructionPrecombatMainPostConditions()
 {
  DestructionDefaultMainActions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=aoe specialization=destruction
{
 if not InCombat() DestructionPrecombatMainActions()
 unless not InCombat() and DestructionPrecombatMainPostConditions()
 {
  DestructionDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=cd specialization=destruction
{
 if not InCombat() DestructionPrecombatCdActions()
 unless not InCombat() and DestructionPrecombatCdPostConditions()
 {
  DestructionDefaultCdActions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=cd specialization=destruction
{
 if not InCombat() DestructionPrecombatCdActions()
 unless not InCombat() and DestructionPrecombatCdPostConditions()
 {
  DestructionDefaultCdActions()
 }
}

### Required symbols
# active_havoc_buff
# backdraft_buff
# battle_potion_of_intellect
# berserking
# blood_fury_sp
# cataclysm
# cataclysm_talent
# channel_demonfire
# channel_demonfire_talent
# chaos_bolt
# conflagrate
# dark_soul_instability
# dark_soul_instability_buff
# dark_soul_instability_talent
# eradication_debuff
# eradication_talent
# fire_and_brimstone_talent
# fireblood
# flashover_talent
# grimoire_of_sacrifice
# grimoire_of_sacrifice_talent
# grimoire_of_supremacy_buff
# grimoire_of_supremacy_talent
# havoc
# havoc_debuff
# immolate
# immolate_debuff
# incinerate
# inferno_talent
# internal_combustion_talent
# rain_of_fire
# roaring_blaze_talent
# shadowburn
# soul_fire
# soul_fire_talent
# summon_imp
# summon_infernal

]]
    OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
