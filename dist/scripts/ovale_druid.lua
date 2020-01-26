local __exports = LibStub:NewLibrary("ovale/scripts/ovale_druid", 80300)
if not __exports then return end
__exports.registerDruid = function(OvaleScripts)
    do
        local name = "sc_t24_druid_balance"
        local desc = "[8.3] Simulationcraft: T24_Druid_Balance"
        local code = [[
# Based on SimulationCraft profile "T24_Druid_Balance".
#	class=druid
#	spec=balance
#	talents=1000231

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction sf_targets
{
 4
}

AddFunction az_ap
{
 azeritetraitrank(arcanic_pulsar_trait)
}

AddFunction az_ss
{
 azeritetraitrank(streaking_stars_trait)
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=balance)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=balance)

AddFunction balanceinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(solar_beam) and target.isinterruptible() spell(solar_beam)
  if target.inrange(mighty_bash) and not target.classification(worldboss) spell(mighty_bash)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.distance(less 15) and not target.classification(worldboss) spell(typhoon)
 }
}

AddFunction balanceuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction balanceprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #variable,name=az_ss,value=azerite.streaking_stars.rank
 #variable,name=az_ap,value=azerite.arcanic_pulsar.rank
 #variable,name=sf_targets,value=4
 #variable,name=sf_targets,op=add,value=1,if=azerite.arcanic_pulsar.enabled
 #variable,name=sf_targets,op=add,value=1,if=talent.starlord.enabled
 #variable,name=sf_targets,op=add,value=1,if=azerite.streaking_stars.rank>2&azerite.arcanic_pulsar.enabled
 #variable,name=sf_targets,op=sub,value=1,if=!talent.twin_moons.enabled
 #moonkin_form
 spell(moonkin_form_balance)
 #solar_wrath
 spell(solar_wrath_balance)
 #solar_wrath
 spell(solar_wrath_balance)
 #starsurge
 spell(starsurge_balance)
}

AddFunction balanceprecombatmainpostconditions
{
}

AddFunction balanceprecombatshortcdactions
{
}

AddFunction balanceprecombatshortcdpostconditions
{
 spell(moonkin_form_balance) or spell(solar_wrath_balance) or spell(solar_wrath_balance) or spell(starsurge_balance)
}

AddFunction balanceprecombatcdactions
{
 unless spell(moonkin_form_balance)
 {
  #use_item,name=azsharas_font_of_power
  balanceuseitemactions()
  #potion,dynamic_prepot=1
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction balanceprecombatcdpostconditions
{
 spell(moonkin_form_balance) or spell(solar_wrath_balance) or spell(solar_wrath_balance) or spell(starsurge_balance)
}

### actions.default

AddFunction balance_defaultmainactions
{
 #concentrated_flame,if=(!buff.ca_inc.up|stack=2)&!action.concentrated_flame_missile.in_flight,target_if=!dot.concentrated_flame_burn.ticking
 if { not buffpresent(ca_inc) or buffstacks(concentrated_flame_essence) == 2 } and not inflighttotarget(concentrated_flame) and not target.debuffpresent(concentrated_flame_burn_debuff) spell(concentrated_flame_essence)
 #warrior_of_elune
 spell(warrior_of_elune)
 #force_of_nature,if=(variable.az_ss&!buff.ca_inc.up|!variable.az_ss&(buff.ca_inc.up|cooldown.ca_inc.remains>30))&ap_check
 if { az_ss() and not buffpresent(ca_inc) or not az_ss() and { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } } and astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)
 #cancel_buff,name=starlord,if=buff.starlord.remains<3&!solar_wrath.ap_check
 if buffremaining(starlord_buff) < 3 and not astralpower() >= astralpowercost(solar_wrath) and buffpresent(starlord_buff) texture(starlord text=cancel)
 #starfall,if=(buff.starlord.stack<3|buff.starlord.remains>=8)&spell_targets>=variable.sf_targets&(target.time_to_die+1)*spell_targets>cost%2.5
 if { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 8 } and enemies() >= sf_targets() and { target.timetodie() + 1 } * enemies() > powercost(starfall) / 2.5 spell(starfall)
 #starsurge,if=(talent.starlord.enabled&(buff.starlord.stack<3|buff.starlord.remains>=5&buff.arcanic_pulsar.stack<8)|!talent.starlord.enabled&(buff.arcanic_pulsar.stack<8|buff.ca_inc.up))&spell_targets.starfall<variable.sf_targets&buff.lunar_empowerment.stack+buff.solar_empowerment.stack<4&buff.solar_empowerment.stack<3&buff.lunar_empowerment.stack<3&(!variable.az_ss|!buff.ca_inc.up|!prev.starsurge)|target.time_to_die<=execute_time*astral_power%40|!solar_wrath.ap_check
 if { hastalent(starlord_talent) and { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 5 and buffstacks(arcanic_pulsar_buff) < 8 } or not hastalent(starlord_talent) and { buffstacks(arcanic_pulsar_buff) < 8 or buffpresent(ca_inc) } } and enemies() < sf_targets() and buffstacks(lunar_empowerment_buff) + buffstacks(solar_empowerment_buff) < 4 and buffstacks(solar_empowerment_buff) < 3 and buffstacks(lunar_empowerment_buff) < 3 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(starsurge_balance) } or target.timetodie() <= executetime(starsurge_balance) * astralpower() / 40 or not astralpower() >= astralpowercost(solar_wrath) spell(starsurge_balance)
 #sunfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss&dot.moonfire.remains>remains
 if buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() and target.debuffremaining(moonfire) > target.debuffremaining(sunfire_debuff) spell(sunfire)
 #moonfire,if=buff.ca_inc.up&buff.ca_inc.remains<gcd.max&variable.az_ss
 if buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() spell(moonfire)
 #sunfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=ceil(floor(2%spell_targets)*1.5)+2*spell_targets&(spell_targets>1+talent.twin_moons.enabled|dot.moonfire.ticking)&(!variable.az_ss|!buff.ca_inc.up|!prev.sunfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
 if target.refreshable(sunfire_debuff) and astralpower() >= astralpowercost(sunfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 2 / enemies() * 1.5 + 2 * enemies() and { enemies() > 1 + talentpoints(twin_moons_talent) or target.debuffpresent(moonfire) } and { not az_ss() or not buffpresent(ca_inc) or not previousspell(sunfire) } and { buffremaining(ca_inc) > target.debuffremaining(sunfire_debuff) or not buffpresent(ca_inc) } spell(sunfire)
 #moonfire,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))*spell_targets>=6&(!variable.az_ss|!buff.ca_inc.up|!prev.moonfire)&(buff.ca_inc.remains>remains|!buff.ca_inc.up)
 if target.refreshable(moonfire) and astralpower() >= astralpowercost(moonfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 6 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(moonfire) } and { buffremaining(ca_inc) > buffremaining(moonfire) or not buffpresent(ca_inc) } spell(moonfire)
 #stellar_flare,target_if=refreshable,if=ap_check&floor(target.time_to_die%(2*spell_haste))>=5&(!variable.az_ss|!buff.ca_inc.up|!prev.stellar_flare)
 if target.refreshable(stellar_flare_debuff) and astralpower() >= astralpowercost(stellar_flare) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } >= 5 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(stellar_flare) } spell(stellar_flare)
 #new_moon,if=ap_check
 if astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) spell(new_moon)
 #half_moon,if=ap_check
 if astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) spell(half_moon)
 #full_moon,if=ap_check
 if astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) spell(full_moon)
 #lunar_strike,if=buff.solar_empowerment.stack<3&(ap_check|buff.lunar_empowerment.stack=3)&((buff.warrior_of_elune.up|buff.lunar_empowerment.up|spell_targets>=2&!buff.solar_empowerment.up)&(!variable.az_ss|!buff.ca_inc.up)|variable.az_ss&buff.ca_inc.up&prev.solar_wrath)
 if buffstacks(solar_empowerment_buff) < 3 and { astralpower() >= astralpowercost(lunar_strike) or buffstacks(lunar_empowerment_buff) == 3 } and { { buffpresent(warrior_of_elune_buff) or buffpresent(lunar_empowerment_buff) or enemies() >= 2 and not buffpresent(solar_empowerment_buff) } and { not az_ss() or not buffpresent(ca_inc) } or az_ss() and buffpresent(ca_inc) and previousspell(solar_wrath_balance) } spell(lunar_strike)
 #solar_wrath,if=variable.az_ss<3|!buff.ca_inc.up|!prev.solar_wrath
 if az_ss() < 3 or not buffpresent(ca_inc) or not previousspell(solar_wrath_balance) spell(solar_wrath_balance)
 #sunfire
 spell(sunfire)
}

AddFunction balance_defaultmainpostconditions
{
}

AddFunction balance_defaultshortcdactions
{
 #purifying_blast
 spell(purifying_blast)
 #ripple_in_space
 spell(ripple_in_space_essence)

 unless { not buffpresent(ca_inc) or buffstacks(concentrated_flame_essence) == 2 } and not inflighttotarget(concentrated_flame) and not target.debuffpresent(concentrated_flame_burn_debuff) and spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<5,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
  if { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 5 } and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } spell(the_unbound_force)
  #worldvein_resonance,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
  if not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } spell(worldvein_resonance_essence)
  #reaping_flames,if=!buff.ca_inc.up
  if not buffpresent(ca_inc) spell(reaping_flames)
  #thorns
  spell(thorns)

  unless spell(warrior_of_elune) or { az_ss() and not buffpresent(ca_inc) or not az_ss() and { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } } and astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
  {
   #fury_of_elune,if=(buff.ca_inc.up|cooldown.ca_inc.remains>30)&solar_wrath.ap_check
   if { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } and astralpower() >= astralpowercost(solar_wrath) spell(fury_of_elune)
  }
 }
}

