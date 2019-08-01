local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warlock")
if not __exports then return end
__exports.registerWarlockDemonologyXeltor = function(OvaleScripts)
do
	local name = "xeltor_demonology"
	local desc = "[Xel][8.2] Warlock: Demonology"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warlock_spells)

Define(spell_lock_fh 19647)
	SpellInfo(spell_lock_fh cd=24)
Define(pet_auto_spin 89751)
	SpellInfo(pet_auto_spin duration=5)

AddIcon specialization=2 help=main
{
	# if not Mounted() and not Pet.CreatureFamily(Felguard) and not Pet.Present() and not Pet.Exists() Texture(spell_warlock_summonwrathguard)
	
	# Interrupt
	if InCombat() InterruptActions()
	
	# Save ass
	SaveActions()
	
	if wet() and not mounted() and not BuffPresent(unending_breath) Spell(unending_breath)
	
	# Rotation
	if InCombat() and target.InRange(shadow_bolt) and HasFullControl()
    {
		PetStuff()
		
		# Control stuff
		
		if Speed() == 0 or CanMove() > 0
		{
			# Cooldowns
			if Boss() DemonologyDefaultCdActions()
			
			# Short Cooldowns
			DemonologyDefaultShortCdActions()
			
			# Default rotation
			DemonologyDefaultMainActions()
		}
		if Speed() > 0 and SoulShards() < 4 and BuffStacks(demonic_core_buff) >= 1 Spell(demonbolt)
	}
	
	if not InCombat() and not mounted() OutOfCombatActions()
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		# Felhunter Spell Lock
		if target.Distance() - pet.Distance() <= 40 and pet.CreatureFamily(Felhunter) Spell(spell_lock_fh)
		if pet.CreatureFamily(Felguard) and not target.Classification(worldboss) Spell(pet_axe_toss)
	}
}

AddFunction PetStuff
{
	if not pet.Present() and { Speed() == 0 or CanMove() > 0 } and SpellUsable(summon_felguard) Texture(spell_warlock_summonwrathguard)
	if pet.Health() < pet.HealthMissing() and pet.Present() and Speed() == 0 and SpellUsable(health_funnel) Texture(ability_deathwing_bloodcorruption_death)
}

AddFunction SaveActions
{
	if HealthPercent() < 30 and InCombat() Spell(unending_resolve)
	if HealthPercent() < 50 
	{
		if ItemCharges(healthstone) > 0 and ItemCooldown(healthstone) <= GCD() and Item(healthstone usable=1) Texture(inv_stone_04)
		if Speed() == 0 Spell(drain_life)
	}
}

AddFunction OutOfCombatActions
{
	if not ItemCharges(healthstone) > 0 and Speed() == 0 and SpellUsable(create_healthstone) and not PreviousGCDSpell(create_healthstone) Texture(inv_misc_gem_bloodstone_01)
}

AddFunction DemonologyUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction DemonologyDefaultMainActions
{
 #call_action_list,name=dcon_opener,if=talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconOpenerMainActions()

 unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerMainPostConditions()
 {
  #hand_of_guldan,if=azerite.explosive_potential.rank&time<5&soul_shard>2&buff.explosive_potential.down&buff.wild_imps.stack<3&!prev_gcd.1.hand_of_guldan&&!prev_gcd.2.hand_of_guldan
  if AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) Spell(hand_of_guldan)
  #demonbolt,if=soul_shard<=3&buff.demonic_core.up&buff.demonic_core.stack=4
  if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 Spell(demonbolt)
  #implosion,if=azerite.explosive_potential.rank&buff.wild_imps.stack>2&buff.explosive_potential.remains<action.shadow_bolt.execute_time&(!talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains>12)
  if AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } Spell(implosion)
  #doom,if=!ticking&time_to_die>30&spell_targets.implosion<2
  if not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies(tagged=1) < 2 Spell(doom)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 DemonologyNetherPortalMainActions()

  unless Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalMainPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies(tagged=1) > 1 DemonologyImplosionMainActions()

   unless Enemies(tagged=1) > 1 and DemonologyImplosionMainPostConditions()
   {
    #call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
    if SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 Spell(call_dreadstalkers)
    #hand_of_guldan,if=(azerite.baleful_invocation.enabled|talent.demonic_consumption.enabled)&prev_gcd.1.hand_of_guldan&cooldown.summon_demonic_tyrant.remains<2
    if { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 Spell(hand_of_guldan)
    #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
    if Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies(tagged=1) < 2 Spell(power_siphon)
    #doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
    if Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 Spell(doom)
    #hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(cooldown.summon_demonic_tyrant.remains>20|(cooldown.summon_demonic_tyrant.remains<gcd*2&talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains<gcd*4&!talent.demonic_consumption.enabled))&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
    if SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } Spell(hand_of_guldan)
    #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
    if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
    #demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<6|cooldown.summon_demonic_tyrant.remains>22&!azerite.shadows_bite.enabled)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25|buff.shadows_bite.remains)
    if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite_buff) } Spell(demonbolt)
    #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&!pet.demonic_tyrant.active
    if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 Spell(concentrated_flame_essence)
    #call_action_list,name=build_a_shard
    DemonologyBuildAShardMainActions()
   }
  }
 }
}

