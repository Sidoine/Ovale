local __exports = LibStub:NewLibrary("ovale/scripts/ovale_hunter", 90000)
if not __exports then return end
__exports.registerHunter = function(OvaleScripts)
    do
        local name = "sc_t25_hunter_beast_mastery"
        local desc = "[9.0] Simulationcraft: T25_Hunter_Beast_Mastery"
        local code = [[
# Based on SimulationCraft profile "T25_Hunter_Beast_Mastery".
#	class=hunter
#	spec=beast_mastery
#	talents=2202012

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(beast_mastery)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(beast_mastery)))

AddFunction beast_masteryinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counter_shot) and target.isinterruptible() spell(counter_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction beast_masteryuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction beast_masterysummonpet
{
 if not pet.present() and not pet.isdead() and not previousspell(revive_pet) texture(ability_hunter_beastcall help=(l(summon_pet)))
}

### actions.st

AddFunction beast_masterystmainactions
{
 #kill_shot
 spell(kill_shot)
 #barbed_shot,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<gcd|cooldown.bestial_wrath.remains&(full_recharge_time<gcd|azerite.primal_instincts.enabled&cooldown.aspect_of_the_wild.remains<gcd)|cooldown.bestial_wrath.remains<12+gcd&talent.scent_of_blood.enabled
 if pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) spell(barbed_shot)
 #concentrated_flame,if=focus+focus.regen*gcd<focus.max&buff.bestial_wrath.down&(!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight)|full_recharge_time<gcd|target.time_to_die<5
 if focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 spell(concentrated_flame)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10|target.time_to_die<5
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 spell(the_unbound_force)
 #barbed_shot,if=azerite.dance_of_death.rank>1&buff.dance_of_death.remains<gcd
 if azeritetraitrank(dance_of_death_trait) > 1 and buffremaining(dance_of_death_buff) < gcd() spell(barbed_shot)
 #blood_of_the_enemy,if=buff.aspect_of_the_wild.remains>10+gcd|target.time_to_die<10+gcd
 if buffremaining(aspect_of_the_wild) > 10 + gcd() or target.timetodie() < 10 + gcd() spell(blood_of_the_enemy)
 #kill_command
 if pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() spell(kill_command)
 #chimaera_shot
 spell(chimaera_shot)
 #dire_beast
 spell(dire_beast)
 #barbed_shot,if=talent.one_with_the_pack.enabled&charges_fractional>1.5|charges_fractional>1.8|cooldown.aspect_of_the_wild.remains<pet.main.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|target.time_to_die<9
 if hastalent(one_with_the_pack_talent) and charges(barbed_shot count=0) > 1.5 or charges(barbed_shot count=0) > 1.8 or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or target.timetodie() < 9 spell(barbed_shot)
 #barrage
 spell(barrage)
 #cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd&cooldown.bestial_wrath.remains_guess>focus.time_to_max|buff.memory_of_lucid_dreams.up)&cooldown.kill_command.remains>1|target.time_to_die<3
 if { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() and spellcooldown(bestial_wrath) > timetomaxfocus() or buffpresent(memory_of_lucid_dreams_buff) } and spellcooldown(kill_command) > 1 or target.timetodie() < 3 spell(cobra_shot)
 #barbed_shot,if=pet.main.buff.frenzy.duration-gcd>full_recharge_time
 if baseduration(frenzy_buff) - gcd() > spellfullrecharge(barbed_shot) spell(barbed_shot)
}

AddFunction beast_masterystmainpostconditions
{
}

AddFunction beast_masterystshortcdactions
{
 unless spell(kill_shot)
 {
  #bloodshed
  spell(bloodshed)

  unless { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame)
  {
   #a_murder_of_crows
   spell(a_murder_of_crows)
   #focused_azerite_beam,if=buff.bestial_wrath.down|target.time_to_die<5
   if buffexpires(bestial_wrath) or target.timetodie() < 5 spell(focused_azerite_beam)

   unless { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 } and spell(the_unbound_force)
   {
    #bestial_wrath,if=talent.scent_of_blood.enabled|talent.one_with_the_pack.enabled&buff.bestial_wrath.remains<gcd|buff.bestial_wrath.down&cooldown.aspect_of_the_wild.remains>15|target.time_to_die<15+gcd
    if hastalent(scent_of_blood_talent_beast_mastery) or hastalent(one_with_the_pack_talent) and buffremaining(bestial_wrath) < gcd() or buffexpires(bestial_wrath) and spellcooldown(aspect_of_the_wild) > 15 or target.timetodie() < 15 + gcd() spell(bestial_wrath)

    unless azeritetraitrank(dance_of_death_trait) > 1 and buffremaining(dance_of_death_buff) < gcd() and spell(barbed_shot) or { buffremaining(aspect_of_the_wild) > 10 + gcd() or target.timetodie() < 10 + gcd() } and spell(blood_of_the_enemy) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command)
    {
     #bag_of_tricks,if=buff.bestial_wrath.down|target.time_to_die<5
     if buffexpires(bestial_wrath) or target.timetodie() < 5 spell(bag_of_tricks)

     unless spell(chimaera_shot) or spell(dire_beast) or { hastalent(one_with_the_pack_talent) and charges(barbed_shot count=0) > 1.5 or charges(barbed_shot count=0) > 1.8 or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or target.timetodie() < 9 } and spell(barbed_shot)
     {
      #purifying_blast,if=buff.bestial_wrath.down|target.time_to_die<8
      if buffexpires(bestial_wrath) or target.timetodie() < 8 spell(purifying_blast)
     }
    }
   }
  }
 }
}

AddFunction beast_masterystshortcdpostconditions
{
 spell(kill_shot) or { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or azeritetraitrank(dance_of_death_trait) > 1 and buffremaining(dance_of_death_buff) < gcd() and spell(barbed_shot) or { buffremaining(aspect_of_the_wild) > 10 + gcd() or target.timetodie() < 10 + gcd() } and spell(blood_of_the_enemy) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(chimaera_shot) or spell(dire_beast) or { hastalent(one_with_the_pack_talent) and charges(barbed_shot count=0) > 1.5 or charges(barbed_shot count=0) > 1.8 or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or target.timetodie() < 9 } and spell(barbed_shot) or spell(barrage) or { { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() and spellcooldown(bestial_wrath) > timetomaxfocus() or buffpresent(memory_of_lucid_dreams_buff) } and spellcooldown(kill_command) > 1 or target.timetodie() < 3 } and spell(cobra_shot) or baseduration(frenzy_buff) - gcd() > spellfullrecharge(barbed_shot) and spell(barbed_shot)
}

AddFunction beast_masterystcdactions
{
 unless spell(kill_shot) or spell(bloodshed) or { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame)
 {
  #aspect_of_the_wild,if=buff.aspect_of_the_wild.down&(cooldown.barbed_shot.charges<1|!azerite.primal_instincts.enabled)
  if buffexpires(aspect_of_the_wild) and { spellcharges(barbed_shot) < 1 or not hasazeritetrait(primal_instincts_trait) } spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if buffpresent(aspect_of_the_wild) and buffpresent(bestial_wrath) or target.timetodie() < 15 spell(stampede)
 }
}

AddFunction beast_masterystcdpostconditions
{
 spell(kill_shot) or spell(bloodshed) or { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame) or spell(a_murder_of_crows) or { buffexpires(bestial_wrath) or target.timetodie() < 5 } and spell(focused_azerite_beam) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or { hastalent(scent_of_blood_talent_beast_mastery) or hastalent(one_with_the_pack_talent) and buffremaining(bestial_wrath) < gcd() or buffexpires(bestial_wrath) and spellcooldown(aspect_of_the_wild) > 15 or target.timetodie() < 15 + gcd() } and spell(bestial_wrath) or azeritetraitrank(dance_of_death_trait) > 1 and buffremaining(dance_of_death_buff) < gcd() and spell(barbed_shot) or { buffremaining(aspect_of_the_wild) > 10 + gcd() or target.timetodie() < 10 + gcd() } and spell(blood_of_the_enemy) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or { buffexpires(bestial_wrath) or target.timetodie() < 5 } and spell(bag_of_tricks) or spell(chimaera_shot) or spell(dire_beast) or { hastalent(one_with_the_pack_talent) and charges(barbed_shot count=0) > 1.5 or charges(barbed_shot count=0) > 1.8 or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or target.timetodie() < 9 } and spell(barbed_shot) or { buffexpires(bestial_wrath) or target.timetodie() < 8 } and spell(purifying_blast) or spell(barrage) or { { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() and spellcooldown(bestial_wrath) > timetomaxfocus() or buffpresent(memory_of_lucid_dreams_buff) } and spellcooldown(kill_command) > 1 or target.timetodie() < 3 } and spell(cobra_shot) or baseduration(frenzy_buff) - gcd() > spellfullrecharge(barbed_shot) and spell(barbed_shot)
}

### actions.precombat

AddFunction beast_masteryprecombatmainactions
{
 #worldvein_resonance
 spell(worldvein_resonance)
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams)
}

AddFunction beast_masteryprecombatmainpostconditions
{
}

AddFunction beast_masteryprecombatshortcdactions
{
 #flask
 #augmentation
 #food
 #summon_pet
 beast_masterysummonpet()

 unless spell(worldvein_resonance) or spell(memory_of_lucid_dreams)
 {
  #focused_azerite_beam,if=!raid_event.invulnerable.exists
  if not false(raid_event_invulnerable_exists) and buffexpires(focused_azerite_beam_unused_0) spell(focused_azerite_beam)
  #bestial_wrath,precast_time=1.5,if=azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.cyclotronic_blast)
  if hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } spell(bestial_wrath)
 }
}

AddFunction beast_masteryprecombatshortcdpostconditions
{
 spell(worldvein_resonance) or spell(memory_of_lucid_dreams)
}

AddFunction beast_masteryprecombatcdactions
{
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 beast_masteryuseitemactions()

 unless spell(worldvein_resonance)
 {
  #guardian_of_azeroth
  spell(guardian_of_azeroth)

  unless spell(memory_of_lucid_dreams)
  {
   #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists&(trinket.1.has_cooldown+trinket.2.has_cooldown<2|equipped.variable_intensity_gigavolt_oscillating_reactor)
   if not false(raid_event_invulnerable_exists) and { { itemcooldown(trinket0slot) and itemcooldown(trinket1slot) } + { itemcooldown(trinket0slot) and itemcooldown(trinket1slot) } < 2 or hasequippeditem(variable_intensity_gigavolt_oscillating_reactor_item) } beast_masteryuseitemactions()

   unless not false(raid_event_invulnerable_exists) and buffexpires(focused_azerite_beam_unused_0) and spell(focused_azerite_beam)
   {
    #aspect_of_the_wild,precast_time=1.3,if=!azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.cyclotronic_blast)
    if not hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } spell(aspect_of_the_wild)

    unless hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } and spell(bestial_wrath)
    {
     #potion,dynamic_prepot=1
     if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
    }
   }
  }
 }
}

AddFunction beast_masteryprecombatcdpostconditions
{
 spell(worldvein_resonance) or spell(memory_of_lucid_dreams) or not false(raid_event_invulnerable_exists) and buffexpires(focused_azerite_beam_unused_0) and spell(focused_azerite_beam) or hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } and spell(bestial_wrath)
}

### actions.cleave

AddFunction beast_masterycleavemainactions
{
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd.max|cooldown.bestial_wrath.remains<12+gcd&talent.scent_of_blood.enabled
 if pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) <= gcd() or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) spell(barbed_shot)
 #multishot,if=gcd.max-pet.main.buff.beast_cleave.remains>0.25
 if gcd() - pet.buffremaining(beast_cleave_buff) > 0.25 spell(multishot)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd.max&cooldown.bestial_wrath.remains
 if spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 spell(barbed_shot)
 #chimaera_shot
 spell(chimaera_shot)
 #barrage
 spell(barrage)
 #kill_command,if=active_enemies<4|!azerite.rapid_reload.enabled
 if { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and { pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() } spell(kill_command)
 #dire_beast
 spell(dire_beast)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.main.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|charges_fractional>1.4|target.time_to_die<9
 if pet.buffexpires(frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath) } or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 spell(barbed_shot)
 #concentrated_flame
 spell(concentrated_flame)
 #blood_of_the_enemy
 spell(blood_of_the_enemy)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 spell(the_unbound_force)
 #multishot,if=azerite.rapid_reload.enabled&active_enemies>2
 if hasazeritetrait(rapid_reload_trait) and enemies() > 2 spell(multishot)
 #cobra_shot,if=cooldown.kill_command.remains>focus.time_to_max&(active_enemies<3|!azerite.rapid_reload.enabled)
 if spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } spell(cobra_shot)
}

