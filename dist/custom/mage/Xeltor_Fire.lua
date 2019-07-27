local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFireXeltor = function(OvaleScripts)
do
	local name = "xeltor_fire"
	local desc = "[Xel][8.1] Mage: Fire"
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
	if InCombat() InterruptActions()
	
	if InCombat() and target.InRange(fireball) and HasFullControl()
	{
		# Cooldowns
		if Boss() and {Speed() == 0 or CanMove() > 0 } FireDefaultCdActions()
		
		if Speed() == 0 or CanMove() > 0 FireDefaultShortCdActions()
		
		if Speed() == 0 or CanMove() > 0 FireDefaultMainActions()
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
	}
}

AddFunction FireUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction fire_blast_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(fire_blast) and { SpellCooldown(combustion) > combustion_rop_cutoff() or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait) and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } and SpellCooldown(combustion) < target.TimeToDie() or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 and target.TimeToHealthPercent(90) < SpellCooldown(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait)
}

AddFunction combustion_rop_cutoff
{
 60
}

AddFunction phoenix_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(phoenix_flames) and SpellCooldown(combustion) > combustion_rop_cutoff() and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(phoenix_flames) and SpellCooldown(combustion) < target.TimeToDie()
}

### actions.default

AddFunction FireDefaultMainActions
{
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

AddFunction FireDefaultMainPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseMainPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseMainPostConditions() or FireStandardRotationMainPostConditions()
}

AddFunction FireDefaultShortCdActions
{
 #rune_of_power,if=talent.firestarter.enabled&firestarter.remains>full_recharge_time|cooldown.combustion.remains>variable.combustion_rop_cutoff&buff.combustion.down|target.time_to_die<cooldown.combustion.remains&buff.combustion.down
 if Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) Spell(rune_of_power)
 #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionPhaseShortCdActions()

 unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions()
 {
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

AddFunction FireDefaultShortCdPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseShortCdPostConditions() or FireStandardRotationShortCdPostConditions()
}

