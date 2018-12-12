local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_warlock_affliction"
    local desc = "[8.0] Simulationcraft: PR_Warlock_Affliction"
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
 #unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*execute_time&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=soul_shard*execute_time)
 if SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } Spell(unstable_affliction)
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
 unless SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersShortCdActions()
 }
}

AddFunction AfflictionSpendersShortCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersShortCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies() < 2 or SoulShards() >= 2 and Enemies() >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
}

AddFunction AfflictionSpendersCdActions
{
 unless SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(6-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersCdActions()
 }
}

AddFunction AfflictionSpendersCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * ExecuteTime(unstable_affliction) and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 6 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies() < 2 or SoulShards() >= 2 and Enemies() >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies() == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
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
 #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
 if Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshMainActions()

 unless Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshMainPostConditions()
 {
  #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
  if Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshMainActions()

  unless Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshMainPostConditions()
  {
   #shadow_bolt,if=buff.movement.up&buff.nightfall.remains
   if Speed() > 0 and BuffPresent(nightfall_buff) Spell(shadow_bolt_affliction)
   #agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
   if Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } Spell(agony)
   #siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
   if Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } Spell(siphon_life)
   #corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
   if Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) Spell(corruption)
   #drain_life,if=(buff.inevitable_demise.stack>=85-(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>2)*20&(cooldown.deathbolt.remains>execute_time|!talent.deathbolt.enabled)&(cooldown.phantom_singularity.remains>execute_time|!talent.phantom_singularity.enabled)&(cooldown.dark_soul.remains>execute_time|!talent.dark_soul_misery.enabled)&(cooldown.vile_taint.remains>execute_time|!talent.vile_taint.enabled)&cooldown.summon_darkglare.remains>execute_time+10|buff.inevitable_demise.stack>30&target.time_to_die<=10)
   if BuffStacks(inevitable_demise_buff) >= 85 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 Spell(drain_life)
   #haunt
   Spell(haunt)
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
 Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshMainPostConditions() or Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshMainPostConditions()
}

AddFunction AfflictionFillersShortCdActions
{
 unless TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshShortCdActions()

  unless Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshShortCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshShortCdActions()

   unless Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshShortCdPostConditions()
   {
    #deathbolt,if=cooldown.summon_darkglare.remains>=30+gcd|cooldown.summon_darkglare.remains>140
    if SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 Spell(deathbolt)
   }
  }
 }
}

AddFunction AfflictionFillersShortCdPostConditions
{
 TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction) or Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshShortCdPostConditions() or Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshShortCdPostConditions() or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 85 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 } and Spell(drain_life) or Spell(haunt) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

AddFunction AfflictionFillersCdActions
{
 unless TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbrefreshCdActions()

  unless Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbrefreshCdActions()
  }
 }
}

AddFunction AfflictionFillersCdPostConditions
{
 TimeSincePreviousSpell(unstable_affliction) > 15 and SpellCooldown(deathbolt) <= GCD() * 2 and Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) > 20 and Spell(unstable_affliction) or Enemies() == 1 + False(raid_events_invulnerable_up) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbrefreshCdPostConditions() or Enemies() == 1 + False(raid_events_invulnerable_up) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbrefreshCdPostConditions() or { SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 } and Spell(deathbolt) or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or { BuffStacks(inevitable_demise_buff) >= 85 - { Enemies() - False(raid_events_invulnerable_up) > 2 } * 20 and { SpellCooldown(deathbolt) > ExecuteTime(drain_life) or not Talent(deathbolt_talent) } and { SpellCooldown(phantom_singularity) > ExecuteTime(drain_life) or not Talent(phantom_singularity_talent) } and { SpellCooldown(dark_soul_misery) > ExecuteTime(drain_life) or not Talent(dark_soul_misery_talent) } and { SpellCooldown(vile_taint) > ExecuteTime(drain_life) or not Talent(vile_taint_talent) } and SpellCooldown(summon_darkglare) > ExecuteTime(drain_life) + 10 or BuffStacks(inevitable_demise_buff) > 30 and target.TimeToDie() <= 10 } and Spell(drain_life) or Spell(haunt) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

### actions.dots

