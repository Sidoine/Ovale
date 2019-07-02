local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_shaman_elemental"
    local desc = "[8.2] Simulationcraft: PR_Shaman_Elemental"
    local code = [[
# Based on SimulationCraft profile "PR_Shaman_Elemental".
#	class=shaman
#	spec=elemental
#	talents=2303023

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=elemental)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=elemental)
AddCheckBox(opt_bloodlust SpellName(bloodlust) specialization=elemental)

AddFunction ElementalInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
  if not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(capacitor_totem)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) Spell(hex)
 }
}

AddFunction ElementalUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction ElementalBloodlust
{
 if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
 {
  Spell(bloodlust)
  Spell(heroism)
 }
}

### actions.single_target

AddFunction ElementalSingletargetMainActions
{
 #flame_shock,target_if=(!ticking|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<2*gcd|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
 if { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(burst_haste_buff any=1) } and not BuffPresent(surge_of_power_buff) Spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
 if Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } Spell(elemental_blast)
 #lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack)<26&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
 if BuffPresent(stormkeeper_buff) and Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } Spell(lightning_bolt_elemental)
 #earthquake,if=(spell_targets.chain_lightning>1|azerite.tectonic_thunder.rank>=3&!talent.surge_of_power.enabled&azerite.lava_shock.rank<1)&azerite.lava_shock.rank*buff.lava_shock.stack<(36+3*azerite.tectonic_thunder.rank*spell_targets.chain_lightning)&(!talent.surge_of_power.enabled|!dot.flame_shock.refreshable|cooldown.storm_elemental.remains>120)&(!talent.master_of_the_elements.enabled|buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled)
 if { Enemies() > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies() and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } Spell(earthquake)
 #earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack<26)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
 if not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } Spell(earth_shock)
 #earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
 if not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } Spell(earth_shock)
 #earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>120)|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>120))
 if Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } Spell(earth_shock)
 #lightning_bolt,if=cooldown.storm_elemental.remains>120&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
 if SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(burst_haste_buff any=1) } Spell(lightning_bolt_elemental)
 #lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
 if BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) Spell(lightning_bolt_elemental)
 #frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
 if Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) Spell(frost_shock)
 #lava_burst,if=buff.ascendance.up
 if BuffPresent(ascendance_elemental_buff) Spell(lava_burst)
 #flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
 if target.Refreshable(flame_shock_debuff) and Enemies() > 1 and BuffPresent(surge_of_power_buff) Spell(flame_shock)
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
 if Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } Spell(totem_mastery_elemental)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
 if Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } Spell(frost_shock)
 #chain_lightning,if=buff.tectonic_thunder.up&!buff.stormkeeper.up&spell_targets.chain_lightning>1
 if BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies() > 1 Spell(chain_lightning_elemental)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
 #frost_shock,moving=1
 if Speed() > 0 Spell(frost_shock)
}

AddFunction ElementalSingletargetMainPostConditions
{
}

AddFunction ElementalSingletargetShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(burst_haste_buff any=1) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
  if Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } Spell(stormkeeper)
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } Spell(liquid_magma_totem)

  unless BuffPresent(stormkeeper_buff) and Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies() > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies() and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(burst_haste_buff any=1) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies() > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst)
  {
   #icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)
   if Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } Spell(icefury)
  }
 }
}

