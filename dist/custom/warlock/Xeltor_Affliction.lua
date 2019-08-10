local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warlock")
if not __exports then return end
__exports.registerWarlockAfflictionXeltor = function(OvaleScripts)
do
	local name = "xeltor_affliction"
	local desc = "[Xel][8.2] Warlock: Affliction"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

Define(spell_lock_fh 19647)
	SpellInfo(spell_lock_fh cd=24)
Define(shadow_lock_dg 171138)
	SpellInfo(shadow_lock_dg cd=24)

AddIcon specialization=1 help=main
{
	# Interrupts please the RL :(
	if InCombat() InterruptActions()
	
	# Save ass
	if not Mounted() and InCombat() SaveActions()
	
	# I need to breath :(
	if wet() and not mounted() and not BuffPresent(unending_breath) Spell(unending_breath)
	
	# Now we can kill things :)
	if InCombat() and target.InRange(agony) and HasFullControl()
    {
		# Save pet if i have one that is worth saving :3
		if pet.CreatureFamily(Voidwalker) or pet.CreatureFamily(Voidlord) PetStuff()

		# Cooldowns
		if Boss() and { Speed() == 0 or CanMove() > 0 } AfflictionDefaultCdActions()

		# Short Cooldowns
		if Speed() == 0 or CanMove() > 0 AfflictionDefaultShortCdActions()

		# Default rotation
		if Speed() == 0 or CanMove() > 0 AfflictionDefaultMainActions()

		#shadow_bolt,if=buff.movement.up&buff.nightfall.remains
		if Speed() > 0 and BuffPresent(nightfall_buff) Spell(shadow_bolt_affliction)
		#agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
		if Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } Spell(agony)
		#siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
		if Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } Spell(siphon_life)
		#corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
		if Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) Spell(corruption)
	}
	
	if not InCombat() and not mounted() OutOfCombatActions()
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.Distance() - pet.Distance() <= 40 and pet.CreatureFamily(Felhunter) Spell(spell_lock_fh)
		if target.Distance() - pet.Distance() <= 40 and pet.CreatureFamily(Doomguard) Spell(shadow_lock_dg)
	}
}

AddFunction PetStuff
{
	if pet.Health() < pet.HealthMissing() and pet.Present() and { Speed() == 0 or CanMove() > 0 } and SpellUsable(health_funnel) Texture(ability_deathwing_bloodcorruption_death)
}

AddFunction SaveActions
{
	if HealthPercent() < 30 or DamageTaken(5) >= MaxHealth() * 0.7 Spell(unending_resolve)
	if HealthPercent() < 50
	{
		if ItemCharges(healthstone) > 0 and Item(healthstone usable=1) Texture(inv_stone_04)
		if Speed() == 0 Spell(drain_life)
	}
}

AddFunction OutOfCombatActions
{
	if not ItemCharges(healthstone) > 0 and Speed() == 0 and SpellUsable(create_healthstone) and not PreviousGCDSpell(create_healthstone) Texture(inv_misc_gem_bloodstone_01)
}

AddFunction AfflictionUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### functions

AddFunction maintain_se
{
 Enemies(tagged=1) <= 1 + TalentPoints(writhe_in_agony_talent) + TalentPoints(absolute_corruption_talent) * 2 + { Talent(writhe_in_agony_talent) and Talent(sow_the_seeds_talent) and Enemies(tagged=1) > 2 } + { Talent(siphon_life_talent) and not Talent(creeping_death_talent) and not Talent(drain_soul_talent) } + False(raid_events_invulnerable_up)
}

AddFunction use_seed
{
 Talent(sow_the_seeds_talent) and Enemies(tagged=1) >= 3 or Talent(siphon_life_talent) and Enemies(tagged=1) >= 5 or Enemies(tagged=1) >= 8
}

