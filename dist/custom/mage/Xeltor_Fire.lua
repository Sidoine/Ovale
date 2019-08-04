local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFireXeltor = function(OvaleScripts)
do
	local name = "xeltor_fire"
	local desc = "[Xel][8.2] Mage: Fire"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

Define(blazing_barrier 235313)
	SpellInfo(blazing_barrier cd=25)
Define(blazing_barrier_buff 235313)
	SpellInfo(blazing_barrier_buff duration=60)
Define(ice_block 45438)
	SpellInfo(ice_block cd=300)
	SpellAddBuff(ice_block ice_block_buff=1)
	SpellAddDebuff(ice_block hypothermia_debuff=1)
Define(ice_block_buff 45438)
	SpellInfo(ice_block_buff duration=10)
Define(hypothermia_debuff 41425)
	SpellInfo(hypothermia_debuff duration=30)

AddIcon specialization=2 help=main
{
	# Precombat
	if not mounted() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		# self cast.
		if not BuffPresent(arcane_intellect_buff) and { not target.Present() or target.Present() and not target.IsFriend() } Spell(arcane_intellect)
		# friend cast.
		if not target.BuffPresent(arcane_intellect_buff) and target.Present() and target.IsFriend() Spell(arcane_intellect)
	}

	if InCombat() InterruptActions()
	
	if InCombat() and target.InRange(fireball) and HasFullControl()
	{
		if IncomingDamage(5) > 0 and target.istargetingplayer() and not BuffPresent(blazing_barrier_buff) Spell(blazing_barrier)
		
		# Cooldowns
		if Speed() == 0 or CanMove() > 0 FireDefaultCdActions()
		
		if Speed() == 0 or CanMove() > 0 FireDefaultShortCdActions()
		
		if Speed() == 0 or CanMove() > 0 FireDefaultMainActions()
		
		if Speed() > 0 Spell(scorch)
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.Distance(less 12) and not target.Classification(worldboss) Spell(dragons_breath)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
	}
}

AddFunction FireUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction on_use_cutoff
{
 20 * combustion_on_use() and not font_double_on_use() + 40 * font_double_on_use() + 25 * HasEquippedItem(azsharas_font_of_power_item) and not font_double_on_use()
}

AddFunction font_double_on_use
{
 HasEquippedItem(azsharas_font_of_power_item) and combustion_on_use()
}

AddFunction combustion_on_use
{
 HasEquippedItem(notorious_aspirants_badge_item) or HasEquippedItem(notorious_gladiators_badge_item) or HasEquippedItem(sinister_gladiators_badge_item) or HasEquippedItem(sinister_aspirants_badge_item) or HasEquippedItem(dread_gladiators_badge_item) or HasEquippedItem(dread_aspirants_badge_item) or HasEquippedItem(dread_combatants_insignia_item) or HasEquippedItem(notorious_aspirants_medallion_item) or HasEquippedItem(notorious_gladiators_medallion_item) or HasEquippedItem(sinister_gladiators_medallion_item) or HasEquippedItem(sinister_aspirants_medallion_item) or HasEquippedItem(dread_gladiators_medallion_item) or HasEquippedItem(dread_aspirants_medallion_item) or HasEquippedItem(dread_combatants_medallion_item) or HasEquippedItem(ignition_mages_fuse_item) or HasEquippedItem(tzanes_barkspines_item) or HasEquippedItem(azurethos_singed_plumage_item) or HasEquippedItem(ancient_knot_of_wisdom_item) or HasEquippedItem(shockbiters_fang_item) or HasEquippedItem(neural_synapse_enhancer_item) or HasEquippedItem(balefire_branch_item)
}

AddFunction combustion_rop_cutoff
{
 60
}

AddFunction fire_blast_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(fire_blast) and { SpellCooldown(combustion) > combustion_rop_cutoff() or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait) and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } and SpellCooldown(combustion) < target.TimeToDie() or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 and target.TimeToHealthPercent(90) < SpellCooldown(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait)
}

AddFunction phoenix_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(phoenix_flames) and SpellCooldown(combustion) > combustion_rop_cutoff() and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(phoenix_flames) and SpellCooldown(combustion) < target.TimeToDie()
}

### actions.default

