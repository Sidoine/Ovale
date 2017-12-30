local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_shaman_elemental_t19"
    local desc = "[7.0] Simulationcraft: Shaman_Elemental_T19"
    local code = [[
# Based on SimulationCraft profile "Shaman_Elemental_T19P".
#	class=shaman
#	spec=elemental
#	talents=2112333

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
  if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) Spell(hex)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(lightning_surge_totem)
  if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
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

### actions.single_lr

AddFunction ElementalSinglelrMainActions
{
 #flame_shock,if=!ticking|dot.flame_shock.remains<=gcd
 if not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() Spell(flame_shock)
 #elemental_blast
 Spell(elemental_blast)
 #earthquake,if=buff.echoes_of_the_great_sundering.up
 if BuffPresent(echoes_of_the_great_sundering_buff) Spell(earthquake)
 #earth_shock,if=maelstrom>=117|!artifact.swelling_maelstrom.enabled&maelstrom>=92
 if Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 Spell(earth_shock)
 #stormkeeper,if=raid_event.adds.count<3|raid_event.adds.in>50
 if 0 < 3 or 600 > 50 Spell(stormkeeper)
 #lava_burst,if=dot.flame_shock.remains>cast_time&cooldown_react
 if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
 #flame_shock,if=maelstrom>=20&buff.elemental_focus.up,target_if=refreshable
 if Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earth_shock,if=maelstrom>=111|!artifact.swelling_maelstrom.enabled&maelstrom>=86|equipped.smoldering_heart&equipped.the_deceivers_blood_pact&maelstrom>70&talent.aftershock.enabled
 if Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) Spell(earth_shock)
 #totem_mastery,if=buff.resonance_totem.remains<10|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15)
 if { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 Spell(totem_mastery)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&spell_targets.chain_lightning<3,target_if=debuff.lightning_rod.down
 if BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and target.DebuffExpires(lightning_rod_debuff) Spell(lightning_bolt_elemental)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&spell_targets.chain_lightning<3
 if BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 Spell(lightning_bolt_elemental)
 #chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1,target_if=debuff.lightning_rod.down
 if Enemies() > 1 and Enemies() > 1 and target.DebuffExpires(lightning_rod_debuff) Spell(chain_lightning)
 #chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1
 if Enemies() > 1 and Enemies() > 1 Spell(chain_lightning)
 #lightning_bolt,target_if=debuff.lightning_rod.down
 if target.DebuffExpires(lightning_rod_debuff) Spell(lightning_bolt_elemental)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earth_shock,moving=1
 if Speed() > 0 Spell(earth_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
}

AddFunction ElementalSinglelrMainPostConditions
{
}

AddFunction ElementalSinglelrShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper)
 {
  #liquid_magma_totem,if=raid_event.adds.count<3|raid_event.adds.in>50
  if 0 < 3 or 600 > 50 Spell(liquid_magma_totem)
 }
}

AddFunction ElementalSinglelrShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and target.DebuffExpires(lightning_rod_debuff) and Spell(lightning_bolt_elemental) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and target.DebuffExpires(lightning_rod_debuff) and Spell(chain_lightning) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or target.DebuffExpires(lightning_rod_debuff) and Spell(lightning_bolt_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

AddFunction ElementalSinglelrCdActions
{
}

AddFunction ElementalSinglelrCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and target.DebuffExpires(lightning_rod_debuff) and Spell(lightning_bolt_elemental) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and target.DebuffExpires(lightning_rod_debuff) and Spell(chain_lightning) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or target.DebuffExpires(lightning_rod_debuff) and Spell(lightning_bolt_elemental) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

### actions.single_if

AddFunction ElementalSingleifMainActions
{
 #flame_shock,if=!ticking|dot.flame_shock.remains<=gcd
 if not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() Spell(flame_shock)
 #earthquake,if=buff.echoes_of_the_great_sundering.up&maelstrom>=86
 if BuffPresent(echoes_of_the_great_sundering_buff) and Maelstrom() >= 86 Spell(earthquake)
 #frost_shock,if=buff.icefury.up&maelstrom>=111&!buff.ascendance.up
 if BuffPresent(icefury_buff) and Maelstrom() >= 111 and not BuffPresent(ascendance_elemental_buff) Spell(frost_shock)
 #elemental_blast
 Spell(elemental_blast)
 #earth_shock,if=maelstrom>=117|!artifact.swelling_maelstrom.enabled&maelstrom>=92
 if Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 Spell(earth_shock)
 #stormkeeper,if=raid_event.adds.count<3|raid_event.adds.in>50
 if 0 < 3 or 600 > 50 Spell(stormkeeper)
 #icefury,if=(raid_event.movement.in<5|maelstrom<=101&artifact.swelling_maelstrom.enabled|!artifact.swelling_maelstrom.enabled&maelstrom<=76)&!buff.ascendance.up
 if { 600 < 5 or Maelstrom() <= 101 and HasArtifactTrait(swelling_maelstrom) or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() <= 76 } and not BuffPresent(ascendance_elemental_buff) Spell(icefury)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&buff.stormkeeper.up&spell_targets.chain_lightning<3
 if BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 Spell(lightning_bolt_elemental)
 #lava_burst,if=dot.flame_shock.remains>cast_time&cooldown_react
 if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 Spell(lava_burst)
 #frost_shock,if=buff.icefury.up&((maelstrom>=20&raid_event.movement.in>buff.icefury.remains)|buff.icefury.remains<(1.5*spell_haste*buff.icefury.stack+1))
 if BuffPresent(icefury_buff) and { Maelstrom() >= 20 and 600 > BuffRemaining(icefury_buff) or BuffRemaining(icefury_buff) < 1 * { 100 / { 100 + SpellHaste() } } * BuffStacks(icefury_buff) + 1 } Spell(frost_shock)
 #flame_shock,if=maelstrom>=20&buff.elemental_focus.up,target_if=refreshable
 if Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #frost_shock,moving=1,if=buff.icefury.up
 if Speed() > 0 and BuffPresent(icefury_buff) Spell(frost_shock)
 #earth_shock,if=maelstrom>=111|!artifact.swelling_maelstrom.enabled&maelstrom>=86|equipped.smoldering_heart&equipped.the_deceivers_blood_pact&maelstrom>70&talent.aftershock.enabled
 if Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) Spell(earth_shock)
 #totem_mastery,if=buff.resonance_totem.remains<10
 if TotemRemaining(totem_mastery) < 10 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 Spell(totem_mastery)
 #earthquake,if=buff.echoes_of_the_great_sundering.up
 if BuffPresent(echoes_of_the_great_sundering_buff) Spell(earthquake)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&spell_targets.chain_lightning<3
 if BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 Spell(lightning_bolt_elemental)
 #chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1
 if Enemies() > 1 and Enemies() > 1 Spell(chain_lightning)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earth_shock,moving=1
 if Speed() > 0 Spell(earth_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
}

AddFunction ElementalSingleifMainPostConditions
{
}

AddFunction ElementalSingleifShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or BuffPresent(echoes_of_the_great_sundering_buff) and Maelstrom() >= 86 and Spell(earthquake) or BuffPresent(icefury_buff) and Maelstrom() >= 111 and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Spell(elemental_blast) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or { 600 < 5 or Maelstrom() <= 101 and HasArtifactTrait(swelling_maelstrom) or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() <= 76 } and not BuffPresent(ascendance_elemental_buff) and Spell(icefury)
 {
  #liquid_magma_totem,if=raid_event.adds.count<3|raid_event.adds.in>50
  if 0 < 3 or 600 > 50 Spell(liquid_magma_totem)
 }
}