AddFunction padding
{
 ExecuteTime(shadow_bolt_affliction) * HasAzeriteTrait(cascading_calamity_trait)
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
  if Enemies(tagged=1) <= 2 + False(raid_events_invulnerable_up) Spell(haunt)
  #agony,target_if=min:dot.agony.remains,if=remains<=gcd+action.shadow_bolt.execute_time&target.time_to_die>8
  if target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 Spell(agony)
  #agony,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.azsharas_font_of_power
  if TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(agony) > 30 Spell(agony)
  #corruption,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.azsharas_font_of_power&!talent.absolute_corruption.enabled&(talent.siphon_life.enabled|spell_targets.seed_of_corruption_aoe>1&spell_targets.seed_of_corruption_aoe<=3)
  if TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and not Talent(absolute_corruption_talent) and { Talent(siphon_life_talent) or Enemies(tagged=1) > 1 and Enemies(tagged=1) <= 3 } and TimeSincePreviousSpell(corruption) > 30 Spell(corruption)
  #siphon_life,line_cd=30,if=time>30&cooldown.summon_darkglare.remains<=15&equipped.azsharas_font_of_power
  if TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(siphon_life) > 30 Spell(siphon_life)
  #unstable_affliction,target_if=!contagion&target.time_to_die<=8
  if not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 Spell(unstable_affliction)
  #drain_soul,target_if=min:debuff.shadow_embrace.remains,cancel_if=ticks_remain<5,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=gcd*2
  if Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 Spell(drain_soul)
  #shadow_bolt,target_if=min:debuff.shadow_embrace.remains,if=talent.shadow_embrace.enabled&variable.maintain_se&debuff.shadow_embrace.remains&debuff.shadow_embrace.remains<=execute_time*2+travel_time&!action.shadow_bolt.in_flight
  if Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) Spell(shadow_bolt_affliction)
  #unstable_affliction,target_if=min:contagion,if=!variable.use_seed&soul_shard=5
  if not use_seed() and SoulShards() == 5 Spell(unstable_affliction)
  #seed_of_corruption,if=variable.use_seed&soul_shard=5
  if use_seed() and SoulShards() == 5 Spell(seed_of_corruption)
  #call_action_list,name=dots
  AfflictionDotsMainActions()

  unless AfflictionDotsMainPostConditions()
  {
   #vile_taint,target_if=max:target.time_to_die,if=time>15&target.time_to_die>=10&(cooldown.summon_darkglare.remains>30|cooldown.summon_darkglare.remains<10&dot.agony.remains>=10&dot.corruption.remains>=10&(dot.siphon_life.remains>=10|!talent.siphon_life.enabled))
   if TimeInCombat() > 15 and target.TimeToDie() >= 10 and { SpellCooldown(summon_darkglare) > 30 or SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(agony_debuff) >= 10 and target.DebuffRemaining(corruption_debuff) >= 10 and { target.DebuffRemaining(siphon_life_debuff) >= 10 or not Talent(siphon_life_talent) } } Spell(vile_taint)
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

 unless AfflictionCooldownsShortCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies(tagged=1) <= 2 + False(raid_events_invulnerable_up) and Spell(haunt)
 {
  #deathbolt,if=cooldown.summon_darkglare.remains&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(!essence.vision_of_perfection.minor&!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>30)
  if SpellCooldown(summon_darkglare) > 0 and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } Spell(deathbolt)
  #the_unbound_force,if=buff.reckless_force.remains
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)

  unless target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(agony) > 30 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and not Talent(absolute_corruption_talent) and { Talent(siphon_life_talent) or Enemies(tagged=1) > 1 and Enemies(tagged=1) <= 3 } and TimeSincePreviousSpell(corruption) > 30 and Spell(corruption) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(siphon_life) > 30 and Spell(siphon_life) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction)
  {
   #phantom_singularity,target_if=max:target.time_to_die,if=time>35&target.time_to_die>16*spell_haste&(!essence.vision_of_perfection.minor&!azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains>45+soul_shard*azerite.dreadful_calling.rank|cooldown.summon_darkglare.remains<15*spell_haste+soul_shard*azerite.dreadful_calling.rank)
   if TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) } Spell(phantom_singularity)

   unless not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    AfflictionDotsShortCdActions()

    unless AfflictionDotsShortCdPostConditions() or TimeInCombat() > 15 and target.TimeToDie() >= 10 and { SpellCooldown(summon_darkglare) > 30 or SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(agony_debuff) >= 10 and target.DebuffRemaining(corruption_debuff) >= 10 and { target.DebuffRemaining(siphon_life_debuff) >= 10 or not Talent(siphon_life_talent) } } and Spell(vile_taint)
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
 AfflictionCooldownsShortCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies(tagged=1) <= 2 + False(raid_events_invulnerable_up) and Spell(haunt) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(agony) > 30 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and not Talent(absolute_corruption_talent) and { Talent(siphon_life_talent) or Enemies(tagged=1) > 1 and Enemies(tagged=1) <= 3 } and TimeSincePreviousSpell(corruption) > 30 and Spell(corruption) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(siphon_life) > 30 and Spell(siphon_life) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption) or AfflictionDotsShortCdPostConditions() or TimeInCombat() > 15 and target.TimeToDie() >= 10 and { SpellCooldown(summon_darkglare) > 30 or SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(agony_debuff) >= 10 and target.DebuffRemaining(corruption_debuff) >= 10 and { target.DebuffRemaining(siphon_life_debuff) >= 10 or not Talent(siphon_life_talent) } } and Spell(vile_taint) or TimeInCombat() < 15 and Spell(vile_taint) or AfflictionSpendersShortCdPostConditions() or AfflictionFillersShortCdPostConditions()
}

