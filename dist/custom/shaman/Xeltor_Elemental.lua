local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanElementalXeltor = function(OvaleScripts)
do
	local name = "xeltor_elemental"
	local desc = "[Xel][8.2] Shaman: Elemental"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

# Elemental
AddIcon specialization=1 help=main
{
	if not InCombat() and not target.IsFriend() and not mounted() and target.Present() and Speed() == 0
	{
		if TotemRemaining(totem_mastery_elemental) < 2 and not BuffPresent(ele_resonance_totem_buff) and Boss() Spell(totem_mastery_elemental)
	}
	
	# Interrupt
	if InCombat() InterruptActions()
	
	# Save ass
	if not mounted() SaveActions()
	
	if target.InRange(lightning_bolt_elemental) and HasFullControl() and InCombat()
    {
		if PreviousGCDSpell(lava_burst) and not target.DebuffPresent(flame_shock_debuff) Spell(flame_shock)
		
		# Cooldowns
		if Boss() and { Speed() == 0 or CanMove() > 0 } ElementalDefaultCdActions()
		
		# Short Cooldowns
		if Speed() == 0 or CanMove() > 0 ElementalDefaultShortCdActions()
		
		# Default rotation
		if Speed() == 0 or CanMove() > 0 ElementalDefaultMainActions()

		#lava_burst,moving=1,if=talent.ascendance.enabled
		if Speed() > 0 and Talent(ascendance_talent) Spell(lava_burst)
		#flame_shock,moving=1,target_if=refreshable
		if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
		#flame_shock,moving=1,if=movement.distance>6
		if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
		#frost_shock,moving=1
		if Speed() > 0 Spell(frost_shock)
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
		if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) and Speed() == 0 Spell(hex)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		# if not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(capacitor_totem)
	}
}

AddFunction SaveActions
{
	if HealthPercent() <= 50 and InCombat() Spell(astral_shift)
	if { Speed() == 0 or CanMove() > 0 } and HealthPercent() <= 50 and ManaPercent() > 25 and CanCast(healing_surge) and { not InCombat() or target.istargetingplayer() } Spell(healing_surge)
	if not BuffPresent(earth_shield_buff) and HealthPercent() < 100 and target.istargetingplayer() Spell(earth_shield)
	if target.istargetingplayer() and HealthPercent() < 50 Spell(earth_elemental)
}

AddFunction ElementalUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction ElementalDefaultMainActions
{
 #totem_mastery,if=talent.totem_mastery.enabled&buff.resonance_totem.remains<2
 # if Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 Spell(totem_mastery_elemental)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
 if Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } ElementalAoeMainActions()

 unless Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeMainPostConditions()
 {
  #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
  if Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } ElementalFunnelMainActions()

  unless Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelMainPostConditions()
  {
   #run_action_list,name=single_target
   ElementalSingleTargetMainActions()
  }
 }
}

AddFunction ElementalDefaultMainPostConditions
{
 Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeMainPostConditions() or Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelMainPostConditions() or ElementalSingleTargetMainPostConditions()
}

AddFunction ElementalDefaultShortCdActions
{
 unless Spell(concentrated_flame_essence)
 {
  #focused_azerite_beam
  Spell(focused_azerite_beam)
  #purifying_blast
  Spell(purifying_blast)
  #the_unbound_force
  Spell(the_unbound_force)
  #ripple_in_space
  Spell(ripple_in_space_essence)
  #worldvein_resonance
  Spell(worldvein_resonance_essence)
  #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
  if Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } ElementalAoeShortCdActions()

  unless Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeShortCdPostConditions()
  {
   #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
   if Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } ElementalFunnelShortCdActions()

   unless Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelShortCdPostConditions()
   {
    #run_action_list,name=single_target
    ElementalSingleTargetShortCdActions()
   }
  }
 }
}

AddFunction ElementalDefaultShortCdPostConditions
{
 Spell(concentrated_flame_essence) or Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeShortCdPostConditions() or Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelShortCdPostConditions() or ElementalSingleTargetShortCdPostConditions()
}