AddFunction ElementalSingleifShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or BuffPresent(echoes_of_the_great_sundering_buff) and Maelstrom() >= 86 and Spell(earthquake) or BuffPresent(icefury_buff) and Maelstrom() >= 111 and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Spell(elemental_blast) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or { 600 < 5 or Maelstrom() <= 101 and HasArtifactTrait(swelling_maelstrom) or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() <= 76 } and not BuffPresent(ascendance_elemental_buff) and Spell(icefury) or BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or BuffPresent(icefury_buff) and { Maelstrom() >= 20 and 600 > BuffRemaining(icefury_buff) or BuffRemaining(icefury_buff) < 1 * { 100 / { 100 + SpellHaste() } } * BuffStacks(icefury_buff) + 1 } and Spell(frost_shock) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and BuffPresent(icefury_buff) and Spell(frost_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or TotemRemaining(totem_mastery) < 10 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or BuffPresent(echoes_of_the_great_sundering_buff) and Spell(earthquake) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

AddFunction ElementalSingleifCdActions
{
}

AddFunction ElementalSingleifCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or BuffPresent(echoes_of_the_great_sundering_buff) and Maelstrom() >= 86 and Spell(earthquake) or BuffPresent(icefury_buff) and Maelstrom() >= 111 and not BuffPresent(ascendance_elemental_buff) and Spell(frost_shock) or Spell(elemental_blast) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or { 600 < 5 or Maelstrom() <= 101 and HasArtifactTrait(swelling_maelstrom) or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() <= 76 } and not BuffPresent(ascendance_elemental_buff) and Spell(icefury) or { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and not SpellCooldown(lava_burst) > 0 and Spell(lava_burst) or BuffPresent(icefury_buff) and { Maelstrom() >= 20 and 600 > BuffRemaining(icefury_buff) or BuffRemaining(icefury_buff) < 1 * { 100 / { 100 + SpellHaste() } } * BuffStacks(icefury_buff) + 1 } and Spell(frost_shock) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and BuffPresent(icefury_buff) and Spell(frost_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or TotemRemaining(totem_mastery) < 10 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or BuffPresent(echoes_of_the_great_sundering_buff) and Spell(earthquake) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

### actions.single_asc

AddFunction ElementalSingleascMainActions
{
 #flame_shock,if=!ticking|dot.flame_shock.remains<=gcd
 if not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() Spell(flame_shock)
 #flame_shock,if=maelstrom>=20&remains<=buff.ascendance.duration&cooldown.ascendance.remains+buff.ascendance.duration<=duration
 if Maelstrom() >= 20 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) <= BaseDuration(flame_shock_debuff) Spell(flame_shock)
 #elemental_blast
 Spell(elemental_blast)
 #earthquake,if=buff.echoes_of_the_great_sundering.up&!buff.ascendance.up&maelstrom>=86
 if BuffPresent(echoes_of_the_great_sundering_buff) and not BuffPresent(ascendance_elemental_buff) and Maelstrom() >= 86 Spell(earthquake)
 #earth_shock,if=maelstrom>=117|!artifact.swelling_maelstrom.enabled&maelstrom>=92
 if Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 Spell(earth_shock)
 #stormkeeper,if=raid_event.adds.count<3|raid_event.adds.in>50
 if 0 < 3 or 600 > 50 Spell(stormkeeper)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&buff.stormkeeper.up&spell_targets.chain_lightning<3
 if BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 Spell(lightning_bolt_elemental)
 #lava_burst,if=dot.flame_shock.remains>cast_time&(cooldown_react|buff.ascendance.up)
 if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { not SpellCooldown(lava_burst) > 0 or BuffPresent(ascendance_elemental_buff) } Spell(lava_burst)
 #flame_shock,if=maelstrom>=20&buff.elemental_focus.up,target_if=refreshable
 if Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earth_shock,if=maelstrom>=111|!artifact.swelling_maelstrom.enabled&maelstrom>=86|equipped.smoldering_heart&equipped.the_deceivers_blood_pact&maelstrom>70&talent.aftershock.enabled
 if Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) Spell(earth_shock)
 #totem_mastery,if=buff.resonance_totem.remains<10|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15)
 if { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 Spell(totem_mastery)
 #lava_beam,if=active_enemies>1&spell_targets.lava_beam>1
 if Enemies() > 1 and Enemies() > 1 Spell(lava_beam)
 #lightning_bolt,if=buff.power_of_the_maelstrom.up&spell_targets.chain_lightning<3
 if BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 Spell(lightning_bolt_elemental)
 #chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1
 if Enemies() > 1 and Enemies() > 1 Spell(chain_lightning)
 #lightning_bolt
 Spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earth_shock,moving=1
 if Speed() > 0 Spell(earth_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if Speed() > 0 and target.Distance() > 6 Spell(flame_shock)
}

AddFunction ElementalSingleascMainPostConditions
{
}

AddFunction ElementalSingleascShortCdActions
{
 unless { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Maelstrom() >= 20 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) <= BaseDuration(flame_shock_debuff) and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and not BuffPresent(ascendance_elemental_buff) and Maelstrom() >= 86 and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper)
 {
  #liquid_magma_totem,if=raid_event.adds.count<3|raid_event.adds.in>50
  if 0 < 3 or 600 > 50 Spell(liquid_magma_totem)
 }
}

AddFunction ElementalSingleascShortCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Maelstrom() >= 20 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) <= BaseDuration(flame_shock_debuff) and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and not BuffPresent(ascendance_elemental_buff) and Maelstrom() >= 86 and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { not SpellCooldown(lava_burst) > 0 or BuffPresent(ascendance_elemental_buff) } and Spell(lava_burst) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Enemies() > 1 and Enemies() > 1 and Spell(lava_beam) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

AddFunction ElementalSingleascCdActions
{
 #ascendance,if=dot.flame_shock.remains>buff.ascendance.duration&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&!buff.stormkeeper.up
 if target.DebuffRemaining(flame_shock_debuff) > BaseDuration(ascendance_elemental_buff) and { TimeInCombat() >= 60 or BuffPresent(burst_haste_buff any=1) } and SpellCooldown(lava_burst) > 0 and not BuffPresent(stormkeeper_buff) and BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
}

AddFunction ElementalSingleascCdPostConditions
{
 { not target.DebuffPresent(flame_shock_debuff) or target.DebuffRemaining(flame_shock_debuff) <= GCD() } and Spell(flame_shock) or Maelstrom() >= 20 and target.DebuffRemaining(flame_shock_debuff) <= BaseDuration(ascendance_elemental_buff) and SpellCooldown(ascendance_elemental) + BaseDuration(ascendance_elemental_buff) <= BaseDuration(flame_shock_debuff) and Spell(flame_shock) or Spell(elemental_blast) or BuffPresent(echoes_of_the_great_sundering_buff) and not BuffPresent(ascendance_elemental_buff) and Maelstrom() >= 86 and Spell(earthquake) or { Maelstrom() >= 117 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 92 } and Spell(earth_shock) or { 0 < 3 or 600 > 50 } and Spell(stormkeeper) or { 0 < 3 or 600 > 50 } and Spell(liquid_magma_totem) or BuffPresent(power_of_the_maelstrom_buff) and BuffPresent(stormkeeper_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and { not SpellCooldown(lava_burst) > 0 or BuffPresent(ascendance_elemental_buff) } and Spell(lava_burst) or Maelstrom() >= 20 and BuffPresent(elemental_focus_buff) and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or { Maelstrom() >= 111 or not HasArtifactTrait(swelling_maelstrom) and Maelstrom() >= 86 or HasEquippedItem(smoldering_heart) and HasEquippedItem(the_deceivers_blood_pact) and Maelstrom() > 70 and Talent(aftershock_talent) } and Spell(earth_shock) or { TotemRemaining(totem_mastery) < 10 or TotemRemaining(totem_mastery) < BaseDuration(ascendance_elemental_buff) + SpellCooldown(ascendance_elemental) and SpellCooldown(ascendance_elemental) < 15 } and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Enemies() > 1 and Enemies() > 1 and Spell(lava_beam) or BuffPresent(power_of_the_maelstrom_buff) and Enemies() < 3 and Spell(lightning_bolt_elemental) or Enemies() > 1 and Enemies() > 1 and Spell(chain_lightning) or Spell(lightning_bolt_elemental) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Speed() > 0 and Spell(earth_shock) or Speed() > 0 and target.Distance() > 6 and Spell(flame_shock)
}

### actions.precombat

AddFunction ElementalPrecombatMainActions
{
 #totem_mastery
 if { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 Spell(totem_mastery)
 #stormkeeper
 Spell(stormkeeper)
}

AddFunction ElementalPrecombatMainPostConditions
{
}

AddFunction ElementalPrecombatShortCdActions
{
}

AddFunction ElementalPrecombatShortCdPostConditions
{
 { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Spell(stormkeeper)
}

AddFunction ElementalPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
}

AddFunction ElementalPrecombatCdPostConditions
{
 { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Spell(stormkeeper)
}

### actions.aoe

AddFunction ElementalAoeMainActions
{
 #stormkeeper
 Spell(stormkeeper)
 #flame_shock,if=spell_targets.chain_lightning<4&maelstrom>=20,target_if=refreshable
 if Enemies() < 4 and Maelstrom() >= 20 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
 #earthquake
 Spell(earthquake)
 #lava_burst,if=dot.flame_shock.remains>cast_time&buff.lava_surge.up&!talent.lightning_rod.enabled&spell_targets.chain_lightning<4
 if target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and BuffPresent(lava_surge_buff) and not Talent(lightning_rod_talent) and Enemies() < 4 Spell(lava_burst)
 #elemental_blast,if=!talent.lightning_rod.enabled&spell_targets.chain_lightning<5|talent.lightning_rod.enabled&spell_targets.chain_lightning<4
 if not Talent(lightning_rod_talent) and Enemies() < 5 or Talent(lightning_rod_talent) and Enemies() < 4 Spell(elemental_blast)
 #lava_beam
 Spell(lava_beam)
 #chain_lightning,target_if=debuff.lightning_rod.down
 if target.DebuffExpires(lightning_rod_debuff) Spell(chain_lightning)
 #chain_lightning
 Spell(chain_lightning)
 #lava_burst,moving=1
 if Speed() > 0 Spell(lava_burst)
 #flame_shock,moving=1,target_if=refreshable
 if Speed() > 0 and target.Refreshable(flame_shock_debuff) Spell(flame_shock)
}

AddFunction ElementalAoeMainPostConditions
{
}

AddFunction ElementalAoeShortCdActions
{
 unless Spell(stormkeeper)
 {
  #liquid_magma_totem
  Spell(liquid_magma_totem)
 }
}

AddFunction ElementalAoeShortCdPostConditions
{
 Spell(stormkeeper) or Enemies() < 4 and Maelstrom() >= 20 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Spell(earthquake) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and BuffPresent(lava_surge_buff) and not Talent(lightning_rod_talent) and Enemies() < 4 and Spell(lava_burst) or { not Talent(lightning_rod_talent) and Enemies() < 5 or Talent(lightning_rod_talent) and Enemies() < 4 } and Spell(elemental_blast) or Spell(lava_beam) or target.DebuffExpires(lightning_rod_debuff) and Spell(chain_lightning) or Spell(chain_lightning) or Speed() > 0 and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock)
}

AddFunction ElementalAoeCdActions
{
 unless Spell(stormkeeper)
 {
  #ascendance
  if BuffExpires(ascendance_elemental_buff) Spell(ascendance_elemental)
 }
}

AddFunction ElementalAoeCdPostConditions
{
 Spell(stormkeeper) or Spell(liquid_magma_totem) or Enemies() < 4 and Maelstrom() >= 20 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock) or Spell(earthquake) or target.DebuffRemaining(flame_shock_debuff) > CastTime(lava_burst) and BuffPresent(lava_surge_buff) and not Talent(lightning_rod_talent) and Enemies() < 4 and Spell(lava_burst) or { not Talent(lightning_rod_talent) and Enemies() < 5 or Talent(lightning_rod_talent) and Enemies() < 4 } and Spell(elemental_blast) or Spell(lava_beam) or target.DebuffExpires(lightning_rod_debuff) and Spell(chain_lightning) or Spell(chain_lightning) or Speed() > 0 and Spell(lava_burst) or Speed() > 0 and target.Refreshable(flame_shock_debuff) and Spell(flame_shock)
}

### actions.default

AddFunction ElementalDefaultMainActions
{
 #totem_mastery,if=buff.resonance_totem.remains<2
 if TotemRemaining(totem_mastery) < 2 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 Spell(totem_mastery)
 #storm_elemental
 Spell(storm_elemental)
 #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
 if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeMainActions()

 unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeMainPostConditions()
 {
  #run_action_list,name=single_asc,if=talent.ascendance.enabled
  if Talent(ascendance_talent) ElementalSingleascMainActions()

  unless Talent(ascendance_talent) and ElementalSingleascMainPostConditions()
  {
   #run_action_list,name=single_if,if=talent.icefury.enabled
   if Talent(icefury_talent) ElementalSingleifMainActions()

   unless Talent(icefury_talent) and ElementalSingleifMainPostConditions()
   {
    #run_action_list,name=single_lr,if=talent.lightning_rod.enabled
    if Talent(lightning_rod_talent) ElementalSinglelrMainActions()
   }
  }
 }
}

AddFunction ElementalDefaultMainPostConditions
{
 Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeMainPostConditions() or Talent(ascendance_talent) and ElementalSingleascMainPostConditions() or Talent(icefury_talent) and ElementalSingleifMainPostConditions() or Talent(lightning_rod_talent) and ElementalSinglelrMainPostConditions()
}

AddFunction ElementalDefaultShortCdActions
{
 unless TotemRemaining(totem_mastery) < 2 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Spell(storm_elemental)
 {
  #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
  if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeShortCdActions()

  unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeShortCdPostConditions()
  {
   #run_action_list,name=single_asc,if=talent.ascendance.enabled
   if Talent(ascendance_talent) ElementalSingleascShortCdActions()

   unless Talent(ascendance_talent) and ElementalSingleascShortCdPostConditions()
   {
    #run_action_list,name=single_if,if=talent.icefury.enabled
    if Talent(icefury_talent) ElementalSingleifShortCdActions()

    unless Talent(icefury_talent) and ElementalSingleifShortCdPostConditions()
    {
     #run_action_list,name=single_lr,if=talent.lightning_rod.enabled
     if Talent(lightning_rod_talent) ElementalSinglelrShortCdActions()
    }
   }
  }
 }
}

AddFunction ElementalDefaultShortCdPostConditions
{
 TotemRemaining(totem_mastery) < 2 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Spell(storm_elemental) or Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeShortCdPostConditions() or Talent(ascendance_talent) and ElementalSingleascShortCdPostConditions() or Talent(icefury_talent) and ElementalSingleifShortCdPostConditions() or Talent(lightning_rod_talent) and ElementalSinglelrShortCdPostConditions()
}

AddFunction ElementalDefaultCdActions
{
 #bloodlust,if=target.health.pct<25|time>0.500
 if target.HealthPercent() < 25 or TimeInCombat() > 0 ElementalBloodlust()
 #potion,if=cooldown.fire_elemental.remains>280|target.time_to_die<=60
 if { SpellCooldown(fire_elemental) > 280 or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #wind_shear
 ElementalInterruptActions()

 unless TotemRemaining(totem_mastery) < 2 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery)
 {
  #fire_elemental
  Spell(fire_elemental)

  unless Spell(storm_elemental)
  {
   #elemental_mastery
   Spell(elemental_mastery)
   #use_items
   ElementalUseItemActions()
   #use_item,name=gnawed_thumb_ring,if=equipped.gnawed_thumb_ring&(talent.ascendance.enabled&!buff.ascendance.up|!talent.ascendance.enabled)
   if HasEquippedItem(gnawed_thumb_ring) and { Talent(ascendance_talent) and not BuffPresent(ascendance_elemental_buff) or not Talent(ascendance_talent) } ElementalUseItemActions()
   #blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
   if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) or SpellCooldown(ascendance_elemental) > 50 Spell(blood_fury_apsp)
   #berserking,if=!talent.ascendance.enabled|buff.ascendance.up
   if not Talent(ascendance_talent) or BuffPresent(ascendance_elemental_buff) Spell(berserking)
   #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
   if Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } ElementalAoeCdActions()

   unless Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeCdPostConditions()
   {
    #run_action_list,name=single_asc,if=talent.ascendance.enabled
    if Talent(ascendance_talent) ElementalSingleascCdActions()

    unless Talent(ascendance_talent) and ElementalSingleascCdPostConditions()
    {
     #run_action_list,name=single_if,if=talent.icefury.enabled
     if Talent(icefury_talent) ElementalSingleifCdActions()

     unless Talent(icefury_talent) and ElementalSingleifCdPostConditions()
     {
      #run_action_list,name=single_lr,if=talent.lightning_rod.enabled
      if Talent(lightning_rod_talent) ElementalSinglelrCdActions()
     }
    }
   }
  }
 }
}

