local __exports = LibStub:NewLibrary("ovale/scripts/ovale_hunter", 80201)
if not __exports then return end
__exports.registerHunter = function(OvaleScripts)
    do
        local name = "sc_t23_hunter_beast_mastery"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Beast_Mastery"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Beast_Mastery".
#	class=hunter
#	spec=beast_mastery
#	talents=1303011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=beast_mastery)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=beast_mastery)

AddFunction BeastmasteryInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counter_shot) and target.isinterruptible() spell(counter_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction BeastmasteryUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

AddFunction BeastmasterySummonPet
{
 if not pet.present() and not pet.isdead() and not previousspell(revive_pet) texture(ability_hunter_beastcall help=l(summon_pet))
}

### actions.st

AddFunction BeastmasteryStMainActions
{
 #barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<gcd|cooldown.bestial_wrath.remains&(full_recharge_time<gcd|azerite.primal_instincts.enabled&cooldown.aspect_of_the_wild.remains<gcd)
 if pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } spell(barbed_shot)
 #concentrated_flame,if=focus+focus.regen*gcd<focus.max&buff.bestial_wrath.down&(!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight)|full_recharge_time<gcd|target.time_to_die<5
 if focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 spell(concentrated_flame_essence)
 #kill_command
 if pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() spell(kill_command)
 #chimaera_shot
 spell(chimaera_shot)
 #dire_beast
 spell(dire_beast)
 #barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|azerite.dance_of_death.rank>1&buff.dance_of_death.down&crit_pct_current>40|target.time_to_die<9
 if pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or azeritetraitrank(dance_of_death_trait) > 1 and buffexpires(dance_of_death_buff) and spellcritchance() > 40 or target.timetodie() < 9 spell(barbed_shot)
 #cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd|buff.memory_of_lucid_dreams.up)&cooldown.kill_command.remains>1
 if { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() or buffpresent(memory_of_lucid_dreams_essence_buff) } and spellcooldown(kill_command) > 1 spell(cobra_shot)
 #barbed_shot,if=charges_fractional>1.4
 if charges(barbed_shot count=0) > 1.4 spell(barbed_shot)
}

AddFunction BeastmasteryStMainPostConditions
{
}

AddFunction BeastmasteryStShortCdActions
{
 unless { pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence)
 {
  #a_murder_of_crows,if=cooldown.bestial_wrath.remains
  if spellcooldown(bestial_wrath) > 0 spell(a_murder_of_crows)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10|target.time_to_die<5
  if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 or target.timetodie() < 5 spell(the_unbound_force)
  #bestial_wrath
  spell(bestial_wrath)

  unless pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(chimaera_shot) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or azeritetraitrank(dance_of_death_trait) > 1 and buffexpires(dance_of_death_buff) and spellcritchance() > 40 or target.timetodie() < 9 } and spell(barbed_shot)
  {
   #purifying_blast,if=buff.bestial_wrath.down|target.time_to_die<8
   if buffexpires(bestial_wrath_buff) or target.timetodie() < 8 spell(purifying_blast)
   #barrage
   spell(barrage)

   unless { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() or buffpresent(memory_of_lucid_dreams_essence_buff) } and spellcooldown(kill_command) > 1 and spell(cobra_shot)
   {
    #spitting_cobra
    spell(spitting_cobra)
   }
  }
 }
}

AddFunction BeastmasteryStShortCdPostConditions
{
 { pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(chimaera_shot) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or azeritetraitrank(dance_of_death_trait) > 1 and buffexpires(dance_of_death_buff) and spellcritchance() > 40 or target.timetodie() < 9 } and spell(barbed_shot) or { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() or buffpresent(memory_of_lucid_dreams_essence_buff) } and spellcooldown(kill_command) > 1 and spell(cobra_shot) or charges(barbed_shot count=0) > 1.4 and spell(barbed_shot)
}

AddFunction BeastmasteryStCdActions
{
 unless { pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence)
 {
  #aspect_of_the_wild,if=cooldown.barbed_shot.charges<2|pet.cat.buff.frenzy.stack>2|!azerite.primal_instincts.enabled
  if spellcharges(barbed_shot) < 2 or pet.buffstacks(pet_frenzy_buff) > 2 or not hasazeritetrait(primal_instincts_trait) spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if buffpresent(aspect_of_the_wild_buff) and buffpresent(bestial_wrath_buff) or target.timetodie() < 15 spell(stampede)

  unless spellcooldown(bestial_wrath) > 0 and spell(a_murder_of_crows)
  {
   #focused_azerite_beam,if=buff.bestial_wrath.down|target.time_to_die<5
   if buffexpires(bestial_wrath_buff) or target.timetodie() < 5 spell(focused_azerite_beam)

   unless { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or spell(bestial_wrath) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(chimaera_shot) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or azeritetraitrank(dance_of_death_trait) > 1 and buffexpires(dance_of_death_buff) and spellcritchance() > 40 or target.timetodie() < 9 } and spell(barbed_shot) or { buffexpires(bestial_wrath_buff) or target.timetodie() < 8 } and spell(purifying_blast)
   {
    #blood_of_the_enemy
    spell(blood_of_the_enemy)
   }
  }
 }
}

AddFunction BeastmasteryStCdPostConditions
{
 { pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) < gcd() or spellcooldown(bestial_wrath) > 0 and { spellfullrecharge(barbed_shot) < gcd() or hasazeritetrait(primal_instincts_trait) and spellcooldown(aspect_of_the_wild) < gcd() } } and spell(barbed_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or spellcooldown(bestial_wrath) > 0 and spell(a_murder_of_crows) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or spell(bestial_wrath) or pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(chimaera_shot) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or azeritetraitrank(dance_of_death_trait) > 1 and buffexpires(dance_of_death_buff) and spellcritchance() > 40 or target.timetodie() < 9 } and spell(barbed_shot) or { buffexpires(bestial_wrath_buff) or target.timetodie() < 8 } and spell(purifying_blast) or spell(barrage) or { focus() - powercost(cobra_shot) + focusregenrate() * { spellcooldown(kill_command) - 1 } > powercost(kill_command) or spellcooldown(kill_command) > 1 + gcd() or buffpresent(memory_of_lucid_dreams_essence_buff) } and spellcooldown(kill_command) > 1 and spell(cobra_shot) or spell(spitting_cobra) or charges(barbed_shot count=0) > 1.4 and spell(barbed_shot)
}

### actions.precombat

AddFunction BeastmasteryPrecombatMainActions
{
}

AddFunction BeastmasteryPrecombatMainPostConditions
{
}

AddFunction BeastmasteryPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 beastmasterysummonpet()
 #worldvein_resonance
 spell(worldvein_resonance_essence)
 #bestial_wrath,precast_time=1.5,if=azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.cyclotronic_blast)
 if hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } spell(bestial_wrath)
}

AddFunction BeastmasteryPrecombatShortCdPostConditions
{
}

AddFunction BeastmasteryPrecombatCdActions
{
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_item,name=azsharas_font_of_power
 beastmasteryuseitemactions()

 unless spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists&(trinket.1.has_cooldown+trinket.2.has_cooldown<2|equipped.variable_intensity_gigavolt_oscillating_reactor)
  if not 0 and { true(trinket_has_cooldown_undefined) + true(trinket_has_cooldown_undefined) < 2 or hasequippeditem(variable_intensity_gigavolt_oscillating_reactor_item) } beastmasteryuseitemactions()
  #focused_azerite_beam,if=!raid_event.invulnerable.exists
  if not 0 spell(focused_azerite_beam)
  #aspect_of_the_wild,precast_time=1.1,if=!azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.cyclotronic_blast)
  if not hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } spell(aspect_of_the_wild)
 }
}

AddFunction BeastmasteryPrecombatCdPostConditions
{
 spell(worldvein_resonance_essence) or hasazeritetrait(primal_instincts_trait) and not azeriteessenceismajor(essence_of_the_focusing_iris_essence_id) and { hasequippeditem(azsharas_font_of_power_item) or not hasequippeditem(cyclotronic_blast_item) } and spell(bestial_wrath)
}

### actions.cleave

AddFunction BeastmasteryCleaveMainActions
{
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
 if pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) <= gcd() spell(barbed_shot)
 #multishot,if=gcd.max-pet.cat.buff.beast_cleave.remains>0.25
 if gcd() - pet.buffremaining(pet_beast_cleave_buff) > 0.25 spell(multishot_bm)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd.max&cooldown.bestial_wrath.remains
 if spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 spell(barbed_shot)
 #chimaera_shot
 spell(chimaera_shot)
 #kill_command,if=active_enemies<4|!azerite.rapid_reload.enabled
 if { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() spell(kill_command)
 #dire_beast
 spell(dire_beast)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|charges_fractional>1.4|target.time_to_die<9
 if pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 spell(barbed_shot)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #multishot,if=azerite.rapid_reload.enabled&active_enemies>2
 if hasazeritetrait(rapid_reload_trait) and enemies() > 2 spell(multishot_bm)
 #cobra_shot,if=cooldown.kill_command.remains>focus.time_to_max&(active_enemies<3|!azerite.rapid_reload.enabled)
 if spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } spell(cobra_shot)
}

AddFunction BeastmasteryCleaveMainPostConditions
{
}

