local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_t23_demon_hunter_havoc"
    local desc = "[8.2] Simulationcraft: T23_Demon_Hunter_Havoc"
    local code = [[
# Based on SimulationCraft profile "T23_Demon_Hunter_Havoc".
#	class=demonhunter
#	spec=havoc
#	talents=1310221

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)


AddFunction waiting_for_momentum
{
 Talent(momentum_talent) and not BuffPresent(momentum_buff)
}

AddFunction waiting_for_dark_slash
{
 Talent(dark_slash_talent) and not pooling_for_blade_dance() and not pooling_for_meta() and not SpellCooldown(dark_slash) > 0
}

AddFunction pooling_for_eye_beam
{
 Talent(demonic_talent) and not Talent(blind_fury_talent) and SpellCooldown(eye_beam) < GCD() * 2 and FuryDeficit() > 20
}

AddFunction pooling_for_blade_dance
{
 blade_dance() and Fury() < 75 - TalentPoints(first_blood_talent) * 20
}

AddFunction pooling_for_meta
{
 not Talent(demonic_talent) and SpellCooldown(metamorphosis_havoc) < 6 and FuryDeficit() > 30 and { not waiting_for_nemesis() or SpellCooldown(nemesis) < 10 }
}

AddFunction waiting_for_nemesis
{
 not { not Talent(nemesis_talent) or Talent(nemesis_talent) and SpellCooldown(nemesis) == 0 or SpellCooldown(nemesis) > target.TimeToDie() or SpellCooldown(nemesis) > 60 }
}

AddFunction blade_dance
{
 Talent(first_blood_talent) or Enemies() >= 3 - TalentPoints(trail_of_ruin_talent)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=havoc)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=havoc)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=havoc)
AddCheckBox(opt_meta_only_during_boss L(meta_only_during_boss) default specialization=havoc)
AddCheckBox(opt_vengeful_retreat SpellName(vengeful_retreat) default specialization=havoc)
AddCheckBox(opt_fel_rush SpellName(fel_rush) default specialization=havoc)

AddFunction HavocInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(disrupt) and target.IsInterruptible() Spell(disrupt)
  if target.InRange(fel_eruption) and not target.Classification(worldboss) Spell(fel_eruption)
  if target.Distance(less 8) and not target.Classification(worldboss) Spell(chaos_nova)
  if target.InRange(imprison) and not target.Classification(worldboss) and target.CreatureType(Demon Humanoid Beast) Spell(imprison)
 }
}

AddFunction HavocUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction HavocGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike)
 {
  if target.InRange(felblade) Spell(felblade)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.precombat

AddFunction HavocPrecombatMainActions
{
}

AddFunction HavocPrecombatMainPostConditions
{
}

AddFunction HavocPrecombatShortCdActions
{
}

AddFunction HavocPrecombatShortCdPostConditions
{
}

AddFunction HavocPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
 #metamorphosis,if=!azerite.chaotic_transformation.enabled
 if not HasAzeriteTrait(chaotic_transformation_trait) and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
}

AddFunction HavocPrecombatCdPostConditions
{
}

### actions.normal