AddFunction ElementalDefaultCdPostConditions
{
 TotemRemaining(totem_mastery) < 2 and { not TotemPresent(totem_mastery) or InCombat() } and Speed() == 0 and Spell(totem_mastery) or Spell(storm_elemental) or Enemies() > 2 and { Enemies() > 2 or Enemies() > 2 } and ElementalAoeCdPostConditions() or Talent(ascendance_talent) and ElementalSingleascCdPostConditions() or Talent(icefury_talent) and ElementalSingleifCdPostConditions() or Talent(lightning_rod_talent) and ElementalSinglelrCdPostConditions()
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
# flame_shock
# flame_shock_debuff
# elemental_blast
# earthquake
# echoes_of_the_great_sundering_buff
# earth_shock
# swelling_maelstrom
# stormkeeper
# liquid_magma_totem
# lava_burst
# elemental_focus_buff
# smoldering_heart
# the_deceivers_blood_pact
# aftershock_talent
# totem_mastery
# ascendance_elemental_buff
# ascendance_elemental
# lightning_bolt_elemental
# power_of_the_maelstrom_buff
# lightning_rod_debuff
# chain_lightning
# frost_shock
# icefury_buff
# icefury
# stormkeeper_buff
# lava_beam
# prolonged_power_potion
# lava_surge_buff
# lightning_rod_talent
# fire_elemental
# storm_elemental
# elemental_mastery
# gnawed_thumb_ring
# ascendance_talent
# blood_fury_apsp
# berserking
# icefury_talent
# bloodlust
# heroism
# hex
# war_stomp
# quaking_palm
# lightning_surge_totem
# wind_shear
]]
    OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