AddFunction DemonologyDefaultMainPostConditions
{
 Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerMainPostConditions() or Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalMainPostConditions() or Enemies(tagged=1) > 1 and DemonologyImplosionMainPostConditions() or DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyDefaultShortCdActions
{
 #worldvein_resonance,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(worldvein_resonance_essence)
 #ripple_in_space,if=pet.demonic_tyrant.active|target.time_to_die<=15
 if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 Spell(ripple_in_space_essence)
 #call_action_list,name=dcon_opener,if=talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
 if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconOpenerShortCdActions()

 unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerShortCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies(tagged=1) < 2 and Spell(doom)
 {
  #bilescourge_bombers,if=azerite.explosive_potential.rank>0&time<10&spell_targets.implosion<2&buff.dreadstalkers.remains&talent.nether_portal.enabled
  if AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies(tagged=1) < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) Spell(bilescourge_bombers)
  #demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
  if { Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies(tagged=1) < 2 } and not pet.BuffPresent(pet_auto_spin) Spell(demonic_strength)
  #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
  if Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 DemonologyNetherPortalShortCdActions()

  unless Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalShortCdPostConditions()
  {
   #call_action_list,name=implosion,if=spell_targets.implosion>1
   if Enemies(tagged=1) > 1 DemonologyImplosionShortCdActions()

   unless Enemies(tagged=1) > 1 and DemonologyImplosionShortCdPostConditions()
   {
    #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

    unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
    {
     #the_unbound_force,if=buff.reckless_force.react
     if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
     #bilescourge_bombers
     Spell(bilescourge_bombers)

     unless { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies(tagged=1) < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite_buff) } and Spell(demonbolt)
     {
      #purifying_blast
      Spell(purifying_blast)

      unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence)
      {
       #call_action_list,name=build_a_shard
       DemonologyBuildAShardShortCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultShortCdPostConditions
{
 Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerShortCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies(tagged=1) < 2 and Spell(doom) or Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalShortCdPostConditions() or Enemies(tagged=1) > 1 and DemonologyImplosionShortCdPostConditions() or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies(tagged=1) < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite_buff) } and Spell(demonbolt) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyDefaultCdActions
{
 #potion,if=pet.demonic_tyrant.active&(!talent.nether_portal.enabled|cooldown.nether_portal.remains>160)|target.time_to_die<30
 # if { DemonDuration(demonic_tyrant) > 0 and { not Talent(nether_portal_talent) or SpellCooldown(nether_portal) > 160 } or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
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
  if Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 DemonologyDconOpenerCdActions()

  unless Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies(tagged=1) < 2 and Spell(doom) or AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies(tagged=1) < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) and Spell(bilescourge_bombers) or { Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies(tagged=1) < 2 } and Spell(demonic_strength)
  {
   #call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
   if Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 DemonologyNetherPortalCdActions()

   unless Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalCdPostConditions()
   {
    #call_action_list,name=implosion,if=spell_targets.implosion>1
    if Enemies(tagged=1) > 1 DemonologyImplosionCdActions()

    unless Enemies(tagged=1) > 1 and DemonologyImplosionCdPostConditions()
    {
     #guardian_of_azeroth,if=pet.demonic_tyrant.active|target.time_to_die<=30
     if DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 30 Spell(guardian_of_azeroth)
     #grimoire_felguard,if=(target.time_to_die>120|target.time_to_die<cooldown.summon_demonic_tyrant.remains+15|cooldown.summon_demonic_tyrant.remains<13)
     if target.TimeToDie() > 120 or target.TimeToDie() < SpellCooldown(summon_demonic_tyrant) + 15 or SpellCooldown(summon_demonic_tyrant) < 13 Spell(grimoire_felguard)

     unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(bilescourge_bombers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan)
     {
      #summon_demonic_tyrant,if=soul_shard<3&(!talent.demonic_consumption.enabled|buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6&time_to_imps.all.remains<cast_time)|target.time_to_die<20
      if SoulShards() < 3 and { not Talent(demonic_consumption_talent) or Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 and 0 < CastTime(summon_demonic_tyrant) } or target.TimeToDie() < 20 Spell(summon_demonic_tyrant)

      unless Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies(tagged=1) < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite_buff) } and Spell(demonbolt)
      {
       #focused_azerite_beam,if=!pet.demonic_tyrant.active
       if not DemonDuration(demonic_tyrant) > 0 Spell(focused_azerite_beam)

       unless Spell(purifying_blast)
       {
        #blood_of_the_enemy
        Spell(blood_of_the_enemy)

        unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence)
        {
         #call_action_list,name=build_a_shard
         DemonologyBuildAShardCdActions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction DemonologyDefaultCdPostConditions
{
 { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(worldvein_resonance_essence) or { DemonDuration(demonic_tyrant) > 0 or target.TimeToDie() <= 15 } and Spell(ripple_in_space_essence) or Talent(demonic_consumption_talent) and TimeInCombat() < 30 and not SpellCooldown(summon_demonic_tyrant) > 0 and DemonologyDconOpenerCdPostConditions() or AzeriteTraitRank(explosive_potential_trait) and TimeInCombat() < 5 and SoulShards() > 2 and BuffExpires(explosive_potential) and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 3 and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and BuffStacks(demonic_core_buff) == 4 and Spell(demonbolt) or AzeriteTraitRank(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffRemaining(explosive_potential) < ExecuteTime(shadow_bolt) and { not Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) > 12 } and Spell(implosion) or not target.DebuffPresent(doom_debuff) and target.TimeToDie() > 30 and Enemies(tagged=1) < 2 and Spell(doom) or AzeriteTraitRank(explosive_potential_trait) > 0 and TimeInCombat() < 10 and Enemies(tagged=1) < 2 and DemonDuration(dreadstalker) and Talent(nether_portal_talent) and Spell(bilescourge_bombers) or { Demons(wild_imp) + Demons(wild_imp_inner_demons) < 6 or BuffPresent(demonic_power) or Enemies(tagged=1) < 2 } and Spell(demonic_strength) or Talent(nether_portal_talent) and Enemies(tagged=1) <= 2 and DemonologyNetherPortalCdPostConditions() or Enemies(tagged=1) > 1 and DemonologyImplosionCdPostConditions() or { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(bilescourge_bombers) or { HasAzeriteTrait(baleful_invocation_trait) or Talent(demonic_consumption_talent) } and PreviousGCDSpell(hand_of_guldan) and SpellCooldown(summon_demonic_tyrant) < 2 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and Enemies(tagged=1) < 2 and Spell(power_siphon) or Talent(doom_talent) and target.Refreshable(doom_debuff) and target.TimeToDie() > target.DebuffRemaining(doom_debuff) + 30 and Spell(doom) or { SoulShards() >= 5 or SoulShards() >= 3 and SpellCooldown(call_dreadstalkers) > 4 and { SpellCooldown(summon_demonic_tyrant) > 20 or SpellCooldown(summon_demonic_tyrant) < GCD() * 2 and Talent(demonic_consumption_talent) or SpellCooldown(summon_demonic_tyrant) < GCD() * 4 and not Talent(demonic_consumption_talent) } and { not Talent(summon_vilefiend_talent) or SpellCooldown(summon_vilefiend) > 3 } } and Spell(hand_of_guldan) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { SpellCooldown(summon_demonic_tyrant) < 6 or SpellCooldown(summon_demonic_tyrant) > 22 and not HasAzeriteTrait(shadows_bite_trait) or BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) < 5 or target.TimeToDie() < 25 or BuffPresent(shadows_bite_buff) } and Spell(demonbolt) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and not DemonDuration(demonic_tyrant) > 0 and Spell(concentrated_flame_essence) or DemonologyBuildAShardCdPostConditions()
}

### actions.build_a_shard

AddFunction DemonologyBuildAShardMainActions
{
 #soul_strike,if=!talent.demonic_consumption.enabled|time>15|prev_gcd.1.hand_of_guldan&!buff.bloodlust.remains
 if not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(bloodlust) Spell(soul_strike)
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
 { not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(bloodlust) } and Spell(soul_strike) or Spell(shadow_bolt)
}

AddFunction DemonologyBuildAShardCdActions
{
 #memory_of_lucid_dreams,if=soul_shard<2
 if SoulShards() < 2 Spell(memory_of_lucid_dreams_essence)
}

AddFunction DemonologyBuildAShardCdPostConditions
{
 { not Talent(demonic_consumption_talent) or TimeInCombat() > 15 or PreviousGCDSpell(hand_of_guldan) and not BuffPresent(bloodlust) } and Spell(soul_strike) or Spell(shadow_bolt)
}

### actions.dcon_opener

AddFunction DemonologyDconOpenerMainActions
{
 #hand_of_guldan,line_cd=30,if=azerite.explosive_potential.enabled
 if HasAzeriteTrait(explosive_potential_trait) and TimeSincePreviousSpell(hand_of_guldan) > 30 Spell(hand_of_guldan)
 #implosion,if=azerite.explosive_potential.enabled&buff.wild_imps.stack>2&buff.explosive_potential.down
 if HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) Spell(implosion)
 #doom,line_cd=30
 if TimeSincePreviousSpell(doom) > 30 Spell(doom)
 #hand_of_guldan,if=prev_gcd.1.hand_of_guldan&soul_shard>0&prev_gcd.2.soul_strike
 if PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) Spell(hand_of_guldan)
 #soul_strike,line_cd=30,if=!buff.bloodlust.remains|time>5&prev_gcd.1.hand_of_guldan
 if { not BuffPresent(bloodlust) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and TimeSincePreviousSpell(soul_strike) > 30 Spell(soul_strike)
 #call_dreadstalkers,if=soul_shard=5
 if SoulShards() == 5 Spell(call_dreadstalkers)
 #hand_of_guldan,if=soul_shard=5
 if SoulShards() == 5 Spell(hand_of_guldan)
 #hand_of_guldan,if=soul_shard>=3&prev_gcd.2.hand_of_guldan&time>5&(prev_gcd.1.soul_strike|!talent.soul_strike.enabled&prev_gcd.1.shadow_bolt)
 if SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } Spell(hand_of_guldan)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.remains
 if SoulShards() <= 3 and BuffPresent(demonic_core_buff) Spell(demonbolt)
 #call_action_list,name=build_a_shard
 DemonologyBuildAShardMainActions()
}

AddFunction DemonologyDconOpenerMainPostConditions
{
 DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyDconOpenerShortCdActions
{
 unless HasAzeriteTrait(explosive_potential_trait) and TimeSincePreviousSpell(hand_of_guldan) > 30 and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan)
 {
  #demonic_strength,if=prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&(buff.wild_imps.stack>1&action.hand_of_guldan.in_flight)
  if PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) and not pet.BuffPresent(pet_auto_spin) Spell(demonic_strength)
  #bilescourge_bombers
  Spell(bilescourge_bombers)

  unless { not BuffPresent(bloodlust) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and TimeSincePreviousSpell(soul_strike) > 30 and Spell(soul_strike)
  {
   #summon_vilefiend,if=soul_shard=5
   if SoulShards() == 5 Spell(summon_vilefiend)

   unless SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildAShardShortCdActions()
   }
  }
 }
}

AddFunction DemonologyDconOpenerShortCdPostConditions
{
 HasAzeriteTrait(explosive_potential_trait) and TimeSincePreviousSpell(hand_of_guldan) > 30 and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or { not BuffPresent(bloodlust) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and TimeSincePreviousSpell(soul_strike) > 30 and Spell(soul_strike) or SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyDconOpenerCdActions
{
 unless HasAzeriteTrait(explosive_potential_trait) and TimeSincePreviousSpell(hand_of_guldan) > 30 and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) and Spell(demonic_strength) or Spell(bilescourge_bombers) or { not BuffPresent(bloodlust) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and TimeSincePreviousSpell(soul_strike) > 30 and Spell(soul_strike) or SoulShards() == 5 and Spell(summon_vilefiend)
 {
  #grimoire_felguard,if=soul_shard=5
  if SoulShards() == 5 Spell(grimoire_felguard)

  unless SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan)
  {
   #summon_demonic_tyrant,if=prev_gcd.1.demonic_strength|prev_gcd.1.hand_of_guldan&prev_gcd.2.hand_of_guldan|!talent.demonic_strength.enabled&buff.wild_imps.stack+imps_spawned_during.2000%spell_haste>=6
   if PreviousGCDSpell(demonic_strength) or PreviousGCDSpell(hand_of_guldan) and PreviousGCDSpell(hand_of_guldan count=2) or not Talent(demonic_strength_talent) and Demons(wild_imp) + Demons(wild_imp_inner_demons) + ImpsSpawnedDuring(2000) / { 100 / { 100 + SpellCastSpeedPercent() } } >= 6 Spell(summon_demonic_tyrant)

   unless SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
   {
    #call_action_list,name=build_a_shard
    DemonologyBuildAShardCdActions()
   }
  }
 }
}

AddFunction DemonologyDconOpenerCdPostConditions
{
 HasAzeriteTrait(explosive_potential_trait) and TimeSincePreviousSpell(hand_of_guldan) > 30 and Spell(hand_of_guldan) or HasAzeriteTrait(explosive_potential_trait) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and BuffExpires(explosive_potential) and Spell(implosion) or TimeSincePreviousSpell(doom) > 30 and Spell(doom) or PreviousGCDSpell(hand_of_guldan) and SoulShards() > 0 and PreviousGCDSpell(soul_strike count=2) and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 1 and InFlightToTarget(hand_of_guldan) and Spell(demonic_strength) or Spell(bilescourge_bombers) or { not BuffPresent(bloodlust) or TimeInCombat() > 5 and PreviousGCDSpell(hand_of_guldan) } and TimeSincePreviousSpell(soul_strike) > 30 and Spell(soul_strike) or SoulShards() == 5 and Spell(summon_vilefiend) or SoulShards() == 5 and Spell(call_dreadstalkers) or SoulShards() == 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and PreviousGCDSpell(hand_of_guldan count=2) and TimeInCombat() > 5 and { PreviousGCDSpell(soul_strike) or not Talent(soul_strike_talent) and PreviousGCDSpell(shadow_bolt) } and Spell(hand_of_guldan) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or DemonologyBuildAShardCdPostConditions()
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
 #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&spell_targets.implosion<5
 if not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies(tagged=1) < 5 Spell(concentrated_flame_essence)
 #soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
 if SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 Spell(soul_strike)
 #demonbolt,if=soul_shard<=3&buff.demonic_core.up&(buff.demonic_core.stack>=3|buff.demonic_core.remains<=gcd*5.7)
 if SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } Spell(demonbolt)
 #doom,cycle_targets=1,max_cycle_targets=7,if=refreshable
 if DebuffCountOnAny(doom_debuff) < Enemies(tagged=1) and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) Spell(doom)
 #call_action_list,name=build_a_shard
 DemonologyBuildAShardMainActions()
}

AddFunction DemonologyImplosionMainPostConditions
{
 DemonologyBuildAShardMainPostConditions()
}

AddFunction DemonologyImplosionShortCdActions
{
 unless { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt)
 {
  #summon_vilefiend,if=(cooldown.summon_demonic_tyrant.remains>40&spell_targets.implosion<=2)|cooldown.summon_demonic_tyrant.remains<12
  if SpellCooldown(summon_demonic_tyrant) > 40 and Enemies(tagged=1) <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)
  #bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
  if SpellCooldown(summon_demonic_tyrant) > 9 Spell(bilescourge_bombers)
  #purifying_blast
  Spell(purifying_blast)

  unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies(tagged=1) < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies(tagged=1) and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildAShardShortCdActions()
  }
 }
}

AddFunction DemonologyImplosionShortCdPostConditions
{
 { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies(tagged=1) < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies(tagged=1) and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyImplosionCdActions
{
 unless { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

  unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
  {
   #summon_demonic_tyrant
   Spell(summon_demonic_tyrant)

   unless SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies(tagged=1) <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers)
   {
    #focused_azerite_beam
    Spell(focused_azerite_beam)

    unless Spell(purifying_blast)
    {
     #blood_of_the_enemy
     Spell(blood_of_the_enemy)

     unless not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies(tagged=1) < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies(tagged=1) and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom)
     {
      #call_action_list,name=build_a_shard
      DemonologyBuildAShardCdActions()
     }
    }
   }
  }
 }
}

AddFunction DemonologyImplosionCdPostConditions
{
 { Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 6 and { SoulShards() < 3 or PreviousGCDSpell(call_dreadstalkers) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 9 or PreviousGCDSpell(bilescourge_bombers) or not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) } and not PreviousGCDSpell(hand_of_guldan) and not PreviousGCDSpell(hand_of_guldan count=2) and BuffExpires(demonic_power) or target.TimeToDie() < 3 and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 0 or PreviousGCDSpell(call_dreadstalkers count=2) and Demons(wild_imp) + Demons(wild_imp_inner_demons) > 2 and not Talent(demonic_calling_talent) } and Spell(implosion) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() >= 5 and Spell(hand_of_guldan) or SoulShards() >= 3 and { { PreviousGCDSpell(hand_of_guldan count=2) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 3 } and Demons(wild_imp) + Demons(wild_imp_inner_demons) < 9 or SpellCooldown(summon_demonic_tyrant) <= GCD() * 2 or BuffRemaining(demonic_power) > GCD() * 2 } and Spell(hand_of_guldan) or PreviousGCDSpell(hand_of_guldan) and SoulShards() >= 1 and { Demons(wild_imp) + Demons(wild_imp_inner_demons) <= 3 or PreviousGCDSpell(hand_of_guldan count=3) } and SoulShards() < 4 and BuffPresent(demonic_core_buff) and Spell(demonbolt) or { SpellCooldown(summon_demonic_tyrant) > 40 and Enemies(tagged=1) <= 2 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or SpellCooldown(summon_demonic_tyrant) > 9 and Spell(bilescourge_bombers) or Spell(purifying_blast) or not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) and Enemies(tagged=1) < 5 and Spell(concentrated_flame_essence) or SoulShards() < 5 and BuffStacks(demonic_core_buff) <= 2 and Spell(soul_strike) or SoulShards() <= 3 and BuffPresent(demonic_core_buff) and { BuffStacks(demonic_core_buff) >= 3 or BuffRemaining(demonic_core_buff) <= GCD() * 5.7 } and Spell(demonbolt) or DebuffCountOnAny(doom_debuff) < Enemies(tagged=1) and DebuffCountOnAny(doom_debuff) <= 7 and target.Refreshable(doom_debuff) and Spell(doom) or DemonologyBuildAShardCdPostConditions()
}

### actions.nether_portal

AddFunction DemonologyNetherPortalMainActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingMainActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingMainPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherPortalActiveMainActions()
 }
}

AddFunction DemonologyNetherPortalMainPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingMainPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherPortalActiveMainPostConditions()
}

AddFunction DemonologyNetherPortalShortCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingShortCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingShortCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherPortalActiveShortCdActions()
 }
}

AddFunction DemonologyNetherPortalShortCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingShortCdPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherPortalActiveShortCdPostConditions()
}

AddFunction DemonologyNetherPortalCdActions
{
 #call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
 if SpellCooldown(nether_portal) < 20 DemonologyNetherPortalBuildingCdActions()

 unless SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingCdPostConditions()
 {
  #call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
  if SpellCooldown(nether_portal) > 165 DemonologyNetherPortalActiveCdActions()
 }
}

AddFunction DemonologyNetherPortalCdPostConditions
{
 SpellCooldown(nether_portal) < 20 and DemonologyNetherPortalBuildingCdPostConditions() or SpellCooldown(nether_portal) > 165 and DemonologyNetherPortalActiveCdPostConditions()
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
  #hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(165+action.hand_of_guldan.cast_time)
  if SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) Spell(hand_of_guldan)
  #demonbolt,if=buff.demonic_core.up&soul_shard<=3
  if BuffPresent(demonic_core_buff) and SoulShards() <= 3 Spell(demonbolt)
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
 #bilescourge_bombers
 Spell(bilescourge_bombers)
 #summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
 if SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 Spell(summon_vilefiend)

 unless { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
 {
  #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
  if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildAShardShortCdActions()

  unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt)
  {
   #call_action_list,name=build_a_shard
   DemonologyBuildAShardShortCdActions()
  }
 }
}

