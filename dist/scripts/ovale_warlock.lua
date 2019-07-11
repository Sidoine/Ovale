local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_warlock_affliction"
    local desc = "[8.2] Simulationcraft: PR_Warlock_Affliction"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Affliction".
#	class=warlock
#	spec=affliction
#	talents=3302023
#	pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)


AddFunction maintain_se
{
 Enemies() <= 1 + TalentPoints(writhe_in_agony_talent) + TalentPoints(absolute_corruption_talent) * 2 + { Talent(writhe_in_agony_talent) and Talent(sow_the_seeds_talent) and Enemies() > 2 } + { Talent(siphon_life_talent) and not Talent(creeping_death_talent) and not Talent(drain_soul_talent) } + False(raid_events_invulnerable_up)
}

AddFunction padding
{
 ExecuteTime(shadow_bolt_affliction) * HasAzeriteTrait(cascading_calamity_trait)
}

AddFunction use_seed
{
 Talent(sow_the_seeds_talent) and Enemies() >= 3 + False(raid_events_invulnerable_up) or Talent(siphon_life_talent) and Enemies() >= 5 + False(raid_events_invulnerable_up) or Enemies() >= 8 + False(raid_events_invulnerable_up)
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=affliction)

AddFunction AfflictionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.spenders

AddFunction AfflictionSpendersMainActions
{
 #unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*(execute_time+azerite.dreadful_calling.rank)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=soul_shard*execute_time)
 if SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } Spell(unstable_affliction)
 #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
 if { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersMainActions()

 unless { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions()
 {
  #seed_of_corruption,if=variable.use_seed
  if use_seed() Spell(seed_of_corruption)
  #unstable_affliction,if=!variable.use_seed&!prev_gcd.1.summon_darkglare&(talent.deathbolt.enabled&cooldown.deathbolt.remains<=execute_time&!azerite.cascading_calamity.enabled|(soul_shard>=5&spell_targets.seed_of_corruption_aoe<2|soul_shard>=2&spell_targets.seed_of_corruption_aoe>=2)&target.time_to_die>4+execute_time&spell_targets.seed_of_corruption_aoe=1|target.time_to_die<=8+execute_time*soul_shard)
  if not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies() < 2 or SoulShards() >= 2 and Enemies() >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } Spell(unstable_affliction)
  #unstable_affliction,if=!variable.use_seed&contagion<=cast_time+variable.padding
  if not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() Spell(unstable_affliction)
  #unstable_affliction,cycle_targets=1,if=!variable.use_seed&(!talent.deathbolt.enabled|cooldown.deathbolt.remains>time_to_shard|soul_shard>1)&(!talent.vile_taint.enabled|soul_shard>1)&contagion<=cast_time+variable.padding&(!azerite.cascading_calamity.enabled|buff.cascading_calamity.remains>time_to_shard)
  if not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } Spell(unstable_affliction)
 }
}

AddFunction AfflictionSpendersMainPostConditions
{
 { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions()
}

AddFunction AfflictionSpendersShortCdActions
{
 unless SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersShortCdActions()
 }
}

AddFunction AfflictionSpendersShortCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersShortCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies() < 2 or SoulShards() >= 2 and Enemies() >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
}

AddFunction AfflictionSpendersCdActions
{
 unless SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersCdActions()
 }
}

AddFunction AfflictionSpendersCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies() < 2 or SoulShards() >= 2 and Enemies() >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
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
 if not Talent(haunt_talent) and Enemies() < 3 Spell(shadow_bolt_affliction)
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
 Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Enemies() >= 3 and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies() < 3 and Spell(shadow_bolt_affliction)
}

AddFunction AfflictionPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction AfflictionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Enemies() >= 3 and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies() < 3 and Spell(shadow_bolt_affliction)
}

### actions.fillers

AddFunction AfflictionFillersMainActions
{
 #unstable_affliction,line_cd=15,if=cooldown.deathbolt.remains<=gcd*2&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains>20
 if TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 Spell(unstable_affliction)
 #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
 if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshMainActions()

 unless Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshMainPostConditions()
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
  if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshMainActions()

  unless Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshMainPostConditions()
  {
   #shadow_bolt,if=buff.movement.up&buff.nightfall.remains
   if Speed() > 0 and BuffPresent(nightfall_buff) Spell(shadow_bolt_affliction)
   #agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
   if Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } Spell(agony)
   #siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
   if Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } Spell(siphon_life)
   #corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
   if Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) Spell(corruption)
   #drain_life,if=(buff.inevitable_demise.stack>=40-(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>2)*20&(cooldown.deathbolt.remains>execute_time|!talent.deathbolt.enabled)&(cooldown.phantom_singularity.remains>execute_time|!talent.phantom_singularity.enabled)&(cooldown.dark_soul.remains>execute_time|!talent.dark_soul_misery.enabled)&(cooldown.vile_taint.remains>execute_time|!talent.vile_taint.enabled)&cooldown.summon_darkglare.remains>execute_time+10|buff.inevitable_demise.stack>10&target.time_to_die<=10)
   if BuffStacks(inevitable_demise_buff) >= 40 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 Spell(drain_life)
   #haunt
   Spell(haunt)
   #focused_azerite_beam
   Spell(focused_azerite_beam)
   #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight
   if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) Spell(concentrated_flame_essence)
   #drain_soul,interrupt_global=1,chain=1,interrupt=1,cycle_targets=1,if=target.time_to_die<=gcd
   if target.TimeToDie() <= GCD() Spell(drain_soul)
   #drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains
   if Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) Spell(drain_soul)
   #drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se
   if Talent(shadow_embrace_talent) and maintain_se() Spell(drain_soul)
   #drain_soul,interrupt_global=1,chain=1,interrupt=1
   Spell(drain_soul)
   #shadow_bolt,cycle_targets=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains&!action.shadow_bolt.in_flight
   if Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) Spell(shadow_bolt_affliction)
   #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se
   if Talent(shadow_embrace_talent) and maintain_se() Spell(shadow_bolt_affliction)
   #shadow_bolt
   Spell(shadow_bolt_affliction)
  }
 }
}

AddFunction AfflictionFillersMainPostConditions
{
 Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshMainPostConditions() or Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshMainPostConditions()
}

AddFunction AfflictionFillersShortCdActions
{
 unless TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshShortCdActions()

  unless Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshShortCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshShortCdActions()

   unless Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshShortCdPostConditions()
   {
    #deathbolt,if=cooldown.summon_darkglare.remains>=30+gcd|cooldown.summon_darkglare.remains>140
    if SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 Spell(deathbolt)

    unless Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 40 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 } and Spell(drain_life) or Spell(haunt) or Spell(focused_azerite_beam)
    {
     #purifying_blast
     Spell(purifying_blast)
    }
   }
  }
 }
}

AddFunction AfflictionFillersShortCdPostConditions
{
 TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction) or Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshShortCdPostConditions() or Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshShortCdPostConditions() or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 40 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 } and Spell(drain_life) or Spell(haunt) or Spell(focused_azerite_beam) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

AddFunction AfflictionFillersCdActions
{
 unless TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshCdActions()

  unless Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshCdActions()
  }
 }
}

AddFunction AfflictionFillersCdPostConditions
{
 TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction) or Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshCdPostConditions() or Talent(deathbolt_talent) and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshCdPostConditions() or { SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 } and Spell(deathbolt) or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 40 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 } and Spell(drain_life) or Spell(haunt) or Spell(focused_azerite_beam) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

### actions.dots

AddFunction AfflictionDotsMainActions
{
 #seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight
 if target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) Spell(seed_of_corruption)
 #agony,target_if=min:remains,if=talent.creeping_death.enabled&active_dot.agony<6&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } Spell(agony)
 #agony,target_if=min:remains,if=!talent.creeping_death.enabled&active_dot.agony<8&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } Spell(agony)
 #siphon_life,target_if=min:remains,if=(active_dot.siphon_life<8-talent.creeping_death.enabled-spell_targets.sow_the_seeds_aoe)&target.time_to_die>10&refreshable&(!remains&spell_targets.seed_of_corruption_aoe=1|cooldown.summon_darkglare.remains>soul_shard*action.unstable_affliction.execute_time)
 if DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies() and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies() == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } Spell(siphon_life)
 #corruption,cycle_targets=1,if=spell_targets.seed_of_corruption_aoe<3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)&target.time_to_die>10
 if Enemies() < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 Spell(corruption)
}