AddFunction balance_defaultshortcdpostconditions
{
 { not buffpresent(ca_inc) or buffstacks(concentrated_flame_essence) == 2 } and not inflighttotarget(concentrated_flame) and not target.debuffpresent(concentrated_flame_burn_debuff) and spell(concentrated_flame_essence) or spell(warrior_of_elune) or { az_ss() and not buffpresent(ca_inc) or not az_ss() and { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } } and astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or buffremaining(starlord_buff) < 3 and not astralpower() >= astralpowercost(solar_wrath) and buffpresent(starlord_buff) and texture(starlord text=cancel) or { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 8 } and enemies() >= sf_targets() and { target.timetodie() + 1 } * enemies() > powercost(starfall) / 2.5 and spell(starfall) or { { hastalent(starlord_talent) and { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 5 and buffstacks(arcanic_pulsar_buff) < 8 } or not hastalent(starlord_talent) and { buffstacks(arcanic_pulsar_buff) < 8 or buffpresent(ca_inc) } } and enemies() < sf_targets() and buffstacks(lunar_empowerment_buff) + buffstacks(solar_empowerment_buff) < 4 and buffstacks(solar_empowerment_buff) < 3 and buffstacks(lunar_empowerment_buff) < 3 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(starsurge_balance) } or target.timetodie() <= executetime(starsurge_balance) * astralpower() / 40 or not astralpower() >= astralpowercost(solar_wrath) } and spell(starsurge_balance) or buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() and target.debuffremaining(moonfire) > target.debuffremaining(sunfire_debuff) and spell(sunfire) or buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() and spell(moonfire) or target.refreshable(sunfire_debuff) and astralpower() >= astralpowercost(sunfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 2 / enemies() * 1.5 + 2 * enemies() and { enemies() > 1 + talentpoints(twin_moons_talent) or target.debuffpresent(moonfire) } and { not az_ss() or not buffpresent(ca_inc) or not previousspell(sunfire) } and { buffremaining(ca_inc) > target.debuffremaining(sunfire_debuff) or not buffpresent(ca_inc) } and spell(sunfire) or target.refreshable(moonfire) and astralpower() >= astralpowercost(moonfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 6 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(moonfire) } and { buffremaining(ca_inc) > buffremaining(moonfire) or not buffpresent(ca_inc) } and spell(moonfire) or target.refreshable(stellar_flare_debuff) and astralpower() >= astralpowercost(stellar_flare) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } >= 5 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or buffstacks(solar_empowerment_buff) < 3 and { astralpower() >= astralpowercost(lunar_strike) or buffstacks(lunar_empowerment_buff) == 3 } and { { buffpresent(warrior_of_elune_buff) or buffpresent(lunar_empowerment_buff) or enemies() >= 2 and not buffpresent(solar_empowerment_buff) } and { not az_ss() or not buffpresent(ca_inc) } or az_ss() and buffpresent(ca_inc) and previousspell(solar_wrath_balance) } and spell(lunar_strike) or { az_ss() < 3 or not buffpresent(ca_inc) or not previousspell(solar_wrath_balance) } and spell(solar_wrath_balance) or spell(sunfire)
}

AddFunction balance_defaultcdactions
{
 balanceinterruptactions()
 #potion,if=buff.celestial_alignment.remains>13|buff.incarnation.remains>16.5
 if { buffremaining(celestial_alignment_buff) > 13 or buffremaining(incarnation_chosen_of_elune_buff) > 16.5 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #berserking,if=buff.ca_inc.up
 if buffpresent(ca_inc) spell(berserking)
 #use_item,name=azsharas_font_of_power,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
 if not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } balanceuseitemactions()
 #guardian_of_azeroth,if=(!talent.starlord.enabled|buff.starlord.up)&!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
 if { not hastalent(starlord_talent) or buffpresent(starlord_buff) } and not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } spell(guardian_of_azeroth)
 #use_item,effect_name=cyclotronic_blast,if=!buff.ca_inc.up,target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
 if not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } balanceuseitemactions()
 #use_item,name=shiver_venom_relic,if=!buff.ca_inc.up&!buff.bloodlust.up,target_if=dot.shiver_venom.stack>=5
 if not buffpresent(ca_inc) and not buffpresent(bloodlust) and target.debuffstacks(shiver_venom) >= 5 balanceuseitemactions()
 #blood_of_the_enemy,if=cooldown.ca_inc.remains>30
 if spellcooldown(ca_inc) > 30 spell(blood_of_the_enemy)
 #memory_of_lucid_dreams,if=!buff.ca_inc.up&(astral_power<25|cooldown.ca_inc.remains>30),target_if=dot.sunfire.remains>10&dot.moonfire.remains>10&(!talent.stellar_flare.enabled|dot.stellar_flare.remains>10)
 if not buffpresent(ca_inc) and { astralpower() < 25 or spellcooldown(ca_inc) > 30 } and target.debuffremaining(sunfire_debuff) > 10 and target.debuffremaining(moonfire) > 10 and { not hastalent(stellar_flare_talent) or target.debuffremaining(stellar_flare_debuff) > 10 } spell(memory_of_lucid_dreams_essence)

 unless spell(purifying_blast) or spell(ripple_in_space_essence) or { not buffpresent(ca_inc) or buffstacks(concentrated_flame_essence) == 2 } and not inflighttotarget(concentrated_flame) and not target.debuffpresent(concentrated_flame_burn_debuff) and spell(concentrated_flame_essence) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 5 } and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } and spell(the_unbound_force) or not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } and spell(worldvein_resonance_essence) or not buffpresent(ca_inc) and spell(reaping_flames)
 {
  #focused_azerite_beam,if=(!variable.az_ss|!buff.ca_inc.up),target_if=dot.moonfire.ticking&dot.sunfire.ticking&(!talent.stellar_flare.enabled|dot.stellar_flare.ticking)
  if { not az_ss() or not buffpresent(ca_inc) } and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } spell(focused_azerite_beam)

  unless spell(thorns)
  {
   #use_items,slots=trinket1,if=!trinket.1.has_proc.any|buff.ca_inc.up
   if not true(trinket_has_proc_any) or buffpresent(ca_inc) balanceuseitemactions()
   #use_items,slots=trinket2,if=!trinket.2.has_proc.any|buff.ca_inc.up
   if not true(trinket_has_proc_any) or buffpresent(ca_inc) balanceuseitemactions()
   #use_items
   balanceuseitemactions()

   unless spell(warrior_of_elune)
   {
    #innervate,if=azerite.lively_spirit.enabled&(cooldown.incarnation.remains<2|cooldown.celestial_alignment.remains<12)
    if hasazeritetrait(lively_spirit_trait) and { spellcooldown(incarnation_chosen_of_elune) < 2 or spellcooldown(celestial_alignment) < 12 } spell(innervate)

    unless { az_ss() and not buffpresent(ca_inc) or not az_ss() and { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } } and astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
    {
     #incarnation,if=!buff.ca_inc.up&(buff.memory_of_lucid_dreams.up|((cooldown.memory_of_lucid_dreams.remains>20|!essence.memory_of_lucid_dreams.major)&ap_check))&(buff.memory_of_lucid_dreams.up|ap_check),target_if=dot.sunfire.remains>8&dot.moonfire.remains>12&(dot.stellar_flare.remains>6|!talent.stellar_flare.enabled)
     if not buffpresent(ca_inc) and { buffpresent(memory_of_lucid_dreams_essence_buff) or { spellcooldown(memory_of_lucid_dreams_essence) > 20 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) } and astralpower() >= astralpowercost(incarnation_chosen_of_elune) } and { buffpresent(memory_of_lucid_dreams_essence_buff) or astralpower() >= astralpowercost(incarnation_chosen_of_elune) } and target.debuffremaining(sunfire_debuff) > 8 and target.debuffremaining(moonfire) > 12 and { target.debuffremaining(stellar_flare_debuff) > 6 or not hastalent(stellar_flare_talent) } spell(incarnation_chosen_of_elune)
     #celestial_alignment,if=!buff.ca_inc.up&(!talent.starlord.enabled|buff.starlord.up)&(buff.memory_of_lucid_dreams.up|((cooldown.memory_of_lucid_dreams.remains>20|!essence.memory_of_lucid_dreams.major)&ap_check))&(!azerite.lively_spirit.enabled|buff.lively_spirit.up),target_if=(dot.sunfire.remains>2&dot.moonfire.ticking&(dot.stellar_flare.ticking|!talent.stellar_flare.enabled))
     if not buffpresent(ca_inc) and { not hastalent(starlord_talent) or buffpresent(starlord_buff) } and { buffpresent(memory_of_lucid_dreams_essence_buff) or { spellcooldown(memory_of_lucid_dreams_essence) > 20 or not azeriteessenceismajor(memory_of_lucid_dreams_essence_id) } and astralpower() >= astralpowercost(celestial_alignment) } and { not hasazeritetrait(lively_spirit_trait) or buffpresent(lively_spirit_buff) } and target.debuffremaining(sunfire_debuff) > 2 and target.debuffpresent(moonfire) and { target.debuffpresent(stellar_flare_debuff) or not hastalent(stellar_flare_talent) } spell(celestial_alignment)
    }
   }
  }
 }
}