AddFunction AfflictionDotsMainActions
{
 #seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight
 if target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) Spell(seed_of_corruption)
 #agony,target_if=min:remains,if=talent.creeping_death.enabled&active_dot.agony<6&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)
 if Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } Spell(agony)
 #agony,target_if=min:remains,if=!talent.creeping_death.enabled&active_dot.agony<8&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)
 if not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } Spell(agony)
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
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies() and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies() == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies() < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
}

AddFunction AfflictionDotsCdActions
{
}

AddFunction AfflictionDotsCdPostConditions
{
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies() >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(agony_debuff) } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies() and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies() == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies() < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
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
}

AddFunction AfflictionCooldownsShortCdPostConditions
{
}

AddFunction AfflictionCooldownsCdActions
{
 #potion,if=(talent.dark_soul_misery.enabled&cooldown.summon_darkglare.up&cooldown.dark_soul.up)|cooldown.summon_darkglare.up|target.time_to_die<30
 if { Talent(dark_soul_misery_talent) and not SpellCooldown(summon_darkglare) > 0 and not SpellCooldown(dark_soul_misery) > 0 or not SpellCooldown(summon_darkglare) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 #use_items,if=!cooldown.summon_darkglare.up,if=cooldown.summon_darkglare.remains>70|time_to_die<20|((buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains)&!cooldown.summon_darkglare.remains)
 if SpellCooldown(summon_darkglare) > 70 or target.TimeToDie() < 20 or { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) > 0 } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 } and not SpellCooldown(summon_darkglare) > 0 AfflictionUseItemActions()
 #fireblood,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(fireblood)
 #blood_fury,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(blood_fury_sp)
}

AddFunction AfflictionCooldownsCdPostConditions
{
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
  #deathbolt,if=cooldown.summon_darkglare.remains&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up
  if SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) Spell(deathbolt)

  unless target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction)
  {
   #phantom_singularity,target_if=max:target.time_to_die,if=time>35&(cooldown.summon_darkglare.remains>=45|cooldown.summon_darkglare.remains<8)&target.time_to_die>16*spell_haste
   if TimeInCombat() > 35 and { SpellCooldown(summon_darkglare) >= 45 or SpellCooldown(summon_darkglare) < 8 } and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } Spell(phantom_singularity)

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
  #summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up)
  if target.DebuffPresent(agony_debuff) and target.DebuffPresent(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) > 0 } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 or Enemies() > 1 + False(raid_events_invulnerable_up) } Spell(summon_darkglare)

  unless SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) and Spell(deathbolt) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and { SpellCooldown(summon_darkglare) >= 45 or SpellCooldown(summon_darkglare) < 8 } and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(phantom_singularity) or TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption)
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

AddFunction AfflictionDefaultCdPostConditions
{
 AfflictionCooldownsCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies() <= 2 + False(raid_events_invulnerable_up) and Spell(haunt) or SpellCooldown(summon_darkglare) > 0 and Enemies() == 1 + False(raid_events_invulnerable_up) and Spell(deathbolt) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and { SpellCooldown(summon_darkglare) >= 45 or SpellCooldown(summon_darkglare) < 8 } and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(phantom_singularity) or TimeInCombat() > 15 and target.TimeToDie() >= 10 and Spell(vile_taint) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption) or AfflictionDotsCdPostConditions() or TimeInCombat() <= 35 and Spell(phantom_singularity) or TimeInCombat() < 15 and Spell(vile_taint) or AfflictionSpendersCdPostConditions() or AfflictionFillersCdPostConditions()
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
# cascading_calamity_buff
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
# drain_soul_talent
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
# shadow_bolt_affliction
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
    local name = "sc_pr_warlock_demonology"
    local desc = "[8.0] Simulationcraft: PR_Warlock_Demonology"
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
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
  if Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 Spell(power_siphon)

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

 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildashardCdActions()
 }
}

AddFunction DemonologyNetherportalbuildingCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildashardCdPostConditions()
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
  #hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(160+action.hand_of_guldan.cast_time)
  if SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) Spell(hand_of_guldan)
  #demonbolt,if=buff.demonic_core.up
  if BuffPresent(demonic_core_buff) Spell(demonbolt)
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
 #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
 if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

 unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildashardShortCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan)
  {
   #summon_demonic_tyrant,if=buff.nether_portal.remains<10&soul_shard=0
   if BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 Spell(summon_demonic_tyrant)
   #summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+5.5
   if BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 Spell(summon_demonic_tyrant)

   unless BuffPresent(demonic_core_buff) and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildashardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyNetherportalactiveShortCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildashardShortCdPostConditions()
}

AddFunction DemonologyNetherportalactiveCdActions
{
 #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
 if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

 unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildashardCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and Spell(demonbolt)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildashardCdActions()
  }
 }
}

AddFunction DemonologyNetherportalactiveCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildashardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 160 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffRemaining(nether_portal_buff) < 10 and SoulShards() == 0 and Spell(summon_demonic_tyrant) or BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 5.5 and Spell(summon_demonic_tyrant) or BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildashardCdPostConditions()
}

### actions.nether_portal

AddFunction DemonologyNetherportalMainActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingMainActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingMainPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherportalactiveMainActions()
 }
}

AddFunction DemonologyNetherportalMainPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingMainPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherportalactiveMainPostConditions()
}

AddFunction DemonologyNetherportalShortCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingShortCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingShortCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherportalactiveShortCdActions()
 }
}

AddFunction DemonologyNetherportalShortCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingShortCdPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherportalactiveShortCdPostConditions()
}

AddFunction DemonologyNetherportalCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherportalbuildingCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>160
  if SpellCooldown(nether_portal) > 160 DemonologyNetherportalactiveCdActions()
 }
}

AddFunction DemonologyNetherportalCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherportalbuildingCdPostConditions() or SpellCooldown(nether_portal) > 160 and DemonologyNetherportalactiveCdPostConditions()
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
 DemonologyBuildashardMainActions()
}

AddFunction DemonologyImplosionMainPostConditions
{
 DemonologyBuildashardMainPostConditions()
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
    DemonologyBuildashardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyImplosionShortCdPostConditions
{
 { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildashardShortCdPostConditions()
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
   DemonologyBuildashardCdActions()
  }
 }
}

AddFunction DemonologyImplosionCdPostConditions
{
 { Demons(wild_imp) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan) and DebuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Spell(summon_demonic_tyrant) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan) or Demons(wild_imp) >= 3 } and Demons(wild_imp) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or DebuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) <= 3 or PreviousGCDSpell(hand_of_guldan) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies() <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies() and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildashardCdPostConditions()
}

### actions.build_a_shard

AddFunction DemonologyBuildashardMainActions
{
 #demonbolt,if=azerite.forbidden_knowledge.enabled&buff.forbidden_knowledge.react&!buff.demonic_core.react&cooldown.summon_demonic_tyrant.remains>20
 if HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 Spell(demonbolt)
 #soul_strike
 Spell(soul_strike)
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
 HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 and Spell(demonbolt) or Spell(soul_strike) or Spell(shadow_bolt)
}

AddFunction DemonologyBuildashardCdActions
{
}

AddFunction DemonologyBuildashardCdPostConditions
{
 HasAzeriteTrait(forbidden_knowledge_trait) and BuffPresent(forbidden_knowledge_buff) and not BuffPresent(demonic_core_buff) and SpellCooldown(summon_demonic_tyrant) > 20 and Spell(demonbolt) or Spell(soul_strike) or Spell(shadow_bolt)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
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
   #call_dreadstalkers,if=equipped.132369|(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
   if HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
   #doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
   if Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 Spell(doom)
   #hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
   if SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } Spell(hand_of_guldan)
   #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
   if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
   #demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<10|cooldown.summon_demonic_tyrant.remains>22)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25)
   if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } Spell(demonbolt)
   #call_action_list,name=build_a_shard
   DemonologyBuildashardMainActions()
  }
 }
}

AddFunction DemonologyDefaultMainPostConditions
{
 Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalMainPostConditions() or Enemies() > 1 and DemonologyImplosionMainPostConditions() or DemonologyBuildashardMainPostConditions()
}