AddFunction beast_masterycleavemainpostconditions
{
}

AddFunction beast_masterycleaveshortcdactions
{
 unless { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) <= gcd() or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or gcd() - pet.buffremaining(beast_cleave_buff) > 0.25 and spell(multishot) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot)
 {
  #bestial_wrath,if=talent.scent_of_blood.enabled|cooldown.aspect_of_the_wild.remains_guess>20|talent.one_with_the_pack.enabled|target.time_to_die<15
  if hastalent(scent_of_blood_talent_beast_mastery) or spellcooldown(aspect_of_the_wild) > 20 or hastalent(one_with_the_pack_talent) or target.timetodie() < 15 spell(bestial_wrath)

  unless spell(chimaera_shot)
  {
   #a_murder_of_crows
   spell(a_murder_of_crows)

   unless spell(barrage) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and { pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() } and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath) } or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot)
   {
    #focused_azerite_beam
    spell(focused_azerite_beam)
    #purifying_blast
    spell(purifying_blast)
   }
  }
 }
}

AddFunction beast_masterycleaveshortcdpostconditions
{
 { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) <= gcd() or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or gcd() - pet.buffremaining(beast_cleave_buff) > 0.25 and spell(multishot) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot) or spell(chimaera_shot) or spell(barrage) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and { pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() } and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath) } or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot) or spell(concentrated_flame) or spell(blood_of_the_enemy) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 } and spell(the_unbound_force) or hasazeritetrait(rapid_reload_trait) and enemies() > 2 and spell(multishot) or spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } and spell(cobra_shot)
}

AddFunction beast_masterycleavecdactions
{
 unless { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) <= gcd() or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or gcd() - pet.buffremaining(beast_cleave_buff) > 0.25 and spell(multishot) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot)
 {
  #aspect_of_the_wild
  spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if buffpresent(aspect_of_the_wild) and buffpresent(bestial_wrath) or target.timetodie() < 15 spell(stampede)
 }
}

AddFunction beast_masterycleavecdpostconditions
{
 { pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) <= gcd() or spellcooldown(bestial_wrath) < 12 + gcd() and hastalent(scent_of_blood_talent_beast_mastery) } and spell(barbed_shot) or gcd() - pet.buffremaining(beast_cleave_buff) > 0.25 and spell(multishot) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot) or { hastalent(scent_of_blood_talent_beast_mastery) or spellcooldown(aspect_of_the_wild) > 20 or hastalent(one_with_the_pack_talent) or target.timetodie() < 15 } and spell(bestial_wrath) or spell(chimaera_shot) or spell(a_murder_of_crows) or spell(barrage) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and { pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() } and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath) } or spellcooldown(aspect_of_the_wild) < baseduration(frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot) or spell(focused_azerite_beam) or spell(purifying_blast) or spell(concentrated_flame) or spell(blood_of_the_enemy) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 } and spell(the_unbound_force) or hasazeritetrait(rapid_reload_trait) and enemies() > 2 and spell(multishot) or spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } and spell(cobra_shot)
}

### actions.cds

AddFunction beast_masterycdsmainactions
{
 #berserking,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<13
 if buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 spell(berserking)
 #worldvein_resonance,if=(prev_gcd.1.aspect_of_the_wild|cooldown.aspect_of_the_wild.remains<gcd|target.time_to_die<20)|!essence.vision_of_perfection.minor
 if previousgcdspell(aspect_of_the_wild) or spellcooldown(aspect_of_the_wild) < gcd() or target.timetodie() < 20 or not azeriteessenceisminor(vision_of_perfection_essence_id) spell(worldvein_resonance)
 #ripple_in_space
 spell(ripple_in_space)
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams)
}

AddFunction beast_masterycdsmainpostconditions
{
}

AddFunction beast_masterycdsshortcdactions
{
 unless { buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 } and spell(berserking) or { previousgcdspell(aspect_of_the_wild) or spellcooldown(aspect_of_the_wild) < gcd() or target.timetodie() < 20 or not azeriteessenceisminor(vision_of_perfection_essence_id) } and spell(worldvein_resonance) or spell(ripple_in_space) or spell(memory_of_lucid_dreams)
 {
  #reaping_flames,if=target.health.pct>80|target.health.pct<=20|target.time_to_pct_20>30
  if target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 spell(reaping_flames)
 }
}

AddFunction beast_masterycdsshortcdpostconditions
{
 { buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 } and spell(berserking) or { previousgcdspell(aspect_of_the_wild) or spellcooldown(aspect_of_the_wild) < gcd() or target.timetodie() < 20 or not azeriteessenceisminor(vision_of_perfection_essence_id) } and spell(worldvein_resonance) or spell(ripple_in_space) or spell(memory_of_lucid_dreams)
}

AddFunction beast_masterycdscdactions
{
 #ancestral_call,if=cooldown.bestial_wrath.remains>30
 if spellcooldown(bestial_wrath) > 30 spell(ancestral_call)
 #fireblood,if=cooldown.bestial_wrath.remains>30
 if spellcooldown(bestial_wrath) > 30 spell(fireblood)

 unless { buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 } and spell(berserking)
 {
  #blood_fury,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<16
  if buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(blood_fury) + baseduration(blood_fury) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 16 spell(blood_fury)
  #lights_judgment,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains>gcd.max|!pet.main.buff.frenzy.up
  if pet.buffpresent(frenzy_buff) and pet.buffremaining(frenzy_buff) > gcd() or not pet.buffpresent(frenzy_buff) spell(lights_judgment)
  #potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up&target.health.pct<35|((consumable.potion_of_unbridled_fury|consumable.unbridled_fury)&target.time_to_die<61|target.time_to_die<26)
  if { buffpresent(bestial_wrath) and buffpresent(aspect_of_the_wild) and target.healthpercent() < 35 or { buffpresent(potion_of_unbridled_fury_buff) or buffpresent(potion_of_unbridled_fury_buff) } and target.timetodie() < 61 or target.timetodie() < 26 } and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(unbridled_fury_item usable=1)

  unless { previousgcdspell(aspect_of_the_wild) or spellcooldown(aspect_of_the_wild) < gcd() or target.timetodie() < 20 or not azeriteessenceisminor(vision_of_perfection_essence_id) } and spell(worldvein_resonance)
  {
   #guardian_of_azeroth,if=cooldown.aspect_of_the_wild.remains<10|target.time_to_die>cooldown+duration|target.time_to_die<30
   if spellcooldown(aspect_of_the_wild) < 10 or target.timetodie() > spellcooldown(guardian_of_azeroth) + baseduration(guardian_of_azeroth) or target.timetodie() < 30 spell(guardian_of_azeroth)
  }
 }
}

AddFunction beast_masterycdscdpostconditions
{
 { buffpresent(aspect_of_the_wild) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 } and spell(berserking) or { previousgcdspell(aspect_of_the_wild) or spellcooldown(aspect_of_the_wild) < gcd() or target.timetodie() < 20 or not azeriteessenceisminor(vision_of_perfection_essence_id) } and spell(worldvein_resonance) or spell(ripple_in_space) or spell(memory_of_lucid_dreams) or { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } and spell(reaping_flames)
}

### actions.default

AddFunction beast_mastery_defaultmainactions
{
 #call_action_list,name=cds
 beast_masterycdsmainactions()

 unless beast_masterycdsmainpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 beast_masterystmainactions()

  unless enemies() < 2 and beast_masterystmainpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 beast_masterycleavemainactions()
  }
 }
}

AddFunction beast_mastery_defaultmainpostconditions
{
 beast_masterycdsmainpostconditions() or enemies() < 2 and beast_masterystmainpostconditions() or enemies() > 1 and beast_masterycleavemainpostconditions()
}

AddFunction beast_mastery_defaultshortcdactions
{
 #call_action_list,name=cds
 beast_masterycdsshortcdactions()

 unless beast_masterycdsshortcdpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 beast_masterystshortcdactions()

  unless enemies() < 2 and beast_masterystshortcdpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 beast_masterycleaveshortcdactions()
  }
 }
}

AddFunction beast_mastery_defaultshortcdpostconditions
{
 beast_masterycdsshortcdpostconditions() or enemies() < 2 and beast_masterystshortcdpostconditions() or enemies() > 1 and beast_masterycleaveshortcdpostconditions()
}

AddFunction beast_mastery_defaultcdactions
{
 beast_masteryinterruptactions()
 #auto_shot
 #use_items,if=prev_gcd.1.aspect_of_the_wild|target.time_to_die<20
 if previousgcdspell(aspect_of_the_wild) or target.timetodie() < 20 beast_masteryuseitemactions()
 #use_item,name=azsharas_font_of_power,if=cooldown.aspect_of_the_wild.remains_guess<15&target.time_to_die>10
 if spellcooldown(aspect_of_the_wild) < 15 and target.timetodie() > 10 beast_masteryuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.up&(!equipped.azsharas_font_of_power|trinket.azsharas_font_of_power.cooldown.remains>86|essence.blood_of_the_enemy.major)&(prev_gcd.1.aspect_of_the_wild|!equipped.cyclotronic_blast&buff.aspect_of_the_wild.remains>9)&(!essence.condensed_lifeforce.major|buff.guardian_of_azeroth.up)&(target.health.pct<35|!essence.condensed_lifeforce.major|!talent.killer_instinct.enabled)|(debuff.razor_coral_debuff.down|target.time_to_die<26)&target.time_to_die>(24*(cooldown.cyclotronic_blast.remains+4<target.time_to_die))
 if target.debuffpresent(razor_coral_debuff) and { not hasequippeditem(azsharas_font_of_power_item) or buffcooldownduration(azsharas_font_of_power_item) > 86 or azeriteessenceismajor(blood_of_the_enemy_essence_id) } and { previousgcdspell(aspect_of_the_wild) or not hasequippeditem(cyclotronic_blast_item) and buffremaining(aspect_of_the_wild) > 9 } and { not azeriteessenceismajor(condensed_lifeforce_essence_id) or buffpresent(guardian_of_azeroth_buff) } and { target.healthpercent() < 35 or not azeriteessenceismajor(condensed_lifeforce_essence_id) or not hastalent(killer_instinct_talent) } or { target.debuffexpires(razor_coral_debuff) or target.timetodie() < 26 } and target.timetodie() > 24 * { spellcooldown(cyclotronic_blast) + 4 < target.timetodie() } beast_masteryuseitemactions()
 #use_item,effect_name=cyclotronic_blast,if=buff.bestial_wrath.down|target.time_to_die<5
 if buffexpires(bestial_wrath) or target.timetodie() < 5 beast_masteryuseitemactions()
 #call_action_list,name=cds
 beast_masterycdscdactions()

 unless beast_masterycdscdpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 beast_masterystcdactions()

  unless enemies() < 2 and beast_masterystcdpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 beast_masterycleavecdactions()
  }
 }
}

AddFunction beast_mastery_defaultcdpostconditions
{
 beast_masterycdscdpostconditions() or enemies() < 2 and beast_masterystcdpostconditions() or enemies() > 1 and beast_masterycleavecdpostconditions()
}

### Beastmastery icons.

AddCheckBox(opt_hunter_beast_mastery_aoe l(aoe) default enabled=(specialization(beast_mastery)))

AddIcon enabled=(not checkboxon(opt_hunter_beast_mastery_aoe) and specialization(beast_mastery)) enemies=1 help=shortcd
{
 if not incombat() beast_masteryprecombatshortcdactions()
 beast_mastery_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_beast_mastery_aoe) and specialization(beast_mastery)) help=shortcd
{
 if not incombat() beast_masteryprecombatshortcdactions()
 beast_mastery_defaultshortcdactions()
}

