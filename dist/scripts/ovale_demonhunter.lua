local __exports = LibStub:NewLibrary("ovale/scripts/ovale_demonhunter", 80300)
if not __exports then return end
__exports.registerDemonHunter = function(OvaleScripts)
    do
        local name = "sc_t24_demon_hunter_havoc"
        local desc = "[8.3] Simulationcraft: T24_Demon_Hunter_Havoc"
        local code = [[
# Based on SimulationCraft profile "T24_Demon_Hunter_Havoc".
#	class=demonhunter
#	spec=havoc
#	talents=2313221

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)


AddFunction waiting_for_momentum
{
 hastalent(momentum_talent) and not buffpresent(momentum_buff)
}

AddFunction waiting_for_dark_slash
{
 hastalent(dark_slash_talent) and not pooling_for_blade_dance() and not pooling_for_meta() and not spellcooldown(dark_slash) > 0
}

AddFunction pooling_for_eye_beam
{
 hastalent(demonic_talent) and not hastalent(blind_fury_talent) and spellcooldown(eye_beam) < gcd() * 2 and furydeficit() > 20
}

AddFunction pooling_for_blade_dance
{
 blade_dance() and fury() < 75 - talentpoints(first_blood_talent) * 20
}

AddFunction pooling_for_meta
{
 not hastalent(demonic_talent) and spellcooldown(metamorphosis_havoc) < 6 and furydeficit() > 30 and { not waiting_for_nemesis() or spellcooldown(nemesis) < 10 }
}

AddFunction waiting_for_nemesis
{
 not { not hastalent(nemesis_talent) or talent(nemesis_talent) and spellcooldown(nemesis) == 0 or spellcooldown(nemesis) > target.timetodie() or spellcooldown(nemesis) > 60 }
}

AddFunction blade_dance
{
 hastalent(first_blood_talent) or enemies() >= 3 - talentpoints(trail_of_ruin_talent)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=havoc)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=havoc)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=havoc)
AddCheckBox(opt_meta_only_during_boss l(meta_only_during_boss) default specialization=havoc)
AddCheckBox(opt_vengeful_retreat spellname(vengeful_retreat) default specialization=havoc)
AddCheckBox(opt_fel_rush spellname(fel_rush) default specialization=havoc)

AddFunction havocinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(disrupt) and target.isinterruptible() spell(disrupt)
  if target.inrange(fel_eruption) and not target.classification(worldboss) spell(fel_eruption)
  if target.distance(less 8) and not target.classification(worldboss) spell(chaos_nova)
  if target.inrange(imprison) and not target.classification(worldboss) and target.creaturetype(demon humanoid beast) spell(imprison)
 }
}

AddFunction havocuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction havocgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(chaos_strike)
 {
  if target.inrange(felblade) spell(felblade)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.precombat

AddFunction havocprecombatmainactions
{
}

AddFunction havocprecombatmainpostconditions
{
}

AddFunction havocprecombatshortcdactions
{
}

AddFunction havocprecombatshortcdpostconditions
{
}

AddFunction havocprecombatcdactions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #metamorphosis,if=!azerite.chaotic_transformation.enabled
 if not hasazeritetrait(chaotic_transformation_trait) and { not checkboxon(opt_meta_only_during_boss) or isbossfight() } spell(metamorphosis_havoc)
 #use_item,name=azsharas_font_of_power
 havocuseitemactions()
}

AddFunction havocprecombatcdpostconditions
{
}

### actions.normal