end
do
    local name = "sc_shaman_enhancement_t19"
    local desc = "[7.0] Simulationcraft: Shaman_Enhancement_T19"
    local code = [[
# Based on SimulationCraft profile "Shaman_Enhancement_T19P".
#	class=shaman
#	spec=enhancement
#	talents=2002222

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)


AddFunction alphaWolfCheck
{
 pet.BuffRemaining(frost_wolf_alpha_wolf_buff) < 2 and pet.BuffRemaining(fiery_wolf_alpha_wolf_buff) < 2 and pet.BuffRemaining(lightning_wolf_alpha_wolf_buff) < 2 and TotemRemaining(sprit_wolf) > 4
}

AddFunction LightningCrashNotUp
{
 not BuffPresent(lightning_crash_buff) and ArmorSetBonus(T20 2)
}

AddFunction akainuAS
{
 akainuEquipped() and BuffPresent(hot_hand_buff) and not BuffPresent(frostbrand_buff)
}

AddFunction akainuEquipped
{
 HasEquippedItem(137084)
}

AddFunction heartEquipped
{
 HasEquippedItem(151819)
}

AddFunction OCPool60
{
 not Talent(overcharge_talent) or Talent(overcharge_talent) and Maelstrom() > 60
}

AddFunction OCPool70
{
 not Talent(overcharge_talent) or Talent(overcharge_talent) and Maelstrom() > 70
}

AddFunction furyCheck25
{
 not Talent(fury_of_air_talent) or Talent(fury_of_air_talent) and Maelstrom() > 25
}

AddFunction furyCheck45
{
 not Talent(fury_of_air_talent) or Talent(fury_of_air_talent) and Maelstrom() > 45
}

AddFunction furyCheck70
{
 not Talent(fury_of_air_talent) or Talent(fury_of_air_talent) and Maelstrom() > 70
}

AddFunction furyCheck80
{
 not Talent(fury_of_air_talent) or Talent(fury_of_air_talent) and Maelstrom() > 80
}

AddFunction hailstormCheck
{
 Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) or not Talent(hailstorm_talent)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=enhancement)