AddFunction DemonologyDefaultShortCdActions
{
 unless not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom)
 {
  #demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
  if Demons(wild_imp) < 6 or DebuffPresent(demonic_power) or Enemies() < 2 Spell(demonic_strength)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherportalShortCdActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalShortCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionShortCdActions()

   unless Enemies() > 1 and DemonologyImplosionShortCdPostConditions()
   {
    #summon_vilefiend,if=equipped.132369|cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

    unless { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
    {
     #summon_demonic_tyrant,if=ptr=0&(equipped.132369|(buff.dreadstalkers.remains>cast_time&(buff.wild_imps.stack>=3|prev_gcd.1.hand_of_guldan)&(soul_shard<3|buff.dreadstalkers.remains<gcd*2.7|buff.grimoire_felguard.remains<gcd*2.7)))
     if PTR() == 0 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } Spell(summon_demonic_tyrant)
     #summon_demonic_tyrant,if=ptr=1&(equipped.132369|(buff.dreadstalkers.remains>cast_time&(buff.wild_imps.stack>=3+talent.inner_demons.enabled+talent.demonic_consumption.enabled*3|prev_gcd.1.hand_of_guldan&(!talent.demonic_consumption.enabled|buff.wild_imps.stack>=3+talent.inner_demons.enabled))&(soul_shard<3|buff.dreadstalkers.remains<gcd*2.7|buff.grimoire_felguard.remains<gcd*2.7)))
     if PTR() == 1 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) + TalentPoints(demonic_consumption_talent) * 3 or PreviousGCDSpell(hand_of_guldan) and { not Talent(demonic_consumption_talent) or Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) } } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } Spell(summon_demonic_tyrant)
     #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
     if Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 Spell(power_siphon)

     unless Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt)
     {
      #bilescourge_bombers,if=ptr=1
      if PTR() == 1 Spell(bilescourge_bombers)
      #call_action_list,name=build_a_shard
      DemonologyBuildashardShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultShortCdPostConditions
{
 not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalShortCdPostConditions() or Enemies() > 1 and DemonologyImplosionShortCdPostConditions() or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt) or DemonologyBuildashardShortCdPostConditions()
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
  if Talent(nether_portal_talent) and Enemies() <= 2 DemonologyNetherportalCdActions()

  unless Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies() > 1 DemonologyImplosionCdActions()

   unless Enemies() > 1 and DemonologyImplosionCdPostConditions()
   {
    #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
    if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

    unless { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or PTR() == 0 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or PTR() == 1 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) + TalentPoints(demonic_consumption_talent) * 3 or PreviousGCDSpell(hand_of_guldan) and { not Talent(demonic_consumption_talent) or Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) } } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt) or PTR() == 1 and Spell(bilescourge_bombers)
    {
     #call_action_list,name=build_a_shard
     DemonologyBuildashardCdActions()
    }
   }
  }
 }
}