AddFunction havocnormalmainactions
{
 #vengeful_retreat,if=talent.momentum.enabled&buff.prepared.down&time>1
 if hastalent(momentum_talent) and buffexpires(prepared_buff) and timeincombat() > 1 and checkboxon(opt_vengeful_retreat) spell(vengeful_retreat)
 #fel_rush,if=(variable.waiting_for_momentum|talent.fel_mastery.enabled)&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if { waiting_for_momentum() or hastalent(fel_mastery_talent) } and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) spell(fel_rush)
 #death_sweep,if=variable.blade_dance
 if blade_dance() spell(death_sweep)
 #immolation_aura
 spell(immolation_aura_havoc)
 #blade_dance,if=variable.blade_dance
 if blade_dance() spell(blade_dance)
 #felblade,if=fury.deficit>=40
 if furydeficit() >= 40 spell(felblade)
 #annihilation,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30|buff.metamorphosis.remains<5)&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 or buffremaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() spell(annihilation)
 #chaos_strike,if=(talent.demon_blades.enabled|!variable.waiting_for_momentum|fury.deficit<30)&!variable.pooling_for_meta&!variable.pooling_for_blade_dance&!variable.waiting_for_dark_slash
 if { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() spell(chaos_strike)
 #demons_bite
 spell(demons_bite)
 #fel_rush,if=!talent.momentum.enabled&raid_event.movement.in>charges*10&talent.demon_blades.enabled
 if not hastalent(momentum_talent) and 600 > charges(fel_rush) * 10 and hastalent(demon_blades_talent) and checkboxon(opt_fel_rush) spell(fel_rush)
 #felblade,if=movement.distance>15|buff.out_of_range.up
 if target.distance() > 15 or not target.inrange() spell(felblade)
 #fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum.enabled)
 if { target.distance() > 15 or not target.inrange() and not hastalent(momentum_talent) } and checkboxon(opt_fel_rush) spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.distance() > 15 and checkboxon(opt_vengeful_retreat) spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if hastalent(demon_blades_talent) spell(throw_glaive_havoc)
}

AddFunction havocnormalmainpostconditions
{
}

AddFunction havocnormalshortcdactions
{
 unless hastalent(momentum_talent) and buffexpires(prepared_buff) and timeincombat() > 1 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or { waiting_for_momentum() or hastalent(fel_mastery_talent) } and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) and spell(fel_rush)
 {
  #fel_barrage,if=!variable.waiting_for_momentum&(active_enemies>desired_targets|raid_event.adds.in>30)
  if not waiting_for_momentum() and { enemies() > enemies(tagged=1) or 600 > 30 } spell(fel_barrage)

  unless blade_dance() and spell(death_sweep) or spell(immolation_aura_havoc)
  {
   #eye_beam,if=active_enemies>1&(!raid_event.adds.exists|raid_event.adds.up)&!variable.waiting_for_momentum
   if enemies() > 1 and { not false(raid_event_adds_exists) or false(raid_event_adds_exists) } and not waiting_for_momentum() spell(eye_beam)

   unless blade_dance() and spell(blade_dance) or furydeficit() >= 40 and spell(felblade)
   {
    #eye_beam,if=!talent.blind_fury.enabled&!variable.waiting_for_dark_slash&raid_event.adds.in>cooldown
    if not hastalent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > spellcooldown(eye_beam) spell(eye_beam)

    unless { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 or buffremaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(annihilation) or { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(chaos_strike)
    {
     #eye_beam,if=talent.blind_fury.enabled&raid_event.adds.in>cooldown
     if hastalent(blind_fury_talent) and 600 > spellcooldown(eye_beam) spell(eye_beam)
    }
   }
  }
 }
}

AddFunction havocnormalshortcdpostconditions
{
 hastalent(momentum_talent) and buffexpires(prepared_buff) and timeincombat() > 1 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or { waiting_for_momentum() or hastalent(fel_mastery_talent) } and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) and spell(fel_rush) or blade_dance() and spell(death_sweep) or spell(immolation_aura_havoc) or blade_dance() and spell(blade_dance) or furydeficit() >= 40 and spell(felblade) or { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 or buffremaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(annihilation) or { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(chaos_strike) or spell(demons_bite) or not hastalent(momentum_talent) and 600 > charges(fel_rush) * 10 and hastalent(demon_blades_talent) and checkboxon(opt_fel_rush) and spell(fel_rush) or { target.distance() > 15 or not target.inrange() } and spell(felblade) or { target.distance() > 15 or not target.inrange() and not hastalent(momentum_talent) } and checkboxon(opt_fel_rush) and spell(fel_rush) or target.distance() > 15 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or hastalent(demon_blades_talent) and spell(throw_glaive_havoc)
}

AddFunction havocnormalcdactions
{
}

AddFunction havocnormalcdpostconditions
{
 hastalent(momentum_talent) and buffexpires(prepared_buff) and timeincombat() > 1 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or { waiting_for_momentum() or hastalent(fel_mastery_talent) } and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) and spell(fel_rush) or not waiting_for_momentum() and { enemies() > enemies(tagged=1) or 600 > 30 } and spell(fel_barrage) or blade_dance() and spell(death_sweep) or spell(immolation_aura_havoc) or enemies() > 1 and { not false(raid_event_adds_exists) or false(raid_event_adds_exists) } and not waiting_for_momentum() and spell(eye_beam) or blade_dance() and spell(blade_dance) or furydeficit() >= 40 and spell(felblade) or not hastalent(blind_fury_talent) and not waiting_for_dark_slash() and 600 > spellcooldown(eye_beam) and spell(eye_beam) or { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 or buffremaining(metamorphosis_havoc_buff) < 5 } and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(annihilation) or { hastalent(demon_blades_talent) or not waiting_for_momentum() or furydeficit() < 30 } and not pooling_for_meta() and not pooling_for_blade_dance() and not waiting_for_dark_slash() and spell(chaos_strike) or hastalent(blind_fury_talent) and 600 > spellcooldown(eye_beam) and spell(eye_beam) or spell(demons_bite) or not hastalent(momentum_talent) and 600 > charges(fel_rush) * 10 and hastalent(demon_blades_talent) and checkboxon(opt_fel_rush) and spell(fel_rush) or { target.distance() > 15 or not target.inrange() } and spell(felblade) or { target.distance() > 15 or not target.inrange() and not hastalent(momentum_talent) } and checkboxon(opt_fel_rush) and spell(fel_rush) or target.distance() > 15 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or hastalent(demon_blades_talent) and spell(throw_glaive_havoc)
}

### actions.essences

AddFunction havocessencesmainactions
{
 #concentrated_flame,if=(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() spell(concentrated_flame_essence)
}

AddFunction havocessencesmainpostconditions
{
}

AddFunction havocessencesshortcdactions
{
 unless { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=spell_targets.blade_dance1>=2|raid_event.adds.in>60
  if enemies() >= 2 or 600 > 60 spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.metamorphosis.up
  if buffpresent(metamorphosis_havoc_buff) spell(worldvein_resonance_essence)
  #reaping_flames,if=target.health.pct>80|target.health.pct<=20|target.time_to_pct_20>30
  if target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 spell(reaping_flames)
 }
}

AddFunction havocessencesshortcdpostconditions
{
 { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
}

AddFunction havocessencescdactions
{
 unless { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=buff.metamorphosis.up|target.time_to_die<=10
  if buffpresent(metamorphosis_havoc_buff) or target.timetodie() <= 10 spell(blood_of_the_enemy)
  #guardian_of_azeroth,if=(buff.metamorphosis.up&cooldown.metamorphosis.ready)|buff.metamorphosis.remains>25|target.time_to_die<=30
  if buffpresent(metamorphosis_havoc_buff) and { not checkboxon(opt_meta_only_during_boss) or isbossfight() } and spellcooldown(metamorphosis_havoc) == 0 or buffremaining(metamorphosis_havoc_buff) > 25 or target.timetodie() <= 30 spell(guardian_of_azeroth)
  #focused_azerite_beam,if=spell_targets.blade_dance1>=2|raid_event.adds.in>60
  if enemies() >= 2 or 600 > 60 spell(focused_azerite_beam)

  unless { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffpresent(metamorphosis_havoc_buff) and spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=fury<40&buff.metamorphosis.up
   if fury() < 40 and buffpresent(metamorphosis_havoc_buff) spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction havocessencescdpostconditions
{
 { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffpresent(metamorphosis_havoc_buff) and spell(worldvein_resonance_essence) or { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } and spell(reaping_flames)
}

### actions.demonic

AddFunction havocdemonicmainactions
{
 #death_sweep,if=variable.blade_dance
 if blade_dance() spell(death_sweep)
 #blade_dance,if=variable.blade_dance&!cooldown.metamorphosis.ready&(cooldown.eye_beam.remains>(5-azerite.revolving_blades.rank*3)|(raid_event.adds.in>cooldown&raid_event.adds.in<25))
 if blade_dance() and not { { not checkboxon(opt_meta_only_during_boss) or isbossfight() } and spellcooldown(metamorphosis_havoc) == 0 } and { spellcooldown(eye_beam) > 5 - azeritetraitrank(revolving_blades_trait) * 3 or 600 > spellcooldown(blade_dance) and 600 < 25 } spell(blade_dance)
 #immolation_aura
 spell(immolation_aura_havoc)
 #annihilation,if=!variable.pooling_for_blade_dance
 if not pooling_for_blade_dance() spell(annihilation)
 #felblade,if=fury.deficit>=40
 if furydeficit() >= 40 spell(felblade)
 #chaos_strike,if=!variable.pooling_for_blade_dance&!variable.pooling_for_eye_beam
 if not pooling_for_blade_dance() and not pooling_for_eye_beam() spell(chaos_strike)
 #fel_rush,if=talent.demon_blades.enabled&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10))
 if hastalent(demon_blades_talent) and not spellcooldown(eye_beam) == 0 and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) spell(fel_rush)
 #demons_bite
 spell(demons_bite)
 #throw_glaive,if=buff.out_of_range.up
 if not target.inrange() spell(throw_glaive_havoc)
 #fel_rush,if=movement.distance>15|buff.out_of_range.up
 if { target.distance() > 15 or not target.inrange() } and checkboxon(opt_fel_rush) spell(fel_rush)
 #vengeful_retreat,if=movement.distance>15
 if target.distance() > 15 and checkboxon(opt_vengeful_retreat) spell(vengeful_retreat)
 #throw_glaive,if=talent.demon_blades.enabled
 if hastalent(demon_blades_talent) spell(throw_glaive_havoc)
}

AddFunction havocdemonicmainpostconditions
{
}

AddFunction havocdemonicshortcdactions
{
 unless blade_dance() and spell(death_sweep)
 {
  #eye_beam,if=raid_event.adds.up|raid_event.adds.in>25
  if false(raid_event_adds_exists) or 600 > 25 spell(eye_beam)
  #fel_barrage,if=((!cooldown.eye_beam.up|buff.metamorphosis.up)&raid_event.adds.in>30)|active_enemies>desired_targets
  if { not { not spellcooldown(eye_beam) > 0 } or buffpresent(metamorphosis_havoc_buff) } and 600 > 30 or enemies() > enemies(tagged=1) spell(fel_barrage)
 }
}

AddFunction havocdemonicshortcdpostconditions
{
 blade_dance() and spell(death_sweep) or blade_dance() and not { { not checkboxon(opt_meta_only_during_boss) or isbossfight() } and spellcooldown(metamorphosis_havoc) == 0 } and { spellcooldown(eye_beam) > 5 - azeritetraitrank(revolving_blades_trait) * 3 or 600 > spellcooldown(blade_dance) and 600 < 25 } and spell(blade_dance) or spell(immolation_aura_havoc) or not pooling_for_blade_dance() and spell(annihilation) or furydeficit() >= 40 and spell(felblade) or not pooling_for_blade_dance() and not pooling_for_eye_beam() and spell(chaos_strike) or hastalent(demon_blades_talent) and not spellcooldown(eye_beam) == 0 and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) and spell(fel_rush) or spell(demons_bite) or not target.inrange() and spell(throw_glaive_havoc) or { target.distance() > 15 or not target.inrange() } and checkboxon(opt_fel_rush) and spell(fel_rush) or target.distance() > 15 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or hastalent(demon_blades_talent) and spell(throw_glaive_havoc)
}

AddFunction havocdemoniccdactions
{
}

AddFunction havocdemoniccdpostconditions
{
 blade_dance() and spell(death_sweep) or { false(raid_event_adds_exists) or 600 > 25 } and spell(eye_beam) or { { not { not spellcooldown(eye_beam) > 0 } or buffpresent(metamorphosis_havoc_buff) } and 600 > 30 or enemies() > enemies(tagged=1) } and spell(fel_barrage) or blade_dance() and not { { not checkboxon(opt_meta_only_during_boss) or isbossfight() } and spellcooldown(metamorphosis_havoc) == 0 } and { spellcooldown(eye_beam) > 5 - azeritetraitrank(revolving_blades_trait) * 3 or 600 > spellcooldown(blade_dance) and 600 < 25 } and spell(blade_dance) or spell(immolation_aura_havoc) or not pooling_for_blade_dance() and spell(annihilation) or furydeficit() >= 40 and spell(felblade) or not pooling_for_blade_dance() and not pooling_for_eye_beam() and spell(chaos_strike) or hastalent(demon_blades_talent) and not spellcooldown(eye_beam) == 0 and { charges(fel_rush) == 2 or 600 > 10 and 600 > 10 } and checkboxon(opt_fel_rush) and spell(fel_rush) or spell(demons_bite) or not target.inrange() and spell(throw_glaive_havoc) or { target.distance() > 15 or not target.inrange() } and checkboxon(opt_fel_rush) and spell(fel_rush) or target.distance() > 15 and checkboxon(opt_vengeful_retreat) and spell(vengeful_retreat) or hastalent(demon_blades_talent) and spell(throw_glaive_havoc)
}

### actions.dark_slash

AddFunction havocdark_slashmainactions
{
 #dark_slash,if=fury>=80&(!variable.blade_dance|!cooldown.blade_dance.ready)
 if fury() >= 80 and { not blade_dance() or not spellcooldown(blade_dance) == 0 } spell(dark_slash)
 #annihilation,if=debuff.dark_slash.up
 if target.debuffpresent(dark_slash_debuff) spell(annihilation)
 #chaos_strike,if=debuff.dark_slash.up
 if target.debuffpresent(dark_slash_debuff) spell(chaos_strike)
}

AddFunction havocdark_slashmainpostconditions
{
}

AddFunction havocdark_slashshortcdactions
{
}

AddFunction havocdark_slashshortcdpostconditions
{
 fury() >= 80 and { not blade_dance() or not spellcooldown(blade_dance) == 0 } and spell(dark_slash) or target.debuffpresent(dark_slash_debuff) and spell(annihilation) or target.debuffpresent(dark_slash_debuff) and spell(chaos_strike)
}

AddFunction havocdark_slashcdactions
{
}

AddFunction havocdark_slashcdpostconditions
{
 fury() >= 80 and { not blade_dance() or not spellcooldown(blade_dance) == 0 } and spell(dark_slash) or target.debuffpresent(dark_slash_debuff) and spell(annihilation) or target.debuffpresent(dark_slash_debuff) and spell(chaos_strike)
}

### actions.cooldown

AddFunction havoccooldownmainactions
{
 #call_action_list,name=essences
 havocessencesmainactions()
}

AddFunction havoccooldownmainpostconditions
{
 havocessencesmainpostconditions()
}

AddFunction havoccooldownshortcdactions
{
 #call_action_list,name=essences
 havocessencesshortcdactions()
}

AddFunction havoccooldownshortcdpostconditions
{
 havocessencesshortcdpostconditions()
}

AddFunction havoccooldowncdactions
{
 #metamorphosis,if=!(talent.demonic.enabled|variable.pooling_for_meta|variable.waiting_for_nemesis)|target.time_to_die<25
 if { not { hastalent(demonic_talent) or pooling_for_meta() or waiting_for_nemesis() } or target.timetodie() < 25 } and { not checkboxon(opt_meta_only_during_boss) or isbossfight() } spell(metamorphosis_havoc)
 #metamorphosis,if=talent.demonic.enabled&(!azerite.chaotic_transformation.enabled|(cooldown.eye_beam.remains>20&(!variable.blade_dance|cooldown.blade_dance.remains>gcd.max)))
 if hastalent(demonic_talent) and { not hasazeritetrait(chaotic_transformation_trait) or spellcooldown(eye_beam) > 20 and { not blade_dance() or spellcooldown(blade_dance) > gcd() } } and { not checkboxon(opt_meta_only_during_boss) or isbossfight() } spell(metamorphosis_havoc)
 #nemesis,target_if=min:target.time_to_die,if=raid_event.adds.exists&debuff.nemesis.down&(active_enemies>desired_targets|raid_event.adds.in>60)
 if false(raid_event_adds_exists) and target.debuffexpires(nemesis_debuff) and { enemies() > enemies(tagged=1) or 600 > 60 } spell(nemesis)
 #nemesis,if=!raid_event.adds.exists
 if not false(raid_event_adds_exists) spell(nemesis)
 #potion,if=buff.metamorphosis.remains>25|target.time_to_die<60
 if { buffremaining(metamorphosis_havoc_buff) > 25 or target.timetodie() < 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_item,name=galecallers_boon,if=!talent.fel_barrage.enabled|cooldown.fel_barrage.ready
 if not hastalent(fel_barrage_talent) or spellcooldown(fel_barrage) == 0 havocuseitemactions()
 #use_item,effect_name=cyclotronic_blast,if=buff.metamorphosis.up&buff.memory_of_lucid_dreams.down&(!variable.blade_dance|!cooldown.blade_dance.ready)
 if buffpresent(metamorphosis_havoc_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and { not blade_dance() or not spellcooldown(blade_dance) == 0 } havocuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|(debuff.conductive_ink_debuff.up|buff.metamorphosis.remains>20)&target.health.pct<31|target.time_to_die<20
 if target.debuffexpires(razor_coral) or { target.debuffpresent(conductive_ink) or buffremaining(metamorphosis_havoc_buff) > 20 } and target.healthpercent() < 31 or target.timetodie() < 20 havocuseitemactions()
 #use_item,name=azsharas_font_of_power,if=cooldown.metamorphosis.remains<10|cooldown.metamorphosis.remains>60
 if spellcooldown(metamorphosis_havoc) < 10 or spellcooldown(metamorphosis_havoc) > 60 havocuseitemactions()
 #use_items,if=buff.metamorphosis.up
 if buffpresent(metamorphosis_havoc_buff) havocuseitemactions()
 #call_action_list,name=essences
 havocessencescdactions()
}

AddFunction havoccooldowncdpostconditions
{
 havocessencescdpostconditions()
}

### actions.default

AddFunction havoc_defaultmainactions
{
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not gcdremaining() > 0 havoccooldownmainactions()

 unless not gcdremaining() > 0 and havoccooldownmainpostconditions()
 {
  #pick_up_fragment,if=fury.deficit>=35&(!azerite.eyes_of_rage.enabled|cooldown.eye_beam.remains>1.4)
  if furydeficit() >= 35 and { not hasazeritetrait(eyes_of_rage_trait) or spellcooldown(eye_beam) > 1.4 } spell(pick_up_fragment)
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } havocdark_slashmainactions()

  unless hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashmainpostconditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if hastalent(demonic_talent) havocdemonicmainactions()

   unless hastalent(demonic_talent) and havocdemonicmainpostconditions()
   {
    #run_action_list,name=normal
    havocnormalmainactions()
   }
  }
 }
}

AddFunction havoc_defaultmainpostconditions
{
 not gcdremaining() > 0 and havoccooldownmainpostconditions() or hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashmainpostconditions() or hastalent(demonic_talent) and havocdemonicmainpostconditions() or havocnormalmainpostconditions()
}

AddFunction havoc_defaultshortcdactions
{
 #auto_attack
 havocgetinmeleerange()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not gcdremaining() > 0 havoccooldownshortcdactions()

 unless not gcdremaining() > 0 and havoccooldownshortcdpostconditions() or furydeficit() >= 35 and { not hasazeritetrait(eyes_of_rage_trait) or spellcooldown(eye_beam) > 1.4 } and spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } havocdark_slashshortcdactions()

  unless hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashshortcdpostconditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if hastalent(demonic_talent) havocdemonicshortcdactions()

   unless hastalent(demonic_talent) and havocdemonicshortcdpostconditions()
   {
    #run_action_list,name=normal
    havocnormalshortcdactions()
   }
  }
 }
}

AddFunction havoc_defaultshortcdpostconditions
{
 not gcdremaining() > 0 and havoccooldownshortcdpostconditions() or furydeficit() >= 35 and { not hasazeritetrait(eyes_of_rage_trait) or spellcooldown(eye_beam) > 1.4 } and spell(pick_up_fragment) or hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashshortcdpostconditions() or hastalent(demonic_talent) and havocdemonicshortcdpostconditions() or havocnormalshortcdpostconditions()
}

AddFunction havoc_defaultcdactions
{
 #variable,name=blade_dance,value=talent.first_blood.enabled|spell_targets.blade_dance1>=(3-talent.trail_of_ruin.enabled)
 #variable,name=waiting_for_nemesis,value=!(!talent.nemesis.enabled|cooldown.nemesis.ready|cooldown.nemesis.remains>target.time_to_die|cooldown.nemesis.remains>60)
 #variable,name=pooling_for_meta,value=!talent.demonic.enabled&cooldown.metamorphosis.remains<6&fury.deficit>30&(!variable.waiting_for_nemesis|cooldown.nemesis.remains<10)
 #variable,name=pooling_for_blade_dance,value=variable.blade_dance&(fury<75-talent.first_blood.enabled*20)
 #variable,name=pooling_for_eye_beam,value=talent.demonic.enabled&!talent.blind_fury.enabled&cooldown.eye_beam.remains<(gcd.max*2)&fury.deficit>20
 #variable,name=waiting_for_dark_slash,value=talent.dark_slash.enabled&!variable.pooling_for_blade_dance&!variable.pooling_for_meta&cooldown.dark_slash.up
 #variable,name=waiting_for_momentum,value=talent.momentum.enabled&!buff.momentum.up
 #disrupt
 havocinterruptactions()
 #call_action_list,name=cooldown,if=gcd.remains=0
 if not gcdremaining() > 0 havoccooldowncdactions()

 unless not gcdremaining() > 0 and havoccooldowncdpostconditions() or furydeficit() >= 35 and { not hasazeritetrait(eyes_of_rage_trait) or spellcooldown(eye_beam) > 1.4 } and spell(pick_up_fragment)
 {
  #call_action_list,name=dark_slash,if=talent.dark_slash.enabled&(variable.waiting_for_dark_slash|debuff.dark_slash.up)
  if hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } havocdark_slashcdactions()

  unless hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashcdpostconditions()
  {
   #run_action_list,name=demonic,if=talent.demonic.enabled
   if hastalent(demonic_talent) havocdemoniccdactions()

   unless hastalent(demonic_talent) and havocdemoniccdpostconditions()
   {
    #run_action_list,name=normal
    havocnormalcdactions()
   }
  }
 }
}

AddFunction havoc_defaultcdpostconditions
{
 not gcdremaining() > 0 and havoccooldowncdpostconditions() or furydeficit() >= 35 and { not hasazeritetrait(eyes_of_rage_trait) or spellcooldown(eye_beam) > 1.4 } and spell(pick_up_fragment) or hastalent(dark_slash_talent) and { waiting_for_dark_slash() or target.debuffpresent(dark_slash_debuff) } and havocdark_slashcdpostconditions() or hastalent(demonic_talent) and havocdemoniccdpostconditions() or havocnormalcdpostconditions()
}

### Havoc icons.

AddCheckBox(opt_demonhunter_havoc_aoe l(aoe) default specialization=havoc)

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=shortcd specialization=havoc
{
 if not incombat() havocprecombatshortcdactions()
 havoc_defaultshortcdactions()
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=shortcd specialization=havoc
{
 if not incombat() havocprecombatshortcdactions()
 havoc_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=havoc
{
 if not incombat() havocprecombatmainactions()
 havoc_defaultmainactions()
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=aoe specialization=havoc
{
 if not incombat() havocprecombatmainactions()
 havoc_defaultmainactions()
}

AddIcon checkbox=!opt_demonhunter_havoc_aoe enemies=1 help=cd specialization=havoc
{
 if not incombat() havocprecombatcdactions()
 havoc_defaultcdactions()
}

AddIcon checkbox=opt_demonhunter_havoc_aoe help=cd specialization=havoc
{
 if not incombat() havocprecombatcdactions()
 havoc_defaultcdactions()
}

### Required symbols
# annihilation
# blade_dance
# blind_fury_talent
# blood_of_the_enemy
# chaos_nova
# chaos_strike
# chaotic_transformation_trait
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
# dark_slash
# dark_slash_debuff
# dark_slash_talent
# death_sweep
# demon_blades_talent
# demonic_talent
# demons_bite
# disrupt
# eye_beam
# eyes_of_rage_trait
# fel_barrage
# fel_barrage_talent
# fel_eruption
# fel_mastery_talent
# fel_rush
# felblade
# first_blood_talent
# focused_azerite_beam
# guardian_of_azeroth
# immolation_aura_havoc
# imprison
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# metamorphosis_havoc
# metamorphosis_havoc_buff
# momentum_buff
# momentum_talent
# nemesis
# nemesis_debuff
# nemesis_talent
# pick_up_fragment
# prepared_buff
# purifying_blast
# razor_coral
# reaping_flames
# reckless_force_buff
# reckless_force_counter_buff
# revolving_blades_trait
# ripple_in_space_essence
# the_unbound_force
# throw_glaive_havoc
# trail_of_ruin_talent
# unbridled_fury_item
# vengeful_retreat
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
    end
    do
        local name = "sc_t24_demon_hunter_vengeance"
        local desc = "[8.3] Simulationcraft: T24_Demon_Hunter_Vengeance"
        local code = [[
# Based on SimulationCraft profile "T24_Demon_Hunter_Vengeance".
#	class=demonhunter
#	spec=vengeance
#	talents=1213121

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=vengeance)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=vengeance)

AddFunction vengeanceinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(disrupt) and target.isinterruptible() spell(disrupt)
  if target.isinterruptible() and not target.classification(worldboss) and not sigilcharging(silence misery chains) and target.remainingcasttime() >= 2 - talent(quickened_sigils_talent) + gcdremaining() spell(sigil_of_silence)
  if not target.classification(worldboss) and not sigilcharging(silence misery chains) and target.remainingcasttime() >= 2 - talent(quickened_sigils_talent) + gcdremaining() spell(sigil_of_misery)
  if not target.classification(worldboss) and not sigilcharging(silence misery chains) and target.remainingcasttime() >= 2 - talent(quickened_sigils_talent) + gcdremaining() spell(sigil_of_chains)
  if target.inrange(imprison) and not target.classification(worldboss) and target.creaturetype(demon humanoid beast) spell(imprison)
 }
}

AddFunction vengeanceuseheartessence
{
 spell(concentrated_flame_essence)
}

AddFunction vengeanceuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction vengeancegetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(shear) texture(misc_arrowlup help=l(not_in_melee_range))
}

### actions.precombat

AddFunction vengeanceprecombatmainactions
{
}

AddFunction vengeanceprecombatmainpostconditions
{
}

AddFunction vengeanceprecombatshortcdactions
{
}

AddFunction vengeanceprecombatshortcdpostconditions
{
}

AddFunction vengeanceprecombatcdactions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(steelskin_potion_item usable=1)
 #use_item,name=azsharas_font_of_power
 vengeanceuseitemactions()
}