AddFunction balance_defaultcdpostconditions
{
 spell(purifying_blast) or spell(ripple_in_space_essence) or { not buffpresent(ca_inc) or buffstacks(concentrated_flame_essence) == 2 } and not inflighttotarget(concentrated_flame) and not target.debuffpresent(concentrated_flame_burn_debuff) and spell(concentrated_flame_essence) or { buffpresent(reckless_force_buff) or buffstacks(reckless_force_counter_buff) < 5 } and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } and spell(the_unbound_force) or not buffpresent(ca_inc) and target.debuffpresent(moonfire) and target.debuffpresent(sunfire_debuff) and { not hastalent(stellar_flare_talent) or target.debuffpresent(stellar_flare_debuff) } and spell(worldvein_resonance_essence) or not buffpresent(ca_inc) and spell(reaping_flames) or spell(thorns) or spell(warrior_of_elune) or { az_ss() and not buffpresent(ca_inc) or not az_ss() and { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } } and astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { buffpresent(ca_inc) or spellcooldown(ca_inc) > 30 } and astralpower() >= astralpowercost(solar_wrath) and spell(fury_of_elune) or buffremaining(starlord_buff) < 3 and not astralpower() >= astralpowercost(solar_wrath) and buffpresent(starlord_buff) and texture(starlord text=cancel) or { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 8 } and enemies() >= sf_targets() and { target.timetodie() + 1 } * enemies() > powercost(starfall) / 2.5 and spell(starfall) or { { hastalent(starlord_talent) and { buffstacks(starlord_buff) < 3 or buffremaining(starlord_buff) >= 5 and buffstacks(arcanic_pulsar_buff) < 8 } or not hastalent(starlord_talent) and { buffstacks(arcanic_pulsar_buff) < 8 or buffpresent(ca_inc) } } and enemies() < sf_targets() and buffstacks(lunar_empowerment_buff) + buffstacks(solar_empowerment_buff) < 4 and buffstacks(solar_empowerment_buff) < 3 and buffstacks(lunar_empowerment_buff) < 3 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(starsurge_balance) } or target.timetodie() <= executetime(starsurge_balance) * astralpower() / 40 or not astralpower() >= astralpowercost(solar_wrath) } and spell(starsurge_balance) or buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() and target.debuffremaining(moonfire) > target.debuffremaining(sunfire_debuff) and spell(sunfire) or buffpresent(ca_inc) and buffremaining(ca_inc) < gcd() and az_ss() and spell(moonfire) or target.refreshable(sunfire_debuff) and astralpower() >= astralpowercost(sunfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 2 / enemies() * 1.5 + 2 * enemies() and { enemies() > 1 + talentpoints(twin_moons_talent) or target.debuffpresent(moonfire) } and { not az_ss() or not buffpresent(ca_inc) or not previousspell(sunfire) } and { buffremaining(ca_inc) > target.debuffremaining(sunfire_debuff) or not buffpresent(ca_inc) } and spell(sunfire) or target.refreshable(moonfire) and astralpower() >= astralpowercost(moonfire) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } * enemies() >= 6 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(moonfire) } and { buffremaining(ca_inc) > buffremaining(moonfire) or not buffpresent(ca_inc) } and spell(moonfire) or target.refreshable(stellar_flare_debuff) and astralpower() >= astralpowercost(stellar_flare) and target.timetodie() / { 2 * { 100 / { 100 + spellcastspeedpercent() } } } >= 5 and { not az_ss() or not buffpresent(ca_inc) or not previousspell(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or buffstacks(solar_empowerment_buff) < 3 and { astralpower() >= astralpowercost(lunar_strike) or buffstacks(lunar_empowerment_buff) == 3 } and { { buffpresent(warrior_of_elune_buff) or buffpresent(lunar_empowerment_buff) or enemies() >= 2 and not buffpresent(solar_empowerment_buff) } and { not az_ss() or not buffpresent(ca_inc) } or az_ss() and buffpresent(ca_inc) and previousspell(solar_wrath_balance) } and spell(lunar_strike) or { az_ss() < 3 or not buffpresent(ca_inc) or not previousspell(solar_wrath_balance) } and spell(solar_wrath_balance) or spell(sunfire)
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe l(aoe) default specialization=balance)

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=shortcd specialization=balance
{
 if not incombat() balanceprecombatshortcdactions()
 balance_defaultshortcdactions()
}

AddIcon checkbox=opt_druid_balance_aoe help=shortcd specialization=balance
{
 if not incombat() balanceprecombatshortcdactions()
 balance_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=balance
{
 if not incombat() balanceprecombatmainactions()
 balance_defaultmainactions()
}

AddIcon checkbox=opt_druid_balance_aoe help=aoe specialization=balance
{
 if not incombat() balanceprecombatmainactions()
 balance_defaultmainactions()
}

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=cd specialization=balance
{
 if not incombat() balanceprecombatcdactions()
 balance_defaultcdactions()
}

AddIcon checkbox=opt_druid_balance_aoe help=cd specialization=balance
{
 if not incombat() balanceprecombatcdactions()
 balance_defaultcdactions()
}

### Required symbols
# arcanic_pulsar_buff
# arcanic_pulsar_trait
# berserking
# blood_of_the_enemy
# bloodlust
# ca_inc
# celestial_alignment
# celestial_alignment_buff
# concentrated_flame
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# focused_azerite_beam
# force_of_nature
# full_moon
# fury_of_elune
# guardian_of_azeroth
# half_moon
# incarnation_chosen_of_elune
# incarnation_chosen_of_elune_buff
# innervate
# lively_spirit_buff
# lively_spirit_trait
# lunar_empowerment_buff
# lunar_strike
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# mighty_bash
# moonfire
# moonkin_form_balance
# new_moon
# purifying_blast
# reaping_flames
# reckless_force_buff
# reckless_force_counter_buff
# ripple_in_space_essence
# shiver_venom
# solar_beam
# solar_empowerment_buff
# solar_wrath
# solar_wrath_balance
# starfall
# starlord
# starlord_buff
# starlord_talent
# starsurge_balance
# stellar_flare
# stellar_flare_debuff
# stellar_flare_talent
# streaking_stars_trait
# sunfire
# sunfire_debuff
# the_unbound_force
# thorns
# twin_moons_talent
# typhoon
# unbridled_fury_item
# war_stomp
# warrior_of_elune
# warrior_of_elune_buff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
    end
    do
        local name = "sc_t24_druid_feral"
        local desc = "[8.3] Simulationcraft: T24_Druid_Feral"
        local code = [[
# Based on SimulationCraft profile "T24_Druid_Feral".
#	class=druid
#	spec=feral
#	talents=2000122

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction opener_done
{
 target.debuffpresent(rip_debuff)
}

AddFunction use_thrash
{
 if hasazeritetrait(wild_fleshrending_trait) 2
 0
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=feral)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=feral)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=feral)

AddFunction feralinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(skull_bash) and target.isinterruptible() spell(skull_bash)
  if target.inrange(mighty_bash) and not target.classification(worldboss) spell(mighty_bash)
  if target.inrange(maim) and not target.classification(worldboss) spell(maim)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.distance(less 15) and not target.classification(worldboss) spell(typhoon)
 }
}

AddFunction feraluseheartessence
{
 spell(concentrated_flame_essence)
}

AddFunction feraluseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction feralgetinmeleerange
{
 if checkboxon(opt_melee_range) and stance(druid_bear_form) and not target.inrange(mangle) or { stance(druid_cat_form) or stance(druid_claws_of_shirvallah) } and not target.inrange(shred)
 {
  if target.inrange(wild_charge) spell(wild_charge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.precombat

AddFunction feralprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #variable,name=use_thrash,value=0
 #variable,name=use_thrash,value=2,if=azerite.wild_fleshrending.enabled
 #regrowth,if=talent.bloodtalons.enabled
 if hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #cat_form
 spell(cat_form)
 #prowl
 spell(prowl)
}

AddFunction feralprecombatmainpostconditions
{
}

AddFunction feralprecombatshortcdactions
{
}

AddFunction feralprecombatshortcdpostconditions
{
 hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or spell(cat_form) or spell(prowl)
}

AddFunction feralprecombatcdactions
{
 unless hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
 {
  #use_item,name=azsharas_font_of_power
  feraluseitemactions()

  unless spell(cat_form) or spell(prowl)
  {
   #potion,dynamic_prepot=1
   if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
   #berserk
   spell(berserk)
  }
 }
}

AddFunction feralprecombatcdpostconditions
{
 hastalent(bloodtalons_talent) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or spell(cat_form) or spell(prowl)
}

### actions.opener

AddFunction feralopenermainactions
{
 #rake,if=!ticking|buff.prowl.up
 if not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) spell(rake)
 #variable,name=opener_done,value=dot.rip.ticking
 #wait,sec=0.001,if=dot.rip.ticking
 #moonfire_cat,if=!ticking
 if not target.debuffpresent(moonfire_cat_debuff) spell(moonfire_cat)
 #rip,if=!ticking
 if not target.debuffpresent(rip_debuff) spell(rip)
}

AddFunction feralopenermainpostconditions
{
}

AddFunction feralopenershortcdactions
{
 #tigers_fury
 spell(tigers_fury)
}

AddFunction feralopenershortcdpostconditions
{
 { not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) } and spell(rake) or not target.debuffpresent(moonfire_cat_debuff) and spell(moonfire_cat) or not target.debuffpresent(rip_debuff) and spell(rip)
}

AddFunction feralopenercdactions
{
}

AddFunction feralopenercdpostconditions
{
 spell(tigers_fury) or { not target.debuffpresent(rake_debuff) or buffpresent(prowl_buff) } and spell(rake) or not target.debuffpresent(moonfire_cat_debuff) and spell(moonfire_cat) or not target.debuffpresent(rip_debuff) and spell(rip)
}

### actions.generators

AddFunction feralgeneratorsmainactions
{
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #regrowth,if=talent.bloodtalons.enabled&buff.bloodtalons.down&buff.predatory_swiftness.up&talent.lunar_inspiration.enabled&dot.rake.remains<1
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if enemies() > enemies(tagged=1) spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=(refreshable)&(spell_targets.thrash_cat>2)
 if target.refreshable(thrash_cat_debuff) and enemies() > 2 spell(thrash_cat)
 unless target.refreshable(thrash_cat_debuff) and enemies() > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
 {
  #pool_resource,for_next=1
  #thrash_cat,if=(talent.scent_of_blood.enabled&buff.scent_of_blood.down)&spell_targets.thrash_cat>3
  if hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 spell(thrash_cat)
  unless hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
  {
   #pool_resource,for_next=1
   #swipe_cat,if=buff.scent_of_blood.up|(action.swipe_cat.damage*spell_targets.swipe_cat>(action.rake.damage+(action.rake_bleed.tick_damage*5)))
   if buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 spell(swipe_cat)
   unless { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat)
   {
    #pool_resource,for_next=1
    #rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
    if not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 spell(rake)
    unless { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake)
    {
     #pool_resource,for_next=1
     #rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
     if hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 spell(rake)
     unless hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake)
     {
      #moonfire_cat,if=buff.bloodtalons.up&buff.predatory_swiftness.down&combo_points<5
      if buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 spell(moonfire_cat)
      #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
      if buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) spell(brutal_slash)
      #moonfire_cat,target_if=refreshable
      if target.refreshable(moonfire_cat_debuff) spell(moonfire_cat)
      #pool_resource,for_next=1
      #thrash_cat,if=refreshable&((variable.use_thrash=2&(!buff.incarnation.up|azerite.wild_fleshrending.enabled))|spell_targets.thrash_cat>1)
      if target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } spell(thrash_cat)
      unless target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat)
      {
       #thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react&(!buff.incarnation.up|azerite.wild_fleshrending.enabled)
       if target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } spell(thrash_cat)
       #pool_resource,for_next=1
       #swipe_cat,if=spell_targets.swipe_cat>1
       if enemies() > 1 spell(swipe_cat)
       unless enemies() > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat)
       {
        #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
        if target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) spell(shred)
       }
      }
     }
    }
   }
  }
 }
}