AddFunction ElementalSingletargetShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(burst_haste_buff any=1) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or BuffPresent(stormkeeper_buff) and Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies() > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies() and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(burst_haste_buff any=1) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies() > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies() > 1 and Spell(chain_lightning_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

AddFunction ElementalSingletargetCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(burst_haste_buff any=1) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<120|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if Talent(ascendance_talent) and { TimeInCombat() >= 60 or BuffPresent(burst_haste_buff any=1) } and SpellCooldown(lava_burst) > 0 and { SpellCooldown(storm_elemental) < 120 or not Talent(storm_elemental_talent) } and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalSingletargetCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 2 * GCD() or target.DebuffRemaining(flame_shock_debuff) <= GCD() or Talent(ascendance_talent) and target.DebuffRemaining(flame_shock_debuff) < SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) < 4 and { not Talent(storm_elemental_talent) or Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 } } and { BuffStacks(wind_gust_buff) < 14 or AzeriteTraitRank(igneous_potential_trait) >= 2 or BuffPresent(lava_surge_buff) or not BuffPresent(burst_haste_buff any=1) } and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(elemental_blast_talent) and { Talent(master_of_the_elements_talent) and BuffPresent(master_of_the_elements_buff) and Maelstrom() < 60 or not Talent(master_of_the_elements_talent) } and { not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } or AzeriteTraitRank(natural_harmony_trait) == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(elemental_blast) or Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) or Maelstrom() >= 44 } and Spell(stormkeeper) or Talent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or BuffPresent(stormkeeper_buff) and Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and { BuffPresent(master_of_the_elements_buff) and not Talent(surge_of_power_talent) or BuffPresent(surge_of_power_buff) } and Spell(lightning_bolt_elemental) or { Enemies() > 1 or AzeriteTraitRank(tectonic_thunder_trait) >= 3 and not Talent(surge_of_power_talent) and AzeriteTraitRank(lava_shock_trait) < 1 } and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 36 + 3 * AzeriteTraitRank(tectonic_thunder_trait) * Enemies() and { not Talent(surge_of_power_talent) or not target.DebuffRefreshable(flame_shock_debuff) or SpellCooldown(storm_elemental) > 120 } and { not Talent(master_of_the_elements_talent) or BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) } and Spell(earthquake) or not BuffPresent(surge_of_power_buff) and Talent(master_of_the_elements_talent) and { BuffPresent(master_of_the_elements_buff) or SpellCooldown(lava_burst) > 0 and Maelstrom() >= 92 + 30 * TalentPoints(call_the_thunder_talent) or Enemies() < 2 and AzeriteTraitRank(lava_shock_trait) * BuffStacks(lava_shock_buff) < 26 and BuffPresent(stormkeeper_buff) and SpellCooldown(lava_burst) <= GCD() } and Spell(earth_shock) or not Talent(master_of_the_elements_talent) and not { AzeriteTraitRank(igneous_potential_trait) > 2 and BuffPresent(ascendance_elemental_buff) } and { BuffPresent(stormkeeper_buff) or Maelstrom() >= 90 + 30 * TalentPoints(call_the_thunder_talent) or not { SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) } and 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } >= 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } } and Spell(earth_shock) or Talent(surge_of_power_talent) and not BuffPresent(surge_of_power_buff) and SpellCooldown(lava_burst) <= GCD() and { not Talent(storm_elemental_talent) and not SpellCooldown(fire_elemental) > 120 or Talent(storm_elemental_talent) and not SpellCooldown(storm_elemental) > 120 } and Spell(earth_shock) or SpellCooldown(storm_elemental) > 120 and Talent(storm_elemental_talent) and { AzeriteTraitRank(igneous_potential_trait) < 2 or not BuffPresent(lava_surge_buff) and BuffPresent(burst_haste_buff any=1) } and Spell(lightning_bolt_elemental) or { BuffRemaining(stormkeeper_buff) < 1.1 * GCD() * BuffStacks(stormkeeper_buff) or BuffPresent(stormkeeper_buff) and BuffPresent(master_of_the_elements_buff) } and Spell(lightning_bolt_elemental) or Talent(icefury_talent) and Talent(master_of_the_elements_talent) and BuffPresent(icefury_buff) and BuffPresent(master_of_the_elements_buff) and Spell(frost_shock) or BuffPresent(ascendance_elemental_buff) and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and Enemies() > 1 and BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(storm_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(storm_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(storm_elemental) } / 150 } } and Spell(lava_burst) or not Talent(storm_elemental_talent) and not SpellCooldown(lava_burst) > 0 and BuffPresent(surge_of_power_buff) and { 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } < 30 * { 1 + { AzeriteTraitRank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) - 150 * { { 1.16 * { 600 - TimeInCombat() } - SpellCooldown(fire_elemental) } / 150 } < 600 - TimeInCombat() - SpellCooldown(fire_elemental) - 150 * { { 600 - TimeInCombat() - SpellCooldown(fire_elemental) } / 150 } } and Spell(lava_burst) or BuffPresent(surge_of_power_buff) and Spell(lightning_bolt_elemental) or not SpellCooldown(lava_burst) > 0 and not Talent(master_of_the_elements_talent) and Spell(lava_burst) or Talent(icefury_talent) and not { Maelstrom() > 75 and SpellCooldown(lava_burst) <= 0 } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(icefury) or not SpellCooldown(lava_burst) > 0 and Charges(lava_burst) > TalentPoints(echo_of_the_elements_talent_elemental) and Spell(lava_burst) or Talent(icefury_talent) and BuffPresent(icefury_buff) and BuffRemaining(icefury_buff) < 1.1 * GCD() * BuffStacks(icefury_buff) and Spell(frost_shock) or not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or target.Refreshable(flame_shock_debuff) and not BuffPresent(surge_of_power_buff) and Spell(flame_shock) or Talent(totem_mastery_talent_elemental) and { TotemRemaining(totem_mastery_elemental) < 6 or TotemRemaining(totem_mastery_elemental) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Talent(icefury_talent) and BuffPresent(icefury_buff) and { BuffRemaining(icefury_buff) < GCD() * 4 * BuffStacks(icefury_buff) or BuffPresent(stormkeeper_buff) or not Talent(master_of_the_elements_talent) } and Spell(frost_shock) or BuffPresent(tectonic_thunder) and not BuffPresent(stormkeeper_buff) and Enemies() > 1 and Spell(chain_lightning_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

### actions.precombat

AddFunction ElementalPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #totem_mastery
 if InCombat() or not BuffPresent(ele_resonance_totem_buff) Spell(totem_mastery_elemental)
 #elemental_blast,if=talent.elemental_blast.enabled
 if Talent(elemental_blast_talent) Spell(elemental_blast)
 #lava_burst,if=!talent.elemental_blast.enabled&spell_targets.chain_lightning<3
 if not Talent(elemental_blast_talent) and Enemies() < 3 Spell(lava_burst)
 #chain_lightning,if=spell_targets.chain_lightning>2
 if Enemies() > 2 Spell(chain_lightning_elemental)
}

AddFunction ElementalPrecombatMainPostConditions
{
}

AddFunction ElementalPrecombatShortCdActions
{
 unless { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } Spell(stormkeeper)
 }
}

AddFunction ElementalPrecombatShortCdPostConditions
{
 { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Talent(elemental_blast_talent) and Spell(elemental_blast) or not Talent(elemental_blast_talent) and Enemies() < 3 and Spell(lava_burst) or Enemies() > 2 and Spell(chain_lightning_elemental)
}

AddFunction ElementalPrecombatCdActions
{
 unless { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental)
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
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_intellect usable=1)
  }
 }
}