AddFunction HavocNormalMainActions
{
 #vengeful_retreat,if=talent.momentum.enabled&buff.prepared.down&time>1
 if Talent(momentum_talent) and BuffExpires(prepared_buff) and TimeInCombat() > 1 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #fel_rush,if=(variable.waiting_for_momentum|talent.fel_mastery.enabled)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #death_sweep,if=variable.blade_dance
 if blade_dance() Spell(death_sweep)
 #immolation_aura
 Spell(immolation_aura_havoc)
 #blade_dance,if=variable.blade_dance
 if blade_dance() Spell(blade_dance)
 #felblade,if=fury.deficit>=40
 if FuryDeficit() >= 40 Spell(felblade)
 #annihilation,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() Spell(annihilation)
 #chaos_strike,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() Spell(chaos_strike)
 #demons_bite
 Spell(demons_bite)
 #fel_rush,if=!talent.momentum.enabled&raid_event.movement.in>charges*10&talent.demon_blades.enabled
 if not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #felblade,if=movement.distance>15|buff.out_of_range.up
 if target.Distance() > 15 or not target.InRange() Spell(felblade)
 #fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
 if { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if Talent(demon_blades_talent) Spell(throw_glaive_havoc)
}

AddFunction HavocNormalMainPostConditions
{
}

AddFunction HavocNormalShortCdActions
{
 unless Talent(momentum_talent) and BuffExpires(prepared_buff) and TimeInCombat() > 1 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush)
 {
  #fel_barrage,if=!variable.waiting_for_momentum&(active_enemies>desired_targets|raid_event.adds.in>30)
  if not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } Spell(fel_barrage)

  unless blade_dance() and Spell(death_sweep) or Spell(immolation_aura_havoc)
  {
   #eye_beam,if=active_enemies>1&(!raid_event.adds.exists|raid_event.adds.up)&!variable.waiting_for_momentum
   if Enemies() > 1 and { not False(raid_event_adds_exists) or False(raid_event_adds_exists) } and not waiting_for_momentum() Spell(eye_beam)

   unless blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade)
   {
    #eye_beam,if=!talent.blind_fury.enabled&!variable.waiting_for_dark_slash&raid_event.adds.in>cooldown
    if not Talent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > SpellCooldown(eye_beam) Spell(eye_beam)

    unless { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike)
    {
     #eye_beam,if=talent.blind_fury.enabled&raid_event.adds.in>cooldown
     if Talent(blind_fury_talent) and 600 > SpellCooldown(eye_beam) Spell(eye_beam)
    }
   }
  }
 }
}

