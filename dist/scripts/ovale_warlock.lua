local __exports = LibStub:NewLibrary("ovale/scripts/ovale_warlock", 80300)
if not __exports then return end
__exports.registerWarlock = function(OvaleScripts)
    do
        local name = "sc_t24_warlock_affliction"
        local desc = "[8.3] Simulationcraft: T24_Warlock_Affliction"
        local code = [[
# Based on SimulationCraft profile "T24_Warlock_Affliction".
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
 enemies() <= 1 + talentpoints(writhe_in_agony_talent) + talentpoints(absolute_corruption_talent) * 2 + { hastalent(writhe_in_agony_talent) and hastalent(sow_the_seeds_talent) and enemies() > 2 } + { hastalent(siphon_life_talent) and not hastalent(creeping_death_talent) and not hastalent(drain_soul_talent) } + false(raid_events_invulnerable_up)
}

AddFunction padding
{
 executetime(shadow_bolt_affliction) * hasazeritetrait(cascading_calamity_trait)
}

AddFunction use_seed
{
 hastalent(sow_the_seeds_talent) and enemies() >= 3 + false(raid_events_invulnerable_up) or hastalent(siphon_life_talent) and enemies() >= 5 + false(raid_events_invulnerable_up) or enemies() >= 8 + false(raid_events_invulnerable_up)
}

AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=affliction)

AddFunction afflictionuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.spenders

AddFunction afflictionspendersmainactions
{
 #unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*(execute_time+azerite.dreadful_calling.rank)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=soul_shard*execute_time)&(talent.sow_the_seeds.enabled|dot.phantom_singularity.remains|dot.vile_taint.remains)
 if spellcooldown(summon_darkglare) <= soulshards() * { executetime(unstable_affliction) + azeritetraitrank(dreadful_calling_trait) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= soulshards() * executetime(unstable_affliction) } and { hastalent(sow_the_seeds_talent) or target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } spell(unstable_affliction)
 #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
 if { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) afflictionfillersmainactions()

 unless { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) and afflictionfillersmainpostconditions()
 {
  #seed_of_corruption,if=variable.use_seed
  if use_seed() spell(seed_of_corruption)
  #unstable_affliction,if=!variable.use_seed&!prev_gcd.1.summon_darkglare&(talent.deathbolt.enabled&cooldown.deathbolt.remains<=execute_time&!azerite.cascading_calamity.enabled|(soul_shard>=5&spell_targets.seed_of_corruption_aoe<2|soul_shard>=2&spell_targets.seed_of_corruption_aoe>=2)&target.time_to_die>4+execute_time&spell_targets.seed_of_corruption_aoe=1|target.time_to_die<=8+execute_time*soul_shard)
  if not use_seed() and not previousgcdspell(summon_darkglare) and { hastalent(deathbolt_talent) and spellcooldown(deathbolt) <= executetime(unstable_affliction) and not hasazeritetrait(cascading_calamity_trait) or { soulshards() >= 5 and enemies() < 2 or soulshards() >= 2 and enemies() >= 2 } and target.timetodie() > 4 + executetime(unstable_affliction) and enemies() == 1 or target.timetodie() <= 8 + executetime(unstable_affliction) * soulshards() } spell(unstable_affliction)
  #unstable_affliction,if=!variable.use_seed&contagion<=cast_time+variable.padding
  if not use_seed() and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() spell(unstable_affliction)
  #unstable_affliction,cycle_targets=1,if=!variable.use_seed&(!talent.deathbolt.enabled|cooldown.deathbolt.remains>time_to_shard|soul_shard>1)&(!talent.vile_taint.enabled|soul_shard>1)&contagion<=cast_time+variable.padding&(!azerite.cascading_calamity.enabled|buff.cascading_calamity.remains>time_to_shard)
  if not use_seed() and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) > timetoshard() or soulshards() > 1 } and { not hastalent(vile_taint_talent) or soulshards() > 1 } and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() and { not hasazeritetrait(cascading_calamity_trait) or buffremaining(cascading_calamity_buff) > timetoshard() } spell(unstable_affliction)
 }
}

AddFunction afflictionspendersmainpostconditions
{
 { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) and afflictionfillersmainpostconditions()
}

AddFunction afflictionspendersshortcdactions
{
 unless spellcooldown(summon_darkglare) <= soulshards() * { executetime(unstable_affliction) + azeritetraitrank(dreadful_calling_trait) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= soulshards() * executetime(unstable_affliction) } and { hastalent(sow_the_seeds_talent) or target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } and spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) afflictionfillersshortcdactions()
 }
}

AddFunction afflictionspendersshortcdpostconditions
{
 spellcooldown(summon_darkglare) <= soulshards() * { executetime(unstable_affliction) + azeritetraitrank(dreadful_calling_trait) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= soulshards() * executetime(unstable_affliction) } and { hastalent(sow_the_seeds_talent) or target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } and spell(unstable_affliction) or { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) and afflictionfillersshortcdpostconditions() or use_seed() and spell(seed_of_corruption) or not use_seed() and not previousgcdspell(summon_darkglare) and { hastalent(deathbolt_talent) and spellcooldown(deathbolt) <= executetime(unstable_affliction) and not hasazeritetrait(cascading_calamity_trait) or { soulshards() >= 5 and enemies() < 2 or soulshards() >= 2 and enemies() >= 2 } and target.timetodie() > 4 + executetime(unstable_affliction) and enemies() == 1 or target.timetodie() <= 8 + executetime(unstable_affliction) * soulshards() } and spell(unstable_affliction) or not use_seed() and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() and spell(unstable_affliction) or not use_seed() and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) > timetoshard() or soulshards() > 1 } and { not hastalent(vile_taint_talent) or soulshards() > 1 } and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() and { not hasazeritetrait(cascading_calamity_trait) or buffremaining(cascading_calamity_buff) > timetoshard() } and spell(unstable_affliction)
}

AddFunction afflictionspenderscdactions
{
 unless spellcooldown(summon_darkglare) <= soulshards() * { executetime(unstable_affliction) + azeritetraitrank(dreadful_calling_trait) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= soulshards() * executetime(unstable_affliction) } and { hastalent(sow_the_seeds_talent) or target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } and spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) afflictionfillerscdactions()
 }
}

AddFunction afflictionspenderscdpostconditions
{
 spellcooldown(summon_darkglare) <= soulshards() * { executetime(unstable_affliction) + azeritetraitrank(dreadful_calling_trait) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= soulshards() * executetime(unstable_affliction) } and { hastalent(sow_the_seeds_talent) or target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } and spell(unstable_affliction) or { spellcooldown(summon_darkglare) < timetoshard() * { 5 - soulshards() } or not spellcooldown(summon_darkglare) > 0 } and target.timetodie() > spellcooldown(summon_darkglare) and afflictionfillerscdpostconditions() or use_seed() and spell(seed_of_corruption) or not use_seed() and not previousgcdspell(summon_darkglare) and { hastalent(deathbolt_talent) and spellcooldown(deathbolt) <= executetime(unstable_affliction) and not hasazeritetrait(cascading_calamity_trait) or { soulshards() >= 5 and enemies() < 2 or soulshards() >= 2 and enemies() >= 2 } and target.timetodie() > 4 + executetime(unstable_affliction) and enemies() == 1 or target.timetodie() <= 8 + executetime(unstable_affliction) * soulshards() } and spell(unstable_affliction) or not use_seed() and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() and spell(unstable_affliction) or not use_seed() and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) > timetoshard() or soulshards() > 1 } and { not hastalent(vile_taint_talent) or soulshards() > 1 } and buffremaining(unstable_affliction_buff) <= casttime(unstable_affliction) + padding() and { not hasazeritetrait(cascading_calamity_trait) or buffremaining(cascading_calamity_buff) > timetoshard() } and spell(unstable_affliction)
}

### actions.precombat

AddFunction afflictionprecombatmainactions
{
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if hastalent(grimoire_of_sacrifice_talent) and pet.present() spell(grimoire_of_sacrifice)
 #seed_of_corruption,if=spell_targets.seed_of_corruption_aoe>=3&!equipped.169314
 if enemies() >= 3 and not hasequippeditem(169314) spell(seed_of_corruption)
 #haunt
 spell(haunt)
 #shadow_bolt,if=!talent.haunt.enabled&spell_targets.seed_of_corruption_aoe<3&!equipped.169314
 if not hastalent(haunt_talent) and enemies() < 3 and not hasequippeditem(169314) spell(shadow_bolt_affliction)
}

AddFunction afflictionprecombatmainpostconditions
{
}

AddFunction afflictionprecombatshortcdactions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.present() spell(summon_imp)
}

AddFunction afflictionprecombatshortcdpostconditions
{
 hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice) or enemies() >= 3 and not hasequippeditem(169314) and spell(seed_of_corruption) or spell(haunt) or not hastalent(haunt_talent) and enemies() < 3 and not hasequippeditem(169314) and spell(shadow_bolt_affliction)
}

AddFunction afflictionprecombatcdactions
{
 unless not pet.present() and spell(summon_imp) or hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice)
 {
  #snapshot_stats
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #use_item,name=azsharas_font_of_power
  afflictionuseitemactions()
 }
}

AddFunction afflictionprecombatcdpostconditions
{
 not pet.present() and spell(summon_imp) or hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice) or enemies() >= 3 and not hasequippeditem(169314) and spell(seed_of_corruption) or spell(haunt) or not hastalent(haunt_talent) and enemies() < 3 and not hasequippeditem(169314) and spell(shadow_bolt_affliction)
}

### actions.fillers

AddFunction afflictionfillersmainactions
{
 #unstable_affliction,line_cd=15,if=cooldown.deathbolt.remains<=gcd*2&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains>20
 if timesincepreviousspell(unstable_affliction) > 15 and spellcooldown(deathbolt) <= gcd() * 2 and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) > 20 spell(unstable_affliction)
 #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
 if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 afflictiondb_refreshmainactions()

 unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshmainpostconditions()
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
  if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } afflictiondb_refreshmainactions()

  unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshmainpostconditions()
  {
   #shadow_bolt,if=buff.movement.up&buff.nightfall.remains
   if speed() > 0 and buffpresent(nightfall_buff) spell(shadow_bolt_affliction)
   #agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
   if speed() > 0 and not { hastalent(siphon_life_talent) and previousgcdspell(agony) and previousgcdspell(agony count=2) and previousgcdspell(agony count=3) or previousgcdspell(agony) } spell(agony)
   #siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
   if speed() > 0 and not { previousgcdspell(siphon_life) and previousgcdspell(siphon_life count=2) and previousgcdspell(siphon_life count=3) } spell(siphon_life)
   #corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
   if speed() > 0 and not previousgcdspell(corruption) and not hastalent(absolute_corruption_talent) spell(corruption)
   #drain_life,if=buff.inevitable_demise.stack>10&target.time_to_die<=10
   if buffstacks(inevitable_demise_buff) > 10 and target.timetodie() <= 10 spell(drain_life)
   #drain_life,if=talent.siphon_life.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=2)&dot.agony.remains>5*spell_haste&dot.corruption.remains>gcd&(dot.siphon_life.remains>gcd|!talent.siphon_life.enabled)&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if hastalent(siphon_life_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(siphon_life_debuff) > gcd() or not hastalent(siphon_life_talent) } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } spell(drain_life)
   #drain_life,if=talent.writhe_in_agony.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=3)-5*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up=2)&dot.agony.remains>5*spell_haste&dot.corruption.remains>gcd&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if hastalent(writhe_in_agony_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 3 } - 5 * { enemies() - false(raid_events_invulnerable_up) == 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } spell(drain_life)
   #drain_life,if=talent.absolute_corruption.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=4)&dot.agony.remains>5*spell_haste&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if hastalent(absolute_corruption_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 4 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } spell(drain_life)
   #haunt
   spell(haunt)
   #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight
   if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) spell(concentrated_flame_essence)
   #drain_soul,interrupt_global=1,chain=1,interrupt=1,cycle_targets=1,if=target.time_to_die<=gcd
   if target.timetodie() <= gcd() spell(drain_soul)
   #drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains
   if hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) spell(drain_soul)
   #drain_soul,target_if=min:debuff.shadow_embrace.remains,chain=1,interrupt_if=ticks_remain<5,interrupt_global=1,if=talent.shadow_embrace.enabled&variable.maintain_se
   if hastalent(shadow_embrace_talent) and maintain_se() spell(drain_soul)
   #drain_soul,interrupt_global=1,chain=1,interrupt=1
   spell(drain_soul)
   #shadow_bolt,cycle_targets=1,if=talent.shadow_embrace.enabled&variable.maintain_se&!debuff.shadow_embrace.remains&!action.shadow_bolt.in_flight
   if hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) and not inflighttotarget(shadow_bolt_affliction) spell(shadow_bolt_affliction)
   #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se
   if hastalent(shadow_embrace_talent) and maintain_se() spell(shadow_bolt_affliction)
   #shadow_bolt
   spell(shadow_bolt_affliction)
  }
 }
}

AddFunction afflictionfillersmainpostconditions
{
 hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshmainpostconditions() or hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshmainpostconditions()
}

AddFunction afflictionfillersshortcdactions
{
 unless timesincepreviousspell(unstable_affliction) > 15 and spellcooldown(deathbolt) <= gcd() * 2 and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) > 20 and spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 afflictiondb_refreshshortcdactions()

  unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshshortcdpostconditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } afflictiondb_refreshshortcdactions()

   unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshshortcdpostconditions()
   {
    #deathbolt,if=cooldown.summon_darkglare.remains>=30+gcd|cooldown.summon_darkglare.remains>140
    if spellcooldown(summon_darkglare) >= 30 + gcd() or spellcooldown(summon_darkglare) > 140 spell(deathbolt)

    unless speed() > 0 and buffpresent(nightfall_buff) and spell(shadow_bolt_affliction) or speed() > 0 and not { hastalent(siphon_life_talent) and previousgcdspell(agony) and previousgcdspell(agony count=2) and previousgcdspell(agony count=3) or previousgcdspell(agony) } and spell(agony) or speed() > 0 and not { previousgcdspell(siphon_life) and previousgcdspell(siphon_life count=2) and previousgcdspell(siphon_life count=3) } and spell(siphon_life) or speed() > 0 and not previousgcdspell(corruption) and not hastalent(absolute_corruption_talent) and spell(corruption) or buffstacks(inevitable_demise_buff) > 10 and target.timetodie() <= 10 and spell(drain_life) or hastalent(siphon_life_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(siphon_life_debuff) > gcd() or not hastalent(siphon_life_talent) } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(writhe_in_agony_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 3 } - 5 * { enemies() - false(raid_events_invulnerable_up) == 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(absolute_corruption_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 4 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or spell(haunt)
    {
     #purifying_blast
     spell(purifying_blast)
    }
   }
  }
 }
}

AddFunction afflictionfillersshortcdpostconditions
{
 timesincepreviousspell(unstable_affliction) > 15 and spellcooldown(deathbolt) <= gcd() * 2 and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) > 20 and spell(unstable_affliction) or hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshshortcdpostconditions() or hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshshortcdpostconditions() or speed() > 0 and buffpresent(nightfall_buff) and spell(shadow_bolt_affliction) or speed() > 0 and not { hastalent(siphon_life_talent) and previousgcdspell(agony) and previousgcdspell(agony count=2) and previousgcdspell(agony count=3) or previousgcdspell(agony) } and spell(agony) or speed() > 0 and not { previousgcdspell(siphon_life) and previousgcdspell(siphon_life count=2) and previousgcdspell(siphon_life count=3) } and spell(siphon_life) or speed() > 0 and not previousgcdspell(corruption) and not hastalent(absolute_corruption_talent) and spell(corruption) or buffstacks(inevitable_demise_buff) > 10 and target.timetodie() <= 10 and spell(drain_life) or hastalent(siphon_life_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(siphon_life_debuff) > gcd() or not hastalent(siphon_life_talent) } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(writhe_in_agony_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 3 } - 5 * { enemies() - false(raid_events_invulnerable_up) == 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(absolute_corruption_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 4 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or spell(haunt) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or target.timetodie() <= gcd() and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and spell(drain_soul) or spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and spell(shadow_bolt_affliction) or spell(shadow_bolt_affliction)
}

AddFunction afflictionfillerscdactions
{
 unless timesincepreviousspell(unstable_affliction) > 15 and spellcooldown(deathbolt) <= gcd() * 2 and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) > 20 and spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 afflictiondb_refreshcdactions()

  unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshcdpostconditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } afflictiondb_refreshcdactions()

   unless hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshcdpostconditions() or { spellcooldown(summon_darkglare) >= 30 + gcd() or spellcooldown(summon_darkglare) > 140 } and spell(deathbolt) or speed() > 0 and buffpresent(nightfall_buff) and spell(shadow_bolt_affliction) or speed() > 0 and not { hastalent(siphon_life_talent) and previousgcdspell(agony) and previousgcdspell(agony count=2) and previousgcdspell(agony count=3) or previousgcdspell(agony) } and spell(agony) or speed() > 0 and not { previousgcdspell(siphon_life) and previousgcdspell(siphon_life count=2) and previousgcdspell(siphon_life count=3) } and spell(siphon_life) or speed() > 0 and not previousgcdspell(corruption) and not hastalent(absolute_corruption_talent) and spell(corruption) or buffstacks(inevitable_demise_buff) > 10 and target.timetodie() <= 10 and spell(drain_life) or hastalent(siphon_life_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(siphon_life_debuff) > gcd() or not hastalent(siphon_life_talent) } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(writhe_in_agony_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 3 } - 5 * { enemies() - false(raid_events_invulnerable_up) == 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(absolute_corruption_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 4 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or spell(haunt)
   {
    #focused_azerite_beam
    spell(focused_azerite_beam)
   }
  }
 }
}