AddFunction ElementalPrecombatCdPostConditions
{
 { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Talent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or Talent(elemental_blast_talent) and Spell(elemental_blast) or not Talent(elemental_blast_talent) and Enemies() < 3 and Spell(lava_burst) or Enemies() > 2 and Spell(chain_lightning_elemental)
}

### actions.aoe

AddFunction ElementalAoeMainActions
{
 #flame_shock,target_if=refreshable&(spell_targets.chain_lightning<(5-!talent.totem_mastery.enabled)|!talent.storm_elemental.enabled&(cooldown.fire_elemental.remains>(120+14*spell_haste)|cooldown.fire_elemental.remains<(24-14*spell_haste)))&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120|spell_targets.chain_lightning=3&buff.wind_gust.stack<14)
 if target.Refreshable(flame_shock_debuff) and { Enemies() < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies() == 3 and BuffStacks(wind_gust_buff) < 14 } Spell(flame_shock)
 #earthquake,if=!talent.master_of_the_elements.enabled|buff.stormkeeper.up|maelstrom>=(100-4*spell_targets.chain_lightning)|buff.master_of_the_elements.up|spell_targets.chain_lightning>3
 if not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies() or BuffPresent(master_of_the_elements_buff) or Enemies() > 3 Spell(earthquake)
 #chain_lightning,if=buff.stormkeeper.remains<3*gcd*buff.stormkeeper.stack
 if BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) Spell(chain_lightning_elemental)
 #lava_burst,if=buff.lava_surge.up&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)&dot.flame_shock.ticking
 if BuffPresent(lava_surge_buff) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) Spell(lava_burst)
 #frost_shock,if=spell_targets.chain_lightning<4&buff.icefury.up&!buff.ascendance.up
 if Enemies() < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) Spell(frost_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120)
 if Talent(elemental_blast_talent) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } Spell(elemental_blast)
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

 unless target.Refreshable(flame_shock_debuff) and { Enemies() < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies() == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock)
 {
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled
  if Talent(liquid_magma_totem_talent) Spell(liquid_magma_totem)

  unless { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies() or BuffPresent(master_of_the_elements_buff) or Enemies() > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst)
  {
   #icefury,if=spell_targets.chain_lightning<4&!buff.ascendance.up
   if Enemies() < 4 and not BuffPresent(ascendance_elemental_buff) Spell(icefury)
  }
 }
}

AddFunction ElementalAoeShortCdPostConditions
{
 target.Refreshable(flame_shock_debuff) and { Enemies() < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies() == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock) or { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies() or BuffPresent(master_of_the_elements_buff) or Enemies() > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst) or Enemies() < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Talent(elemental_blast_talent) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(elemental_blast) or Talent(ascendance_talent) and Spell(lava_beam) or Spell(chain_lightning_elemental) or Speed() > 0 and Talent(ascendance_talent) and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

AddFunction ElementalAoeCdActions
{
 unless Talent(stormkeeper_talent) and Spell(stormkeeper) or target.Refreshable(flame_shock_debuff) and { Enemies() < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies() == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if Talent(ascendance_talent) and { Talent(storm_elemental_talent) and SpellCooldown(storm_elemental) < 120 and SpellCooldown(storm_elemental) > 15 or not Talent(storm_elemental_talent) } and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalAoeCdPostConditions
{
 Talent(stormkeeper_talent) and Spell(stormkeeper) or target.Refreshable(flame_shock_debuff) and { Enemies() < 5 - Talent(totem_mastery_talent_elemental no) or not Talent(storm_elemental_talent) and { SpellCooldown(fire_elemental) > 120 + 14 * { 100 / { 100 + SpellCastSpeedPercent() } } or SpellCooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + SpellCastSpeedPercent() } } } } and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 or Enemies() == 3 and BuffStacks(wind_gust_buff) < 14 } and Spell(flame_shock) or Talent(liquid_magma_totem_talent) and Spell(liquid_magma_totem) or { not Talent(master_of_the_elements_talent) or BuffPresent(stormkeeper_buff) or Maelstrom() >= 100 - 4 * Enemies() or BuffPresent(master_of_the_elements_buff) or Enemies() > 3 } and Spell(earthquake) or BuffRemaining(stormkeeper_buff) < 3 * GCD() * BuffStacks(stormkeeper_buff) and Spell(chain_lightning_elemental) or BuffPresent(lava_surge_buff) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and target.DebuffPresent(flame_shock_debuff) and Spell(lava_burst) or Enemies() < 4 and not BuffPresent(ascendance_elemental_buff) and Spell(icefury) or Enemies() < 4 and BuffPresent(icefury_buff) and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Talent(elemental_blast_talent) and Enemies() < 4 and { not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 } and Spell(elemental_blast) or Talent(ascendance_talent) and Spell(lava_beam) or Spell(chain_lightning_elemental) or Speed() > 0 and Talent(ascendance_talent) and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(frost_shock)
}

### actions.default

AddFunction ElementalDefaultMainActions
{
 #totem_mastery,if=talent.totem_mastery.enabled&buff.resonance_totem.remains<2
 if Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } Spell(totem_mastery_elemental)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #ripple_in_space
 Spell(ripple_in_space)
 #worldvein_resonance
 Spell(worldvein_resonance_essence)
 #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
 if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeMainActions()

 unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeMainPostConditions()
 {
  #run_action_list,name=single_target
  ElementalSingletargetMainActions()
 }
}

AddFunction ElementalDefaultMainPostConditions
{
 Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeMainPostConditions() or ElementalSingletargetMainPostConditions()
}

AddFunction ElementalDefaultShortCdActions
{
 unless Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Spell(concentrated_flame_essence) or Spell(focused_azerite_beam)
 {
  #purifying_blast
  Spell(purifying_blast)
  #the_unbound_force
  Spell(the_unbound_force)

  unless Spell(ripple_in_space) or Spell(worldvein_resonance_essence)
  {
   #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
   if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeShortCdActions()

   unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeShortCdPostConditions()
   {
    #run_action_list,name=single_target
    ElementalSingletargetShortCdActions()
   }
  }
 }
}

AddFunction ElementalDefaultShortCdPostConditions
{
 Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(ripple_in_space) or Spell(worldvein_resonance_essence) or Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeShortCdPostConditions() or ElementalSingletargetShortCdPostConditions()
}

