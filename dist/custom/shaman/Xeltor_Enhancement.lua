local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanEnhancementXeltor = function(OvaleScripts)
do
	local name = "xeltor_enhancement"
	local desc = "[Xel][8.2] Shaman: Enhancement"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

# Enhancement
AddIcon specialization=2 help=main
{
	if not mounted() and not BuffPresent(ghost_wolf_buff) and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if not BuffPresent(lightning_shield) Spell(lightning_shield)
			if Speed() > 0 Spell(ghost_wolf)
		}
	}
	if not InCombat() and not target.IsFriend() and not mounted() and target.Present() and Speed() == 0
	{
		if TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and not BuffPresent(enh_resonance_totem_buff) and Boss() Spell(totem_mastery_enhancement)
	}
	
	# Interrupt
	if InCombat() InterruptActions()
	
	# Save ass
	if not mounted() SaveActions()
	
	if target.InRange(lava_lash) or target.InRange(wind_shear) and InCombat() and { target.HealthPercent() < 100 or target.istargetingplayer() }
    {
		# Cooldowns
		if Boss() EnhancementDefaultCdActions()
		
		# Short Cooldowns
		if not BuffPresent(lightning_shield) Spell(lightning_shield)
		EnhancementDefaultShortCdActions()
		
		# Default rotation
		EnhancementDefaultMainActions()
	}
	
	# Go forth and murder
	if InCombat() and HasFullControl() and target.Present() and not target.InRange(lava_lash) and { TimeInCombat() < 6 or Falling() }
	{
		if target.InRange(feral_lunge) Spell(feral_lunge)
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) and { Speed() == 0 or CanMove() > 0 } Spell(hex)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if not target.Classification(worldboss) and target.RemainingCastTime() > 2 and target.Distance(less 8) Spell(capacitor_totem)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(sundering)
		if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
	}
}

AddFunction SaveActions
{
	if HealthPercent() <= 50 and InCombat() Spell(astral_shift)
	if { Speed() == 0 or CanMove() > 0 } and { HealthPercent() <= 50 and not target.IsPvP() or HealthPercent() <= 30 and target.IsPvP() } and ManaPercent() > 25 and CanCast(healing_surge) and { not InCombat() or target.istargetingplayer() } Spell(healing_surge)
	if not BuffPresent(earth_shield_buff) and HealthPercent() < 100 and target.istargetingplayer() Spell(earth_shield)
	if target.istargetingplayer() and HealthPercent() < 50 and not target.Classification(worldboss) Spell(earth_elemental)
}

AddFunction EnhancementUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### functions

AddFunction OCPool_FB
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(frostbrand) }
}

AddFunction furyCheck_FB
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(frostbrand) }
}

AddFunction freezerburn_enabled
{
 Talent(hot_hand_talent) and Talent(hailstorm_talent) and HasAzeriteTrait(primal_primer_trait)
}

AddFunction OCPool_SS
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(stormstrike) }
}

AddFunction OCPool_LL
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(lava_lash) }
}

AddFunction cooldown_sync
{
 Talent(ascendance_talent_enhancement) and { BuffPresent(ascendance_enhancement_buff) or SpellCooldown(ascendance_enhancement) > 50 } or not Talent(ascendance_talent_enhancement) and { TotemRemaining(sprit_wolf) > 5 or SpellCooldown(feral_spirit) > 50 }
}

AddFunction furyCheck_CL
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(crash_lightning) }
}

AddFunction CLPool_LL
{
 Enemies(tagged=1) == 1 or Maelstrom() >= PowerCost(crash_lightning) + PowerCost(lava_lash)
}

AddFunction CLPool_SS
{
 Enemies(tagged=1) == 1 or Maelstrom() >= PowerCost(crash_lightning) + PowerCost(stormstrike)
}

AddFunction furyCheck_LL
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(lava_lash) }
}

AddFunction OCPool_CL
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(crash_lightning) }
}

AddFunction OCPool
{
 Enemies(tagged=1) > 1 or SpellCooldown(lightning_bolt_enhancement) >= 2 * GCD()
}

AddFunction furyCheck_ES
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(earthen_spike) }
}