AddFunction feralgeneratorsmainpostconditions
{
}

AddFunction feralgeneratorsshortcdactions
{
}

AddFunction feralgeneratorsshortcdpostconditions
{
 hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or enemies() > enemies(tagged=1) and spell(brutal_slash) or target.refreshable(thrash_cat_debuff) and enemies() > 2 and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and enemies() > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 and spell(thrash_cat) or not { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spell(swipe_cat) or not { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spell(rake) or not { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spell(rake) or not { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 and spell(moonfire_cat) or buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and spell(brutal_slash) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } and spell(thrash_cat) or enemies() > 1 and spell(swipe_cat) or not { enemies() > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) } and spell(shred) } } } } } }
}

AddFunction feralgeneratorscdactions
{
}

AddFunction feralgeneratorscdpostconditions
{
 hastalent(bloodtalons_talent) and buffpresent(predatory_swiftness_buff) and buffexpires(bloodtalons_buff) and combopoints() == 4 and target.debuffremaining(rake_debuff) < 4 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and buffpresent(predatory_swiftness_buff) and hastalent(lunar_inspiration_talent) and target.debuffremaining(rake_debuff) < 1 and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or enemies() > enemies(tagged=1) and spell(brutal_slash) or target.refreshable(thrash_cat_debuff) and enemies() > 2 and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and enemies() > 2 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 and spell(thrash_cat) or not { hastalent(scent_of_blood_talent) and buffexpires(scent_of_blood_feral) and enemies() > 3 and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spell(swipe_cat) or not { { buffpresent(scent_of_blood_feral) or damage(swipe_cat) * enemies() > damage(rake) + target.lastdamage(rake_debuff) * 5 } and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spell(rake) or not { { not target.debuffpresent(rake_debuff) or not hastalent(bloodtalons_talent) and target.debuffremaining(rake_debuff) < baseduration(rake_debuff) * 0.3 and target.timetodie() > 4 } and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spell(rake) or not { hastalent(bloodtalons_talent) and buffpresent(bloodtalons_buff) and target.debuffremaining(rake_debuff) <= 7 and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) * 0.85 and target.timetodie() > 4 and spellusable(rake) and spellcooldown(rake) < timetoenergyfor(rake) } and { buffpresent(bloodtalons_buff) and buffexpires(predatory_swiftness_buff) and combopoints() < 5 and spell(moonfire_cat) or buffpresent(tigers_fury_buff) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and spell(brutal_slash) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } and spell(thrash_cat) or not { target.refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } or enemies() > 1 } and spellusable(thrash_cat) and spellcooldown(thrash_cat) < timetoenergyfor(thrash_cat) } and { target.refreshable(thrash_cat_debuff) and use_thrash() == 1 and buffpresent(clearcasting_buff) and { not buffpresent(incarnation_king_of_the_jungle_buff) or hasazeritetrait(wild_fleshrending_trait) } and spell(thrash_cat) or enemies() > 1 and spell(swipe_cat) or not { enemies() > 1 and spellusable(swipe_cat) and spellcooldown(swipe_cat) < timetoenergyfor(swipe_cat) } and { target.debuffremaining(rake_debuff) > { powercost(shred) + powercost(rake) - energy() } / energyregenrate() or buffpresent(clearcasting_buff) } and spell(shred) } } } } } }
}

### actions.finishers

AddFunction feralfinishersmainactions
{
 #pool_resource,for_next=1
 #savage_roar,if=buff.savage_roar.down
 if buffexpires(savage_roar_buff) spell(savage_roar)
 unless buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar)
 {
  #pool_resource,for_next=1
  #primal_wrath,target_if=spell_targets.primal_wrath>1&dot.rip.remains<4
  if enemies() > 1 and target.debuffremaining(rip_debuff) < 4 spell(primal_wrath)
  unless enemies() > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath)
  {
   #pool_resource,for_next=1
   #primal_wrath,target_if=spell_targets.primal_wrath>=2
   if enemies() >= 2 spell(primal_wrath)
   unless enemies() >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath)
   {
    #pool_resource,for_next=1
    #rip,target_if=!ticking|(remains<=duration*0.3)&(!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
    if not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 spell(rip)
    unless { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip)
    {
     #pool_resource,for_next=1
     #savage_roar,if=buff.savage_roar.remains<12
     if buffremaining(savage_roar_buff) < 12 spell(savage_roar)
     unless buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar)
     {
      #pool_resource,for_next=1
      #maim,if=buff.iron_jaws.up
      if buffpresent(iron_jaws) spell(maim)
      unless buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim)
      {
       #ferocious_bite,max_energy=1,target_if=max:druid.rip.ticks_gained_on_refresh
       if energy() >= energycost(ferocious_bite max=1) spell(ferocious_bite)
      }
     }
    }
   }
  }
 }
}

AddFunction feralfinishersmainpostconditions
{
}

AddFunction feralfinishersshortcdactions
{
}

AddFunction feralfinishersshortcdpostconditions
{
 buffexpires(savage_roar_buff) and spell(savage_roar) or not { buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { enemies() > 1 and target.debuffremaining(rip_debuff) < 4 and spell(primal_wrath) or not { enemies() > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { enemies() >= 2 and spell(primal_wrath) or not { enemies() >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spell(rip) or not { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip) } and { buffremaining(savage_roar_buff) < 12 and spell(savage_roar) or not { buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { buffpresent(iron_jaws) and spell(maim) or not { buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim) } and energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite) } } } } }
}

AddFunction feralfinisherscdactions
{
}

AddFunction feralfinisherscdpostconditions
{
 buffexpires(savage_roar_buff) and spell(savage_roar) or not { buffexpires(savage_roar_buff) and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { enemies() > 1 and target.debuffremaining(rip_debuff) < 4 and spell(primal_wrath) or not { enemies() > 1 and target.debuffremaining(rip_debuff) < 4 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { enemies() >= 2 and spell(primal_wrath) or not { enemies() >= 2 and spellusable(primal_wrath) and spellcooldown(primal_wrath) < timetoenergyfor(primal_wrath) } and { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spell(rip) or not { { not target.debuffpresent(rip_debuff) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.3 and not hastalent(sabertooth_talent) or target.debuffremaining(rip_debuff) <= baseduration(rip_debuff) * 0.8 and persistentmultiplier(rip_debuff) > target.debuffpersistentmultiplier(rip_debuff) and target.timetodie() > 8 } and spellusable(rip) and spellcooldown(rip) < timetoenergyfor(rip) } and { buffremaining(savage_roar_buff) < 12 and spell(savage_roar) or not { buffremaining(savage_roar_buff) < 12 and spellusable(savage_roar) and spellcooldown(savage_roar) < timetoenergyfor(savage_roar) } and { buffpresent(iron_jaws) and spell(maim) or not { buffpresent(iron_jaws) and spellusable(maim) and spellcooldown(maim) < timetoenergyfor(maim) } and energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite) } } } } }
}

### actions.cooldowns

AddFunction feralcooldownsmainactions
{
}

AddFunction feralcooldownsmainpostconditions
{
}

AddFunction feralcooldownsshortcdactions
{
 #tigers_fury,if=energy.deficit>=60
 if energydeficit() >= 60 spell(tigers_fury)
 #thorns,if=active_enemies>desired_targets|raid_event.adds.in>45
 if enemies() > enemies(tagged=1) or 600 > 45 spell(thorns)
 #the_unbound_force,if=buff.reckless_force.up|buff.tigers_fury.up
 if buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) spell(the_unbound_force)
 #feral_frenzy,if=combo_points=0
 if combopoints() == 0 spell(feral_frenzy)
 #purifying_blast,if=active_enemies>desired_targets|raid_event.adds.in>60
 if enemies() > enemies(tagged=1) or 600 > 60 spell(purifying_blast)
}

AddFunction feralcooldownsshortcdpostconditions
{
}