AddFunction AfflictionDefaultCdActions
{
 #variable,name=use_seed,value=talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up|talent.siphon_life.enabled&spell_targets.seed_of_corruption>=5+raid_event.invulnerable.up|spell_targets.seed_of_corruption>=8+raid_event.invulnerable.up
 #variable,name=padding,op=set,value=action.shadow_bolt.execute_time*azerite.cascading_calamity.enabled
 #variable,name=padding,op=reset,value=gcd,if=azerite.cascading_calamity.enabled&(talent.drain_soul.enabled|talent.deathbolt.enabled&cooldown.deathbolt.remains<=gcd)
 #variable,name=maintain_se,value=spell_targets.seed_of_corruption_aoe<=1+talent.writhe_in_agony.enabled+talent.absolute_corruption.enabled*2+(talent.writhe_in_agony.enabled&talent.sow_the_seeds.enabled&spell_targets.seed_of_corruption_aoe>2)+(talent.siphon_life.enabled&!talent.creeping_death.enabled&!talent.drain_soul.enabled)+raid_event.invulnerable.up
 #call_action_list,name=cooldowns
 AfflictionCooldownsCdActions()

 unless AfflictionCooldownsCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies(tagged=1) <= 2 + False(raid_events_invulnerable_up) and Spell(haunt)
 {
  #summon_darkglare,if=summon_darkglare,if=dot.agony.ticking&dot.corruption.ticking&(buff.active_uas.stack=5|soul_shard=0|dot.phantom_singularity.remains&dot.phantom_singularity.remains<=gcd)&(!talent.phantom_singularity.enabled|dot.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains|spell_targets.seed_of_corruption_aoe>1+raid_event.invulnerable.up)
  if target.DebuffPresent(agony_debuff) and target.DebuffPresent(corruption_debuff) and { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 or target.DebuffRemaining(phantom_singularity) and target.DebuffRemaining(phantom_singularity) <= GCD() } and { not Talent(phantom_singularity_talent) or target.DebuffRemaining(phantom_singularity) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 or Enemies(tagged=1) > 1 + False(raid_events_invulnerable_up) } Spell(summon_darkglare)

  unless SpellCooldown(summon_darkglare) > 0 and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } and Spell(deathbolt) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony)
  {
   #memory_of_lucid_dreams,if=time<30
   if TimeInCombat() < 30 Spell(memory_of_lucid_dreams_essence)

   unless TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(agony) > 30 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and not Talent(absolute_corruption_talent) and { Talent(siphon_life_talent) or Enemies(tagged=1) > 1 and Enemies(tagged=1) <= 3 } and TimeSincePreviousSpell(corruption) > 30 and Spell(corruption) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(siphon_life) > 30 and Spell(siphon_life) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) } and Spell(phantom_singularity) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption)
   {
    #call_action_list,name=dots
    AfflictionDotsCdActions()

    unless AfflictionDotsCdPostConditions() or TimeInCombat() > 15 and target.TimeToDie() >= 10 and { SpellCooldown(summon_darkglare) > 30 or SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(agony_debuff) >= 10 and target.DebuffRemaining(corruption_debuff) >= 10 and { target.DebuffRemaining(siphon_life_debuff) >= 10 or not Talent(siphon_life_talent) } } and Spell(vile_taint)
    {
     #use_item,name=azsharas_font_of_power,if=time<=3
     if TimeInCombat() <= 3 AfflictionUseItemActions()

     unless TimeInCombat() <= 35 and Spell(phantom_singularity) or TimeInCombat() < 15 and Spell(vile_taint)
     {
      #guardian_of_azeroth,if=(cooldown.summon_darkglare.remains<15+soul_shard*azerite.dreadful_calling.enabled|(azerite.dreadful_calling.rank|essence.vision_of_perfection.rank)&time>30&target.time_to_die>=210)&(dot.phantom_singularity.remains|dot.vile_taint.remains|!talent.phantom_singularity.enabled&!talent.vile_taint.enabled)|target.time_to_die<30+gcd
      if { SpellCooldown(summon_darkglare) < 15 + SoulShards() * HasAzeriteTrait(dreadful_calling_trait) or { AzeriteTraitRank(dreadful_calling_trait) or AzeriteEssenceRank(vision_of_perfection_essence_id) } and TimeInCombat() > 30 and target.TimeToDie() >= 210 } and { target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) or not Talent(phantom_singularity_talent) and not Talent(vile_taint_talent) } or target.TimeToDie() < 30 + GCD() Spell(guardian_of_azeroth)
      #dark_soul,if=cooldown.summon_darkglare.remains<15+soul_shard*azerite.dreadful_calling.enabled&(dot.phantom_singularity.remains|dot.vile_taint.remains)
      if SpellCooldown(summon_darkglare) < 15 + SoulShards() * HasAzeriteTrait(dreadful_calling_trait) and { target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } Spell(dark_soul_misery)
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
}

AddFunction AfflictionDefaultCdPostConditions
{
 AfflictionCooldownsCdPostConditions() or target.TimeToDie() <= GCD() and SoulShards() < 5 and Spell(drain_soul) or Enemies(tagged=1) <= 2 + False(raid_events_invulnerable_up) and Spell(haunt) or SpellCooldown(summon_darkglare) > 0 and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 30 } and Spell(deathbolt) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or target.DebuffRemaining(agony_debuff) <= GCD() + ExecuteTime(shadow_bolt_affliction) and target.TimeToDie() > 8 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(agony) > 30 and Spell(agony) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and not Talent(absolute_corruption_talent) and { Talent(siphon_life_talent) or Enemies(tagged=1) > 1 and Enemies(tagged=1) <= 3 } and TimeSincePreviousSpell(corruption) > 30 and Spell(corruption) or TimeInCombat() > 30 and SpellCooldown(summon_darkglare) <= 15 and HasEquippedItem(azsharas_font_of_power_item) and TimeSincePreviousSpell(siphon_life) > 30 and Spell(siphon_life) or not BuffRemaining(unstable_affliction_buff) and target.TimeToDie() <= 8 and Spell(unstable_affliction) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= GCD() * 2 and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and target.DebuffPresent(shadow_embrace_debuff) and target.DebuffRemaining(shadow_embrace_debuff) <= ExecuteTime(shadow_bolt_affliction) * 2 + TravelTime(shadow_bolt_affliction) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or TimeInCombat() > 35 and target.TimeToDie() > 16 * { 100 / { 100 + SpellCastSpeedPercent() } } and { not AzeriteEssenceIsMinor(vision_of_perfection_essence_id) and not AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) > 45 + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) or SpellCooldown(summon_darkglare) < 15 * { 100 / { 100 + SpellCastSpeedPercent() } } + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) } and Spell(phantom_singularity) or not use_seed() and SoulShards() == 5 and Spell(unstable_affliction) or use_seed() and SoulShards() == 5 and Spell(seed_of_corruption) or AfflictionDotsCdPostConditions() or TimeInCombat() > 15 and target.TimeToDie() >= 10 and { SpellCooldown(summon_darkglare) > 30 or SpellCooldown(summon_darkglare) < 10 and target.DebuffRemaining(agony_debuff) >= 10 and target.DebuffRemaining(corruption_debuff) >= 10 and { target.DebuffRemaining(siphon_life_debuff) >= 10 or not Talent(siphon_life_talent) } } and Spell(vile_taint) or TimeInCombat() <= 35 and Spell(phantom_singularity) or TimeInCombat() < 15 and Spell(vile_taint) or AfflictionSpendersCdPostConditions() or AfflictionFillersCdPostConditions()
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
 #worldvein_resonance,if=buff.lifeblood.stack<3
 if BuffStacks(lifeblood_buff) < 3 Spell(worldvein_resonance_essence)
 #ripple_in_space
 Spell(ripple_in_space_essence)
}