AddFunction BeastmasteryCleaveShortCdActions
{
 unless pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) <= gcd() and spell(barbed_shot) or gcd() - pet.buffremaining(pet_beast_cleave_buff) > 0.25 and spell(multishot_bm) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot)
 {
  #bestial_wrath,if=cooldown.aspect_of_the_wild.remains_guess>20|talent.one_with_the_pack.enabled|target.time_to_die<15
  if spellcooldown(aspect_of_the_wild) > 20 or hastalent(one_with_the_pack_talent) or target.timetodie() < 15 spell(bestial_wrath)

  unless spell(chimaera_shot)
  {
   #a_murder_of_crows
   spell(a_murder_of_crows)
   #barrage
   spell(barrage)

   unless { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot)
   {
    #purifying_blast
    spell(purifying_blast)

    unless spell(concentrated_flame_essence)
    {
     #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
     if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)

     unless hasazeritetrait(rapid_reload_trait) and enemies() > 2 and spell(multishot_bm) or spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } and spell(cobra_shot)
     {
      #spitting_cobra
      spell(spitting_cobra)
     }
    }
   }
  }
 }
}

AddFunction BeastmasteryCleaveShortCdPostConditions
{
 pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) <= gcd() and spell(barbed_shot) or gcd() - pet.buffremaining(pet_beast_cleave_buff) > 0.25 and spell(multishot_bm) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot) or spell(chimaera_shot) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot) or spell(concentrated_flame_essence) or hasazeritetrait(rapid_reload_trait) and enemies() > 2 and spell(multishot_bm) or spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } and spell(cobra_shot)
}

AddFunction BeastmasteryCleaveCdActions
{
 unless pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) <= gcd() and spell(barbed_shot) or gcd() - pet.buffremaining(pet_beast_cleave_buff) > 0.25 and spell(multishot_bm) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot)
 {
  #aspect_of_the_wild
  spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if buffpresent(aspect_of_the_wild_buff) and buffpresent(bestial_wrath_buff) or target.timetodie() < 15 spell(stampede)

  unless { spellcooldown(aspect_of_the_wild) > 20 or hastalent(one_with_the_pack_talent) or target.timetodie() < 15 } and spell(bestial_wrath) or spell(chimaera_shot) or spell(a_murder_of_crows) or spell(barrage) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot)
  {
   #focused_azerite_beam
   spell(focused_azerite_beam)

   unless spell(purifying_blast) or spell(concentrated_flame_essence)
   {
    #blood_of_the_enemy
    spell(blood_of_the_enemy)
   }
  }
 }
}

AddFunction BeastmasteryCleaveCdPostConditions
{
 pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) <= gcd() and spell(barbed_shot) or gcd() - pet.buffremaining(pet_beast_cleave_buff) > 0.25 and spell(multishot_bm) or spellfullrecharge(barbed_shot) < gcd() and spellcooldown(bestial_wrath) > 0 and spell(barbed_shot) or { spellcooldown(aspect_of_the_wild) > 20 or hastalent(one_with_the_pack_talent) or target.timetodie() < 15 } and spell(bestial_wrath) or spell(chimaera_shot) or spell(a_murder_of_crows) or spell(barrage) or { enemies() < 4 or not hasazeritetrait(rapid_reload_trait) } and pet.present() and not pet.isincapacitated() and not pet.isfeared() and not pet.isstunned() and spell(kill_command) or spell(dire_beast) or { pet.buffexpires(pet_frenzy_buff) and { charges(barbed_shot count=0) > 1.8 or buffpresent(bestial_wrath_buff) } or spellcooldown(aspect_of_the_wild) < baseduration(pet_frenzy_buff) - gcd() and hasazeritetrait(primal_instincts_trait) or charges(barbed_shot count=0) > 1.4 or target.timetodie() < 9 } and spell(barbed_shot) or spell(purifying_blast) or spell(concentrated_flame_essence) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or hasazeritetrait(rapid_reload_trait) and enemies() > 2 and spell(multishot_bm) or spellcooldown(kill_command) > timetomaxfocus() and { enemies() < 3 or not hasazeritetrait(rapid_reload_trait) } and spell(cobra_shot) or spell(spitting_cobra)
}

### actions.cds

AddFunction BeastmasteryCdsMainActions
{
}

AddFunction BeastmasteryCdsMainPostConditions
{
}

AddFunction BeastmasteryCdsShortCdActions
{
 #worldvein_resonance,if=buff.lifeblood.stack<4
 if buffstacks(lifeblood_buff) < 4 spell(worldvein_resonance_essence)
 #ripple_in_space
 spell(ripple_in_space_essence)
}

AddFunction BeastmasteryCdsShortCdPostConditions
{
}

AddFunction BeastmasteryCdsCdActions
{
 #ancestral_call,if=cooldown.bestial_wrath.remains>30
 if spellcooldown(bestial_wrath) > 30 spell(ancestral_call)
 #fireblood,if=cooldown.bestial_wrath.remains>30
 if spellcooldown(bestial_wrath) > 30 spell(fireblood)
 #berserking,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<13
 if buffpresent(aspect_of_the_wild_buff) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 13 spell(berserking)
 #blood_fury,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<16
 if buffpresent(aspect_of_the_wild_buff) and { target.timetodie() > spellcooldownduration(blood_fury_ap) + baseduration(blood_fury_ap) or target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or target.timetodie() < 16 spell(blood_fury_ap)
 #lights_judgment,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains>gcd.max|!pet.cat.buff.frenzy.up
 if pet.buffpresent(pet_frenzy_buff) and pet.buffremaining(pet_frenzy_buff) > gcd() or not pet.buffpresent(pet_frenzy_buff) spell(lights_judgment)
 #potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up&(target.health.pct<35|!talent.killer_instinct.enabled)|((consumable.potion_of_unbridled_fury|consumable.unbridled_fury)&target.time_to_die<61|target.time_to_die<26)
 if { buffpresent(bestial_wrath_buff) and buffpresent(aspect_of_the_wild_buff) and { target.healthpercent() < 35 or not hastalent(killer_instinct_talent) } or { buffpresent(unbridled_fury) or buffpresent(unbridled_fury) } and target.timetodie() < 61 or target.timetodie() < 26 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless buffstacks(lifeblood_buff) < 4 and spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth,if=cooldown.aspect_of_the_wild.remains<10|target.time_to_die>cooldown+duration|target.time_to_die<30
  if spellcooldown(aspect_of_the_wild) < 10 or target.timetodie() > spellcooldown(guardian_of_azeroth) + baseduration(guardian_of_azeroth) or target.timetodie() < 30 spell(guardian_of_azeroth)

  unless spell(ripple_in_space_essence)
  {
   #memory_of_lucid_dreams
   spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction BeastmasteryCdsCdPostConditions
{
 buffstacks(lifeblood_buff) < 4 and spell(worldvein_resonance_essence) or spell(ripple_in_space_essence)
}

### actions.default

AddFunction BeastmasteryDefaultMainActions
{
 #call_action_list,name=cds
 BeastmasteryCdsMainActions()

 unless BeastmasteryCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 BeastmasteryStMainActions()

  unless enemies() < 2 and BeastmasteryStMainPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 BeastmasteryCleaveMainActions()
  }
 }
}

AddFunction BeastmasteryDefaultMainPostConditions
{
 BeastmasteryCdsMainPostConditions() or enemies() < 2 and BeastmasteryStMainPostConditions() or enemies() > 1 and BeastmasteryCleaveMainPostConditions()
}

AddFunction BeastmasteryDefaultShortCdActions
{
 #call_action_list,name=cds
 BeastmasteryCdsShortCdActions()

 unless BeastmasteryCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 BeastmasteryStShortCdActions()

  unless enemies() < 2 and BeastmasteryStShortCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 BeastmasteryCleaveShortCdActions()
  }
 }
}

AddFunction BeastmasteryDefaultShortCdPostConditions
{
 BeastmasteryCdsShortCdPostConditions() or enemies() < 2 and BeastmasteryStShortCdPostConditions() or enemies() > 1 and BeastmasteryCleaveShortCdPostConditions()
}

AddFunction BeastmasteryDefaultCdActions
{
 undefined()
 #auto_shot
 #use_items
 beastmasteryuseitemactions()
 #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.up&(prev_gcd.1.aspect_of_the_wild|!equipped.cyclotronic_blast&buff.aspect_of_the_wild.up)&(target.health.pct<35|!essence.condensed_lifeforce.major)|(debuff.razor_coral_debuff.down|target.time_to_die<26)&target.time_to_die>(24*(cooldown.cyclotronic_blast.remains+4<target.time_to_die))
 if target.DebuffPresent(razor_coral) and { previousgcdspell(aspect_of_the_wild) or not hasequippeditem(cyclotronic_blast_item) and buffpresent(aspect_of_the_wild_buff) } and { target.healthpercent() < 35 or not azeriteessenceismajor(condensed_life_force_essence_id) } or { target.DebuffExpires(razor_coral) or target.timetodie() < 26 } and target.timetodie() > 24 * { spellcooldown(cyclotronic_blast) + 4 < target.timetodie() } beastmasteryuseitemactions()
 #use_item,effect_name=cyclotronic_blast,if=buff.bestial_wrath.down|target.time_to_die<5
 if buffexpires(bestial_wrath_buff) or target.timetodie() < 5 beastmasteryuseitemactions()
 #call_action_list,name=cds
 BeastmasteryCdsCdActions()

 unless BeastmasteryCdsCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if enemies() < 2 BeastmasteryStCdActions()

  unless enemies() < 2 and BeastmasteryStCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if enemies() > 1 BeastmasteryCleaveCdActions()
  }
 }
}