AddIcon enabled=(specialization(beast_mastery)) enemies=1 help=main
{
 if not incombat() beast_masteryprecombatmainactions()
 beast_mastery_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_beast_mastery_aoe) and specialization(beast_mastery)) help=aoe
{
 if not incombat() beast_masteryprecombatmainactions()
 beast_mastery_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_beast_mastery_aoe) and not specialization(beast_mastery)) enemies=1 help=cd
{
 if not incombat() beast_masteryprecombatcdactions()
 beast_mastery_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_beast_mastery_aoe) and specialization(beast_mastery)) help=cd
{
 if not incombat() beast_masteryprecombatcdactions()
 beast_mastery_defaultcdactions()
}

### Required symbols
# a_murder_of_crows
# ancestral_call
# aspect_of_the_wild
# azsharas_font_of_power_item
# bag_of_tricks
# barbed_shot
# barrage
# beast_cleave_buff
# berserking
# bestial_wrath
# blood_fury
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodshed
# chimaera_shot
# cobra_shot
# concentrated_flame
# concentrated_flame_burn_debuff
# condensed_lifeforce_essence_id
# counter_shot
# cyclotronic_blast
# cyclotronic_blast_item
# dance_of_death_buff
# dance_of_death_trait
# dire_beast
# essence_of_the_focusing_iris_essence_id
# fireblood
# focused_azerite_beam
# frenzy_buff
# guardian_of_azeroth
# guardian_of_azeroth_buff
# kill_command
# kill_shot
# killer_instinct_talent
# lights_judgment
# memory_of_lucid_dreams
# memory_of_lucid_dreams_buff
# multishot
# one_with_the_pack_talent
# potion_of_unbridled_fury_buff
# primal_instincts_trait
# purifying_blast
# quaking_palm
# rapid_reload_trait
# razor_coral_debuff
# reaping_flames
# reckless_force_buff
# reckless_force_counter
# revive_pet
# ripple_in_space
# scent_of_blood_talent_beast_mastery
# stampede
# the_unbound_force
# unbridled_fury_item
# variable_intensity_gigavolt_oscillating_reactor_item
# vision_of_perfection_essence_id
# war_stomp
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
    end
    do
        local name = "sc_t25_hunter_marksmanship"
        local desc = "[9.0] Simulationcraft: T25_Hunter_Marksmanship"
        local code = [[
# Based on SimulationCraft profile "T25_Hunter_Marksmanship".
#	class=hunter
#	spec=marksmanship
#	talents=1103031

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(marksmanship)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(marksmanship)))
AddCheckBox(opt_volley spellname(volley) default enabled=(specialization(marksmanship)))

AddFunction marksmanshipinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counter_shot) and target.isinterruptible() spell(counter_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction marksmanshipuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.trickshots

AddFunction marksmanshiptrickshotsmainactions
{
 #kill_shot
 spell(kill_shot)
 #barrage
 spell(barrage)
 #aimed_shot,if=buff.trick_shots.up&ca_active&buff.double_tap.up
 if buffpresent(trick_shots_buff) and { talent(careful_aim_talent) and target.healthpercent() > 70 } and buffpresent(double_tap) spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
 if buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } spell(rapid_fire)
 #aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time|buff.trueshot.up)
 if buffpresent(trick_shots_buff) and { buffexpires(precise_shots) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot) } spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up
 if buffpresent(trick_shots_buff) spell(rapid_fire)
 #multishot,if=buff.trick_shots.down|buff.precise_shots.up&!buff.trueshot.up|focus>70
 if buffexpires(trick_shots_buff) or buffpresent(precise_shots) and not buffpresent(trueshot) or focus() > 70 spell(multishot_marksmanship)
 #concentrated_flame
 spell(concentrated_flame)
 #blood_of_the_enemy,if=prev_gcd.1.volley|!talent.volley.enabled|target.time_to_die<11
 if previousgcdspell(volley) or not hastalent(volley_talent) or target.timetodie() < 11 spell(blood_of_the_enemy)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 spell(the_unbound_force)
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) spell(serpent_sting)
 #steady_shot
 spell(steady_shot)
}

AddFunction marksmanshiptrickshotsmainpostconditions
{
}

AddFunction marksmanshiptrickshotsshortcdactions
{
 unless spell(kill_shot)
 {
  #volley
  if checkboxon(opt_volley) spell(volley)

  unless spell(barrage)
  {
   #explosive_shot
   spell(explosive_shot)

   unless buffpresent(trick_shots_buff) and { talent(careful_aim_talent) and target.healthpercent() > 70 } and buffpresent(double_tap) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots) and not buffpresent(trueshot) or focus() > 70 } and spell(multishot_marksmanship)
   {
    #focused_azerite_beam
    spell(focused_azerite_beam)
    #purifying_blast
    spell(purifying_blast)

    unless spell(concentrated_flame) or { previousgcdspell(volley) or not hastalent(volley_talent) or target.timetodie() < 11 } and spell(blood_of_the_enemy) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 } and spell(the_unbound_force)
    {
     #a_murder_of_crows
     spell(a_murder_of_crows)
    }
   }
  }
 }
}

AddFunction marksmanshiptrickshotsshortcdpostconditions
{
 spell(kill_shot) or spell(barrage) or buffpresent(trick_shots_buff) and { talent(careful_aim_talent) and target.healthpercent() > 70 } and buffpresent(double_tap) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots) and not buffpresent(trueshot) or focus() > 70 } and spell(multishot_marksmanship) or spell(concentrated_flame) or { previousgcdspell(volley) or not hastalent(volley_talent) or target.timetodie() < 11 } and spell(blood_of_the_enemy) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 } and spell(the_unbound_force) or target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) and spell(serpent_sting) or spell(steady_shot)
}

AddFunction marksmanshiptrickshotscdactions
{
}

AddFunction marksmanshiptrickshotscdpostconditions
{
 spell(kill_shot) or checkboxon(opt_volley) and spell(volley) or spell(barrage) or spell(explosive_shot) or buffpresent(trick_shots_buff) and { talent(careful_aim_talent) and target.healthpercent() > 70 } and buffpresent(double_tap) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots) and not buffpresent(trueshot) or focus() > 70 } and spell(multishot_marksmanship) or spell(focused_azerite_beam) or spell(purifying_blast) or spell(concentrated_flame) or { previousgcdspell(volley) or not hastalent(volley_talent) or target.timetodie() < 11 } and spell(blood_of_the_enemy) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 } and spell(the_unbound_force) or spell(a_murder_of_crows) or target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) and spell(serpent_sting) or spell(steady_shot)
}

### actions.st

AddFunction marksmanshipstmainactions
{
 #steady_shot,if=talent.steady_focus.enabled&prev_gcd.1.steady_shot&buff.steady_focus.remains<5
 if hastalent(steady_focus_talent) and previousgcdspell(steady_shot) and buffremaining(steady_focus_buff) < 5 spell(steady_shot)
 #kill_shot
 spell(kill_shot)
 #barrage,if=active_enemies>1
 if enemies() > 1 spell(barrage)
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) spell(serpent_sting)
 #rapid_fire,if=buff.trueshot.down|focus<35|focus<60&!talent.lethal_shots.enabled|buff.in_the_rhythm.remains<execute_time
 if buffexpires(trueshot) or focus() < 35 or focus() < 60 and not hastalent(lethal_shots_talent) or buffremaining(in_the_rhythm) < executetime(rapid_fire) spell(rapid_fire)
 #blood_of_the_enemy,if=buff.trueshot.up&(buff.unerring_vision.stack>4|!azerite.unerring_vision.enabled)|target.time_to_die<11
 if buffpresent(trueshot) and { buffstacks(unerring_vision) > 4 or not hasazeritetrait(unerring_vision_trait) } or target.timetodie() < 11 spell(blood_of_the_enemy)
 #aimed_shot,if=buff.trueshot.up|(buff.double_tap.down|ca_active)&buff.precise_shots.down|full_recharge_time<cast_time&cooldown.trueshot.remains
 if buffpresent(trueshot) or { buffexpires(double_tap) or talent(careful_aim_talent) and target.healthpercent() > 70 } and buffexpires(precise_shots) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 spell(aimed_shot)
 #concentrated_flame,if=focus+focus.regen*gcd<focus.max&buff.trueshot.down&(!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight)|full_recharge_time<gcd|target.time_to_die<5
 if focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 spell(concentrated_flame)
 #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10|target.time_to_die<5
 if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 spell(the_unbound_force)
 #arcane_shot,if=buff.trueshot.down&(buff.precise_shots.up&(focus>55)|focus>75|target.time_to_die<5)
 if buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } spell(arcane_shot)
 #chimaera_shot,if=buff.trueshot.down&(buff.precise_shots.up&(focus>55)|focus>75|target.time_to_die<5)
 if buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } spell(chimaera_shot_marksmanship)
 #steady_shot
 spell(steady_shot)
}

AddFunction marksmanshipstmainpostconditions
{
}

AddFunction marksmanshipstshortcdactions
{
 unless hastalent(steady_focus_talent) and previousgcdspell(steady_shot) and buffremaining(steady_focus_buff) < 5 and spell(steady_shot) or spell(kill_shot)
 {
  #explosive_shot
  spell(explosive_shot)

  unless enemies() > 1 and spell(barrage)
  {
   #a_murder_of_crows
   spell(a_murder_of_crows)
   #volley
   if checkboxon(opt_volley) spell(volley)

   unless target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) and spell(serpent_sting) or { buffexpires(trueshot) or focus() < 35 or focus() < 60 and not hastalent(lethal_shots_talent) or buffremaining(in_the_rhythm) < executetime(rapid_fire) } and spell(rapid_fire) or { buffpresent(trueshot) and { buffstacks(unerring_vision) > 4 or not hasazeritetrait(unerring_vision_trait) } or target.timetodie() < 11 } and spell(blood_of_the_enemy)
   {
    #focused_azerite_beam,if=!buff.trueshot.up|target.time_to_die<5
    if not buffpresent(trueshot) or target.timetodie() < 5 spell(focused_azerite_beam)

    unless { buffpresent(trueshot) or { buffexpires(double_tap) or talent(careful_aim_talent) and target.healthpercent() > 70 } and buffexpires(precise_shots) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot)
    {
     #purifying_blast,if=!buff.trueshot.up|target.time_to_die<8
     if not buffpresent(trueshot) or target.timetodie() < 8 spell(purifying_blast)
    }
   }
  }
 }
}

AddFunction marksmanshipstshortcdpostconditions
{
 hastalent(steady_focus_talent) and previousgcdspell(steady_shot) and buffremaining(steady_focus_buff) < 5 and spell(steady_shot) or spell(kill_shot) or enemies() > 1 and spell(barrage) or target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) and spell(serpent_sting) or { buffexpires(trueshot) or focus() < 35 or focus() < 60 and not hastalent(lethal_shots_talent) or buffremaining(in_the_rhythm) < executetime(rapid_fire) } and spell(rapid_fire) or { buffpresent(trueshot) and { buffstacks(unerring_vision) > 4 or not hasazeritetrait(unerring_vision_trait) } or target.timetodie() < 11 } and spell(blood_of_the_enemy) or { buffpresent(trueshot) or { buffexpires(double_tap) or talent(careful_aim_talent) and target.healthpercent() > 70 } and buffexpires(precise_shots) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } and spell(arcane_shot) or buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } and spell(chimaera_shot_marksmanship) or spell(steady_shot)
}

AddFunction marksmanshipstcdactions
{
}