AddFunction rockslide_enabled
{
 not freezerburn_enabled() and Talent(boulderfist_talent) and Talent(landslide_talent) and HasAzeriteTrait(strength_of_earth_trait)
}

AddFunction furyCheck_LB
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + 40 }
}

AddFunction furyCheck_SS
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(stormstrike) }
}

### actions.default

AddFunction EnhancementDefaultMainActions
{
 #call_action_list,name=opener
 EnhancementOpenerMainActions()

 unless EnhancementOpenerMainPostConditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if BuffPresent(ascendance_enhancement_buff) EnhancementAscMainActions()

  unless BuffPresent(ascendance_enhancement_buff) and EnhancementAscMainPostConditions()
  {
   #call_action_list,name=priority
   EnhancementPriorityMainActions()

   unless EnhancementPriorityMainPostConditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if Enemies(tagged=1) < 3 EnhancementMaintenanceMainActions()

    unless Enemies(tagged=1) < 3 and EnhancementMaintenanceMainPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsMainActions()

     unless EnhancementCdsMainPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburnCoreMainActions()

      unless freezerburn_enabled() and EnhancementFreezerburnCoreMainPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultCoreMainActions()

       unless not freezerburn_enabled() and EnhancementDefaultCoreMainPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies(tagged=1) >= 3 EnhancementMaintenanceMainActions()

        unless Enemies(tagged=1) >= 3 and EnhancementMaintenanceMainPostConditions()
        {
         #call_action_list,name=filler
         EnhancementFillerMainActions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultMainPostConditions
{
 EnhancementOpenerMainPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscMainPostConditions() or EnhancementPriorityMainPostConditions() or Enemies(tagged=1) < 3 and EnhancementMaintenanceMainPostConditions() or EnhancementCdsMainPostConditions() or freezerburn_enabled() and EnhancementFreezerburnCoreMainPostConditions() or not freezerburn_enabled() and EnhancementDefaultCoreMainPostConditions() or Enemies(tagged=1) >= 3 and EnhancementMaintenanceMainPostConditions() or EnhancementFillerMainPostConditions()
}

AddFunction EnhancementDefaultShortCdActions
{
 #variable,name=cooldown_sync,value=(talent.ascendance.enabled&(buff.ascendance.up|cooldown.ascendance.remains>50))|(!talent.ascendance.enabled&(feral_spirit.remains>5|cooldown.feral_spirit.remains>50))
 #variable,name=furyCheck_SS,value=maelstrom>=(talent.fury_of_air.enabled*(6+action.stormstrike.cost))
 #variable,name=furyCheck_LL,value=maelstrom>=(talent.fury_of_air.enabled*(6+action.lava_lash.cost))
 #variable,name=furyCheck_CL,value=maelstrom>=(talent.fury_of_air.enabled*(6+action.crash_lightning.cost))
 #variable,name=furyCheck_FB,value=maelstrom>=(talent.fury_of_air.enabled*(6+action.frostbrand.cost))
 #variable,name=furyCheck_ES,value=maelstrom>=(talent.fury_of_air.enabled*(6+action.earthen_spike.cost))
 #variable,name=furyCheck_LB,value=maelstrom>=(talent.fury_of_air.enabled*(6+40))
 #variable,name=OCPool,value=(active_enemies>1|(cooldown.lightning_bolt.remains>=2*gcd))
 #variable,name=OCPool_SS,value=(variable.OCPool|maelstrom>=(talent.overcharge.enabled*(40+action.stormstrike.cost)))
 #variable,name=OCPool_LL,value=(variable.OCPool|maelstrom>=(talent.overcharge.enabled*(40+action.lava_lash.cost)))
 #variable,name=OCPool_CL,value=(variable.OCPool|maelstrom>=(talent.overcharge.enabled*(40+action.crash_lightning.cost)))
 #variable,name=OCPool_FB,value=(variable.OCPool|maelstrom>=(talent.overcharge.enabled*(40+action.frostbrand.cost)))
 #variable,name=CLPool_LL,value=active_enemies=1|maelstrom>=(action.crash_lightning.cost+action.lava_lash.cost)
 #variable,name=CLPool_SS,value=active_enemies=1|maelstrom>=(action.crash_lightning.cost+action.stormstrike.cost)
 #variable,name=freezerburn_enabled,value=(talent.hot_hand.enabled&talent.hailstorm.enabled&azerite.primal_primer.enabled)
 #variable,name=rockslide_enabled,value=(!variable.freezerburn_enabled&(talent.boulderfist.enabled&talent.landslide.enabled&azerite.strength_of_earth.enabled))
 #auto_attack
 # EnhancementGetInMeleeRange()
 #call_action_list,name=opener
 EnhancementOpenerShortCdActions()

 unless EnhancementOpenerShortCdPostConditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if BuffPresent(ascendance_enhancement_buff) EnhancementAscShortCdActions()

  unless BuffPresent(ascendance_enhancement_buff) and EnhancementAscShortCdPostConditions()
  {
   #call_action_list,name=priority
   EnhancementPriorityShortCdActions()

   unless EnhancementPriorityShortCdPostConditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if Enemies(tagged=1) < 3 EnhancementMaintenanceShortCdActions()

    unless Enemies(tagged=1) < 3 and EnhancementMaintenanceShortCdPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsShortCdActions()

     unless EnhancementCdsShortCdPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburnCoreShortCdActions()

      unless freezerburn_enabled() and EnhancementFreezerburnCoreShortCdPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultCoreShortCdActions()

       unless not freezerburn_enabled() and EnhancementDefaultCoreShortCdPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies(tagged=1) >= 3 EnhancementMaintenanceShortCdActions()

        unless Enemies(tagged=1) >= 3 and EnhancementMaintenanceShortCdPostConditions()
        {
         #call_action_list,name=filler
         EnhancementFillerShortCdActions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultShortCdPostConditions
{
 EnhancementOpenerShortCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscShortCdPostConditions() or EnhancementPriorityShortCdPostConditions() or Enemies(tagged=1) < 3 and EnhancementMaintenanceShortCdPostConditions() or EnhancementCdsShortCdPostConditions() or freezerburn_enabled() and EnhancementFreezerburnCoreShortCdPostConditions() or not freezerburn_enabled() and EnhancementDefaultCoreShortCdPostConditions() or Enemies(tagged=1) >= 3 and EnhancementMaintenanceShortCdPostConditions() or EnhancementFillerShortCdPostConditions()
}

AddFunction EnhancementDefaultCdActions
{
 #wind_shear
 # EnhancementInterruptActions()
 #call_action_list,name=opener
 EnhancementOpenerCdActions()

 unless EnhancementOpenerCdPostConditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if BuffPresent(ascendance_enhancement_buff) EnhancementAscCdActions()

  unless BuffPresent(ascendance_enhancement_buff) and EnhancementAscCdPostConditions()
  {
   #call_action_list,name=priority
   EnhancementPriorityCdActions()

   unless EnhancementPriorityCdPostConditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if Enemies(tagged=1) < 3 EnhancementMaintenanceCdActions()

    unless Enemies(tagged=1) < 3 and EnhancementMaintenanceCdPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsCdActions()

     unless EnhancementCdsCdPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburnCoreCdActions()

      unless freezerburn_enabled() and EnhancementFreezerburnCoreCdPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultCoreCdActions()

       unless not freezerburn_enabled() and EnhancementDefaultCoreCdPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies(tagged=1) >= 3 EnhancementMaintenanceCdActions()

        unless Enemies(tagged=1) >= 3 and EnhancementMaintenanceCdPostConditions()
        {
         #call_action_list,name=filler
         EnhancementFillerCdActions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultCdPostConditions
{
 EnhancementOpenerCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscCdPostConditions() or EnhancementPriorityCdPostConditions() or Enemies(tagged=1) < 3 and EnhancementMaintenanceCdPostConditions() or EnhancementCdsCdPostConditions() or freezerburn_enabled() and EnhancementFreezerburnCoreCdPostConditions() or not freezerburn_enabled() and EnhancementDefaultCoreCdPostConditions() or Enemies(tagged=1) >= 3 and EnhancementMaintenanceCdPostConditions() or EnhancementFillerCdPostConditions()
}

### actions.asc

AddFunction EnhancementAscMainActions
{
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) Spell(rockbiter)
 #windstrike
 Spell(windstrike)
}

AddFunction EnhancementAscMainPostConditions
{
}

AddFunction EnhancementAscShortCdActions
{
}

AddFunction EnhancementAscShortCdPostConditions
{
 not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) and Spell(rockbiter) or Spell(windstrike)
}

AddFunction EnhancementAscCdActions
{
}

AddFunction EnhancementAscCdPostConditions
{
 not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) and Spell(rockbiter) or Spell(windstrike)
}

### actions.cds

AddFunction EnhancementCdsMainActions
{
}

AddFunction EnhancementCdsMainPostConditions
{
}

AddFunction EnhancementCdsShortCdActions
{
}

AddFunction EnhancementCdsShortCdPostConditions
{
}

AddFunction EnhancementCdsCdActions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 # if HasAzeriteTrait(ancestral_resonance_trait) EnhancementBloodlust()
 #berserking,if=variable.cooldown_sync
 if cooldown_sync() Spell(berserking)
 #blood_fury,if=variable.cooldown_sync
 if cooldown_sync() Spell(blood_fury_apsp)
 #fireblood,if=variable.cooldown_sync
 if cooldown_sync() Spell(fireblood)
 #ancestral_call,if=variable.cooldown_sync
 if cooldown_sync() Spell(ancestral_call)
 #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
 # if { BuffPresent(ascendance_enhancement_buff) or not Talent(ascendance_talent_enhancement) and TotemRemaining(sprit_wolf) > 5 or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)
 #feral_spirit
 Spell(feral_spirit)
 #blood_of_the_enemy
 Spell(blood_of_the_enemy)
 #ascendance,if=cooldown.strike.remains>0
 if SpellCooldown(windstrike) > 0 and BuffExpires(ascendance_enhancement_buff) Spell(ascendance_enhancement)
 #use_items
 EnhancementUseItemActions()
 #earth_elemental
 Spell(earth_elemental)
}

AddFunction EnhancementCdsCdPostConditions
{
}

### actions.default_core

AddFunction EnhancementDefaultCoreMainActions
{
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() and target.InRange(earthen_spike) Spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) Spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) Spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 Spell(lightning_bolt_enhancement)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS
 if OCPool_SS() and furyCheck_SS() and target.InRange(stormstrike) Spell(stormstrike)
}

AddFunction EnhancementDefaultCoreMainPostConditions
{
}

AddFunction EnhancementDefaultCoreShortCdActions
{
}

AddFunction EnhancementDefaultCoreShortCdPostConditions
{
 furyCheck_ES() and target.InRange(earthen_spike) and Spell(earthen_spike) or Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) and Spell(stormstrike) or Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike)
}

AddFunction EnhancementDefaultCoreCdActions
{
}

AddFunction EnhancementDefaultCoreCdPostConditions
{
 furyCheck_ES() and target.InRange(earthen_spike) and Spell(earthen_spike) or Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) and Spell(stormstrike) or Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike)
}

