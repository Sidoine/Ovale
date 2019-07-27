local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFrostXeltor = function(OvaleScripts)
do
	local name = "xeltor_frost"
	local desc = "[Xel][7.3] Mage: Frost"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

Define(frostjaw 102051)
Define(ice_block_buff 45438)

AddIcon specialization=3 help=main
{
	if InCombat() InterruptActions()
	
	if BuffExpires(ice_barrier) and IncomingDamage(5) > 0 and not mounted() and not { target.Classification(worldboss) or BuffPresent(burst_haste_buff any=1) } Spell(ice_barrier)
	
	if InCombat() and target.InRange(frostbolt) and HasFullControl()
	{
		if BuffExpires(ice_floes_buff) and not { Speed() == 0 or CanMove() > 0 } Spell(ice_floes)
		
		# Cooldowns
		if Boss()
		{
			if Speed() == 0 or CanMove() > 0 FrostDefaultCdActions()
		}
		if Speed() == 0 or CanMove() > 0 FrostDefaultShortCdActions()
		if Speed() == 0 or CanMove() > 0 FrostDefaultMainActions()
		#ice_lance,moving=1
		if Speed() > 0 Spell(ice_lance)
	}
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible() and { target.MustBeInterrupted() or Level() < 100 or target.IsPVP() }
	{
		if target.InRange(counterspell) Spell(counterspell)
		if not target.Classification(worldboss)
		{
			if target.Distance(less 8) Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #ice_lance,if=!buff.fingers_of_frost.react&prev_gcd.1.flurry
 if not BuffPresent(fingers_of_frost_buff) and PreviousGCDSpell(flurry) Spell(ice_lance)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>=3
  if Enemies(tagged=1) >= 3 FrostAoeMainActions()

  unless Enemies(tagged=1) >= 3 and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or Enemies(tagged=1) >= 3 and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 unless not BuffPresent(fingers_of_frost_buff) and PreviousGCDSpell(flurry) and Spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>=3
   if Enemies(tagged=1) >= 3 FrostAoeShortCdActions()

   unless Enemies(tagged=1) >= 3 and FrostAoeShortCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleShortCdActions()
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 not BuffPresent(fingers_of_frost_buff) and PreviousGCDSpell(flurry) and Spell(ice_lance) or FrostCooldownsShortCdPostConditions() or Enemies(tagged=1) >= 3 and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 # FrostInterruptActions()

 unless not BuffPresent(fingers_of_frost_buff) and PreviousGCDSpell(flurry) and Spell(ice_lance)
 {
  #time_warp,if=buff.bloodlust.down&(buff.exhaustion.down|equipped.shard_of_the_exodar)&(cooldown.icy_veins.remains<1|target.time_to_die<50)
  # if BuffExpires(burst_haste_buff any=1) and { DebuffExpires(burst_haste_debuff any=1) or HasEquippedItem(shard_of_the_exodar) } and { SpellCooldown(icy_veins) < 1 or target.TimeToDie() < 50 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>=3
   if Enemies(tagged=1) >= 3 FrostAoeCdActions()

   unless Enemies(tagged=1) >= 3 and FrostAoeCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleCdActions()
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 not BuffPresent(fingers_of_frost_buff) and PreviousGCDSpell(flurry) and Spell(ice_lance) or FrostCooldownsCdPostConditions() or Enemies(tagged=1) >= 3 and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #frostbolt,if=prev_off_gcd.water_jet
 if PreviousOffGCDSpell(water_elemental_water_jet) Spell(frostbolt)
 #blizzard
 Spell(blizzard)
 #ice_nova
 if target.Distance(less 8) Spell(ice_nova)
 #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.glacial_spike|prev_gcd.1.frostbolt)
 if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } Spell(flurry)
 #ice_lance,if=buff.fingers_of_frost.react
 if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
 #ebonbolt
 Spell(ebonbolt)
 #glacial_spike
 Spell(glacial_spike)
 #frostbolt
 Spell(frostbolt)
 #call_action_list,name=movement
 FrostMovementMainActions()

 unless FrostMovementMainPostConditions()
 {
  #ice_lance
  Spell(ice_lance)
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 unless PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt)
 {
  #frozen_orb
  Spell(frozen_orb)

  unless Spell(blizzard)
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova)
   {
    #water_jet,if=prev_gcd.1.frostbolt&buff.fingers_of_frost.stack<3&!buff.brain_freeze.react
    if PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and not BuffPresent(brain_freeze_buff) Spell(water_elemental_water_jet)

    unless { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry)
    {
     #frost_bomb,if=debuff.frost_bomb.remains<action.ice_lance.travel_time&buff.fingers_of_frost.react
     if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) Spell(frost_bomb)

     unless BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt)
     {
      #call_action_list,name=movement
      FrostMovementShortCdActions()

      unless FrostMovementShortCdPostConditions()
      {
       #cone_of_cold
       if target.Distance(less 12) Spell(cone_of_cold)
      }
     }
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or Spell(blizzard) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or Spell(frozen_orb) or Spell(blizzard) or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) and Spell(frost_bomb) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt)
 {
  #call_action_list,name=movement
  FrostMovementCdActions()
 }
}