AddFunction feralcooldownscdactions
{
 #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
 if energy() >= 30 and { spellcooldown(tigers_fury) > 5 or buffpresent(tigers_fury_buff) } spell(berserk)

 unless energydeficit() >= 60 and spell(tigers_fury)
 {
  #berserking
  spell(berserking)

  unless { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) } and spell(the_unbound_force)
  {
   #memory_of_lucid_dreams,if=buff.tigers_fury.up&buff.berserk.down
   if buffpresent(tigers_fury_buff) and buffexpires(berserk_buff) spell(memory_of_lucid_dreams_essence)
   #blood_of_the_enemy,if=buff.tigers_fury.up
   if buffpresent(tigers_fury_buff) spell(blood_of_the_enemy)

   unless combopoints() == 0 and spell(feral_frenzy)
   {
    #focused_azerite_beam,if=active_enemies>desired_targets|(raid_event.adds.in>90&energy.deficit>=50)
    if enemies() > enemies(tagged=1) or 600 > 90 and energydeficit() >= 50 spell(focused_azerite_beam)

    unless { enemies() > enemies(tagged=1) or 600 > 60 } and spell(purifying_blast)
    {
     #heart_essence,if=buff.tigers_fury.up
     if buffpresent(tigers_fury_buff) feraluseheartessence()
     #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
     if energy() >= 30 and { spellcooldown(tigers_fury) > 15 or buffpresent(tigers_fury_buff) } spell(incarnation_king_of_the_jungle)
     #potion,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
     if { target.timetodie() < 65 or target.timetodie() < 180 and { buffpresent(berserk_buff) or buffpresent(incarnation_king_of_the_jungle_buff) } } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
     #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
     if combopoints() < 5 and energy() >= powercost(rake) and target.debuffpersistentmultiplier(rake_debuff) < 2.1 and buffpresent(tigers_fury_buff) and { buffpresent(bloodtalons_buff) or not hastalent(bloodtalons_talent) } and { not hastalent(incarnation_talent) or spellcooldown(incarnation_king_of_the_jungle) > 18 } and not buffpresent(incarnation_king_of_the_jungle_buff) spell(shadowmeld)
     #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.time_to_pct_30<1.5|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.tigers_fury.remains>10
     if target.debuffexpires(razor_coral) or target.debuffpresent(conductive_ink) and target.timetohealthpercent(30) < 1.5 or not target.debuffpresent(conductive_ink) and { target.debuffstacks(razor_coral) >= 25 - 10 * target.debuffpresent(blood_of_the_enemy) or target.timetodie() < 40 } and buffremaining(tigers_fury_buff) > 10 feraluseitemactions()
     #use_item,effect_name=cyclotronic_blast,if=(energy.deficit>=energy.regen*3)&buff.tigers_fury.down&!azerite.jungle_fury.enabled
     if energydeficit() >= energyregenrate() * 3 and buffexpires(tigers_fury_buff) and not hasazeritetrait(jungle_fury_trait) feraluseitemactions()
     #use_item,effect_name=cyclotronic_blast,if=buff.tigers_fury.up&azerite.jungle_fury.enabled
     if buffpresent(tigers_fury_buff) and hasazeritetrait(jungle_fury_trait) feraluseitemactions()
     #use_item,effect_name=azsharas_font_of_power,if=energy.deficit>=50
     if energydeficit() >= 50 feraluseitemactions()
     #use_items,if=buff.tigers_fury.up|target.time_to_die<20
     if buffpresent(tigers_fury_buff) or target.timetodie() < 20 feraluseitemactions()
    }
   }
  }
 }
}

AddFunction feralcooldownscdpostconditions
{
 energydeficit() >= 60 and spell(tigers_fury) or { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury_buff) } and spell(the_unbound_force) or combopoints() == 0 and spell(feral_frenzy) or { enemies() > enemies(tagged=1) or 600 > 60 } and spell(purifying_blast)
}

### actions.default

AddFunction feral_defaultmainactions
{
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenermainactions()

 unless opener_done() == 0 and feralopenermainpostconditions()
 {
  #cat_form,if=!buff.cat_form.up
  if not buffpresent(cat_form_buff) spell(cat_form)
  #rake,if=buff.prowl.up|buff.shadowmeld.up
  if buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) spell(rake)
  #call_action_list,name=cooldowns
  feralcooldownsmainactions()

  unless feralcooldownsmainpostconditions()
  {
   #ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(talent.sabertooth.enabled)
   if target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) spell(ferocious_bite)
   #regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down
   if combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } spell(regrowth)
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinishersmainactions()

   unless combopoints() > 4 and feralfinishersmainpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorsmainactions()
   }
  }
 }
}

AddFunction feral_defaultmainpostconditions
{
 opener_done() == 0 and feralopenermainpostconditions() or feralcooldownsmainpostconditions() or combopoints() > 4 and feralfinishersmainpostconditions() or feralgeneratorsmainpostconditions()
}

AddFunction feral_defaultshortcdactions
{
 #auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
 if not buffpresent(prowl_buff) and not buffpresent(shadowmeld_buff) feralgetinmeleerange()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenershortcdactions()

 unless opener_done() == 0 and feralopenershortcdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake)
 {
  #call_action_list,name=cooldowns
  feralcooldownsshortcdactions()

  unless feralcooldownsshortcdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinishersshortcdactions()

   unless combopoints() > 4 and feralfinishersshortcdpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorsshortcdactions()
   }
  }
 }
}

AddFunction feral_defaultshortcdpostconditions
{
 opener_done() == 0 and feralopenershortcdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake) or feralcooldownsshortcdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or combopoints() > 4 and feralfinishersshortcdpostconditions() or feralgeneratorsshortcdpostconditions()
}

AddFunction feral_defaultcdactions
{
 feralinterruptactions()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 feralopenercdactions()

 unless opener_done() == 0 and feralopenercdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake)
 {
  #call_action_list,name=cooldowns
  feralcooldownscdactions()

  unless feralcooldownscdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if combopoints() > 4 feralfinisherscdactions()

   unless combopoints() > 4 and feralfinisherscdpostconditions()
   {
    #run_action_list,name=generators
    feralgeneratorscdactions()
   }
  }
 }
}

AddFunction feral_defaultcdpostconditions
{
 opener_done() == 0 and feralopenercdpostconditions() or not buffpresent(cat_form_buff) and spell(cat_form) or { buffpresent(prowl_buff) or buffpresent(shadowmeld_buff) } and spell(rake) or feralcooldownscdpostconditions() or target.debuffpresent(rip_debuff) and target.debuffremaining(rip_debuff) < 3 and target.timetodie() > 10 and hastalent(sabertooth_talent) and spell(ferocious_bite) or combopoints() == 5 and buffpresent(predatory_swiftness_buff) and hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and talent(bloodtalons_talent) and { buffremaining(bloodtalons_buff) < casttime(regrowth) + gcdremaining() or incombat() } and spell(regrowth) or combopoints() > 4 and feralfinisherscdpostconditions() or feralgeneratorscdpostconditions()
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe l(aoe) default specialization=feral)

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
{
 if not incombat() feralprecombatshortcdactions()
 feral_defaultshortcdactions()
}

AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
{
 if not incombat() feralprecombatshortcdactions()
 feral_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=feral
{
 if not incombat() feralprecombatmainactions()
 feral_defaultmainactions()
}

AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
{
 if not incombat() feralprecombatmainactions()
 feral_defaultmainactions()
}

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
{
 if not incombat() feralprecombatcdactions()
 feral_defaultcdactions()
}

AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
{
 if not incombat() feralprecombatcdactions()
 feral_defaultcdactions()
}

### Required symbols
# berserk
# berserk_buff
# berserking
# blood_of_the_enemy
# bloodtalons_buff
# bloodtalons_talent
# brutal_slash
# cat_form
# cat_form_buff
# clearcasting_buff
# concentrated_flame_essence
# conductive_ink
# feral_frenzy
# ferocious_bite
# focused_azerite_beam
# focused_resolve_item
# incarnation_king_of_the_jungle
# incarnation_king_of_the_jungle_buff
# incarnation_talent
# iron_jaws
# jungle_fury_trait
# lunar_inspiration_talent
# maim
# mangle
# memory_of_lucid_dreams_essence
# mighty_bash
# moonfire_cat
# moonfire_cat_debuff
# predatory_swiftness_buff
# primal_wrath
# prowl
# prowl_buff
# purifying_blast
# rake
# rake_debuff
# razor_coral
# reckless_force_buff
# regrowth
# rip
# rip_debuff
# sabertooth_talent
# savage_roar
# savage_roar_buff
# scent_of_blood_feral
# scent_of_blood_talent
# shadowmeld
# shadowmeld_buff
# shred
# skull_bash
# swipe_cat
# the_unbound_force
# thorns
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# tigers_fury_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
# wild_fleshrending_trait
]]
        OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
    end
    do
        local name = "sc_t24_druid_guardian"
        local desc = "[8.3] Simulationcraft: T24_Druid_Guardian"
        local code = [[
# Based on SimulationCraft profile "T24_Druid_Guardian".
#	class=druid
#	spec=guardian
#	talents=1000131

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=guardian)

AddFunction guardianinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(skull_bash) and target.isinterruptible() spell(skull_bash)
  if target.inrange(mighty_bash) and not target.classification(worldboss) spell(mighty_bash)
  if target.distance(less 10) and not target.classification(worldboss) spell(incapacitating_roar)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.distance(less 15) and not target.classification(worldboss) spell(typhoon)
 }
}