AddFunction ElementalDefaultCdActions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 if HasAzeriteTrait(ancestral_resonance_trait) ElementalBloodlust()
 #potion,if=expected_combat_length-time<30|cooldown.fire_elemental.remains>120|cooldown.storm_elemental.remains>120
 if { 600 - TimeInCombat() < 30 or SpellCooldown(fire_elemental) > 120 or SpellCooldown(storm_elemental) > 120 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_intellect usable=1)
 #wind_shear
 ElementalInterruptActions()

 unless Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental)
 {
  #fire_elemental,if=!talent.storm_elemental.enabled
  if not Talent(storm_elemental_talent) Spell(fire_elemental)
  #storm_elemental,if=talent.storm_elemental.enabled&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)&(!talent.ascendance.enabled|!cooldown.ascendance.up)
  if Talent(storm_elemental_talent) and { not Talent(icefury_talent) or not BuffPresent(icefury_buff) and not { not SpellCooldown(icefury) > 0 } } and { not Talent(ascendance_talent) or not { not SpellCooldown(ascendance_elemental) > 0 } } Spell(storm_elemental)
  #earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<120&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120&talent.storm_elemental.enabled)
  if not Talent(primal_elementalist_talent) or Talent(primal_elementalist_talent) and { SpellCooldown(fire_elemental) < 120 and not Talent(storm_elemental_talent) or SpellCooldown(storm_elemental) < 120 and Talent(storm_elemental_talent) } Spell(earth_elemental)
  #use_items
  ElementalUseItemActions()

  unless Spell(concentrated_flame_essence)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
   #guardian_of_azeroth
   Spell(guardian_of_azeroth)

   unless Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force)
   {
    #memory_of_lucid_dreams
    Spell(memory_of_lucid_dreams)

    unless Spell(ripple_in_space) or Spell(worldvein_resonance_essence)
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
     if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeCdActions()

     unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeCdPostConditions()
     {
      #run_action_list,name=single_target
      ElementalSingletargetCdActions()
     }
    }
   }
  }
 }
}

AddFunction ElementalDefaultCdPostConditions
{
 Talent(totem_mastery_talent_elemental) and TotemRemaining(totem_mastery_elemental) < 2 and { InCombat() or not BuffPresent(ele_resonance_totem_buff) } and Spell(totem_mastery_elemental) or Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(the_unbound_force) or Spell(ripple_in_space) or Spell(worldvein_resonance_essence) or Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeCdPostConditions() or ElementalSingletargetCdPostConditions()
}

### Elemental icons.

AddCheckBox(opt_shaman_elemental_aoe L(AOE) default specialization=elemental)

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=shortcd specialization=elemental
{
 if not InCombat() ElementalPrecombatShortCdActions()
 unless not InCombat() and ElementalPrecombatShortCdPostConditions()
 {
  ElementalDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_shaman_elemental_aoe help=shortcd specialization=elemental
{
 if not InCombat() ElementalPrecombatShortCdActions()
 unless not InCombat() and ElementalPrecombatShortCdPostConditions()
 {
  ElementalDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=elemental
{
 if not InCombat() ElementalPrecombatMainActions()
 unless not InCombat() and ElementalPrecombatMainPostConditions()
 {
  ElementalDefaultMainActions()
 }
}

AddIcon checkbox=opt_shaman_elemental_aoe help=aoe specialization=elemental
{
 if not InCombat() ElementalPrecombatMainActions()
 unless not InCombat() and ElementalPrecombatMainPostConditions()
 {
  ElementalDefaultMainActions()
 }
}

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=cd specialization=elemental
{
 if not InCombat() ElementalPrecombatCdActions()
 unless not InCombat() and ElementalPrecombatCdPostConditions()
 {
  ElementalDefaultCdActions()
 }
}

AddIcon checkbox=opt_shaman_elemental_aoe help=cd specialization=elemental
{
 if not InCombat() ElementalPrecombatCdActions()
 unless not InCombat() and ElementalPrecombatCdPostConditions()
 {
  ElementalDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_elemental
# ascendance_elemental_buff
# ascendance_talent
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# bloodlust
# call_the_thunder_talent
# capacitor_totem
# chain_lightning_elemental
# concentrated_flame_essence
# earth_elemental
# earth_shock
# earthquake
# echo_of_the_elementals_trait
# echo_of_the_elements_talent_elemental
# ele_resonance_totem_buff
# elemental_blast
# elemental_blast_talent
# fire_elemental
# fireblood
# flame_shock
# flame_shock_debuff
# focused_azerite_beam
# frost_shock
# guardian_of_azeroth
# heroism
# hex
# icefury
# icefury_buff
# icefury_talent
# igneous_potential_trait
# item_battle_potion_of_intellect
# lava_beam
# lava_burst
# lava_shock_buff
# lava_shock_trait
# lava_surge_buff
# lightning_bolt_elemental
# liquid_magma_totem
# liquid_magma_totem_talent
# master_of_the_elements_buff
# master_of_the_elements_talent
# memory_of_lucid_dreams
# natural_harmony_trait
# primal_elementalist_talent
# purifying_blast
# quaking_palm
# ripple_in_space
# storm_elemental
# storm_elemental_talent
# stormkeeper
# stormkeeper_buff
# stormkeeper_talent
# surge_of_power_buff
# surge_of_power_talent
# tectonic_thunder
# tectonic_thunder_trait
# the_unbound_force
# totem_mastery_elemental
# totem_mastery_talent_elemental
# war_stomp
# wind_gust_buff
# wind_shear
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
end
do
    local name = "sc_pr_shaman_enhancement"
    local desc = "[8.2] Simulationcraft: PR_Shaman_Enhancement"
    local code = [[
# Based on SimulationCraft profile "PR_Shaman_Enhancement".
#	class=shaman
#	spec=enhancement
#	talents=1101033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)


AddFunction rockslide_enabled
{
 not freezerburn_enabled() and Talent(boulderfist_talent) and Talent(landslide_talent) and HasAzeriteTrait(strength_of_earth_trait)
}

AddFunction freezerburn_enabled
{
 Talent(hot_hand_talent) and Talent(hailstorm_talent) and HasAzeriteTrait(primal_primer_trait)
}

AddFunction CLPool_SS
{
 Enemies() == 1 or Maelstrom() >= PowerCost(crash_lightning) + PowerCost(stormstrike)
}

AddFunction CLPool_LL
{
 Enemies() == 1 or Maelstrom() >= PowerCost(crash_lightning) + PowerCost(lava_lash)
}

AddFunction OCPool_FB
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(frostbrand) }
}

AddFunction OCPool_CL
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(crash_lightning) }
}

AddFunction OCPool_LL
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(lava_lash) }
}

AddFunction OCPool_SS
{
 OCPool() or Maelstrom() >= TalentPoints(overcharge_talent) * { 40 + PowerCost(stormstrike) }
}

AddFunction OCPool
{
 Enemies() > 1 or SpellCooldown(lightning_bolt_enhancement) >= 2 * GCD()
}

AddFunction furyCheck_LB
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + 40 }
}