AddFunction FireDefaultCdActions
{
 #counterspell
 # FireInterruptActions()
 #mirror_image,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(mirror_image)

 unless { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power)
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

AddFunction FireDefaultCdPostConditions
{
 { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power) or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionPhaseCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseCdPostConditions() or FireStandardRotationCdPostConditions()
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

### actions.bm_combustion_phase

AddFunction FireBmCombustionPhaseMainActions
{
 #living_bomb,if=buff.combustion.down&active_enemies>1
 if BuffExpires(combustion_buff) and Enemies(tagged=1) > 1 Spell(living_bomb)
 #call_action_list,name=active_talents
 FireActiveTalentsMainActions()

 unless FireActiveTalentsMainPostConditions()
 {
  #call_action_list,name=trinkets
  FireTrinketsMainActions()

  unless FireTrinketsMainPostConditions()
  {
   #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up
   if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) Spell(pyroblast)
   #pyroblast,if=buff.hot_streak.up
   if BuffPresent(hot_streak_buff) Spell(pyroblast)
   #pyroblast,if=buff.pyroclasm.react&cast_time<buff.combustion.remains
   if DebuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(combustion_buff) Spell(pyroblast)
   #phoenix_flames
   Spell(phoenix_flames)
   #scorch,if=buff.hot_streak.down&(cooldown.fire_blast.remains<cast_time|action.fire_blast.charges>0)
   if BuffExpires(hot_streak_buff) and { SpellCooldown(fire_blast) < CastTime(scorch) or Charges(fire_blast) > 0 } Spell(scorch)
   #living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1
   if BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 Spell(living_bomb)
   #scorch
   Spell(scorch)
  }
 }
}

AddFunction FireBmCombustionPhaseMainPostConditions
{
 FireActiveTalentsMainPostConditions() or FireTrinketsMainPostConditions()
}

AddFunction FireBmCombustionPhaseShortCdActions
{
 unless BuffExpires(combustion_buff) and Enemies(tagged=1) > 1 and Spell(living_bomb)
 {
  #rune_of_power,if=buff.combustion.down
  if BuffExpires(combustion_buff) Spell(rune_of_power)
  #fire_blast,use_while_casting=1,if=buff.blaster_master.down&(talent.rune_of_power.enabled&action.rune_of_power.executing&action.rune_of_power.execute_remains<0.6|(cooldown.combustion.ready|buff.combustion.up)&!talent.rune_of_power.enabled&!action.pyroblast.in_flight&!action.fireball.in_flight)
  if BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } Spell(fire_blast)
  #call_action_list,name=active_talents
  FireActiveTalentsShortCdActions()

  unless FireActiveTalentsShortCdPostConditions()
  {
   #call_action_list,name=trinkets
   FireTrinketsShortCdActions()

   unless FireTrinketsShortCdPostConditions() or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(combustion_buff) and Spell(pyroblast) or Spell(phoenix_flames)
   {
    #fire_blast,use_off_gcd=1,if=buff.blaster_master.stack=1&buff.hot_streak.down&!buff.pyroclasm.react&prev_gcd.1.pyroblast&(buff.blaster_master.remains<0.15|gcd.remains<0.15)
    if BuffStacks(blaster_master_buff) == 1 and BuffExpires(hot_streak_buff) and not DebuffPresent(pyroclasm) and PreviousGCDSpell(pyroblast) and { BuffRemaining(blaster_master_buff) < 0.15 or GCDRemaining() < 0.15 } Spell(fire_blast)
    #fire_blast,use_while_casting=1,if=buff.blaster_master.stack=1&(action.scorch.executing&action.scorch.execute_remains<0.15|buff.blaster_master.remains<0.15)
    if BuffStacks(blaster_master_buff) == 1 and { ExecuteTime(scorch) > 0 and ExecuteTime(scorch) < 0.15 or BuffRemaining(blaster_master_buff) < 0.15 } Spell(fire_blast)

    unless BuffExpires(hot_streak_buff) and { SpellCooldown(fire_blast) < CastTime(scorch) or Charges(fire_blast) > 0 } and Spell(scorch)
    {
     #fire_blast,use_while_casting=1,use_off_gcd=1,if=buff.blaster_master.stack>1&(prev_gcd.1.scorch&!buff.hot_streak.up&!action.scorch.executing|buff.blaster_master.remains<0.15)
     if BuffStacks(blaster_master_buff) > 1 and { PreviousGCDSpell(scorch) and not BuffPresent(hot_streak_buff) and not ExecuteTime(scorch) > 0 or BuffRemaining(blaster_master_buff) < 0.15 } Spell(fire_blast)

     unless BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb)
     {
      #dragons_breath,if=buff.combustion.remains<gcd.max
      if BuffRemaining(combustion_buff) < GCD() and target.Distance(less 12) Spell(dragons_breath)
     }
    }
   }
  }
 }
}

AddFunction FireBmCombustionPhaseShortCdPostConditions
{
 BuffExpires(combustion_buff) and Enemies(tagged=1) > 1 and Spell(living_bomb) or FireActiveTalentsShortCdPostConditions() or FireTrinketsShortCdPostConditions() or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(combustion_buff) and Spell(pyroblast) or Spell(phoenix_flames) or BuffExpires(hot_streak_buff) and { SpellCooldown(fire_blast) < CastTime(scorch) or Charges(fire_blast) > 0 } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or Spell(scorch)
}

AddFunction FireBmCombustionPhaseCdActions
{
 #lights_judgment,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(lights_judgment)

 unless BuffExpires(combustion_buff) and Enemies(tagged=1) > 1 and Spell(living_bomb) or BuffExpires(combustion_buff) and Spell(rune_of_power)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()

  unless FireActiveTalentsCdPostConditions()
  {
   #combustion,use_off_gcd=1,use_while_casting=1,if=azerite.blaster_master.enabled&((action.meteor.in_flight&action.meteor.in_flight_remains<0.2)|!talent.meteor.enabled|prev_gcd.1.meteor)&(buff.rune_of_power.up|!talent.rune_of_power.enabled)
   if HasAzeriteTrait(blaster_master_trait) and { InFlightToTarget(meteor) and 0 < 0.2 or not Talent(meteor_talent) or PreviousGCDSpell(meteor) } and { BuffPresent(rune_of_power_buff) or not Talent(rune_of_power_talent) } Spell(combustion)
   #potion
   # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
   #call_action_list,name=trinkets
   FireTrinketsCdActions()
  }
 }
}

