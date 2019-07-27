local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
if not __exports then return end
__exports.registerWarriorFuryXeltor = function(OvaleScripts)
do
	local name = "xeltor_fury"
	local desc = "[Xel][8.1.5] Warrior: Fury"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

# Fury
AddIcon specialization=2 help=main
{
	if not mounted() and not PlayerIsResting() and not Dead()
	{
		#battle_shout
		if not BuffPresent(battle_shout any=1) and not target.IsFriend() Spell(battle_shout)
	}
	if InCombat()
	{
		if not target.IsFriend() or target.IsPvP() InterruptActions()
		ControlActions()
	}
	
    if target.InRange(rampage) and not IsStunned() and not IsIncapacitated() and not IsFeared()
	{
		if Spell(victory_rush) Spell(victory_rush)
		if not target.IsFriend() and HealthPercent() < 60 and Spell(bloodthirst) Spell(enraged_regeneration)
		
		# Cooldowns
		FuryDefaultCdActions()
		
		# Short Cooldowns
		FuryDefaultShortCdActions()
		
		# Default rotation
		FuryDefaultMainActions()
	}
	
	# On the move
	if not target.InRange(rampage) and InCombat() and not IsStunned() and not IsIncapacitated() and not IsFeared()
	{
		if target.InRange(charge) and { TimeInCombat() < 6 or Falling() } Spell(charge)
		if target.InRange(heroic_throw) Spell(heroic_throw)
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(intimidating_shout) and not target.Classification(worldboss) and target.IsPvP() Spell(intimidating_shout)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
		if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
		if target.InRange(pummel) and target.IsInterruptible() Spell(pummel)
	}
}

AddFunction ControlActions
{
	if { IsIncapacitated() or IsStunned() } and SpellCooldown(every_man_for_himself) <= 0 Spell(every_man_for_himself)
	if { IsFeared() or IsIncapacitated() or IsStunned() or IsRooted() } and SpellCooldown(berserker_rage) <= 0 Spell(berserker_rage)
	if not target.DebuffPresent(piercing_howl_debuff) and not target.IsFriend() and target.Distance(less 15) and target.IsPvP() and not target.InRange(rampage) Spell(piercing_howl)
}

AddFunction FuryUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction FuryDefaultMainActions
{
 #run_action_list,name=movement,if=movement.distance>5
 if target.Distance() > 5 FuryMovementMainActions()

 unless target.Distance() > 5 and FuryMovementMainPostConditions()
 {
  #furious_slash,if=talent.furious_slash.enabled&(buff.furious_slash.stack<3|buff.furious_slash.remains<3|(cooldown.recklessness.remains<3&buff.furious_slash.remains<9))
  if Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } Spell(furious_slash)
  #rampage,if=cooldown.recklessness.remains<3
  if SpellCooldown(recklessness) < 3 Spell(rampage)
  #whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up
  if Enemies(tagged=1) > 1 and not BuffPresent(whirlwind_buff) Spell(whirlwind_fury)
  #run_action_list,name=single_target
  FurySingleTargetMainActions()
 }
}

AddFunction FuryDefaultMainPostConditions
{
 target.Distance() > 5 and FuryMovementMainPostConditions() or FurySingleTargetMainPostConditions()
}

AddFunction FuryDefaultShortCdActions
{
 #auto_attack
 # FuryGetInMeleeRange()
 #charge
 # if CheckBoxOn(opt_melee_range) and target.InRange(charge) Spell(charge)
 #run_action_list,name=movement,if=movement.distance>5
 if target.Distance() > 5 FuryMovementShortCdActions()

 unless target.Distance() > 5 and FuryMovementShortCdPostConditions()
 {
  #heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
  # if { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)

  unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies(tagged=1) > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
  {
   #run_action_list,name=single_target
   FurySingleTargetShortCdActions()
  }
 }
}

AddFunction FuryDefaultShortCdPostConditions
{
 target.Distance() > 5 and FuryMovementShortCdPostConditions() or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies(tagged=1) > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingleTargetShortCdPostConditions()
}