### actions.filler

AddFunction EnhancementFillerMainActions
{
 #sundering,if=active_enemies<3
 if Enemies(tagged=1) < 3 and target.Distance(less 8) Spell(sundering)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #crash_lightning,if=talent.forceful_winds.enabled&active_enemies>1&variable.furyCheck_CL
 if Talent(forceful_winds_talent) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #lava_lash,if=!azerite.primal_primer.enabled&talent.hot_hand.enabled&buff.hot_hand.react
 if not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and target.InRange(lava_lash) Spell(lava_lash)
 #crash_lightning,if=active_enemies>1&variable.furyCheck_CL
 if Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #rockbiter,if=maelstrom<70&!buff.strength_of_earth.up
 if Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and target.InRange(rockbiter) Spell(rockbiter)
 #crash_lightning,if=talent.crashing_storm.enabled&variable.OCPool_CL
 if Talent(crashing_storm_talent) and OCPool_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #lava_lash,if=variable.OCPool_LL&variable.furyCheck_LL
 if OCPool_LL() and furyCheck_LL() and target.InRange(lava_lash) Spell(lava_lash)
 #rockbiter
 if target.InRange(rockbiter) Spell(rockbiter)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8+gcd&variable.furyCheck_FB
 if Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and target.InRange(frostbrand) Spell(frostbrand)
}