AddFunction DemonologyDefaultCdPostConditions
{
 not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies() < 2 and Spell(doom) or { Demons(wild_imp) < 6 or DebuffPresent(demonic_power) or Enemies() < 2 } and Spell(demonic_strength) or Talent(nether_portal_talent) and Enemies() <= 2 and DemonologyNetherportalCdPostConditions() or Enemies() > 1 and DemonologyImplosionCdPostConditions() or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or PTR() == 0 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 or PreviousGCDSpell(hand_of_guldan) } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or PTR() == 1 and { HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) or DemonDuration(dreadstalker) > CastTime(summon_demonic_tyrant) and { Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) + TalentPoints(demonic_consumption_talent) * 3 or PreviousGCDSpell(hand_of_guldan) and { not Talent(demonic_consumption_talent) or Demons(wild_imp) >= 3 + TalentPoints(inner_demons_talent) } } and { SoulShards() < 3 or DemonDuration(dreadstalker) < GCD() * 2.7 or DebuffRemaining(grimoire_felguard) < GCD() * 2.7 } } and Spell(summon_demonic_tyrant) or Demons(wild_imp) >= 2 and BuffStacks(demonic_core_buff) <= 2 and DebuffExpires(demonic_power) and Enemies() < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 10 or SpellCooldown(summon_demonic_tyrant) > 22 or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 } and Spell(demonbolt) or PTR() == 1 and Spell(bilescourge_bombers) or DemonologyBuildashardCdPostConditions()
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
# demonic_consumption_talent
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
    local name = "sc_pr_warlock_destruction"
    local desc = "[8.0] Simulationcraft: PR_Warlock_Destruction"
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction DestructionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Talent(grimoire_of_sacrifice_talent) and pet.Present() and Spell(grimoire_of_sacrifice) or Spell(soul_fire) or not Talent(soul_fire_talent) and Spell(incinerate)
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
  #channel_demonfire,if=!buff.active_havoc.remains
  if not BuffPresent(active_havoc_buff) Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up+talent.internal_combustion.enabled&((108*(spell_targets.rain_of_fire+raid_event.invulnerable.up)%(3-0.16*(spell_targets.rain_of_fire+raid_event.invulnerable.up)))<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / { 3 - 0.16 * { Enemies() + False(raid_events_invulnerable_up) } } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=3+raid_event.invulnerable.up&(talent.eradication.enabled|talent.internal_combustion.enabled)
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } Spell(chaos_bolt)
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

  unless Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up+talent.internal_combustion.enabled&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=4+raid_event.invulnerable.up+talent.internal_combustion.enabled&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

   unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / { 3 - 0.16 * { Enemies() + False(raid_events_invulnerable_up) } } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
   {
    #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=3+raid_event.invulnerable.up&(talent.eradication.enabled|talent.internal_combustion.enabled)
    if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 Spell(havoc)
    #havoc,if=spell_targets.rain_of_fire<=3+raid_event.invulnerable.up&(talent.eradication.enabled|talent.internal_combustion.enabled)
    if Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 Spell(havoc)
   }
  }
 }
}

AddFunction DestructionInfShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / { 3 - 0.16 * { Enemies() + False(raid_events_invulnerable_up) } } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionInfCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionInfCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Spell(cataclysm) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) + TalentPoints(internal_combustion_talent) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / { 3 - 0.16 * { Enemies() + False(raid_events_invulnerable_up) } } < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 and Spell(havoc) or Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 3 + False(raid_events_invulnerable_up) and { Talent(eradication_talent) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
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
  #channel_demonfire,if=!buff.active_havoc.remains
  if not BuffPresent(active_havoc_buff) Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&active_enemies<=4+raid_event.invulnerable.up&((108*(spell_targets.rain_of_fire+raid_event.invulnerable.up)%3)<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) Spell(chaos_bolt)
  #immolate,cycle_targets=1,if=!debuff.havoc.remains&refreshable&spell_targets.incinerate<=8+raid_event.invulnerable.up
  if not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 + False(raid_events_invulnerable_up) Spell(immolate)
  #rain_of_fire
  Spell(rain_of_fire)
  #soul_fire,cycle_targets=1,if=!debuff.havoc.remains&spell_targets.incinerate<=3+raid_event.invulnerable.up
  if not target.DebuffPresent(havoc_debuff) and Enemies() <= 3 + False(raid_events_invulnerable_up) Spell(soul_fire)
  #conflagrate,cycle_targets=1,if=!debuff.havoc.remains&(talent.flashover.enabled&buff.backdraft.stack<=2|spell_targets.incinerate<=7+raid_event.invulnerable.up|talent.roaring_blaze.enabled&spell_targets.incinerate<=9+raid_event.invulnerable.up)
  if not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 + False(raid_events_invulnerable_up) or Talent(roaring_blaze_talent) and Enemies() <= 9 + False(raid_events_invulnerable_up) } Spell(conflagrate)
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

 unless DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire)
 {
  #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
  if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
  #havoc,if=spell_targets.rain_of_fire<=4+raid_event.invulnerable.up&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
  if Enemies() <= 4 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

  unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
   if Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
  }
 }
}