AddFunction afflictionfillerscdpostconditions
{
 timesincepreviousspell(unstable_affliction) > 15 and spellcooldown(deathbolt) <= gcd() * 2 and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) > 20 and spell(unstable_affliction) or hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 0.75 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 0.75 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 0.75 } and spellcooldown(deathbolt) <= gcd() * 4 and spellcooldown(summon_darkglare) > 20 and afflictiondb_refreshcdpostconditions() or hastalent(deathbolt_talent) and enemies() == 1 + false(raid_events_invulnerable_up) and spellcooldown(summon_darkglare) <= soulshards() * gcd() + gcd() * 3 and { target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1 or target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1 or target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1 } and afflictiondb_refreshcdpostconditions() or { spellcooldown(summon_darkglare) >= 30 + gcd() or spellcooldown(summon_darkglare) > 140 } and spell(deathbolt) or speed() > 0 and buffpresent(nightfall_buff) and spell(shadow_bolt_affliction) or speed() > 0 and not { hastalent(siphon_life_talent) and previousgcdspell(agony) and previousgcdspell(agony count=2) and previousgcdspell(agony count=3) or previousgcdspell(agony) } and spell(agony) or speed() > 0 and not { previousgcdspell(siphon_life) and previousgcdspell(siphon_life count=2) and previousgcdspell(siphon_life count=3) } and spell(siphon_life) or speed() > 0 and not previousgcdspell(corruption) and not hastalent(absolute_corruption_talent) and spell(corruption) or buffstacks(inevitable_demise_buff) > 10 and target.timetodie() <= 10 and spell(drain_life) or hastalent(siphon_life_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(siphon_life_debuff) > gcd() or not hastalent(siphon_life_talent) } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(writhe_in_agony_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 3 } - 5 * { enemies() - false(raid_events_invulnerable_up) == 2 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and target.debuffremaining(corruption_debuff) > gcd() and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or hastalent(absolute_corruption_talent) and buffstacks(inevitable_demise_buff) >= 50 - 20 * { enemies() - false(raid_events_invulnerable_up) >= 4 } and target.debuffremaining(agony_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and { target.debuffremaining(haunt_debuff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } or not hastalent(haunt_talent) } and buffremaining(unstable_affliction_buff) > 5 * { 100 / { 100 + spellcastspeedpercent() } } and spell(drain_life) or spell(haunt) or spell(purifying_blast) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or target.timetodie() <= gcd() and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and spell(drain_soul) or spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and not target.debuffpresent(shadow_embrace_debuff) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and spell(shadow_bolt_affliction) or spell(shadow_bolt_affliction)
}

### actions.dots

AddFunction afflictiondotsmainactions
{
 #seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight
 if target.debuffremaining(corruption_debuff) <= casttime(seed_of_corruption) + timetoshard() + 4.2 * { 1 - talentpoints(creeping_death_talent) * 0.15 } and enemies() >= 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and not target.debuffremaining(seed_of_corruption_debuff) and not inflighttotarget(seed_of_corruption) spell(seed_of_corruption)
 #agony,target_if=min:remains,if=talent.creeping_death.enabled&active_dot.agony<6&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 6 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } spell(agony)
 #agony,target_if=min:remains,if=!talent.creeping_death.enabled&active_dot.agony<8&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if not hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 8 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } spell(agony)
 #siphon_life,target_if=min:remains,if=(active_dot.siphon_life<8-talent.creeping_death.enabled-spell_targets.sow_the_seeds_aoe)&target.time_to_die>10&refreshable&(!remains&spell_targets.seed_of_corruption_aoe=1|cooldown.summon_darkglare.remains>soul_shard*action.unstable_affliction.execute_time)
 if debuffcountonany(siphon_life_debuff) < 8 - talentpoints(creeping_death_talent) - enemies() and target.timetodie() > 10 and target.refreshable(siphon_life_debuff) and { not target.debuffremaining(siphon_life_debuff) and enemies() == 1 or spellcooldown(summon_darkglare) > soulshards() * executetime(unstable_affliction) } spell(siphon_life)
 #corruption,cycle_targets=1,if=spell_targets.seed_of_corruption_aoe<3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)&target.time_to_die>10
 if enemies() < 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and { target.debuffremaining(corruption_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and target.refreshable(corruption_debuff) } and target.timetodie() > 10 spell(corruption)
}

AddFunction afflictiondotsmainpostconditions
{
}

AddFunction afflictiondotsshortcdactions
{
}

AddFunction afflictiondotsshortcdpostconditions
{
 target.debuffremaining(corruption_debuff) <= casttime(seed_of_corruption) + timetoshard() + 4.2 * { 1 - talentpoints(creeping_death_talent) * 0.15 } and enemies() >= 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and not target.debuffremaining(seed_of_corruption_debuff) and not inflighttotarget(seed_of_corruption) and spell(seed_of_corruption) or hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 6 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } and spell(agony) or not hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 8 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } and spell(agony) or debuffcountonany(siphon_life_debuff) < 8 - talentpoints(creeping_death_talent) - enemies() and target.timetodie() > 10 and target.refreshable(siphon_life_debuff) and { not target.debuffremaining(siphon_life_debuff) and enemies() == 1 or spellcooldown(summon_darkglare) > soulshards() * executetime(unstable_affliction) } and spell(siphon_life) or enemies() < 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and { target.debuffremaining(corruption_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and target.refreshable(corruption_debuff) } and target.timetodie() > 10 and spell(corruption)
}

AddFunction afflictiondotscdactions
{
}

AddFunction afflictiondotscdpostconditions
{
 target.debuffremaining(corruption_debuff) <= casttime(seed_of_corruption) + timetoshard() + 4.2 * { 1 - talentpoints(creeping_death_talent) * 0.15 } and enemies() >= 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and not target.debuffremaining(seed_of_corruption_debuff) and not inflighttotarget(seed_of_corruption) and spell(seed_of_corruption) or hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 6 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } and spell(agony) or not hastalent(creeping_death_talent) and debuffcountonany(agony_debuff) < 8 and target.timetodie() > 10 and { target.debuffremaining(agony_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and { target.debuffremaining(agony_debuff) < 5 or not azeritetraitrank(pandemic_invocation_trait) and target.refreshable(agony_debuff) } } and spell(agony) or debuffcountonany(siphon_life_debuff) < 8 - talentpoints(creeping_death_talent) - enemies() and target.timetodie() > 10 and target.refreshable(siphon_life_debuff) and { not target.debuffremaining(siphon_life_debuff) and enemies() == 1 or spellcooldown(summon_darkglare) > soulshards() * executetime(unstable_affliction) } and spell(siphon_life) or enemies() < 3 + false(raid_events_invulnerable_up) + talentpoints(writhe_in_agony_talent) and { target.debuffremaining(corruption_debuff) <= gcd() or spellcooldown(summon_darkglare) > 10 and target.refreshable(corruption_debuff) } and target.timetodie() > 10 and spell(corruption)
}

### actions.db_refresh

AddFunction afflictiondb_refreshmainactions
{
 #siphon_life,line_cd=15,if=(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.corruption.remains%dot.corruption.duration)&dot.siphon_life.remains<dot.siphon_life.duration*1.3
 if timesincepreviousspell(siphon_life) > 15 and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1.3 spell(siphon_life)
 #agony,line_cd=15,if=(dot.agony.remains%dot.agony.duration)<=(dot.corruption.remains%dot.corruption.duration)&(dot.agony.remains%dot.agony.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.agony.remains<dot.agony.duration*1.3
 if timesincepreviousspell(agony) > 15 and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1.3 spell(agony)
 #corruption,line_cd=15,if=(dot.corruption.remains%dot.corruption.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.corruption.remains%dot.corruption.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.corruption.remains<dot.corruption.duration*1.3
 if timesincepreviousspell(corruption) > 15 and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1.3 spell(corruption)
}

AddFunction afflictiondb_refreshmainpostconditions
{
}

AddFunction afflictiondb_refreshshortcdactions
{
}

AddFunction afflictiondb_refreshshortcdpostconditions
{
 timesincepreviousspell(siphon_life) > 15 and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1.3 and spell(siphon_life) or timesincepreviousspell(agony) > 15 and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1.3 and spell(agony) or timesincepreviousspell(corruption) > 15 and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1.3 and spell(corruption)
}

AddFunction afflictiondb_refreshcdactions
{
}

AddFunction afflictiondb_refreshcdpostconditions
{
 timesincepreviousspell(siphon_life) > 15 and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(siphon_life_debuff) < target.debuffduration(siphon_life_debuff) * 1.3 and spell(siphon_life) or timesincepreviousspell(agony) > 15 and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) and target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(agony_debuff) < target.debuffduration(agony_debuff) * 1.3 and spell(agony) or timesincepreviousspell(corruption) > 15 and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(agony_debuff) / target.debuffduration(agony_debuff) and target.debuffremaining(corruption_debuff) / target.debuffduration(corruption_debuff) <= target.debuffremaining(siphon_life_debuff) / target.debuffduration(siphon_life_debuff) and target.debuffremaining(corruption_debuff) < target.debuffduration(corruption_debuff) * 1.3 and spell(corruption)
}

### actions.cooldowns

AddFunction afflictioncooldownsmainactions
{
}

AddFunction afflictioncooldownsmainpostconditions
{
}

AddFunction afflictioncooldownsshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
 #ripple_in_space
 spell(ripple_in_space_essence)
}

AddFunction afflictioncooldownsshortcdpostconditions
{
}

AddFunction afflictioncooldownscdactions
{
 #use_item,name=azsharas_font_of_power,if=(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains<4*spell_haste|!cooldown.phantom_singularity.remains)&cooldown.summon_darkglare.remains<19*spell_haste+soul_shard*azerite.dreadful_calling.rank&dot.agony.remains&dot.corruption.remains&(dot.siphon_life.remains|!talent.siphon_life.enabled)
 if { not hastalent(phantom_singularity_talent) or spellcooldown(phantom_singularity) < 4 * { 100 / { 100 + spellcastspeedpercent() } } or not spellcooldown(phantom_singularity) > 0 } and spellcooldown(summon_darkglare) < 19 * { 100 / { 100 + spellcastspeedpercent() } } + soulshards() * azeritetraitrank(dreadful_calling_trait) and target.debuffremaining(agony_debuff) and target.debuffremaining(corruption_debuff) and { target.debuffremaining(siphon_life_debuff) or not hastalent(siphon_life_talent) } afflictionuseitemactions()
 #potion,if=(talent.dark_soul_misery.enabled&cooldown.summon_darkglare.up&cooldown.dark_soul.up)|cooldown.summon_darkglare.up|target.time_to_die<30
 if { hastalent(dark_soul_misery_talent) and not spellcooldown(summon_darkglare) > 0 and not spellcooldown(dark_soul_misery) > 0 or not spellcooldown(summon_darkglare) > 0 or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_items,if=cooldown.summon_darkglare.remains>70|time_to_die<20|((buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains)&!cooldown.summon_darkglare.remains)
 if spellcooldown(summon_darkglare) > 70 or target.timetodie() < 20 or { target.debuffstacks(unstable_affliction_debuff) == 5 or soulshards() == 0 } and { not hastalent(phantom_singularity_talent) or spellcooldown(phantom_singularity) > 0 } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= gcd() or not spellcooldown(deathbolt) > 0 } and not spellcooldown(summon_darkglare) > 0 afflictionuseitemactions()
 #fireblood,if=!cooldown.summon_darkglare.up
 if not { not spellcooldown(summon_darkglare) > 0 } spell(fireblood)
 #blood_fury,if=!cooldown.summon_darkglare.up
 if not { not spellcooldown(summon_darkglare) > 0 } spell(blood_fury_sp)
 #memory_of_lucid_dreams,if=time>30
 if timeincombat() > 30 spell(memory_of_lucid_dreams_essence)
 #dark_soul,if=target.time_to_die<20+gcd|talent.sow_the_seeds.enabled&cooldown.summon_darkglare.remains>=cooldown.summon_darkglare.duration-10
 if target.timetodie() < 20 + gcd() or hastalent(sow_the_seeds_talent) and spellcooldown(summon_darkglare) >= spellcooldownduration(summon_darkglare) - 10 spell(dark_soul_misery)
 #blood_of_the_enemy,if=pet.darkglare.remains|(!cooldown.deathbolt.remains|!talent.deathbolt.enabled)&cooldown.summon_darkglare.remains>=80&essence.blood_of_the_enemy.rank>1
 if demonduration(darkglare) or { not spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } and spellcooldown(summon_darkglare) >= 80 and azeriteessencerank(blood_of_the_enemy_essence_id) > 1 spell(blood_of_the_enemy)
 #use_item,name=pocketsized_computation_device,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
 #use_item,name=rotcrusted_voodoo_doll,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
 #use_item,name=shiver_venom_relic,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
 #use_item,name=aquipotent_nautilus,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
 #use_item,name=tidestorm_codex,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
 #use_item,name=vial_of_storms,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { spellcooldown(summon_darkglare) >= 25 or target.timetodie() <= 30 } and { spellcooldown(deathbolt) > 0 or not hastalent(deathbolt_talent) } afflictionuseitemactions()
}

AddFunction afflictioncooldownscdpostconditions
{
 spell(worldvein_resonance_essence) or spell(ripple_in_space_essence)
}

### actions.default

AddFunction affliction_defaultmainactions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 afflictioncooldownsmainactions()

 unless afflictioncooldownsmainpostconditions()
 {
  #drain_soul,interrupt_global=1,chain=1,cycle_targets=1,if=target.time_to_die<=gcd&soul_shard<5
  if target.timetodie() <= gcd() and soulshards() < 5 spell(drain_soul)
  #haunt,if=spell_targets.seed_of_corruption_aoe<=2+raid_event.invulnerable.up
  if enemies() <= 2 + false(raid_events_invulnerable_up) spell(haunt)
  #agony,target_if=min:dot.agony.remains,if=remains<=gcd+action.shadow_bolt.execute_time&target.time_to_die>8
  if target.debuffremaining(agony_debuff) <= gcd() + executetime(shadow_bolt_affliction) and target.timetodie() > 8 spell(agony)
  #agony,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.169314
  if timesincepreviousspell(agony) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) spell(agony)
  #corruption,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.169314&!talent.absolute_corruption.enabled&(talent.siphon_life.enabled|spell_targets.seed_of_corruption_aoe>1&spell_targets.seed_of_corruption_aoe<=3)
  if timesincepreviousspell(corruption) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and not hastalent(absolute_corruption_talent) and { hastalent(siphon_life_talent) or enemies() > 1 and enemies() <= 3 } spell(corruption)
  #siphon_life,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.169314
  if timesincepreviousspell(siphon_life) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) spell(siphon_life)
  #unstable_affliction,target_if=!contagion&target.time_to_die<=8
  if not buffremaining(unstable_affliction_buff) and target.timetodie() <= 8 spell(unstable_affliction)
  #drain_soul,target_if=min:debuff.shadow_embrace.remains,cancel_if=ticks_remain<5,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=gcd*2
  if hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= gcd() * 2 spell(drain_soul)
  #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=execute_time*2+travel_time&!action.shadow_bolt.in_flight
  if hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= executetime(shadow_bolt_affliction) * 2 + traveltime(shadow_bolt_affliction) and not inflighttotarget(shadow_bolt_affliction) spell(shadow_bolt_affliction)
  #unstable_affliction,target_if=min:contagion,if=!variable.use_seed&soul_shard=5
  if not use_seed() and soulshards() == 5 spell(unstable_affliction)
  #seed_of_corruption,if=variable.use_seed&soul_shard=5
  if use_seed() and soulshards() == 5 spell(seed_of_corruption)
  #call_action_list,name=dots
  afflictiondotsmainactions()

  unless afflictiondotsmainpostconditions()
  {
   #vile_taint,target_if=max:target.time_to_die,if=time>15&target.time_to_die>=10&(cooldown.summon_darkglare.remains>30|cooldown.summon_darkglare.remains<10&dot.agony.remains>=10&dot.corruption.remains>=10&(dot.siphon_life.remains>=10|!talent.siphon_life.enabled))
   if timeincombat() > 15 and target.timetodie() >= 10 and { spellcooldown(summon_darkglare) > 30 or spellcooldown(summon_darkglare) < 10 and target.debuffremaining(agony_debuff) >= 10 and target.debuffremaining(corruption_debuff) >= 10 and { target.debuffremaining(siphon_life_debuff) >= 10 or not hastalent(siphon_life_talent) } } spell(vile_taint)
   #vile_taint,if=time<15
   if timeincombat() < 15 spell(vile_taint)
   #call_action_list,name=spenders
   afflictionspendersmainactions()

   unless afflictionspendersmainpostconditions()
   {
    #call_action_list,name=fillers
    afflictionfillersmainactions()
   }
  }
 }
}

AddFunction affliction_defaultmainpostconditions
{
 afflictioncooldownsmainpostconditions() or afflictiondotsmainpostconditions() or afflictionspendersmainpostconditions() or afflictionfillersmainpostconditions()
}