AddFunction EnhancementFillerMainPostConditions
{
}

AddFunction EnhancementFillerShortCdActions
{
 unless Enemies(tagged=1) < 3 and target.Distance(less 8) and Spell(sundering)
 {
  #purifying_blast
  Spell(purifying_blast)

  unless Spell(concentrated_flame_essence)
  {
   #worldvein_resonance,if=buff.lifeblood.stack<4
   if BuffStacks(lifeblood_buff) < 4 Spell(worldvein_resonance_essence)

   unless Talent(forceful_winds_talent) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning)
   {
    #flametongue,if=talent.searing_assault.enabled
    if Talent(searing_assault_talent) and target.InRange(flametongue) Spell(flametongue)

    unless not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and target.InRange(lava_lash) and Spell(lava_lash) or Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and target.InRange(rockbiter) and Spell(rockbiter) or Talent(crashing_storm_talent) and OCPool_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or target.InRange(rockbiter) and Spell(rockbiter) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
    {
     #flametongue
     if target.InRange(flametongue) Spell(flametongue)
    }
   }
  }
 }
}

AddFunction EnhancementFillerShortCdPostConditions
{
 Enemies(tagged=1) < 3 and target.Distance(less 8) and Spell(sundering) or Spell(concentrated_flame_essence) or Talent(forceful_winds_talent) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and target.InRange(lava_lash) and Spell(lava_lash) or Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and target.InRange(rockbiter) and Spell(rockbiter) or Talent(crashing_storm_talent) and OCPool_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or target.InRange(rockbiter) and Spell(rockbiter) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
}