AddFunction FireDefaultMainActions
{
 #call_action_list,name=items_high_priority
 FireItemsHighPriorityMainActions()

 unless FireItemsHighPriorityMainPostConditions()
 {
  #concentrated_flame
  Spell(concentrated_flame_essence)
  #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionPhaseMainActions()

  unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseMainPostConditions()
  {
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseMainActions()

   unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseMainPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardRotationMainActions()
   }
  }
 }
}

AddFunction FireDefaultMainPostConditions
{
 FireItemsHighPriorityMainPostConditions() or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseMainPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseMainPostConditions() or FireStandardRotationMainPostConditions()
}

AddFunction FireDefaultShortCdActions
{
 #call_action_list,name=items_high_priority
 FireItemsHighPriorityShortCdActions()

 unless FireItemsHighPriorityShortCdPostConditions() or Spell(concentrated_flame_essence)
 {
  #focused_azerite_beam
  Spell(focused_azerite_beam)
  #purifying_blast
  Spell(purifying_blast)
  #ripple_in_space
  Spell(ripple_in_space_essence)
  #the_unbound_force
  Spell(the_unbound_force)
  #worldvein_resonance
  Spell(worldvein_resonance_essence)
  #rune_of_power,if=talent.firestarter.enabled&firestarter.remains>full_recharge_time|cooldown.combustion.remains>variable.combustion_rop_cutoff&buff.combustion.down|target.time_to_die<cooldown.combustion.remains&buff.combustion.down
  if Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) Spell(rune_of_power)
  #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionPhaseShortCdActions()

  unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions()
  {
   #fire_blast,use_while_casting=1,use_off_gcd=1,if=(essence.memory_of_lucid_dreams.major|essence.memory_of_lucid_dreams.minor&azerite.blaster_master.enabled)&charges=max_charges&!buff.hot_streak.react&!(buff.heating_up.react&(buff.combustion.up&(action.fireball.in_flight|action.pyroblast.in_flight|action.scorch.executing)|target.health.pct<=30&action.scorch.executing))&!(!buff.heating_up.react&!buff.hot_streak.react&buff.combustion.down&(action.fireball.in_flight|action.pyroblast.in_flight))
   if { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } Spell(fire_blast)
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseShortCdActions()

   unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseShortCdPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardRotationShortCdActions()
   }
  }
 }
}

AddFunction FireDefaultShortCdPostConditions
{
 FireItemsHighPriorityShortCdPostConditions() or Spell(concentrated_flame_essence) or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseShortCdPostConditions() or FireStandardRotationShortCdPostConditions()
}

AddFunction FireDefaultCdActions
{
 #counterspell
 # FireInterruptActions()
 #call_action_list,name=items_high_priority
 FireItemsHighPriorityCdActions()

 unless FireItemsHighPriorityCdPostConditions()
 {
  #mirror_image,if=buff.combustion.down
  if BuffExpires(combustion_buff) Spell(mirror_image)

  unless Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(ripple_in_space_essence) or Spell(the_unbound_force) or Spell(worldvein_resonance_essence) or { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power)
  {
   #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
   if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionPhaseCdActions()

   unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseCdPostConditions()
   {
    #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
    if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseCdActions()

    unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseCdPostConditions()
    {
     #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
     #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
     #call_action_list,name=standard_rotation
     FireStandardRotationCdActions()
    }
   }
  }
 }
}

AddFunction FireDefaultCdPostConditions
{
 FireItemsHighPriorityCdPostConditions() or Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(ripple_in_space_essence) or Spell(the_unbound_force) or Spell(worldvein_resonance_essence) or { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power) or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseCdPostConditions() or FireStandardRotationCdPostConditions()
}

### actions.active_talents

AddFunction FireActiveTalentsMainActions
{
 #living_bomb,if=active_enemies>1&buff.combustion.down&(cooldown.combustion.remains>cooldown.living_bomb.duration|cooldown.combustion.ready)
 if Enemies(tagged=1) > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } Spell(living_bomb)
}

AddFunction FireActiveTalentsMainPostConditions
{
}