AddFunction furyCheck_ES
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(earthen_spike) }
}

AddFunction furyCheck_FB
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(frostbrand) }
}

AddFunction furyCheck_CL
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(crash_lightning) }
}

AddFunction furyCheck_LL
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(lava_lash) }
}

AddFunction furyCheck_SS
{
 Maelstrom() >= TalentPoints(fury_of_air_talent) * { 6 + PowerCost(stormstrike) }
}

AddFunction cooldown_sync
{
 Talent(ascendance_talent_enhancement) and { BuffPresent(ascendance_enhancement_buff) or SpellCooldown(ascendance_enhancement) > 50 } or not Talent(ascendance_talent_enhancement) and { TotemRemaining(sprit_wolf) > 5 or SpellCooldown(feral_spirit) > 50 }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=enhancement)
AddCheckBox(opt_bloodlust SpellName(bloodlust) specialization=enhancement)

AddFunction EnhancementInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(sundering)
  if not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(capacitor_totem)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) Spell(hex)
 }
}

AddFunction EnhancementUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction EnhancementBloodlust
{
 if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
 {
  Spell(bloodlust)
  Spell(heroism)
 }
}

AddFunction EnhancementGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(stormstrike)
 {
  if target.InRange(feral_lunge) Spell(feral_lunge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.priority

AddFunction EnhancementPriorityMainActions
{
 #crash_lightning,if=active_enemies>=(8-(talent.forceful_winds.enabled*3))&variable.freezerburn_enabled&variable.furyCheck_CL
 if Enemies() >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() Spell(crash_lightning)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&active_enemies=1&variable.freezerburn_enabled&variable.furyCheck_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies() == 1 and freezerburn_enabled() and furyCheck_LL() Spell(lava_lash)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() Spell(crash_lightning)
 #fury_of_air,if=!buff.fury_of_air.up&maelstrom>=20&spell_targets.fury_of_air_damage>=(1+variable.freezerburn_enabled)
 if not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies() >= 1 + freezerburn_enabled() Spell(fury_of_air)
 #fury_of_air,if=buff.fury_of_air.up&&spell_targets.fury_of_air_damage<(1+variable.freezerburn_enabled)
 if BuffPresent(fury_of_air_buff) and Enemies() < 1 + freezerburn_enabled() Spell(fury_of_air)
 #totem_mastery,if=buff.resonance_totem.remains<=2*gcd
 if TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and { InCombat() or not BuffPresent(enh_resonance_totem_buff) } Spell(totem_mastery_enhancement)
 #sundering,if=active_enemies>=3
 if Enemies() >= 3 Spell(sundering)
 #focused_azerite_beam,if=active_enemies>=3
 if Enemies() >= 3 Spell(focused_azerite_beam)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 Spell(rockbiter)
 #frostbrand,if=(azerite.natural_harmony.enabled&buff.natural_harmony_frost.remains<=2*gcd)&talent.hailstorm.enabled&variable.furyCheck_FB
 if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() Spell(frostbrand)
 #flametongue,if=(azerite.natural_harmony.enabled&buff.natural_harmony_fire.remains<=2*gcd)
 if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_fire) <= 2 * GCD() Spell(flametongue)
 #rockbiter,if=(azerite.natural_harmony.enabled&buff.natural_harmony_nature.remains<=2*gcd)&maelstrom<70
 if HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 Spell(rockbiter)
}

AddFunction EnhancementPriorityMainPostConditions
{
}

AddFunction EnhancementPriorityShortCdActions
{
 unless Enemies() >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and Spell(crash_lightning)
 {
  #the_unbound_force,if=buff.reckless_force.up|time<5
  if BuffPresent(reckless_force_buff) or TimeInCombat() < 5 Spell(the_unbound_force)

  unless AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies() >= 1 + freezerburn_enabled() and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies() < 1 + freezerburn_enabled() and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and { InCombat() or not BuffPresent(enh_resonance_totem_buff) } and Spell(totem_mastery_enhancement) or Enemies() >= 3 and Spell(sundering) or Enemies() >= 3 and Spell(focused_azerite_beam)
  {
   #purifying_blast,if=active_enemies>=3
   if Enemies() >= 3 Spell(purifying_blast)
  }
 }
}

AddFunction EnhancementPriorityShortCdPostConditions
{
 Enemies() >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and Spell(crash_lightning) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies() >= 1 + freezerburn_enabled() and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies() < 1 + freezerburn_enabled() and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and { InCombat() or not BuffPresent(enh_resonance_totem_buff) } and Spell(totem_mastery_enhancement) or Enemies() >= 3 and Spell(sundering) or Enemies() >= 3 and Spell(focused_azerite_beam) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and Spell(rockbiter) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and Spell(frostbrand) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_fire) <= 2 * GCD() and Spell(flametongue) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 and Spell(rockbiter)
}