AddFunction BeastmasteryDefaultCdPostConditions
{
 BeastmasteryCdsCdPostConditions() or enemies() < 2 and BeastmasteryStCdPostConditions() or enemies() > 1 and BeastmasteryCleaveCdPostConditions()
}

### Beastmastery icons.

AddCheckBox(opt_hunter_beast_mastery_aoe l(AOE) default specialization=beast_mastery)

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=shortcd specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatshortcdactions()
 unless not incombat() and beastmasteryprecombatshortcdpostconditions()
 {
  beastmasterydefaultshortcdactions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=shortcd specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatshortcdactions()
 unless not incombat() and beastmasteryprecombatshortcdpostconditions()
 {
  beastmasterydefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatmainactions()
 unless not incombat() and beastmasteryprecombatmainpostconditions()
 {
  beastmasterydefaultmainactions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=aoe specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatmainactions()
 unless not incombat() and beastmasteryprecombatmainpostconditions()
 {
  beastmasterydefaultmainactions()
 }
}

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=cd specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatcdactions()
 unless not incombat() and beastmasteryprecombatcdpostconditions()
 {
  beastmasterydefaultcdactions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=cd specialization=beast_mastery
{
 if not incombat() beastmasteryprecombatcdactions()
 unless not incombat() and beastmasteryprecombatcdpostconditions()
 {
  beastmasterydefaultcdactions()
 }
}

### Required symbols
# a_murder_of_crows
# ancestral_call
# aspect_of_the_wild
# aspect_of_the_wild_buff
# azsharas_font_of_power_item
# barbed_shot
# barrage
# berserking
# bestial_wrath
# bestial_wrath_buff
# blood_fury_ap
# blood_of_the_enemy
# chimaera_shot
# cobra_shot
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# condensed_life_force_essence_id
# counter_shot
# cyclotronic_blast
# cyclotronic_blast_item
# dance_of_death_buff
# dance_of_death_trait
# dire_beast
# essence_of_the_focusing_iris_essence_id
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# kill_command
# killer_instinct_talent
# lifeblood_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# multishot_bm
# one_with_the_pack_talent
# pet_beast_cleave_buff
# pet_frenzy_buff
# primal_instincts_trait
# purifying_blast
# quaking_palm
# rapid_reload_trait
# razor_coral
# reckless_force_buff
# reckless_force_counter_buff
# revive_pet
# ripple_in_space_essence
# spitting_cobra
# stampede
# the_unbound_force
# unbridled_fury
# unbridled_fury_item
# variable_intensity_gigavolt_oscillating_reactor_item
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
    end
    do
        local name = "sc_t23_hunter_marksmanship"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Marksmanship"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Marksmanship".
#	class=hunter
#	spec=marksmanship
#	talents=1103031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=marksmanship)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=marksmanship)

AddFunction MarksmanshipInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(counter_shot) and target.isinterruptible() spell(counter_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction MarksmanshipUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

### actions.trickshots

AddFunction MarksmanshipTrickshotsMainActions
{
 #aimed_shot,if=buff.trick_shots.up&ca_execute&buff.double_tap.up
 if buffpresent(trick_shots_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } and buffpresent(double_tap_buff) spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
 if buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } spell(rapid_fire)
 #aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time|buff.trueshot.up)
 if buffpresent(trick_shots_buff) and { buffexpires(precise_shots_buff) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot_buff) } spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up
 if buffpresent(trick_shots_buff) spell(rapid_fire)
 #multishot,if=buff.trick_shots.down|buff.precise_shots.up&!buff.trueshot.up|focus>70
 if buffexpires(trick_shots_buff) or buffpresent(precise_shots_buff) and not buffpresent(trueshot_buff) or focus() > 70 spell(multishot_mm)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) spell(serpent_sting_mm)
 #steady_shot
 spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsMainPostConditions
{
}

AddFunction MarksmanshipTrickshotsShortCdActions
{
 #barrage
 spell(barrage)
 #explosive_shot
 spell(explosive_shot)

 unless buffpresent(trick_shots_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } and buffpresent(double_tap_buff) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots_buff) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot_buff) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots_buff) and not buffpresent(trueshot_buff) or focus() > 70 } and spell(multishot_mm)
 {
  #purifying_blast
  spell(purifying_blast)

  unless spell(concentrated_flame_essence)
  {
   #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
   if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)
   #piercing_shot
   spell(piercing_shot)
   #a_murder_of_crows
   spell(a_murder_of_crows)
  }
 }
}

AddFunction MarksmanshipTrickshotsShortCdPostConditions
{
 buffpresent(trick_shots_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } and buffpresent(double_tap_buff) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots_buff) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot_buff) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots_buff) and not buffpresent(trueshot_buff) or focus() > 70 } and spell(multishot_mm) or spell(concentrated_flame_essence) or target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsCdActions
{
 unless spell(barrage) or spell(explosive_shot) or buffpresent(trick_shots_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } and buffpresent(double_tap_buff) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots_buff) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot_buff) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots_buff) and not buffpresent(trueshot_buff) or focus() > 70 } and spell(multishot_mm)
 {
  #focused_azerite_beam
  spell(focused_azerite_beam)

  unless spell(purifying_blast) or spell(concentrated_flame_essence)
  {
   #blood_of_the_enemy
   spell(blood_of_the_enemy)
  }
 }
}

AddFunction MarksmanshipTrickshotsCdPostConditions
{
 spell(barrage) or spell(explosive_shot) or buffpresent(trick_shots_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } and buffpresent(double_tap_buff) and spell(aimed_shot) or buffpresent(trick_shots_buff) and { hasazeritetrait(focused_fire_trait) or azeritetraitrank(in_the_rhythm_trait) > 1 or hasazeritetrait(surging_shots_trait) or hastalent(streamline_talent) } and spell(rapid_fire) or buffpresent(trick_shots_buff) and { buffexpires(precise_shots_buff) or spellcooldown(aimed_shot) < casttime(aimed_shot) or buffpresent(trueshot_buff) } and spell(aimed_shot) or buffpresent(trick_shots_buff) and spell(rapid_fire) or { buffexpires(trick_shots_buff) or buffpresent(precise_shots_buff) and not buffpresent(trueshot_buff) or focus() > 70 } and spell(multishot_mm) or spell(purifying_blast) or spell(concentrated_flame_essence) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(piercing_shot) or spell(a_murder_of_crows) or target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or spell(steady_shot)
}

### actions.st

AddFunction MarksmanshipStMainActions
{
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) spell(serpent_sting_mm)
 #rapid_fire,if=buff.trueshot.down|focus<70
 if buffexpires(trueshot_buff) or focus() < 70 spell(rapid_fire)
 #arcane_shot,if=buff.trueshot.up&buff.master_marksman.up&!buff.memory_of_lucid_dreams.up
 if buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) spell(arcane_shot)
 #aimed_shot,if=buff.trueshot.up|(buff.double_tap.down|ca_execute)&buff.precise_shots.down|full_recharge_time<cast_time&cooldown.trueshot.remains
 if buffpresent(trueshot_buff) or { buffexpires(double_tap_buff) or talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } } and buffexpires(precise_shots_buff) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 spell(aimed_shot)
 #arcane_shot,if=buff.trueshot.up&buff.master_marksman.up&buff.memory_of_lucid_dreams.up
 if buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) spell(arcane_shot)
 #concentrated_flame,if=focus+focus.regen*gcd<focus.max&buff.trueshot.down&(!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight)|full_recharge_time<gcd|target.time_to_die<5
 if focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 spell(concentrated_flame_essence)
 #arcane_shot,if=buff.trueshot.down&(buff.precise_shots.up&(focus>41|buff.master_marksman.up)|(focus>50&azerite.focused_fire.enabled|focus>75)&(cooldown.trueshot.remains>5|focus>80)|target.time_to_die<5)
 if buffexpires(trueshot_buff) and { buffpresent(precise_shots_buff) and { focus() > 41 or buffpresent(master_marksman_buff) } or { focus() > 50 and hasazeritetrait(focused_fire_trait) or focus() > 75 } and { spellcooldown(trueshot) > 5 or focus() > 80 } or target.timetodie() < 5 } spell(arcane_shot)
 #steady_shot
 spell(steady_shot)
}

AddFunction MarksmanshipStMainPostConditions
{
}

AddFunction MarksmanshipStShortCdActions
{
 #explosive_shot
 spell(explosive_shot)
 #barrage,if=active_enemies>1
 if enemies() > 1 spell(barrage)
 #a_murder_of_crows
 spell(a_murder_of_crows)

 unless target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or { buffexpires(trueshot_buff) or focus() < 70 } and spell(rapid_fire) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot) or { buffpresent(trueshot_buff) or { buffexpires(double_tap_buff) or talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } } and buffexpires(precise_shots_buff) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot)
 {
  #piercing_shot
  spell(piercing_shot)
  #purifying_blast,if=!buff.trueshot.up|target.time_to_die<8
  if not buffpresent(trueshot_buff) or target.timetodie() < 8 spell(purifying_blast)

  unless { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence)
  {
   #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10|target.time_to_die<5
   if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 or target.timetodie() < 5 spell(the_unbound_force)
  }
 }
}