AddFunction HavocNormalShortCdPostConditions
{
 Talent(momentum_talent) and BuffExpires(prepared_buff) and TimeInCombat() > 1 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or blade_dance() and Spell(death_sweep) or Spell(immolation_aura_havoc) or blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike) or Spell(demons_bite) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or { target.Distance() > 15 or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

AddFunction HavocNormalCdActions
{
}

AddFunction HavocNormalCdPostConditions
{
 Talent(momentum_talent) and BuffExpires(prepared_buff) and TimeInCombat() > 1 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or { waiting_for_momentum() or Talent(fel_mastery_talent) } and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or not waiting_for_momentum() and { Enemies() > Enemies(tagged=1) or 600 > 30 } and Spell(fel_barrage) or blade_dance() and Spell(death_sweep) or Spell(immolation_aura_havoc) or Enemies() > 1 and { not False(raid_event_adds_exists) or False(raid_event_adds_exists) } and not waiting_for_momentum() and Spell(eye_beam) or blade_dance() and Spell(blade_dance) or FuryDeficit() >= 40 and Spell(felblade) or not Talent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > SpellCooldown(eye_beam) and Spell(eye_beam) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 or BuffRemaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(annihilation) or { Talent(demon_blades_talent) or not waiting_for_momentum() or FuryDeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and Spell(chaos_strike) or Talent(blind_fury_talent) and 600 > SpellCooldown(eye_beam) and Spell(eye_beam) or Spell(demons_bite) or not Talent(momentum_talent) and 600 > Charges(fel_rush) * 10 and Talent(demon_blades_talent) and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or { target.Distance() > 15 or not target.InRange() } and Spell(felblade) or { target.Distance() > 15 or not target.InRange() and not Talent(momentum_talent) } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

### actions.demonic

AddFunction HavocDemonicMainActions
{
 #death_sweep,if=variable.blade_dance
 if blade_dance() Spell(death_sweep)
 #blade_dance,if=variable.blade_dance&!cooldown.metamorphosis.ready&(cooldown.eye_beam.remains>(5-azerite.revolving_blades.rank*3)|(raid_event.adds.in>cooldown&raid_event.adds.in<25))
 if blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and { SpellCooldown(eye_beam) > 5 - AzeriteTraitRank(revolving_blades_trait) * 3 or 600 > SpellCooldown(blade_dance) and 600 < 25 } Spell(blade_dance)
 #immolation_aura
 Spell(immolation_aura_havoc)
 #annihilation,if=!variable.pooling_for_blade_dance
 if not pooling_for_blade_dance() Spell(annihilation)
 #felblade,if=fury.deficit>=40
 if FuryDeficit() >= 40 Spell(felblade)
 #chaos_strike,if=!variable.pooling_for_blade_dance&!variable.pooling_for_eye_beam
 if not pooling_for_blade_dance() and not pooling_for_eye_beam() Spell(chaos_strike)
 #fel_rush,if=talent.demon_blades.enabled&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #demons_bite
 Spell(demons_bite)
 #throw_glaive,if=buff.out_of_range.up
 if not target.InRange() Spell(throw_glaive_havoc)
 #fel_rush,if=movement.distance>15|buff.out_of_range.up
 if { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) Spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) Spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if Talent(demon_blades_talent) Spell(throw_glaive_havoc)
}

AddFunction HavocDemonicMainPostConditions
{
}

AddFunction HavocDemonicShortCdActions
{
 unless blade_dance() and Spell(death_sweep)
 {
  #eye_beam,if=raid_event.adds.up|raid_event.adds.in>25
  if False(raid_event_adds_exists) or 600 > 25 Spell(eye_beam)
  #fel_barrage,if=((!cooldown.eye_beam.up|buff.metamorphosis.up)&raid_event.adds.in>30)|active_enemies>desired_targets
  if { not { not SpellCooldown(eye_beam) > 0 } or BuffPresent(metamorphosis_havoc_buff) } and 600 > 30 or Enemies() > Enemies(tagged=1) Spell(fel_barrage)
 }
}

AddFunction HavocDemonicShortCdPostConditions
{
 blade_dance() and Spell(death_sweep) or blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and { SpellCooldown(eye_beam) > 5 - AzeriteTraitRank(revolving_blades_trait) * 3 or 600 > SpellCooldown(blade_dance) and 600 < 25 } and Spell(blade_dance) or Spell(immolation_aura_havoc) or not pooling_for_blade_dance() and Spell(annihilation) or FuryDeficit() >= 40 and Spell(felblade) or not pooling_for_blade_dance() and not pooling_for_eye_beam() and Spell(chaos_strike) or Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

AddFunction HavocDemonicCdActions
{
}

AddFunction HavocDemonicCdPostConditions
{
 blade_dance() and Spell(death_sweep) or { False(raid_event_adds_exists) or 600 > 25 } and Spell(eye_beam) or { { not { not SpellCooldown(eye_beam) > 0 } or BuffPresent(metamorphosis_havoc_buff) } and 600 > 30 or Enemies() > Enemies(tagged=1) } and Spell(fel_barrage) or blade_dance() and not { { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } and SpellCooldown(metamorphosis_havoc) == 0 } and { SpellCooldown(eye_beam) > 5 - AzeriteTraitRank(revolving_blades_trait) * 3 or 600 > SpellCooldown(blade_dance) and 600 < 25 } and Spell(blade_dance) or Spell(immolation_aura_havoc) or not pooling_for_blade_dance() and Spell(annihilation) or FuryDeficit() >= 40 and Spell(felblade) or not pooling_for_blade_dance() and not pooling_for_eye_beam() and Spell(chaos_strike) or Talent(demon_blades_talent) and not SpellCooldown(eye_beam) == 0 and { Charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or Spell(demons_bite) or not target.InRange() and Spell(throw_glaive_havoc) or { target.Distance() > 15 or not target.InRange() } and CheckBoxOn(opt_fel_rush) and Spell(fel_rush) or target.Distance() > 15 and CheckBoxOn(opt_vengeful_retreat) and Spell(vengeful_retreat) or Talent(demon_blades_talent) and Spell(throw_glaive_havoc)
}

### actions.dark_slash

AddFunction HavocDarkslashMainActions
{
 #dark_slash,if=fury>=80&(!variable.blade_dance|!cooldown.blade_dance.ready)
 if Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } Spell(dark_slash)
 #annihilation,if=debuff.dark_slash.up
 if target.DebuffPresent(dark_slash_debuff) Spell(annihilation)
 #chaos_strike,if=debuff.dark_slash.up
 if target.DebuffPresent(dark_slash_debuff) Spell(chaos_strike)
}

AddFunction HavocDarkslashMainPostConditions
{
}

AddFunction HavocDarkslashShortCdActions
{
}

AddFunction HavocDarkslashShortCdPostConditions
{
 Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } and Spell(dark_slash) or target.DebuffPresent(dark_slash_debuff) and Spell(annihilation) or target.DebuffPresent(dark_slash_debuff) and Spell(chaos_strike)
}

AddFunction HavocDarkslashCdActions
{
}

AddFunction HavocDarkslashCdPostConditions
{
 Fury() >= 80 and { not blade_dance() or not SpellCooldown(blade_dance) == 0 } and Spell(dark_slash) or target.DebuffPresent(dark_slash_debuff) and Spell(annihilation) or target.DebuffPresent(dark_slash_debuff) and Spell(chaos_strike)
}

### actions.cooldown

AddFunction HavocCooldownMainActions
{
}

AddFunction HavocCooldownMainPostConditions
{
}

AddFunction HavocCooldownShortCdActions
{
}

AddFunction HavocCooldownShortCdPostConditions
{
}

AddFunction HavocCooldownCdActions
{
 #metamorphosis,if=!(talent.demonic.enabled|variable.pooling_for_meta|variable.waiting_for_nemesis)|target.time_to_die<25
 if { not { Talent(demonic_talent) or pooling_for_meta() or waiting_for_nemesis() } or target.TimeToDie() < 25 } and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
 #metamorphosis,if=talent.demonic.enabled&(!azerite.chaotic_transformation.enabled|(cooldown.eye_beam.remains>20&cooldown.blade_dance.remains>gcd.max))
 if Talent(demonic_talent) and { not HasAzeriteTrait(chaotic_transformation_trait) or SpellCooldown(eye_beam) > 20 and SpellCooldown(blade_dance) > GCD() } and { not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight() } Spell(metamorphosis_havoc)
 #nemesis,target_if=min:target.time_to_die,if=raid_event.adds.exists&debuff.nemesis.down&(active_enemies>desired_targets|raid_event.adds.in>60)
 if False(raid_event_adds_exists) and target.DebuffExpires(nemesis_debuff) and { Enemies() > Enemies(tagged=1) or 600 > 60 } Spell(nemesis)
 #nemesis,if=!raid_event.adds.exists
 if not False(raid_event_adds_exists) Spell(nemesis)
 #potion,if=buff.metamorphosis.remains>25|target.time_to_die<60
 if { BuffRemaining(metamorphosis_havoc_buff) > 25 or target.TimeToDie() < 60 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)
 #use_item,name=variable_intensity_gigavolt_oscillating_reactor
 HavocUseItemActions()
}

AddFunction HavocCooldownCdPostConditions
{
}

### actions.default

AddFunction HavocDefaultMainActions
{
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not GCDRemaining() > 0 HavocCooldownMainActions()

 unless not GCDRemaining() > 0 and HavocCooldownMainPostConditions()
 {
  #pick_up_fragment,if=fury.deficit>=35
  if FuryDeficit() >= 35 Spell(pick_up_fragment)
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkslashMainActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashMainPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicMainActions()

   unless Talent(demonic_talent) and HavocDemonicMainPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalMainActions()
   }
  }
 }
}