AddFunction AfflictionDotsMainPostConditions
{
}

AddFunction AfflictionDotsShortCdActions
{
}

AddFunction AfflictionDotsShortCdPostConditions
{
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies() and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies() == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies() < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
}

AddFunction AfflictionDotsCdActions
{
}

AddFunction AfflictionDotsCdPostConditions
{
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies() and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies() == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies() < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
}

### actions.db_refresh

AddFunction AfflictionDbrefreshMainActions
{
 #siphon_life,line_cd=15,if=(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.corruption.remains%dot.corruption.duration)&dot.siphon_life.remains<dot.siphon_life.duration*1.3
 if TimeSincePreviousSpell(siphon_life) > 15 and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 Spell(siphon_life)
 #agony,line_cd=15,if=(dot.agony.remains%dot.agony.duration)<=(dot.corruption.remains%dot.corruption.duration)&(dot.agony.remains%dot.agony.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.agony.remains<dot.agony.duration*1.3
 if TimeSincePreviousSpell(agony) > 15 and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 Spell(agony)
 #corruption,line_cd=15,if=(dot.corruption.remains%dot.corruption.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.corruption.remains%dot.corruption.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.corruption.remains<dot.corruption.duration*1.3
 if TimeSincePreviousSpell(corruption) > 15 and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 Spell(corruption)
}

AddFunction AfflictionDbrefreshMainPostConditions
{
}

AddFunction AfflictionDbrefreshShortCdActions
{
}

AddFunction AfflictionDbrefreshShortCdPostConditions
{
 TimeSincePreviousSpell(siphon_life) > 15 and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 and Spell(siphon_life) or TimeSincePreviousSpell(agony) > 15 and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 and Spell(agony) or TimeSincePreviousSpell(corruption) > 15 and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 and Spell(corruption)
}

AddFunction AfflictionDbrefreshCdActions
{
}

AddFunction AfflictionDbrefreshCdPostConditions
{
 TimeSincePreviousSpell(siphon_life) > 15 and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 and Spell(siphon_life) or TimeSincePreviousSpell(agony) > 15 and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 and Spell(agony) or TimeSincePreviousSpell(corruption) > 15 and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 and Spell(corruption)
}

### actions.cooldowns

AddFunction AfflictionCooldownsMainActions
{
}

AddFunction AfflictionCooldownsMainPostConditions
{
}

AddFunction AfflictionCooldownsShortCdActions
{
 #worldvein_resonance,if=pet.darkglare.active|cooldown.summon_darkglare.remains>30
 if DemonDuration(darkglare) > 0 or SpellCooldown(summon_darkglare) > 30 Spell(worldvein_resonance_essence)
 #ripple_in_space,if=pet.darkglare.active|cooldown.summon_darkglare.remains>30
 if DemonDuration(darkglare) > 0 or SpellCooldown(summon_darkglare) > 30 Spell(ripple_in_space_essence)
}

AddFunction AfflictionCooldownsShortCdPostConditions
{
}

AddFunction AfflictionCooldownsCdActions
{
 #potion,if=(talent.dark_soul_misery.enabled&cooldown.summon_darkglare.up&cooldown.dark_soul.up)|cooldown.summon_darkglare.up|target.time_to_die<30
 if { Talent(dark_soul_misery_talent) and not SpellCooldown(summon_darkglare) > 0 and not SpellCooldown(dark_soul_misery) > 0 or not SpellCooldown(summon_darkglare) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #use_items,if=cooldown.summon_darkglare.remains>70|time_to_die<20|((buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains)&!cooldown.summon_darkglare.remains)
 if SpellCooldown(summon_darkglare) > 70 or target.TimeToDie() < 20 or { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) > 0 } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 } and not SpellCooldown(summon_darkglare) > 0 AfflictionUseItemActions()
 #fireblood,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(fireblood)
 #blood_fury,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(blood_fury_sp)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=pet.darkglare.active|cooldown.summon_darkglare.remains>30
 if DemonDuration(darkglare) > 0 or SpellCooldown(summon_darkglare) > 30 Spell(blood_of_the_enemy)
}

AddFunction AfflictionCooldownsCdPostConditions
{
 { DemonDuration(darkglare) > 0 or SpellCooldown(summon_darkglare) > 30 } and Spell(worldvein_resonance_essence) or { DemonDuration(darkglare) > 0 or SpellCooldown(summon_darkglare) > 30 } and Spell(ripple_in_space_essence)
}

### actions.default

AddFunction AfflictionDefaultMainActions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 AfflictionCooldownsMainActions()

 unless AfflictionCooldownsMainPostConditions()
 {
  #drain_soul,interrupt_global=1,chain=1,cycle_targets=1,if=target.time_to_die<=gcd&soul_shard<5
  if target.TimeToDie() <= GCD() and SoulShards() < 5 Spell(drain_soul)
  #haunt,if=spell_targets.seed_of_corruption_aoe<=2+raid_event.invulnerable.up
  if Enemies() <= 2 + False(raid_events_invulnerable_up) Spell(haunt)
  #agony,target_if=min:dot.agony.remains,if=remains<=gcd+action.shadow_bolt.execute_time&target.time_to_die>8
  if target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 Spell(agony)
  #unstable_affliction,target_if=!contagion&target.time_to_die<=8
  if not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 Spell(unstable_affliction)
  #drain_soul,target_if=min:debuff.shadow_embrace.remains,cancel_if=ticks_remain<5,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=gcd*2
  if Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 Spell(drain_soul)
  #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=execute_time*2+travel_time&!action.shadow_bolt.in_flight
  if Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) Spell(shadow_bolt_affliction)
  #vile_taint,target_if=max:target.time_to_die,if=time>15&target.time_to_die>=10
  if TimeInCombat() > 15 and target.TimeToDie() >= 10 Spell(vile_taint)
  #unstable_affliction,target_if=min:contagion,if=!variable.use_seed&soul_shard=5
  if not use_seed() and SoulShards() == 5 Spell(unstable_affliction)
  #seed_of_corruption,if=variable.use_seed&soul_shard=5
  if use_seed() and SoulShards() == 5 Spell(seed_of_corruption)
  #call_action_list,name=dots
  AfflictionDotsMainActions()

  unless AfflictionDotsMainPostConditions()
  {
   #vile_taint,if=time<15
   if TimeInCombat() < 15 Spell(vile_taint)
   #call_action_list,name=spenders
   AfflictionSpendersMainActions()

   unless AfflictionSpendersMainPostConditions()
   {
    #call_action_list,name=fillers
    AfflictionFillersMainActions()
   }
  }
 }
}

AddFunction AfflictionDefaultMainPostConditions
{
 AfflictionCooldownsMainPostConditions() or AfflictionDotsMainPostConditions() or AfflictionSpendersMainPostConditions() or AfflictionFillersMainPostConditions()
}