AddFunction EnhancementPriorityCdActions
{
}

AddFunction EnhancementPriorityCdPostConditions
{
 Enemies() >= 8 - TalentPoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and Spell(crash_lightning) or { BuffPresent(reckless_force_buff) or TimeInCombat() < 5 } and Spell(the_unbound_force) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and Enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and Spell(lava_lash) or not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or not BuffPresent(fury_of_air_buff) and Maelstrom() >= 20 and Enemies() >= 1 + freezerburn_enabled() and Spell(fury_of_air) or BuffPresent(fury_of_air_buff) and Enemies() < 1 + freezerburn_enabled() and Spell(fury_of_air) or TotemRemaining(totem_mastery_enhancement) <= 2 * GCD() and { InCombat() or not BuffPresent(enh_resonance_totem_buff) } and Spell(totem_mastery_enhancement) or Enemies() >= 3 and Spell(sundering) or Enemies() >= 3 and Spell(focused_azerite_beam) or Enemies() >= 3 and Spell(purifying_blast) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and Spell(rockbiter) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_frost) <= 2 * GCD() and Talent(hailstorm_talent) and furyCheck_FB() and Spell(frostbrand) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_fire) <= 2 * GCD() and Spell(flametongue) or HasAzeriteTrait(natural_harmony_trait) and BuffRemaining(natural_harmony_nature) <= 2 * GCD() and Maelstrom() < 70 and Spell(rockbiter)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
}

AddFunction EnhancementPrecombatCdPostConditions
{
 Spell(lightning_shield)
}

### actions.opener

AddFunction EnhancementOpenerMainActions
{
 #rockbiter,if=maelstrom<15&time<gcd
 if Maelstrom() < 15 and TimeInCombat() < GCD() Spell(rockbiter)
}

AddFunction EnhancementOpenerMainPostConditions
{
}

AddFunction EnhancementOpenerShortCdActions
{
}

AddFunction EnhancementOpenerShortCdPostConditions
{
 Maelstrom() < 15 and TimeInCombat() < GCD() and Spell(rockbiter)
}

AddFunction EnhancementOpenerCdActions
{
}

AddFunction EnhancementOpenerCdPostConditions
{
 Maelstrom() < 15 and TimeInCombat() < GCD() and Spell(rockbiter)
}

### actions.maintenance

AddFunction EnhancementMaintenanceMainActions
{
 #flametongue,if=!buff.flametongue.up
 if not BuffPresent(flametongue_buff) Spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck_FB
 if Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() Spell(frostbrand)
}

AddFunction EnhancementMaintenanceMainPostConditions
{
}

AddFunction EnhancementMaintenanceShortCdActions
{
}

AddFunction EnhancementMaintenanceShortCdPostConditions
{
 not BuffPresent(flametongue_buff) and Spell(flametongue) or Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() and Spell(frostbrand)
}

AddFunction EnhancementMaintenanceCdActions
{
}

AddFunction EnhancementMaintenanceCdPostConditions
{
 not BuffPresent(flametongue_buff) and Spell(flametongue) or Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck_FB() and Spell(frostbrand)
}

### actions.freezerburn_core

AddFunction EnhancementFreezerburncoreMainActions
{
 #lava_lash,target_if=max:debuff.primal_primer.stack,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&variable.furyCheck_LL&variable.CLPool_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() Spell(lava_lash)
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() Spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() Spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() Spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if Enemies() >= 3 and furyCheck_CL() Spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 Spell(lightning_bolt_enhancement)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack>7&variable.furyCheck_LL&variable.CLPool_LL
 if AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() Spell(lava_lash)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS&variable.CLPool_SS
 if OCPool_SS() and furyCheck_SS() and CLPool_SS() Spell(stormstrike)
 #lava_lash,if=debuff.primal_primer.stack=10&variable.furyCheck_LL
 if target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() Spell(lava_lash)
}

AddFunction EnhancementFreezerburncoreMainPostConditions
{
}

AddFunction EnhancementFreezerburncoreShortCdActions
{
}

AddFunction EnhancementFreezerburncoreShortCdPostConditions
{
 AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and Spell(lava_lash) or furyCheck_ES() and Spell(earthen_spike) or Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and Spell(stormstrike) or Enemies() >= 3 and furyCheck_CL() and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and Spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and Spell(stormstrike) or target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and Spell(lava_lash)
}

AddFunction EnhancementFreezerburncoreCdActions
{
}

AddFunction EnhancementFreezerburncoreCdPostConditions
{
 AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and Spell(lava_lash) or furyCheck_ES() and Spell(earthen_spike) or Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and Spell(stormstrike) or Enemies() >= 3 and furyCheck_CL() and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or AzeriteTraitRank(primal_primer_trait) >= 2 and target.DebuffStacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and Spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and Spell(stormstrike) or target.DebuffStacks(primal_primer) == 10 and furyCheck_LL() and Spell(lava_lash)
}

### actions.filler

AddFunction EnhancementFillerMainActions
{
 #sundering
 Spell(sundering)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #worldvein_resonance
 Spell(worldvein_resonance_essence)
 #crash_lightning,if=talent.forceful_winds.enabled&active_enemies>1&variable.furyCheck_CL
 if Talent(forceful_winds_talent) and Enemies() > 1 and furyCheck_CL() Spell(crash_lightning)
 #flametongue,if=talent.searing_assault.enabled
 if Talent(searing_assault_talent) Spell(flametongue)
 #lava_lash,if=!azerite.primal_primer.enabled&talent.hot_hand.enabled&buff.hot_hand.react
 if not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) Spell(lava_lash)
 #crash_lightning,if=active_enemies>1&variable.furyCheck_CL
 if Enemies() > 1 and furyCheck_CL() Spell(crash_lightning)
 #rockbiter,if=maelstrom<70&!buff.strength_of_earth.up
 if Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) Spell(rockbiter)
 #crash_lightning,if=talent.crashing_storm.enabled&variable.OCPool_CL
 if Talent(crashing_storm_talent) and OCPool_CL() Spell(crash_lightning)
 #lava_lash,if=variable.OCPool_LL&variable.furyCheck_LL
 if OCPool_LL() and furyCheck_LL() Spell(lava_lash)
 #rockbiter
 Spell(rockbiter)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8+gcd&variable.furyCheck_FB
 if Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() Spell(frostbrand)
 #flametongue
 Spell(flametongue)
}