AddFunction DemonologyNetherPortalActiveShortCdPostConditions
{
 { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardShortCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyNetherPortalActiveCdActions
{
 unless Spell(bilescourge_bombers)
 {
  #grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
  if SpellCooldown(summon_demonic_tyrant) < 13 or not HasEquippedItem(wilfreds_sigil_of_superior_summoning_item) Spell(grimoire_felguard)

  unless { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers)
  {
   #call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
   if SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } DemonologyBuildAShardCdActions()

   unless SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan)
   {
    #summon_demonic_tyrant,if=buff.nether_portal.remains<5&soul_shard=0
    if BuffRemaining(nether_portal_buff) < 5 and SoulShards() == 0 Spell(summon_demonic_tyrant)
    #summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+0.5
    if BuffRemaining(nether_portal_buff) < CastTime(summon_demonic_tyrant) + 0.5 Spell(summon_demonic_tyrant)

    unless BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt)
    {
     #call_action_list,name=build_a_shard
     DemonologyBuildAShardCdActions()
    }
   }
  }
 }
}

AddFunction DemonologyNetherPortalActiveCdPostConditions
{
 Spell(bilescourge_bombers) or { SpellCooldown(summon_demonic_tyrant) > 40 or SpellCooldown(summon_demonic_tyrant) < 12 } and Spell(summon_vilefiend) or { SpellCooldown(summon_demonic_tyrant) < 9 and BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) < 11 and not BuffPresent(demonic_calling_buff) or SpellCooldown(summon_demonic_tyrant) > 14 } and Spell(call_dreadstalkers) or SoulShards() == 1 and { SpellCooldown(call_dreadstalkers) < CastTime(shadow_bolt) or Talent(bilescourge_bombers_talent) and SpellCooldown(bilescourge_bombers) < CastTime(shadow_bolt) } and DemonologyBuildAShardCdPostConditions() or SpellCooldown(call_dreadstalkers) > CastTime(demonbolt) and SpellCooldown(call_dreadstalkers) > CastTime(shadow_bolt) and SpellCooldown(nether_portal) > 165 + CastTime(hand_of_guldan) and Spell(hand_of_guldan) or BuffPresent(demonic_core_buff) and SoulShards() <= 3 and Spell(demonbolt) or DemonologyBuildAShardCdPostConditions()
}