AddFunction HavocDefaultMainPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownMainPostConditions() or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashMainPostConditions() or Talent(demonic_talent) and HavocDemonicMainPostConditions() or HavocNormalMainPostConditions()
}

AddFunction HavocDefaultShortCdActions
{
 #auto_attack
 HavocGetInMeleeRange()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not GCDRemaining() > 0 HavocCooldownShortCdActions()

 unless not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkslashShortCdActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashShortCdPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicShortCdActions()

   unless Talent(demonic_talent) and HavocDemonicShortCdPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalShortCdActions()
   }
  }
 }
}

AddFunction HavocDefaultShortCdPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownShortCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment) or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashShortCdPostConditions() or Talent(demonic_talent) and HavocDemonicShortCdPostConditions() or HavocNormalShortCdPostConditions()
}

AddFunction HavocDefaultCdActions
{
 #variable,name=blade_dance,value=talent.first_blood.enabled|spell_targets.blade_dance1>=(3-talent.trail_of_ruin.enabled)
 #variable,name=waiting_for_nemesis,value=!(!talent.nemesis.enabled|cooldown.nemesis.ready|cooldown.nemesis.remains>target.time_to_die|cooldown.nemesis.remains>60)
 #variable,name=pooling_for_meta,value=!talent.demonic.enabled&cooldown.metamorphosis.remains<6&fury.deficit>30&(!variable.waiting_for_nemesis|cooldown.nemesis.remains<10)
 #variable,name=pooling_for_blade_dance,value=variable.blade_dance&(fury<75-talent.first_blood.enabled*20)
 #variable,name=pooling_for_eye_beam,value=talent.demonic.enabled&!talent.blind_fury.enabled&cooldown.eye_beam.remains<(gcd.max*2)&fury.deficit>20
 #variable,name=waiting_for_dark_slash,value=talent.dark_slash.enabled&!variable.pooling_for_blade_dance&!variable.pooling_for_meta&cooldown.dark_slash.up
 #variable,name=waiting_for_momentum,value=talent.momentum.enabled&!buff.momentum.up
 #disrupt
 HavocInterruptActions()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not GCDRemaining() > 0 HavocCooldownCdActions()

 unless not GCDRemaining() > 0 and HavocCooldownCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } HavocDarkslashCdActions()

  unless Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashCdPostConditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if Talent(demonic_talent) HavocDemonicCdActions()

   unless Talent(demonic_talent) and HavocDemonicCdPostConditions()
   {
    #run_action_list,name=normal
    HavocNormalCdActions()
   }
  }
 }
}