AddFunction AfflictionDefaultShortCdActions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 AfflictionCooldownsShortCdActions()

 unless AfflictionCooldownsShortCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies() <= 2 + False(raid_events_invulnerable_up) and Spell(haunt)
 {
  #deathbolt,if=cooldown.summon_darkglare.remains&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(!essence.vision_of_perfection.minor|!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>30)
  if SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } Spell(deathbolt)
  #the_unbound_force,if=buff.reckless_force.remains
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)

  unless target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction)
  {
   #phantom_singularity,target_if=max:target.time_to_die,if=time>35&target.time_to_die>16*spell_haste&(!essence.vision_of_perfection.minor|!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>45|cooldown.summon_darkglare.remains<15*spell_haste)
   if TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } } Spell(phantom_singularity)

   unless TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    AfflictionDotsShortCdActions()

    unless AfflictionDotsShortCdPostConditions()
    {
     #phantom_singularity,if=time<=35
     if TimeInCombat() <= 35 Spell(phantom_singularity)

     unless TimeInCombat() < 15 and Spell(vile_taint)
     {
      #call_action_list,name=spenders
      AfflictionSpendersShortCdActions()

      unless AfflictionSpendersShortCdPostConditions()
      {
       #call_action_list,name=fillers
       AfflictionFillersShortCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction AfflictionDefaultShortCdPostConditions
{
 AfflictionCooldownsShortCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies() <= 2 + False(raid_events_invulnerable_up) and Spell(haunt) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption) or AfflictionDotsShortCdPostConditions() or TimeInCombat() < 15 and Spell(vile_taint) or AfflictionSpendersShortCdPostConditions() or AfflictionFillersShortCdPostConditions()
}

AddFunction AfflictionDefaultCdActions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 AfflictionCooldownsCdActions()

 unless AfflictionCooldownsCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies() <= 2 + False(raid_events_invulnerable_up) and Spell(haunt)
 {
  #summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|dot.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up)
  if target.DebuffPresent(agony_debuff) and target.DebuffPresent(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or target.DebuffRemaining(phantom_singularity) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 or Enemies() > 1 + False(raid_events_invulnerable_up) } Spell(summon_darkglare)

  unless SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } and Spell(deathbolt)
  {
   #guardian_of_azeroth,if=pet.darkglare.active
   if DemonDuration(darkglare) > 0 Spell(guardian_of_azeroth)

   unless BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } } and Spell(phantom_singularity) or TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    AfflictionDotsCdActions()

    unless AfflictionDotsCdPostConditions() or TimeInCombat() <= 35 and Spell(phantom_singularity) or TimeInCombat() < 15 and Spell(vile_taint)
    {
     #dark_soul,if=cooldown.summon_darkglare.remains<10&dot.phantom_singularity.remains|target.time_to_die<20+gcd|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up
     if SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(phantom_singularity) or target.TimeToDie() < 20 + GCD() or Enemies() > 1 + False(raid_events_invulnerable_up) Spell(dark_soul_misery)
     #berserking
     Spell(berserking)
     #call_action_list,name=spenders
     AfflictionSpendersCdActions()

     unless AfflictionSpendersCdPostConditions()
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
 AfflictionCooldownsCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies() <= 2 + False(raid_events_invulnerable_up) and Spell(haunt) or SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } and Spell(deathbolt) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) or not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } } and Spell(phantom_singularity) or TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption) or AfflictionDotsCdPostConditions() or TimeInCombat() <= 35 and Spell(phantom_singularity) or TimeInCombat() < 15 and Spell(vile_taint) or AfflictionSpendersCdPostConditions() or AfflictionFillersCdPostConditions()
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
# berserking
# blood_fury_sp
# blood_of_the_enemy
# cascading_calamity_buff
# cascading_calamity_trait
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# corruption
# corruption_debuff
# creeping_death_talent
# dark_soul_misery
# dark_soul_misery_talent
# deathbolt
# deathbolt_talent
# drain_life
# drain_soul
# drain_soul_talent
# dreadful_calling_trait
# fireblood
# focused_azerite_beam
# grimoire_of_sacrifice
# grimoire_of_sacrifice_talent
# guardian_of_azeroth
# haunt
# haunt_talent
# inevitable_demise_buff
# item_unbridled_fury
# memory_of_lucid_dreams_essence
# nightfall_buff
# pandemic_invocation_trait
# phantom_singularity
# phantom_singularity_talent
# purifying_blast
# reckless_force_buff
# ripple_in_space_essence
# seed_of_corruption
# seed_of_corruption_debuff
# shadow_bolt_affliction
# shadow_embrace_debuff
# shadow_embrace_talent
# siphon_life
# siphon_life_debuff
# siphon_life_talent
# sow_the_seeds_talent
# summon_darkglare
# summon_imp
# the_unbound_force
# unstable_affliction
# vile_taint
# vile_taint_talent
# vision_of_perfection_essence_id
# worldvein_resonance_essence
# writhe_in_agony_talent
]]
    OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
end
do
    local name = "sc_pr_warlock_demonology"
    local desc = "[8.2] Simulationcraft: PR_Warlock_Demonology"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Demonology".
#	class=warlock
#	spec=demonology
#	talents=2303031
#	pet=felguard

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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction DemonologyPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_felguard) or Talent(inner_demons_talent) and Spell(inner_demons) or Spell(demonbolt)
}

### actions.nether_portal_building

AddFunction DemonologyNetherportalbuildingMainActions
{
 #call_dreadstalkers
 Spell(call_dreadstalkers)
 #hand_of_guldan,if=cooldown.call_dreadstalkers.remains>18&soul_shard>=3
 if SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 Spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=5
 if SoulShards() >= 5 Spell(hand_of_guldan)
 #call_action_list,name=build_a_shard
 DemonologyBuildashardMainActions()
}

AddFunction DemonologyNetherportalbuildingMainPostConditions
{
 DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyNetherportalbuildingShortCdActions
{
 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan)
 {
  #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&soul_shard>=3
  if Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 Spell(power_siphon)

  unless SoulShards() >= 5 and Spell(hand_of_guldan)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildashardShortCdActions()
  }
 }
}

AddFunction DemonologyNetherportalbuildingShortCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyNetherportalbuildingCdActions
{
 #nether_portal,if=soul_shard>=5&(!talent.power_siphon.enabled|buff.demonic_core.up)
 if SoulShards() >= 5 and { not Talent(power_siphon_talent) or BuffPresent(demonic_core_buff) } Spell(nether_portal)

 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildashardCdActions()
 }
}

AddFunction DemonologyNetherportalbuildingCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildashardCdPostConditions()
}

### actions.nether_portal_active

AddFunction DemonologyNetherportalactiveMainActions
{
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
 #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
 if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildashardMainActions()

 unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardMainPostConditions()
 {
  #hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(165+action.hand_of_guldan.cast_time)
  if SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) Spell(hand_of_guldan)
  #demonbolt,if=buff.demonic_core.up&soul_shard<=3
  if BuffPresent(demonic_core_buff) and SoulShards() <= 3 Spell(demonbolt)
  #call_action_list,name=build_a_shard
  DemonologyBuildashardMainActions()
 }
}

AddFunction DemonologyNetherportalactiveMainPostConditions
{
 SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardMainPostConditions() or DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyNetherportalactiveShortCdActions
{
 #bilescourge_bombers
 Spell(bilescourge_bombers)
 #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
 if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

 unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildashardShortCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan)
  {
   #summon_demonic_tyrant,if=buff.nether_portal.remains<5&soul_shard=0
   if BuffRemaining(nether_portal_buff) < 5 and SoulShards() == 0 Spell(summon_demonic_tyrant)
   #summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+0.5
   if BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 0.5 Spell(summon_demonic_tyrant)

   unless BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildashardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyNetherportalactiveShortCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyNetherportalactiveCdActions
{
 unless Spell(bilescourge_bombers)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

  unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
  {
   #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
   if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildashardCdActions()

   unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 5 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 0.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildashardCdActions()
   }
  }
 }
}

AddFunction DemonologyNetherportalactiveCdPostConditions
{
 Spell(bilescourge_bombers) or { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 5 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 0.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt) or DemonologyBuildashardCdPostConditions()
}

### actions.nether_portal

AddFunction DemonologyNetherportalMainActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingMainActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingMainPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherportalactiveMainActions()
 }
}

AddFunction DemonologyNetherportalMainPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingMainPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherportalactiveMainPostConditions()
}

AddFunction DemonologyNetherportalShortCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingShortCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingShortCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherportalactiveShortCdActions()
 }
}

AddFunction DemonologyNetherportalShortCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingShortCdPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherportalactiveShortCdPostConditions()
}

AddFunction DemonologyNetherportalCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherportalactiveCdActions()
 }
}

AddFunction DemonologyNetherportalCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingCdPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherportalactiveCdPostConditions()
}

### actions.implosion

AddFunction DemonologyImplosionMainActions
{
 #implosion,if=(buff.wild_imps.stack>=6&(soul_shard<3|prev_gcd.1.call_dreadstalkers|buff.wild_imps.stack>=9|prev_gcd.1.bilescourge_bombers|(!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan))&!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&buff.demonic_power.down)|(time_to_die<3&buff.wild_imps.stack>0)|(prev_gcd.2.call_dreadstalkers&buff.wild_imps.stack>2&!talent.demonic_calling.enabled)
 if Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) Spell(implosion)
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard>=5
 if SoulShards() >= 5 Spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&(((prev_gcd.2.hand_of_guldan|buff.wild_imps.stack>=3)&buff.wild_imps.stack<9)|cooldown.summon_demonic_tyrant.remains<=gcd*2|buff.demonic_power.remains>gcd*2)
 if SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } Spell(hand_of_guldan)
 #demonbolt,if=prev_gcd.1.hand_of_guldan&soul_shard>=1&(buff.wild_imps.stack<=3|prev_gcd.3.hand_of_guldan)&soul_shard<4&buff.demonic_core.up
 if PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) Spell(demonbolt)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&spell_targets.implosion<5
 if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 Spell(concentrated_flame_essence)
 #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
 if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.up&(buff.demonic_core.stack>=3|buff.demonic_core.remains<=gcd*5.7)
 if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } Spell(demonbolt)
 #doom,cycle_targets=1,max_cycle_targets=7,if=refreshable
 if DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) Spell(doom)
 #call_action_list,name=build_a_shard
 DemonologyBuildashardMainActions()
}