AddFunction MarksmanshipStShortCdPostConditions
{
 target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or { buffexpires(trueshot_buff) or focus() < 70 } and spell(rapid_fire) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot) or { buffpresent(trueshot_buff) or { buffexpires(double_tap_buff) or talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } } and buffexpires(precise_shots_buff) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or buffexpires(trueshot_buff) and { buffpresent(precise_shots_buff) and { focus() > 41 or buffpresent(master_marksman_buff) } or { focus() > 50 and hasazeritetrait(focused_fire_trait) or focus() > 75 } and { spellcooldown(trueshot) > 5 or focus() > 80 } or target.timetodie() < 5 } and spell(arcane_shot) or spell(steady_shot)
}

AddFunction MarksmanshipStCdActions
{
 unless spell(explosive_shot) or enemies() > 1 and spell(barrage) or spell(a_murder_of_crows) or target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or { buffexpires(trueshot_buff) or focus() < 70 } and spell(rapid_fire)
 {
  #blood_of_the_enemy,if=buff.trueshot.up&(buff.unerring_vision.stack>4|!azerite.unerring_vision.enabled)|target.time_to_die<11
  if buffpresent(trueshot_buff) and { buffstacks(unerring_vision_buff) > 4 or not hasazeritetrait(unerring_vision_trait) } or target.timetodie() < 11 spell(blood_of_the_enemy)
  #focused_azerite_beam,if=!buff.trueshot.up|target.time_to_die<5
  if not buffpresent(trueshot_buff) or target.timetodie() < 5 spell(focused_azerite_beam)
 }
}

AddFunction MarksmanshipStCdPostConditions
{
 spell(explosive_shot) or enemies() > 1 and spell(barrage) or spell(a_murder_of_crows) or target.refreshable(serpent_sting_mm_debuff) and not inflighttotarget(serpent_sting_mm) and spell(serpent_sting_mm) or { buffexpires(trueshot_buff) or focus() < 70 } and spell(rapid_fire) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot) or { buffpresent(trueshot_buff) or { buffexpires(double_tap_buff) or talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } } and buffexpires(precise_shots_buff) or spellfullrecharge(aimed_shot) < casttime(aimed_shot) and spellcooldown(trueshot) > 0 } and spell(aimed_shot) or buffpresent(trueshot_buff) and buffpresent(master_marksman_buff) and buffpresent(memory_of_lucid_dreams_essence_buff) and spell(arcane_shot) or spell(piercing_shot) or { not buffpresent(trueshot_buff) or target.timetodie() < 8 } and spell(purifying_blast) or { focus() + focusregenrate() * gcd() < maxfocus() and buffexpires(trueshot_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() or target.timetodie() < 5 } and spell(concentrated_flame_essence) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 or target.timetodie() < 5 } and spell(the_unbound_force) or buffexpires(trueshot_buff) and { buffpresent(precise_shots_buff) and { focus() > 41 or buffpresent(master_marksman_buff) } or { focus() > 50 and hasazeritetrait(focused_fire_trait) or focus() > 75 } and { spellcooldown(trueshot) > 5 or focus() > 80 } or target.timetodie() < 5 } and spell(arcane_shot) or spell(steady_shot)
}

### actions.precombat

AddFunction MarksmanshipPrecombatMainActions
{
 #hunters_mark
 spell(hunters_mark)
 #aimed_shot,if=active_enemies<3
 if enemies() < 3 spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatMainPostConditions
{
}

AddFunction MarksmanshipPrecombatShortCdActions
{
 unless spell(hunters_mark)
 {
  #double_tap,precast_time=10
  spell(double_tap)
  #worldvein_resonance
  spell(worldvein_resonance_essence)
 }
}

AddFunction MarksmanshipPrecombatShortCdPostConditions
{
 spell(hunters_mark) or enemies() < 3 and spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(hunters_mark) or spell(double_tap) or spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  spell(memory_of_lucid_dreams_essence)
  #use_item,name=azsharas_font_of_power
  marksmanshipuseitemactions()
  #trueshot,precast_time=1.5,if=active_enemies>2
  if enemies() > 2 spell(trueshot)
 }
}

AddFunction MarksmanshipPrecombatCdPostConditions
{
 spell(hunters_mark) or spell(double_tap) or spell(worldvein_resonance_essence) or enemies() < 3 and spell(aimed_shot)
}

### actions.cds

AddFunction MarksmanshipCdsMainActions
{
 #hunters_mark,if=debuff.hunters_mark.down&!buff.trueshot.up
 if target.DebuffExpires(hunters_mark_debuff) and not buffpresent(trueshot_buff) spell(hunters_mark)
}

AddFunction MarksmanshipCdsMainPostConditions
{
}

AddFunction MarksmanshipCdsShortCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and not buffpresent(trueshot_buff) and spell(hunters_mark)
 {
  #double_tap,if=cooldown.rapid_fire.remains<gcd|cooldown.rapid_fire.remains<cooldown.aimed_shot.remains|target.time_to_die<20
  if spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 spell(double_tap)
  #worldvein_resonance,if=buff.lifeblood.stack<4&!buff.trueshot.up
  if buffstacks(lifeblood_buff) < 4 and not buffpresent(trueshot_buff) spell(worldvein_resonance_essence)
  #ripple_in_space,if=cooldown.trueshot.remains<7
  if spellcooldown(trueshot) < 7 spell(ripple_in_space_essence)
 }
}

AddFunction MarksmanshipCdsShortCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and not buffpresent(trueshot_buff) and spell(hunters_mark)
}

AddFunction MarksmanshipCdsCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and not buffpresent(trueshot_buff) and spell(hunters_mark) or { spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 } and spell(double_tap)
 {
  #berserking,if=buff.trueshot.up&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<13
  if buffpresent(trueshot_buff) and { target.timetodie() > spellcooldownduration(berserking) + baseduration(berserking) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 13 spell(berserking)
  #blood_fury,if=buff.trueshot.up&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if buffpresent(trueshot_buff) and { target.timetodie() > spellcooldownduration(blood_fury_ap) + baseduration(blood_fury_ap) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 16 spell(blood_fury_ap)
  #ancestral_call,if=buff.trueshot.up&(target.time_to_die>cooldown.ancestral_call.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if buffpresent(trueshot_buff) and { target.timetodie() > spellcooldownduration(ancestral_call) + baseduration(ancestral_call) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 16 spell(ancestral_call)
  #fireblood,if=buff.trueshot.up&(target.time_to_die>cooldown.fireblood.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<9
  if buffpresent(trueshot_buff) and { target.timetodie() > spellcooldownduration(fireblood) + baseduration(fireblood) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 9 spell(fireblood)
  #lights_judgment
  spell(lights_judgment)

  unless buffstacks(lifeblood_buff) < 4 and not buffpresent(trueshot_buff) and spell(worldvein_resonance_essence)
  {
   #guardian_of_azeroth,if=(ca_execute|target.time_to_die>cooldown.guardian_of_azeroth.duration+duration)&(buff.trueshot.up|cooldown.trueshot.remains<16)|target.time_to_die<31
   if { talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } or target.timetodie() > spellcooldownduration(guardian_of_azeroth) + baseduration(guardian_of_azeroth) } and { buffpresent(trueshot_buff) or spellcooldown(trueshot) < 16 } or target.timetodie() < 31 spell(guardian_of_azeroth)

   unless spellcooldown(trueshot) < 7 and spell(ripple_in_space_essence)
   {
    #memory_of_lucid_dreams,if=!buff.trueshot.up
    if not buffpresent(trueshot_buff) spell(memory_of_lucid_dreams_essence)
    #potion,if=buff.trueshot.react&buff.bloodlust.react|buff.trueshot.up&ca_execute|((consumable.potion_of_unbridled_fury|consumable.unbridled_fury)&target.time_to_die<61|target.time_to_die<26)
    if { buffpresent(trueshot_buff) and buffpresent(bloodlust) or buffpresent(trueshot_buff) and talent(careful_aim_talent) and { target.healthpercent() > 80 or target.healthpercent() < 20 } or { buffpresent(unbridled_fury) or buffpresent(unbridled_fury) } and target.timetodie() < 61 or target.timetodie() < 26 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
    #trueshot,if=focus>60&(buff.precise_shots.down&cooldown.rapid_fire.remains&target.time_to_die>cooldown.trueshot.duration_guess+duration|target.health.pct<20|!talent.careful_aim.enabled)|target.time_to_die<15
    if focus() > 60 and { buffexpires(precise_shots_buff) and spellcooldown(rapid_fire) > 0 and target.timetodie() > 0 + baseduration(trueshot) or target.healthpercent() < 20 or not hastalent(careful_aim_talent) } or target.timetodie() < 15 spell(trueshot)
   }
  }
 }
}

AddFunction MarksmanshipCdsCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and not buffpresent(trueshot_buff) and spell(hunters_mark) or { spellcooldown(rapid_fire) < gcd() or spellcooldown(rapid_fire) < spellcooldown(aimed_shot) or target.timetodie() < 20 } and spell(double_tap) or buffstacks(lifeblood_buff) < 4 and not buffpresent(trueshot_buff) and spell(worldvein_resonance_essence) or spellcooldown(trueshot) < 7 and spell(ripple_in_space_essence)
}