AddFunction HavocDefaultCdPostConditions
{
 not GCDRemaining() > 0 and HavocCooldownCdPostConditions() or FuryDeficit() >= 35 and Spell(pick_up_fragment) or Talent(dark_slash_talent) and { waiting_for_dark_slash() or target.DebuffPresent(dark_slash_debuff) } and HavocDarkslashCdPostConditions() or Talent(demonic_talent) and HavocDemonicCdPostConditions() or HavocNormalCdPostConditions()
}

### Havoc icons.

AddCheckBox(opt_demonhunter_havoc_aoe L(AOE) default specialization=havoc)

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=shortcd specialization=havoc
{
 if not InCombat() HavocPrecombatShortCdActions()
 unless not InCombat() and HavocPrecombatShortCdPostConditions()
 {
  HavocDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=shortcd specialization=havoc
{
 if not InCombat() HavocPrecombatShortCdActions()
 unless not InCombat() and HavocPrecombatShortCdPostConditions()
 {
  HavocDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=havoc
{
 if not InCombat() HavocPrecombatMainActions()
 unless not InCombat() and HavocPrecombatMainPostConditions()
 {
  HavocDefaultMainActions()
 }
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=aoe specialization=havoc
{
 if not InCombat() HavocPrecombatMainActions()
 unless not InCombat() and HavocPrecombatMainPostConditions()
 {
  HavocDefaultMainActions()
 }
}

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=cd specialization=havoc
{
 if not InCombat() HavocPrecombatCdActions()
 unless not InCombat() and HavocPrecombatCdPostConditions()
 {
  HavocDefaultCdActions()
 }
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=cd specialization=havoc
{
 if not InCombat() HavocPrecombatCdActions()
 unless not InCombat() and HavocPrecombatCdPostConditions()
 {
  HavocDefaultCdActions()
 }
}

### Required symbols
# annihilation
# blade_dance
# blind_fury_talent
# chaos_nova
# chaos_strike
# chaotic_transformation_trait
# dark_slash
# dark_slash_debuff
# dark_slash_talent
# death_sweep
# demon_blades_talent
# demonic_talent
# demons_bite
# disrupt
# eye_beam
# fel_barrage
# fel_eruption
# fel_mastery_talent
# fel_rush
# felblade
# first_blood_talent
# immolation_aura_havoc
# imprison
# item_battle_potion_of_agility
# metamorphosis_havoc
# metamorphosis_havoc_buff
# momentum_buff
# momentum_talent
# nemesis
# nemesis_debuff
# nemesis_talent
# pick_up_fragment
# prepared_buff
# revolving_blades_trait
# throw_glaive_havoc
# trail_of_ruin_talent
# vengeful_retreat
]]
    OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
end
do
    local name = "sc_t23_demon_hunter_vengeance"
    local desc = "[8.2] Simulationcraft: T23_Demon_Hunter_Vengeance"
    local code = [[
# Based on SimulationCraft profile "T23_Demon_Hunter_Vengeance".
#	class=demonhunter
#	spec=vengeance
#	talents=1213121

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=vengeance)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=vengeance)

AddFunction VengeanceInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(disrupt) and target.IsInterruptible() Spell(disrupt)
  if target.IsInterruptible() and not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_silence)
  if not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_misery)
  if not target.Classification(worldboss) and not SigilCharging(silence misery chains) and target.RemainingCastTime() >= 2 - Talent(quickened_sigils_talent) + GCDRemaining() Spell(sigil_of_chains)
  if target.InRange(imprison) and not target.Classification(worldboss) and target.CreatureType(Demon Humanoid Beast) Spell(imprison)
 }
}