AddFunction FrostAoeCdPostConditions
{
 PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or Spell(frozen_orb) or Spell(blizzard) or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) and Spell(frost_bomb) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(cone_of_cold) or Spell(ice_lance)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
}

AddFunction FrostCooldownsMainPostConditions
{
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=cooldown.icy_veins.remains<cast_time|charges_fractional>1.9&cooldown.icy_veins.remains>10|buff.icy_veins.up|target.time_to_die+5<charges_fractional*10
 if SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 Spell(rune_of_power)
}

AddFunction FrostCooldownsShortCdPostConditions
{
}

AddFunction FrostCooldownsCdActions
{
 unless { SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 } and Spell(rune_of_power)
 {
  #potion,if=cooldown.icy_veins.remains<1|target.time_to_die<70
  # if SpellCooldown(icy_veins) < 1 or target.TimeToDie() < 70 Item(prolonged_power_potion)
  #icy_veins
  Spell(icy_veins)
  #mirror_image
  Spell(mirror_image)
  #use_items
  # FrostUseItemActions()
  #blood_fury
  Spell(blood_fury_sp)
  #berserking
  Spell(berserking)
  #arcane_torrent
  Spell(arcane_torrent_mana)
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 } and Spell(rune_of_power)
}

### actions.movement

AddFunction FrostMovementMainActions
{
}

AddFunction FrostMovementMainPostConditions
{
}