AddFunction FireActiveTalentsShortCdActions
{
 unless Enemies(tagged=1) > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb)
 {
  #meteor,if=buff.rune_of_power.up&(firestarter.remains>cooldown.meteor.duration|!firestarter.active)|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1|(cooldown.meteor.duration<cooldown.combustion.remains|cooldown.combustion.ready)&!talent.rune_of_power.enabled&(cooldown.meteor.duration<firestarter.remains|!talent.firestarter.enabled|!firestarter.active)
  if BuffPresent(rune_of_power_buff) and { target.TimeToHealthPercent(90) > SpellCooldownDuration(meteor) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 or { SpellCooldownDuration(meteor) < SpellCooldown(combustion) or SpellCooldown(combustion) == 0 } and not Talent(rune_of_power_talent) and { SpellCooldownDuration(meteor) < target.TimeToHealthPercent(90) or not Talent(firestarter_talent) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } Spell(meteor)
 }
}

AddFunction FireActiveTalentsShortCdPostConditions
{
 Enemies(tagged=1) > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb)
}

AddFunction FireActiveTalentsCdActions
{
}

AddFunction FireActiveTalentsCdPostConditions
{
 Enemies(tagged=1) > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb)
}

### actions.combustion_phase

AddFunction FireCombustionPhaseMainActions
{
 #call_action_list,name=active_talents
 FireActiveTalentsMainActions()

 unless FireActiveTalentsMainPostConditions()
 {
  #flamestrike,if=((talent.flame_patch.enabled&active_enemies>2)|active_enemies>6)&buff.hot_streak.react&!azerite.blaster_master.enabled
  if { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) Spell(flamestrike)
  #pyroblast,if=buff.pyroclasm.react&buff.combustion.remains>cast_time
  if BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) Spell(pyroblast)
  #pyroblast,if=buff.hot_streak.react
  if BuffPresent(hot_streak_buff) Spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up
  if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) Spell(pyroblast)
  #phoenix_flames
  Spell(phoenix_flames)
  #scorch,if=buff.combustion.remains>cast_time&buff.combustion.up|buff.combustion.down
  if BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) Spell(scorch)
  #living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1
  if BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 Spell(living_bomb)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
 }
}

AddFunction FireCombustionPhaseMainPostConditions
{
 FireActiveTalentsMainPostConditions()
}

AddFunction FireCombustionPhaseShortCdActions
{
 #fire_blast,use_while_casting=1,use_off_gcd=1,if=charges>=1&((action.fire_blast.charges_fractional+(buff.combustion.remains-buff.blaster_master.duration)%cooldown.fire_blast.duration-(buff.combustion.remains)%(buff.blaster_master.duration-0.5))>=0|!azerite.blaster_master.enabled|!talent.flame_on.enabled|buff.combustion.remains<=buff.blaster_master.duration|buff.blaster_master.remains<0.5|equipped.hyperthread_wristwraps&cooldown.hyperthread_wristwraps_300142.remains<5)&buff.combustion.up&(!action.scorch.executing&!action.pyroblast.in_flight&buff.heating_up.up|action.scorch.executing&buff.hot_streak.down&(buff.heating_up.down|azerite.blaster_master.enabled)|azerite.blaster_master.enabled&talent.flame_on.enabled&action.pyroblast.in_flight&buff.heating_up.down&buff.hot_streak.down)
 if Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } Spell(fire_blast)
 #rune_of_power,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(rune_of_power)
 #fire_blast,use_while_casting=1,if=azerite.blaster_master.enabled&talent.flame_on.enabled&buff.blaster_master.down&(talent.rune_of_power.enabled&action.rune_of_power.executing&action.rune_of_power.execute_remains<0.6|(cooldown.combustion.ready|buff.combustion.up)&!talent.rune_of_power.enabled&!action.pyroblast.in_flight&!action.fireball.in_flight)
 if HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } Spell(fire_blast)
 #call_action_list,name=active_talents
 FireActiveTalentsShortCdActions()

 unless FireActiveTalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb)
 {
  #dragons_breath,if=buff.combustion.remains<gcd.max&buff.combustion.up
  if BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) Spell(dragons_breath)
 }
}

AddFunction FireCombustionPhaseShortCdPostConditions
{
 FireActiveTalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
}