AddFunction VengeanceGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
}

### actions.precombat

AddFunction VengeancePrecombatMainActions
{
}

AddFunction VengeancePrecombatMainPostConditions
{
}

AddFunction VengeancePrecombatShortCdActions
{
}

AddFunction VengeancePrecombatShortCdPostConditions
{
}

AddFunction VengeancePrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_steelskin_potion usable=1)
}

AddFunction VengeancePrecombatCdPostConditions
{
}

### actions.normal

AddFunction VengeanceNormalMainActions
{
 #infernal_strike
 Spell(infernal_strike)
 #spirit_bomb,if=soul_fragments>=4
 if SoulFragments() >= 4 Spell(spirit_bomb)
 #soul_cleave,if=!talent.spirit_bomb.enabled
 if not Talent(spirit_bomb_talent) Spell(soul_cleave)
 #soul_cleave,if=talent.spirit_bomb.enabled&soul_fragments=0
 if Talent(spirit_bomb_talent) and SoulFragments() == 0 Spell(soul_cleave)
 #immolation_aura,if=pain<=90
 if Pain() <= 90 Spell(immolation_aura)
 #felblade,if=pain<=70
 if Pain() <= 70 Spell(felblade)
 #fracture,if=soul_fragments<=3
 if SoulFragments() <= 3 Spell(fracture)
 #sigil_of_flame
 Spell(sigil_of_flame)
 #shear
 Spell(shear)
 #throw_glaive
 Spell(throw_glaive_veng)
}