AddFunction ElementalDefaultCdActions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 # if HasAzeriteTrait(ancestral_resonance_trait) ElementalBloodlust()
 #potion,if=expected_combat_length-time<30|cooldown.fire_elemental.remains>120|cooldown.storm_elemental.remains>120
 # if { 600 - TimeInCombat() < 30 or SpellCooldown(fire_elemental) > 120 or SpellCooldown(storm_elemental) > 120 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
 #wind_shear
 # ElementalInterruptActions()

 # unless Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and Spell(totem_mastery_elemental)
 # {
  #use_items
  ElementalUseItemActions()
  #fire_elemental,if=!talent.storm_elemental.enabled
  if not Talent(storm_elemental_talent) Spell(fire_elemental)
  #storm_elemental,if=talent.storm_elemental.enabled&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)&(!talent.ascendance.enabled|!cooldown.ascendance.up)
  if Talent(storm_elemental_talent) and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and { not Talent(ascendance_talent) or not { not SpellCooldown(ascendance_elemental) > 0 } } Spell(storm_elemental)
  #earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<120&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120&talent.storm_elemental.enabled)
  if not Talent(primal_elementalist_talent) or Talent(primal_elementalist_talent) and { SpellCooldown(fire_elemental) < 120 and not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 and Talent(storm_elemental_talent) } Spell(earth_elemental)

  unless Spell(concentrated_flame_essence)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
   #guardian_of_azeroth
   Spell(guardian_of_azeroth)

   unless Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force)
   {
    #memory_of_lucid_dreams
    Spell(memory_of_lucid_dreams_essence)

    unless Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence)
    {
     #blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
     if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) or SpellCooldown(ascendance_elemental) > 50 Spell(blood_fury_apsp)
     #berserking,if=!talent.ascendance.enabled|buff.ascendance.up
     if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) Spell(berserking)
     #fireblood,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
     if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) or SpellCooldown(ascendance_elemental) > 50 Spell(fireblood)
     #ancestral_call,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
     if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) or SpellCooldown(ascendance_elemental) > 50 Spell(ancestral_call)
     #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
     if Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } ElementalAoeCdActions()

     unless Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeCdPostConditions()
     {
      #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
      if Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } ElementalFunnelCdActions()

      unless Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelCdPostConditions()
      {
       #run_action_list,name=single_target
       ElementalSingleTargetCdActions()
      }
     }
    }
   }
  }
 # }
}

AddFunction ElementalDefaultCdPostConditions
{
 Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(ripple_in_space_essence) or Spell(worldvein_resonance_essence) or Enemies(tagged=1) > 2 and { Enemies(tagged=1) > 2 or Enemies(tagged=1) > 2 } and ElementalAoeCdPostConditions() or Enemies(tagged=1) >= 2 and { Enemies(tagged=1) < 2 or Enemies(tagged=1) < 2 } and ElementalFunnelCdPostConditions() or ElementalSingleTargetCdPostConditions()
}

### actions.aoe

AddFunction ElementalAoeMainActions
{
 #flame_shock,target_if=refreshable&(spell_targets.chain_lightning<(5-!talent.totem_mastery.enabled)|!talent.storm_elemental.enabled&(cooldown.fire_elemental.remains>(120+14*spell_haste)|cooldown.fire_elemental.remains<(24-14*spell_haste)))&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120|spell_targets.chain_lightning=3&buff.wind_gust.stack<14)
 if target.Refreshable(flame_shock_debuff) and { Enemies(tagged=1) < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies(tagged=1) == 3 and BuffStacks(wind_gust_buff) < 14 } Spell(flame_shock)
 #earthquake,if=!talent.master_of_the_elements.enabled|buff.stormkeeper.up|maelstrom>=(100-4*spell_targets.chain_lightning)|buff.master_of_the_elements.up|spell_targets.chain_lightning>3
 if not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies(tagged=1) or BuffPresent(master_of_the_elements_buff) or Enemies(tagged=1) > 3 Spell(earthquake)
 #chain_lightning,if=buff.stormkeeper.remains<3*gcd*buff.stormkeeper.stack
 if BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) Spell(chain_lightning_elemental)
 #lava_burst,if=buff.lava_surge.up&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)&dot.flame_shock.ticking
 if BuffPresent(lava_surge_buff) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) Spell(lava_burst)
 #frost_shock,if=spell_targets.chain_lightning<4&buff.icefury.up&!buff.ascendance.up
 if Enemies(tagged=1) < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) Spell(frost_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)
 if Talent(elemental_blast_talent) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } Spell(elemental_blast)
 #lava_beam,if=talent.ascendance.enabled
 if Talent(ascendance_talent) Spell(lava_beam)
 #chain_lightning
 Spell(chain_lightning_elemental)
 #lava_burst,moving=1,if=talent.ascendance.enabled
 if Speed() > 0 and Talent(ascendance_talent) Spell(lava_burst)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #frost_shock,moving=1
 if Speed() > 0 Spell(frost_shock)
}

