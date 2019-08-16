local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFrostXeltor = function(OvaleScripts)
do
	local name = "xeltor_frost"
	local desc = "[Xel][8.2] Mage: Frost"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddIcon specialization=3 help=main
{
	if not mounted() and not PlayerIsResting() and not IsDead()
	{
		#arcane_intellect
		if not BuffPresent(arcane_intellect_buff any=1) and not { target.IsFriend() or target.Present() } Spell(arcane_intellect)
		if not target.BuffPresent(arcane_intellect_buff any=1) and target.IsFriend() Spell(arcane_intellect)
		#summon_arcane_familiar
		if not pet.Present() Spell(summon_water_elemental)
	}
	
	if InCombat() InterruptActions()
	
	if InCombat() and not target.IsFriend() SafetyDance()
	
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

AddFunction SafetyDance
{
	if target.istargetingplayer() and { target.distance() <= 8 or IncomingDamage(3) >= MaxHealth() * 0.01 } and not BuffPresent(ice_barrier_buff) Spell(ice_barrier)
	if target.Distance(less 12) and not target.DebuffPresent(frost_nova_debuff) and target.IsPvP() and not IsBossFight() Spell(frost_nova)
	if target.BuffStealable() and target.InRange(spellsteal) and not PreviousGCDSpell(spellsteal) Spell(spellsteal)
}

AddFunction FrostUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 FrostAoeMainActions()

  unless { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsShortCdActions()

 unless FrostCooldownsShortCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 FrostAoeShortCdActions()

  unless { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeShortCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleShortCdActions()
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 FrostCooldownsShortCdPostConditions() or { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 # FrostInterruptActions()
 #call_action_list,name=cooldowns
 FrostCooldownsCdActions()

 unless FrostCooldownsCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 FrostAoeCdActions()

  unless { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleCdActions()
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 FrostCooldownsCdPostConditions() or { Enemies(tagged=1) > 3 and Talent(freezing_rain_talent) or Enemies(tagged=1) > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 Spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  Spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } Spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
  #ray_of_frost
  Spell(ray_of_frost)
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
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 Spell(frozen_orb)

 unless Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike)
   {
    #cone_of_cold
    if target.Distance() < 12 Spell(cone_of_cold)

    unless Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 Spell(blizzard) or FrostEssencesShortCdPostConditions() or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless Spell(frozen_orb) or Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 Spell(frozen_orb) or Spell(blizzard) or FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentRopMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentRopMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 Spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentRopShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentRopShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #icy_veins
 Spell(icy_veins)
 #mirror_image
 Spell(mirror_image)

 unless { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentRopCdActions()

  unless Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentRopCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   # if { PreviousGCDSpell(icy_veins) or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
   #use_item,name=balefire_branch,if=!talent.glacial_spike.enabled|buff.brain_freeze.react&prev_gcd.1.glacial_spike
   if not Talent(glacial_spike_talent) or BuffPresent(brain_freeze_buff) and PreviousGCDSpell(glacial_spike) FrostUseItemActions()
   #use_items
   FrostUseItemActions()
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #lights_judgment
   Spell(lights_judgment)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power) or Talent(rune_of_power_talent) and Enemies(tagged=1) == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentRopCdPostConditions()
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down
 if BuffExpires(rune_of_power_buff) and TimeSincePreviousSpell(concentrated_flame_essence) > 6 Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 Spell(focused_azerite_beam)
 #blood_of_the_enemy,if=(talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|prev_gcd.1.ebonbolt))|((active_enemies>3|!talent.glacial_spike.enabled)&(prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5))
 if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) } or { Enemies(tagged=1) > 3 or not Talent(glacial_spike_talent) } and { PreviousGCDSpell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 } Spell(blood_of_the_enemy)
 #purifying_blast,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 Spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 Spell(ripple_in_space_essence)

 unless BuffExpires(rune_of_power_buff) and TimeSincePreviousSpell(concentrated_flame_essence) > 6 and Spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down|active_enemies>3
  if BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 BuffExpires(rune_of_power_buff) and TimeSincePreviousSpell(concentrated_flame_essence) > 6 and Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 unless { BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 } and Spell(focused_azerite_beam)
 {
  #memory_of_lucid_dreams,if=active_enemies<5&(buff.icicles.stack<=1|!talent.glacial_spike.enabled)&cooldown.frozen_orb.remains>10
  if Enemies(tagged=1) < 5 and { BuffStacks(icicles_buff) <= 1 or not Talent(glacial_spike_talent) } and SpellCooldown(frozen_orb) > 10 Spell(memory_of_lucid_dreams_essence)
 }
}

AddFunction FrostEssencesCdPostConditions
{
 { BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 } and Spell(focused_azerite_beam) or { BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 } and Spell(purifying_blast) or { BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 } and Spell(ripple_in_space_essence) or BuffExpires(rune_of_power_buff) and TimeSincePreviousSpell(concentrated_flame_essence) > 6 and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or { BuffExpires(rune_of_power_buff) or Enemies(tagged=1) > 3 } and Spell(worldvein_resonance_essence)
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
 #blink_any,if=movement.distance>10
 # if target.Distance() > 10 and CheckBoxOn(opt_blink) Spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if BuffExpires(ice_floes_buff) and Speed() > 0 Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 # target.Distance() > 10 and CheckBoxOn(opt_blink) and Spell(blink)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless Spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.Present() Spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FrostUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental) or Spell(frostbolt)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) Spell(ice_nova)
 #flurry,if=talent.ebonbolt.enabled&prev_gcd.1.ebonbolt&buff.brain_freeze.react
 if Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) Spell(flurry)
 #flurry,if=prev_gcd.1.glacial_spike&buff.brain_freeze.react
 if PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) Spell(flurry)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #blizzard,if=active_enemies>2|active_enemies>1&!talent.splitting_ice.enabled
  if Enemies(tagged=1) > 2 or Enemies(tagged=1) > 1 and not Talent(splitting_ice_talent) Spell(blizzard)
  #ebonbolt,if=buff.icicles.stack=5&!buff.brain_freeze.react
  if BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) Spell(ebonbolt)
  #glacial_spike,if=buff.brain_freeze.react|prev_gcd.1.ebonbolt|talent.incanters_flow.enabled&cast_time+travel_time>incanters_flow_time_to.5.up&cast_time+travel_time<incanters_flow_time_to.4.down
  if BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) Spell(glacial_spike)
  #ice_nova
  Spell(ice_nova)
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
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   Spell(frozen_orb)

   unless { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard)
   {
    #comet_storm
    Spell(comet_storm)

    unless BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or FrostEssencesShortCdPostConditions() or { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or Spell(comet_storm) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or Spell(comet_storm) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.talent_rop

AddFunction FrostTalentRopMainActions
{
}

AddFunction FrostTalentRopMainPostConditions
{
}

AddFunction FrostTalentRopShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } Spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } Spell(rune_of_power)
}

AddFunction FrostTalentRopShortCdPostConditions
{
}

AddFunction FrostTalentRopCdActions
{
}

AddFunction FrostTalentRopCdPostConditions
{
 Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } and Spell(rune_of_power) or not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } and Spell(rune_of_power)
}
]]

		OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
	end
end