AddFunction FrostMovementShortCdActions
{
 #blink,if=movement.distance>10
 # if target.Distance() > 10 Spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if BuffExpires(ice_floes_buff) Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.Distance() > 10 and Spell(blink) or BuffExpires(ice_floes_buff) and Spell(ice_floes)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #water_elemental
 if not pet.Present() Spell(water_elemental)
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless not pet.Present() and Spell(water_elemental)
 {
  #snapshot_stats
  #mirror_image
  Spell(mirror_image)
  #potion
  Item(prolonged_power_potion)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 not pet.Present() and Spell(water_elemental) or Spell(frostbolt)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=debuff.winters_chill.up
 if target.DebuffPresent(winters_chill_debuff) and target.Distance(less 8) Spell(ice_nova)
 #frostbolt,if=prev_off_gcd.water_jet
 if PreviousOffGCDSpell(water_elemental_water_jet) Spell(frostbolt)
 #ray_of_frost,if=buff.icy_veins.up|cooldown.icy_veins.remains>action.ray_of_frost.cooldown&buff.rune_of_power.down
 if BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) Spell(ray_of_frost)
 #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.glacial_spike|prev_gcd.1.frostbolt&(!talent.glacial_spike.enabled|buff.icicles.stack<=4|cooldown.frozen_orb.remains<=10&set_bonus.tier20_2pc))
 if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 4 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } Spell(flurry)
 #blizzard,if=cast_time=0&active_enemies>1&buff.fingers_of_frost.react<3
 if CastTime(blizzard) == 0 and Enemies(tagged=1) > 1 and BuffStacks(fingers_of_frost_buff) < 3 Spell(blizzard)
 #ice_lance,if=buff.fingers_of_frost.react
 if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
 #ebonbolt
 Spell(ebonbolt)
 #ice_nova
 if target.Distance(less 8) Spell(ice_nova)
 #blizzard,if=active_enemies>1|buff.zannesu_journey.stack=5&buff.zannesu_journey.remains>cast_time
 if Enemies(tagged=1) > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) Spell(blizzard)
 #frostbolt,if=buff.frozen_mass.remains>execute_time+action.glacial_spike.execute_time+action.glacial_spike.travel_time&!buff.brain_freeze.react&talent.glacial_spike.enabled
 if BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and not BuffPresent(brain_freeze_buff) and Talent(glacial_spike_talent) Spell(frostbolt)
 #glacial_spike,if=cooldown.frozen_orb.remains>10|!set_bonus.tier20_2pc
 if SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) Spell(glacial_spike)
 #frostbolt
 Spell(frostbolt)
 #call_action_list,name=movement
 FrostMovementMainActions()

 unless FrostMovementMainPostConditions()
 {
  #blizzard
  Spell(blizzard)
  #ice_lance
  Spell(ice_lance)
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt)
 {
  #water_jet,if=prev_gcd.1.frostbolt&buff.fingers_of_frost.stack<3&!buff.brain_freeze.react
  if PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and not BuffPresent(brain_freeze_buff) Spell(water_elemental_water_jet)

  unless { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 4 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry)
  {
   #frozen_orb,if=set_bonus.tier20_2pc&buff.fingers_of_frost.react<3
   if ArmorSetBonus(T20 2) and BuffStacks(fingers_of_frost_buff) < 3 Spell(frozen_orb)

   unless CastTime(blizzard) == 0 and Enemies(tagged=1) > 1 and BuffStacks(fingers_of_frost_buff) < 3 and Spell(blizzard)
   {
    #frost_bomb,if=debuff.frost_bomb.remains<action.ice_lance.travel_time&buff.fingers_of_frost.react
    if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) Spell(frost_bomb)

    unless BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt)
    {
     #frozen_orb
     Spell(frozen_orb)

     unless Spell(ice_nova)
     {
      #comet_storm
      Spell(comet_storm)

      unless { Enemies(tagged=1) > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and not BuffPresent(brain_freeze_buff) and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt)
      {
       #call_action_list,name=movement
       FrostMovementShortCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 4 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry) or CastTime(blizzard) == 0 and Enemies(tagged=1) > 1 and BuffStacks(fingers_of_frost_buff) < 3 and Spell(blizzard) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(ice_nova) or { Enemies(tagged=1) > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and not BuffPresent(brain_freeze_buff) and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(blizzard) or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 4 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry) or ArmorSetBonus(T20 2) and BuffStacks(fingers_of_frost_buff) < 3 and Spell(frozen_orb) or CastTime(blizzard) == 0 and Enemies(tagged=1) > 1 and BuffStacks(fingers_of_frost_buff) < 3 and Spell(blizzard) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) and Spell(frost_bomb) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(frozen_orb) or Spell(ice_nova) or Spell(comet_storm) or { Enemies(tagged=1) > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and not BuffPresent(brain_freeze_buff) and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt)
 {
  #call_action_list,name=movement
  FrostMovementCdActions()
 }
}

AddFunction FrostSingleCdPostConditions
{
 target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 4 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry) or ArmorSetBonus(T20 2) and BuffStacks(fingers_of_frost_buff) < 3 and Spell(frozen_orb) or CastTime(blizzard) == 0 and Enemies(tagged=1) > 1 and BuffStacks(fingers_of_frost_buff) < 3 and Spell(blizzard) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and BuffPresent(fingers_of_frost_buff) and Spell(frost_bomb) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or Spell(frozen_orb) or Spell(ice_nova) or Spell(comet_storm) or { Enemies(tagged=1) > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and not BuffPresent(brain_freeze_buff) and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(blizzard) or Spell(ice_lance)
}
]]

		OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
	end
end