AddFunction DestructionFnbShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 + False(raid_events_invulnerable_up) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Enemies() <= 3 + False(raid_events_invulnerable_up) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 + False(raid_events_invulnerable_up) or Talent(roaring_blaze_talent) and Enemies() <= 9 + False(raid_events_invulnerable_up) } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionFnbCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionFnbCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and Enemies() <= 8 + False(raid_events_invulnerable_up) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Enemies() <= 3 + False(raid_events_invulnerable_up) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or Enemies() <= 7 + False(raid_events_invulnerable_up) or Talent(roaring_blaze_talent) and Enemies() <= 9 + False(raid_events_invulnerable_up) } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
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
  #channel_demonfire,if=!buff.active_havoc.remains
  if not BuffPresent(active_havoc_buff) Spell(channel_demonfire)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&talent.grimoire_of_supremacy.enabled&pet.infernal.remains>execute_time&active_enemies<=8+raid_event.invulnerable.up&((108*(spell_targets.rain_of_fire+raid_event.invulnerable.up)%3)<(240*(1+0.08*buff.grimoire_of_supremacy.stack)%2*(1+buff.active_havoc.remains>execute_time)))
  if not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } Spell(chaos_bolt)
  #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&buff.active_havoc.remains>execute_time&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
  if not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) Spell(chaos_bolt)
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

  unless Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire)
  {
   #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=8+raid_event.invulnerable.up&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 8 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)
   #havoc,if=spell_targets.rain_of_fire<=8+raid_event.invulnerable.up&talent.grimoire_of_supremacy.enabled&pet.infernal.active&pet.infernal.remains<=10
   if Enemies() <= 8 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 Spell(havoc)

   unless not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt)
   {
    #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
    if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
    #havoc,if=spell_targets.rain_of_fire<=4+raid_event.invulnerable.up
    if Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
   }
  }
 }
}