AddFunction EnhancementFillerCdActions
{
 unless Enemies(tagged=1) < 3 and target.Distance(less 8) and Spell(sundering)
 {
  #focused_azerite_beam,if=!buff.ascendance.up&!buff.molten_weapon.up&!buff.icy_edge.up&!buff.crackling_surge.up&!debuff.earthen_spike.up
  if not BuffPresent(ascendance_enhancement_buff) and not BuffPresent(molten_weapon_buff) and not BuffPresent(icy_edge_buff) and not BuffPresent(crackling_surge_buff) and not target.DebuffPresent(earthen_spike_debuff) Spell(focused_azerite_beam)
 }
}

AddFunction EnhancementFillerCdPostConditions
{
 Enemies(tagged=1) < 3 and target.Distance(less 8) and Spell(sundering) or Spell(purifying_blast) or Spell(concentrated_flame_essence) or BuffStacks(lifeblood_buff) < 4 and Spell(worldvein_resonance_essence) or Talent(forceful_winds_talent) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and target.InRange(lava_lash) and Spell(lava_lash) or Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and target.InRange(rockbiter) and Spell(rockbiter) or Talent(crashing_storm_talent) and OCPool_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or target.InRange(rockbiter) and Spell(rockbiter) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
}

### actions.freezerburn_core

AddFunction EnhancementFreezerburnCoreMainActions
{
 #lava_lash,target_if=max:debuff.primal_primer.stack,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&variable.furyCheck_LL&variable.CLPool_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) Spell(lava_lash)
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() and target.InRange(earthen_spike) Spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) Spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) Spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 Spell(lightning_bolt_enhancement)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack>7&variable.furyCheck_LL&variable.CLPool_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) Spell(lava_lash)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS&variable.CLPool_SS
 if OCPool_SS() and furyCheck_SS() and CLPool_SS() and target.InRange(stormstrike) Spell(stormstrike)
 #lava_lash,if=debuff.primal_primer.stack=10&variable.furyCheck_LL
 if target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and target.InRange(lava_lash) Spell(lava_lash)
}

AddFunction EnhancementFreezerburnCoreMainPostConditions
{
}

AddFunction EnhancementFreezerburnCoreShortCdActions
{
}

AddFunction EnhancementFreezerburnCoreShortCdPostConditions
{
 AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) and Spell(lava_lash) or furyCheck_ES() and target.InRange(earthen_spike) and Spell(earthen_spike) or Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) and Spell(stormstrike) or Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) and Spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and target.InRange(stormstrike) and Spell(stormstrike) or target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash)
}

AddFunction EnhancementFreezerburnCoreCdActions
{
}