AddFunction FireBmCombustionPhaseCdPostConditions
{
 BuffExpires(combustion_buff) and Enemies(tagged=1) > 1 and Spell(living_bomb) or BuffExpires(combustion_buff) and Spell(rune_of_power) or FireActiveTalentsCdPostConditions() or FireTrinketsCdPostConditions() or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(combustion_buff) and Spell(pyroblast) or Spell(phoenix_flames) or BuffExpires(hot_streak_buff) and { SpellCooldown(fire_blast) < CastTime(scorch) or Charges(fire_blast) > 0 } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or BuffRemaining(combustion_buff) < GCD() and target.Distance(less 12) and Spell(dragons_breath) or Spell(scorch)
}

### actions.combustion_phase

AddFunction FireCombustionPhaseMainActions
{
 #call_action_list,name=bm_combustion_phase,if=azerite.blaster_master.enabled&talent.flame_on.enabled
 if HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) FireBmCombustionPhaseMainActions()

 unless HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseMainPostConditions()
 {
  #call_action_list,name=active_talents
  FireActiveTalentsMainActions()

  unless FireActiveTalentsMainPostConditions()
  {
   #call_action_list,name=trinkets
   FireTrinketsMainActions()

   unless FireTrinketsMainPostConditions()
   {
    #flamestrike,if=((talent.flame_patch.enabled&active_enemies>2)|active_enemies>6)&buff.hot_streak.react
    if { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
    #pyroblast,if=buff.pyroclasm.react&buff.combustion.remains>cast_time
    if DebuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) Spell(pyroblast)
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
 }
}

AddFunction FireCombustionPhaseMainPostConditions
{
 HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseMainPostConditions() or FireActiveTalentsMainPostConditions() or FireTrinketsMainPostConditions()
}

AddFunction FireCombustionPhaseShortCdActions
{
 #call_action_list,name=bm_combustion_phase,if=azerite.blaster_master.enabled&talent.flame_on.enabled
 if HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) FireBmCombustionPhaseShortCdActions()

 unless HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseShortCdPostConditions()
 {
  #rune_of_power,if=buff.combustion.down
  if BuffExpires(combustion_buff) Spell(rune_of_power)
  #call_action_list,name=active_talents
  FireActiveTalentsShortCdActions()

  unless FireActiveTalentsShortCdPostConditions()
  {
   #call_action_list,name=trinkets
   FireTrinketsShortCdActions()

   unless FireTrinketsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or DebuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
   {
    #fire_blast,use_off_gcd=1,use_while_casting=1,if=(!azerite.blaster_master.enabled|!talent.flame_on.enabled)&((buff.combustion.up&(buff.heating_up.react&!action.pyroblast.in_flight&!action.scorch.executing)|(action.scorch.execute_remains&buff.heating_up.down&buff.hot_streak.down&!action.pyroblast.in_flight)))
    if { not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) } and { BuffPresent(combustion_buff) and BuffPresent(heating_up_buff) and not InFlightToTarget(pyroblast) and not ExecuteTime(scorch) > 0 or ExecuteTime(scorch) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) and not InFlightToTarget(pyroblast) } Spell(fire_blast)

    unless PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb)
    {
     #dragons_breath,if=buff.combustion.remains<gcd.max&buff.combustion.up
     if BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) Spell(dragons_breath)
    }
   }
  }
 }
}

AddFunction FireCombustionPhaseShortCdPostConditions
{
 HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseShortCdPostConditions() or FireActiveTalentsShortCdPostConditions() or FireTrinketsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or DebuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
}