### actions.default

AddFunction MarksmanshipDefaultMainActions
{
 #call_action_list,name=cds
 MarksmanshipCdsMainActions()

 unless MarksmanshipCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 MarksmanshipStMainActions()

  unless enemies() < 3 and MarksmanshipStMainPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 MarksmanshipTrickshotsMainActions()
  }
 }
}

AddFunction MarksmanshipDefaultMainPostConditions
{
 MarksmanshipCdsMainPostConditions() or enemies() < 3 and MarksmanshipStMainPostConditions() or enemies() > 2 and MarksmanshipTrickshotsMainPostConditions()
}

AddFunction MarksmanshipDefaultShortCdActions
{
 #call_action_list,name=cds
 MarksmanshipCdsShortCdActions()

 unless MarksmanshipCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 MarksmanshipStShortCdActions()

  unless enemies() < 3 and MarksmanshipStShortCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 MarksmanshipTrickshotsShortCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultShortCdPostConditions
{
 MarksmanshipCdsShortCdPostConditions() or enemies() < 3 and MarksmanshipStShortCdPostConditions() or enemies() > 2 and MarksmanshipTrickshotsShortCdPostConditions()
}

AddFunction MarksmanshipDefaultCdActions
{
 undefined()
 #auto_shot
 #use_item,name=galecallers_boon,if=buff.trueshot.up|!talent.calling_the_shots.enabled|target.time_to_die<10
 if buffpresent(trueshot_buff) or not hastalent(calling_the_shots_talent) or target.timetodie() < 10 marksmanshipuseitemactions()
 #use_item,name=pocketsized_computation_device,if=!buff.trueshot.up&!essence.blood_of_the_enemy.major.rank3|debuff.blood_of_the_enemy.up|target.time_to_die<5
 if not buffpresent(trueshot_buff) and not azeriteessenceismajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) or target.timetodie() < 5 marksmanshipuseitemactions()
 #use_items,if=buff.trueshot.up|!talent.calling_the_shots.enabled|target.time_to_die<20
 if buffpresent(trueshot_buff) or not hastalent(calling_the_shots_talent) or target.timetodie() < 20 marksmanshipuseitemactions()
 #call_action_list,name=cds
 MarksmanshipCdsCdActions()

 unless MarksmanshipCdsCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if enemies() < 3 MarksmanshipStCdActions()

  unless enemies() < 3 and MarksmanshipStCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if enemies() > 2 MarksmanshipTrickshotsCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultCdPostConditions
{
 MarksmanshipCdsCdPostConditions() or enemies() < 3 and MarksmanshipStCdPostConditions() or enemies() > 2 and MarksmanshipTrickshotsCdPostConditions()
}

### Marksmanship icons.

AddCheckBox(opt_hunter_marksmanship_aoe l(AOE) default specialization=marksmanship)

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=shortcd specialization=marksmanship
{
 if not incombat() marksmanshipprecombatshortcdactions()
 unless not incombat() and marksmanshipprecombatshortcdpostconditions()
 {
  marksmanshipdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=shortcd specialization=marksmanship
{
 if not incombat() marksmanshipprecombatshortcdactions()
 unless not incombat() and marksmanshipprecombatshortcdpostconditions()
 {
  marksmanshipdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=marksmanship
{
 if not incombat() marksmanshipprecombatmainactions()
 unless not incombat() and marksmanshipprecombatmainpostconditions()
 {
  marksmanshipdefaultmainactions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=aoe specialization=marksmanship
{
 if not incombat() marksmanshipprecombatmainactions()
 unless not incombat() and marksmanshipprecombatmainpostconditions()
 {
  marksmanshipdefaultmainactions()
 }
}

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=cd specialization=marksmanship
{
 if not incombat() marksmanshipprecombatcdactions()
 unless not incombat() and marksmanshipprecombatcdpostconditions()
 {
  marksmanshipdefaultcdactions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=cd specialization=marksmanship
{
 if not incombat() marksmanshipprecombatcdactions()
 unless not incombat() and marksmanshipprecombatcdpostconditions()
 {
  marksmanshipdefaultcdactions()
 }
}

### Required symbols
# a_murder_of_crows
# aimed_shot
# ancestral_call
# arcane_shot
# barrage
# berserking
# blood_fury_ap
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# calling_the_shots_talent
# careful_aim_talent
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# counter_shot
# double_tap
# double_tap_buff
# explosive_shot
# fireblood
# focused_azerite_beam
# focused_fire_trait
# guardian_of_azeroth
# hunters_mark
# hunters_mark_debuff
# in_the_rhythm_trait
# lifeblood_buff
# lights_judgment
# master_marksman_buff
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# multishot_mm
# piercing_shot
# precise_shots_buff
# purifying_blast
# quaking_palm
# rapid_fire
# reckless_force_buff
# reckless_force_counter_buff
# ripple_in_space_essence
# serpent_sting_mm
# serpent_sting_mm_debuff
# steady_shot
# streamline_talent
# surging_shots_trait
# the_unbound_force
# trick_shots_buff
# trueshot
# trueshot_buff
# unbridled_fury
# unbridled_fury_item
# unerring_vision_buff
# unerring_vision_trait
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
    end
    do
        local name = "sc_t23_hunter_survival"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Survival"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Survival".
#	class=hunter
#	spec=survival
#	talents=1101021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)


AddFunction carve_cdr
{
 if enemies() < 5 enemies()
 unless enemies() < 5 5
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=survival)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=survival)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=survival)
AddCheckBox(opt_harpoon spellname(harpoon) default specialization=survival)

AddFunction SurvivalInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(muzzle) and target.isinterruptible() spell(muzzle)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
 }
}

AddFunction SurvivalUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

AddFunction SurvivalSummonPet
{
 if not pet.present() and not pet.isdead() and not previousspell(revive_pet) texture(ability_hunter_beastcall help=l(summon_pet))
}

AddFunction SurvivalGetInMeleeRange
{
 if checkboxon(opt_melee_range) and not target.inrange(raptor_strike)
 {
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.wfi

AddFunction SurvivalWfiMainActions
{
 #harpoon,if=focus+cast_regen<focus.max&talent.terms_of_engagement.enabled
 if focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up&buff.vipers_venom.remains<1.5*gcd|!dot.serpent_sting.ticking
 if buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.DebuffPresent(serpent_sting_sv_debuff) spell(serpent_sting_sv)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max|(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 spell(wildfire_bomb)
 #kill_command,if=focus+cast_regen<focus.max-focus.regen
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() spell(kill_command_survival)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd
 if buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() spell(serpent_sting_sv)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking|buff.mongoose_fury.stack=5
 if target.DebuffPresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury_buff) == 5 spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&dot.serpent_sting.remains>5*gcd
 if spellusable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() spell(wildfire_bomb)
 #serpent_sting,if=refreshable
 if target.refreshable(serpent_sting_sv_debuff) spell(serpent_sting_sv)
 #chakrams,if=!buff.mongoose_fury.remains
 if not buffpresent(mongoose_fury_buff) spell(chakrams)
 #mongoose_bite
 spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up
 if buffpresent(vipers_venom_buff) spell(serpent_sting_sv)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel
 if spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) spell(wildfire_bomb)
}

AddFunction SurvivalWfiMainPostConditions
{
}

AddFunction SurvivalWfiShortCdActions
{
 unless focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.DebuffPresent(serpent_sting_sv_debuff) } and spell(serpent_sting_sv) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival)
 {
  #a_murder_of_crows
  spell(a_murder_of_crows)
  #steel_trap,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)
 }
}

AddFunction SurvivalWfiShortCdPostConditions
{
 focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.DebuffPresent(serpent_sting_sv_debuff) } and spell(serpent_sting_sv) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() and spell(serpent_sting_sv) or { target.DebuffPresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury_buff) == 5 } and spell(mongoose_bite) or spellusable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() and spell(wildfire_bomb) or target.refreshable(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or not buffpresent(mongoose_fury_buff) and spell(chakrams) or spell(mongoose_bite) or spell(raptor_strike) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv) or { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) } and spell(wildfire_bomb)
}

AddFunction SurvivalWfiCdActions
{
 unless focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.DebuffPresent(serpent_sting_sv_debuff) } and spell(serpent_sting_sv) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spell(a_murder_of_crows) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction SurvivalWfiCdPostConditions
{
 focus() + focuscastingregen(harpoon) < maxfocus() and hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or { buffpresent(vipers_venom_buff) and buffremaining(vipers_venom_buff) < 1.5 * gcd() or not target.DebuffPresent(serpent_sting_sv_debuff) } and spell(serpent_sting_sv) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and focus() + focuscastingregen(wildfire_bomb) < maxfocus() or spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } and spell(wildfire_bomb) or focus() + focuscastingregen(kill_command_survival) < maxfocus() - focusregenrate() and spell(kill_command_survival) or spell(a_murder_of_crows) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or spellfullrecharge(wildfire_bomb) < 1.5 * gcd() and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() and spell(serpent_sting_sv) or { target.DebuffPresent(shrapnel_bomb_debuff) or buffstacks(mongoose_fury_buff) == 5 } and spell(mongoose_bite) or spellusable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() and spell(wildfire_bomb) or target.refreshable(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or not buffpresent(mongoose_fury_buff) and spell(chakrams) or spell(mongoose_bite) or spell(raptor_strike) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv) or { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) } and spell(wildfire_bomb)
}