AddFunction marksmanshipstcdpostconditions
{
 hastalent(steady_focus_talent) and previousgcdspell(steady_shot) and buffremaining(steady_focus_buff) < 5 and spell(steady_shot) or spell(kill_shot) or spell(explosive_shot) or enemies() > 1 and spell(barrage) or spell(a_murder_of_crows) or checkboxon(opt_volley) and spell(volley) or target.refreshable(serpent_sting) and not inflighttotarget(serpent_sting) and spell(serpent_sting) or { buffexpires(trueshot) or focus() < 35 or focus() < 60 and not hastalent(lethal_shots_talent) or buffremaining(in_the_rhythm) < executetime(rapid_fire) } and spell(rapid_fire) or { buffpresent(trueshot) and { buffstacks(unerring_vision) > 4 or not hasazeritetrait(unerring_vision_trait) } or target.timetodie() < 11 } and spell(blood_of_the_enemy) or { not buffpresent(trueshot) or target.timetodie() < 5 } and spell(focused_azerite_beam) or { buffpresent(trueshot) or { buffexpires(double_tap) or talent(careful_aim_talent) and target.healthpercent() > 70 } and buffexpires(precise_shots) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot) or { not buffpresent(trueshot) or target.timetodie() < 8 } and spell(purifying_blast) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot) and not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) or spellfullrecharge(concentrated_flame) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } and spell(arcane_shot) or buffexpires(trueshot) and { buffpresent(precise_shots) and focus() > 55 or focus() > 75 or target.timetodie() < 5 } and spell(chimaera_shot_marksmanship) or spell(steady_shot)
}

### actions.precombat

AddFunction marksmanshipprecombatmainactions
{
 #worldvein_resonance
 spell(worldvein_resonance)
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams)
 #aimed_shot,if=active_enemies<3
 if enemies() < 3 spell(aimed_shot)
}

AddFunction marksmanshipprecombatmainpostconditions
{
}

AddFunction marksmanshipprecombatshortcdactions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #double_tap,precast_time=10
 spell(double_tap)
}

AddFunction marksmanshipprecombatshortcdpostconditions
{
 spell(worldvein_resonance) or spell(memory_of_lucid_dreams) or enemies() < 3 and spell(aimed_shot)
}

AddFunction marksmanshipprecombatcdactions
{
 unless spell(double_tap)
 {
  #use_item,name=azsharas_font_of_power
  marksmanshipuseitemactions()

  unless spell(worldvein_resonance)
  {
   #guardian_of_azeroth
   spell(guardian_of_azeroth)

   unless spell(memory_of_lucid_dreams)
   {
    #trueshot,precast_time=1.5,if=active_enemies>2
    if enemies() > 2 spell(trueshot)
    #potion,dynamic_prepot=1
    if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
   }
  }
 }
}

AddFunction marksmanshipprecombatcdpostconditions
{
 spell(double_tap) or spell(worldvein_resonance) or spell(memory_of_lucid_dreams) or enemies() < 3 and spell(aimed_shot)
}

### actions.cds

AddFunction marksmanshipcdsmainactions
{
 #berserking,if=buff.trueshot.remains>14&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<13
 if buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 spell(berserking)
 #worldvein_resonance,if=(trinket.azsharas_font_of_power.cooldown.remains>20|!equipped.azsharas_font_of_power|target.time_to_die<trinket.azsharas_font_of_power.cooldown.duration+34&target.health.pct>20)&(cooldown.trueshot.remains_guess<3|(essence.vision_of_perfection.minor&target.time_to_die>cooldown+buff.worldvein_resonance.duration))|target.time_to_die<20
 if { buffcooldownduration(azsharas_font_of_power_item) > 20 or not hasequippeditem(azsharas_font_of_power_item) or target.timetodie() < buffcooldownduration(azsharas_font_of_power_item) + 34 and target.healthpercent() > 20 } and { spellcooldown(trueshot) < 3 or azeriteessenceisminor(vision_of_perfection_essence_id) and target.timetodie() > spellcooldown(worldvein_resonance) + baseduration(worldvein_resonance_buff) } or target.timetodie() < 20 spell(worldvein_resonance)
 #ripple_in_space,if=cooldown.trueshot.remains<7
 if spellcooldown(trueshot) < 7 spell(ripple_in_space)
 #memory_of_lucid_dreams,if=!buff.trueshot.up
 if not buffpresent(trueshot) spell(memory_of_lucid_dreams)
}

AddFunction marksmanshipcdsmainpostconditions
{
}

AddFunction marksmanshipcdsshortcdactions
{
 #double_tap,if=cooldown.rapid_fire.remains<gcd|cooldown.rapid_fire.remains<cooldown.aimed_shot.remains|target.time_to_die<20
 if spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 spell(double_tap)

 unless { buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 } and spell(berserking)
 {
  #bag_of_tricks,if=buff.trueshot.down
  if buffexpires(trueshot) spell(bag_of_tricks)
  #reaping_flames,if=buff.trueshot.down&(target.health.pct>80|target.health.pct<=20|target.time_to_pct_20>30)
  if buffexpires(trueshot) and { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } spell(reaping_flames)
 }
}

AddFunction marksmanshipcdsshortcdpostconditions
{
 { buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 } and spell(berserking) or { { buffcooldownduration(azsharas_font_of_power_item) > 20 or not hasequippeditem(azsharas_font_of_power_item) or target.timetodie() < buffcooldownduration(azsharas_font_of_power_item) + 34 and target.healthpercent() > 20 } and { spellcooldown(trueshot) < 3 or azeriteessenceisminor(vision_of_perfection_essence_id) and target.timetodie() > spellcooldown(worldvein_resonance) + baseduration(worldvein_resonance_buff) } or target.timetodie() < 20 } and spell(worldvein_resonance) or spellcooldown(trueshot) < 7 and spell(ripple_in_space) or not buffpresent(trueshot) and spell(memory_of_lucid_dreams)
}

AddFunction marksmanshipcdscdactions
{
 unless { spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 } and spell(double_tap) or { buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 } and spell(berserking)
 {
  #blood_fury,if=buff.trueshot.remains>14&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(blood_fury) + baseduration(blood_fury) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 16 spell(blood_fury)
  #ancestral_call,if=buff.trueshot.remains>14&(target.time_to_die>cooldown.ancestral_call.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(ancestral_call) + baseduration(ancestral_call) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 16 spell(ancestral_call)
  #fireblood,if=buff.trueshot.remains>14&(target.time_to_die>cooldown.fireblood.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<9
  if buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(fireblood) + baseduration(fireblood) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 9 spell(fireblood)
  #lights_judgment,if=buff.trueshot.down
  if buffexpires(trueshot) spell(lights_judgment)

  unless buffexpires(trueshot) and spell(bag_of_tricks) or buffexpires(trueshot) and { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } and spell(reaping_flames) or { { buffcooldownduration(azsharas_font_of_power_item) > 20 or not hasequippeditem(azsharas_font_of_power_item) or target.timetodie() < buffcooldownduration(azsharas_font_of_power_item) + 34 and target.healthpercent() > 20 } and { spellcooldown(trueshot) < 3 or azeriteessenceisminor(vision_of_perfection_essence_id) and target.timetodie() > spellcooldown(worldvein_resonance) + baseduration(worldvein_resonance_buff) } or target.timetodie() < 20 } and spell(worldvein_resonance)
  {
   #guardian_of_azeroth,if=(ca_active|target.time_to_die>cooldown+30)&(buff.trueshot.up|cooldown.trueshot.remains<16)|target.time_to_die<31
   if { talent(careful_aim_talent) and target.healthpercent() > 70 or target.timetodie() > spellcooldown(guardian_of_azeroth) + 30 } and { buffpresent(trueshot) or spellcooldown(trueshot) < 16 } or target.timetodie() < 31 spell(guardian_of_azeroth)

   unless spellcooldown(trueshot) < 7 and spell(ripple_in_space) or not buffpresent(trueshot) and spell(memory_of_lucid_dreams)
   {
    #potion,if=buff.trueshot.react&buff.bloodlust.react|buff.trueshot.remains>14&target.health.pct<20|((consumable.potion_of_unbridled_fury|consumable.unbridled_fury)&target.time_to_die<61|target.time_to_die<26)
    if { buffpresent(trueshot) and buffpresent(bloodlust) or buffremaining(trueshot) > 14 and target.healthpercent() < 20 or { buffpresent(potion_of_unbridled_fury_buff) or buffpresent(potion_of_unbridled_fury_buff) } and target.timetodie() < 61 or target.timetodie() < 26 } and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(unbridled_fury_item usable=1)
    #trueshot,if=buff.trueshot.down&cooldown.rapid_fire.remains|target.time_to_die<15
    if buffexpires(trueshot) and spellcooldown(rapid_fire) > 0 or target.timetodie() < 15 spell(trueshot)
   }
  }
 }
}

AddFunction marksmanshipcdscdpostconditions
{
 { spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 } and spell(double_tap) or { buffremaining(trueshot) > 14 and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 } and spell(berserking) or buffexpires(trueshot) and spell(bag_of_tricks) or buffexpires(trueshot) and { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } and spell(reaping_flames) or { { buffcooldownduration(azsharas_font_of_power_item) > 20 or not hasequippeditem(azsharas_font_of_power_item) or target.timetodie() < buffcooldownduration(azsharas_font_of_power_item) + 34 and target.healthpercent() > 20 } and { spellcooldown(trueshot) < 3 or azeriteessenceisminor(vision_of_perfection_essence_id) and target.timetodie() > spellcooldown(worldvein_resonance) + baseduration(worldvein_resonance_buff) } or target.timetodie() < 20 } and spell(worldvein_resonance) or spellcooldown(trueshot) < 7 and spell(ripple_in_space) or not buffpresent(trueshot) and spell(memory_of_lucid_dreams)
}

### actions.default

AddFunction marksmanship_defaultmainactions
{
 #call_action_list,name=cds
 marksmanshipcdsmainactions()

 unless marksmanshipcdsmainpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 marksmanshipstmainactions()

  unless enemies() < 3 and marksmanshipstmainpostconditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 marksmanshiptrickshotsmainactions()
  }
 }
}

AddFunction marksmanship_defaultmainpostconditions
{
 marksmanshipcdsmainpostconditions() or enemies() < 3 and marksmanshipstmainpostconditions() or enemies() > 2 and marksmanshiptrickshotsmainpostconditions()
}

AddFunction marksmanship_defaultshortcdactions
{
 #call_action_list,name=cds
 marksmanshipcdsshortcdactions()

 unless marksmanshipcdsshortcdpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 marksmanshipstshortcdactions()

  unless enemies() < 3 and marksmanshipstshortcdpostconditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 marksmanshiptrickshotsshortcdactions()
  }
 }
}

AddFunction marksmanship_defaultshortcdpostconditions
{
 marksmanshipcdsshortcdpostconditions() or enemies() < 3 and marksmanshipstshortcdpostconditions() or enemies() > 2 and marksmanshiptrickshotsshortcdpostconditions()
}

AddFunction marksmanship_defaultcdactions
{
 marksmanshipinterruptactions()
 #auto_shot
 #use_item,name=lurkers_insidious_gift,if=cooldown.trueshot.remains_guess<15|target.time_to_die<30
 if spellcooldown(trueshot) < 15 or target.timetodie() < 30 marksmanshipuseitemactions()
 #use_item,name=azsharas_font_of_power,if=(target.time_to_die>cooldown+34|target.health.pct<20|target.time_to_pct_20<15)&cooldown.trueshot.remains_guess<15|target.time_to_die<35
 if { target.timetodie() > itemcooldown(trinket0slot) + 34 or target.healthpercent() < 20 or target.timetohealthpercent(20) < 15 } and spellcooldown(trueshot) < 15 or target.timetodie() < 35 marksmanshipuseitemactions()
 #use_item,name=lustrous_golden_plumage,if=cooldown.trueshot.remains_guess<5|target.time_to_die<20
 if spellcooldown(trueshot) < 5 or target.timetodie() < 20 marksmanshipuseitemactions()
 #use_item,name=galecallers_boon,if=buff.trueshot.remains>14|!talent.calling_the_shots.enabled|target.time_to_die<10
 if buffremaining(trueshot) > 14 or not hastalent(calling_the_shots_talent) or target.timetodie() < 10 marksmanshipuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=buff.trueshot.remains>14&(buff.guardian_of_azeroth.up|!essence.condensed_lifeforce.major&ca_active)|debuff.razor_coral_debuff.down|target.time_to_die<20
 if buffremaining(trueshot) > 14 and { buffpresent(guardian_of_azeroth_buff) or not azeriteessenceismajor(condensed_lifeforce_essence_id) and { talent(careful_aim_talent) and target.healthpercent() > 70 } } or target.debuffexpires(razor_coral_debuff) or target.timetodie() < 20 marksmanshipuseitemactions()
 #use_item,name=pocketsized_computation_device,if=!buff.trueshot.up&!essence.blood_of_the_enemy.major|debuff.blood_of_the_enemy.up|target.time_to_die<5
 if not buffpresent(trueshot) and not azeriteessenceismajor(blood_of_the_enemy_essence_id) or target.debuffpresent(blood_of_the_enemy_debuff) or target.timetodie() < 5 marksmanshipuseitemactions()
 #use_items,if=buff.trueshot.remains>14|!talent.calling_the_shots.enabled|target.time_to_die<20
 if buffremaining(trueshot) > 14 or not hastalent(calling_the_shots_talent) or target.timetodie() < 20 marksmanshipuseitemactions()
 #call_action_list,name=cds
 marksmanshipcdscdactions()

 unless marksmanshipcdscdpostconditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 marksmanshipstcdactions()

  unless enemies() < 3 and marksmanshipstcdpostconditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 marksmanshiptrickshotscdactions()
  }
 }
}