AddFunction DemonologyImplosionMainPostConditions
{
 DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyImplosionShortCdActions
{
 unless { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #summon_demonic_tyrant
  Spell(summon_demonic_tyrant)

  unless SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
  {
   #summon_vilefiend,if=(cooldown.summon_demonic_tyrant.remains>40&spell_targets.implosion<=2)|cooldown.summon_demonic_tyrant.remains<12
   if SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)
   #bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
   if SpellCooldown(summon_demonic_tyrant) > 9 Spell(bilescourge_bombers)

   unless Spell(focused_azerite_beam)
   {
    #purifying_blast
    Spell(purifying_blast)

    unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
    {
     #call_action_list,name=build_a_shard
     DemonologyBuildashardShortCdActions()
    }
   }
  }
 }
}

AddFunction DemonologyImplosionShortCdPostConditions
{
 { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or Spell(focused_azerite_beam) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyImplosionCdActions
{
 unless { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

  unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Spell(summon_demonic_tyrant) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or Spell(focused_azerite_beam) or Spell(purifying_blast)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)

   unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildashardCdActions()
   }
  }
 }
}

AddFunction DemonologyImplosionCdPostConditions
{
 { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Spell(summon_demonic_tyrant) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or Spell(focused_azerite_beam) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildashardCdPostConditions()
}

### actions.dcon_opener

AddFunction DemonologyDconopenerMainActions
{
 #hand_of_guldan,line_cd=30,if=azerite.explosive_potential.enabled
 if TimeSincePreviousSpell(hand_of_guldan) > 30 and HasAzeriteTrait(explosive_potential_trait) Spell(hand_of_guldan)
 #implosion,if=azerite.explosive_potential.enabled&buff.wild_imps.stack>2&buff.explosive_potential.down
 if HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) Spell(implosion)
 #doom,line_cd=30
 if TimeSincePreviousSpell(doom) > 30 Spell(doom)
 #hand_of_guldan,if=prev_gcd.1.hand_of_guldan&soul_shard>0&prev_gcd.2.soul_strike
 if PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) Spell(hand_of_guldan)
 #soul_strike,line_cd=30,if=!buff.bloodlust.remains|time>5&prev_gcd.1.hand_of_guldan
 if TimeSincePreviousSpell(soul_strike) > 30 and { not BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } Spell(soul_strike)
 #call_dreadstalkers,if=soul_shard=5
 if SoulShards() == 5 Spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard=5
 if SoulShards() == 5 Spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&prev_gcd.2.hand_of_guldan&time>5&(prev_gcd.1.soul_strike|!talent.soul_strike.enabled&prev_gcd.1.shadow_bolt)
 if SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } Spell(hand_of_guldan)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.remains
 if SoulShards() <= 3 and BuffPresent(demonic_core_buff) Spell(demonbolt)
 #call_action_list,name=build_a_shard
 DemonologyBuildashardMainActions()
}

AddFunction DemonologyDconopenerMainPostConditions
{
 DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyDconopenerShortCdActions
{
 unless TimeSincePreviousSpell(hand_of_guldan) > 30 and HasAzeriteTrait(explosive_potential_trait) and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan)
 {
  #demonic_strength,if=prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&(buff.wild_imps.stack>1&action.hand_of_guldan.in_flight)
  if PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) Spell(demonic_strength)
  #bilescourge_bombers
  Spell(bilescourge_bombers)

  unless TimeSincePreviousSpell(soul_strike) > 30 and { not BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and Spell(soul_strike)
  {
   #summon_vilefiend,if=soul_shard=5
   if SoulShards() == 5 Spell(summon_vilefiend)

   unless SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan)
   {
    #summon_demonic_tyrant,if=prev_gcd.1.demonic_strength|prev_gcd.1.hand_of_guldan&prev_gcd.2.hand_of_guldan|!talent.demonic_strength.enabled&buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6
    if PreviousGCDSpell(demonic_strength) or PreviousGCDSpell(hand_of_guldan) and PreviousGCDSpell(hand_of_guldan count=2) or not Talent(demonic_strength_talent) and Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 Spell(summon_demonic_tyrant)

    unless SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
    {
     #call_action_list,name=build_a_shard
     DemonologyBuildashardShortCdActions()
    }
   }
  }
 }
}

AddFunction DemonologyDconopenerShortCdPostConditions
{
 TimeSincePreviousSpell(hand_of_guldan) > 30 and HasAzeriteTrait(explosive_potential_trait) and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or TimeSincePreviousSpell(soul_strike) > 30 and { not BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and Spell(soul_strike) or SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyDconopenerCdActions
{
 unless TimeSincePreviousSpell(hand_of_guldan) > 30 and HasAzeriteTrait(explosive_potential_trait) and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) and Spell(demonic_strength) or Spell(bilescourge_bombers) or TimeSincePreviousSpell(soul_strike) > 30 and { not BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and Spell(soul_strike) or SoulShards() == 5 and Spell(summon_vilefiend)
 {
  #grimoire_felguard,if=soul_shard=5
  if SoulShards() == 5 Spell(grimoire_felguard)

  unless SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or { PreviousGCDSpell(demonic_strength) or PreviousGCDSpell(hand_of_guldan) and PreviousGCDSpell(hand_of_guldan count=2) or not Talent(demonic_strength_talent) and Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 } and Spell(summon_demonic_tyrant) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildashardCdActions()
  }
 }
}

AddFunction DemonologyDconopenerCdPostConditions
{
 TimeSincePreviousSpell(hand_of_guldan) > 30 and HasAzeriteTrait(explosive_potential_trait) and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) and Spell(demonic_strength) or Spell(bilescourge_bombers) or TimeSincePreviousSpell(soul_strike) > 30 and { not BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and Spell(soul_strike) or SoulShards() == 5 and Spell(summon_vilefiend) or SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or { PreviousGCDSpell(demonic_strength) or PreviousGCDSpell(hand_of_guldan) and PreviousGCDSpell(hand_of_guldan count=2) or not Talent(demonic_strength_talent) and Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 } and Spell(summon_demonic_tyrant) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildashardCdPostConditions()
}

### actions.build_a_shard

AddFunction DemonologyBuildashardMainActions
{
 #soul_strike,if=!talent.demonic_consumption.enabled|time>15|prev_gcd.1.hand_of_guldan&!buff.bloodlust.remains
 if not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(burst_haste_buff any=1) Spell(soul_strike)
 #shadow_bolt
 Spell(shadow_bolt)
}

AddFunction DemonologyBuildashardMainPostConditions
{
}

AddFunction DemonologyBuildashardShortCdActions
{
}

AddFunction DemonologyBuildashardShortCdPostConditions
{
 { not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(burst_haste_buff any=1) } and Spell(soul_strike) or Spell(shadow_bolt)
}

AddFunction DemonologyBuildashardCdActions
{
 #memory_of_lucid_dreams,if=soul_shard<2
 if SoulShards() < 2 Spell(memory_of_lucid_dreams_essence)
}

AddFunction DemonologyBuildashardCdPostConditions
{
 { not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(burst_haste_buff any=1) } and Spell(soul_strike) or Spell(shadow_bolt)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
 #call_action_list,name=dcon_opener,if=talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconopenerMainActions()

 unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerMainPostConditions()
 {
  #hand_of_guldan,if=azerite.explosive_potential.rank&time<5&soul_shard>2&buff.explosive_potential.down&buff.wild_imps.stack<3&!prev_gcd.1.hand_of_guldan&&!prev_gcd.2.hand_of_guldan
  if AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) Spell(hand_of_guldan)
  #demonbolt,if=soul_shard<=3&buff.demonic_core.up&buff.demonic_core.stack=4
  if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 Spell(demonbolt)
  #implosion,if=azerite.explosive_potential.rank&buff.wild_imps.stack>2&buff.explosive_potential.remains<action.shadow_bolt.execute_time&(!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>12)
  if AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } Spell(implosion)
  #doom,if=!ticking&time_to_die>30&spell_targets.implosion<2
  if not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 Spell(doom)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherportalMainActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalMainPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionMainActions()

   unless Enemies() > 1 and DemonologyImplosionMainPostConditions()
   {
    #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
    if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
    #hand_of_guldan,if=(azerite.baleful_invocation.enabled|talent.demonic_consumption.enabled)&prev_gcd.1.hand_of_guldan&cooldown.summon_demonic_tyrant.remains<2
    if { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 Spell(hand_of_guldan)
    #doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
    if Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 Spell(doom)
    #hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(cooldown.summon_demonic_tyrant.remains>20|(cooldown.summon_demonic_tyrant.remains<gcd*2&talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains<gcd*4&!talent.demonic_consumption.enabled))&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
    if SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } Spell(hand_of_guldan)
    #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
    if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
    #demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<6|cooldown.summon_demonic_tyrant.remains>22&!azerite.shadows_bite.enabled)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25|buff.shadows_bite.remains)
    if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite) } Spell(demonbolt)
    #focused_azerite_beam,if=!pet.demonic_tyrant.active
    if not DemonDuration(demonic_tyrant) > 0 Spell(focused_azerite_beam)
    #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&!pet.demonic_tyrant.active
    if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 Spell(concentrated_flame_essence)
    #call_action_list,name=build_a_shard
    DemonologyBuildashardMainActions()
   }
  }
 }
}