AddFunction AfflictionCooldownsShortCdPostConditions
{
}

AddFunction AfflictionCooldownsCdActions
{
 #use_item,name=azsharas_font_of_power,if=(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains<4*spell_haste|!cooldown.phantom_singularity.remains)&cooldown.summon_darkglare.remains<19*spell_haste+soul_shard*azerite.dreadful_calling.rank&dot.agony.remains&dot.corruption.remains&(dot.siphon_life.remains|!talent.siphon_life.enabled)
 if { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) < 4 * { 100 / { 100 + SpellCastSpeedPercent() } } or not SpellCooldown(phantom_singularity) > 0 } and SpellCooldown(summon_darkglare) < 19 * { 100 / { 100 + SpellCastSpeedPercent() } } + SoulShards() * AzeriteTraitRank(dreadful_calling_trait) and target.DebuffRemaining(agony_debuff) and target.DebuffRemaining(corruption_debuff) and { target.DebuffRemaining(siphon_life_debuff) or not Talent(siphon_life_talent) } AfflictionUseItemActions()
 #potion,if=(talent.dark_soul_misery.enabled&cooldown.summon_darkglare.up&cooldown.dark_soul.up)|cooldown.summon_darkglare.up|target.time_to_die<30
 # if { Talent(dark_soul_misery_talent) and not SpellCooldown(summon_darkglare) > 0 and not SpellCooldown(dark_soul_misery) > 0 or not SpellCooldown(summon_darkglare) > 0 or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #use_items,if=cooldown.summon_darkglare.remains>70|time_to_die<20|((buff.active_uas.stack=5|soul_shard=0)&(!talent.phantom_singularity.enabled|cooldown.phantom_singularity.remains)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=gcd|!cooldown.deathbolt.remains)&!cooldown.summon_darkglare.remains)
 if SpellCooldown(summon_darkglare) > 70 or target.TimeToDie() < 20 or { target.DebuffStacks(unstable_affliction_debuff) == 5 or SoulShards() == 0 } and { not Talent(phantom_singularity_talent) or SpellCooldown(phantom_singularity) > 0 } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= GCD() or not SpellCooldown(deathbolt) > 0 } and not SpellCooldown(summon_darkglare) > 0 AfflictionUseItemActions()
 #fireblood,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(fireblood)
 #blood_fury,if=!cooldown.summon_darkglare.up
 if not { not SpellCooldown(summon_darkglare) > 0 } Spell(blood_fury_sp)
 #memory_of_lucid_dreams,if=time>30
 if TimeInCombat() > 30 Spell(memory_of_lucid_dreams_essence)
 #dark_soul,if=target.time_to_die<20+gcd|talent.sow_the_seeds.enabled&cooldown.summon_darkglare.remains>=cooldown.summon_darkglare.duration-10
 if target.TimeToDie() < 20 + GCD() or Talent(sow_the_seeds_talent) and SpellCooldown(summon_darkglare) >= SpellCooldownDuration(summon_darkglare) - 10 Spell(dark_soul_misery)
 #blood_of_the_enemy,if=pet.darkglare.remains|(!cooldown.deathbolt.remains|!talent.deathbolt.enabled)&cooldown.summon_darkglare.remains>=80&essence.blood_of_the_enemy.rank>1
 if DemonDuration(darkglare) or { not SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } and SpellCooldown(summon_darkglare) >= 80 and AzeriteEssenceRank(blood_of_the_enemy_essence_id) > 1 Spell(blood_of_the_enemy)
 #use_item,name=pocketsized_computation_device,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
 #use_item,name=rotcrusted_voodoo_doll,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
 #use_item,name=shiver_venom_relic,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
 #use_item,name=aquipotent_nautilus,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
 #use_item,name=tidestorm_codex,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
 #use_item,name=vial_of_storms,if=(cooldown.summon_darkglare.remains>=25|target.time_to_die<=30)&(cooldown.deathbolt.remains|!talent.deathbolt.enabled)
 if { SpellCooldown(summon_darkglare) >= 25 or target.TimeToDie() <= 30 } and { SpellCooldown(deathbolt) > 0 or not Talent(deathbolt_talent) } AfflictionUseItemActions()
}

AddFunction AfflictionCooldownsCdPostConditions
{
 BuffStacks(lifeblood_buff) < 3 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence)
}