AddFunction marksmanship_defaultcdpostconditions
{
 marksmanshipcdscdpostconditions() or enemies() < 3 and marksmanshipstcdpostconditions() or enemies() > 2 and marksmanshiptrickshotscdpostconditions()
}

### Marksmanship icons.

AddCheckBox(opt_hunter_marksmanship_aoe l(aoe) default enabled=(specialization(marksmanship)))

AddIcon enabled=(not checkboxon(opt_hunter_marksmanship_aoe) and specialization(marksmanship)) enemies=1 help=shortcd
{
 if not incombat() marksmanshipprecombatshortcdactions()
 marksmanship_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_marksmanship_aoe) and specialization(marksmanship)) help=shortcd
{
 if not incombat() marksmanshipprecombatshortcdactions()
 marksmanship_defaultshortcdactions()
}

AddIcon enabled=(specialization(marksmanship)) enemies=1 help=main
{
 if not incombat() marksmanshipprecombatmainactions()
 marksmanship_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_marksmanship_aoe) and specialization(marksmanship)) help=aoe
{
 if not incombat() marksmanshipprecombatmainactions()
 marksmanship_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_marksmanship_aoe) and not specialization(marksmanship)) enemies=1 help=cd
{
 if not incombat() marksmanshipprecombatcdactions()
 marksmanship_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_marksmanship_aoe) and specialization(marksmanship)) help=cd
{
 if not incombat() marksmanshipprecombatcdactions()
 marksmanship_defaultcdactions()
}

### Required symbols
# a_murder_of_crows
# aimed_shot
# ancestral_call
# arcane_shot
# azsharas_font_of_power_item
# bag_of_tricks
# barrage
# berserking
# blood_fury
# blood_of_the_enemy
# blood_of_the_enemy_debuff
# blood_of_the_enemy_essence_id
# bloodlust
# calling_the_shots_talent
# careful_aim_talent
# chimaera_shot_marksmanship
# concentrated_flame
# concentrated_flame_burn_debuff
# condensed_lifeforce_essence_id
# counter_shot
# double_tap
# explosive_shot
# fireblood
# focused_azerite_beam
# focused_fire_trait
# guardian_of_azeroth
# guardian_of_azeroth_buff
# in_the_rhythm
# in_the_rhythm_trait
# kill_shot
# lethal_shots_talent
# lights_judgment
# memory_of_lucid_dreams
# multishot_marksmanship
# potion_of_unbridled_fury_buff
# precise_shots
# purifying_blast
# quaking_palm
# rapid_fire
# razor_coral_debuff
# reaping_flames
# reckless_force_buff
# reckless_force_counter
# ripple_in_space
# serpent_sting
# steady_focus_buff
# steady_focus_talent
# steady_shot
# streamline_talent
# surging_shots_trait
# the_unbound_force
# trick_shots_buff
# trueshot
# unbridled_fury_item
# unerring_vision
# unerring_vision_trait
# vision_of_perfection_essence_id
# volley
# volley_talent
# war_stomp
# worldvein_resonance
# worldvein_resonance_buff
]]
        OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
    end
    do
        local name = "sc_t25_hunter_survival"
        local desc = "[9.0] Simulationcraft: T25_Hunter_Survival"
        local code = [[
# Based on SimulationCraft profile "T25_Hunter_Survival".
#	class=hunter
#	spec=survival
#	talents=1101021

Include(ovale_common)
Include(ovale_hunter_spells)


AddFunction carve_cdr
{
 if enemies() < 5 enemies()
 unless enemies() < 5 5
}

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(survival)))
AddCheckBox(opt_melee_range l(not_in_melee_range) enabled=(specialization(survival)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(survival)))
AddCheckBox(opt_harpoon spellname(harpoon) default enabled=(specialization(survival)))

AddFunction survivalinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(muzzle) and target.isinterruptible() spell(muzzle)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction survivaluseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction survivalsummonpet
{
 if not pet.present() and not pet.isdead() and not previousspell(revive_pet) texture(ability_hunter_beastcall help=(l(summon_pet)))
}

AddFunction survivalgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(raptor_strike) texture(misc_arrowlup help=(l(not_in_melee_range)))
}

### actions.wfi

AddFunction survivalwfimainactions
{
 #kill_shot
 spell(kill_shot)
 #harpoon,if=focus+cast_regen<focus.max&talent.terms_of_engagement.enabled
 if focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up&buff.vipers_venom.remains<1.5*gcd|!dot.serpent_sting.ticking
 if buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.debuffpresent(serpent_sting) spell(serpent_sting)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max|(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 spell(wildfire_bomb)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max-focus.regen
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() spell(kill_command_survival)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd
 if buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() spell(serpent_sting)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking|buff.mongoose_fury.stack=5
 if target.debuffpresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury) == 5 spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&dot.serpent_sting.remains>5*gcd
 if buffpresent(shrapnel_bomb) and target.debuffremaining(serpent_sting) > 5 * gcd() spell(wildfire_bomb)
 #serpent_sting,if=refreshable
 if target.refreshable(serpent_sting) spell(serpent_sting)
 #chakrams,if=!buff.mongoose_fury.remains
 if not buffpresent(mongoose_fury) spell(chakrams)
 #mongoose_bite
 spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up
 if buffpresent(vipers_venom_buff) spell(serpent_sting)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel
 if buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) spell(wildfire_bomb)
}

AddFunction survivalwfimainpostconditions
{
}

AddFunction survivalwfishortcdactions
{
 unless spell(kill_shot) or focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.debuffpresent(serpent_sting) } and spell(serpent_sting) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival)
 {
  #a_murder_of_crows
  spell(a_murder_of_crows)
  #steel_trap,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)
 }
}

AddFunction survivalwfishortcdpostconditions
{
 spell(kill_shot) or focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.debuffpresent(serpent_sting) } and spell(serpent_sting) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() and spell(serpent_sting) or { target.debuffpresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury) == 5 } and spell(mongoose_bite) or buffpresent(shrapnel_bomb) and target.debuffremaining(serpent_sting) > 5 * gcd() and spell(wildfire_bomb) or target.refreshable(serpent_sting) and spell(serpent_sting) or not buffpresent(mongoose_fury) and spell(chakrams) or spell(mongoose_bite) or spell(raptor_strike) or buffpresent(vipers_venom_buff) and spell(serpent_sting) or { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) } and spell(wildfire_bomb)
}

AddFunction survivalwficdactions
{
 unless spell(kill_shot) or focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.debuffpresent(serpent_sting) } and spell(serpent_sting) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spell(a_murder_of_crows) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction survivalwficdpostconditions
{
 spell(kill_shot) or focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.debuffpresent(serpent_sting) } and spell(serpent_sting) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spell(a_murder_of_crows) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() and spell(serpent_sting) or { target.debuffpresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury) == 5 } and spell(mongoose_bite) or buffpresent(shrapnel_bomb) and target.debuffremaining(serpent_sting) > 5 * gcd() and spell(wildfire_bomb) or target.refreshable(serpent_sting) and spell(serpent_sting) or not buffpresent(mongoose_fury) and spell(chakrams) or spell(mongoose_bite) or spell(raptor_strike) or buffpresent(vipers_venom_buff) and spell(serpent_sting) or { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) } and spell(wildfire_bomb)
}

### actions.st

AddFunction survivalstmainactions
{
 #kill_shot
 spell(kill_shot)
 #harpoon,if=talent.terms_of_engagement.enabled
 if hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } spell(raptor_strike)
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } spell(mongoose_bite)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() spell(kill_command_survival)
 #serpent_sting,if=buff.vipers_venom.up&buff.vipers_venom.remains<1*gcd
 if buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1 * gcd() spell(serpent_sting)
 #wildfire_bomb,if=focus+cast_regen<focus.max&refreshable&full_recharge_time<gcd&!buff.memory_of_lucid_dreams.up|focus+cast_regen<focus.max&(!dot.wildfire_bomb.ticking&(!buff.coordinated_assault.up|buff.mongoose_fury.stack<1|time_to_die<18|!dot.wildfire_bomb.ticking&azerite.wilderness_survival.rank>0))&!buff.memory_of_lucid_dreams.up
 if focus() + focuscastingregen(wildfire_bomb) < maxfocus() and target.refreshable(wildfire_bomb_debuff) and spellfullrecharge(wildfire_bomb) < gcd() and not buffpresent(memory_of_lucid_dreams_buff) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and { not buffpresent(coordinated_assault) or buffstacks(mongoose_fury) < 1 or target.timetodie() < 18 or not target.debuffpresent(wildfire_bomb_debuff) and azeritetraitrank(wilderness_survival_trait) > 0 } and not buffpresent(memory_of_lucid_dreams_buff) spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd|dot.serpent_sting.refreshable&!buff.coordinated_assault.up
 if buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() or target.debuffrefreshable(serpent_sting) and not buffpresent(coordinated_assault) spell(serpent_sting)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-20&talent.vipers_venom.enabled|focus+cast_regen>focus.max-1&talent.terms_of_engagement.enabled|buff.coordinated_assault.up
 if buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault) spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable
 if target.debuffrefreshable(wildfire_bomb_debuff) spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up
 if buffpresent(vipers_venom_buff) spell(serpent_sting)
}

AddFunction survivalstmainpostconditions
{
}

AddFunction survivalstshortcdactions
{
 unless spell(kill_shot) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

  unless buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1 * gcd() and spell(serpent_sting)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)

   unless { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and target.refreshable(wildfire_bomb_debuff) and spellfullrecharge(wildfire_bomb) < gcd() and not buffpresent(memory_of_lucid_dreams_buff) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and { not buffpresent(coordinated_assault) or buffstacks(mongoose_fury) < 1 or target.timetodie() < 18 or not target.debuffpresent(wildfire_bomb_debuff) and azeritetraitrank(wilderness_survival_trait) > 0 } and not buffpresent(memory_of_lucid_dreams_buff) } and spell(wildfire_bomb) or { buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() or target.debuffrefreshable(serpent_sting) and not buffpresent(coordinated_assault) } and spell(serpent_sting)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not buffpresent(coordinated_assault) spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction survivalstshortcdpostconditions
{
 spell(kill_shot) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1 * gcd() and spell(serpent_sting) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and target.refreshable(wildfire_bomb_debuff) and spellfullrecharge(wildfire_bomb) < gcd() and not buffpresent(memory_of_lucid_dreams_buff) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and { not buffpresent(coordinated_assault) or buffstacks(mongoose_fury) < 1 or target.timetodie() < 18 or not target.debuffpresent(wildfire_bomb_debuff) and azeritetraitrank(wilderness_survival_trait) > 0 } and not buffpresent(memory_of_lucid_dreams_buff) } and spell(wildfire_bomb) or { buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() or target.debuffrefreshable(serpent_sting) and not buffpresent(coordinated_assault) } and spell(serpent_sting) or { buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault) } and spell(mongoose_bite) or spell(raptor_strike) or target.debuffrefreshable(wildfire_bomb_debuff) and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting)
}