AddFunction DemonologyDefaultMainPostConditions
{
 Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerMainPostConditions() or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalMainPostConditions() or Enemies() > 1 and DemonologyImplosionMainPostConditions() or DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyDefaultShortCdActions
{
 #worldvein_resonance,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(worldvein_resonance_essence)
 #ripple_in_space,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(ripple_in_space_essence)
 #call_action_list,name=dcon_opener,if=talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconopenerShortCdActions()

 unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerShortCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom)
 {
  #bilescourge_bombers,if=azerite.explosive_potential.rank>0&time<10&spell_targets.implosion<2&buff.dreadstalkers.remains&talent.nether_portal.enabled
  if AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies() < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) Spell(bilescourge_bombers)
  #demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
  if Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies() < 2 Spell(demonic_strength)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherportalShortCdActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalShortCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionShortCdActions()

   unless Enemies() > 1 and DemonologyImplosionShortCdPostConditions()
   {
    #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

    unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
    {
     #the_unbound_force,if=buff.reckless_force.react
     if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
     #bilescourge_bombers
     Spell(bilescourge_bombers)

     unless { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan)
     {
      #summon_demonic_tyrant,if=soul_shard<3&(!talent.demonic_consumption.enabled|buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6&time_to_imps.all.remains<cast_time)|target.time_to_die<20
      if SoulShards() < 3 and { not Talent(demonic_consumption_talent) or Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 and 0 < CastTime(summon_demonic_tyrant) } or target.TimeToDie() < 20 Spell(summon_demonic_tyrant)
      #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
      if Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies() < 2 Spell(power_siphon)

      unless Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite) } and Spell(demonbolt) or not DemonDuration(demonic_tyrant) > 0 and Spell(focused_azerite_beam)
      {
       #purifying_blast
       Spell(purifying_blast)

       unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence)
       {
        #call_action_list,name=build_a_shard
        DemonologyBuildashardShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultShortCdPostConditions
{
 Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerShortCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalShortCdPostConditions() or Enemies() > 1 and DemonologyImplosionShortCdPostConditions() or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite) } and Spell(demonbolt) or not DemonDuration(demonic_tyrant) > 0 and Spell(focused_azerite_beam) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyDefaultCdActions
{
 #potion,if=pet.demonic_tyrant.active&(!talent.nether_portal.enabled|cooldown.nether_portal.remains>160)|target.time_to_die<30
 if { DemonDuration(demonic_tyrant) > 0 and { not Talent(nether_portal_talent) or SpellCooldown(nether_portal) > 160 } or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #use_items,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 DemonologyUseItemActions()
 #berserking,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(berserking)
 #blood_fury,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(blood_fury_sp)
 #fireblood,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(fireblood)

 unless { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(worldvein_resonance_essence) or { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(ripple_in_space_essence)
 {
  #call_action_list,name=dcon_opener,if=talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
  if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconopenerCdActions()

  unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies() < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) and Spell(bilescourge_bombers) or { Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies() < 2 } and Spell(demonic_strength)
  {
   #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
   if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherportalCdActions()

   unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalCdPostConditions()
   {
    #call_action_list,name=implosion,if=spell_targets.implosion>1
    if Enemies() > 1 DemonologyImplosionCdActions()

    unless Enemies() > 1 and DemonologyImplosionCdPostConditions()
    {
     #guardian_of_azeroth,if=pet.demonic_tyrant.active|target.time_to_die<=30
     if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 30 Spell(guardian_of_azeroth)
     #grimoire_felguard,if=(target.time_to_die>120|target.time_to_die<cooldown.summon_demonic_tyrant.remains+15|cooldown.summon_demonic_tyrant.remains<13)
     if target.TimeToDie() > 120 or target.TimeToDie() < SpellCooldown(summon_demonic_tyrant) + 15 or SpellCooldown(summon_demonic_tyrant) < 13 Spell(grimoire_felguard)

     unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(bilescourge_bombers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or { SoulShards() < 3 and { not Talent(demonic_consumption_talent) or Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 and 0 < CastTime(summon_demonic_tyrant) } or target.TimeToDie() < 20 } and Spell(summon_demonic_tyrant) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite) } and Spell(demonbolt) or not DemonDuration(demonic_tyrant) > 0 and Spell(focused_azerite_beam) or Spell(purifying_blast)
     {
      #blood_of_the_enemy
      Spell(blood_of_the_enemy)

      unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence)
      {
       #call_action_list,name=build_a_shard
       DemonologyBuildashardCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultCdPostConditions
{
 { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(worldvein_resonance_essence) or { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(ripple_in_space_essence) or Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconopenerCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies() < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) and Spell(bilescourge_bombers) or { Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies() < 2 } and Spell(demonic_strength) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalCdPostConditions() or Enemies() > 1 and DemonologyImplosionCdPostConditions() or { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(bilescourge_bombers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or { SoulShards() < 3 and { not Talent(demonic_consumption_talent) or Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 and 0 < CastTime(summon_demonic_tyrant) } or target.TimeToDie() < 20 } and Spell(summon_demonic_tyrant) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite) } and Spell(demonbolt) or not DemonDuration(demonic_tyrant) > 0 and Spell(focused_azerite_beam) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence) or DemonologyBuildashardCdPostConditions()
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
# baleful_invocation_trait
# berserking
# bilescourge_bombers
# bilescourge_bombers_talent
# blood_fury_sp
# blood_of_the_enemy
# call_dreadstalkers
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# demonbolt
# demonic_calling_buff
# demonic_calling_talent
# demonic_consumption_talent
# demonic_core_buff
# demonic_power
# demonic_strength
# demonic_strength_talent
# doom
# doom_debuff
# doom_talent
# dreadstalker
# explosive_potential
# explosive_potential_trait
# fireblood
# focused_azerite_beam
# grimoire_felguard
# guardian_of_azeroth
# hand_of_guldan
# implosion
# inner_demons
# inner_demons_talent
# item_unbridled_fury
# memory_of_lucid_dreams_essence
# nether_portal
# nether_portal_buff
# nether_portal_talent
# power_siphon
# power_siphon_talent
# purifying_blast
# reckless_force_buff
# ripple_in_space_essence
# shadow_bolt
# shadows_bite
# shadows_bite_trait
# soul_strike
# soul_strike_talent
# summon_demonic_tyrant
# summon_felguard
# summon_vilefiend
# summon_vilefiend_talent
# the_unbound_force
# wild_imp
# wild_imp_inner_demons
# wilfreds_sigil_of_superior_summoning_item
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
end
do
    local name = "sc_pr_warlock_destruction"
    local desc = "[8.2] Simulationcraft: PR_Warlock_Destruction"
    local code = [[
# Based on SimulationCraft profile "PR_Warlock_Destruction".
#	class=warlock
#	spec=destruction
#	talents=1203023
#	pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)


AddFunction pool_soul_shards
{
 Enemies() > 1 and SpellCooldown(havoc) <= 10 or SpellCooldown(summon_infernal) <= 20 and { Talent(grimoire_of_supremacy_talent) or Talent(dark_soul_instability_talent) and SpellCooldown(dark_soul_instability) <= 20 } or Talent(dark_soul_instability_talent) and SpellCooldown(dark_soul_instability) <= 20 and { SpellCooldown(summon_infernal) > target.TimeToDie() or SpellCooldown(summon_infernal) + SpellCooldownDuration(summon_infernal) > target.TimeToDie() }
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=destruction)

AddFunction DestructionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
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
 Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Spell(soul_fire) or not Talent(soul_fire_talent) and Spell(incinerate)
}

AddFunction DestructionPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction DestructionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Spell(soul_fire) or not Talent(soul_fire_talent) and Spell(incinerate)
}

### actions.havoc

AddFunction DestructionHavocMainActions
{
 #conflagrate,if=buff.backdraft.down&soul_shard>=1&soul_shard<=4
 if BuffExpires(backdraft_buff) and SoulShards() >= 1 and SoulShards() <= 4 Spell(conflagrate)
 #immolate,if=talent.internal_combustion.enabled&remains<duration*0.5|!talent.internal_combustion.enabled&refreshable
 if Talent(internal_combustion_talent) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 or not Talent(internal_combustion_talent) and target.Refreshable(immolate_debuff) Spell(immolate)
 #chaos_bolt,if=cast_time<havoc_remains
 if CastTime(chaos_bolt) < DebuffRemainingOnAny(havoc_debuff) Spell(chaos_bolt)
 #soul_fire
 Spell(soul_fire)
 #shadowburn,if=active_enemies<3|!talent.fire_and_brimstone.enabled
 if Enemies() < 3 or not Talent(fire_and_brimstone_talent) Spell(shadowburn)
 #incinerate,if=cast_time<havoc_remains
 if CastTime(incinerate) < DebuffRemainingOnAny(havoc_debuff) Spell(incinerate)
}

AddFunction DestructionHavocMainPostConditions
{
}

AddFunction DestructionHavocShortCdActions
{
}

AddFunction DestructionHavocShortCdPostConditions
{
 BuffExpires(backdraft_buff) and SoulShards() >= 1 and SoulShards() <= 4 and Spell(conflagrate) or { Talent(internal_combustion_talent) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 or not Talent(internal_combustion_talent) and target.Refreshable(immolate_debuff) } and Spell(immolate) or CastTime(chaos_bolt) < DebuffRemainingOnAny(havoc_debuff) and Spell(chaos_bolt) or Spell(soul_fire) or { Enemies() < 3 or not Talent(fire_and_brimstone_talent) } and Spell(shadowburn) or CastTime(incinerate) < DebuffRemainingOnAny(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionHavocCdActions
{
}

AddFunction DestructionHavocCdPostConditions
{
 BuffExpires(backdraft_buff) and SoulShards() >= 1 and SoulShards() <= 4 and Spell(conflagrate) or { Talent(internal_combustion_talent) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 or not Talent(internal_combustion_talent) and target.Refreshable(immolate_debuff) } and Spell(immolate) or CastTime(chaos_bolt) < DebuffRemainingOnAny(havoc_debuff) and Spell(chaos_bolt) or Spell(soul_fire) or { Enemies() < 3 or not Talent(fire_and_brimstone_talent) } and Spell(shadowburn) or CastTime(incinerate) < DebuffRemainingOnAny(havoc_debuff) and Spell(incinerate)
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
 #worldvein_resonance
 Spell(worldvein_resonance_essence)
 #ripple_in_space
 Spell(ripple_in_space_essence)
}

AddFunction DestructionCdsShortCdPostConditions
{
}

AddFunction DestructionCdsCdActions
{
 #summon_infernal,if=cooldown.dark_soul_instability.ready|cooldown.memory_of_lucid_dreams.ready|(!talent.dark_soul_instability.enabled&!essence.memory_of_lucid_dreams.major)|cooldown.dark_soul_instability.remains<=10|cooldown.memory_of_lucid_dreams.remains<=10
 if SpellCooldown(dark_soul_instability) == 0 or SpellCooldown(memory_of_lucid_dreams_essence) == 0 or not Talent(dark_soul_instability_talent) and not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or SpellCooldown(dark_soul_instability) <= 10 or SpellCooldown(memory_of_lucid_dreams_essence) <= 10 Spell(summon_infernal)
 #guardian_of_azeroth,if=pet.infernal.active
 if DemonDuration(infernal) > 0 Spell(guardian_of_azeroth)
 #dark_soul_instability,if=pet.infernal.active&pet.infernal.remains<=20
 if DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 20 Spell(dark_soul_instability)
 #memory_of_lucid_dreams,if=pet.infernal.active&pet.infernal.remains<=20
 if DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 20 Spell(memory_of_lucid_dreams_essence)
 #summon_infernal,if=target.time_to_die>cooldown.summon_infernal.duration+30
 if target.TimeToDie() > SpellCooldownDuration(summon_infernal) + 30 Spell(summon_infernal)
 #guardian_of_azeroth,if=time>30&target.time_to_die>cooldown.guardian_of_azeroth.duration+30
 if TimeInCombat() > 30 and target.TimeToDie() > SpellCooldownDuration(guardian_of_azeroth) + 30 Spell(guardian_of_azeroth)
 #summon_infernal,if=talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains>target.time_to_die
 if Talent(dark_soul_instability_talent) and SpellCooldown(dark_soul_instability) > target.TimeToDie() Spell(summon_infernal)
 #guardian_of_azeroth,if=cooldown.summon_infernal.remains>target.time_to_die
 if SpellCooldown(summon_infernal) > target.TimeToDie() Spell(guardian_of_azeroth)
 #dark_soul_instability,if=cooldown.summon_infernal.remains>target.time_to_die
 if SpellCooldown(summon_infernal) > target.TimeToDie() Spell(dark_soul_instability)
 #memory_of_lucid_dreams,if=cooldown.summon_infernal.remains>target.time_to_die
 if SpellCooldown(summon_infernal) > target.TimeToDie() Spell(memory_of_lucid_dreams_essence)
 #summon_infernal,if=target.time_to_die<30
 if target.TimeToDie() < 30 Spell(summon_infernal)
 #guardian_of_azeroth,if=target.time_to_die<30
 if target.TimeToDie() < 30 Spell(guardian_of_azeroth)
 #dark_soul_instability,if=target.time_to_die<20
 if target.TimeToDie() < 20 Spell(dark_soul_instability)
 #memory_of_lucid_dreams,if=target.time_to_die<20
 if target.TimeToDie() < 20 Spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy
 Spell(blood_of_the_enemy)

 unless Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence)
 {
  #potion,if=pet.infernal.active|target.time_to_die<30
  if { DemonDuration(infernal) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
  #berserking,if=pet.infernal.active|buff.memory_of_lucid_dreams.remains|buff.dark_soul_instability.remains|target.time_to_die<30
  if DemonDuration(infernal) > 0 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 30 Spell(berserking)
  #blood_fury,if=pet.infernal.active|buff.memory_of_lucid_dreams.remains|buff.dark_soul_instability.remains|target.time_to_die<30
  if DemonDuration(infernal) > 0 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 30 Spell(blood_fury_sp)
  #fireblood,if=pet.infernal.active|buff.memory_of_lucid_dreams.remains|buff.dark_soul_instability.remains|target.time_to_die<30
  if DemonDuration(infernal) > 0 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 30 Spell(fireblood)
  #use_items,if=pet.infernal.active|buff.memory_of_lucid_dreams.remains|buff.dark_soul_instability.remains|target.time_to_die<30
  if DemonDuration(infernal) > 0 or BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(dark_soul_instability_buff) or target.TimeToDie() < 30 DestructionUseItemActions()
 }
}

AddFunction DestructionCdsCdPostConditions
{
 Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence)
}

### actions.aoe

AddFunction DestructionAoeMainActions
{
 #rain_of_fire,if=pet.infernal.active&(buff.crashing_chaos.down|!talent.grimoire_of_supremacy.enabled)&(!cooldown.havoc.ready|active_enemies>3)
 if DemonDuration(infernal) > 0 and { BuffExpires(crashing_chaos_buff) or not Talent(grimoire_of_supremacy_talent) } and { not SpellCooldown(havoc) == 0 or Enemies() > 3 } Spell(rain_of_fire)
 #channel_demonfire,if=dot.immolate.remains>cast_time
 if target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) Spell(channel_demonfire)
 #immolate,cycle_targets=1,if=remains<5&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
 if target.DebuffRemaining(immolate_debuff) < 5 and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } Spell(immolate)
 #call_action_list,name=cds
 DestructionCdsMainActions()

 unless DestructionCdsMainPostConditions()
 {
  #chaos_bolt,if=talent.grimoire_of_supremacy.enabled&pet.infernal.active&(havoc_active|talent.cataclysm.enabled|talent.inferno.enabled&active_enemies<4)
  if Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and { DebuffCountOnAny(havoc_debuff) > 0 or Talent(cataclysm_talent) or Talent(inferno_talent) and Enemies() < 4 } Spell(chaos_bolt)
  #rain_of_fire
  Spell(rain_of_fire)
  #focused_azerite_beam
  Spell(focused_azerite_beam)
  #incinerate,if=talent.fire_and_brimstone.enabled&buff.backdraft.up&soul_shard<5-0.2*active_enemies
  if Talent(fire_and_brimstone_talent) and BuffPresent(backdraft_buff) and SoulShards() < 5 - 0.2 * Enemies() Spell(incinerate)
  #soul_fire
  Spell(soul_fire)
  #conflagrate,if=buff.backdraft.down
  if BuffExpires(backdraft_buff) Spell(conflagrate)
  #shadowburn,if=!talent.fire_and_brimstone.enabled
  if not Talent(fire_and_brimstone_talent) Spell(shadowburn)
  #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&active_enemies<5
  if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 Spell(concentrated_flame_essence)
  #incinerate
  Spell(incinerate)
 }
}

AddFunction DestructionAoeMainPostConditions
{
 DestructionCdsMainPostConditions()
}

AddFunction DestructionAoeShortCdActions
{
 unless DemonDuration(infernal) > 0 and { BuffExpires(crashing_chaos_buff) or not Talent(grimoire_of_supremacy_talent) } and { not SpellCooldown(havoc) == 0 or Enemies() > 3 } and Spell(rain_of_fire) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and Spell(channel_demonfire) or target.DebuffRemaining(immolate_debuff) < 5 and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate)
 {
  #call_action_list,name=cds
  DestructionCdsShortCdActions()

  unless DestructionCdsShortCdPostConditions()
  {
   #havoc,cycle_targets=1,if=!(target=self.target)&active_enemies<4
   if not False(target_is_target) and Enemies() < 4 and Enemies() > 1 Spell(havoc)

   unless Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and { DebuffCountOnAny(havoc_debuff) > 0 or Talent(cataclysm_talent) or Talent(inferno_talent) and Enemies() < 4 } and Spell(chaos_bolt) or Spell(rain_of_fire) or Spell(focused_azerite_beam)
   {
    #purifying_blast
    Spell(purifying_blast)
    #havoc,cycle_targets=1,if=!(target=self.target)&(!talent.grimoire_of_supremacy.enabled|!talent.inferno.enabled|talent.grimoire_of_supremacy.enabled&pet.infernal.remains<=10)
    if not False(target_is_target) and { not Talent(grimoire_of_supremacy_talent) or not Talent(inferno_talent) or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) <= 10 } and Enemies() > 1 Spell(havoc)
   }
  }
 }
}

AddFunction DestructionAoeShortCdPostConditions
{
 DemonDuration(infernal) > 0 and { BuffExpires(crashing_chaos_buff) or not Talent(grimoire_of_supremacy_talent) } and { not SpellCooldown(havoc) == 0 or Enemies() > 3 } and Spell(rain_of_fire) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and Spell(channel_demonfire) or target.DebuffRemaining(immolate_debuff) < 5 and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or DestructionCdsShortCdPostConditions() or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and { DebuffCountOnAny(havoc_debuff) > 0 or Talent(cataclysm_talent) or Talent(inferno_talent) and Enemies() < 4 } and Spell(chaos_bolt) or Spell(rain_of_fire) or Spell(focused_azerite_beam) or Talent(fire_and_brimstone_talent) and BuffPresent(backdraft_buff) and SoulShards() < 5 - 0.2 * Enemies() and Spell(incinerate) or Spell(soul_fire) or BuffExpires(backdraft_buff) and Spell(conflagrate) or not Talent(fire_and_brimstone_talent) and Spell(shadowburn) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or Spell(incinerate)
}

AddFunction DestructionAoeCdActions
{
 unless DemonDuration(infernal) > 0 and { BuffExpires(crashing_chaos_buff) or not Talent(grimoire_of_supremacy_talent) } and { not SpellCooldown(havoc) == 0 or Enemies() > 3 } and Spell(rain_of_fire) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and Spell(channel_demonfire) or target.DebuffRemaining(immolate_debuff) < 5 and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate)
 {
  #call_action_list,name=cds
  DestructionCdsCdActions()
 }
}

AddFunction DestructionAoeCdPostConditions
{
 DemonDuration(infernal) > 0 and { BuffExpires(crashing_chaos_buff) or not Talent(grimoire_of_supremacy_talent) } and { not SpellCooldown(havoc) == 0 or Enemies() > 3 } and Spell(rain_of_fire) or target.DebuffRemaining(immolate_debuff) > CastTime(channel_demonfire) and Spell(channel_demonfire) or target.DebuffRemaining(immolate_debuff) < 5 and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or DestructionCdsCdPostConditions() or not False(target_is_target) and Enemies() < 4 and Enemies() > 1 and Spell(havoc) or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and { DebuffCountOnAny(havoc_debuff) > 0 or Talent(cataclysm_talent) or Talent(inferno_talent) and Enemies() < 4 } and Spell(chaos_bolt) or Spell(rain_of_fire) or Spell(focused_azerite_beam) or Spell(purifying_blast) or not False(target_is_target) and { not Talent(grimoire_of_supremacy_talent) or not Talent(inferno_talent) or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) <= 10 } and Enemies() > 1 and Spell(havoc) or Talent(fire_and_brimstone_talent) and BuffPresent(backdraft_buff) and SoulShards() < 5 - 0.2 * Enemies() and Spell(incinerate) or Spell(soul_fire) or BuffExpires(backdraft_buff) and Spell(conflagrate) or not Talent(fire_and_brimstone_talent) and Spell(shadowburn) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies() < 5 and Spell(concentrated_flame_essence) or Spell(incinerate)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } DestructionHavocMainActions()

 unless DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if Enemies() > 2 DestructionAoeMainActions()

  unless Enemies() > 2 and DestructionAoeMainPostConditions()
  {
   #immolate,cycle_targets=1,if=refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
   if target.Refreshable(immolate_debuff) and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } Spell(immolate)
   #immolate,if=talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains<duration*0.5
   if Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 Spell(immolate)
   #call_action_list,name=cds
   DestructionCdsMainActions()

   unless DestructionCdsMainPostConditions()
   {
    #focused_azerite_beam,if=!pet.infernal.active|!talent.grimoire_of_supremacy.enabled
    if not DemonDuration(infernal) > 0 or not Talent(grimoire_of_supremacy_talent) Spell(focused_azerite_beam)
    #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight
    if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) Spell(concentrated_flame_essence)
    #channel_demonfire
    Spell(channel_demonfire)
    #soul_fire
    Spell(soul_fire)
    #conflagrate,if=buff.backdraft.down&soul_shard>=1.5-0.3*talent.flashover.enabled&!variable.pool_soul_shards
    if BuffExpires(backdraft_buff) and SoulShards() >= 1.5 - 0.3 * TalentPoints(flashover_talent) and not pool_soul_shards() Spell(conflagrate)
    #shadowburn,if=soul_shard<2&(!variable.pool_soul_shards|charges>1)
    if SoulShards() < 2 and { not pool_soul_shards() or Charges(shadowburn) > 1 } Spell(shadowburn)
    #variable,name=pool_soul_shards,value=active_enemies>1&cooldown.havoc.remains<=10|cooldown.summon_infernal.remains<=20&(talent.grimoire_of_supremacy.enabled|talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=20)|talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=20&(cooldown.summon_infernal.remains>target.time_to_die|cooldown.summon_infernal.remains+cooldown.summon_infernal.duration>target.time_to_die)
    #chaos_bolt,if=(talent.grimoire_of_supremacy.enabled|azerite.crashing_chaos.enabled)&pet.infernal.active|buff.dark_soul_instability.up|buff.reckless_force.react&buff.reckless_force.remains>cast_time
    if { Talent(grimoire_of_supremacy_talent) or HasAzeriteTrait(crashing_chaos_trait) } and DemonDuration(infernal) > 0 or BuffPresent(dark_soul_instability_buff) or BuffPresent(reckless_force_buff) and BuffRemaining(reckless_force_buff) > CastTime(chaos_bolt) Spell(chaos_bolt)
    #chaos_bolt,if=!variable.pool_soul_shards&!talent.eradication.enabled
    if not pool_soul_shards() and not Talent(eradication_talent) Spell(chaos_bolt)
    #chaos_bolt,if=!variable.pool_soul_shards&talent.eradication.enabled&(debuff.eradication.remains<cast_time|buff.backdraft.up)
    if not pool_soul_shards() and Talent(eradication_talent) and { target.DebuffRemaining(eradication_debuff) < CastTime(chaos_bolt) or BuffPresent(backdraft_buff) } Spell(chaos_bolt)
    #chaos_bolt,if=(soul_shard>=4.5-0.2*active_enemies)
    if SoulShards() >= 4.5 - 0.2 * Enemies() Spell(chaos_bolt)
    #conflagrate,if=charges>1
    if Charges(conflagrate) > 1 Spell(conflagrate)
    #incinerate
    Spell(incinerate)
   }
  }
 }
}

AddFunction DestructionDefaultMainPostConditions
{
 DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocMainPostConditions() or Enemies() > 2 and DestructionAoeMainPostConditions() or DestructionCdsMainPostConditions()
}

AddFunction DestructionDefaultShortCdActions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } DestructionHavocShortCdActions()

 unless DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocShortCdPostConditions()
 {
  #cataclysm
  Spell(cataclysm)
  #call_action_list,name=aoe,if=active_enemies>2
  if Enemies() > 2 DestructionAoeShortCdActions()

  unless Enemies() > 2 and DestructionAoeShortCdPostConditions() or target.Refreshable(immolate_debuff) and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 and Spell(immolate)
  {
   #call_action_list,name=cds
   DestructionCdsShortCdActions()

   unless DestructionCdsShortCdPostConditions() or { not DemonDuration(infernal) > 0 or not Talent(grimoire_of_supremacy_talent) } and Spell(focused_azerite_beam)
   {
    #the_unbound_force,if=buff.reckless_force.react
    if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
    #purifying_blast
    Spell(purifying_blast)

    unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or Spell(channel_demonfire)
    {
     #havoc,cycle_targets=1,if=!(target=self.target)&(dot.immolate.remains>dot.immolate.duration*0.5|!talent.internal_combustion.enabled)&(!cooldown.summon_infernal.ready|!talent.grimoire_of_supremacy.enabled|talent.grimoire_of_supremacy.enabled&pet.infernal.remains<=10)
     if not False(target_is_target) and { target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0.5 or not Talent(internal_combustion_talent) } and { not SpellCooldown(summon_infernal) == 0 or not Talent(grimoire_of_supremacy_talent) or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) <= 10 } and Enemies() > 1 Spell(havoc)
    }
   }
  }
 }
}