AddFunction ElementalAoeMainPostConditions
{
}

AddFunction ElementalAoeShortCdActions
{
 #stormkeeper,if=talent.stormkeeper.enabled
 if Talent(stormkeeper_talent) Spell(stormkeeper)

 unless target.Refreshable(flame_shock_debuff) and { Enemies(tagged=1) < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies(tagged=1) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock)
 {
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled
  if Talent(liquid_magma_totem_talent) Spell(liquid_magma_totem)

  unless { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies(tagged=1) or BuffPresent(master_of_the_elements_buff) or Enemies(tagged=1) > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst)
  {
   #icefury,if=spell_targets.chain_lightning<4&!buff.ascendance.up
   if Enemies(tagged=1) < 4 and not BuffPresent(ascendance_elemental_buff) Spell(icefury)
  }
 }
}

AddFunction ElementalAoeShortCdPostConditions
{
 target.Refreshable(flame_shock_debuff) and { Enemies(tagged=1) < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies(tagged=1) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock) or { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies(tagged=1) or BuffPresent(master_of_the_elements_buff) or Enemies(tagged=1) > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst) or Enemies(tagged=1) < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Talent(elemental_blast_talent) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(elemental_blast) or Talent(ascendance_talent) and Spell(lava_beam) or Spell(chain_lightning_elemental) or Speed() > 0 and Talent(ascendance_talent) and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

AddFunction ElementalAoeCdActions
{
 unless Talent(stormkeeper_talent) and Spell(stormkeeper) or target.Refreshable(flame_shock_debuff) and { Enemies(tagged=1) < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies(tagged=1) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if Talent(ascendance_talent) and { Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 and SpellCooldown(storm_elemental) > 15 or not Talent(storm_elemental_talent) } and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalAoeCdPostConditions
{
 Talent(stormkeeper_talent) and Spell(stormkeeper) or target.Refreshable(flame_shock_debuff) and { Enemies(tagged=1) < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies(tagged=1) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock) or Talent(liquid_magma_totem_talent) and Spell(liquid_magma_totem) or { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies(tagged=1) or BuffPresent(master_of_the_elements_buff) or Enemies(tagged=1) > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst) or Enemies(tagged=1) < 4 and not BuffPresent(ascendance_elemental_buff) and Spell(icefury) or Enemies(tagged=1) < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Talent(elemental_blast_talent) and Enemies(tagged=1) < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(elemental_blast) or Talent(ascendance_talent) and Spell(lava_beam) or Spell(chain_lightning_elemental) or Speed() > 0 and Talent(ascendance_talent) and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

### actions.funnel

AddFunction ElementalFunnelMainActions
{
 #flame_shock,target_if=(!ticking|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<2*gcd|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
 if { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
 if Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } Spell(elemental_blast)
 #lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<6&(azerite.lava_shock.rank*buff.lava_shock.stack)<36&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
 if BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 6 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } Spell(lightning_bolt_elemental)
 #earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|(azerite.lava_shock.rank*buff.lava_shock.stack<36)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
 if not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } Spell(earth_shock)
 #earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
 if not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } Spell(earth_shock)
 #earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>120)|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>120))
 if Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } Spell(earth_shock)
 #lightning_bolt,if=cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
 if SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } Spell(lightning_bolt_elemental)
 #lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
 if BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) Spell(lightning_bolt_elemental)
 #frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
 if Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) Spell(frost_shock)
 #lava_burst,if=buff.ascendance.up
 if BuffPresent(ascendance_elemental_buff) Spell(lava_burst)
 #flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
 if target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%150))<(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)))
 if Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } Spell(lava_burst)
 #lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%150))<(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)))
 if not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } Spell(lava_burst)
 #lightning_bolt,if=buff.surge_of_power.up
 if BuffPresent(surge_of_power_buff) Spell(lightning_bolt_elemental)
 #lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
 if not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) Spell(lava_burst)
 #lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
 if not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) Spell(lava_burst)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
 if Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) Spell(frost_shock)
 #lava_burst,if=cooldown_react
 if not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
 #flame_shock,target_if=refreshable&!buff.surge_of_power.up
 if target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
 # if Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } Spell(totem_mastery_elemental)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
 if Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } Spell(frost_shock)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
 #frost_shock,moving=1
 if Speed() > 0 Spell(frost_shock)
}