### actions.db_refresh

AddFunction AfflictionDbRefreshMainActions
{
 #siphon_life,line_cd=15,if=(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.siphon_life.remains%dot.siphon_life.duration)<=(dot.corruption.remains%dot.corruption.duration)&dot.siphon_life.remains<dot.siphon_life.duration*1.3
 if target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 and TimeSincePreviousSpell(siphon_life) > 15 Spell(siphon_life)
 #agony,line_cd=15,if=(dot.agony.remains%dot.agony.duration)<=(dot.corruption.remains%dot.corruption.duration)&(dot.agony.remains%dot.agony.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.agony.remains<dot.agony.duration*1.3
 if target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 and TimeSincePreviousSpell(agony) > 15 Spell(agony)
 #corruption,line_cd=15,if=(dot.corruption.remains%dot.corruption.duration)<=(dot.agony.remains%dot.agony.duration)&(dot.corruption.remains%dot.corruption.duration)<=(dot.siphon_life.remains%dot.siphon_life.duration)&dot.corruption.remains<dot.corruption.duration*1.3
 if target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 and TimeSincePreviousSpell(corruption) > 15 Spell(corruption)
}

AddFunction AfflictionDbRefreshMainPostConditions
{
}

AddFunction AfflictionDbRefreshShortCdActions
{
}

AddFunction AfflictionDbRefreshShortCdPostConditions
{
 target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 and TimeSincePreviousSpell(siphon_life) > 15 and Spell(siphon_life) or target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 and TimeSincePreviousSpell(agony) > 15 and Spell(agony) or target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 and TimeSincePreviousSpell(corruption) > 15 and Spell(corruption)
}

AddFunction AfflictionDbRefreshCdActions
{
}

AddFunction AfflictionDbRefreshCdPostConditions
{
 target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1.3 and TimeSincePreviousSpell(siphon_life) > 15 and Spell(siphon_life) or target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) and target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1.3 and TimeSincePreviousSpell(agony) > 15 and Spell(agony) or target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(agony_debuff) / target.DebuffDuration(agony_debuff) and target.DebuffRemaining(corruption_debuff) / target.DebuffDuration(corruption_debuff) <= target.DebuffRemaining(siphon_life_debuff) / target.DebuffDuration(siphon_life_debuff) and target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1.3 and TimeSincePreviousSpell(corruption) > 15 and Spell(corruption)
}

### actions.dots

AddFunction AfflictionDotsMainActions
{
 #seed_of_corruption,if=dot.corruption.remains<=action.seed_of_corruption.cast_time+time_to_shard+4.2*(1-talent.creeping_death.enabled*0.15)&spell_targets.seed_of_corruption_aoe>=3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&!dot.seed_of_corruption.remains&!action.seed_of_corruption.in_flight
 if target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies(tagged=1) >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) Spell(seed_of_corruption)
 #agony,target_if=min:remains,if=talent.creeping_death.enabled&active_dot.agony<6&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } Spell(agony)
 #agony,target_if=min:remains,if=!talent.creeping_death.enabled&active_dot.agony<8&target.time_to_die>10&(remains<=gcd|cooldown.summon_darkglare.remains>10&(remains<5|!azerite.pandemic_invocation.rank&refreshable))
 if not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } Spell(agony)
 #siphon_life,target_if=min:remains,if=(active_dot.siphon_life<8-talent.creeping_death.enabled-spell_targets.sow_the_seeds_aoe)&target.time_to_die>10&refreshable&(!remains&spell_targets.seed_of_corruption_aoe=1|cooldown.summon_darkglare.remains>soul_shard*action.unstable_affliction.execute_time)
 if DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies(tagged=1) and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies(tagged=1) == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } Spell(siphon_life)
 #corruption,cycle_targets=1,if=spell_targets.seed_of_corruption_aoe<3+raid_event.invulnerable.up+talent.writhe_in_agony.enabled&(remains<=gcd|cooldown.summon_darkglare.remains>10&refreshable)&target.time_to_die>10
 if Enemies(tagged=1) < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 Spell(corruption)
}

AddFunction AfflictionDotsMainPostConditions
{
}

AddFunction AfflictionDotsShortCdActions
{
}

AddFunction AfflictionDotsShortCdPostConditions
{
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies(tagged=1) >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies(tagged=1) and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies(tagged=1) == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies(tagged=1) < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
}

AddFunction AfflictionDotsCdActions
{
}