AddFunction affliction_defaultshortcdactions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 afflictioncooldownsshortcdactions()

 unless afflictioncooldownsshortcdpostconditions() or target.timetodie() <= gcd() and soulshards() < 5 and spell(drain_soul) or enemies() <= 2 + false(raid_events_invulnerable_up) and spell(haunt)
 {
  #deathbolt,if=cooldown.summon_darkglare.remains&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(!essence.vision_of_perfection.minor&!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>30)
  if spellcooldown(summon_darkglare) > 0 and enemies() == 1 + false(raid_events_invulnerable_up) and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 30 } spell(deathbolt)
  #the_unbound_force,if=buff.reckless_force.remains
  if buffpresent(reckless_force_buff) spell(the_unbound_force)

  unless target.debuffremaining(agony_debuff) <= gcd() + executetime(shadow_bolt_affliction) and target.timetodie() > 8 and spell(agony) or timesincepreviousspell(agony) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(agony) or timesincepreviousspell(corruption) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and not hastalent(absolute_corruption_talent) and { hastalent(siphon_life_talent) or enemies() > 1 and enemies() <= 3 } and spell(corruption) or timesincepreviousspell(siphon_life) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(siphon_life) or not buffremaining(unstable_affliction_buff) and target.timetodie() <= 8 and spell(unstable_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= gcd() * 2 and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= executetime(shadow_bolt_affliction) * 2 + traveltime(shadow_bolt_affliction) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction)
  {
   #phantom_singularity,target_if=max:target.time_to_die,if=time>35&target.time_to_die>16*spell_haste&(!essence.vision_of_perfection.minor&!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>45+soul_shard*azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains<15*spell_haste+soul_shard*azerite.dreadful_calling.rank)
   if timeincombat() > 35 and target.timetodie() > 16 * { 100 / { 100 + spellcastspeedpercent() } } and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 45 + soulshards() * azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) < 15 * { 100 / { 100 + spellcastspeedpercent() } } + soulshards() * azeritetraitrank(dreadful_calling_trait) } spell(phantom_singularity)

   unless not use_seed() and soulshards() == 5 and spell(unstable_affliction) or use_seed() and soulshards() == 5 and spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    afflictiondotsshortcdactions()

    unless afflictiondotsshortcdpostconditions() or timeincombat() > 15 and target.timetodie() >= 10 and { spellcooldown(summon_darkglare) > 30 or spellcooldown(summon_darkglare) < 10 and target.debuffremaining(agony_debuff) >= 10 and target.debuffremaining(corruption_debuff) >= 10 and { target.debuffremaining(siphon_life_debuff) >= 10 or not hastalent(siphon_life_talent) } } and spell(vile_taint)
    {
     #phantom_singularity,if=time<=35
     if timeincombat() <= 35 spell(phantom_singularity)

     unless timeincombat() < 15 and spell(vile_taint)
     {
      #call_action_list,name=spenders
      afflictionspendersshortcdactions()

      unless afflictionspendersshortcdpostconditions()
      {
       #call_action_list,name=fillers
       afflictionfillersshortcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction affliction_defaultshortcdpostconditions
{
 afflictioncooldownsshortcdpostconditions() or target.timetodie() <= gcd() and soulshards() < 5 and spell(drain_soul) or enemies() <= 2 + false(raid_events_invulnerable_up) and spell(haunt) or target.debuffremaining(agony_debuff) <= gcd() + executetime(shadow_bolt_affliction) and target.timetodie() > 8 and spell(agony) or timesincepreviousspell(agony) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(agony) or timesincepreviousspell(corruption) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and not hastalent(absolute_corruption_talent) and { hastalent(siphon_life_talent) or enemies() > 1 and enemies() <= 3 } and spell(corruption) or timesincepreviousspell(siphon_life) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(siphon_life) or not buffremaining(unstable_affliction_buff) and target.timetodie() <= 8 and spell(unstable_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= gcd() * 2 and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= executetime(shadow_bolt_affliction) * 2 + traveltime(shadow_bolt_affliction) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction) or not use_seed() and soulshards() == 5 and spell(unstable_affliction) or use_seed() and soulshards() == 5 and spell(seed_of_corruption) or afflictiondotsshortcdpostconditions() or timeincombat() > 15 and target.timetodie() >= 10 and { spellcooldown(summon_darkglare) > 30 or spellcooldown(summon_darkglare) < 10 and target.debuffremaining(agony_debuff) >= 10 and target.debuffremaining(corruption_debuff) >= 10 and { target.debuffremaining(siphon_life_debuff) >= 10 or not hastalent(siphon_life_talent) } } and spell(vile_taint) or timeincombat() < 15 and spell(vile_taint) or afflictionspendersshortcdpostconditions() or afflictionfillersshortcdpostconditions()
}

AddFunction affliction_defaultcdactions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 afflictioncooldownscdactions()

 unless afflictioncooldownscdpostconditions() or target.timetodie() <= gcd() and soulshards() < 5 and spell(drain_soul) or enemies() <= 2 + false(raid_events_invulnerable_up) and spell(haunt)
 {
  #summon_darkglare,if=summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0|dot.phantom_singularity.remains&dot.phantom_singularity.remains<=gcd)&(!talent.phantom_singularity.enabled|dot.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up)
  if target.debuffpresent(agony_debuff) and target.debuffpresent(corruption_debuff) and { target.debuffstacks(unstable_affliction_debuff) == 5 or soulshards() == 0 or target.debuffremaining(phantom_singularity) and target.debuffremaining(phantom_singularity) <= gcd() } and { not hastalent(phantom_singularity_talent) or target.debuffremaining(phantom_singularity) } and { not hastalent(deathbolt_talent) or spellcooldown(deathbolt) <= gcd() or not spellcooldown(deathbolt) > 0 or enemies() > 1 + false(raid_events_invulnerable_up) } spell(summon_darkglare)

  unless spellcooldown(summon_darkglare) > 0 and enemies() == 1 + false(raid_events_invulnerable_up) and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 30 } and spell(deathbolt) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or target.debuffremaining(agony_debuff) <= gcd() + executetime(shadow_bolt_affliction) and target.timetodie() > 8 and spell(agony)
  {
   #memory_of_lucid_dreams,if=time<30
   if timeincombat() < 30 spell(memory_of_lucid_dreams_essence)

   unless timesincepreviousspell(agony) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(agony) or timesincepreviousspell(corruption) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and not hastalent(absolute_corruption_talent) and { hastalent(siphon_life_talent) or enemies() > 1 and enemies() <= 3 } and spell(corruption) or timesincepreviousspell(siphon_life) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(siphon_life) or not buffremaining(unstable_affliction_buff) and target.timetodie() <= 8 and spell(unstable_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= gcd() * 2 and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= executetime(shadow_bolt_affliction) * 2 + traveltime(shadow_bolt_affliction) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction) or timeincombat() > 35 and target.timetodie() > 16 * { 100 / { 100 + spellcastspeedpercent() } } and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 45 + soulshards() * azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) < 15 * { 100 / { 100 + spellcastspeedpercent() } } + soulshards() * azeritetraitrank(dreadful_calling_trait) } and spell(phantom_singularity) or not use_seed() and soulshards() == 5 and spell(unstable_affliction) or use_seed() and soulshards() == 5 and spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    afflictiondotscdactions()

    unless afflictiondotscdpostconditions() or timeincombat() > 15 and target.timetodie() >= 10 and { spellcooldown(summon_darkglare) > 30 or spellcooldown(summon_darkglare) < 10 and target.debuffremaining(agony_debuff) >= 10 and target.debuffremaining(corruption_debuff) >= 10 and { target.debuffremaining(siphon_life_debuff) >= 10 or not hastalent(siphon_life_talent) } } and spell(vile_taint)
    {
     #use_item,name=azsharas_font_of_power,if=time<=3
     if timeincombat() <= 3 afflictionuseitemactions()

     unless timeincombat() <= 35 and spell(phantom_singularity) or timeincombat() < 15 and spell(vile_taint)
     {
      #guardian_of_azeroth,if=(cooldown.summon_darkglare.remains<15+soul_shard*azerite.dreadful_calling.enabled|(azerite.dreadful_calling.rank|essence.vision_of_perfection.rank)&time>30&target.time_to_die>=210)&(dot.phantom_singularity.remains|dot.vile_taint.remains|!talent.phantom_singularity.enabled&!talent.vile_taint.enabled)|target.time_to_die<30+gcd
      if { spellcooldown(summon_darkglare) < 15 + soulshards() * hasazeritetrait(dreadful_calling_trait) or { azeritetraitrank(dreadful_calling_trait) or azeriteessencerank(vision_of_perfection_essence_id) } and timeincombat() > 30 and target.timetodie() >= 210 } and { target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) or not hastalent(phantom_singularity_talent) and not hastalent(vile_taint_talent) } or target.timetodie() < 30 + gcd() spell(guardian_of_azeroth)
      #dark_soul,if=cooldown.summon_darkglare.remains<15+soul_shard*azerite.dreadful_calling.enabled&(dot.phantom_singularity.remains|dot.vile_taint.remains)
      if spellcooldown(summon_darkglare) < 15 + soulshards() * hasazeritetrait(dreadful_calling_trait) and { target.debuffremaining(phantom_singularity) or target.debuffremaining(vile_taint_debuff) } spell(dark_soul_misery)
      #berserking
      spell(berserking)
      #call_action_list,name=spenders
      afflictionspenderscdactions()

      unless afflictionspenderscdpostconditions()
      {
       #call_action_list,name=fillers
       afflictionfillerscdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction affliction_defaultcdpostconditions
{
 afflictioncooldownscdpostconditions() or target.timetodie() <= gcd() and soulshards() < 5 and spell(drain_soul) or enemies() <= 2 + false(raid_events_invulnerable_up) and spell(haunt) or spellcooldown(summon_darkglare) > 0 and enemies() == 1 + false(raid_events_invulnerable_up) and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 30 } and spell(deathbolt) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or target.debuffremaining(agony_debuff) <= gcd() + executetime(shadow_bolt_affliction) and target.timetodie() > 8 and spell(agony) or timesincepreviousspell(agony) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(agony) or timesincepreviousspell(corruption) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and not hastalent(absolute_corruption_talent) and { hastalent(siphon_life_talent) or enemies() > 1 and enemies() <= 3 } and spell(corruption) or timesincepreviousspell(siphon_life) > 30 and timeincombat() > 30 and spellcooldown(summon_darkglare) <= 15 and hasequippeditem(169314) and spell(siphon_life) or not buffremaining(unstable_affliction_buff) and target.timetodie() <= 8 and spell(unstable_affliction) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= gcd() * 2 and spell(drain_soul) or hastalent(shadow_embrace_talent) and maintain_se() and target.debuffpresent(shadow_embrace_debuff) and target.debuffremaining(shadow_embrace_debuff) <= executetime(shadow_bolt_affliction) * 2 + traveltime(shadow_bolt_affliction) and not inflighttotarget(shadow_bolt_affliction) and spell(shadow_bolt_affliction) or timeincombat() > 35 and target.timetodie() > 16 * { 100 / { 100 + spellcastspeedpercent() } } and { not azeriteessenceisminor(vision_of_perfection_essence_id) and not azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) > 45 + soulshards() * azeritetraitrank(dreadful_calling_trait) or spellcooldown(summon_darkglare) < 15 * { 100 / { 100 + spellcastspeedpercent() } } + soulshards() * azeritetraitrank(dreadful_calling_trait) } and spell(phantom_singularity) or not use_seed() and soulshards() == 5 and spell(unstable_affliction) or use_seed() and soulshards() == 5 and spell(seed_of_corruption) or afflictiondotscdpostconditions() or timeincombat() > 15 and target.timetodie() >= 10 and { spellcooldown(summon_darkglare) > 30 or spellcooldown(summon_darkglare) < 10 and target.debuffremaining(agony_debuff) >= 10 and target.debuffremaining(corruption_debuff) >= 10 and { target.debuffremaining(siphon_life_debuff) >= 10 or not hastalent(siphon_life_talent) } } and spell(vile_taint) or timeincombat() <= 35 and spell(phantom_singularity) or timeincombat() < 15 and spell(vile_taint) or afflictionspenderscdpostconditions() or afflictionfillerscdpostconditions()
}

### Affliction icons.

AddCheckBox(opt_warlock_affliction_aoe l(aoe) default specialization=affliction)

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=shortcd specialization=affliction
{
 if not incombat() afflictionprecombatshortcdactions()
 unless not incombat() and afflictionprecombatshortcdpostconditions()
 {
  affliction_defaultshortcdactions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=shortcd specialization=affliction
{
 if not incombat() afflictionprecombatshortcdactions()
 unless not incombat() and afflictionprecombatshortcdpostconditions()
 {
  affliction_defaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=affliction
{
 if not incombat() afflictionprecombatmainactions()
 unless not incombat() and afflictionprecombatmainpostconditions()
 {
  affliction_defaultmainactions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=aoe specialization=affliction
{
 if not incombat() afflictionprecombatmainactions()
 unless not incombat() and afflictionprecombatmainpostconditions()
 {
  affliction_defaultmainactions()
 }
}

AddIcon checkbox=!opt_warlock_affliction_aoe enemies=1 help=cd specialization=affliction
{
 if not incombat() afflictionprecombatcdactions()
 unless not incombat() and afflictionprecombatcdpostconditions()
 {
  affliction_defaultcdactions()
 }
}

AddIcon checkbox=opt_warlock_affliction_aoe help=cd specialization=affliction
{
 if not incombat() afflictionprecombatcdactions()
 unless not incombat() and afflictionprecombatcdpostconditions()
 {
  affliction_defaultcdactions()
 }
}

### Required symbols
# 169314
# absolute_corruption_talent
# agony
# agony_debuff
# berserking
# blood_fury_sp
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
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
# haunt_debuff
# haunt_talent
# inevitable_demise_buff
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
# unbridled_fury_item
# unstable_affliction
# vile_taint
# vile_taint_debuff
# vile_taint_talent
# vision_of_perfection_essence_id
# worldvein_resonance_essence
# writhe_in_agony_talent
]]
        OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
    end
    do
        local name = "sc_t24_warlock_demonology"
        local desc = "[8.3] Simulationcraft: T24_Warlock_Demonology"
        local code = [[
# Based on SimulationCraft profile "T24_Warlock_Demonology".
#	class=warlock
#	spec=demonology
#	talents=2303032
#	pet=felguard

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=demonology)

AddFunction demonologyuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction demonologyprecombatmainactions
{
 #inner_demons,if=talent.inner_demons.enabled
 if hastalent(inner_demons_talent) spell(inner_demons)
 #demonbolt
 spell(demonbolt)
}

AddFunction demonologyprecombatmainpostconditions
{
}

AddFunction demonologyprecombatshortcdactions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.present() spell(summon_felguard)
}

AddFunction demonologyprecombatshortcdpostconditions
{
 hastalent(inner_demons_talent) and spell(inner_demons) or spell(demonbolt)
}

AddFunction demonologyprecombatcdactions
{
 unless not pet.present() and spell(summon_felguard) or hastalent(inner_demons_talent) and spell(inner_demons)
 {
  #snapshot_stats
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction demonologyprecombatcdpostconditions
{
 not pet.present() and spell(summon_felguard) or hastalent(inner_demons_talent) and spell(inner_demons) or spell(demonbolt)
}

### actions.opener

AddFunction demonologyopenermainactions
{
 #hand_of_guldan,line_cd=30,if=azerite.explosive_potential.enabled
 if timesincepreviousspell(hand_of_guldan) > 30 and hasazeritetrait(explosive_potential_trait) spell(hand_of_guldan)
 #implosion,if=azerite.explosive_potential.enabled&buff.wild_imps.stack>2&buff.explosive_potential.down
 if hasazeritetrait(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffexpires(explosive_potential) spell(implosion)
 #doom,line_cd=30
 if timesincepreviousspell(doom) > 30 spell(doom)
 #hand_of_guldan,if=prev_gcd.1.hand_of_guldan&soul_shard>0&prev_gcd.2.soul_strike
 if previousgcdspell(hand_of_guldan) and soulshards() > 0 and previousgcdspell(soul_strike count=2) spell(hand_of_guldan)
 #soul_strike,line_cd=30,if=!buff.bloodlust.remains|time>5&prev_gcd.1.hand_of_guldan
 if timesincepreviousspell(soul_strike) > 30 and { not buffpresent(bloodlust) or timeincombat() > 5 and previousgcdspell(hand_of_guldan) } spell(soul_strike)
 #call_dreadstalkers,if=soul_shard=5
 if soulshards() == 5 spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard=5
 if soulshards() == 5 spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&prev_gcd.2.hand_of_guldan&time>5&(prev_gcd.1.soul_strike|!talent.soul_strike.enabled&prev_gcd.1.shadow_bolt)
 if soulshards() >= 3 and previousgcdspell(hand_of_guldan count=2) and timeincombat() > 5 and { previousgcdspell(soul_strike) or not hastalent(soul_strike_talent) and previousgcdspell(shadow_bolt) } spell(hand_of_guldan)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.remains
 if soulshards() <= 3 and buffpresent(demonic_core_buff) spell(demonbolt)
 #call_action_list,name=build_a_shard
 demonologybuild_a_shardmainactions()
}

AddFunction demonologyopenermainpostconditions
{
 demonologybuild_a_shardmainpostconditions()
}

AddFunction demonologyopenershortcdactions
{
 unless timesincepreviousspell(hand_of_guldan) > 30 and hasazeritetrait(explosive_potential_trait) and spell(hand_of_guldan) or hasazeritetrait(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffexpires(explosive_potential) and spell(implosion) or timesincepreviousspell(doom) > 30 and spell(doom) or previousgcdspell(hand_of_guldan) and soulshards() > 0 and previousgcdspell(soul_strike count=2) and spell(hand_of_guldan)
 {
  #demonic_strength,if=prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&(buff.wild_imps.stack>1&action.hand_of_guldan.in_flight)
  if previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 1 and inflighttotarget(hand_of_guldan) spell(demonic_strength)
  #bilescourge_bombers
  spell(bilescourge_bombers)

  unless timesincepreviousspell(soul_strike) > 30 and { not buffpresent(bloodlust) or timeincombat() > 5 and previousgcdspell(hand_of_guldan) } and spell(soul_strike)
  {
   #summon_vilefiend,if=soul_shard=5
   if soulshards() == 5 spell(summon_vilefiend)

   unless soulshards() == 5 and spell(call_dreadstalkers) or soulshards() == 5 and spell(hand_of_guldan) or soulshards() >= 3 and previousgcdspell(hand_of_guldan count=2) and timeincombat() > 5 and { previousgcdspell(soul_strike) or not hastalent(soul_strike_talent) and previousgcdspell(shadow_bolt) } and spell(hand_of_guldan)
   {
    #summon_demonic_tyrant,if=prev_gcd.1.demonic_strength|prev_gcd.1.hand_of_guldan&prev_gcd.2.hand_of_guldan|!talent.demonic_strength.enabled&buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6
    if previousgcdspell(demonic_strength) or previousgcdspell(hand_of_guldan) and previousgcdspell(hand_of_guldan count=2) or not hastalent(demonic_strength_talent) and demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 spell(summon_demonic_tyrant)

    unless soulshards() <= 3 and buffpresent(demonic_core_buff) and spell(demonbolt)
    {
     #call_action_list,name=build_a_shard
     demonologybuild_a_shardshortcdactions()
    }
   }
  }
 }
}

AddFunction demonologyopenershortcdpostconditions
{
 timesincepreviousspell(hand_of_guldan) > 30 and hasazeritetrait(explosive_potential_trait) and spell(hand_of_guldan) or hasazeritetrait(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffexpires(explosive_potential) and spell(implosion) or timesincepreviousspell(doom) > 30 and spell(doom) or previousgcdspell(hand_of_guldan) and soulshards() > 0 and previousgcdspell(soul_strike count=2) and spell(hand_of_guldan) or timesincepreviousspell(soul_strike) > 30 and { not buffpresent(bloodlust) or timeincombat() > 5 and previousgcdspell(hand_of_guldan) } and spell(soul_strike) or soulshards() == 5 and spell(call_dreadstalkers) or soulshards() == 5 and spell(hand_of_guldan) or soulshards() >= 3 and previousgcdspell(hand_of_guldan count=2) and timeincombat() > 5 and { previousgcdspell(soul_strike) or not hastalent(soul_strike_talent) and previousgcdspell(shadow_bolt) } and spell(hand_of_guldan) or soulshards() <= 3 and buffpresent(demonic_core_buff) and spell(demonbolt) or demonologybuild_a_shardshortcdpostconditions()
}

AddFunction demonologyopenercdactions
{
 unless timesincepreviousspell(hand_of_guldan) > 30 and hasazeritetrait(explosive_potential_trait) and spell(hand_of_guldan) or hasazeritetrait(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffexpires(explosive_potential) and spell(implosion) or timesincepreviousspell(doom) > 30 and spell(doom)
 {
  #guardian_of_azeroth
  spell(guardian_of_azeroth)

  unless previousgcdspell(hand_of_guldan) and soulshards() > 0 and previousgcdspell(soul_strike count=2) and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 1 and inflighttotarget(hand_of_guldan) and spell(demonic_strength) or spell(bilescourge_bombers) or timesincepreviousspell(soul_strike) > 30 and { not buffpresent(bloodlust) or timeincombat() > 5 and previousgcdspell(hand_of_guldan) } and spell(soul_strike) or soulshards() == 5 and spell(summon_vilefiend)
  {
   #grimoire_felguard,if=soul_shard=5
   if soulshards() == 5 spell(grimoire_felguard)

   unless soulshards() == 5 and spell(call_dreadstalkers) or soulshards() == 5 and spell(hand_of_guldan) or soulshards() >= 3 and previousgcdspell(hand_of_guldan count=2) and timeincombat() > 5 and { previousgcdspell(soul_strike) or not hastalent(soul_strike_talent) and previousgcdspell(shadow_bolt) } and spell(hand_of_guldan) or { previousgcdspell(demonic_strength) or previousgcdspell(hand_of_guldan) and previousgcdspell(hand_of_guldan count=2) or not hastalent(demonic_strength_talent) and demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 } and spell(summon_demonic_tyrant) or soulshards() <= 3 and buffpresent(demonic_core_buff) and spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    demonologybuild_a_shardcdactions()
   }
  }
 }
}

AddFunction demonologyopenercdpostconditions
{
 timesincepreviousspell(hand_of_guldan) > 30 and hasazeritetrait(explosive_potential_trait) and spell(hand_of_guldan) or hasazeritetrait(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffexpires(explosive_potential) and spell(implosion) or timesincepreviousspell(doom) > 30 and spell(doom) or previousgcdspell(hand_of_guldan) and soulshards() > 0 and previousgcdspell(soul_strike count=2) and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 1 and inflighttotarget(hand_of_guldan) and spell(demonic_strength) or spell(bilescourge_bombers) or timesincepreviousspell(soul_strike) > 30 and { not buffpresent(bloodlust) or timeincombat() > 5 and previousgcdspell(hand_of_guldan) } and spell(soul_strike) or soulshards() == 5 and spell(summon_vilefiend) or soulshards() == 5 and spell(call_dreadstalkers) or soulshards() == 5 and spell(hand_of_guldan) or soulshards() >= 3 and previousgcdspell(hand_of_guldan count=2) and timeincombat() > 5 and { previousgcdspell(soul_strike) or not hastalent(soul_strike_talent) and previousgcdspell(shadow_bolt) } and spell(hand_of_guldan) or { previousgcdspell(demonic_strength) or previousgcdspell(hand_of_guldan) and previousgcdspell(hand_of_guldan count=2) or not hastalent(demonic_strength_talent) and demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 } and spell(summon_demonic_tyrant) or soulshards() <= 3 and buffpresent(demonic_core_buff) and spell(demonbolt) or demonologybuild_a_shardcdpostconditions()
}

### actions.nether_portal_building

AddFunction demonologynether_portal_buildingmainactions
{
 #call_dreadstalkers,if=time>=30
 if timeincombat() >= 30 spell(call_dreadstalkers)
 #hand_of_guldan,if=time>=30&cooldown.call_dreadstalkers.remains>18&soul_shard>=3
 if timeincombat() >= 30 and spellcooldown(call_dreadstalkers) > 18 and soulshards() >= 3 spell(hand_of_guldan)
 #hand_of_guldan,if=time>=30&soul_shard>=5
 if timeincombat() >= 30 and soulshards() >= 5 spell(hand_of_guldan)
 #call_action_list,name=build_a_shard
 demonologybuild_a_shardmainactions()
}

AddFunction demonologynether_portal_buildingmainpostconditions
{
 demonologybuild_a_shardmainpostconditions()
}

AddFunction demonologynether_portal_buildingshortcdactions
{
 unless timeincombat() >= 30 and spell(call_dreadstalkers) or timeincombat() >= 30 and spellcooldown(call_dreadstalkers) > 18 and soulshards() >= 3 and spell(hand_of_guldan)
 {
  #power_siphon,if=time>=30&buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&soul_shard>=3
  if timeincombat() >= 30 and demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and soulshards() >= 3 spell(power_siphon)

  unless timeincombat() >= 30 and soulshards() >= 5 and spell(hand_of_guldan)
  {
   #call_action_list,name=build_a_shard
   demonologybuild_a_shardshortcdactions()
  }
 }
}

AddFunction demonologynether_portal_buildingshortcdpostconditions
{
 timeincombat() >= 30 and spell(call_dreadstalkers) or timeincombat() >= 30 and spellcooldown(call_dreadstalkers) > 18 and soulshards() >= 3 and spell(hand_of_guldan) or timeincombat() >= 30 and soulshards() >= 5 and spell(hand_of_guldan) or demonologybuild_a_shardshortcdpostconditions()
}

AddFunction demonologynether_portal_buildingcdactions
{
 #use_item,name=azsharas_font_of_power,if=cooldown.nether_portal.remains<=5*spell_haste
 if spellcooldown(nether_portal) <= 5 * { 100 / { 100 + spellcastspeedpercent() } } demonologyuseitemactions()
 #guardian_of_azeroth,if=!cooldown.nether_portal.remains&soul_shard>=5
 if not spellcooldown(nether_portal) > 0 and soulshards() >= 5 spell(guardian_of_azeroth)
 #nether_portal,if=soul_shard>=5
 if soulshards() >= 5 spell(nether_portal)

 unless timeincombat() >= 30 and spell(call_dreadstalkers) or timeincombat() >= 30 and spellcooldown(call_dreadstalkers) > 18 and soulshards() >= 3 and spell(hand_of_guldan) or timeincombat() >= 30 and demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and soulshards() >= 3 and spell(power_siphon) or timeincombat() >= 30 and soulshards() >= 5 and spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  demonologybuild_a_shardcdactions()
 }
}

AddFunction demonologynether_portal_buildingcdpostconditions
{
 timeincombat() >= 30 and spell(call_dreadstalkers) or timeincombat() >= 30 and spellcooldown(call_dreadstalkers) > 18 and soulshards() >= 3 and spell(hand_of_guldan) or timeincombat() >= 30 and demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and soulshards() >= 3 and spell(power_siphon) or timeincombat() >= 30 and soulshards() >= 5 and spell(hand_of_guldan) or demonologybuild_a_shardcdpostconditions()
}

### actions.nether_portal_active

AddFunction demonologynether_portal_activemainactions
{
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 spell(call_dreadstalkers)
 #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
 if soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } demonologybuild_a_shardmainactions()

 unless soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardmainpostconditions()
 {
  #hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(165+action.hand_of_guldan.cast_time)
  if spellcooldown(call_dreadstalkers) > casttime(demonbolt) and spellcooldown(call_dreadstalkers) > casttime(shadow_bolt) and spellcooldown(nether_portal) > 165 + casttime(hand_of_guldan) spell(hand_of_guldan)
  #demonbolt,if=buff.demonic_core.up&soul_shard<=3
  if buffpresent(demonic_core_buff) and soulshards() <= 3 spell(demonbolt)
  #call_action_list,name=build_a_shard
  demonologybuild_a_shardmainactions()
 }
}

AddFunction demonologynether_portal_activemainpostconditions
{
 soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardmainpostconditions() or demonologybuild_a_shardmainpostconditions()
}

AddFunction demonologynether_portal_activeshortcdactions
{
 #bilescourge_bombers
 spell(bilescourge_bombers)
 #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
 if spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 spell(summon_vilefiend)

 unless { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } demonologybuild_a_shardshortcdactions()

  unless soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardshortcdpostconditions() or spellcooldown(call_dreadstalkers) > casttime(demonbolt) and spellcooldown(call_dreadstalkers) > casttime(shadow_bolt) and spellcooldown(nether_portal) > 165 + casttime(hand_of_guldan) and spell(hand_of_guldan)
  {
   #summon_demonic_tyrant,if=buff.nether_portal.remains<5&soul_shard=0
   if buffremaining(nether_portal_buff) < 5 and soulshards() == 0 spell(summon_demonic_tyrant)
   #summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+0.5
   if buffremaining(nether_portal_buff) < casttime(summon_demonic_tyrant) + 0.5 spell(summon_demonic_tyrant)

   unless buffpresent(demonic_core_buff) and soulshards() <= 3 and spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    demonologybuild_a_shardshortcdactions()
   }
  }
 }
}

AddFunction demonologynether_portal_activeshortcdpostconditions
{
 { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardshortcdpostconditions() or spellcooldown(call_dreadstalkers) > casttime(demonbolt) and spellcooldown(call_dreadstalkers) > casttime(shadow_bolt) and spellcooldown(nether_portal) > 165 + casttime(hand_of_guldan) and spell(hand_of_guldan) or buffpresent(demonic_core_buff) and soulshards() <= 3 and spell(demonbolt) or demonologybuild_a_shardshortcdpostconditions()
}

AddFunction demonologynether_portal_activecdactions
{
 unless spell(bilescourge_bombers)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if spellcooldown(summon_demonic_tyrant) < 13 or not hasequippeditem(132369) spell(grimoire_felguard)

  unless { spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers)
  {
   #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
   if soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } demonologybuild_a_shardcdactions()

   unless soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardcdpostconditions() or spellcooldown(call_dreadstalkers) > casttime(demonbolt) and spellcooldown(call_dreadstalkers) > casttime(shadow_bolt) and spellcooldown(nether_portal) > 165 + casttime(hand_of_guldan) and spell(hand_of_guldan) or buffremaining(nether_portal_buff) < 5 and soulshards() == 0 and spell(summon_demonic_tyrant) or buffremaining(nether_portal_buff) < casttime(summon_demonic_tyrant) + 0.5 and spell(summon_demonic_tyrant) or buffpresent(demonic_core_buff) and soulshards() <= 3 and spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    demonologybuild_a_shardcdactions()
   }
  }
 }
}

AddFunction demonologynether_portal_activecdpostconditions
{
 spell(bilescourge_bombers) or { spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or soulshards() == 1 and { spellcooldown(call_dreadstalkers) < casttime(shadow_bolt) or hastalent(bilescourge_bombers_talent) and spellcooldown(bilescourge_bombers) < casttime(shadow_bolt) } and demonologybuild_a_shardcdpostconditions() or spellcooldown(call_dreadstalkers) > casttime(demonbolt) and spellcooldown(call_dreadstalkers) > casttime(shadow_bolt) and spellcooldown(nether_portal) > 165 + casttime(hand_of_guldan) and spell(hand_of_guldan) or buffremaining(nether_portal_buff) < 5 and soulshards() == 0 and spell(summon_demonic_tyrant) or buffremaining(nether_portal_buff) < casttime(summon_demonic_tyrant) + 0.5 and spell(summon_demonic_tyrant) or buffpresent(demonic_core_buff) and soulshards() <= 3 and spell(demonbolt) or demonologybuild_a_shardcdpostconditions()
}

### actions.nether_portal

AddFunction demonologynether_portalmainactions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if spellcooldown(nether_portal) < 20 demonologynether_portal_buildingmainactions()

 unless spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingmainpostconditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if spellcooldown(nether_portal) > 165 demonologynether_portal_activemainactions()
 }
}

AddFunction demonologynether_portalmainpostconditions
{
 spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingmainpostconditions() or spellcooldown(nether_portal) > 165 and demonologynether_portal_activemainpostconditions()
}

AddFunction demonologynether_portalshortcdactions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if spellcooldown(nether_portal) < 20 demonologynether_portal_buildingshortcdactions()

 unless spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingshortcdpostconditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if spellcooldown(nether_portal) > 165 demonologynether_portal_activeshortcdactions()
 }
}

AddFunction demonologynether_portalshortcdpostconditions
{
 spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingshortcdpostconditions() or spellcooldown(nether_portal) > 165 and demonologynether_portal_activeshortcdpostconditions()
}

AddFunction demonologynether_portalcdactions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if spellcooldown(nether_portal) < 20 demonologynether_portal_buildingcdactions()

 unless spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingcdpostconditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if spellcooldown(nether_portal) > 165 demonologynether_portal_activecdactions()
 }
}

AddFunction demonologynether_portalcdpostconditions
{
 spellcooldown(nether_portal) < 20 and demonologynether_portal_buildingcdpostconditions() or spellcooldown(nether_portal) > 165 and demonologynether_portal_activecdpostconditions()
}

### actions.implosion

AddFunction demonologyimplosionmainactions
{
 #implosion,if=(buff.wild_imps.stack>=6&(soul_shard<3|prev_gcd.1.call_dreadstalkers|buff.wild_imps.stack>=9|prev_gcd.1.bilescourge_bombers|(!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan))&!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&buff.demonic_power.down)|(time_to_die<3&buff.wild_imps.stack>0)|(prev_gcd.2.call_dreadstalkers&buff.wild_imps.stack>2&!talent.demonic_calling.enabled)
 if demons(wild_imp) + demons(wild_imp_inner_demons) >= 6 and { soulshards() < 3 or previousgcdspell(call_dreadstalkers) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 9 or previousgcdspell(bilescourge_bombers) or not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) } and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and buffexpires(demonic_power) or target.timetodie() < 3 and demons(wild_imp) + demons(wild_imp_inner_demons) > 0 or previousgcdspell(call_dreadstalkers count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and not hastalent(demonic_calling_talent) spell(implosion)
 #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
 if spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard>=5
 if soulshards() >= 5 spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&(((prev_gcd.2.hand_of_guldan|buff.wild_imps.stack>=3)&buff.wild_imps.stack<9)|cooldown.summon_demonic_tyrant.remains<=gcd*2|buff.demonic_power.remains>gcd*2)
 if soulshards() >= 3 and { { previousgcdspell(hand_of_guldan count=2) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 3 } and demons(wild_imp) + demons(wild_imp_inner_demons) < 9 or spellcooldown(summon_demonic_tyrant) <= gcd() * 2 or buffremaining(demonic_power) > gcd() * 2 } spell(hand_of_guldan)
 #demonbolt,if=prev_gcd.1.hand_of_guldan&soul_shard>=1&(buff.wild_imps.stack<=3|prev_gcd.3.hand_of_guldan)&soul_shard<4&buff.demonic_core.up
 if previousgcdspell(hand_of_guldan) and soulshards() >= 1 and { demons(wild_imp) + demons(wild_imp_inner_demons) <= 3 or previousgcdspell(hand_of_guldan count=3) } and soulshards() < 4 and buffpresent(demonic_core_buff) spell(demonbolt)
 #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&spell_targets.implosion<5
 if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 spell(concentrated_flame_essence)
 #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
 if soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 spell(soul_strike)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.up&(buff.demonic_core.stack>=3|buff.demonic_core.remains<=gcd*5.7)
 if soulshards() <= 3 and buffpresent(demonic_core_buff) and { buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) <= gcd() * 5.7 } spell(demonbolt)
 #doom,cycle_targets=1,max_cycle_targets=7,if=refreshable
 if debuffcountonany(doom_debuff) < enemies() and debuffcountonany(doom_debuff) <= 7 and target.refreshable(doom_debuff) spell(doom)
 #call_action_list,name=build_a_shard
 demonologybuild_a_shardmainactions()
}