### actions.st

AddFunction SurvivalStMainActions
{
 #harpoon,if=talent.terms_of_engagement.enabled
 if hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } spell(raptor_strike)
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } spell(mongoose_bite)
 #kill_command,if=focus+cast_regen<focus.max
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&!ticking&!buff.memory_of_lucid_dreams.up&(full_recharge_time<1.5*gcd|!dot.wildfire_bomb.ticking&!buff.coordinated_assault.up|!dot.wildfire_bomb.ticking&buff.mongoose_fury.stack<1)
 if focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.stack>5&!cooldown.coordinated_assault.remains
 if buffstacks(mongoose_fury_buff) > 5 and not spellcooldown(coordinated_assault) > 0 spell(mongoose_bite)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd|dot.serpent_sting.refreshable&!buff.coordinated_assault.up
 if buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) spell(serpent_sting_sv)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-20&talent.vipers_venom.enabled|focus+cast_regen>focus.max-1&talent.terms_of_engagement.enabled|buff.coordinated_assault.up
 if buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault_buff) spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable
 if target.DebuffRefreshable(wildfire_bomb_debuff) spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up
 if buffpresent(vipers_venom_buff) spell(serpent_sting_sv)
}

AddFunction SurvivalStMainPostConditions
{
}

AddFunction SurvivalStShortCdActions
{
 unless hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

  unless buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)

   unless focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or buffstacks(mongoose_fury_buff) > 5 and not spellcooldown(coordinated_assault) > 0 and spell(mongoose_bite) or { buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) } and spell(serpent_sting_sv)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not buffpresent(coordinated_assault_buff) spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction SurvivalStShortCdPostConditions
{
 hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or buffstacks(mongoose_fury_buff) > 5 and not spellcooldown(coordinated_assault) > 0 and spell(mongoose_bite) or { buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) } and spell(serpent_sting_sv) or { buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault_buff) } and spell(mongoose_bite) or spell(raptor_strike) or target.DebuffRefreshable(wildfire_bomb_debuff) and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv)
}

AddFunction SurvivalStCdActions
{
 unless hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or buffstacks(mongoose_fury_buff) > 5 and not spellcooldown(coordinated_assault) > 0 and spell(mongoose_bite) or { buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) } and spell(serpent_sting_sv) or not buffpresent(coordinated_assault_buff) and spell(a_murder_of_crows)
 {
  #coordinated_assault,if=!buff.coordinated_assault.up
  if not buffpresent(coordinated_assault_buff) spell(coordinated_assault)
 }
}

AddFunction SurvivalStCdPostConditions
{
 hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or buffstacks(mongoose_fury_buff) > 5 and not spellcooldown(coordinated_assault) > 0 and spell(mongoose_bite) or { buffpresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * gcd() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) } and spell(serpent_sting_sv) or not buffpresent(coordinated_assault_buff) and spell(a_murder_of_crows) or { buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 20 and hastalent(vipers_venom_talent) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 1 and hastalent(terms_of_engagement_talent) or buffpresent(coordinated_assault_buff) } and spell(mongoose_bite) or spell(raptor_strike) or target.DebuffRefreshable(wildfire_bomb_debuff) and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv)
}

### actions.precombat

AddFunction SurvivalPrecombatMainActions
{
 #harpoon
 if checkboxon(opt_harpoon) spell(harpoon)
}

AddFunction SurvivalPrecombatMainPostConditions
{
}

AddFunction SurvivalPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 survivalsummonpet()
 #steel_trap
 spell(steel_trap)
}

AddFunction SurvivalPrecombatShortCdPostConditions
{
 checkboxon(opt_harpoon) and spell(harpoon)
}

AddFunction SurvivalPrecombatCdActions
{
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #use_item,name=azsharas_font_of_power
 survivaluseitemactions()
 #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists
 if not 0 survivaluseitemactions()
 #guardian_of_azeroth
 spell(guardian_of_azeroth)
}

AddFunction SurvivalPrecombatCdPostConditions
{
 spell(steel_trap) or checkboxon(opt_harpoon) and spell(harpoon)
}

### actions.cleave

AddFunction SurvivalCleaveMainActions
{
 #carve,if=dot.shrapnel_bomb.ticking
 if target.DebuffPresent(shrapnel_bomb_debuff) spell(carve)
 #wildfire_bomb,if=!talent.guerrilla_tactics.enabled|full_recharge_time<gcd
 if not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() spell(wildfire_bomb)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack=10
 if target.DebuffStacks(latent_poison) == 10 spell(mongoose_bite)
 #chakrams
 spell(chakrams)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() spell(kill_command_survival)
 #butchery,if=full_recharge_time<gcd|!talent.wildfire_infusion.enabled|dot.shrapnel_bomb.ticking&dot.internal_bleeding.stack<3
 if spellfullrecharge(butchery) < gcd() or not hastalent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 spell(butchery)
 #carve,if=talent.guerrilla_tactics.enabled
 if hastalent(guerrilla_tactics_talent) spell(carve)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable|talent.wildfire_infusion.enabled
 if target.DebuffRefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) spell(wildfire_bomb)
 #serpent_sting,target_if=min:remains,if=buff.vipers_venom.react
 if buffpresent(vipers_venom_buff) spell(serpent_sting_sv)
 #carve,if=cooldown.wildfire_bomb.remains>variable.carve_cdr%2
 if spellcooldown(wildfire_bomb) > undefined() / 2 spell(carve)
 #harpoon,if=talent.terms_of_engagement.enabled
 if hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) spell(harpoon)
 #serpent_sting,target_if=min:remains,if=refreshable&buff.tip_of_the_spear.stack<3
 if target.refreshable(serpent_sting_sv_debuff) and buffstacks(tip_of_the_spear_buff) < 3 spell(serpent_sting_sv)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack
 spell(mongoose_bite)
 #raptor_strike,target_if=max:debuff.latent_poison.stack
 spell(raptor_strike)
}

AddFunction SurvivalCleaveMainPostConditions
{
}

AddFunction SurvivalCleaveShortCdActions
{
 #variable,name=carve_cdr,op=setif,value=active_enemies,value_else=5,condition=active_enemies<5
 #a_murder_of_crows
 spell(a_murder_of_crows)

 unless target.DebuffPresent(shrapnel_bomb_debuff) and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() } and spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or { spellfullrecharge(butchery) < gcd() or not hastalent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and spell(butchery) or hastalent(guerrilla_tactics_talent) and spell(carve)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

  unless { target.DebuffRefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv) or spellcooldown(wildfire_bomb) > undefined() / 2 and spell(carve)
  {
   #steel_trap
   spell(steel_trap)
  }
 }
}

AddFunction SurvivalCleaveShortCdPostConditions
{
 target.DebuffPresent(shrapnel_bomb_debuff) and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() } and spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or { spellfullrecharge(butchery) < gcd() or not hastalent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and spell(butchery) or hastalent(guerrilla_tactics_talent) and spell(carve) or { target.DebuffRefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv) or spellcooldown(wildfire_bomb) > undefined() / 2 and spell(carve) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or target.refreshable(serpent_sting_sv_debuff) and buffstacks(tip_of_the_spear_buff) < 3 and spell(serpent_sting_sv) or spell(mongoose_bite) or spell(raptor_strike)
}