AddCheckBox(opt_bloodlust SpellName(bloodlust) specialization=enhancement)

AddFunction EnhancementInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(hex) and not target.Classification(worldboss) and target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast) Spell(hex)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if not target.Classification(worldboss) and target.RemainingCastTime() > 2 Spell(lightning_surge_totem)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(sundering)
  if target.InRange(wind_shear) and target.IsInterruptible() Spell(wind_shear)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
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

### actions.filler

AddFunction EnhancementFillerMainActions
{
 #rockbiter,if=maelstrom<120
 if Maelstrom() < 120 Spell(rockbiter)
 #flametongue,if=buff.flametongue.remains<4.8
 if BuffRemaining(flametongue_buff) < 4 Spell(flametongue)
 #crash_lightning,if=(talent.crashing_storm.enabled|active_enemies>=2)&debuff.earthen_spike.up&maelstrom>=40&variable.OCPool60
 if { Talent(crashing_storm_talent) or Enemies() >= 2 } and target.DebuffPresent(earthen_spike_debuff) and Maelstrom() >= 40 and OCPool60() Spell(crash_lightning)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8&maelstrom>40
 if Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4 and Maelstrom() > 40 Spell(frostbrand)
 #frostbrand,if=variable.akainuEquipped&!buff.frostbrand.up&maelstrom>=75
 if akainuEquipped() and not BuffPresent(frostbrand_buff) and Maelstrom() >= 75 Spell(frostbrand)
 #sundering
 Spell(sundering)
 #lava_lash,if=maelstrom>=50&variable.OCPool70&variable.furyCheck80
 if Maelstrom() >= 50 and OCPool70() and furyCheck80() Spell(lava_lash)
 #rockbiter
 Spell(rockbiter)
 #crash_lightning,if=(maelstrom>=65|talent.crashing_storm.enabled|active_enemies>=2)&variable.OCPool60&variable.furyCheck45
 if { Maelstrom() >= 65 or Talent(crashing_storm_talent) or Enemies() >= 2 } and OCPool60() and furyCheck45() Spell(crash_lightning)
 #flametongue
 Spell(flametongue)
}