AddFunction survivalstcdactions
{
 unless spell(kill_shot) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1 * gcd() and spell(serpent_sting) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and target.refreshable(wildfire_bomb_debuff) and spellfullrecharge(wildfire_bomb) < gcd() and not buffpresent(memory_of_lucid_dreams_buff) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and { not buffpresent(coordinated_assault) or buffstacks(mongoose_fury) < 1 or target.timetodie() < 18 or not target.debuffpresent(wildfire_bomb_debuff) and azeritetraitrank(wilderness_survival_trait) > 0 } and not buffpresent(memory_of_lucid_dreams_buff) } and spell(wildfire_bomb) or { buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() or target.debuffrefreshable(serpent_sting) and not buffpresent(coordinated_assault) } and spell(serpent_sting) or not buffpresent(coordinated_assault) and spell(a_murder_of_crows)
 {
  #coordinated_assault,if=!buff.coordinated_assault.up
  if not buffpresent(coordinated_assault) spell(coordinated_assault)
 }
}

AddFunction survivalstcdpostconditions
{
 spell(kill_shot) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1 * gcd() and spell(serpent_sting) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and target.refreshable(wildfire_bomb_debuff) and spellfullrecharge(wildfire_bomb) < gcd() and not buffpresent(memory_of_lucid_dreams_buff) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and { not buffpresent(coordinated_assault) or buffstacks(mongoose_fury) < 1 or target.timetodie() < 18 or not target.debuffpresent(wildfire_bomb_debuff) and azeritetraitrank(wilderness_survival_trait) > 0 } and not buffpresent(memory_of_lucid_dreams_buff) } and spell(wildfire_bomb) or { buffpresent(vipers_venom_buff) and target.debuffremaining(serpent_sting) < 4 * gcd() or target.debuffrefreshable(serpent_sting) and not buffpresent(coordinated_assault) } and spell(serpent_sting) or not buffpresent(coordinated_assault) and spell(a_murder_of_crows) or { buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault) } and spell(mongoose_bite) or spell(raptor_strike) or target.debuffrefreshable(wildfire_bomb_debuff) and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting)
}

### actions.precombat

AddFunction survivalprecombatmainactions
{
 #worldvein_resonance
 spell(worldvein_resonance)
 #harpoon
 if checkboxon(opt_harpoon) spell(harpoon)
}

AddFunction survivalprecombatmainpostconditions
{
}

AddFunction survivalprecombatshortcdactions
{
 #flask
 #augmentation
 #food
 #summon_pet
 survivalsummonpet()

 unless spell(worldvein_resonance)
 {
  #steel_trap
  spell(steel_trap)
 }
}

AddFunction survivalprecombatshortcdpostconditions
{
 spell(worldvein_resonance) or checkboxon(opt_harpoon) and spell(harpoon)
}

AddFunction survivalprecombatcdactions
{
 #snapshot_stats
 #use_item,name=azsharas_font_of_power
 survivaluseitemactions()
 #guardian_of_azeroth
 spell(guardian_of_azeroth)
 #coordinated_assault
 spell(coordinated_assault)

 unless spell(worldvein_resonance)
 {
  #potion,dynamic_prepot=1
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction survivalprecombatcdpostconditions
{
 spell(worldvein_resonance) or spell(steel_trap) or checkboxon(opt_harpoon) and spell(harpoon)
}

### actions.cleave

AddFunction survivalcleavemainactions
{
 #variable,name=carve_cdr,op=setif,value=active_enemies,value_else=5,condition=active_enemies<5
 #mongoose_bite,if=azerite.blur_of_talons.rank>0&(buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd|buff.coordinated_assault.remains&!buff.blur_of_talons.remains))
 if azeritetraitrank(blur_of_talons_trait) > 0 and buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() or buffpresent(coordinated_assault) and not buffpresent(blur_of_talons) } spell(mongoose_bite)
 #mongoose_bite,target_if=min:time_to_die,if=debuff.latent_poison.stack>(active_enemies|9)&target.time_to_die<active_enemies*gcd
 if target.debuffstacks(latent_poison) > { enemies() or 9 } and target.timetodie() < enemies() * gcd() spell(mongoose_bite)
 #carve,if=dot.shrapnel_bomb.ticking&!talent.hydras_bite.enabled|dot.shrapnel_bomb.ticking&active_enemies>5
 if target.debuffpresent(shrapnel_bomb_debuff) and not hastalent(hydras_bite_talent) or target.debuffpresent(shrapnel_bomb_debuff) and enemies() > 5 spell(carve)
 #wildfire_bomb,if=!talent.guerrilla_tactics.enabled|full_recharge_time<gcd|raid_event.adds.remains<6&raid_event.adds.exists
 if not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() or 0 < 6 and false(raid_event_adds_exists) spell(wildfire_bomb)
 #butchery,if=charges_fractional>2.5|dot.shrapnel_bomb.ticking|cooldown.wildfire_bomb.remains>active_enemies-gcd|debuff.blood_of_the_enemy.remains|raid_event.adds.remains<5&raid_event.adds.exists
 if charges(butchery count=0) > 2.5 or target.debuffpresent(shrapnel_bomb_debuff) or spellcooldown(wildfire_bomb) > enemies() - gcd() or target.debuffpresent(blood_of_the_enemy_debuff) or 0 < 5 and false(raid_event_adds_exists) spell(butchery)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8
 if target.debuffstacks(latent_poison) > 8 spell(mongoose_bite)
 #chakrams
 spell(chakrams)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() spell(kill_command_survival)
 #harpoon,if=talent.terms_of_engagement.enabled
 if hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #carve,if=talent.guerrilla_tactics.enabled
 if hastalent(guerrilla_tactics_talent) spell(carve)
 #butchery,if=cooldown.wildfire_bomb.remains>(active_enemies|5)
 if spellcooldown(wildfire_bomb) > { enemies() or 5 } spell(butchery)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable|talent.wildfire_infusion.enabled
 if target.debuffrefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) spell(wildfire_bomb)
 #serpent_sting,target_if=min:remains,if=buff.vipers_venom.react
 if buffpresent(vipers_venom_buff) spell(serpent_sting)
 #carve,if=cooldown.wildfire_bomb.remains>variable.carve_cdr%2
 if spellcooldown(wildfire_bomb) > carve_cdr() / 2 spell(carve)
 #serpent_sting,target_if=min:remains,if=refreshable&buff.tip_of_the_spear.stack<3&next_wi_bomb.volatile|refreshable&azerite.latent_poison.rank>0
 if target.refreshable(serpent_sting) and buffstacks(tip_of_the_spear_buff) < 3 and buffpresent(volatile_bomb) or target.refreshable(serpent_sting) and azeritetraitrank(latent_poison_trait) > 0 spell(serpent_sting)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack
 spell(mongoose_bite)
 #raptor_strike,target_if=max:debuff.latent_poison.stack
 spell(raptor_strike)
}

AddFunction survivalcleavemainpostconditions
{
}

AddFunction survivalcleaveshortcdactions
{
 unless azeritetraitrank(blur_of_talons_trait) > 0 and buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() or buffpresent(coordinated_assault) and not buffpresent(blur_of_talons) } and spell(mongoose_bite) or target.debuffstacks(latent_poison) > { enemies() or 9 } and target.timetodie() < enemies() * gcd() and spell(mongoose_bite)
 {
  #a_murder_of_crows
  spell(a_murder_of_crows)

  unless { target.debuffpresent(shrapnel_bomb_debuff) and not hastalent(hydras_bite_talent) or target.debuffpresent(shrapnel_bomb_debuff) and enemies() > 5 } and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() or 0 < 6 and false(raid_event_adds_exists) } and spell(wildfire_bomb) or { charges(butchery count=0) > 2.5 or target.debuffpresent(shrapnel_bomb_debuff) or spellcooldown(wildfire_bomb) > enemies() - gcd() or target.debuffpresent(blood_of_the_enemy_debuff) or 0 < 5 and false(raid_event_adds_exists) } and spell(butchery) or target.debuffstacks(latent_poison) > 8 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or hastalent(guerrilla_tactics_talent) and spell(carve) or spellcooldown(wildfire_bomb) > { enemies() or 5 } and spell(butchery)
  {
   #flanking_strike,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

   unless { target.debuffrefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting) or spellcooldown(wildfire_bomb) > carve_cdr() / 2 and spell(carve)
   {
    #steel_trap
    spell(steel_trap)
   }
  }
 }
}

AddFunction survivalcleaveshortcdpostconditions
{
 azeritetraitrank(blur_of_talons_trait) > 0 and buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() or buffpresent(coordinated_assault) and not buffpresent(blur_of_talons) } and spell(mongoose_bite) or target.debuffstacks(latent_poison) > { enemies() or 9 } and target.timetodie() < enemies() * gcd() and spell(mongoose_bite) or { target.debuffpresent(shrapnel_bomb_debuff) and not hastalent(hydras_bite_talent) or target.debuffpresent(shrapnel_bomb_debuff) and enemies() > 5 } and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() or 0 < 6 and false(raid_event_adds_exists) } and spell(wildfire_bomb) or { charges(butchery count=0) > 2.5 or target.debuffpresent(shrapnel_bomb_debuff) or spellcooldown(wildfire_bomb) > enemies() - gcd() or target.debuffpresent(blood_of_the_enemy_debuff) or 0 < 5 and false(raid_event_adds_exists) } and spell(butchery) or target.debuffstacks(latent_poison) > 8 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or hastalent(guerrilla_tactics_talent) and spell(carve) or spellcooldown(wildfire_bomb) > { enemies() or 5 } and spell(butchery) or { target.debuffrefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting) or spellcooldown(wildfire_bomb) > carve_cdr() / 2 and spell(carve) or { target.refreshable(serpent_sting) and buffstacks(tip_of_the_spear_buff) < 3 and buffpresent(volatile_bomb) or target.refreshable(serpent_sting) and azeritetraitrank(latent_poison_trait) > 0 } and spell(serpent_sting) or spell(mongoose_bite) or spell(raptor_strike)
}

AddFunction survivalcleavecdactions
{
 unless azeritetraitrank(blur_of_talons_trait) > 0 and buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() or buffpresent(coordinated_assault) and not buffpresent(blur_of_talons) } and spell(mongoose_bite) or target.debuffstacks(latent_poison) > { enemies() or 9 } and target.timetodie() < enemies() * gcd() and spell(mongoose_bite) or spell(a_murder_of_crows)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction survivalcleavecdpostconditions
{
 azeritetraitrank(blur_of_talons_trait) > 0 and buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() or buffpresent(coordinated_assault) and not buffpresent(blur_of_talons) } and spell(mongoose_bite) or target.debuffstacks(latent_poison) > { enemies() or 9 } and target.timetodie() < enemies() * gcd() and spell(mongoose_bite) or spell(a_murder_of_crows) or { target.debuffpresent(shrapnel_bomb_debuff) and not hastalent(hydras_bite_talent) or target.debuffpresent(shrapnel_bomb_debuff) and enemies() > 5 } and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() or 0 < 6 and false(raid_event_adds_exists) } and spell(wildfire_bomb) or { charges(butchery count=0) > 2.5 or target.debuffpresent(shrapnel_bomb_debuff) or spellcooldown(wildfire_bomb) > enemies() - gcd() or target.debuffpresent(blood_of_the_enemy_debuff) or 0 < 5 and false(raid_event_adds_exists) } and spell(butchery) or target.debuffstacks(latent_poison) > 8 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or hastalent(guerrilla_tactics_talent) and spell(carve) or spellcooldown(wildfire_bomb) > { enemies() or 5 } and spell(butchery) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or { target.debuffrefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting) or spellcooldown(wildfire_bomb) > carve_cdr() / 2 and spell(carve) or spell(steel_trap) or { target.refreshable(serpent_sting) and buffstacks(tip_of_the_spear_buff) < 3 and buffpresent(volatile_bomb) or target.refreshable(serpent_sting) and azeritetraitrank(latent_poison_trait) > 0 } and spell(serpent_sting) or spell(mongoose_bite) or spell(raptor_strike)
}

### actions.cds

