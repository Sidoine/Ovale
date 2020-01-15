local __exports = LibStub:NewLibrary("ovale/scripts/ovale_rogue", 80201)
if not __exports then return end
__exports.registerRogue = function(OvaleScripts)
    do
        local name = "sc_t23_rogue_assassination"
        local desc = "[8.2] Simulationcraft: T23_Rogue_Assassination"
        local code = [[
# Based on SimulationCraft profile "T23_Rogue_Assassination".
#	class=rogue
#	spec=assassination
#	talents=2310021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction single_target
{
 enemies() < 2
}

AddFunction energy_regen_combined
{
 energyregenrate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + spellcastspeedpercent() } } }
}

AddFunction ss_vanish_condition
{
 hasazeritetrait(shrouded_suffocation_trait) and { enemies() - DebuffCountOnAny(garrote_debuff) >= 1 or enemies() == 3 } and { 0 == 0 or enemies() >= 6 }
}

AddFunction use_filler
{
 combopointsdeficit() > 1 or energydeficit() <= 25 + undefined() or not undefined()
}

AddFunction skip_rupture
{
 target.DebuffPresent(vendetta_debuff) and { target.DebuffPresent(toxic_blade_debuff) or buffremaining(master_assassin_buff) > 0 } and target.DebuffRemaining(rupture_debuff) > 2
}

AddFunction skip_cycle_rupture
{
 checkboxon(opt_priority_rotation) and enemies() > 3 and { target.DebuffPresent(toxic_blade_debuff) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 and not hasazeritetrait(scent_of_blood_trait) }
}

AddFunction skip_cycle_garrote
{
 checkboxon(opt_priority_rotation) and enemies() > 3 and { target.DebuffRemaining(garrote_debuff) < spellcooldownduration(garrote) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 }
}

AddCheckBox(opt_priority_rotation l(opt_priority_rotation) default specialization=assassination)
AddCheckBox(opt_interrupt l(interrupt) default specialization=assassination)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=assassination)
AddCheckBox(opt_vanish spellname(vanish) default specialization=assassination)

AddFunction AssassinationInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(kick) and target.isinterruptible() spell(kick)
  if target.inrange(cheap_shot) and not target.classification(worldboss) spell(cheap_shot)
  if target.inrange(kidney_shot) and not target.classification(worldboss) and combopoints() >= 1 spell(kidney_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction AssassinationUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

AddFunction AssassinationGetInMeleeRange
{
 if checkboxon(opt_melee_range) and not target.inrange(kick)
 {
  spell(shadowstep)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.stealthed

AddFunction AssassinationStealthedMainActions
{
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6
 if combopoints() >= 4 and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and { hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and undefined() } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 6 spell(rupture)
 #pool_resource,for_next=1
 #garrote,if=azerite.shrouded_suffocation.enabled&buff.subterfuge.up&buff.subterfuge.remains<1.3&!ss_buffed
 if hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) spell(garrote)
 unless hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote)
 {
  #pool_resource,for_next=1
  #garrote,target_if=min:remains,if=talent.subterfuge.enabled&(remains<12|pmultiplier<=1)&target.time_to_die-remains>2
  if hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 spell(garrote)
  unless hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote)
  {
   #rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking&variable.single_target
   if hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and undefined() spell(rupture)
   #pool_resource,for_next=1
   #garrote,target_if=min:remains,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&target.time_to_die>remains&(remains<18|!ss_buffed)
   if hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } spell(garrote)
   unless hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote)
   {
    #pool_resource,for_next=1
    #garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend
    if hastalent(subterfuge_talent) and hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) < 1 and previousgcdspell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * maxcombopoints() spell(garrote)
   }
  }
 }
}

AddFunction AssassinationStealthedMainPostConditions
{
}

AddFunction AssassinationStealthedShortCdActions
{
}

AddFunction AssassinationStealthedShortCdPostConditions
{
 combopoints() >= 4 and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and { hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and undefined() } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 6 and spell(rupture) or hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) and spell(garrote) or not { hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 and spell(garrote) or not { hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and undefined() and spell(rupture) or hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } and spell(garrote) or not { hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and hastalent(subterfuge_talent) and hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) < 1 and previousgcdspell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * maxcombopoints() and spell(garrote) } }
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 combopoints() >= 4 and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and { hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and undefined() } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 6 and spell(rupture) or hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) and spell(garrote) or not { hasazeritetrait(shrouded_suffocation_trait) and buffpresent(subterfuge_buff) and buffremaining(subterfuge_buff) < 1.3 and not false(ss_buffed) and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 and spell(garrote) or not { hastalent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or persistentmultiplier(garrote_debuff) <= 1 } and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 2 and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and undefined() and spell(rupture) or hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } and spell(garrote) or not { hastalent(subterfuge_talent) and hasazeritetrait(shrouded_suffocation_trait) and target.timetodie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not false(ss_buffed) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and hastalent(subterfuge_talent) and hastalent(exsanguinate_talent) and spellcooldown(exsanguinate) < 1 and previousgcdspell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * maxcombopoints() and spell(garrote) } }
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
 #apply_poison
 #stealth
 spell(stealth)
}

AddFunction AssassinationPrecombatMainPostConditions
{
}

AddFunction AssassinationPrecombatShortCdActions
{
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>15
 if 600 > 15 spell(marked_for_death)
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
 spell(stealth)
}

AddFunction AssassinationPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless 600 > 15 and spell(marked_for_death) or spell(stealth)
 {
  #use_item,name=azsharas_font_of_power
  assassinationuseitemactions()
 }
}

AddFunction AssassinationPrecombatCdPostConditions
{
 600 > 15 and spell(marked_for_death) or spell(stealth)
}

### actions.essences

AddFunction AssassinationEssencesMainActions
{
 #concentrated_flame,if=energy.time_to_max>1&!debuff.vendetta.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if timetomaxenergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } spell(concentrated_flame_essence)
}

AddFunction AssassinationEssencesMainPostConditions
{
}

AddFunction AssassinationEssencesShortCdActions
{
 unless timetomaxenergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60
  if enemies() >= 2 or 600 > 60 spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
 }
}

AddFunction AssassinationEssencesShortCdPostConditions
{
 timetomaxenergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
}

AddFunction AssassinationEssencesCdActions
{
 unless timetomaxenergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up&combo_points.deficit<=1|debuff.vendetta.remains<=10)|target.time_to_die<=10
  if target.DebuffPresent(vendetta_debuff) and { not hastalent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) and combopointsdeficit() <= 1 or target.DebuffRemaining(vendetta_debuff) <= 10 } or target.timetodie() <= 10 spell(blood_of_the_enemy)
  #guardian_of_azeroth,if=cooldown.vendetta.remains<3|debuff.vendetta.up|target.time_to_die<30
  if spellcooldown(vendetta) < 3 or target.DebuffPresent(vendetta_debuff) or target.timetodie() < 30 spell(guardian_of_azeroth)
  #guardian_of_azeroth,if=floor((target.time_to_die-30)%cooldown)>floor((target.time_to_die-30-cooldown.vendetta.remains)%cooldown)
  if { target.timetodie() - 30 } / spellcooldown(guardian_of_azeroth) > { target.timetodie() - 30 - spellcooldown(vendetta) } / spellcooldown(guardian_of_azeroth) spell(guardian_of_azeroth)
  #focused_azerite_beam,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60&energy<70
  if enemies() >= 2 or 600 > 60 and energy() < 70 spell(focused_azerite_beam)

  unless { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=energy<50&!cooldown.vendetta.up
   if energy() < 50 and not { not spellcooldown(vendetta) > 0 } spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction AssassinationEssencesCdPostConditions
{
 timetomaxenergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
}

### actions.dot

AddFunction AssassinationDotMainActions
{
 #variable,name=skip_cycle_garrote,value=priority_rotation&spell_targets.fan_of_knives>3&(dot.garrote.remains<cooldown.garrote.duration|poisoned_bleeds>5)
 #variable,name=skip_cycle_rupture,value=priority_rotation&spell_targets.fan_of_knives>3&(debuff.toxic_blade.up|(poisoned_bleeds>5&!azerite.scent_of_blood.enabled))
 #variable,name=skip_rupture,value=debuff.vendetta.up&(debuff.toxic_blade.up|master_assassin_remains>0)&dot.rupture.remains>2
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)))
 if hastalent(exsanguinate_talent) and { combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { timeincombat() > 10 or combopoints() >= 2 } } spell(rupture)
 #pool_resource,for_next=1
 #garrote,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>4&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
 if { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } spell(garrote)
 unless { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote)
 {
  #pool_resource,for_next=1
  #garrote,cycle_targets=1,if=!variable.skip_cycle_garrote&target!=self.target&(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>12&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
  if not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } spell(garrote)
  unless not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote)
  {
   #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
   if enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { enemies() >= 5 } and combopoints() >= 4 spell(crimson_tempest)
   #rupture,if=!variable.skip_rupture&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
   if not undefined() and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 spell(rupture)
   #rupture,cycle_targets=1,if=!variable.skip_cycle_rupture&!variable.skip_rupture&target!=self.target&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
   if not undefined() and not undefined() and not false(target_is_target) and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 spell(rupture)
  }
 }
}

AddFunction AssassinationDotMainPostConditions
{
}

AddFunction AssassinationDotShortCdActions
{
}