AddFunction DestructionDefaultShortCdPostConditions
{
 DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocShortCdPostConditions() or Enemies() > 2 and DestructionAoeShortCdPostConditions() or target.Refreshable(immolate_debuff) and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 and Spell(immolate) or DestructionCdsShortCdPostConditions() or { not DemonDuration(infernal) > 0 or not Talent(grimoire_of_supremacy_talent) } and Spell(focused_azerite_beam) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or Spell(channel_demonfire) or Spell(soul_fire) or BuffExpires(backdraft_buff) and SoulShards() >= 1.5 - 0.3 * TalentPoints(flashover_talent) and not pool_soul_shards() and Spell(conflagrate) or SoulShards() < 2 and { not pool_soul_shards() or Charges(shadowburn) > 1 } and Spell(shadowburn) or { { Talent(grimoire_of_supremacy_talent) or HasAzeriteTrait(crashing_chaos_trait) } and DemonDuration(infernal) > 0 or BuffPresent(dark_soul_instability_buff) or BuffPresent(reckless_force_buff) and BuffRemaining(reckless_force_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not pool_soul_shards() and not Talent(eradication_talent) and Spell(chaos_bolt) or not pool_soul_shards() and Talent(eradication_talent) and { target.DebuffRemaining(eradication_debuff) < CastTime(chaos_bolt) or BuffPresent(backdraft_buff) } and Spell(chaos_bolt) or SoulShards() >= 4.5 - 0.2 * Enemies() and Spell(chaos_bolt) or Charges(conflagrate) > 1 and Spell(conflagrate) or Spell(incinerate)
}

AddFunction DestructionDefaultCdActions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } DestructionHavocCdActions()

 unless DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocCdPostConditions() or Spell(cataclysm)
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if Enemies() > 2 DestructionAoeCdActions()

  unless Enemies() > 2 and DestructionAoeCdPostConditions() or target.Refreshable(immolate_debuff) and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 and Spell(immolate)
  {
   #call_action_list,name=cds
   DestructionCdsCdActions()
  }
 }
}