AddFunction vengeanceprecombatcdpostconditions
{
}

### actions.normal

AddFunction vengeancenormalmainactions
{
 #infernal_strike
 spell(infernal_strike)
 #spirit_bomb,if=soul_fragments>=4
 if soulfragments() >= 4 spell(spirit_bomb)
 #soul_cleave,if=!talent.spirit_bomb.enabled
 if not hastalent(spirit_bomb_talent) spell(soul_cleave)
 #soul_cleave,if=talent.spirit_bomb.enabled&soul_fragments=0
 if hastalent(spirit_bomb_talent) and soulfragments() == 0 spell(soul_cleave)
 #immolation_aura,if=pain<=90
 if pain() <= 90 spell(immolation_aura)
 #felblade,if=pain<=70
 if pain() <= 70 spell(felblade)
 #fracture,if=soul_fragments<=3
 if soulfragments() <= 3 spell(fracture)
 #sigil_of_flame
 spell(sigil_of_flame)
 #shear
 spell(shear)
 #throw_glaive
 spell(throw_glaive_veng)
}

AddFunction vengeancenormalmainpostconditions
{
}

AddFunction vengeancenormalshortcdactions
{
 unless spell(infernal_strike) or soulfragments() >= 4 and spell(spirit_bomb) or not hastalent(spirit_bomb_talent) and spell(soul_cleave) or hastalent(spirit_bomb_talent) and soulfragments() == 0 and spell(soul_cleave) or pain() <= 90 and spell(immolation_aura) or pain() <= 70 and spell(felblade) or soulfragments() <= 3 and spell(fracture)
 {
  #fel_devastation
  spell(fel_devastation)
 }
}