AddFunction ElementalFunnelMainPostConditions
{
}

AddFunction ElementalFunnelShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
  if Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } Spell(stormkeeper)
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } Spell(liquid_magma_totem)

  unless BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 6 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst)
  {
   #icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)
   if Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } Spell(icefury)
  }
 }
}

AddFunction ElementalFunnelShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 6 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

AddFunction ElementalFunnelCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<120|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if Talent(ascendance_talent) and { TimeInCombat() >= 60 or BuffPresent(bloodlust_buff) } and SpellCooldown(lava_burst) > 0 and { SpellCooldown(storm_elemental) < 120 or not Talent(storm_elemental_talent) } and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalFunnelCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } and Spell(stormkeeper) or Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 6 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(icefury) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

### actions.precombat

AddFunction ElementalPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #totem_mastery
 Spell(totem_mastery_elemental)
 #elemental_blast,if=talent.elemental_blast.enabled
 if Talent(elemental_blast_talent) Spell(elemental_blast)
 #lava_burst,if=!talent.elemental_blast.enabled&spell_targets.chain_lightning<3
 if not Talent(elemental_blast_talent) and Enemies(tagged=1) < 3 Spell(lava_burst)
 #chain_lightning,if=spell_targets.chain_lightning>2
 if Enemies(tagged=1) > 2 Spell(chain_lightning_elemental)
}

AddFunction ElementalPrecombatMainPostConditions
{
}

AddFunction ElementalPrecombatShortCdActions
{
 unless Spell(totem_mastery_elemental)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } Spell(stormkeeper)
 }
}

AddFunction ElementalPrecombatShortCdPostConditions
{
 Spell(totem_mastery_elemental) or Talent(elemental_blast_talent) and Spell(elemental_blast) or not Talent(elemental_blast_talent) and Enemies(tagged=1) < 3 and Spell(lava_burst) or Enemies(tagged=1) > 2 and Spell(chain_lightning_elemental)
}

AddFunction ElementalPrecombatCdActions
{
 unless Spell(totem_mastery_elemental)
 {
  #earth_elemental,if=!talent.primal_elementalist.enabled
  if not Talent(primal_elementalist_talent) Spell(earth_elemental)

  unless Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and Spell(stormkeeper)
  {
   #fire_elemental,if=!talent.storm_elemental.enabled
   if not Talent(storm_elemental_talent) Spell(fire_elemental)
   #storm_elemental,if=talent.storm_elemental.enabled
   if Talent(storm_elemental_talent) Spell(storm_elemental)
   #potion
   # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
  }
 }
}