AddFunction FuryDefaultCdActions
{
 # FuryInterruptActions()
 #run_action_list,name=movement,if=movement.distance>5
 if target.Distance() > 5 FuryMovementCdActions()

 unless target.Distance() > 5 and FuryMovementCdPostConditions()
 {
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)

  unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage)
  {
   #recklessness,if=!talent.siegebreaker.enabled|(cooldown.siegebreaker.remains<1|cooldown.siegebreaker.remains>5)
   if not Talent(siegebreaker_talent) or SpellCooldown(siegebreaker) < 1 or SpellCooldown(siegebreaker) > 5 Spell(recklessness)

   unless Enemies(tagged=1) > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
   {
    #use_item,name=ramping_amplitude_gigavolt_engine
    FuryUseItemActions()
    #blood_fury
    Spell(blood_fury_ap)
    #berserking
    Spell(berserking)
    #lights_judgment,if=buff.recklessness.down
    if BuffExpires(recklessness_buff) Spell(lights_judgment)
    #fireblood
    Spell(fireblood)
    #ancestral_call
    Spell(ancestral_call)
    #run_action_list,name=single_target
    FurySingleTargetCdActions()
   }
  }
 }
}

AddFunction FuryDefaultCdPostConditions
{
 target.Distance() > 5 and FuryMovementCdPostConditions() or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies(tagged=1) > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingleTargetCdPostConditions()
}

### actions.movement

AddFunction FuryMovementMainActions
{
}

AddFunction FuryMovementMainPostConditions
{
}

AddFunction FuryMovementShortCdActions
{
 #heroic_leap
 # if CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
}

AddFunction FuryMovementShortCdPostConditions
{
}

AddFunction FuryMovementCdActions
{
}

AddFunction FuryMovementCdPostConditions
{
}

### actions.precombat

AddFunction FuryPrecombatMainActions
{
}

AddFunction FuryPrecombatMainPostConditions
{
}

AddFunction FuryPrecombatShortCdActions
{
}

AddFunction FuryPrecombatShortCdPostConditions
{
}

AddFunction FuryPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)
 #recklessness,if=!talent.furious_slash.enabled&!talent.reckless_abandon.enabled
 if not Talent(furious_slash_talent) and not Talent(reckless_abandon_talent) Spell(recklessness)
}

AddFunction FuryPrecombatCdPostConditions
{
}

### actions.single_target

AddFunction FurySingleTargetMainActions
{
 #rampage,if=buff.recklessness.up|(talent.frothing_berserker.enabled|talent.carnage.enabled&(buff.enrage.remains<gcd|rage>90)|talent.massacre.enabled&(buff.enrage.remains<gcd|rage>90))
 if BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } Spell(rampage)
 #execute
 Spell(execute)
 #bloodthirst,if=buff.enrage.down|azerite.cold_steel_hot_blood.rank>1
 if not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 Spell(bloodthirst)
 #raging_blow,if=charges=2
 if Charges(raging_blow) == 2 Spell(raging_blow)
 #bloodthirst
 Spell(bloodthirst)
 #raging_blow,if=talent.carnage.enabled|(talent.massacre.enabled&rage<80)|(talent.frothing_berserker.enabled&rage<90)
 if Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 Spell(raging_blow)
 #furious_slash,if=talent.furious_slash.enabled
 if Talent(furious_slash_talent) Spell(furious_slash)
 #whirlwind
 Spell(whirlwind_fury)
}

AddFunction FurySingleTargetMainPostConditions
{
}

AddFunction FurySingleTargetShortCdActions
{
 #siegebreaker
 Spell(siegebreaker)

 unless { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute)
 {
  #bladestorm,if=prev_gcd.1.rampage
  if PreviousGCDSpell(rampage) Spell(bladestorm_fury)

  unless { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst)
  {
   #dragon_roar,if=buff.enrage.up
   if IsEnraged() Spell(dragon_roar)
  }
 }
}

AddFunction FurySingleTargetShortCdPostConditions
{
 { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
}

AddFunction FurySingleTargetCdActions
{
}

AddFunction FurySingleTargetCdPostConditions
{
 Spell(siegebreaker) or { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or PreviousGCDSpell(rampage) and Spell(bladestorm_fury) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or IsEnraged() and Spell(dragon_roar) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
}
]]

		OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
	end
end