AddFunction SurvivalCleaveCdActions
{
 unless spell(a_murder_of_crows)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction SurvivalCleaveCdPostConditions
{
 spell(a_murder_of_crows) or target.DebuffPresent(shrapnel_bomb_debuff) and spell(carve) or { not hastalent(guerrilla_tactics_talent) or spellfullrecharge(wildfire_bomb) < gcd() } and spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and spell(mongoose_bite) or spell(chakrams) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and spell(kill_command_survival) or { spellfullrecharge(butchery) < gcd() or not hastalent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and spell(butchery) or hastalent(guerrilla_tactics_talent) and spell(carve) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or { target.DebuffRefreshable(wildfire_bomb_debuff) or hastalent(wildfire_infusion_talent) } and spell(wildfire_bomb) or buffpresent(vipers_venom_buff) and spell(serpent_sting_sv) or spellcooldown(wildfire_bomb) > undefined() / 2 and spell(carve) or spell(steel_trap) or hastalent(terms_of_engagement_talent) and checkboxon(opt_harpoon) and spell(harpoon) or target.refreshable(serpent_sting_sv_debuff) and buffstacks(tip_of_the_spear_buff) < 3 and spell(serpent_sting_sv) or spell(mongoose_bite) or spell(raptor_strike)
}

### actions.cds

AddFunction SurvivalCdsMainActions
{
 #concentrated_flame,if=full_recharge_time<1*gcd
 if spellfullrecharge(concentrated_flame_essence) < 1 * gcd() spell(concentrated_flame_essence)
}

AddFunction SurvivalCdsMainPostConditions
{
}

AddFunction SurvivalCdsShortCdActions
{
 #aspect_of_the_eagle,if=target.distance>=6
 if target.distance() >= 6 spell(aspect_of_the_eagle)
 #purifying_blast
 spell(purifying_blast)
 #ripple_in_space
 spell(ripple_in_space_essence)

 unless spellfullrecharge(concentrated_flame_essence) < 1 * gcd() and spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if buffpresent(reckless_force_buff) spell(the_unbound_force)
  #worldvein_resonance
  spell(worldvein_resonance_essence)
 }
}

AddFunction SurvivalCdsShortCdPostConditions
{
 spellfullrecharge(concentrated_flame_essence) < 1 * gcd() and spell(concentrated_flame_essence)
}

AddFunction SurvivalCdsCdActions
{
 #blood_fury,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(blood_fury_ap)
 #ancestral_call,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(ancestral_call)
 #fireblood,if=cooldown.coordinated_assault.remains>30
 if spellcooldown(coordinated_assault) > 30 spell(fireblood)
 #lights_judgment
 spell(lights_judgment)
 #berserking,if=cooldown.coordinated_assault.remains>60|time_to_die<13
 if spellcooldown(coordinated_assault) > 60 or target.timetodie() < 13 spell(berserking)
 #potion,if=buff.guardian_of_azeroth.up&(buff.berserking.up|buff.blood_fury.up|!race.troll)|(consumable.potion_of_unbridled_fury&target.time_to_die<61|target.time_to_die<26)|!essence.condensed_lifeforce.major&buff.coordinated_assault.up
 if { buffpresent(guardian_of_azeroth_buff) and { buffpresent(berserking_buff) or buffpresent(blood_fury_ap_buff) or not race(Troll) } or buffpresent(unbridled_fury) and target.timetodie() < 61 or target.timetodie() < 26 or not azeriteessenceismajor(condensed_life_force_essence_id) and buffpresent(coordinated_assault_buff) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless target.distance() >= 6 and spell(aspect_of_the_eagle)
 {
  #use_item,name=ashvanes_razor_coral,if=equipped.dribbling_inkpod&(debuff.razor_coral_debuff.down|time_to_pct_30<1|(health.pct<30&buff.guardian_of_azeroth.up|buff.memory_of_lucid_dreams.up))|(!equipped.dribbling_inkpod&(buff.memory_of_lucid_dreams.up|buff.guardian_of_azeroth.up&cooldown.guardian_of_azeroth.remains>175)|debuff.razor_coral_debuff.down)|target.time_to_die<20
  if hasequippeditem(dribbling_inkpod_item) and { target.DebuffExpires(razor_coral) or timetohealthpercent(30) < 1 or healthpercent() < 30 and buffpresent(guardian_of_azeroth_buff) or buffpresent(memory_of_lucid_dreams_essence_buff) } or not hasequippeditem(dribbling_inkpod_item) and { buffpresent(memory_of_lucid_dreams_essence_buff) or buffpresent(guardian_of_azeroth_buff) and spellcooldown(guardian_of_azeroth) > 175 } or target.DebuffExpires(razor_coral) or target.timetodie() < 20 survivaluseitemactions()
  #use_item,name=galecallers_boon,if=cooldown.memory_of_lucid_dreams.remains|talent.wildfire_infusion.enabled&cooldown.coordinated_assault.remains|cooldown.cyclotronic_blast.remains|!essence.memory_of_lucid_dreams.major&cooldown.coordinated_assault.remains
  if spellcooldown(memory_of_lucid_dreams_essence) > 0 or hastalent(wildfire_infusion_talent) and spellcooldown(coordinated_assault) > 0 or spellcooldown(cyclotronic_blast) > 0 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) and spellcooldown(coordinated_assault) > 0 survivaluseitemactions()
  #use_item,name=azsharas_font_of_power
  survivaluseitemactions()
  #focused_azerite_beam
  spell(focused_azerite_beam)
  #memory_of_lucid_dreams,if=focus<focus.max-30&buff.coordinated_assault.up
  if focus() < maxfocus() - 30 and buffpresent(coordinated_assault_buff) spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy,if=buff.coordinated_assault.up
  if buffpresent(coordinated_assault_buff) spell(blood_of_the_enemy)

  unless spell(purifying_blast)
  {
   #guardian_of_azeroth
   spell(guardian_of_azeroth)
  }
 }
}

AddFunction SurvivalCdsCdPostConditions
{
 target.distance() >= 6 and spell(aspect_of_the_eagle) or spell(purifying_blast) or spell(ripple_in_space_essence) or spellfullrecharge(concentrated_flame_essence) < 1 * gcd() and spell(concentrated_flame_essence) or buffpresent(reckless_force_buff) and spell(the_unbound_force) or spell(worldvein_resonance_essence)
}

### actions.apwfi

AddFunction SurvivalApwfiMainActions
{
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() spell(raptor_strike)
 #serpent_sting,if=!dot.serpent_sting.ticking
 if not target.DebuffPresent(serpent_sting_sv_debuff) spell(serpent_sting_sv)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd|focus+cast_regen<focus.max&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.remains&next_wi_bomb.pheromone
 if buffpresent(mongoose_fury_buff) and spellusable(270323) spell(mongoose_bite)
 #kill_command,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max-20
 if spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 spell(kill_command_survival)
 #raptor_strike,if=buff.tip_of_the_spear.stack=3|dot.shrapnel_bomb.ticking
 if buffstacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) spell(raptor_strike)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking
 if target.DebuffPresent(shrapnel_bomb_debuff) spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&focus>30&dot.serpent_sting.remains>5*gcd
 if spellusable(270335) and focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() spell(wildfire_bomb)
 #chakrams,if=!buff.mongoose_fury.remains
 if not buffpresent(mongoose_fury_buff) spell(chakrams)
 #serpent_sting,if=refreshable
 if target.refreshable(serpent_sting_sv_debuff) spell(serpent_sting_sv)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } spell(kill_command_survival)
 #raptor_strike
 spell(raptor_strike)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>40|dot.shrapnel_bomb.ticking
 if buffpresent(mongoose_fury_buff) or focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50
 if spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) and focus() > 50 spell(wildfire_bomb)
}

AddFunction SurvivalApwfiMainPostConditions
{
}

AddFunction SurvivalApwfiShortCdActions
{
 unless buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and spell(serpent_sting_sv)
 {
  #a_murder_of_crows
  spell(a_murder_of_crows)

  unless { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury_buff) and spellusable(270323) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)
  }
 }
}

AddFunction SurvivalApwfiShortCdPostConditions
{
 buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury_buff) and spellusable(270323) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival) or { buffstacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) } and spell(raptor_strike) or target.DebuffPresent(shrapnel_bomb_debuff) and spell(mongoose_bite) or spellusable(270335) and focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() and spell(wildfire_bomb) or not buffpresent(mongoose_fury_buff) and spell(chakrams) or target.refreshable(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or spell(raptor_strike) or { buffpresent(mongoose_fury_buff) or focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) } and spell(mongoose_bite) or { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) and focus() > 50 } and spell(wildfire_bomb)
}

AddFunction SurvivalApwfiCdActions
{
 unless buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or spell(a_murder_of_crows) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb)
 {
  #coordinated_assault
  spell(coordinated_assault)
 }
}

AddFunction SurvivalApwfiCdPostConditions
{
 buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(mongoose_bite) or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < gcd() and spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or spell(a_murder_of_crows) or { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or spellusable(270323) and not buffpresent(mongoose_fury_buff) and focus() + focuscastingregen(wildfire_bomb) < maxfocus() - focuscastingregen(kill_command_survival) * 3 } } and spell(wildfire_bomb) or buffpresent(mongoose_fury_buff) and spellusable(270323) and spell(mongoose_bite) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 20 and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or { buffstacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) } and spell(raptor_strike) or target.DebuffPresent(shrapnel_bomb_debuff) and spell(mongoose_bite) or spellusable(270335) and focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * gcd() and spell(wildfire_bomb) or not buffpresent(mongoose_fury_buff) and spell(chakrams) or target.refreshable(serpent_sting_sv_debuff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or spell(raptor_strike) or { buffpresent(mongoose_fury_buff) or focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) } and spell(mongoose_bite) or { spellusable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or spellusable(270323) or spellusable(270335) and focus() > 50 } and spell(wildfire_bomb)
}

### actions.apst

AddFunction SurvivalApstMainActions
{
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } spell(mongoose_bite)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } spell(raptor_strike)
 #kill_command,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max-10
 if spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 10 spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&!ticking&!buff.memory_of_lucid_dreams.up&(full_recharge_time<1.5*gcd|!dot.wildfire_bomb.ticking&!buff.coordinated_assault.up|!dot.wildfire_bomb.ticking&buff.mongoose_fury.stack<1)
 if focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } spell(wildfire_bomb)
 #serpent_sting,if=!dot.serpent_sting.ticking&!buff.coordinated_assault.up
 if not target.DebuffPresent(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) spell(serpent_sting_sv)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } spell(kill_command_survival)
 #serpent_sting,if=refreshable&!buff.coordinated_assault.up&buff.mongoose_fury.stack<5
 if target.refreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and buffstacks(mongoose_fury_buff) < 5 spell(serpent_sting_sv)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-10|buff.coordinated_assault.up
 if buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault_buff) spell(mongoose_bite)
 #raptor_strike
 spell(raptor_strike)
 #wildfire_bomb,if=!ticking
 if not target.DebuffPresent(wildfire_bomb_debuff) spell(wildfire_bomb)
}