AddFunction FireCombustionPhaseCdActions
{
 #lights_judgment,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(lights_judgment)
 #blood_of_the_enemy
 Spell(blood_of_the_enemy)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)

 unless BuffExpires(combustion_buff) and Spell(rune_of_power)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()

  unless FireActiveTalentsCdPostConditions()
  {
   #combustion,use_off_gcd=1,use_while_casting=1,if=((action.meteor.in_flight&action.meteor.in_flight_remains<=0.5)|!talent.meteor.enabled)&(buff.rune_of_power.up|!talent.rune_of_power.enabled)
   if { InFlightToTarget(meteor) and 0 <= 0.5 or not Talent(meteor_talent) } and { BuffPresent(rune_of_power_buff) or not Talent(rune_of_power_talent) } Spell(combustion)
   #potion
   # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FireCombustionPhaseCdPostConditions
{
 BuffExpires(combustion_buff) and Spell(rune_of_power) or FireActiveTalentsCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) and Spell(dragons_breath) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
}

### actions.items_combustion

AddFunction FireItemsCombustionMainActions
{
}

AddFunction FireItemsCombustionMainPostConditions
{
}

AddFunction FireItemsCombustionShortCdActions
{
}

AddFunction FireItemsCombustionShortCdPostConditions
{
}

AddFunction FireItemsCombustionCdActions
{
 #use_item,name=ignition_mages_fuse
 FireUseItemActions()
 #use_item,name=hyperthread_wristwraps,if=buff.combustion.up&(action.fire_blast.full_recharge_time>=10+gcd.remains|action.fire_blast.charges=0&action.fire_blast.recharge_time>gcd.remains)
 if BuffPresent(combustion_buff) and { SpellFullRecharge(fire_blast) >= 10 + GCDRemaining() or Charges(fire_blast) == 0 and SpellChargeCooldown(fire_blast) > GCDRemaining() } FireUseItemActions()
 #use_item,use_off_gcd=1,name=azurethos_singed_plumage,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,effect_name=gladiators_badge,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,effect_name=gladiators_medallion,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=balefire_branch,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=shockbiters_fang,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=tzanes_barkspines,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=ancient_knot_of_wisdom,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=neural_synapse_enhancer,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=malformed_heralds_legwraps,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
}

AddFunction FireItemsCombustionCdPostConditions
{
}

### actions.items_high_priority

AddFunction FireItemsHighPriorityMainActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemsCombustionMainActions()
}

AddFunction FireItemsHighPriorityMainPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemsCombustionMainPostConditions()
}

AddFunction FireItemsHighPriorityShortCdActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemsCombustionShortCdActions()
}

AddFunction FireItemsHighPriorityShortCdPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemsCombustionShortCdPostConditions()
}

AddFunction FireItemsHighPriorityCdActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemsCombustionCdActions()

 unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemsCombustionCdPostConditions()
 {
  #use_items
  FireUseItemActions()
  #use_item,name=azsharas_font_of_power,if=cooldown.combustion.remains<=5+15*variable.font_double_on_use
  if SpellCooldown(combustion) <= 5 + 15 * font_double_on_use() FireUseItemActions()
  #use_item,name=rotcrusted_voodoo_doll,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=aquipotent_nautilus,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=shiver_venom_relic,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,effect_name=harmonic_dematerializer
  FireUseItemActions()
  #use_item,name=malformed_heralds_legwraps,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 55 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=ancient_knot_of_wisdom,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 55 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=neural_synapse_enhancer,if=cooldown.combustion.remains>=45&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 45 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
 }
}

AddFunction FireItemsHighPriorityCdPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemsCombustionCdPostConditions()
}

### actions.items_low_priority

AddFunction FireItemsLowPriorityMainActions
{
}

AddFunction FireItemsLowPriorityMainPostConditions
{
}

AddFunction FireItemsLowPriorityShortCdActions
{
}

AddFunction FireItemsLowPriorityShortCdPostConditions
{
}

AddFunction FireItemsLowPriorityCdActions
{
 #use_item,name=tidestorm_codex,if=cooldown.combustion.remains>variable.on_use_cutoff|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if SpellCooldown(combustion) > on_use_cutoff() or Talent(firestarter_talent) and target.TimeToHealthPercent(90) > on_use_cutoff() FireUseItemActions()
 #use_item,effect_name=cyclotronic_blast,if=cooldown.combustion.remains>variable.on_use_cutoff|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if SpellCooldown(combustion) > on_use_cutoff() or Talent(firestarter_talent) and target.TimeToHealthPercent(90) > on_use_cutoff() FireUseItemActions()
}

AddFunction FireItemsLowPriorityCdPostConditions
{
}

### actions.precombat

AddFunction FirePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #pyroblast
 Spell(pyroblast)
}

AddFunction FirePrecombatMainPostConditions
{
}