AddFunction survivalcdsmainactions
{
 #berserking,if=cooldown.coordinated_assault.remains>60|time_to_die<13
 if spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 spell(berserking)
 #blood_of_the_enemy,if=((raid_event.adds.remains>90|!raid_event.adds.exists)|(active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2))&focus<focus.max
 if { 0 > 90 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() spell(blood_of_the_enemy)
 #ripple_in_space
 spell(ripple_in_space)
 #concentrated_flame,if=full_recharge_time<1*gcd
 if spellfullrecharge(concentrated_flame) < 1 * gcd() spell(concentrated_flame)
 #the_unbound_force,if=buff.reckless_force.up
 if buffpresent(reckless_force_buff) spell(the_unbound_force)
 #worldvein_resonance
 spell(worldvein_resonance)
 #serpent_sting,if=essence.memory_of_lucid_dreams.major&refreshable&buff.vipers_venom.up&!cooldown.memory_of_lucid_dreams.remains
 if azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.refreshable(serpent_sting) and buffpresent(vipers_venom_buff) and not spellcooldown(memory_of_lucid_dreams) > 0 spell(serpent_sting)
 #mongoose_bite,if=essence.memory_of_lucid_dreams.major&!cooldown.memory_of_lucid_dreams.remains
 if azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and not spellcooldown(memory_of_lucid_dreams) > 0 spell(mongoose_bite)
 #wildfire_bomb,if=essence.memory_of_lucid_dreams.major&full_recharge_time<1.5*gcd&focus<action.mongoose_bite.cost&!cooldown.memory_of_lucid_dreams.remains
 if azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() < powercost(mongoose_bite) and not spellcooldown(memory_of_lucid_dreams) > 0 spell(wildfire_bomb)
 #memory_of_lucid_dreams,if=focus<action.mongoose_bite.cost&buff.coordinated_assault.up
 if focus() < powercost(mongoose_bite) and buffpresent(coordinated_assault) spell(memory_of_lucid_dreams)
}

AddFunction survivalcdsmainpostconditions
{
}

AddFunction survivalcdsshortcdactions
{
 unless { spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 } and spell(berserking)
 {
  #aspect_of_the_eagle,if=target.distance>=6
  if target.distance() >= 6 spell(aspect_of_the_eagle)
  #focused_azerite_beam,if=raid_event.adds.in>90&focus<focus.max-25|(active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2)&(buff.blur_of_talons.up&buff.blur_of_talons.remains>3*gcd|!buff.blur_of_talons.up)
  if 600 > 90 and focus() < maxfocus() - 25 or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and { buffpresent(blur_of_talons) and buffremaining(blur_of_talons) > 3 * gcd() or not buffpresent(blur_of_talons) } spell(focused_azerite_beam)

  unless { 0 > 90 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(blood_of_the_enemy)
  {
   #purifying_blast,if=((raid_event.adds.remains>60|!raid_event.adds.exists)|(active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2))&focus<focus.max
   if { 0 > 60 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() spell(purifying_blast)

   unless spell(ripple_in_space) or spellfullrecharge(concentrated_flame) < 1 * gcd() and spell(concentrated_flame) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance)
   {
    #reaping_flames,if=target.health.pct>80|target.health.pct<=20|target.time_to_pct_20>30
    if target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 spell(reaping_flames)
   }
  }
 }
}

AddFunction survivalcdsshortcdpostconditions
{
 { spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 } and spell(berserking) or { 0 > 90 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(blood_of_the_enemy) or spell(ripple_in_space) or spellfullrecharge(concentrated_flame) < 1 * gcd() and spell(concentrated_flame) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.refreshable(serpent_sting) and buffpresent(vipers_venom_buff) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(serpent_sting) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(mongoose_bite) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() < powercost(mongoose_bite) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(wildfire_bomb) or focus() < powercost(mongoose_bite) and buffpresent(coordinated_assault) and spell(memory_of_lucid_dreams)
}

AddFunction survivalcdscdactions
{
 #blood_fury,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(blood_fury)
 #ancestral_call,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(ancestral_call)
 #fireblood,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(fireblood)
 #lights_judgment
 spell(lights_judgment)

 unless { spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 } and spell(berserking)
 {
  #potion,if=buff.guardian_of_azeroth.up&(buff.berserking.up|buff.blood_fury.up|!race.troll)|(consumable.potion_of_unbridled_fury&target.time_to_die<61|target.time_to_die<26)|!essence.condensed_lifeforce.major&buff.coordinated_assault.up
  if { buffpresent(guardian_of_azeroth_buff) and { buffpresent(berserking_buff) or buffpresent(blood_fury) or not race(troll) } or buffpresent(potion_of_unbridled_fury_buff) and target.timetodie() < 61 or target.timetodie() < 26 or not azeriteessenceismajor(condensed_lifeforce_essence_id) and buffpresent(coordinated_assault) } and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(unbridled_fury_item usable=1)

  unless target.distance() >= 6 and spell(aspect_of_the_eagle)
  {
   #use_item,name=ashvanes_razor_coral,if=buff.memory_of_lucid_dreams.up&target.time_to_die<cooldown.memory_of_lucid_dreams.remains+15|buff.guardian_of_azeroth.stack=5&target.time_to_die<cooldown.guardian_of_azeroth.remains+20|debuff.razor_coral_debuff.down|target.time_to_die<21|buff.worldvein_resonance.remains&target.time_to_die<cooldown.worldvein_resonance.remains+18|!talent.birds_of_prey.enabled&target.time_to_die<cooldown.coordinated_assault.remains+20&buff.coordinated_assault.remains
   if buffpresent(memory_of_lucid_dreams_buff) and target.timetodie() < spellcooldown(memory_of_lucid_dreams) + 15 or buffstacks(guardian_of_azeroth_buff) == 5 and target.timetodie() < spellcooldown(guardian_of_azeroth) + 20 or target.debuffexpires(razor_coral_debuff) or target.timetodie() < 21 or buffpresent(worldvein_resonance_buff) and target.timetodie() < spellcooldown(worldvein_resonance) + 18 or not hastalent(birds_of_prey_talent) and target.timetodie() < spellcooldown(coordinated_assault) + 20 and buffpresent(coordinated_assault) survivaluseitemactions()
   #use_item,name=galecallers_boon,if=cooldown.memory_of_lucid_dreams.remains|talent.wildfire_infusion.enabled&cooldown.coordinated_assault.remains|!essence.memory_of_lucid_dreams.major&cooldown.coordinated_assault.remains
   if spellcooldown(memory_of_lucid_dreams) > 0 or hastalent(wildfire_infusion_talent) and spellcooldown(coordinated_assault) > 0 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and spellcooldown(coordinated_assault) > 0 survivaluseitemactions()
   #use_item,name=azsharas_font_of_power
   survivaluseitemactions()

   unless { 600 > 90 and focus() < maxfocus() - 25 or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and { buffpresent(blur_of_talons) and buffremaining(blur_of_talons) > 3 * gcd() or not buffpresent(blur_of_talons) } } and spell(focused_azerite_beam) or { 0 > 90 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(blood_of_the_enemy) or { 0 > 60 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(purifying_blast)
   {
    #guardian_of_azeroth
    spell(guardian_of_azeroth)
   }
  }
 }
}

AddFunction survivalcdscdpostconditions
{
 { spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 } and spell(berserking) or target.distance() >= 6 and spell(aspect_of_the_eagle) or { 600 > 90 and focus() < maxfocus() - 25 or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and { buffpresent(blur_of_talons) and buffremaining(blur_of_talons) > 3 * gcd() or not buffpresent(blur_of_talons) } } and spell(focused_azerite_beam) or { 0 > 90 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(blood_of_the_enemy) or { 0 > 60 or not false(raid_event_adds_exists) or enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and focus() < maxfocus() and spell(purifying_blast) or spell(ripple_in_space) or spellfullrecharge(concentrated_flame) < 1 * gcd() and spell(concentrated_flame) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance) or { target.healthpercent() > 80 or target.healthpercent() <= 20 or target.timetohealthpercent(20) > 30 } and spell(reaping_flames) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and target.refreshable(serpent_sting) and buffpresent(vipers_venom_buff) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(serpent_sting) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(mongoose_bite) or azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() < powercost(mongoose_bite) and not spellcooldown(memory_of_lucid_dreams) > 0 and spell(wildfire_bomb) or focus() < powercost(mongoose_bite) and buffpresent(coordinated_assault) and spell(memory_of_lucid_dreams)
}

### actions.apwfi

AddFunction survivalapwfimainactions
{
 #kill_shot
 spell(kill_shot)
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() spell(raptor_strike)
 #serpent_sting,if=!dot.serpent_sting.ticking
 if not target.debuffpresent(serpent_sting) spell(serpent_sting)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd|focus+cast_regen<focus.max&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.remains&next_wi_bomb.pheromone
 if buffpresent(mongoose_fury) and buffpresent(pheromone_bomb) spell(mongoose_bite)
 #kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max-20
 if spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 spell(kill_command_survival)
 #raptor_strike,if=buff.tip_of_the_spear.stack=3|dot.shrapnel_bomb.ticking
 if buffstacks(tip_of_the_spear_buff) == 3 or target.debuffpresent(shrapnel_bomb_debuff) spell(raptor_strike)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking
 if target.debuffpresent(shrapnel_bomb_debuff) spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&focus>30&dot.serpent_sting.remains>5*gcd
 if buffpresent(shrapnel_bomb) and focus() > 30 and target.debuffremaining(serpent_sting) > 5 * gcd() spell(wildfire_bomb)
 #chakrams,if=!buff.mongoose_fury.remains
 if not buffpresent(mongoose_fury) spell(chakrams)
 #serpent_sting,if=refreshable
 if target.refreshable(serpent_sting) spell(serpent_sting)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } spell(kill_command_survival)
 #raptor_strike
 spell(raptor_strike)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>40|dot.shrapnel_bomb.ticking
 if buffpresent(mongoose_fury) or focus() > 40 or target.debuffpresent(shrapnel_bomb_debuff) spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50
 if buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) and focus() > 50 spell(wildfire_bomb)
}

AddFunction survivalapwfimainpostconditions
{
}

AddFunction survivalapwfishortcdactions
{
 unless spell(kill_shot) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or not target.debuffpresent(serpent_sting) and spell(serpent_sting)
 {
  #a_murder_of_crows
  spell(a_murder_of_crows)

  unless { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury) and buffpresent(pheromone_bomb) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)
  }
 }
}

AddFunction survivalapwfishortcdpostconditions
{
 spell(kill_shot) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or not target.debuffpresent(serpent_sting) and spell(serpent_sting) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury) and buffpresent(pheromone_bomb) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival) or { buffstacks(tip_of_the_spear_buff) == 3 or target.debuffpresent(shrapnel_bomb_debuff) } and spell(raptor_strike) or target.debuffpresent(shrapnel_bomb_debuff) and spell(mongoose_bite) or buffpresent(shrapnel_bomb) and focus() > 30 and target.debuffremaining(serpent_sting) > 5 * gcd() and spell(wildfire_bomb) or not buffpresent(mongoose_fury) and spell(chakrams) or target.refreshable(serpent_sting) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or spell(raptor_strike) or { buffpresent(mongoose_fury) or focus() > 40 or target.debuffpresent(shrapnel_bomb_debuff) } and spell(mongoose_bite) or { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) and focus() > 50 } and spell(wildfire_bomb)
}

AddFunction survivalapwficdactions
{
 unless spell(kill_shot) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or not target.debuffpresent(serpent_sting) and spell(serpent_sting) or spell(a_murder_of_crows) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction survivalapwficdpostconditions
{
 spell(kill_shot) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < gcd() and spell(raptor_strike) or not target.debuffpresent(serpent_sting) and spell(serpent_sting) or spell(a_murder_of_crows) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) and target.debuffrefreshable(serpent_sting) or buffpresent(pheromone_bomb) and not buffpresent(mongoose_fury) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury) and buffpresent(pheromone_bomb) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { buffstacks(tip_of_the_spear_buff) == 3 or target.debuffpresent(shrapnel_bomb_debuff) } and spell(raptor_strike) or target.debuffpresent(shrapnel_bomb_debuff) and spell(mongoose_bite) or buffpresent(shrapnel_bomb) and focus() > 30 and target.debuffremaining(serpent_sting) > 5 * gcd() and spell(wildfire_bomb) or not buffpresent(mongoose_fury) and spell(chakrams) or target.refreshable(serpent_sting) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or spell(raptor_strike) or { buffpresent(mongoose_fury) or focus() > 40 or target.debuffpresent(shrapnel_bomb_debuff) } and spell(mongoose_bite) or { buffpresent(volatile_bomb) and target.debuffpresent(serpent_sting) or buffpresent(pheromone_bomb) or buffpresent(shrapnel_bomb) and focus() > 50 } and spell(wildfire_bomb)
}