AddFunction SurvivalApstMainPostConditions
{
}

AddFunction SurvivalApstShortCdActions
{
 unless buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if focus() + focuscastingregen(flanking_strike) < maxfocus() spell(flanking_strike)

  unless spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 10 and spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if focus() + focuscastingregen(steel_trap) < maxfocus() spell(steel_trap)

   unless focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and buffstacks(mongoose_fury_buff) < 5 and spell(serpent_sting_sv)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not buffpresent(coordinated_assault_buff) spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction SurvivalApstShortCdPostConditions
{
 buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 10 and spell(kill_command_survival) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and buffstacks(mongoose_fury_buff) < 5 and spell(serpent_sting_sv) or { buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault_buff) } and spell(mongoose_bite) or spell(raptor_strike) or not target.DebuffPresent(wildfire_bomb_debuff) and spell(wildfire_bomb)
}

AddFunction SurvivalApstCdActions
{
 unless buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 10 and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and buffstacks(mongoose_fury_buff) < 5 and spell(serpent_sting_sv) or not buffpresent(coordinated_assault_buff) and spell(a_murder_of_crows)
 {
  #coordinated_assault,if=!buff.coordinated_assault.up
  if not buffpresent(coordinated_assault_buff) spell(coordinated_assault)
 }
}

AddFunction SurvivalApstCdPostConditions
{
 buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(mongoose_bite) or buffpresent(coordinated_assault_buff) and { buffremaining(coordinated_assault_buff) < 1.5 * gcd() or buffpresent(blur_of_talons_buff) and buffremaining(blur_of_talons_buff) < 1.5 * gcd() } and spell(raptor_strike) or focus() + focuscastingregen(flanking_strike) < maxfocus() and spell(flanking_strike) or spellfullrecharge(kill_command_survival) < 1.5 * gcd() and focus() + focuscastingregen(kill_command_survival) < maxfocus() - 10 and spell(kill_command_survival) or focus() + focuscastingregen(steel_trap) < maxfocus() and spell(steel_trap) or focus() + focuscastingregen(wildfire_bomb) < maxfocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(memory_of_lucid_dreams_essence_buff) and { spellfullrecharge(wildfire_bomb) < 1.5 * gcd() or not target.DebuffPresent(wildfire_bomb_debuff) and not buffpresent(coordinated_assault_buff) or not target.DebuffPresent(wildfire_bomb_debuff) and buffstacks(mongoose_fury_buff) < 1 } and spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and spell(serpent_sting_sv) or focus() + focuscastingregen(kill_command_survival) < maxfocus() and { buffstacks(mongoose_fury_buff) < 5 or focus() < powercost(mongoose_bite) } and spell(kill_command_survival) or target.refreshable(serpent_sting_sv_debuff) and not buffpresent(coordinated_assault_buff) and buffstacks(mongoose_fury_buff) < 5 and spell(serpent_sting_sv) or not buffpresent(coordinated_assault_buff) and spell(a_murder_of_crows) or { buffpresent(mongoose_fury_buff) or focus() + focuscastingregen(mongoose_bite) > maxfocus() - 10 or buffpresent(coordinated_assault_buff) } and spell(mongoose_bite) or spell(raptor_strike) or not target.DebuffPresent(wildfire_bomb_debuff) and spell(wildfire_bomb)
}

### actions.default

AddFunction SurvivalDefaultMainActions
{
 #call_action_list,name=cds
 SurvivalCdsMainActions()

 unless SurvivalCdsMainPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) SurvivalApwfiMainActions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiMainPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) SurvivalWfiMainActions()

   unless enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiMainPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalStMainActions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStMainPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalApstMainActions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstMainPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalApwfiMainActions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiMainPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalWfiMainActions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiMainPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if enemies() > 1 SurvivalCleaveMainActions()

        unless enemies() > 1 and SurvivalCleaveMainPostConditions()
        {
         #concentrated_flame
         spell(concentrated_flame_essence)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultMainPostConditions
{
 SurvivalCdsMainPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiMainPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiMainPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStMainPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstMainPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiMainPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiMainPostConditions() or enemies() > 1 and SurvivalCleaveMainPostConditions()
}

AddFunction SurvivalDefaultShortCdActions
{
 #auto_attack
 survivalgetinmeleerange()
 #call_action_list,name=cds
 SurvivalCdsShortCdActions()

 unless SurvivalCdsShortCdPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) SurvivalApwfiShortCdActions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiShortCdPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) SurvivalWfiShortCdActions()

   unless enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalStShortCdActions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStShortCdPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalApstShortCdActions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstShortCdPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalApwfiShortCdActions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiShortCdPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalWfiShortCdActions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiShortCdPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if enemies() > 1 SurvivalCleaveShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultShortCdPostConditions
{
 SurvivalCdsShortCdPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiShortCdPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiShortCdPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStShortCdPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstShortCdPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiShortCdPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiShortCdPostConditions() or enemies() > 1 and SurvivalCleaveShortCdPostConditions() or spell(concentrated_flame_essence)
}

AddFunction SurvivalDefaultCdActions
{
 undefined()
 #use_items
 survivaluseitemactions()
 #call_action_list,name=cds
 SurvivalCdsCdActions()

 unless SurvivalCdsCdPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) SurvivalApwfiCdActions()

  unless enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiCdPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if enemies() < 3 and hastalent(chakrams_talent) SurvivalWfiCdActions()

   unless enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalStCdActions()

    unless enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStCdPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) SurvivalApstCdActions()

     unless enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstCdPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalApwfiCdActions()

      unless enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiCdPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) SurvivalWfiCdActions()

       unless enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiCdPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if enemies() > 1 SurvivalCleaveCdActions()

        unless enemies() > 1 and SurvivalCleaveCdPostConditions() or spell(concentrated_flame_essence)
        {
         #arcane_torrent
         spell(arcane_torrent_focus)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultCdPostConditions
{
 SurvivalCdsCdPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and hastalent(alpha_predator_talent) and SurvivalApwfiCdPostConditions() or enemies() < 3 and hastalent(chakrams_talent) and SurvivalWfiCdPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalStCdPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and not hastalent(wildfire_infusion_talent) and SurvivalApstCdPostConditions() or enemies() < 3 and hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalApwfiCdPostConditions() or enemies() < 3 and not hastalent(alpha_predator_talent) and hastalent(wildfire_infusion_talent) and SurvivalWfiCdPostConditions() or enemies() > 1 and SurvivalCleaveCdPostConditions() or spell(concentrated_flame_essence)
}

### Survival icons.

AddCheckBox(opt_hunter_survival_aoe l(AOE) default specialization=survival)

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=shortcd specialization=survival
{
 if not incombat() survivalprecombatshortcdactions()
 unless not incombat() and survivalprecombatshortcdpostconditions()
 {
  survivaldefaultshortcdactions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=shortcd specialization=survival
{
 if not incombat() survivalprecombatshortcdactions()
 unless not incombat() and survivalprecombatshortcdpostconditions()
 {
  survivaldefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=survival
{
 if not incombat() survivalprecombatmainactions()
 unless not incombat() and survivalprecombatmainpostconditions()
 {
  survivaldefaultmainactions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=aoe specialization=survival
{
 if not incombat() survivalprecombatmainactions()
 unless not incombat() and survivalprecombatmainpostconditions()
 {
  survivaldefaultmainactions()
 }
}

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=cd specialization=survival
{
 if not incombat() survivalprecombatcdactions()
 unless not incombat() and survivalprecombatcdpostconditions()
 {
  survivaldefaultcdactions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=cd specialization=survival
{
 if not incombat() survivalprecombatcdactions()
 unless not incombat() and survivalprecombatcdpostconditions()
 {
  survivaldefaultcdactions()
 }
}

### Required symbols
# a_murder_of_crows
# alpha_predator_talent
# ancestral_call
# arcane_torrent_focus
# aspect_of_the_eagle
# berserking
# berserking_buff
# blood_fury_ap
# blood_fury_ap_buff
# blood_of_the_enemy
# blur_of_talons_buff
# butchery
# carve
# chakrams
# chakrams_talent
# concentrated_flame_essence
# condensed_life_force_essence_id
# coordinated_assault
# coordinated_assault_buff
# cyclotronic_blast
# dribbling_inkpod_item
# fireblood
# flanking_strike
# focused_azerite_beam
# guardian_of_azeroth
# guardian_of_azeroth_buff
# guerrilla_tactics_talent
# harpoon
# internal_bleeding_debuff
# kill_command_survival
# latent_poison
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# mongoose_bite
# mongoose_fury_buff
# muzzle
# purifying_blast
# quaking_palm
# raptor_strike
# razor_coral
# reckless_force_buff
# revive_pet
# ripple_in_space_essence
# serpent_sting_sv
# serpent_sting_sv_debuff
# shrapnel_bomb_debuff
# steel_trap
# terms_of_engagement_talent
# the_unbound_force
# tip_of_the_spear_buff
# unbridled_fury
# unbridled_fury_item
# vipers_venom_buff
# vipers_venom_talent
# war_stomp
# wildfire_bomb
# wildfire_bomb_debuff
# wildfire_infusion_talent
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
    end
end