AddFunction guardianuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction guardiangetinmeleerange
{
 if checkboxon(opt_melee_range) and stance(druid_bear_form) and not target.inrange(mangle) or { stance(druid_cat_form) or stance(druid_claws_of_shirvallah) } and not target.inrange(shred)
 {
  if target.inrange(wild_charge) spell(wild_charge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.precombat

AddFunction guardianprecombatmainactions
{
 #bear_form
 spell(bear_form)
}

AddFunction guardianprecombatmainpostconditions
{
}

AddFunction guardianprecombatshortcdactions
{
}

AddFunction guardianprecombatshortcdpostconditions
{
 spell(bear_form)
}

AddFunction guardianprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #memory_of_lucid_dreams
 spell(memory_of_lucid_dreams_essence)

 unless spell(bear_form)
 {
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 }
}

AddFunction guardianprecombatcdpostconditions
{
 spell(bear_form)
}

### actions.multi

AddFunction guardianmultimainactions
{
 #maul,if=essence.conflict_and_strife.major&!buff.sharpened_claws.up
 if azeriteessenceismajor(conflict_and_strife_essence_id) and not buffpresent(sharpened_claws_buff) spell(maul)
 #ironfur,if=(rage>=cost&azerite.layered_mane.enabled)|rage.deficit<10
 if rage() >= powercost(ironfur) and hasazeritetrait(layered_mane_trait) or ragedeficit() < 10 spell(ironfur)
 #thrash,if=(buff.incarnation.up&active_enemies>=4)|cooldown.thrash_bear.up
 if buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() >= 4 or not spellcooldown(thrash_bear) > 0 spell(thrash)
 #mangle,if=buff.incarnation.up&active_enemies=3&dot.thrash_bear.ticking
 if buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() == 3 and target.debuffpresent(thrash_bear_debuff) spell(mangle)
 #moonfire,if=dot.moonfire.refreshable&active_enemies<=4
 if target.debuffrefreshable(moonfire) and enemies() <= 4 spell(moonfire)
 #swipe,if=buff.incarnation.down
 if buffexpires(incarnation_guardian_of_ursoc_buff) spell(swipe_bear)
}

AddFunction guardianmultimainpostconditions
{
}

AddFunction guardianmultishortcdactions
{
}

AddFunction guardianmultishortcdpostconditions
{
 azeriteessenceismajor(conflict_and_strife_essence_id) and not buffpresent(sharpened_claws_buff) and spell(maul) or { rage() >= powercost(ironfur) and hasazeritetrait(layered_mane_trait) or ragedeficit() < 10 } and spell(ironfur) or { buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() >= 4 or not spellcooldown(thrash_bear) > 0 } and spell(thrash) or buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() == 3 and target.debuffpresent(thrash_bear_debuff) and spell(mangle) or target.debuffrefreshable(moonfire) and enemies() <= 4 and spell(moonfire) or buffexpires(incarnation_guardian_of_ursoc_buff) and spell(swipe_bear)
}

AddFunction guardianmulticdactions
{
}

AddFunction guardianmulticdpostconditions
{
 azeriteessenceismajor(conflict_and_strife_essence_id) and not buffpresent(sharpened_claws_buff) and spell(maul) or { rage() >= powercost(ironfur) and hasazeritetrait(layered_mane_trait) or ragedeficit() < 10 } and spell(ironfur) or { buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() >= 4 or not spellcooldown(thrash_bear) > 0 } and spell(thrash) or buffpresent(incarnation_guardian_of_ursoc_buff) and enemies() == 3 and target.debuffpresent(thrash_bear_debuff) and spell(mangle) or target.debuffrefreshable(moonfire) and enemies() <= 4 and spell(moonfire) or buffexpires(incarnation_guardian_of_ursoc_buff) and spell(swipe_bear)
}

### actions.essences

AddFunction guardianessencesmainactions
{
 #concentrated_flame,if=essence.the_crucible_of_flame.major&((!dot.concentrated_flame_burn.ticking&!action.concentrated_flame_missile.in_flight)^time_to_die<=7)
 if azeriteessenceismajor(the_crucible_of_flame_essence_id) and { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) xor target.timetodie() <= 7 } spell(concentrated_flame_essence)
}

AddFunction guardianessencesmainpostconditions
{
}

AddFunction guardianessencesshortcdactions
{
 unless azeriteessenceismajor(the_crucible_of_flame_essence_id) and { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) xor target.timetodie() <= 7 } and spell(concentrated_flame_essence)
 {
  #worldvein_resonance,if=essence.worldvein_resonance.major
  if azeriteessenceismajor(worldvein_resonance_essence_id) spell(worldvein_resonance_essence)
  #ripple_in_space,if=essence.ripple_in_space.major
  if azeriteessenceismajor(ripple_in_space_essence_id) spell(ripple_in_space_essence)
 }
}

AddFunction guardianessencesshortcdpostconditions
{
 azeriteessenceismajor(the_crucible_of_flame_essence_id) and { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) xor target.timetodie() <= 7 } and spell(concentrated_flame_essence)
}

AddFunction guardianessencescdactions
{
 unless azeriteessenceismajor(the_crucible_of_flame_essence_id) and { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) xor target.timetodie() <= 7 } and spell(concentrated_flame_essence)
 {
  #anima_of_death,if=essence.anima_of_life_and_death.major
  if azeriteessenceismajor(anima_of_life_and_death_essence_id) spell(anima_of_death)
  #memory_of_lucid_dreams,if=essence.memory_of_lucid_dreams.major
  if azeriteessenceismajor(memory_of_lucid_dreams_essence_id) spell(memory_of_lucid_dreams_essence)
 }
}

AddFunction guardianessencescdpostconditions
{
 azeriteessenceismajor(the_crucible_of_flame_essence_id) and { not target.debuffpresent(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame) xor target.timetodie() <= 7 } and spell(concentrated_flame_essence) or azeriteessenceismajor(worldvein_resonance_essence_id) and spell(worldvein_resonance_essence) or azeriteessenceismajor(ripple_in_space_essence_id) and spell(ripple_in_space_essence)
}

### actions.cooldowns

AddFunction guardiancooldownsmainactions
{
}

AddFunction guardiancooldownsmainpostconditions
{
}

AddFunction guardiancooldownsshortcdactions
{
 #bag_of_tricks
 spell(bag_of_tricks)
 #barkskin,if=buff.bear_form.up
 if buffpresent(bear_form) spell(barkskin)
 #lunar_beam,if=buff.bear_form.up
 if buffpresent(bear_form) spell(lunar_beam)
 #bristling_fur,if=buff.bear_form.up
 if buffpresent(bear_form) spell(bristling_fur)
}

AddFunction guardiancooldownsshortcdpostconditions
{
}

AddFunction guardiancooldownscdactions
{
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(focused_resolve_item usable=1)
 #blood_fury
 spell(blood_fury)
 #berserking
 spell(berserking)
 #arcane_torrent
 spell(arcane_torrent_energy)
 #lights_judgment
 spell(lights_judgment)
 #fireblood
 spell(fireblood)
 #ancestral_call
 spell(ancestral_call)

 unless spell(bag_of_tricks) or buffpresent(bear_form) and spell(barkskin) or buffpresent(bear_form) and spell(lunar_beam) or buffpresent(bear_form) and spell(bristling_fur)
 {
  #incarnation,if=(dot.moonfire.ticking|active_enemies>1)&dot.thrash_bear.ticking
  if { target.debuffpresent(moonfire) or enemies() > 1 } and target.debuffpresent(thrash_bear_debuff) spell(incarnation_guardian_of_ursoc)
  #use_item,name=ashvanes_razor_coral,if=((equipped.cyclotronic_blast&cooldown.cyclotronic_blast.remains>25&debuff.razor_coral_debuff.down)|debuff.razor_coral_debuff.down|(debuff.razor_coral_debuff.up&debuff.conductive_ink_debuff.up&target.time_to_pct_30<=2)|(debuff.razor_coral_debuff.up&time_to_die<=20))
  if hasequippeditem(cyclotronic_blast_item) and spellcooldown(cyclotronic_blast) > 25 and target.debuffexpires(razor_coral) or target.debuffexpires(razor_coral) or target.debuffpresent(razor_coral) and target.debuffpresent(conductive_ink) and target.timetohealthpercent(30) <= 2 or target.debuffpresent(razor_coral) and target.timetodie() <= 20 guardianuseitemactions()
  #use_item,effect_name=cyclotronic_blast
  guardianuseitemactions()
  #use_items
  guardianuseitemactions()
 }
}

AddFunction guardiancooldownscdpostconditions
{
 spell(bag_of_tricks) or buffpresent(bear_form) and spell(barkskin) or buffpresent(bear_form) and spell(lunar_beam) or buffpresent(bear_form) and spell(bristling_fur)
}

### actions.cleave

AddFunction guardiancleavemainactions
{
 #maul,if=rage.deficit<=10
 if ragedeficit() <= 10 spell(maul)
 #ironfur,if=cost<=0
 if powercost(ironfur) <= 0 spell(ironfur)
 #pulverize,target_if=dot.thrash_bear.stack=dot.thrash_bear.max_stacks
 if target.debuffstacks(thrash_bear_debuff) == maxstacks(thrash_bear_debuff) and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) spell(pulverize)
 #moonfire,target_if=!dot.moonfire.ticking
 if not target.debuffpresent(moonfire) spell(moonfire)
 #mangle,if=dot.thrash_bear.ticking
 if target.debuffpresent(thrash_bear_debuff) spell(mangle)
 #moonfire,target_if=buff.galactic_guardian.up&active_enemies=1|dot.moonfire.refreshable
 if buffpresent(galactic_guardian_buff) and enemies() == 1 or target.debuffrefreshable(moonfire) spell(moonfire)
 #maul
 spell(maul)
 #thrash
 spell(thrash)
 #swipe
 spell(swipe_bear)
}

AddFunction guardiancleavemainpostconditions
{
}

AddFunction guardiancleaveshortcdactions
{
}

AddFunction guardiancleaveshortcdpostconditions
{
 ragedeficit() <= 10 and spell(maul) or powercost(ironfur) <= 0 and spell(ironfur) or target.debuffstacks(thrash_bear_debuff) == maxstacks(thrash_bear_debuff) and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) and spell(pulverize) or not target.debuffpresent(moonfire) and spell(moonfire) or target.debuffpresent(thrash_bear_debuff) and spell(mangle) or { buffpresent(galactic_guardian_buff) and enemies() == 1 or target.debuffrefreshable(moonfire) } and spell(moonfire) or spell(maul) or spell(thrash) or spell(swipe_bear)
}

AddFunction guardiancleavecdactions
{
}

AddFunction guardiancleavecdpostconditions
{
 ragedeficit() <= 10 and spell(maul) or powercost(ironfur) <= 0 and spell(ironfur) or target.debuffstacks(thrash_bear_debuff) == maxstacks(thrash_bear_debuff) and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) and spell(pulverize) or not target.debuffpresent(moonfire) and spell(moonfire) or target.debuffpresent(thrash_bear_debuff) and spell(mangle) or { buffpresent(galactic_guardian_buff) and enemies() == 1 or target.debuffrefreshable(moonfire) } and spell(moonfire) or spell(maul) or spell(thrash) or spell(swipe_bear)
}

### actions.default

AddFunction guardian_defaultmainactions
{
 #call_action_list,name=cooldowns
 guardiancooldownsmainactions()

 unless guardiancooldownsmainpostconditions()
 {
  #call_action_list,name=essences
  guardianessencesmainactions()

  unless guardianessencesmainpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies<=2
   if enemies() <= 2 guardiancleavemainactions()

   unless enemies() <= 2 and guardiancleavemainpostconditions()
   {
    #call_action_list,name=multi,if=active_enemies>=3
    if enemies() >= 3 guardianmultimainactions()
   }
  }
 }
}

AddFunction guardian_defaultmainpostconditions
{
 guardiancooldownsmainpostconditions() or guardianessencesmainpostconditions() or enemies() <= 2 and guardiancleavemainpostconditions() or enemies() >= 3 and guardianmultimainpostconditions()
}