### actions.apst

AddFunction survivalapstmainactions
{
 #kill_shot
 spell(kill_shot)
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } spell(mongoose_bite)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } spell(raptor_strike)
 #kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max
 if spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&!ticking&!buff.memory_of_lucid_dreams.up&(full_recharge_time<1.5*gcd|!dot.wildfire_bomb.ticking&!buff.coordinated_assault.up|!dot.wildfire_bomb.ticking&buff.mongoose_fury.stack<1)|time_to_die<18&!dot.wildfire_bomb.ticking
 if focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault) or not target.debuffpresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury) < 1 } or target.timetodie() < 18 and not target.debuffpresent(wildfire_bomb_debuff) spell(wildfire_bomb)
 #serpent_sting,if=!dot.serpent_sting.ticking&!buff.coordinated_assault.up
 if not target.debuffpresent(serpent_sting) and not buffpresent(coordinated_assault) spell(serpent_sting)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } spell(kill_command_survival)
 #serpent_sting,if=refreshable&!buff.coordinated_assault.up&buff.mongoose_fury.stack<5
 if target.refreshable(serpent_sting) and not buffpresent(coordinated_assault) and buffstacks(mongoose_fury) < 5 spell(serpent_sting)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-10|buff.coordinated_assault.up
 if buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault) spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #wildfire_bomb,if=!ticking
 if not target.debuffpresent(wildfire_bomb_debuff) spell(wildfire_bomb)
}

AddFunction survivalapstmainpostconditions
{
}

AddFunction survivalapstshortcdactions
{
 unless spell(kill_shot) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

  unless spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)

   unless { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault) or not target.debuffpresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury) < 1 } or target.timetodie() < 18 and not target.debuffpresent(wildfire_bomb_debuff) } and spell(wildfire_bomb) or not target.debuffpresent(serpent_sting) and not buffpresent(coordinated_assault) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting) and not buffpresent(coordinated_assault) and buffstacks(mongoose_fury) < 5 and spell(serpent_sting)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not buffpresent(coordinated_assault) spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction survivalapstshortcdpostconditions
{
 spell(kill_shot) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault) or not target.debuffpresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury) < 1 } or target.timetodie() < 18 and not target.debuffpresent(wildfire_bomb_debuff) } and spell(wildfire_bomb) or not target.debuffpresent(serpent_sting) and not buffpresent(coordinated_assault) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting) and not buffpresent(coordinated_assault) and buffstacks(mongoose_fury) < 5 and spell(serpent_sting) or { buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault) } and spell(mongoose_bite) or spell(raptor_strike) or not target.debuffpresent(wildfire_bomb_debuff) and spell(wildfire_bomb)
}

AddFunction survivalapstcdactions
{
 unless spell(kill_shot) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault) or not target.debuffpresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury) < 1 } or target.timetodie() < 18 and not target.debuffpresent(wildfire_bomb_debuff) } and spell(wildfire_bomb) or not target.debuffpresent(serpent_sting) and not buffpresent(coordinated_assault) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting) and not buffpresent(coordinated_assault) and buffstacks(mongoose_fury) < 5 and spell(serpent_sting) or not buffpresent(coordinated_assault) and spell(a_murder_of_crows)
 {
  #coordinated_assault,if=!buff.coordinated_assault.up
  if not buffpresent(coordinated_assault) spell(coordinated_assault)
 }
}

AddFunction survivalapstcdpostconditions
{
 spell(kill_shot) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault) and { buffremaining(coordinated_assault) < 1.5 * gcd() or buffpresent(blur_of_talons) and buffremaining(blur_of_talons) < 1.5 * gcd() } and spell(raptor_strike) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.debuffpresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault) or not target.debuffpresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury) < 1 } or target.timetodie() < 18 and not target.debuffpresent(wildfire_bomb_debuff) } and spell(wildfire_bomb) or not target.debuffpresent(serpent_sting) and not buffpresent(coordinated_assault) and spell(serpent_sting) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting) and not buffpresent(coordinated_assault) and buffstacks(mongoose_fury) < 5 and spell(serpent_sting) or not buffpresent(coordinated_assault) and spell(a_murder_of_crows) or { buffpresent(mongoose_fury) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault) } and spell(mongoose_bite) or spell(raptor_strike) or not target.debuffpresent(wildfire_bomb_debuff) and spell(wildfire_bomb)
}

### actions.default

AddFunction survival_defaultmainactions
{
 #call_action_list,name=cds
 survivalcdsmainactions()

 unless survivalcdsmainpostconditions()
 {
  #mongoose_bite,if=active_enemies=1&target.time_to_die<focus%(action.mongoose_bite.cost-cast_regen)*gcd
  if enemies() == 1 and target.timetodie() < focus() / { powercost(mongoose_bite) - focuscastingregen(mongoose_bite) } * gcd() spell(mongoose_bite)
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) survivalapwfimainactions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwfimainpostconditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) survivalwfimainactions()

   unless enemies() < 3 and hastalent(chakrams_talent) and survivalwfimainpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalstmainactions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstmainpostconditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalapstmainactions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstmainpostconditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalapwfimainactions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwfimainpostconditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalwfimainactions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwfimainpostconditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2
        if enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 survivalcleavemainactions()

        unless { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleavemainpostconditions()
        {
         #concentrated_flame
         spell(concentrated_flame)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction survival_defaultmainpostconditions
{
 survivalcdsmainpostconditions() or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwfimainpostconditions() or enemies() < 3 and hastalent(chakrams_talent) and survivalwfimainpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstmainpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstmainpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwfimainpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwfimainpostconditions() or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleavemainpostconditions()
}

AddFunction survival_defaultshortcdactions
{
 #auto_attack
 survivalgetinmeleerange()
 #call_action_list,name=cds
 survivalcdsshortcdactions()

 unless survivalcdsshortcdpostconditions() or enemies() == 1 and target.timetodie() < focus() / { powercost(mongoose_bite) - focuscastingregen(mongoose_bite) } * gcd() and spell(mongoose_bite)
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) survivalapwfishortcdactions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwfishortcdpostconditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) survivalwfishortcdactions()

   unless enemies() < 3 and hastalent(chakrams_talent) and survivalwfishortcdpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalstshortcdactions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstshortcdpostconditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalapstshortcdactions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstshortcdpostconditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalapwfishortcdactions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwfishortcdpostconditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalwfishortcdactions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwfishortcdpostconditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2
        if enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 survivalcleaveshortcdactions()

        unless { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleaveshortcdpostconditions() or spell(concentrated_flame)
        {
         #bag_of_tricks
         spell(bag_of_tricks)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction survival_defaultshortcdpostconditions
{
 survivalcdsshortcdpostconditions() or enemies() == 1 and target.timetodie() < focus() / { powercost(mongoose_bite) - focuscastingregen(mongoose_bite) } * gcd() and spell(mongoose_bite) or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwfishortcdpostconditions() or enemies() < 3 and hastalent(chakrams_talent) and survivalwfishortcdpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstshortcdpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstshortcdpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwfishortcdpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwfishortcdpostconditions() or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleaveshortcdpostconditions() or spell(concentrated_flame)
}

AddFunction survival_defaultcdactions
{
 survivalinterruptactions()
 #use_items
 survivaluseitemactions()
 #call_action_list,name=cds
 survivalcdscdactions()

 unless survivalcdscdpostconditions() or enemies() == 1 and target.timetodie() < focus() / { powercost(mongoose_bite) - focuscastingregen(mongoose_bite) } * gcd() and spell(mongoose_bite)
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) survivalapwficdactions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwficdpostconditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) survivalwficdactions()

   unless enemies() < 3 and hastalent(chakrams_talent) and survivalwficdpostconditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalstcdactions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstcdpostconditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) survivalapstcdactions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstcdpostconditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalapwficdactions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwficdpostconditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) survivalwficdactions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwficdpostconditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1&!talent.birds_of_prey.enabled|active_enemies>2
        if enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 survivalcleavecdactions()

        unless { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleavecdpostconditions() or spell(concentrated_flame)
        {
         #arcane_torrent
         spell(arcane_torrent)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction survival_defaultcdpostconditions
{
 survivalcdscdpostconditions() or enemies() == 1 and target.timetodie() < focus() / { powercost(mongoose_bite) - focuscastingregen(mongoose_bite) } * gcd() and spell(mongoose_bite) or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and survivalapwficdpostconditions() or enemies() < 3 and hastalent(chakrams_talent) and survivalwficdpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalstcdpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and survivalapstcdpostconditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalapwficdpostconditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and survivalwficdpostconditions() or { enemies() > 1 and not hastalent(birds_of_prey_talent) or enemies() > 2 } and survivalcleavecdpostconditions() or spell(concentrated_flame) or spell(bag_of_tricks)
}

### Survival icons.

AddCheckBox(opt_hunter_survival_aoe l(aoe) default enabled=(specialization(survival)))

AddIcon enabled=(not checkboxon(opt_hunter_survival_aoe) and specialization(survival)) enemies=1 help=shortcd
{
 if not incombat() survivalprecombatshortcdactions()
 survival_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_survival_aoe) and specialization(survival)) help=shortcd
{
 if not incombat() survivalprecombatshortcdactions()
 survival_defaultshortcdactions()
}

AddIcon enabled=(specialization(survival)) enemies=1 help=main
{
 if not incombat() survivalprecombatmainactions()
 survival_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_survival_aoe) and specialization(survival)) help=aoe
{
 if not incombat() survivalprecombatmainactions()
 survival_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_hunter_survival_aoe) and not specialization(survival)) enemies=1 help=cd
{
 if not incombat() survivalprecombatcdactions()
 survival_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_hunter_survival_aoe) and specialization(survival)) help=cd
{
 if not incombat() survivalprecombatcdactions()
 survival_defaultcdactions()
}

### Required symbols
# a_murder_of_crows
# alpha_predator_talent
# ancestral_call
# arcane_torrent
# aspect_of_the_eagle
# bag_of_tricks
# berserking
# berserking_buff
# birds_of_prey_talent
# blood_fury
# blood_of_the_enemy
# blood_of_the_enemy_debuff
# blur_of_talons
# blur_of_talons_trait
# butchery
# carve
# chakrams
# chakrams_talent
# concentrated_flame
# condensed_lifeforce_essence_id
# coordinated_assault
# fireblood
# flanking_strike
# focused_azerite_beam
# guardian_of_azeroth
# guardian_of_azeroth_buff
# guerrilla_tactics_talent
# harpoon
# hydras_bite_talent
# kill_command_survival
# kill_shot
# latent_poison
# latent_poison_trait
# lights_judgment
# memory_of_lucid_dreams
# memory_of_lucid_dreams_buff
# memory_of_lucid_dreams_essence_id
# mongoose_bite
# mongoose_fury
# muzzle
# pheromone_bomb
# potion_of_unbridled_fury_buff
# purifying_blast
# quaking_palm
# raptor_strike
# razor_coral_debuff
# reaping_flames
# reckless_force_buff
# revive_pet
# ripple_in_space
# serpent_sting
# shrapnel_bomb
# shrapnel_bomb_debuff
# steel_trap
# terms_of_engagement_talent
# the_unbound_force
# tip_of_the_spear_buff
# unbridled_fury_item
# vipers_venom_buff
# vipers_venom_talent
# volatile_bomb
# war_stomp
# wilderness_survival_trait
# wildfire_bomb
# wildfire_bomb_debuff
# wildfire_infusion_talent
# worldvein_resonance
# worldvein_resonance_buff
]]
        OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
    end
end