AddFunction AssassinationDotShortCdPostConditions
{
 hastalent(exsanguinate_talent) and { combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { timeincombat() > 10 or combopoints() >= 2 } } and spell(rupture) or { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spell(garrote) or not { { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spell(garrote) or not { not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { enemies() >= 5 } and combopoints() >= 4 and spell(crimson_tempest) or not undefined() and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 and spell(rupture) or not undefined() and not undefined() and not false(target_is_target) and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 and spell(rupture) } }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 hastalent(exsanguinate_talent) and { combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { timeincombat() > 10 or combopoints() >= 2 } } and spell(rupture) or { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spell(garrote) or not { { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 4 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spell(garrote) or not { not undefined() and not false(target_is_target) and { not hastalent(subterfuge_talent) or not { not spellcooldown(vanish) > 0 and spellcooldown(vendetta) <= 4 } } and combopointsdeficit() >= 1 + 3 * { hasazeritetrait(shrouded_suffocation_trait) and not spellcooldown(vanish) > 0 } and target.refreshable(garrote_debuff) and { persistentmultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.currentticktime(garrote_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and not false(ss_buffed) and target.timetodie() - target.DebuffRemaining(garrote_debuff) > 12 and { buffremaining(master_assassin_buff) == 0 or not target.DebuffPresent(garrote_debuff) and hasazeritetrait(shrouded_suffocation_trait) } and spellusable(garrote) and spellcooldown(garrote) < timetoenergyfor(garrote) } and { enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { enemies() >= 5 } and combopoints() >= 4 and spell(crimson_tempest) or not undefined() and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 and spell(rupture) or not undefined() and not undefined() and not false(target_is_target) and combopoints() >= 4 and target.refreshable(rupture_debuff) and { persistentmultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.currentticktime(rupture_debuff) * 2 and enemies() >= 3 + hasazeritetrait(shrouded_suffocation_trait) } and target.timetodie() - target.DebuffRemaining(rupture_debuff) > 4 and spell(rupture) } }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if combopoints() >= 4 + talentpoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or energydeficit() <= 25 + undefined() or not undefined() } and { not hastalent(exsanguinate_talent) or spellcooldown(exsanguinate) > 2 } spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
 #fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2
 if undefined() and hasazeritetrait(echoing_blades_trait) and enemies() >= 2 spell(fan_of_knives)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|(!priority_rotation&spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue))
 if undefined() and { buffstacks(hidden_blades_buff) >= 19 or not checkboxon(opt_priority_rotation) and enemies() >= 4 + { azeritetraitrank(double_dose_trait) > 2 } + stealthed() } spell(fan_of_knives)
 #fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
 if not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() >= 3 spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
 if undefined() and { buffpresent(blindside_buff) or not hastalent(venom_rush_talent) and not hasazeritetrait(double_dose_trait) } spell(blindside)
 #mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
 if not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() == 2 spell(mutilate)
 #mutilate,if=variable.use_filler
 if undefined() spell(mutilate)
}

AddFunction AssassinationDirectMainPostConditions
{
}

AddFunction AssassinationDirectShortCdActions
{
}

AddFunction AssassinationDirectShortCdPostConditions
{
 combopoints() >= 4 + talentpoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or energydeficit() <= 25 + undefined() or not undefined() } and { not hastalent(exsanguinate_talent) or spellcooldown(exsanguinate) > 2 } and spell(envenom) or undefined() and hasazeritetrait(echoing_blades_trait) and enemies() >= 2 and spell(fan_of_knives) or undefined() and { buffstacks(hidden_blades_buff) >= 19 or not checkboxon(opt_priority_rotation) and enemies() >= 4 + { azeritetraitrank(double_dose_trait) > 2 } + stealthed() } and spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() >= 3 and spell(fan_of_knives) or undefined() and { buffpresent(blindside_buff) or not hastalent(venom_rush_talent) and not hasazeritetrait(double_dose_trait) } and spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() == 2 and spell(mutilate) or undefined() and spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 combopoints() >= 4 + talentpoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or energydeficit() <= 25 + undefined() or not undefined() } and { not hastalent(exsanguinate_talent) or spellcooldown(exsanguinate) > 2 } and spell(envenom) or undefined() and hasazeritetrait(echoing_blades_trait) and enemies() >= 2 and spell(fan_of_knives) or undefined() and { buffstacks(hidden_blades_buff) >= 19 or not checkboxon(opt_priority_rotation) and enemies() >= 4 + { azeritetraitrank(double_dose_trait) > 2 } + stealthed() } and spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() >= 3 and spell(fan_of_knives) or undefined() and { buffpresent(blindside_buff) or not hastalent(venom_rush_talent) and not hasazeritetrait(double_dose_trait) } and spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and undefined() and enemies() == 2 and spell(mutilate) or undefined() and spell(mutilate)
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&master_assassin_remains=0
 if not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 AssassinationEssencesMainActions()

 unless not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesMainPostConditions()
 {
  #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
  #pool_resource,for_next=1,extra_amount=45
  #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
  unless hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) and spellusable(vanish) and spellcooldown(vanish) < timetoenergy(45)
  {
   #exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable
   if target.DebuffRemaining(rupture_debuff) > 4 + 4 * maxcombopoints() and not target.DebuffRefreshable(garrote_debuff) spell(exsanguinate)
   #toxic_blade,if=dot.rupture.ticking
   if target.DebuffPresent(rupture_debuff) spell(toxic_blade)
  }
 }
}

AddFunction AssassinationCdsMainPostConditions
{
 not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesMainPostConditions()
}

AddFunction AssassinationCdsShortCdActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&master_assassin_remains=0
 if not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 AssassinationEssencesShortCdActions()

 unless not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesShortCdPostConditions()
 {
  #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
  if false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() * 1.5 or combopointsdeficit() >= maxcombopoints() } spell(marked_for_death)
  #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
  if 600 > 30 - 10 and combopointsdeficit() >= maxcombopoints() spell(marked_for_death)
  #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1)
  if hastalent(exsanguinate_talent) and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and undefined() } and combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 and { not hastalent(subterfuge_talent) or not hasazeritetrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and checkboxon(opt_vanish) spell(vanish)
  #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
  if hastalent(nightstalker_talent) and not hastalent(exsanguinate_talent) and combopoints() >= maxcombopoints() and target.DebuffPresent(vendetta_debuff) and checkboxon(opt_vanish) spell(vanish)
  #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
  #pool_resource,for_next=1,extra_amount=45
  #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
  if hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) spell(vanish)
  unless hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) and spellusable(vanish) and spellcooldown(vanish) < timetoenergy(45)
  {
   #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable&dot.garrote.remains>3&debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up)&(!essence.blood_of_the_enemy.major|debuff.blood_of_the_enemy.up)
   if hastalent(master_assassin_talent) and not stealthed() and buffremaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and target.DebuffRemaining(garrote_debuff) > 3 and target.DebuffPresent(vendetta_debuff) and { not hastalent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) } and checkboxon(opt_vanish) spell(vanish)
  }
 }
}

AddFunction AssassinationCdsShortCdPostConditions
{
 not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesShortCdPostConditions() or not { hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) and spellusable(vanish) and spellcooldown(vanish) < timetoenergy(45) } and { target.DebuffRemaining(rupture_debuff) > 4 + 4 * maxcombopoints() and not target.DebuffRefreshable(garrote_debuff) and spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and spell(toxic_blade) }
}