AddFunction EnhancementFillerMainPostConditions
{
}

AddFunction EnhancementFillerShortCdActions
{
}

AddFunction EnhancementFillerShortCdPostConditions
{
 Maelstrom() < 120 and Spell(rockbiter) or BuffRemaining(flametongue_buff) < 4 and Spell(flametongue) or { Talent(crashing_storm_talent) or Enemies() >= 2 } and target.DebuffPresent(earthen_spike_debuff) and Maelstrom() >= 40 and OCPool60() and Spell(crash_lightning) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4 and Maelstrom() > 40 and Spell(frostbrand) or akainuEquipped() and not BuffPresent(frostbrand_buff) and Maelstrom() >= 75 and Spell(frostbrand) or Spell(sundering) or Maelstrom() >= 50 and OCPool70() and furyCheck80() and Spell(lava_lash) or Spell(rockbiter) or { Maelstrom() >= 65 or Talent(crashing_storm_talent) or Enemies() >= 2 } and OCPool60() and furyCheck45() and Spell(crash_lightning) or Spell(flametongue)
}

AddFunction EnhancementFillerCdActions
{
}

AddFunction EnhancementFillerCdPostConditions
{
 Maelstrom() < 120 and Spell(rockbiter) or BuffRemaining(flametongue_buff) < 4 and Spell(flametongue) or { Talent(crashing_storm_talent) or Enemies() >= 2 } and target.DebuffPresent(earthen_spike_debuff) and Maelstrom() >= 40 and OCPool60() and Spell(crash_lightning) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 4 and Maelstrom() > 40 and Spell(frostbrand) or akainuEquipped() and not BuffPresent(frostbrand_buff) and Maelstrom() >= 75 and Spell(frostbrand) or Spell(sundering) or Maelstrom() >= 50 and OCPool70() and furyCheck80() and Spell(lava_lash) or Spell(rockbiter) or { Maelstrom() >= 65 or Talent(crashing_storm_talent) or Enemies() >= 2 } and OCPool60() and furyCheck45() and Spell(crash_lightning) or Spell(flametongue)
}

### actions.core

AddFunction EnhancementCoreMainActions
{
 #earthen_spike,if=variable.furyCheck25
 if furyCheck25() Spell(earthen_spike)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>=2
 if not BuffPresent(crash_lightning_buff) and Enemies() >= 2 Spell(crash_lightning)
 #crash_lightning,if=active_enemies>=8|(active_enemies>=6&talent.crashing_storm.enabled)
 if Enemies() >= 8 or Enemies() >= 6 and Talent(crashing_storm_talent) Spell(crash_lightning)
 #windstrike
 Spell(windstrike)
 #stormstrike,if=buff.stormbringer.up&variable.furyCheck25
 if BuffPresent(stormbringer_buff) and furyCheck25() Spell(stormstrike)
 #crash_lightning,if=active_enemies>=4|(active_enemies>=2&talent.crashing_storm.enabled)
 if Enemies() >= 4 or Enemies() >= 2 and Talent(crashing_storm_talent) Spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&variable.furyCheck45&maelstrom>=40
 if Talent(overcharge_talent) and furyCheck45() and Maelstrom() >= 40 Spell(lightning_bolt_enhancement)
 #stormstrike,if=(!talent.overcharge.enabled&variable.furyCheck45)|(talent.overcharge.enabled&variable.furyCheck80)
 if not Talent(overcharge_talent) and furyCheck45() or Talent(overcharge_talent) and furyCheck80() Spell(stormstrike)
 #frostbrand,if=variable.akainuAS
 if akainuAS() Spell(frostbrand)
 #lava_lash,if=buff.hot_hand.react&((variable.akainuEquipped&buff.frostbrand.up)|!variable.akainuEquipped)
 if BuffPresent(hot_hand_buff) and { akainuEquipped() and BuffPresent(frostbrand_buff) or not akainuEquipped() } Spell(lava_lash)
 #sundering,if=active_enemies>=3
 if Enemies() >= 3 Spell(sundering)
 #crash_lightning,if=active_enemies>=3|variable.LightningCrashNotUp|variable.alphaWolfCheck
 if Enemies() >= 3 or LightningCrashNotUp() or alphaWolfCheck() Spell(crash_lightning)
}

AddFunction EnhancementCoreMainPostConditions
{
}

AddFunction EnhancementCoreShortCdActions
{
 unless furyCheck25() and Spell(earthen_spike) or not BuffPresent(crash_lightning_buff) and Enemies() >= 2 and Spell(crash_lightning)
 {
  #windsong
  Spell(windsong)
 }
}

AddFunction EnhancementCoreShortCdPostConditions
{
 furyCheck25() and Spell(earthen_spike) or not BuffPresent(crash_lightning_buff) and Enemies() >= 2 and Spell(crash_lightning) or { Enemies() >= 8 or Enemies() >= 6 and Talent(crashing_storm_talent) } and Spell(crash_lightning) or Spell(windstrike) or BuffPresent(stormbringer_buff) and furyCheck25() and Spell(stormstrike) or { Enemies() >= 4 or Enemies() >= 2 and Talent(crashing_storm_talent) } and Spell(crash_lightning) or Talent(overcharge_talent) and furyCheck45() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or { not Talent(overcharge_talent) and furyCheck45() or Talent(overcharge_talent) and furyCheck80() } and Spell(stormstrike) or akainuAS() and Spell(frostbrand) or BuffPresent(hot_hand_buff) and { akainuEquipped() and BuffPresent(frostbrand_buff) or not akainuEquipped() } and Spell(lava_lash) or Enemies() >= 3 and Spell(sundering) or { Enemies() >= 3 or LightningCrashNotUp() or alphaWolfCheck() } and Spell(crash_lightning)
}

AddFunction EnhancementCoreCdActions
{
}