AddFunction DestructionCataShortCdPostConditions
{
 DestructionCdsShortCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and target.DebuffRemaining(immolate_debuff) <= SpellCooldown(cataclysm) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionCataCdActions
{
 #call_action_list,name=cds
 DestructionCdsCdActions()
}

AddFunction DestructionCataCdPostConditions
{
 DestructionCdsCdPostConditions() or SoulShards() >= 4.5 and Spell(rain_of_fire) or Spell(cataclysm) or Talent(channel_demonfire_talent) and not target.DebuffRemaining(immolate_debuff) and SpellCooldown(channel_demonfire) <= ExecuteTime(chaos_bolt) and Spell(immolate) or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 8 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or Enemies() <= 8 + False(raid_events_invulnerable_up) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > 0 and DemonDuration(infernal) <= 10 and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Talent(grimoire_of_supremacy_talent) and DemonDuration(infernal) > ExecuteTime(chaos_bolt) and Enemies() <= 8 + False(raid_events_invulnerable_up) and 108 * { Enemies() + False(raid_events_invulnerable_up) } / 3 < 240 * { 1 + 0.08 * BuffStacks(grimoire_of_supremacy_buff) } / 2 * { 1 + BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) } and Spell(chaos_bolt) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or Enemies() <= 4 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and BuffRemaining(active_havoc_buff) > ExecuteTime(chaos_bolt) and Enemies() <= 4 + False(raid_events_invulnerable_up) and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and target.Refreshable(immolate_debuff) and target.DebuffRemaining(immolate_debuff) <= SpellCooldown(cataclysm) and Spell(immolate) or Spell(rain_of_fire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

### actions.default

AddFunction DestructionDefaultMainActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.cataclysm.enabled
 if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) DestructionCataMainActions()

 unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataMainPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) DestructionFnbMainActions()

  unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbMainPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.inferno.enabled
   if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) DestructionInfMainActions()

   unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfMainPostConditions()
   {
    #immolate,cycle_targets=1,if=!debuff.havoc.remains&(refreshable|talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains-action.chaos_bolt.travel_time-5<duration*0.3)
    if not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } Spell(immolate)
    #call_action_list,name=cds
    DestructionCdsMainActions()

    unless DestructionCdsMainPostConditions()
    {
     #channel_demonfire,if=!buff.active_havoc.remains
     if not BuffPresent(active_havoc_buff) Spell(channel_demonfire)
     #soul_fire,cycle_targets=1,if=!debuff.havoc.remains
     if not target.DebuffPresent(havoc_debuff) Spell(soul_fire)
     #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&execute_time+travel_time<target.time_to_die&(trinket.proc.intellect.react&trinket.proc.intellect.remains>cast_time|trinket.proc.mastery.react&trinket.proc.mastery.remains>cast_time|trinket.proc.versatility.react&trinket.proc.versatility.remains>cast_time|trinket.proc.crit.react&trinket.proc.crit.remains>cast_time|trinket.proc.spell_power.react&trinket.proc.spell_power.remains>cast_time)
     if not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
     #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&execute_time+travel_time<target.time_to_die&(trinket.stacking_proc.intellect.react&trinket.stacking_proc.intellect.remains>cast_time|trinket.stacking_proc.mastery.react&trinket.stacking_proc.mastery.remains>cast_time|trinket.stacking_proc.versatility.react&trinket.stacking_proc.versatility.remains>cast_time|trinket.stacking_proc.crit.react&trinket.stacking_proc.crit.remains>cast_time|trinket.stacking_proc.spell_power.react&trinket.stacking_proc.spell_power.remains>cast_time)
     if not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
     #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&execute_time+travel_time<target.time_to_die&(cooldown.summon_infernal.remains>=20|!talent.grimoire_of_supremacy.enabled)&(cooldown.dark_soul_instability.remains>=20|!talent.dark_soul_instability.enabled)&(talent.eradication.enabled&debuff.eradication.remains<=cast_time|buff.backdraft.remains|talent.internal_combustion.enabled)
     if not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SpellCooldown(summon_infernal) >= 20 or not Talent(grimoire_of_supremacy_talent) } and { SpellCooldown(dark_soul_instability) >= 20 or not Talent(dark_soul_instability_talent) } and { Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffPresent(backdraft_buff) or Talent(internal_combustion_talent) } Spell(chaos_bolt)
     #chaos_bolt,cycle_targets=1,if=!debuff.havoc.remains&execute_time+travel_time<target.time_to_die&(soul_shard>=4|buff.dark_soul_instability.remains>cast_time|pet.infernal.active|buff.active_havoc.remains>cast_time)
     if not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SoulShards() >= 4 or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 or BuffRemaining(active_havoc_buff) > CastTime(chaos_bolt) } Spell(chaos_bolt)
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
 Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataMainPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbMainPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfMainPostConditions() or DestructionCdsMainPostConditions()
}

AddFunction DestructionDefaultShortCdActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.cataclysm.enabled
 if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) DestructionCataShortCdActions()

 unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataShortCdPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) DestructionFnbShortCdActions()

  unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbShortCdPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.inferno.enabled
   if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) DestructionInfShortCdActions()

   unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfShortCdPostConditions()
   {
    #cataclysm
    Spell(cataclysm)

    unless not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate)
    {
     #call_action_list,name=cds
     DestructionCdsShortCdActions()

     unless DestructionCdsShortCdPostConditions() or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire)
     {
      #havoc,cycle_targets=1,if=!(target=sim.target)&target.time_to_die>10&active_enemies>1+raid_event.invulnerable.up
      if not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() > 1 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
      #havoc,if=active_enemies>1+raid_event.invulnerable.up
      if Enemies() > 1 + False(raid_events_invulnerable_up) and Enemies() > 1 Spell(havoc)
     }
    }
   }
  }
 }
}

AddFunction DestructionDefaultShortCdPostConditions
{
 Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataShortCdPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbShortCdPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfShortCdPostConditions() or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate) or DestructionCdsShortCdPostConditions() or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SpellCooldown(summon_infernal) >= 20 or not Talent(grimoire_of_supremacy_talent) } and { SpellCooldown(dark_soul_instability) >= 20 or not Talent(dark_soul_instability_talent) } and { Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffPresent(backdraft_buff) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SoulShards() >= 4 or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 or BuffRemaining(active_havoc_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or not Talent(flashover_talent) and BuffStacks(backdraft_buff) < 2 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
}

AddFunction DestructionDefaultCdActions
{
 #run_action_list,name=cata,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.cataclysm.enabled
 if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) DestructionCataCdActions()

 unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataCdPostConditions()
 {
  #run_action_list,name=fnb,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.fire_and_brimstone.enabled
  if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) DestructionFnbCdActions()

  unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbCdPostConditions()
  {
   #run_action_list,name=inf,if=spell_targets.infernal_awakening>=3+raid_event.invulnerable.up&talent.inferno.enabled
   if Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) DestructionInfCdActions()

   unless Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfCdPostConditions() or Spell(cataclysm) or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate)
   {
    #call_action_list,name=cds
    DestructionCdsCdActions()
   }
  }
 }
}