AddFunction demonologyimplosionmainpostconditions
{
 demonologybuild_a_shardmainpostconditions()
}

AddFunction demonologyimplosionshortcdactions
{
 unless { demons(wild_imp) + demons(wild_imp_inner_demons) >= 6 and { soulshards() < 3 or previousgcdspell(call_dreadstalkers) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 9 or previousgcdspell(bilescourge_bombers) or not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) } and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and buffexpires(demonic_power) or target.timetodie() < 3 and demons(wild_imp) + demons(wild_imp_inner_demons) > 0 or previousgcdspell(call_dreadstalkers count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and not hastalent(demonic_calling_talent) } and spell(implosion) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers)
 {
  #summon_demonic_tyrant
  spell(summon_demonic_tyrant)

  unless soulshards() >= 5 and spell(hand_of_guldan) or soulshards() >= 3 and { { previousgcdspell(hand_of_guldan count=2) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 3 } and demons(wild_imp) + demons(wild_imp_inner_demons) < 9 or spellcooldown(summon_demonic_tyrant) <= gcd() * 2 or buffremaining(demonic_power) > gcd() * 2 } and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and soulshards() >= 1 and { demons(wild_imp) + demons(wild_imp_inner_demons) <= 3 or previousgcdspell(hand_of_guldan count=3) } and soulshards() < 4 and buffpresent(demonic_core_buff) and spell(demonbolt)
  {
   #summon_vilefiend,if=(cooldown.summon_demonic_tyrant.remains>40&spell_targets.implosion<=2)|cooldown.summon_demonic_tyrant.remains<12
   if spellcooldown(summon_demonic_tyrant) > 40 and enemies() <= 2 or spellcooldown(summon_demonic_tyrant) < 12 spell(summon_vilefiend)
   #bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
   if spellcooldown(summon_demonic_tyrant) > 9 spell(bilescourge_bombers)
   #purifying_blast
   spell(purifying_blast)

   unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) <= gcd() * 5.7 } and spell(demonbolt) or debuffcountonany(doom_debuff) < enemies() and debuffcountonany(doom_debuff) <= 7 and target.refreshable(doom_debuff) and spell(doom)
   {
    #call_action_list,name=build_a_shard
    demonologybuild_a_shardshortcdactions()
   }
  }
 }
}