AddFunction FirePrecombatShortCdActions
{
}

AddFunction FirePrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(pyroblast)
}

AddFunction FirePrecombatCdActions
{
 unless Spell(arcane_intellect)
 {
  #variable,name=combustion_rop_cutoff,op=set,value=60
  #variable,name=combustion_on_use,op=set,value=equipped.notorious_aspirants_badge|equipped.notorious_gladiators_badge|equipped.sinister_gladiators_badge|equipped.sinister_aspirants_badge|equipped.dread_gladiators_badge|equipped.dread_aspirants_badge|equipped.dread_combatants_insignia|equipped.notorious_aspirants_medallion|equipped.notorious_gladiators_medallion|equipped.sinister_gladiators_medallion|equipped.sinister_aspirants_medallion|equipped.dread_gladiators_medallion|equipped.dread_aspirants_medallion|equipped.dread_combatants_medallion|equipped.ignition_mages_fuse|equipped.tzanes_barkspines|equipped.azurethos_singed_plumage|equipped.ancient_knot_of_wisdom|equipped.shockbiters_fang|equipped.neural_synapse_enhancer|equipped.balefire_branch
  #variable,name=font_double_on_use,op=set,value=equipped.azsharas_font_of_power&variable.combustion_on_use
  #variable,name=on_use_cutoff,op=set,value=20*variable.combustion_on_use&!variable.font_double_on_use+40*variable.font_double_on_use+25*equipped.azsharas_font_of_power&!variable.font_double_on_use
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FireUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
 }
}

AddFunction FirePrecombatCdPostConditions
{
 Spell(arcane_intellect) or Spell(pyroblast)
}

### actions.rop_phase

AddFunction FireRopPhaseMainActions
{
 #flamestrike,if=((talent.flame_patch.enabled&active_enemies>1)|active_enemies>4)&buff.hot_streak.react
 if { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react
 if BuffPresent(hot_streak_buff) Spell(pyroblast)
 #call_action_list,name=active_talents
 FireActiveTalentsMainActions()

 unless FireActiveTalentsMainPostConditions()
 {
  #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains&buff.rune_of_power.remains>cast_time
  if BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) Spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&(!talent.flame_patch.enabled|active_enemies=1)
  if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } Spell(pyroblast)
  #phoenix_flames,if=!prev_gcd.1.phoenix_flames&buff.heating_up.react
  if not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) Spell(phoenix_flames)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
  #flamestrike,if=(talent.flame_patch.enabled&active_enemies>2)|active_enemies>5
  if Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 5 Spell(flamestrike)
  #fireball
  Spell(fireball)
 }
}

AddFunction FireRopPhaseMainPostConditions
{
 FireActiveTalentsMainPostConditions()
}

AddFunction FireRopPhaseShortCdActions
{
 #rune_of_power
 Spell(rune_of_power)

 unless { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
 {
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&(!buff.heating_up.react&!buff.hot_streak.react&!prev_off_gcd.fire_blast&(action.fire_blast.charges>=2|(action.phoenix_flames.charges>=1&talent.phoenix_flames.enabled)|(talent.alexstraszas_fury.enabled&cooldown.dragons_breath.ready)|(talent.searing_touch.enabled&target.health.pct<=30)|(talent.firestarter.enabled&firestarter.active)))
  if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } Spell(fire_blast)
  #call_action_list,name=active_talents
  FireActiveTalentsShortCdActions()

  unless FireActiveTalentsShortCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast)
  {
   #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&(buff.heating_up.react&(target.health.pct>=30|!talent.searing_touch.enabled))
   if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and BuffPresent(heating_up_buff) and { target.HealthPercent() >= 30 or not Talent(searing_touch_talent) } Spell(fire_blast)
   #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.heating_up.react&!buff.hot_streak.react)
   if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } Spell(fire_blast)

   unless PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
   {
    #dragons_breath,if=active_enemies>2
    if Enemies(tagged=1) > 2 and target.Distance(less 12) Spell(dragons_breath)
   }
  }
 }
}

AddFunction FireRopPhaseShortCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsShortCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 5 } and Spell(flamestrike) or Spell(fireball)
}

AddFunction FireRopPhaseCdActions
{
 unless Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()
 }
}