AddFunction AfflictionDotsCdPostConditions
{
 target.DebuffRemaining(corruption_debuff) <= CastTime(seed_of_corruption) + TimeToShard() + 4.2 * { 1 - TalentPoints(creeping_death_talent) * 0.15 } and Enemies(tagged=1) >= 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and not target.DebuffRemaining(seed_of_corruption_debuff) and not InFlightToTarget(seed_of_corruption) and Spell(seed_of_corruption) or Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 6 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or not Talent(creeping_death_talent) and DebuffCountOnAny(agony_debuff) < 8 and target.TimeToDie() > 10 and { target.DebuffRemaining(agony_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and { target.DebuffRemaining(agony_debuff) < 5 or not AzeriteTraitRank(pandemic_invocation_trait) and target.Refreshable(agony_debuff) } } and Spell(agony) or DebuffCountOnAny(siphon_life_debuff) < 8 - TalentPoints(creeping_death_talent) - Enemies(tagged=1) and target.TimeToDie() > 10 and target.Refreshable(siphon_life_debuff) and { not target.DebuffRemaining(siphon_life_debuff) and Enemies(tagged=1) == 1 or SpellCooldown(summon_darkglare) > SoulShards() * ExecuteTime(unstable_affliction) } and Spell(siphon_life) or Enemies(tagged=1) < 3 + False(raid_events_invulnerable_up) + TalentPoints(writhe_in_agony_talent) and { target.DebuffRemaining(corruption_debuff) <= GCD() or SpellCooldown(summon_darkglare) > 10 and target.Refreshable(corruption_debuff) } and target.TimeToDie() > 10 and Spell(corruption)
}

### actions.fillers

AddFunction AfflictionFillersMainActions
{
 #unstable_affliction,line_cd=15,if=cooldown.deathbolt.remains<=gcd*2&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains>20
 if SpellCooldown(deathbolt) <= GCD() * 2 and SpellCooldown(summon_darkglare) > 20 and TimeSincePreviousSpell(unstable_affliction) > 15 Spell(unstable_affliction)
 #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
 if Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbRefreshMainActions()

 unless Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshMainPostConditions()
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
  if Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbRefreshMainActions()

  unless Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbRefreshMainPostConditions()
  {
   #shadow_bolt,if=buff.movement.up&buff.nightfall.remains
   if Speed() > 0 and BuffPresent(nightfall_buff) Spell(shadow_bolt_affliction)
   #agony,if=buff.movement.up&!(talent.siphon_life.enabled&(prev_gcd.1.agony&prev_gcd.2.agony&prev_gcd.3.agony)|prev_gcd.1.agony)
   if Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } Spell(agony)
   #siphon_life,if=buff.movement.up&!(prev_gcd.1.siphon_life&prev_gcd.2.siphon_life&prev_gcd.3.siphon_life)
   if Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } Spell(siphon_life)
   #corruption,if=buff.movement.up&!prev_gcd.1.corruption&!talent.absolute_corruption.enabled
   if Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) Spell(corruption)
   #drain_life,if=buff.inevitable_demise.stack>10&target.time_to_die<=10
   if BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 Spell(drain_life)
   #drain_life,if=talent.siphon_life.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=2)&dot.agony.remains>5*spell_haste&dot.corruption.remains>gcd&(dot.siphon_life.remains>gcd|!talent.siphon_life.enabled)&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if Talent(siphon_life_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(siphon_life_debuff) > GCD() or not Talent(siphon_life_talent) } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } Spell(drain_life)
   #drain_life,if=talent.writhe_in_agony.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=3)-5*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up=2)&dot.agony.remains>5*spell_haste&dot.corruption.remains>gcd&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if Talent(writhe_in_agony_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 3 } - 5 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) == 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } Spell(drain_life)
   #drain_life,if=talent.absolute_corruption.enabled&buff.inevitable_demise.stack>=50-20*(spell_targets.seed_of_corruption_aoe-raid_event.invulnerable.up>=4)&dot.agony.remains>5*spell_haste&(debuff.haunt.remains>5*spell_haste|!talent.haunt.enabled)&contagion>5*spell_haste
   if Talent(absolute_corruption_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 4 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } Spell(drain_life)
   #haunt
   Spell(haunt)
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
 Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshMainPostConditions() or Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbRefreshMainPostConditions()
}

AddFunction AfflictionFillersShortCdActions
{
 unless SpellCooldown(deathbolt) <= GCD() * 2 and SpellCooldown(summon_darkglare) > 20 and TimeSincePreviousSpell(unstable_affliction) > 15 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbRefreshShortCdActions()

  unless Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshShortCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbRefreshShortCdActions()

   unless Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbRefreshShortCdPostConditions()
   {
    #deathbolt,if=cooldown.summon_darkglare.remains>=30+gcd|cooldown.summon_darkglare.remains>140
    if SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 Spell(deathbolt)

    unless Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 and Spell(drain_life) or Talent(siphon_life_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(siphon_life_debuff) > GCD() or not Talent(siphon_life_talent) } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(writhe_in_agony_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 3 } - 5 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) == 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(absolute_corruption_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 4 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Spell(haunt)
    {
     #focused_azerite_beam
     Spell(focused_azerite_beam)
     #purifying_blast
     Spell(purifying_blast)
    }
   }
  }
 }
}

AddFunction AfflictionFillersShortCdPostConditions
{
 SpellCooldown(deathbolt) <= GCD() * 2 and SpellCooldown(summon_darkglare) > 20 and TimeSincePreviousSpell(unstable_affliction) > 15 and Spell(unstable_affliction) or Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshShortCdPostConditions() or Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbRefreshShortCdPostConditions() or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 and Spell(drain_life) or Talent(siphon_life_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(siphon_life_debuff) > GCD() or not Talent(siphon_life_talent) } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(writhe_in_agony_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 3 } - 5 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) == 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(absolute_corruption_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 4 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Spell(haunt) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

AddFunction AfflictionFillersCdActions
{
 unless SpellCooldown(deathbolt) <= GCD() * 2 and SpellCooldown(summon_darkglare) > 20 and TimeSincePreviousSpell(unstable_affliction) > 15 and Spell(unstable_affliction)
 {
  #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&(dot.agony.remains<dot.agony.duration*0.75|dot.corruption.remains<dot.corruption.duration*0.75|dot.siphon_life.remains<dot.siphon_life.duration*0.75)&cooldown.deathbolt.remains<=action.agony.gcd*4&cooldown.summon_darkglare.remains>20
  if Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 AfflictionDbRefreshCdActions()

  unless Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshCdPostConditions()
  {
   #call_action_list,name=db_refresh,if=talent.deathbolt.enabled&spell_targets.seed_of_corruption_aoe=1+raid_event.invulnerable.up&cooldown.summon_darkglare.remains<=soul_shard*action.agony.gcd+action.agony.gcd*3&(dot.agony.remains<dot.agony.duration*1|dot.corruption.remains<dot.corruption.duration*1|dot.siphon_life.remains<dot.siphon_life.duration*1)
   if Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } AfflictionDbRefreshCdActions()
  }
 }
}