AddFunction demonologyimplosionshortcdpostconditions
{
 { demons(wild_imp) + demons(wild_imp_inner_demons) >= 6 and { soulshards() < 3 or previousgcdspell(call_dreadstalkers) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 9 or previousgcdspell(bilescourge_bombers) or not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) } and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and buffexpires(demonic_power) or target.timetodie() < 3 and demons(wild_imp) + demons(wild_imp_inner_demons) > 0 or previousgcdspell(call_dreadstalkers count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and not hastalent(demonic_calling_talent) } and spell(implosion) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or soulshards() >= 5 and spell(hand_of_guldan) or soulshards() >= 3 and { { previousgcdspell(hand_of_guldan count=2) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 3 } and demons(wild_imp) + demons(wild_imp_inner_demons) < 9 or spellcooldown(summon_demonic_tyrant) <= gcd() * 2 or buffremaining(demonic_power) > gcd() * 2 } and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and soulshards() >= 1 and { demons(wild_imp) + demons(wild_imp_inner_demons) <= 3 or previousgcdspell(hand_of_guldan count=3) } and soulshards() < 4 and buffpresent(demonic_core_buff) and spell(demonbolt) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) <= gcd() * 5.7 } and spell(demonbolt) or debuffcountonany(doom_debuff) < enemies() and debuffcountonany(doom_debuff) <= 7 and target.refreshable(doom_debuff) and spell(doom) or demonologybuild_a_shardshortcdpostconditions()
}

AddFunction demonologyimplosioncdactions
{
 unless { demons(wild_imp) + demons(wild_imp_inner_demons) >= 6 and { soulshards() < 3 or previousgcdspell(call_dreadstalkers) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 9 or previousgcdspell(bilescourge_bombers) or not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) } and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and buffexpires(demonic_power) or target.timetodie() < 3 and demons(wild_imp) + demons(wild_imp_inner_demons) > 0 or previousgcdspell(call_dreadstalkers count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and not hastalent(demonic_calling_talent) } and spell(implosion)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if spellcooldown(summon_demonic_tyrant) < 13 or not hasequippeditem(132369) spell(grimoire_felguard)

  unless { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or spell(summon_demonic_tyrant) or soulshards() >= 5 and spell(hand_of_guldan) or soulshards() >= 3 and { { previousgcdspell(hand_of_guldan count=2) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 3 } and demons(wild_imp) + demons(wild_imp_inner_demons) < 9 or spellcooldown(summon_demonic_tyrant) <= gcd() * 2 or buffremaining(demonic_power) > gcd() * 2 } and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and soulshards() >= 1 and { demons(wild_imp) + demons(wild_imp_inner_demons) <= 3 or previousgcdspell(hand_of_guldan count=3) } and soulshards() < 4 and buffpresent(demonic_core_buff) and spell(demonbolt) or { spellcooldown(summon_demonic_tyrant) > 40 and enemies() <= 2 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or spellcooldown(summon_demonic_tyrant) > 9 and spell(bilescourge_bombers)
  {
   #focused_azerite_beam
   spell(focused_azerite_beam)

   unless spell(purifying_blast)
   {
    #blood_of_the_enemy
    spell(blood_of_the_enemy)

    unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) <= gcd() * 5.7 } and spell(demonbolt) or debuffcountonany(doom_debuff) < enemies() and debuffcountonany(doom_debuff) <= 7 and target.refreshable(doom_debuff) and spell(doom)
    {
     #call_action_list,name=build_a_shard
     demonologybuild_a_shardcdactions()
    }
   }
  }
 }
}

AddFunction demonologyimplosioncdpostconditions
{
 { demons(wild_imp) + demons(wild_imp_inner_demons) >= 6 and { soulshards() < 3 or previousgcdspell(call_dreadstalkers) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 9 or previousgcdspell(bilescourge_bombers) or not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) } and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and buffexpires(demonic_power) or target.timetodie() < 3 and demons(wild_imp) + demons(wild_imp_inner_demons) > 0 or previousgcdspell(call_dreadstalkers count=2) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and not hastalent(demonic_calling_talent) } and spell(implosion) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or spell(summon_demonic_tyrant) or soulshards() >= 5 and spell(hand_of_guldan) or soulshards() >= 3 and { { previousgcdspell(hand_of_guldan count=2) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 3 } and demons(wild_imp) + demons(wild_imp_inner_demons) < 9 or spellcooldown(summon_demonic_tyrant) <= gcd() * 2 or buffremaining(demonic_power) > gcd() * 2 } and spell(hand_of_guldan) or previousgcdspell(hand_of_guldan) and soulshards() >= 1 and { demons(wild_imp) + demons(wild_imp_inner_demons) <= 3 or previousgcdspell(hand_of_guldan count=3) } and soulshards() < 4 and buffpresent(demonic_core_buff) and spell(demonbolt) or { spellcooldown(summon_demonic_tyrant) > 40 and enemies() <= 2 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or spellcooldown(summon_demonic_tyrant) > 9 and spell(bilescourge_bombers) or spell(purifying_blast) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) <= gcd() * 5.7 } and spell(demonbolt) or debuffcountonany(doom_debuff) < enemies() and debuffcountonany(doom_debuff) <= 7 and target.refreshable(doom_debuff) and spell(doom) or demonologybuild_a_shardcdpostconditions()
}

### actions.build_a_shard

AddFunction demonologybuild_a_shardmainactions
{
 #soul_strike,if=!talent.demonic_consumption.enabled|time>15|prev_gcd.1.hand_of_guldan&!buff.bloodlust.remains
 if not hastalent(demonic_consumption_talent) or timeincombat() > 15 or previousgcdspell(hand_of_guldan) and not buffpresent(bloodlust) spell(soul_strike)
 #shadow_bolt
 spell(shadow_bolt)
}

AddFunction demonologybuild_a_shardmainpostconditions
{
}

AddFunction demonologybuild_a_shardshortcdactions
{
}

AddFunction demonologybuild_a_shardshortcdpostconditions
{
 { not hastalent(demonic_consumption_talent) or timeincombat() > 15 or previousgcdspell(hand_of_guldan) and not buffpresent(bloodlust) } and spell(soul_strike) or spell(shadow_bolt)
}

AddFunction demonologybuild_a_shardcdactions
{
 #memory_of_lucid_dreams,if=soul_shard<2
 if soulshards() < 2 spell(memory_of_lucid_dreams_essence)
}

AddFunction demonologybuild_a_shardcdpostconditions
{
 { not hastalent(demonic_consumption_talent) or timeincombat() > 15 or previousgcdspell(hand_of_guldan) and not buffpresent(bloodlust) } and spell(soul_strike) or spell(shadow_bolt)
}

### actions.default

AddFunction demonology_defaultmainactions
{
 #call_action_list,name=opener,if=!talent.nether_portal.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 demonologyopenermainactions()

 unless not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenermainpostconditions()
 {
  #hand_of_guldan,if=azerite.explosive_potential.rank&time<5&soul_shard>2&buff.explosive_potential.down&buff.wild_imps.stack<3&!prev_gcd.1.hand_of_guldan&&!prev_gcd.2.hand_of_guldan
  if azeritetraitrank(explosive_potential_trait) and timeincombat() < 5 and soulshards() > 2 and buffexpires(explosive_potential) and demons(wild_imp) + demons(wild_imp_inner_demons) < 3 and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) spell(hand_of_guldan)
  #demonbolt,if=soul_shard<=3&buff.demonic_core.up&buff.demonic_core.stack=4
  if soulshards() <= 3 and buffpresent(demonic_core_buff) and buffstacks(demonic_core_buff) == 4 spell(demonbolt)
  #implosion,if=azerite.explosive_potential.rank&buff.wild_imps.stack>2&buff.explosive_potential.remains<action.shadow_bolt.execute_time&(!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>12)
  if azeritetraitrank(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffremaining(explosive_potential) < executetime(shadow_bolt) and { not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) > 12 } spell(implosion)
  #doom,if=!ticking&time_to_die>30&spell_targets.implosion<2&!buff.nether_portal.remains
  if not target.debuffpresent(doom_debuff) and target.timetodie() > 30 and enemies() < 2 and not buffpresent(nether_portal_buff) spell(doom)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if hastalent(nether_portal_talent) and enemies() <= 2 demonologynether_portalmainactions()

  unless hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalmainpostconditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if enemies() > 1 demonologyimplosionmainactions()

   unless enemies() > 1 and demonologyimplosionmainpostconditions()
   {
    #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
    if spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 spell(call_dreadstalkers)
    #hand_of_guldan,if=(azerite.baleful_invocation.enabled|talent.demonic_consumption.enabled)&prev_gcd.1.hand_of_guldan&cooldown.summon_demonic_tyrant.remains<2
    if { hasazeritetrait(baleful_invocation_trait) or hastalent(demonic_consumption_talent) } and previousgcdspell(hand_of_guldan) and spellcooldown(summon_demonic_tyrant) < 2 spell(hand_of_guldan)
    #doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
    if hastalent(doom_talent) and target.refreshable(doom_debuff) and target.timetodie() > target.debuffremaining(doom_debuff) + 30 spell(doom)
    #hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(cooldown.summon_demonic_tyrant.remains>20|(cooldown.summon_demonic_tyrant.remains<gcd*2&talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains<gcd*4&!talent.demonic_consumption.enabled))&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
    if soulshards() >= 5 or soulshards() >= 3 and spellcooldown(call_dreadstalkers) > 4 and { spellcooldown(summon_demonic_tyrant) > 20 or spellcooldown(summon_demonic_tyrant) < gcd() * 2 and hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) < gcd() * 4 and not hastalent(demonic_consumption_talent) } and { not hastalent(summon_vilefiend_talent) or spellcooldown(summon_vilefiend) > 3 } spell(hand_of_guldan)
    #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
    if soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 spell(soul_strike)
    #demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<6|cooldown.summon_demonic_tyrant.remains>22&!azerite.shadows_bite.enabled)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25|buff.shadows_bite.remains)
    if soulshards() <= 3 and buffpresent(demonic_core_buff) and { spellcooldown(summon_demonic_tyrant) < 6 or spellcooldown(summon_demonic_tyrant) > 22 and not hasazeritetrait(shadows_bite_trait) or buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) < 5 or target.timetodie() < 25 or buffpresent(shadows_bite) } spell(demonbolt)
    #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&!pet.demonic_tyrant.active
    if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not demonduration(demonic_tyrant) > 0 spell(concentrated_flame_essence)
    #call_action_list,name=build_a_shard
    demonologybuild_a_shardmainactions()
   }
  }
 }
}

AddFunction demonology_defaultmainpostconditions
{
 not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenermainpostconditions() or hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalmainpostconditions() or enemies() > 1 and demonologyimplosionmainpostconditions() or demonologybuild_a_shardmainpostconditions()
}