AddFunction EnhancementFreezerburnCoreCdPostConditions
{
 AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) and Spell(lava_lash) or furyCheck_ES() and target.InRange(earthen_spike) and Spell(earthen_spike) or Enemies(tagged=1) > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and target.InRange(stormstrike) and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies(tagged=1) > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and target.InRange(stormstrike) and Spell(stormstrike) or Enemies(tagged=1) >= 3 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies(tagged=1) == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and target.InRange(lava_lash) and Spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and target.InRange(stormstrike) and Spell(stormstrike) or target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash)
}

### actions.maintenance

AddFunction EnhancementMaintenanceMainActions
{
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck_FB
 if Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() and target.InRange(frostbrand) Spell(frostbrand)
}

AddFunction EnhancementMaintenanceMainPostConditions
{
}

AddFunction EnhancementMaintenanceShortCdActions
{
 #flametongue,if=!buff.flametongue.up
 if not BuffPresent(flametongue_buff) and target.InRange(flametongue) Spell(flametongue)
}

AddFunction EnhancementMaintenanceShortCdPostConditions
{
 Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
}

AddFunction EnhancementMaintenanceCdActions
{
}

AddFunction EnhancementMaintenanceCdPostConditions
{
 Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
}

### actions.opener

AddFunction EnhancementOpenerMainActions
{
 #rockbiter,if=maelstrom<15&time<gcd
 if Maelstrom() < 15 and TimeInCombat() < GCD() and target.InRange(rockbiter) Spell(rockbiter)
}

AddFunction EnhancementOpenerMainPostConditions
{
}

AddFunction EnhancementOpenerShortCdActions
{
}

AddFunction EnhancementOpenerShortCdPostConditions
{
 Maelstrom() < 15 and TimeInCombat() < GCD() and target.InRange(rockbiter) and Spell(rockbiter)
}

AddFunction EnhancementOpenerCdActions
{
}

AddFunction EnhancementOpenerCdPostConditions
{
 Maelstrom() < 15 and TimeInCombat() < GCD() and target.InRange(rockbiter) and Spell(rockbiter)
}

### actions.precombat

AddFunction EnhancementPrecombatMainActions
{
 #lightning_shield
 Spell(lightning_shield)
}

AddFunction EnhancementPrecombatMainPostConditions
{
}

AddFunction EnhancementPrecombatShortCdActions
{
}

AddFunction EnhancementPrecombatShortCdPostConditions
{
 Spell(lightning_shield)
}

AddFunction EnhancementPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
}

AddFunction EnhancementPrecombatCdPostConditions
{
 Spell(lightning_shield)
}

### actions.priority

AddFunction EnhancementPriorityMainActions
{
 #crash_lightning,if=active_enemies>=(8-(talent.forceful_winds.enabled*3))&variable.freezerburn_enabled&variable.furyCheck_CL
 if Enemies(tagged=1) >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&active_enemies=1&variable.freezerburn_enabled&variable.furyCheck_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies(tagged=1) == 1 and freezerburn_enabled() and furyCheck_LL() and target.InRange(lava_lash) Spell(lava_lash)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) Spell(crash_lightning)
 #fury_of_air,if=!buff.fury_of_air.up&maelstrom>=20&spell_targets.fury_of_air_damage>=(1+variable.freezerburn_enabled)
 if not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies(tagged=1) >= 1 + freezerburn_enabled() and target.Distance(less 8) Spell(fury_of_air)
 #fury_of_air,if=buff.fury_of_air.up&&spell_targets.fury_of_air_damage<(1+variable.freezerburn_enabled)
 if BuffPresent(fury_of_air_buff) and Enemies(tagged=1) < 1 + freezerburn_enabled() and target.Distance(less 8) Spell(fury_of_air)
 #totem_mastery,if=buff.resonance_totem.remains<=2*gcd
 if TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() Spell(totem_mastery_enhancement)
 #sundering,if=active_enemies>=3&(!essence.blood_of_the_enemy.major|(essence.blood_of_the_enemy.major&(buff.seething_rage.up|cooldown.blood_of_the_enemy.remains>40)))
 if Enemies(tagged=1) >= 3 and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) and { BuffPresent(seething_rage_buff) or SpellCooldown(blood_of_the_enemy) > 40 } } and target.Distance(less 8) Spell(sundering)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) Spell(rockbiter)
 #frostbrand,if=(azerite.natural_harmony.enabled&buff.natural_harmony_frost.remains<=2*gcd)&talent.hailstorm.enabled&variable.furyCheck_FB
 if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and target.InRange(frostbrand) Spell(frostbrand)
 #rockbiter,if=(azerite.natural_harmony.enabled&buff.natural_harmony_nature.remains<=2*gcd)&maelstrom<70
 if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 and target.InRange(rockbiter) Spell(rockbiter)
}