AddFunction DestructionDefaultCdPostConditions
{
 Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(cataclysm_talent) and DestructionCataCdPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(fire_and_brimstone_talent) and DestructionFnbCdPostConditions() or Enemies() >= 3 + False(raid_events_invulnerable_up) and Talent(inferno_talent) and DestructionInfCdPostConditions() or Spell(cataclysm) or not target.DebuffPresent(havoc_debuff) and { target.Refreshable(immolate_debuff) or Talent(internal_combustion_talent) and InFlightToTarget(chaos_bolt) and target.DebuffRemaining(immolate_debuff) - TravelTime(chaos_bolt) - 5 < BaseDuration(immolate_debuff) * 0.3 } and Spell(immolate) or DestructionCdsCdPostConditions() or not BuffPresent(active_havoc_buff) and Spell(channel_demonfire) or not True(target_is_sim_target) and target.TimeToDie() > 10 and Enemies() > 1 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or Enemies() > 1 + False(raid_events_invulnerable_up) and Enemies() > 1 and Spell(havoc) or not target.DebuffPresent(havoc_debuff) and Spell(soul_fire) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_proc_intellect_buff) and BuffRemaining(trinket_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_mastery_buff) and BuffRemaining(trinket_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_versatility_buff) and BuffRemaining(trinket_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_crit_buff) and BuffRemaining(trinket_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_proc_spell_power_buff) and BuffRemaining(trinket_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { BuffPresent(trinket_stacking_proc_intellect_buff) and BuffRemaining(trinket_stacking_proc_intellect_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_mastery_buff) and BuffRemaining(trinket_stacking_proc_mastery_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_versatility_buff) and BuffRemaining(trinket_stacking_proc_versatility_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_crit_buff) and BuffRemaining(trinket_stacking_proc_crit_buff) > CastTime(chaos_bolt) or BuffPresent(trinket_stacking_proc_spell_power_buff) and BuffRemaining(trinket_stacking_proc_spell_power_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SpellCooldown(summon_infernal) >= 20 or not Talent(grimoire_of_supremacy_talent) } and { SpellCooldown(dark_soul_instability) >= 20 or not Talent(dark_soul_instability_talent) } and { Talent(eradication_talent) and target.DebuffRemaining(eradication_debuff) <= CastTime(chaos_bolt) or BuffPresent(backdraft_buff) or Talent(internal_combustion_talent) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and ExecuteTime(chaos_bolt) + TravelTime(chaos_bolt) < target.TimeToDie() and { SoulShards() >= 4 or BuffRemaining(dark_soul_instability_buff) > CastTime(chaos_bolt) or DemonDuration(infernal) > 0 or BuffRemaining(active_havoc_buff) > CastTime(chaos_bolt) } and Spell(chaos_bolt) or not target.DebuffPresent(havoc_debuff) and { Talent(flashover_talent) and BuffStacks(backdraft_buff) <= 2 or not Talent(flashover_talent) and BuffStacks(backdraft_buff) < 2 } and Spell(conflagrate) or not target.DebuffPresent(havoc_debuff) and { Charges(shadowburn) == 2 or not BuffPresent(backdraft_buff) or BuffRemaining(backdraft_buff) > BuffStacks(backdraft_buff) * ExecuteTime(incinerate) } and Spell(shadowburn) or not target.DebuffPresent(havoc_debuff) and Spell(incinerate)
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
# trinket_proc_spell_power_buff
# trinket_stacking_proc_spell_power_buff
]]
    OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
end