AddFunction VengeanceNormalMainPostConditions
{
}

AddFunction VengeanceNormalShortCdActions
{
 unless Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture)
 {
  #fel_devastation
  Spell(fel_devastation)
 }
}

AddFunction VengeanceNormalShortCdPostConditions
{
 Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
}

AddFunction VengeanceNormalCdActions
{
}

AddFunction VengeanceNormalCdPostConditions
{
 Spell(infernal_strike) or SoulFragments() >= 4 and Spell(spirit_bomb) or not Talent(spirit_bomb_talent) and Spell(soul_cleave) or Talent(spirit_bomb_talent) and SoulFragments() == 0 and Spell(soul_cleave) or Pain() <= 90 and Spell(immolation_aura) or Pain() <= 70 and Spell(felblade) or SoulFragments() <= 3 and Spell(fracture) or Spell(fel_devastation) or Spell(sigil_of_flame) or Spell(shear) or Spell(throw_glaive_veng)
}

### actions.defensives

AddFunction VengeanceDefensivesMainActions
{
}

AddFunction VengeanceDefensivesMainPostConditions
{
}

AddFunction VengeanceDefensivesShortCdActions
{
 #demon_spikes
 Spell(demon_spikes)
 #fiery_brand
 Spell(fiery_brand)
}

AddFunction VengeanceDefensivesShortCdPostConditions
{
}

AddFunction VengeanceDefensivesCdActions
{
 unless Spell(demon_spikes)
 {
  #metamorphosis
  Spell(metamorphosis_veng)
 }
}

AddFunction VengeanceDefensivesCdPostConditions
{
 Spell(demon_spikes) or Spell(fiery_brand)
}

### actions.brand

AddFunction VengeanceBrandMainActions
{
 #sigil_of_flame,if=cooldown.fiery_brand.remains<2
 if SpellCooldown(fiery_brand) < 2 Spell(sigil_of_flame)
 #infernal_strike,if=cooldown.fiery_brand.remains=0
 if not SpellCooldown(fiery_brand) > 0 Spell(infernal_strike)
 #immolation_aura,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(immolation_aura)
 #infernal_strike,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(infernal_strike)
 #sigil_of_flame,if=dot.fiery_brand.ticking
 if target.DebuffPresent(fiery_brand_debuff) Spell(sigil_of_flame)
}

AddFunction VengeanceBrandMainPostConditions
{
}

AddFunction VengeanceBrandShortCdActions
{
 unless SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike)
 {
  #fiery_brand
  Spell(fiery_brand)

  unless target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura)
  {
   #fel_devastation,if=dot.fiery_brand.ticking
   if target.DebuffPresent(fiery_brand_debuff) Spell(fel_devastation)
  }
 }
}

AddFunction VengeanceBrandShortCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

AddFunction VengeanceBrandCdActions
{
}

AddFunction VengeanceBrandCdPostConditions
{
 SpellCooldown(fiery_brand) < 2 and Spell(sigil_of_flame) or not SpellCooldown(fiery_brand) > 0 and Spell(infernal_strike) or Spell(fiery_brand) or target.DebuffPresent(fiery_brand_debuff) and Spell(immolation_aura) or target.DebuffPresent(fiery_brand_debuff) and Spell(fel_devastation) or target.DebuffPresent(fiery_brand_debuff) and Spell(infernal_strike) or target.DebuffPresent(fiery_brand_debuff) and Spell(sigil_of_flame)
}

### actions.default

AddFunction VengeanceDefaultMainActions
{
 #consume_magic
 if target.HasDebuffType(magic) Spell(consume_magic)
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if Talent(charred_flesh_talent) VengeanceBrandMainActions()

 unless Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions()
 {
  #call_action_list,name=defensives
  VengeanceDefensivesMainActions()

  unless VengeanceDefensivesMainPostConditions()
  {
   #call_action_list,name=normal
   VengeanceNormalMainActions()
  }
 }
}