AddFunction ElementalPrecombatCdPostConditions
{
 Spell(totem_mastery_elemental) or Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or Talent(elemental_blast_talent) and Spell(elemental_blast) or not Talent(elemental_blast_talent) and Enemies(tagged=1) < 3 and Spell(lava_burst) or Enemies(tagged=1) > 2 and Spell(chain_lightning_elemental)
}

### actions.single_target

AddFunction ElementalSingleTargetMainActions
{
 #flame_shock,target_if=(!ticking|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<2*gcd|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
 if { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
 if Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } Spell(elemental_blast)
 #lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack)<26&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
 if BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } Spell(lightning_bolt_elemental)
 #earthquake,if=(spell_targets.chain_lightning>1|azerite.tectonic_thunder.rank>=3&!talent.surge_of_power.enabled&azerite.lava_shock.rank<1)&azerite.lava_shock.rank*buff.lava_shock.stack<(36+3*azerite.tectonic_thunder.rank*spell_targets.chain_lightning)&(!talent.surge_of_power.enabled|!dot.flame_shock.refreshable|cooldown.storm_elemental.remains>120)&(!talent.master_of_the_elements.enabled|buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled)
 if { Enemies(tagged=1) > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies(tagged=1) and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } Spell(earthquake)
 #earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack<26)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
 if not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } Spell(earth_shock)
 #earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
 if not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } Spell(earth_shock)
 #earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>120)|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>120))
 if Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } Spell(earth_shock)
 #lightning_bolt,if=cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
 if SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } Spell(lightning_bolt_elemental)
 #lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
 if BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) Spell(lightning_bolt_elemental)
 #frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
 if Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) Spell(frost_shock)
 #lava_burst,if=buff.ascendance.up
 if BuffPresent(ascendance_elemental_buff) Spell(lava_burst)
 #flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
 if target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%150))<(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)))
 if Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } Spell(lava_burst)
 #lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%150))<(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)))
 if not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } Spell(lava_burst)
 #lightning_bolt,if=buff.surge_of_power.up
 if BuffPresent(surge_of_power_buff) Spell(lightning_bolt_elemental)
 #lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
 if not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) Spell(lava_burst)
 #lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
 if not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) Spell(lava_burst)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
 if Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) Spell(frost_shock)
 #lava_burst,if=cooldown_react
 if not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
 #flame_shock,target_if=refreshable&!buff.surge_of_power.up
 if target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
 if Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } Spell(totem_mastery_elemental)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
 if Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } Spell(frost_shock)
 #chain_lightning,if=buff.tectonic_thunder.up&!buff.stormkeeper.up&spell_targets.chain_lightning>1
 if BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies(tagged=1) > 1 Spell(chain_lightning_elemental)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
 #frost_shock,moving=1
 if Speed() > 0 Spell(frost_shock)
}

AddFunction ElementalSingleTargetMainPostConditions
{
}

AddFunction ElementalSingleTargetShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
  if Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } Spell(stormkeeper)
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } Spell(liquid_magma_totem)

  unless BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies(tagged=1) > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies(tagged=1) and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock)
  {
   #lightning_lasso
   Spell(lightning_lasso)

   unless SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst)
   {
    #icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)
    if Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } Spell(icefury)
   }
  }
 }
}

AddFunction ElementalSingleTargetShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies(tagged=1) > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies(tagged=1) and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies(tagged=1) > 1 and Spell(chain_lightning_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

AddFunction ElementalSingleTargetCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<120|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if Talent(ascendance_talent) and { TimeInCombat() >= 60 or BuffPresent(bloodlust_buff) } and SpellCooldown(lava_burst) > 0 and { SpellCooldown(storm_elemental) < 120 or not Talent(storm_elemental_talent) } and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalSingleTargetCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(bloodlust_buff) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } and Spell(stormkeeper) or Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or BuffPresent(stormkeeper_buff) and Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies(tagged=1) > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies(tagged=1) and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies(tagged=1) < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or Spell(lightning_lasso) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(bloodlust_buff) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies(tagged=1) > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(icefury) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies(tagged=1) > 1 and Spell(chain_lightning_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}
]]

		OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
	end
end