AddFunction vengeancenormalshortcdpostconditions
{
 spell(infernal_strike) or soulfragments() >= 4 and spell(spirit_bomb) or not hastalent(spirit_bomb_talent) and spell(soul_cleave) or hastalent(spirit_bomb_talent) and soulfragments() == 0 and spell(soul_cleave) or pain() <= 90 and spell(immolation_aura) or pain() <= 70 and spell(felblade) or soulfragments() <= 3 and spell(fracture) or spell(sigil_of_flame) or spell(shear) or spell(throw_glaive_veng)
}

AddFunction vengeancenormalcdactions
{
}

AddFunction vengeancenormalcdpostconditions
{
 spell(infernal_strike) or soulfragments() >= 4 and spell(spirit_bomb) or not hastalent(spirit_bomb_talent) and spell(soul_cleave) or hastalent(spirit_bomb_talent) and soulfragments() == 0 and spell(soul_cleave) or pain() <= 90 and spell(immolation_aura) or pain() <= 70 and spell(felblade) or soulfragments() <= 3 and spell(fracture) or spell(fel_devastation) or spell(sigil_of_flame) or spell(shear) or spell(throw_glaive_veng)
}

### actions.defensives

AddFunction vengeancedefensivesmainactions
{
 #demon_spikes
 spell(demon_spikes)
}