AddFunction FireRopPhaseCdPostConditions
{
 Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Enemies(tagged=1) > 2 and target.Distance(less 12) and Spell(dragons_breath) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 5 } and Spell(flamestrike) or Spell(fireball)
}

### actions.standard_rotation

AddFunction FireStandardRotationMainActions
{
 #flamestrike,if=((talent.flame_patch.enabled&active_enemies>1&!firestarter.active)|active_enemies>4)&buff.hot_streak.react
 if { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react&buff.hot_streak.remains<action.fireball.execute_time
 if BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) Spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&(prev_gcd.1.fireball|firestarter.active|action.pyroblast.in_flight)
 if BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } Spell(pyroblast)
 #phoenix_flames,if=charges>=3&active_enemies>2&!variable.phoenix_pooling
 if Charges(phoenix_flames) >= 3 and Enemies(tagged=1) > 2 and not phoenix_pooling() Spell(phoenix_flames)
 #pyroblast,if=buff.hot_streak.react&target.health.pct<=30&talent.searing_touch.enabled
 if BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(pyroblast)
 #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains
 if BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) Spell(pyroblast)
 #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&((talent.flame_patch.enabled&active_enemies=1&!firestarter.active)|(active_enemies<4&!talent.flame_patch.enabled))
 if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } Spell(pyroblast)
 #phoenix_flames,if=(buff.heating_up.react|(!buff.hot_streak.react&(action.fire_blast.charges>0|talent.searing_touch.enabled&target.health.pct<=30)))&!variable.phoenix_pooling
 if { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() Spell(phoenix_flames)
 #call_action_list,name=active_talents
 FireActiveTalentsMainActions()

 unless FireActiveTalentsMainPostConditions()
 {
  #call_action_list,name=items_low_priority
  FireItemsLowPriorityMainActions()

  unless FireItemsLowPriorityMainPostConditions()
  {
   #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
   if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
   #fireball
   Spell(fireball)
   #scorch
   Spell(scorch)
  }
 }
}

AddFunction FireStandardRotationMainPostConditions
{
 FireActiveTalentsMainPostConditions() or FireItemsLowPriorityMainPostConditions()
}

AddFunction FireStandardRotationShortCdActions
{
 unless { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies(tagged=1) > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast)
 {
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0&buff.rune_of_power.down|firestarter.active)&!talent.kindling.enabled&!variable.fire_blast_pooling&(((action.fireball.executing|action.pyroblast.executing)&(buff.heating_up.react|firestarter.active&!buff.hot_streak.react&!buff.heating_up.react))|(talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!action.pyroblast.in_flight&!action.fireball.in_flight))|(firestarter.active&(action.pyroblast.in_flight|action.fireball.in_flight)&!buff.heating_up.react&!buff.hot_streak.react))
  if { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } Spell(fire_blast)
  #fire_blast,if=talent.kindling.enabled&buff.heating_up.react&(cooldown.combustion.remains>full_recharge_time+2+talent.kindling.enabled|firestarter.remains>full_recharge_time|(!talent.rune_of_power.enabled|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1)&cooldown.combustion.remains>target.time_to_die)
  if Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } Spell(fire_blast)

  unless PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames)
  {
   #call_action_list,name=active_talents
   FireActiveTalentsShortCdActions()

   unless FireActiveTalentsShortCdPostConditions()
   {
    #dragons_breath,if=active_enemies>1
    if Enemies(tagged=1) > 1 and target.Distance(less 12) Spell(dragons_breath)
    #call_action_list,name=items_low_priority
    FireItemsLowPriorityShortCdActions()
   }
  }
 }
}

AddFunction FireStandardRotationShortCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies(tagged=1) > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActiveTalentsShortCdPostConditions() or FireItemsLowPriorityShortCdPostConditions() or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}

AddFunction FireStandardRotationCdActions
{
 unless { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies(tagged=1) > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()

  unless FireActiveTalentsCdPostConditions() or Enemies(tagged=1) > 1 and target.Distance(less 12) and Spell(dragons_breath)
  {
   #call_action_list,name=items_low_priority
   FireItemsLowPriorityCdActions()
  }
 }
}

AddFunction FireStandardRotationCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies(tagged=1) > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActiveTalentsCdPostConditions() or Enemies(tagged=1) > 1 and target.Distance(less 12) and Spell(dragons_breath) or FireItemsLowPriorityCdPostConditions() or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}
]]

		OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
	end
end