AddFunction guardian_defaultshortcdactions
{
 #auto_attack
 guardiangetinmeleerange()
 #call_action_list,name=cooldowns
 guardiancooldownsshortcdactions()

 unless guardiancooldownsshortcdpostconditions()
 {
  #call_action_list,name=essences
  guardianessencesshortcdactions()

  unless guardianessencesshortcdpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies<=2
   if enemies() <= 2 guardiancleaveshortcdactions()

   unless enemies() <= 2 and guardiancleaveshortcdpostconditions()
   {
    #call_action_list,name=multi,if=active_enemies>=3
    if enemies() >= 3 guardianmultishortcdactions()
   }
  }
 }
}

AddFunction guardian_defaultshortcdpostconditions
{
 guardiancooldownsshortcdpostconditions() or guardianessencesshortcdpostconditions() or enemies() <= 2 and guardiancleaveshortcdpostconditions() or enemies() >= 3 and guardianmultishortcdpostconditions()
}

AddFunction guardian_defaultcdactions
{
 guardianinterruptactions()
 #call_action_list,name=cooldowns
 guardiancooldownscdactions()

 unless guardiancooldownscdpostconditions()
 {
  #call_action_list,name=essences
  guardianessencescdactions()

  unless guardianessencescdpostconditions()
  {
   #call_action_list,name=cleave,if=active_enemies<=2
   if enemies() <= 2 guardiancleavecdactions()

   unless enemies() <= 2 and guardiancleavecdpostconditions()
   {
    #call_action_list,name=multi,if=active_enemies>=3
    if enemies() >= 3 guardianmulticdactions()
   }
  }
 }
}