AddFunction demonology_defaultshortcdactions
{
 #worldvein_resonance,if=(pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15)
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 spell(worldvein_resonance_essence)
 #ripple_in_space,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 spell(ripple_in_space_essence)
 #call_action_list,name=opener,if=!talent.nether_portal.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 demonologyopenershortcdactions()

 unless not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenershortcdpostconditions() or azeritetraitrank(explosive_potential_trait) and timeincombat() < 5 and soulshards() > 2 and buffexpires(explosive_potential) and demons(wild_imp) + demons(wild_imp_inner_demons) < 3 and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and spell(hand_of_guldan) or soulshards() <= 3 and buffpresent(demonic_core_buff) and buffstacks(demonic_core_buff) == 4 and spell(demonbolt) or azeritetraitrank(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffremaining(explosive_potential) < executetime(shadow_bolt) and { not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) > 12 } and spell(implosion) or not target.debuffpresent(doom_debuff) and target.timetodie() > 30 and enemies() < 2 and not buffpresent(nether_portal_buff) and spell(doom)
 {
  #bilescourge_bombers,if=azerite.explosive_potential.rank>0&time<10&spell_targets.implosion<2&buff.dreadstalkers.remains&talent.nether_portal.enabled
  if azeritetraitrank(explosive_potential_trait) > 0 and timeincombat() < 10 and enemies() < 2 and demonduration(dreadstalker) and hastalent(nether_portal_talent) spell(bilescourge_bombers)
  #demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
  if demons(wild_imp) + demons(wild_imp_inner_demons) < 6 or buffpresent(demonic_power) or enemies() < 2 spell(demonic_strength)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if hastalent(nether_portal_talent) and enemies() <= 2 demonologynether_portalshortcdactions()

  unless hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalshortcdpostconditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if enemies() > 1 demonologyimplosionshortcdactions()

   unless enemies() > 1 and demonologyimplosionshortcdpostconditions()
   {
    #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 spell(summon_vilefiend)

    unless { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers)
    {
     #the_unbound_force,if=buff.reckless_force.react
     if buffpresent(reckless_force_buff) spell(the_unbound_force)
     #bilescourge_bombers
     spell(bilescourge_bombers)

     unless { hasazeritetrait(baleful_invocation_trait) or hastalent(demonic_consumption_talent) } and previousgcdspell(hand_of_guldan) and spellcooldown(summon_demonic_tyrant) < 2 and spell(hand_of_guldan)
     {
      #summon_demonic_tyrant,if=soul_shard<3&(!talent.demonic_consumption.enabled|buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6&time_to_imps.all.remains<cast_time)|target.time_to_die<20
      if soulshards() < 3 and { not hastalent(demonic_consumption_talent) or demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 and 0 < casttime(summon_demonic_tyrant) } or target.timetodie() < 20 spell(summon_demonic_tyrant)
      #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
      if demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and enemies() < 2 spell(power_siphon)

      unless hastalent(doom_talent) and target.refreshable(doom_debuff) and target.timetodie() > target.debuffremaining(doom_debuff) + 30 and spell(doom) or { soulshards() >= 5 or soulshards() >= 3 and spellcooldown(call_dreadstalkers) > 4 and { spellcooldown(summon_demonic_tyrant) > 20 or spellcooldown(summon_demonic_tyrant) < gcd() * 2 and hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) < gcd() * 4 and not hastalent(demonic_consumption_talent) } and { not hastalent(summon_vilefiend_talent) or spellcooldown(summon_vilefiend) > 3 } } and spell(hand_of_guldan) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { spellcooldown(summon_demonic_tyrant) < 6 or spellcooldown(summon_demonic_tyrant) > 22 and not hasazeritetrait(shadows_bite_trait) or buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) < 5 or target.timetodie() < 25 or buffpresent(shadows_bite) } and spell(demonbolt)
      {
       #purifying_blast
       spell(purifying_blast)

       unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not demonduration(demonic_tyrant) > 0 and spell(concentrated_flame_essence)
       {
        #call_action_list,name=build_a_shard
        demonologybuild_a_shardshortcdactions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction demonology_defaultshortcdpostconditions
{
 not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenershortcdpostconditions() or azeritetraitrank(explosive_potential_trait) and timeincombat() < 5 and soulshards() > 2 and buffexpires(explosive_potential) and demons(wild_imp) + demons(wild_imp_inner_demons) < 3 and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and spell(hand_of_guldan) or soulshards() <= 3 and buffpresent(demonic_core_buff) and buffstacks(demonic_core_buff) == 4 and spell(demonbolt) or azeritetraitrank(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffremaining(explosive_potential) < executetime(shadow_bolt) and { not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) > 12 } and spell(implosion) or not target.debuffpresent(doom_debuff) and target.timetodie() > 30 and enemies() < 2 and not buffpresent(nether_portal_buff) and spell(doom) or hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalshortcdpostconditions() or enemies() > 1 and demonologyimplosionshortcdpostconditions() or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or { hasazeritetrait(baleful_invocation_trait) or hastalent(demonic_consumption_talent) } and previousgcdspell(hand_of_guldan) and spellcooldown(summon_demonic_tyrant) < 2 and spell(hand_of_guldan) or hastalent(doom_talent) and target.refreshable(doom_debuff) and target.timetodie() > target.debuffremaining(doom_debuff) + 30 and spell(doom) or { soulshards() >= 5 or soulshards() >= 3 and spellcooldown(call_dreadstalkers) > 4 and { spellcooldown(summon_demonic_tyrant) > 20 or spellcooldown(summon_demonic_tyrant) < gcd() * 2 and hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) < gcd() * 4 and not hastalent(demonic_consumption_talent) } and { not hastalent(summon_vilefiend_talent) or spellcooldown(summon_vilefiend) > 3 } } and spell(hand_of_guldan) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { spellcooldown(summon_demonic_tyrant) < 6 or spellcooldown(summon_demonic_tyrant) > 22 and not hasazeritetrait(shadows_bite_trait) or buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) < 5 or target.timetodie() < 25 or buffpresent(shadows_bite) } and spell(demonbolt) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not demonduration(demonic_tyrant) > 0 and spell(concentrated_flame_essence) or demonologybuild_a_shardshortcdpostconditions()
}

AddFunction demonology_defaultcdactions
{
 #potion,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)&(!talent.nether_portal.enabled|cooldown.nether_portal.remains>160)|target.time_to_die<30
 if { demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } and { not hastalent(nether_portal_talent) or spellcooldown(nether_portal) > 160 } or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_item,name=azsharas_font_of_power,if=cooldown.summon_demonic_tyrant.remains<=20&!talent.nether_portal.enabled
 if spellcooldown(summon_demonic_tyrant) <= 20 and not hastalent(nether_portal_talent) demonologyuseitemactions()
 #use_items,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 demonologyuseitemactions()
 #berserking,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 spell(berserking)
 #blood_fury,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 spell(blood_fury_sp)
 #fireblood,if=pet.demonic_tyrant.active&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)|target.time_to_die<=15
 if demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 spell(fireblood)
 #blood_of_the_enemy,if=pet.demonic_tyrant.active&pet.demonic_tyrant.remains<=15-gcd*3&(!essence.vision_of_perfection.major|!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>=cooldown.summon_demonic_tyrant.duration-5)
 if demonduration(demonic_tyrant) > 0 and demonduration(demonic_tyrant) <= 15 - gcd() * 3 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } spell(blood_of_the_enemy)

 unless { demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 } and spell(worldvein_resonance_essence) or { demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 } and spell(ripple_in_space_essence)
 {
  #use_item,name=pocketsized_computation_device,if=cooldown.summon_demonic_tyrant.remains>=20&cooldown.summon_demonic_tyrant.remains<=cooldown.summon_demonic_tyrant.duration-15|target.time_to_die<=30
  if spellcooldown(summon_demonic_tyrant) >= 20 and spellcooldown(summon_demonic_tyrant) <= spellcooldownduration(summon_demonic_tyrant) - 15 or target.timetodie() <= 30 demonologyuseitemactions()
  #use_item,name=rotcrusted_voodoo_doll,if=(cooldown.summon_demonic_tyrant.remains>=25|target.time_to_die<=30)
  if spellcooldown(summon_demonic_tyrant) >= 25 or target.timetodie() <= 30 demonologyuseitemactions()
  #use_item,name=shiver_venom_relic,if=(cooldown.summon_demonic_tyrant.remains>=25|target.time_to_die<=30)
  if spellcooldown(summon_demonic_tyrant) >= 25 or target.timetodie() <= 30 demonologyuseitemactions()
  #use_item,name=aquipotent_nautilus,if=(cooldown.summon_demonic_tyrant.remains>=25|target.time_to_die<=30)
  if spellcooldown(summon_demonic_tyrant) >= 25 or target.timetodie() <= 30 demonologyuseitemactions()
  #use_item,name=tidestorm_codex,if=(cooldown.summon_demonic_tyrant.remains>=25|target.time_to_die<=30)
  if spellcooldown(summon_demonic_tyrant) >= 25 or target.timetodie() <= 30 demonologyuseitemactions()
  #use_item,name=vial_of_storms,if=(cooldown.summon_demonic_tyrant.remains>=25|target.time_to_die<=30)
  if spellcooldown(summon_demonic_tyrant) >= 25 or target.timetodie() <= 30 demonologyuseitemactions()
  #call_action_list,name=opener,if=!talent.nether_portal.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
  if not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 demonologyopenercdactions()

  unless not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenercdpostconditions()
  {
   #use_item,name=azsharas_font_of_power,if=(time>30|!talent.nether_portal.enabled)&talent.grimoire_felguard.enabled&(target.time_to_die>120|target.time_to_die<cooldown.summon_demonic_tyrant.remains+15)|target.time_to_die<=35
   if { timeincombat() > 30 or not hastalent(nether_portal_talent) } and hastalent(grimoire_felguard_talent) and { target.timetodie() > 120 or target.timetodie() < spellcooldown(summon_demonic_tyrant) + 15 } or target.timetodie() <= 35 demonologyuseitemactions()

   unless azeritetraitrank(explosive_potential_trait) and timeincombat() < 5 and soulshards() > 2 and buffexpires(explosive_potential) and demons(wild_imp) + demons(wild_imp_inner_demons) < 3 and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and spell(hand_of_guldan) or soulshards() <= 3 and buffpresent(demonic_core_buff) and buffstacks(demonic_core_buff) == 4 and spell(demonbolt) or azeritetraitrank(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffremaining(explosive_potential) < executetime(shadow_bolt) and { not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) > 12 } and spell(implosion) or not target.debuffpresent(doom_debuff) and target.timetodie() > 30 and enemies() < 2 and not buffpresent(nether_portal_buff) and spell(doom) or azeritetraitrank(explosive_potential_trait) > 0 and timeincombat() < 10 and enemies() < 2 and demonduration(dreadstalker) and hastalent(nether_portal_talent) and spell(bilescourge_bombers) or { demons(wild_imp) + demons(wild_imp_inner_demons) < 6 or buffpresent(demonic_power) or enemies() < 2 } and spell(demonic_strength)
   {
    #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
    if hastalent(nether_portal_talent) and enemies() <= 2 demonologynether_portalcdactions()

    unless hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalcdpostconditions()
    {
     #call_action_list,name=implosion,if=spell_targets.implosion>1
     if enemies() > 1 demonologyimplosioncdactions()

     unless enemies() > 1 and demonologyimplosioncdpostconditions()
     {
      #guardian_of_azeroth,if=cooldown.summon_demonic_tyrant.remains<=15|target.time_to_die<=30
      if spellcooldown(summon_demonic_tyrant) <= 15 or target.timetodie() <= 30 spell(guardian_of_azeroth)
      #grimoire_felguard,if=(target.time_to_die>120|target.time_to_die<cooldown.summon_demonic_tyrant.remains+15|cooldown.summon_demonic_tyrant.remains<13)
      if target.timetodie() > 120 or target.timetodie() < spellcooldown(summon_demonic_tyrant) + 15 or spellcooldown(summon_demonic_tyrant) < 13 spell(grimoire_felguard)

      unless { spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(bilescourge_bombers) or { hasazeritetrait(baleful_invocation_trait) or hastalent(demonic_consumption_talent) } and previousgcdspell(hand_of_guldan) and spellcooldown(summon_demonic_tyrant) < 2 and spell(hand_of_guldan) or { soulshards() < 3 and { not hastalent(demonic_consumption_talent) or demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 and 0 < casttime(summon_demonic_tyrant) } or target.timetodie() < 20 } and spell(summon_demonic_tyrant) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and enemies() < 2 and spell(power_siphon) or hastalent(doom_talent) and target.refreshable(doom_debuff) and target.timetodie() > target.debuffremaining(doom_debuff) + 30 and spell(doom) or { soulshards() >= 5 or soulshards() >= 3 and spellcooldown(call_dreadstalkers) > 4 and { spellcooldown(summon_demonic_tyrant) > 20 or spellcooldown(summon_demonic_tyrant) < gcd() * 2 and hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) < gcd() * 4 and not hastalent(demonic_consumption_talent) } and { not hastalent(summon_vilefiend_talent) or spellcooldown(summon_vilefiend) > 3 } } and spell(hand_of_guldan) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { spellcooldown(summon_demonic_tyrant) < 6 or spellcooldown(summon_demonic_tyrant) > 22 and not hasazeritetrait(shadows_bite_trait) or buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) < 5 or target.timetodie() < 25 or buffpresent(shadows_bite) } and spell(demonbolt)
      {
       #focused_azerite_beam,if=!pet.demonic_tyrant.active
       if not demonduration(demonic_tyrant) > 0 spell(focused_azerite_beam)

       unless spell(purifying_blast)
       {
        #blood_of_the_enemy
        spell(blood_of_the_enemy)

        unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not demonduration(demonic_tyrant) > 0 and spell(concentrated_flame_essence)
        {
         #call_action_list,name=build_a_shard
         demonologybuild_a_shardcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction demonology_defaultcdpostconditions
{
 { demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 } and spell(worldvein_resonance_essence) or { demonduration(demonic_tyrant) > 0 and { not azeriteessenceismajor(vision_of_perfection_essence_id) or not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) >= spellcooldownduration(summon_demonic_tyrant) - 5 } or target.timetodie() <= 15 } and spell(ripple_in_space_essence) or not hastalent(nether_portal_talent) and timeincombat() < 30 and not spellcooldown(summon_demonic_tyrant) > 0 and demonologyopenercdpostconditions() or azeritetraitrank(explosive_potential_trait) and timeincombat() < 5 and soulshards() > 2 and buffexpires(explosive_potential) and demons(wild_imp) + demons(wild_imp_inner_demons) < 3 and not previousgcdspell(hand_of_guldan) and not previousgcdspell(hand_of_guldan count=2) and spell(hand_of_guldan) or soulshards() <= 3 and buffpresent(demonic_core_buff) and buffstacks(demonic_core_buff) == 4 and spell(demonbolt) or azeritetraitrank(explosive_potential_trait) and demons(wild_imp) + demons(wild_imp_inner_demons) > 2 and buffremaining(explosive_potential) < executetime(shadow_bolt) and { not hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) > 12 } and spell(implosion) or not target.debuffpresent(doom_debuff) and target.timetodie() > 30 and enemies() < 2 and not buffpresent(nether_portal_buff) and spell(doom) or azeritetraitrank(explosive_potential_trait) > 0 and timeincombat() < 10 and enemies() < 2 and demonduration(dreadstalker) and hastalent(nether_portal_talent) and spell(bilescourge_bombers) or { demons(wild_imp) + demons(wild_imp_inner_demons) < 6 or buffpresent(demonic_power) or enemies() < 2 } and spell(demonic_strength) or hastalent(nether_portal_talent) and enemies() <= 2 and demonologynether_portalcdpostconditions() or enemies() > 1 and demonologyimplosioncdpostconditions() or { spellcooldown(summon_demonic_tyrant) > 40 or spellcooldown(summon_demonic_tyrant) < 12 } and spell(summon_vilefiend) or { spellcooldown(summon_demonic_tyrant) < 9 and buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) < 11 and not buffpresent(demonic_calling_buff) or spellcooldown(summon_demonic_tyrant) > 14 } and spell(call_dreadstalkers) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(bilescourge_bombers) or { hasazeritetrait(baleful_invocation_trait) or hastalent(demonic_consumption_talent) } and previousgcdspell(hand_of_guldan) and spellcooldown(summon_demonic_tyrant) < 2 and spell(hand_of_guldan) or { soulshards() < 3 and { not hastalent(demonic_consumption_talent) or demons(wild_imp) + demons(wild_imp_inner_demons) + impsspawnedduring(2000) / { 100 / { 100 + spellcastspeedpercent() } } >= 6 and 0 < casttime(summon_demonic_tyrant) } or target.timetodie() < 20 } and spell(summon_demonic_tyrant) or demons(wild_imp) + demons(wild_imp_inner_demons) >= 2 and buffstacks(demonic_core_buff) <= 2 and buffexpires(demonic_power) and enemies() < 2 and spell(power_siphon) or hastalent(doom_talent) and target.refreshable(doom_debuff) and target.timetodie() > target.debuffremaining(doom_debuff) + 30 and spell(doom) or { soulshards() >= 5 or soulshards() >= 3 and spellcooldown(call_dreadstalkers) > 4 and { spellcooldown(summon_demonic_tyrant) > 20 or spellcooldown(summon_demonic_tyrant) < gcd() * 2 and hastalent(demonic_consumption_talent) or spellcooldown(summon_demonic_tyrant) < gcd() * 4 and not hastalent(demonic_consumption_talent) } and { not hastalent(summon_vilefiend_talent) or spellcooldown(summon_vilefiend) > 3 } } and spell(hand_of_guldan) or soulshards() < 5 and buffstacks(demonic_core_buff) <= 2 and spell(soul_strike) or soulshards() <= 3 and buffpresent(demonic_core_buff) and { spellcooldown(summon_demonic_tyrant) < 6 or spellcooldown(summon_demonic_tyrant) > 22 and not hasazeritetrait(shadows_bite_trait) or buffstacks(demonic_core_buff) >= 3 or buffremaining(demonic_core_buff) < 5 or target.timetodie() < 25 or buffpresent(shadows_bite) } and spell(demonbolt) or spell(purifying_blast) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not demonduration(demonic_tyrant) > 0 and spell(concentrated_flame_essence) or demonologybuild_a_shardcdpostconditions()
}

### Demonology icons.

AddCheckBox(opt_warlock_demonology_aoe l(aoe) default specialization=demonology)

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=shortcd specialization=demonology
{
 if not incombat() demonologyprecombatshortcdactions()
 unless not incombat() and demonologyprecombatshortcdpostconditions()
 {
  demonology_defaultshortcdactions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=shortcd specialization=demonology
{
 if not incombat() demonologyprecombatshortcdactions()
 unless not incombat() and demonologyprecombatshortcdpostconditions()
 {
  demonology_defaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=demonology
{
 if not incombat() demonologyprecombatmainactions()
 unless not incombat() and demonologyprecombatmainpostconditions()
 {
  demonology_defaultmainactions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=aoe specialization=demonology
{
 if not incombat() demonologyprecombatmainactions()
 unless not incombat() and demonologyprecombatmainpostconditions()
 {
  demonology_defaultmainactions()
 }
}

AddIcon checkbox=!opt_warlock_demonology_aoe enemies=1 help=cd specialization=demonology
{
 if not incombat() demonologyprecombatcdactions()
 unless not incombat() and demonologyprecombatcdpostconditions()
 {
  demonology_defaultcdactions()
 }
}

AddIcon checkbox=opt_warlock_demonology_aoe help=cd specialization=demonology
{
 if not incombat() demonologyprecombatcdactions()
 unless not incombat() and demonologyprecombatcdpostconditions()
 {
  demonology_defaultcdactions()
 }
}

### Required symbols
# 132369
# baleful_invocation_trait
# berserking
# bilescourge_bombers
# bilescourge_bombers_talent
# blood_fury_sp
# blood_of_the_enemy
# bloodlust
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
# grimoire_felguard_talent
# guardian_of_azeroth
# hand_of_guldan
# implosion
# inner_demons
# inner_demons_talent
# memory_of_lucid_dreams_essence
# nether_portal
# nether_portal_buff
# nether_portal_talent
# power_siphon
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
# unbridled_fury_item
# vision_of_perfection_essence_id
# wild_imp
# wild_imp_inner_demons
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
    end
    do
        local name = "sc_t24_warlock_destruction"
        local desc = "[8.3] Simulationcraft: T24_Warlock_Destruction"
        local code = [[
# Based on SimulationCraft profile "T24_Warlock_Destruction".
#	class=warlock
#	spec=destruction
#	talents=2103023
#	pet=imp

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)


AddFunction pool_soul_shards
{
 enemies() > 1 and spellcooldown(havoc) <= 10 or spellcooldown(summon_infernal) <= 15 and { hastalent(grimoire_of_supremacy_talent) or hastalent(dark_soul_instability_talent) and spellcooldown(dark_soul_instability) <= 15 } or hastalent(dark_soul_instability_talent) and spellcooldown(dark_soul_instability) <= 15 and { spellcooldown(summon_infernal) > target.timetodie() or spellcooldown(summon_infernal) + spellcooldownduration(summon_infernal) > target.timetodie() }
}

AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=destruction)

AddFunction destructionuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction destructionprecombatmainactions
{
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if hastalent(grimoire_of_sacrifice_talent) and pet.present() spell(grimoire_of_sacrifice)
 #soul_fire
 spell(soul_fire)
 #incinerate,if=!talent.soul_fire.enabled
 if not hastalent(soul_fire_talent) spell(incinerate)
}

AddFunction destructionprecombatmainpostconditions
{
}

AddFunction destructionprecombatshortcdactions
{
 #flask
 #food
 #augmentation
 #summon_pet
 if not pet.present() spell(summon_imp)
}

AddFunction destructionprecombatshortcdpostconditions
{
 hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice) or spell(soul_fire) or not hastalent(soul_fire_talent) and spell(incinerate)
}

AddFunction destructionprecombatcdactions
{
 unless not pet.present() and spell(summon_imp) or hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice)
 {
  #snapshot_stats
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction destructionprecombatcdpostconditions
{
 not pet.present() and spell(summon_imp) or hastalent(grimoire_of_sacrifice_talent) and pet.present() and spell(grimoire_of_sacrifice) or spell(soul_fire) or not hastalent(soul_fire_talent) and spell(incinerate)
}

### actions.havoc

AddFunction destructionhavocmainactions
{
 #conflagrate,if=buff.backdraft.down&soul_shard>=1&soul_shard<=4
 if buffexpires(backdraft_buff) and soulshards() >= 1 and soulshards() <= 4 spell(conflagrate)
 #immolate,if=talent.internal_combustion.enabled&remains<duration*0.5|!talent.internal_combustion.enabled&refreshable
 if hastalent(internal_combustion_talent) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) and target.refreshable(immolate_debuff) spell(immolate)
 #chaos_bolt,if=cast_time<havoc_remains
 if casttime(chaos_bolt) < debuffremainingonany(havoc) spell(chaos_bolt)
 #soul_fire
 spell(soul_fire)
 #shadowburn,if=active_enemies<3|!talent.fire_and_brimstone.enabled
 if enemies() < 3 or not hastalent(fire_and_brimstone_talent) spell(shadowburn)
 #incinerate,if=cast_time<havoc_remains
 if casttime(incinerate) < debuffremainingonany(havoc) spell(incinerate)
}

AddFunction destructionhavocmainpostconditions
{
}

AddFunction destructionhavocshortcdactions
{
}

AddFunction destructionhavocshortcdpostconditions
{
 buffexpires(backdraft_buff) and soulshards() >= 1 and soulshards() <= 4 and spell(conflagrate) or { hastalent(internal_combustion_talent) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) and target.refreshable(immolate_debuff) } and spell(immolate) or casttime(chaos_bolt) < debuffremainingonany(havoc) and spell(chaos_bolt) or spell(soul_fire) or { enemies() < 3 or not hastalent(fire_and_brimstone_talent) } and spell(shadowburn) or casttime(incinerate) < debuffremainingonany(havoc) and spell(incinerate)
}

AddFunction destructionhavoccdactions
{
}

AddFunction destructionhavoccdpostconditions
{
 buffexpires(backdraft_buff) and soulshards() >= 1 and soulshards() <= 4 and spell(conflagrate) or { hastalent(internal_combustion_talent) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) and target.refreshable(immolate_debuff) } and spell(immolate) or casttime(chaos_bolt) < debuffremainingonany(havoc) and spell(chaos_bolt) or spell(soul_fire) or { enemies() < 3 or not hastalent(fire_and_brimstone_talent) } and spell(shadowburn) or casttime(incinerate) < debuffremainingonany(havoc) and spell(incinerate)
}

### actions.gosup_infernal

AddFunction destructiongosup_infernalmainactions
{
 #rain_of_fire,if=soul_shard=5&!buff.backdraft.up&buff.memory_of_lucid_dreams.up&buff.grimoire_of_supremacy.stack<=10
 if soulshards() == 5 and not buffpresent(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and buffstacks(grimoire_of_supremacy_buff) <= 10 spell(rain_of_fire)
 #chaos_bolt,if=buff.backdraft.up
 if buffpresent(backdraft_buff) spell(chaos_bolt)
 #chaos_bolt,if=soul_shard>=4.2-buff.memory_of_lucid_dreams.up
 if soulshards() >= 4.2 - buffpresent(memory_of_lucid_dreams_essence_buff) spell(chaos_bolt)
 #chaos_bolt,if=!cooldown.conflagrate.up
 if not { not spellcooldown(conflagrate) > 0 } spell(chaos_bolt)
 #chaos_bolt,if=cast_time<pet.infernal.remains&pet.infernal.remains<cast_time+gcd
 if casttime(chaos_bolt) < demonduration(infernal) and demonduration(infernal) < casttime(chaos_bolt) + gcd() spell(chaos_bolt)
 #conflagrate,if=buff.backdraft.down&buff.memory_of_lucid_dreams.up&soul_shard>=1.3
 if buffexpires(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and soulshards() >= 1.3 spell(conflagrate)
 #conflagrate,if=buff.backdraft.down&!buff.memory_of_lucid_dreams.up&(soul_shard>=2.8|charges_fractional>1.9&soul_shard>=1.3)
 if buffexpires(backdraft_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { soulshards() >= 2.8 or charges(conflagrate count=0) > 1.9 and soulshards() >= 1.3 } spell(conflagrate)
 #conflagrate,if=pet.infernal.remains<5
 if demonduration(infernal) < 5 spell(conflagrate)
 #conflagrate,if=charges>1
 if charges(conflagrate) > 1 spell(conflagrate)
 #soul_fire
 spell(soul_fire)
 #shadowburn
 spell(shadowburn)
 #incinerate
 spell(incinerate)
}

AddFunction destructiongosup_infernalmainpostconditions
{
}

AddFunction destructiongosup_infernalshortcdactions
{
}

AddFunction destructiongosup_infernalshortcdpostconditions
{
 soulshards() == 5 and not buffpresent(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and buffstacks(grimoire_of_supremacy_buff) <= 10 and spell(rain_of_fire) or buffpresent(backdraft_buff) and spell(chaos_bolt) or soulshards() >= 4.2 - buffpresent(memory_of_lucid_dreams_essence_buff) and spell(chaos_bolt) or not { not spellcooldown(conflagrate) > 0 } and spell(chaos_bolt) or casttime(chaos_bolt) < demonduration(infernal) and demonduration(infernal) < casttime(chaos_bolt) + gcd() and spell(chaos_bolt) or buffexpires(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and soulshards() >= 1.3 and spell(conflagrate) or buffexpires(backdraft_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { soulshards() >= 2.8 or charges(conflagrate count=0) > 1.9 and soulshards() >= 1.3 } and spell(conflagrate) or demonduration(infernal) < 5 and spell(conflagrate) or charges(conflagrate) > 1 and spell(conflagrate) or spell(soul_fire) or spell(shadowburn) or spell(incinerate)
}

AddFunction destructiongosup_infernalcdactions
{
}

AddFunction destructiongosup_infernalcdpostconditions
{
 soulshards() == 5 and not buffpresent(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and buffstacks(grimoire_of_supremacy_buff) <= 10 and spell(rain_of_fire) or buffpresent(backdraft_buff) and spell(chaos_bolt) or soulshards() >= 4.2 - buffpresent(memory_of_lucid_dreams_essence_buff) and spell(chaos_bolt) or not { not spellcooldown(conflagrate) > 0 } and spell(chaos_bolt) or casttime(chaos_bolt) < demonduration(infernal) and demonduration(infernal) < casttime(chaos_bolt) + gcd() and spell(chaos_bolt) or buffexpires(backdraft_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and soulshards() >= 1.3 and spell(conflagrate) or buffexpires(backdraft_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { soulshards() >= 2.8 or charges(conflagrate count=0) > 1.9 and soulshards() >= 1.3 } and spell(conflagrate) or demonduration(infernal) < 5 and spell(conflagrate) or charges(conflagrate) > 1 and spell(conflagrate) or spell(soul_fire) or spell(shadowburn) or spell(incinerate)
}

### actions.cds

AddFunction destructioncdsmainactions
{
 #immolate,if=talent.grimoire_of_supremacy.enabled&remains<8&cooldown.summon_infernal.remains<4.5
 if hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) < 8 and spellcooldown(summon_infernal) < 4.5 spell(immolate)
 #conflagrate,if=talent.grimoire_of_supremacy.enabled&cooldown.summon_infernal.remains<4.5&!buff.backdraft.up&soul_shard<4.3
 if hastalent(grimoire_of_supremacy_talent) and spellcooldown(summon_infernal) < 4.5 and not buffpresent(backdraft_buff) and soulshards() < 4.3 spell(conflagrate)
}

AddFunction destructioncdsmainpostconditions
{
}

AddFunction destructioncdsshortcdactions
{
 unless hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) < 8 and spellcooldown(summon_infernal) < 4.5 and spell(immolate) or hastalent(grimoire_of_supremacy_talent) and spellcooldown(summon_infernal) < 4.5 and not buffpresent(backdraft_buff) and soulshards() < 4.3 and spell(conflagrate)
 {
  #worldvein_resonance
  spell(worldvein_resonance_essence)
  #ripple_in_space
  spell(ripple_in_space_essence)
 }
}

AddFunction destructioncdsshortcdpostconditions
{
 hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) < 8 and spellcooldown(summon_infernal) < 4.5 and spell(immolate) or hastalent(grimoire_of_supremacy_talent) and spellcooldown(summon_infernal) < 4.5 and not buffpresent(backdraft_buff) and soulshards() < 4.3 and spell(conflagrate)
}

AddFunction destructioncdscdactions
{
 unless hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) < 8 and spellcooldown(summon_infernal) < 4.5 and spell(immolate) or hastalent(grimoire_of_supremacy_talent) and spellcooldown(summon_infernal) < 4.5 and not buffpresent(backdraft_buff) and soulshards() < 4.3 and spell(conflagrate)
 {
  #use_item,name=azsharas_font_of_power,if=cooldown.summon_infernal.up|cooldown.summon_infernal.remains<=4
  if not spellcooldown(summon_infernal) > 0 or spellcooldown(summon_infernal) <= 4 destructionuseitemactions()
  #summon_infernal
  spell(summon_infernal)
  #guardian_of_azeroth,if=pet.infernal.active
  if demonduration(infernal) > 0 spell(guardian_of_azeroth)
  #dark_soul_instability,if=pet.infernal.active&(pet.infernal.remains<20.5|pet.infernal.remains<22&soul_shard>=3.6|!talent.grimoire_of_supremacy.enabled)
  if demonduration(infernal) > 0 and { demonduration(infernal) < 20.5 or demonduration(infernal) < 22 and soulshards() >= 3.6 or not hastalent(grimoire_of_supremacy_talent) } spell(dark_soul_instability)
  #memory_of_lucid_dreams,if=pet.infernal.active&(pet.infernal.remains<15.5|soul_shard<3.5&(buff.dark_soul_instability.up|!talent.grimoire_of_supremacy.enabled&dot.immolate.remains>12))
  if demonduration(infernal) > 0 and { demonduration(infernal) < 15.5 or soulshards() < 3.5 and { buffpresent(dark_soul_instability_buff) or not hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) > 12 } } spell(memory_of_lucid_dreams_essence)
  #summon_infernal,if=target.time_to_die>cooldown.summon_infernal.duration+30
  if target.timetodie() > spellcooldownduration(summon_infernal) + 30 spell(summon_infernal)
  #guardian_of_azeroth,if=time>30&target.time_to_die>cooldown.guardian_of_azeroth.duration+30
  if timeincombat() > 30 and target.timetodie() > spellcooldownduration(guardian_of_azeroth) + 30 spell(guardian_of_azeroth)
  #summon_infernal,if=talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains>target.time_to_die
  if hastalent(dark_soul_instability_talent) and spellcooldown(dark_soul_instability) > target.timetodie() spell(summon_infernal)
  #guardian_of_azeroth,if=cooldown.summon_infernal.remains>target.time_to_die
  if spellcooldown(summon_infernal) > target.timetodie() spell(guardian_of_azeroth)
  #dark_soul_instability,if=cooldown.summon_infernal.remains>target.time_to_die&pet.infernal.remains<20.5
  if spellcooldown(summon_infernal) > target.timetodie() and demonduration(infernal) < 20.5 spell(dark_soul_instability)
  #memory_of_lucid_dreams,if=cooldown.summon_infernal.remains>target.time_to_die&(pet.infernal.remains<15.5|buff.dark_soul_instability.up&soul_shard<3)
  if spellcooldown(summon_infernal) > target.timetodie() and { demonduration(infernal) < 15.5 or buffpresent(dark_soul_instability_buff) and soulshards() < 3 } spell(memory_of_lucid_dreams_essence)
  #summon_infernal,if=target.time_to_die<30
  if target.timetodie() < 30 spell(summon_infernal)
  #guardian_of_azeroth,if=target.time_to_die<30
  if target.timetodie() < 30 spell(guardian_of_azeroth)
  #dark_soul_instability,if=target.time_to_die<21&target.time_to_die>4
  if target.timetodie() < 21 and target.timetodie() > 4 spell(dark_soul_instability)
  #memory_of_lucid_dreams,if=target.time_to_die<16&target.time_to_die>6
  if target.timetodie() < 16 and target.timetodie() > 6 spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy
  spell(blood_of_the_enemy)

  unless spell(worldvein_resonance_essence) or spell(ripple_in_space_essence)
  {
   #potion,if=pet.infernal.active|target.time_to_die<30
   if { demonduration(infernal) > 0 or target.timetodie() < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   #berserking,if=pet.infernal.active&(!talent.grimoire_of_supremacy.enabled|(!essence.memory_of_lucid_dreams.major|buff.memory_of_lucid_dreams.remains)&(!talent.dark_soul_instability.enabled|buff.dark_soul_instability.remains))|target.time_to_die<=15
   if demonduration(infernal) > 0 and { not hastalent(grimoire_of_supremacy_talent) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) } and { not hastalent(dark_soul_instability_talent) or buffpresent(dark_soul_instability_buff) } } or target.timetodie() <= 15 spell(berserking)
   #blood_fury,if=pet.infernal.active&(!talent.grimoire_of_supremacy.enabled|(!essence.memory_of_lucid_dreams.major|buff.memory_of_lucid_dreams.remains)&(!talent.dark_soul_instability.enabled|buff.dark_soul_instability.remains))|target.time_to_die<=15
   if demonduration(infernal) > 0 and { not hastalent(grimoire_of_supremacy_talent) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) } and { not hastalent(dark_soul_instability_talent) or buffpresent(dark_soul_instability_buff) } } or target.timetodie() <= 15 spell(blood_fury_sp)
   #fireblood,if=pet.infernal.active&(!talent.grimoire_of_supremacy.enabled|(!essence.memory_of_lucid_dreams.major|buff.memory_of_lucid_dreams.remains)&(!talent.dark_soul_instability.enabled|buff.dark_soul_instability.remains))|target.time_to_die<=15
   if demonduration(infernal) > 0 and { not hastalent(grimoire_of_supremacy_talent) or { not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) or buffpresent(memory_of_lucid_dreams_essence_buff) } and { not hastalent(dark_soul_instability_talent) or buffpresent(dark_soul_instability_buff) } } or target.timetodie() <= 15 spell(fireblood)
   #use_items,if=pet.infernal.active&(!talent.grimoire_of_supremacy.enabled|pet.infernal.remains<=20)|target.time_to_die<=20
   if demonduration(infernal) > 0 and { not hastalent(grimoire_of_supremacy_talent) or demonduration(infernal) <= 20 } or target.timetodie() <= 20 destructionuseitemactions()
   #use_item,name=pocketsized_computation_device,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
   #use_item,name=rotcrusted_voodoo_doll,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
   #use_item,name=shiver_venom_relic,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
   #use_item,name=aquipotent_nautilus,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
   #use_item,name=tidestorm_codex,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
   #use_item,name=vial_of_storms,if=dot.immolate.remains>=5&(cooldown.summon_infernal.remains>=20|target.time_to_die<30)
   if target.debuffremaining(immolate_debuff) >= 5 and { spellcooldown(summon_infernal) >= 20 or target.timetodie() < 30 } destructionuseitemactions()
  }
 }
}

AddFunction destructioncdscdpostconditions
{
 hastalent(grimoire_of_supremacy_talent) and target.debuffremaining(immolate_debuff) < 8 and spellcooldown(summon_infernal) < 4.5 and spell(immolate) or hastalent(grimoire_of_supremacy_talent) and spellcooldown(summon_infernal) < 4.5 and not buffpresent(backdraft_buff) and soulshards() < 4.3 and spell(conflagrate) or spell(worldvein_resonance_essence) or spell(ripple_in_space_essence)
}

### actions.aoe

AddFunction destructionaoemainactions
{
 #rain_of_fire,if=pet.infernal.active&(buff.crashing_chaos.down|!talent.grimoire_of_supremacy.enabled)&(!cooldown.havoc.ready|active_enemies>3)
 if demonduration(infernal) > 0 and { buffexpires(crashing_chaos_buff) or not hastalent(grimoire_of_supremacy_talent) } and { not spellcooldown(havoc) == 0 or enemies() > 3 } spell(rain_of_fire)
 #channel_demonfire,if=dot.immolate.remains>cast_time
 if target.debuffremaining(immolate_debuff) > casttime(channel_demonfire) spell(channel_demonfire)
 #immolate,cycle_targets=1,if=remains<5&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
 if target.debuffremaining(immolate_debuff) < 5 and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } spell(immolate)
 #call_action_list,name=cds
 destructioncdsmainactions()

 unless destructioncdsmainpostconditions()
 {
  #chaos_bolt,if=talent.grimoire_of_supremacy.enabled&pet.infernal.active&(havoc_active|talent.cataclysm.enabled|talent.inferno.enabled&active_enemies<4)
  if hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and { debuffcountonany(havoc) > 0 or hastalent(cataclysm_talent) or hastalent(inferno_talent) and enemies() < 4 } spell(chaos_bolt)
  #rain_of_fire
  spell(rain_of_fire)
  #incinerate,if=talent.fire_and_brimstone.enabled&buff.backdraft.up&soul_shard<5-0.2*active_enemies
  if hastalent(fire_and_brimstone_talent) and buffpresent(backdraft_buff) and soulshards() < 5 - 0.2 * enemies() spell(incinerate)
  #soul_fire
  spell(soul_fire)
  #conflagrate,if=buff.backdraft.down
  if buffexpires(backdraft_buff) spell(conflagrate)
  #shadowburn,if=!talent.fire_and_brimstone.enabled
  if not hastalent(fire_and_brimstone_talent) spell(shadowburn)
  #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&active_enemies<5
  if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 spell(concentrated_flame_essence)
  #incinerate
  spell(incinerate)
 }
}

AddFunction destructionaoemainpostconditions
{
 destructioncdsmainpostconditions()
}

AddFunction destructionaoeshortcdactions
{
 unless demonduration(infernal) > 0 and { buffexpires(crashing_chaos_buff) or not hastalent(grimoire_of_supremacy_talent) } and { not spellcooldown(havoc) == 0 or enemies() > 3 } and spell(rain_of_fire) or target.debuffremaining(immolate_debuff) > casttime(channel_demonfire) and spell(channel_demonfire) or target.debuffremaining(immolate_debuff) < 5 and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate)
 {
  #call_action_list,name=cds
  destructioncdsshortcdactions()

  unless destructioncdsshortcdpostconditions()
  {
   #havoc,cycle_targets=1,if=!(target=self.target)&active_enemies<4
   if not false(target_is_target) and enemies() < 4 and enemies() > 1 spell(havoc)

   unless hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and { debuffcountonany(havoc) > 0 or hastalent(cataclysm_talent) or hastalent(inferno_talent) and enemies() < 4 } and spell(chaos_bolt) or spell(rain_of_fire)
   {
    #purifying_blast
    spell(purifying_blast)
    #havoc,cycle_targets=1,if=!(target=self.target)&(!talent.grimoire_of_supremacy.enabled|!talent.inferno.enabled|talent.grimoire_of_supremacy.enabled&pet.infernal.remains<=10)
    if not false(target_is_target) and { not hastalent(grimoire_of_supremacy_talent) or not hastalent(inferno_talent) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) <= 10 } and enemies() > 1 spell(havoc)
   }
  }
 }
}

AddFunction destructionaoeshortcdpostconditions
{
 demonduration(infernal) > 0 and { buffexpires(crashing_chaos_buff) or not hastalent(grimoire_of_supremacy_talent) } and { not spellcooldown(havoc) == 0 or enemies() > 3 } and spell(rain_of_fire) or target.debuffremaining(immolate_debuff) > casttime(channel_demonfire) and spell(channel_demonfire) or target.debuffremaining(immolate_debuff) < 5 and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or destructioncdsshortcdpostconditions() or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and { debuffcountonany(havoc) > 0 or hastalent(cataclysm_talent) or hastalent(inferno_talent) and enemies() < 4 } and spell(chaos_bolt) or spell(rain_of_fire) or hastalent(fire_and_brimstone_talent) and buffpresent(backdraft_buff) and soulshards() < 5 - 0.2 * enemies() and spell(incinerate) or spell(soul_fire) or buffexpires(backdraft_buff) and spell(conflagrate) or not hastalent(fire_and_brimstone_talent) and spell(shadowburn) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or spell(incinerate)
}

AddFunction destructionaoecdactions
{
 unless demonduration(infernal) > 0 and { buffexpires(crashing_chaos_buff) or not hastalent(grimoire_of_supremacy_talent) } and { not spellcooldown(havoc) == 0 or enemies() > 3 } and spell(rain_of_fire) or target.debuffremaining(immolate_debuff) > casttime(channel_demonfire) and spell(channel_demonfire) or target.debuffremaining(immolate_debuff) < 5 and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate)
 {
  #call_action_list,name=cds
  destructioncdscdactions()

  unless destructioncdscdpostconditions() or not false(target_is_target) and enemies() < 4 and enemies() > 1 and spell(havoc) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and { debuffcountonany(havoc) > 0 or hastalent(cataclysm_talent) or hastalent(inferno_talent) and enemies() < 4 } and spell(chaos_bolt) or spell(rain_of_fire)
  {
   #focused_azerite_beam
   spell(focused_azerite_beam)
  }
 }
}

AddFunction destructionaoecdpostconditions
{
 demonduration(infernal) > 0 and { buffexpires(crashing_chaos_buff) or not hastalent(grimoire_of_supremacy_talent) } and { not spellcooldown(havoc) == 0 or enemies() > 3 } and spell(rain_of_fire) or target.debuffremaining(immolate_debuff) > casttime(channel_demonfire) and spell(channel_demonfire) or target.debuffremaining(immolate_debuff) < 5 and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or destructioncdscdpostconditions() or not false(target_is_target) and enemies() < 4 and enemies() > 1 and spell(havoc) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and { debuffcountonany(havoc) > 0 or hastalent(cataclysm_talent) or hastalent(inferno_talent) and enemies() < 4 } and spell(chaos_bolt) or spell(rain_of_fire) or spell(purifying_blast) or not false(target_is_target) and { not hastalent(grimoire_of_supremacy_talent) or not hastalent(inferno_talent) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) <= 10 } and enemies() > 1 and spell(havoc) or hastalent(fire_and_brimstone_talent) and buffpresent(backdraft_buff) and soulshards() < 5 - 0.2 * enemies() and spell(incinerate) or spell(soul_fire) or buffexpires(backdraft_buff) and spell(conflagrate) or not hastalent(fire_and_brimstone_talent) and spell(shadowburn) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and enemies() < 5 and spell(concentrated_flame_essence) or spell(incinerate)
}

### actions.default

AddFunction destruction_defaultmainactions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } destructionhavocmainactions()

 unless debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavocmainpostconditions()
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 destructionaoemainactions()

  unless enemies() > 2 and destructionaoemainpostconditions()
  {
   #immolate,cycle_targets=1,if=refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>remains)
   if target.refreshable(immolate_debuff) and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } spell(immolate)
   #immolate,if=talent.internal_combustion.enabled&action.chaos_bolt.in_flight&remains<duration*0.5
   if hastalent(internal_combustion_talent) and inflighttotarget(chaos_bolt) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 spell(immolate)
   #call_action_list,name=cds
   destructioncdsmainactions()

   unless destructioncdsmainpostconditions()
   {
    #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight
    if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) spell(concentrated_flame_essence)
    #channel_demonfire
    spell(channel_demonfire)
    #call_action_list,name=gosup_infernal,if=talent.grimoire_of_supremacy.enabled&pet.infernal.active
    if hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 destructiongosup_infernalmainactions()

    unless hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and destructiongosup_infernalmainpostconditions()
    {
     #soul_fire
     spell(soul_fire)
     #variable,name=pool_soul_shards,value=active_enemies>1&cooldown.havoc.remains<=10|cooldown.summon_infernal.remains<=15&(talent.grimoire_of_supremacy.enabled|talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=15)|talent.dark_soul_instability.enabled&cooldown.dark_soul_instability.remains<=15&(cooldown.summon_infernal.remains>target.time_to_die|cooldown.summon_infernal.remains+cooldown.summon_infernal.duration>target.time_to_die)
     #conflagrate,if=buff.backdraft.down&soul_shard>=1.5-0.3*talent.flashover.enabled&!variable.pool_soul_shards
     if buffexpires(backdraft_buff) and soulshards() >= 1.5 - 0.3 * talentpoints(flashover_talent) and not pool_soul_shards() spell(conflagrate)
     #shadowburn,if=soul_shard<2&(!variable.pool_soul_shards|charges>1)
     if soulshards() < 2 and { not pool_soul_shards() or charges(shadowburn) > 1 } spell(shadowburn)
     #chaos_bolt,if=(talent.grimoire_of_supremacy.enabled|azerite.crashing_chaos.enabled)&pet.infernal.active|buff.dark_soul_instability.up|buff.reckless_force.react&buff.reckless_force.remains>cast_time
     if { hastalent(grimoire_of_supremacy_talent) or hasazeritetrait(crashing_chaos_trait) } and demonduration(infernal) > 0 or buffpresent(dark_soul_instability_buff) or buffpresent(reckless_force_buff) and buffremaining(reckless_force_buff) > casttime(chaos_bolt) spell(chaos_bolt)
     #chaos_bolt,if=buff.backdraft.up&!variable.pool_soul_shards&!talent.eradication.enabled
     if buffpresent(backdraft_buff) and not pool_soul_shards() and not hastalent(eradication_talent) spell(chaos_bolt)
     #chaos_bolt,if=!variable.pool_soul_shards&talent.eradication.enabled&(debuff.eradication.remains<cast_time|buff.backdraft.up)
     if not pool_soul_shards() and hastalent(eradication_talent) and { target.debuffremaining(eradication_debuff) < casttime(chaos_bolt) or buffpresent(backdraft_buff) } spell(chaos_bolt)
     #chaos_bolt,if=(soul_shard>=4.5-0.2*active_enemies)&(!talent.grimoire_of_supremacy.enabled|cooldown.summon_infernal.remains>7)
     if soulshards() >= 4.5 - 0.2 * enemies() and { not hastalent(grimoire_of_supremacy_talent) or spellcooldown(summon_infernal) > 7 } spell(chaos_bolt)
     #conflagrate,if=charges>1
     if charges(conflagrate) > 1 spell(conflagrate)
     #incinerate
     spell(incinerate)
    }
   }
  }
 }
}