AddFunction FireCombustionPhaseCdActions
{
 #lights_judgment,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(lights_judgment)
 #call_action_list,name=bm_combustion_phase,if=azerite.blaster_master.enabled&talent.flame_on.enabled
 if HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) FireBmCombustionPhaseCdActions()

 unless HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseCdPostConditions() or BuffExpires(combustion_buff) and Spell(rune_of_power)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()

  unless FireActiveTalentsCdPostConditions()
  {
   #combustion,use_off_gcd=1,use_while_casting=1,if=(!azerite.blaster_master.enabled|!talent.flame_on.enabled)&((action.meteor.in_flight&action.meteor.in_flight_remains<=0.5)|!talent.meteor.enabled)&(buff.rune_of_power.up|!talent.rune_of_power.enabled)
   if { not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) } and { InFlightToTarget(meteor) and 0 <= 0.5 or not Talent(meteor_talent) } and { BuffPresent(rune_of_power_buff) or not Talent(rune_of_power_talent) } Spell(combustion)
   #potion
   # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
   #call_action_list,name=trinkets
   FireTrinketsCdActions()
  }
 }
}

AddFunction FireCombustionPhaseCdPostConditions
{
 HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and FireBmCombustionPhaseCdPostConditions() or BuffExpires(combustion_buff) and Spell(rune_of_power) or FireActiveTalentsCdPostConditions() or FireTrinketsCdPostConditions() or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 6 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or DebuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies(tagged=1) > 1 and Spell(living_bomb) or BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) and Spell(dragons_breath) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
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
  #snapshot_stats
  #mirror_image
  Spell(mirror_image)
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
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
  if DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) Spell(pyroblast)
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

  unless FireActiveTalentsShortCdPostConditions() or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast)
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
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsShortCdPostConditions() or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 5 } and Spell(flamestrike) or Spell(fireball)
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
 Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsCdPostConditions() or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies(tagged=1) == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Enemies(tagged=1) > 2 and target.Distance(less 12) and Spell(dragons_breath) or { Talent(flame_patch_talent) and Enemies(tagged=1) > 2 or Enemies(tagged=1) > 5 } and Spell(flamestrike) or Spell(fireball)
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
 #pyroblast,if=buff.hot_streak.react&target.health.pct<=30&talent.searing_touch.enabled
 if BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(pyroblast)
 #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains
 if DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) Spell(pyroblast)
 #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&((talent.flame_patch.enabled&active_enemies=1&!firestarter.active)|(active_enemies<4&!talent.flame_patch.enabled))
 if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } Spell(pyroblast)
 #phoenix_flames,if=(buff.heating_up.react|(!buff.hot_streak.react&(action.fire_blast.charges>0|talent.searing_touch.enabled&target.health.pct<=30)))&!variable.phoenix_pooling
 if { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() Spell(phoenix_flames)
 #call_action_list,name=active_talents
 FireActiveTalentsMainActions()

 unless FireActiveTalentsMainPostConditions()
 {
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
  #fireball
  Spell(fireball)
  #scorch
  Spell(scorch)
 }
}

AddFunction FireStandardRotationMainPostConditions
{
 FireActiveTalentsMainPostConditions()
}

AddFunction FireStandardRotationShortCdActions
{
 unless { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and Spell(pyroblast)
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
   }
  }
 }
}

AddFunction FireStandardRotationShortCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActiveTalentsShortCdPostConditions() or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}

AddFunction FireStandardRotationCdActions
{
 unless { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActiveTalentsCdActions()
 }
}

AddFunction FireStandardRotationCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies(tagged=1) > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or DebuffPresent(pyroclasm) and CastTime(pyroblast) < DebuffRemaining(pyroclasm) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies(tagged=1) == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies(tagged=1) < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActiveTalentsCdPostConditions() or Enemies(tagged=1) > 1 and target.Distance(less 12) and Spell(dragons_breath) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}

### actions.trinkets

AddFunction FireTrinketsMainActions
{
}

AddFunction FireTrinketsMainPostConditions
{
}

AddFunction FireTrinketsShortCdActions
{
}

AddFunction FireTrinketsShortCdPostConditions
{
}

AddFunction FireTrinketsCdActions
{
 #use_items
 FireUseItemActions()
}

AddFunction FireTrinketsCdPostConditions
{
}
]]

		OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
	end
end