AddFunction vengeancedefensivesmainpostconditions
{
}

AddFunction vengeancedefensivesshortcdactions
{
 unless spell(demon_spikes)
 {
  #fiery_brand
  spell(fiery_brand)
 }
}

AddFunction vengeancedefensivesshortcdpostconditions
{
 spell(demon_spikes)
}

AddFunction vengeancedefensivescdactions
{
 unless spell(demon_spikes)
 {
  #metamorphosis
  spell(metamorphosis_veng)
 }
}

AddFunction vengeancedefensivescdpostconditions
{
 spell(demon_spikes) or spell(fiery_brand)
}

### actions.cooldowns

AddFunction vengeancecooldownsmainactions
{
 #concentrated_flame,if=(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() spell(concentrated_flame_essence)
}

AddFunction vengeancecooldownsmainpostconditions
{
}

AddFunction vengeancecooldownsshortcdactions
{
 unless { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
 }
}

AddFunction vengeancecooldownsshortcdpostconditions
{
 { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
}

AddFunction vengeancecooldownscdactions
{
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(steelskin_potion_item usable=1)

 unless { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
 {
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #heart_essence
  vengeanceuseheartessence()
  #use_item,effect_name=cyclotronic_blast,if=buff.memory_of_lucid_dreams.down
  if buffexpires(memory_of_lucid_dreams_essence_buff) vengeanceuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<31|target.time_to_die<20
  if target.debuffexpires(razor_coral) or target.debuffpresent(conductive_ink) and target.healthpercent() < 31 or target.timetodie() < 20 vengeanceuseitemactions()
  #use_items
  vengeanceuseitemactions()
 }
}

AddFunction vengeancecooldownscdpostconditions
{
 { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
}

### actions.brand

AddFunction vengeancebrandmainactions
{
 #sigil_of_flame,if=cooldown.fiery_brand.remains<2
 if spellcooldown(fiery_brand) < 2 spell(sigil_of_flame)
 #infernal_strike,if=cooldown.fiery_brand.remains=0
 if not spellcooldown(fiery_brand) > 0 spell(infernal_strike)
 #immolation_aura,if=dot.fiery_brand.ticking
 if target.debuffpresent(fiery_brand_debuff) spell(immolation_aura)
 #infernal_strike,if=dot.fiery_brand.ticking
 if target.debuffpresent(fiery_brand_debuff) spell(infernal_strike)
 #sigil_of_flame,if=dot.fiery_brand.ticking
 if target.debuffpresent(fiery_brand_debuff) spell(sigil_of_flame)
}

AddFunction vengeancebrandmainpostconditions
{
}

AddFunction vengeancebrandshortcdactions
{
 unless spellcooldown(fiery_brand) < 2 and spell(sigil_of_flame) or not spellcooldown(fiery_brand) > 0 and spell(infernal_strike)
 {
  #fiery_brand
  spell(fiery_brand)

  unless target.debuffpresent(fiery_brand_debuff) and spell(immolation_aura)
  {
   #fel_devastation,if=dot.fiery_brand.ticking
   if target.debuffpresent(fiery_brand_debuff) spell(fel_devastation)
  }
 }
}

AddFunction vengeancebrandshortcdpostconditions
{
 spellcooldown(fiery_brand) < 2 and spell(sigil_of_flame) or not spellcooldown(fiery_brand) > 0 and spell(infernal_strike) or target.debuffpresent(fiery_brand_debuff) and spell(immolation_aura) or target.debuffpresent(fiery_brand_debuff) and spell(infernal_strike) or target.debuffpresent(fiery_brand_debuff) and spell(sigil_of_flame)
}

AddFunction vengeancebrandcdactions
{
}

AddFunction vengeancebrandcdpostconditions
{
 spellcooldown(fiery_brand) < 2 and spell(sigil_of_flame) or not spellcooldown(fiery_brand) > 0 and spell(infernal_strike) or spell(fiery_brand) or target.debuffpresent(fiery_brand_debuff) and spell(immolation_aura) or target.debuffpresent(fiery_brand_debuff) and spell(fel_devastation) or target.debuffpresent(fiery_brand_debuff) and spell(infernal_strike) or target.debuffpresent(fiery_brand_debuff) and spell(sigil_of_flame)
}

### actions.default

AddFunction vengeance_defaultmainactions
{
 #consume_magic
 if target.hasdebufftype(magic) spell(consume_magic)
 #call_action_list,name=brand,if=talent.charred_flesh.enabled
 if hastalent(charred_flesh_talent) vengeancebrandmainactions()

 unless hastalent(charred_flesh_talent) and vengeancebrandmainpostconditions()
 {
  #call_action_list,name=defensives
  vengeancedefensivesmainactions()

  unless vengeancedefensivesmainpostconditions()
  {
   #call_action_list,name=cooldowns
   vengeancecooldownsmainactions()

   unless vengeancecooldownsmainpostconditions()
   {
    #call_action_list,name=normal
    vengeancenormalmainactions()
   }
  }
 }
}

AddFunction vengeance_defaultmainpostconditions
{
 hastalent(charred_flesh_talent) and vengeancebrandmainpostconditions() or vengeancedefensivesmainpostconditions() or vengeancecooldownsmainpostconditions() or vengeancenormalmainpostconditions()
}

AddFunction vengeance_defaultshortcdactions
{
 #auto_attack
 vengeancegetinmeleerange()

 unless target.hasdebufftype(magic) and spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if hastalent(charred_flesh_talent) vengeancebrandshortcdactions()

  unless hastalent(charred_flesh_talent) and vengeancebrandshortcdpostconditions()
  {
   #call_action_list,name=defensives
   vengeancedefensivesshortcdactions()

   unless vengeancedefensivesshortcdpostconditions()
   {
    #call_action_list,name=cooldowns
    vengeancecooldownsshortcdactions()

    unless vengeancecooldownsshortcdpostconditions()
    {
     #call_action_list,name=normal
     vengeancenormalshortcdactions()
    }
   }
  }
 }
}

AddFunction vengeance_defaultshortcdpostconditions
{
 target.hasdebufftype(magic) and spell(consume_magic) or hastalent(charred_flesh_talent) and vengeancebrandshortcdpostconditions() or vengeancedefensivesshortcdpostconditions() or vengeancecooldownsshortcdpostconditions() or vengeancenormalshortcdpostconditions()
}

AddFunction vengeance_defaultcdactions
{
 vengeanceinterruptactions()

 unless target.hasdebufftype(magic) and spell(consume_magic)
 {
  #call_action_list,name=brand,if=talent.charred_flesh.enabled
  if hastalent(charred_flesh_talent) vengeancebrandcdactions()

  unless hastalent(charred_flesh_talent) and vengeancebrandcdpostconditions()
  {
   #call_action_list,name=defensives
   vengeancedefensivescdactions()

   unless vengeancedefensivescdpostconditions()
   {
    #call_action_list,name=cooldowns
    vengeancecooldownscdactions()

    unless vengeancecooldownscdpostconditions()
    {
     #call_action_list,name=normal
     vengeancenormalcdactions()
    }
   }
  }
 }
}

AddFunction vengeance_defaultcdpostconditions
{
 target.hasdebufftype(magic) and spell(consume_magic) or hastalent(charred_flesh_talent) and vengeancebrandcdpostconditions() or vengeancedefensivescdpostconditions() or vengeancecooldownscdpostconditions() or vengeancenormalcdpostconditions()
}

### Vengeance icons.

AddCheckBox(opt_demonhunter_vengeance_aoe l(aoe) default specialization=vengeance)

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=shortcd specialization=vengeance
{
 if not incombat() vengeanceprecombatshortcdactions()
 vengeance_defaultshortcdactions()
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=shortcd specialization=vengeance
{
 if not incombat() vengeanceprecombatshortcdactions()
 vengeance_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=vengeance
{
 if not incombat() vengeanceprecombatmainactions()
 vengeance_defaultmainactions()
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=aoe specialization=vengeance
{
 if not incombat() vengeanceprecombatmainactions()
 vengeance_defaultmainactions()
}

AddIcon checkbox=!opt_demonhunter_vengeance_aoe enemies=1 help=cd specialization=vengeance
{
 if not incombat() vengeanceprecombatcdactions()
 vengeance_defaultcdactions()
}

AddIcon checkbox=opt_demonhunter_vengeance_aoe help=cd specialization=vengeance
{
 if not incombat() vengeanceprecombatcdactions()
 vengeance_defaultcdactions()
}

### Required symbols
# charred_flesh_talent
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
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
# lifeblood_buff
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# metamorphosis_veng
# razor_coral
# shear
# sigil_of_chains
# sigil_of_flame
# sigil_of_misery
# sigil_of_silence
# soul_cleave
# spirit_bomb
# spirit_bomb_talent
# steelskin_potion_item
# throw_glaive_veng
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
    end
end