AddFunction EnhancementPriorityMainPostConditions
{
}

AddFunction EnhancementPriorityShortCdActions
{
 unless Enemies(tagged=1) >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning)
 {
  #the_unbound_force,if=buff.reckless_force.up|time<5
  if BuffPresent(reckless_force_buff) or TimeInCombat() < 5 Spell(the_unbound_force)

  unless AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies(tagged=1) == 1 and freezerburn_enabled() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies(tagged=1) >= 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies(tagged=1) < 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and Spell(totem_mastery_enhancement) or Enemies(tagged=1) >= 3 and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) and { BuffPresent(seething_rage_buff) or SpellCooldown(blood_of_the_enemy) > 40 } } and target.Distance(less 8) and Spell(sundering)
  {
   #purifying_blast,if=active_enemies>=3
   if Enemies(tagged=1) >= 3 Spell(purifying_blast)

   unless Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) and Spell(rockbiter) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand)
   {
    #flametongue,if=(azerite.natural_harmony.enabled&buff.natural_harmony_fire.remains<=2*gcd)
    if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_fire) <= 2 * GCD() and target.InRange(flametongue) Spell(flametongue)
   }
  }
 }
}

AddFunction EnhancementPriorityShortCdPostConditions
{
 Enemies(tagged=1) >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies(tagged=1) == 1 and freezerburn_enabled() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies(tagged=1) >= 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies(tagged=1) < 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and Spell(totem_mastery_enhancement) or Enemies(tagged=1) >= 3 and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) and { BuffPresent(seething_rage_buff) or SpellCooldown(blood_of_the_enemy) > 40 } } and target.Distance(less 8) and Spell(sundering) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) and Spell(rockbiter) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 and target.InRange(rockbiter) and Spell(rockbiter)
}

AddFunction EnhancementPriorityCdActions
{
 unless Enemies(tagged=1) >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or { BuffPresent(reckless_force_buff) or TimeInCombat() < 5 } and Spell(the_unbound_force) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies(tagged=1) == 1 and freezerburn_enabled() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies(tagged=1) >= 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies(tagged=1) < 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and Spell(totem_mastery_enhancement) or Enemies(tagged=1) >= 3 and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) and { BuffPresent(seething_rage_buff) or SpellCooldown(blood_of_the_enemy) > 40 } } and target.Distance(less 8) and Spell(sundering)
 {
  #focused_azerite_beam,if=active_enemies>=3
  if Enemies(tagged=1) >= 3 Spell(focused_azerite_beam)
 }
}

AddFunction EnhancementPriorityCdPostConditions
{
 Enemies(tagged=1) >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or { BuffPresent(reckless_force_buff) or TimeInCombat() < 5 } and Spell(the_unbound_force) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies(tagged=1) == 1 and freezerburn_enabled() and furyCheck_LL() and target.InRange(lava_lash) and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies(tagged=1) > 1 and furyCheck_CL() and target.InRange(crash_lightning) and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies(tagged=1) >= 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies(tagged=1) < 1 + freezerburn_enabled() and target.Distance(less 8) and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and Spell(totem_mastery_enhancement) or Enemies(tagged=1) >= 3 and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) and { BuffPresent(seething_rage_buff) or SpellCooldown(blood_of_the_enemy) > 40 } } and target.Distance(less 8) and Spell(sundering) or Enemies(tagged=1) >= 3 and Spell(purifying_blast) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and target.InRange(rockbiter) and Spell(rockbiter) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and target.InRange(frostbrand) and Spell(frostbrand) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 and target.InRange(rockbiter) and Spell(rockbiter)
}
]]

		OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
	end
end