AddFunction AssassinationCdsCdActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&master_assassin_remains=0
 if not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 AssassinationEssencesCdActions()

 unless not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesCdPostConditions() or false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() * 1.5 or combopointsdeficit() >= maxcombopoints() } and spell(marked_for_death) or 600 > 30 - 10 and combopointsdeficit() >= maxcombopoints() and spell(marked_for_death)
 {
  #vendetta,if=!stealthed.rogue&dot.rupture.ticking&!debuff.vendetta.up&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1&(spell_targets.fan_of_knives<6|!cooldown.vanish.up))&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled)&(!equipped.azsharas_font_of_power|azerite.shrouded_suffocation.enabled|debuff.razor_coral_debuff.down|trinket.ashvanes_razor_coral.cooldown.remains<10&cooldown.toxic_blade.remains<1)
  if not stealthed() and target.DebuffPresent(rupture_debuff) and not target.DebuffPresent(vendetta_debuff) and { not hastalent(subterfuge_talent) or not hasazeritetrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and { enemies() < 6 or not { not spellcooldown(vanish) > 0 } } } and { not hastalent(nightstalker_talent) or not hastalent(exsanguinate_talent) or spellcooldown(exsanguinate) < 5 - 2 * talentpoints(deeper_stratagem_talent) } and { not hasequippeditem(azsharas_font_of_power_item) or hasazeritetrait(shrouded_suffocation_trait) or target.DebuffExpires(razor_coral) or buffremaining(trinket_ashvanes_razor_coral_cooldown_buff) < 10 and spellcooldown(toxic_blade) < 1 } spell(vendetta)

  unless hastalent(exsanguinate_talent) and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and undefined() } and combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 and { not hastalent(subterfuge_talent) or not hasazeritetrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and checkboxon(opt_vanish) and spell(vanish) or hastalent(nightstalker_talent) and not hastalent(exsanguinate_talent) and combopoints() >= maxcombopoints() and target.DebuffPresent(vendetta_debuff) and checkboxon(opt_vanish) and spell(vanish)
  {
   #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
   #pool_resource,for_next=1,extra_amount=45
   #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
   unless hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) and spellusable(vanish) and spellcooldown(vanish) < timetoenergy(45)
   {
    unless hastalent(master_assassin_talent) and not stealthed() and buffremaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and target.DebuffRemaining(garrote_debuff) > 3 and target.DebuffPresent(vendetta_debuff) and { not hastalent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) } and checkboxon(opt_vanish) and spell(vanish)
    {
     #shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
     if not stealthed() and hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) and target.DebuffPersistentMultiplier(garrote_debuff) <= 1 and combopointsdeficit() >= 1 spell(shadowmeld)

     unless target.DebuffRemaining(rupture_debuff) > 4 + 4 * maxcombopoints() and not target.DebuffRefreshable(garrote_debuff) and spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and spell(toxic_blade)
     {
      #potion,if=buff.bloodlust.react|debuff.vendetta.up
      if { buffpresent(bloodlust) or target.DebuffPresent(vendetta_debuff) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
      #blood_fury,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) spell(blood_fury_ap)
      #berserking,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) spell(berserking)
      #fireblood,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) spell(fireblood)
      #ancestral_call,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) spell(ancestral_call)
      #use_item,name=galecallers_boon,if=cooldown.vendetta.remains>45
      if spellcooldown(vendetta) > 45 assassinationuseitemactions()
      #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.vendetta.remains>10-4*equipped.azsharas_font_of_power|target.time_to_die<20
      if target.DebuffExpires(razor_coral) or target.DebuffRemaining(vendetta_debuff) > 10 - 4 * hasequippeditem(azsharas_font_of_power_item) or target.timetodie() < 20 assassinationuseitemactions()
      #use_item,name=lurkers_insidious_gift,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) assassinationuseitemactions()
      #use_item,name=lustrous_golden_plumage,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) assassinationuseitemactions()
      #use_item,effect_name=gladiators_medallion,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) assassinationuseitemactions()
      #use_item,effect_name=gladiators_badge,if=debuff.vendetta.up
      if target.DebuffPresent(vendetta_debuff) assassinationuseitemactions()
      #use_item,effect_name=cyclotronic_blast,if=master_assassin_remains=0&!debuff.vendetta.up&!debuff.toxic_blade.up&buff.memory_of_lucid_dreams.down&energy<80&dot.rupture.remains>4
      if buffremaining(master_assassin_buff) == 0 and not target.DebuffPresent(vendetta_debuff) and not target.DebuffPresent(toxic_blade_debuff) and buffexpires(memory_of_lucid_dreams_essence_buff) and energy() < 80 and target.DebuffRemaining(rupture_debuff) > 4 assassinationuseitemactions()
      #use_items
      assassinationuseitemactions()
     }
    }
   }
  }
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 not stealthed() and target.DebuffPresent(rupture_debuff) and buffremaining(master_assassin_buff) == 0 and AssassinationEssencesCdPostConditions() or false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() * 1.5 or combopointsdeficit() >= maxcombopoints() } and spell(marked_for_death) or 600 > 30 - 10 and combopointsdeficit() >= maxcombopoints() and spell(marked_for_death) or hastalent(exsanguinate_talent) and { hastalent(nightstalker_talent) or hastalent(subterfuge_talent) and undefined() } and combopoints() >= maxcombopoints() and spellcooldown(exsanguinate) < 1 and { not hastalent(subterfuge_talent) or not hasazeritetrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and checkboxon(opt_vanish) and spell(vanish) or hastalent(nightstalker_talent) and not hastalent(exsanguinate_talent) and combopoints() >= maxcombopoints() and target.DebuffPresent(vendetta_debuff) and checkboxon(opt_vanish) and spell(vanish) or not { hastalent(subterfuge_talent) and not stealthed() and not spellcooldown(garrote) > 0 and { undefined() or not hasazeritetrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and combopointsdeficit() >= { 1 + 2 * hasazeritetrait(shrouded_suffocation_trait) } * enemies() >? 4 and 600 > 12 and checkboxon(opt_vanish) and spellusable(vanish) and spellcooldown(vanish) < timetoenergy(45) } and { hastalent(master_assassin_talent) and not stealthed() and buffremaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and target.DebuffRemaining(garrote_debuff) > 3 and target.DebuffPresent(vendetta_debuff) and { not hastalent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) } and checkboxon(opt_vanish) and spell(vanish) or target.DebuffRemaining(rupture_debuff) > 4 + 4 * maxcombopoints() and not target.DebuffRefreshable(garrote_debuff) and spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and spell(toxic_blade) }
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #stealth
 spell(stealth)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if stealthed() AssassinationStealthedMainActions()

 unless stealthed() and AssassinationStealthedMainPostConditions()
 {
  #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
  if { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } AssassinationCdsMainActions()

  unless { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsMainPostConditions()
  {
   #call_action_list,name=dot
   AssassinationDotMainActions()

   unless AssassinationDotMainPostConditions()
   {
    #call_action_list,name=direct
    AssassinationDirectMainActions()
   }
  }
 }
}

AddFunction AssassinationDefaultMainPostConditions
{
 stealthed() and AssassinationStealthedMainPostConditions() or { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsMainPostConditions() or AssassinationDotMainPostConditions() or AssassinationDirectMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 unless spell(stealth)
 {
  #call_action_list,name=stealthed,if=stealthed.rogue
  if stealthed() AssassinationStealthedShortCdActions()

  unless stealthed() and AssassinationStealthedShortCdPostConditions()
  {
   #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
   if { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } AssassinationCdsShortCdActions()

   unless { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsShortCdPostConditions()
   {
    #call_action_list,name=dot
    AssassinationDotShortCdActions()

    unless AssassinationDotShortCdPostConditions()
    {
     #call_action_list,name=direct
     AssassinationDirectShortCdActions()
    }
   }
  }
 }
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 spell(stealth) or stealthed() and AssassinationStealthedShortCdPostConditions() or { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 undefined()

 unless spell(stealth)
 {
  #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
  #variable,name=single_target,value=spell_targets.fan_of_knives<2
  #use_item,name=azsharas_font_of_power,if=!stealthed.all&master_assassin_remains=0&cooldown.vendetta.remains<10+10*equipped.ashvanes_razor_coral&!debuff.vendetta.up&!debuff.toxic_blade.up
  if not stealthed() and buffremaining(master_assassin_buff) == 0 and spellcooldown(vendetta) < 10 + 10 * hasequippeditem(ashvanes_razor_coral_item) and not target.DebuffPresent(vendetta_debuff) and not target.DebuffPresent(toxic_blade_debuff) assassinationuseitemactions()
  #call_action_list,name=stealthed,if=stealthed.rogue
  if stealthed() AssassinationStealthedCdActions()

  unless stealthed() and AssassinationStealthedCdPostConditions()
  {
   #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
   if { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } AssassinationCdsCdActions()

   unless { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsCdPostConditions()
   {
    #call_action_list,name=dot
    AssassinationDotCdActions()

    unless AssassinationDotCdPostConditions()
    {
     #call_action_list,name=direct
     AssassinationDirectCdActions()

     unless AssassinationDirectCdPostConditions()
     {
      #arcane_torrent,if=energy.deficit>=15+variable.energy_regen_combined
      if energydeficit() >= 15 + undefined() spell(arcane_torrent_energy)
      #arcane_pulse
      spell(arcane_pulse)
      #lights_judgment
      spell(lights_judgment)
     }
    }
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 spell(stealth) or stealthed() and AssassinationStealthedCdPostConditions() or { not hastalent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not hasequippeditem(azsharas_font_of_power_item) or not { not spellcooldown(latent_arcana) > 0 } } and AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
}

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe l(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
 if not incombat() assassinationprecombatshortcdactions()
 unless not incombat() and assassinationprecombatshortcdpostconditions()
 {
  assassinationdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
 if not incombat() assassinationprecombatshortcdactions()
 unless not incombat() and assassinationprecombatshortcdpostconditions()
 {
  assassinationdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=assassination
{
 if not incombat() assassinationprecombatmainactions()
 unless not incombat() and assassinationprecombatmainpostconditions()
 {
  assassinationdefaultmainactions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
 if not incombat() assassinationprecombatmainactions()
 unless not incombat() and assassinationprecombatmainpostconditions()
 {
  assassinationdefaultmainactions()
 }
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
 if not incombat() assassinationprecombatcdactions()
 unless not incombat() and assassinationprecombatcdpostconditions()
 {
  assassinationdefaultcdactions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
 if not incombat() assassinationprecombatcdactions()
 unless not incombat() and assassinationprecombatcdpostconditions()
 {
  assassinationdefaultcdactions()
 }
}

### Required symbols
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# ashvanes_razor_coral_item
# azsharas_font_of_power_item
# berserking
# blindside
# blindside_buff
# blood_fury_ap
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# cheap_shot
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# crimson_tempest
# crimson_tempest_debuff
# deadly_poison_debuff
# deeper_stratagem_talent
# double_dose_trait
# echoing_blades_trait
# envenom
# exsanguinate
# exsanguinate_talent
# exsanguinated
# fan_of_knives
# fireblood
# focused_azerite_beam
# garrote
# garrote_debuff
# guardian_of_azeroth
# hidden_blades_buff
# internal_bleeding_debuff
# internal_bleeding_talent
# kick
# kidney_shot
# latent_arcana
# lifeblood_buff
# lights_judgment
# marked_for_death
# master_assassin_buff
# master_assassin_talent
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# mutilate
# nightstalker_talent
# purifying_blast
# quaking_palm
# razor_coral
# reckless_force_buff
# reckless_force_counter_buff
# ripple_in_space_essence
# rupture
# rupture_debuff
# scent_of_blood_trait
# shadowmeld
# shadowstep
# shrouded_suffocation_trait
# stealth
# subterfuge_buff
# subterfuge_talent
# the_unbound_force
# toxic_blade
# toxic_blade_debuff
# toxic_blade_talent
# trinket_ashvanes_razor_coral_cooldown_buff
# unbridled_fury_item
# vanish
# vendetta
# vendetta_debuff
# venom_rush_talent
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
    end
    do
        local name = "sc_t23_rogue_outlaw"
        local desc = "[8.2] Simulationcraft: T23_Rogue_Outlaw"
        local code = [[
# Based on SimulationCraft profile "T23_Rogue_Outlaw".
#	class=rogue
#	spec=outlaw
#	talents=2010022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction blade_flurry_sync
{
 enemies() < 2 and 600 > 20 or buffpresent(blade_flurry_buff)
}

AddFunction bte_condition
{
 buffpresent(ruthless_precision_buff) or { hasazeritetrait(deadshot_trait) or hasazeritetrait(ace_up_your_sleeve_trait) } and buffpresent(roll_the_bones_buff)
}

AddFunction ambush_condition
{
 combopointsdeficit() >= 2 + 2 * { hastalent(ghostly_strike_talent) and spellcooldown(ghostly_strike) < 1 } + buffpresent(broadside_buff) and energy() > 60 and not buffpresent(skull_and_crossbones_buff) and not buffpresent(keep_your_wits_about_you_buff)
}

AddFunction rtb_reroll
{
 if buffpresent(blade_flurry_buff) buffcount(roll_the_bones_buff) - buffpresent(skull_and_crossbones_buff) < 2 and { buffpresent(loaded_dice_buff) or not buffpresent(grand_melee_buff) and not buffpresent(ruthless_precision_buff) and not buffpresent(broadside_buff) }
 if azeritetraitrank(snake_eyes_trait) >= 2 buffcount(roll_the_bones_buff) < 2
 if hasazeritetrait(deadshot_trait) or hasazeritetrait(ace_up_your_sleeve_trait) buffcount(roll_the_bones_buff) < 2 and { buffpresent(loaded_dice_buff) or buffremaining(ruthless_precision_buff) <= spellcooldown(between_the_eyes) }
 buffcount(roll_the_bones_buff) < 2 and { buffpresent(loaded_dice_buff) or not buffpresent(grand_melee_buff) and not buffpresent(ruthless_precision_buff) }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=outlaw)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=outlaw)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=outlaw)
AddCheckBox(opt_blade_flurry spellname(blade_flurry) default specialization=outlaw)

AddFunction OutlawInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(kick) and target.isinterruptible() spell(kick)
  if target.inrange(cheap_shot) and not target.classification(worldboss) spell(cheap_shot)
  if target.inrange(between_the_eyes) and not target.classification(worldboss) and combopoints() >= 1 spell(between_the_eyes)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.inrange(gouge) and not target.classification(worldboss) spell(gouge)
 }
}

AddFunction OutlawUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

AddFunction OutlawGetInMeleeRange
{
 if checkboxon(opt_melee_range) and not target.inrange(kick)
 {
  spell(shadowstep)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.stealth

AddFunction OutlawStealthMainActions
{
 #ambush
 spell(ambush)
}

AddFunction OutlawStealthMainPostConditions
{
}

AddFunction OutlawStealthShortCdActions
{
}

AddFunction OutlawStealthShortCdPostConditions
{
 spell(ambush)
}

AddFunction OutlawStealthCdActions
{
}

AddFunction OutlawStealthCdPostConditions
{
 spell(ambush)
}

### actions.precombat

AddFunction OutlawPrecombatMainActions
{
 #stealth,if=(!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration|raid_event.invulnerable.exists)
 if not hasequippeditem(pocket_sized_computation_device_item) or not spellcooldownduration(cyclotronic_blast) or 0 spell(stealth)
 #roll_the_bones,precombat_seconds=2
 spell(roll_the_bones)
 #slice_and_dice,precombat_seconds=2
 spell(slice_and_dice)
}

AddFunction OutlawPrecombatMainPostConditions
{
}

AddFunction OutlawPrecombatShortCdActions
{
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
 if 600 > 40 spell(marked_for_death)
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 { not hasequippeditem(pocket_sized_computation_device_item) or not spellcooldownduration(cyclotronic_blast) or 0 } and spell(stealth) or spell(roll_the_bones) or spell(slice_and_dice)
}

AddFunction OutlawPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless 600 > 40 and spell(marked_for_death) or { not hasequippeditem(pocket_sized_computation_device_item) or not spellcooldownduration(cyclotronic_blast) or 0 } and spell(stealth) or spell(roll_the_bones) or spell(slice_and_dice)
 {
  #adrenaline_rush,precombat_seconds=1,if=(!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration|raid_event.invulnerable.exists)
  if { not hasequippeditem(pocket_sized_computation_device_item) or not spellcooldownduration(cyclotronic_blast) or 0 } and energydeficit() > 1 spell(adrenaline_rush)
  #use_item,name=azsharas_font_of_power
  outlawuseitemactions()
  #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists
  if not 0 outlawuseitemactions()
 }
}

AddFunction OutlawPrecombatCdPostConditions
{
 600 > 40 and spell(marked_for_death) or { not hasequippeditem(pocket_sized_computation_device_item) or not spellcooldownduration(cyclotronic_blast) or 0 } and spell(stealth) or spell(roll_the_bones) or spell(slice_and_dice)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #between_the_eyes,if=variable.bte_condition
 if undefined() spell(between_the_eyes)
 #slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
 if buffremaining(slice_and_dice_buff) < target.timetodie() and buffremaining(slice_and_dice_buff) < { 1 + combopoints() } * 1.8 spell(slice_and_dice)
 #roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll
 if buffremaining(roll_the_bones_buff) <= 3 or undefined() spell(roll_the_bones)
 #between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
 if hasazeritetrait(ace_up_your_sleeve_trait) or hasazeritetrait(deadshot_trait) spell(between_the_eyes)
 #dispatch
 spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
}

AddFunction OutlawFinishShortCdPostConditions
{
 undefined() and spell(between_the_eyes) or buffremaining(slice_and_dice_buff) < target.timetodie() and buffremaining(slice_and_dice_buff) < { 1 + combopoints() } * 1.8 and spell(slice_and_dice) or { buffremaining(roll_the_bones_buff) <= 3 or undefined() } and spell(roll_the_bones) or { hasazeritetrait(ace_up_your_sleeve_trait) or hasazeritetrait(deadshot_trait) } and spell(between_the_eyes) or spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 undefined() and spell(between_the_eyes) or buffremaining(slice_and_dice_buff) < target.timetodie() and buffremaining(slice_and_dice_buff) < { 1 + combopoints() } * 1.8 and spell(slice_and_dice) or { buffremaining(roll_the_bones_buff) <= 3 or undefined() } and spell(roll_the_bones) or { hasazeritetrait(ace_up_your_sleeve_trait) or hasazeritetrait(deadshot_trait) } and spell(between_the_eyes) or spell(dispatch)
}

### actions.essences

AddFunction OutlawEssencesMainActions
{
 #concentrated_flame,if=energy.time_to_max>1&!buff.blade_flurry.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if timetomaxenergy() > 1 and not buffpresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } spell(concentrated_flame_essence)
}

AddFunction OutlawEssencesMainPostConditions
{
}

AddFunction OutlawEssencesShortCdActions
{
 unless timetomaxenergy() > 1 and not buffpresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=spell_targets.blade_flurry>=2|raid_event.adds.in>60
  if enemies() >= 2 or 600 > 60 spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
 }
}

AddFunction OutlawEssencesShortCdPostConditions
{
 timetomaxenergy() > 1 and not buffpresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
}

AddFunction OutlawEssencesCdActions
{
 unless timetomaxenergy() > 1 and not buffpresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=variable.blade_flurry_sync&cooldown.between_the_eyes.up&variable.bte_condition
  if undefined() and not spellcooldown(between_the_eyes) > 0 and undefined() spell(blood_of_the_enemy)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #focused_azerite_beam,if=spell_targets.blade_flurry>=2|raid_event.adds.in>60&!buff.adrenaline_rush.up
  if enemies() >= 2 or 600 > 60 and not buffpresent(adrenaline_rush_buff) spell(focused_azerite_beam)

  unless { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=energy<45
   if energy() < 45 spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction OutlawEssencesCdPostConditions
{
 timetomaxenergy() > 1 and not buffpresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not stealthed() OutlawEssencesMainActions()

 unless not stealthed() and OutlawEssencesMainPostConditions()
 {
  #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
  if enemies() >= 2 and not buffpresent(blade_flurry_buff) and { not false(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - spellcharges(blade_flurry count=0) } * 25 } and checkboxon(opt_blade_flurry) spell(blade_flurry)
  #ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
  if undefined() and combopointsdeficit() >= 1 + buffpresent(broadside_buff) spell(ghostly_strike)
 }
}

AddFunction OutlawCdsMainPostConditions
{
 not stealthed() and OutlawEssencesMainPostConditions()
}

AddFunction OutlawCdsShortCdActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not stealthed() OutlawEssencesShortCdActions()

 unless not stealthed() and OutlawEssencesShortCdPostConditions()
 {
  #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
  if false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 } spell(marked_for_death)
  #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
  if 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 spell(marked_for_death)

  unless enemies() >= 2 and not buffpresent(blade_flurry_buff) and { not false(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - spellcharges(blade_flurry count=0) } * 25 } and checkboxon(opt_blade_flurry) and spell(blade_flurry) or undefined() and combopointsdeficit() >= 1 + buffpresent(broadside_buff) and spell(ghostly_strike)
  {
   #blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
   if undefined() and timetomaxenergy() > 1 spell(blade_rush)
   #vanish,if=!stealthed.all&variable.ambush_condition
   if not stealthed() and undefined() spell(vanish)
  }
 }
}

AddFunction OutlawCdsShortCdPostConditions
{
 not stealthed() and OutlawEssencesShortCdPostConditions() or enemies() >= 2 and not buffpresent(blade_flurry_buff) and { not false(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - spellcharges(blade_flurry count=0) } * 25 } and checkboxon(opt_blade_flurry) and spell(blade_flurry) or undefined() and combopointsdeficit() >= 1 + buffpresent(broadside_buff) and spell(ghostly_strike)
}

AddFunction OutlawCdsCdActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not stealthed() OutlawEssencesCdActions()

 unless not stealthed() and OutlawEssencesCdPostConditions()
 {
  #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1&(!equipped.azsharas_font_of_power|cooldown.latent_arcana.remains>20)
  if not buffpresent(adrenaline_rush_buff) and timetomaxenergy() > 1 and { not hasequippeditem(azsharas_font_of_power_item) or spellcooldown(latent_arcana) > 20 } and energydeficit() > 1 spell(adrenaline_rush)

  unless false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 } and spell(marked_for_death) or 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 and spell(marked_for_death) or enemies() >= 2 and not buffpresent(blade_flurry_buff) and { not false(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - spellcharges(blade_flurry count=0) } * 25 } and checkboxon(opt_blade_flurry) and spell(blade_flurry) or undefined() and combopointsdeficit() >= 1 + buffpresent(broadside_buff) and spell(ghostly_strike)
  {
   #killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
   if undefined() and { timetomaxenergy() > 5 or energy() < 15 } spell(killing_spree)

   unless undefined() and timetomaxenergy() > 1 and spell(blade_rush) or not stealthed() and undefined() and spell(vanish)
   {
    #shadowmeld,if=!stealthed.all&variable.ambush_condition
    if not stealthed() and undefined() spell(shadowmeld)
    #potion,if=buff.bloodlust.react|buff.adrenaline_rush.up
    if { buffpresent(bloodlust) or buffpresent(adrenaline_rush_buff) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
    #blood_fury
    spell(blood_fury_ap)
    #berserking
    spell(berserking)
    #fireblood
    spell(fireblood)
    #ancestral_call
    spell(ancestral_call)
    #use_item,effect_name=cyclotronic_blast,if=!stealthed.all&buff.adrenaline_rush.down&buff.memory_of_lucid_dreams.down&energy.time_to_max>4&rtb_buffs<5
    if not stealthed() and buffexpires(adrenaline_rush_buff) and buffexpires(memory_of_lucid_dreams_essence_buff) and timetomaxenergy() > 4 and buffcount(roll_the_bones_buff) < 5 outlawuseitemactions()
    #use_item,name=azsharas_font_of_power,if=!buff.adrenaline_rush.up&!buff.blade_flurry.up&cooldown.adrenaline_rush.remains<15
    if not buffpresent(adrenaline_rush_buff) and not buffpresent(blade_flurry_buff) and spellcooldown(adrenaline_rush) < 15 outlawuseitemactions()
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<32&target.health.pct>=30|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=20-10*debuff.blood_of_the_enemy.up|target.time_to_die<60)&buff.adrenaline_rush.remains>18
    if target.DebuffExpires(razor_coral) or target.DebuffPresent(conductive_ink) and target.healthpercent() < 32 and target.healthpercent() >= 30 or not target.DebuffPresent(conductive_ink) and { target.DebuffStacks(razor_coral) >= 20 - 10 * target.DebuffPresent(blood_of_the_enemy) or target.timetodie() < 60 } and buffremaining(adrenaline_rush_buff) > 18 outlawuseitemactions()
    #use_items,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
    if buffpresent(bloodlust) or target.timetodie() <= 20 or combopointsdeficit() <= 2 outlawuseitemactions()
   }
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 not stealthed() and OutlawEssencesCdPostConditions() or false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 } and spell(marked_for_death) or 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() - 1 and spell(marked_for_death) or enemies() >= 2 and not buffpresent(blade_flurry_buff) and { not false(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - spellcharges(blade_flurry count=0) } * 25 } and checkboxon(opt_blade_flurry) and spell(blade_flurry) or undefined() and combopointsdeficit() >= 1 + buffpresent(broadside_buff) and spell(ghostly_strike) or undefined() and timetomaxenergy() > 1 and spell(blade_rush) or not stealthed() and undefined() and spell(vanish)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=buff.opportunity.up&(buff.keep_your_wits_about_you.stack<14|buff.deadshot.up|energy<45)
 if buffpresent(opportunity_buff) and { buffstacks(keep_your_wits_about_you_buff) < 14 or buffpresent(deadshot_buff) or energy() < 45 } spell(pistol_shot)
 #sinister_strike
 spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildMainPostConditions
{
}

AddFunction OutlawBuildShortCdActions
{
}

AddFunction OutlawBuildShortCdPostConditions
{
 buffpresent(opportunity_buff) and { buffstacks(keep_your_wits_about_you_buff) < 14 or buffpresent(deadshot_buff) or energy() < 45 } and spell(pistol_shot) or spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 buffpresent(opportunity_buff) and { buffstacks(keep_your_wits_about_you_buff) < 14 or buffpresent(deadshot_buff) or energy() < 45 } and spell(pistol_shot) or spell(sinister_strike_outlaw)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #stealth
 spell(stealth)
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
 #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if stealthed() OutlawStealthMainActions()

 unless stealthed() and OutlawStealthMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
   if combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } OutlawFinishMainActions()

   unless combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishMainPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildMainActions()
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 stealthed() and OutlawStealthMainPostConditions() or OutlawCdsMainPostConditions() or combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishMainPostConditions() or OutlawBuildMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 unless spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
  #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
  #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
  #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
  #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
  #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
  #call_action_list,name=stealth,if=stealthed.all
  if stealthed() OutlawStealthShortCdActions()

  unless stealthed() and OutlawStealthShortCdPostConditions()
  {
   #call_action_list,name=cds
   OutlawCdsShortCdActions()

   unless OutlawCdsShortCdPostConditions()
   {
    #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
    if combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } OutlawFinishShortCdActions()

    unless combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishShortCdPostConditions()
    {
     #call_action_list,name=build
     OutlawBuildShortCdActions()
    }
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 spell(stealth) or stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 undefined()

 unless spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
  #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
  #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
  #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
  #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
  #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
  #call_action_list,name=stealth,if=stealthed.all
  if stealthed() OutlawStealthCdActions()

  unless stealthed() and OutlawStealthCdPostConditions()
  {
   #call_action_list,name=cds
   OutlawCdsCdActions()

   unless OutlawCdsCdPostConditions()
   {
    #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
    if combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } OutlawFinishCdActions()

    unless combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishCdPostConditions()
    {
     #call_action_list,name=build
     OutlawBuildCdActions()

     unless OutlawBuildCdPostConditions()
     {
      #arcane_torrent,if=energy.deficit>=15+energy.regen
      if energydeficit() >= 15 + energyregenrate() spell(arcane_torrent_energy)
      #arcane_pulse
      spell(arcane_pulse)
      #lights_judgment
      spell(lights_judgment)
     }
    }
   }
  }
 }
}

AddFunction OutlawDefaultCdPostConditions
{
 spell(stealth) or stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or combopoints() >= maxcombopoints() - { buffpresent(broadside_buff) + buffpresent(opportunity_buff) } * { hastalent(quick_draw_talent) and { not hastalent(marked_for_death_talent) or spellcooldown(marked_for_death) > 1 } } * { azeritetraitrank(ace_up_your_sleeve_trait) < 2 or not { not spellcooldown(between_the_eyes) > 0 } or not buffpresent(roll_the_bones_buff) } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
}

### Outlaw icons.

AddCheckBox(opt_rogue_outlaw_aoe l(AOE) default specialization=outlaw)

AddIcon checkbox=!opt_rogue_outlaw_aoe enemies=1 help=shortcd specialization=outlaw
{
 if not incombat() outlawprecombatshortcdactions()
 unless not incombat() and outlawprecombatshortcdpostconditions()
 {
  outlawdefaultshortcdactions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=shortcd specialization=outlaw
{
 if not incombat() outlawprecombatshortcdactions()
 unless not incombat() and outlawprecombatshortcdpostconditions()
 {
  outlawdefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=outlaw
{
 if not incombat() outlawprecombatmainactions()
 unless not incombat() and outlawprecombatmainpostconditions()
 {
  outlawdefaultmainactions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=aoe specialization=outlaw
{
 if not incombat() outlawprecombatmainactions()
 unless not incombat() and outlawprecombatmainpostconditions()
 {
  outlawdefaultmainactions()
 }
}

AddIcon checkbox=!opt_rogue_outlaw_aoe enemies=1 help=cd specialization=outlaw
{
 if not incombat() outlawprecombatcdactions()
 unless not incombat() and outlawprecombatcdpostconditions()
 {
  outlawdefaultcdactions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=cd specialization=outlaw
{
 if not incombat() outlawprecombatcdactions()
 unless not incombat() and outlawprecombatcdpostconditions()
 {
  outlawdefaultcdactions()
 }
}

### Required symbols
# ace_up_your_sleeve_trait
# adrenaline_rush
# adrenaline_rush_buff
# ambush
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# azsharas_font_of_power_item
# berserking
# between_the_eyes
# blade_flurry
# blade_flurry_buff
# blade_rush
# blood_fury_ap
# blood_of_the_enemy
# bloodlust
# broadside_buff
# cheap_shot
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
# cyclotronic_blast
# deadshot_buff
# deadshot_trait
# dispatch
# fireblood
# focused_azerite_beam
# ghostly_strike
# ghostly_strike_talent
# gouge
# grand_melee_buff
# guardian_of_azeroth
# keep_your_wits_about_you_buff
# kick
# killing_spree
# latent_arcana
# lifeblood_buff
# lights_judgment
# loaded_dice_buff
# marked_for_death
# marked_for_death_talent
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# opportunity_buff
# pistol_shot
# pocket_sized_computation_device_item
# purifying_blast
# quaking_palm
# quick_draw_talent
# razor_coral
# reckless_force_buff
# reckless_force_counter_buff
# ripple_in_space_essence
# roll_the_bones
# roll_the_bones_buff
# ruthless_precision_buff
# shadowmeld
# shadowstep
# sinister_strike_outlaw
# skull_and_crossbones_buff
# slice_and_dice
# slice_and_dice_buff
# snake_eyes_trait
# stealth
# the_unbound_force
# unbridled_fury_item
# vanish
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
    end
    do
        local name = "sc_t23_rogue_subtlety"
        local desc = "[8.2] Simulationcraft: T23_Rogue_Subtlety"
        local code = [[
# Based on SimulationCraft profile "T23_Rogue_Subtlety".
#	class=rogue
#	spec=subtlety
#	talents=2320031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction stealth_threshold
{
 25 + talentpoints(vigor_talent) * 35 + talentpoints(master_of_shadows_talent) * 25 + talentpoints(shadow_focus_talent) * 20 + talentpoints(alacrity_talent) * 10 + 15 * { enemies() >= 3 }
}

AddFunction use_priority_rotation
{
 checkboxon(opt_priority_rotation) and enemies() >= 2
}

AddFunction shd_combo_points
{
 if undefined() and { hastalent(nightstalker_talent) or hastalent(dark_shadow_talent) } combopointsdeficit() <= 1 + 2 * hasazeritetrait(the_first_dance_trait)
 combopointsdeficit() >= 4
}

AddFunction shd_threshold
{
 spellcharges(shadow_dance count=0) >= 1.75
}

AddCheckBox(opt_priority_rotation l(opt_priority_rotation) default specialization=subtlety)
AddCheckBox(opt_interrupt l(interrupt) default specialization=subtlety)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=subtlety)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=subtlety)

AddFunction SubtletyInterruptActions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(kick) and target.isinterruptible() spell(kick)
  if target.inrange(cheap_shot) and not target.classification(worldboss) spell(cheap_shot)
  if target.inrange(kidney_shot) and not target.classification(worldboss) and combopoints() >= 1 spell(kidney_shot)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
 }
}

AddFunction SubtletyUseItemActions
{
 item(Trinket0Slot text=13 usable=1)
 item(Trinket1Slot text=14 usable=1)
}

AddFunction SubtletyGetInMeleeRange
{
 if checkboxon(opt_melee_range) and not target.inrange(kick)
 {
  spell(shadowstep)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.stealthed

AddFunction SubtletyStealthedMainActions
{
 #shadowstrike,if=(talent.find_weakness.enabled|spell_targets.shuriken_storm<3)&(buff.stealth.up|buff.vanish.up)
 if { hastalent(find_weakness_talent) or enemies() < 3 } and { buffpresent(stealthed_buff any=1) or buffpresent(vanish_buff) } spell(shadowstrike)
 #call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
 if buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 SubtletyFinishMainActions()

 unless buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishMainPostConditions()
 {
  #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
  if enemies() == 4 and combopoints() >= 4 SubtletyFinishMainActions()

  unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishMainPostConditions()
  {
   #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled&spell_targets.shuriken_storm<3))
   if combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } SubtletyFinishMainActions()

   unless combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } and SubtletyFinishMainPostConditions()
   {
    #gloomblade,if=azerite.perforate.rank>=2&spell_targets.shuriken_storm<=2&position_back
    if azeritetraitrank(perforate_trait) >= 2 and enemies() <= 2 and true(position_back) spell(gloomblade)
    #shadowstrike,cycle_targets=1,if=talent.secret_technique.enabled&talent.find_weakness.enabled&debuff.find_weakness.remains<1&spell_targets.shuriken_storm=2&target.time_to_die-remains>6
    if hastalent(secret_technique_talent) and hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and enemies() == 2 and target.timetodie() - buffremaining(shadowstrike) > 6 spell(shadowstrike)
    #shadowstrike,if=!talent.deeper_stratagem.enabled&azerite.blade_in_the_shadows.rank=3&spell_targets.shuriken_storm=3
    if not hastalent(deeper_stratagem_talent) and azeritetraitrank(blade_in_the_shadows_trait) == 3 and enemies() == 3 spell(shadowstrike)
    #shadowstrike,if=variable.use_priority_rotation&(talent.find_weakness.enabled&debuff.find_weakness.remains<1|talent.weaponmaster.enabled&spell_targets.shuriken_storm<=4|azerite.inevitability.enabled&buff.symbols_of_death.up&spell_targets.shuriken_storm<=3+azerite.blade_in_the_shadows.enabled)
    if undefined() and { hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 or hastalent(weaponmaster_talent) and enemies() <= 4 or hasazeritetrait(inevitability_trait) and buffpresent(symbols_of_death_buff) and enemies() <= 3 + hasazeritetrait(blade_in_the_shadows_trait) } spell(shadowstrike)
    #shuriken_storm,if=spell_targets>=3
    if enemies() >= 3 spell(shuriken_storm)
    #shadowstrike
    spell(shadowstrike)
   }
  }
 }
}

AddFunction SubtletyStealthedMainPostConditions
{
 buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishMainPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishMainPostConditions() or combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } and SubtletyFinishMainPostConditions()
}

AddFunction SubtletyStealthedShortCdActions
{
 unless { hastalent(find_weakness_talent) or enemies() < 3 } and { buffpresent(stealthed_buff any=1) or buffpresent(vanish_buff) } and spell(shadowstrike)
 {
  #call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
  if buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 SubtletyFinishShortCdActions()

  unless buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishShortCdPostConditions()
  {
   #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
   if enemies() == 4 and combopoints() >= 4 SubtletyFinishShortCdActions()

   unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishShortCdPostConditions()
   {
    #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled&spell_targets.shuriken_storm<3))
    if combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } SubtletyFinishShortCdActions()
   }
  }
 }
}

AddFunction SubtletyStealthedShortCdPostConditions
{
 { hastalent(find_weakness_talent) or enemies() < 3 } and { buffpresent(stealthed_buff any=1) or buffpresent(vanish_buff) } and spell(shadowstrike) or buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishShortCdPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishShortCdPostConditions() or combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } and SubtletyFinishShortCdPostConditions() or azeritetraitrank(perforate_trait) >= 2 and enemies() <= 2 and true(position_back) and spell(gloomblade) or hastalent(secret_technique_talent) and hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and enemies() == 2 and target.timetodie() - buffremaining(shadowstrike) > 6 and spell(shadowstrike) or not hastalent(deeper_stratagem_talent) and azeritetraitrank(blade_in_the_shadows_trait) == 3 and enemies() == 3 and spell(shadowstrike) or undefined() and { hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 or hastalent(weaponmaster_talent) and enemies() <= 4 or hasazeritetrait(inevitability_trait) and buffpresent(symbols_of_death_buff) and enemies() <= 3 + hasazeritetrait(blade_in_the_shadows_trait) } and spell(shadowstrike) or enemies() >= 3 and spell(shuriken_storm) or spell(shadowstrike)
}

AddFunction SubtletyStealthedCdActions
{
 unless { hastalent(find_weakness_talent) or enemies() < 3 } and { buffpresent(stealthed_buff any=1) or buffpresent(vanish_buff) } and spell(shadowstrike)
 {
  #call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2
  if buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 SubtletyFinishCdActions()

  unless buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishCdPostConditions()
  {
   #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
   if enemies() == 4 and combopoints() >= 4 SubtletyFinishCdActions()

   unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishCdPostConditions()
   {
    #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled&spell_targets.shuriken_storm<3))
    if combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } SubtletyFinishCdActions()
   }
  }
 }
}

AddFunction SubtletyStealthedCdPostConditions
{
 { hastalent(find_weakness_talent) or enemies() < 3 } and { buffpresent(stealthed_buff any=1) or buffpresent(vanish_buff) } and spell(shadowstrike) or buffpresent(shuriken_tornado) and combopointsdeficit() <= 2 and SubtletyFinishCdPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishCdPostConditions() or combopointsdeficit() <= 1 - { hastalent(deeper_stratagem_talent) and { buffpresent(vanish_buff) or hasazeritetrait(the_first_dance_trait) and not hastalent(dark_shadow_talent) and not hastalent(subterfuge_talent) and enemies() < 3 } } and SubtletyFinishCdPostConditions() or azeritetraitrank(perforate_trait) >= 2 and enemies() <= 2 and true(position_back) and spell(gloomblade) or hastalent(secret_technique_talent) and hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and enemies() == 2 and target.timetodie() - buffremaining(shadowstrike) > 6 and spell(shadowstrike) or not hastalent(deeper_stratagem_talent) and azeritetraitrank(blade_in_the_shadows_trait) == 3 and enemies() == 3 and spell(shadowstrike) or undefined() and { hastalent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 or hastalent(weaponmaster_talent) and enemies() <= 4 or hasazeritetrait(inevitability_trait) and buffpresent(symbols_of_death_buff) and enemies() <= 3 + hasazeritetrait(blade_in_the_shadows_trait) } and spell(shadowstrike) or enemies() >= 3 and spell(shuriken_storm) or spell(shadowstrike)
}

### actions.stealth_cds

AddFunction SubtletyStealthcdsMainActions
{
}

AddFunction SubtletyStealthcdsMainPostConditions
{
}

AddFunction SubtletyStealthcdsShortCdActions
{
 #variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=1.75
 #vanish,if=!variable.shd_threshold&combo_points.deficit>1&debuff.find_weakness.remains<1&cooldown.symbols_of_death.remains>=3
 if not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 and spellcooldown(symbols_of_death) >= 3 spell(vanish)
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&combo_points.deficit>1&debuff.find_weakness.remains<1
 unless energy() >= 40 and energydeficit() >= 10 and not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 and spellusable(shadowmeld) and spellcooldown(shadowmeld) < timetoenergy(40)
 {
  #variable,name=shd_combo_points,value=combo_points.deficit>=4
  #variable,name=shd_combo_points,value=combo_points.deficit<=1+2*azerite.the_first_dance.enabled,if=variable.use_priority_rotation&(talent.nightstalker.enabled|talent.dark_shadow.enabled)
  #shadow_dance,if=variable.shd_combo_points&(!talent.dark_shadow.enabled|dot.nightblade.remains>=5+talent.subterfuge.enabled)&(variable.shd_threshold|buff.symbols_of_death.remains>=1.2|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)&(azerite.nights_vengeance.rank<2|buff.nights_vengeance.up)
  if undefined() and { not hastalent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + talentpoints(subterfuge_talent) } and { undefined() or buffremaining(symbols_of_death_buff) >= 1.2 or enemies() >= 4 and spellcooldown(symbols_of_death) > 10 } and { azeritetraitrank(nights_vengeance_trait) < 2 or buffpresent(nights_vengeance_buff) } spell(shadow_dance)
  #shadow_dance,if=variable.shd_combo_points&target.time_to_die<cooldown.symbols_of_death.remains&!raid_event.adds.up
  if undefined() and target.timetodie() < spellcooldown(symbols_of_death) and not false(raid_event_adds_exists) spell(shadow_dance)
 }
}

AddFunction SubtletyStealthcdsShortCdPostConditions
{
}

AddFunction SubtletyStealthcdsCdActions
{
 unless not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 and spellcooldown(symbols_of_death) >= 3 and spell(vanish)
 {
  #pool_resource,for_next=1,extra_amount=40
  #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&combo_points.deficit>1&debuff.find_weakness.remains<1
  if energy() >= 40 and energydeficit() >= 10 and not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 spell(shadowmeld)
 }
}

AddFunction SubtletyStealthcdsCdPostConditions
{
 not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 and spellcooldown(symbols_of_death) >= 3 and spell(vanish) or not { energy() >= 40 and energydeficit() >= 10 and not undefined() and combopointsdeficit() > 1 and target.DebuffRemaining(find_weakness_debuff) < 1 and spellusable(shadowmeld) and spellcooldown(shadowmeld) < timetoenergy(40) } and { undefined() and { not hastalent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + talentpoints(subterfuge_talent) } and { undefined() or buffremaining(symbols_of_death_buff) >= 1.2 or enemies() >= 4 and spellcooldown(symbols_of_death) > 10 } and { azeritetraitrank(nights_vengeance_trait) < 2 or buffpresent(nights_vengeance_buff) } and spell(shadow_dance) or undefined() and target.timetodie() < spellcooldown(symbols_of_death) and not false(raid_event_adds_exists) and spell(shadow_dance) }
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #stealth
 spell(stealth)
}

AddFunction SubtletyPrecombatMainPostConditions
{
}

AddFunction SubtletyPrecombatShortCdActions
{
 unless spell(stealth)
 {
  #marked_for_death,precombat_seconds=15
  spell(marked_for_death)
 }
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
 spell(stealth)
}

AddFunction SubtletyPrecombatCdActions
{
 unless spell(stealth) or spell(marked_for_death)
 {
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #use_item,name=azsharas_font_of_power
  subtletyuseitemactions()
 }
}

AddFunction SubtletyPrecombatCdPostConditions
{
 spell(stealth) or spell(marked_for_death)
}

### actions.finish

AddFunction SubtletyFinishMainActions
{
 #pool_resource,for_next=1
 #eviscerate,if=buff.nights_vengeance.up
 if buffpresent(nights_vengeance_buff) spell(eviscerate)
 unless buffpresent(nights_vengeance_buff) and spellusable(eviscerate) and spellcooldown(eviscerate) < timetoenergyfor(eviscerate)
 {
  #nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&remains<tick_time*2
  if { not hastalent(dark_shadow_talent) or not buffpresent(shadow_dance_buff) } and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.currentticktime(nightblade_debuff) * 2 spell(nightblade)
  #nightblade,cycle_targets=1,if=!variable.use_priority_rotation&spell_targets.shuriken_storm>=2&(azerite.nights_vengeance.enabled|!azerite.replicating_shadows.enabled|spell_targets.shuriken_storm-active_dot.nightblade>=2)&!buff.shadow_dance.up&target.time_to_die>=(5+(2*combo_points))&refreshable
  if not undefined() and enemies() >= 2 and { hasazeritetrait(nights_vengeance_trait) or not hasazeritetrait(replicating_shadows_trait) or enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not buffpresent(shadow_dance_buff) and target.timetodie() >= 5 + 2 * combopoints() and target.refreshable(nightblade_debuff) spell(nightblade)
  #nightblade,if=remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
  if target.DebuffRemaining(nightblade_debuff) < spellcooldown(symbols_of_death) + 10 and spellcooldown(symbols_of_death) <= 5 and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > spellcooldown(symbols_of_death) + 5 spell(nightblade)
  #eviscerate
  spell(eviscerate)
 }
}

AddFunction SubtletyFinishMainPostConditions
{
}

AddFunction SubtletyFinishShortCdActions
{
 #pool_resource,for_next=1
 #eviscerate,if=buff.nights_vengeance.up
 unless buffpresent(nights_vengeance_buff) and spellusable(eviscerate) and spellcooldown(eviscerate) < timetoenergyfor(eviscerate)
 {
  unless { not hastalent(dark_shadow_talent) or not buffpresent(shadow_dance_buff) } and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.currentticktime(nightblade_debuff) * 2 and spell(nightblade) or not undefined() and enemies() >= 2 and { hasazeritetrait(nights_vengeance_trait) or not hasazeritetrait(replicating_shadows_trait) or enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not buffpresent(shadow_dance_buff) and target.timetodie() >= 5 + 2 * combopoints() and target.refreshable(nightblade_debuff) and spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < spellcooldown(symbols_of_death) + 10 and spellcooldown(symbols_of_death) <= 5 and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > spellcooldown(symbols_of_death) + 5 and spell(nightblade)
  {
   #secret_technique
   spell(secret_technique)
  }
 }
}

AddFunction SubtletyFinishShortCdPostConditions
{
 not { buffpresent(nights_vengeance_buff) and spellusable(eviscerate) and spellcooldown(eviscerate) < timetoenergyfor(eviscerate) } and { { not hastalent(dark_shadow_talent) or not buffpresent(shadow_dance_buff) } and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.currentticktime(nightblade_debuff) * 2 and spell(nightblade) or not undefined() and enemies() >= 2 and { hasazeritetrait(nights_vengeance_trait) or not hasazeritetrait(replicating_shadows_trait) or enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not buffpresent(shadow_dance_buff) and target.timetodie() >= 5 + 2 * combopoints() and target.refreshable(nightblade_debuff) and spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < spellcooldown(symbols_of_death) + 10 and spellcooldown(symbols_of_death) <= 5 and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > spellcooldown(symbols_of_death) + 5 and spell(nightblade) or spell(eviscerate) }
}

AddFunction SubtletyFinishCdActions
{
}

AddFunction SubtletyFinishCdPostConditions
{
 buffpresent(nights_vengeance_buff) and spell(eviscerate) or not { buffpresent(nights_vengeance_buff) and spellusable(eviscerate) and spellcooldown(eviscerate) < timetoenergyfor(eviscerate) } and { { not hastalent(dark_shadow_talent) or not buffpresent(shadow_dance_buff) } and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.currentticktime(nightblade_debuff) * 2 and spell(nightblade) or not undefined() and enemies() >= 2 and { hasazeritetrait(nights_vengeance_trait) or not hasazeritetrait(replicating_shadows_trait) or enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not buffpresent(shadow_dance_buff) and target.timetodie() >= 5 + 2 * combopoints() and target.refreshable(nightblade_debuff) and spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < spellcooldown(symbols_of_death) + 10 and spellcooldown(symbols_of_death) <= 5 and target.timetodie() - target.DebuffRemaining(nightblade_debuff) > spellcooldown(symbols_of_death) + 5 and spell(nightblade) or spell(secret_technique) or spell(eviscerate) }
}

### actions.essences

AddFunction SubtletyEssencesMainActions
{
 #concentrated_flame,if=energy.time_to_max>1&!buff.symbols_of_death.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if timetomaxenergy() > 1 and not buffpresent(symbols_of_death_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } spell(concentrated_flame_essence)
}

AddFunction SubtletyEssencesMainPostConditions
{
}

AddFunction SubtletyEssencesShortCdActions
{
 unless timetomaxenergy() > 1 and not buffpresent(symbols_of_death_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #purifying_blast,if=spell_targets.shuriken_storm>=2|raid_event.adds.in>60
  if enemies() >= 2 or 600 > 60 spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 spell(the_unbound_force)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if buffstacks(lifeblood_buff) < 3 spell(worldvein_resonance_essence)
 }
}

AddFunction SubtletyEssencesShortCdPostConditions
{
 timetomaxenergy() > 1 and not buffpresent(symbols_of_death_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
}

AddFunction SubtletyEssencesCdActions
{
 unless timetomaxenergy() > 1 and not buffpresent(symbols_of_death_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=!cooldown.shadow_blades.up&cooldown.symbols_of_death.up|target.time_to_die<=10
  if not { not spellcooldown(shadow_blades) > 0 } and not spellcooldown(symbols_of_death) > 0 or target.timetodie() <= 10 spell(blood_of_the_enemy)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #focused_azerite_beam,if=(spell_targets.shuriken_storm>=2|raid_event.adds.in>60)&!cooldown.symbols_of_death.up&!buff.symbols_of_death.up&energy.deficit>=30
  if { enemies() >= 2 or 600 > 60 } and not { not spellcooldown(symbols_of_death) > 0 } and not buffpresent(symbols_of_death_buff) and energydeficit() >= 30 spell(focused_azerite_beam)

  unless { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=energy<40&buff.symbols_of_death.up
   if energy() < 40 and buffpresent(symbols_of_death_buff) spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction SubtletyEssencesCdPostConditions
{
 timetomaxenergy() > 1 and not buffpresent(symbols_of_death_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) or spellfullrecharge(concentrated_flame_essence) < gcd() } and spell(concentrated_flame_essence) or { enemies() >= 2 or 600 > 60 } and spell(purifying_blast) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 10 } and spell(the_unbound_force) or spell(ripple_in_space_essence) or buffstacks(lifeblood_buff) < 3 and spell(worldvein_resonance_essence)
}

### actions.cds

AddFunction SubtletyCdsMainActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.nightblade.ticking
 if not stealthed() and target.DebuffPresent(nightblade_debuff) SubtletyEssencesMainActions()
}

AddFunction SubtletyCdsMainPostConditions
{
 not stealthed() and target.DebuffPresent(nightblade_debuff) and SubtletyEssencesMainPostConditions()
}

AddFunction SubtletyCdsShortCdActions
{
 #shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if not buffpresent(shadow_dance_buff) and buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 spell(shadow_dance)
 #symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 spell(symbols_of_death)
 #call_action_list,name=essences,if=!stealthed.all&dot.nightblade.ticking
 if not stealthed() and target.DebuffPresent(nightblade_debuff) SubtletyEssencesShortCdActions()

 unless not stealthed() and target.DebuffPresent(nightblade_debuff) and SubtletyEssencesShortCdPostConditions()
 {
  #pool_resource,for_next=1,if=!talent.shadow_focus.enabled
  unless not hastalent(shadow_focus_talent)
  {
   #shuriken_tornado,if=energy>=60&dot.nightblade.ticking&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1
   if energy() >= 60 and target.DebuffPresent(nightblade_debuff) and not spellcooldown(symbols_of_death) > 0 and spellcharges(shadow_dance) >= 1 spell(shuriken_tornado)
   #symbols_of_death,if=dot.nightblade.ticking&!cooldown.shadow_blades.up&(!talent.shuriken_tornado.enabled|talent.shadow_focus.enabled|cooldown.shuriken_tornado.remains>2)&(!essence.blood_of_the_enemy.major|cooldown.blood_of_the_enemy.remains>2)&(azerite.nights_vengeance.rank<2|buff.nights_vengeance.up)
   if target.DebuffPresent(nightblade_debuff) and not { not spellcooldown(shadow_blades) > 0 } and { not hastalent(shuriken_tornado_talent) or hastalent(shadow_focus_talent) or spellcooldown(shuriken_tornado) > 2 } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or spellcooldown(blood_of_the_enemy) > 2 } and { azeritetraitrank(nights_vengeance_trait) < 2 or buffpresent(nights_vengeance_buff) } spell(symbols_of_death)
   #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend)
   if false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() } spell(marked_for_death)
   #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.all&combo_points.deficit>=cp_max_spend
   if 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() spell(marked_for_death)
   #shuriken_tornado,if=talent.shadow_focus.enabled&dot.nightblade.ticking&buff.symbols_of_death.up
   if hastalent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and buffpresent(symbols_of_death_buff) spell(shuriken_tornado)
   #shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=5+talent.subterfuge.enabled&!raid_event.adds.up
   if not buffpresent(shadow_dance_buff) and target.timetodie() <= 5 + talentpoints(subterfuge_talent) and not false(raid_event_adds_exists) spell(shadow_dance)
  }
 }
}

AddFunction SubtletyCdsShortCdPostConditions
{
 not stealthed() and target.DebuffPresent(nightblade_debuff) and SubtletyEssencesShortCdPostConditions()
}

AddFunction SubtletyCdsCdActions
{
 unless not buffpresent(shadow_dance_buff) and buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 and spell(shadow_dance) or buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 and spell(symbols_of_death)
 {
  #call_action_list,name=essences,if=!stealthed.all&dot.nightblade.ticking
  if not stealthed() and target.DebuffPresent(nightblade_debuff) SubtletyEssencesCdActions()

  unless not stealthed() and target.DebuffPresent(nightblade_debuff) and SubtletyEssencesCdPostConditions()
  {
   #pool_resource,for_next=1,if=!talent.shadow_focus.enabled
   unless not hastalent(shadow_focus_talent)
   {
    unless energy() >= 60 and target.DebuffPresent(nightblade_debuff) and not spellcooldown(symbols_of_death) > 0 and spellcharges(shadow_dance) >= 1 and spell(shuriken_tornado) or target.DebuffPresent(nightblade_debuff) and not { not spellcooldown(shadow_blades) > 0 } and { not hastalent(shuriken_tornado_talent) or hastalent(shadow_focus_talent) or spellcooldown(shuriken_tornado) > 2 } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or spellcooldown(blood_of_the_enemy) > 2 } and { azeritetraitrank(nights_vengeance_trait) < 2 or buffpresent(nights_vengeance_buff) } and spell(symbols_of_death) or false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() } and spell(marked_for_death) or 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() and spell(marked_for_death)
    {
     #shadow_blades,if=!stealthed.all&dot.nightblade.ticking&combo_points.deficit>=2
     if not stealthed() and target.DebuffPresent(nightblade_debuff) and combopointsdeficit() >= 2 spell(shadow_blades)

     unless hastalent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and buffpresent(symbols_of_death_buff) and spell(shuriken_tornado) or not buffpresent(shadow_dance_buff) and target.timetodie() <= 5 + talentpoints(subterfuge_talent) and not false(raid_event_adds_exists) and spell(shadow_dance)
     {
      #potion,if=buff.bloodlust.react|buff.symbols_of_death.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=10)
      if { buffpresent(bloodlust) or buffpresent(symbols_of_death_buff) and { buffpresent(shadow_blades_buff) or spellcooldown(shadow_blades) <= 10 } } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
      #blood_fury,if=buff.symbols_of_death.up
      if buffpresent(symbols_of_death_buff) spell(blood_fury_ap)
      #berserking,if=buff.symbols_of_death.up
      if buffpresent(symbols_of_death_buff) spell(berserking)
      #fireblood,if=buff.symbols_of_death.up
      if buffpresent(symbols_of_death_buff) spell(fireblood)
      #ancestral_call,if=buff.symbols_of_death.up
      if buffpresent(symbols_of_death_buff) spell(ancestral_call)
      #use_item,effect_name=cyclotronic_blast,if=!stealthed.all&dot.nightblade.ticking&!buff.symbols_of_death.up&energy.deficit>=30
      if not stealthed() and target.DebuffPresent(nightblade_debuff) and not buffpresent(symbols_of_death_buff) and energydeficit() >= 30 subtletyuseitemactions()
      #use_item,name=azsharas_font_of_power,if=!buff.shadow_dance.up&cooldown.symbols_of_death.remains<10
      if not buffpresent(shadow_dance_buff) and spellcooldown(symbols_of_death) < 10 subtletyuseitemactions()
      #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<32&target.health.pct>=30|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.symbols_of_death.remains>8
      if target.DebuffExpires(razor_coral) or target.DebuffPresent(conductive_ink) and target.healthpercent() < 32 and target.healthpercent() >= 30 or not target.DebuffPresent(conductive_ink) and { target.DebuffStacks(razor_coral) >= 25 - 10 * target.DebuffPresent(blood_of_the_enemy) or target.timetodie() < 40 } and buffremaining(symbols_of_death_buff) > 8 subtletyuseitemactions()
      #use_item,name=mydas_talisman
      subtletyuseitemactions()
      #use_items,if=buff.symbols_of_death.up|target.time_to_die<20
      if buffpresent(symbols_of_death_buff) or target.timetodie() < 20 subtletyuseitemactions()
     }
    }
   }
  }
 }
}

AddFunction SubtletyCdsCdPostConditions
{
 not buffpresent(shadow_dance_buff) and buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 and spell(shadow_dance) or buffpresent(shuriken_tornado) and buffremaining(shuriken_tornado) <= 3.5 and spell(symbols_of_death) or not stealthed() and target.DebuffPresent(nightblade_debuff) and SubtletyEssencesCdPostConditions() or not { not hastalent(shadow_focus_talent) } and { energy() >= 60 and target.DebuffPresent(nightblade_debuff) and not spellcooldown(symbols_of_death) > 0 and spellcharges(shadow_dance) >= 1 and spell(shuriken_tornado) or target.DebuffPresent(nightblade_debuff) and not { not spellcooldown(shadow_blades) > 0 } and { not hastalent(shuriken_tornado_talent) or hastalent(shadow_focus_talent) or spellcooldown(shuriken_tornado) > 2 } and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or spellcooldown(blood_of_the_enemy) > 2 } and { azeritetraitrank(nights_vengeance_trait) < 2 or buffpresent(nights_vengeance_buff) } and spell(symbols_of_death) or false(raid_event_adds_exists) and { target.timetodie() < combopointsdeficit() or not stealthed() and combopointsdeficit() >= maxcombopoints() } and spell(marked_for_death) or 600 > 30 - 10 and not stealthed() and combopointsdeficit() >= maxcombopoints() and spell(marked_for_death) or hastalent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and buffpresent(symbols_of_death_buff) and spell(shuriken_tornado) or not buffpresent(shadow_dance_buff) and target.timetodie() <= 5 + talentpoints(subterfuge_talent) and not false(raid_event_adds_exists) and spell(shadow_dance) }
}

### actions.build

AddFunction SubtletyBuildMainActions
{
 #shuriken_storm,if=spell_targets>=2+(talent.gloomblade.enabled&azerite.perforate.rank>=2&position_back)
 if enemies() >= 2 + { hastalent(gloomblade_talent) and azeritetraitrank(perforate_trait) >= 2 and true(position_back) } spell(shuriken_storm)
 #gloomblade
 spell(gloomblade)
 #backstab
 spell(backstab)
}

AddFunction SubtletyBuildMainPostConditions
{
}

AddFunction SubtletyBuildShortCdActions
{
}

AddFunction SubtletyBuildShortCdPostConditions
{
 enemies() >= 2 + { hastalent(gloomblade_talent) and azeritetraitrank(perforate_trait) >= 2 and true(position_back) } and spell(shuriken_storm) or spell(gloomblade) or spell(backstab)
}

AddFunction SubtletyBuildCdActions
{
}

AddFunction SubtletyBuildCdPostConditions
{
 enemies() >= 2 + { hastalent(gloomblade_talent) and azeritetraitrank(perforate_trait) >= 2 and true(position_back) } and spell(shuriken_storm) or spell(gloomblade) or spell(backstab)
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
 #stealth
 spell(stealth)
 #call_action_list,name=cds
 SubtletyCdsMainActions()

 unless SubtletyCdsMainPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if stealthed() SubtletyStealthedMainActions()

  unless stealthed() and SubtletyStealthedMainPostConditions()
  {
   #nightblade,if=target.time_to_die>6&remains<gcd.max&combo_points>=4-(time<10)*2
   if target.timetodie() > 6 and target.DebuffRemaining(nightblade_debuff) < gcd() and combopoints() >= 4 - { timeincombat() < 10 } * 2 spell(nightblade)
   #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
   #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
   if undefined() SubtletyStealthcdsMainActions()

   unless undefined() and SubtletyStealthcdsMainPostConditions()
   {
    #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
    #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold
    if energydeficit() <= undefined() SubtletyStealthcdsMainActions()

    unless energydeficit() <= undefined() and SubtletyStealthcdsMainPostConditions()
    {
     #nightblade,if=azerite.nights_vengeance.enabled&!buff.nights_vengeance.up&combo_points.deficit>1&(spell_targets.shuriken_storm<2|variable.use_priority_rotation)&(cooldown.symbols_of_death.remains<=3|(azerite.nights_vengeance.rank>=2&buff.symbols_of_death.remains>3&!stealthed.all&cooldown.shadow_dance.charges_fractional>=0.9))
     if hasazeritetrait(nights_vengeance_trait) and not buffpresent(nights_vengeance_buff) and combopointsdeficit() > 1 and { enemies() < 2 or undefined() } and { spellcooldown(symbols_of_death) <= 3 or azeritetraitrank(nights_vengeance_trait) >= 2 and buffremaining(symbols_of_death_buff) > 3 and not stealthed() and spellcharges(shadow_dance count=0) >= 0.9 } spell(nightblade)
     #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
     if combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 SubtletyFinishMainActions()

     unless { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishMainPostConditions()
     {
      #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
      if enemies() == 4 and combopoints() >= 4 SubtletyFinishMainActions()

      unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishMainPostConditions()
      {
       #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
       if energydeficit() <= undefined() SubtletyBuildMainActions()
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultMainPostConditions
{
 SubtletyCdsMainPostConditions() or stealthed() and SubtletyStealthedMainPostConditions() or undefined() and SubtletyStealthcdsMainPostConditions() or energydeficit() <= undefined() and SubtletyStealthcdsMainPostConditions() or { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishMainPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishMainPostConditions() or energydeficit() <= undefined() and SubtletyBuildMainPostConditions()
}

AddFunction SubtletyDefaultShortCdActions
{
 unless spell(stealth)
 {
  #call_action_list,name=cds
  SubtletyCdsShortCdActions()

  unless SubtletyCdsShortCdPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if stealthed() SubtletyStealthedShortCdActions()

   unless stealthed() and SubtletyStealthedShortCdPostConditions() or target.timetodie() > 6 and target.DebuffRemaining(nightblade_debuff) < gcd() and combopoints() >= 4 - { timeincombat() < 10 } * 2 and spell(nightblade)
   {
    #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
    #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
    if undefined() SubtletyStealthcdsShortCdActions()

    unless undefined() and SubtletyStealthcdsShortCdPostConditions()
    {
     #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold
     if energydeficit() <= undefined() SubtletyStealthcdsShortCdActions()

     unless energydeficit() <= undefined() and SubtletyStealthcdsShortCdPostConditions() or hasazeritetrait(nights_vengeance_trait) and not buffpresent(nights_vengeance_buff) and combopointsdeficit() > 1 and { enemies() < 2 or undefined() } and { spellcooldown(symbols_of_death) <= 3 or azeritetraitrank(nights_vengeance_trait) >= 2 and buffremaining(symbols_of_death_buff) > 3 and not stealthed() and spellcharges(shadow_dance count=0) >= 0.9 } and spell(nightblade)
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 SubtletyFinishShortCdActions()

      unless { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishShortCdPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if enemies() == 4 and combopoints() >= 4 SubtletyFinishShortCdActions()

       unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishShortCdPostConditions()
       {
        #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
        if energydeficit() <= undefined() SubtletyBuildShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultShortCdPostConditions
{
 spell(stealth) or SubtletyCdsShortCdPostConditions() or stealthed() and SubtletyStealthedShortCdPostConditions() or target.timetodie() > 6 and target.DebuffRemaining(nightblade_debuff) < gcd() and combopoints() >= 4 - { timeincombat() < 10 } * 2 and spell(nightblade) or undefined() and SubtletyStealthcdsShortCdPostConditions() or energydeficit() <= undefined() and SubtletyStealthcdsShortCdPostConditions() or hasazeritetrait(nights_vengeance_trait) and not buffpresent(nights_vengeance_buff) and combopointsdeficit() > 1 and { enemies() < 2 or undefined() } and { spellcooldown(symbols_of_death) <= 3 or azeritetraitrank(nights_vengeance_trait) >= 2 and buffremaining(symbols_of_death_buff) > 3 and not stealthed() and spellcharges(shadow_dance count=0) >= 0.9 } and spell(nightblade) or { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishShortCdPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishShortCdPostConditions() or energydeficit() <= undefined() and SubtletyBuildShortCdPostConditions()
}

AddFunction SubtletyDefaultCdActions
{
 undefined()

 unless spell(stealth)
 {
  #call_action_list,name=cds
  SubtletyCdsCdActions()

  unless SubtletyCdsCdPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if stealthed() SubtletyStealthedCdActions()

   unless stealthed() and SubtletyStealthedCdPostConditions() or target.timetodie() > 6 and target.DebuffRemaining(nightblade_debuff) < gcd() and combopoints() >= 4 - { timeincombat() < 10 } * 2 and spell(nightblade)
   {
    #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
    #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
    if undefined() SubtletyStealthcdsCdActions()

    unless undefined() and SubtletyStealthcdsCdPostConditions()
    {
     #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold
     if energydeficit() <= undefined() SubtletyStealthcdsCdActions()

     unless energydeficit() <= undefined() and SubtletyStealthcdsCdPostConditions() or hasazeritetrait(nights_vengeance_trait) and not buffpresent(nights_vengeance_buff) and combopointsdeficit() > 1 and { enemies() < 2 or undefined() } and { spellcooldown(symbols_of_death) <= 3 or azeritetraitrank(nights_vengeance_trait) >= 2 and buffremaining(symbols_of_death_buff) > 3 and not stealthed() and spellcharges(shadow_dance count=0) >= 0.9 } and spell(nightblade)
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 SubtletyFinishCdActions()

      unless { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishCdPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if enemies() == 4 and combopoints() >= 4 SubtletyFinishCdActions()

       unless enemies() == 4 and combopoints() >= 4 and SubtletyFinishCdPostConditions()
       {
        #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
        if energydeficit() <= undefined() SubtletyBuildCdActions()

        unless energydeficit() <= undefined() and SubtletyBuildCdPostConditions()
        {
         #arcane_torrent,if=energy.deficit>=15+energy.regen
         if energydeficit() >= 15 + energyregenrate() spell(arcane_torrent_energy)
         #arcane_pulse
         spell(arcane_pulse)
         #lights_judgment
         spell(lights_judgment)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultCdPostConditions
{
 spell(stealth) or SubtletyCdsCdPostConditions() or stealthed() and SubtletyStealthedCdPostConditions() or target.timetodie() > 6 and target.DebuffRemaining(nightblade_debuff) < gcd() and combopoints() >= 4 - { timeincombat() < 10 } * 2 and spell(nightblade) or undefined() and SubtletyStealthcdsCdPostConditions() or energydeficit() <= undefined() and SubtletyStealthcdsCdPostConditions() or hasazeritetrait(nights_vengeance_trait) and not buffpresent(nights_vengeance_buff) and combopointsdeficit() > 1 and { enemies() < 2 or undefined() } and { spellcooldown(symbols_of_death) <= 3 or azeritetraitrank(nights_vengeance_trait) >= 2 and buffremaining(symbols_of_death_buff) > 3 and not stealthed() and spellcharges(shadow_dance count=0) >= 0.9 } and spell(nightblade) or { combopointsdeficit() <= 1 or target.timetodie() <= 1 and combopoints() >= 3 } and SubtletyFinishCdPostConditions() or enemies() == 4 and combopoints() >= 4 and SubtletyFinishCdPostConditions() or energydeficit() <= undefined() and SubtletyBuildCdPostConditions()
}

### Subtlety icons.

AddCheckBox(opt_rogue_subtlety_aoe l(AOE) default specialization=subtlety)

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=shortcd specialization=subtlety
{
 if not incombat() subtletyprecombatshortcdactions()
 unless not incombat() and subtletyprecombatshortcdpostconditions()
 {
  subtletydefaultshortcdactions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=shortcd specialization=subtlety
{
 if not incombat() subtletyprecombatshortcdactions()
 unless not incombat() and subtletyprecombatshortcdpostconditions()
 {
  subtletydefaultshortcdactions()
 }
}

AddIcon enemies=1 help=main specialization=subtlety
{
 if not incombat() subtletyprecombatmainactions()
 unless not incombat() and subtletyprecombatmainpostconditions()
 {
  subtletydefaultmainactions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=aoe specialization=subtlety
{
 if not incombat() subtletyprecombatmainactions()
 unless not incombat() and subtletyprecombatmainpostconditions()
 {
  subtletydefaultmainactions()
 }
}

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=cd specialization=subtlety
{
 if not incombat() subtletyprecombatcdactions()
 unless not incombat() and subtletyprecombatcdpostconditions()
 {
  subtletydefaultcdactions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=cd specialization=subtlety
{
 if not incombat() subtletyprecombatcdactions()
 unless not incombat() and subtletyprecombatcdpostconditions()
 {
  subtletydefaultcdactions()
 }
}

### Required symbols
# alacrity_talent
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# backstab
# berserking
# blade_in_the_shadows_trait
# blood_fury_ap
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# cheap_shot
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
# dark_shadow_talent
# deeper_stratagem_talent
# eviscerate
# find_weakness_debuff
# find_weakness_talent
# fireblood
# focused_azerite_beam
# gloomblade
# gloomblade_talent
# guardian_of_azeroth
# inevitability_trait
# kick
# kidney_shot
# lifeblood_buff
# lights_judgment
# marked_for_death
# master_of_shadows_talent
# memory_of_lucid_dreams_essence
# nightblade
# nightblade_debuff
# nights_vengeance_buff
# nights_vengeance_trait
# nightstalker_talent
# perforate_trait
# purifying_blast
# quaking_palm
# razor_coral
# reckless_force_buff
# reckless_force_counter_buff
# replicating_shadows_trait
# ripple_in_space_essence
# secret_technique
# secret_technique_talent
# shadow_blades
# shadow_blades_buff
# shadow_dance
# shadow_dance_buff
# shadow_focus_talent
# shadowmeld
# shadowstep
# shadowstrike
# shuriken_storm
# shuriken_tornado
# shuriken_tornado_talent
# stealth
# subterfuge_talent
# symbols_of_death
# symbols_of_death_buff
# the_first_dance_trait
# the_unbound_force
# unbridled_fury_item
# vanish
# vanish_buff
# vigor_talent
# weaponmaster_talent
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
    end
end