AddFunction guardian_defaultcdpostconditions
{
 guardiancooldownscdpostconditions() or guardianessencescdpostconditions() or enemies() <= 2 and guardiancleavecdpostconditions() or enemies() >= 3 and guardianmulticdpostconditions()
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe l(aoe) default specialization=guardian)

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=shortcd specialization=guardian
{
 if not incombat() guardianprecombatshortcdactions()
 guardian_defaultshortcdactions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=shortcd specialization=guardian
{
 if not incombat() guardianprecombatshortcdactions()
 guardian_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=guardian
{
 if not incombat() guardianprecombatmainactions()
 guardian_defaultmainactions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
 if not incombat() guardianprecombatmainactions()
 guardian_defaultmainactions()
}

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=cd specialization=guardian
{
 if not incombat() guardianprecombatcdactions()
 guardian_defaultcdactions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=cd specialization=guardian
{
 if not incombat() guardianprecombatcdactions()
 guardian_defaultcdactions()
}

### Required symbols
# ancestral_call
# anima_of_death
# anima_of_life_and_death_essence_id
# arcane_torrent_energy
# bag_of_tricks
# barkskin
# bear_form
# berserking
# blood_fury
# bristling_fur
# concentrated_flame
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# conductive_ink
# conflict_and_strife_essence_id
# cyclotronic_blast
# cyclotronic_blast_item
# fireblood
# focused_resolve_item
# galactic_guardian_buff
# incapacitating_roar
# incarnation_guardian_of_ursoc
# incarnation_guardian_of_ursoc_buff
# ironfur
# layered_mane_trait
# lights_judgment
# lunar_beam
# mangle
# maul
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_id
# mighty_bash
# moonfire
# pulverize
# razor_coral
# ripple_in_space_essence
# ripple_in_space_essence_id
# sharpened_claws_buff
# shred
# skull_bash
# swipe_bear
# the_crucible_of_flame_essence_id
# thrash
# thrash_bear
# thrash_bear_debuff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
# worldvein_resonance_essence
# worldvein_resonance_essence_id
]]
        OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
    end
    do
        local name = "sc_t24_druid_restoration"
        local desc = "[8.3] Simulationcraft: T24_Druid_Restoration"
        local code = [[
# Based on SimulationCraft profile "T24_Druid_Restoration".
#	class=druid
#	spec=restoration
#	talents=0020000

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=restoration)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=restoration)

AddFunction restorationuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction restorationgetinmeleerange
{
 if checkboxon(opt_melee_range) and stance(druid_bear_form) and not target.inrange(mangle) or { stance(druid_cat_form) or stance(druid_claws_of_shirvallah) } and not target.inrange(shred)
 {
  if target.inrange(wild_charge) spell(wild_charge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.precombat

AddFunction restorationprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #cat_form
 spell(cat_form)
 #prowl
 spell(prowl)
}

AddFunction restorationprecombatmainpostconditions
{
}

AddFunction restorationprecombatshortcdactions
{
}

AddFunction restorationprecombatshortcdpostconditions
{
 spell(cat_form) or spell(prowl)
}

AddFunction restorationprecombatcdactions
{
 unless spell(cat_form) or spell(prowl)
 {
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 }
}

AddFunction restorationprecombatcdpostconditions
{
 spell(cat_form) or spell(prowl)
}

### actions.feral

AddFunction restorationferalmainactions
{
 #rake,if=buff.shadowmeld.up|buff.prowl.up
 if buffpresent(shadowmeld_buff) or buffpresent(prowl_buff) spell(rake)
 #sunfire,target_if=refreshable
 if target.refreshable(sunfire_debuff) spell(sunfire)
 #moonfire,target_if=refreshable&time_to_die>12&(spell_targets.swipe_cat<=4|energy<50)&(!buff.memory_of_lucid_dreams.up|(!ticking&spell_targets.swipe_cat<3))|(prev_gcd.1.sunfire&remains<duration*0.8&spell_targets.sunfire=1)
 if target.refreshable(moonfire) and target.timetodie() > 12 and { enemies() <= 4 or energy() < 50 } and { not buffpresent(memory_of_lucid_dreams_essence_buff) or not buffpresent(moonfire) and enemies() < 3 } or previousgcdspell(sunfire) and buffremaining(moonfire) < baseduration(moonfire) * 0.8 and enemies() == 1 spell(moonfire)
 #sunfire,if=prev_gcd.1.moonfire&remains<duration*0.8
 if previousgcdspell(moonfire) and target.debuffremaining(sunfire_debuff) < baseduration(sunfire_debuff) * 0.8 spell(sunfire)
 #cat_form,if=!buff.cat_form.up&energy>50
 if not buffpresent(cat_form_buff) and energy() > 50 spell(cat_form)
 #solar_wrath,if=!buff.cat_form.up
 if not buffpresent(cat_form_buff) spell(solar_wrath)
 #ferocious_bite,if=(combo_points>3&target.1.time_to_die<3)|(combo_points=5&energy>=50&dot.rip.remains>10)&spell_targets.swipe_cat<5
 if combopoints() > 3 and target.timetodie() < 3 or combopoints() == 5 and energy() >= 50 and target.debuffremaining(rip_debuff) > 10 and enemies() < 5 spell(ferocious_bite)
 #rip,target_if=(refreshable&(combo_points=5&time_to_die>remains+24|(remains+combo_points*4<time_to_die&remains+4+combo_points*4>time_to_die)))|combo_points=5&energy>90&remains<=10
 if target.refreshable(rip_debuff) and { combopoints() == 5 and target.timetodie() > target.debuffremaining(rip_debuff) + 24 or target.debuffremaining(rip_debuff) + combopoints() * 4 < target.timetodie() and target.debuffremaining(rip_debuff) + 4 + combopoints() * 4 > target.timetodie() } or combopoints() == 5 and energy() > 90 and target.debuffremaining(rip_debuff) <= 10 spell(rip)
 #rake,target_if=refreshable&time_to_die>10&(combo_points<5|remains<1)&spell_targets.swipe_cat<4
 if target.refreshable(rake_debuff) and target.timetodie() > 10 and { combopoints() < 5 or target.debuffremaining(rake_debuff) < 1 } and enemies() < 4 spell(rake)
 #swipe_cat,if=spell_targets.swipe_cat>=2
 if enemies() >= 2 spell(swipe_cat)
 #shred,if=combo_points<5|energy>90
 if combopoints() < 5 or energy() > 90 spell(shred)
}

AddFunction restorationferalmainpostconditions
{
}

AddFunction restorationferalshortcdactions
{
 unless { buffpresent(shadowmeld_buff) or buffpresent(prowl_buff) } and spell(rake)
 {
  #auto_attack
  restorationgetinmeleerange()
 }
}

AddFunction restorationferalshortcdpostconditions
{
 { buffpresent(shadowmeld_buff) or buffpresent(prowl_buff) } and spell(rake) or target.refreshable(sunfire_debuff) and spell(sunfire) or { target.refreshable(moonfire) and target.timetodie() > 12 and { enemies() <= 4 or energy() < 50 } and { not buffpresent(memory_of_lucid_dreams_essence_buff) or not buffpresent(moonfire) and enemies() < 3 } or previousgcdspell(sunfire) and buffremaining(moonfire) < baseduration(moonfire) * 0.8 and enemies() == 1 } and spell(moonfire) or previousgcdspell(moonfire) and target.debuffremaining(sunfire_debuff) < baseduration(sunfire_debuff) * 0.8 and spell(sunfire) or not buffpresent(cat_form_buff) and energy() > 50 and spell(cat_form) or not buffpresent(cat_form_buff) and spell(solar_wrath) or { combopoints() > 3 and target.timetodie() < 3 or combopoints() == 5 and energy() >= 50 and target.debuffremaining(rip_debuff) > 10 and enemies() < 5 } and spell(ferocious_bite) or { target.refreshable(rip_debuff) and { combopoints() == 5 and target.timetodie() > target.debuffremaining(rip_debuff) + 24 or target.debuffremaining(rip_debuff) + combopoints() * 4 < target.timetodie() and target.debuffremaining(rip_debuff) + 4 + combopoints() * 4 > target.timetodie() } or combopoints() == 5 and energy() > 90 and target.debuffremaining(rip_debuff) <= 10 } and spell(rip) or target.refreshable(rake_debuff) and target.timetodie() > 10 and { combopoints() < 5 or target.debuffremaining(rake_debuff) < 1 } and enemies() < 4 and spell(rake) or enemies() >= 2 and spell(swipe_cat) or { combopoints() < 5 or energy() > 90 } and spell(shred)
}

AddFunction restorationferalcdactions
{
}

AddFunction restorationferalcdpostconditions
{
 { buffpresent(shadowmeld_buff) or buffpresent(prowl_buff) } and spell(rake) or target.refreshable(sunfire_debuff) and spell(sunfire) or { target.refreshable(moonfire) and target.timetodie() > 12 and { enemies() <= 4 or energy() < 50 } and { not buffpresent(memory_of_lucid_dreams_essence_buff) or not buffpresent(moonfire) and enemies() < 3 } or previousgcdspell(sunfire) and buffremaining(moonfire) < baseduration(moonfire) * 0.8 and enemies() == 1 } and spell(moonfire) or previousgcdspell(moonfire) and target.debuffremaining(sunfire_debuff) < baseduration(sunfire_debuff) * 0.8 and spell(sunfire) or not buffpresent(cat_form_buff) and energy() > 50 and spell(cat_form) or not buffpresent(cat_form_buff) and spell(solar_wrath) or { combopoints() > 3 and target.timetodie() < 3 or combopoints() == 5 and energy() >= 50 and target.debuffremaining(rip_debuff) > 10 and enemies() < 5 } and spell(ferocious_bite) or { target.refreshable(rip_debuff) and { combopoints() == 5 and target.timetodie() > target.debuffremaining(rip_debuff) + 24 or target.debuffremaining(rip_debuff) + combopoints() * 4 < target.timetodie() and target.debuffremaining(rip_debuff) + 4 + combopoints() * 4 > target.timetodie() } or combopoints() == 5 and energy() > 90 and target.debuffremaining(rip_debuff) <= 10 } and spell(rip) or target.refreshable(rake_debuff) and target.timetodie() > 10 and { combopoints() < 5 or target.debuffremaining(rake_debuff) < 1 } and enemies() < 4 and spell(rake) or enemies() >= 2 and spell(swipe_cat) or { combopoints() < 5 or energy() > 90 } and spell(shred)
}

### actions.balance

AddFunction restorationbalancemainactions
{
 #sunfire,target_if=refreshable
 if target.refreshable(sunfire_debuff) spell(sunfire)
 #moonfire,target_if=refreshable&spell_targets.lunar_strike<7
 if target.refreshable(moonfire) and enemies() < 7 spell(moonfire)
 #starsurge
 spell(starsurge)
 #lunar_strike,if=buff.lunar_empowerment.up|spell_targets>1
 if buffpresent(lunar_empowerment_buff) or enemies() > 1 spell(lunar_strike)
 #solar_wrath
 spell(solar_wrath)
}

AddFunction restorationbalancemainpostconditions
{
}

AddFunction restorationbalanceshortcdactions
{
}

AddFunction restorationbalanceshortcdpostconditions
{
 target.refreshable(sunfire_debuff) and spell(sunfire) or target.refreshable(moonfire) and enemies() < 7 and spell(moonfire) or spell(starsurge) or { buffpresent(lunar_empowerment_buff) or enemies() > 1 } and spell(lunar_strike) or spell(solar_wrath)
}

AddFunction restorationbalancecdactions
{
}

AddFunction restorationbalancecdpostconditions
{
 target.refreshable(sunfire_debuff) and spell(sunfire) or target.refreshable(moonfire) and enemies() < 7 and spell(moonfire) or spell(starsurge) or { buffpresent(lunar_empowerment_buff) or enemies() > 1 } and spell(lunar_strike) or spell(solar_wrath)
}

### actions.default

AddFunction restoration_defaultmainactions
{
 #concentrated_flame,if=!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight&!buff.shadowmeld.up&!buff.prowl.up
 if not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not buffpresent(shadowmeld_buff) and not buffpresent(prowl_buff) spell(concentrated_flame_essence)
 #run_action_list,name=feral,if=talent.feral_affinity.enabled
 if hastalent(feral_affinity_talent_restoration) restorationferalmainactions()

 unless hastalent(feral_affinity_talent_restoration) and restorationferalmainpostconditions()
 {
  #run_action_list,name=balance,if=talent.balance_affinity.enabled
  if hastalent(balance_affinity_talent_restoration) restorationbalancemainactions()

  unless hastalent(balance_affinity_talent_restoration) and restorationbalancemainpostconditions()
  {
   #sunfire,target_if=refreshable
   if target.refreshable(sunfire_debuff) spell(sunfire)
   #moonfire,target_if=refreshable
   if target.refreshable(moonfire) spell(moonfire)
   #solar_wrath
   spell(solar_wrath)
  }
 }
}

AddFunction restoration_defaultmainpostconditions
{
 hastalent(feral_affinity_talent_restoration) and restorationferalmainpostconditions() or hastalent(balance_affinity_talent_restoration) and restorationbalancemainpostconditions()
}

AddFunction restoration_defaultshortcdactions
{
 #bag_of_tricks
 spell(bag_of_tricks)

 unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not buffpresent(shadowmeld_buff) and not buffpresent(prowl_buff) and spell(concentrated_flame_essence)
 {
  #run_action_list,name=feral,if=talent.feral_affinity.enabled
  if hastalent(feral_affinity_talent_restoration) restorationferalshortcdactions()

  unless hastalent(feral_affinity_talent_restoration) and restorationferalshortcdpostconditions()
  {
   #run_action_list,name=balance,if=talent.balance_affinity.enabled
   if hastalent(balance_affinity_talent_restoration) restorationbalanceshortcdactions()
  }
 }
}

AddFunction restoration_defaultshortcdpostconditions
{
 not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not buffpresent(shadowmeld_buff) and not buffpresent(prowl_buff) and spell(concentrated_flame_essence) or hastalent(feral_affinity_talent_restoration) and restorationferalshortcdpostconditions() or hastalent(balance_affinity_talent_restoration) and restorationbalanceshortcdpostconditions() or target.refreshable(sunfire_debuff) and spell(sunfire) or target.refreshable(moonfire) and spell(moonfire) or spell(solar_wrath)
}

AddFunction restoration_defaultcdactions
{
 #blood_fury
 spell(blood_fury)
 #berserking
 spell(berserking)
 #arcane_torrent
 spell(arcane_torrent_energy)
 #lights_judgment
 spell(lights_judgment)
 #fireblood
 spell(fireblood)
 #ancestral_call
 spell(ancestral_call)

 unless spell(bag_of_tricks)
 {
  #use_item,effect_name=cyclotronic_blast,if=!buff.prowl.up&!buff.shadowmeld.up
  if not buffpresent(prowl_buff) and not buffpresent(shadowmeld_buff) restorationuseitemactions()
  #use_items
  restorationuseitemactions()
  #potion
  if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #memory_of_lucid_dreams,if=buff.cat_form.up&energy<50&dot.sunfire.remains>5&dot.moonfire.remains>5
  if buffpresent(cat_form_buff) and energy() < 50 and target.debuffremaining(sunfire_debuff) > 5 and target.debuffremaining(moonfire) > 5 spell(memory_of_lucid_dreams_essence)

  unless not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not buffpresent(shadowmeld_buff) and not buffpresent(prowl_buff) and spell(concentrated_flame_essence)
  {
   #run_action_list,name=feral,if=talent.feral_affinity.enabled
   if hastalent(feral_affinity_talent_restoration) restorationferalcdactions()

   unless hastalent(feral_affinity_talent_restoration) and restorationferalcdpostconditions()
   {
    #run_action_list,name=balance,if=talent.balance_affinity.enabled
    if hastalent(balance_affinity_talent_restoration) restorationbalancecdactions()
   }
  }
 }
}

AddFunction restoration_defaultcdpostconditions
{
 spell(bag_of_tricks) or not target.debuffremaining(concentrated_flame_burn_debuff) and not inflighttotarget(concentrated_flame_essence) and not buffpresent(shadowmeld_buff) and not buffpresent(prowl_buff) and spell(concentrated_flame_essence) or hastalent(feral_affinity_talent_restoration) and restorationferalcdpostconditions() or hastalent(balance_affinity_talent_restoration) and restorationbalancecdpostconditions() or target.refreshable(sunfire_debuff) and spell(sunfire) or target.refreshable(moonfire) and spell(moonfire) or spell(solar_wrath)
}

### Restoration icons.

AddCheckBox(opt_druid_restoration_aoe l(aoe) default specialization=restoration)

AddIcon checkbox=!opt_druid_restoration_aoe enemies=1 help=shortcd specialization=restoration
{
 if not incombat() restorationprecombatshortcdactions()
 restoration_defaultshortcdactions()
}

AddIcon checkbox=opt_druid_restoration_aoe help=shortcd specialization=restoration
{
 if not incombat() restorationprecombatshortcdactions()
 restoration_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=restoration
{
 if not incombat() restorationprecombatmainactions()
 restoration_defaultmainactions()
}

AddIcon checkbox=opt_druid_restoration_aoe help=aoe specialization=restoration
{
 if not incombat() restorationprecombatmainactions()
 restoration_defaultmainactions()
}

AddIcon checkbox=!opt_druid_restoration_aoe enemies=1 help=cd specialization=restoration
{
 if not incombat() restorationprecombatcdactions()
 restoration_defaultcdactions()
}

AddIcon checkbox=opt_druid_restoration_aoe help=cd specialization=restoration
{
 if not incombat() restorationprecombatcdactions()
 restoration_defaultcdactions()
}

### Required symbols
# ancestral_call
# arcane_torrent_energy
# bag_of_tricks
# balance_affinity_talent_restoration
# berserking
# blood_fury
# cat_form
# cat_form_buff
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# feral_affinity_talent_restoration
# ferocious_bite
# fireblood
# lights_judgment
# lunar_empowerment_buff
# lunar_strike
# mangle
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# moonfire
# prowl
# prowl_buff
# rake
# rake_debuff
# rip
# rip_debuff
# shadowmeld_buff
# shred
# solar_wrath
# starsurge
# sunfire
# sunfire_debuff
# swipe_cat
# unbridled_fury_item
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
        OvaleScripts:RegisterScript("DRUID", "restoration", name, desc, code, "script")
    end
end