AddFunction VengeanceDefaultMainPostConditions
{
 Talent(charred_flesh_talent) and VengeanceBrandMainPostConditions() or VengeanceDefensivesMainPostConditions() or VengeanceNormalMainPostConditions()
}

AddFunction VengeanceDefaultShortCdActions
{
 #auto_attack
 VengeanceGetInMeleeRange()

 unless target.HasDebuffType(magic) and Spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if Talent(charred_flesh_talent) VengeanceBrandShortCdActions()

  unless Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions()
  {
   #call_action_list,name=defensives
   VengeanceDefensivesShortCdActions()

   unless VengeanceDefensivesShortCdPostConditions()
   {
    #call_action_list,name=normal
    VengeanceNormalShortCdActions()
   }
  }
 }
}

AddFunction VengeanceDefaultShortCdPostConditions
{
 target.HasDebuffType(magic) and Spell(consume_magic) or Talent(charred_flesh_talent) and VengeanceBrandShortCdPostConditions() or VengeanceDefensivesShortCdPostConditions() or VengeanceNormalShortCdPostConditions()
}

AddFunction VengeanceDefaultCdActions
{
 VengeanceInterruptActions()

 unless target.HasDebuffType(magic) and Spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if Talent(charred_flesh_talent) VengeanceBrandCdActions()

  unless Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions()
  {
   #call_action_list,name=defensives
   VengeanceDefensivesCdActions()

   unless VengeanceDefensivesCdPostConditions()
   {
    #call_action_list,name=normal
    VengeanceNormalCdActions()
   }
  }
 }
}

AddFunction VengeanceDefaultCdPostConditions
{
 target.HasDebuffType(magic) and Spell(consume_magic) or Talent(charred_flesh_talent) and VengeanceBrandCdPostConditions() or VengeanceDefensivesCdPostConditions() or VengeanceNormalCdPostConditions()
}

### Vengeance icons.

AddCheckBox(opt_demonhunter_vengeance_aoe L(AOE) default specialization=vengeance)

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=shortcd specialization=vengeance
{
 if not InCombat() VengeancePrecombatShortCdActions()
 unless not InCombat() and VengeancePrecombatShortCdPostConditions()
 {
  VengeanceDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=shortcd specialization=vengeance
{
 if not InCombat() VengeancePrecombatShortCdActions()
 unless not InCombat() and VengeancePrecombatShortCdPostConditions()
 {
  VengeanceDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=vengeance
{
 if not InCombat() VengeancePrecombatMainActions()
 unless not InCombat() and VengeancePrecombatMainPostConditions()
 {
  VengeanceDefaultMainActions()
 }
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=aoe specialization=vengeance
{
 if not InCombat() VengeancePrecombatMainActions()
 unless not InCombat() and VengeancePrecombatMainPostConditions()
 {
  VengeanceDefaultMainActions()
 }
}

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=cd specialization=vengeance
{
 if not InCombat() VengeancePrecombatCdActions()
 unless not InCombat() and VengeancePrecombatCdPostConditions()
 {
  VengeanceDefaultCdActions()
 }
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=cd specialization=vengeance
{
 if not InCombat() VengeancePrecombatCdActions()
 unless not InCombat() and VengeancePrecombatCdPostConditions()
 {
  VengeanceDefaultCdActions()
 }
}

### Required symbols
# charred_flesh_talent
# consume_magic
# demon_spikes
# disrupt
# fel_devastation
# felblade
# fiery_brand
# fiery_brand_debuff
# fracture
# immolation_aura
# imprison
# infernal_strike
# item_steelskin_potion
# metamorphosis_veng
# shear
# sigil_of_chains
# sigil_of_flame
# sigil_of_misery
# sigil_of_silence
# soul_cleave
# spirit_bomb
# spirit_bomb_talent
# throw_glaive_veng
]]
    OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end