AddFunction destruction_defaultmainpostconditions
{
 debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavocmainpostconditions() or enemies() > 2 and destructionaoemainpostconditions() or destructioncdsmainpostconditions() or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and destructiongosup_infernalmainpostconditions()
}

AddFunction destruction_defaultshortcdactions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } destructionhavocshortcdactions()

 unless debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavocshortcdpostconditions()
 {
  #cataclysm,if=!(pet.infernal.active&dot.immolate.remains+1>pet.infernal.remains)|spell_targets.cataclysm>1|!talent.grimoire_of_supremacy.enabled
  if not { demonduration(infernal) > 0 and target.debuffremaining(immolate_debuff) + 1 > demonduration(infernal) } or enemies() > 1 or not hastalent(grimoire_of_supremacy_talent) spell(cataclysm)
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 destructionaoeshortcdactions()

  unless enemies() > 2 and destructionaoeshortcdpostconditions() or target.refreshable(immolate_debuff) and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or hastalent(internal_combustion_talent) and inflighttotarget(chaos_bolt) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 and spell(immolate)
  {
   #call_action_list,name=cds
   destructioncdsshortcdactions()

   unless destructioncdsshortcdpostconditions()
   {
    #the_unbound_force,if=buff.reckless_force.react
    if buffpresent(reckless_force_buff) spell(the_unbound_force)
    #purifying_blast
    spell(purifying_blast)

    unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or spell(channel_demonfire)
    {
     #havoc,cycle_targets=1,if=!(target=self.target)&(dot.immolate.remains>dot.immolate.duration*0.5|!talent.internal_combustion.enabled)&(!cooldown.summon_infernal.ready|!talent.grimoire_of_supremacy.enabled|talent.grimoire_of_supremacy.enabled&pet.infernal.remains<=10)
     if not false(target_is_target) and { target.debuffremaining(immolate_debuff) > target.debuffduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) } and { not spellcooldown(summon_infernal) == 0 or not hastalent(grimoire_of_supremacy_talent) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) <= 10 } and enemies() > 1 spell(havoc)
     #call_action_list,name=gosup_infernal,if=talent.grimoire_of_supremacy.enabled&pet.infernal.active
     if hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 destructiongosup_infernalshortcdactions()
    }
   }
  }
 }
}