AddFunction DestructionDefaultCdPostConditions
{
 DebuffCountOnAny(havoc_debuff) > 0 and Enemies() < 5 - TalentPoints(inferno_talent) + { Talent(inferno_talent) and Talent(internal_combustion_talent) } and DestructionHavocCdPostConditions() or Spell(cataclysm) or Enemies() > 2 and DestructionAoeCdPostConditions() or target.Refreshable(immolate_debuff) and { not Talent(cataclysm_talent) or SpellCooldown(cataclysm) > target.DebuffRemaining(immolate_debuff) } and Spell(immolate) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) < BaseDuration(immolate_debuff) * 0.5 and Spell(immolate) or DestructionCdsCdPostConditions() or { not DemonDuration(infernal) > 0 or not Talent(grimoire_of_supremacy_talent) } and Spell(focused_azerite_beam) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or Spell(channel_demonfire) or not False(target_is_target) and { target.DebuffRemaining(immolate_debuff) > target.DebuffDuration(immolate_debuff) * 0.5 or not Talent(internal_combustion_talent) } and { not SpellCooldown(summon_infernal) == 0 or not Talent(grimoire_of_supremacy_talent) or Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) <= 10 } and Enemies() > 1 and Spell(havoc) or Spell(soul_fire) or BuffExpires(backdraft_buff) and SoulShards() >= 1.5 - 0.3 * TalentPoints(flashover_talent) and not pool_soul_shards() and Spell(conflagrate) or SoulShards() < 2 and { not pool_soul_shards() or Charges(shadowburn) > 1 } and Spell(shadowburn) or { { Talent(grimoire_of_supremacy_talent) or HasAzeriteTrait(crashing_chaos_trait) } and DemonDuration(infernal) > 0 or BuffPresent(dark_soul_instability_buff) or BuffPresent(reckless_force_buff) and BuffRemaining(reckless_force_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not pool_soul_shards() and not Talent(eradication_talent) and Spell(chaos_bolt) or not pool_soul_shards() and Talent(eradication_talent) and { target.DebuffRemaining(eradication_debuff) < CastTime(chaos_bolt) or BuffPresent(backdraft_buff) } and Spell(chaos_bolt) or SoulShards() >= 4.5 - 0.2 * Enemies() and Spell(chaos_bolt) or Charges(conflagrate) > 1 and Spell(conflagrate) or Spell(incinerate)
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
# backdraft_buff
# berserking
# blood_fury_sp
# blood_of_the_enemy
# cataclysm
# cataclysm_talent
# channel_demonfire
# chaos_bolt
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conflagrate
# crashing_chaos_buff
# crashing_chaos_trait
# dark_soul_instability
# dark_soul_instability_buff
# dark_soul_instability_talent
# eradication_debuff
# eradication_talent
# fire_and_brimstone_talent
# fireblood
# flashover_talent
# focused_azerite_beam
# grimoire_of_sacrifice
# grimoire_of_sacrifice_talent
# grimoire_of_supremacy_talent
# guardian_of_azeroth
# havoc
# havoc_debuff
# immolate
# immolate_debuff
# incinerate
# inferno_talent
# internal_combustion_talent
# item_unbridled_fury
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# purifying_blast
# rain_of_fire
# reckless_force_buff
# ripple_in_space_essence
# shadowburn
# soul_fire
# soul_fire_talent
# summon_imp
# summon_infernal
# the_unbound_force
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