AddFunction EnhancementFillerMainPostConditions
{
}

AddFunction EnhancementFillerShortCdActions
{
 unless Spell(sundering) or Spell(focused_azerite_beam)
 {
  #purifying_blast
  Spell(purifying_blast)
 }
}

AddFunction EnhancementFillerShortCdPostConditions
{
 Spell(sundering) or Spell(focused_azerite_beam) or Spell(concentrated_flame_essence) or Spell(worldvein_resonance_essence) or Talent(forceful_winds_talent) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Talent(searing_assault_talent) and Spell(flametongue) or not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and Spell(lava_lash) or Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and Spell(rockbiter) or Talent(crashing_storm_talent) and OCPool_CL() and Spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and Spell(lava_lash) or Spell(rockbiter) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and Spell(frostbrand) or Spell(flametongue)
}

AddFunction EnhancementFillerCdActions
{
}

AddFunction EnhancementFillerCdPostConditions
{
 Spell(sundering) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(concentrated_flame_essence) or Spell(worldvein_resonance_essence) or Talent(forceful_winds_talent) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Talent(searing_assault_talent) and Spell(flametongue) or not HasAzeriteTrait(primal_primer_trait) and Talent(hot_hand_talent) and BuffPresent(hot_hand_buff) and Spell(lava_lash) or Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Maelstrom() < 70 and not BuffPresent(strength_of_earth_buff) and Spell(rockbiter) or Talent(crashing_storm_talent) and OCPool_CL() and Spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and Spell(lava_lash) or Spell(rockbiter) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4.8 + GCD() and furyCheck_FB() and Spell(frostbrand) or Spell(flametongue)
}

### actions.default_core

AddFunction EnhancementDefaultcoreMainActions
{
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() Spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() Spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() Spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if Enemies() >= 3 and furyCheck_CL() Spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 Spell(lightning_bolt_enhancement)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS
 if OCPool_SS() and furyCheck_SS() Spell(stormstrike)
}

AddFunction EnhancementDefaultcoreMainPostConditions
{
}

AddFunction EnhancementDefaultcoreShortCdActions
{
}

AddFunction EnhancementDefaultcoreShortCdPostConditions
{
 furyCheck_ES() and Spell(earthen_spike) or Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and Spell(stormstrike) or Enemies() >= 3 and furyCheck_CL() and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and Spell(stormstrike)
}

AddFunction EnhancementDefaultcoreCdActions
{
}