AddFunction destruction_defaultshortcdpostconditions
{
 debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavocshortcdpostconditions() or enemies() > 2 and destructionaoeshortcdpostconditions() or target.refreshable(immolate_debuff) and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or hastalent(internal_combustion_talent) and inflighttotarget(chaos_bolt) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 and spell(immolate) or destructioncdsshortcdpostconditions() or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or spell(channel_demonfire) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and destructiongosup_infernalshortcdpostconditions() or spell(soul_fire) or buffexpires(backdraft_buff) and soulshards() >= 1.5 - 0.3 * talentpoints(flashover_talent) and not pool_soul_shards() and spell(conflagrate) or soulshards() < 2 and { not pool_soul_shards() or charges(shadowburn) > 1 } and spell(shadowburn) or { { hastalent(grimoire_of_supremacy_talent) or hasazeritetrait(crashing_chaos_trait) } and demonduration(infernal) > 0 or buffpresent(dark_soul_instability_buff) or buffpresent(reckless_force_buff) and buffremaining(reckless_force_buff) > casttime(chaos_bolt) } and spell(chaos_bolt) or buffpresent(backdraft_buff) and not pool_soul_shards() and not hastalent(eradication_talent) and spell(chaos_bolt) or not pool_soul_shards() and hastalent(eradication_talent) and { target.debuffremaining(eradication_debuff) < casttime(chaos_bolt) or buffpresent(backdraft_buff) } and spell(chaos_bolt) or soulshards() >= 4.5 - 0.2 * enemies() and { not hastalent(grimoire_of_supremacy_talent) or spellcooldown(summon_infernal) > 7 } and spell(chaos_bolt) or charges(conflagrate) > 1 and spell(conflagrate) or spell(incinerate)
}

AddFunction destruction_defaultcdactions
{
 #call_action_list,name=havoc,if=havoc_active&active_enemies<5-talent.inferno.enabled+(talent.inferno.enabled&talent.internal_combustion.enabled)
 if debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } destructionhavoccdactions()

 unless debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavoccdpostconditions() or { not { demonduration(infernal) > 0 and target.debuffremaining(immolate_debuff) + 1 > demonduration(infernal) } or enemies() > 1 or not hastalent(grimoire_of_supremacy_talent) } and spell(cataclysm)
 {
  #call_action_list,name=aoe,if=active_enemies>2
  if enemies() > 2 destructionaoecdactions()

  unless enemies() > 2 and destructionaoecdpostconditions() or target.refreshable(immolate_debuff) and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or hastalent(internal_combustion_talent) and inflighttotarget(chaos_bolt) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 and spell(immolate)
  {
   #call_action_list,name=cds
   destructioncdscdactions()

   unless destructioncdscdpostconditions()
   {
    #focused_azerite_beam,if=!pet.infernal.active|!talent.grimoire_of_supremacy.enabled
    if not demonduration(infernal) > 0 or not hastalent(grimoire_of_supremacy_talent) spell(focused_azerite_beam)

    unless buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(purifying_blast) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or spell(channel_demonfire) or not false(target_is_target) and { target.debuffremaining(immolate_debuff) > target.debuffduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) } and { not spellcooldown(summon_infernal) == 0 or not hastalent(grimoire_of_supremacy_talent) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) <= 10 } and enemies() > 1 and spell(havoc)
    {
     #call_action_list,name=gosup_infernal,if=talent.grimoire_of_supremacy.enabled&pet.infernal.active
     if hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 destructiongosup_infernalcdactions()
    }
   }
  }
 }
}

AddFunction destruction_defaultcdpostconditions
{
 debuffcountonany(havoc) > 0 and enemies() < 5 - talentpoints(inferno_talent) + { hastalent(inferno_talent) and hastalent(internal_combustion_talent) } and destructionhavoccdpostconditions() or { not { demonduration(infernal) > 0 and target.debuffremaining(immolate_debuff) + 1 > demonduration(infernal) } or enemies() > 1 or not hastalent(grimoire_of_supremacy_talent) } and spell(cataclysm) or enemies() > 2 and destructionaoecdpostconditions() or target.refreshable(immolate_debuff) and { not hastalent(cataclysm_talent) or spellcooldown(cataclysm) > target.debuffremaining(immolate_debuff) } and spell(immolate) or hastalent(internal_combustion_talent) and inflighttotarget(chaos_bolt) and target.debuffremaining(immolate_debuff) < baseduration(immolate_debuff) * 0.5 and spell(immolate) or destructioncdscdpostconditions() or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(purifying_blast) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and spell(concentrated_flame_essence) or spell(channel_demonfire) or not false(target_is_target) and { target.debuffremaining(immolate_debuff) > target.debuffduration(immolate_debuff) * 0.5 or not hastalent(internal_combustion_talent) } and { not spellcooldown(summon_infernal) == 0 or not hastalent(grimoire_of_supremacy_talent) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) <= 10 } and enemies() > 1 and spell(havoc) or hastalent(grimoire_of_supremacy_talent) and demonduration(infernal) > 0 and destructiongosup_infernalcdpostconditions() or spell(soul_fire) or buffexpires(backdraft_buff) and soulshards() >= 1.5 - 0.3 * talentpoints(flashover_talent) and not pool_soul_shards() and spell(conflagrate) or soulshards() < 2 and { not pool_soul_shards() or charges(shadowburn) > 1 } and spell(shadowburn) or { { hastalent(grimoire_of_supremacy_talent) or hasazeritetrait(crashing_chaos_trait) } and demonduration(infernal) > 0 or buffpresent(dark_soul_instability_buff) or buffpresent(reckless_force_buff) and buffremaining(reckless_force_buff) > casttime(chaos_bolt) } and spell(chaos_bolt) or buffpresent(backdraft_buff) and not pool_soul_shards() and not hastalent(eradication_talent) and spell(chaos_bolt) or not pool_soul_shards() and hastalent(eradication_talent) and { target.debuffremaining(eradication_debuff) < casttime(chaos_bolt) or buffpresent(backdraft_buff) } and spell(chaos_bolt) or soulshards() >= 4.5 - 0.2 * enemies() and { not hastalent(grimoire_of_supremacy_talent) or spellcooldown(summon_infernal) > 7 } and spell(chaos_bolt) or charges(conflagrate) > 1 and spell(conflagrate) or spell(incinerate)
}

### Destruction icons.

AddCheckBox(opt_warlock_destruction_aoe l(aoe) default specialization=destruction)

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=shortcd specialization=destruction
{
 if not incombat() destructionprecombatshortcdactions()
 unless not incombat() and destructionprecombatshortcdpostconditions()
 {
  destruction_defaultshortcdactions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=shortcd specialization=destruction
{
 if not incombat() destructionprecombatshortcdactions()
 unless not incombat() and destructionprecombatshortcdpostconditions()
 {
  destruction_defaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=destruction
{
 if not incombat() destructionprecombatmainactions()
 unless not incombat() and destructionprecombatmainpostconditions()
 {
  destruction_defaultmainactions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=aoe specialization=destruction
{
 if not incombat() destructionprecombatmainactions()
 unless not incombat() and destructionprecombatmainpostconditions()
 {
  destruction_defaultmainactions()
 }
}

AddIcon checkbox=!opt_warlock_destruction_aoe enemies=1 help=cd specialization=destruction
{
 if not incombat() destructionprecombatcdactions()
 unless not incombat() and destructionprecombatcdpostconditions()
 {
  destruction_defaultcdactions()
 }
}

AddIcon checkbox=opt_warlock_destruction_aoe help=cd specialization=destruction
{
 if not incombat() destructionprecombatcdactions()
 unless not incombat() and destructionprecombatcdpostconditions()
 {
  destruction_defaultcdactions()
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
# grimoire_of_supremacy_buff
# grimoire_of_supremacy_talent
# guardian_of_azeroth
# havoc
# immolate
# immolate_debuff
# incinerate
# inferno_talent
# internal_combustion_talent
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
# unbridled_fury_item
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("WARLOCK", "destruction", name, desc, code, "script")
    end
end