AddFunction AfflictionFillersCdPostConditions
{
 SpellCooldown(deathbolt) <= GCD() * 2 and SpellCooldown(summon_darkglare) > 20 and TimeSincePreviousSpell(unstable_affliction) > 15 and Spell(unstable_affliction) or Talent(deathbolt_talent) and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 0.75 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 0.75 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 0.75 } and SpellCooldown(deathbolt) <= GCD() * 4 and SpellCooldown(summon_darkglare) > 20 and AfflictionDbRefreshCdPostConditions() or Talent(deathbolt_talent) and SpellCooldown(summon_darkglare) <= SoulShards() * GCD() + GCD() * 3 and { target.DebuffRemaining(agony_debuff) < target.DebuffDuration(agony_debuff) * 1 or target.DebuffRemaining(corruption_debuff) < target.DebuffDuration(corruption_debuff) * 1 or target.DebuffRemaining(siphon_life_debuff) < target.DebuffDuration(siphon_life_debuff) * 1 } and AfflictionDbRefreshCdPostConditions() or { SpellCooldown(summon_darkglare) >= 30 + GCD() or SpellCooldown(summon_darkglare) > 140 } and Spell(deathbolt) or Speed() > 0 and BuffPresent(nightfall_buff) and Spell(shadow_bolt_affliction) or Speed() > 0 and not { Talent(siphon_life_talent) and PreviousGCDSpell(agony) and PreviousGCDSpell(agony count=2) and PreviousGCDSpell(agony count=3) or PreviousGCDSpell(agony) } and Spell(agony) or Speed() > 0 and not { PreviousGCDSpell(siphon_life) and PreviousGCDSpell(siphon_life count=2) and PreviousGCDSpell(siphon_life count=3) } and Spell(siphon_life) or Speed() > 0 and not PreviousGCDSpell(corruption) and not Talent(absolute_corruption_talent) and Spell(corruption) or BuffStacks(inevitable_demise_buff) > 10 and target.TimeToDie() <= 10 and Spell(drain_life) or Talent(siphon_life_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(siphon_life_debuff) > GCD() or not Talent(siphon_life_talent) } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(writhe_in_agony_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 3 } - 5 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) == 2 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and target.DebuffRemaining(corruption_debuff) > GCD() and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Talent(absolute_corruption_talent) and BuffStacks(inevitable_demise_buff) >= 50 - 20 * { Enemies(tagged=1) - False(raid_events_invulnerable_up) >= 4 } and target.DebuffRemaining(agony_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and { target.DebuffRemaining(haunt_debuff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } or not Talent(haunt_talent) } and BuffRemaining(unstable_affliction_buff) > 5 * { 100 / { 100 + SpellCastSpeedPercent() } } and Spell(drain_life) or Spell(haunt) or Spell(focused_azerite_beam) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Spell(concentrated_flame_essence) or target.TimeToDie() <= GCD() and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and Spell(drain_soul) or Spell(drain_soul) or Talent(shadow_embrace_talent) and maintain_se() and not target.DebuffPresent(shadow_embrace_debuff) and not InFlightToTarget(shadow_bolt_affliction) and Spell(shadow_bolt_affliction) or Talent(shadow_embrace_talent) and maintain_se() and Spell(shadow_bolt_affliction) or Spell(shadow_bolt_affliction)
}

### actions.precombat

AddFunction AfflictionPrecombatMainActions
{
 #grimoire_of_sacrifice,if=talent.grimoire_of_sacrifice.enabled
 if Talent(grimoire_of_sacrifice_talent) and pet.Present() Spell(grimoire_of_sacrifice)
 #seed_of_corruption,if=spell_targets.seed_of_corruption_aoe>=3&!equipped.azsharas_font_of_power
 if Enemies(tagged=1) >= 3 and not HasEquippedItem(azsharas_font_of_power_item) Spell(seed_of_corruption)
 #haunt
 Spell(haunt)
 #shadow_bolt,if=!talent.haunt.enabled&spell_targets.seed_of_corruption_aoe<3&!equipped.azsharas_font_of_power
 if not Talent(haunt_talent) and Enemies(tagged=1) < 3 and not HasEquippedItem(azsharas_font_of_power_item) Spell(shadow_bolt_affliction)
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
 Enemies(tagged=1) >= 3 and not HasEquippedItem(azsharas_font_of_power_item) and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies(tagged=1) < 3 and not HasEquippedItem(azsharas_font_of_power_item) and Spell(shadow_bolt_affliction)
}

AddFunction AfflictionPrecombatCdActions
{
 unless not pet.Present() and Spell(summon_imp)
 {
  #snapshot_stats
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
  #use_item,name=azsharas_font_of_power
  AfflictionUseItemActions()
 }
}