### actions.nether_portal_building

AddFunction DemonologyNetherPortalBuildingMainActions
{
 #call_dreadstalkers
 Spell(call_dreadstalkers)
 #hand_of_guldan,if=cooldown.call_dreadstalkers.remains>18&soul_shard>=3
 if SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 Spell(hand_of_guldan)
 #power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&soul_shard>=3
 if Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 Spell(power_siphon)
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
 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildAShardShortCdActions()
 }
}

AddFunction DemonologyNetherPortalBuildingShortCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildAShardShortCdPostConditions()
}

AddFunction DemonologyNetherPortalBuildingCdActions
{
 #nether_portal,if=soul_shard>=5&(!talent.power_siphon.enabled|buff.demonic_core.up)
 if SoulShards() >= 5 and { not Talent(power_siphon_talent) or BuffPresent(demonic_core_buff) } Spell(nether_portal)

 unless Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan)
 {
  #call_action_list,name=build_a_shard
  DemonologyBuildAShardCdActions()
 }
}

AddFunction DemonologyNetherPortalBuildingCdPostConditions
{
 Spell(call_dreadstalkers) or SpellCooldown(call_dreadstalkers) > 18 and SoulShards() >= 3 and Spell(hand_of_guldan) or Demons(wild_imp) + Demons(wild_imp_inner_demons) >= 2 and BuffStacks(demonic_core_buff) <= 2 and BuffExpires(demonic_power) and SoulShards() >= 3 and Spell(power_siphon) or SoulShards() >= 5 and Spell(hand_of_guldan) or DemonologyBuildAShardCdPostConditions()
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
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction DemonologyPrecombatCdPostConditions
{
 not pet.Present() and Spell(summon_felguard) or Talent(inner_demons_talent) and Spell(inner_demons) or Spell(demonbolt)
}
]]

		OvaleScripts:RegisterScript("WARLOCK", "demonology", name, desc, code, "script")
	end
end