AddFunction EnhancementDefaultcoreCdPostConditions
{
 furyCheck_ES() and Spell(earthen_spike) or Enemies() > 1 and HasAzeriteTrait(lightning_conduit_trait) and not target.DebuffPresent(lightning_conduit_debuff) and furyCheck_SS() and Spell(stormstrike) or { BuffPresent(stormbringer_buff) or Enemies() > 1 and BuffPresent(gathering_storms_buff) and furyCheck_SS() } and Spell(stormstrike) or Enemies() >= 3 and furyCheck_CL() and Spell(crash_lightning) or Talent(overcharge_talent) and Enemies() == 1 and furyCheck_LB() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and Spell(stormstrike)
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
 if HasAzeriteTrait(ancestral_resonance_trait) EnhancementBloodlust()
 #berserking,if=variable.cooldown_sync
 if cooldown_sync() Spell(berserking)
 #blood_fury,if=variable.cooldown_sync
 if cooldown_sync() Spell(blood_fury_apsp)
 #fireblood,if=variable.cooldown_sync
 if cooldown_sync() Spell(fireblood)
 #ancestral_call,if=variable.cooldown_sync
 if cooldown_sync() Spell(ancestral_call)
 #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
 if { BuffPresent(ascendance_enhancement_buff) or not Talent(ascendance_talent_enhancement) and TotemRemaining(sprit_wolf) > 5 or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams)
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

### actions.asc

AddFunction EnhancementAscMainActions
{
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() Spell(crash_lightning)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 Spell(rockbiter)
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
 not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and Spell(rockbiter) or Spell(windstrike)
}

AddFunction EnhancementAscCdActions
{
}

AddFunction EnhancementAscCdPostConditions
{
 not BuffPresent(crash_lightning_buff) and Enemies() > 1 and furyCheck_CL() and Spell(crash_lightning) or Talent(landslide_talent) and not BuffPresent(landslide_buff) and Charges(rockbiter count=0) > 1.7 and Spell(rockbiter) or Spell(windstrike)
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
    if Enemies() < 3 EnhancementMaintenanceMainActions()

    unless Enemies() < 3 and EnhancementMaintenanceMainPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsMainActions()

     unless EnhancementCdsMainPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburncoreMainActions()

      unless freezerburn_enabled() and EnhancementFreezerburncoreMainPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultcoreMainActions()

       unless not freezerburn_enabled() and EnhancementDefaultcoreMainPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies() >= 3 EnhancementMaintenanceMainActions()

        unless Enemies() >= 3 and EnhancementMaintenanceMainPostConditions()
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
 EnhancementOpenerMainPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscMainPostConditions() or EnhancementPriorityMainPostConditions() or Enemies() < 3 and EnhancementMaintenanceMainPostConditions() or EnhancementCdsMainPostConditions() or freezerburn_enabled() and EnhancementFreezerburncoreMainPostConditions() or not freezerburn_enabled() and EnhancementDefaultcoreMainPostConditions() or Enemies() >= 3 and EnhancementMaintenanceMainPostConditions() or EnhancementFillerMainPostConditions()
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
 EnhancementGetInMeleeRange()
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
    if Enemies() < 3 EnhancementMaintenanceShortCdActions()

    unless Enemies() < 3 and EnhancementMaintenanceShortCdPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsShortCdActions()

     unless EnhancementCdsShortCdPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburncoreShortCdActions()

      unless freezerburn_enabled() and EnhancementFreezerburncoreShortCdPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultcoreShortCdActions()

       unless not freezerburn_enabled() and EnhancementDefaultcoreShortCdPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies() >= 3 EnhancementMaintenanceShortCdActions()

        unless Enemies() >= 3 and EnhancementMaintenanceShortCdPostConditions()
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
 EnhancementOpenerShortCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscShortCdPostConditions() or EnhancementPriorityShortCdPostConditions() or Enemies() < 3 and EnhancementMaintenanceShortCdPostConditions() or EnhancementCdsShortCdPostConditions() or freezerburn_enabled() and EnhancementFreezerburncoreShortCdPostConditions() or not freezerburn_enabled() and EnhancementDefaultcoreShortCdPostConditions() or Enemies() >= 3 and EnhancementMaintenanceShortCdPostConditions() or EnhancementFillerShortCdPostConditions()
}

AddFunction EnhancementDefaultCdActions
{
 #wind_shear
 EnhancementInterruptActions()
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
    if Enemies() < 3 EnhancementMaintenanceCdActions()

    unless Enemies() < 3 and EnhancementMaintenanceCdPostConditions()
    {
     #call_action_list,name=cds
     EnhancementCdsCdActions()

     unless EnhancementCdsCdPostConditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() EnhancementFreezerburncoreCdActions()

      unless freezerburn_enabled() and EnhancementFreezerburncoreCdPostConditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() EnhancementDefaultcoreCdActions()

       unless not freezerburn_enabled() and EnhancementDefaultcoreCdPostConditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if Enemies() >= 3 EnhancementMaintenanceCdActions()

        unless Enemies() >= 3 and EnhancementMaintenanceCdPostConditions()
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
 EnhancementOpenerCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscCdPostConditions() or EnhancementPriorityCdPostConditions() or Enemies() < 3 and EnhancementMaintenanceCdPostConditions() or EnhancementCdsCdPostConditions() or freezerburn_enabled() and EnhancementFreezerburncoreCdPostConditions() or not freezerburn_enabled() and EnhancementDefaultcoreCdPostConditions() or Enemies() >= 3 and EnhancementMaintenanceCdPostConditions() or EnhancementFillerCdPostConditions()
}

### Enhancement icons.

AddCheckBox(opt_shaman_enhancement_aoe L(AOE) default specialization=enhancement)

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=shortcd specialization=enhancement
{
 if not InCombat() EnhancementPrecombatShortCdActions()
 unless not InCombat() and EnhancementPrecombatShortCdPostConditions()
 {
  EnhancementDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=shortcd specialization=enhancement
{
 if not InCombat() EnhancementPrecombatShortCdActions()
 unless not InCombat() and EnhancementPrecombatShortCdPostConditions()
 {
  EnhancementDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=enhancement
{
 if not InCombat() EnhancementPrecombatMainActions()
 unless not InCombat() and EnhancementPrecombatMainPostConditions()
 {
  EnhancementDefaultMainActions()
 }
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=aoe specialization=enhancement
{
 if not InCombat() EnhancementPrecombatMainActions()
 unless not InCombat() and EnhancementPrecombatMainPostConditions()
 {
  EnhancementDefaultMainActions()
 }
}

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=cd specialization=enhancement
{
 if not InCombat() EnhancementPrecombatCdActions()
 unless not InCombat() and EnhancementPrecombatCdPostConditions()
 {
  EnhancementDefaultCdActions()
 }
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=cd specialization=enhancement
{
 if not InCombat() EnhancementPrecombatCdActions()
 unless not InCombat() and EnhancementPrecombatCdPostConditions()
 {
  EnhancementDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_enhancement
# ascendance_enhancement_buff
# ascendance_talent_enhancement
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# bloodlust
# boulderfist_talent
# capacitor_totem
# concentrated_flame_essence
# crash_lightning
# crash_lightning_buff
# crashing_storm_talent
# earth_elemental
# earthen_spike
# enh_resonance_totem_buff
# feral_lunge
# feral_spirit
# fireblood
# flametongue
# flametongue_buff
# focused_azerite_beam
# forceful_winds_talent
# frostbrand
# frostbrand_buff
# fury_of_air
# fury_of_air_buff
# fury_of_air_talent
# gathering_storms_buff
# guardian_of_azeroth
# hailstorm_talent
# heroism
# hex
# hot_hand_buff
# hot_hand_talent
# item_battle_potion_of_agility
# landslide_buff
# landslide_talent
# lava_lash
# lightning_bolt_enhancement
# lightning_conduit_debuff
# lightning_conduit_trait
# lightning_shield
# memory_of_lucid_dreams
# natural_harmony_fire
# natural_harmony_frost
# natural_harmony_nature
# natural_harmony_trait
# overcharge_talent
# primal_primer
# primal_primer_trait
# purifying_blast
# quaking_palm
# reckless_force_buff
# rockbiter
# searing_assault_talent
# stormbringer_buff
# stormstrike
# strength_of_earth_buff
# strength_of_earth_trait
# sundering
# the_unbound_force
# totem_mastery_enhancement
# war_stomp
# wind_shear
# windstrike
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
end