AddFunction AfflictionPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_imp) or Enemies(tagged=1) >= 3 and not HasEquippedItem(azsharas_font_of_power_item) and Spell(seed_of_corruption) or Spell(haunt) or not Talent(haunt_talent) and Enemies(tagged=1) < 3 and not HasEquippedItem(azsharas_font_of_power_item) and Spell(shadow_bolt_affliction)
}

### actions.spenders

AddFunction AfflictionSpendersMainActions
{
 #unstable_affliction,if=cooldown.summon_darkglare.remains<=soul_shard*(execute_time+azerite.dreadful_calling.rank)&(!talent.deathbolt.enabled|cooldown.deathbolt.remains<=soul_shard*execute_time)&(talent.sow_the_seeds.enabled|dot.phantom_singularity.remains|dot.vile_taint.remains)
 if SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and { Talent(sow_the_seeds_talent) or target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } Spell(unstable_affliction)
 #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
 if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersMainActions()

 unless { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions()
 {
  #seed_of_corruption,if=variable.use_seed
  if use_seed() Spell(seed_of_corruption)
  #unstable_affliction,if=!variable.use_seed&!prev_gcd.1.summon_darkglare&(talent.deathbolt.enabled&cooldown.deathbolt.remains<=execute_time&!azerite.cascading_calamity.enabled|(soul_shard>=5&spell_targets.seed_of_corruption_aoe<2|soul_shard>=2&spell_targets.seed_of_corruption_aoe>=2)&target.time_to_die>4+execute_time&spell_targets.seed_of_corruption_aoe=1|target.time_to_die<=8+execute_time*soul_shard)
  if not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies(tagged=1) < 2 or SoulShards() >= 2 and Enemies(tagged=1) >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies(tagged=1) == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } Spell(unstable_affliction)
  #unstable_affliction,if=!variable.use_seed&contagion<=cast_time+variable.padding
  if not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() Spell(unstable_affliction)
  #unstable_affliction,cycle_targets=1,if=!variable.use_seed&(!talent.deathbolt.enabled|cooldown.deathbolt.remains>time_to_shard|soul_shard>1)&(!talent.vile_taint.enabled|soul_shard>1)&contagion<=cast_time+variable.padding&(!azerite.cascading_calamity.enabled|buff.cascading_calamity.remains>time_to_shard)
  if not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } Spell(unstable_affliction)
 }
}

AddFunction AfflictionSpendersMainPostConditions
{
 { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersMainPostConditions()
}

AddFunction AfflictionSpendersShortCdActions
{
 unless SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and { Talent(sow_the_seeds_talent) or target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersShortCdActions()
 }
}

AddFunction AfflictionSpendersShortCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and { Talent(sow_the_seeds_talent) or target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersShortCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies(tagged=1) < 2 or SoulShards() >= 2 and Enemies(tagged=1) >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies(tagged=1) == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
}

AddFunction AfflictionSpendersCdActions
{
 unless SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and { Talent(sow_the_seeds_talent) or target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } and Spell(unstable_affliction)
 {
  #call_action_list,name=fillers,if=(cooldown.summon_darkglare.remains<time_to_shard*(5-soul_shard)|cooldown.summon_darkglare.up)&time_to_die>cooldown.summon_darkglare.remains
  if { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) AfflictionFillersCdActions()
 }
}

AddFunction AfflictionSpendersCdPostConditions
{
 SpellCooldown(summon_darkglare) <= SoulShards() * { ExecuteTime(unstable_affliction) + AzeriteTraitRank(dreadful_calling_trait) } and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) <= SoulShards() * ExecuteTime(unstable_affliction) } and { Talent(sow_the_seeds_talent) or target.DebuffRemaining(phantom_singularity) or target.DebuffRemaining(vile_taint_debuff) } and Spell(unstable_affliction) or { SpellCooldown(summon_darkglare) < TimeToShard() * { 5 - SoulShards() } or not SpellCooldown(summon_darkglare) > 0 } and target.TimeToDie() > SpellCooldown(summon_darkglare) and AfflictionFillersCdPostConditions() or use_seed() and Spell(seed_of_corruption) or not use_seed() and not PreviousGCDSpell(summon_darkglare) and { Talent(deathbolt_talent) and SpellCooldown(deathbolt) <= ExecuteTime(unstable_affliction) and not HasAzeriteTrait(cascading_calamity_trait) or { SoulShards() >= 5 and Enemies(tagged=1) < 2 or SoulShards() >= 2 and Enemies(tagged=1) >= 2 } and target.TimeToDie() > 4 + ExecuteTime(unstable_affliction) and Enemies(tagged=1) == 1 or target.TimeToDie() <= 8 + ExecuteTime(unstable_affliction) * SoulShards() } and Spell(unstable_affliction) or not use_seed() and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and Spell(unstable_affliction) or not use_seed() and { not Talent(deathbolt_talent) or SpellCooldown(deathbolt) > TimeToShard() or SoulShards() > 1 } and { not Talent(vile_taint_talent) or SoulShards() > 1 } and BuffRemaining(unstable_affliction_buff) <= CastTime(unstable_affliction) + padding() and { not HasAzeriteTrait(cascading_calamity_trait) or BuffRemaining(cascading_calamity_buff) > TimeToShard() } and Spell(unstable_affliction)
}
]]

		OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
	end
end