AddFunction EnhancementCoreCdPostConditions
{
 furyCheck25() and Spell(earthen_spike) or not BuffPresent(crash_lightning_buff) and Enemies() >= 2 and Spell(crash_lightning) or Spell(windsong) or { Enemies() >= 8 or Enemies() >= 6 and Talent(crashing_storm_talent) } and Spell(crash_lightning) or Spell(windstrike) or BuffPresent(stormbringer_buff) and furyCheck25() and Spell(stormstrike) or { Enemies() >= 4 or Enemies() >= 2 and Talent(crashing_storm_talent) } and Spell(crash_lightning) or Talent(overcharge_talent) and furyCheck45() and Maelstrom() >= 40 and Spell(lightning_bolt_enhancement) or { not Talent(overcharge_talent) and furyCheck45() or Talent(overcharge_talent) and furyCheck80() } and Spell(stormstrike) or akainuAS() and Spell(frostbrand) or BuffPresent(hot_hand_buff) and { akainuEquipped() and BuffPresent(frostbrand_buff) or not akainuEquipped() } and Spell(lava_lash) or Enemies() >= 3 and Spell(sundering) or { Enemies() >= 3 or LightningCrashNotUp() or alphaWolfCheck() } and Spell(crash_lightning)
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
 #doom_winds,if=cooldown.ascendance.remains>6|talent.boulderfist.enabled|debuff.earthen_spike.up
 if SpellCooldown(ascendance_enhancement) > 6 or Talent(boulderfist_talent) or target.DebuffPresent(earthen_spike_debuff) Spell(doom_winds)
}

AddFunction EnhancementCdsShortCdPostConditions
{
}

AddFunction EnhancementCdsCdActions
{
 #bloodlust,if=target.health.pct<25|time>0.500
 if target.HealthPercent() < 25 or TimeInCombat() > 0 EnhancementBloodlust()
 #berserking,if=buff.ascendance.up|(feral_spirit.remains>5)|level<100
 if BuffPresent(ascendance_enhancement_buff) or TotemRemaining(sprit_wolf) > 5 or Level() < 100 Spell(berserking)
 #blood_fury,if=buff.ascendance.up|(feral_spirit.remains>5)|level<100
 if BuffPresent(ascendance_enhancement_buff) or TotemRemaining(sprit_wolf) > 5 or Level() < 100 Spell(blood_fury_apsp)
 #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
 if { BuffPresent(ascendance_enhancement_buff) or not Talent(ascendance_talent) and TotemRemaining(sprit_wolf) > 5 or target.TimeToDie() <= 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #feral_spirit
 Spell(feral_spirit)

 unless { SpellCooldown(ascendance_enhancement) > 6 or Talent(boulderfist_talent) or target.DebuffPresent(earthen_spike_debuff) } and Spell(doom_winds)
 {
  #ascendance,if=(cooldown.strike.remains>0)&buff.ascendance.down
  if SpellCooldown(stormstrike) > 0 and BuffExpires(ascendance_enhancement_buff) and BuffExpires(ascendance_enhancement_buff) Spell(ascendance_enhancement)
 }
}

AddFunction EnhancementCdsCdPostConditions
{
 { SpellCooldown(ascendance_enhancement) > 6 or Talent(boulderfist_talent) or target.DebuffPresent(earthen_spike_debuff) } and Spell(doom_winds)
}

### actions.buffs

AddFunction EnhancementBuffsMainActions
{
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up
 if Talent(landslide_talent) and not BuffPresent(landslide_buff) Spell(rockbiter)
 #fury_of_air,if=!ticking&maelstrom>22
 if not target.DebuffPresent(fury_of_air_debuff) and Maelstrom() > 22 Spell(fury_of_air)
 #crash_lightning,if=artifact.alpha_wolf.rank&prev_gcd.1.feral_spirit
 if ArtifactTraitRank(alpha_wolf) and PreviousGCDSpell(feral_spirit) Spell(crash_lightning)
 #flametongue,if=!buff.flametongue.up
 if not BuffPresent(flametongue_buff) Spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck45
 if Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck45() Spell(frostbrand)
 #flametongue,if=buff.flametongue.remains<6+gcd&cooldown.doom_winds.remains<gcd*2
 if BuffRemaining(flametongue_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 Spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<6+gcd&cooldown.doom_winds.remains<gcd*2
 if Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 Spell(frostbrand)
}

AddFunction EnhancementBuffsMainPostConditions
{
}

AddFunction EnhancementBuffsShortCdActions
{
}

AddFunction EnhancementBuffsShortCdPostConditions
{
 Talent(landslide_talent) and not BuffPresent(landslide_buff) and Spell(rockbiter) or not target.DebuffPresent(fury_of_air_debuff) and Maelstrom() > 22 and Spell(fury_of_air) or ArtifactTraitRank(alpha_wolf) and PreviousGCDSpell(feral_spirit) and Spell(crash_lightning) or not BuffPresent(flametongue_buff) and Spell(flametongue) or Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck45() and Spell(frostbrand) or BuffRemaining(flametongue_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 and Spell(flametongue) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 and Spell(frostbrand)
}

AddFunction EnhancementBuffsCdActions
{
}

AddFunction EnhancementBuffsCdPostConditions
{
 Talent(landslide_talent) and not BuffPresent(landslide_buff) and Spell(rockbiter) or not target.DebuffPresent(fury_of_air_debuff) and Maelstrom() > 22 and Spell(fury_of_air) or ArtifactTraitRank(alpha_wolf) and PreviousGCDSpell(feral_spirit) and Spell(crash_lightning) or not BuffPresent(flametongue_buff) and Spell(flametongue) or Talent(hailstorm_talent) and not BuffPresent(frostbrand_buff) and furyCheck45() and Spell(frostbrand) or BuffRemaining(flametongue_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 and Spell(flametongue) or Talent(hailstorm_talent) and BuffRemaining(frostbrand_buff) < 6 + GCD() and SpellCooldown(doom_winds) < GCD() * 2 and Spell(frostbrand)
}

### actions.asc

AddFunction EnhancementAscMainActions
{
 #earthen_spike
 Spell(earthen_spike)
 #windstrike
 Spell(windstrike)
}

AddFunction EnhancementAscMainPostConditions
{
}

AddFunction EnhancementAscShortCdActions
{
 unless Spell(earthen_spike)
 {
  #doom_winds,if=cooldown.strike.up
  if not SpellCooldown(stormstrike) > 0 Spell(doom_winds)
 }
}

AddFunction EnhancementAscShortCdPostConditions
{
 Spell(earthen_spike) or Spell(windstrike)
}

AddFunction EnhancementAscCdActions
{
}

AddFunction EnhancementAscCdPostConditions
{
 Spell(earthen_spike) or not SpellCooldown(stormstrike) > 0 and Spell(doom_winds) or Spell(windstrike)
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
   #call_action_list,name=buffs
   EnhancementBuffsMainActions()

   unless EnhancementBuffsMainPostConditions()
   {
    #call_action_list,name=cds
    EnhancementCdsMainActions()

    unless EnhancementCdsMainPostConditions()
    {
     #call_action_list,name=core
     EnhancementCoreMainActions()

     unless EnhancementCoreMainPostConditions()
     {
      #call_action_list,name=filler
      EnhancementFillerMainActions()
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultMainPostConditions
{
 EnhancementOpenerMainPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscMainPostConditions() or EnhancementBuffsMainPostConditions() or EnhancementCdsMainPostConditions() or EnhancementCoreMainPostConditions() or EnhancementFillerMainPostConditions()
}

AddFunction EnhancementDefaultShortCdActions
{
 #variable,name=hailstormCheck,value=((talent.hailstorm.enabled&!buff.frostbrand.up)|!talent.hailstorm.enabled)
 #variable,name=furyCheck80,value=(!talent.fury_of_air.enabled|(talent.fury_of_air.enabled&maelstrom>80))
 #variable,name=furyCheck70,value=(!talent.fury_of_air.enabled|(talent.fury_of_air.enabled&maelstrom>70))
 #variable,name=furyCheck45,value=(!talent.fury_of_air.enabled|(talent.fury_of_air.enabled&maelstrom>45))
 #variable,name=furyCheck25,value=(!talent.fury_of_air.enabled|(talent.fury_of_air.enabled&maelstrom>25))
 #variable,name=OCPool70,value=(!talent.overcharge.enabled|(talent.overcharge.enabled&maelstrom>70))
 #variable,name=OCPool60,value=(!talent.overcharge.enabled|(talent.overcharge.enabled&maelstrom>60))
 #variable,name=heartEquipped,value=(equipped.151819)
 #variable,name=akainuEquipped,value=(equipped.137084)
 #variable,name=akainuAS,value=(variable.akainuEquipped&buff.hot_hand.react&!buff.frostbrand.up)
 #variable,name=LightningCrashNotUp,value=(!buff.lightning_crash.up&set_bonus.tier20_2pc)
 #variable,name=alphaWolfCheck,value=((pet.frost_wolf.buff.alpha_wolf.remains<2&pet.fiery_wolf.buff.alpha_wolf.remains<2&pet.lightning_wolf.buff.alpha_wolf.remains<2)&feral_spirit.remains>4)
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
   #call_action_list,name=buffs
   EnhancementBuffsShortCdActions()

   unless EnhancementBuffsShortCdPostConditions()
   {
    #call_action_list,name=cds
    EnhancementCdsShortCdActions()

    unless EnhancementCdsShortCdPostConditions()
    {
     #call_action_list,name=core
     EnhancementCoreShortCdActions()

     unless EnhancementCoreShortCdPostConditions()
     {
      #call_action_list,name=filler
      EnhancementFillerShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultShortCdPostConditions
{
 EnhancementOpenerShortCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscShortCdPostConditions() or EnhancementBuffsShortCdPostConditions() or EnhancementCdsShortCdPostConditions() or EnhancementCoreShortCdPostConditions() or EnhancementFillerShortCdPostConditions()
}

AddFunction EnhancementDefaultCdActions
{
 #wind_shear
 EnhancementInterruptActions()
 #use_items
 EnhancementUseItemActions()
 #call_action_list,name=opener
 EnhancementOpenerCdActions()

 unless EnhancementOpenerCdPostConditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if BuffPresent(ascendance_enhancement_buff) EnhancementAscCdActions()

  unless BuffPresent(ascendance_enhancement_buff) and EnhancementAscCdPostConditions()
  {
   #call_action_list,name=buffs
   EnhancementBuffsCdActions()

   unless EnhancementBuffsCdPostConditions()
   {
    #call_action_list,name=cds
    EnhancementCdsCdActions()

    unless EnhancementCdsCdPostConditions()
    {
     #call_action_list,name=core
     EnhancementCoreCdActions()

     unless EnhancementCoreCdPostConditions()
     {
      #call_action_list,name=filler
      EnhancementFillerCdActions()
     }
    }
   }
  }
 }
}

AddFunction EnhancementDefaultCdPostConditions
{
 EnhancementOpenerCdPostConditions() or BuffPresent(ascendance_enhancement_buff) and EnhancementAscCdPostConditions() or EnhancementBuffsCdPostConditions() or EnhancementCdsCdPostConditions() or EnhancementCoreCdPostConditions() or EnhancementFillerCdPostConditions()
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
# prolonged_power_potion
# lightning_shield
# rockbiter
# flametongue
# flametongue_buff
# crash_lightning
# crashing_storm_talent
# earthen_spike_debuff
# frostbrand
# hailstorm_talent
# frostbrand_buff
# sundering
# lava_lash
# earthen_spike
# crash_lightning_buff
# windsong
# windstrike
# stormstrike
# stormbringer_buff
# lightning_bolt_enhancement
# overcharge_talent
# hot_hand_buff
# berserking
# ascendance_enhancement_buff
# blood_fury_apsp
# ascendance_talent
# feral_spirit
# doom_winds
# ascendance_enhancement
# boulderfist_talent
# landslide_talent
# landslide_buff
# fury_of_air
# fury_of_air_debuff
# alpha_wolf
# fury_of_air_talent
# 151819
# 137084
# lightning_crash_buff
# frost_wolf_alpha_wolf_buff
# fiery_wolf_alpha_wolf_buff
# lightning_wolf_alpha_wolf_buff
# feral_lunge
# bloodlust
# heroism
# hex
# war_stomp
# quaking_palm
# lightning_surge_totem
# wind_shear
]]
    OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
end
